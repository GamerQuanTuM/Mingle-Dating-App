import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:social_heart/core/theme/app_pallete.dart';
import 'package:social_heart/core/widgets/app_button.dart';
import 'package:social_heart/features/auth/view/pages/phone_page.dart';
import 'package:social_heart/features/auth/view/pages/signup_page.dart';

class LoginPage extends StatelessWidget {
  final String termsText = '''
By clicking Log In, you agree with our Terms.
Learn how we process your data in our Privacy
Policy and Cookies Policy.''';

  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Pallete.primaryPurple,
      appBar: AppBar(
        backgroundColor: Pallete.primaryPurple,
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                flex: 1,
                child: _buildLogo(),
              ),
              Expanded(
                flex: 2,
                child: _buildLoginOptions(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      height: 150,
      width: 150,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage("assets/images/Logo-m.png"),
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _buildLoginOptions(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          termsText,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Pallete.white,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        const AppButton(
          text: "LOGIN WITH GOOGLE",
          iconPath: "assets/images/Google.png",
        ),
        const SizedBox(height: 20),
        const AppButton(
          text: "LOGIN WITH FACEBOOK",
          iconPath: "assets/images/Facebook.png",
        ),
        const SizedBox(height: 20),
        AppButton(
          text: "LOGIN WITH PHONE",
          iconPath: "assets/images/Phone.png",
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const PhonePage(),
              ),
            );
          },
        ),
        const SizedBox(height: 30),
        RichText(
          text: TextSpan(
            text: 'Dont have an accout? ',
            style: const TextStyle(
                fontWeight: FontWeight.w500, color: Pallete.white),
            children: [
              TextSpan(
                recognizer: TapGestureRecognizer()
                  ..onTap = () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const SignupPage(),
                      ),
                    );
                  },
                text: 'Signup',
                style: const TextStyle(
                    fontWeight: FontWeight.w600, color: Pallete.white),
              ),
            ],
          ),
        )
      ],
    );
  }
}
