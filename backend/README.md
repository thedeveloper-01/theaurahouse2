# TheAuraHouse Backend API

NestJS backend for TheAuraHouse social media platform.

## Tech Stack

- **Framework**: NestJS (TypeScript)
- **Database**: PostgreSQL
- **ORM**: Prisma
- **Authentication**: JWT (Passport)
- **Storage**: AWS S3 + CloudFront
- **Cache**: Redis (to be implemented)

## Setup

### Prerequisites

- Node.js 18+
- PostgreSQL 14+
- AWS Account (for S3)
- Redis (optional, for caching)

### Installation

```bash
cd backend
npm install
```

### Environment Variables

Copy `.env.example` to `.env` and fill in your values:

```bash
cp .env.example .env
```

Required variables:
- `DATABASE_URL` - PostgreSQL connection string (e.g., `postgresql://user:password@localhost:5432/theaurahouse?schema=public`)
- `JWT_SECRET`, `JWT_EXPIRES_IN`
- `AWS_REGION`, `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `S3_BUCKET_NAME`, `CLOUDFRONT_DOMAIN`
- `REDIS_HOST`, `REDIS_PORT` (optional)

### Database Setup

1. Create PostgreSQL database:
```sql
CREATE DATABASE theaurahouse;
```

2. Set `DATABASE_URL` in `.env`:
```env
DATABASE_URL="postgresql://username:password@localhost:5432/theaurahouse?schema=public"
```

3. Generate Prisma Client:
```bash
npm run prisma:generate
```

4. Run Prisma migrations:
```bash
npm run prisma:migrate
```

This will create the database schema and apply all migrations.

For more details, see [PRISMA_SETUP.md](./PRISMA_SETUP.md)

### Running the App

```bash
# Development
npm run start:dev

# Production
npm run build
npm run start:prod
```

## API Endpoints

### Authentication

- `POST /auth/register` - Register new user
- `POST /auth/login` - Login
- `GET /auth/profile` - Get current user profile (protected)

### Users

- `GET /users/:id` - Get user by ID
- `GET /users/username/:username` - Get user by username
- `PUT /users/profile` - Update profile (protected)

### Posts

- `POST /posts` - Create post with media upload (protected)
- `GET /posts` - Get posts (paginated, optional userId filter)
- `GET /posts/:id` - Get single post
- `PATCH /posts/:id` - Update post (protected)
- `DELETE /posts/:id` - Delete post (protected)

### Comments

- `POST /comments/post/:postId` - Create comment (protected)
- `GET /comments/post/:postId` - Get comments for post (paginated)
- `GET /comments/:id` - Get single comment
- `PATCH /comments/:id` - Update comment (protected)
- `DELETE /comments/:id` - Delete comment (protected)

### Likes

- `POST /likes/post/:postId` - Toggle like (protected)
- `GET /likes/post/:postId/check` - Check if user liked post (protected)
- `GET /likes/post/:postId` - Get likes for post (paginated)
- `GET /likes/user/:userId` - Get user's likes (paginated)

## Database Schema

The database schema is defined in `prisma/schema.prisma`. Prisma generates TypeScript types and handles migrations automatically.

To view the schema:
- Open `prisma/schema.prisma` in your editor
- Or use Prisma Studio: `npm run prisma:studio`

### Key Tables

- `users` - User accounts
- `posts` - Posts with media (JSONB for multiple attachments)
- `comments` - Comments with nested replies support
- `likes` - Post likes (unique constraint prevents double-likes)
- `follows` - User follow relationships
- `notifications` - User notifications

### Design Decisions

- **PostgreSQL**: ACID compliance, complex joins, mature ecosystem
- **Denormalized counts**: `like_count` and `comment_count` in posts table for fast reads
- **JSONB media**: Store multiple media items (images/videos) as JSONB array
- **S3 + CloudFront**: Scalable media storage with CDN delivery

## File Upload

Posts support multiple file uploads (images/videos). Files are:
1. Uploaded to S3
2. URLs stored in `media_json` JSONB field
3. Served via CloudFront CDN

Max 10 files per post (configurable in `posts.controller.ts`).

## Security

- JWT authentication for protected routes
- Password hashing with bcrypt (10 rounds)
- Input validation with class-validator
- CORS enabled for Flutter app

## Next Steps

- [ ] Redis caching for counts and sessions
- [ ] Rate limiting
- [ ] WebSocket/Socket.IO for real-time features
- [ ] Elasticsearch for search
- [ ] Background jobs for notifications
- [ ] Image/video processing (thumbnails, transcoding)

