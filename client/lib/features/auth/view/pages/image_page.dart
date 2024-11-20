import 'dart:io';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:social_heart/core/failure.dart';
import 'package:social_heart/core/repository/asset_remote_repository.dart';
import 'package:social_heart/core/theme/app_pallete.dart';
import 'package:social_heart/core/utils/error_snackbar.dart';
import 'package:social_heart/core/utils/pick_file.dart';
import 'package:social_heart/core/utils/success_snackbar.dart';
import 'package:social_heart/core/widgets/app_button.dart';
import 'package:social_heart/core/widgets/loader.dart';
import 'package:social_heart/features/auth/view/pages/phone_page.dart';

class ImagePage extends ConsumerStatefulWidget {
  final List<String?> passion;
  final String userId;
  const ImagePage({super.key, required this.passion, required this.userId});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ImagePageState();
}

class _ImagePageState extends ConsumerState<ImagePage> {
  List<File?> selectedImages = List.generate(9, (_) => null);
  File? profileImage;
  bool _isLoading = false;
  late Future<Either<AppFailure, Map<String, String>>> _asset;

  void pickProfileImage() async {
    final pickedImage = await pickFile();
    if (pickedImage != null && pickedImage is File) {
      setState(() {
        profileImage = pickedImage;
      });
    }
  }

  void removeProfileImage() {
    setState(() {
      profileImage = null;
    });
  }

  void pickImageList(int index) async {
    final pickedImage = await pickFile();

    if (pickedImage != null && pickedImage is File) {
      setState(() {
        int emptyIndex = selectedImages.indexWhere((image) => image == null);
        if (emptyIndex != -1) {
          selectedImages[emptyIndex] = pickedImage;
        } else {
          selectedImages[index] = pickedImage;
        }
      });
    }
  }

  void removeImage(int index) {
    setState(() {
      selectedImages[index] = null;
      // Filter all the images which are not null and change to list
      selectedImages = selectedImages.where((image) => image != null).toList();

      // Creating a empty list of null of length 9 - selectedImages and then appending this null list into selectedImages list
      selectedImages
          .addAll(List.generate(9 - selectedImages.length, (_) => null));
    });
  }

  Future<void> _uploadAsset() async {
    if (widget.userId.isEmpty) {
      if (!mounted) return;
      showErrorSnackBar(context, "User ID is missing. Please try again.");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    _asset = ref.read(assetRemoteRepositoryProvider).uploadAsset(
          profilePicture: profileImage,
          imageList: selectedImages,
          passionList: widget.passion,
          userId: widget.userId,
        );

    _asset.then((result) {
      if (!mounted) return;

      result.fold((failure) {
        showErrorSnackBar(context, failure.message);
      }, (success) {
        showSuccessSnackBar(context, success["message"]!);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) {
              return const PhonePage();
            },
          ),
        );
      });

      setState(() {
        _isLoading = false;
      });
    }).catchError((error) {
      if (!mounted) return;

      showErrorSnackBar(context, "An error occurred. Please try again.");
      setState(() {
        _isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Pallete.white,
      appBar: AppBar(
        backgroundColor: Pallete.white,
        elevation: 0,
        actions: _isLoading
            ? []
            : const [
                Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  child: Text(
                    "Skip",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Pallete.primaryBorder,
                    ),
                  ),
                )
              ],
      ),
      body: _isLoading
          ? const Loader()
          : DefaultTabController(
              length: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Images",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Pallete.black,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const TabBar(
                      tabs: [
                        Tab(
                          child: Text(
                            "Profile Picture",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                              color: Pallete.black,
                            ),
                          ),
                        ),
                        Tab(
                          child: Text(
                            "Image List",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                              color: Pallete.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _uploadProfilePictureWidget(context),
                          _uploadImagesWidget(context),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    AppButton(
                      text: "CONTINUE",
                      backgroundColor: Pallete.primaryPurple,
                      color: Pallete.white,
                      onPressed: _uploadAsset,
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _uploadProfilePictureWidget(BuildContext context) {
    return Center(
      child: Stack(
        children: [
          profileImage != null
              ? InkWell(
                  onTap: pickProfileImage,
                  child: DottedBorder(
                    color: Pallete.primaryBorder,
                    strokeWidth: 2,
                    dashPattern: const [4, 3],
                    borderType: BorderType.RRect,
                    radius: const Radius.circular(12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(
                        profileImage!,
                        fit: BoxFit.cover,
                        width: 300,
                        height: 400,
                      ),
                    ),
                  ),
                )
              : InkWell(
                  onTap: pickProfileImage,
                  child: DottedBorder(
                    color: Pallete.primaryBorder,
                    strokeWidth: 2,
                    dashPattern: const [4, 3],
                    borderType: BorderType.RRect,
                    radius: const Radius.circular(12),
                    child: Container(
                      height: 400,
                      width: 300,
                      color: Pallete.transparent,
                      child: Center(
                        child: Container(
                          height: 40,
                          width: 40,
                          decoration: BoxDecoration(
                            color: Pallete.primaryPurple,
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: const Icon(
                            Icons.add,
                            size: 30,
                            color: Pallete.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
          if (profileImage != null)
            Positioned(
              right: 0,
              top: 2,
              child: GestureDetector(
                onTap: removeProfileImage,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24.0),
                    color: Pallete.primaryPurple,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Pallete.white,
                    size: 30,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _uploadImagesWidget(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      itemCount: 9,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.7,
      ),
      itemBuilder: (BuildContext context, int index) {
        return Stack(
          children: [
            selectedImages[index] != null
                ? InkWell(
                    onTap: () => pickImageList(index),
                    child: DottedBorder(
                      color: Pallete.primaryBorder,
                      strokeWidth: 2,
                      dashPattern: const [4, 3],
                      borderType: BorderType.RRect,
                      radius: const Radius.circular(12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(
                          selectedImages[index]!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      ),
                    ),
                  )
                : DottedBorder(
                    color: Pallete.primaryBorder,
                    strokeWidth: 2,
                    dashPattern: const [4, 3],
                    borderType: BorderType.RRect,
                    radius: const Radius.circular(12),
                    child: Container(
                      color: Pallete.transparent,
                    ),
                  ),
            selectedImages[index] != null
                ? Positioned(
                    right: 0,
                    top: 2,
                    child: GestureDetector(
                      onTap: () => removeImage(index),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24.0),
                          color: Pallete.primaryPurple,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Pallete.white,
                        ),
                      ),
                    ),
                  )
                : Positioned(
                    right: 0,
                    bottom: 2,
                    child: GestureDetector(
                      onTap: () => pickImageList(index),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24.0),
                          color: Pallete.primaryPurple,
                        ),
                        child: const Icon(
                          Icons.add,
                          color: Pallete.white,
                        ),
                      ),
                    ),
                  ),
          ],
        );
      },
    );
  }
}
