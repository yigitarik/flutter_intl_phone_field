import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart' show Dialog, InputDecoration, TextStyle, FontWeight;
import 'package:flutter_intl_phone_field/countries.dart';
import 'package:flutter_intl_phone_field/helpers.dart';

/// Türkçe arayüz metinleri
class _Strings {
  static const String title = 'Ülke';
  static const String done = 'Tamam';
  static const String searchPlaceholder = 'Ülke ara';
}

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
  int _selectedIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  late FixedExtentScrollController _scrollController;

  static const double _itemExtent = 44.0;

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
    _selectedIndex = _indexOfSelectedInFiltered();
    _scrollController = FixedExtentScrollController(
      initialItem: _selectedIndex,
    );
  }

  int _indexOfSelectedInFiltered() {
    final i = _filteredCountries
        .indexWhere((c) => c.code == _selectedCountry.code);
    return i < 0 ? 0 : i;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController.dispose();
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
      _selectedIndex = _indexOfSelectedInFiltered();
      if (_selectedIndex < _filteredCountries.length) {
        _selectedCountry = _filteredCountries[_selectedIndex];
      }
      _scrollController.jumpToItem(_selectedIndex);
    });
  }

  void _onPickerSelected(int index) {
    setState(() {
      _selectedIndex = index;
      if (index < _filteredCountries.length) {
        _selectedCountry = _filteredCountries[index];
      }
    });
  }

  void _onDone() {
    widget.onCountryChanged(_selectedCountry);
    Navigator.of(context).pop();
  }

  Widget _buildPickerContent(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6),
        padding: widget.style?.padding ?? const EdgeInsets.all(0),
        color: widget.style?.backgroundColor ??
            CupertinoColors.systemBackground.resolveFrom(context),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // Üst araç çubuğu (Cupertino tarzı)
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
                      _Strings.title,
                      style: CupertinoTheme.of(context)
                          .textTheme
                          .navTitleTextStyle,
                    ),
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      onPressed: _onDone,
                      child: const Text(_Strings.done),
                    ),
                  ],
                ),
              ),
            ),
            // Arama (Türkçe placeholder)
            Container(
              padding: widget.style?.searchFieldPadding ??
                  const EdgeInsets.fromLTRB(16, 8, 16, 8),
              color: CupertinoColors.systemGroupedBackground
                  .resolveFrom(context),
              child: CupertinoSearchTextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                placeholder: widget.searchText.isNotEmpty
                    ? widget.searchText
                    : _Strings.searchPlaceholder,
                onChanged: _onSearchChanged,
                style: CupertinoTheme.of(context).textTheme.textStyle,
              ),
            ),
            // Tekerlek picker (CupertinoPicker)
            Flexible(
              child: _filteredCountries.isEmpty
                  ? const Center(child: Text('Ülke bulunamadı'))
                  : CupertinoPicker(
                      scrollController: _scrollController,
                      itemExtent: _itemExtent,
                      selectionOverlay: const CupertinoPickerDefaultSelectionOverlay(),
                      onSelectedItemChanged: _onPickerSelected,
                      children: List.generate(
                        _filteredCountries.length,
                        (index) {
                          final country = _filteredCountries[index];
                          return Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (kIsWeb)
                                  Image.asset(
                                    'assets/flags/${country.code.toLowerCase()}.png',
                                    package: 'flutter_intl_phone_field',
                                    width: 28,
                                    errorBuilder: (_, __, ___) =>
                                        Text(country.flag, style: const TextStyle(fontSize: 20)),
                                  )
                                else
                                  Text(
                                    country.flag,
                                    style: const TextStyle(fontSize: 20),
                                  ),
                                const SizedBox(width: 10),
                                Flexible(
                                  child: Text(
                                    country.localizedName(widget.languageCode),
                                    style: widget.style?.countryNameStyle ??
                                        CupertinoTheme.of(context)
                                            .textTheme
                                            .textStyle
                                            .copyWith(
                                                fontWeight: FontWeight.w600),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '+${country.dialCode}',
                                  style: widget.style?.countryCodeStyle ??
                                      CupertinoTheme.of(context)
                                          .textTheme
                                          .textStyle
                                          .copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: CupertinoColors.activeBlue,
                                          ),
                                ),
                              ],
                            ),
                          );
                        },
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
}
