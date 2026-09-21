import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';

class SupportScreen extends StatefulWidget {
  final bool isDriver;
  const SupportScreen({super.key, this.isDriver = false});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final TextEditingController _issueController = TextEditingController();
  late String _selectedCategory;

  // ── Student categories & FAQs ──────────────────────────────────────────
  static const List<String> _studentCategories = [
    'Ride Not Found / Long Wait',
    'Fare & Pricing Issue',
    'Driver Behaviour & Safety',
    'Payment / Refund Query',
    'Student ID Verification Issue',
    'App Technical Glitch',
  ];

  static const List<_FaqItem> _studentFaqs = [
    _FaqItem(
      question: 'How is the student ride fare calculated?',
      answer: 'Fares = Base Fare + Distance Rate (per km) + Time Rate (per min) + Platform Fee. '
          'Student discounts, if applicable, are deducted automatically at checkout.',
    ),
    _FaqItem(
      question: 'How do I get a refund for a cancelled ride?',
      answer: 'If your ride was cancelled by the driver or due to a system error, a refund is '
          'initiated within 24 hours to your original payment method or Payano Wallet.',
    ),
    _FaqItem(
      question: 'My student ID verification is pending — what do I do?',
      answer: 'Go to Profile → Student Documents and re-upload a clear photo of your student ID. '
          'Verification usually completes within a few minutes.',
    ),
    _FaqItem(
      question: 'Is a helmet provided for the ride?',
      answer: 'Yes! All Payano drivers carry a sanitised ISI-marked helmet for passenger safety '
          'as per traffic rules.',
    ),
  ];

  // ── Driver categories & FAQs ───────────────────────────────────────────
  static const List<String> _driverCategories = [
    'Payout / Earnings Issue',
    'Document Verification Rejected',
    'Ride Assignment Problem',
    'Passenger Complaint',
    'Vehicle / Insurance Update',
    'App Technical Glitch',
  ];

  static const List<_FaqItem> _driverFaqs = [
    _FaqItem(
      question: 'When will my earnings be paid out?',
      answer: 'Earnings are settled every Monday for the previous week\'s rides. '
          'You can also request an instant payout (₹1 fee) from the Earnings screen.',
    ),
    _FaqItem(
      question: 'My document was rejected — how do I re-submit?',
      answer: 'Go to Profile → My Documents and tap "Update Document" next to the rejected item. '
          'Upload a clear, unedited scan or photo. Verification takes up to 24 hours.',
    ),
    _FaqItem(
      question: 'How do I update my vehicle information?',
      answer: 'Navigate to Profile → My Documents → Vehicle RC & Insurance and upload the new documents. '
          'The update will be reviewed by our team within 24 hours.',
    ),
    _FaqItem(
      question: 'How is the driver rating calculated?',
      answer: 'Your rating is a weighted average of the last 500 completed rides. '
          'Ratings below 4.0 may temporarily pause your account for a review.',
    ),
  ];

  // ── Quick-action contacts ──────────────────────────────────────────────
  static const List<_ContactItem> _studentContacts = [
    _ContactItem(icon: Icons.chat_bubble_outline, label: 'Live Chat', color: Color(0xFF4CAF50)),
    _ContactItem(icon: Icons.phone_outlined, label: 'Call Support', color: Color(0xFF2196F3)),
    _ContactItem(icon: Icons.email_outlined, label: 'Email Us', color: Color(0xFFFF9800)),
  ];

  static const List<_ContactItem> _driverContacts = [
    _ContactItem(icon: Icons.headset_mic_outlined, label: 'Driver Helpline', color: Color(0xFF4CAF50)),
    _ContactItem(icon: Icons.account_balance_wallet_outlined, label: 'Earnings Support', color: Color(0xFF9C27B0)),
    _ContactItem(icon: Icons.verified_user_outlined, label: 'Docs Helpdesk', color: Color(0xFF2196F3)),
  ];

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.isDriver ? _driverCategories.first : _studentCategories.first;
  }

  @override
  void dispose() {
    _issueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isDriver = widget.isDriver;

    final List<String> categories = isDriver ? _driverCategories : _studentCategories;
    final List<_FaqItem> faqs = isDriver ? _driverFaqs : _studentFaqs;
    final List<_ContactItem> contacts = isDriver ? _driverContacts : _studentContacts;

    final Color accentColor = isDriver ? const Color(0xFF6C63FF) : const Color(0xFF00BFA5);

    return Scaffold(
      appBar: AppBar(
        title: Text(isDriver ? 'Driver Support' : 'Student Support'),
        backgroundColor: isDark ? const Color(0xFF1A1A2E) : accentColor.withOpacity(0.08),
        foregroundColor: isDark ? Colors.white : accentColor,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),

              // ── Header ────────────────────────────────────────────────
              Text(
                isDriver ? 'How can we assist you, Driver?' : 'How can we help you today?',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                isDriver
                    ? 'Reach the Payano Driver Support team — available 24 / 7.'
                    : 'Submit a ticket to the Payano Student Support team.',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 20),

              // ── Quick-contact chips ───────────────────────────────────
              Row(
                children: contacts
                    .map(
                      (c) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: _QuickContactChip(
                            item: c,
                            isDark: isDark,
                            onTap: () => ScaffoldMessenger.of(context)
                                .showSnackBar(SnackBar(content: Text('Opening ${c.label}…'))),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 24),

              // ── Ticket Form ───────────────────────────────────────────
              Text(
                'Submit a Support Ticket',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : Colors.black87),
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Select Issue Category',
                  filled: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                items: categories
                    .map((c) => DropdownMenuItem(
                        value: c, child: Text(c, overflow: TextOverflow.ellipsis)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedCategory = val!),
              ),
              const SizedBox(height: 16),

              AppTextField(
                controller: _issueController,
                labelText: 'Describe Your Issue',
                hintText: isDriver
                    ? 'Please detail the issue you faced as a driver…'
                    : 'Please detail what happened during your ride…',
              ),

              const SizedBox(height: 24),
              AppButton(
                text: 'Submit Support Ticket',
                onPressed: () {
                  final ms = DateTime.now().millisecond;
                  final ticketId = isDriver
                      ? 'DRV-${1000 + ms}'
                      : 'STU-${2000 + ms}';
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Ticket #$ticketId created! Our team will contact you within 2 hours.'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                  _issueController.clear();
                },
              ),

              // ── FAQ ───────────────────────────────────────────────────
              const SizedBox(height: 32),
              Text(
                isDriver ? 'Driver FAQ' : 'Frequently Asked Questions',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              ...faqs.map((faq) => ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: Text(faq.question, style: const TextStyle(fontSize: 14)),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(0, 0, 0, 12),
                        child: Text(
                          faq.answer,
                          style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.white70 : Colors.black54),
                        ),
                      ),
                    ],
                  )),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Data models ──────────────────────────────────────────────────────────────

class _FaqItem {
  final String question;
  final String answer;
  const _FaqItem({required this.question, required this.answer});
}

class _ContactItem {
  final IconData icon;
  final String label;
  final Color color;
  const _ContactItem({required this.icon, required this.label, required this.color});
}

// ── Quick-contact chip ────────────────────────────────────────────────────────

class _QuickContactChip extends StatelessWidget {
  final _ContactItem item;
  final bool isDark;
  final VoidCallback onTap;

  const _QuickContactChip({required this.item, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: isDark ? item.color.withOpacity(0.15) : item.color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: item.color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(item.icon, color: item.color, size: 24),
            const SizedBox(height: 6),
            Text(
              item.label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: item.color),
            ),
          ],
        ),
      ),
    );
  }
}
