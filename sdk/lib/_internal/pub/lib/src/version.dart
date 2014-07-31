// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Handles version numbers, following the [Semantic Versioning][semver] spec.
///
/// [semver]: http://semver.org/
library pub.version;

import 'dart:math';

import 'package:collection/equality.dart';

/// Regex that matches a version number at the beginning of a string.
final _START_VERSION = new RegExp(
    r'^'                                        // Start at beginning.
    r'(\d+).(\d+).(\d+)'                        // Version number.
    r'(-([0-9A-Za-z-]+(\.[0-9A-Za-z-]+)*))?'    // Pre-release.
    r'(\+([0-9A-Za-z-]+(\.[0-9A-Za-z-]+)*))?'); // Build.

/// Like [_START_VERSION] but matches the entire string.
final _COMPLETE_VERSION = new RegExp("${_START_VERSION.pattern}\$");

/// Parses a comparison operator ("<", ">", "<=", or ">=") at the beginning of
/// a string.
final _START_COMPARISON = new RegExp(r"^[<>]=?");

/// The equality operator to use for comparing version components.
final _equality = const IterableEquality();

/// A parsed semantic version number.
class Version implements Comparable<Version>, VersionConstraint {
  /// No released version: i.e. "0.0.0".
  static Version get none => new Version(0, 0, 0);

  /// Compares [a] and [b] to see which takes priority over the other.
  ///
  /// Returns `1` if [a] takes priority over [b] and `-1` if vice versa. If
  /// [a] and [b] are equivalent, returns `0`.
  ///
  /// Unlike [compareTo], which *orders* versions, this determines which
  /// version a user is likely to prefer. In particular, it prioritizes
  /// pre-release versions lower than stable versions, regardless of their
  /// version numbers.
  ///
  /// When used to sort a list, orders in ascending priority so that the
  /// highest priority version is *last* in the result.
  static int prioritize(Version a, Version b) {
    // Sort all prerelease versions after all normal versions. This way
    // the solver will prefer stable packages over unstable ones.
    if (a.isPreRelease && !b.isPreRelease) return -1;
    if (!a.isPreRelease && b.isPreRelease) return 1;

    return a.compareTo(b);
  }

  /// Like [proiritize], but lower version numbers are considered greater than
  /// higher version numbers.
  ///
  /// This still considers prerelease versions to be lower than non-prerelease
  /// versions.
  static int antiPrioritize(Version a, Version b) {
    if (a.isPreRelease && !b.isPreRelease) return -1;
    if (!a.isPreRelease && b.isPreRelease) return 1;

    return b.compareTo(a);
  }

  /// The major version number: "1" in "1.2.3".
  final int major;

  /// The minor version number: "2" in "1.2.3".
  final int minor;

  /// The patch version number: "3" in "1.2.3".
  final int patch;

  /// The pre-release identifier: "foo" in "1.2.3-foo".
  ///
  /// This is split into a list of components, each of which may be either a
  /// string or a non-negative integer. It may also be empty, indicating that
  /// this version has no pre-release identifier.
  final List preRelease;

  /// The build identifier: "foo" in "1.2.3+foo".
  ///
  /// This is split into a list of components, each of which may be either a
  /// string or a non-negative integer. It may also be empty, indicating that
  /// this version has no build identifier.
  final List build;

  /// The original string representation of the version number.
  ///
  /// This preserves textual artifacts like leading zeros that may be left out
  /// of the parsed version.
  final String _text;

  Version._(this.major, this.minor, this.patch, String preRelease, String build,
            this._text)
      : preRelease = preRelease == null ? [] : _splitParts(preRelease),
        build = build == null ? [] : _splitParts(build) {
    if (major < 0) throw new ArgumentError(
        'Major version must be non-negative.');
    if (minor < 0) throw new ArgumentError(
        'Minor version must be non-negative.');
    if (patch < 0) throw new ArgumentError(
        'Patch version must be non-negative.');
  }

  /// Creates a new [Version] object.
  factory Version(int major, int minor, int patch, {String pre, String build}) {
    var text = "$major.$minor.$patch";
    if (pre != null) text += "-$pre";
    if (build != null) text += "+$build";

    return new Version._(major, minor, patch, pre, build, text);
  }

