// ignore_for_file: library_prefixes
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:social_heart/core/utils/debug.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

part 'socket_io_client.g.dart';

@Riverpod(keepAlive: true)
SocketSingleton socketSingleton(SocketSingletonRef ref) {
  return SocketSingleton.instance;
}

class SocketSingleton {
  SocketSingleton._privateConstructor();
  static final SocketSingleton _instance =
      SocketSingleton._privateConstructor();
  static SocketSingleton get instance => _instance;

  IO.Socket? socket;
  final List<String> onlineUsers = [];
  String? currentUserId;

  void initSocket(String userId) {
    currentUserId = userId;
    socket = getSocket();

    socket!.connect();

    socket!.on('connect', (_) {
      Debug.print("socket_io_client", 'Connected to socket server');
      socket!.emit('login', {'user_id': userId});
      Debug.print("socket_io_client", 'User ID sent: $userId');
    });

    socket!.on("join", (data) {
      final onlineUsersData = data["online_users"];

      if (onlineUsersData is Map) {
        final filteredOnlineUsers = onlineUsersData.entries
            .where((entry) => entry.value["status"] == "ONLINE")
            .map((entry) => entry.key as String)
            .toList();

        onlineUsers
          ..clear()
          ..addAll(filteredOnlineUsers);
      }
      Debug.print("socket_io_client", "Online users updated: $onlineUsers");
    });

    socket!.on("leave", (data) {
      final userId = data['user_id'] as String?;
      if (userId != null) {
        onlineUsers.remove(userId);
      }

      Debug.print(
          "socket_io_client", "User left, updated online users: $onlineUsers");
    });

    socket!.on('disconnect', (_) {
      Debug.print("socket_io_client", 'Disconnected from socket server');
    });
  }

  void disconnect() {
    if (socket != null && socket!.connected) {
      socket!.emit('logout', {'user_id': currentUserId});
      socket!.disconnect();
      Debug.print("socket_io_client", 'Disconnected from socket server');
    }
  }

  List<String> getOnlineUsers() {
    return onlineUsers;
  }

  IO.Socket getSocket() {
    return IO.io(
      'ws://localhost:8000',
      IO.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .enableForceNew()
          .setPath('/sockets')
          .build(),
    );
  }
}
