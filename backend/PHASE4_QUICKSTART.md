# Phase 4 - Quick Start Guide

## Step 1: Install Dependencies

```bash
cd backend
npm install socket.io @nestjs/platform-socket.io @nestjs/websockets firebase-admin
```

## Step 2: Update Prisma Schema

The `DeviceToken` model has been added to `prisma/schema.prisma`. Now regenerate Prisma client:

```bash
npm run prisma:generate
```

## Step 3: Run Database Migration

```bash
npm run prisma:migrate
```

Or if using SQL directly:
```bash
psql $DATABASE_URL -f src/notifications/device-tokens.schema.sql
```

## Step 4: Configure Firebase

1. Get Firebase service account JSON from Firebase Console
2. Add to `.env`:

```env
FCM_SERVICE_ACCOUNT='{"type":"service_account",...}'
```

Or use a file path:
```env
FCM_SERVICE_ACCOUNT_PATH=./firebase-service-account.json
```

## Step 5: Start Server

```bash
npm run start:dev
```

Socket.IO will be available on the same port as your HTTP server.

## Testing

### Test Socket Connection

```javascript
const socket = io('http://localhost:3000', {
  auth: { token: 'your_jwt_token' }
});

socket.on('connect', (data) => {
  console.log('Connected!', data);
});
```

### Test Device Token Registration

```bash
curl -X POST http://localhost:3000/device-tokens/register \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "token": "test_fcm_token",
    "platform": "android",
    "deviceId": "device123"
  }'
```

## Files Created

- `src/realtime/socket.gateway.ts` - Socket.IO server
- `src/realtime/guards/ws-jwt.guard.ts` - WebSocket JWT guard
- `src/realtime/realtime.module.ts` - Realtime module
- `src/realtime/socket-events.contracts.md` - Event documentation
- `src/notifications/fcm-payloads.ts` - FCM templates
- `src/notifications/fcm.service.ts` - FCM service
- `src/notifications/device-tokens.service.ts` - Token management
- `src/notifications/device-tokens.controller.ts` - Token endpoints
- `src/notifications/notification-queue.service.ts` - Queue processor
- `src/notifications/notifications.module.ts` - Notifications module
- `src/notifications/device-tokens.schema.sql` - Database schema
- `src/realtime/REALTIME_TEST_PLAN.md` - Test plan

## Next: Flutter Integration

1. Add `socket_io_client` package
2. Connect to Socket.IO on app start
3. Add `firebase_messaging` package
4. Register FCM token on app launch
5. Handle incoming notifications

