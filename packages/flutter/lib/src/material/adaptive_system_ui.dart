import 'package:flutter/widgets.dart';

import 'adaptive_text_selection_toolbar.dart';

// TODO(justinmc): Maybe this should just be a SystemUIData?
class AdaptiveSystemUI extends StatelessWidget {
  const AdaptiveSystemUI({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SystemUI(
      data: SystemUIData(
        contextMenuBuilder:
            (
              BuildContext context,
              TextSelectionToolbarAnchors anchors,
              List<ContextMenuButtonItem>? buttonItems,
            ) {
              // TODO(justinmc): Is this where to decide what to do for no buttonItems, or should I make this non-nullable here?
              if (buttonItems == null || buttonItems.isEmpty) {
                return const SizedBox.shrink();
              }
              final Iterable<Widget> children = AdaptiveTextSelectionToolbar.getAdaptiveButtons(
                context,
                buttonItems,
              );
              return AdaptiveTextSelectionToolbar(anchors: anchors, children: children.toList());
            },
      ),
      child: child,
    );
  }
}
