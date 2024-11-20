import 'dart:core';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:social_heart/core/models/match_user_asset_model.dart';
import 'package:social_heart/features/home/repository/match_local_repository.dart';
import 'package:social_heart/features/home/view/single_chat_page.dart';
import 'package:social_heart/features/home/viewmodel/asset_viewmodel.dart';
import 'package:social_heart/features/home/viewmodel/matchuser_viewmodel.dart';
import 'package:social_heart/features/home/widget/match_widget.dart';
import 'package:top_modal_sheet/top_modal_sheet.dart';
import 'package:swipe_cards/swipe_cards.dart';

import 'package:social_heart/core/models/user_model.dart';
import 'package:social_heart/features/home/viewmodel/match_viewmodel.dart';

import 'package:social_heart/core/theme/app_pallete.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  late List<SwipeItem> _swipeItems;
  MatchEngine? _matchEngine;
  Gender _selectedGender = Gender.BOTH;
  RangeValues _selectedAgeRange = const RangeValues(18, 100);
  int page = 1;
  int pageSize = 30;
  bool _isLoading = false;
  bool _isEnd = false;

  Future<void> _initializeSwipeItems() async {
    if (!mounted) return;

    setState(() => _isLoading = true);
    _swipeItems.clear();

    final result =
        await ref.read(matchUserViewModelProvider.notifier).getProfilesForMatch(
              gender: _selectedGender.toShortString(),
              lowerLimitAge: _selectedAgeRange.start,
              upperLimitAge: _selectedAgeRange.end,
              page: page.toString(),
              pageSize: pageSize.toString(),
            );

    if (!mounted) return;

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failure.message),
            duration: const Duration(seconds: 2),
          ),
        );
        setState(() {
          _isLoading = false;
          _isEnd = true;
        });
      },
      (matchData) {
        if (matchData != null && matchData.users.isNotEmpty) {
          _addToSwipeCards(matchData);
          setState(() {
            _matchEngine = MatchEngine(swipeItems: _swipeItems);
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
            _isEnd = true;
          });
        }
      },
    );
  }

  void _addToSwipeCards(MatchUserAssetModel matchData) {
    for (final profile in matchData.users) {
      final UserDetails userDetail = profile.userDetails;
      _swipeItems.add(
        SwipeItem(
          content: Content(
            name: userDetail.name,
            age: userDetail.age.toString(),
            gender: userDetail.gender.toShortString(),
            imageUrl: (profile.assets != null && profile.assets!.isNotEmpty)
                ? profile.assets![0].profilePicture
                : 'assets/images/default_profile.jpg',
            passionList: (profile.assets != null &&
                    profile.assets!.isNotEmpty &&
                    profile.assets![0].passionList.isNotEmpty)
                ? profile.assets![0].passionList
                : null,
          ),
          likeAction: () => _handleLike(profile),
          nopeAction: () => _handleDislike(profile),
        ),
      );
    }
  }

  void _handleLike(UserWithAssetsModel profile) async {
    final match = await ref
        .read(matchViewModelProvider.notifier)
        .match(user2Id: profile.userDetails.id, matchType: MatchType.CREATE);

    final currentUserAsset =
        await ref.read(assetViewmodelProvider.notifier).getUserAsset();

    if (!mounted) return;
    match.fold((failure) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(failure.message),
        duration: const Duration(milliseconds: 500),
      ));
    }, (match) {
      if (match.message == "You are now matched!") {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) {
            return MatchWidget(
              matchUserImage: profile.assets!.isNotEmpty
                  ? profile.assets![0].profilePicture
                  : 'assets/images/default_profile.jpg',
              currentUserImage: currentUserAsset?.profilePicture ??
                  'assets/images/default_profile.jpg',
              matchUserName: profile.userDetails.name,
              onClose: () => Navigator.pop(context),
              onMessage: () {
                Navigator.of(context)
                    .pushReplacement(MaterialPageRoute(builder: (context) {
                  return SingleChatPage(matchUser: profile);
                }));
              },
            );
          },
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(match.message),
          duration: const Duration(milliseconds: 500),
        ));
      }
    });
  }

  void _handleDislike(UserWithAssetsModel profile) async {
    final match = await ref
        .read(matchViewModelProvider.notifier)
        .match(user2Id: profile.userDetails.id, matchType: MatchType.REJECT);
    if (!mounted) return;
    match.fold((failure) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(failure.message),
        duration: const Duration(milliseconds: 500),
      ));
    }, (match) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(match.message),
        duration: const Duration(milliseconds: 500),
      ));
    });
  }

  Future<void> _loadMoreProfiles() async {
    setState(() => page++);
    await _initializeSwipeItems();
  }

  Future<void> _applyFilters(
      Gender selectedGender, RangeValues selectedAgeRange) async {
    setState(() {
      page = 1;
      _isEnd = false;
      _selectedGender = selectedGender;
      _selectedAgeRange = selectedAgeRange;
    });
    await _initializeSwipeItems();
  }

  @override
  void initState() {
    super.initState();
    _swipeItems = <SwipeItem>[];
    Future.microtask(() => _initializeSwipeItems());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        toolbarHeight: 70,
        backgroundColor: Colors.white,
        elevation: 0,
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
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt, color: Pallete.black),
            onPressed: () async {
              final result = await showTopModalSheet<Map<String, dynamic>?>(
                context,
                _buildFilterModal(),
              );
              if (result != null) {
                await _applyFilters(
                  result['gender'] as Gender,
                  result['ageRange'] as RangeValues,
                );
              }
            },
          ),
        ],
      ),
      body: Skeletonizer(
        enabled: _isLoading,
        child: (_matchEngine == null || _swipeItems.isEmpty)
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
                          "No more matches",
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
            : Column(
                children: [
                  Expanded(
                    child: Stack(
                      children: [
                        SizedBox(
                          child: _isLoading
                              ? SwipeCards(
                                  matchEngine: _matchEngine!,
                                  itemBuilder:
                                      (BuildContext context, int index) {
                                    return _buildCardContent(
                                      Content(
                                        name: "John Doe",
                                        age: "25",
                                        gender: "Male",
                                        imageUrl:
                                            "assets/images/default_profile.jpg",
                                        passionList: [
                                          "Travel",
                                          "Music",
                                          "Sports"
                                        ],
                                      ),
                                    );
                                  },
                                  onStackFinished: () {},
                                )
                              : SwipeCards(
                                  matchEngine: _matchEngine!,
                                  itemBuilder:
                                      (BuildContext context, int index) {
                                    if (index >= _swipeItems.length) {
                                      return const SizedBox.shrink();
                                    }
                                    final content =
                                        _swipeItems[index].content as Content;
                                    return _buildCardContent(content);
                                  },
                                  onStackFinished: () {
                                    if (!_isEnd && !_isLoading) {
                                      _loadMoreProfiles();
                                    }
                                  },
                                  itemChanged: (items, index) {},
                                ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 20, horizontal: 100),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildActionButton(Icons.close, Colors.red),
                        _buildActionButton(
                            Icons.favorite, Pallete.primaryPurple),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
      ),
    );
  }

  Widget _buildCardContent(Content content) {
    return Container(
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: DecorationImage(
          image: content.imageUrl.startsWith('assets/')
              ? AssetImage(content.imageUrl)
              : NetworkImage(content.imageUrl) as ImageProvider,
          fit: BoxFit.cover,
        ),
      ),
      margin: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Pallete.transparent,
              Pallete.black.withOpacity(0.3),
              Pallete.black.withOpacity(0.5),
            ],
            stops: const [0.6, 0.8, 1.0],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Text(
                    "${content.name}, ${content.age}",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      foreground: Paint()
                        ..style = PaintingStyle.stroke
                        ..strokeWidth = 3
                        ..color = Pallete.black,
                    ),
                  ),
                  Text(
                    "${content.name}, ${content.age}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Stack(
                children: [
                  Text(
                    content.gender,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      foreground: Paint()
                        ..style = PaintingStyle.stroke
                        ..strokeWidth = 3
                        ..color = Colors.black,
                    ),
                  ),
                  Text(
                    content.gender,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if ((content.passionList ?? []).isNotEmpty)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 80),
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 6.0,
                      runSpacing: 6.0,
                      children: List<Widget>.generate(
                        content.passionList!.length > 5
                            ? 5
                            : content.passionList!.length,
                        (index) => Container(
                          constraints: const BoxConstraints(maxHeight: 32),
                          child: Chip(
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                            label: Text(
                              content.passionList![index],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                    offset: Offset(0, 0),
                                    blurRadius: 2.0,
                                    color: Pallete.black,
                                  ),
                                ],
                              ),
                            ),
                            backgroundColor: Pallete.black.withOpacity(0.3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, Color color) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
      child: IconButton(
        icon: Icon(icon, size: 30, color: Pallete.white),
        onPressed: () {
          if (_matchEngine!.currentItem != null) {
            if (icon == Icons.close) {
              _matchEngine!.currentItem?.nope();
            } else if (icon == Icons.favorite) {
              _matchEngine!.currentItem?.like();
            }
          }
        },
      ),
    );
  }

  Widget _buildFilterModal() {
    Gender tempGender = _selectedGender;
    RangeValues tempAgeRange = _selectedAgeRange;

    return StatefulBuilder(builder: (context, setState) {
      return Container(
        padding: const EdgeInsets.only(top: 20.0, left: 10.0, right: 10.0),
        height: MediaQuery.of(context).size.height * 0.50,
        width: double.infinity,
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
          color: Colors.white,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    "Filter",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.check,
                      color: Pallete.primaryPurple,
                    ),
                    onPressed: () => Navigator.pop(context, {
                      'gender': tempGender,
                      'ageRange': tempAgeRange,
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 14.0),
                      child: Text(
                        "Gender",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                tempGender = Gender.BOTH;
                              });
                            },
                            child: Container(
                              height: 45,
                              decoration: BoxDecoration(
                                color: tempGender == Gender.BOTH
                                    ? Pallete.primaryPurple
                                    : Pallete.transparent,
                                border:
                                    Border.all(color: Pallete.primaryBorder),
                                borderRadius: const BorderRadius.horizontal(
                                  left: Radius.circular(25),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  'Both',
                                  style: TextStyle(
                                    color: tempGender == Gender.BOTH
                                        ? Colors.white
                                        : Pallete.primaryBorder,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                tempGender = Gender.MALE;
                              });
                            },
                            child: Container(
                              height: 45,
                              decoration: BoxDecoration(
                                color: tempGender == Gender.MALE
                                    ? Pallete.primaryPurple
                                    : Pallete.transparent,
                                border:
                                    Border.all(color: Pallete.primaryBorder),
                                // borderRadius: const BorderRadius.horizontal(
                                //   left: Radius.circular(25),
                                // ),
                              ),
                              child: Center(
                                child: Text(
                                  'Male',
                                  style: TextStyle(
                                    color: tempGender == Gender.MALE
                                        ? Colors.white
                                        : Pallete.primaryBorder,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                tempGender = Gender.FEMALE;
                              });
                            },
                            child: Container(
                              height: 45,
                              decoration: BoxDecoration(
                                color: tempGender == Gender.FEMALE
                                    ? Pallete.primaryPurple
                                    : Pallete.transparent,
                                border:
                                    Border.all(color: Pallete.primaryBorder),
                                borderRadius: const BorderRadius.horizontal(
                                  right: Radius.circular(25),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  'Female',
                                  style: TextStyle(
                                    color: tempGender == Gender.FEMALE
                                        ? Colors.white
                                        : Pallete.primaryBorder,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 14.0),
                      child: Text(
                        "Age",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 2,
                        activeTrackColor: Pallete.primaryPurple,
                        inactiveTrackColor: Pallete.primaryBorder,
                        thumbColor: Pallete.primaryPurple,
                        overlayColor: Pallete.primaryPurple.withOpacity(0.2),
                        valueIndicatorColor: Pallete.primaryPurple,
                        valueIndicatorTextStyle:
                            const TextStyle(color: Pallete.white),
                      ),
                      child: RangeSlider(
                        values: tempAgeRange,
                        min: 18,
                        max: 100,
                        divisions: 82,
                        labels: RangeLabels(
                          tempAgeRange.start.round().toString(),
                          tempAgeRange.end.round().toString(),
                        ),
                        onChanged: (RangeValues values) {
                          setState(() {
                            tempAgeRange = values;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

class Content {
  final String name;
  final String age;
  final String gender;
  final String imageUrl;
  List<String>? passionList;

  Content({
    required this.name,
    required this.age,
    required this.gender,
    required this.imageUrl,
    this.passionList,
  });
}
