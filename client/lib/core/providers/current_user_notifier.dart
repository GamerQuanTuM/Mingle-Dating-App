import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:social_heart/core/models/user_model.dart';
import 'package:social_heart/features/auth/repository/auth_local_repository.dart';

part 'current_user_notifier.g.dart';

@Riverpod(keepAlive: true)
class CurrentUserNotifier extends _$CurrentUserNotifier {
  late AuthLocalRepository _authLocalRepository;
  @override
  UserDetails? build() {
    _authLocalRepository = ref.watch(authLocalRepositoryProvider);
    return null;
  }

  void addUser(UserDetails userDetails) {
    state = userDetails;
  }

  void removeUser() {
    _authLocalRepository.removeToken();
    state = null;
  }
}
