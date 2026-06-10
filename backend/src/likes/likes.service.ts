import {
  Injectable,
  NotFoundException,
  ConflictException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { Like } from '@prisma/client';
import { PostsService } from '../posts/posts.service';

@Injectable()
export class LikesService {
  constructor(
    private prisma: PrismaService,
    private postsService: PostsService,
  ) {}

  async toggleLike(postId: string, userId: string): Promise<{ liked: boolean }> {
    // Verify post exists
    await this.postsService.findOne(postId);

    const existingLike = await this.prisma.like.findUnique({
      where: {
        userId_postId: {
          userId,
          postId,
        },
      },
    });

    if (existingLike) {
      // Unlike
      await this.prisma.like.delete({
        where: {
          userId_postId: {
            userId,
            postId,
          },
        },
      });
      await this.postsService.decrementLikeCount(postId);
      return { liked: false };
    } else {
      // Like
      await this.prisma.like.create({
        data: { postId, userId },
      });
      await this.postsService.incrementLikeCount(postId);
      return { liked: true };
    }
  }

  async checkIfLiked(postId: string, userId: string): Promise<boolean> {
    const like = await this.prisma.like.findUnique({
      where: {
        userId_postId: {
          userId,
          postId,
        },
      },
    });
    return !!like;
  }

  async getLikesByPost(postId: string, page: number = 1, limit: number = 50) {
    const skip = (page - 1) * limit;
    const [likes, total] = await Promise.all([
      this.prisma.like.findMany({
        where: { postId },
        include: { user: true },
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
      }),
      this.prisma.like.count({ where: { postId } }),
    ]);

    return { likes, total };
  }

  async getLikesByUser(userId: string, page: number = 1, limit: number = 50) {
    const skip = (page - 1) * limit;
    const [likes, total] = await Promise.all([
      this.prisma.like.findMany({
        where: { userId },
        include: { post: true },
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
      }),
      this.prisma.like.count({ where: { userId } }),
    ]);

    return { likes, total };
  }
}

