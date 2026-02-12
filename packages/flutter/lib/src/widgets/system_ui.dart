import 'framework.dart';
import 'inherited_model.dart';

// TODO(justinmc): This probably doesn't need to be an InheritedModel, could just be an InheritedWidget.
/// Provides [SystemUIData] to its descendants.
class SystemUI extends InheritedModel<_SystemUIAspect> {
  /// Creates a widget that provides [SystemUIData] to its descendants.
  const SystemUI({super.key, required super.child, required this.data});

  /// The data that is provided to the descendants of this widget.
  final SystemUIData data;

  /// Returns the [SystemUIData.contextMenuBuilder] from the nearest [SystemUI]
  /// ancestor.
  ///
  /// If no [SystemUI] ancestor is found, returns null.
  ///
  /// The `context` argument is used to look up the [SystemUI] ancestor.
  static WidgetBuilder? maybeContextMenuBuilderOf(BuildContext context) {
    return InheritedModel.inheritFrom<SystemUI>(
      context,
      aspect: _SystemUIAspect.contextMenuBuilder,
    )?.data.contextMenuBuilder;
  }

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

/// Describes the system UI that should be applied to the descendants of a
/// [SystemUI] widget.
class SystemUIData {
  /// Creates a new [SystemUIData].
  const SystemUIData({required this.contextMenuBuilder});

  /// The builder for the context menu.
  final WidgetBuilder contextMenuBuilder;
}

/// The aspects of [SystemUIData] that can be individually listened to.
enum _SystemUIAspect {
  /// Specifies the aspect according to [SystemUIData.contextMenuBuilder];
  contextMenuBuilder,
}
