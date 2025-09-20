import 'package:cnn/features/Auth/color_palet.dart';
import 'package:flutter/material.dart';

class AuthField extends StatelessWidget {
  final TextEditingController? controller;
  final hintText;
  AuthField({super.key, this.hintText, this.controller});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: const BorderSide(
            color: ColorPalet.backgroundColorAuth,
            width: 3,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: const BorderSide(color: ColorPalet.grey, width: 3),
        ),
        filled: true,
        fillColor: ColorPalet.White,
        contentPadding: EdgeInsets.all(22),
        hintText: hintText,
        hintStyle: TextStyle(fontSize: 18),
      ),
    );
  }
}
