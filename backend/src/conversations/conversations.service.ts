import {
  Injectable,
  NotFoundException,
  ForbiddenException,
  BadRequestException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateConversationDto } from './dto/create-conversation.dto';

@Injectable()
export class ConversationsService {
  constructor(private prisma: PrismaService) {}

  async findOrCreateConversation(
    currentUserId: string,
    otherUserId: string,
  ) {
    // Validate inputs
    if (!currentUserId || !otherUserId) {
      throw new BadRequestException(
        `Missing user IDs: currentUserId=${currentUserId}, otherUserId=${otherUserId}`,
      );
    }

    // Don't allow users to create conversations with themselves
    if (currentUserId === otherUserId) {
      throw new BadRequestException('Cannot create conversation with yourself');
    }

    // Ensure user1Id < user2Id for consistent ordering
    const [user1Id, user2Id] =
      currentUserId < otherUserId
        ? [currentUserId, otherUserId]
        : [otherUserId, currentUserId];

    // Validate that both IDs are still present after ordering
    if (!user1Id || !user2Id) {
      throw new BadRequestException(
        `Invalid user IDs after ordering: user1Id=${user1Id}, user2Id=${user2Id}`,
      );
    }

    // Check if conversation exists
    let conversation = await this.prisma.conversation.findUnique({
      where: {
        user1Id_user2Id: {
          user1Id,
          user2Id,
        },
      },
      include: {
        user1: {
          select: {
            id: true,
            username: true,
            displayName: true,
            avatarUrl: true,
          },
        },
        user2: {
          select: {
            id: true,
            username: true,
            displayName: true,
            avatarUrl: true,
          },
        },
        messages: {
          take: 1,
          orderBy: { createdAt: 'desc' },
        },
      },
    });

    // Create if doesn't exist
    if (!conversation) {
      conversation = await this.prisma.conversation.create({
        data: {
          user1Id,
          user2Id,
        },
        include: {
          user1: {
            select: {
              id: true,
              username: true,
              displayName: true,
              avatarUrl: true,
            },
          },
          user2: {
            select: {
              id: true,
              username: true,
              displayName: true,
              avatarUrl: true,
            },
          },
          messages: {
            take: 1,
            orderBy: { createdAt: 'desc' },
          },
        },
      });
    }

    // Return conversation with the other user's info
    const otherUser =
      conversation.user1Id === currentUserId
        ? conversation.user2
        : conversation.user1;

    return {
      id: conversation.id,
      userId: otherUser.id,
      username: otherUser.username,
      displayName: otherUser.displayName,
      avatarUrl: otherUser.avatarUrl,
      lastMessage: conversation.lastMessageText,
      lastMessageTime: conversation.lastMessageTime,
      unreadCount:
        conversation.user1Id === currentUserId
          ? conversation.user1UnreadCount
          : conversation.user2UnreadCount,
      createdAt: conversation.createdAt,
      updatedAt: conversation.updatedAt,
    };
  }

  async findAllConversations(userId: string) {
    const conversations = await this.prisma.conversation.findMany({
      where: {
        OR: [{ user1Id: userId }, { user2Id: userId }],
      },
      include: {
        user1: {
          select: {
            id: true,
            username: true,
            displayName: true,
            avatarUrl: true,
          },
        },
        user2: {
          select: {
            id: true,
            username: true,
            displayName: true,
            avatarUrl: true,
          },
        },
      },
      orderBy: {
        updatedAt: 'desc',
      },
    });

    return conversations.map((conv) => {
      const otherUser =
        conv.user1Id === userId ? conv.user2 : conv.user1;
      const unreadCount =
        conv.user1Id === userId
          ? conv.user1UnreadCount
          : conv.user2UnreadCount;

      return {
        id: conv.id,
        userId: otherUser.id,
        username: otherUser.username,
        displayName: otherUser.displayName,
        avatarUrl: otherUser.avatarUrl,
        lastMessage: conv.lastMessageText,
        lastMessageTime: conv.lastMessageTime,
        unreadCount,
        createdAt: conv.createdAt,
        updatedAt: conv.updatedAt,
      };
    });
  }

  async findOne(conversationId: string, userId: string) {
    const conversation = await this.prisma.conversation.findUnique({
      where: { id: conversationId },
      include: {
        user1: {
          select: {
            id: true,
            username: true,
            displayName: true,
            avatarUrl: true,
          },
        },
        user2: {
          select: {
            id: true,
            username: true,
            displayName: true,
            avatarUrl: true,
          },
        },
      },
    });

    if (!conversation) {
      throw new NotFoundException('Conversation not found');
    }

    if (conversation.user1Id !== userId && conversation.user2Id !== userId) {
      throw new ForbiddenException('Access denied');
    }

    const otherUser =
      conversation.user1Id === userId
        ? conversation.user2
        : conversation.user1;

    return {
      id: conversation.id,
      userId: otherUser.id,
      username: otherUser.username,
      displayName: otherUser.displayName,
      avatarUrl: otherUser.avatarUrl,
      lastMessage: conversation.lastMessageText,
      lastMessageTime: conversation.lastMessageTime,
      unreadCount:
        conversation.user1Id === userId
          ? conversation.user1UnreadCount
          : conversation.user2UnreadCount,
      createdAt: conversation.createdAt,
      updatedAt: conversation.updatedAt,
    };
  }

  async markAsRead(conversationId: string, userId: string) {
    const conversation = await this.prisma.conversation.findUnique({
      where: { id: conversationId },
    });

    if (!conversation) {
      throw new NotFoundException('Conversation not found');
    }

    if (conversation.user1Id !== userId && conversation.user2Id !== userId) {
      throw new ForbiddenException('Access denied');
    }

    // Mark all messages as read
    await this.prisma.message.updateMany({
      where: {
        conversationId,
        receiverId: userId,
        isRead: false,
      },
      data: {
        isRead: true,
      },
    });

    // Reset unread count
    if (conversation.user1Id === userId) {
      await this.prisma.conversation.update({
        where: { id: conversationId },
        data: { user1UnreadCount: 0 },
      });
    } else {
      await this.prisma.conversation.update({
        where: { id: conversationId },
        data: { user2UnreadCount: 0 },
      });
    }

    return { success: true };
  }
}
