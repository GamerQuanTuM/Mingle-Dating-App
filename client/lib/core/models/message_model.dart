// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class MessageModel {
  final String id;
  final String senderId;
  final String? content;
  final String contentType;
  final DateTime createdAt;
  final String matchId;
  final String recipientId;
  final String? fileUrl;
  final DateTime updatedAt;
  final bool seen;

  MessageModel(
      {required this.id,
      required this.senderId,
      required this.recipientId,
      required this.contentType,
      this.content,
      required this.matchId,
      this.fileUrl,
      required this.createdAt,
      required this.updatedAt,
      required this.seen});

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      id: map['id'] ?? '',
      senderId: map['sender_id'] ?? '',
      recipientId: map['recipient_id'] ?? '',
      contentType: map['content_type'] ?? '',
      content: map['content'] as String?,
      matchId: map['match_id'] ?? '',
      fileUrl: map['file_url'] as String?,
      seen: map['seen'] ?? false,
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at'] ?? '') ?? DateTime.now(),
    );
  }

  MessageModel copyWith(
      {String? id,
      String? senderId,
      String? recipientId,
      String? contentType,
      String? content,
      String? matchId,
      String? fileUrl,
      DateTime? createdAt,
      DateTime? updatedAt,
      bool? seen}) {
    return MessageModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      recipientId: recipientId ?? this.recipientId,
      contentType: contentType ?? this.contentType,
      content: content ?? this.content,
      matchId: matchId ?? this.matchId,
      fileUrl: fileUrl ?? this.fileUrl,
      seen: seen ?? this.seen,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'sender_id': senderId,
      'recipient_id': recipientId,
      'content_type': contentType,
      'content': content,
      'match_id': matchId,
      'file_url': fileUrl,
      'seen': seen,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String toJson() => json.encode(toMap());

  factory MessageModel.fromJson(String source) =>
      MessageModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'MessageModel(id: $id, senderId: $senderId, recipientId: $recipientId, contentType: $contentType, content: $content, matchId: $matchId, fileUrl: $fileUrl, seen:$seen, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(covariant MessageModel other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.senderId == senderId &&
        other.recipientId == recipientId &&
        other.contentType == contentType &&
        other.content == content &&
        other.matchId == matchId &&
        other.fileUrl == fileUrl &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        senderId.hashCode ^
        recipientId.hashCode ^
        contentType.hashCode ^
        content.hashCode ^
        matchId.hashCode ^
        fileUrl.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }
}
