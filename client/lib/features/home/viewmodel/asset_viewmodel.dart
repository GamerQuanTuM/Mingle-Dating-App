import 'dart:io';

import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:social_heart/core/failure.dart';
import 'package:social_heart/core/models/asset_model.dart';
import 'package:social_heart/core/providers/current_user_asset_notifier.dart';
import 'package:social_heart/core/repository/asset_remote_repository.dart';
import 'package:social_heart/features/auth/repository/auth_local_repository.dart';

part 'asset_viewmodel.g.dart';

@riverpod
class AssetViewmodel extends _$AssetViewmodel {
  late AuthLocalRepository _authLocalRepository;
  late AssetRemoteRepository _assetRemoteRepository;
  late CurrentUserAssetNotifier _currentUserAssetNotifier;
  @override
  AsyncValue<AssetModel>? build() {
    _authLocalRepository = ref.watch(authLocalRepositoryProvider);
    _assetRemoteRepository = ref.watch(assetRemoteRepositoryProvider);
    _currentUserAssetNotifier =
        ref.watch(currentUserAssetNotifierProvider.notifier);
    return null;
  }

  Future<AssetModel?> getUserAsset() async {
    final token = _authLocalRepository.getToken();

    if (token != null) {
      final res = await _assetRemoteRepository.getAsset(token);

      state = switch (res) {
        Left(value: final l) => AsyncValue.error(l.message, StackTrace.current),
        Right(value: final r) => _getCurrentUserAsset(r),
      };
    }

    return null;
  }

  Future<Either<AppFailure, AssetModel>> getUserAssetById(
      {required String userId}) async {
    final token = _authLocalRepository.getToken();

    if (token == null) {
      Left(AppFailure(message: "User Not Authenticated"));
    }

    final res =
        await _assetRemoteRepository.getAssetByUserId(token!, userId: userId);

    state = switch (res) {
      Left(value: final l) => AsyncValue.error(l.message, StackTrace.current),
      Right(value: final r) => AsyncValue.data(r),
    };

    return res;
  }

  Future<Either<AppFailure, AssetModel>> updateUserImageList({
    List<dynamic> imageList = const [],
    List<int> editImageIndex = const [],
  }) async {
    state = const AsyncValue.loading();
    final token = _authLocalRepository.getToken();

    if (token == null) {
      Left(AppFailure(message: "User Not Authenticated"));
    }

    final res = await _assetRemoteRepository.updateImageList(
      token: token!,
      imageList: imageList,
      editImageIndex: editImageIndex,
    );

    state = switch (res) {
      Left(value: final l) => AsyncValue.error(l.message, StackTrace.current),
      Right(value: final r) => _getCurrentUserAsset(r),
    };

    return res;
  }

  Future<Either<AppFailure, AssetModel>> updateUserProfilePicture({
    required File profilePicture,
  }) async {
    state = const AsyncValue.loading();
    final token = _authLocalRepository.getToken();

    if (token == null) {
      Left(AppFailure(message: "User Not Authenticated"));
    }

    final res = await _assetRemoteRepository.updateProfilePicture(
        token: token!, profilePicture: profilePicture);

    state = switch (res) {
      Left(value: final l) => AsyncValue.error(l.message, StackTrace.current),
      Right(value: final r) => _getCurrentUserAsset(r),
    };

    return res;
  }

  AsyncValue<AssetModel>? _getCurrentUserAsset(AssetModel asset) {
    _currentUserAssetNotifier.getAsset(asset);
    return state = AsyncValue.data(asset);
  }
}
