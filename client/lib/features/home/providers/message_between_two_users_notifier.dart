import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:social_heart/core/models/message_model.dart';

part 'message_between_two_users_notifier.g.dart';

@riverpod
class MessageBetweenTwoUsersNotifier extends _$MessageBetweenTwoUsersNotifier {
  @override
  List<MessageModel>? build() {
    return null;
  }

  void usersMessage(List<MessageModel> message) {
    state = message;
  }
}
