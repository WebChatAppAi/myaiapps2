import 'package:flutter/material.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import '../theme/colors.dart';

class ToastUtils {
  /// Show a success toast notification at the top of the screen
  static void showSuccessToast(BuildContext? context, String message) {
    if (context == null) return;
    
    try {
      // Try to get Overlay safely
      final overlay = Overlay.maybeOf(context);
      if (overlay == null) {
        print('Toast warning: Overlay not available, skipping toast: $message');
        return;
      }
      
      showTopSnackBar(
        overlay,
        _buildModernToast(
          message: message,
          backgroundColor: Colors.green.shade700,
          icon: Icons.check_circle_rounded,
        ),
        displayDuration: const Duration(seconds: 2),
      );
    } catch (e) {
      print('Toast error: Unable to show success toast: $e');
    }
  }

  /// Show an error toast notification at the top of the screen
  static void showErrorToast(BuildContext? context, String message) {
    if (context == null) return;
    
    try {
      // Try to get Overlay safely
      final overlay = Overlay.maybeOf(context);
      if (overlay == null) {
        print('Toast warning: Overlay not available, skipping toast: $message');
        return;
      }
      
      showTopSnackBar(
        overlay,
        _buildModernToast(
          message: message,
          backgroundColor: Colors.red.shade700,
          icon: Icons.error_rounded,
        ),
        displayDuration: const Duration(seconds: 3),
      );
    } catch (e) {
      print('Toast error: Unable to show error toast: $e');
    }
  }

  /// Show an info toast notification at the top of the screen
  static void showInfoToast(BuildContext? context, String message) {
    if (context == null) return;
    
    try {
      // Try to get Overlay safely
      final overlay = Overlay.maybeOf(context);
      if (overlay == null) {
        print('Toast warning: Overlay not available, skipping toast: $message');
        return;
      }
      
      showTopSnackBar(
        overlay,
        _buildModernToast(
          message: message,
          backgroundColor: AppColors.accentBlue.withOpacity(0.9),
          icon: Icons.info_rounded,
        ),
        displayDuration: const Duration(seconds: 2),
      );
    } catch (e) {
      print('Toast error: Unable to show info toast: $e');
    }
  }

  /// Build a modern toast notification
  static Widget _buildModernToast({
    required String message,
    required Color backgroundColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 26,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
