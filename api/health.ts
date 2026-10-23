
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
  });
}
