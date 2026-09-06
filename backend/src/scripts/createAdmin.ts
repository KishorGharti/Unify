// One-off CLI to create (or reset the password of) an admin panel account.
// There is deliberately no public HTTP signup route for admins - run this
// locally, against whatever DATABASE_URL your .env currently points at.
//
// Usage:
//   npm run create-admin -- --email you@example.com --password 'Str0ngPass!' --name "Your Name"

import bcrypt from 'bcryptjs';
import { prisma } from '../db/prisma';

function getArg(flag: string): string | undefined {
  const i = process.argv.indexOf(flag);
  return i !== -1 ? process.argv[i + 1] : undefined;
}

async function main() {
  const email = getArg('--email')?.trim().toLowerCase();
  const password = getArg('--password');
  const fullName = getArg('--name') ?? 'Admin';

  if (!email || !password) {
    console.error('Usage: npm run create-admin -- --email you@example.com --password \'Str0ngPass!\' --name "Your Name"');
    process.exit(1);
  }
  if (password.length < 8) {
    console.error('Password must be at least 8 characters.');
    process.exit(1);
  }

  const passwordHash = await bcrypt.hash(password, 12);

  const admin = await prisma.adminUser.upsert({
    where: { email },
    update: { passwordHash, fullName },
    create: { email, passwordHash, fullName },
  });

  console.log(`✅ Admin ready: ${admin.email} (id: ${admin.id})`);
  console.log(`Log in at the admin panel with this email and the password you just set.`);
}

main()
  .catch((err) => {
    console.error('Failed to create admin:', err);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
