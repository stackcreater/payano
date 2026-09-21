import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_button.dart';

class PaymentMethodScreen extends StatelessWidget {
  const PaymentMethodScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Methods'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: AppSpacing.screenPadding,
          children: [
            const SizedBox(height: 12),
            _buildPaymentTile(
              context,
              icon: Icons.account_balance_wallet,
              title: 'Payano Wallet',
              subtitle: 'Balance: ₹250.00',
              isDefault: true,
              isDark: isDark,
              onTap: () {},
            ),
            const SizedBox(height: 12),
            _buildPaymentTile(
              context,
              icon: Icons.credit_card,
              title: 'Visa ending 4242',
              subtitle: 'Expires 12/27',
              isDefault: false,
              isDark: isDark,
              onTap: () {},
            ),
            const SizedBox(height: 12),
            _buildPaymentTile(
              context,
              icon: Icons.payment,
              title: 'UPI - rahul@okaxis',
              subtitle: 'Default UPI ID',
              isDefault: false,
              isDark: isDark,
              onTap: () {},
            ),
            const SizedBox(height: 12),
            _buildPaymentTile(
              context,
              icon: Icons.money,
              title: 'Cash',
              subtitle: 'Pay directly to driver',
              isDefault: false,
              isDark: isDark,
              onTap: () {},
            ),
            const SizedBox(height: 24),
            AppButton(
              text: 'Add Payment Method',
              variant: AppButtonVariant.outline,
              icon: Icons.add,
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (context) => Padding(
                    padding: AppSpacing.screenPadding,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: const Icon(Icons.credit_card, color: AppColors.primary),
                          title: const Text('Add Card'),
                          onTap: () {
                            context.pop();
                            context.push('/add-card');
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.payment, color: AppColors.primary),
                          title: const Text('Add UPI'),
                          onTap: () {
                            context.pop();
                            context.push('/add-upi');
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDefault,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: AppRadius.borderLg,
          boxShadow: AppShadows.cardShadow(isDark),
          border: isDefault ? Border.all(color: AppColors.primary, width: 2) : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(30),
                borderRadius: AppRadius.borderSm,
              ),
              child: Icon(icon, color: AppColors.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      if (isDefault) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(30),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text('DEFAULT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 20),
          ],
        ),
      ),
    );
  }
}