  /// Creates a new [Version] by parsing [text].
  factory Version.parse(String text) {
    final match = _COMPLETE_VERSION.firstMatch(text);
    if (match == null) {
      throw new FormatException('Could not parse "$text".');
    }

    try {
      int major = int.parse(match[1]);
      int minor = int.parse(match[2]);
      int patch = int.parse(match[3]);

      String preRelease = match[5];
      String build = match[8];

      return new Version._(major, minor, patch, preRelease, build, text);
    } on FormatException catch (ex) {
      throw new FormatException('Could not parse "$text".');
    }
  }

  /// Returns the primary version out of a list of candidates.
  ///
  /// This is the highest-numbered stable (non-prerelease) version. If there
  /// are no stable versions, it's just the highest-numbered version.
  static Version primary(List<Version> versions) {
    var primary;
    for (var version in versions) {
      if (primary == null || (!version.isPreRelease && primary.isPreRelease) ||
          (version.isPreRelease == primary.isPreRelease && version > primary)) {
        primary = version;
      }
    }
    return primary;
  }

  /// Splits a string of dot-delimited identifiers into their component parts.
  ///
  /// Identifiers that are numeric are converted to numbers.
  static List _splitParts(String text) {
    return text.split('.').map((part) {
      try {
        return int.parse(part);
      } on FormatException catch (ex) {
        // Not a number.
        return part;
      }
    }).toList();
  }

  bool operator ==(other) {
    if (other is! Version) return false;
    return major == other.major && minor == other.minor &&
        patch == other.patch &&
        _equality.equals(preRelease, other.preRelease) &&
        _equality.equals(build, other.build);
  }

  int get hashCode => major ^ minor ^ patch ^ _equality.hash(preRelease) ^
      _equality.hash(build);

  bool operator <(Version other) => compareTo(other) < 0;
  bool operator >(Version other) => compareTo(other) > 0;
  bool operator <=(Version other) => compareTo(other) <= 0;
  bool operator >=(Version other) => compareTo(other) >= 0;

  bool get isAny => false;
  bool get isEmpty => false;

  /// Whether or not this is a pre-release version.
  bool get isPreRelease => preRelease.isNotEmpty;

  /// Gets the next major version number that follows this one.
  ///
  /// If this version is a pre-release of a major version release (i.e. the
  /// minor and patch versions are zero), then it just strips the pre-release
  /// suffix. Otherwise, it increments the major version and resets the minor
  /// and patch.
  Version get nextMajor {
    if (isPreRelease && minor == 0 && patch == 0) {
      return new Version(major, minor, patch);
    }

    return new Version(major + 1, 0, 0);
  }

  /// Gets the next minor version number that follows this one.
  ///
  /// If this version is a pre-release of a minor version release (i.e. the
  /// patch version is zero), then it just strips the pre-release suffix.
  /// Otherwise, it increments the minor version and resets the patch.
  Version get nextMinor {
    if (isPreRelease && patch == 0) {
      return new Version(major, minor, patch);
    }

    return new Version(major, minor + 1, 0);
  }

  /// Gets the next patch version number that follows this one.
  ///
  /// If this version is a pre-release, then it just strips the pre-release
  /// suffix. Otherwise, it increments the patch version.
  Version get nextPatch {
    if (isPreRelease) {
      return new Version(major, minor, patch);
    }

    return new Version(major, minor, patch + 1);
  }

  /// Tests if [other] matches this version exactly.
  bool allows(Version other) => this == other;

  VersionConstraint intersect(VersionConstraint other) {
    if (other.isEmpty) return other;

    // Intersect a version and a range.
    if (other is VersionRange) return other.intersect(this);

    // Intersecting two versions only works if they are the same.
    if (other is Version) {
      return this == other ? this : VersionConstraint.empty;
    }

    throw new ArgumentError(
        'Unknown VersionConstraint type $other.');
  }

  int compareTo(Version other) {
    if (major != other.major) return major.compareTo(other.major);
    if (minor != other.minor) return minor.compareTo(other.minor);
    if (patch != other.patch) return patch.compareTo(other.patch);

    // Pre-releases always come before no pre-release string.
    if (!isPreRelease && other.isPreRelease) return 1;
    if (!other.isPreRelease && isPreRelease) return -1;

    var comparison = _compareLists(preRelease, other.preRelease);
    if (comparison != 0) return comparison;

    // Builds always come after no build string.
    if (build.isEmpty && other.build.isNotEmpty) return -1;
    if (other.build.isEmpty && build.isNotEmpty) return 1;
    return _compareLists(build, other.build);
  }

  String toString() => _text;

