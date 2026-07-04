import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../app_loading_indicator.dart';

class AdminTableColumn {
  const AdminTableColumn({
    required this.label,
    this.flex = 1,
    this.minWidth = 0,
    this.align = TextAlign.start,
  });

  final String label;
  final int flex;
  final double minWidth;
  final TextAlign align;
}

/// Paginated admin table with sticky header.
class AdminDataTable extends StatefulWidget {
  const AdminDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.pageSize = 15,
    this.emptyMessage = 'رکوردی یافت نشد',
    this.loading = false,
    this.horizontalScroll = false,
    this.cellPadding = 8,
  });

  final List<AdminTableColumn> columns;
  final List<List<Widget>> rows;
  final int pageSize;
  final String emptyMessage;
  final bool loading;
  final bool horizontalScroll;
  final double cellPadding;

  @override
  State<AdminDataTable> createState() => _AdminDataTableState();
}

class _AdminDataTableState extends State<AdminDataTable> {
  int _page = 0;

  @override
  void didUpdateWidget(covariant AdminDataTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    final maxPage = _maxPage;
    if (_page > maxPage) _page = maxPage;
  }

  int get _maxPage {
    if (widget.rows.isEmpty) return 0;
    return (widget.rows.length - 1) ~/ widget.pageSize;
  }

  List<List<Widget>> get _pageRows {
    final start = _page * widget.pageSize;
    final end = (start + widget.pageSize).clamp(0, widget.rows.length);
    if (start >= widget.rows.length) return [];
    return widget.rows.sublist(start, end);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.loading) {
      return const AppLoadingCenter();
    }

    if (widget.rows.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Text(widget.emptyMessage, style: TextStyle(color: AppColors.textMuted)),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final table = Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _HeaderRow(columns: widget.columns, cellPadding: widget.cellPadding),
                      Expanded(
                        child: Scrollbar(
                          thumbVisibility: true,
                          child: ListView.separated(
                            itemCount: _pageRows.length,
                            separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.border),
                            itemBuilder: (context, index) {
                              final cells = _pageRows[index];
                              return _BodyRow(
                                columns: widget.columns,
                                cells: cells,
                                striped: index.isOdd,
                                cellPadding: widget.cellPadding,
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  );

                  if (!widget.horizontalScroll) {
                    return SizedBox(height: constraints.maxHeight, child: table);
                  }

                  final tableWidth = _minTableWidth(context);
                  return Scrollbar(
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: tableWidth,
                        height: constraints.maxHeight,
                        child: table,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _PaginationBar(
          page: _page,
          maxPage: _maxPage,
          total: widget.rows.length,
          pageSize: widget.pageSize,
          onPageChanged: (p) => setState(() => _page = p),
        ),
      ],
    );
  }

  double _minTableWidth(BuildContext context) {
    final sum = widget.columns.fold<double>(0, (a, c) => a + c.minWidth);
    return sum.clamp(MediaQuery.sizeOf(context).width - 80, double.infinity);
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({required this.columns, required this.cellPadding});

  final List<AdminTableColumn> columns;
  final double cellPadding;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.black,
      padding: EdgeInsets.symmetric(horizontal: cellPadding, vertical: 10),
      child: Row(
        children: [
          for (final col in columns)
            Expanded(
              flex: col.flex,
              child: _TableCell(
                align: col.align,
                minWidth: col.minWidth,
                child: Text(
                  col.label,
                  textAlign: col.align,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.textOnDark,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BodyRow extends StatelessWidget {
  const _BodyRow({
    required this.columns,
    required this.cells,
    required this.striped,
    required this.cellPadding,
  });

  final List<AdminTableColumn> columns;
  final List<Widget> cells;
  final bool striped;
  final double cellPadding;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: striped ? AppColors.surfaceMuted.withValues(alpha: 0.35) : AppColors.white,
      padding: EdgeInsets.symmetric(horizontal: cellPadding, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (var i = 0; i < columns.length; i++)
            Expanded(
              flex: columns[i].flex,
              child: _TableCell(
                align: columns[i].align,
                minWidth: columns[i].minWidth,
                child: i < cells.length ? cells[i] : const SizedBox.shrink(),
              ),
            ),
        ],
      ),
    );
  }
}

class _TableCell extends StatelessWidget {
  const _TableCell({
    required this.align,
    required this.minWidth,
    required this.child,
  });

  final TextAlign align;
  final double minWidth;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (child is Text) {
      final text = child as Text;
      return Align(
        alignment: _alignment(align),
        widthFactor: 1,
        child: Text(
          text.data ?? '',
          textAlign: align,
          maxLines: text.maxLines,
          overflow: text.overflow ?? TextOverflow.ellipsis,
          style: text.style,
        ),
      );
    }

    if (align == TextAlign.center) {
      return Align(
        alignment: AlignmentDirectional.center,
        widthFactor: 1,
        child: child,
      );
    }

    final cell = Align(
      alignment: _alignment(align),
      widthFactor: 1,
      child: child,
    );

    if (minWidth <= 0) return cell;

    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: minWidth),
      child: cell,
    );
  }

  AlignmentGeometry _alignment(TextAlign align) => switch (align) {
        TextAlign.center => AlignmentDirectional.center,
        TextAlign.end => AlignmentDirectional.centerEnd,
        _ => AlignmentDirectional.centerStart,
      };
}

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({
    required this.page,
    required this.maxPage,
    required this.total,
    required this.pageSize,
    required this.onPageChanged,
  });

  final int page;
  final int maxPage;
  final int total;
  final int pageSize;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    final from = page * pageSize + 1;
    final to = ((page + 1) * pageSize).clamp(0, total);

    return Row(
      children: [
        Text(
          'نمایش $from تا $to از $total',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        const Spacer(),
        IconButton(
          tooltip: 'صفحه قبل',
          onPressed: page > 0 ? () => onPageChanged(page - 1) : null,
          icon: const Icon(Icons.chevron_right),
        ),
        Text('${page + 1} / ${maxPage + 1}', style: const TextStyle(fontWeight: FontWeight.w600)),
        IconButton(
          tooltip: 'صفحه بعد',
          onPressed: page < maxPage ? () => onPageChanged(page + 1) : null,
          icon: const Icon(Icons.chevron_left),
        ),
      ],
    );
  }
}

/// Search field for admin tables.
class AdminSearchBar extends StatelessWidget {
  const AdminSearchBar({
    super.key,
    required this.controller,
    required this.hint,
    this.onChanged,
    this.trailing,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            textAlign: TextAlign.right,
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: const Icon(Icons.search, size: 20),
              filled: true,
              fillColor: AppColors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 12), trailing!],
      ],
    );
  }
}

/// +/- quantity stepper for inventory.
class AdminQuantityStepper extends StatelessWidget {
  const AdminQuantityStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.loading = false,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _btn(Icons.remove, value > 0 ? () => onChanged(value - 1) : null),
        SizedBox(
          width: 36,
          child: Center(
            child: loading
                ? const AppLoadingInline(size: 14)
                : Text('$value', style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ),
        _btn(Icons.add, () => onChanged(value + 1)),
      ],
    );
  }

  Widget _btn(IconData icon, VoidCallback? onTap) {
    return SizedBox(
      width: 32,
      height: 32,
      child: IconButton(
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        style: IconButton.styleFrom(
          backgroundColor: AppColors.surfaceMuted,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}
