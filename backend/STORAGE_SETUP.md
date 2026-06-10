# Storage Provider Setup Guide

## Quick Setup

Set the `STORAGE_PROVIDER` environment variable to switch between providers:

- `aws-s3` - AWS S3 (default)
- `cloudflare-r2` - Cloudflare R2 (Recommended - Free unlimited bandwidth!)
- `cloudinary` - Cloudinary (Best for image optimization)

## 1. Cloudflare R2 (Recommended) ⭐

**Free Tier**: 10 GB storage, **Unlimited bandwidth**

### Setup Steps:

1. Create Cloudflare account: https://dash.cloudflare.com
2. Go to R2 → Create bucket
3. Create API token: R2 → Manage R2 API Tokens → Create API Token
4. Set environment variables:

```env
STORAGE_PROVIDER=cloudflare-r2
R2_ACCOUNT_ID=your-account-id
R2_ACCESS_KEY_ID=your-access-key-id
R2_SECRET_ACCESS_KEY=your-secret-access-key
R2_BUCKET_NAME=theaurahouse-media
R2_PUBLIC_URL=https://your-bucket.your-account-id.r2.cloudflarestorage.com
```

### Enable Public Access:

1. Go to R2 → Your bucket → Settings
2. Enable "Public Access"
3. Set custom domain (optional) for better URLs

**Why R2?** Unlimited egress = no bandwidth charges! Perfect for social media apps.

---

## 2. Cloudinary

**Free Tier**: 25 GB storage, 25 GB bandwidth/month

### Setup Steps:

1. Sign up: https://cloudinary.com/users/register_free
2. Get credentials from Dashboard
3. Set environment variables:

```env
STORAGE_PROVIDER=cloudinary
CLOUDINARY_CLOUD_NAME=your-cloud-name
CLOUDINARY_API_KEY=your-api-key
CLOUDINARY_API_SECRET=your-api-secret
```

**Why Cloudinary?** Automatic image optimization, transformations, and CDN included.

---

## 3. AWS S3 (Original)

**Free Tier**: 5 GB storage, 20,000 GET requests/month (first year)

### Setup Steps:

1. Create AWS account
2. Create S3 bucket
3. Create IAM user with S3 permissions
4. Set environment variables:

```env
STORAGE_PROVIDER=aws-s3
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=your-access-key
AWS_SECRET_ACCESS_KEY=your-secret-key
S3_BUCKET_NAME=theaurahouse-media
CLOUDFRONT_DOMAIN=https://your-cdn.cloudfront.net
```

---

## Installation

For Cloudinary:
```bash
npm install cloudinary
```

For R2/S3 (already installed):
```bash
# Uses existing @aws-sdk/client-s3
```

---

## Switching Providers

Just change the `STORAGE_PROVIDER` environment variable - no code changes needed!

```env
# Switch to R2
STORAGE_PROVIDER=cloudflare-r2

# Switch to Cloudinary
STORAGE_PROVIDER=cloudinary

# Switch back to S3
STORAGE_PROVIDER=aws-s3
```

---

## Comparison

| Feature | Cloudflare R2 | Cloudinary | AWS S3 |
|---------|---------------|------------|--------|
| Free Storage | 10 GB | 25 GB | 5 GB (1st year) |
| Free Bandwidth | **Unlimited** | 25 GB/month | 20K requests |
| Image Optimization | ❌ | ✅ | ❌ |
| CDN Included | ✅ | ✅ | ✅ (CloudFront) |
| S3 Compatible | ✅ | ❌ | ✅ |
| Setup Difficulty | Easy | Easy | Medium |

---

## Recommendation

**For Production**: Use **Cloudflare R2**
- Unlimited bandwidth (no surprise bills!)
- S3-compatible (easy migration)
- Fast global CDN
- Simple setup

**For Development**: Use **Cloudinary**
- Easiest setup
- Great for testing image uploads
- Automatic optimizations