  /// Compares a dot-separated component of two versions.
  ///
  /// This is used for the pre-release and build version parts. This follows
  /// Rule 12 of the Semantic Versioning spec (v2.0.0-rc.1).
  int _compareLists(List a, List b) {
    for (var i = 0; i < max(a.length, b.length); i++) {
      var aPart = (i < a.length) ? a[i] : null;
      var bPart = (i < b.length) ? b[i] : null;

      if (aPart == bPart) continue;

      // Missing parts come before present ones.
      if (aPart == null) return -1;
      if (bPart == null) return 1;

      if (aPart is num) {
        if (bPart is num) {
          // Compare two numbers.
          return aPart.compareTo(bPart);
        } else {
          // Numbers come before strings.
          return -1;
        }
      } else {
        if (bPart is num) {
          // Strings come after numbers.
          return 1;
        } else {
          // Compare two strings.
          return aPart.compareTo(bPart);
        }
      }
    }

    // The lists are entirely equal.
    return 0;
  }
}

/// A [VersionConstraint] is a predicate that can determine whether a given
/// version is valid or not.
///
/// For example, a ">= 2.0.0" constraint allows any version that is "2.0.0" or
/// greater. Version objects themselves implement this to match a specific
/// version.
abstract class VersionConstraint {
  /// A [VersionConstraint] that allows all versions.
  static VersionConstraint any = new VersionRange();

  /// A [VersionConstraint] that allows no versions: i.e. the empty set.
  static VersionConstraint empty = const _EmptyVersion();

  /// Parses a version constraint.
  ///
  /// This string is either "any" or a series of version parts. Each part can
  /// be one of:
  ///
  ///   * A version string like `1.2.3`. In other words, anything that can be
  ///     parsed by [Version.parse()].
  ///   * A comparison operator (`<`, `>`, `<=`, or `>=`) followed by a version
  ///     string.
  ///
  /// Whitespace is ignored.
  ///
  /// Examples:
  ///
  ///     any
  ///     1.2.3-alpha
  ///     <=5.1.4
  ///     >2.0.4 <= 2.4.6
  factory VersionConstraint.parse(String text) {
    // Handle the "any" constraint.
    if (text.trim() == "any") return new VersionRange();

    var originalText = text;
    var constraints = <VersionConstraint>[];

    void skipWhitespace() {
      text = text.trim();
    }

    // Try to parse and consume a version number.
    Version matchVersion() {
      var version = _START_VERSION.firstMatch(text);
      if (version == null) return null;

      text = text.substring(version.end);
      return new Version.parse(version[0]);
    }

    // Try to parse and consume a comparison operator followed by a version.
    VersionConstraint matchComparison() {
      var comparison = _START_COMPARISON.firstMatch(text);
      if (comparison == null) return null;

      var op = comparison[0];
      text = text.substring(comparison.end);
      skipWhitespace();

      var version = matchVersion();
      if (version == null) {
        throw new FormatException('Expected version number after "$op" in '
            '"$originalText", got "$text".');
      }

      switch (op) {
        case '<=':
          return new VersionRange(max: version, includeMax: true);
        case '<':
          return new VersionRange(max: version, includeMax: false);
        case '>=':
          return new VersionRange(min: version, includeMin: true);
        case '>':
          return new VersionRange(min: version, includeMin: false);
      }
      throw "Unreachable.";
    }

    while (true) {
      skipWhitespace();
      if (text.isEmpty) break;

      var version = matchVersion();
      if (version != null) {
        constraints.add(version);
        continue;
      }

      var comparison = matchComparison();
      if (comparison != null) {
        constraints.add(comparison);
        continue;
      }

      // If we got here, we couldn't parse the remaining string.
      throw new FormatException('Could not parse version "$originalText". '
          'Unknown text at "$text".');
    }

    if (constraints.isEmpty) {
      throw new FormatException('Cannot parse an empty string.');
    }

    return new VersionConstraint.intersection(constraints);
  }

  /// Creates a new version constraint that is the intersection of
  /// [constraints].
  ///
  /// It only allows versions that all of those constraints allow. If
  /// constraints is empty, then it returns a VersionConstraint that allows
  /// all versions.
  factory VersionConstraint.intersection(
      Iterable<VersionConstraint> constraints) {
    var constraint = new VersionRange();
    for (var other in constraints) {
      constraint = constraint.intersect(other);
    }
    return constraint;
  }

  /// Returns `true` if this constraint allows no versions.
  bool get isEmpty;

  /// Returns `true` if this constraint allows all versions.
  bool get isAny;

