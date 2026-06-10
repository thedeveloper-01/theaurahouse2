import { Module } from '@nestjs/common';
import { DeviceTokensController } from './device-tokens.controller';
import { DeviceTokensService } from './device-tokens.service';
import { FCMService } from './fcm.service';
import { NotificationQueueService } from './notification-queue.service';
import { PrismaModule } from '../prisma/prisma.module';
import { ConfigModule } from '@nestjs/config';

@Module({
  imports: [PrismaModule, ConfigModule],
  controllers: [DeviceTokensController],
  providers: [DeviceTokensService, FCMService, NotificationQueueService],
  exports: [DeviceTokensService, FCMService, NotificationQueueService],
})
export class NotificationsModule {}

