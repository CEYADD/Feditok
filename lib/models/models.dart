class UserProfile {
  final String id;
  final String username;
  final String? email;
  final String? fullName;
  final String? avatarUrl;
  final String? bannerUrl;
  final String? bio;
  final bool isFediverse;
  final String? fediverseHandle;
  final String rank;
  final bool isOnboardingCompleted;
  final DateTime createdAt;

  UserProfile({
    required this.id,
    required this.username,
    this.email,
    this.fullName,
    this.avatarUrl,
    this.bannerUrl,
    this.bio,
    this.isFediverse = false,
    this.fediverseHandle,
    this.rank = 'User',
    this.isOnboardingCompleted = false,
    required this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      username: json['username'] as String? ?? 'user',
      email: json['email'] as String?,
      fullName: json['full_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      bannerUrl: json['banner_url'] as String?,
      bio: json['bio'] as String?,
      isFediverse: json['is_fediverse'] as bool? ?? false,
      fediverseHandle: json['fediverse_handle'] as String?,
      rank: json['rank'] as String? ?? 'User',
      isOnboardingCompleted: json['is_onboarding_completed'] as bool? ?? false,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'banner_url': bannerUrl,
      'bio': bio,
      'is_fediverse': isFediverse,
      'fediverse_handle': fediverseHandle,
      'rank': rank,
      'is_onboarding_completed': isOnboardingCompleted,
    };
  }
}

class VideoItem {
  final String id;
  final String userId;
  final String videoUrl;
  final String? caption;
  final String? title;
  final List<String> taggedUsernames;
  final DateTime createdAt;
  final UserProfile? author;
  final int likesCount;
  final bool isLikedByMe;

  VideoItem({
    required this.id,
    required this.userId,
    required this.videoUrl,
    this.caption,
    this.title,
    this.taggedUsernames = const [],
    required this.createdAt,
    this.author,
    this.likesCount = 0,
    this.isLikedByMe = false,
  });

  factory VideoItem.fromJson(Map<String, dynamic> json, {UserProfile? author, bool isLiked = false, int likes = 0}) {
    return VideoItem(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      videoUrl: json['video_url'] as String,
      caption: json['caption'] as String?,
      title: json['title'] as String?,
      taggedUsernames: json['tagged_usernames'] != null 
          ? List<String>.from(json['tagged_usernames']) 
          : [],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      author: author ?? (json['profiles'] != null ? UserProfile.fromJson(json['profiles']) : null),
      likesCount: likes,
      isLikedByMe: isLiked,
    );
  }
}

class AppNotification {
  final String id;
  final String type; // 'friend_request', 'like', 'comment'
  final String title;
  final String message;
  final DateTime createdAt;
  final bool isRead;
  final String? fromUserId;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.createdAt,
    this.isRead = false,
    this.fromUserId,
  });
}

class FriendShip {
  final String id;
  final String requesterId;
  final String receiverId;
  final String status; // 'pending', 'accepted', 'rejected'
  final UserProfile? profile;

  FriendShip({
    required this.id,
    required this.requesterId,
    required this.receiverId,
    required this.status,
    this.profile,
  });
}

class ChatMessage {
  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      senderId: json['sender_id'] as String,
      receiverId: json['receiver_id'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
