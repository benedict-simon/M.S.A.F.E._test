import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/vendor_supplier_service.dart';
import '../services/settings_service.dart';
import 'vendor_supplier_form_screen.dart';

class VendorSupplierDetailsScreen extends StatefulWidget {
  const VendorSupplierDetailsScreen({super.key});

  @override
  State<VendorSupplierDetailsScreen> createState() => _VendorSupplierDetailsScreenState();
}

class _VendorSupplierDetailsScreenState extends State<VendorSupplierDetailsScreen> {
  bool _loading = true;

  bool get _isEn => SettingsService.isEnglish;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await VendorSupplierService.fetchAll();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _openForm({VendorSupplier? supplier}) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => VendorSupplierFormScreen(supplier: supplier)),
    );
    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEn ? 'Supplier saved.' : 'Nai-save ang supplier.'),
        ),
      );
    }
  }

  Future<void> _confirmDelete(VendorSupplier supplier) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(_isEn ? 'Remove supplier?' : 'Alisin ang supplier?'),
        content: Text(
          _isEn
              ? 'Remove "${supplier.supplierName}" from your declared suppliers?'
              : 'Alisin ang "${supplier.supplierName}" sa iyong mga nakadeklarang supplier?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(_isEn ? 'Cancel' : 'Kanselahin'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(_isEn ? 'Remove' : 'Alisin', style: TextStyle(color: AppTheme.spoiledRed)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await VendorSupplierService.remove(supplier.id);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e is VendorSupplierServiceException
                ? e.message
                : (_isEn
                    ? "We couldn't remove that supplier. Please try again."
                    : 'Hindi namin naalis ang supplier. Pakisubukang muli.'),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([SettingsService.language, SettingsService.darkMode, VendorSupplierService.suppliers]),
      builder: (context, _) {
        final isEn = SettingsService.isEnglish;
        final suppliers = VendorSupplierService.suppliers.value;
        return Scaffold(
          backgroundColor: AppTheme.bgColor,
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    children: [
                      AppTheme.screenHeader(
                        context,
                        isEn ? 'Supplier Details' : 'Detalye ng Supplier',
                        titleFontSize: 18,
                      ),
                      const SizedBox(height: 20),
                      AppTheme.tintedInfoBox(
                        icon: Icons.local_shipping_rounded,
                        color: AppTheme.vendorBlue,
                        text: isEn
                            ? 'Declare who you source your meat from.'
                            : 'Ideklara kung kanino ka kumukuha ng karne.',
                      ),
                      const SizedBox(height: 20),
                      if (_loading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (suppliers.isEmpty)
                        _buildEmptyState(isEn)
                      else
                        for (final supplier in suppliers) ...[
                          _buildSupplierCard(isEn, supplier),
                          const SizedBox(height: 12),
                        ],
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _openForm(),
                          icon: Icon(Icons.add_rounded, size: 18, color: AppTheme.vendorBlue),
                          label: Text(
                            isEn ? 'Add Supplier' : 'Magdagdag ng Supplier',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.vendorBlue,
                            side: BorderSide(color: AppTheme.vendorBlue.withValues(alpha: 0.4)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(bool isEn) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.outlinedCard(radius: 14),
      child: Column(
        children: [
          Icon(Icons.local_shipping_outlined, size: 28, color: AppTheme.textFaint),
          const SizedBox(height: 10),
          Text(
            isEn ? 'No suppliers declared yet.' : 'Wala pang nadeklarang supplier.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textMuted, fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildSupplierCard(bool isEn, VendorSupplier supplier) {
    final subtitleParts = [
      if (supplier.supplierContact != null && supplier.supplierContact!.isNotEmpty) supplier.supplierContact!,
      if (supplier.supplierAddress != null && supplier.supplierAddress!.isNotEmpty) supplier.supplierAddress!,
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.outlinedCard(radius: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: AppTheme.iconBadgeBg(AppTheme.vendorBlue, radius: 10),
            child: Icon(Icons.local_shipping_rounded, size: 19, color: AppTheme.vendorBlue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  supplier.supplierName,
                  style: TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.w700, fontSize: 13.5),
                ),
                if (subtitleParts.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitleParts.join(' · '),
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 11.5),
                  ),
                ],
                if (supplier.supplierAccreditationNo != null && supplier.supplierAccreditationNo!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${isEn ? 'Accreditation' : 'Accreditation'}: ${supplier.supplierAccreditationNo}',
                    style: TextStyle(color: AppTheme.textFaint, fontSize: 11),
                  ),
                ],
              ],
            ),
          ),
          InkWell(
            onTap: () => _openForm(supplier: supplier),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(Icons.edit_outlined, size: 18, color: AppTheme.textMuted),
            ),
          ),
          InkWell(
            onTap: () => _confirmDelete(supplier),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(Icons.delete_outline_rounded, size: 18, color: AppTheme.spoiledRed),
            ),
          ),
        ],
      ),
    );
  }
}
