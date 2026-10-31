
import type { VercelRequest, VercelResponse } from '@vercel/node';

const GROQ_URL = 'https://api.groq.com/openai/v1/chat/completions';
const MODEL = 'qwen/qwen3.8-27b';
const MAX_IMAGE_DATA_URL_CHARS = 3_800_000;

type JsonObject = Record<string, unknown>;

function parseBody(body: unknown): JsonObject | null {
  let value = body;

  if (typeof value === 'string') {
    try {
      value = JSON.parse(value);
    } catch {
      return null;
    }
  }

  if (!value || typeof value !== 'object' || Array.isArray(value)) {
    return null;
  }

  return value as JsonObject;
}

function errorMessage(payload: unknown): string | undefined {
  if (!payload || typeof payload !== 'object') return undefined;

  const root = payload as JsonObject;
  const error = root.error;

  if (typeof error === 'string') return error;

  if (error && typeof error === 'object') {
    const message = (error as JsonObject).message;
    if (typeof message === 'string') return message;
  }

  return undefined;
}

function validateImages(messages: unknown[]): string | null {
  for (const rawMessage of messages) {
    if (!rawMessage || typeof rawMessage !== 'object') continue;

    const message = rawMessage as JsonObject;
    if (!Array.isArray(message.content)) continue;

    for (const rawPart of message.content) {
      if (!rawPart || typeof rawPart !== 'object') continue;

      const part = rawPart as JsonObject;
      if (part.type !== 'image_url') continue;

      const imageUrl = part.image_url;
      if (!imageUrl || typeof imageUrl !== 'object') continue;

      const url = (imageUrl as JsonObject).url;
      if (typeof url !== 'string' || !url.startsWith('data:')) continue;

      if (url.length > MAX_IMAGE_DATA_URL_CHARS) {
        return 'IMAGE_PAYLOAD_TOO_LARGE';
      }

      const validImage = /^data:image\/(jpeg|png|webp|gif);base64,[A-Za-z0-9+/=\r\n]+$/i.test(url);
      if (!validImage) return 'UNSUPPORTED_IMAGE_FORMAT';
    }
  }

  return null;
}

const RATE_WINDOW_MS = 60_000;
const RATE_LIMIT_PER_WINDOW = 20;
const MAX_MESSAGES = 6;
const rateHits = new Map<string, { count: number; resetAt: number }>();

/**
 * Best-effort, per-instance rate limit. Serverless instances do not share
 * memory, so this slows abuse rather than stopping it; add a shared store
 * (for example Vercel KV) if you need a hard limit.
 */
function isRateLimited(req: VercelRequest): boolean {
  const forwarded = req.headers['x-forwarded-for'];
  const first = Array.isArray(forwarded)
    ? forwarded[0]
    : (forwarded ?? '').split(',')[0];
  const key = (first || req.socket?.remoteAddress || 'unknown').trim();
  const now = Date.now();

  if (rateHits.size > 5000) {
    for (const [k, v] of rateHits) {
      if (v.resetAt <= now) rateHits.delete(k);
    }
  }

  const entry = rateHits.get(key);
  if (!entry || entry.resetAt <= now) {
    rateHits.set(key, { count: 1, resetAt: now + RATE_WINDOW_MS });
    return false;
  }
  entry.count += 1;
  return entry.count > RATE_LIMIT_PER_WINDOW;
}

/**
 * The Flutter web app calls this endpoint from the same origin, and native
 * apps send no Origin header at all. Any other website is refused unless its
 * origin is listed in the ALLOWED_ORIGINS environment variable.
 */
function isOriginAllowed(req: VercelRequest): boolean {
  const origin = req.headers.origin;
  if (!origin) return true;

  const allowed = (process.env.ALLOWED_ORIGINS ?? '')
    .split(',')
    .map((value) => value.trim())
    .filter(Boolean);
  if (allowed.includes(origin)) return true;

  try {
    return new URL(origin).host === req.headers.host;
  } catch {
    return false;
  }
}

