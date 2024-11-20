import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:social_heart/core/utils/socket_io_client.dart';
// import 'package:social_heart/core/utils/socket_io_client.dart';

part 'online_users_notifier.g.dart';

// What Happens Behind the Scenes
// Here’s what typically happens in a Riverpod and socket-based architecture:

// 1. The backend sends data via the socket.
// 2. The socket layer listens to events (join, leave).
// 3. The socket processes and cleans the data (e.g., filtering out invalid users).
// 4. The socket forwards the cleaned data to Riverpod.
// 5. Riverpod updates its state provider (e.g., onlineUsersProvider).
// 6. The UI reacts to changes in the state provider.

// Then update the OnlineUsersNotifier
@Riverpod(keepAlive: true)
class OnlineUsersNotifier extends _$OnlineUsersNotifier {
  late SocketSingleton _socketSingleton;

  @override
  List<String> build() {
    _socketSingleton = ref.watch(socketSingletonProvider);

    // Listen to socket events and update state
    _socketSingleton.socket?.on('join', (data) {
      _updateOnlineUsers(data);
    });

    _socketSingleton.socket?.on('leave', (data) {
      _updateOnlineUsers();
    });

    // ref.onDispose(() {
    //   // Clean up socket listeners when the notifier is disposed
    //   _socketSingleton.socket?.off('join');
    //   _socketSingleton.socket?.off('leave');
    // });

    // Return initial list of online users
    return List<String>.from(_socketSingleton.onlineUsers);
  }

  void _updateOnlineUsers([dynamic data]) {
    // Sync onlineUsers from the singleton
    state = List<String>.from(_socketSingleton.onlineUsers);
  }
}
