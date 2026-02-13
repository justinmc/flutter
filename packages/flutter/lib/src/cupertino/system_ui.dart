import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'desktop_text_selection_toolbar_button.dart';
import 'desktop_text_selection_toolbar.dart';
import 'text_selection_toolbar.dart';
import 'text_selection_toolbar_button.dart';

class CupertinoSystemUI extends StatelessWidget {
  const CupertinoSystemUI({super.key, required this.child});

  final Widget child;

  Iterable<Widget> _getButtons(BuildContext context, List<ContextMenuButtonItem> buttonItems) {
    switch (defaultTargetPlatform) {
      case TargetPlatform.fuchsia:
      case TargetPlatform.android:
      case TargetPlatform.iOS:
        return buttonItems.map((ContextMenuButtonItem buttonItem) {
          return CupertinoTextSelectionToolbarButton.buttonItem(buttonItem: buttonItem);
        });
      case TargetPlatform.linux:
      case TargetPlatform.windows:
      case TargetPlatform.macOS:
        return buttonItems.map((ContextMenuButtonItem buttonItem) {
          return CupertinoDesktopTextSelectionToolbarButton.text(
            onPressed: buttonItem.onPressed,
            text: CupertinoTextSelectionToolbarButton.getButtonLabel(context, buttonItem),
          );
        });
    }
  }

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
              final Iterable<Widget> children = _getButtons(context, buttonItems);
              switch (defaultTargetPlatform) {
                case TargetPlatform.fuchsia:
                case TargetPlatform.android:
                case TargetPlatform.iOS:
                  return CupertinoTextSelectionToolbar(
                    anchorAbove: anchors.primaryAnchor,
                    anchorBelow: anchors.secondaryAnchor == null
                        ? anchors.primaryAnchor
                        : anchors.secondaryAnchor!,
                    children: children.toList(),
                  );
                case TargetPlatform.linux:
                case TargetPlatform.windows:
                case TargetPlatform.macOS:
                  return CupertinoDesktopTextSelectionToolbar(
                    anchor: anchors.primaryAnchor,
                    children: children.toList(),
                  );
              }
              ;
            },
      ),
      child: child,
    );
  }
}
