import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:social_heart/core/failure.dart';
import 'package:social_heart/core/models/match_model.dart';
import 'package:social_heart/core/models/match_user_asset_model.dart';

import 'package:social_heart/features/auth/repository/auth_local_repository.dart';
import 'package:social_heart/features/home/providers/profile_match_notifier.dart';
import 'package:social_heart/features/home/providers/profiles_for_match_notifier.dart';
import 'package:social_heart/features/home/repository/match_local_repository.dart';

part 'matchuser_viewmodel.g.dart';

@riverpod
class MatchUserViewModel extends _$MatchUserViewModel {
  late AuthLocalRepository _authLocalRepository;
  late MatchLocalRepository _matchLocalRepository;
  late ProfilesForMatchNotifier _profilesForMatchNotifier;
  late ProfileMatchNotifier _profileMatchNotifier;

  @override
  AsyncValue<MatchUserAssetModel>? build() {
    _authLocalRepository = ref.watch(authLocalRepositoryProvider);
    _matchLocalRepository = ref.watch(matchLocalRepositoryProvider);
    _profileMatchNotifier = ref.watch(profileMatchNotifierProvider.notifier);
    _profilesForMatchNotifier =
        ref.watch(profilesForMatchNotifierProvider.notifier);
    return null;
  }

  Future<Either<AppFailure, MatchUserAssetModel?>> getProfilesForMatch({
    String? passionList,
    String? page,
    String? pageSize,
    double? lowerLimitAge,
    double? upperLimitAge,
    String? gender,
  }) async {
    final token = _authLocalRepository.getToken();

    if (token == null) {
      return Left(AppFailure(message: 'User is not authenticated'));
    }

    state = const AsyncValue.loading();

    try {
      final result = await _matchLocalRepository.getProfilesForMatch(
          token: token,
          passionList: passionList,
          page: page,
          pageSize: pageSize,
          lowerLimitAge: lowerLimitAge,
          upperLimitAge: upperLimitAge,
          gender: gender);

      return result.match(
        (failure) {
          state = AsyncValue.error(failure.message, StackTrace.current);
          return Left(failure);
        },
        (user) {
          _profilesForMatchNotifier.profilesForMatch(user);
          state = AsyncValue.data(user);
          return Right(user);
        },
      );
    } catch (e, st) {
      state = AsyncValue.error('An unexpected error occurred', st);
      return Left(AppFailure(
          message:
              'An unexpected error occurred')); // Return Left for catch block
    }
  }

  Future<Either<AppFailure, MatchUserAssetModel>> profileMatch(
      {required Status matchStatus}) async {
    final token = _authLocalRepository.getToken();
    if (token == null) {
      return Left(AppFailure(message: 'User is not authenticated'));
    }

    state = const AsyncValue.loading();

    try {
      final result = await _matchLocalRepository.profileMatch(
          token: token, matchStatus: matchStatus);

      return result.fold((failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
        return Left(failure);
      }, (match) {
        _profileMatchNotifier.profileMatch(match);
        state = AsyncValue.data(match);
        return Right(match);
      });
    } catch (e, st) {
      state = AsyncValue.error('An unexpected error occurred', st);
      return Left(AppFailure(message: 'An unexpected error occurred'));
    }
  }
}
