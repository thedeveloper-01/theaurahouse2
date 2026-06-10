import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  UseGuards,
  Request,
  BadRequestException,
} from '@nestjs/common';
import { ConversationsService } from './conversations.service';
import { CreateConversationDto } from './dto/create-conversation.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@Controller('conversations')
@UseGuards(JwtAuthGuard)
export class ConversationsController {
  constructor(private readonly conversationsService: ConversationsService) {}

  @Get()
  async findAll(@Request() req) {
    return await this.conversationsService.findAllConversations(req.user.id);
  }

  @Post()
  async create(
    @Request() req,
    @Body() createConversationDto: CreateConversationDto,
  ) {
    // Get current user ID - support both id and userId for compatibility
    const currentUserId = req.user?.id || req.user?.userId;

    if (!currentUserId) {
      throw new BadRequestException(
        'User ID not found in request. Authentication may have failed.',
      );
    }

    if (!createConversationDto.userId) {
      throw new BadRequestException('Other user ID is required in request body');
    }

    return await this.conversationsService.findOrCreateConversation(
      currentUserId,
      createConversationDto.userId,
    );
  }

  @Get(':id')
  async findOne(@Request() req, @Param('id') id: string) {
    return await this.conversationsService.findOne(id, req.user.id);
  }

  @Post(':id/read')
  async markAsRead(@Request() req, @Param('id') id: string) {
    return await this.conversationsService.markAsRead(id, req.user.id);
  }
}
