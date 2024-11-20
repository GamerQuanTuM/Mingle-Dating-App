import 'package:fpdart/fpdart.dart';
import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:social_heart/core/failure.dart';
import 'package:social_heart/core/models/user_model.dart';
import 'package:social_heart/core/utils/debug.dart';
import 'package:social_heart/core/utils/http.dart';

part 'profile_remote_repository.g.dart';

@riverpod
ProfileRemoteRepository profileRemoteRepository(
    ProfileRemoteRepositoryRef ref) {
  return ProfileRemoteRepository();
}

class ProfileRemoteRepository {
  final HttpService httpService = HttpService();

  Future<Either<AppFailure, UserModel>> updateProfile({
    required String token,
    required String name,
    required String phone,
    required DateTime dob,
  }) async {
    try {
      String formattedDob = DateFormat('MM/dd/yyyy').format(dob);

      await httpService.put("/profile/update", {
        "Content-Type": "application/json",
        "x-auth-token": token,
      }, {
        "name": name,
        "phone": phone,
        "dob": formattedDob,
      });

      if (httpService.statusCode == 200) {
        return Right(UserModel.fromMap(httpService.response));
      } else {
        return Left(
          AppFailure(
            message: httpService.response["detail"].toString(),
          ),
        );
      }
    } catch (e) {
      Debug.print("auth_remote_repository.dart", e.toString());
      return Left(
        AppFailure(message: "Internal Server Error"),
      );
    }
  }
}
