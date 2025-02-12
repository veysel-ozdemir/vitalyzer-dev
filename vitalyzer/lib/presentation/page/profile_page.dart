import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitalyzer/const/color_palette.dart';
import 'package:vitalyzer/controller/nutrition_controller.dart';
import 'package:vitalyzer/controller/permission_controller.dart';
import 'package:vitalyzer/controller/user_profile_controller.dart';
import 'package:vitalyzer/model/user_profile.dart';
import 'package:vitalyzer/presentation/page/home_page.dart';
import 'package:vitalyzer/presentation/page/landing_page.dart';
import 'package:vitalyzer/presentation/widget/user_info_item.dart';
import 'package:vitalyzer/service/auth_service.dart';
import 'package:vitalyzer/util/funtions.dart';

class ProfilePage extends StatefulWidget {
  final String nameInitials;

  const ProfilePage({
    super.key,
    required this.nameInitials,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _currentPasswordController =
      TextEditingController();
  bool _obscurePassword = true;

  final ImagePicker _imagePicker = ImagePicker();
  final PermissionController permissionController = Get.find();
  final NutritionController nutritionController = Get.find();
  final AuthService _authService = AuthService();

  late SharedPreferences prefs;
  String? selectedSex;
  int? selectedAge;
  int? selectedHeight;
  double? selectedWeight;
  double? bodyMassIndexLevel;
  double? carbsCalorieLimit;
  double? proteinCalorieLimit;
  double? fatCalorieLimit;
  double? carbsGramLimit;
  double? proteinGramLimit;
  double? fatGramLimit;
  double? waterBottleCapacity;
  int? carbsCaloriePerGram;
  int? proteinCaloriePerGram;
  int? fatCaloriePerGram;

  int? currentUserProfileId;
  String? currentUserFirebaseUid;
  UserProfile? currentUserProfile;
  Uint8List? userProfilePhoto;
  XFile? profilePhoto;

  final UserProfileController _userProfileController = Get.find();

  String? userName;
  String? userEmail;

  @override
  void initState() {
    super.initState();
    _loadSharedPrefs();
  }

  Future<void> _loadSharedPrefs() async {
    prefs = await SharedPreferences.getInstance();
    setState(() {
      currentUserProfileId = prefs.getInt('userProfileId');
      currentUserFirebaseUid = prefs.getString('userFirebaseUid');
      selectedSex = prefs.getString('userSex');
      selectedAge = prefs.getInt('userAge');
      selectedHeight = prefs.getInt('userHeight');
      selectedWeight = prefs.getDouble('userWeight');
      bodyMassIndexLevel = prefs.getDouble('bodyMassIndexLevel');
      carbsCalorieLimit = prefs.getDouble('carbsCalorieLimit');
      proteinCalorieLimit = prefs.getDouble('proteinCalorieLimit');
      fatCalorieLimit = prefs.getDouble('fatCalorieLimit');
      carbsGramLimit = prefs.getDouble('carbsGramLimit');
      proteinGramLimit = prefs.getDouble('proteinGramLimit');
      fatGramLimit = prefs.getDouble('fatGramLimit');
      waterBottleCapacity = prefs.getDouble('waterBottleCapacity');
      carbsCaloriePerGram = prefs.getInt('carbsCaloriePerGram');
      proteinCaloriePerGram = prefs.getInt('proteinCaloriePerGram');
      fatCaloriePerGram = prefs.getInt('fatCaloriePerGram');
    });
    await _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    debugPrint('Loading user profile from local database');

    await _userProfileController.loadUserProfile(currentUserFirebaseUid!);

    setState(() {
      currentUserProfile = _userProfileController.currentProfile.value;
    });

    if (currentUserProfile != null) {
      debugPrint(
          'Successfully loaded current user profile from local database');

      setState(() {
        userProfilePhoto = currentUserProfile!.profilePhoto;
        userName = currentUserProfile!.fullName;
        userEmail = currentUserProfile!.email;

        _nameController.text = userName!;
        _emailController.text = userEmail!;
      });
    } else {
      debugPrint('Could not fetch current user profile from local database');
      debugPrint('currentUserFirebaseUid: $currentUserFirebaseUid');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _currentPasswordController.dispose();
    super.dispose();
  }

  void _toggleVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  void _handlePopupMenuClick(String value) async {
    switch (value) {
      case 'Log Out':
        _logOutDialog();
      case 'Delete Account':
        _deleteAccountDialog();
    }
  }

  Future<void> _saveDataToSharedPrefs() async {
    await prefs.setString('userSex', selectedSex!);
    await prefs.setInt('userAge', selectedAge!);
    await prefs.setInt('userHeight', selectedHeight!);
    await prefs.setDouble('userWeight', selectedWeight!);

    await prefs.setDouble('bodyMassIndexLevel', bodyMassIndexLevel!);

    await prefs.setString('bmiAdvice', nutritionController.bmiAdvice.value);

    await prefs.setDouble(
        'dailyWaterLimit', nutritionController.waterLimit.value);
    await prefs.setDouble('carbsCalorieLimit',
        nutritionController.carbsLimit.value * carbsCaloriePerGram!);
    await prefs.setDouble('proteinCalorieLimit',
        nutritionController.proteinLimit.value * proteinCaloriePerGram!);
    await prefs.setDouble('fatCalorieLimit',
        nutritionController.fatLimit.value * fatCaloriePerGram!);
    await prefs.setDouble(
        'carbsGramLimit', nutritionController.carbsLimit.value);
    await prefs.setDouble(
        'proteinGramLimit', nutritionController.proteinLimit.value);
    await prefs.setDouble('fatGramLimit', nutritionController.fatLimit.value);

    await prefs.setInt('drankWaterBottle', 0);

    await prefs.setBool('exceededWaterLimit', false);

    await prefs.remove('lastWaterDrinkingTime');

    await prefs.setDouble('gainedCarbsCalorie', 0.0);
    await prefs.setDouble('gainedProteinCalorie', 0.0);
    await prefs.setDouble('gainedFatCalorie', 0.0);
    await prefs.setDouble('gainedCarbsGram', 0.0);
    await prefs.setDouble('gainedProteinGram', 0.0);
    await prefs.setDouble('gainedFatGram', 0.0);

    int waterBottleItemCount =
        (nutritionController.waterLimit.value / waterBottleCapacity!).toInt();
    await prefs.setStringList(
      'waterBottleItemStates',
      List.generate(waterBottleItemCount, (_) => false)
          .map((e) => e.toString())
          .toList(),
    );
  }

  Future<void> _saveUserProfileChanges() async {
    try {
      // Update profile photo
      if (profilePhoto != null) {
        await _authService.updateProfilePhoto(
          uid: currentUserFirebaseUid!,
          image: profilePhoto!,
        );
      }

      // Update user name
      if (_nameController.text.trim().isEmpty) {
        Get.snackbar(
          'Caution:',
          'Name field should be filled',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      } else {
        await _authService.updateUserFields(
          uid: currentUserFirebaseUid!,
          fullName: _nameController.text.trim(),
        );
      }

      // Update user email
      if (_emailController.text.trim().isEmpty) {
        Get.snackbar(
          'Caution:',
          'Email field cannot be empty',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      } else if (_emailController.text.trim() !=
          _userProfileController.currentProfile.value!.email) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return AlertDialog(
              backgroundColor: ColorPalette.beige,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(
                  width: 3,
                  color: ColorPalette.lightGreen,
                ),
              ),
              title: const Text(
                'Password required to update email',
                style: TextStyle(color: ColorPalette.darkGreen),
              ),
              content: Padding(
                padding: const EdgeInsets.all(5),
                child: TextFormField(
                  controller: _currentPasswordController,
                  style: const TextStyle(
                    color: ColorPalette.darkGreen,
                  ),
                  cursorColor: ColorPalette.green,
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText: 'Current password',
                    hintStyle: TextStyle(
                      color: ColorPalette.green.withOpacity(0.75),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 0,
                      horizontal: 10,
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(
                        color: ColorPalette.green,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.all(
                        Radius.circular(15),
                      ),
                    ),
                    enabledBorder: const OutlineInputBorder(
                      borderSide: BorderSide(
                        color: ColorPalette.green,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.all(
                        Radius.circular(15),
                      ),
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _currentPasswordController.clear();
                    Get.back();
                  },
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: ColorPalette.darkGreen),
                  ),
                ),
                TextButton(
                  onPressed: () => Get.back(),
                  child: const Text(
                    'Ok',
                    style: TextStyle(color: ColorPalette.darkGreen),
                  ),
                ),
              ],
            );
          },
        );

        await _authService.updateUserEmail(
          uid: currentUserFirebaseUid!,
          newEmail: _emailController.text.trim(),
          password: _currentPasswordController.text.trim(),
        );

        _currentPasswordController.clear();
      }

      // Update user password
      if (_passwordController.text.trim().isNotEmpty) {
        if (_passwordController.text.trim() !=
            _confirmPasswordController.text.trim()) {
          Get.snackbar(
            'Caution:',
            'Passwords do not match',
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
          return;
        } else {
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) {
              return AlertDialog(
                backgroundColor: ColorPalette.beige,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(
                    width: 3,
                    color: ColorPalette.lightGreen,
                  ),
                ),
                title: const Text(
                  'Password required to update password',
                  style: TextStyle(color: ColorPalette.darkGreen),
                ),
                content: Padding(
                  padding: const EdgeInsets.all(5),
                  child: TextFormField(
                    controller: _currentPasswordController,
                    style: const TextStyle(
                      color: ColorPalette.darkGreen,
                    ),
                    cursorColor: ColorPalette.green,
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      hintText: 'Current password',
                      hintStyle: TextStyle(
                        color: ColorPalette.green.withOpacity(0.75),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 0,
                        horizontal: 10,
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(
                          color: ColorPalette.green,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.all(
                          Radius.circular(15),
                        ),
                      ),
                      enabledBorder: const OutlineInputBorder(
                        borderSide: BorderSide(
                          color: ColorPalette.green,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.all(
                          Radius.circular(15),
                        ),
                      ),
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      _currentPasswordController.clear();
                      Get.back();
                    },
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: ColorPalette.darkGreen),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Get.back(),
                    child: const Text(
                      'Ok',
                      style: TextStyle(color: ColorPalette.darkGreen),
                    ),
                  ),
                ],
              );
            },
          );

          await _authService.changePassword(
            currentPassword: _currentPasswordController.text.trim(),
            newPassword: _passwordController.text.trim(),
          );

          _currentPasswordController.clear();
        }
      }

      // navigate to home page
      await Get.offAll(() => const HomePage());
    } catch (e) {
      Get.snackbar(
        'Error',
        "Couldn't complete the update of user profile credentials!",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      debugPrint('Error: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: ColorPalette.beige,
      appBar: AppBar(
        backgroundColor: ColorPalette.beige,
        foregroundColor: ColorPalette.green,
        actions: [
          PopupMenuButton(
            color: ColorPalette.beige,
            onSelected: _handlePopupMenuClick,
            itemBuilder: (BuildContext context) {
              return {'Log Out', 'Delete Account'}.map((String choice) {
                return PopupMenuItem(
                  value: choice,
                  child: Text(
                    choice,
                    style: const TextStyle(color: ColorPalette.green),
                  ),
                );
              }).toList();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.only(bottom: 25, right: 25, left: 25),
        child: SingleChildScrollView(
          child: SizedBox(
            height: Get.height,
            width: Get.width,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Container(
                      alignment: Alignment.center,
                      child: Container(
                        height: Get.width * 0.3,
                        width: Get.width * 0.3,
                        decoration: BoxDecoration(
                          color: ColorPalette.lightGreen.withOpacity(0.5),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: ColorPalette.darkGreen,
                            width: 3,
                          ),
                        ),
                        child: (userProfilePhoto != null)
                            ? ClipOval(
                                child: Image.memory(
                                  userProfilePhoto!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Center(
                                child: TextButton(
                                  onPressed: null,
                                  child: Text(
                                    widget.nameInitials,
                                    style: const TextStyle(
                                      color: ColorPalette.green,
                                      fontSize: 35,
                                    ),
                                  ),
                                ),
                              ),
                      ),
                    ),
                    Column(
                      children: [
                        ElevatedButton(
                          onPressed: () async => await _pickImage(context),
                          style: const ButtonStyle(
                            backgroundColor:
                                WidgetStatePropertyAll(Colors.white),
                            side: WidgetStatePropertyAll(
                              BorderSide(
                                color: ColorPalette.green,
                                width: 2,
                              ),
                            ),
                          ),
                          child: const Icon(
                            Icons.cloud_upload,
                            color: ColorPalette.green,
                            size: 30,
                          ),
                        ),
                        Text(
                          'Change profile photo',
                          style: TextStyle(
                            color: ColorPalette.green.withOpacity(0.75),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(25),
                  child: TextFormField(
                    controller: _nameController,
                    style: const TextStyle(
                      color: ColorPalette.darkGreen,
                    ),
                    cursorColor: ColorPalette.green,
                    decoration: InputDecoration(
                      hintText: 'Full name',
                      hintStyle: TextStyle(
                        color: ColorPalette.green.withOpacity(0.75),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 0,
                        horizontal: 10,
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(
                          color: ColorPalette.green,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.all(
                          Radius.circular(15),
                        ),
                      ),
                      enabledBorder: const OutlineInputBorder(
                        borderSide: BorderSide(
                          color: ColorPalette.green,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.all(
                          Radius.circular(15),
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.only(left: 25, right: 25, bottom: 25),
                  child: TextFormField(
                    controller: _emailController,
                    style: const TextStyle(
                      color: ColorPalette.darkGreen,
                    ),
                    cursorColor: ColorPalette.green,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: 'Email',
                      hintStyle: TextStyle(
                        color: ColorPalette.green.withOpacity(0.75),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 0,
                        horizontal: 10,
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(
                          color: ColorPalette.green,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.all(
                          Radius.circular(15),
                        ),
                      ),
                      enabledBorder: const OutlineInputBorder(
                        borderSide: BorderSide(
                          color: ColorPalette.green,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.all(
                          Radius.circular(15),
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.only(left: 25, right: 25, bottom: 25),
                  child: TextFormField(
                    controller: _passwordController,
                    style: const TextStyle(
                      color: ColorPalette.darkGreen,
                    ),
                    cursorColor: ColorPalette.green,
                    obscureText: _obscurePassword,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      hintText: 'Change password',
                      hintStyle: TextStyle(
                        color: ColorPalette.green.withOpacity(0.75),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: _toggleVisibility,
                      ),
                      suffixIconColor: ColorPalette.green,
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 0,
                        horizontal: 10,
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(
                          color: ColorPalette.green,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.all(
                          Radius.circular(15),
                        ),
                      ),
                      enabledBorder: const OutlineInputBorder(
                        borderSide: BorderSide(
                          color: ColorPalette.green,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.all(
                          Radius.circular(15),
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.only(left: 25, right: 25, bottom: 25),
                  child: TextFormField(
                    controller: _confirmPasswordController,
                    style: const TextStyle(
                      color: ColorPalette.darkGreen,
                    ),
                    cursorColor: ColorPalette.green,
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      hintText: 'Confirm password',
                      hintStyle: TextStyle(
                        color: ColorPalette.green.withOpacity(0.75),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 0,
                        horizontal: 10,
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(
                          color: ColorPalette.green,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.all(
                          Radius.circular(15),
                        ),
                      ),
                      enabledBorder: const OutlineInputBorder(
                        borderSide: BorderSide(
                          color: ColorPalette.green,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.all(
                          Radius.circular(15),
                        ),
                      ),
                    ),
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 10, right: 5),
                        child: UserInfoItem(
                          text: 'Height',
                          icon: Icons.height,
                          buttonText: selectedHeight != null
                              ? selectedHeight.toString()
                              : selectedHeight,
                          unit: 'cm',
                          onTap: () => _showHeightSelector(
                            context: context,
                            onHeightSelected: (height) {
                              setState(() {
                                selectedHeight = height;
                              });
                            },
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 5, right: 5),
                        child: UserInfoItem(
                          text: 'Weight',
                          icon: Icons.scale,
                          buttonText: selectedWeight != null
                              ? selectedWeight.toString()
                              : selectedWeight,
                          unit: 'kg',
                          onTap: () => _showWeightSelector(
                            context: context,
                            onWeightSelected: (weight) {
                              setState(() {
                                selectedWeight = weight;
                              });
                            },
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 5, right: 5),
                        child: UserInfoItem(
                          text: 'Age',
                          icon: Icons.cake,
                          buttonText: selectedAge != null
                              ? selectedAge.toString()
                              : selectedAge,
                          unit: 'years',
                          onTap: () => _showAgeSelector(
                            context: context,
                            onAgeSelected: (age) {
                              setState(() {
                                selectedAge = age;
                              });
                            },
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 5, right: 10),
                        child: UserInfoItem(
                          text: 'Sex',
                          icon: Icons.people_alt,
                          buttonText: selectedSex,
                          unit: null,
                          onTap: () => _showSexSelector(
                            context: context,
                            onSexSelected: (sex) {
                              setState(() {
                                selectedSex = sex;
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 25),
                ElevatedButton(
                  onPressed: () async => await _saveChanges(),
                  style: ButtonStyle(
                    backgroundColor:
                        const WidgetStatePropertyAll(ColorPalette.green),
                    fixedSize: WidgetStatePropertyAll(
                      Size.fromWidth(Get.width * 0.5),
                    ),
                  ),
                  child: const Text(
                    'Save Changes',
                    style: TextStyle(
                      color: ColorPalette.beige,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(BuildContext context) async {
    final isGranted = await permissionController.checkPhotoLibraryPermission();

    if (isGranted) {
      // Pick an image.
      final XFile? image =
          await _imagePicker.pickImage(source: ImageSource.gallery);

      setState(() {
        profilePhoto = image;
      });

      if (profilePhoto != null) {
        if (context.mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) {
              return AlertDialog(
                backgroundColor: ColorPalette.beige,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(
                    width: 3,
                    color: ColorPalette.lightGreen,
                  ),
                ),
                title: const Text(
                  'Selected Image',
                  style: TextStyle(color: ColorPalette.darkGreen),
                ),
                content: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(profilePhoto!.path), // Convert XFile to File
                    fit: BoxFit.cover,
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: const Text(
                      'Close',
                      style: TextStyle(color: ColorPalette.darkGreen),
                    ),
                  ),
                ],
              );
            },
          );
        }
      }
    } else {
      if (context.mounted) {
        showModalBottomSheet(
          context: context,
          backgroundColor: ColorPalette.beige,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            side: BorderSide(
              color: ColorPalette.lightGreen,
              width: 3,
            ),
          ),
          builder: (context) {
            return SizedBox(
              height: Get.height * 0.25,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Access to the photo library is required to select and upload your profile photo.',
                    style: TextStyle(color: ColorPalette.green),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () async =>
                        await permissionController.openSettings(),
                    child: const Text(
                      'Go to settings',
                      style: TextStyle(
                        color: ColorPalette.green,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                ],
              ),
            );
          },
        );
      }
    }
  }

  void _showSexSelector({
    required BuildContext context,
    required void Function(String)
        onSexSelected, // Pass a callback to update the state
  }) {
    String? sex = selectedSex;

    showModalBottomSheet(
      context: context,
      backgroundColor: ColorPalette.beige,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        side: BorderSide(
          color: ColorPalette.lightGreen,
          width: 3,
        ),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(25),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Sex",
                style: TextStyle(
                  color: ColorPalette.darkGreen,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 10),
              ListTile(
                tileColor: ColorPalette.lightGreen.withOpacity(0.5),
                shape: RoundedRectangleBorder(
                  side: const BorderSide(
                      color: ColorPalette.lightGreen, width: 3),
                  borderRadius: BorderRadius.circular(15),
                ),
                leading: const Icon(Icons.male, color: ColorPalette.green),
                title: const Text(
                  "Male",
                  style: TextStyle(color: ColorPalette.darkGreen),
                ),
                onTap: () {
                  sex = "Male";
                  onSexSelected(sex!); // Call the callback
                  Navigator.pop(context); // Close the bottom sheet
                },
              ),
              const SizedBox(height: 5),
              ListTile(
                tileColor: ColorPalette.lightGreen.withOpacity(0.5),
                shape: RoundedRectangleBorder(
                  side: const BorderSide(
                      color: ColorPalette.lightGreen, width: 3),
                  borderRadius: BorderRadius.circular(15),
                ),
                leading: const Icon(Icons.female, color: ColorPalette.green),
                title: const Text(
                  "Female",
                  style: TextStyle(color: ColorPalette.darkGreen),
                ),
                onTap: () {
                  sex = "Female";
                  onSexSelected(sex!); // Call the callback
                  Navigator.pop(context); // Close the bottom sheet
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAgeSelector({
    required BuildContext context,
    required void Function(int)
        onAgeSelected, // Pass a callback to update the state
  }) {
    // Initialize scroll controller with previously selected age or default to 35
    FixedExtentScrollController scrollController =
        FixedExtentScrollController(initialItem: selectedAge ?? 35);

    // Set initial age only if it hasn't been set before
    int age = selectedAge ?? 35;

    showModalBottomSheet(
      context: context,
      backgroundColor: ColorPalette.beige,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        side: BorderSide(
          color: ColorPalette.lightGreen,
          width: 3,
        ),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Container(
              padding: const EdgeInsets.all(25),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Age",
                    style: TextStyle(
                      color: ColorPalette.darkGreen,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 200,
                    child: CupertinoTheme(
                      data: CupertinoThemeData(
                        textTheme: CupertinoTextThemeData(
                          pickerTextStyle:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: ColorPalette.darkGreen,
                                  ),
                        ),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CupertinoPicker(
                            scrollController: scrollController,
                            itemExtent: 40,
                            selectionOverlay: Container(
                              decoration: BoxDecoration(
                                color: ColorPalette.lightGreen.withOpacity(0.5),
                                border: Border.all(
                                  color: ColorPalette.lightGreen,
                                  width: 3,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onSelectedItemChanged: (int index) {
                              setState(() {
                                age = index;
                              });
                            },
                            children: List.generate(
                              101,
                              (index) => Center(
                                child: Text(
                                  index.toString(),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                          // Fixed "years" text overlay
                          Positioned(
                            right: Get.width * 0.25,
                            child: const Text(
                              'years',
                              style: TextStyle(
                                color: ColorPalette.darkGreen,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  age >= 18
                      ? ElevatedButton(
                          style: ButtonStyle(
                            fixedSize: WidgetStatePropertyAll(
                                Size.fromWidth(Get.width * 0.5)),
                            backgroundColor: const WidgetStatePropertyAll(
                                ColorPalette.green),
                          ),
                          onPressed: () {
                            onAgeSelected(age); // Call the callback
                            Navigator.pop(context);
                          },
                          child: const Text(
                            'Select',
                            style: TextStyle(color: ColorPalette.beige),
                          ),
                        )
                      : const Text(
                          'You must be 18+ to use this app, as per market guidelines.',
                          style: TextStyle(
                            color: Colors.red,
                          ),
                          textAlign: TextAlign.center,
                        )
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showHeightSelector({
    required BuildContext context,
    required void Function(int)
        onHeightSelected, // Callback to update the state
  }) {
    // Define the range for height
    const int minHeight = 120;
    const int maxHeight = 250;

    // Initialize scroll controller with the selected or default height (170 cm)
    FixedExtentScrollController scrollController = FixedExtentScrollController(
      initialItem: (selectedHeight ?? 170) - minHeight,
    );

    // Set initial height only if it hasn't been set before
    int height = selectedHeight ?? 170;

    showModalBottomSheet(
      context: context,
      backgroundColor: ColorPalette.beige,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        side: BorderSide(
          color: ColorPalette.lightGreen,
          width: 3,
        ),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Container(
              padding: const EdgeInsets.all(25),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Height",
                    style: TextStyle(
                      color: ColorPalette.darkGreen,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 200,
                    child: CupertinoTheme(
                      data: CupertinoThemeData(
                        textTheme: CupertinoTextThemeData(
                          pickerTextStyle:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: ColorPalette.darkGreen,
                                  ),
                        ),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CupertinoPicker(
                            scrollController: scrollController,
                            itemExtent: 40,
                            selectionOverlay: Container(
                              decoration: BoxDecoration(
                                color: ColorPalette.lightGreen.withOpacity(0.5),
                                border: Border.all(
                                  color: ColorPalette.lightGreen,
                                  width: 3,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onSelectedItemChanged: (int index) {
                              setState(() {
                                height = (index + minHeight);
                              });
                            },
                            children: List.generate(
                              maxHeight - minHeight + 1,
                              (index) => Center(
                                child: Text(
                                  "${index + minHeight}",
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                          // Fixed "cm" text overlay
                          Positioned(
                            right: Get.width * 0.25,
                            child: const Text(
                              'cm',
                              style: TextStyle(
                                color: ColorPalette.darkGreen,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    style: ButtonStyle(
                      fixedSize: WidgetStatePropertyAll(
                        Size.fromWidth(Get.width * 0.5),
                      ),
                      backgroundColor:
                          const WidgetStatePropertyAll(ColorPalette.green),
                    ),
                    onPressed: () {
                      onHeightSelected(height); // Call the callback
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Select',
                      style: TextStyle(color: ColorPalette.beige),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showWeightSelector({
    required BuildContext context,
    required void Function(double)
        onWeightSelected, // Callback to update the state
  }) {
    // Define the range for weight
    const int minIntegerPart = 30;
    const int maxIntegerPart = 200;
    const int minFractionPart = 0;
    const int maxFractionPart = 9;

    // Extract integer and fractional parts of the selected weight
    int initialIntegerPart = selectedWeight?.floor() ?? 70;
    int initialFractionPart = ((selectedWeight ?? 70) * 10 % 10).toInt();

    // Scroll controllers for the two pickers
    FixedExtentScrollController integerPartController =
        FixedExtentScrollController(
      initialItem: initialIntegerPart - minIntegerPart,
    );
    FixedExtentScrollController fractionPartController =
        FixedExtentScrollController(
      initialItem: initialFractionPart,
    );

    // Set initial weight only if it hasn't been set before
    double weight =
        selectedWeight ?? initialIntegerPart + (initialFractionPart / 10.0);

    showModalBottomSheet(
      context: context,
      backgroundColor: ColorPalette.beige,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        side: BorderSide(
          color: ColorPalette.lightGreen,
          width: 3,
        ),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Container(
              padding: const EdgeInsets.all(25),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Weight",
                    style: TextStyle(
                      color: ColorPalette.darkGreen,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 200,
                    child: CupertinoTheme(
                      data: CupertinoThemeData(
                        textTheme: CupertinoTextThemeData(
                          pickerTextStyle:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: ColorPalette.darkGreen,
                                  ),
                        ),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Spacer(flex: 1),
                              Expanded(
                                child: CupertinoPicker(
                                  scrollController: integerPartController,
                                  itemExtent: 40,
                                  selectionOverlay: Container(
                                    decoration: BoxDecoration(
                                      color: ColorPalette.lightGreen
                                          .withOpacity(0.5),
                                      border: const Border(
                                        left: BorderSide(
                                          color: ColorPalette.lightGreen,
                                          width: 3,
                                        ),
                                        top: BorderSide(
                                          color: ColorPalette.lightGreen,
                                          width: 3,
                                        ),
                                        bottom: BorderSide(
                                          color: ColorPalette.lightGreen,
                                          width: 3,
                                        ),
                                      ),
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(8),
                                        bottomLeft: Radius.circular(8),
                                      ),
                                    ),
                                  ),
                                  onSelectedItemChanged: (int index) {
                                    setState(() {
                                      initialIntegerPart =
                                          index + minIntegerPart;
                                      weight = initialIntegerPart +
                                          initialFractionPart / 10.0;
                                    });
                                  },
                                  children: List.generate(
                                    maxIntegerPart - minIntegerPart + 1,
                                    (index) => Center(
                                      child: Text(
                                        "${index + minIntegerPart}",
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: CupertinoPicker(
                                  scrollController: fractionPartController,
                                  itemExtent: 40,
                                  selectionOverlay: Container(
                                    decoration: BoxDecoration(
                                      color: ColorPalette.lightGreen
                                          .withOpacity(0.5),
                                      border: const Border(
                                        right: BorderSide(
                                          color: ColorPalette.lightGreen,
                                          width: 3,
                                        ),
                                        top: BorderSide(
                                          color: ColorPalette.lightGreen,
                                          width: 3,
                                        ),
                                        bottom: BorderSide(
                                          color: ColorPalette.lightGreen,
                                          width: 3,
                                        ),
                                      ),
                                      borderRadius: const BorderRadius.only(
                                        topRight: Radius.circular(8),
                                        bottomRight: Radius.circular(8),
                                      ),
                                    ),
                                  ),
                                  onSelectedItemChanged: (int index) {
                                    setState(() {
                                      initialFractionPart = index;
                                      weight = initialIntegerPart +
                                          initialFractionPart / 10.0;
                                    });
                                  },
                                  children: List.generate(
                                    maxFractionPart - minFractionPart + 1,
                                    (index) => Center(
                                      child: Text(
                                        "$index",
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const Spacer(flex: 1),
                            ],
                          ),
                          const Center(
                            child: Text(
                              '.',
                              style: TextStyle(
                                color: ColorPalette.darkGreen,
                              ),
                            ),
                          ),
                          Positioned(
                            right: Get.width * 0.1,
                            child: const Text(
                              'kg',
                              style: TextStyle(
                                color: ColorPalette.darkGreen,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    style: ButtonStyle(
                      fixedSize: WidgetStatePropertyAll(
                        Size.fromWidth(Get.width * 0.5),
                      ),
                      backgroundColor:
                          const WidgetStatePropertyAll(ColorPalette.green),
                    ),
                    onPressed: () {
                      onWeightSelected(weight); // Call the callback
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Select',
                      style: TextStyle(color: ColorPalette.beige),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _deleteAccountDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: ColorPalette.beige,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(
              width: 3,
              color: ColorPalette.lightGreen,
            ),
          ),
          title: const Text(
            'Account Deletion',
            style: TextStyle(color: ColorPalette.darkGreen),
            textAlign: TextAlign.center,
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Divider(
                color: ColorPalette.lightGreen,
                thickness: 2,
              ),
              SizedBox(height: 15),
              Text(
                'Do you want to delete your account?\n\nYour data will be permanently deleted and this action cannot be undone.',
                style: TextStyle(color: ColorPalette.darkGreen),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: ColorPalette.darkGreen),
              ),
            ),
            TextButton(
              onPressed: () async {
                Get.back(); // Close the confirmation dialog

                // Show password confirmation dialog
                await showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) {
                    return AlertDialog(
                      backgroundColor: ColorPalette.beige,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(
                          width: 3,
                          color: ColorPalette.lightGreen,
                        ),
                      ),
                      title: const Text(
                        'Confirm Password',
                        style: TextStyle(color: ColorPalette.darkGreen),
                      ),
                      content: Padding(
                        padding: const EdgeInsets.all(5),
                        child: TextFormField(
                          controller: _currentPasswordController,
                          style: const TextStyle(
                            color: ColorPalette.darkGreen,
                          ),
                          cursorColor: ColorPalette.green,
                          obscureText: true,
                          decoration: InputDecoration(
                            hintText: 'Enter your password',
                            hintStyle: TextStyle(
                              color: ColorPalette.green.withOpacity(0.75),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 0,
                              horizontal: 10,
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderSide: BorderSide(
                                color: ColorPalette.green,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.all(
                                Radius.circular(15),
                              ),
                            ),
                            enabledBorder: const OutlineInputBorder(
                              borderSide: BorderSide(
                                color: ColorPalette.green,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.all(
                                Radius.circular(15),
                              ),
                            ),
                          ),
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            _currentPasswordController.clear();
                            Get.back();
                          },
                          child: const Text(
                            'Cancel',
                            style: TextStyle(color: ColorPalette.darkGreen),
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            try {
                              await _authService.deleteUserAccount(
                                uid: currentUserFirebaseUid!,
                                password:
                                    _currentPasswordController.text.trim(),
                              );
                              _currentPasswordController.clear();

                              // Clear shared preferences
                              await prefs.clear();
                              // Initialize essential shared preferences data
                              await initSharedPrefData(prefs);
                              await prefs.setBool(
                                  'userHasFilledInfoForm', false);
                              await prefs.setBool('hasActiveSession', false);

                              debugPrint(
                                  '\nShared Prefs after account deletion:');
                              printKeyValueOfSharedPrefs(prefs);

                              // Navigate to landing page
                              await Get.offAll(() => const LandingPage());
                            } catch (e) {
                              debugPrint('Error during account deletion: $e');
                            }
                          },
                          child: const Text(
                            'Delete Account',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  void _logOutDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: ColorPalette.beige,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(
              width: 3,
              color: ColorPalette.lightGreen,
            ),
          ),
          title: const Text(
            'Log Out',
            style: TextStyle(color: ColorPalette.darkGreen),
            textAlign: TextAlign.center,
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Divider(
                color: ColorPalette.lightGreen,
                thickness: 2,
              ),
              SizedBox(height: 15),
              Text(
                'Do you want to log out from the session?\n\nConsider that your nutrition data will be stored only on this physical device. You can access your data by logging in again to continue using it.',
                style: TextStyle(color: ColorPalette.darkGreen),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: ColorPalette.darkGreen),
              ),
            ),
            TextButton(
              onPressed: () async {
                debugPrint('\nShared Prefs before sign out:');
                printKeyValueOfSharedPrefs(prefs);

                await _authService.signOut();

                debugPrint('\nShared Prefs after sign out:');
                printKeyValueOfSharedPrefs(prefs);

                await prefs.setBool('userHasFilledInfoForm', false);
                await prefs.setBool('hasActiveSession', false);

                await Get.offAll(() => const LandingPage());
              },
              child: const Text(
                'Log out',
                style: TextStyle(color: ColorPalette.darkGreen),
              ),
            ),
          ],
        );
      },
    );
  }

  _saveChanges() async {
    // calculate new bmi
    bodyMassIndexLevel = calculateBodyMassIndex(
      kgWeight: selectedWeight!,
      cmHeight: selectedHeight!,
    );
    debugPrint('BMI calculated...');
    // get new bmi advice
    await nutritionController.getBMIAdvice(
      bmi: bodyMassIndexLevel!,
      gender: selectedSex!,
      age: selectedAge!,
    );
    debugPrint('BMI advice generated...');
    // get new daily limits
    await nutritionController.calculateNutritionLimits(
      age: selectedAge!,
      gender: selectedSex!,
      height: selectedHeight!,
      weight: selectedWeight!,
    );
    debugPrint('Nutrition limits calculated...');
    // save physical information
    await _saveDataToSharedPrefs();
    debugPrint('Data saved to shared prefs:');
    printKeyValueOfSharedPrefs(prefs);
    // save user fields locally
    await _authService.updateUserFields(
      uid: currentUserFirebaseUid!,
      height: selectedHeight!,
      weight: selectedWeight!,
      age: selectedAge!,
      gender: selectedSex!,
    );
    debugPrint('Data saved locally');
    // save profile information
    debugPrint('Before user profile update');
    await _saveUserProfileChanges();
    debugPrint('After user profile update');
  }
}
