import {
  Controller,
  Post,
  Delete,
  Body,
  UseGuards,
  Request,
  Get,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { DeviceTokensService } from './device-tokens.service';
import { RegisterDeviceTokenDto, DeleteDeviceTokenDto } from './dto/device-token.dto';

@Controller('device-tokens')
@UseGuards(JwtAuthGuard)
export class DeviceTokensController {
  constructor(private readonly deviceTokensService: DeviceTokensService) {}

  /**
   * Register or update device token
   * POST /device-tokens/register
   * 
   * Called on:
   * - App launch (if token exists)
   * - Token refresh (FCM)
   * - Login
   * 
   * Deduplication handled automatically:
   * - Same device_id + platform: updates existing token
   * - Same token for different user: deactivates old token
   * - Max 10 active tokens per user (oldest deactivated)
   */
  @Post('register')
  async registerToken(
    @Request() req,
    @Body() dto: RegisterDeviceTokenDto,
  ) {
    const userId = req.user.id;
    return await this.deviceTokensService.registerToken(userId, dto);
  }

  /**
   * Delete device token
   * DELETE /device-tokens
   * 
   * Called on:
   * - Logout
   * - App uninstall (if possible)
   * - User manually disables notifications
   */
  @Delete()
  async deleteToken(
    @Request() req,
    @Body() dto: DeleteDeviceTokenDto,
  ) {
    const userId = req.user.id;
    return await this.deviceTokensService.deleteToken(userId, dto.token);
  }

  /**
   * Get all active device tokens for current user
   * GET /device-tokens
   * 
   * Useful for debugging and user settings
   */
  @Get()
  async getTokens(@Request() req) {
    const userId = req.user.id;
    return await this.deviceTokensService.getUserTokens(userId);
  }
}

