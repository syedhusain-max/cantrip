/// What a user is entitled to.
///
/// Deliberately not "credits" or "generations". This app's prompts ship in
/// the bundle and are copied to the clipboard — metering that would be a
/// lock on an open door, trivially bypassed and visibly dishonest. What
/// can be metered is what the server actually holds or the author actually
/// maintains: how much client workspace you keep in sync, whether you're
/// told when a saved prompt breaks, and how soon you see newly verified
/// prompts.
enum Tier { free, pro }

/// The limits for a tier, as data rather than scattered `if` statements, so
/// the paywall copy and the enforcement can never drift apart.
class Entitlement {
  final Tier tier;

  /// Null means unlimited.
  final int? folderLimit;
  final int? savedCopyLimit;

  /// Folder-level variable defaults — set a client's brand once and every
  /// prompt saved into that folder pre-fills from it. The clearest "this is
  /// for client work" feature in the app, which is why it sits here.
  final bool folderDefaults;

  /// Told when a prompt you saved is reported broken.
  final bool breakageAlerts;

  final bool exportFolders;

  /// How long a newly verified prompt stays Pro-only. Free users still get
  /// everything, just later — which keeps every already-shared link working
  /// and keeps the free library genuinely complete.
  final Duration newContentDelay;

  const Entitlement._({
    required this.tier,
    required this.folderLimit,
    required this.savedCopyLimit,
    required this.folderDefaults,
    required this.breakageAlerts,
    required this.exportFolders,
    required this.newContentDelay,
  });

  static const free = Entitlement._(
    tier: Tier.free,
    folderLimit: 1,
    savedCopyLimit: 10,
    folderDefaults: false,
    breakageAlerts: false,
    exportFolders: false,
    newContentDelay: Duration(days: 14),
  );

  static const pro = Entitlement._(
    tier: Tier.pro,
    folderLimit: null,
    savedCopyLimit: null,
    folderDefaults: true,
    breakageAlerts: true,
    exportFolders: true,
    newContentDelay: Duration.zero,
  );

  static Entitlement of(Tier tier) => tier == Tier.pro ? pro : free;

  bool get isPro => tier == Tier.pro;

  bool allowsAnotherFolder(int current) =>
      folderLimit == null || current < folderLimit!;

  bool allowsAnotherSavedCopy(int current) =>
      savedCopyLimit == null || current < savedCopyLimit!;
}

/// Why an action was refused, so the UI can explain the specific limit
/// rather than showing one generic paywall for everything.
enum LimitHit { folders, savedCopies, folderDefaults, export }
