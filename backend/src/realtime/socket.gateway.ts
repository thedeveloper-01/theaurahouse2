import {
  WebSocketGateway,
  WebSocketServer,
  SubscribeMessage,
  OnGatewayConnection,
  OnGatewayDisconnect,
  ConnectedSocket,
  MessageBody,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { JwtService } from '@nestjs/jwt';
import { Injectable, Logger, UseGuards } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { WsJwtGuard } from './guards/ws-jwt.guard';
import { NotificationQueueService } from '../notifications/notification-queue.service';

interface AuthenticatedSocket extends Socket {
  userId?: string;
  user?: {
    id: string;
    username: string;
    displayName?: string;
    avatarUrl?: string;
  };
}

@Injectable()
@WebSocketGateway({
  cors: {
    origin: '*', // Configure appropriately for production
    credentials: true,
  },
  namespace: '/',
})
export class SocketGateway
  implements OnGatewayConnection, OnGatewayDisconnect
{
  @WebSocketServer()
  server: Server;

  private readonly logger = new Logger(SocketGateway.name);
  private readonly connectedUsers = new Map<string, Set<string>>(); // userId -> Set of socketIds

  constructor(
    private readonly jwtService: JwtService,
    private readonly prisma: PrismaService,
    private readonly notificationQueue: NotificationQueueService,
  ) {}

  async handleConnection(client: AuthenticatedSocket) {
    try {
      const token = client.handshake.auth?.token || client.handshake.headers?.authorization?.replace('Bearer ', '');

      if (!token) {
        this.logger.warn(`Connection rejected: No token provided for socket ${client.id}`);
        client.emit('error', {
          code: 'AUTH_ERROR',
          message: 'Authentication token required',
          timestamp: new Date().toISOString(),
        });
        client.disconnect();
        return;
      }

      // Verify JWT token
      const payload = await this.jwtService.verifyAsync(token);
      const userId = payload.sub;

      // Get user from database
      const user = await this.prisma.user.findUnique({
        where: { id: userId },
        select: {
          id: true,
          username: true,
          displayName: true,
          avatarUrl: true,
        },
      });

      if (!user) {
        this.logger.warn(`Connection rejected: User not found for socket ${client.id}`);
        client.emit('error', {
          code: 'AUTH_ERROR',
          message: 'User not found',
          timestamp: new Date().toISOString(),
        });
        client.disconnect();
        return;
      }

      // Attach user info to socket
      client.userId = userId;
      client.user = user;

      // Track connected user
      if (!this.connectedUsers.has(userId)) {
        this.connectedUsers.set(userId, new Set());
      }
      this.connectedUsers.get(userId)!.add(client.id);

      // Join user's personal room
      await client.join(`user:${userId}`);

      this.logger.log(`User ${user.username} connected (socket: ${client.id})`);

      // Emit connection success (using 'authenticated' instead of reserved 'connect' event)
      client.emit('authenticated', {
        status: 'connected',
        userId: userId,
        socketId: client.id,
      });

      // Broadcast presence online
      client.broadcast.emit('presence:online', {
        userId: userId,
        user: user,
        status: 'online',
        lastSeen: new Date().toISOString(),
      });
    } catch (error) {
      this.logger.error(`Connection error for socket ${client.id}:`, error);
      client.emit('error', {
        code: 'AUTH_ERROR',
        message: 'Invalid or expired token',
        timestamp: new Date().toISOString(),
      });
      client.disconnect();
    }
  }

  async handleDisconnect(client: AuthenticatedSocket) {
    if (client.userId) {
      // Remove socket from connected users
      const userSockets = this.connectedUsers.get(client.userId);
      if (userSockets) {
        userSockets.delete(client.id);
        if (userSockets.size === 0) {
          this.connectedUsers.delete(client.userId);
        }
      }

      this.logger.log(`User ${client.userId} disconnected (socket: ${client.id})`);

      // Broadcast presence offline
      if (client.user) {
        this.server.emit('presence:offline', {
          userId: client.userId,
          status: 'offline',
          lastSeen: new Date().toISOString(),
        });
      }
    }
  }

  @UseGuards(WsJwtGuard)
  @SubscribeMessage('post:like')
  async handlePostLike(
    @ConnectedSocket() client: AuthenticatedSocket,
    @MessageBody() data: { postId: string },
  ) {
    try {
      const { postId } = data;
      const userId = client.userId!;

      if (!postId) {
        client.emit('error', {
          code: 'VALIDATION_ERROR',
          message: 'postId is required',
          timestamp: new Date().toISOString(),
        });
        return;
      }

      // Check if post exists
      const post = await this.prisma.post.findUnique({
        where: { id: postId },
        include: { user: true },
      });

      if (!post) {
        client.emit('error', {
          code: 'NOT_FOUND',
          message: 'Post not found',
          timestamp: new Date().toISOString(),
        });
        return;
      }

      // Check if like already exists
      const existingLike = await this.prisma.like.findUnique({
        where: {
          userId_postId: {
            userId: userId,
            postId: postId,
          },
        },
      });

      let isLiked: boolean;
      let likeCount: number;

      if (existingLike) {
        // Unlike: Delete the like
        await this.prisma.like.delete({
          where: {
            userId_postId: {
              userId: userId,
              postId: postId,
            },
          },
        });

        // Update post like count
        const updatedPost = await this.prisma.post.update({
          where: { id: postId },
          data: {
            likeCount: {
              decrement: 1,
            },
          },
        });

        isLiked = false;
        likeCount = updatedPost.likeCount;

        // Emit unlike event
        this.server.emit('post:unliked', {
          postId: postId,
          userId: userId,
          isLiked: false,
          likeCount: likeCount,
          timestamp: new Date().toISOString(),
        });
      } else {
        // Like: Create the like
        await this.prisma.like.create({
          data: {
            userId: userId,
            postId: postId,
          },
        });

        // Update post like count
        const updatedPost = await this.prisma.post.update({
          where: { id: postId },
          data: {
            likeCount: {
              increment: 1,
            },
          },
        });

        isLiked = true;
        likeCount = updatedPost.likeCount;

        // Get user info for notification
        const user = await this.prisma.user.findUnique({
          where: { id: userId },
          select: {
            id: true,
            username: true,
            displayName: true,
            avatarUrl: true,
          },
        });

        // Emit like event to all clients
        this.server.emit('post:liked', {
          postId: postId,
          userId: userId,
          user: user,
          isLiked: true,
          likeCount: likeCount,
          timestamp: new Date().toISOString(),
        });

        // Push notification job to queue (only if not own post)
        if (post.userId !== userId) {
          await this.notificationQueue.addNotificationJob({
            type: 'like',
            userId: post.userId, // Post owner receives notification
            payload: {
              postId: postId,
              userId: userId,
              user: user,
            },
          });
        }
      }

      this.logger.log(`Post ${postId} ${isLiked ? 'liked' : 'unliked'} by user ${userId}`);
    } catch (error) {
      this.logger.error(`Error handling post:like for socket ${client.id}:`, error);
      client.emit('error', {
        code: 'SERVER_ERROR',
        message: 'Failed to process like',
        timestamp: new Date().toISOString(),
      });
    }
  }

  @UseGuards(WsJwtGuard)
  @SubscribeMessage('post:typing:start')
  async handlePostTypingStart(
    @ConnectedSocket() client: AuthenticatedSocket,
    @MessageBody() data: { postId: string },
  ) {
    const { postId } = data;
    const userId = client.userId!;

    // Broadcast typing indicator to room (excluding sender)
    client.to(`post:${postId}`).emit('typing:start', {
      postId: postId,
      userId: userId,
      user: client.user,
      isTyping: true,
    });
  }

  @UseGuards(WsJwtGuard)
  @SubscribeMessage('post:typing:stop')
  async handlePostTypingStop(
    @ConnectedSocket() client: AuthenticatedSocket,
    @MessageBody() data: { postId: string },
  ) {
    const { postId } = data;
    const userId = client.userId!;

    // Broadcast typing stop to room
    client.to(`post:${postId}`).emit('typing:stop', {
      postId: postId,
      userId: userId,
      isTyping: false,
    });
  }

  @UseGuards(WsJwtGuard)
  @SubscribeMessage('room:join')
  async handleRoomJoin(
    @ConnectedSocket() client: AuthenticatedSocket,
    @MessageBody() data: { room: string },
  ) {
    const { room } = data;
    await client.join(room);
    this.logger.log(`Socket ${client.id} joined room ${room}`);
  }

  @UseGuards(WsJwtGuard)
  @SubscribeMessage('room:leave')
  async handleRoomLeave(
    @ConnectedSocket() client: AuthenticatedSocket,
    @MessageBody() data: { room: string },
  ) {
    const { room } = data;
    await client.leave(room);
    this.logger.log(`Socket ${client.id} left room ${room}`);
  }

  // Helper method to emit post:created event
  emitPostCreated(post: any) {
    this.server.emit('post:created', { post });
  }

  // Helper method to emit comment:created event
  emitCommentCreated(comment: any, postId: string, commentCount: number) {
    this.server.emit('comment:created', {
      comment,
      postId,
      commentCount,
    });
  }

  // Helper method to emit notification
  emitNotification(userId: string, notification: any) {
    this.server.to(`user:${userId}`).emit('notification:new', {
      notification,
    });
  }

  // Real-time messaging events
  @UseGuards(WsJwtGuard)
  @SubscribeMessage('message:send')
  async handleMessageSend(
    @ConnectedSocket() client: AuthenticatedSocket,
    @MessageBody()
    data: {
      conversationId: string;
      text: string;
    },
  ) {
    try {
      const { conversationId, text } = data;
      const senderId = client.userId!;

      if (!conversationId || !text) {
        client.emit('error', {
          code: 'VALIDATION_ERROR',
          message: 'conversationId and text are required',
          timestamp: new Date().toISOString(),
        });
        return;
      }

      // Verify conversation exists
      const conversation = await this.prisma.conversation.findUnique({
        where: { id: conversationId },
      });

      if (!conversation) {
        client.emit('error', {
          code: 'NOT_FOUND',
          message: 'Conversation not found',
          timestamp: new Date().toISOString(),
        });
        return;
      }

      if (
        conversation.user1Id !== senderId &&
        conversation.user2Id !== senderId
      ) {
        client.emit('error', {
          code: 'FORBIDDEN',
          message: 'Access denied',
          timestamp: new Date().toISOString(),
        });
        return;
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
        },
      });

      // Update conversation
      const updateData: any = {
        lastMessageText: text,
        lastMessageTime: message.createdAt,
        updatedAt: new Date(),
      };

      if (conversation.user1Id === receiverId) {
        updateData.user1UnreadCount = { increment: 1 };
      } else {
        updateData.user2UnreadCount = { increment: 1 };
      }

      await this.prisma.conversation.update({
        where: { id: conversationId },
        data: updateData,
      });

      // Emit to both users
      this.server.to(`user:${senderId}`).emit('message:sent', {
        message,
        conversationId,
      });

      this.server.to(`user:${receiverId}`).emit('message:received', {
        message,
        conversationId,
      });

      // Queue notification for receiver
      await this.notificationQueue.addNotificationJob({
        userId: receiverId,
        type: 'message',
        payload: {
          senderId: senderId,
          conversationId: conversationId,
          messageId: message.id,
          text: text,
          senderUsername: message.sender.username,
          senderDisplayName: message.sender.displayName,
          senderAvatarUrl: message.sender.avatarUrl,
        },
      });

      // Also emit conversation update
      const updatedConversation = await this.prisma.conversation.findUnique({
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

      if (updatedConversation) {
        const senderConv = {
          id: updatedConversation.id,
          userId:
            updatedConversation.user1Id === senderId
              ? updatedConversation.user2.id
              : updatedConversation.user1.id,
          username:
            updatedConversation.user1Id === senderId
              ? updatedConversation.user2.username
              : updatedConversation.user1.username,
          displayName:
            updatedConversation.user1Id === senderId
              ? updatedConversation.user2.displayName
              : updatedConversation.user1.displayName,
          avatarUrl:
            updatedConversation.user1Id === senderId
              ? updatedConversation.user2.avatarUrl
              : updatedConversation.user1.avatarUrl,
          lastMessage: updatedConversation.lastMessageText,
          lastMessageTime: updatedConversation.lastMessageTime,
          unreadCount:
            updatedConversation.user1Id === senderId
              ? updatedConversation.user1UnreadCount
              : updatedConversation.user2UnreadCount,
          createdAt: updatedConversation.createdAt,
          updatedAt: updatedConversation.updatedAt,
        };

        const receiverConv = {
          id: updatedConversation.id,
          userId:
            updatedConversation.user1Id === receiverId
              ? updatedConversation.user2.id
              : updatedConversation.user1.id,
          username:
            updatedConversation.user1Id === receiverId
              ? updatedConversation.user2.username
              : updatedConversation.user1.username,
          displayName:
            updatedConversation.user1Id === receiverId
              ? updatedConversation.user2.displayName
              : updatedConversation.user1.displayName,
          avatarUrl:
            updatedConversation.user1Id === receiverId
              ? updatedConversation.user2.avatarUrl
              : updatedConversation.user1.avatarUrl,
          lastMessage: updatedConversation.lastMessageText,
          lastMessageTime: updatedConversation.lastMessageTime,
          unreadCount:
            updatedConversation.user1Id === receiverId
              ? updatedConversation.user1UnreadCount
              : updatedConversation.user2UnreadCount,
          createdAt: updatedConversation.createdAt,
          updatedAt: updatedConversation.updatedAt,
        };

        this.server.to(`user:${senderId}`).emit('conversation:updated', {
          conversation: senderConv,
        });

        this.server.to(`user:${receiverId}`).emit('conversation:updated', {
          conversation: receiverConv,
        });
      }

      this.logger.log(
        `Message sent from ${senderId} to ${receiverId} in conversation ${conversationId}`,
      );
    } catch (error) {
      this.logger.error(
        `Error handling message:send for socket ${client.id}:`,
        error,
      );
      client.emit('error', {
        code: 'SERVER_ERROR',
        message: 'Failed to send message',
        timestamp: new Date().toISOString(),
      });
    }
  }

  @UseGuards(WsJwtGuard)
  @SubscribeMessage('conversation:join')
  async handleConversationJoin(
    @ConnectedSocket() client: AuthenticatedSocket,
    @MessageBody() data: { conversationId: string },
  ) {
    const { conversationId } = data;
    const userId = client.userId!;

    // Verify user is part of conversation
    const conversation = await this.prisma.conversation.findUnique({
      where: { id: conversationId },
    });

    if (
      conversation &&
      (conversation.user1Id === userId || conversation.user2Id === userId)
    ) {
      await client.join(`conversation:${conversationId}`);
      this.logger.log(
        `User ${userId} joined conversation ${conversationId}`,
      );
    }
  }

  @UseGuards(WsJwtGuard)
  @SubscribeMessage('conversation:leave')
  async handleConversationLeave(
    @ConnectedSocket() client: AuthenticatedSocket,
    @MessageBody() data: { conversationId: string },
  ) {
    const { conversationId } = data;
    await client.leave(`conversation:${conversationId}`);
    this.logger.log(
      `User ${client.userId} left conversation ${conversationId}`,
    );
  }

  @UseGuards(WsJwtGuard)
  @SubscribeMessage('typing:start')
  async handleTypingStart(
    @ConnectedSocket() client: AuthenticatedSocket,
    @MessageBody() data: { conversationId: string },
  ) {
    const { conversationId } = data;
    const userId = client.userId!;

    // Broadcast typing indicator to conversation room (excluding sender)
    client.to(`conversation:${conversationId}`).emit('typing:start', {
      conversationId,
      userId,
      user: client.user,
      isTyping: true,
    });
  }

  @UseGuards(WsJwtGuard)
  @SubscribeMessage('typing:stop')
  async handleTypingStop(
    @ConnectedSocket() client: AuthenticatedSocket,
    @MessageBody() data: { conversationId: string },
  ) {
    const { conversationId } = data;
    const userId = client.userId!;

    // Broadcast typing stop to conversation room
    client.to(`conversation:${conversationId}`).emit('typing:stop', {
      conversationId,
      userId,
      isTyping: false,
    });
  }
}

