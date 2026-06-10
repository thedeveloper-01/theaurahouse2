# Phase 4 - Next Steps & Important Notes

## ⚠️ IMPORTANT: Run Prisma Generate

After adding the `DeviceToken` model to the Prisma schema, you **must** regenerate the Prisma client:

```bash
cd backend
npm run prisma:generate
```

This will fix the TypeScript errors in `device-tokens.service.ts` where it references `prisma.deviceToken`.

## Database Migration

After generating Prisma client, run the migration:

```bash
npm run prisma:migrate
```

This will create the `device_tokens` table in your database.

## Install Missing Dependencies

Make sure all dependencies are installed:

```bash
npm install socket.io @nestjs/platform-socket.io @nestjs/websockets firebase-admin
```

## Firebase Configuration

1. **Get Service Account Key:**
   - Go to Firebase Console > Project Settings > Service Accounts
   - Click "Generate new private key"
   - Download the JSON file

2. **Add to `.env`:**
   
   Option 1: JSON string (single line):
   ```env
   FCM_SERVICE_ACCOUNT='{"type":"service_account","project_id":"...","private_key":"..."}'
   ```
   
   Option 2: File path:
   ```env
   FCM_SERVICE_ACCOUNT_PATH=./firebase-service-account.json
   ```

## Testing Checklist

- [ ] Prisma client generated successfully
- [ ] Database migration completed
- [ ] Dependencies installed
- [ ] Firebase service account configured
- [ ] Server starts without errors
- [ ] Socket.IO connection works with JWT
- [ ] Device token registration endpoint works
- [ ] Post like event works via Socket.IO
- [ ] FCM notification sent successfully

## Integration with Flutter

### Socket.IO Client

Add to `pubspec.yaml`:
```yaml
dependencies:
  socket_io_client: ^2.0.3+1
```

Connect in Flutter:
```dart
import 'package:socket_io_client/socket_io_client.dart' as IO;

final socket = IO.io(
  'https://your-backend.onrender.com',
  IO.OptionBuilder()
    .setTransports(['websocket'])
    .setAuth({'token': jwtToken})
    .build(),
);

socket.onConnect((_) {
  print('Connected to Socket.IO');
});

socket.on('post:liked', (data) {
  print('Post liked: $data');
});
```

### FCM Client

Add to `pubspec.yaml`:
```yaml
dependencies:
  firebase_messaging: ^14.7.0
  firebase_core: ^2.24.0
```

Register token:
```dart
import 'package:firebase_messaging/firebase_messaging.dart';

final fcmToken = await FirebaseMessaging.instance.getToken();

// Send to backend
await apiService.registerDeviceToken(
  token: fcmToken!,
  platform: Platform.isAndroid ? 'android' : 'ios',
);
```

## Known Issues & Solutions

### Issue: `Property 'deviceToken' does not exist`
**Solution:** Run `npm run prisma:generate`

### Issue: Firebase Admin SDK not initialized
**Solution:** Check `FCM_SERVICE_ACCOUNT` or `FCM_SERVICE_ACCOUNT_PATH` in `.env`

### Issue: Socket.IO connection fails
**Solution:** 
- Check JWT token is valid
- Verify CORS settings
- Check server logs for authentication errors

### Issue: Notifications not received
**Solution:**
- Verify device token is registered
- Check Firebase project configuration
- Verify FCM service account has proper permissions
- Check device token is active in database

## Production Considerations

1. **Socket.IO Scaling:**
   - Use Redis adapter for multi-instance deployments
   - Configure proper CORS origins
   - Add rate limiting

2. **FCM:**
   - Monitor delivery rates
   - Handle token refresh automatically
   - Batch notifications when possible

3. **Database:**
   - Add indexes for performance
   - Clean up inactive tokens periodically
   - Monitor notification table growth

4. **Security:**
   - Validate all socket events
   - Rate limit socket connections
   - Monitor for abuse patterns

