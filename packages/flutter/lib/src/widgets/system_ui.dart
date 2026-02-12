import 'framework.dart';
import 'inherited_model.dart';

class SystemUI extends InheritedModel<_SystemUIAspect> {
  /// Creates a widget that provides [SystemUIData] to its descendants.
  const SystemUI({super.key, required super.child, required this.data});

  final SystemUIData data;

  @override
  bool updateShouldNotify(SystemUI oldWidget) => data != oldWidget.data;

  @override
  bool updateShouldNotifyDependent(SystemUI oldWidget, Set<Object> dependencies) {
    return dependencies.any((Object dependency) {
      if (dependency is! _SystemUIAspect) {
        return false;
      }
      return switch (dependency) {
        _SystemUIAspect.contextMenuBuilder =>
          data.contextMenuBuilder != oldWidget.data.contextMenuBuilder,
      };
    });
  }
}

class SystemUIData {
  const SystemUIData({required this.contextMenuBuilder});

  final WidgetBuilder contextMenuBuilder;
}

enum _SystemUIAspect {
  /// Specifies the aspect according to [SystemUIData.contextMenuBuilder];
  contextMenuBuilder,
}
