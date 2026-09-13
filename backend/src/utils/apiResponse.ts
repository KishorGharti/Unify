import { Response } from 'express';

export function ok(res: Response, data: unknown, status = 200, message?: string) {
  return res.status(status).json({ success: true, message: message ?? null, data, status_code: status, meta: null });
}

export function fail(res: Response, message: string, status = 400) {
  return res.status(status).json({ success: false, message, data: null, status_code: status, meta: null });
}
