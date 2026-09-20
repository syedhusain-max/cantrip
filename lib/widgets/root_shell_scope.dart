import 'package:flutter/widgets.dart';

/// Lets any tab (e.g. Home's guided-flow card) ask the root shell to switch
/// to the Create tab, without the tabs depending on [RootShell] directly.
class RootShellScope extends InheritedWidget {
  final VoidCallback goToCreate;

  const RootShellScope({
    super.key,
    required this.goToCreate,
    required super.child,
  });

  static RootShellScope? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<RootShellScope>();

  @override
  bool updateShouldNotify(RootShellScope oldWidget) =>
      goToCreate != oldWidget.goToCreate;
}
