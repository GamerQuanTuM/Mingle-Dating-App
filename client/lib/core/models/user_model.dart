// ignore_for_file: constant_identifier_names

import 'dart:convert';
import 'package:intl/intl.dart';

enum Gender { MALE, FEMALE, BOTH }

extension GenderExtension on Gender {
  static Gender fromString(String gender) {
    switch (gender.toLowerCase()) {
      case 'male':
        return Gender.MALE;
      case 'female':
        return Gender.FEMALE;
      case 'both':
        return Gender.BOTH;
      default:
        throw Exception('Invalid gender type');
    }
  }

  String toShortString() {
    return toString().split('.').last;
  }
}

// UserDetails class to store the details within the user field
class UserDetails {
  final String id;
  final String name;
  final String phone;
  final Gender gender;
  final DateTime dob;
  final int age;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserDetails({
    required this.id,
    required this.name,
    required this.phone,
    required this.gender,
    required this.dob,
    required this.age,
    required this.createdAt,
    required this.updatedAt,
  });

  UserDetails copyWith({
    String? id,
    String? name,
    String? phone,
    Gender? gender,
    DateTime? dob,
    int? age,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserDetails(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      gender: gender ?? this.gender,
      dob: dob ?? this.dob,
      age: age ?? this.age,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'gender': gender.toShortString(),
      'dob': DateFormat('yyyy-MM-dd').format(dob),
      'age': age,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory UserDetails.fromMap(Map<String, dynamic> map) {
    return UserDetails(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      gender: GenderExtension.fromString(map['gender']),
      dob: DateTime.parse(map['dob']),
      age: map['age'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  @override
  String toString() {
    return 'UserDetails(id: $id, name: $name, phone: $phone, gender: $gender, dob: $dob, age:$age, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}

class UserModel {
  final String message;
  final String token;
  final UserDetails user;

  UserModel({
    required this.message,
    required this.token,
    required this.user,
  });

  UserModel copyWith({
    String? message,
    String? token,
    UserDetails? user,
  }) {
    return UserModel(
      message: message ?? this.message,
      token: token ?? this.token,
      user: user ?? this.user,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'message': message,
      'token': token,
      'user': user.toMap(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      message: map['message'] ?? '',
      token: map['token'] ?? '',
      user: UserDetails.fromMap(map['user'] ?? {}),
    );
  }

  String toJson() => json.encode(toMap());

  factory UserModel.fromJson(String source) =>
      UserModel.fromMap(json.decode(source));

  @override
  String toString() {
    return 'UserModel(message: $message, token: $token, user: $user)';
  }

  @override
  bool operator ==(covariant UserModel other) {
    if (identical(this, other)) return true;

    return other.message == message &&
        other.token == token &&
        other.user == user;
  }

  @override
  int get hashCode {
    return message.hashCode ^ token.hashCode ^ user.hashCode;
  }
}
