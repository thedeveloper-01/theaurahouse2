import {
  Injectable,
  NotFoundException,
  ForbiddenException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateMessageDto } from './dto/create-message.dto';

@Injectable()
export class MessagesService {
  constructor(private prisma: PrismaService) {}

  async create(
    conversationId: string,
    createMessageDto: CreateMessageDto,
    senderId: string,
  ) {
    const { text } = createMessageDto;

    // Verify conversation exists and user is part of it
    const conversation = await this.prisma.conversation.findUnique({
      where: { id: conversationId },
    });

    if (!conversation) {
      throw new NotFoundException('Conversation not found');
    }

    if (
      conversation.user1Id !== senderId &&
      conversation.user2Id !== senderId
    ) {
      throw new ForbiddenException('Access denied');
    }

    const receiverId =
      conversation.user1Id === senderId
        ? conversation.user2Id
        : conversation.user1Id;

    // Create message
    const message = await this.prisma.message.create({
      data: {
        conversationId,
        senderId,
        receiverId,
        text,
      },
      include: {
        sender: {
          select: {
            id: true,
            username: true,
            displayName: true,
            avatarUrl: true,
          },
        },
        receiver: {
          select: {
            id: true,
            username: true,
            displayName: true,
            avatarUrl: true,
          },
        },
      },
    });

    // Update conversation
    const updateData: any = {
      lastMessageText: text,
      lastMessageTime: message.createdAt,
      updatedAt: new Date(),
    };

    // Increment unread count for receiver
    if (conversation.user1Id === receiverId) {
      updateData.user1UnreadCount = { increment: 1 };
    } else {
      updateData.user2UnreadCount = { increment: 1 };
    }

    await this.prisma.conversation.update({
      where: { id: conversationId },
      data: updateData,
    });

    return message;
  }

  async findAll(conversationId: string, userId: string, page = 1, limit = 50) {
    // Verify conversation exists and user is part of it
    const conversation = await this.prisma.conversation.findUnique({
      where: { id: conversationId },
    });

    if (!conversation) {
      throw new NotFoundException('Conversation not found');
    }

    if (conversation.user1Id !== userId && conversation.user2Id !== userId) {
      throw new ForbiddenException('Access denied');
    }

    const skip = (page - 1) * limit;

    const [messages, total] = await Promise.all([
      this.prisma.message.findMany({
        where: { conversationId },
        include: {
          sender: {
            select: {
              id: true,
              username: true,
              displayName: true,
              avatarUrl: true,
            },
          },
        },
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
      }),
      this.prisma.message.count({
        where: { conversationId },
      }),
    ]);

    return {
      messages: messages.reverse(), // Return in chronological order
      total,
      page,
      limit,
      hasMore: skip + messages.length < total,
    };
  }
}
