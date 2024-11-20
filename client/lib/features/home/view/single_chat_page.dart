import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:social_heart/core/models/asset_model.dart';
import 'package:social_heart/core/models/match_user_asset_model.dart';
import 'package:social_heart/core/models/message_model.dart';
import 'package:social_heart/core/providers/current_user_notifier.dart';
import 'package:social_heart/core/providers/online_users_notifier.dart';
import 'package:social_heart/core/theme/app_pallete.dart';
import 'package:social_heart/core/utils/pick_file.dart';
import 'package:social_heart/core/utils/socket_io_client.dart';
import 'package:social_heart/core/widgets/loader.dart';
import 'package:social_heart/features/home/providers/message_between_two_users_notifier.dart';
import 'package:social_heart/features/home/viewmodel/message_viewmodel.dart';
import 'package:social_heart/features/home/viewmodel/unseen_messages_viewmodel.dart';
import 'package:social_heart/features/home/widget/custom_error_widget.dart';
import 'package:social_heart/features/home/widget/image_upload_preview_widget.dart';

class SingleChatPage extends ConsumerStatefulWidget {
  final UserWithAssetsModel matchUser;
  const SingleChatPage({super.key, required this.matchUser});

  @override
  ConsumerState<SingleChatPage> createState() => _SingleChatPageState();
}

