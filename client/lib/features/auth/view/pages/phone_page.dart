import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:social_heart/core/failure.dart';
import 'package:social_heart/core/theme/app_pallete.dart';
import 'package:social_heart/core/utils/error_snackbar.dart';
import 'package:social_heart/core/utils/success_snackbar.dart';
import 'package:social_heart/core/widgets/app_button.dart';
import 'package:social_heart/core/widgets/loader.dart';
import 'package:social_heart/features/auth/repository/auth_remote_repository.dart';
import 'package:social_heart/features/auth/view/pages/otp_page.dart';
import 'package:fpdart/fpdart.dart';

class PhonePage extends ConsumerStatefulWidget {
  const PhonePage({super.key});

  @override
  ConsumerState createState() => _PhonePageState();
}

class _PhonePageState extends ConsumerState<PhonePage> {
  late CountryCode selectedCountryCode;
  final FocusNode _focusNode = FocusNode();
  bool isFocused = false;

  final TextEditingController phoneController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  Future<Either<AppFailure, String>>? _otpFuture;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    phoneController.dispose();
    super.dispose();
  }

  Widget _buildPhoneForm() {
    const String text =
        '''By clicking Log In, you agree with our Terms. Learn how process your data in our Privacy Policy and Cookies Policy. By clicking Log In, you agree with our Terms. Learn how process your data in our Privacy Policy and Cookies''';

    return Scaffold(
      backgroundColor: Pallete.white,
      appBar: AppBar(
        backgroundColor: Pallete.white,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "My number is",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Pallete.black,
              ),
            ),
            const SizedBox(height: 60),
            Form(
              key: formKey,
              child: Row(
                children: [
                  Container(
                    height: 50,
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Pallete.primaryBorder,
                          width: 1.5,
                        ),
                      ),
                    ),
                    padding: const EdgeInsets.only(bottom: 0),
                    child: CountryCodePicker(
                      onChanged: (newValue) {
                        setState(() {
                          selectedCountryCode = newValue;
                        });
                      },
                      initialSelection: 'IT',
                      favorite: const ['+39', 'FR', '91'],
                      showCountryOnly: false,
                      showOnlyCountryWhenClosed: false,
                      alignLeft: false,
                    ),
                  ),
                  const SizedBox(width: 25),
                  Expanded(
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: isFocused
                                ? Pallete.primaryPurple
                                : Pallete.primaryBorder,
                            width: 1.5,
                          ),
                        ),
                      ),
                      child: TextField(
                        focusNode: _focusNode,
                        controller: phoneController,
                        decoration: const InputDecoration(
                          hintText: 'Phone number',
                          border: InputBorder.none,
                          counterText: '',
                        ),
                        keyboardType: TextInputType.phone,
                        maxLength: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Pallete.secondaryBorder,
                ),
              ),
            ),
            const SizedBox(height: 40),
            Center(
              child: AppButton(
                onPressed: () {
                  if (formKey.currentState?.validate() ?? false) {
                    setState(() {
                      _otpFuture =
                          ref.read(authRemoteRepositoryProvider).generateOTP(
                                countryCode: selectedCountryCode.dialCode!,
                                phone: phoneController.text,
                              );
                    });
                  }
                },
                perWidth: 0.7,
                text: "CONTINUE",
                backgroundColor: Pallete.primaryPurple,
                color: Pallete.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Either<AppFailure, String>>(
      future: _otpFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: Loader(),
            ),
          );
        }

        // if (snapshot.hasError) {
        //   return Scaffold(
        //     body: Center(
        //       child: Column(
        //         mainAxisAlignment: MainAxisAlignment.center,
        //         children: [
        //           Text(
        //             'Error: ${snapshot.error}',
        //             style: const TextStyle(color: Colors.red),
        //           ),
        //           const SizedBox(height: 20),
        //           ElevatedButton(
        //             onPressed: () {
        //               setState(() {
        //                 _otpFuture = null;
        //               });
        //             },
        //             child: const Text('Try Again'),
        //           ),
        //         ],
        //       ),
        //     ),
        //   );
        // }

        if (snapshot.hasData) {
          return snapshot.data!.fold(
            (failure) {
              // Show error and return to form
              WidgetsBinding.instance.addPostFrameCallback((_) {
                showErrorSnackBar(context, failure.message);
              });
              return _buildPhoneForm();
            },
            (success) {
              // Show success message and navigate
              WidgetsBinding.instance.addPostFrameCallback((_) {
                showSuccessSnackBar(context, success);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (_) => OtpPage(
                            countryCode: selectedCountryCode.dialCode!,
                            phone: phoneController.text,
                          )),
                );
              });
              return const Scaffold(
                body: Center(
                  child: Loader(),
                ),
              );
            },
          );
        }

        // Show the main form when no future is running
        return _buildPhoneForm();
      },
    );
  }
}
