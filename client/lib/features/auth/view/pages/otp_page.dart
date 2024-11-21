// ignore_for_file: must_be_immutable

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:social_heart/core/failure.dart';
import 'package:social_heart/core/theme/app_pallete.dart';
import 'package:social_heart/core/utils/error_snackbar.dart';
import 'package:social_heart/core/utils/success_snackbar.dart';
import 'package:social_heart/core/widgets/app_button.dart';
import 'package:social_heart/core/widgets/loader.dart';
import 'package:social_heart/features/auth/repository/auth_remote_repository.dart';
import 'package:social_heart/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:social_heart/features/home/view/main_navigation.dart';

class OtpPage extends ConsumerStatefulWidget {
  final String phone;
  final String countryCode;
  const OtpPage({
    super.key,
    required this.phone,
    required this.countryCode,
  });

  @override
  ConsumerState<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends ConsumerState<OtpPage> {
  // Add TextEditingControllers for each OTP box
  final TextEditingController otp1 = TextEditingController();
  final TextEditingController otp2 = TextEditingController();
  final TextEditingController otp3 = TextEditingController();
  final TextEditingController otp4 = TextEditingController();
  final formKey = GlobalKey<FormState>();
  late Future<Either<AppFailure, String>> _otpFuture;
  bool _isResending = false;
  // Add FocusNodes for each OTP box
  final FocusNode focusNode1 = FocusNode();
  final FocusNode focusNode2 = FocusNode();
  final FocusNode focusNode3 = FocusNode();
  final FocusNode focusNode4 = FocusNode();

  @override
  void initState() {
    super.initState();
    // Automatically focus the first OTP box when the screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(focusNode1);
    });
  }

  Future<void> _resendOtp() async {
    setState(() {
      _isResending = true;
      _otpFuture = ref.read(authRemoteRepositoryProvider).generateOTP(
            countryCode: widget.countryCode,
            phone: widget.phone,
          );
    });

    _otpFuture.then((result) {
      setState(() => _isResending = false);
      result.fold(
        (failure) => showErrorSnackBar(context, failure.message),
        (success) => showSuccessSnackBar(context, success),
      );
    });
  }

  void login(WidgetRef ref, String otp) async {
    if (formKey.currentState!.validate()) {
      ref.read(authViewModelProvider.notifier).loginUser(
          countryCode: widget.countryCode, phone: widget.phone, otp: otp);
    }
  }

  void _resetFields() {
    otp1.clear();
    otp2.clear();
    otp3.clear();
    otp4.clear();
  }

  @override
  void dispose() {
    // Dispose controllers and focus nodes
    otp1.dispose();
    otp2.dispose();
    otp3.dispose();
    otp4.dispose();
    focusNode1.dispose();
    focusNode2.dispose();
    focusNode3.dispose();
    focusNode4.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<String> otpParts = [otp1.text, otp2.text, otp3.text, otp4.text];
    final String otp = otpParts.join();
    final isLoading = ref.watch(
        authViewModelProvider.select((value) => value?.isLoading == true));

    ref.listen(
      authViewModelProvider,
      (prev, next) {
        next?.when(
            data: (data) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) {
                    WidgetsBinding.instance.addPostFrameCallback(
                      (_) {
                        showSuccessSnackBar(
                            context, "Successfully logged in!!!");
                        _resetFields();
                      },
                    );
                    return const MainNavigationPage();
                  },
                ),
                (route) => false,
              );
            },
            error: (error, st) {
              showErrorSnackBar(context, error);
            },
            loading: () {});
      },
    );

    return Scaffold(
      backgroundColor: Pallete.white,
      appBar: AppBar(
        backgroundColor: Pallete.white,
      ),
      body: isLoading || _isResending
          ? const Loader()
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 32.0, vertical: 20.0),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Enter OTP",
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Pallete.black,
                        ),
                      ),
                      const SizedBox(height: 60),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildOtpBox(otp1, focusNode1, focusNode2, null),
                          _buildOtpBox(
                              otp2, focusNode2, focusNode3, focusNode1),
                          _buildOtpBox(
                              otp3, focusNode3, focusNode4, focusNode2),
                          _buildOtpBox(otp4, focusNode4, null, focusNode3),
                        ],
                      ),
                      const SizedBox(height: 40),
                      Center(
                        child: TextButton(
                          onPressed: _resendOtp,
                          child: const Text(
                            "Resend",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Pallete.primaryBorder,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      Center(
                        child: AppButton(
                          perWidth: 0.7,
                          text: "CONTINUE",
                          backgroundColor: Pallete.primaryPurple,
                          color: Pallete.white,
                          onPressed: () => login(ref, otp),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  // Helper method to create an OTP box with focus logic
  Widget _buildOtpBox(
    TextEditingController controller,
    FocusNode currentFocusNode,
    FocusNode? nextFocusNode,
    FocusNode? previousFocusNode,
  ) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: currentFocusNode.hasFocus
                ? Pallete.primaryPurple
                : Pallete.primaryBorder,
            width: 1.5,
          ),
        ),
      ),
      width: 50,
      child: TextField(
        controller: controller,
        focusNode: currentFocusNode,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        decoration: const InputDecoration(
          counterText: '',
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        onChanged: (value) {
          //  1. User enters a value (value.length == 1)
          // if (value.length == 1): This checks if the user has typed exactly 1 character into the field.
          // currentFocusNode.unfocus(): It removes the focus from the current OTP field after a character is entered, preventing further input into this field.
          // if (nextFocusNode != null): This checks if the next OTP field exists.
          // FocusScope.of(context).requestFocus(nextFocusNode): This moves the focus to the next OTP field, allowing the user to type the next character there.
          // So, after entering a character, the focus automatically shifts to the next field.

          // 2. User deletes the value (value.isEmpty)
          // else if (value.isEmpty && previousFocusNode != null): This checks if the field becomes empty (indicating the user has pressed backspace to delete the value) and ensures that the previous OTP field exists.
          // currentFocusNode.unfocus(): It removes the focus from the current OTP field, preventing further input into this field.
          // FocusScope.of(context).requestFocus(previousFocusNode): This moves the focus back to the previous OTP field, allowing the user to edit or re-enter a value there.
          if (value.length == 1) {
            currentFocusNode.unfocus();
            if (nextFocusNode != null) {
              FocusScope.of(context).requestFocus(nextFocusNode);
            }
          } else if (value.isEmpty && previousFocusNode != null) {
            currentFocusNode.unfocus();
            FocusScope.of(context).requestFocus(previousFocusNode);
          }
        },
        onTap: () {
          setState(() {});
        },
      ),
    );
  }
}
