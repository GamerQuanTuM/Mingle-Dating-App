import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:social_heart/core/models/asset_model.dart';

part 'current_user_asset_notifier.g.dart';

@Riverpod(keepAlive: true)
class CurrentUserAssetNotifier extends _$CurrentUserAssetNotifier {
  @override
  AssetModel? build() {
    return null;
  }

  void getAsset(AssetModel asset) {
    state = asset;
  }
}
