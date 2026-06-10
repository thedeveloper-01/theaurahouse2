import {
  Injectable,
  NotFoundException,
  ForbiddenException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { Prisma } from '@prisma/client';
import { MediaItem } from '../types/media-item.type';

type PostWithUser = Prisma.PostGetPayload<{ include: { user: true } }>;
import { CreatePostDto } from './dto/create-post.dto';
import { UpdatePostDto } from './dto/update-post.dto';
import { StorageService } from '../storage/storage.service';

@Injectable()
export class PostsService {
  constructor(
    private prisma: PrismaService,
    private storageService: StorageService,
  ) {}

  async create(
    userId: string,
    createPostDto: CreatePostDto,
    files?: Express.Multer.File[],
  ): Promise<PostWithUser> {
    let mediaJson: MediaItem[] = [];

    // Upload files to storage (Cloudinary/S3/R2) if provided
    if (files && files.length > 0) {
      const uploadResults = await this.storageService.uploadMultipleFiles(files);
      mediaJson = uploadResults.map((result, index) => {
        const file = files[index];
        const isVideo = file.mimetype.startsWith('video/');
        return {
          url: result.url,
          type: isVideo ? 'video' : 'image',
          key: result.key, // Store key for deletion
          width: undefined, // Can be extracted from image metadata if needed
          height: undefined,
          duration: undefined, // Can be extracted from video metadata if needed
        };
      });
    }

    return this.prisma.post.create({
      data: {
        userId,
        text: createPostDto.text,
        mediaJson: mediaJson as unknown as any,
        isVideo: mediaJson.some((m) => m.type === 'video'),
        privacy: createPostDto.privacy || 'public',
      },
      include: { user: true },
    });
  }

  async findAll(
    page: number = 1,
    limit: number = 20,
    userId?: string,
  ): Promise<{ posts: PostWithUser[]; total: number }> {
    const skip = (page - 1) * limit;
    const where = userId ? { userId } : {};

    const [posts, total] = await Promise.all([
      this.prisma.post.findMany({
        where,
        include: { user: true },
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
      }),
      this.prisma.post.count({ where }),
    ]);

    return { posts, total };
  }

  async findOne(id: string): Promise<PostWithUser> {
    const post = await this.prisma.post.findUnique({
      where: { id },
      include: { user: true },
    });

    if (!post) {
      throw new NotFoundException('Post not found');
    }

    return post;
  }

  async update(
    id: string,
    userId: string,
    updatePostDto: UpdatePostDto,
  ): Promise<PostWithUser> {
    const post = await this.findOne(id);

    if (post.userId !== userId) {
      throw new ForbiddenException('You can only update your own posts');
    }

    return this.prisma.post.update({
      where: { id },
      data: updatePostDto,
      include: { user: true },
    });
  }

  async remove(id: string, userId: string): Promise<void> {
    const post = await this.findOne(id);

    if (post.userId !== userId) {
      throw new ForbiddenException('You can only delete your own posts');
    }

    // Delete media files from storage
    if (post.mediaJson) {
      const mediaJson = post.mediaJson as unknown as MediaItem[];
      if (Array.isArray(mediaJson) && mediaJson.length > 0) {
        await Promise.all(
          mediaJson.map(async (media) => {
            // Use stored key, or fallback to URL for deletion
            const key = media.key || media.url;
            if (key) {
              await this.storageService.deleteFile(key);
            }
          }),
        );
      }
    }

    await this.prisma.post.delete({ where: { id } });
  }

  async incrementLikeCount(postId: string): Promise<void> {
    await this.prisma.post.update({
      where: { id: postId },
      data: { likeCount: { increment: 1 } },
    });
  }

  async decrementLikeCount(postId: string): Promise<void> {
    await this.prisma.post.update({
      where: { id: postId },
      data: { likeCount: { decrement: 1 } },
    });
  }

  async incrementCommentCount(postId: string): Promise<void> {
    await this.prisma.post.update({
      where: { id: postId },
      data: { commentCount: { increment: 1 } },
    });
  }

  async decrementCommentCount(postId: string): Promise<void> {
    await this.prisma.post.update({
      where: { id: postId },
      data: { commentCount: { decrement: 1 } },
    });
  }
}

