# Socket.IO Event Contracts

## Connection Events

### `connect`
**Client → Server**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**Server → Client (Success)**
```json
{
  "status": "connected",
  "userId": "550e8400-e29b-41d4-a716-446655440000",
  "socketId": "socket_abc123"
}
```

**Server → Client (Error)**
```json
{
  "status": "error",
  "message": "Invalid or expired token"
}
```

---

## Post Events

### `post:created`
**Server → Client**
```json
{
  "post": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "userId": "660e8400-e29b-41d4-a716-446655440001",
    "user": {
      "id": "660e8400-e29b-41d4-a716-446655440001",
      "username": "johndoe",
      "displayName": "John Doe",
      "avatarUrl": "https://cloudinary.com/avatar.jpg"
    },
    "text": "Just posted a new photo!",
    "mediaJson": [
      {
        "url": "https://cloudinary.com/image1.jpg",
        "type": "image",
        "width": 1920,
        "height": 1080,
        "key": "media/image1"
      }
    ],
    "isVideo": false,
    "privacy": "public",
    "likeCount": 0,
    "commentCount": 0,
    "createdAt": "2024-01-15T10:30:00Z"
  }
}
```

### `post:updated`
**Server → Client**
```json
{
  "postId": "550e8400-e29b-41d4-a716-446655440000",
  "updates": {
    "text": "Updated caption",
    "updatedAt": "2024-01-15T11:00:00Z"
  }
}
```

### `post:liked`
**Server → Client**
```json
{
  "postId": "550e8400-e29b-41d4-a716-446655440000",
  "userId": "660e8400-e29b-41d4-a716-446655440001",
  "user": {
    "id": "660e8400-e29b-41d4-a716-446655440001",
    "username": "johndoe",
    "displayName": "John Doe",
    "avatarUrl": "https://cloudinary.com/avatar.jpg"
  },
  "isLiked": true,
  "likeCount": 42,
  "timestamp": "2024-01-15T10:35:00Z"
}
```

### `post:unliked`
**Server → Client**
```json
{
  "postId": "550e8400-e29b-41d4-a716-446655440000",
  "userId": "660e8400-e29b-41d4-a716-446655440001",
  "isLiked": false,
  "likeCount": 41,
  "timestamp": "2024-01-15T10:36:00Z"
}
```

---

## Comment Events

### `comment:created`
**Server → Client**
```json
{
  "comment": {
    "id": "770e8400-e29b-41d4-a716-446655440002",
    "postId": "550e8400-e29b-41d4-a716-446655440000",
    "userId": "660e8400-e29b-41d4-a716-446655440001",
    "user": {
      "id": "660e8400-e29b-41d4-a716-446655440001",
      "username": "johndoe",
      "displayName": "John Doe",
      "avatarUrl": "https://cloudinary.com/avatar.jpg"
    },
    "text": "Great post!",
    "parentCommentId": null,
    "createdAt": "2024-01-15T10:40:00Z"
  },
  "postId": "550e8400-e29b-41d4-a716-446655440000",
  "commentCount": 5
}
```

### `comment:updated`
**Server → Client**
```json
{
  "commentId": "770e8400-e29b-41d4-a716-446655440002",
  "text": "Updated comment text",
  "updatedAt": "2024-01-15T10:45:00Z"
}
```

### `comment:deleted`
**Server → Client**
```json
{
  "commentId": "770e8400-e29b-41d4-a716-446655440002",
  "postId": "550e8400-e29b-41d4-a716-446655440000",
  "commentCount": 4
}
```

---

## Typing Events

### `typing:start`
**Client → Server**
```json
{
  "postId": "550e8400-e29b-41d4-a716-446655440000"
}
```

**Server → Client (Broadcast)**
```json
{
  "postId": "550e8400-e29b-41d4-a716-446655440000",
  "userId": "660e8400-e29b-41d4-a716-446655440001",
  "user": {
    "id": "660e8400-e29b-41d4-a716-446655440001",
    "username": "johndoe",
    "displayName": "John Doe"
  },
  "isTyping": true
}
```

### `typing:stop`
**Client → Server**
```json
{
  "postId": "550e8400-e29b-41d4-a716-446655440000"
}
```

**Server → Client (Broadcast)**
```json
{
  "postId": "550e8400-e29b-41d4-a716-446655440000",
  "userId": "660e8400-e29b-41d4-a716-446655440001",
  "isTyping": false
}
```

---

## Presence Events

### `presence:online`
**Server → Client**
```json
{
  "userId": "660e8400-e29b-41d4-a716-446655440001",
  "user": {
    "id": "660e8400-e29b-41d4-a716-446655440001",
    "username": "johndoe",
    "displayName": "John Doe",
    "avatarUrl": "https://cloudinary.com/avatar.jpg"
  },
  "status": "online",
  "lastSeen": "2024-01-15T10:50:00Z"
}
```

### `presence:offline`
**Server → Client**
```json
{
  "userId": "660e8400-e29b-41d4-a716-446655440001",
  "status": "offline",
  "lastSeen": "2024-01-15T10:55:00Z"
}
```

### `presence:typing`
**Server → Client**
```json
{
  "userId": "660e8400-e29b-41d4-a716-446655440001",
  "postId": "550e8400-e29b-41d4-a716-446655440000",
  "isTyping": true
}
```

---

## Error Events

### `error`
**Server → Client**
```json
{
  "code": "AUTH_ERROR",
  "message": "Invalid authentication token",
  "timestamp": "2024-01-15T10:00:00Z"
}
```

### `rate_limit`
**Server → Client**
```json
{
  "message": "Rate limit exceeded. Please try again later.",
  "retryAfter": 60,
  "timestamp": "2024-01-15T10:00:00Z"
}
```

---

## Room Events

### `room:join`
**Client → Server**
```json
{
  "room": "post:550e8400-e29b-41d4-a716-446655440000"
}
```

### `room:leave`
**Client → Server**
```json
{
  "room": "post:550e8400-e29b-41d4-a716-446655440000"
}
```

---

## Notification Events

### `notification:new`
**Server → Client**
```json
{
  "notification": {
    "id": "880e8400-e29b-41d4-a716-446655440003",
    "type": "like",
    "payload": {
      "postId": "550e8400-e29b-41d4-a716-446655440000",
      "userId": "660e8400-e29b-41d4-a716-446655440001",
      "user": {
        "id": "660e8400-e29b-41d4-a716-446655440001",
        "username": "johndoe",
        "displayName": "John Doe",
        "avatarUrl": "https://cloudinary.com/avatar.jpg"
      }
    },
    "isRead": false,
    "createdAt": "2024-01-15T10:35:00Z"
  }
}
```

