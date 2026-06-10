import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { RegisterDeviceTokenDto } from './dto/device-token.dto';

@Injectable()
export class DeviceTokensService {
  private readonly logger = new Logger(DeviceTokensService.name);

  constructor(private readonly prisma: PrismaService) {}

  /**
   * Register or update device token with automatic deduplication
   */
  async registerToken(userId: string, dto: RegisterDeviceTokenDto) {
    const { token, platform, deviceId, appVersion } = dto;

    try {
      // Rule 1: Check if same device_id + platform exists for this user
      if (deviceId) {
        const existing = await this.prisma.deviceToken.findFirst({
          where: {
            userId: userId,
            deviceId: deviceId,
            platform: platform,
            isActive: true,
          },
        });

        if (existing) {
          // Update existing token
          const updated = await this.prisma.deviceToken.update({
            where: { id: existing.id },
            data: {
              token: token,
              appVersion: appVersion || existing.appVersion,
              lastUsedAt: new Date(),
              isActive: true,
            },
          });

          this.logger.log(`Updated device token for user ${userId}, device ${deviceId}`);
          return { success: true, action: 'updated', tokenId: updated.id };
        }
      }

      // Rule 2: Deactivate same token if used by different user
      await this.prisma.deviceToken.updateMany({
        where: {
          token: token,
          userId: { not: userId },
          isActive: true,
        },
        data: {
          isActive: false,
        },
      });

      // Rule 3: Check if same token exists for this user
      const sameToken = await this.prisma.deviceToken.findFirst({
        where: {
          userId: userId,
          token: token,
        },
      });

      if (sameToken) {
        // Update existing token
        const updated = await this.prisma.deviceToken.update({
          where: { id: sameToken.id },
          data: {
            platform: platform,
            deviceId: deviceId || sameToken.deviceId,
            appVersion: appVersion || sameToken.appVersion,
            lastUsedAt: new Date(),
            isActive: true,
          },
        });

        this.logger.log(`Updated existing token for user ${userId}`);
        return { success: true, action: 'updated', tokenId: updated.id };
      }

      // Rule 4: Check active token count and deactivate oldest if >= 10
      const activeCount = await this.prisma.deviceToken.count({
        where: {
          userId: userId,
          isActive: true,
        },
      });

      if (activeCount >= 10) {
        // Find and deactivate oldest token
        const oldestToken = await this.prisma.deviceToken.findFirst({
          where: {
            userId: userId,
            isActive: true,
          },
          orderBy: {
            lastUsedAt: 'asc',
          },
        });

        if (oldestToken) {
          await this.prisma.deviceToken.update({
            where: { id: oldestToken.id },
            data: { isActive: false },
          });
        }
      }

      // Insert new token
      const newToken = await this.prisma.deviceToken.create({
        data: {
          userId: userId,
          token: token,
          platform: platform,
          deviceId: deviceId,
          appVersion: appVersion,
        },
      });

      this.logger.log(`Registered new device token for user ${userId}`);
      return { success: true, action: 'created', tokenId: newToken.id };
    } catch (error) {
      this.logger.error(`Error registering device token: ${error}`);
      throw error;
    }
  }

  /**
   * Delete (deactivate) device token
   */
  async deleteToken(userId: string, token: string) {
    try {
      const result = await this.prisma.deviceToken.updateMany({
        where: {
          userId: userId,
          token: token,
          isActive: true,
        },
        data: {
          isActive: false,
        },
      });

      this.logger.log(`Deleted device token for user ${userId}`);
      return { success: true, deleted: result.count > 0 };
    } catch (error) {
      this.logger.error(`Error deleting device token: ${error}`);
      throw error;
    }
  }

  /**
   * Get all active tokens for a user
   */
  async getUserTokens(userId: string) {
    try {
      const tokens = await this.prisma.deviceToken.findMany({
        where: {
          userId: userId,
          isActive: true,
        },
        select: {
          id: true,
          token: true,
          platform: true,
          deviceId: true,
          createdAt: true,
          lastUsedAt: true,
        },
        orderBy: {
          lastUsedAt: 'desc',
        },
      });

      return tokens;
    } catch (error) {
      this.logger.error(`Error getting user tokens: ${error}`);
      throw error;
    }
  }

  /**
   * Get all active tokens for a user (for sending notifications)
   */
  async getActiveTokensForUser(userId: string): Promise<string[]> {
    try {
      const tokens = await this.prisma.deviceToken.findMany({
        where: {
          userId: userId,
          isActive: true,
        },
        select: {
          token: true,
        },
      });

      return tokens.map((t) => t.token);
    } catch (error) {
      this.logger.error(`Error getting active tokens: ${error}`);
      return [];
    }
  }
}

