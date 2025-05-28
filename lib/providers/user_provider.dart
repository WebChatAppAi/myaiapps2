import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class UserState {
  final String? userName;
  final String? email;
  final String? profilePicturePath;
  final List<String> generatedImages;
  final bool isLoading;

  UserState({
    this.userName,
    this.email,
    this.profilePicturePath,
    List<String>? generatedImages,
    this.isLoading = false,
  }) : generatedImages = generatedImages ?? [];

  UserState copyWith({
    String? userName,
    String? email,
    String? profilePicturePath,
    List<String>? generatedImages,
    bool? isLoading,
  }) {
    return UserState(
      userName: userName ?? this.userName,
      email: email ?? this.email,
      profilePicturePath: profilePicturePath ?? this.profilePicturePath,
      generatedImages: generatedImages ?? this.generatedImages,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class UserNotifier extends StateNotifier<UserState> {
  UserNotifier() : super(UserState()) {
    _loadUserData();
  }

  static const String _userNameKey = 'user_name';
  static const String _emailKey = 'user_email';
  static const String _profilePictureKey = 'profile_picture';
  static const String _generatedImagesKey = 'generated_images';

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userName = prefs.getString(_userNameKey);
      final email = prefs.getString(_emailKey);
      final profilePicturePath = prefs.getString(_profilePictureKey);
      final generatedImages = prefs.getStringList(_generatedImagesKey) ?? [];

      state = state.copyWith(
        userName: userName,
        email: email,
        profilePicturePath: profilePicturePath,
        generatedImages: generatedImages,
        isLoading: false,
      );
    } catch (e) {
      print('Error loading user data: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> updateUserName(String name) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userNameKey, name);
      state = state.copyWith(userName: name);
    } catch (e) {
      print('Error updating user name: $e');
    }
  }

  Future<void> updateEmail(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_emailKey, email);
      state = state.copyWith(email: email);
    } catch (e) {
      print('Error updating email: $e');
    }
  }

  Future<void> updateProfilePicture(String imagePath) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_profilePictureKey, imagePath);
      state = state.copyWith(profilePicturePath: imagePath);
    } catch (e) {
      print('Error updating profile picture: $e');
    }
  }

  Future<void> addGeneratedImage(String imagePath) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final updatedImages = [...state.generatedImages, imagePath];
      await prefs.setStringList(_generatedImagesKey, updatedImages);
      state = state.copyWith(generatedImages: updatedImages);
    } catch (e) {
      print('Error adding generated image: $e');
    }
  }

  Future<void> clearGeneratedImages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_generatedImagesKey);
      state = state.copyWith(generatedImages: []);
    } catch (e) {
      print('Error clearing generated images: $e');
    }
  }

  Future<void> clearUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userNameKey);
      await prefs.remove(_emailKey);
      await prefs.remove(_profilePictureKey);
      await prefs.remove(_generatedImagesKey);
      state = UserState();
    } catch (e) {
      print('Error clearing user data: $e');
    }
  }
}

final userProvider = StateNotifierProvider<UserNotifier, UserState>((ref) {
  return UserNotifier();
});
