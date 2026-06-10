# Quick Start with Prisma

## 🚀 Get Started in 5 Minutes

### 1. Install Dependencies

```bash
cd backend
npm install
```

### 2. Configure Database

Create `.env` file:

```env
DATABASE_URL="postgresql://postgres:postgres@localhost:5432/theaurahouse?schema=public"
JWT_SECRET=your-secret-key-here
JWT_EXPIRES_IN=7d
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=your-key
AWS_SECRET_ACCESS_KEY=your-secret
S3_BUCKET_NAME=theaurahouse-media
CLOUDFRONT_DOMAIN=https://your-cdn.cloudfront.net
PORT=3000
NODE_ENV=development
```

### 3. Create Database

```sql
CREATE DATABASE theaurahouse;
```

### 4. Generate Prisma Client

```bash
npm run prisma:generate
```

### 5. Run Migrations

```bash
npm run prisma:migrate
```

When prompted, name your migration: `init`

This will:
- Create the database schema
- Generate Prisma Client
- Set up all tables and indexes

### 6. Start Server

```bash
npm run start:dev
```

Server runs on `http://localhost:3000`

## 📋 Verify Setup

### Check Database

```bash
npm run prisma:studio
```

Opens Prisma Studio at `http://localhost:5555` - visual database browser

### Test API

```bash
# Register user
curl -X POST http://localhost:3000/auth/register \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser","email":"test@example.com","password":"password123"}'

# Login
curl -X POST http://localhost:3000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser","password":"password123"}'
```

## 📁 Project Structure

```
backend/
├── prisma/
│   └── schema.prisma      # Database schema
├── src/
│   ├── prisma/
│   │   ├── prisma.service.ts
│   │   └── prisma.module.ts
│   ├── auth/              # Authentication
│   ├── users/             # User management
│   ├── posts/             # Posts CRUD
│   ├── comments/          # Comments
│   ├── likes/             # Likes
│   └── storage/           # S3 storage
└── package.json
```

## 🔧 Common Commands

```bash
# Generate Prisma Client (after schema changes)
npm run prisma:generate

# Create and apply migration
npm run prisma:migrate

# Apply migrations (production)
npm run prisma:migrate:deploy

# Open Prisma Studio
npm run prisma:studio

# Format schema
npx prisma format

# Validate schema
npx prisma validate
```

## 🐛 Troubleshooting

### "Prisma Client not generated"
```bash
npm run prisma:generate
```

### "Migration failed"
```bash
# Check database connection in .env
# Verify DATABASE_URL is correct
npx prisma migrate reset  # ⚠️ Deletes all data (dev only)
```

### "Cannot find module '@prisma/client'"
```bash
npm install
npm run prisma:generate
```

## 📚 Next Steps

- Read [PRISMA_SETUP.md](./PRISMA_SETUP.md) for detailed guide
- Check [README.md](./README.md) for API documentation
- See [PRISMA_MIGRATION_SUMMARY.md](./PRISMA_MIGRATION_SUMMARY.md) for migration details

