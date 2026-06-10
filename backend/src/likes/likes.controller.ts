import {
  Controller,
  Get,
  Post,
  Param,
  UseGuards,
  Request,
  Query,
} from '@nestjs/common';
import { LikesService } from './likes.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@Controller('likes')
export class LikesController {
  constructor(private readonly likesService: LikesService) {}

  @Post('post/:postId')
  @UseGuards(JwtAuthGuard)
  async toggleLike(@Request() req, @Param('postId') postId: string) {
    return this.likesService.toggleLike(postId, req.user.userId);
  }

  @Get('post/:postId/check')
  @UseGuards(JwtAuthGuard)
  async checkIfLiked(@Request() req, @Param('postId') postId: string) {
    const liked = await this.likesService.checkIfLiked(postId, req.user.userId);
    return { liked };
  }

  @Get('post/:postId')
  async getLikesByPost(
    @Param('postId') postId: string,
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    return this.likesService.getLikesByPost(
      postId,
      page ? parseInt(page, 10) : 1,
      limit ? parseInt(limit, 10) : 50,
    );
  }

  @Get('user/:userId')
  async getLikesByUser(
    @Param('userId') userId: string,
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    return this.likesService.getLikesByUser(
      userId,
      page ? parseInt(page, 10) : 1,
      limit ? parseInt(limit, 10) : 50,
    );
  }
}

