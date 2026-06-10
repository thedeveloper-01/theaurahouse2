# Cloudinary Quick Start

## ✅ Cloudinary is Now Active!

Cloudinary has been implemented and set as the **default storage provider**.

## Setup (2 minutes)

### 1. Get Cloudinary Credentials

1. Sign up: https://cloudinary.com/users/register_free
2. Copy your credentials from Dashboard:
   - Cloud Name
   - API Key  
   - API Secret

### 2. Add to `.env`

```env
STORAGE_PROVIDER=cloudinary
CLOUDINARY_CLOUD_NAME=your-cloud-name
CLOUDINARY_API_KEY=your-api-key
CLOUDINARY_API_SECRET=your-api-secret
```

### 3. Restart Server

```bash
npm run start:dev
```

## That's It! 🎉

Your file uploads now go to Cloudinary automatically.

## Test It

```bash
curl -X POST http://localhost:3000/posts \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -F "text=Test with Cloudinary" \
  -F "files=@image.jpg"
```

## What You Get

- ✅ 25 GB free storage
- ✅ 25 GB bandwidth/month
- ✅ Automatic image optimization
- ✅ CDN included
- ✅ Video support
- ✅ HTTPS by default

## For Render Deployment

Add these environment variables in Render:

```
STORAGE_PROVIDER=cloudinary
CLOUDINARY_CLOUD_NAME=your-cloud-name
CLOUDINARY_API_KEY=your-api-key
CLOUDINARY_API_SECRET=your-api-secret
```

Done! 🚀