class _SingleChatPageState extends ConsumerState<SingleChatPage>
    with WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final List<dynamic> _messages = [];
  File? _selectedFile;
  late final UserWithAssetsModel messageUser;
  final socket = SocketSingleton.instance.getSocket();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    messageUser = widget.matchUser;
    WidgetsBinding.instance.addObserver(this);
    _setupSocketListeners();
    Future.microtask(() {
      _fetchMessage();
      _markMessagesAsSeen(); // Mark messages as seen when entering chat
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _removeSocketListeners();
    _scrollController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _markMessagesAsSeen();
    }
  }

  // New method to mark messages as seen
  void _markMessagesAsSeen() {
    final currentUser = ref.read(currentUserNotifierProvider);
    if (currentUser != null) {
      final seenData = {
        'current_user_id': currentUser.id,
        'sender_id': messageUser.userDetails.id,
      };
      socket.emit('mark_messages_seen', seenData);
    }
  }

  // Helper method to safely get profile picture
  String? _getProfilePicture() {
    if (messageUser.assets != null &&
        messageUser.assets is List<AssetModel> &&
        messageUser.assets!.isNotEmpty &&
        (messageUser.assets![0]).profilePicture.isNotEmpty) {
      return (messageUser.assets![0]).profilePicture;
    }
    return null;
  }

  void _fetchMessage() {
    ref
        .read(messageViewModelProvider.notifier)
        .getMessageBetweenTwoUsers(messageUserId: messageUser.userDetails.id)
        .then((_) {
      _scrollToBottom();
    });
  }

  void _setupSocketListeners() {
    socket.on('chat', (data) {
      _handleIncomingMessage(data);
      _markMessagesAsSeen(); // Mark new messages as seen immediately
    });
  }

  void _removeSocketListeners() {
    socket.off('chat');
  }

  void _handleIncomingMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      try {
        final messageModel = MessageModel.fromMap(data);
        setState(() {
          _messages.add(messageModel);
        });
        _scrollToBottom();
        // Mark the new message as seen immediately if it's from the other user
        final currentUser = ref.read(currentUserNotifierProvider);
        if (currentUser != null && messageModel.senderId != currentUser.id) {
          _markMessagesAsSeen();
        }
      } catch (e) {
        print('Error parsing message: $e');
      }
    }
  }

  void _sendMessage() async {
    final currentUser = ref.read(currentUserNotifierProvider);
    if (currentUser != null && _messageController.text.isNotEmpty) {
      final message = {
        'current_user_id': currentUser.id,
        'message_user_id': messageUser.userDetails.id,
        'message': _messageController.text,
      };
      socket.emit('chat', message);
      await ref
          .read(unseenMessagesViewModelProvider.notifier)
          .unseenMessageCount(
            recipientId: widget.matchUser.userDetails.id,
            isUpdate: true,
          );

      _messageController.clear();
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildProfileImage() {
    final profilePicture = _getProfilePicture();
    return CircleAvatar(
      radius: 20,
      backgroundImage: profilePicture != null
          ? NetworkImage(profilePicture)
          : const AssetImage("assets/images/default_profile.jpg")
              as ImageProvider,
    );
  }

  Widget _buildMessageAvatar() {
    final profilePicture = _getProfilePicture();
    return CircleAvatar(
      radius: 16,
      backgroundImage: profilePicture != null
          ? NetworkImage(profilePicture)
          : const AssetImage("assets/images/default_profile.jpg")
              as ImageProvider,
    );
  }

  void _showMatchModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ImageUploadPreviewWidget(
        onClose: () => Navigator.pop(context),
        selectedFile: _selectedFile,
        matchUser: messageUser,
      ),
    );
  }

  void picked() async {
    final pickedFile = await pickFile();
    if (pickedFile != null && pickedFile is File) {
      setState(() {
        _selectedFile = pickedFile;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final error =
        ref.watch(messageViewModelProvider.select((value) => value?.error));
    final onlineUsers = ref.watch(onlineUsersNotifierProvider);
    final messages = ref.watch(messageBetweenTwoUsersNotifierProvider);

    // ignore: unused_local_variable
    File? file;

    if (error != null) {
      return Scaffold(
        body: Center(
          child: CustomErrorWidget(
            errorMessage: "Something went wrong",
            onRetry: _fetchMessage,
          ),
        ),
      );
    }

    if (messages == null) {
      return const Loader();
    }

    final messageList = [...messages, ..._messages];

    void picked() async {
      final pickedFile = await pickFile();
      if (pickedFile != null && pickedFile is File) {
        setState(() {
          _selectedFile = pickedFile;
        });
        _showMatchModal(); // Show modal after file is picked
      }
    }

    return Scaffold(
      backgroundColor: Pallete.white,
      appBar: AppBar(
        backgroundColor: Pallete.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Pallete.black),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            _buildProfileImage(),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  messageUser.userDetails.name,
                  style: const TextStyle(
                    color: Pallete.black,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                StatefulBuilder(
                  builder: (context, index) {
                    final isActive =
                        onlineUsers.contains(messageUser.userDetails.id);
                    return Text(
                      isActive ? "online" : "offline",
                      style: const TextStyle(
                        color: Pallete.secondaryBorder,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 15.0),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: messageList.length,
                itemBuilder: (context, index) {
                  final message = messageList[index];
                  final isCurrentUser = message.senderId ==
                      ref.read(currentUserNotifierProvider)?.id;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      mainAxisAlignment: isCurrentUser
                          ? MainAxisAlignment.end
                          : MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!isCurrentUser) ...[
                          _buildMessageAvatar(),
                          const SizedBox(width: 8),
                        ],
                        Flexible(
                          child: Container(
                            constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context).size.width - 120),
                            padding: EdgeInsets.symmetric(
                              horizontal:
                                  message.contentType == "text" ? 16 : 0,
                              vertical: message.contentType == "text" ? 12 : 0,
                            ),
                            decoration: BoxDecoration(
                              color: isCurrentUser
                                  ? (message.contentType == "text"
                                      ? Pallete.primaryPurple
                                      : Pallete.white)
                                  : (message.contentType == "text"
                                      ? Colors.grey[200]
                                      : Pallete.white),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: message.contentType == "file"
                                ? Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(
                                        height: 10,
                                      ),
                                      ClipRRect(
                                        borderRadius: BorderRadius.only(
                                            topRight: const Radius.circular(20),
                                            topLeft: const Radius.circular(20),
                                            bottomLeft: message.contentType ==
                                                            "file" &&
                                                        message.content !=
                                                            null ||
                                                    message.content == "None"
                                                ? const Radius.circular(0)
                                                : const Radius.circular(20),
                                            bottomRight: message.contentType ==
                                                            "file" &&
                                                        message.content !=
                                                            null ||
                                                    message.content == "None"
                                                ? const Radius.circular(0)
                                                : const Radius.circular(20)),
                                        child: InkWell(
                                          onTap: () {
                                            Navigator.of(context).push(
                                                MaterialPageRoute(
                                                    builder: (context) {
                                              return ImageUploadPreviewWidget(
                                                onClose: () =>
                                                    Navigator.pop(context),
                                                imageUrl: message.fileUrl,
                                                matchUser: messageUser,
                                              );
                                            }));
                                          },
                                          child: Image.network(
                                            height: 250,
                                            width: 300,
                                            scale: 0.5,
                                            message.fileUrl as String,
                                            fit: BoxFit.cover,
                                            loadingBuilder: (context, child,
                                                loadingProgress) {
                                              if (loadingProgress == null) {
                                                return child;
                                              }
                                              return Center(
                                                child:
                                                    CircularProgressIndicator(
                                                  value: loadingProgress
                                                              .expectedTotalBytes !=
                                                          null
                                                      ? loadingProgress
                                                              .cumulativeBytesLoaded /
                                                          loadingProgress
                                                              .expectedTotalBytes!
                                                      : null,
                                                ),
                                              );
                                            },
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return Container(
                                                color: Colors.grey[200],
                                                child: const Icon(
                                                  Icons.error_outline,
                                                  color: Colors.red,
                                                  size: 50,
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                      if (message.contentType == "file" &&
                                              message.content != null ||
                                          message.content == "None")
                                        Container(
                                          width:
                                              MediaQuery.of(context).size.width,
                                          decoration: BoxDecoration(
                                              borderRadius:
                                                  const BorderRadius.only(
                                                bottomRight:
                                                    Radius.circular(20),
                                                bottomLeft: Radius.circular(20),
                                              ),
                                              color: isCurrentUser
                                                  ? Pallete.primaryPurple
                                                  : Colors.grey[200]),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 12),
                                          child: Text(
                                            message.content ?? '',
                                            style: TextStyle(
                                              color: isCurrentUser
                                                  ? Pallete.white
                                                  : Pallete.black,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                      const SizedBox(
                                        height: 10,
                                      )
                                    ],
                                  )
                                : Text(
                                    message.content ?? '',
                                    style: TextStyle(
                                      color: isCurrentUser
                                          ? Pallete.white
                                          : Pallete.black,
                                      fontSize: 16,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                // bottom: MediaQuery.of(context).padding.bottom + 16,
                top: 16,
              ),
              decoration: BoxDecoration(
                color: Pallete.white,
                border: Border(
                  top: BorderSide(
                    color: Colors.grey[200]!,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Stack(
                        children: [
                          TextField(
                            controller: _messageController,
                            decoration: InputDecoration(
                              hintText: 'Type Something....',
                              hintStyle: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 16,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                          Positioned(
                              right: 15,
                              top: 0,
                              child: IconButton(
                                onPressed: picked,
                                icon: const Icon(Icons.attach_file),
                                color: Colors.grey[600],
                              ))
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Pallete.primaryPurple,
                    ),
                    child: IconButton(
                      icon:
                          const Icon(Icons.arrow_forward, color: Pallete.white),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
