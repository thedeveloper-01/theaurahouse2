export interface StorageProvider {
  uploadFile(
    file: Express.Multer.File,
    folder?: string,
  ): Promise<{ url: string; key: string }>;
  deleteFile(key: string): Promise<void>;
}

