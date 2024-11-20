import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:social_heart/core/models/user_model.dart';
import 'package:social_heart/core/providers/current_user_notifier.dart';
import 'package:social_heart/core/theme/app_pallete.dart';
import 'package:social_heart/core/utils/error_snackbar.dart';
import 'package:social_heart/core/widgets/app_button.dart';
import 'package:social_heart/core/widgets/loader.dart';
import 'package:social_heart/features/home/providers/profile_update_notifier.dart';
import 'package:social_heart/features/home/viewmodel/profile_viewmodel.dart';

class ProfileEditPage extends ConsumerStatefulWidget {
  final UserDetails currentUser;
  const ProfileEditPage({super.key, required this.currentUser});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _ProfileEditPageState();
}

class _ProfileEditPageState extends ConsumerState<ProfileEditPage> {
  late final user = widget.currentUser;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  final formKey = GlobalKey<FormState>();

  final FocusNode _namefocusNode = FocusNode();
  final FocusNode _phonefocusNode = FocusNode();
  final FocusNode _datefocusNode = FocusNode();
  DateTime? _selectedDate;

  bool _isFocusedName = false;
  bool _isFocusedPhone = false;
  bool _isFocusedDate = false;

  Future<bool> _showExitDialog() async {
    bool hasChanges = _nameController.text != user.name.toString() ||
        _phoneController.text != user.phone ||
        _dateController.text != DateFormat('MM/dd/yyyy').format(user.dob);

    if (!hasChanges) return true;

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

  OutlineInputBorder _inputBorder(bool isFocus) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(8.0),
      borderSide: BorderSide(
        color: isFocus ? Pallete.primaryPurple : Pallete.primaryBorder,
      ),
    );
  }

  void _update(WidgetRef ref) async {
    if (formKey.currentState!.validate()) {
      // print(_nameController.text.trim());
      // print(_phoneController.text.trim());
      // print(_dateController.text.trim());

      final formattedDate =
          DateFormat('dd/MM/yyyy').parse(_dateController.text.trim());

      ref.read(profileViewModelProvider.notifier).updateProfile(
            name: _nameController.text.trim(),
            phone: _phoneController.text.trim(),
            dob: formattedDate,
          );
    }
  }

  Future<void> _selectDate(context) async {
    final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: _selectedDate ?? DateTime.now(),
        firstDate: DateTime(1900),
        lastDate: DateTime.now(),
        builder: (context, child) {
          return Theme(
            data:
                Theme.of(context).copyWith(primaryColor: Pallete.primaryPurple),
            child: child!,
          );
        });

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('MM/dd/yyyy').format(picked);
        _isFocusedDate = false;
      });
    }
  }

  void _focus() {
    _namefocusNode.requestFocus();
    _namefocusNode.addListener(() {
      setState(() {
        _isFocusedName = _namefocusNode.hasFocus;
      });
    });
    _phonefocusNode.addListener(() {
      setState(() {
        _isFocusedPhone = _phonefocusNode.hasFocus;
      });
    });
    _datefocusNode.addListener(() {
      setState(() {
        _isFocusedDate = _datefocusNode.hasFocus;
      });
    });
  }

  void _initialiseTextField() {
    _nameController.text = user.name.toString();
    _phoneController.text = user.phone;
    _dateController.text = DateFormat('MM/dd/yyyy').format(user.dob);
  }

  @override
  void initState() {
    _focus();
    _initialiseTextField();
    super.initState();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _dateController.dispose();
    _namefocusNode.dispose();
    _phonefocusNode.dispose();
    _datefocusNode.dispose();
    if (formKey.currentState != null) {
      formKey.currentState!.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(
        profileViewModelProvider.select((value) => value?.isLoading == true));

    final error =
        ref.watch(profileViewModelProvider.select((value) => value?.error));

    final updateProfile = ref.watch(profileUpdateNotifierProvider);
    final currentUser = ref.watch(currentUserNotifierProvider);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (updateProfile != null && currentUser != null) {
        Navigator.of(context).pop();
      }

      if (error != null) {
        showErrorSnackBar(context, error.toString());
      }
    });

    void pop() async {
      final bool shouldPop = await _showExitDialog();
      if (shouldPop) {
        if (!context.mounted) return;
        Navigator.of(context).pop();
      }
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
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
            : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20.0, vertical: 32.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Profile Settings",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Form(
                        key: formKey,
                        child: Column(
                          children: [
                            TextField(
                              focusNode: _namefocusNode,
                              controller: _nameController,
                              decoration: InputDecoration(
                                hintText: "Username",
                                hintStyle:
                                    const TextStyle(color: Pallete.black),
                                border: _inputBorder(false),
                                enabledBorder: _inputBorder(false),
                                focusedBorder: _inputBorder(_isFocusedName),
                              ),
                              keyboardType: TextInputType.name,
                            ),
                            const SizedBox(height: 30),
                            TextField(
                              focusNode: _phonefocusNode,
                              controller: _phoneController,
                              decoration: InputDecoration(
                                hintText: "Phone",
                                hintStyle:
                                    const TextStyle(color: Pallete.black),
                                border: _inputBorder(false),
                                enabledBorder: _inputBorder(false),
                                focusedBorder: _inputBorder(_isFocusedPhone),
                                counterText: '',
                              ),
                              keyboardType: TextInputType.number,
                              maxLength: 10,
                            ),
                            const SizedBox(height: 30),
                            TextField(
                              onTap: () async {
                                await _selectDate(context);
                              },
                              readOnly: true,
                              focusNode: _datefocusNode,
                              controller: _dateController,
                              decoration: InputDecoration(
                                hintText: "Date of Birth",
                                hintStyle:
                                    const TextStyle(color: Pallete.black),
                                border: _inputBorder(false),
                                enabledBorder: _inputBorder(false),
                                focusedBorder: _inputBorder(_isFocusedDate),
                                suffixIcon: const Icon(Icons.calendar_month),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 60),
                      Center(
                        child: AppButton(
                          onPressed: () => _update(ref),
                          text: "SAVE",
                          backgroundColor: Pallete.primaryPurple,
                          color: Pallete.white,
                        ),
                      )
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
