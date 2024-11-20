import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:social_heart/core/models/match_user_asset_model.dart';

part 'profile_match_notifier.g.dart';

@riverpod
class ProfileMatchNotifier extends _$ProfileMatchNotifier {
  @override
  MatchUserAssetModel? build() {
    return null;
  }

  void profileMatch(MatchUserAssetModel profile) {
    state = profile;
  }
}
