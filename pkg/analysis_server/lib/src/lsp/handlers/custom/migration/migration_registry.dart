// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:linter/src/lint_names.dart';
import 'package:pub_semver/pub_semver.dart';

/// A registry mapping target SDK versions to clean up lint rules that should be
/// applied and fixes *after* the SDK constraint is bumped.
///
/// Each registered lint rule must have exactly one bulk-fix enabled
/// correction producer associated with it.
final Map<Version, List<String>> cleanUpLintsRegistry = {
  Version(3, 13, 0): [LintNames.unnecessary_type_name_in_constructor],
  Version(3, 12, 0): [LintNames.prefer_initializing_formals],
};

/// An ordered list of all supported SDK versions for migration.
final List<Version> knownSdkVersions = [
  // Dart 3.x releases
  Version(3, 0, 0),
  Version(3, 1, 0),
  Version(3, 2, 0),
  Version(3, 3, 0),
  Version(3, 4, 0),
  Version(3, 5, 0),
  Version(3, 6, 0),
  Version(3, 7, 0),
  Version(3, 8, 0),
  Version(3, 9, 0),
  Version(3, 10, 0),
  Version(3, 11, 0),
  Version(3, 12, 0),
  Version(3, 13, 0),
  Version(3, 14, 0),
];

/// A registry mapping target SDK versions to preparatory lint rules that should
/// be applied and fixes *before* the SDK constraint is bumped.
///
/// Each registered lint rule must have exactly one bulk-fix enabled
/// correction producer associated with it.
final Map<Version, List<String>> preparatoryLintsRegistry = {
  Version(3, 13, 0): [
    LintNames.avoid_final_parameters,
    LintNames.var_with_no_type_annotation,
  ],
};

/// Returns the next sequential SDK version after [currentVersion] from
/// [knownSdkVersions], or `null` if [currentVersion] is at or beyond the latest
/// known version.
Version? nextSdkVersion(Version currentVersion) {
  var normalizedVersion = Version(
    currentVersion.major,
    currentVersion.minor,
    0,
  );
  var index = knownSdkVersions.indexOf(normalizedVersion);
  if (index >= 0 && index + 1 < knownSdkVersions.length) {
    return knownSdkVersions[index + 1];
  }
  return null;
}
