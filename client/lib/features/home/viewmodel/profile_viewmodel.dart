import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:social_heart/core/failure.dart';
import 'package:social_heart/core/models/user_model.dart';
import 'package:social_heart/core/providers/current_user_notifier.dart';
import 'package:social_heart/features/auth/repository/auth_local_repository.dart';
import 'package:social_heart/features/home/providers/profile_update_notifier.dart';
import 'package:social_heart/features/home/repository/profile_remote_repository.dart';

part 'profile_viewmodel.g.dart';

@riverpod
class ProfileViewModel extends _$ProfileViewModel {
  late ProfileRemoteRepository _profileRemoteRepository;
  late AuthLocalRepository _authLocalRepository;
  late CurrentUserNotifier _currentUserNotifier;
  late ProfileUpdateNotifier _profileUpdateNotifier;
  @override
  AsyncValue<UserModel>? build() {
    _profileRemoteRepository = ref.watch(profileRemoteRepositoryProvider);
    _authLocalRepository = ref.watch(authLocalRepositoryProvider);
    _profileUpdateNotifier = ref.watch(profileUpdateNotifierProvider.notifier);
    _currentUserNotifier = ref.watch(currentUserNotifierProvider.notifier);
    return null;
  }

  Future<Either<AppFailure, UserModel>> updateProfile({
    required String name,
    required String phone,
    required DateTime dob,
  }) async {
    state = const AsyncValue.loading();
    final token = _authLocalRepository.getToken();

    if (token == null) {
      return Left(AppFailure(message: 'User is not authenticated'));
    }

    final res = await _profileRemoteRepository.updateProfile(
      token: token,
      name: name,
      phone: phone,
      dob: dob,
    );

    state = switch (res) {
      Left(value: final l) => AsyncValue.error(l.message, StackTrace.current),
      Right(value: final r) => _updateProfile(r),
    };
    return res;
  }

  AsyncValue<UserModel>? _updateProfile(UserModel profile) {
    _profileUpdateNotifier.updateProfile(profile);
    _currentUserNotifier.addUser(profile.user);
    return state = AsyncValue.data(profile);
  }
}
