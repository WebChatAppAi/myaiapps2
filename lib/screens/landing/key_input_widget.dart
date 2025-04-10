import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../utils/constants.dart';
import '../../theme/colors.dart';

class KeyInputWidget extends StatefulWidget {
  final Function(String) onKeySubmitted;

  const KeyInputWidget({
    Key? key,
    required this.onKeySubmitted,
  }) : super(key: key);

  @override
  State<KeyInputWidget> createState() => _KeyInputWidgetState();
}

class _KeyInputWidgetState extends State<KeyInputWidget> {
  final _keyController = TextEditingController();
  bool _isError = false;
  bool _isSuccess = false;

  void _validateKey() {
    final key = _keyController.text.trim();
    if (key == AppConstants.validAccessKey) {
      setState(() {
        _isError = false;
        _isSuccess = true;
      });
      widget.onKeySubmitted(key);
    } else {
      setState(() {
        _isError = true;
        _isSuccess = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeInUp(
      duration: AppConstants.mediumAnimation,
      child: TextField(
        controller: _keyController,
        decoration: InputDecoration(
          hintText: 'Enter access key',
          hintStyle: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 16,
          ),
          prefixIcon: Icon(
            Icons.key,
            color: _isError
                ? AppColors.error
                : _isSuccess
                    ? AppColors.success
                    : Colors.white.withOpacity(0.5),
          ),
          suffixIcon: IconButton(
            icon: Icon(
              _isSuccess ? Icons.check_circle : Icons.arrow_forward,
              color: _isSuccess
                  ? AppColors.success
                  : Colors.white.withOpacity(0.7),
            ),
            onPressed: _validateKey,
          ),
          errorText: _isError ? AppConstants.invalidKeyError : null,
          errorStyle: TextStyle(color: AppColors.error),
          filled: true,
          fillColor: Colors.transparent,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(
              color: Colors.white.withOpacity(0.2),
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(
              color: AppColors.error.withOpacity(0.5),
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(
              color: AppColors.error.withOpacity(0.7),
              width: 2,
            ),
          ),
        ),
        onSubmitted: (_) => _validateKey(),
        obscureText: true,
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
        ),
        cursorColor: Colors.white.withOpacity(0.7),
      ),
    );
  }

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }
}
