import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/debtor_model.dart';
import '../providers/khaata_provider.dart';
import '../screens/debtor_detail_screen.dart';

/// Card widget representing an individual debtor item in the dashboard list.
class DebtorCard extends StatelessWidget {
  final Debtor debtor;

  const DebtorCard({super.key, required this.debtor});

  /// Launch Phone Dialer
  Future<void> _makePhoneCall(BuildContext context, String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not dial $phoneNumber')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error launching dialer: $e')),
        );
      }
    }
  }

  /// Send Direct WhatsApp Message with Customized Owner Name Balance Summary
  Future<void> _sendWhatsAppMessage(
    BuildContext context,
    String phone,
    String name,
    double netBalance,
  ) async {
    // Clean phone number (keep digits only)
    String cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanPhone.startsWith('0')) {
      cleanPhone = '92${cleanPhone.substring(1)}';
    } else if (!cleanPhone.startsWith('92')) {
      cleanPhone = '92$cleanPhone';
    }

    final provider = context.read<KhaataProvider>();
    final String senderName = provider.userName.trim().isNotEmpty
        ? provider.userName.trim()
        : provider.businessName.trim();

    String message;
    if (netBalance > 0) {
      message =
          'Assalam-o-Alaikum $name bhai,\n\n$senderName ka qarz jo aap ne liya tha, aap ke zimay total *Rs. ${netBalance.toStringAsFixed(0)}* baki hain.\n\nPlease clear your balance at your earliest convenience. Thank you!';
    } else if (netBalance < 0) {
      message =
          'Assalam-o-Alaikum $name bhai,\n\n$senderName ke zimay aap ke total *Rs. ${netBalance.abs().toStringAsFixed(0)}* rehte hain.\n\nShukriya!';
    } else {
      message =
          'Assalam-o-Alaikum $name bhai,\n\n$senderName ke sath aap ka qarz account fully clear / settled hai (*Rs. 0*).\n\nShukriya!';
    }

    final String encodedMsg = Uri.encodeComponent(message);
    final Uri waMeUri = Uri.parse('https://wa.me/$cleanPhone?text=$encodedMsg');
    final Uri waApiUri = Uri.parse('https://api.whatsapp.com/send?phone=$cleanPhone&text=$encodedMsg');

    try {
      bool launched = false;
      try {
        launched = await launchUrl(waMeUri, mode: LaunchMode.externalApplication);
      } catch (_) {}

      if (!launched) {
        try {
          launched = await launchUrl(waApiUri, mode: LaunchMode.externalApplication);
        } catch (_) {}
      }

      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open WhatsApp for $cleanPhone. Check internet/WhatsApp.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening WhatsApp: $e')),
        );
      }
    }
  }

  /// Show Delete Confirmation Dialog
  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Kharzdaar?'),
        content: Text(
          'Are you sure you want to delete "${debtor.name}"? This will permanently remove all associated transactions.',
        ),
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
            onPressed: () async {
              Navigator.pop(ctx);
              if (debtor.id != null) {
                final success = await context.read<KhaataProvider>().deleteDebtor(debtor.id!);
                if (success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Deleted ${debtor.name}')),
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  /// Show Edit Debtor Dialog
  void _showEditDebtorDialog(BuildContext context) {
    final nameController = TextEditingController(text: debtor.name);
    final phoneController = TextEditingController(text: debtor.phone);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Debtor Info'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.person),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.phone),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter phone number' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final updated = debtor.copyWith(
                  name: nameController.text.trim(),
                  phone: phoneController.text.trim(),
                );
                await context.read<KhaataProvider>().updateDebtor(updated);
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nameParts = debtor.name.trim().split(' ');
    String initials = debtor.name.isNotEmpty ? debtor.name[0].toUpperCase() : '?';
    if (nameParts.length > 1 && nameParts[1].isNotEmpty) {
      initials += nameParts[1][0].toUpperCase();
    }

    final double balance = debtor.netBalance;

    Color balanceColor;
    String statusText;
    String amountText = 'Rs. ${balance.abs().toStringAsFixed(0)}';

    if (balance > 0) {
      balanceColor = const Color(0xFFD32F2F);
      statusText = "You'll Get";
    } else if (balance < 0) {
      balanceColor = const Color(0xFF2E7D32);
      statusText = "You'll Give";
    } else {
      balanceColor = Colors.grey.shade600;
      statusText = 'Settled';
      amountText = 'Rs. 0';
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          if (debtor.id != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DebtorDetailScreen(debtorId: debtor.id!),
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Avatar with Initials
              CircleAvatar(
                radius: 24,
                backgroundColor: balanceColor.withAlpha(30),
                child: Text(
                  initials,
                  style: TextStyle(
                    color: balanceColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Debtor Name & Phone Number
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      debtor.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.phone_outlined, size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            debtor.phone,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // WhatsApp Direct Quick Action Icon
              IconButton(
                icon: Image.network(
                  'https://upload.wikimedia.org/wikipedia/commons/6/6b/WhatsApp.svg',
                  width: 22,
                  height: 22,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: Color(0xFF25D366),
                    size: 22,
                  ),
                ),
                tooltip: 'Send WhatsApp Balance Reminder',
                onPressed: () => _sendWhatsAppMessage(
                  context,
                  debtor.phone,
                  debtor.name,
                  debtor.netBalance,
                ),
              ),

              // Net Balance Column
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    amountText,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: balanceColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: balanceColor.withAlpha(20),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: balanceColor,
                      ),
                    ),
                  ),
                ],
              ),

              // Action Options Menu
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, color: Colors.black54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onSelected: (value) {
                  if (value == 'whatsapp') {
                    _sendWhatsAppMessage(
                      context,
                      debtor.phone,
                      debtor.name,
                      debtor.netBalance,
                    );
                  } else if (value == 'call') {
                    _makePhoneCall(context, debtor.phone);
                  } else if (value == 'edit') {
                    _showEditDebtorDialog(context);
                  } else if (value == 'delete') {
                    _confirmDelete(context);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'whatsapp',
                    child: Row(
                      children: [
                        Icon(Icons.chat_rounded, color: Color(0xFF25D366), size: 20),
                        SizedBox(width: 8),
                        Text('WhatsApp Reminder'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'call',
                    child: Row(
                      children: [
                        Icon(Icons.call_outlined, color: Colors.indigo, size: 20),
                        SizedBox(width: 8),
                        Text('Call Kharzdaar'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, color: Colors.blue, size: 20),
                        SizedBox(width: 8),
                        Text('Edit Debtor Info'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                        SizedBox(width: 8),
                        Text('Delete Kharzdaar'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
