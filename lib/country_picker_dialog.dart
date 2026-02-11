import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart' show Dialog, InputDecoration, TextStyle, FontWeight;
import 'package:flutter_intl_phone_field/countries.dart';
import 'package:flutter_intl_phone_field/helpers.dart';

class PickerDialogStyle {
  final Color? backgroundColor;

  final TextStyle? countryCodeStyle;

  final TextStyle? countryNameStyle;

  final Widget? listTileDivider;

  final EdgeInsets? listTilePadding;

  final EdgeInsets? dialogPadding;

  final EdgeInsets? padding;

  final Color? searchFieldCursorColor;

  final InputDecoration? searchFieldInputDecoration;

  final EdgeInsets? searchFieldPadding;

  final double? width;

  PickerDialogStyle({
    this.backgroundColor,
    this.countryCodeStyle,
    this.countryNameStyle,
    this.listTileDivider,
    this.listTilePadding,
    this.dialogPadding,
    this.padding,
    this.searchFieldCursorColor,
    this.searchFieldInputDecoration,
    this.searchFieldPadding,
    this.width,
  });
}

class CountryPickerDialog extends StatefulWidget {
  final List<Country> countryList;
  final Country selectedCountry;
  final ValueChanged<Country> onCountryChanged;
  final String searchText;
  final List<Country> filteredCountries;
  final PickerDialogStyle? style;
  final String languageCode;

  final EdgeInsets? dialogPadding;

  /// When false, only the picker content is built (no Dialog wrapper).
  /// Use with [showCupertinoModalPopup] for bottom sheet style.
  final bool showAsDialog;

  const CountryPickerDialog({
    Key? key,
    required this.searchText,
    required this.languageCode,
    required this.countryList,
    required this.onCountryChanged,
    required this.selectedCountry,
    required this.filteredCountries,
    this.style,
    this.dialogPadding,
    this.showAsDialog = true,
  }) : super(key: key);

  @override
  State<CountryPickerDialog> createState() => _CountryPickerDialogState();
}

class _CountryPickerDialogState extends State<CountryPickerDialog> {
  late List<Country> _filteredCountries;
  late Country _selectedCountry;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _selectedCountry = widget.selectedCountry;
    _filteredCountries = widget.filteredCountries.toList()
      ..sort(
        (a, b) => a
            .localizedName(widget.languageCode)
            .compareTo(b.localizedName(widget.languageCode)),
      );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() {
      _filteredCountries = widget.countryList.stringSearch(value)
        ..sort(
          (a, b) => a
              .localizedName(widget.languageCode)
              .compareTo(b.localizedName(widget.languageCode)),
        );
    });
  }

  Widget _buildPickerContent(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7),
        padding: widget.style?.padding ?? const EdgeInsets.all(0),
        color: widget.style?.backgroundColor ??
            CupertinoColors.systemBackground.resolveFrom(context),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // Üst başlık çubuğu (Cupertino tarzı)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGroupedBackground
                    .resolveFrom(context),
              ),
              child: SafeArea(
                bottom: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 80),
                    Text(
                      'Country',
                      style: CupertinoTheme.of(context)
                          .textTheme
                          .navTitleTextStyle,
                    ),
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Done'),
                    ),
                  ],
                ),
              ),
            ),
            // Ülke listesi (scroll)
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _filteredCountries.length,
                itemBuilder: (ctx, index) =>
                    _buildCountryTile(_filteredCountries[index]),
              ),
            ),
            // Modalın altında sabit arama (Safari tarzı)
            Container(
              padding: widget.style?.searchFieldPadding ??
                  const EdgeInsets.fromLTRB(16, 12, 16, 24),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGroupedBackground
                    .resolveFrom(context),
              ),
              child: SafeArea(
                top: false,
                child: CupertinoSearchTextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  placeholder: widget.searchText,
                  onChanged: _onSearchChanged,
                  style: CupertinoTheme.of(context).textTheme.textStyle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.showAsDialog) {
      return _buildPickerContent(context);
    }
    final mediaWidth = MediaQuery.of(context).size.width;
    final width = widget.style?.width ?? mediaWidth;
    const defaultHorizontalPadding = 40.0;
    const defaultVerticalPadding = 24.0;

    return Dialog(
      insetPadding: widget.style?.dialogPadding ??
          widget.dialogPadding ??
          EdgeInsets.symmetric(
              vertical: defaultVerticalPadding,
              horizontal: mediaWidth > (width + defaultHorizontalPadding * 2)
                  ? (mediaWidth - width) / 2
                  : defaultHorizontalPadding),
      backgroundColor: widget.style?.backgroundColor ??
          CupertinoColors.systemBackground.resolveFrom(context),
      child: _buildPickerContent(context),
    );
  }

  Widget _buildCountryTile(Country country) {
    final isSelected = country.code == _selectedCountry.code;
    return CupertinoListTile(
      leading: kIsWeb
          ? Image.asset(
              'assets/flags/${country.code.toLowerCase()}.png',
              package: 'flutter_intl_phone_field',
              width: 32,
            )
          : Text(
              country.flag,
              style: const TextStyle(fontSize: 18),
            ),
      padding: widget.style?.listTilePadding ??
          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      title: Text(
        country.localizedName(widget.languageCode),
        style: widget.style?.countryNameStyle ??
            CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                  fontWeight: FontWeight.w600,
                ),
      ),
      trailing: Text(
        '+${country.dialCode}',
        style: widget.style?.countryCodeStyle ??
            CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.activeBlue,
                ),
      ),
      backgroundColor: isSelected
          ? CupertinoColors.activeBlue.withValues(alpha: 0.15)
          : null,
      onTap: () => _selectCountry(country),
    );
  }

  void _selectCountry(Country country) {
    _selectedCountry = country;
    widget.onCountryChanged(_selectedCountry);
    Navigator.of(context).pop();
  }
}
