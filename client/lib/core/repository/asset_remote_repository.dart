// ignore_for_file: depend_on_referenced_packages, implementation_imports

import 'dart:convert';
import 'dart:io';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:fpdart/fpdart.dart';
import 'package:social_heart/core/failure.dart';
import 'package:social_heart/core/models/asset_model.dart';
import 'package:social_heart/core/server_constant.dart';
import 'package:social_heart/core/utils/debug.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/src/media_type.dart';
import 'package:social_heart/core/utils/http.dart';

part "asset_remote_repository.g.dart";

@riverpod
AssetRemoteRepository assetRemoteRepository(AssetRemoteRepositoryRef ref) {
  return AssetRemoteRepository();
}

class AssetRemoteRepository {
  final httpService = HttpService();
  String sanitizeFilename(String originalFilename) {
    return originalFilename
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(' ', '_');
  }

  Future<Either<AppFailure, Map<String, String>>> uploadAsset({
    File? profilePicture,
    List<File?> imageList = const [],
    List<String?> passionList = const [],
    required String userId,
  }) async {
    try {
      // Prepare multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ServerConstant.baseUrl}/asset/upload'),
      );

      // Add profile picture if provided
      if (profilePicture != null && profilePicture.path.isNotEmpty) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'profile_picture',
            profilePicture.path,
            filename: sanitizeFilename(profilePicture.path.split('/').last),
            contentType: _getMediaType(profilePicture),
          ),
        );
      }

      // Add images from imageList, checking for non-null paths
      for (var image in imageList) {
        if (image != null && image.path.isNotEmpty) {
          request.files.add(
            await http.MultipartFile.fromPath(
              'image_list',
              image.path,
              filename: sanitizeFilename(image.path.split('/').last),
              contentType: _getMediaType(image),
            ),
          );
        }
      }

      // Add additional fields
      request.fields.addAll({
        'user_id': userId,
        'passion_list': jsonEncode(passionList.whereType<String>().toList()),
      });

      // Send request and parse response
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      // Parse and handle response
      if (response.statusCode == 201) {
        final responseBody = jsonDecode(response.body) as Map<String, dynamic>?;
        if (responseBody != null) {
          Debug.print("asset_remote_repository.dart", responseBody);
          return Right(Map<String, String>.from(responseBody));
        }
      }

      // Handle error response with detail
      final errorBody = jsonDecode(response.body);
      Debug.print("asset_remote_repository", errorBody["detail"].toString());
      return Left(AppFailure(message: "Failed to upload assets"));
    } catch (e) {
      Debug.print("asset_remote_repository", e.toString());
      return Left(AppFailure(message: "Internal Server Error"));
    }
  }

  Future<Either<AppFailure, AssetModel>> getAsset(String token) async {
    try {
      await httpService.get("/asset", {
        "Content-Type": "application/json",
        "x-auth-token": token,
      });

      if (httpService.statusCode == 200) {
        return Right(AssetModel.fromMap(httpService.response));
      } else {
        return Left(
          AppFailure(
            message: httpService.response["detail"].toString(),
          ),
        );
      }
    } catch (e) {
      Debug.print("asset_remote_repository", e.toString());
      return Left(AppFailure(
        message: "Internal server error",
      ));
    }
  }

  Future<Either<AppFailure, AssetModel>> getAssetByUserId(String token,
      {required String userId}) async {
    try {
      await httpService.get("/asset?user_id=$userId", {
        "Content-Type": "application/json",
        "x-auth-token": token,
      });

      if (httpService.statusCode == 200) {
        return Right(AssetModel.fromMap(httpService.response));
      } else {
        return Left(
          AppFailure(
            message: httpService.response["detail"].toString(),
          ),
        );
      }
    } catch (e) {
      Debug.print("asset_remote_repository", e.toString());
      return Left(AppFailure(
        message: "Internal server error",
      ));
    }
  }

  Future<Either<AppFailure, AssetModel>> updateImageList({
    List<dynamic> imageList = const [],
    required String token,
    List<int> editImageIndex = const [],
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ServerConstant.baseUrl}/asset/update-image-list'),
      );

      request.headers.addAll({
        'x-auth-token': token,
        'Content-Type': 'multipart/form-data',
      });

      for (File? image in imageList) {
        if (image != null && image.path.isNotEmpty) {
          request.files.add(
            await http.MultipartFile.fromPath(
              "image_list",
              image.path,
              filename: sanitizeFilename(image.path.split("/").last),
              contentType: _getMediaType(image),
            ),
          );
        }
      }

      request.fields.addAll(
        {
          'edit_image_index': jsonEncode(editImageIndex),
        },
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);

        if (responseBody != null) {
          final id = responseBody["id"];
          final userId = responseBody["user_id"];
          final profilePicture = responseBody["profile_picture"];
          final passionList = responseBody["passion_list"];
          final imageList = responseBody["image_list"];
          final createdAt = responseBody["created_at"];
          final updatedAt = responseBody["updated_at"];

          final List<String> modifiedPassionList = [];
          passionList.forEach((passion) => modifiedPassionList.add(passion));

          final List<String> modifiedImageList = [];
          imageList.forEach((passion) => modifiedImageList.add(passion));

          return Right(AssetModel(
            id: id,
            userId: userId,
            profilePicture: profilePicture,
            passionList: modifiedPassionList,
            imageList: modifiedImageList,
            createdAt: DateTime.parse(createdAt),
            updatedAt: DateTime.parse(updatedAt),
          ));
        } else {
          final errorBody = jsonDecode(response.body);
          Debug.print(
              "asset_remote_repository", errorBody["detail"].toString());
          return Left(AppFailure(message: "Failed to upload assets"));
        }
      } else {
        Debug.print("asset_remote_repository", jsonDecode(response.body));
        return Left(AppFailure(message: "Failed to upload assets"));
      }
    } catch (e) {
      Debug.print("asset_remote_repository", e.toString());
      return Left(AppFailure(message: "Internal Server Error"));
    }
  }

  Future<Either<AppFailure, AssetModel>> updateProfilePicture({
    required String token,
    required File profilePicture,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ServerConstant.baseUrl}/asset/update-profile-picture'),
      );

      request.headers.addAll({
        'x-auth-token': token,
        'Content-Type': 'multipart/form-data',
      });

      request.files.add(
        await http.MultipartFile.fromPath(
          'profile_picture',
          profilePicture.path,
          filename: sanitizeFilename(profilePicture.path.split('/').last),
          contentType: _getMediaType(profilePicture),
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);

        if (responseBody != null) {
          final id = responseBody["id"];
          final userId = responseBody["user_id"];
          final profilePicture = responseBody["profile_picture"];
          final passionList = responseBody["passion_list"];
          final imageList = responseBody["image_list"];
          final createdAt = responseBody["created_at"];
          final updatedAt = responseBody["updated_at"];

          final List<String> modifiedPassionList = [];
          passionList.forEach((passion) => modifiedPassionList.add(passion));

          final List<String> modifiedImageList = [];
          imageList.forEach((passion) => modifiedImageList.add(passion));

          return Right(AssetModel(
            id: id,
            userId: userId,
            profilePicture: profilePicture,
            passionList: modifiedPassionList,
            imageList: modifiedImageList,
            createdAt: DateTime.parse(createdAt),
            updatedAt: DateTime.parse(updatedAt),
          ));
        } else {
          final errorBody = jsonDecode(response.body);
          Debug.print(
              "asset_remote_repository", errorBody["detail"].toString());
          return Left(AppFailure(message: "Failed to upload assets"));
        }
      } else {
        Debug.print("asset_remote_repository", jsonDecode(response.body));
        return Left(AppFailure(message: "Failed to upload assets"));
      }
    } catch (e) {
      Debug.print("asset_remote_repository", e.toString());
      return Left(AppFailure(message: "Internal Server Error"));
    }
  }

// Helper function to get MediaType
  MediaType _getMediaType(File file) {
    final extension = file.path.split('.').last.toLowerCase();
    return MediaType('image', extension.isNotEmpty ? extension : 'jpeg');
  }
}
