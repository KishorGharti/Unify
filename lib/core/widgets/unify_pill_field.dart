import 'package:flutter/material.dart';
import '../theme/app_dimensions.dart';

class UnifyPillField extends StatefulWidget {
  final String hint;
  final TextEditingController? controller;
  final IconData icon;
  final bool isPassword;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  const UnifyPillField({
    Key? key,
    required this.hint,
    this.controller,
    required this.icon,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.validator,
  }) : super(key: key);

  @override
  State<UnifyPillField> createState() => _UnifyPillFieldState();
}

class _UnifyPillFieldState extends State<UnifyPillField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: widget.isPassword ? _obscure : false,
      keyboardType: widget.keyboardType,
      validator: widget.validator,
      style: const TextStyle(color: Color(0xFF334155), fontSize: 15),
      decoration: InputDecoration(
        hintText: widget.hint,
        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 15),
        filled: true,
        fillColor: const Color(0xFFF3F5F9),
        prefixIcon: Icon(widget.icon, color: const Color(0xFF94A3B8), size: 20),
        suffixIcon: widget.isPassword
            ? IconButton(
                icon: Icon(
                  _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: const Color(0xFF94A3B8),
                  size: 20,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              )
            : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(borderRadius: AppDimensions.roundedFull, borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: AppDimensions.roundedFull, borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppDimensions.roundedFull,
          borderSide: const BorderSide(color: Color(0xFF2FA0DE), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppDimensions.roundedFull,
          borderSide: const BorderSide(color: Colors.red, width: 1.2),
        ),
      ),
    );
  }
}
