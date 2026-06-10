import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  Query,
  UseGuards,
  Request,
  BadRequestException,
} from '@nestjs/common';
import { MessagesService } from './messages.service';
import { CreateMessageDto } from './dto/create-message.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@Controller('conversations/:conversationId/messages')
@UseGuards(JwtAuthGuard)
export class MessagesController {
  constructor(private readonly messagesService: MessagesService) {}

  @Post()
  async create(
    @Request() req,
    @Param('conversationId') conversationId: string,
    @Body() createMessageDto: CreateMessageDto,
  ) {
    // Get current user ID - support both id and userId for compatibility
    const currentUserId = req.user?.id || req.user?.userId;

    if (!currentUserId) {
      throw new BadRequestException(
        'User ID not found in request. Authentication may have failed.',
      );
    }

    if (!conversationId) {
      throw new BadRequestException('Conversation ID is required');
    }

    if (!createMessageDto.text || createMessageDto.text.trim().length === 0) {
      throw new BadRequestException('Message text is required');
    }

    return await this.messagesService.create(
      conversationId,
      createMessageDto,
      currentUserId,
    );
  }

  @Get()
  async findAll(
    @Request() req,
    @Param('conversationId') conversationId: string,
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    // Get current user ID - support both id and userId for compatibility
    const currentUserId = req.user?.id || req.user?.userId;

    if (!currentUserId) {
      throw new BadRequestException(
        'User ID not found in request. Authentication may have failed.',
      );
    }

    return await this.messagesService.findAll(
      conversationId,
      currentUserId,
      page ? parseInt(page, 10) : 1,
      limit ? parseInt(limit, 10) : 50,
    );
  }
}
