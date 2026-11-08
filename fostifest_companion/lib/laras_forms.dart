import 'package:flutter/material.dart';

import 'laras_design.dart';

/// Wait until the exit transition ends before the caller releases its inputs.
Future<T?> showLarasFormDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  final route = DialogRoute<T>(
    context: context,
    builder: builder,
    themes: InheritedTheme.capture(from: context, to: navigator.context),
  );
  final result = await navigator.push(route);
  await route.completed;
  return result;
}

/// Persistent visual labels also label the underlying native input semantics.
class LarasLabeledField extends StatelessWidget {
  const LarasLabeledField({
    super.key,
    required this.label,
    required this.child,
    this.optional = false,
  });
  final String label;
  final Widget child;
  final bool optional;
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(
            child: Wrap(
              spacing: 7,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                    color: LarasDesign.text(context),
                  ),
                ),
                if (optional)
                  Text(
                    '(opsional)',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.5,
                      color: LarasDesign.secondary(context),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Semantics(label: optional ? '$label, opsional' : label, child: child),
        ],
      );
}

InputDecoration larasEntryDecoration({
  String? hint,
  String? prefix,
  Widget? suffix,
}) =>
    InputDecoration(
      hintText: hint,
      prefixIcon: prefix == null
          ? null
          : Padding(
              padding: const EdgeInsets.only(left: 16, right: 8),
              child: Center(
                widthFactor: 1,
                child:
                    Text(prefix.trim(), style: const TextStyle(fontSize: 14)),
              ),
            ),
      prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      suffixIcon: suffix,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );

class LarasFormSection extends StatelessWidget {
  const LarasFormSection({
    super.key,
    required this.title,
    required this.children,
    this.filled = false,
  });
  final String title;
  final List<Widget> children;
  final bool filled;
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: filled ? const EdgeInsets.all(20) : EdgeInsets.zero,
        decoration: filled
            ? BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
              )
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                fontWeight: FontWeight.w600,
                color: LarasDesign.text(context),
              ),
            ),
            const SizedBox(height: 20),
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const SizedBox(height: 20),
              children[i],
            ],
          ],
        ),
      );
}

/// Header and actions remain visible; only the form body scrolls.
class LarasFormDialog extends StatefulWidget {
  const LarasFormDialog({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.body,
    required this.onCancel,
    required this.onSave,
  });
  final String title, description;
  final IconData icon;
  final Widget body;
  final VoidCallback onCancel, onSave;
  @override
  State<LarasFormDialog> createState() => _LarasFormDialogState();
}

class _LarasFormDialogState extends State<LarasFormDialog> {
  final _scroll = ScrollController();
  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        constraints: const BoxConstraints(maxWidth: 440),
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * .9,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ExcludeSemantics(
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: LarasDesign.soft(context),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          widget.icon,
                          size: 23,
                          color: LarasDesign.accent(context),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: TextStyle(
                              fontSize: 21,
                              height: 1.35,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -.4,
                              color: LarasDesign.text(context),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.description,
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.6,
                              color: LarasDesign.secondary(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: LarasDesign.line(context)),
              Flexible(
                child: Scrollbar(
                  controller: _scroll,
                  thumbVisibility: true,
                  thickness: 3,
                  radius: const Radius.circular(4),
                  child: SingleChildScrollView(
                    controller: _scroll,
                    key: const Key('laras_form_scroll'),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
                    child: widget.body,
                  ),
                ),
              ),
              Divider(height: 1, color: LarasDesign.line(context)),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 16, 22, 20),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: widget.onCancel,
                        child: const Text('Batal'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: widget.onSave,
                        child: const Text('Simpan'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}
