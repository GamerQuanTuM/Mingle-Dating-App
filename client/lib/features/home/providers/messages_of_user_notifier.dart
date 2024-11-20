import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:social_heart/core/models/message_with_user_and_asset_model.dart';

part 'messages_of_user_notifier.g.dart';

@riverpod
class MessagesOfUserNotifier extends _$MessagesOfUserNotifier {
  @override
  List<MessageWithUserAndAssetModel>? build() {
    return null;
  }

  void userMessages(List<MessageWithUserAndAssetModel> message) {
    state = message;
  }
}
