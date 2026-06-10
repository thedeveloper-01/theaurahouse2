# Quick Start Guide

## 1. Install Dependencies

```bash
cd backend
npm install
```

## 2. Set Up Environment

```bash
cp .env.example .env
```

Edit `.env` with your configuration:
- Database credentials
- JWT secret (generate a strong random string)
- AWS S3 credentials
- CloudFront domain (optional)

## 3. Set Up PostgreSQL

### Option A: Local PostgreSQL

```bash
# Create database
createdb theaurahouse

# Or using psql
psql -U postgres
CREATE DATABASE theaurahouse;
\q
```

### Option B: Cloud (RDS / Cloud SQL)

Use your managed PostgreSQL connection string in `.env`.

## 4. Run Database Migration

```bash
psql -U postgres -d theaurahouse -f src/migrations/001-initial-schema.sql
```

Or if using environment variables:
```bash
psql -h $DB_HOST -U $DB_USERNAME -d $DB_DATABASE -f src/migrations/001-initial-schema.sql
```

## 5. Set Up AWS S3

1. Create S3 bucket (e.g., `theaurahouse-media`)
2. Configure bucket policy for public read (or use CloudFront)
3. Create IAM user with S3 permissions
4. Add credentials to `.env`

### S3 Bucket Policy Example

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicReadGetObject",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::theaurahouse-media/*"
    }
  ]
}
```

### CloudFront Setup (Optional but Recommended)

1. Create CloudFront distribution
2. Point to S3 bucket
3. Add domain to `CLOUDFRONT_DOMAIN` in `.env`

## 6. Start the Server

```bash
# Development
npm run start:dev

# Production
npm run build
npm run start:prod
```

Server runs on `http://localhost:3000` (or PORT from .env)

## 7. Test the API

### Register a User

```bash
curl -X POST http://localhost:3000/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "email": "test@example.com",
    "password": "password123"
  }'
```

### Login

```bash
curl -X POST http://localhost:3000/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "password": "password123"
  }'
```

Save the `accessToken` from response.

### Create a Post (with image)

```bash
curl -X POST http://localhost:3000/posts \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -F "text=My first post!" \
  -F "files=@/path/to/image.jpg"
```

### Get Posts

```bash
curl http://localhost:3000/posts
```

## API Documentation

See `README.md` for full API endpoint documentation.

## Troubleshooting

### Database Connection Error
- Check PostgreSQL is running
- Verify credentials in `.env`
- Ensure database exists

### S3 Upload Fails
- Verify AWS credentials
- Check bucket name matches `.env`
- Ensure IAM user has S3 write permissions

### JWT Errors
- Ensure `JWT_SECRET` is set in `.env`
- Token expires after `JWT_EXPIRES_IN` (default: 7d)

## Next Steps

- [ ] Set up Redis for caching
- [ ] Configure production environment variables
- [ ] Set up CI/CD pipeline
- [ ] Add monitoring (Sentry, Prometheus)
- [ ] Implement rate limiting

