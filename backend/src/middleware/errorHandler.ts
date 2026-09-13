import { NextFunction, Request, Response } from 'express';
import { fail } from '../utils/apiResponse';

export function notFoundHandler(_req: Request, res: Response) {
  fail(res, 'Route not found.', 404);
}

export function errorHandler(err: unknown, _req: Request, res: Response, _next: NextFunction) {
  console.error(err);
  const message = err instanceof Error ? err.message : 'Internal server error.';
  fail(res, message, 500);
}
