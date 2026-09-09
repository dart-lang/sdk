// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Utilities for comparing Apple OS version strings.
library;

/// Compares two Apple OS version strings numerically.
///
/// Returns:
///  - negative if [a] < [b]
///  - zero     if [a] == [b]
///  - positive if [a] > [b]
///
/// Example:
/// ```dart
/// compareVersions('14.0', '13.4') > 0  // true — 14.0 is newer
/// compareVersions('12.0', '12.0') == 0 // true — equal
/// ```
int compareVersions(String a, String b) {
  final aParts = _parseVersion(a);
  final bParts = _parseVersion(b);

  final maxLen = aParts.length > bParts.length ? aParts.length : bParts.length;
  for (var i = 0; i < maxLen; i++) {
    final av = i < aParts.length ? aParts[i] : 0;
    final bv = i < bParts.length ? bParts[i] : 0;
    if (av != bv) return av - bv;
  }
  return 0;
}

/// Returns `true` if [apiMin] > [projectMin], meaning the API requires a
/// newer OS version than the project's minimum target.
///
/// When `true`, calling this API on a device running exactly [projectMin]
/// will crash.
bool apiRequiresNewerThan(String apiMin, String projectMin) =>
    compareVersions(apiMin, projectMin) > 0;

/// Returns `true` if [projectMin] >= [apiMax], meaning the project's minimum
/// target is at or above the version where the API was removed/obsoleted.
///
/// When `true`, the API may not exist at all on devices running [projectMin].
bool apiObsoletedBefore(String apiMax, String projectMin) =>
    compareVersions(projectMin, apiMax) >= 0;

/// Returns `true` if [apiDeprecatedAt] <= [projectMin] <= [apiObsoletedAt],
/// meaning the API is deprecated (but still present) on the project target.
///
/// Pass `null` for [apiObsoletedAt] if the API has not been removed yet.
bool apiDeprecatedOn(
  String apiDeprecatedAt,
  String? apiObsoletedAt,
  String projectMin,
) {
  final pastDeprecation = compareVersions(projectMin, apiDeprecatedAt) >= 0;
  final notYetObsoleted = apiObsoletedAt == null ||
      compareVersions(projectMin, apiObsoletedAt) < 0;
  return pastDeprecation && notYetObsoleted;
}

List<int> _parseVersion(String v) {
  return v
      .split('.')
      .map((part) => int.tryParse(part) ?? 0)
      .toList();
}
