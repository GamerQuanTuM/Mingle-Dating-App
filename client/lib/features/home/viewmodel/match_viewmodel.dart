import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:social_heart/core/failure.dart';
import 'package:social_heart/core/models/match_model.dart';

import 'package:social_heart/features/auth/repository/auth_local_repository.dart';
import 'package:social_heart/features/home/repository/match_local_repository.dart';

part 'match_viewmodel.g.dart';

@riverpod
class MatchViewModel extends _$MatchViewModel {
  late AuthLocalRepository _authLocalRepository;
  late MatchLocalRepository _matchLocalRepository;

  @override
  AsyncValue<MatchModel>? build() {
    _authLocalRepository = ref.watch(authLocalRepositoryProvider);
    _matchLocalRepository = ref.watch(matchLocalRepositoryProvider);
    return null;
  }

  Future<Either<AppFailure, MatchModel>> match({
    required String user2Id,
    required MatchType matchType,
  }) async {
    final token = _authLocalRepository.getToken();

    if (token == null) {
      return Left(AppFailure(message: 'User is not authenticated'));
    }

    state = const AsyncValue.loading();

    try {
      final result = await _matchLocalRepository.match(
          token: token, user2Id: user2Id, matchType: matchType);

      state = switch (result) {
        Left(value: final l) => AsyncValue.error(l.message, StackTrace.current),
        Right(value: final r) => AsyncValue.data(r),
      };

      return result;
    } catch (e, st) {
      state = AsyncValue.error('An unexpected error occurred', st);
      return Left(AppFailure(message: 'An unexpected error occurred'));
    }
  }
}
