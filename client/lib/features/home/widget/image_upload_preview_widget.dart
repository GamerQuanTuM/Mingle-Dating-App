import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:social_heart/core/models/match_user_asset_model.dart';
import 'package:social_heart/core/providers/current_user_notifier.dart';
import 'package:social_heart/core/theme/app_pallete.dart';
import 'package:social_heart/core/utils/socket_io_client.dart';
import 'package:social_heart/features/home/viewmodel/unseen_messages_viewmodel.dart';

class ImageUploadPreviewWidget extends ConsumerStatefulWidget {
  final VoidCallback onClose;
  final File? selectedFile;
  final String? imageUrl;
  final UserWithAssetsModel matchUser;

  const ImageUploadPreviewWidget({
    super.key,
    required this.onClose,
    this.selectedFile,
    this.imageUrl,
    required this.matchUser,
  });

  @override
  ConsumerState<ImageUploadPreviewWidget> createState() =>
      _ImageUploadPreviewWidgetState();
}

class _ImageUploadPreviewWidgetState
    extends ConsumerState<ImageUploadPreviewWidget> {
  final TextEditingController _messageController = TextEditingController();
  final socket = SocketSingleton.instance.getSocket();
  late final UserWithAssetsModel messageUser;

  @override
  void initState() {
    super.initState();
    messageUser = widget.matchUser;
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Widget _buildImage() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxHeight = constraints.maxHeight;
        final maxWidth = constraints.maxWidth;

        return Container(
          constraints: BoxConstraints(
            maxHeight: maxHeight * 0.7, // Use 70% of available height
            maxWidth: maxWidth,
          ),
          child: Center(
            child: AspectRatio(
              aspectRatio: 3 / 4, // Maintain a 3:4 aspect ratio
              child: ClipRRect(
                borderRadius:
                    BorderRadius.circular(12), // Optional rounded corners
                child: widget.selectedFile != null
                    ? Image.file(
                        widget.selectedFile!,
                        fit: BoxFit.contain,
                        alignment: Alignment.center,
                      )
                    : Image.network(
                        widget.imageUrl!,
                        fit: BoxFit.contain,
                        alignment: Alignment.center,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
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
          ),
        );
      },
    );
  }

  void _sendMessage() async {
    final currentUser = ref.read(currentUserNotifierProvider);

    if (currentUser != null &&
        (widget.selectedFile != null || _messageController.text.isNotEmpty)) {
      String? encodedFile;
      if (widget.selectedFile != null) {
        final bytes = await widget.selectedFile!.readAsBytes();
        encodedFile = base64Encode(bytes);
      }

      final message = {
        'current_user_id': currentUser.id,
        'message_user_id': messageUser.userDetails.id,
        'message':
            _messageController.text.isNotEmpty ? _messageController.text : null,
        'file': encodedFile,
      };

      socket.emit('chat', message);

      await ref
          .read(unseenMessagesViewModelProvider.notifier)
          .unseenMessageCount(
            recipientId: widget.matchUser.userDetails.id,
            isUpdate: true,
          );

      _messageController.clear();
      widget.onClose();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please type a message or select a file to send.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: TweenAnimationBuilder<Offset>(
        tween:
            Tween<Offset>(begin: const Offset(0, 1), end: const Offset(0, 0)),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
        builder: (context, offset, child) {
          return AnimatedOpacity(
            opacity: offset.dy == 0 ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: Transform.translate(
              offset: offset,
              child: Container(
                padding: EdgeInsets.only(
                  top: 40.0,
                  left: 10.0,
                  right: 10.0,
                  bottom: MediaQuery.of(context).padding.bottom + 15,
                ),
                color: Pallete.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      onPressed: widget.onClose,
                      icon: const Icon(Icons.close, size: 30),
                    ),
                    const SizedBox(height: 20),
                    if (widget.selectedFile != null || widget.imageUrl != null)
                      Expanded(child: _buildImage()),
                    if (widget.imageUrl == null)
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 16,
                          right: 16,
                          top: 16,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: TextField(
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
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Pallete.primaryPurple,
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.arrow_forward,
                                    color: Pallete.white),
                                onPressed: _sendMessage,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
