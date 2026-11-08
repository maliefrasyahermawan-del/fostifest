import 'package:flutter/material.dart';

import 'laras_design.dart';

/// Uses natural heights and switches to one column when text needs more room.
class LarasAdaptivePair extends StatelessWidget {
  const LarasAdaptivePair({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, box) {
          final columns = box.maxWidth >= 300 &&
                  MediaQuery.textScalerOf(context).scale(16) <= 20
              ? 2
              : 1;
          return Column(
            children: [
              for (var i = 0; i < children.length; i += columns) ...[
                if (i > 0) const SizedBox(height: 12),
                if (columns == 1)
                  children[i]
                else
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: children[i]),
                        const SizedBox(width: 12),
                        Expanded(
                          child: i + 1 < children.length
                              ? children[i + 1]
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
              ],
            ],
          );
        },
      );
}

class LarasDataCard extends StatelessWidget {
  const LarasDataCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.note,
    this.highlight = false,
  });
  final String label, value;
  final String? note;
  final IconData icon;
  final bool highlight;
  @override
  Widget build(BuildContext context) {
    final foreground = LarasDesign.text(context);
    final muted = LarasDesign.secondary(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: highlight ? Colors.transparent : LarasDesign.line(context),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: LarasDesign.soft(context),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, size: 22, color: LarasDesign.accent(context)),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              fontWeight: FontWeight.w600,
              color: muted,
            ),
          ),
          const SizedBox(height: 6),
          Text.rich(
            TextSpan(
              children: value.startsWith('Rp')
                  ? [
                      TextSpan(
                        text: 'Rp ',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: foreground,
                        ),
                      ),
                      TextSpan(text: value.substring(2)),
                    ]
                  : [TextSpan(text: value)],
            ),
            semanticsLabel: value,
            style: TextStyle(
              fontSize: 23,
              height: 1.25,
              letterSpacing: -.65,
              fontFeatures: const [FontFeature.tabularFigures()],
              fontWeight: FontWeight.w600,
              color: foreground,
            ),
          ),
          if (note != null) ...[
            const SizedBox(height: 8),
            Text(
              note!,
              style: TextStyle(fontSize: 12, height: 1.5, color: muted),
            ),
          ],
        ],
      ),
    );
  }
}

class LarasWelcomePanel extends StatelessWidget {
  const LarasWelcomePanel({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.description,
    this.onAdd,
    this.compact = false,
  });
  final String eyebrow, title, description;
  final VoidCallback? onAdd;
  final bool compact;
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: LarasDesign.heroGradient,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -65,
              top: -80,
              child: ExcludeSemantics(
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      width: 32,
                      color: Colors.white.withValues(alpha: .06),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.spa_outlined,
                          color: Colors.white,
                          size: 21,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          eyebrow,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            letterSpacing: 1,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: compact ? 25 : 32,
                      height: 1.22,
                      letterSpacing: -.8,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.65,
                      color: Color(0xFFE3F4EC),
                    ),
                  ),
                  if (onAdd != null && !compact) ...[
                    const SizedBox(height: 20),
                    OutlinedButton.icon(
                      onPressed: onAdd,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Catat transaksi'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
}

class LarasRecordCard extends StatelessWidget {
  const LarasRecordCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onTap,
    this.trailing,
  });
  final String title, subtitle;
  final IconData icon;
  final VoidCallback? onTap;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExcludeSemantics(
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: LarasDesign.soft(context),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon,
                        size: 24, color: LarasDesign.accent(context)),
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
                          fontSize: 16,
                          height: 1.4,
                          fontWeight: FontWeight.w600,
                          color: LarasDesign.text(context),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.6,
                          color: LarasDesign.secondary(context),
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailing != null)
                  trailing!
                else if (onTap != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: ExcludeSemantics(
                      child: Icon(
                        Icons.chevron_right_rounded,
                        size: 22,
                        color: LarasDesign.accent(context),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
}

class LarasSegmentedTabs extends StatelessWidget {
  const LarasSegmentedTabs({
    super.key,
    required this.labels,
    required this.selected,
    required this.onSelected,
  });
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelected;
  @override
  Widget build(BuildContext context) => Material(
        color: LarasDesign.soft(context),
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < labels.length; i++)
                  Expanded(
                    child: Semantics(
                      selected: selected == i,
                      child: InkWell(
                        onTap: () => onSelected(i),
                        borderRadius: BorderRadius.circular(14),
                        child: AnimatedContainer(
                          duration: MediaQuery.disableAnimationsOf(context)
                              ? Duration.zero
                              : const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: selected == i
                                ? Theme.of(context).colorScheme.surface
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: Text(
                              labels[i],
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.4,
                                fontWeight: selected == i
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: selected == i
                                    ? LarasDesign.text(context)
                                    : LarasDesign.secondary(context),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
}
