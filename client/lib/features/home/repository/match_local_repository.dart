// ignore_for_file: constant_identifier_names

import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:social_heart/core/failure.dart';
import 'package:social_heart/core/models/match_model.dart';
import 'package:social_heart/core/models/match_user_asset_model.dart';
import 'package:social_heart/core/utils/debug.dart';
import 'package:social_heart/core/utils/http.dart';

part 'match_local_repository.g.dart';

@riverpod
MatchLocalRepository matchLocalRepository(MatchLocalRepositoryRef ref) {
  return MatchLocalRepository();
}

enum MatchType { CREATE, REJECT }

class MatchLocalRepository {
  final HttpService httpService = HttpService();

  Future<Either<AppFailure, dynamic>> getProfilesForMatch({
    required String token,
    String? passionList,
    String? page,
    String? pageSize,
    double? lowerLimitAge,
    double? upperLimitAge,
    String? gender,
  }) async {
    try {
      final queryParams = <String, String>{
        if (page != null) 'page': page,
        if (pageSize != null) 'page_size': pageSize,
        if (lowerLimitAge != null) 'low_age': lowerLimitAge.toString(),
        if (upperLimitAge != null) 'up_age': upperLimitAge.toString(),
        if (gender != null) 'gender': gender,
        if (passionList != null) 'passion_list': passionList,
      };

      // Construct URL with query parameters
      final queryString = queryParams.entries
          .map((e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&');

      final url =
          '/match/suggest-profile-for-match${queryString.isNotEmpty ? '?$queryString' : ''}';
      await httpService.get(
        url,
        {
          "Content-Type": "application/json",
          "x-auth-token": token,
        },
      );

      if (httpService.statusCode == 200) {
        return Right(
          MatchUserAssetModel.fromMap(httpService.response),
        );
      } else {
        return Left(
          AppFailure(
            message: httpService.response["detail"].toString(),
          ),
        );
      }
    } catch (e) {
      Debug.print("match_local_repository.dart", e);

      return Left(
        AppFailure(message: "Internal Server Error"),
      );
    }
  }

  Future<Either<AppFailure, MatchModel>> match({
    required String token,
    required String user2Id,
    required MatchType matchType,
  }) async {
    String url = "";

    if (matchType == MatchType.CREATE) {
      url = "/match/create-match";
    } else if (matchType == MatchType.REJECT) {
      url = "/match/reject-match";
    }
    try {
      await httpService.post(url, {
        "Content-Type": "application/json",
        "x-auth-token": token,
      }, {
        "user2_id": user2Id
      });

      if (httpService.statusCode == 200) {
        return Right(MatchModel.fromMap(httpService.response));
      } else {
        return Left(
            AppFailure(message: httpService.response["detail"].toString()));
      }
    } catch (e) {
      return Left(
        AppFailure(message: "Internal Server Error"),
      );
    }
  }

  Future<Either<AppFailure, MatchUserAssetModel>> profileMatch(
      {required String token, required Status matchStatus}) async {
    try {
      await httpService.get(
          "/match/match-profile?match_status=${matchStatus.toShortString()}", {
        "Content-Type": "application/json",
        "x-auth-token": token,
      });

      if (httpService.statusCode == 200) {
        return Right(MatchUserAssetModel.fromMap(httpService.response));
      } else {
        return Left(
            AppFailure(message: httpService.response["detail"].toString()));
      }
    } catch (e) {
      return Left(
        AppFailure(message: "Internal Server Error"),
      );
    }
  }
}
