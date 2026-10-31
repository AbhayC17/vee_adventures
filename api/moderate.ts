import type { VercelRequest, VercelResponse } from '@vercel/node';

/**
 * Safety check for the "Discover anything" feature in SPOT.
 *
 * The game asks this endpoint whether a short piece of AI-written text (an
 * object's name and one or two facts) is suitable for children aged 3 to 6
 * BEFORE the child sees it. The app also runs its own word filters; this is a
 * second, independent check.
 *
 * Request:  POST { "text": "tennis ball. Tennis balls are fuzzy." }
 * Response: { "safe": true }  or  { "safe": false }
 *
 * By default the same model as the main proxy acts as the checker. To use a
 * dedicated safety model (for example a Llama Guard model), set the
 * GROQ_GUARD_MODEL environment variable in Vercel.
 */

const GROQ_URL = 'https://api.groq.com/openai/v1/chat/completions';
const DEFAULT_MODEL = 'qwen/qwen3.8-27b';
const MAX_TEXT_CHARS = 600;

const RATE_WINDOW_MS = 60_000;
const RATE_LIMIT_PER_WINDOW = 30;
const rateHits = new Map<string, { count: number; resetAt: number }>();

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

function readText(body: unknown): string | null {
  let value = body;
  if (typeof value === 'string') {
    try {
      value = JSON.parse(value);
    } catch {
      return null;
    }
  }
  if (!value || typeof value !== 'object' || Array.isArray(value)) return null;
  const text = (value as Record<string, unknown>).text;
  if (typeof text !== 'string') return null;
  const trimmed = text.trim();
  if (trimmed.length === 0 || trimmed.length > MAX_TEXT_CHARS) return null;
  return trimmed;
}

const CHECKER_PROMPT = `You are a strict safety checker for a game for children aged 3 to 6.
You will be given the name of an everyday object and one or two short sentences about it.
Answer with JSON only: {"safe": true} or {"safe": false}.
Answer {"safe": false} if the text contains ANY of: violence, weapons, drugs, alcohol, smoking, adult or romantic themes, scary or disturbing ideas, insults or hate, dangerous instructions, personal information, advertising or brand promotion, web addresses, or anything a young child should not read.
Answer {"safe": false} if a sentence is clearly untrue or very likely to be untrue about the named object.
Otherwise answer {"safe": true}. Never write anything except the JSON.`;

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
    return res.status(503).json({
      error: 'The AI service is not configured.',
      code: 'MISSING_GROQ_API_KEY',
    });
  }

  const text = readText(req.body);
  if (!text) {
    return res.status(400).json({
      error: 'Send a JSON object with a short "text" string.',
      code: 'INVALID_REQUEST',
    });
  }

  const guardModel = process.env.GROQ_GUARD_MODEL?.trim();
  const useGuardModel = Boolean(guardModel);

  const payload = useGuardModel
    ? {
        model: guardModel,
        temperature: 0,
        max_completion_tokens: 40,
        // Guard models read the text itself and answer "safe" or "unsafe".
        messages: [{ role: 'user', content: text }],
      }
    : {
        model: DEFAULT_MODEL,
        temperature: 0,
        max_completion_tokens: 60,
        response_format: { type: 'json_object' },
        messages: [
          { role: 'system', content: CHECKER_PROMPT },
          { role: 'user', content: text },
        ],
      };

  try {
    const upstream = await fetch(GROQ_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${apiKey}`,
      },
      body: JSON.stringify(payload),
      signal: AbortSignal.timeout(20_000),
    });

    const raw = await upstream.text();
    if (!upstream.ok) {
      console.error(`[Moderate] Upstream HTTP ${upstream.status}`);
      return res.status(502).json({
        error: 'The safety check is not available right now.',
        code: 'MODERATION_UNAVAILABLE',
      });
    }

    let content = '';
    try {
      const data = JSON.parse(raw) as {
        choices?: { message?: { content?: unknown } }[];
      };
      const first = data.choices?.[0]?.message?.content;
      content = typeof first === 'string' ? first.trim() : '';
    } catch {
      content = '';
    }

    let safe = false; // anything unclear counts as NOT safe
    if (useGuardModel) {
      safe = /^safe\b/i.test(content);
    } else {
      try {
        const verdict = JSON.parse(content) as { safe?: unknown };
        safe = verdict.safe === true;
      } catch {
        safe = false;
      }
    }

    return res.status(200).json({ safe });
  } catch (error) {
    console.error(
      '[Moderate] Request failed:',
      error instanceof Error ? error.message : 'Unknown error',
    );
    return res.status(502).json({
      error: 'The safety check is not available right now.',
      code: 'MODERATION_UNAVAILABLE',
    });
  }
}
