import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../models/search_suggestion.dart';
import '../services/api_service.dart';
import '../widgets/app_loading_indicator.dart';
import '../theme/app_theme.dart';

/// Live autocomplete search — dropdown renders in an [Overlay], not in document flow.
class LiveSearchBar extends StatefulWidget {
  const LiveSearchBar({
    super.key,
    this.compact = false,
    this.onNavigate,
  });

  final bool compact;
  final VoidCallback? onNavigate;

  @override
  State<LiveSearchBar> createState() => _LiveSearchBarState();
}

class _LiveSearchBarState extends State<LiveSearchBar> {
  static const _minChars = 2;
  static const _debounceMs = 280;

  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _layerLink = LayerLink();
  final _anchorKey = GlobalKey();

  Timer? _debounce;
  int _requestGen = 0;
  int _selectedIndex = -1;
  OverlayEntry? _overlayEntry;

  List<SearchSuggestion> _results = [];
  bool _loading = false;
  bool _open = false;
  String _lastQuery = '';

  bool get _showDropdown => _open && _controller.text.trim().length >= _minChars;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _removeOverlay();
    _debounce?.cancel();
    _focusNode.removeListener(_onFocusChange);
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (mounted) setState(() {});
    if (_focusNode.hasFocus && _controller.text.trim().length >= _minChars) {
      setState(() => _open = true);
      _syncOverlay();
    }
    if (!_focusNode.hasFocus) {
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted && !_focusNode.hasFocus) {
          setState(() {
            _open = false;
            _selectedIndex = -1;
          });
          _removeOverlay();
        }
      });
    }
  }

  void _onTextChanged() {
    final query = _controller.text.trim();
    _debounce?.cancel();
    if (query.length < _minChars) {
      setState(() {
        _results = [];
        _loading = false;
        _open = false;
        _selectedIndex = -1;
        _lastQuery = query;
      });
      _removeOverlay();
      return;
    }
    setState(() {
      _loading = true;
      _open = true;
      _selectedIndex = -1;
      _lastQuery = query;
    });
    _syncOverlay();
    _debounce = Timer(const Duration(milliseconds: _debounceMs), () => _fetch(query));
  }

  Future<void> _fetch(String query) async {
    final gen = ++_requestGen;
    try {
      final results = await context.read<ApiService>().searchSuggest(query);
      if (!mounted || gen != _requestGen) return;
      setState(() {
        _results = results;
        _loading = false;
        _open = _focusNode.hasFocus && query.length >= _minChars;
      });
      _syncOverlay();
    } catch (_) {
      if (!mounted || gen != _requestGen) return;
      setState(() {
        _results = [];
        _loading = false;
      });
      _syncOverlay();
    }
  }

  double get _barHeight => widget.compact ? 44.0 : 48.0;

  double? _anchorWidth() {
    final box = _anchorKey.currentContext?.findRenderObject() as RenderBox?;
    return box?.size.width;
  }

  void _syncOverlay() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!_showDropdown) {
        _removeOverlay();
        return;
      }
      if (_overlayEntry == null) {
        _overlayEntry = OverlayEntry(builder: _buildOverlay);
        Overlay.of(context).insert(_overlayEntry!);
      } else {
        _overlayEntry!.markNeedsBuild();
      }
    });
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Widget _buildOverlay(BuildContext context) {
    final width = _anchorWidth();

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _close,
          ),
        ),
        CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, _barHeight + 6),
          child: Material(
            elevation: 16,
            shadowColor: Colors.black26,
            borderRadius: BorderRadius.circular(16),
            color: AppColors.white,
            child: AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: Container(
                width: width,
                constraints: const BoxConstraints(maxHeight: 380),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: _buildDropdownContent(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownContent() {
    if (_loading && _results.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: AppLoadingCenter(size: 48),
      );
    }
    if (_results.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          AppStrings.searchNoResults,
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textMuted),
        ),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _results.length,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        indent: 72,
        color: AppColors.border.withValues(alpha: 0.6),
      ),
      itemBuilder: (context, index) {
        final item = _results[index];
        final selected = index == _selectedIndex;
        return _SuggestionTile(
          item: item,
          query: _lastQuery,
          selected: selected,
          onTap: () => _selectProduct(item),
          onHover: () {
            setState(() => _selectedIndex = index);
            _overlayEntry?.markNeedsBuild();
          },
        );
      },
    );
  }

  void _close() {
    setState(() {
      _open = false;
      _selectedIndex = -1;
    });
    _removeOverlay();
    _focusNode.unfocus();
  }

  void _goToShop() {
    final query = _controller.text.trim();
    _close();
    widget.onNavigate?.call();
    context.go('/shop${query.isNotEmpty ? '?search=${Uri.encodeComponent(query)}' : ''}');
  }

  void _selectProduct(SearchSuggestion item) {
    _close();
    widget.onNavigate?.call();
    context.go('/product/${item.id}');
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent || !_open) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.escape) {
      _close();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter) {
      if (_selectedIndex >= 0 && _selectedIndex < _results.length) {
        _selectProduct(_results[_selectedIndex]);
      } else {
        _goToShop();
      }
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      if (_results.isEmpty) return KeyEventResult.handled;
      setState(() {
        _selectedIndex = (_selectedIndex + 1).clamp(0, _results.length - 1);
      });
      _overlayEntry?.markNeedsBuild();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      if (_results.isEmpty) return KeyEventResult.handled;
      setState(() {
        _selectedIndex = _selectedIndex <= 0 ? 0 : _selectedIndex - 1;
      });
      _overlayEntry?.markNeedsBuild();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(widget.compact ? 12 : 24);
    final focused = _focusNode.hasFocus;
    final showActiveBorder = _showDropdown || focused;

    return CompositedTransformTarget(
      key: _anchorKey,
      link: _layerLink,
      child: Focus(
        onKeyEvent: _handleKey,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          height: _barHeight,
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            boxShadow: showActiveBorder ? [AppTheme.goldGlow, AppTheme.searchShadow] : [AppTheme.searchShadow],
          ),
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            textAlign: TextAlign.right,
            decoration: InputDecoration(
              hintText: widget.compact ? AppStrings.searchProductsHint : AppStrings.searchHint,
              filled: true,
              fillColor: AppColors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              prefixIcon: _loading
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: AppLoadingInline(size: 28),
                      ),
                    )
                  : IconButton(
                      icon: Icon(Icons.search, color: focused ? AppColors.gold : AppColors.gold.withValues(alpha: 0.75)),
                      onPressed: _goToShop,
                    ),
              suffixIcon: _controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close, size: 18, color: AppColors.textMuted),
                      onPressed: () {
                        _controller.clear();
                        _close();
                      },
                    )
                  : null,
              border: OutlineInputBorder(borderRadius: borderRadius, borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(
                borderRadius: borderRadius,
                borderSide: BorderSide(
                  color: showActiveBorder ? AppColors.gold.withValues(alpha: 0.6) : AppColors.gold.withValues(alpha: 0.35),
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: borderRadius,
                borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
              ),
            ),
            onSubmitted: (_) => _goToShop(),
          ),
        ),
      ),
    );
  }
}

