import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';

class AddUPIScreen extends StatefulWidget {
  const AddUPIScreen({super.key});

  @override
  State<AddUPIScreen> createState() => _AddUPIScreenState();
}

class _AddUPIScreenState extends State<AddUPIScreen> {
  final TextEditingController _upiController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  bool _isLoading = false;

  void _saveUpi() {
    if (_upiController.text.isEmpty || _nameController.text.isEmpty) {
      return;
    }
    setState(() => _isLoading = true);
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() => _isLoading = false);
        context.pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add UPI'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(30),
                    borderRadius: AppRadius.borderLg,
                  ),
                  child: Icon(Icons.payment, size: 40, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 32),

              Text(
                'UPI ID',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 6),
              AppTextField(
                controller: _upiController,
                hintText: 'yourname@upi',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              Text(
                'Account Holder Name',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 6),
              AppTextField(
                controller: _nameController,
                hintText: 'Name as per bank account',
              ),
              const SizedBox(height: 12),
              Text(
                'We will send a verification request to this UPI ID.',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                ),
              ),
              const SizedBox(height: 32),
              AppButton(
                text: 'Save UPI',
                isLoading: _isLoading,
                onPressed: _saveUpi,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
