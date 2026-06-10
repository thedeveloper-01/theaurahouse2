class MessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String receiverId;
  final String text;
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic>? sender;

  MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.receiverId,
    required this.text,
    this.isRead = false,
    required this.createdAt,
    this.sender,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      conversationId:
          json['conversationId'] as String? ??
          json['conversation_id'] as String? ??
          '',
      senderId:
          json['senderId'] as String? ??
          json['sender_id'] as String? ??
          json['sender']?['id'] as String? ??
          '',
      receiverId:
          json['receiverId'] as String? ??
          json['receiver_id'] as String? ??
          json['receiver']?['id'] as String? ??
          '',
      text: json['text'] as String? ?? '',
      isRead: json['isRead'] as bool? ?? json['is_read'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      sender: json['sender'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversationId': conversationId,
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
      if (sender != null) 'sender': sender,
    };
  }

  MessageModel copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? receiverId,
    String? text,
    bool? isRead,
    DateTime? createdAt,
    Map<String, dynamic>? sender,
  }) {
    return MessageModel(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      text: text ?? this.text,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      sender: sender ?? this.sender,
    );
  }
}
