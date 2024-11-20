import 'package:flutter/material.dart';

class AppButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final Color color;
  final Color backgroundColor;
  final double perWidth;
  final String? iconPath;

  const AppButton({
    super.key,
    required this.text,
    this.iconPath,
    this.onPressed,
    this.backgroundColor = Colors.white,
    this.color = Colors.black,
    this.perWidth = 0.8,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      width: MediaQuery.of(context).size.width * perWidth,
      child: TextButton(
        onPressed: onPressed,
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.all(backgroundColor),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 8),
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
            if (iconPath != null)
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  height: 25,
                  width: MediaQuery.of(context).size.width * 0.1,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage(iconPath!),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
