import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { StorageProvider } from './storage-provider.interface';
import { AwsS3Provider } from './providers/aws-s3.provider';
import { CloudflareR2Provider } from './providers/cloudflare-r2.provider';
import { CloudinaryProvider } from './providers/cloudinary.provider';

@Injectable()
export class StorageService {
  private provider: StorageProvider;

  constructor(private configService: ConfigService) {
    // Determine which provider to use based on environment variables
    // Default to Cloudinary (free tier: 25GB storage, 25GB bandwidth)
    const storageProvider = this.configService.get<string>('STORAGE_PROVIDER') || 'cloudinary';

    switch (storageProvider) {
      case 'cloudflare-r2':
        this.provider = new CloudflareR2Provider(configService);
        break;
      case 'aws-s3':
        this.provider = new AwsS3Provider(configService);
        break;
      case 'cloudinary':
      default:
        this.provider = new CloudinaryProvider(configService);
        break;
    }
  }

  async uploadFile(
    file: Express.Multer.File,
    folder: string = 'media',
  ): Promise<{ url: string; key: string }> {
    return this.provider.uploadFile(file, folder);
  }

  async deleteFile(key: string): Promise<void> {
    return this.provider.deleteFile(key);
  }

  async uploadMultipleFiles(
    files: Express.Multer.File[],
    folder: string = 'media',
  ): Promise<Array<{ url: string; key: string }>> {
    return Promise.all(files.map((file) => this.uploadFile(file, folder)));
  }
}

