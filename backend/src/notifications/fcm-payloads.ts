/**
 * FCM Push Notification Payload Templates
 * 
 * These templates follow FCM v1 API format for both Android and iOS
 */

export interface FCMNotificationPayload {
  notification: {
    title: string;
    body: string;
    image?: string;
  };
  data: {
    type: string;
    [key: string]: string;
  };
  android?: {
    priority: 'normal' | 'high';
    notification: {
      channelId: string;
      sound: string;
      clickAction: string;
    };
  };
  apns?: {
    payload: {
      aps: {
        alert: {
          title: string;
          body: string;
        };
        sound: string;
        badge?: number;
        'content-available'?: number;
      };
    };
  };
}

/**
 * New Like Notification
 */
export function createLikeNotificationPayload(
  likerUsername: string,
  postId: string,
  likerId: string,
  likerAvatarUrl?: string,
): FCMNotificationPayload {
  return {
    notification: {
      title: 'New Like',
      body: `${likerUsername} liked your post`,
      image: likerAvatarUrl,
    },
    data: {
      type: 'like',
      postId: postId,
      userId: likerId,
      username: likerUsername,
    },
    android: {
      priority: 'high',
      notification: {
        channelId: 'likes',
        sound: 'default',
        clickAction: 'FLUTTER_NOTIFICATION_CLICK',
      },
    },
    apns: {
      payload: {
        aps: {
          alert: {
            title: 'New Like',
            body: `${likerUsername} liked your post`,
          },
          sound: 'default',
          badge: 1,
        },
      },
    },
  };
}

/**
 * Example JSON for Android
 */
export const likeNotificationAndroidExample = {
  notification: {
    title: 'New Like',
    body: 'johndoe liked your post',
    image: 'https://cloudinary.com/avatar.jpg',
  },
  data: {
    type: 'like',
    postId: '550e8400-e29b-41d4-a716-446655440000',
    userId: '660e8400-e29b-41d4-a716-446655440001',
    username: 'johndoe',
  },
  android: {
    priority: 'high',
    notification: {
      channelId: 'likes',
      sound: 'default',
      clickAction: 'FLUTTER_NOTIFICATION_CLICK',
    },
  },
};

/**
 * Example JSON for iOS
 */
export const likeNotificationIOSExample = {
  notification: {
    title: 'New Like',
    body: 'johndoe liked your post',
    image: 'https://cloudinary.com/avatar.jpg',
  },
  data: {
    type: 'like',
    postId: '550e8400-e29b-41d4-a716-446655440000',
    userId: '660e8400-e29b-41d4-a716-446655440001',
    username: 'johndoe',
  },
  apns: {
    payload: {
      aps: {
        alert: {
          title: 'New Like',
          body: 'johndoe liked your post',
        },
        sound: 'default',
        badge: 1,
      },
    },
  },
};

/**
 * New Comment Notification
 */
export function createCommentNotificationPayload(
  commenterUsername: string,
  postId: string,
  commentId: string,
  commenterId: string,
  commentText: string,
  commenterAvatarUrl?: string,
): FCMNotificationPayload {
  // Truncate comment text if too long
  const truncatedText = commentText.length > 100 
    ? commentText.substring(0, 100) + '...' 
    : commentText;

  return {
    notification: {
      title: 'New Comment',
      body: `${commenterUsername} commented: ${truncatedText}`,
      image: commenterAvatarUrl,
    },
    data: {
      type: 'comment',
      postId: postId,
      commentId: commentId,
      userId: commenterId,
      username: commenterUsername,
      text: commentText,
    },
    android: {
      priority: 'high',
      notification: {
        channelId: 'comments',
        sound: 'default',
        clickAction: 'FLUTTER_NOTIFICATION_CLICK',
      },
    },
    apns: {
      payload: {
        aps: {
          alert: {
            title: 'New Comment',
            body: `${commenterUsername} commented: ${truncatedText}`,
          },
          sound: 'default',
          badge: 1,
        },
      },
    },
  };
}

/**
 * Example JSON for Android
 */
export const commentNotificationAndroidExample = {
  notification: {
    title: 'New Comment',
    body: 'johndoe commented: Great post!',
    image: 'https://cloudinary.com/avatar.jpg',
  },
  data: {
    type: 'comment',
    postId: '550e8400-e29b-41d4-a716-446655440000',
    commentId: '770e8400-e29b-41d4-a716-446655440002',
    userId: '660e8400-e29b-41d4-a716-446655440001',
    username: 'johndoe',
    text: 'Great post!',
  },
  android: {
    priority: 'high',
    notification: {
      channelId: 'comments',
      sound: 'default',
      clickAction: 'FLUTTER_NOTIFICATION_CLICK',
    },
  },
};

/**
 * Example JSON for iOS
 */
