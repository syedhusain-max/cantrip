/// A saved copy of a library prompt inside a folder.
///
/// Stores a reference plus the user's own edits, not a deep copy of the
/// variant. Two reasons: the saved copy keeps working when the library
/// version is updated (and can show that it changed), and the whole thing
/// serialises to a few hundred bytes, so persisting it is trivial.
///
/// [values] is the real workflow win: a fork remembers what you typed, so
/// reopening a client's saved prompt next month comes back already filled
/// with that client's brand name and colours.
class Fork {
  final String id;
  final String sourceVariantId;

  /// User-renamed title, or null to show the library variant's title.
  String? title;

  /// Variable key → value, as last filled by the user.
  final Map<String, String> values;

  /// The source's verification date when this was saved, so the UI can say
  /// "the original has been updated since you saved this".
  final DateTime sourceVerifiedOn;

  final DateTime createdAt;

  Fork({
    required this.id,
    required this.sourceVariantId,
    this.title,
    Map<String, String>? values,
    required this.sourceVerifiedOn,
    required this.createdAt,
  }) : values = values ?? {};

  Map<String, dynamic> toJson() => {
    'id': id,
    'sourceVariantId': sourceVariantId,
    if (title != null) 'title': title,
    'values': values,
    'sourceVerifiedOn': sourceVerifiedOn.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
  };

  static Fork? fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final source = json['sourceVariantId'];
    if (id is! String || source is! String) return null;
    return Fork(
      id: id,
      sourceVariantId: source,
      title: json['title'] as String?,
      values: {
        for (final e in (json['values'] as Map? ?? {}).entries)
          '${e.key}': '${e.value}',
      },
      sourceVerifiedOn:
          DateTime.tryParse('${json['sourceVerifiedOn']}') ?? DateTime(2000),
      createdAt: DateTime.tryParse('${json['createdAt']}') ?? DateTime(2000),
    );
  }
}
