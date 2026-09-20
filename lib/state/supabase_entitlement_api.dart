import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/entitlement.dart';
import 'entitlement_controller.dart';

/// Reads the tier from the user's profile row.
///
/// The row is written by the server (a billing webhook), never by the app:
/// the client can read its own entitlement but must not be able to grant
/// itself one, which is why the RLS policy on `profiles` allows select and
/// nothing else.
class SupabaseEntitlementApi implements EntitlementApi {
  final SupabaseClient client;

  const SupabaseEntitlementApi(this.client);

  @override
  Future<Tier?> currentTier() async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      final row = await client
          .from('profiles')
          .select('pro_until')
          .eq('id', userId)
          .maybeSingle();

      final until = DateTime.tryParse('${row?['pro_until']}');
      if (until == null) return Tier.free;
      // Compared against the server's own timestamp semantics: pro_until is
      // stored in UTC, so a device with a wrong clock can buy at most a few
      // hours of Pro, not years of it.
      return until.isAfter(DateTime.now().toUtc()) ? Tier.pro : Tier.free;
    } catch (_) {
      // Unreachable server means free, not locked out: the whole library
      // works on the free tier anyway.
      return Tier.free;
    }
  }
}
