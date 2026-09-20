import 'package:flutter/material.dart';

/// How much a prompt can currently be trusted.
///
/// Status is not stored as a fixed value — it decays with age and reacts to
/// user signals, so a one-person library stays honest without a one-person
/// QA team.
enum FreshnessStatus { verified, aging, needsReview, broken }

extension FreshnessStatusX on FreshnessStatus {
  String get label => switch (this) {
    FreshnessStatus.verified => 'Verified',
    FreshnessStatus.aging => 'Aging',
    FreshnessStatus.needsReview => 'Needs review',
    FreshnessStatus.broken => 'Reported broken',
  };

  IconData get icon => switch (this) {
    FreshnessStatus.verified => Icons.verified_outlined,
    FreshnessStatus.aging => Icons.schedule,
    FreshnessStatus.needsReview => Icons.history_toggle_off,
    FreshnessStatus.broken => Icons.error_outline,
  };

  /// Whether this status should be excluded from default search ranking.
  bool get demoteInSearch =>
      this == FreshnessStatus.broken || this == FreshnessStatus.needsReview;
}

/// One recorded change to a prompt after a tool update.
class FreshnessRevision {
  final int version;
  final DateTime changedOn;
  final String reason;

  const FreshnessRevision({
    required this.version,
    required this.changedOn,
    required this.reason,
  });
}

/// Community "still works / broken" tallies.
class FreshnessSignals {
  final int works;
  final int broken;
  final DateTime? lastBrokenReport;

  const FreshnessSignals({
    this.works = 0,
    this.broken = 0,
    this.lastBrokenReport,
  });

  int get total => works + broken;

  double get brokenRatio => total == 0 ? 0 : broken / total;

  FreshnessSignals copyWith({
    int? works,
    int? broken,
    DateTime? lastBrokenReport,
  }) => FreshnessSignals(
    works: works ?? this.works,
    broken: broken ?? this.broken,
    lastBrokenReport: lastBrokenReport ?? this.lastBrokenReport,
  );
}

/// Verification metadata for a variant.
///
/// The model label is per-tool on purpose: some tools expose a version
/// ("Midjourney v7"), some expose a named feature ("Soul 2.0"), some expose
/// nothing at all. A single global version number can't describe that.
class Freshness {
  final DateTime verifiedOn;
  final String verifiedBy;

  /// The tool's own label at the time of verification. Empty means the tool
  /// exposes no version surface.
  final String verifiedAgainstModelLabel;

  final FreshnessSignals signals;
  final List<FreshnessRevision> history;

  /// Decay thresholds, in days.
  final int agingAfterDays;
  final int needsReviewAfterDays;

  /// Share of broken signals that flips a prompt to broken outright.
  final double brokenRatioThreshold;

  /// Minimum signals before the ratio rule is allowed to fire, so three
  /// early reports can't bury a good prompt.
  final int brokenMinSignals;

  const Freshness({
    required this.verifiedOn,
    this.verifiedBy = 'library',
    this.verifiedAgainstModelLabel = '',
    this.signals = const FreshnessSignals(),
    this.history = const [],
    this.agingAfterDays = 60,
    this.needsReviewAfterDays = 90,
    this.brokenRatioThreshold = 0.2,
    this.brokenMinSignals = 5,
  });

  int daysSinceVerified(DateTime now) => now.difference(verifiedOn).inDays;

  /// Status computed from age and signals. Signals win over age: a prompt
  /// verified yesterday that users report broken today is broken.
  FreshnessStatus statusAt(DateTime now) {
    if (signals.total >= brokenMinSignals &&
        signals.brokenRatio > brokenRatioThreshold) {
      return FreshnessStatus.broken;
    }
    final days = daysSinceVerified(now);
    if (days >= needsReviewAfterDays) return FreshnessStatus.needsReview;
    if (days >= agingAfterDays) return FreshnessStatus.aging;
    return FreshnessStatus.verified;
  }

  Freshness copyWith({FreshnessSignals? signals}) => Freshness(
    verifiedOn: verifiedOn,
    verifiedBy: verifiedBy,
    verifiedAgainstModelLabel: verifiedAgainstModelLabel,
    signals: signals ?? this.signals,
    history: history,
    agingAfterDays: agingAfterDays,
    needsReviewAfterDays: needsReviewAfterDays,
    brokenRatioThreshold: brokenRatioThreshold,
    brokenMinSignals: brokenMinSignals,
  );
}
