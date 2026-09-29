import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/khaata_provider.dart';
import '../widgets/add_debtor_sheet.dart';
import '../widgets/business_header.dart';
import '../widgets/debtor_card.dart';

/// Single-Page Primary Dashboard Screen for Qarz Khaata.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<KhaataProvider>();
    final l10n = AppLocalizations(provider.locale);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: Column(
          children: [
            // Top Header: Business Name & Summary Totals Card
            const BusinessHeader(),

            // Search Bar for Filtering Debtors (Kharzdaar)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(12),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    context.read<KhaataProvider>().setSearchQuery(val);
                  },
                  decoration: InputDecoration(
                    hintText: l10n.translate('search_hint'),
                    hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                    prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF1E3C72)),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, color: Colors.grey),
                            onPressed: () {
                              _searchController.clear();
                              context.read<KhaataProvider>().setSearchQuery('');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),

            // Main List View or Empty State
            Expanded(
              child: Consumer<KhaataProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading && provider.debtors.isEmpty) {
                    return const Center(
                      child: CircularProgressIndicator(color: Color(0xFF1E3C72)),
                    );
                  }

                  final debtors = provider.filteredDebtors;

                  if (debtors.isEmpty) {
                    final isSearching = provider.searchQuery.isNotEmpty;
                    return RefreshIndicator(
                      onRefresh: () => provider.loadDebtors(),
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        children: [
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircleAvatar(
                                  radius: 40,
                                  backgroundColor: Colors.indigo.withAlpha(15),
                                  child: Icon(
                                    isSearching ? Icons.search_off_rounded : Icons.people_outline_rounded,
                                    size: 44,
                                    color: const Color(0xFF1E3C72),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  isSearching ? 'No matching debtor found' : l10n.translate('no_debtors'),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 32),
                                  child: Text(
                                    isSearching
                                        ? 'Try searching with a different name or phone number.'
                                        : l10n.translate('no_debtors_sub'),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                if (!isSearching)
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF1E3C72),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    icon: const Icon(Icons.person_add_alt_1_rounded),
                                    label: Text(l10n.translate('add_kharzdaar_now')),
                                    onPressed: () => AddDebtorSheet.show(context),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () => provider.loadDebtors(),
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 80, top: 4),
                      itemCount: debtors.length,
                      itemBuilder: (context, index) {
                        return DebtorCard(debtor: debtors[index]);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),

      // Floating Action Button (FAB) at Bottom-Right Corner
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF1E3C72),
        foregroundColor: Colors.white,
        elevation: 4,
        onPressed: () => AddDebtorSheet.show(context),
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: Text(
          l10n.translate('add_kharzdaar'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
