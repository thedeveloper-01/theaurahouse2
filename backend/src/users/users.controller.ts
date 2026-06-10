import { Controller, Get, Put, Param, Body, UseGuards, Request } from '@nestjs/common';
import { UsersService } from './users.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { UpdateProfileDto } from './dto/update-profile.dto';

@Controller('users')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Get('search')
  async searchUsers(@Request() req) {
    try {
      const query = req.query?.q as string;
      const limit = req.query?.limit ? parseInt(req.query.limit as string, 10) : 20;
      
      if (!query || query.trim().length === 0) {
        return [];
      }

      const results = await this.usersService.searchUsers(query, limit);
      return results;
    } catch (error) {
      console.error('Error in searchUsers controller:', error);
      // Return empty array instead of throwing to prevent 500 errors
      // The frontend will handle empty results gracefully
      return [];
    }
  }

  @Get('username/:username')
  async getUserByUsername(@Param('username') username: string) {
    return this.usersService.findByUsername(username);
  }

  @Get(':id/stats')
  async getUserStats(@Param('id') id: string) {
    return this.usersService.getUserStats(id);
  }

  @Get(':id')
  async getUser(@Param('id') id: string) {
    return this.usersService.findOne(id);
  }

  @Put('profile')
  @UseGuards(JwtAuthGuard)
  async updateProfile(@Request() req, @Body() updateProfileDto: UpdateProfileDto) {
    return this.usersService.updateProfile(req.user.userId, updateProfileDto);
  }
}

