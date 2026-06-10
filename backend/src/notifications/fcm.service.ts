import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as admin from 'firebase-admin';
import {
  createNotificationPayload,
  FCMNotificationPayload,
} from './fcm-payloads';

@Injectable()
export class FCMService {
  private readonly logger = new Logger(FCMService.name);
  private firebaseApp: admin.app.App;

  constructor(private configService: ConfigService) {
    // Initialize Firebase Admin SDK
    const serviceAccount = this.configService.get<string>('FCM_SERVICE_ACCOUNT');
    const serviceAccountPath = this.configService.get<string>('FCM_SERVICE_ACCOUNT_PATH');
    
    if (serviceAccount) {
      try {
        const serviceAccountJson = typeof serviceAccount === 'string' 
          ? JSON.parse(serviceAccount) 
          : serviceAccount;
        this.firebaseApp = admin.initializeApp({
          credential: admin.credential.cert(serviceAccountJson),
        });
        this.logger.log('Firebase Admin SDK initialized');
      } catch (error) {
        this.logger.error('Failed to initialize Firebase Admin SDK:', error);
      }
    } else if (serviceAccountPath) {
      try {
        this.firebaseApp = admin.initializeApp({
          credential: admin.credential.cert(serviceAccountPath),
        });
        this.logger.log('Firebase Admin SDK initialized from file');
      } catch (error) {
        this.logger.error('Failed to initialize Firebase Admin SDK from file:', error);
      }
    } else {
      this.logger.warn('FCM_SERVICE_ACCOUNT not configured. Push notifications disabled.');
    }
  }

  /**
   * Create notification payload
   */
  createNotificationPayload(
    type: 'like' | 'comment' | 'follow' | 'message',
    data: {
      username: string;
      userId: string;
      avatarUrl?: string;
      postId?: string;
      commentId?: string;
      commentText?: string;
      conversationId?: string;
      messageText?: string;
    },
  ): FCMNotificationPayload {
    return createNotificationPayload(type, data);
  }

  /**
   * Send FCM notification to a single device token
   */
  async sendNotification(
    token: string,
    payload: FCMNotificationPayload,
  ): Promise<string> {
    if (!this.firebaseApp) {
      throw new Error('Firebase Admin SDK not initialized');
    }

    try {
      const message: admin.messaging.Message = {
        token: token,
        notification: payload.notification,
        data: payload.data,
        android: payload.android,
        apns: payload.apns,
      };

      const response = await admin.messaging().send(message);
      this.logger.debug(`FCM notification sent successfully: ${response}`);
      return response;
    } catch (error) {
      this.logger.error(`Error sending FCM notification: ${error}`);
      throw error;
    }
  }

  /**
   * Send FCM notification to multiple device tokens
   */
  async sendMulticast(
    tokens: string[],
    payload: FCMNotificationPayload,
  ): Promise<admin.messaging.BatchResponse> {
    if (!this.firebaseApp) {
      throw new Error('Firebase Admin SDK not initialized');
    }

    try {
      const message: admin.messaging.MulticastMessage = {
        tokens: tokens,
        notification: payload.notification,
        data: payload.data,
        android: payload.android,
        apns: payload.apns,
      };

      const response = await admin.messaging().sendEachForMulticast(message);
      this.logger.debug(
        `FCM multicast sent: ${response.successCount} successful, ${response.failureCount} failed`,
      );
      return response;
    } catch (error) {
      this.logger.error(`Error sending FCM multicast: ${error}`);
      throw error;
    }
  }
}

