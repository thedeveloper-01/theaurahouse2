import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { S3Client, PutObjectCommand, DeleteObjectCommand } from '@aws-sdk/client-s3';
import { v4 as uuidv4 } from 'uuid';
import { StorageProvider } from '../storage-provider.interface';

@Injectable()
export class AwsS3Provider implements StorageProvider {
  private s3Client: S3Client;
  private bucketName: string;
  private cloudfrontDomain: string;

  constructor(private configService: ConfigService) {
    this.s3Client = new S3Client({
      region: this.configService.get<string>('AWS_REGION'),
      credentials: {
        accessKeyId: this.configService.get<string>('AWS_ACCESS_KEY_ID'),
        secretAccessKey: this.configService.get<string>('AWS_SECRET_ACCESS_KEY'),
      },
    });
    this.bucketName = this.configService.get<string>('S3_BUCKET_NAME');
    this.cloudfrontDomain = this.configService.get<string>('CLOUDFRONT_DOMAIN');
  }

  async uploadFile(
    file: Express.Multer.File,
    folder: string = 'media',
  ): Promise<{ url: string; key: string }> {
    const fileExtension = file.originalname.split('.').pop();
    const fileName = `${folder}/${uuidv4()}.${fileExtension}`;

    const command = new PutObjectCommand({
      Bucket: this.bucketName,
      Key: fileName,
      Body: file.buffer,
      ContentType: file.mimetype,
      ACL: 'public-read',
    });

    await this.s3Client.send(command);

    const url = this.cloudfrontDomain
      ? `${this.cloudfrontDomain}/${fileName}`
      : `https://${this.bucketName}.s3.amazonaws.com/${fileName}`;

    return { url, key: fileName };
  }

  async deleteFile(key: string): Promise<void> {
    const command = new DeleteObjectCommand({
      Bucket: this.bucketName,
      Key: key,
    });

    await this.s3Client.send(command);
  }
}

