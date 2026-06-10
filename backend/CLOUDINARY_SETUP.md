# Cloudinary Setup Guide

## ✅ Cloudinary is Now the Default Storage Provider!

Cloudinary has been implemented and set as the default storage provider for your project.

## Quick Setup

### 1. Create Cloudinary Account

1. Go to https://cloudinary.com/users/register_free
2. Sign up for a free account
3. You'll get 25 GB storage and 25 GB bandwidth/month free!

### 2. Get Your Credentials

After signing up, you'll see your Dashboard with:
- **Cloud Name** (e.g., `dxyz123abc`)
- **API Key** (e.g., `123456789012345`)
- **API Secret** (e.g., `abcdefghijklmnopqrstuvwxyz`)

### 3. Set Environment Variables

Add these to your `.env` file:

```env
# Storage Provider (Cloudinary is now default)
STORAGE_PROVIDER=cloudinary

# Cloudinary Credentials
CLOUDINARY_CLOUD_NAME=your-cloud-name
CLOUDINARY_API_KEY=your-api-key
CLOUDINARY_API_SECRET=your-api-secret
```

### 4. For Render Deployment

Add these environment variables in Render dashboard:

```
STORAGE_PROVIDER=cloudinary
CLOUDINARY_CLOUD_NAME=your-cloud-name
CLOUDINARY_API_KEY=your-api-key
CLOUDINARY_API_SECRET=your-api-secret
```

## Features You Get with Cloudinary

✅ **Automatic Image Optimization**
- Images are automatically optimized for web
- Multiple format support (WebP, AVIF, etc.)
- Automatic format selection based on browser

✅ **On-the-Fly Transformations**
- Resize, crop, rotate images via URL parameters
- Example: `https://res.cloudinary.com/your-cloud/image/upload/w_500,h_500,c_fill/media/image.jpg`

✅ **Video Support**
- Automatic video optimization
- Thumbnail generation
- Format conversion

✅ **CDN Included**
- Fast global delivery
- Automatic caching
- HTTPS by default

✅ **Free Tier**
- 25 GB storage
- 25 GB bandwidth/month
- Perfect for development and small-medium apps

## Testing

After setting up your credentials, test the upload:

```bash
# Start your server
npm run start:dev

# Test upload (using curl or Postman)
curl -X POST http://localhost:3000/posts \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -F "text=Test post" \
  -F "files=@/path/to/image.jpg"
```

## Image Transformations (Optional)

You can add transformations to image URLs:

```typescript
// In your Flutter app or frontend
const imageUrl = post.mediaJson[0].url;

// Add transformations
const optimizedUrl = imageUrl.replace(
  '/upload/',
  '/upload/w_800,h_600,c_limit,q_auto,f_auto/'
);
```

This will:
- Resize to max 800x600
- Maintain aspect ratio
- Auto quality
- Auto format (WebP if supported)

## Switching Back to Other Providers

If you want to use a different provider, just change:

```env
STORAGE_PROVIDER=cloudflare-r2  # or aws-s3
```

No code changes needed!

## Troubleshooting

### "Invalid API credentials"
- Double-check your Cloudinary credentials
- Make sure there are no extra spaces in `.env` file
- Restart your server after changing `.env`

### Upload fails
- Check file size (free tier has limits)
- Verify file format is supported
- Check server logs for specific errors

### Images not displaying
- Cloudinary URLs use HTTPS by default
- Check CORS settings if loading from different domain
- Verify the URL is correct in your database

## Free Tier Limits

- **Storage**: 25 GB
- **Bandwidth**: 25 GB/month
- **Transformations**: Unlimited
- **Uploads**: 25 GB/month

For production with high traffic, consider upgrading or switching to Cloudflare R2 (unlimited bandwidth).

## Next Steps

1. ✅ Cloudinary is installed and configured
2. ✅ Set your credentials in `.env`
3. ✅ Start uploading! 🚀

Your posts with images/videos will now be stored on Cloudinary automatically!

