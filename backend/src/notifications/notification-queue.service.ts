import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { FCMService } from './fcm.service';
import { DeviceTokensService } from './device-tokens.service';

interface NotificationJob {
  type: 'like' | 'comment' | 'follow' | 'message';
  userId: string; // User who receives the notification
  payload: any;
}

@Injectable()
export class NotificationQueueService {
  private readonly logger = new Logger(NotificationQueueService.name);
  private readonly queue: NotificationJob[] = [];
  private processing = false;

  constructor(
    private readonly prisma: PrismaService,
    private readonly fcmService: FCMService,
    private readonly deviceTokensService: DeviceTokensService,
  ) {
    // Start processing queue
    this.processQueue();
  }

  /**
   * Add notification job to queue
   */
  async addNotificationJob(job: NotificationJob) {
    this.queue.push(job);
    this.logger.debug(`Added notification job to queue: ${job.type} for user ${job.userId}`);
    
    // Trigger processing if not already processing
    if (!this.processing) {
      this.processQueue();
    }
  }

  /**
   * Process notification queue
   */
  private async processQueue() {
    if (this.processing || this.queue.length === 0) {
      return;
    }

    this.processing = true;

    while (this.queue.length > 0) {
      const job = this.queue.shift();
      if (!job) break;

      try {
        await this.processNotificationJob(job);
      } catch (error) {
        this.logger.error(`Error processing notification job: ${error}`);
        // Optionally: retry logic or dead letter queue
      }
    }

    this.processing = false;
  }

  /**
   * Process a single notification job
   */
  private async processNotificationJob(job: NotificationJob) {
    // Create notification in database
    const notification = await this.prisma.notification.create({
      data: {
        userId: job.userId,
        type: job.type,
        payload: job.payload as any,
        isRead: false,
      },
    });

    // Get user's device tokens
    const tokens = await this.deviceTokensService.getActiveTokensForUser(job.userId);

    if (tokens.length === 0) {
      this.logger.debug(`No active device tokens for user ${job.userId}`);
      return;
    }

    // Get user info for notification (sender)
    const userId = job.payload.userId || 
                   job.payload.followerId || 
                   job.payload.senderId;
    
    if (!userId) {
      this.logger.warn(`No user ID found in notification payload`);
      return;
    }

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
      this.logger.warn(`User not found for notification: ${userId}`);
      return;
    }

    // Send FCM notifications
    const payload = this.fcmService.createNotificationPayload(job.type, {
      username: user.displayName || user.username,
      userId: user.id,
      avatarUrl: user.avatarUrl || undefined,
      postId: job.payload.postId,
      commentId: job.payload.commentId,
      commentText: job.payload.text || job.payload.commentText,
      conversationId: job.payload.conversationId,
      messageText: job.payload.text || job.payload.messageText,
    });

    // Send to all device tokens
    const results = await Promise.allSettled(
      tokens.map((token) => this.fcmService.sendNotification(token, payload)),
    );

    // Log results
    const successful = results.filter((r) => r.status === 'fulfilled').length;
    const failed = results.filter((r) => r.status === 'rejected').length;

    this.logger.log(
      `Notification sent: ${successful} successful, ${failed} failed for user ${job.userId}`,
    );

    // Deactivate invalid tokens
    results.forEach((result, index) => {
      if (result.status === 'rejected') {
        const error = result.reason;
        // FCM returns specific error codes for invalid tokens
        if (error?.code === 'messaging/invalid-registration-token' ||
            error?.code === 'messaging/registration-token-not-registered') {
          this.deviceTokensService.deleteToken(job.userId, tokens[index]).catch(
            (err) => this.logger.error(`Error deleting invalid token: ${err}`),
          );
        }
      }
    });
  }
}

