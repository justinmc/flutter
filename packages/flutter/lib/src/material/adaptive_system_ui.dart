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
        contextMenuBuilder: (BuildContext context) {
          // TODO(justinmc): Real context menu. Figure out what to do about needing EditableTextState.
          return const Text('I am context menuuuu');
          //return AdaptiveTextSelectionToolbar();
        },
      ),
      child: child,
    );
  }
}
