import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { Comment } from '@prisma/client';
import { CreateCommentDto } from './dto/create-comment.dto';
import { UpdateCommentDto } from './dto/update-comment.dto';
import { PostsService } from '../posts/posts.service';

@Injectable()
export class CommentsService {
  constructor(
    private prisma: PrismaService,
    private postsService: PostsService,
  ) {}

  async create(
    postId: string,
    userId: string,
    createCommentDto: CreateCommentDto,
  ): Promise<Comment> {
    // Verify post exists
    await this.postsService.findOne(postId);

    const savedComment = await this.prisma.comment.create({
      data: {
        postId,
        userId,
        text: createCommentDto.text,
        parentCommentId: createCommentDto.parentCommentId,
      },
    });

    // Increment comment count
    await this.postsService.incrementCommentCount(postId);

    return savedComment;
  }

  async findByPost(postId: string, page: number = 1, limit: number = 20) {
    const skip = (page - 1) * limit;
    const [comments, total] = await Promise.all([
      this.prisma.comment.findMany({
        where: { postId, parentCommentId: null }, // Only top-level comments
        include: { user: true },
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
      }),
      this.prisma.comment.count({
        where: { postId, parentCommentId: null },
      }),
    ]);

    // Load replies for each comment
    const commentsWithReplies = await Promise.all(
      comments.map(async (comment) => {
        const replies = await this.prisma.comment.findMany({
          where: { parentCommentId: comment.id },
          include: { user: true },
          orderBy: { createdAt: 'asc' },
          take: 3, // Limit replies preview
        });
        return { ...comment, replies };
      }),
    );

    return { comments: commentsWithReplies, total };
  }

  async findOne(id: string): Promise<Comment> {
    const comment = await this.prisma.comment.findUnique({
      where: { id },
      include: { user: true, post: true },
    });

    if (!comment) {
      throw new NotFoundException('Comment not found');
    }

    return comment;
  }

  async update(
    id: string,
    userId: string,
    updateCommentDto: UpdateCommentDto,
  ): Promise<Comment> {
    const comment = await this.findOne(id);

    if (comment.userId !== userId) {
      throw new NotFoundException('Comment not found'); // Don't reveal existence
    }

    return this.prisma.comment.update({
      where: { id },
      data: updateCommentDto,
      include: { user: true },
    });
  }

  async remove(id: string, userId: string): Promise<void> {
    const comment = await this.findOne(id);

    if (comment.userId !== userId) {
      throw new NotFoundException('Comment not found');
    }

    await this.prisma.comment.delete({ where: { id } });

    // Decrement comment count
    await this.postsService.decrementCommentCount(comment.postId);
  }
}

