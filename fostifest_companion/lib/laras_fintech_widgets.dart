import 'package:flutter/material.dart';

import 'laras_design.dart';

class LarasInventoryCard extends StatelessWidget {
  const LarasInventoryCard({
    super.key,
    required this.name,
    required this.price,
    required this.cost,
    required this.stock,
    required this.low,
    required this.onEdit,
    required this.onDelete,
  });
  final String name, price, cost, stock;
  final bool low;
  final VoidCallback onEdit, onDelete;
  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          onTap: onEdit,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: LarasDesign.soft(context),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.inventory_2_outlined,
                        size: 22,
                        color: LarasDesign.accent(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        name,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.5,
                          fontWeight: FontWeight.w600,
                          color: LarasDesign.text(context),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Hapus produk',
                      onPressed: onDelete,
                      icon: Icon(
                        Icons.delete_outline,
                        size: 22,
                        color: LarasDesign.secondary(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 24,
                  runSpacing: 12,
                  children: [
                    for (final entry in [
                      ('Harga jual', price),
                      ('Harga modal', cost),
                      ('Stok', stock),
                    ])
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.$1,
                            style: TextStyle(
                              fontSize: 11,
                              color: LarasDesign.secondary(context),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            entry.$2,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.5,
                              fontWeight: FontWeight.w500,
                              color: LarasDesign.text(context),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                if (low) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      color: LarasDesign.tileTone(context, 2),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text(
                      'Stok menipis',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: LarasDesign.text(context),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
}

class LarasAmountRow extends StatelessWidget {
  const LarasAmountRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.amount,
    this.icon = Icons.receipt_long_outlined,
    this.outgoing = false,
  });
  final String title, subtitle, amount;
  final IconData icon;
  final bool outgoing;
  @override
  Widget build(BuildContext context) {
    final stacked = MediaQuery.textScalerOf(context).scale(16) > 21;
    final amountStyle = TextStyle(
      fontSize: 14,
      height: 1.5,
      fontWeight: FontWeight.w600,
      color: outgoing ? LarasDesign.text(context) : LarasDesign.accent(context),
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: LarasDesign.tileTone(context, outgoing ? 2 : 0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: LarasDesign.accent(context), size: 21),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                      color: LarasDesign.text(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.55,
                      color: LarasDesign.secondary(context),
                    ),
                  ),
                  if (stacked) ...[
                    const SizedBox(height: 8),
                    Text(amount, style: amountStyle),
                  ],
                ],
              ),
            ),
            if (!stacked) ...[
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  amount,
                  textAlign: TextAlign.right,
                  style: amountStyle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A financial overview, not a payment card. All amounts are supplied by HomePage.
class LarasBusinessOverview extends StatelessWidget {
  const LarasBusinessOverview({
    super.key,
    required this.revenue,
    required this.profit,
    required this.transactions,
  });
  final String revenue, profit;
  final int transactions;
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: LarasDesign.heroGradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Color(0x18066B4C),
              blurRadius: 28,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: Stack(
          children: [
            const Positioned(
              right: -90,
              top: -100,
              child: _OverviewOrbit(size: 260),
            ),
            const Positioned(
              right: -45,
              bottom: -125,
              child: _OverviewOrbit(size: 230),
            ),
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Expanded(
                        child: Text(
                          'Ringkasan usaha',
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            color: Color(0xFFE3F4EC),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Bulan ini',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'OMZET BULAN INI',
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.5,
                      letterSpacing: .8,
                      color: Color(0xFFE3F4EC),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    revenue,
                    style: const TextStyle(
                      fontSize: 31,
                      height: 1.3,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -.8,
                      color: Colors.white,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Divider(
                      height: 1, color: Colors.white.withValues(alpha: .22)),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 28,
                    runSpacing: 14,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ESTIMASI LABA',
                            style: TextStyle(
                              fontSize: 10.5,
                              height: 1.5,
                              letterSpacing: .4,
                              color: Color(0xFFE3F4EC),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            profit,
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'TERCATAT',
                            style: TextStyle(
                              fontSize: 10.5,
                              height: 1.5,
                              letterSpacing: .4,
                              color: Color(0xFFE3F4EC),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$transactions transaksi',
                            style: const TextStyle(
                              fontSize: 15,
                              height: 1.8,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Laba berdasarkan biaya yang sudah dicatat.',
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.5,
                      color: Color(0xFFE3F4EC),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _OverviewOrbit extends StatelessWidget {
  const _OverviewOrbit({required this.size});
  final double size;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: .035),
            border: Border.all(
              color: Colors.white.withValues(alpha: .07),
              width: 20,
            ),
          ),
        ),
      );
}

class LarasQuickAction extends StatelessWidget {
  const LarasQuickAction({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.tone = 0,
  });
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final int tone;
  @override
  Widget build(BuildContext context) => Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ExcludeSemantics(
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: LarasDesign.tileTone(context, tone),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon,
                        size: 23, color: LarasDesign.accent(context)),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                    color: LarasDesign.text(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class LarasShortcutGrid extends StatelessWidget {
  const LarasShortcutGrid({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, box) {
          final largeText = MediaQuery.textScalerOf(context).scale(16) > 22;
          final columns = largeText ? 1 : 3;
          return Column(
            children: [
              for (var i = 0; i < children.length; i += columns) ...[
                if (i > 0) const SizedBox(height: 12),
                if (columns == 1)
                  SizedBox(width: double.infinity, child: children[i])
                else
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var j = i; j < i + columns; j++) ...[
                          if (j > i) const SizedBox(width: 12),
                          Expanded(
                            child: j < children.length
                                ? children[j]
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ],
          );
        },
      );
}

/// Paints the existing four time buckets; no financial data is generated here.
class LarasTrendPlot extends StatelessWidget {
  const LarasTrendPlot({super.key, required this.values, required this.labels});
  final List<int> values;
  final List<String> labels;
  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);
    return Semantics(
      label:
          'Tren omzet: ${List.generate(values.length, (i) => 'bagian ${i + 1}, ${LarasDesign.money(values[i])}').join('; ')}',
      child: Column(
        children: [
          SizedBox(
            height: 148,
            width: double.infinity,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: reduced ? 1 : 0, end: 1),
              duration:
                  reduced ? Duration.zero : const Duration(milliseconds: 360),
              curve: Curves.easeOutCubic,
              builder: (_, progress, __) => CustomPaint(
                painter: _TrendPainter(
                  values,
                  LarasDesign.accent(context),
                  LarasDesign.line(context),
                  progress,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (var i = 0; i < labels.length; i++)
                Expanded(
                  child: Text(
                    labels[i],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10.5,
                      height: 1.5,
                      color: LarasDesign.secondary(context),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  _TrendPainter(this.values, this.color, this.grid, this.progress);
  final List<int> values;
  final Color color, grid;
  final double progress;
  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = .7;
    for (var i = 0; i < 4; i++) {
      final y = 12 + (size.height - 24) * i / 3;
      canvas.drawLine(Offset(8, y), Offset(size.width - 8, y), gridPaint);
    }
    final maximum = values.fold<int>(1, (a, b) => a > b ? a : b);
    final points = List.generate(
      values.length,
      (i) => Offset(
        12 + (size.width - 24) * i / (values.length - 1),
        size.height - 12 - (size.height - 32) * values[i] / maximum,
      ),
    );
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final a = points[i - 1], b = points[i], mid = (a.dx + b.dx) / 2;
      path.cubicTo(mid, a.dy, mid, b.dy, b.dx, b.dy);
    }
    final area = Path.from(path)
      ..lineTo(points.last.dx, size.height)
      ..lineTo(points.first.dx, size.height)
      ..close();
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width * progress, size.height));
    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: .17), color.withValues(alpha: .005)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
    for (final p in points) {
      canvas.drawCircle(p, 3.5, Paint()..color = color);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _TrendPainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.grid != grid ||
      old.values != values;
}
