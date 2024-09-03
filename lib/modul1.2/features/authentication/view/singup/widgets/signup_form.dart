import '/modul1.2/common/widgets/login_signup.dart/custom_text_form_field.dart';
import '/modul1.2/features/authentication/controllers/signup/signup_controller.dart';
import '/modul1.2/utils/validators/validation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import '/modul1.2/utils/constants/color.dart';
import '/modul1.2/utils/constants/sizes.dart';
import '/modul1.2/utils/constants/text_string.dart';

class TSignupForm extends StatefulWidget {
  const TSignupForm({super.key});

  @override
  State<TSignupForm> createState() => _TSignupFormState();
}

class _TSignupFormState extends State<TSignupForm> {
  bool _obscureText = true;

  void _togglePasswordVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  final controller = Get.put(SignupController());

  @override
  Widget build(BuildContext context) {
    return Form(
      key: controller.signupFormKey,
      child: Column(
        children: [
          // First & last name
          Row(
            children: [
              Expanded(
                child: CustomTextFormField(
                  validator: (value) =>
                      TValidator.validateEmptyText('First Name', value),
                  controller: controller.firstName,
                  hintText: TTexts.firstName,
                  prefixIcon: Iconsax.user,
                ),
              ),
              const SizedBox(width: TSizes.spaceBtwInputFields),
              Expanded(
                child: CustomTextFormField(
                  validator: (value) =>
                      TValidator.validateEmptyText('Last Name', value),
                  controller: controller.lastName,
                  hintText: TTexts.lastName,
                  prefixIcon: Iconsax.user,
                ),
              ),
            ],
          ),
          const SizedBox(height: TSizes.spaceBtwInputFields),

          // Username
          CustomTextFormField(
            validator: (value) =>
                TValidator.validateEmptyText('Username', value),
            controller: controller.username,
            hintText: TTexts.username,
            prefixIcon: Iconsax.user_edit,
          ),
          const SizedBox(height: TSizes.spaceBtwInputFields),

          // Email
          CustomTextFormField(
            validator: (value) => TValidator.validateEmail(value),
            controller: controller.email,
            hintText: TTexts.email,
            prefixIcon: Iconsax.sms,
          ),
          const SizedBox(height: TSizes.spaceBtwInputFields),

          // Phone number
          CustomTextFormField(
            validator: (value) => TValidator.validatePhoneNumber(value),
            controller: controller.phoneNumber,
            hintText: TTexts.tlp,
            prefixIcon: Iconsax.call,
          ),
          const SizedBox(height: TSizes.spaceBtwInputFields),

          // Password
          TextFormField(
            validator: (value) => TValidator.validatePassword(value),
            controller: controller.password,
            decoration: InputDecoration(
              hintText: TTexts.password,
              prefixIcon:
                  const Icon(Iconsax.password_check, color: Colors.grey),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureText ? Iconsax.eye_slash : Iconsax.eye,
                  color: Colors.grey,
                ),
                onPressed: _togglePasswordVisibility,
              ),
              filled: true,
              fillColor: const Color(0xFFF3F3F3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              hintStyle: const TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w700,
                color: Color(0xFF0B4D3B),
              ),
            ),
            obscureText: _obscureText,
          ),
          const SizedBox(height: TSizes.spaceBtwInputFields),

          // Sign Up Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => controller.signup(),
              style: ElevatedButton.styleFrom(
                backgroundColor: TColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                TTexts.btnSignUp,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
