export interface MediaItem {
  url: string;
  type: 'image' | 'video';
  width?: number;
  height?: number;
  duration?: number; // for videos in seconds
  key?: string; // Storage key for deletion (Cloudinary public_id, S3 key, etc.)
}

