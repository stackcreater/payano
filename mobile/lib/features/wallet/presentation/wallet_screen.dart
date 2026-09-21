import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  double _balance = 250.0;

  final List<Map<String, dynamic>> _transactions = [
    {'title': 'Payano Moto Ride to Koramangala', 'date': '28 Aug, 4:30 PM', 'amount': -45.0, 'type': 'DEBIT'},
    {'title': 'Wallet Top Up via PhonePe UPI', 'date': '27 Aug, 10:15 AM', 'amount': 200.0, 'type': 'CREDIT'},
    {'title': 'Payano Green EV Ride to Indiranagar', 'date': '26 Aug, 8:45 PM', 'amount': -35.0, 'type': 'DEBIT'},
    {'title': 'Promo Cashback PAYANO50', 'date': '26 Aug, 8:45 PM', 'amount': 25.0, 'type': 'CREDIT'},
  ];

  void _addMoney(double amount) {
    setState(() => _balance += amount);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('₹${amount.toStringAsFixed(0)} added to Payano Wallet successfully!'), backgroundColor: AppColors.success),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Payano Wallet')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              // Balance Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: AppRadius.borderLg,
                  boxShadow: AppShadows.cardShadow(isDark),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('TOTAL BALANCE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
                    const SizedBox(height: 6),
                    Text(
                      '₹${_balance.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _addMoney(200.0),
                          icon: const Icon(Icons.add, color: Colors.white),
                          label: const Text('+ Add ₹200', style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                        ),
                        const SizedBox(width: 10),
                        OutlinedButton(
                          onPressed: () => _addMoney(500.0),
                          style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.black)),
                          child: const Text('+ ₹500', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),
              const Text('Payment Methods', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              GestureDetector(
                onTap: () => context.push('/payment-method'),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : Colors.white,
                    borderRadius: AppRadius.borderMd,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.credit_card, color: AppColors.primary),
                      const SizedBox(width: 14),
                      const Expanded(child: Text('Manage Payment Methods', style: TextStyle(fontWeight: FontWeight.w600))),
                      const Icon(Icons.chevron_right, size: 20),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),
              const Text('Recent Transactions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              ..._transactions.map((tx) {
                final isCredit = tx['type'] == 'CREDIT';
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : Colors.white,
                    borderRadius: AppRadius.borderMd,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isCredit ? AppColors.success.withAlpha(30) : AppColors.error.withAlpha(30),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                          color: isCredit ? AppColors.success : AppColors.error,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tx['title'],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 2),
                            Text(tx['date'], style: TextStyle(fontSize: 12, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight)),
                          ],
                        ),
                      ),
                      Text(
                        '${isCredit ? "+" : "-"}₹${(tx['amount'] as double).abs().toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isCredit ? AppColors.success : (isDark ? Colors.white : Colors.black),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
