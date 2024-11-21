import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:social_heart/core/models/asset_model.dart';
import 'package:social_heart/core/models/match_user_asset_model.dart';
import 'package:social_heart/core/models/user_model.dart';
import 'package:social_heart/core/providers/current_user_notifier.dart';
import 'package:social_heart/core/theme/app_pallete.dart';
import 'package:social_heart/core/utils/socket_io_client.dart';
import 'package:social_heart/core/widgets/loader.dart';
import 'package:social_heart/features/home/providers/messages_of_user_notifier.dart';
import 'package:social_heart/features/home/providers/unseen_counts.dart';
import 'package:social_heart/features/home/view/single_chat_page.dart';
import 'package:social_heart/features/home/viewmodel/unseen_messages_viewmodel.dart';
import 'package:social_heart/features/home/viewmodel/user_messages_with_user_and_asset_viewmodel.dart';
import 'package:social_heart/features/home/widget/custom_error_widget.dart';

class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key});

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage>
    with WidgetsBindingObserver {
  final socket = SocketSingleton.instance.getSocket();
  // Map<String, int> unseenCounts = {};
  String? currentChatUserId;

  // void _showMatchModal() {
  //   showModalBottomSheet(
  //     context: context,
  //     isScrollControlled: true,
  //     backgroundColor: Colors.transparent,
  //     builder: (context) => MatchWidget(
  //       currentUserImage:
  //           'https://plus.unsplash.com/premium_photo-1661297485356-2497102824d0?q=80&w=1887&auto=format&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
  //       matchUserImage:
  //           'https://images.unsplash.com/photo-1692842134190-d31cb40db1ec?w=500&auto=format&fit=crop&q=60&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8M3x8YmlraW5pJTIwbW9kZWx8ZW58MHx8MHx8fDA%3D',
  //       matchUserName: 'Lucy',
  //       onClose: () => Navigator.pop(context),
  //       onMessage: () {
  //         Navigator.pop(context);
  //       },
  //     ),
  //   );
  // }

  String _formatMessageTime(DateTime lastMessageTime) {
    final difference = DateTime.now().difference(lastMessageTime);

    // Check if the message is from today, yesterday, or an older date
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else {
      // Format the date as 'MMM dd, yyyy' if it's older than yesterday
      return DateFormat('MMM dd, yyyy').format(lastMessageTime);
    }
  }

  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeData();
  }

  Future<void> _initializeData() async {
    if (!_isInitialized) {
      await _getMessages();
      await _initializeUnseenCounts();
      _setupSocketListener();
      _isInitialized = true;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _removeSocketListeners();
    super.dispose();
  }

  void _removeSocketListeners() {
    socket.off("chat_message");
    socket.off("chat");
    socket.off("message_seen");
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _initializeData();
    }
  }

  Future<void> _initializeUnseenCounts() async {
    final messages = ref.read(messagesOfUserNotifierProvider);
    if (messages != null) {
      for (var message in messages) {
        await _updateUnseenCount(message.interactedUserDetails.id);
      }
    }
  }

  Future<void> _updateUnseenCount(String userId) async {
    if (mounted) {
      final count = await ref
          .read(unseenMessagesViewModelProvider.notifier)
          .unseenMessageCount(recipientId: userId);

      final unseenCounts = ref.read(unseenCountsProvider);

      count.fold(
        (failure) => null,
        (count) {
          if (mounted) {
            setState(() {
              unseenCounts[userId] = int.parse(count);
            });
          }
        },
      );
    }
  }

  void _setupSocketListener() {
    // Remove existing listeners before adding new ones
    _removeSocketListeners();

    socket.on("chat_message", (data) async {
      if (data != null) {
        final senderId = data['sender_id'];

        // Only update count if we're not currently viewing that user's chat
        if (senderId != currentChatUserId) {
          await _updateUnseenCount(senderId);
          // Refresh messages list to show latest message
          await _getMessages();
        }
      }
    });

    socket.on("chat", (data) async {
      if (data != null) {
        await _getMessages();
        // Update counts for all users after new message
        await _initializeUnseenCounts();
      }
    });

    socket.on("message_seen", (data) async {
      if (data != null) {
        final unseenCounts = ref.read(unseenCountsProvider);
        final senderId = data['sender_id'];
        if (mounted) {
          setState(() {
            unseenCounts[senderId] = 0;
          });
        }
      }
    });
  }

  UserDetails? _getCurrentUser() {
    return ref.read(currentUserNotifierProvider);
  }

  Future<void> _getMessages() {
    return ref
        .read(userMessagesWithUserAndAssetViewModelProvider.notifier)
        .getMessagesUser();
  }

  void _navigateToChat({required UserWithAssetsModel matchUser}) {
    final unseenCounts = ref.read(unseenCountsProvider);
    // Reset unseen count when entering chat
    setState(() {
      currentChatUserId = matchUser.userDetails.id;
      unseenCounts[matchUser.userDetails.id] = 0;
    });

    // Mark messages as seen
    ref.read(unseenMessagesViewModelProvider.notifier).unseenMessageCount(
          recipientId: matchUser.userDetails.id,
          isUpdate: true,
        );

    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (context) => SingleChatPage(matchUser: matchUser),
      ),
    )
        .then((_) {
      // Reset current chat user when returning
      setState(() {
        currentChatUserId = null;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(userMessagesWithUserAndAssetViewModelProvider
        .select((value) => value?.isLoading == true));

    final error = ref.watch(userMessagesWithUserAndAssetViewModelProvider
        .select((value) => value?.error));

    final messages = ref.watch(messagesOfUserNotifierProvider);

    final unseenCounts = ref.watch(unseenCountsProvider);

    return Scaffold(
      backgroundColor: Pallete.white,
      appBar: AppBar(
        toolbarHeight: 70,
        backgroundColor: Colors.white,
        elevation: 0,
        title: Center(
          child: Image.asset(
            "assets/images/Logo-h.png",
            height: 50,
          ),
        ),
      ),
      body: isLoading
          ? const Loader()
          : error != null
              ? CustomErrorWidget(
                  errorMessage: "Something went wrong", onRetry: _getMessages)
              : (messages != null && messages.isNotEmpty && messages != []
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20.0),
                      child: ListView.builder(
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          final unseenCount =
                              unseenCounts[message.interactedUserDetails.id] ??
                                  0;

                          final time =
                              _formatMessageTime(message.lastMessageTime);

                          final isUser =
                              _getCurrentUser()!.id == message.senderId
                                  ? false
                                  : true;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10.0),
                            child: InkWell(
                              onTap: () {
                                _navigateToChat(
                                  matchUser: UserWithAssetsModel(
                                    userDetails: message.interactedUserDetails,
                                    assets: message.interactedUserAssets != null
                                        ? [message.interactedUserAssets!]
                                        : [],
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20.0, vertical: 10.0),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 50.0,
                                      height: 50.0,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        image: DecorationImage(
                                          fit: BoxFit.cover,
                                          image: message.interactedUserAssets !=
                                                  null
                                              ? NetworkImage(
                                                  (message.interactedUserAssets
                                                          as AssetModel)
                                                      .profilePicture,
                                                )
                                              : const AssetImage(
                                                      "assets/images/default_profile.jpg")
                                                  as ImageProvider,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(
                                      width: 20.0,
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          message.interactedUserDetails.name,
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: unseenCount > 0
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                          ),
                                        ),
                                        Container(
                                          constraints: BoxConstraints(
                                              maxWidth: MediaQuery.of(context)
                                                      .size
                                                      .width -
                                                  150),
                                          child: Text.rich(
                                            TextSpan(
                                              children: [
                                                TextSpan(
                                                  text: !isUser
                                                      ? "You: "
                                                      : '${message.interactedUserDetails.name}: ',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: unseenCount > 0
                                                        ? FontWeight.w500
                                                        : FontWeight.w400,
                                                    color: unseenCount > 0
                                                        ? Pallete.black
                                                        : Pallete.primaryBorder,
                                                  ),
                                                ),
                                                TextSpan(
                                                  text: message
                                                              .lastMessageContent ==
                                                          "You have not messaged anyone yet"
                                                      ? "'\u{1F4C1} File'"
                                                      : message
                                                          .lastMessageContent,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: unseenCount > 0
                                                        ? FontWeight.w500
                                                        : FontWeight.w400,
                                                    color: unseenCount > 0
                                                        ? Pallete.black
                                                        : Pallete.primaryBorder,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.start,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Expanded(child: SizedBox()),
                                    unseenCount > 0
                                        ? Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: const BoxDecoration(
                                              color: Pallete.primaryPurple,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Text(
                                              unseenCount.toString(),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          )
                                        : Text(
                                            time,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w400,
                                              color: Colors.grey,
                                            ),
                                          ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    )
                  : (error != []
                      ? Center(
                          child: SizedBox(
                            height: MediaQuery.of(context).size.height * 0.7,
                            width: MediaQuery.of(context).size.width * 0.8,
                            child: DottedBorder(
                              color: Pallete.primaryBorder,
                              strokeWidth: 2,
                              dashPattern: const [4, 3],
                              borderType: BorderType.RRect,
                              radius: const Radius.circular(12),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: const Center(
                                  child: Text(
                                    "No messages sent",
                                    style: TextStyle(
                                      fontSize: 25,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        )
                      : Container())),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: _showMatchModal,
      //   backgroundColor: Pallete.primaryPurple,
      //   child: const Icon(Icons.message),
      // ),
    );
  }
}
