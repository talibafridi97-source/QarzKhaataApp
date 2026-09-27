import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/transaction_model.dart';
import '../providers/khaata_provider.dart';

/// Modal dialog/bottom sheet for adding or editing a transaction (Gave Credit / Received Cash).
class AddTransactionDialog extends StatefulWidget {
  final int debtorId;
  final String debtorName;
  final TransactionType initialType;
  final TransactionModel? existingTransaction;

  const AddTransactionDialog({
    super.key,
    required this.debtorId,
    required this.debtorName,
    this.initialType = TransactionType.gave,
    this.existingTransaction,
  });

  /// Static helper to launch the dialog bottom sheet
  static Future<void> show(
    BuildContext context, {
    required int debtorId,
    required String debtorName,
    TransactionType initialType = TransactionType.gave,
    TransactionModel? existingTransaction,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => AddTransactionDialog(
        debtorId: debtorId,
        debtorName: debtorName,
        initialType: initialType,
        existingTransaction: existingTransaction,
      ),
    );
  }

  @override
  State<AddTransactionDialog> createState() => _AddTransactionDialogState();
}

class _AddTransactionDialogState extends State<AddTransactionDialog> {
  final _formKey = GlobalKey<FormState>();
  late TransactionType _selectedType;
  late TextEditingController _amountController;
  late TextEditingController _detailsController;
  late DateTime _selectedDateTime;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingTransaction;
    if (existing != null) {
      _selectedType = existing.type;
      _amountController = TextEditingController(text: existing.amount == existing.amount.roundToDouble() ? existing.amount.toInt().toString() : existing.amount.toString());
      _detailsController = TextEditingController(text: existing.itemDetails);
      _selectedDateTime = existing.timestamp;
    } else {
      _selectedType = widget.initialType;
      _amountController = TextEditingController();
      _detailsController = TextEditingController();
      _selectedDateTime = DateTime.now();
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null && mounted) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
      );

      if (pickedTime != null) {
        setState(() {
          _selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final double amount = double.parse(_amountController.text.trim());
    final String details = _detailsController.text.trim();
    final isEditing = widget.existingTransaction != null;

    setState(() => _isSubmitting = true);

    final transaction = TransactionModel(
      id: widget.existingTransaction?.id,
      debtorId: widget.debtorId,
      itemDetails: details.isEmpty ? (_selectedType == TransactionType.gave ? 'Items given on credit' : 'Cash received payment') : details,
      amount: amount,
      type: _selectedType,
      timestamp: _selectedDateTime,
    );

    final provider = context.read<KhaataProvider>();
    final success = isEditing
        ? await provider.updateTransaction(transaction)
        : await provider.addTransaction(transaction);

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditing
                  ? 'Updated entry of Rs. ${amount.toStringAsFixed(0)}'
                  : (_selectedType == TransactionType.gave
                      ? 'Recorded credit entry of Rs. ${amount.toStringAsFixed(0)}'
                      : 'Recorded payment entry of Rs. ${amount.toStringAsFixed(0)}'),
            ),
            backgroundColor: _selectedType == TransactionType.gave ? Colors.red.shade700 : Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save entry. Please try again.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isGave = _selectedType == TransactionType.gave;
    final themeColor = isGave ? const Color(0xFFD32F2F) : const Color(0xFF2E7D32);
    final isEditing = widget.existingTransaction != null;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottomInset + 20),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: themeColor.withAlpha(25),
                    child: Icon(
                      isEditing ? Icons.edit_note_rounded : (isGave ? Icons.arrow_outward_rounded : Icons.south_west_rounded),
                      color: themeColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEditing
                              ? 'Edit Entry'
                              : (isGave ? 'You Gave (Credit)' : 'You Got (Payment)'),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: themeColor,
                          ),
                        ),
                        Text(
                          'Entry for ${widget.debtorName}',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Transaction Type Selector Segmented Toggle
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedType = TransactionType.gave),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isGave ? const Color(0xFFD32F2F) : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'YOU GAVE (Credit)',
                            style: TextStyle(
                              color: isGave ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedType = TransactionType.got),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: !isGave ? const Color(0xFF2E7D32) : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'YOU GOT (Got Cash)',
                            style: TextStyle(
                              color: !isGave ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Amount Field
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                autofocus: !isEditing,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: themeColor),
                decoration: InputDecoration(
                  labelText: 'Amount (Rs.) *',
                  hintText: '0',
                  prefixIcon: Icon(Icons.numbers_rounded, color: themeColor),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: themeColor, width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter amount';
                  }
                  final parsed = double.tryParse(value.trim());
                  if (parsed == null || parsed <= 0) {
                    return 'Enter a valid amount greater than 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Item Details / Notes Field
              TextFormField(
                controller: _detailsController,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Item Details / Description',
                  hintText: isGave ? 'e.g. 2 Milk Packets, Sugar 1kg' : 'e.g. Cash payment received',
                  prefixIcon: const Icon(Icons.notes_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: themeColor, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Date & Time Selector
              InkWell(
                onTap: _pickDateTime,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_rounded, color: themeColor, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Date & Time: ${DateFormat('dd MMM yyyy, hh:mm a').format(_selectedDateTime)}',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Save Action Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                  ),
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : Text(
                          isEditing ? 'Update Entry' : (isGave ? 'Save Credit Entry' : 'Save Payment Entry'),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
