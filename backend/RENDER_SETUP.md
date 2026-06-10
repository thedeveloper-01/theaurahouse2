# Render Deployment Setup Guide

## Build Command Configuration

Update your Render service's **Build Command** to:

```bash
cd backend && npm install && npx prisma generate && npx prisma migrate deploy && npm run build
```

This will:
1. Navigate to the backend directory
2. Install dependencies
3. Generate Prisma Client
4. Deploy/apply database migrations
5. Build the NestJS application

## Start Command Configuration

Update your Render service's **Start Command** to:

```bash
cd backend && npm run start:prod
```

## Environment Variables

Make sure these are set in your Render service:

### Required:
- `DATABASE_URL` - Your PostgreSQL connection string (Render provides this automatically if you're using Render PostgreSQL)
- `JWT_SECRET` - A secure random string for JWT token signing
- `JWT_EXPIRES_IN` - Token expiration time (e.g., `7d`, `24h`, `3600s`)

### Optional (for file storage):
- `AWS_REGION` - AWS region (e.g., `us-east-1`)
- `AWS_ACCESS_KEY_ID` - AWS access key
- `AWS_SECRET_ACCESS_KEY` - AWS secret key
- `S3_BUCKET_NAME` - S3 bucket name
- `CLOUDFRONT_DOMAIN` - CloudFront distribution domain

### Port Configuration:
- Render automatically sets `PORT` environment variable
- Your NestJS app should read from `process.env.PORT` (check `src/main.ts`)

## Quick Fix for Missing display_name Column

If you're getting the `display_name` column error, run this SQL in your Render database console:

```sql
ALTER TABLE users ADD COLUMN IF NOT EXISTS display_name VARCHAR(100);
```

Or use the provided migration file:
```bash
psql $DATABASE_URL -f backend/fix-display-name.sql
```

## Step-by-Step Render Setup

1. **Go to your Render Dashboard**
   - Navigate to your backend service

2. **Update Build Command:**
   - Go to Settings → Build & Deploy
   - Set Build Command to:
     ```
     cd backend && npm install && npx prisma generate && npx prisma migrate deploy && npm run build
     ```

3. **Update Start Command:**
   - Set Start Command to:
     ```
     cd backend && npm run start:prod
     ```

4. **Set Root Directory:**
   - Set Root Directory to: `backend`

5. **Environment Variables:**
   - Add all required environment variables listed above

6. **Deploy:**
   - Click "Manual Deploy" → "Deploy latest commit"
   - Or push to your connected branch to trigger auto-deploy

## Troubleshooting

### Migration Errors
If migrations fail, you can run them manually:
```bash
cd backend && npx prisma migrate deploy
```

### Prisma Client Not Generated
Make sure `npx prisma generate` is in your build command.

### Port Issues
Ensure your `src/main.ts` reads from `process.env.PORT`:
```typescript
const port = process.env.PORT || 3000;
await app.listen(port);
```

### Database Connection Issues
- Verify `DATABASE_URL` is set correctly
- Check that your database is accessible from Render
- Ensure SSL is enabled if required

