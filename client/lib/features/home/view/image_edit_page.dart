import 'dart:io';

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:social_heart/core/providers/current_user_asset_notifier.dart';
import 'package:social_heart/core/theme/app_pallete.dart';
import 'package:social_heart/core/utils/error_snackbar.dart';
import 'package:social_heart/core/utils/pick_file.dart';
import 'package:social_heart/core/utils/success_snackbar.dart';
import 'package:social_heart/core/widgets/app_button.dart';
import 'package:social_heart/core/widgets/loader.dart';

import 'package:social_heart/features/home/viewmodel/asset_viewmodel.dart';

class ImageEditPage extends ConsumerStatefulWidget {
  const ImageEditPage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ImageEditPageState();
}

class _ImageEditPageState extends ConsumerState<ImageEditPage> {
  List<dynamic> selectedImages = List.generate(9, (_) => null);
  final List<String> currentUserImageList = [];
  final List<int> editImageIndex = [];

  Future<bool> _showExitDialog() async {
    bool hasSelectedImages = selectedImages.any((element) => element is File);

    if (!hasSelectedImages) return true;

    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Discard Changes?'),
          content: const Text(
              'You have unsaved changes. Are you sure you want to leave?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Pallete.primaryPurple),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Leave',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    return shouldPop ?? false;
  }

  @override
  void initState() {
    super.initState();
    final currentUserAsset = ref.read(currentUserAssetNotifierProvider);
    if (currentUserAsset != null) {
      currentUserImageList.addAll(currentUserAsset.imageList);
    }
  }

  void _update(WidgetRef ref) async {
    ref
        .read(assetViewmodelProvider.notifier)
        .updateUserImageList(
          imageList: selectedImages,
          editImageIndex: editImageIndex,
        )
        .then((result) {
      if (!mounted) return;

      result.fold((failure) {
        showErrorSnackBar(context, failure.toString());
      }, (success) {
        showSuccessSnackBar(context, "Profile Images Uploaded Successfully");
        Navigator.of(context).pop();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    void pop() async {
      final bool shouldPop = await _showExitDialog();
      if (shouldPop) {
        if (!context.mounted) return;
        Navigator.of(context).pop();
      }
    }

    final isLoading = ref.watch(
        assetViewmodelProvider.select((value) => value?.isLoading == true));

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;
        pop();
      },
      child: Scaffold(
        backgroundColor: Pallete.white,
        appBar: AppBar(
          backgroundColor: Pallete.white,
          title: const Text(
            "Edit",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async => pop(),
          ),
        ),
        body: isLoading
            ? const Loader()
            : Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20.0, vertical: 32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Image Settings",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: GridView.builder(
                        itemCount: 9,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 0.7,
                        ),
                        itemBuilder: (BuildContext context, int index) {
                          return Stack(
                            children: [
                              DottedBorder(
                                color: Pallete.primaryBorder,
                                strokeWidth: 2,
                                dashPattern: const [4, 3],
                                borderType: BorderType.RRect,
                                radius: const Radius.circular(12),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: GestureDetector(
                                    onTap: () => pickImageList(index),
                                    child: selectedImages[index] is File
                                        ? Image.file(
                                            selectedImages[index]!,
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                            height: double.infinity,
                                          )
                                        : index < currentUserImageList.length
                                            ? Image.network(
                                                currentUserImageList[index],
                                                fit: BoxFit.cover,
                                                width: double.infinity,
                                                height: double.infinity,
                                                loadingBuilder: (context, child,
                                                    loadingProgress) {
                                                  if (loadingProgress == null) {
                                                    return child;
                                                  }
                                                  return Center(
                                                    child: SizedBox(
                                                      width: 60,
                                                      height: 60,
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
                                                        strokeWidth: 2,
                                                        color: Pallete
                                                            .primaryPurple,
                                                      ),
                                                    ),
                                                  );
                                                },
                                                errorBuilder: (context, error,
                                                    stackTrace) {
                                                  return Center(
                                                    child: Icon(
                                                      Icons.error_outline,
                                                      size:
                                                          45, // 30% of container size
                                                      color: Colors.red[400],
                                                    ),
                                                  );
                                                },
                                              )
                                            : Container(
                                                color: Pallete.transparent,
                                              ),
                                  ),
                                ),
                              ),
                              if (selectedImages[index] is File)
                                Positioned(
                                  right: 0,
                                  top: 2,
                                  child: GestureDetector(
                                    onTap: () => removeImage(index),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(24.0),
                                        color: Pallete.primaryPurple,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        color: Pallete.white,
                                      ),
                                    ),
                                  ),
                                )
                              else if (index >= currentUserImageList.length)
                                Positioned(
                                  right: 0,
                                  bottom: 2,
                                  child: GestureDetector(
                                    onTap: () => pickImageList(index),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(24.0),
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
                      ),
                    ),
                    const SizedBox(height: 40),
                    Center(
                      child: AppButton(
                        onPressed: () => _update(ref),
                        text: "Save",
                        backgroundColor: Pallete.primaryPurple,
                        color: Pallete.white,
                      ),
                    )
                  ],
                ),
              ),
      ),
    );
  }

  void pickImageList(int index) async {
    final pickedImage = await pickFile();

    if (pickedImage != null) {
      setState(() {
        selectedImages[index] = pickedImage;
        editImageIndex.add(index);
      });
    }
  }

  void removeImage(int index) {
    setState(() {
      selectedImages[index] = null;
      editImageIndex.add(index);
    });
  }
}
