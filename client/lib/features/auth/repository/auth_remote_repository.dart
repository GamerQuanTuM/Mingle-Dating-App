import 'package:fpdart/fpdart.dart';
import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:social_heart/core/failure.dart';
import 'package:social_heart/core/models/user_model.dart';
import 'package:social_heart/core/utils/debug.dart';
import 'package:social_heart/core/utils/http.dart';

part 'auth_remote_repository.g.dart';

@riverpod
AuthRemoteRepository authRemoteRepository(AuthRemoteRepositoryRef ref) {
  return AuthRemoteRepository();
}

class AuthRemoteRepository {
  final HttpService httpService = HttpService();

  Future<Either<AppFailure, UserModel>> signup({
    required String name,
    required String phone,
    required Gender gender,
    required DateTime dob,
  }) async {
    try {
      String formattedDob = DateFormat('MM/dd/yyyy').format(dob);
      await httpService.post(
        '/auth/signup',
        {
          "Content-Type": "application/json",
        },
        {
          "name": name,
          "phone": phone,
          "gender": gender.toShortString(),
          "dob": formattedDob,
        },
      );

      if (httpService.statusCode == 201) {
        return Right(
          UserModel.fromMap(httpService.response),
        );
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

  Future<Either<AppFailure, String>> generateOTP({
    required String countryCode,
    required String phone,
  }) async {
    try {
      await httpService.post(
        '/auth/generate-otp',
        {
          "Content-Type": "application/json",
        },
        {
          "country_code": countryCode,
          "phone": phone,
        },
      );

      if (httpService.statusCode == 200) {
        return Right(httpService.response["message"]);
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

  Future<Either<AppFailure, UserModel>> login({
    required String countryCode,
    required String phone,
    required String otp,
  }) async {
    try {
      await httpService.post(
        '/auth/login',
        {
          "Content-Type": "application/json",
        },
        {"phone": phone, "country_code": countryCode, "otp": otp},
      );

      if (httpService.statusCode == 200) {
        return Right(
          UserModel.fromMap(httpService.response),
        );
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

  Future<Either<AppFailure, UserModel>> getCurrentUserData(String token) async {
    try {
      await httpService.get(
        '/auth',
        {"Content-Type": "application/json", "x-auth-token": token},
      );

      if (httpService.statusCode == 200) {
        UserModel userModel = UserModel(
          message: httpService.response["message"],
          token: token,
          user: UserDetails.fromMap(httpService.response["user"]),
        );
        return Right(userModel);
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
