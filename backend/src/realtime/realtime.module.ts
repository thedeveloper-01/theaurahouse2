import { Module } from '@nestjs/common';
import { SocketGateway } from './socket.gateway';
import { WsJwtGuard } from './guards/ws-jwt.guard';
import { AuthModule } from '../auth/auth.module';
import { PrismaModule } from '../prisma/prisma.module';
import { NotificationsModule } from '../notifications/notifications.module';

@Module({
  imports: [
    AuthModule, // Provides JwtModule with proper configuration
    PrismaModule,
    NotificationsModule,
  ],
  providers: [SocketGateway, WsJwtGuard],
  exports: [SocketGateway],
})
export class RealtimeModule {}

