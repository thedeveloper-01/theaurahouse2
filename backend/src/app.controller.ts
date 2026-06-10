import { Controller, Get } from '@nestjs/common';

@Controller()
export class AppController {
  @Get()
  getRoot() {
    return {
      message: 'TheAuraHouse API',
      version: '1.0.0',
      status: 'running',
      endpoints: {
        auth: {
          register: 'POST /auth/register',
          login: 'POST /auth/login',
          profile: 'GET /auth/profile',
        },
        users: {
          getUser: 'GET /users/:id',
          getUserByUsername: 'GET /users/username/:username',
          updateProfile: 'PUT /users/profile',
        },
        posts: {
          create: 'POST /posts',
          getAll: 'GET /posts',
          getOne: 'GET /posts/:id',
          update: 'PATCH /posts/:id',
          delete: 'DELETE /posts/:id',
        },
        comments: {
          create: 'POST /comments/post/:postId',
          getByPost: 'GET /comments/post/:postId',
          getOne: 'GET /comments/:id',
          update: 'PATCH /comments/:id',
          delete: 'DELETE /comments/:id',
        },
        likes: {
          toggle: 'POST /likes/post/:postId',
          check: 'GET /likes/post/:postId/check',
          getByPost: 'GET /likes/post/:postId',
          getByUser: 'GET /likes/user/:userId',
        },
      },
    };
  }

  @Get('health')
  getHealth() {
    return {
      status: 'ok',
      timestamp: new Date().toISOString(),
    };
  }
}

