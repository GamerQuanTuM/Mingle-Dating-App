import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:social_heart/core/failure.dart';
import 'package:social_heart/core/models/message_with_user_and_asset_model.dart';
import 'package:social_heart/features/auth/repository/auth_local_repository.dart';
import 'package:social_heart/features/home/providers/messages_of_user_notifier.dart';
import 'package:social_heart/features/home/repository/message_remote_repository.dart';

part 'user_messages_with_user_and_asset_viewmodel.g.dart';

@riverpod
class UserMessagesWithUserAndAssetViewModel
    extends _$UserMessagesWithUserAndAssetViewModel {
  late MessageRemoteRepository _messageRemoteRepository;
  late AuthLocalRepository _authLocalRepository;
  late MessagesOfUserNotifier _messagesOfUserNotifier;

  @override
  AsyncValue<List<MessageWithUserAndAssetModel>>? build() {
    _authLocalRepository = ref.watch(authLocalRepositoryProvider);
    _messageRemoteRepository = ref.watch(messageRemoteRepositoryProvider);
    _messagesOfUserNotifier =
        ref.watch(messagesOfUserNotifierProvider.notifier);
    return null; // Start with a null state.
  }

  Future<Either<AppFailure, List<MessageWithUserAndAssetModel>>>
      getMessagesUser() async {
    final token = _authLocalRepository.getToken();

    if (token == null) {
      return Left(AppFailure(message: "User Not Authenticated"));
    }

    final res = await _messageRemoteRepository.getMessagesUser(token: token);

    // Set state to loading while fetching data
    state = const AsyncValue.loading();

    state = switch (res) {
      Left(value: final l) =>
        AsyncValue.error(l.message, StackTrace.current), // Handle failure.
      Right(value: final r) => _setUserMessages(r), // Process messages.
    };

    return res;
  }

  AsyncValue<List<MessageWithUserAndAssetModel>> _setUserMessages(
      List<MessageWithUserAndAssetModel> messages) {
    _messagesOfUserNotifier.userMessages(messages);
    return AsyncValue.data(messages); // Store the list of messages.
  }
}
