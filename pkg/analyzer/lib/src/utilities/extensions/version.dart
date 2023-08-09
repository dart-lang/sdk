// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:pub_semver/pub_semver.dart';

extension VersionConstraintExtension on VersionConstraint {
  /// The same constraint, but only with major, minor, patch fields.
  ///
  /// Excludes pre-release and build fields, useful when developing against
  /// not yet release version of Dart SDK.
  VersionConstraint get withoutPreRelease {
    switch (this) {
      case Version version:
        return version.withoutPreRelease;
      case VersionRange range:
        return VersionRange(
          min: range.min?.withoutPreRelease,
          includeMin: range.includeMin,
          max: range.max?.withoutPreRelease,
          includeMax: range.includeMax,
        );
      default:
        return this;
    }
  }

  bool requiresAtLeast(Version version) {
    final self = this;
    if (self is Version) {
      return self >= version;
    }
    if (self is VersionRange) {
      final min = self.min;
      if (min == null) {
        return false;
      } else {
        return min >= version;
      }
    }
    // We don't know, but will not complain.
    return true;
  }
}

extension VersionExtension on Version {
  /// The same version, but only with major, minor, patch fields.
  ///
  /// Excludes pre-release and build fields, useful when developing against
  /// not yet release version of Dart SDK.
  Version get withoutPreRelease {
    return Version(major, minor, patch);
  }
}
