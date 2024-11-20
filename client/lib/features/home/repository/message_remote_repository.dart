import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:social_heart/core/failure.dart';
import 'package:social_heart/core/models/asset_model.dart';
import 'package:social_heart/core/models/message_model.dart';
import 'package:social_heart/core/models/message_with_user_and_asset_model.dart';
import 'package:social_heart/core/models/user_model.dart';
import 'package:social_heart/core/utils/debug.dart';
import 'package:social_heart/core/utils/http.dart';

part 'message_remote_repository.g.dart';

@riverpod
MessageRemoteRepository messageRemoteRepository(
    MessageRemoteRepositoryRef ref) {
  return MessageRemoteRepository();
}

class MessageRemoteRepository {
  final HttpService httpService = HttpService();

  Future<Either<AppFailure, List<MessageModel>>> getMessageBetweenTwoUsers({
    required String token,
    required String messageUserId,
  }) async {
    try {
      await httpService.post(
        "/message/get-message-between-two-users",
        {
          "Content-Type": "application/json",
          "x-auth-token": token,
        },
        {'message_user_id': messageUserId},
      );

      if (httpService.statusCode == 200) {
        final List<dynamic> responseData =
            httpService.response as List<dynamic>;

        final List<MessageModel> messages = responseData.map((message) {
          return MessageModel.fromMap(message as Map<String, dynamic>);
        }).toList();

        return Right(messages);
      } else {
        return Left(
          AppFailure(
            message: httpService.response["detail"].toString(),
          ),
        );
      }
    } catch (e) {
      Debug.print("message_local_repository.dart", e);
      return Left(
        AppFailure(message: "Internal Server Error"),
      );
    }
  }

  Future<Either<AppFailure, List<MessageWithUserAndAssetModel>>>
      getMessagesUser({
    required String token,
  }) async {
    try {
      await httpService.get("/message/messages-user", {
        "Content-Type": "application/json",
        "x-auth-token": token,
      });

      if (httpService.statusCode == 200) {
        final responseData = httpService.response;

        if (responseData == null) {
          return Left(AppFailure(message: "Invalid response from server."));
        }

        if (responseData == []) {
          return Left(AppFailure(message: "No messages"));
        }

        final List<MessageWithUserAndAssetModel> messages = responseData
            .map<MessageWithUserAndAssetModel>(
              (message) => MessageWithUserAndAssetModel(
                messageId: message["message_id"],
                matchId: message["match_id"],
                lastMessageContent: message["last_message_content"],
                senderId: message["sender_id"],
                lastMessageTime: DateTime.parse(message["last_message_time"]),
                interactedUserDetails:
                    UserDetails.fromMap(message["interacted_user_details"])
                        .copyWith(
                  createdAt: DateTime.parse(
                      message["interacted_user_details"]["created_at"]),
                  updatedAt: DateTime.parse(
                      message["interacted_user_details"]["updated_at"]),
                ),
                interactedUserAssets: message["interacted_user_assets"] != null
                    ? AssetModel.fromMap(message["interacted_user_assets"])
                        .copyWith(
                        createdAt: DateTime.parse(
                            message["interacted_user_assets"]["created_at"]),
                        updatedAt: DateTime.parse(
                            message["interacted_user_assets"]["updated_at"]),
                      )
                    : null,
              ),
            )
            .toList();

        return Right(messages);
      } else {
        return Left(
          AppFailure(
            message: httpService.response["detail"].toString(),
          ),
        );
      }
    } catch (e) {
      Debug.print("message_local_repository.dart", e);
      return Left(
        AppFailure(message: "Internal Server Error"),
      );
    }
  }

  Future<Either<AppFailure, String>> unseenMessageCount({
    required String recipientId,
    required String token,
    bool isUpdate = false,
  }) async {
    try {
      await httpService.post(
          isUpdate == true
              ? "/message/update-seen-messages"
              : "/message/unseen-messages-count",
          {
            "Content-Type": "application/json",
            "x-auth-token": token,
          },
          {
            "recipient_id": recipientId
          });

      if (httpService.statusCode == 200) {
        final responseData = httpService.response["message"];

        if (responseData is int) {
          return Right(responseData.toString()); // Return the unseen_count
        } else {
          throw Exception("Unexpected data type for 'message'");
        }
      } else {
        return Left(
          AppFailure(
            message: httpService.response["detail"].toString(),
          ),
        );
      }
    } catch (e) {
      Debug.print("message_local_repository.dart", e);
      return Left(AppFailure(message: "Internal Server error"));
    }
  }
}
