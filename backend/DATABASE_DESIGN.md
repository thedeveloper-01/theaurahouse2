# Database Design Decisions

## Primary Database: PostgreSQL

**Why PostgreSQL?**

1. **ACID Compliance**: Ensures data integrity for financial transactions, likes, comments
2. **Complex Joins**: Efficient queries across users, posts, comments, likes
3. **JSONB Support**: Store flexible media metadata while maintaining relational benefits
4. **Mature Ecosystem**: Well-tested, excellent tooling, strong community
5. **Full-Text Search**: Built-in capabilities for future search features
6. **Scalability**: Proven at scale (Instagram, Reddit use PostgreSQL)

## Schema Design

### Denormalized Counts

**Decision**: Store `like_count` and `comment_count` directly in `posts` table.

**Why?**
- Fast reads: No need to COUNT() on every feed load
- Reduced database load: Avoid expensive aggregations
- Better UX: Instant display of counts

**Trade-offs:**
- Must update counts in transactions
- Potential for slight inconsistency (mitigated with background jobs)

**Implementation:**
- Increment/decrement on like/unlike
- Increment/decrement on comment create/delete
- Background job to sync counts periodically (optional)

### Media Storage

**Decision**: Store media metadata as JSONB array in `media_json` field.

**Structure:**
```json
[
  {
    "url": "https://cdn.example.com/image1.jpg",
    "type": "image",
    "width": 1080,
    "height": 1920
  },
  {
    "url": "https://cdn.example.com/video1.mp4",
    "type": "video",
    "width": 1920,
    "height": 1080,
    "duration": 30
  }
]
```

**Why JSONB?**
- Flexible: Support multiple media types per post
- Queryable: Can query within JSONB (e.g., find posts with videos)
- Efficient: PostgreSQL JSONB is optimized and indexed
- No additional joins needed

### Unique Constraints

**Likes Table**: `UNIQUE (user_id, post_id)`
- Prevents double-likes
- Database-level enforcement
- Fast lookups

**Follows Table**: Composite primary key `(follower_id, followee_id)`
- Prevents self-follows (application level)
- Prevents duplicate follows
- Efficient bidirectional queries

## Indexing Strategy

### Critical Indexes

1. **`idx_posts_created_at` (DESC)**
   - Feed queries: `ORDER BY created_at DESC`
   - Most common query pattern

2. **`idx_comments_post`**
   - Load comments for a post
   - Frequently accessed

3. **`idx_likes_post`**
   - Count likes, show who liked
   - High read volume

4. **`idx_notifications_user_read`**
   - Unread notifications query
   - Composite index for filtering

### Future Indexes (if needed)

- Full-text search on `posts.text`
- GIN index on `posts.media_json` for JSONB queries
- Partial indexes for active users

## Caching Strategy (Redis)

**What to Cache:**
- User sessions (JWT refresh tokens)
- Post like counts (with TTL)
- User follower counts
- Rate limiting data
- Hot feed posts (top posts)

**What NOT to Cache:**
- User authentication (security risk)
- Real-time data (comments, new posts)
- User profiles (frequently updated)

## Alternative: MongoDB Consideration

**When MongoDB might be better:**
- Document-heavy workloads
- Rapid schema evolution
- Horizontal scaling needs
- Change streams for real-time

**Why we chose PostgreSQL:**
- Strong consistency requirements (likes, comments)
- Complex relationships (follows, nested comments)
- ACID transactions for counts
- Mature ecosystem for social apps

## Scaling Considerations

### Read Replicas
- Separate read/write traffic
- Feed queries → read replica
- Writes → primary

### Partitioning (Future)
- Partition `posts` by `created_at` (time-based)
- Partition `notifications` by `user_id` (hash-based)

### Archival
- Archive old posts to cold storage
- Keep recent posts hot
- Use materialized views for analytics

