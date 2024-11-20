import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:social_heart/core/failure.dart';
import 'package:social_heart/features/auth/repository/auth_local_repository.dart';
import 'package:social_heart/features/home/repository/message_remote_repository.dart';

part 'unseen_messages_viewmodel.g.dart';

@riverpod
class UnseenMessagesViewModel extends _$UnseenMessagesViewModel {
  late MessageRemoteRepository _messageRemoteRepository;
  late AuthLocalRepository _authLocalRepository;

  @override
  AsyncValue<String>? build() {
    _authLocalRepository = ref.watch(authLocalRepositoryProvider);
    _messageRemoteRepository = ref.watch(messageRemoteRepositoryProvider);
    return null;
  }

  Future<Either<AppFailure, String>> unseenMessageCount({
    bool isUpdate = false,
    required String recipientId,
  }) async {
    final token = _authLocalRepository.getToken();

    if (token == null) {
      return Left(AppFailure(message: "User Not Authenticated"));
    }

    final res = await _messageRemoteRepository.unseenMessageCount(
        token: token, recipientId: recipientId, isUpdate: isUpdate);

    // Set state to loading while fetching data
    state = const AsyncValue.loading();

    state = switch (res) {
      Left(value: final l) => AsyncValue.error(l.message, StackTrace.current),
      Right(value: final r) => AsyncValue.data(r),
    };

    return res;
  }
}
