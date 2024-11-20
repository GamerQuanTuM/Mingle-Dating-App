import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:social_heart/core/models/user_model.dart';

part 'profile_update_notifier.g.dart';

@riverpod
class ProfileUpdateNotifier extends _$ProfileUpdateNotifier {
  @override
  UserModel? build() {
    return null;
  }

  void updateProfile(UserModel profile) {
    state = profile;
  }
}
