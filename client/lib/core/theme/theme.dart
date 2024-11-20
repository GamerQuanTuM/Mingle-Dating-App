import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:social_heart/core/theme/app_pallete.dart';

class AppTheme {
  static final lightTheme = ThemeData.light().copyWith(
    scaffoldBackgroundColor: Pallete.white,
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Pallete.white,
    ),
    textTheme: GoogleFonts.robotoTextTheme(),
  );
}
