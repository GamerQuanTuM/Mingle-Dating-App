import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'unseen_counts.g.dart';

@riverpod
class UnseenCounts extends _$UnseenCounts {
  @override
  Map<String, int> build() {
    return {};
  }

  void addItem(String key, int value) {
    // Fix: Use key parameter instead of string literal 'key'
    state = {...state, key: value};
  }

  void removeItem(String key) {
    final newState = {...state};
    newState.remove(key);
    state = newState;
  }

  void updateItem(String key, int value) {
    // Fix: Create a new map with the key parameter
    final newState = Map<String, int>.from(state);
    newState[key] = value;
    state = newState;
  }

  int? getItem(String key) {
    return state[key];
  }

  void clear() {
    state = {};
  }
}
