# Deploying to Render

## Build & Start Commands for Render

### Build Command
```bash
npm install && npm run build
```

Or simply:
```bash
npm install
```
(Render will automatically run `npm run build` if a build script exists)

### Start Command
```bash
npm run start:prod
```

## Environment Variables

Set these in Render's Environment Variables section:

### Required
- `DATABASE_URL` - Your Neon PostgreSQL connection string
- `JWT_SECRET` - Secret key for JWT tokens
- `JWT_EXPIRES_IN` - Token expiration (e.g., `7d`)
- `PORT` - Port number (Render sets this automatically, but you can use `3000`)

### AWS S3 (Required for file uploads)
- `AWS_REGION` - AWS region (e.g., `us-east-1`)
- `AWS_ACCESS_KEY_ID` - Your AWS access key
- `AWS_SECRET_ACCESS_KEY` - Your AWS secret key
- `S3_BUCKET_NAME` - Your S3 bucket name
- `CLOUDFRONT_DOMAIN` - Your CloudFront domain (optional)

### Optional
- `NODE_ENV` - Set to `production`
- `REDIS_HOST` - Redis host (if using)
- `REDIS_PORT` - Redis port (if using)
- `REDIS_PASSWORD` - Redis password (if using)

## Render Configuration

### Service Type
- **Type**: Web Service

### Build Settings
- **Root Directory**: `backend` (if deploying from monorepo root)
- **Build Command**: `npm install && npm run build`
- **Start Command**: `npm run start:prod`

### Database Setup
1. Use your existing Neon PostgreSQL database
2. Add `DATABASE_URL` environment variable
3. Run migrations: `npx prisma migrate deploy` (or use `prisma db push` for initial setup)

## Post-Deployment

After deployment, you may need to run database migrations:

```bash
npx prisma migrate deploy
```

Or if using `db push`:
```bash
npx prisma db push
```

## Health Check

Render will check: `https://your-app.onrender.com/health`

The health endpoint returns:
```json
{
  "status": "ok",
  "timestamp": "2025-12-04T..."
}
```

## Troubleshooting

### Build Fails
- Ensure `DATABASE_URL` is set (even if migrations fail, Prisma needs it to generate client)
- Check Node.js version (should be 18+)

### Runtime Errors
- Verify all environment variables are set
- Check database connection
- Review Render logs for specific errors

### Database Connection Issues
- Ensure Neon database allows connections from Render's IPs
- Check SSL mode in connection string
- Verify credentials are correct

