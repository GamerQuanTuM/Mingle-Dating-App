// ignore_for_file: public_member_api_docs, sort_constructors_first, constant_identifier_names
import 'dart:convert';

enum Status { ACTIVE, UNMATCHED, REJECTED }

extension StatusExtension on Status {
  static Status fromString(String status) {
    switch (status.toLowerCase()) {
      case 'unmatched':
        return Status.UNMATCHED;
      case 'active':
        return Status.ACTIVE;
      case 'rejected':
        return Status.REJECTED;
      default:
        throw Exception('Invalid status type');
    }
  }

  String toShortString() {
    return toString().split('.').last;
  }
}

class MatchDetails {
  final String id;
  final String user1Id;
  final String user2Id;
  final Status status;
  final DateTime createdAt;
  final DateTime updatedAt;
  MatchDetails({
    required this.id,
    required this.user1Id,
    required this.user2Id,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  MatchDetails copyWith({
    String? id,
    String? user1Id,
    String? user2Id,
    Status? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MatchDetails(
      id: id ?? this.id,
      user1Id: user1Id ?? this.user1Id,
      user2Id: user2Id ?? this.user2Id,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'user1_id': user1Id,
      'user2_id': user2Id,
      'status': status.toShortString(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory MatchDetails.fromMap(Map<String, dynamic> map) {
    return MatchDetails(
      id: map['id'] ?? '',
      user1Id: map['user1Id'] ?? '',
      user2Id: map['user2Id'] ?? '',
      status: StatusExtension.fromString(map['status']),
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  @override
  String toString() {
    return 'MatchDetails(id: $id, user1Id: $user1Id, user2Id: $user2Id, status: $status, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}

class MatchModel {
  final String message;
  final MatchDetails match;
  MatchModel({
    required this.message,
    required this.match,
  });

  MatchModel copyWith({
    String? message,
    MatchDetails? match,
  }) {
    return MatchModel(
      message: message ?? this.message,
      match: match ?? this.match,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'message': message,
      'match': match.toMap(),
    };
  }

  factory MatchModel.fromMap(Map<String, dynamic> map) {
    return MatchModel(
      message: map['message'] ?? '',
      match: MatchDetails.fromMap(map['match'] ?? {}),
    );
  }

  String toJson() => json.encode(toMap());

  factory MatchModel.fromJson(String source) =>
      MatchModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'MatchModel(message: $message, match: $match)';

  @override
  bool operator ==(covariant MatchModel other) {
    if (identical(this, other)) return true;

    return other.message == message && other.match == match;
  }

  @override
  int get hashCode => message.hashCode ^ match.hashCode;
}
