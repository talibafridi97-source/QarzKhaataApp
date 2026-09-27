import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/transaction_model.dart';
import '../providers/khaata_provider.dart';
import '../widgets/add_transaction_dialog.dart';

/// Screen displaying the transaction ledger for a specific debtor.
class DebtorDetailScreen extends StatefulWidget {
  final int debtorId;

  const DebtorDetailScreen({super.key, required this.debtorId});

  @override
  State<DebtorDetailScreen> createState() => _DebtorDetailScreenState();
}

class _DebtorDetailScreenState extends State<DebtorDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<KhaataProvider>().loadDebtorDetail(widget.debtorId);
    });
  }

  /// Launch Phone Dialer
  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch dialer for $phoneNumber')),
        );
      }
    }
  }

  /// Launch SMS
  Future<void> _sendSms(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'sms', path: phoneNumber);
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch messaging for $phoneNumber')),
        );
      }
    }
  }

  /// Launch WhatsApp with automated Personalized Balance summary
  Future<void> _sendWhatsAppMessage(
    BuildContext context,
    String phone,
    String name,
    double netBalance,
  ) async {
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
          SnackBar(content: Text('Could not open WhatsApp for $cleanPhone')),
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

  /// Confirm Delete Transaction
  void _confirmDeleteTransaction(BuildContext context, int transactionId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Entry?'),
        content: const Text('Are you sure you want to delete this ledger entry?'),
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
              await context.read<KhaataProvider>().deleteTransaction(transactionId, widget.debtorId);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<KhaataProvider>(
      builder: (context, provider, child) {
        final debtor = provider.currentDebtor;
        final transactions = provider.currentDebtorTransactions;
        final isLoading = provider.isLoading;

        if (isLoading && debtor == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (debtor == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Debtor Details')),
            body: const Center(child: Text('Debtor record not found.')),
          );
        }

        final double balance = debtor.netBalance;
        Color balanceColor;
        String statusLabel;

        if (balance > 0) {
          balanceColor = const Color(0xFFD32F2F);
          statusLabel = "You will get from ${debtor.name}";
        } else if (balance < 0) {
          balanceColor = const Color(0xFF2E7D32);
          statusLabel = "You will give to ${debtor.name}";
        } else {
          balanceColor = Colors.grey.shade700;
          statusLabel = "Account Settled";
        }

        return Scaffold(
          backgroundColor: Colors.grey.shade100,
          appBar: AppBar(
            backgroundColor: const Color(0xFF1E3C72),
            foregroundColor: Colors.white,
            elevation: 0,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  debtor.name,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  debtor.phone,
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF25D366)),
                tooltip: 'Send WhatsApp Reminder',
                onPressed: () => _sendWhatsAppMessage(
                  context,
                  debtor.phone,
                  debtor.name,
                  debtor.netBalance,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.call_outlined),
                tooltip: 'Call',
                onPressed: () => _makePhoneCall(debtor.phone),
              ),
              IconButton(
                icon: const Icon(Icons.message_outlined),
                tooltip: 'SMS',
                onPressed: () => _sendSms(debtor.phone),
              ),
            ],
          ),
          body: Column(
            children: [
              // Net Balance Header Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                decoration: const BoxDecoration(
                  color: Color(0xFF1E3C72),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(20),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            statusLabel,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Rs. ${balance.abs().toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: balanceColor,
                            ),
                          ),
                        ],
                      ),
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: balanceColor.withAlpha(20),
                        child: Icon(
                          balance > 0
                              ? Icons.arrow_circle_down_rounded
                              : (balance < 0 ? Icons.arrow_circle_up_rounded : Icons.check_circle_rounded),
                          color: balanceColor,
                          size: 32,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Transactions History List Label
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Transaction History',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      '${transactions.length} entries',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),

              // Transaction List or Empty State
              Expanded(
                child: transactions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.receipt_long_outlined,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No transactions recorded yet',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tap "GAVE" or "GOT" below to add an entry',
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: transactions.length,
                        itemBuilder: (context, index) {
                          final item = transactions[index];
                          final isGave = item.type == TransactionType.gave;
                          final itemColor = isGave ? const Color(0xFFD32F2F) : const Color(0xFF2E7D32);

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            elevation: 1,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              leading: CircleAvatar(
                                backgroundColor: itemColor.withAlpha(20),
                                child: Icon(
                                  isGave ? Icons.arrow_outward_rounded : Icons.south_west_rounded,
                                  color: itemColor,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                item.itemDetails,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              subtitle: Text(
                                DateFormat('dd MMM yyyy, hh:mm a').format(item.timestamp),
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'Rs. ${item.amount.toStringAsFixed(0)}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: itemColor,
                                        ),
                                      ),
                                      Text(
                                        isGave ? 'YOU GAVE' : 'YOU GOT',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: itemColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 4),

                                  // Edit Transaction Button
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 20),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    tooltip: 'Edit Entry',
                                    onPressed: () {
                                      AddTransactionDialog.show(
                                        context,
                                        debtorId: debtor.id!,
                                        debtorName: debtor.name,
                                        existingTransaction: item,
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 8),

                                  // Delete Transaction Button
                                  IconButton(
                                    icon: Icon(Icons.delete_outline_rounded, color: Colors.grey.shade400, size: 20),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    tooltip: 'Delete Entry',
                                    onPressed: () => _confirmDeleteTransaction(context, item.id!),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),

              // Bottom Quick Action Buttons Row (YOU GAVE / YOU GOT)
              SafeArea(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(15),
                        blurRadius: 8,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // YOU GAVE Button
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD32F2F),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 2,
                          ),
                          icon: const Icon(Icons.remove_circle_outline, size: 20),
                          label: const Text(
                            'YOU GAVE Rs',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          onPressed: () {
                            AddTransactionDialog.show(
                              context,
                              debtorId: debtor.id!,
                              debtorName: debtor.name,
                              initialType: TransactionType.gave,
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),

                      // YOU GOT Button
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 2,
                          ),
                          icon: const Icon(Icons.add_circle_outline, size: 20),
                          label: const Text(
                            'YOU GOT Rs',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          onPressed: () {
                            AddTransactionDialog.show(
                              context,
                              debtorId: debtor.id!,
                              debtorName: debtor.name,
                              initialType: TransactionType.got,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
