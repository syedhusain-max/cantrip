import 'package:flutter/foundation.dart';

import '../models/entitlement.dart';

/// Where a user's tier comes from.
///
/// Behind an interface for the usual reason — the limits can be tested
/// without a server — and for one more: the source of truth will change.
/// Today it is a row in Supabase; once billing exists it will be Play
/// Billing and Stripe reconciling into that same row. Nothing above this
/// interface should have to notice.
abstract interface class EntitlementApi {
  /// Null when signed out. Entitlement is per account, never per device:
  /// a tier stored on the device is a tier the user can edit.
  Future<Tier?> currentTier();
}

/// Holds the current tier and answers "may they?" questions.
///
/// Signed out is [Tier.free] and that is not a degraded state — the whole
/// library is free. The limits here are about saved client workspace, not
/// about reading prompts.
class EntitlementController extends ChangeNotifier {
  final EntitlementApi? api;

  /// Lets a build be forced to Pro for screenshots, demos and manual
  /// testing: `--dart-define=FORCE_PRO=true`. Never true in a release
  /// build unless someone deliberately passes it.
  static const _forcePro = bool.fromEnvironment('FORCE_PRO');

  EntitlementController({this.api});

  Tier _tier = _forcePro ? Tier.pro : Tier.free;
  Tier get tier => _tier;

  Entitlement get limits => Entitlement.of(_tier);
  bool get isPro => limits.isPro;

  /// Re-read after sign-in, sign-out, or a completed purchase.
  Future<void> refresh() async {
    if (_forcePro) return;
    final next = await api?.currentTier() ?? Tier.free;
    if (next == _tier) return;
    _tier = next;
    notifyListeners();
  }

  /// A prompt verified in the last [Entitlement.newContentDelay] is Pro-only.
  /// Free users get it later rather than never, so nothing in the library is
  /// permanently walled and no shared link ever breaks.
  bool isWithinNewContentWindow(DateTime verifiedOn, {required DateTime now}) {
    final delay = limits.newContentDelay;
    if (delay == Duration.zero) return false;
    return now.difference(verifiedOn) < delay;
  }
}
