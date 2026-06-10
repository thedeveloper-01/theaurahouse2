# Prisma Setup Guide

## Installation

Prisma has been integrated into the project. Follow these steps to set it up:

## 1. Install Dependencies

```bash
npm install
```

This will install:
- `@prisma/client` - Prisma Client for database queries
- `prisma` - Prisma CLI (dev dependency)

## 2. Set Up Database URL

Add to your `.env` file:

```env
DATABASE_URL="postgresql://username:password@localhost:5432/theaurahouse?schema=public"
```

Or for cloud databases (RDS, Cloud SQL):

```env
DATABASE_URL="postgresql://user:password@host:5432/database?schema=public&sslmode=require"
```

## 3. Generate Prisma Client

```bash
npm run prisma:generate
```

This generates the Prisma Client based on the schema in `prisma/schema.prisma`.

## 4. Run Migrations

### Development (creates migration and applies it)

```bash
npm run prisma:migrate
```

This will:
- Create a new migration file
- Apply the migration to your database
- Regenerate Prisma Client

### Production (applies existing migrations)

```bash
npm run prisma:migrate:deploy
```

This applies all pending migrations without creating new ones.

## 5. View Database (Optional)

Open Prisma Studio to view and edit data:

```bash
npm run prisma:studio
```

This opens a web interface at `http://localhost:5555`

## Schema Location

The Prisma schema is located at: `prisma/schema.prisma`

## Key Changes from TypeORM

### Models vs Entities

- **TypeORM**: Used decorators (`@Entity`, `@Column`) in TypeScript classes
- **Prisma**: Uses declarative schema in `schema.prisma` file

### Queries

**TypeORM:**
```typescript
await userRepository.findOne({ where: { id } });
```

**Prisma:**
```typescript
await prisma.user.findUnique({ where: { id } });
```

### Relations

**TypeORM:**
```typescript
await postRepository.findOne({
  where: { id },
  relations: ['user'],
});
```

**Prisma:**
```typescript
await prisma.post.findUnique({
  where: { id },
  include: { user: true },
});
```

### Transactions

**TypeORM:**
```typescript
await dataSource.transaction(async (manager) => {
  // operations
});
```

**Prisma:**
```typescript
await prisma.$transaction(async (tx) => {
  // operations
});
```

## Migration Workflow

1. **Modify schema**: Edit `prisma/schema.prisma`
2. **Create migration**: `npm run prisma:migrate`
3. **Review migration**: Check generated SQL in `prisma/migrations/`
4. **Apply migration**: Automatically applied in dev, use `prisma:migrate:deploy` in prod

## Reset Database (Development Only)

⚠️ **Warning**: This deletes all data!

```bash
npx prisma migrate reset
```

## Useful Commands

- `npx prisma format` - Format schema file
- `npx prisma validate` - Validate schema
- `npx prisma db pull` - Pull schema from existing database
- `npx prisma db push` - Push schema changes without migration (dev only)

## Type Safety

Prisma generates TypeScript types automatically. Import types from `@prisma/client`:

```typescript
import { User, Post, Comment } from '@prisma/client';
```

## Next Steps

1. Run `npm run prisma:generate` to generate client
2. Run `npm run prisma:migrate` to create and apply initial migration
3. Start the server: `npm run start:dev`

