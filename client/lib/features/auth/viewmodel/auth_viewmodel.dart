import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:social_heart/core/failure.dart';
import 'package:social_heart/core/models/user_model.dart';
import 'package:social_heart/core/providers/current_user_notifier.dart';
import 'package:social_heart/features/auth/repository/auth_local_repository.dart';
import 'package:social_heart/features/auth/repository/auth_remote_repository.dart';

part "auth_viewmodel.g.dart";

@riverpod
class AuthViewModel extends _$AuthViewModel {
  late AuthRemoteRepository _authRemoteRepository;
  late AuthLocalRepository _authLocalRepository;
  late CurrentUserNotifier _currentUserNotifier;

  @override
  AsyncValue<UserModel>? build() {
    _authRemoteRepository = ref.watch(authRemoteRepositoryProvider);
    _authLocalRepository = ref.watch(authLocalRepositoryProvider);
    _currentUserNotifier = ref.watch(currentUserNotifierProvider.notifier);
    return null;
  }

  Future<void> initSharedPreferences() async {
    await _authLocalRepository.init();
  }

  Future<void> loginUser({
    required String countryCode,
    required String phone,
    required String otp,
  }) async {
    state = const AsyncValue.loading();

    final res = await _authRemoteRepository.login(
        otp: otp, phone: phone, countryCode: countryCode);

    state = switch (res) {
      Left(value: final l) => AsyncValue.error(l.message, StackTrace.current),
      Right(value: final r) => _loginSuccess(r),
    };
  }

  Future<Either<AppFailure, UserModel>> signupUser({
    required String name,
    required String phone,
    required Gender gender,
    required DateTime dob,
  }) async {
    state = const AsyncValue.loading();

    final res = await _authRemoteRepository.signup(
      name: name,
      phone: phone,
      gender: gender,
      dob: dob,
    );

    state = switch (res) {
      Left(value: final l) => AsyncValue.error(l.message, StackTrace.current),
      Right(value: final r) => AsyncValue.data(r),
    };

    // Return the response as Either for further handling by caller
    return res;
  }

  Future<UserModel?> getCurrentUser() async {
    final token = _authLocalRepository.getToken();

    if (token != null) {
      final res = await _authRemoteRepository.getCurrentUserData(token);

      state = switch (res) {
        Left(value: final l) => AsyncValue.error(l.message, StackTrace.current),
        Right(value: final r) => _getUserData(r),
      };
    }
    return null;
  }

  AsyncValue<UserModel>? _loginSuccess(UserModel userObj) {
    _authLocalRepository.setToken(userObj.token);
    _currentUserNotifier.addUser(userObj.user);
    return state = AsyncValue.data(userObj);
  }

  AsyncValue<UserModel>? _getUserData(UserModel user) {
    _currentUserNotifier.addUser(user.user);
    return state = AsyncValue.data(user);
  }
}
