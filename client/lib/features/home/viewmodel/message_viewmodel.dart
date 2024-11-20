import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:social_heart/core/failure.dart';
import 'package:social_heart/core/models/message_model.dart';
import 'package:social_heart/features/auth/repository/auth_local_repository.dart';
import 'package:social_heart/features/home/providers/message_between_two_users_notifier.dart';
import 'package:social_heart/features/home/repository/message_remote_repository.dart';

part 'message_viewmodel.g.dart';

@riverpod
class MessageViewModel extends _$MessageViewModel {
  late AuthLocalRepository _authLocalRepository;
  late MessageRemoteRepository _messageRemoteRepository;
  late MessageBetweenTwoUsersNotifier _messageBetweenTwoUsersNotifier;
  @override
  AsyncValue<List<MessageModel>>? build() {
    _authLocalRepository = ref.watch(authLocalRepositoryProvider);
    _messageRemoteRepository = ref.watch(messageRemoteRepositoryProvider);
    _messageBetweenTwoUsersNotifier =
        ref.watch(messageBetweenTwoUsersNotifierProvider.notifier);
    return null;
  }

  Future<Either<AppFailure, List<MessageModel>>> getMessageBetweenTwoUsers({
    required String messageUserId,
  }) async {
    final token = _authLocalRepository.getToken();

    if (token == null) {
      Left(AppFailure(message: "User Not Authenticated"));
    }
    state = const AsyncValue.loading();

    final res = await _messageRemoteRepository.getMessageBetweenTwoUsers(
        token: token!, messageUserId: messageUserId);

    state = switch (res) {
      Left(value: final l) => AsyncValue.error(l.message, StackTrace.current),
      Right(value: final r) => _getMessageBetweenTwoUsers(r),
    };

    return res;
  }

  AsyncValue<List<MessageModel>>? _getMessageBetweenTwoUsers(
      List<MessageModel> message) {
    _messageBetweenTwoUsersNotifier.usersMessage(message);
    return state = AsyncValue.data(message);
  }
}
