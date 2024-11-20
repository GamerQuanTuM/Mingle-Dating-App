import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:social_heart/core/models/asset_model.dart';
import 'package:social_heart/core/providers/current_user_asset_notifier.dart';
import 'package:social_heart/core/providers/current_user_notifier.dart';
import 'package:social_heart/core/theme/app_pallete.dart';
import 'package:social_heart/core/utils/error_snackbar.dart';
import 'package:social_heart/core/utils/pick_file.dart';
import 'package:social_heart/core/utils/success_snackbar.dart';
import 'package:social_heart/core/widgets/loader.dart';
import 'package:social_heart/features/auth/view/pages/login_page.dart';
import 'package:social_heart/features/home/view/image_edit_page.dart';
import 'package:social_heart/features/home/view/profile_edit_page.dart';
import 'package:social_heart/features/home/viewmodel/asset_viewmodel.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _SettingsPageState();

  Size get preferredSize => const Size.fromHeight(500);
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  File? profileImage;

  void _pickProfileImage() async {
    final pickedImage = await pickFile();
    if (pickedImage != null && pickedImage is File) {
      setState(() {
        profileImage = pickedImage;
      });

      ref
          .read(assetViewmodelProvider.notifier)
          .updateUserProfilePicture(profilePicture: pickedImage)
          .then((value) {
        value.fold((failure) {
          showErrorSnackBar(context, failure.toString());
        }, (success) {
          showSuccessSnackBar(context, "Profile Picture Upload successfully");
        });
      });
    }
  }

  Widget _buildProfileImage(AssetModel? currentUserAsset) {
    if (currentUserAsset == null) {
      return Container(
        width: 150,
        height: 150,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          image: DecorationImage(
            image: AssetImage("assets/images/default_profile.jpg"),
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    final hasValidProfilePicture = currentUserAsset.profilePicture.isNotEmpty;

    return Container(
      width: 150,
      height: 150,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey[200], // Background color while loading or on error
      ),
      child: ClipOval(
        child: hasValidProfilePicture
            ? Image(
                image: NetworkImage(currentUserAsset.profilePicture),
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: SizedBox(
                      width: 60, // 40% of container size
                      height: 60,
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                        strokeWidth: 2,
                        color: Pallete.primaryPurple,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Icon(
                      Icons.error_outline,
                      size: 45, // 30% of container size
                      color: Colors.red[400],
                    ),
                  );
                },
              )
            : Image.asset(
                "assets/images/default_profile.jpg",
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Icon(
                      Icons.person,
                      size: 75, // 50% of container size
                      color: Colors.grey[400],
                    ),
                  );
                },
              ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserAsset = ref.watch(currentUserAssetNotifierProvider);
    final currentUser = ref.watch(currentUserNotifierProvider);

    // final isCurrentUserLoading = ref.watch(
    //     authViewModelProvider.select((value) => value?.isLoading == true));

    final isCurrentUserAssetLoading = ref.watch(
        assetViewmodelProvider.select((value) => value?.isLoading == true));

    if (currentUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) {
                WidgetsBinding.instance.addPostFrameCallback(
                  (_) {
                    showSuccessSnackBar(context, "Successfully logged out!!!");
                  },
                );
                return const LoginPage();
              },
            ),
            (route) => false,
          );
        }
      });
      return const Scaffold(
        body: Center(
          child: Loader(),
        ),
      );
    }
    return Scaffold(
      backgroundColor: Pallete.white,
      appBar: AppBar(
          backgroundColor: Pallete.tertiaryPurple,
          elevation: 0,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(width: 48),
              Padding(
                padding: const EdgeInsets.only(top: 13.0),
                child: Image.asset(
                  "assets/images/Logo-h.png",
                  height: 50,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              onPressed: () {
                ref.watch(currentUserNotifierProvider.notifier).removeUser();
              },
              icon: const Icon(Icons.logout, color: Pallete.white),
            )
          ]),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(
          children: [
            ClipPath(
              clipper: BottomWaveClipper(),
              child: Container(
                height: 250,
                color: Pallete.tertiaryPurple,
                child: Center(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      isCurrentUserAssetLoading
                          ? Container(
                              width: 150,
                              height: 150,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Pallete.white,
                              ),
                              child: const Center(
                                child: Loader(),
                              ),
                            )
                          : Stack(
                              children: [
                                _buildProfileImage(currentUserAsset),
                                Positioned(
                                  right: 2,
                                  top: 2,
                                  child: Container(
                                    padding: const EdgeInsets.all(0.5),
                                    decoration: const BoxDecoration(
                                      color: Pallete.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: IconButton(
                                      color: Pallete.primaryPurple,
                                      onPressed: _pickProfileImage,
                                      icon: const Icon(
                                        Icons.edit,
                                        size: 15,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                      const SizedBox(height: 15),
                      Text(
                        "${currentUser.name}, ${currentUser.age.toString()}",
                        style: const TextStyle(
                          color: Pallete.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 35),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Text(
                        "User Details",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Expanded(child: SizedBox()),
                      InkWell(
                        onTap: () {
                          Navigator.of(context)
                              .push(MaterialPageRoute(builder: (context) {
                            return ProfileEditPage(currentUser: currentUser);
                          }));
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(right: 14.0),
                          child: Text(
                            "Edit",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.blue[600],
                              decoration: TextDecoration.underline,
                              decorationColor: Colors.blue[600],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  _mappingFieldWithLabel("Name", currentUser.name),
                  const SizedBox(
                    height: 20,
                  ),
                  _mappingFieldWithLabel("Phone", currentUser.phone),
                  const SizedBox(
                    height: 20,
                  ),
                  _mappingFieldWithLabel(
                    "Date of birth",
                    DateFormat('dd/MM/yyyy').format(currentUser.dob),
                  ),
                  const SizedBox(
                    height: 30,
                  ),
                  Row(
                    children: [
                      const Text(
                        "User Images",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Expanded(child: SizedBox()),
                      InkWell(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) {
                              return const ImageEditPage();
                            },
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(right: 14.0),
                          child: Text(
                            "Edit",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.blue[600],
                              decoration: TextDecoration.underline,
                              decorationColor: Colors.blue[600],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 15,
                  ),
                  _mappingFieldWithLabel(
                    "No of images",
                    currentUserAsset != null
                        ? currentUserAsset.imageList.length.toString()
                        : "0",
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _mappingFieldWithLabel(String label, String userDetails) {
    return Column(
      children: [
        Container(
          height: 35,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            border: Border.all(
              color: Pallete.primaryBorder,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 14.0),
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Pallete.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Expanded(child: SizedBox()),
              Padding(
                padding: const EdgeInsets.only(right: 14.0),
                child: Text(
                  userDetails,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Pallete.secondaryBorder,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class BottomWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 20);
    path.quadraticBezierTo(
      size.width / 2,
      size.height + 20,
      size.width,
      size.height - 20,
    );
    path.lineTo(size.width, 0);
    path.lineTo(0, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
