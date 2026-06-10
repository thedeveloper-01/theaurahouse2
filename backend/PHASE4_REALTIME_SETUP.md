# Phase 4 - Realtime & Notifications Setup Guide

## Overview

This phase implements realtime features using Socket.IO and push notifications using Firebase Cloud Messaging (FCM).

## Features Implemented

### ✅ Socket.IO Server
- JWT authentication on connection
- Real-time post likes/unlikes
- Typing indicators
- Presence (online/offline)
- Room management (join/leave)
- Event broadcasting

### ✅ FCM Push Notifications
- Like notifications
- Comment notifications
- Follower notifications
- Device token management
- Automatic token deduplication

### ✅ Device Token Lifecycle
- Registration endpoint
- Deletion endpoint
- Token rotation handling
- Multi-device support (max 10 active tokens per user)

## Installation

### 1. Install Dependencies

```bash
cd backend
npm install socket.io @nestjs/platform-socket.io @nestjs/websockets firebase-admin
```

### 2. Firebase Setup

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project or use existing
3. Go to Project Settings > Service Accounts
4. Generate new private key
5. Download the JSON file
6. Add to `.env`:

```env
FCM_SERVICE_ACCOUNT='{"type":"service_account","project_id":"...","private_key_id":"...","private_key":"...","client_email":"...","client_id":"...","auth_uri":"...","token_uri":"...","auth_provider_x509_cert_url":"...","client_x509_cert_url":"..."}'
```

**Note**: The entire JSON should be in a single line or use a file path.

### 3. Database Migration

Run Prisma migration to add `device_tokens` table:

```bash
npm run prisma:migrate
```

Or manually run the SQL from `src/notifications/device-tokens.schema.sql`

### 4. Update Environment Variables

Add to `backend/.env`:

```env
# Socket.IO (optional - defaults work)
SOCKET_PORT=3001

# FCM
FCM_SERVICE_ACCOUNT='<your-service-account-json>'
```

## API Endpoints

### Device Tokens

#### Register Device Token
```
POST /device-tokens/register
Authorization: Bearer <token>

Body:
{
  "token": "fcm_device_token_here",
  "platform": "android" | "ios" | "web",
  "deviceId": "optional_device_identifier",
  "appVersion": "1.0.0"
}
```

#### Delete Device Token
```
DELETE /device-tokens
Authorization: Bearer <token>

Body:
{
  "token": "fcm_device_token_here"
}
```

#### Get User Tokens
```
GET /device-tokens
Authorization: Bearer <token>
```

## Socket.IO Client Connection

### Connection Example (JavaScript/TypeScript)

```javascript
import io from 'socket.io-client';

const socket = io('https://your-backend.onrender.com', {
  auth: {
    token: 'your_jwt_token_here'
  }
});

// Listen for connection
socket.on('connect', (data) => {
  console.log('Connected:', data);
});

// Listen for post likes
socket.on('post:liked', (data) => {
  console.log('Post liked:', data);
});

// Send like event
socket.emit('post:like', { postId: 'post-id-here' });

// Join post room
socket.emit('room:join', { room: 'post:post-id-here' });

// Typing indicator
socket.emit('typing:start', { postId: 'post-id-here' });
socket.emit('typing:stop', { postId: 'post-id-here' });
```

## Event Contracts

See `backend/src/realtime/socket-events.contracts.md` for complete event documentation.

### Key Events

**Client → Server:**
- `post:like` - Like/unlike a post
- `typing:start` - Start typing indicator
- `typing:stop` - Stop typing indicator
- `room:join` - Join a room
- `room:leave` - Leave a room

**Server → Client:**
- `connect` - Connection established
- `post:liked` - Post was liked
- `post:unliked` - Post was unliked
- `post:created` - New post created
- `comment:created` - New comment created
- `typing:start` - User started typing
- `presence:online` - User came online
- `presence:offline` - User went offline
- `notification:new` - New notification
- `error` - Error occurred

## FCM Payload Examples

See `backend/src/notifications/fcm-payloads.ts` for complete templates.

### Like Notification
```json
{
  "notification": {
    "title": "New Like",
    "body": "johndoe liked your post"
  },
  "data": {
    "type": "like",
    "postId": "550e8400-e29b-41d4-a716-446655440000",
    "userId": "660e8400-e29b-41d4-a716-446655440001"
  }
}
```

## Testing

See `backend/src/realtime/REALTIME_TEST_PLAN.md` for comprehensive test plan.

### Quick Test

1. **Test Socket Connection:**
   ```bash
   # Use Socket.IO client or Postman
   # Connect with JWT token
   ```

2. **Test Like Event:**
   ```javascript
   socket.emit('post:like', { postId: 'test-post-id' });
   // Should receive 'post:liked' event
   ```

3. **Test Device Token:**
   ```bash
   curl -X POST https://your-api/device-tokens/register \
     -H "Authorization: Bearer <token>" \
     -H "Content-Type: application/json" \
     -d '{"token":"test_token","platform":"android"}'
   ```

## Architecture

### Socket.IO Flow
1. Client connects with JWT token
2. Server validates token
3. Server attaches user info to socket
4. Client can emit/receive events
5. Server broadcasts to relevant rooms

### Notification Flow
1. Event occurs (like, comment, follow)
2. Notification job added to queue
3. Queue processor:
   - Creates notification in DB
   - Gets user's device tokens
   - Sends FCM notifications
   - Handles invalid tokens

### Device Token Deduplication Rules
1. Same `user_id + device_id + platform` → Update existing
2. Same token for different user → Deactivate old
3. Same token for same user → Update existing
4. Max 10 active tokens per user → Deactivate oldest

## Production Considerations

1. **Socket.IO Scaling:**
   - Use Redis adapter for multi-server setup
   - Configure CORS properly
   - Set up rate limiting

2. **FCM:**
   - Monitor delivery rates
   - Handle token refresh
   - Batch notifications when possible

3. **Database:**
   - Index device_tokens table properly
   - Clean up inactive tokens periodically
   - Monitor notification table size

4. **Security:**
   - Validate all socket events
   - Rate limit socket events
   - Monitor for abuse

## Next Steps

1. Integrate Socket.IO client in Flutter app
2. Implement FCM in Flutter app
3. Add notification channels (Android)
4. Test multi-device scenarios
5. Set up monitoring and alerts

