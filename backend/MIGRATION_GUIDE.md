# Database Migration Guide

## Option 1: Direct SQL Migration (Recommended for initial setup)

Run the SQL migration file directly:

```bash
psql -U postgres -d theaurahouse -f src/migrations/001-initial-schema.sql
```

Or using environment variables:

```bash
psql -h $DB_HOST -U $DB_USERNAME -d $DB_DATABASE -f src/migrations/001-initial-schema.sql
```

## Option 2: TypeORM Migrations

### Generate Migration

After making changes to entities:

```bash
npm run migration:generate -- src/migrations/MigrationName
```

### Run Migrations

```bash
npm run migration:run
```

### Revert Migration

```bash
npm run migration:revert
```

## Manual Setup

If you prefer to set up the database manually:

1. Create database:
```sql
CREATE DATABASE theaurahouse;
```

2. Connect to database and run the SQL from `src/migrations/001-initial-schema.sql`

## Verification

After migration, verify tables exist:

```sql
\dt
```

You should see:
- users
- posts
- comments
- likes
- follows
- notifications

## Indexes

The migration creates indexes for:
- `posts.created_at` (DESC) - for feed ordering
- `posts.user_id` - for user posts lookup
- `comments.post_id` - for post comments
- `likes.post_id` - for post likes
- `follows.follower_id` and `followee_id` - for follow relationships
- `notifications.user_id` and `(user_id, is_read)` - for notification queries

