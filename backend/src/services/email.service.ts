import nodemailer from 'nodemailer';
import { env } from '../config/env';

let transporter: nodemailer.Transporter | null = null;

function getTransporter(): nodemailer.Transporter {
  if (!transporter) {
    if (!env.email.user || !env.email.appPassword) {
      throw new Error('EMAIL_USER / EMAIL_APP_PASSWORD are not set - copy .env.example and fill them in.');
    }
    transporter = nodemailer.createTransport({
      service: 'gmail',
      auth: { user: env.email.user, pass: env.email.appPassword },
    });
  }
  return transporter;
}

async function sendMail(to: string, subject: string, html: string, text: string): Promise<void> {
  await getTransporter().sendMail({
    from: `Unify <${env.email.user}>`,
    to,
    subject,
    text,
    html,
  });
}

function codeBlock(code: string): string {
  return `<div style="font-size:28px;font-weight:700;letter-spacing:8px;font-family:monospace;margin:16px 0;">${code}</div>`;
}

export async function sendPasswordResetEmail(to: string, code: string, ttlMinutes: number): Promise<void> {
  await sendMail(
    to,
    `Your Unify password reset code: ${code}`,
    `<p>Use this code to set a new Unify password:</p>${codeBlock(code)}<p>It expires in ${ttlMinutes} minutes. If you didn't request this, you can ignore this email - your password won't change.</p>`,
    `Your Unify password reset code is ${code}. It expires in ${ttlMinutes} minutes. If you didn't request this, you can ignore this email - your password won't change.`,
  );
}
