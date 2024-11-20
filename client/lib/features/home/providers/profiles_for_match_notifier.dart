import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:social_heart/core/models/match_user_asset_model.dart';

part 'profiles_for_match_notifier.g.dart';

@riverpod
class ProfilesForMatchNotifier extends _$ProfilesForMatchNotifier {
  @override
  MatchUserAssetModel? build() {
    return null;
  }

  void profilesForMatch(MatchUserAssetModel profile) {
    state = profile;
  }
}
