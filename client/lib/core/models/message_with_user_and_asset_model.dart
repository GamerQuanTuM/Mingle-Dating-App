import 'dart:convert';

import 'package:social_heart/core/models/asset_model.dart';
import 'package:social_heart/core/models/user_model.dart';

class MessageWithUserAndAssetModel {
  final UserDetails interactedUserDetails;
  final AssetModel? interactedUserAssets; // This can be null if no asset data
  final String messageId;
  final String matchId;
  final String senderId;
  final String lastMessageContent;
  final DateTime lastMessageTime;

  MessageWithUserAndAssetModel({
    required this.interactedUserDetails,
    this.interactedUserAssets, // Nullable
    required this.messageId,
    required this.matchId,
    required this.senderId,
    required this.lastMessageContent,
    required this.lastMessageTime,
  });

  MessageWithUserAndAssetModel copyWith({
    UserDetails? interactedUserDetails,
    AssetModel? interactedUserAssets,
    String? messageId,
    String? matchId,
    String? lastMessageContent,
    DateTime? lastMessageTime,
    String? senderId,
  }) {
    return MessageWithUserAndAssetModel(
      interactedUserDetails:
          interactedUserDetails ?? this.interactedUserDetails,
      interactedUserAssets: interactedUserAssets ?? this.interactedUserAssets,
      messageId: messageId ?? this.messageId,
      matchId: matchId ?? this.matchId,
      senderId: senderId ?? this.senderId,
      lastMessageContent: lastMessageContent ?? this.lastMessageContent,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'interacted_user_details': interactedUserDetails.toMap(),
      'interacted_user_assets': interactedUserAssets?.toMap(),
      'message_id': messageId,
      'match_id': matchId,
      'sender_id': senderId,
      'last_message_content': lastMessageContent,
      'last_message_time': lastMessageTime.toIso8601String(),
    };
  }

  factory MessageWithUserAndAssetModel.fromMap(Map<String, dynamic> map) {
    return MessageWithUserAndAssetModel(
      interactedUserDetails: UserDetails.fromMap(
          map['interacted_user_details'] as Map<String, dynamic>),
      interactedUserAssets: map['interacted_user_assets'] != null
          ? AssetModel.fromMap(
              map['interacted_user_assets'] as Map<String, dynamic>)
          : null,
      messageId: map['message_id'] ?? '',
      senderId: map['sender_id'] ?? '',
      matchId: map['match_id'] ?? '',
      lastMessageContent: map['last_message_content'] ?? '',
      lastMessageTime: DateTime.parse(map['last_message_time']),
    );
  }

  String toJson() => json.encode(toMap());

  factory MessageWithUserAndAssetModel.fromJson(String source) =>
      MessageWithUserAndAssetModel.fromMap(
          json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'MessageWithUserAndAssetModel(interactedUserDetails: $interactedUserDetails, senderId:$senderId,  interactedUserAssets: $interactedUserAssets, messageId: $messageId, matchId: $matchId, lastMessageContent: $lastMessageContent, lastMessageTime: $lastMessageTime)';
  }

  @override
  bool operator ==(covariant MessageWithUserAndAssetModel other) {
    if (identical(this, other)) return true;

    return other.interactedUserDetails == interactedUserDetails &&
        other.interactedUserAssets == interactedUserAssets &&
        other.messageId == messageId &&
        other.matchId == matchId &&
        other.lastMessageContent == lastMessageContent &&
        other.senderId == senderId &&
        other.lastMessageTime == lastMessageTime;
  }

  @override
  int get hashCode {
    return interactedUserDetails.hashCode ^
        interactedUserAssets.hashCode ^
        messageId.hashCode ^
        matchId.hashCode ^
        senderId.hashCode ^
        lastMessageContent.hashCode ^
        lastMessageTime.hashCode;
  }
}