  /// Returns `true` if this constraint allows [version].
  bool allows(Version version);

  /// Creates a new [VersionConstraint] that only allows [Version]s allowed by
  /// both this and [other].
  VersionConstraint intersect(VersionConstraint other);
}

/// Constrains versions to a fall within a given range.
///
/// If there is a minimum, then this only allows versions that are at that
/// minimum or greater. If there is a maximum, then only versions less than
/// that are allowed. In other words, this allows `>= min, < max`.
class VersionRange implements VersionConstraint {
  final Version min;
  final Version max;
  final bool includeMin;
  final bool includeMax;

  VersionRange({this.min, this.max,
      this.includeMin: false, this.includeMax: false}) {
    if (min != null && max != null && min > max) {
      throw new ArgumentError(
          'Minimum version ("$min") must be less than maximum ("$max").');
    }
  }

  bool operator ==(other) {
    if (other is! VersionRange) return false;

    return min == other.min &&
           max == other.max &&
           includeMin == other.includeMin &&
           includeMax == other.includeMax;
  }

  bool get isEmpty => false;

  bool get isAny => min == null && max == null;

  /// Tests if [other] matches falls within this version range.
  bool allows(Version other) {
    if (min != null) {
      if (other < min) return false;
      if (!includeMin && other == min) return false;
    }

    if (max != null) {
      if (other > max) return false;
      if (!includeMax && other == max) return false;

      // If the max isn't itself a pre-release, don't allow any pre-release
      // versions of the max.
      //
      // See: https://www.npmjs.org/doc/misc/semver.html
      if (!includeMax &&
          !max.isPreRelease && other.isPreRelease &&
          other.major == max.major && other.minor == max.minor &&
          other.patch == max.patch) {
        return false;
      }
    }

    return true;
  }

  VersionConstraint intersect(VersionConstraint other) {
    if (other.isEmpty) return other;

    // A range and a Version just yields the version if it's in the range.
    if (other is Version) {
      return allows(other) ? other : VersionConstraint.empty;
    }

    if (other is VersionRange) {
      // Intersect the two ranges.
      var intersectMin = min;
      var intersectIncludeMin = includeMin;
      var intersectMax = max;
      var intersectIncludeMax = includeMax;

      if (other.min == null) {
        // Do nothing.
      } else if (intersectMin == null || intersectMin < other.min) {
        intersectMin = other.min;
        intersectIncludeMin = other.includeMin;
      } else if (intersectMin == other.min && !other.includeMin) {
        // The edges are the same, but one is exclusive, make it exclusive.
        intersectIncludeMin = false;
      }

      if (other.max == null) {
        // Do nothing.
      } else if (intersectMax == null || intersectMax > other.max) {
        intersectMax = other.max;
        intersectIncludeMax = other.includeMax;
      } else if (intersectMax == other.max && !other.includeMax) {
        // The edges are the same, but one is exclusive, make it exclusive.
        intersectIncludeMax = false;
      }

      if (intersectMin == null && intersectMax == null) {
        // Open range.
        return new VersionRange();
      }

      // If the range is just a single version.
      if (intersectMin == intersectMax) {
        // If both ends are inclusive, allow that version.
        if (intersectIncludeMin && intersectIncludeMax) return intersectMin;

        // Otherwise, no versions.
        return VersionConstraint.empty;
      }

      if (intersectMin != null && intersectMax != null &&
          intersectMin > intersectMax) {
        // Non-overlapping ranges, so empty.
        return VersionConstraint.empty;
      }

      // If we got here, there is an actual range.
      return new VersionRange(min: intersectMin, max: intersectMax,
          includeMin: intersectIncludeMin, includeMax: intersectIncludeMax);
    }

    throw new ArgumentError(
        'Unknown VersionConstraint type $other.');
  }

  String toString() {
    var buffer = new StringBuffer();

    if (min != null) {
      buffer.write(includeMin ? '>=' : '>');
      buffer.write(min);
    }

    if (max != null) {
      if (min != null) buffer.write(' ');
      buffer.write(includeMax ? '<=' : '<');
      buffer.write(max);
    }

    if (min == null && max == null) buffer.write('any');
    return buffer.toString();
  }
}

class _EmptyVersion implements VersionConstraint {
  const _EmptyVersion();

  bool get isEmpty => true;
  bool get isAny => false;
  bool allows(Version other) => false;
  VersionConstraint intersect(VersionConstraint other) => this;
  String toString() => '<empty>';
}
