
import type { VercelRequest, VercelResponse } from '@vercel/node';

export default function handler(
  _req: VercelRequest,
  res: VercelResponse,
) {
  res.setHeader('Cache-Control', 'no-store');

  return res.status(200).json({
    ok: true,
    service: 'vees-adventures-ai-proxy',
    provider: 'Groq',
    model: 'qwen/qwen3.8-27b',
    groqKeyConfigured: Boolean(process.env.GROQ_API_KEY?.trim()),
    // Which model checks AI-written text before a child sees it.
    moderationModel: process.env.GROQ_GUARD_MODEL?.trim() || 'qwen/qwen3.8-27b',
  });
}
