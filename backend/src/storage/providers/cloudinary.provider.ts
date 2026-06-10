import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { v2 as cloudinary } from 'cloudinary';
import { StorageProvider } from '../storage-provider.interface';

@Injectable()
export class CloudinaryProvider implements StorageProvider {
  constructor(private configService: ConfigService) {
    cloudinary.config({
      cloud_name: this.configService.get<string>('CLOUDINARY_CLOUD_NAME'),
      api_key: this.configService.get<string>('CLOUDINARY_API_KEY'),
      api_secret: this.configService.get<string>('CLOUDINARY_API_SECRET'),
    });
  }

  async uploadFile(
    file: Express.Multer.File,
    folder: string = 'media',
  ): Promise<{ url: string; key: string }> {
    return new Promise((resolve, reject) => {
      const uploadStream = cloudinary.uploader.upload_stream(
        {
          folder,
          resource_type: 'auto', // auto-detect image/video
        },
        (error, result) => {
          if (error) {
            reject(error);
          } else {
            resolve({
              url: result.secure_url,
              key: result.public_id,
            });
          }
        },
      );

      uploadStream.end(file.buffer);
    });
  }

  async deleteFile(key: string): Promise<void> {
    return new Promise((resolve, reject) => {
      // Cloudinary public_id can include folder path
      // Remove any URL parts if key is a full URL
      const publicId = key.includes('http') 
        ? key.split('/').slice(-2).join('/').replace(/\.[^/.]+$/, '') // Extract folder/filename from URL
        : key.replace(/\.[^/.]+$/, ''); // Remove extension if present
      
      cloudinary.uploader.destroy(publicId, (error, result) => {
        if (error) {
          reject(error);
        } else {
          resolve();
        }
      });
    });
  }
}

