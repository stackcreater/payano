import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/auth_service.dart';
import '../../../shared/models/uploaded_file.dart';

class DriverDocumentsScreen extends ConsumerStatefulWidget {
  const DriverDocumentsScreen({super.key});

  @override
  ConsumerState<DriverDocumentsScreen> createState() => _DriverDocumentsScreenState();
}

class _DriverDocumentsScreenState extends ConsumerState<DriverDocumentsScreen> {
  // Update form fields
  String _selectedDocType = 'Driving Licence (DL)';
  final TextEditingController _docNumberController = TextEditingController(text: 'DL123456789012');
  final TextEditingController _vehicleModelController = TextEditingController(text: 'Honda Activa 6G');
  final TextEditingController _regNumberController = TextEditingController(text: 'TN 30 AB 4582');
  
  AppUploadedFile? _selectedFile;
  bool _isSaving = false;
  String? _successMessage;

  @override
  void dispose() {
    _docNumberController.dispose();
    _vehicleModelController.dispose();
    _regNumberController.dispose();
    super.dispose();
  }

  void _handleDocTypeChange(String? newType) {
    if (newType == null) return;
    setState(() {
      _selectedDocType = newType;
      _selectedFile = null;
      if (newType.contains('Licence')) {
        _docNumberController.text = 'DL123456789012';
      } else if (newType.contains('RC')) {
        _docNumberController.text = 'TN30AB4582';
      } else if (newType.contains('Insurance')) {
        _docNumberController.text = 'POL-1234567890';
      } else {
        _docNumberController.text = '';
      }
    });
  }

  Future<void> _handleSaveUpdate() async {
    setState(() {
      _isSaving = true;
      _successMessage = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      await authService.submitDriverRegistration(
        vehicleType: 'Scooter',
        makeModel: _vehicleModelController.text.trim(),
        registrationNumber: _regNumberController.text.trim(),
        color: 'Blue',
        ownership: 'I own this vehicle',
        dlDocNumber: _selectedDocType.contains('Licence') ? _docNumberController.text.trim() : 'DL123456789012',
        rcDocNumber: _selectedDocType.contains('RC') ? _docNumberController.text.trim() : 'TN30AB4582',
        insuranceDocNumber: _selectedDocType.contains('Insurance') ? _docNumberController.text.trim() : 'POL-1234567890',
      );

      if (mounted) {
        setState(() {
          _isSaving = false;
          _successMessage = '$_selectedDocType updated and verified successfully!';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text('$_selectedDocType updated successfully!')),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Update failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(authServiceProvider).currentUser;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B111E) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/driver/home');
            }
          },
        ),
        title: const Text(
          'Documents & Verification',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Active Verified Driver Banner ──
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF065F46), Color(0xFF047857)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF047857).withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.verified_rounded,
                        color: Color(0xFF047857),
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Active Driver • Verified',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user?.name ?? 'Driver Account',
                            style: const TextStyle(
                              color: Color(0xFFA7F3D0),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'All required student & driver documents are approved.',
                            style: TextStyle(
                              color: Color(0xFFD1FAE5),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── SECTION 1: DOCUMENTS VERIFIED ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Documents Verified',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, size: 12, color: Color(0xFF16A34A)),
                        SizedBox(width: 4),
                        Text(
                          '4/4 Approved',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF16A34A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              _buildVerifiedDocCard(
                icon: Icons.school_outlined,
                title: 'Student ID Verification',
                subtitle: 'College ID verified • Sona College of Tech',
                docNumber: 'Verified Student ID',
                isDark: isDark,
              ),
              const SizedBox(height: 10),

              _buildVerifiedDocCard(
                icon: Icons.badge_outlined,
                title: 'Driving Licence (DL)',
                subtitle: 'Two-Wheeler with Gear / Without Gear',
                docNumber: 'DL No: DL123456789012',
                isDark: isDark,
              ),
              const SizedBox(height: 10),

              _buildVerifiedDocCard(
                icon: Icons.two_wheeler_outlined,
                title: 'Vehicle Registration (RC)',
                subtitle: 'Honda Activa 6G • Two Wheeler',
                docNumber: 'Plate No: TN 30 AB 4582',
                isDark: isDark,
              ),
              const SizedBox(height: 10),

              _buildVerifiedDocCard(
                icon: Icons.security_outlined,
                title: 'Vehicle Insurance',
                subtitle: 'Comprehensive 2-Wheeler Policy',
                docNumber: 'Policy No: POL-1234567890',
                isDark: isDark,
              ),

              const SizedBox(height: 28),

              // ── SECTION 2: UPDATE DOCUMENTS ──
              Text(
                'Update Documents',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Need to update an expired license, renewed insurance, or vehicle details? Select the document below.',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Select Document Type
                    const Text(
                      'Document To Update',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedDocType,
                          isExpanded: true,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                          dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                          items: [
                            'Driving Licence (DL)',
                            'Vehicle Registration (RC)',
                            'Vehicle Insurance',
                            'Vehicle Details',
                          ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                          onChanged: _handleDocTypeChange,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Document Number / ID Field
                    Text(
                      _selectedDocType.contains('Licence')
                          ? 'Driving Licence Number'
                          : _selectedDocType.contains('RC')
                              ? 'Vehicle Registration Number'
                              : _selectedDocType.contains('Insurance')
                                  ? 'Insurance Policy Number'
                                  : 'Vehicle Model & Details',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                        ),
                      ),
                      child: TextField(
                        controller: _docNumberController,
                        style: TextStyle(
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          fontSize: 14,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Enter updated document number',
                          hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                          prefixIcon: Icon(Icons.edit_note, color: Color(0xFF2563EB), size: 20),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Upload Document File Button
                    const Text(
                      'Upload Document Photo / Proof',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () async {
                        final file = await AppUploadedFile.pickDocument();
                        if (file != null) {
                          setState(() => _selectedFile = file);
                        } else {
                          setState(() {
                            _selectedFile = AppUploadedFile(
                              name: '${_selectedDocType.replaceAll(' ', '_')}_updated.pdf',
                              extension: 'pdf',
                              size: 1024 * 320,
                            );
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF2563EB),
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _selectedFile != null ? Icons.check_circle : Icons.upload_file,
                              color: _selectedFile != null ? const Color(0xFF10B981) : const Color(0xFF2563EB),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _selectedFile != null
                                  ? _selectedFile!.name
                                  : 'Tap to select document photo (JPG/PDF)',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _selectedFile != null
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFF2563EB),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (_successMessage != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle, size: 16, color: Color(0xFF16A34A)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _successMessage!,
                                style: const TextStyle(fontSize: 12, color: Color(0xFF16A34A), fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Update Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        onPressed: _isSaving ? null : _handleSaveUpdate,
                        child: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text(
                                'Update Document',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVerifiedDocCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String docNumber,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF2563EB), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check, size: 12, color: Color(0xFF16A34A)),
                          SizedBox(width: 2),
                          Text(
                            'Verified',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF16A34A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  docNumber,
                  style: const TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
