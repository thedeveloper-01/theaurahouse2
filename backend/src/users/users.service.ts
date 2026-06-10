import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { User } from '@prisma/client';
import { UpdateProfileDto } from './dto/update-profile.dto';
import { UserStatsDto } from './dto/user-stats.dto';

@Injectable()
export class UsersService {
  constructor(private prisma: PrismaService) {}

  async findOne(id: string): Promise<User> {
    const user = await this.prisma.user.findUnique({
      where: { id },
      include: { posts: true },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    return user;
  }

  async findByUsername(username: string): Promise<User> {
    const user = await this.prisma.user.findUnique({
      where: { username },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    return user;
  }

  async searchUsers(
    query: string,
    limit: number = 20,
  ): Promise<Omit<User, 'password'>[]> {
    if (!query || query.trim().length === 0) {
      return [];
    }

    const searchLower = query.trim().toLowerCase();

    try {
      // Fetch users and filter in memory for reliable case-insensitive search
      // This approach works consistently across all PostgreSQL versions
      const allUsers = await this.prisma.user.findMany({
        take: limit * 3, // Get more to filter (in case of many matches)
        orderBy: {
          username: 'asc',
        },
        select: {
          id: true,
          username: true,
          displayName: true,
          email: true,
          bio: true,
          avatarUrl: true,
          createdAt: true,
          updatedAt: true,
        },
      });

      // Filter case-insensitively
      const filtered = allUsers.filter(
        (user) =>
          user.username.toLowerCase().includes(searchLower) ||
          (user.displayName &&
            user.displayName.toLowerCase().includes(searchLower)),
      );

      return filtered.slice(0, limit) as Omit<User, 'password'>[];
    } catch (error) {
      console.error('Error searching users:', error);
      // Return empty array instead of throwing to prevent 500 errors
      // Log the error for debugging but don't crash the request
      return [];
    }
  }

  async updateProfile(userId: string, updateProfileDto: UpdateProfileDto): Promise<User> {
    return this.prisma.user.update({
      where: { id: userId },
      data: updateProfileDto,
    });
  }

  async getUserStats(userId: string): Promise<UserStatsDto> {
    // Check if user exists
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    // Get all counts in parallel for better performance
    const [
      postCount,
      imagesCount,
      reelsCount,
      followersCount,
      followingCount,
    ] = await Promise.all([
      // Total posts count
      this.prisma.post.count({
        where: { userId },
      }),
      // Images count (posts that are not videos)
      this.prisma.post.count({
        where: {
          userId,
          isVideo: false,
        },
      }),
      // Reels count (posts that are videos)
      this.prisma.post.count({
        where: {
          userId,
          isVideo: true,
        },
      }),
      // Followers count (users following this user)
      this.prisma.follow.count({
        where: { followeeId: userId },
      }),
      // Following count (users this user is following)
      this.prisma.follow.count({
        where: { followerId: userId },
      }),
    ]);

    // For now, events count is 0 - can be added later with a category/type field
    // or a separate events table
    const eventsCount = 0;

    return {
      postCount,
      imagesCount,
      reelsCount,
      eventsCount,
      followersCount,
      followingCount,
    };
  }
}