class _SuggestionTile extends StatefulWidget {
  const _SuggestionTile({
    required this.item,
    required this.query,
    required this.selected,
    required this.onTap,
    required this.onHover,
  });

  final SearchSuggestion item;
  final String query;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onHover;

  @override
  State<_SuggestionTile> createState() => _SuggestionTileState();
}

class _SuggestionTileState extends State<_SuggestionTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final highlighted = widget.selected || _hovered;

    return MouseRegion(
      onEnter: (_) {
        setState(() => _hovered = true);
        widget.onHover();
      },
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        color: highlighted ? AppColors.gold.withValues(alpha: 0.08) : Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: widget.item.image,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      width: 48,
                      height: 48,
                      color: AppColors.surfaceMuted,
                      child: const Icon(Icons.image_outlined, size: 22),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _HighlightText(
                        text: widget.item.name,
                        query: widget.query,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      if (widget.item.brand.isNotEmpty)
                        Text(
                          widget.item.brand,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textMuted),
                        ),
                      if (widget.item.category.isNotEmpty)
                        Text(
                          widget.item.category,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: AppColors.textMuted,
                                fontSize: 10,
                              ),
                        ),
                    ],
                  ),
                ),
                Text(
                  AppStrings.formatPrice(widget.item.price),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.gold,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HighlightText extends StatelessWidget {
  const _HighlightText({required this.text, required this.query, this.style});

  final String text;
  final String query;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final base = style ?? Theme.of(context).textTheme.bodyMedium;
    final q = query.trim();
    if (q.isEmpty) return Text(text, style: base, maxLines: 2, overflow: TextOverflow.ellipsis);

    final lowerText = text.toLowerCase();
    final lowerQuery = q.toLowerCase();
    final spans = <TextSpan>[];
    var start = 0;

    while (true) {
      final index = lowerText.indexOf(lowerQuery, start);
      if (index < 0) {
        if (start < text.length) spans.add(TextSpan(text: text.substring(start), style: base));
        break;
      }
      if (index > start) spans.add(TextSpan(text: text.substring(start, index), style: base));
      spans.add(
        TextSpan(
          text: text.substring(index, index + q.length),
          style: base?.copyWith(
            backgroundColor: AppColors.gold.withValues(alpha: 0.18),
            color: AppColors.goldDark,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
      start = index + q.length;
    }

    return RichText(
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(children: spans),
    );
  }
}
