// ignore_for_file: public_member_api_docs, sort_constructors_first, depend_on_referenced_packages
import 'dart:convert';
import 'package:collection/collection.dart';

class AssetModel {
  final String id;
  final String userId;
  final String profilePicture;
  final List<String> passionList;
  final List<String> imageList;
  final DateTime createdAt;
  final DateTime updatedAt;

  AssetModel({
    required this.id,
    required this.userId,
    required this.profilePicture,
    required this.passionList,
    required this.imageList,
    required this.createdAt,
    required this.updatedAt,
  });

  AssetModel copyWith({
    String? id,
    String? userId,
    String? profilePicture,
    List<String>? passionList,
    List<String>? imageList,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AssetModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      profilePicture: profilePicture ?? this.profilePicture,
      passionList: passionList ?? this.passionList,
      imageList: imageList ?? this.imageList,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'profile_picture': profilePicture,
      'passion_list': passionList,
      'image_list': imageList,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory AssetModel.fromMap(Map<String, dynamic> map) {
    return AssetModel(
      id: map['id'] ?? "",
      userId: map['user_id'] ?? "",
      profilePicture: (map['profile_picture'] ?? '').toString().trim(),
      passionList: List<String>.from(map['passion_list']
          .where((url) => url != null && url.toString().trim().isNotEmpty)),
      imageList: List<String>.from((map['image_list'] ?? [])
          .where((url) => url != null && url.toString().trim().isNotEmpty)),
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  String toJson() => json.encode(toMap());

  factory AssetModel.fromJson(String source) =>
      AssetModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'AssetModel(id: $id, userId: $userId, profilePicture: $profilePicture, passionList: $passionList, imageList: $imageList, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(covariant AssetModel other) {
    if (identical(this, other)) return true;
    final listEquals = const DeepCollectionEquality().equals;
    return other.id == id &&
        other.userId == userId &&
        other.profilePicture == profilePicture &&
        listEquals(other.passionList, passionList) &&
        listEquals(other.imageList, imageList) &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        userId.hashCode ^
        profilePicture.hashCode ^
        passionList.hashCode ^
        imageList.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }

  toList() {}
}