export default async function handler(
  req: VercelRequest,
  res: VercelResponse,
) {
  res.setHeader('Cache-Control', 'no-store');
  res.setHeader('Vary', 'Origin');

  if (!isOriginAllowed(req)) {
    return res.status(403).json({
      error: 'This website is not allowed to use the AI service.',
      code: 'ORIGIN_NOT_ALLOWED',
    });
  }

  if (req.headers.origin) {
    res.setHeader('Access-Control-Allow-Origin', req.headers.origin);
    res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
  }

  if (req.method === 'OPTIONS') return res.status(204).end();

  if (req.method !== 'POST') {
    res.setHeader('Allow', 'POST, OPTIONS');
    return res.status(405).json({
      error: 'Method not allowed. Use POST.',
      code: 'METHOD_NOT_ALLOWED',
    });
  }

  if (isRateLimited(req)) {
    res.setHeader('Retry-After', '30');
    return res.status(429).json({
      error: 'Too many requests. Please wait a moment and try again.',
      code: 'RATE_LIMITED',
    });
  }

  const apiKey = process.env.GROQ_API_KEY?.trim();

  if (!apiKey) {
    console.error('[Groq proxy] GROQ_API_KEY is not configured.');

    return res.status(503).json({
      error: 'The AI service is not configured. Add GROQ_API_KEY to the Vercel Production environment and redeploy.',
      code: 'MISSING_GROQ_API_KEY',
    });
  }

  const incoming = parseBody(req.body);

  if (!incoming || !Array.isArray(incoming.messages)) {
    return res.status(400).json({
      error: 'Invalid request. Expected a JSON object containing a messages array.',
      code: 'INVALID_REQUEST',
    });
  }

  const messages = incoming.messages as unknown[];

  if (messages.length > MAX_MESSAGES) {
    return res.status(400).json({
      error: 'Too many messages in one request.',
      code: 'TOO_MANY_MESSAGES',
    });
  }

  if (messages.length === 0) {
    return res.status(400).json({
      error: 'The messages array cannot be empty.',
      code: 'EMPTY_MESSAGES',
    });
  }

  const imageError = validateImages(messages);

  if (imageError === 'IMAGE_PAYLOAD_TOO_LARGE') {
    return res.status(413).json({
      error: 'That picture is too large. Choose a smaller image and try again.',
      code: imageError,
    });
  }

  if (imageError === 'UNSUPPORTED_IMAGE_FORMAT') {
    return res.status(400).json({
      error: 'This image format is not supported. Try JPEG, PNG, or WebP.',
      code: imageError,
    });
  }

  const payload: JsonObject = {
    model: MODEL,
    messages,
    temperature:
      typeof incoming.temperature === 'number'
        ? incoming.temperature
        : 0.2,
    max_completion_tokens:
      typeof incoming.max_completion_tokens === 'number'
        ? Math.min(Math.max(incoming.max_completion_tokens, 1), 4096)
        : 1024,
    ...(incoming.response_format
      ? { response_format: incoming.response_format }
      : {}),
  };

  try {
    const upstream = await fetch(GROQ_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${apiKey}`,
      },
      body: JSON.stringify(payload),
      signal: AbortSignal.timeout(50_000),
    });

    const raw = await upstream.text();

    let data: unknown;
    try {
      data = raw ? JSON.parse(raw) : {};
    } catch {
      data = {};
    }

    if (!upstream.ok) {
      const message =
        errorMessage(data) ||
        `Groq request failed with HTTP ${upstream.status}.`;

      console.error(
        `[Groq proxy] Upstream HTTP ${upstream.status}: ${message}`,
      );

      // Preserve Groq's retry hint when it provides one.
      const retryAfter = upstream.headers.get('retry-after');
      if (retryAfter) {
        res.setHeader('Retry-After', retryAfter);
      }

      if (upstream.status === 429) {
        return res.status(429).json({
          error: 'The AI service has reached its current rate limit. Wait briefly and try again.',
          code: 'GROQ_RATE_LIMIT',
          retryAfter: retryAfter || null,
        });
      }

      return res.status(upstream.status).json({
        error: message,
        code: 'GROQ_UPSTREAM_ERROR',
      });
    }

    // The Flutter client already expects this OpenAI-compatible envelope.
    return res.status(200).json(data);
  } catch (error) {
    const timedOut =
      error instanceof Error &&
      (error.name === 'TimeoutError' || error.name === 'AbortError');

    console.error(
      '[Groq proxy] Request failed:',
      error instanceof Error ? error.message : 'Unknown error',
    );

    return res.status(timedOut ? 504 : 502).json({
      error: timedOut
        ? 'The AI service took too long to respond. Please try again.'
        : 'Could not connect to the AI service. Please try again.',
      code: timedOut ? 'GROQ_TIMEOUT' : 'GROQ_NETWORK_ERROR',
    });
  }
}
