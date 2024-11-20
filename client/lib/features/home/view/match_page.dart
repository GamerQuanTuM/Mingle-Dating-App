import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:social_heart/core/models/asset_model.dart';
import 'package:social_heart/core/models/match_model.dart';
import 'package:social_heart/core/models/match_user_asset_model.dart';
import 'package:social_heart/core/models/user_model.dart';
import 'package:social_heart/core/theme/app_pallete.dart';
import 'package:social_heart/features/home/providers/profile_match_notifier.dart';
import 'package:social_heart/features/home/providers/unseen_counts.dart';
import 'package:social_heart/features/home/view/imagelist_page.dart';
import 'package:social_heart/features/home/view/single_chat_page.dart';
import 'package:social_heart/features/home/viewmodel/matchuser_viewmodel.dart';
import 'package:social_heart/features/home/viewmodel/unseen_messages_viewmodel.dart';
import 'package:social_heart/features/home/widget/custom_error_widget.dart';

class MatchPage extends ConsumerStatefulWidget {
  const MatchPage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _MatchPageState();
}

class _MatchPageState extends ConsumerState<MatchPage> {
  void _fetchMatch() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(matchUserViewModelProvider.notifier)
          .profileMatch(matchStatus: Status.ACTIVE);
    });
  }

  @override
  initState() {
    super.initState();
    _fetchMatch();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(
        matchUserViewModelProvider.select((value) => value?.isLoading == true));
    final error =
        ref.watch(matchUserViewModelProvider.select((value) => value?.error));

    final match = ref.watch(profileMatchNotifierProvider);

    if (match == null || match.users.isEmpty) {
      return _buildEmptyState(context);
    }

    if (error != null) {
      return CustomErrorWidget(
        errorMessage: error.toString(),
        onRetry: _fetchMatch,
      );
    }

    return Scaffold(
      backgroundColor: Pallete.white,
      appBar: AppBar(
        toolbarHeight: 70,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
              onPressed: _fetchMatch,
              icon: const Icon(Icons.refresh, color: Pallete.black))
        ],
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 48),
            Image.asset(
              "assets/images/Logo-h.png",
              height: 50,
            ),
          ],
        ),
      ),
      body: isLoading
          ? _buildContent(
              context,
              MatchUserAssetModel(
                message: 'Empty state',
                users: [
                  UserWithAssetsModel(
                    userDetails: UserDetails(
                      id: "0",
                      name: "Shuvam Santra",
                      phone: "9433535685",
                      gender: Gender.MALE,
                      dob: DateTime(1999, 3, 4),
                      age: 25,
                      createdAt: DateTime(2024, 9, 7),
                      updatedAt: DateTime(2024, 9, 7),
                    ),
                  )
                ],
              ),
              true)
          : _buildContent(context, match, false),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 70,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
              onPressed: _fetchMatch,
              icon: const Icon(Icons.refresh, color: Pallete.black))
        ],
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 48),
            Image.asset(
              "assets/images/Logo-h.png",
              height: 50,
            ),
          ],
        ),
      ),
      body: Center(
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
                  "No matches found",
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
      BuildContext context, MatchUserAssetModel data, bool isLoading) {
    return Padding(
      padding: const EdgeInsets.only(top: 20.0, left: 16.0, right: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Skeletonizer(
            enabled: isLoading,
            child: Text(
              "${data.users.length} matches",
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 24),
            ),
          ),
          const SizedBox(
            height: 35,
          ),
          Expanded(
            child: Skeletonizer(
              enabled: isLoading,
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.7,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                ),
                itemBuilder: (context, index) {
                  final user = data.users[index];
                  final imageUrls = (user.assets != null &&
                          (user.assets as List<AssetModel>).isNotEmpty)
                      ? (user.assets as List<AssetModel>)[0].imageList
                      : null;
                  return InkWell(
                    onTap: () {
                      Navigator.of(context)
                          .push(MaterialPageRoute(builder: (context) {
                        return ImagelistPage(
                          imageUrls: imageUrls,
                        );
                      }));
                    },
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            image: DecorationImage(
                              image: user.assets != null &&
                                      user.assets!.isNotEmpty
                                  ? NetworkImage(user.assets![0].profilePicture)
                                  : const AssetImage(
                                      "assets/images/default_profile.jpg"),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          right: 10,
                          top: 15,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(80.0),
                              color: Pallete.tertiaryPurple.withOpacity(0.5),
                            ),
                            child: IconButton(
                              onPressed: () {
                                final unseenCountsNotifier =
                                    ref.read(unseenCountsProvider.notifier);

                                // Update the unseen count for this user
                                unseenCountsNotifier.updateItem(
                                    user.userDetails.id, 0);

                                // Mark messages as seen
                                ref
                                    .read(unseenMessagesViewModelProvider
                                        .notifier)
                                    .unseenMessageCount(
                                      recipientId: user.userDetails.id,
                                      isUpdate: true,
                                    );

                                final UserWithAssetsModel
                                    userDetailsWithAssets = UserWithAssetsModel(
                                        userDetails: user.userDetails,
                                        assets:
                                            (user.assets as List<AssetModel>)
                                                    .isNotEmpty
                                                ? user.assets
                                                : []);
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) {
                                      return SingleChatPage(
                                        matchUser: userDetailsWithAssets,
                                      );
                                    },
                                  ),
                                );
                              },
                              icon: const Icon(Icons.message),
                              color: Pallete.white,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 15,
                          left: 10,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.userDetails.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w400,
                                  fontSize: 18,
                                  color: Pallete.white,
                                  overflow: TextOverflow.ellipsis,
                                  shadows: [
                                    Shadow(
                                      blurRadius: 5.0,
                                      color: Colors.black54,
                                      offset: Offset(2.0, 2.0),
                                    ),
                                  ],
                                ),
                                maxLines: 1,
                              ),
                              Text(
                                user.userDetails.gender.toShortString(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w400,
                                  fontSize: 14,
                                  color: Pallete.white,
                                  shadows: [
                                    Shadow(
                                      blurRadius: 5.0,
                                      color: Colors.black54,
                                      offset: Offset(2.0, 2.0),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
                itemCount: data.users.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
