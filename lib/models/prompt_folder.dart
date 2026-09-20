import 'fork.dart';

enum FolderType { personal, client }

extension FolderTypeX on FolderType {
  String get label => switch (this) {
    FolderType.personal => 'Personal',
    FolderType.client => 'Client / project',
  };
}

/// A user-created folder holding saved copies of prompts.
///
/// [variableDefaults] is the "instant for a new client" mechanic from the
/// build plan: set brand colour and logo once on the folder and every
/// prompt saved into it pre-fills from them. Keyed by the goal's input
/// contract, so a default applies across tools.
class PromptFolder {
  final String id;
  String name;
  FolderType type;
  final List<Fork> items;
  final Map<String, String> variableDefaults;

  PromptFolder({
    required this.id,
    required this.name,
    required this.type,
    List<Fork>? items,
    Map<String, String>? variableDefaults,
  }) : items = items ?? [],
       variableDefaults = variableDefaults ?? {};

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type.name,
    'items': [for (final f in items) f.toJson()],
    'variableDefaults': variableDefaults,
  };

  static PromptFolder? fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['name'];
    if (id is! String || name is! String) return null;
    return PromptFolder(
      id: id,
      name: name,
      type: FolderType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => FolderType.personal,
      ),
      items: [
        for (final raw in (json['items'] as List? ?? []))
          if (raw is Map<String, dynamic>) ?Fork.fromJson(raw),
      ],
      variableDefaults: {
        for (final e in (json['variableDefaults'] as Map? ?? {}).entries)
          '${e.key}': '${e.value}',
      },
    );
  }
}
