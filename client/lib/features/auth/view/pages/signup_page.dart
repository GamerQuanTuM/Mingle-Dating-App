import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:social_heart/core/models/user_model.dart';
import 'package:social_heart/core/theme/app_pallete.dart';
import 'package:social_heart/core/utils/debug.dart';
import 'package:social_heart/core/utils/error_snackbar.dart';
import 'package:social_heart/core/utils/success_snackbar.dart';
import 'package:social_heart/core/widgets/app_button.dart';
import 'package:social_heart/core/widgets/loader.dart';
// import 'package:social_heart/features/auth/repository/auth_local_repository.dart';
import 'package:social_heart/features/auth/view/pages/passion_page.dart';
import 'package:social_heart/features/auth/viewmodel/auth_viewmodel.dart';

class SignupPage extends ConsumerStatefulWidget {
  const SignupPage({super.key});

  @override
  ConsumerState<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends ConsumerState<SignupPage> {
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  // final TextEditingController ageController = TextEditingController();
  String? gender;
  DateTime? selectedDate;
  final formKey = GlobalKey<FormState>();

  final FocusNode fullNamefocusNode = FocusNode();
  final FocusNode phoneNumbefocusNode = FocusNode();
  final FocusNode genderfocusNode = FocusNode();
  final FocusNode datefocusNode = FocusNode();
  // final FocusNode agefocusNode = FocusNode();
  bool isFocusedFullName = false;
  bool isFocusedPhoneNumber = false;
  bool isFocusedGender = false;
  bool isFocusedDate = false;
  bool isFocusedAge = false;

  void _resetFields() {
    fullNameController.clear();
    phoneNumberController.clear();
    dateController.clear();
    gender = null;
    selectedDate = null;
    setState(() {
      isFocusedFullName = false;
      isFocusedPhoneNumber = false;
      isFocusedGender = false;
      isFocusedDate = false;
      isFocusedAge = false;
    });
  }

  @override
  void initState() {
    super.initState();
    fullNamefocusNode.addListener(() {
      setState(() {
        isFocusedFullName = fullNamefocusNode.hasFocus;
      });
    });
    phoneNumbefocusNode.addListener(() {
      setState(() {
        isFocusedPhoneNumber = phoneNumbefocusNode.hasFocus;
      });
    });
    genderfocusNode.addListener(() {
      setState(() {
        isFocusedGender = genderfocusNode.hasFocus;
      });
    });
    datefocusNode.addListener(() {
      setState(() {
        isFocusedDate = datefocusNode.hasFocus;
      });
    });
    // agefocusNode.addListener(() {
    //   setState(() {
    //     isFocusedAge = agefocusNode.hasFocus;
    //   });
    // });
  }

  void _signUp(WidgetRef ref) async {
    if (formKey.currentState!.validate()) {
      Gender? genderEnum;

      if (gender != null) {
        genderEnum = gender == 'Male' ? Gender.MALE : Gender.FEMALE;
      }

      // Await the result if signupUser returns a Future
      await ref.read(authViewModelProvider.notifier).signupUser(
            name: fullNameController.text.trim(),
            dob: DateFormat('dd/MM/yyyy').parse(dateController.text.trim()),
            phone: phoneNumberController.text.trim(),
            gender: genderEnum!,
          );
    }
  }

  @override
  void dispose() {
    fullNameController.dispose();
    phoneNumberController.dispose();
    dateController.dispose();
    fullNamefocusNode.dispose();
    phoneNumbefocusNode.dispose();
    genderfocusNode.dispose();
    datefocusNode.dispose();
    if (formKey.currentState != null) {
      formKey.currentState!.dispose();
    }
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            primaryColor: Pallete.primaryPurple,
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        dateController.text = DateFormat('dd/MM/yyyy').format(picked);
        isFocusedDate = false;
      });
    }
  }

  BoxDecoration _boxDecoration(bool focusNode) {
    return BoxDecoration(
      border: Border(
        bottom: BorderSide(
          color: focusNode ? Pallete.primaryPurple : Pallete.primaryBorder,
          width: 1.5,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hintText, {bool suffix = false}) {
    return InputDecoration(
      hintText: hintText,
      border: InputBorder.none,
      contentPadding: suffix
          ? const EdgeInsets.only(top: 8)
          : const EdgeInsets.only(bottom: 8),
      counterText: '',
      hintStyle: const TextStyle(color: Pallete.black),
      suffixIcon: suffix
          ? const Padding(
              padding: EdgeInsets.only(left: 26.0),
              child: Icon(
                Icons.arrow_drop_down,
                color: Pallete.black,
              ),
            )
          : null,
    );
  }

  // Custom Text Input Field Widget
  Widget _textInputField({
    required String hintText,
    required TextEditingController controller,
    required FocusNode focusNode,
    required bool isFocused,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
  }) {
    return Container(
      height: 45,
      decoration: _boxDecoration(isFocused),
      child: TextField(
        focusNode: focusNode,
        controller: controller,
        decoration: _inputDecoration(hintText),
        keyboardType: keyboardType,
        maxLength: maxLength,
      ),
    );
  }

  // Custom Dropdown Field Widget
  Widget _dropdownField({
    required String hintText,
    required String? value,
    required FocusNode focusNode,
    required bool isFocused,
    required void Function(String?) onChanged,
  }) {
    return Focus(
      focusNode: focusNode,
      child: Container(
        height: 45,
        decoration: _boxDecoration(isFocused),
        child: Theme(
          data: Theme.of(context).copyWith(
            hoverColor: Colors.transparent,
          ),
          child: DropdownButton<String>(
            value: value,
            hint: Text(hintText, style: const TextStyle(color: Pallete.black)),
            isExpanded: true,
            underline: const SizedBox(),
            items: ['Male', 'Female'].map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }

  // Custom Date Picker Field Widget
  Widget _datePickerField({
    required String hintText,
    required TextEditingController controller,
    required FocusNode focusNode,
    required bool isFocused,
  }) {
    return Container(
      height: 45,
      decoration: _boxDecoration(isFocused),
      child: TextField(
        focusNode: focusNode,
        controller: controller,
        decoration: _inputDecoration(hintText, suffix: true),
        readOnly: true,
        onTap: () async {
          focusNode.unfocus();
          await _selectDate(context);
        },
      ),
    );
  }

  Widget _iconField({
    required String imagePath,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        width: MediaQuery.of(context).size.width * 0.2,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(imagePath),
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(
      authViewModelProvider.select(
        (value) => value?.isLoading == true,
      ),
    );

    ref.listen(authViewModelProvider, (prev, next) {
      next?.when(
          data: (data) {
            final userId = data.user.id;
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) {
                  WidgetsBinding.instance.addPostFrameCallback(
                    (_) {
                      showSuccessSnackBar(context,
                          "Account Created Successfully! Please Login!");
                      _resetFields();
                    },
                  );
                  return PassionPage(
                    userId: userId,
                  );
                },
              ),
            );
          },
          error: (error, st) {
            showErrorSnackBar(context, error);
          },
          loading: () {});
    });

    return Scaffold(
      backgroundColor: Pallete.white,
      appBar: AppBar(
        backgroundColor: Pallete.white,
      ),
      body: isLoading
          ? const Loader()
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 32.0, vertical: 20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Sign Up",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Pallete.black,
                      ),
                    ),
                    const SizedBox(height: 60),
                    Form(
                      key: formKey,
                      child: Column(
                        children: [
                          _textInputField(
                            hintText: "Full Name",
                            controller: fullNameController,
                            focusNode: fullNamefocusNode,
                            isFocused: isFocusedFullName,
                            keyboardType: TextInputType.name,
                          ),
                          const SizedBox(height: 20),
                          _dropdownField(
                            hintText: "Gender",
                            value: gender,
                            focusNode: genderfocusNode,
                            isFocused: isFocusedGender,
                            onChanged: (String? value) {
                              setState(() {
                                gender = value;
                              });
                            },
                          ),
                          const SizedBox(height: 20),
                          _datePickerField(
                            hintText: "Date of Birth",
                            controller: dateController,
                            focusNode: datefocusNode,
                            isFocused: isFocusedDate,
                          ),
                          const SizedBox(height: 20),
                          // _textInputField(
                          //   hintText: "Age",
                          //   controller: ageController,
                          //   focusNode: agefocusNode,
                          //   isFocused: isFocusedAge,
                          //   keyboardType: TextInputType.phone,
                          //   maxLength: 2,
                          // ),
                          const SizedBox(height: 20),
                          _textInputField(
                            hintText: "Phone Number",
                            controller: phoneNumberController,
                            focusNode: phoneNumbefocusNode,
                            isFocused: isFocusedPhoneNumber,
                            keyboardType: TextInputType.phone,
                            maxLength: 10,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    Center(
                      child: AppButton(
                        onPressed: () => _signUp(ref),
                        perWidth: 0.7,
                        text: "SIGN UP",
                        backgroundColor: Pallete.primaryPurple,
                        color: Pallete.white,
                      ),
                    ),
                    const SizedBox(height: 40),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 40,
                          child: Divider(color: Pallete.primaryBorder),
                        ),
                        Text(
                          " or ",
                          style: TextStyle(
                            color: Pallete.black,
                            fontWeight: FontWeight.w500,
                            fontSize: 20,
                          ),
                        ),
                        SizedBox(
                          width: 40,
                          child: Divider(color: Pallete.primaryBorder),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _iconField(
                            imagePath: "assets/images/Facebook-l.png",
                            onTap: () {
                              Debug.print("signup_page.dart", "Facebook icon");
                            }),
                        _iconField(
                            imagePath: "assets/images/Google.png",
                            onTap: () {
                              Debug.print("signup_page.dart", "Google icon");
                            }),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
