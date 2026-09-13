import dotenv from 'dotenv';

dotenv.config();

function required(name: string): string {
  const value = process.env[name];
  if (!value) {
    throw new Error(`Missing required environment variable: ${name}. Copy .env.example to .env and fill it in.`);
  }
  return value;
}

export const env = {
  port: parseInt(process.env.PORT ?? '4000', 10),
  nodeEnv: process.env.NODE_ENV ?? 'development',
  corsOrigin: process.env.CORS_ORIGIN ?? '*',

  jwtSecret: process.env.JWT_SECRET ?? 'dev-only-insecure-secret-change-me',
  jwtExpiresIn: process.env.JWT_EXPIRES_IN ?? '7d',

  adminJwtSecret: process.env.ADMIN_JWT_SECRET ?? 'dev-only-insecure-admin-secret-change-me',
  adminJwtExpiresIn: process.env.ADMIN_JWT_EXPIRES_IN ?? '12h',

  tokenEncryptionKey: process.env.TOKEN_ENCRYPTION_KEY ?? '0'.repeat(64),

  email: {
    user: process.env.EMAIL_USER ?? '',
    appPassword: process.env.EMAIL_APP_PASSWORD ?? '',
  },

  meta: {
    appId: process.env.META_APP_ID ?? '',
    appSecret: process.env.META_APP_SECRET ?? '',
    oauthRedirectUri: process.env.META_OAUTH_REDIRECT_URI ?? '',
    webhookVerifyToken: process.env.META_WEBHOOK_VERIFY_TOKEN ?? '',
    graphApiVersion: process.env.META_GRAPH_API_VERSION ?? 'v20.0',
  },

  metaInstagramLogin: {
    appId: process.env.META_INSTAGRAM_APP_ID || process.env.META_APP_ID || '',
    appSecret: process.env.META_INSTAGRAM_APP_SECRET || process.env.META_APP_SECRET || '',
    oauthRedirectUri: process.env.META_INSTAGRAM_OAUTH_REDIRECT_URI ?? '',
  },

  assertMetaConfigured(): void {
    required('META_APP_ID');
    required('META_APP_SECRET');
    required('META_OAUTH_REDIRECT_URI');
  },

  assertInstagramLoginConfigured(): void {
    if (!this.metaInstagramLogin.appId) required('META_INSTAGRAM_APP_ID');
    if (!this.metaInstagramLogin.appSecret) required('META_INSTAGRAM_APP_SECRET');
    required('META_INSTAGRAM_OAUTH_REDIRECT_URI');
  },
};