export const commentNotificationIOSExample = {
  notification: {
    title: 'New Comment',
    body: 'johndoe commented: Great post!',
    image: 'https://cloudinary.com/avatar.jpg',
  },
  data: {
    type: 'comment',
    postId: '550e8400-e29b-41d4-a716-446655440000',
    commentId: '770e8400-e29b-41d4-a716-446655440002',
    userId: '660e8400-e29b-41d4-a716-446655440001',
    username: 'johndoe',
    text: 'Great post!',
  },
  apns: {
    payload: {
      aps: {
        alert: {
          title: 'New Comment',
          body: 'johndoe commented: Great post!',
        },
        sound: 'default',
        badge: 1,
      },
    },
  },
};

/**
 * New Follower Notification
 */
export function createFollowerNotificationPayload(
  followerUsername: string,
  followerId: string,
  followerAvatarUrl?: string,
): FCMNotificationPayload {
  return {
    notification: {
      title: 'New Follower',
      body: `${followerUsername} started following you`,
      image: followerAvatarUrl,
    },
    data: {
      type: 'follow',
      userId: followerId,
      username: followerUsername,
    },
    android: {
      priority: 'normal',
      notification: {
        channelId: 'followers',
        sound: 'default',
        clickAction: 'FLUTTER_NOTIFICATION_CLICK',
      },
    },
    apns: {
      payload: {
        aps: {
          alert: {
            title: 'New Follower',
            body: `${followerUsername} started following you`,
          },
          sound: 'default',
          badge: 1,
        },
      },
    },
  };
}

/**
 * Example JSON for Android
 */
export const followerNotificationAndroidExample = {
  notification: {
    title: 'New Follower',
    body: 'johndoe started following you',
    image: 'https://cloudinary.com/avatar.jpg',
  },
  data: {
    type: 'follow',
    userId: '660e8400-e29b-41d4-a716-446655440001',
    username: 'johndoe',
  },
  android: {
    priority: 'normal',
    notification: {
      channelId: 'followers',
      sound: 'default',
      clickAction: 'FLUTTER_NOTIFICATION_CLICK',
    },
  },
};

/**
 * Example JSON for iOS
 */
export const followerNotificationIOSExample = {
  notification: {
    title: 'New Follower',
    body: 'johndoe started following you',
    image: 'https://cloudinary.com/avatar.jpg',
  },
  data: {
    type: 'follow',
    userId: '660e8400-e29b-41d4-a716-446655440001',
    username: 'johndoe',
  },
  apns: {
    payload: {
      aps: {
        alert: {
          title: 'New Follower',
          body: 'johndoe started following you',
        },
        sound: 'default',
        badge: 1,
      },
    },
  },
};

/**
 * New Message Notification
 */
export function createMessageNotificationPayload(
  senderUsername: string,
  conversationId: string,
  messageText: string,
  senderId: string,
  senderAvatarUrl?: string,
): FCMNotificationPayload {
  // Truncate message if too long
  const truncatedText = messageText.length > 100 
    ? messageText.substring(0, 100) + '...' 
    : messageText;

  return {
    notification: {
      title: senderUsername,
      body: truncatedText,
      image: senderAvatarUrl,
    },
    data: {
      type: 'message',
      conversationId: conversationId,
      senderId: senderId,
      messageText: messageText,
    },
    android: {
      priority: 'high',
      notification: {
        channelId: 'messages',
        sound: 'default',
        clickAction: 'FLUTTER_NOTIFICATION_CLICK',
      },
    },
    apns: {
      payload: {
        aps: {
          alert: {
            title: senderUsername,
            body: truncatedText,
          },
          sound: 'default',
          badge: 1,
          'content-available': 1,
        },
      },
    },
  };
}

/**
 * Generic notification payload builder
 */
export function createNotificationPayload(
  type: 'like' | 'comment' | 'follow' | 'message',
  data: {
    username: string;
    userId: string;
    avatarUrl?: string;
    postId?: string;
    commentId?: string;
    commentText?: string;
    conversationId?: string;
    messageText?: string;
  },
): FCMNotificationPayload {
  switch (type) {
    case 'like':
      if (!data.postId) throw new Error('postId required for like notification');
      return createLikeNotificationPayload(
        data.username,
        data.postId,
        data.userId,
        data.avatarUrl,
      );
    case 'comment':
      if (!data.postId || !data.commentId || !data.commentText) {
        throw new Error('postId, commentId, and commentText required for comment notification');
      }
      return createCommentNotificationPayload(
        data.username,
        data.postId,
        data.commentId,
        data.userId,
        data.commentText,
        data.avatarUrl,
      );
    case 'follow':
      return createFollowerNotificationPayload(
        data.username,
        data.userId,
        data.avatarUrl,
      );
    case 'message':
      if (!data.conversationId || !data.messageText) {
        throw new Error('conversationId and messageText required for message notification');
      }
      return createMessageNotificationPayload(
        data.username,
        data.conversationId,
        data.messageText,
        data.userId,
        data.avatarUrl,
      );
    default:
      throw new Error(`Unknown notification type: ${type}`);
  }
}

