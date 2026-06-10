import { CanActivate, ExecutionContext, Injectable } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { WsException } from '@nestjs/websockets';

@Injectable()
export class WsJwtGuard implements CanActivate {
  constructor(private jwtService: JwtService) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const client = context.switchToWs().getClient();
    const token = client.handshake.auth?.token || 
                  client.handshake.headers?.authorization?.replace('Bearer ', '');

    if (!token) {
      throw new WsException('Authentication token required');
    }

    try {
      const payload = await this.jwtService.verifyAsync(token);
      const userId = payload.sub;

      // Verify user exists
      // This could be optimized by caching user info on socket connection
      client.userId = userId;
      return true;
    } catch (error) {
      throw new WsException('Invalid or expired token');
    }
  }
}

