import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/location_service.dart';
import '../utils/text_formatters.dart';

class LocationAutocompleteField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<GeocodedAddress> onSelected;

  final VoidCallback? onManualEdit;

  final String? Function(String?)? validator;

  const LocationAutocompleteField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.onSelected,
    this.onManualEdit,
    this.validator,
  });

  @override
  State<LocationAutocompleteField> createState() => _LocationAutocompleteFieldState();
}

class _LocationAutocompleteFieldState extends State<LocationAutocompleteField> {
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;
  List<GeocodedAddress> _suggestions = const [];
  bool _loading = false;
  bool _suppressNextSearch = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    if (_suppressNextSearch) {
      _suppressNextSearch = false;
      return;
    }

    if (!_focusNode.hasFocus) return;

    widget.onManualEdit?.call();

    _debounce?.cancel();
    final query = text.trim();
    if (query.length < 3) {
      setState(() {
        _suggestions = const [];
        _loading = false;
      });
      return;
    }

    setState(() => _loading = true);
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      final results = await LocationService.searchSuggestions(query);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _suggestions = results;
      });
    });
  }

  void _select(GeocodedAddress address) {
    _debounce?.cancel();
    _suppressNextSearch = true;
    widget.controller.text = address.displayName;
    widget.controller.selection = TextSelection.collapsed(offset: widget.controller.text.length);
    setState(() {
      _suggestions = const [];
      _loading = false;
    });
    FocusScope.of(context).unfocus();
    widget.onSelected(address);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: widget.controller,
          focusNode: _focusNode,
          textCapitalization: TextCapitalization.words,
          inputFormatters: [TitleCaseTextFormatter()],
          onChanged: _onChanged,
          validator: widget.validator,
          decoration: InputDecoration(
            hintText: widget.hintText,
            suffixIcon: _loading
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : null,
          ),
        ),
        if (_suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < _suggestions.length; i++) ...[
                  if (i > 0) Divider(height: 1, color: AppTheme.borderColor),
                  _SuggestionTile(
                    address: _suggestions[i],
                    onTap: () => _select(_suggestions[i]),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _SuggestionTile extends StatelessWidget {
  final GeocodedAddress address;
  final VoidCallback onTap;

  const _SuggestionTile({required this.address, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Icon(Icons.location_on_outlined, color: AppTheme.roleAccent, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                address.displayName,
                style: TextStyle(color: AppTheme.textDark, fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
