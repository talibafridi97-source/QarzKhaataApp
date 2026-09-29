import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/khaata_provider.dart';

/// Top header widget displaying business/profile name, language selector, and running totals summary.
class BusinessHeader extends StatelessWidget {
  const BusinessHeader({super.key});

  void _showEditBusinessDialog(BuildContext context, String currentName) {
    final textController = TextEditingController(text: currentName);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.storefront_rounded, color: Colors.indigo),
              SizedBox(width: 8),
              Text('Edit Profile Name', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: textController,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Profile / Business Name',
                hintText: 'e.g. Talibjan Khaata',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.business_rounded),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Please enter a valid name';
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  context.read<KhaataProvider>().setBusinessName(textController.text);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Profile name updated successfully'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout / Switch Account?'),
        content: const Text('Are you sure you want to log out of this Khaata account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<KhaataProvider>().logout();
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<KhaataProvider>();
    final l10n = AppLocalizations(provider.locale);
    final businessName = provider.businessName;
    final totalReceivable = provider.totalReceivable;
    final totalDebtorsCount = provider.debtors.length;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(40),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Business Profile Header Bar
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: Colors.white.withAlpha(40),
                backgroundImage: provider.userImagePath != null &&
                        provider.userImagePath!.isNotEmpty &&
                        !kIsWeb &&
                        File(provider.userImagePath!).existsSync()
                    ? FileImage(File(provider.userImagePath!))
                    : null,
                child: (provider.userImagePath == null ||
                        provider.userImagePath!.isEmpty ||
                        kIsWeb ||
                        !File(provider.userImagePath!).existsSync())
                    ? const Icon(
                        Icons.store_rounded,
                        color: Colors.white,
                        size: 24,
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            businessName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, color: Colors.white70, size: 18),
                          padding: const EdgeInsets.only(left: 4),
                          constraints: const BoxConstraints(),
                          tooltip: 'Edit Profile Name',
                          onPressed: () => _showEditBusinessDialog(context, businessName),
                        ),
                      ],
                    ),
                    const Text(
                      'Digital Ledger • Qarz Khaata',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),

              // Language Selector Dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(30),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: DropdownButton<String>(
                  value: provider.locale,
                  dropdownColor: const Color(0xFF1E3C72),
                  underline: const SizedBox(),
                  icon: const Icon(Icons.language_rounded, color: Colors.white, size: 16),
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  items: const [
                    DropdownMenuItem(value: 'en', child: Text('EN')),
                    DropdownMenuItem(value: 'ur', child: Text('اردو')),
                    DropdownMenuItem(value: 'ps', child: Text('پښتو')),
                    DropdownMenuItem(value: 'ar', child: Text('عربي')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      provider.setLocale(val);
                    }
                  },
                ),
              ),
              const SizedBox(width: 4),

              IconButton(
                icon: const Icon(Icons.logout_rounded, color: Colors.white70, size: 22),
                tooltip: 'Logout / Switch Account',
                onPressed: () => _confirmLogout(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Total Summary Cards Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(25),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withAlpha(40)),
            ),
            child: Row(
              children: [
                // Total Receivable (You'll Get)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.arrow_downward_rounded, color: Color(0xFFFF8A80), size: 16),
                          const SizedBox(width: 4),
                          Text(
                            l10n.translate('you_ll_get'),
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Rs. ${totalReceivable.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Color(0xFFFF8A80),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(height: 36, width: 1, color: Colors.white30),
                const SizedBox(width: 16),

                // Total Debtors
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.people_alt_rounded, color: Colors.white70, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            l10n.translate('total'),
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$totalDebtorsCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
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
