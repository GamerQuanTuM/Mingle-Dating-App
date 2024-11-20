import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:social_heart/core/theme/app_pallete.dart';
import 'package:social_heart/core/widgets/app_button.dart';

class MatchWidget extends StatelessWidget {
  final String? currentUserImage;
  final String? matchUserImage;
  final String matchUserName;
  final VoidCallback onClose;
  final VoidCallback onMessage;

  const MatchWidget({
    super.key,
    this.currentUserImage,
    this.matchUserImage,
    required this.matchUserName,
    required this.onClose,
    required this.onMessage,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder(
      tween: Tween<Offset>(begin: const Offset(0, 1), end: const Offset(0, 0)),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      builder: (context, Offset offset, child) {
        return AnimatedOpacity(
          opacity: offset.dy == 0 ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: Transform.translate(
            offset: offset,
            child: Container(
              color: Pallete.primaryPurple,
              width: double.infinity,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    "It's a Match",
                    style: GoogleFonts.dancingScript(
                      textStyle: const TextStyle(
                        fontSize: 45,
                        fontWeight: FontWeight.bold,
                        color: Pallete.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    "$matchUserName likes you too",
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Pallete.white,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Transform.translate(
                        offset: const Offset(15, 0),
                        child: _buildProfileImage(currentUserImage),
                      ),
                      Transform.translate(
                        offset: const Offset(-15, 0),
                        child: _buildProfileImage(matchUserImage),
                      ),
                    ],
                  ),
                  const SizedBox(height: 60),
                  AppButton(
                    onPressed: onMessage,
                    text: "SEND A MESSAGE",
                    backgroundColor: Pallete.secondaryPurple,
                    color: Pallete.white,
                  ),
                  const SizedBox(height: 20),
                  AppButton(
                    onPressed: onClose,
                    text: "KEEP SWIPING",
                    backgroundColor: Pallete.secondaryPurple,
                    color: Pallete.white,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Helper method to build consistent profile images with equal height and width
  Widget _buildProfileImage(String? imageUrl) {
    return Container(
      width: 150,
      height: 150,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        image: DecorationImage(
          image: _getImage(imageUrl),
          fit: BoxFit.cover, // Ensure the image covers the entire circle area
        ),
      ),
    );
  }

  // Helper method to get the correct image (either NetworkImage or AssetImage)
  ImageProvider _getImage(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return const AssetImage("assets/images/default_profile.jpg");
    } else if (imageUrl == "assets/images/default_profile.jpg") {
      return const AssetImage("assets/images/default_profile.jpg");
    } else {
      return NetworkImage(imageUrl);
    }
  }
}
