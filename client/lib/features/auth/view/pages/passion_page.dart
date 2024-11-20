import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:social_heart/core/theme/app_pallete.dart';
import 'package:social_heart/core/utils/error_snackbar.dart';
import 'package:social_heart/core/widgets/app_button.dart';
import 'package:social_heart/features/auth/view/pages/image_page.dart';

class PassionPage extends ConsumerStatefulWidget {
  final String userId;
  const PassionPage({
    super.key,
    required this.userId,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _PassionPageState();
}

class _PassionPageState extends ConsumerState<PassionPage> {
  final List<String> passions = [
    "Harry Potter",
    "SoundCloud",
    "Spa",
    "Self-care",
    "Heavy metal",
    "House parties",
    "Gin & tonic",
    "Gymnastics",
    "Ludo",
    "Maggi",
    "Hot yoga",
    "Biryani",
    "Meditation",
    "Sushi",
    "Spotify",
    "Hockey",
    "Basketball",
    "Slam poetry",
    "Home workouts",
    "Theatre",
    "Café hopping",
    "Trainers",
    "Aquarium",
    "Instagram",
    "Hot springs",
    "Walking",
    "Running",
    "Travel",
    "Language exchange",
    "Films",
    "Guitarists",
    "Social development",
    "Gym",
    "Social media",
    "Hip hop",
    "Skincare",
    "J-Pop",
    "Cricket",
    "Shisha",
    "Freelance",
    "K-Pop",
    "Skateboarding",
    "Cooking",
    "Photography",
    "Adventure sports",
    "Volunteering",
    "Wine tasting",
    "Traveling",
    "Reading",
    "Camping",
    "Craft beer",
    "Board games",
    "Anime",
    "Fashion",
    "Baking",
    "Fitness",
    "Music festivals",
    "Cycling",
    "Podcasts",
    "Tech gadgets",
    "Meditation",
    "Sailing",
    "Fishing",
    "Writing",
    "Gardening",
    "Street food",
    "Yoga",
    "Animals",
    "Concerts",
    "Dancing",
    "Motorcycling",
    "Tattoo culture",
    "History",
    "Cryptocurrency",
    "Collecting",
    "Nature walks",
    "Home improvement",
    "DIY projects",
    "Hiking",
    "Rock climbing",
    "Surfing",
    "Martial arts",
    "Skating",
    "Singing",
    "Acting",
    "Travel photography",
    "Culinary arts",
    "Bonsai",
    "Pottery",
    "Art history",
    "Cultural festivals",
    "Astrology",
    "Science fiction",
    "Meditation retreats",
    "Luxury travel",
    "E-sports",
    "Virtual reality",
    "Meditative practices",
    "Horseback riding",
    "Team sports",
    "Puzzles",
    "Charity work",
    "Fashion design",
    "Graphic design",
    "Interior design",
    "Cryptozoology",
    "Digital art",
    "Comics",
    "Binge-watching",
    "Television shows",
    "Motivational speaking",
    "Entrepreneurship",
    "Networking",
    "Cryptocurrency trading",
    "Public speaking",
    "Social justice",
    "Mental health advocacy",
    "Environmentalism",
    "Sustainable living",
    "Wellness",
    "Personal development",
    "Coaching",
  ];

  final List<String> selectedPassion = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Pallete.white,
      appBar: AppBar(
        backgroundColor: Pallete.white,
        elevation: 0,
        actions: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) {
                      return ImagePage(
                        passion: const [],
                        userId: widget.userId,
                      );
                    },
                  ),
                );
              },
              child: const Text(
                "Skip",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Pallete.primaryBorder,
                ),
              ),
            ),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Passions",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Pallete.black,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Let everyone know what you're passionate about, by adding it to your profile.",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 30),
            const Divider(
              color: Pallete.secondaryBorder,
              thickness: 1.0,
            ),
            const SizedBox(height: 30),
            Expanded(
              child: SingleChildScrollView(
                child: Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: passions
                        .map(
                          (passion) => GestureDetector(
                            onTap: () {
                              setState(() {
                                if (selectedPassion.contains(passion)) {
                                  selectedPassion.remove(passion);
                                } else {
                                  if (selectedPassion.length <= 5) {
                                    selectedPassion.add(passion);
                                  } else {
                                    showErrorSnackBar(context,
                                        "You've selected the maximum of 5 passions");
                                    return;
                                  }
                                }
                              });
                            },
                            child: Chip(
                              backgroundColor: Pallete.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20.0),
                                side: BorderSide(
                                  color: selectedPassion.contains(passion)
                                      ? Pallete.primaryPurple
                                      : Pallete.primaryBorder,
                                  width: 2,
                                ),
                              ),
                              label: Text(
                                passion,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Pallete.black,
                                ),
                              ),
                              labelPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 2,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            AppButton(
              text: "CONTINUE (${selectedPassion.length}/5)",
              backgroundColor: Pallete.primaryPurple,
              color: Pallete.white,
              onPressed: () {
                Navigator.of(context)
                    .push(MaterialPageRoute(builder: (context) {
                  return ImagePage(
                    passion: selectedPassion,
                    userId: widget.userId,
                  );
                }));
              },
            )
          ],
        ),
      ),
    );
  }
}
