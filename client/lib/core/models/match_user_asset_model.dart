import 'dart:convert';
import 'package:collection/collection.dart';

import 'package:social_heart/core/models/asset_model.dart';
import 'package:social_heart/core/models/user_model.dart';

class UserWithAssetsModel {
  final UserDetails userDetails;
  final List<AssetModel>? assets;

  UserWithAssetsModel({
    required this.userDetails,
    this.assets,
  });

  UserWithAssetsModel copyWith({
    UserDetails? userDetails,
    List<AssetModel>? assets,
  }) {
    return UserWithAssetsModel(
      userDetails: userDetails ?? this.userDetails,
      assets: assets ?? this.assets,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userDetails': userDetails.toMap(),
      'assets': (assets ?? []).map((asset) => asset.toMap()).toList(),
    };
  }

  factory UserWithAssetsModel.fromMap(Map<String, dynamic> map) {
    return UserWithAssetsModel(
      userDetails: UserDetails(
        id: map['id'] ?? '',
        name: map['name'] ?? '',
        phone: map['phone'] ?? '',
        gender: GenderExtension.fromString(map['gender']),
        dob: DateTime.parse(map['dob']),
        age: map['age'],
        createdAt: DateTime.parse(map['created_at']),
        updatedAt: DateTime.parse(map['updated_at']),
      ),
      assets: map['assets'] != null
          ? List<AssetModel>.from(
              map['assets'].map((asset) => AssetModel.fromMap(asset)),
            )
          : [],
    );
  }

  @override
  String toString() =>
      'UserWithAssets(userDetails: $userDetails, assets: $assets)';

  @override
  bool operator ==(Object other) =>
      other is UserWithAssetsModel &&
      const DeepCollectionEquality().equals(userDetails, other.userDetails) &&
      const DeepCollectionEquality().equals(assets, other.assets);

  @override
  int get hashCode => userDetails.hashCode ^ assets.hashCode;
}

class MatchUserAssetModel {
  final String message;
  final List<UserWithAssetsModel> users;

  MatchUserAssetModel({
    required this.message,
    required this.users,
  });

  MatchUserAssetModel copyWith({
    String? message,
    List<UserWithAssetsModel>? users,
  }) {
    return MatchUserAssetModel(
      message: message ?? this.message,
      users: users ?? this.users,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'message': message,
      'users': users.map((user) => user.toMap()).toList(),
    };
  }

  factory MatchUserAssetModel.fromMap(Map<String, dynamic> map) {
    return MatchUserAssetModel(
      message: map['message'] ?? '',
      users: map['users'] != null
          ? List<UserWithAssetsModel>.from(
              map['users']!.map((user) => UserWithAssetsModel.fromMap(user)))
          : [],
    );
  }

  String toJson() => json.encode(toMap());

  factory MatchUserAssetModel.fromJson(String source) =>
      MatchUserAssetModel.fromMap(json.decode(source));

  @override
  String toString() => 'MatchUserAssetModel(message: $message, users: $users)';

  @override
  bool operator ==(Object other) =>
      other is MatchUserAssetModel &&
      const DeepCollectionEquality().equals(message, other.message) &&
      const DeepCollectionEquality().equals(users, other.users);

  @override
  int get hashCode => message.hashCode ^ users.hashCode;
}
