// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Handles version numbers, following the [Semantic Versioning][semver] spec.
 *
 * [semver]: http://semver.org/
 */
#library('pub_version');

/** A parsed semantic version number. */
class Version implements Comparable, VersionConstraint {
  static final _PARSE_REGEX = const RegExp(
      @'^'                                        // Start at beginning.
      @'(\d+).(\d+).(\d+)'                        // Version number.
      @'(-([0-9A-Za-z-]+(\.[0-9A-Za-z-]+)*))?'  // Pre-release.
      @'(\+([0-9A-Za-z-]+(\.[0-9A-Za-z-]+)*))?' // Build.
      @'$');                                      // Consume entire string.

  /** The major version number: "1" in "1.2.3". */
  final int major;

  /** The minor version number: "2" in "1.2.3". */
  final int minor;

  /** The patch version number: "3" in "1.2.3". */
  final int patch;

  /** The pre-release identifier: "foo" in "1.2.3-foo". May be `null`. */
  final String preRelease;

  /** The build identifier: "foo" in "1.2.3+foo". May be `null`. */
  final String build;

  /** Creates a new [Version] object. */
  Version(this.major, this.minor, this.patch, [String pre, this.build])
    : preRelease = pre {
    if (major < 0) throw new IllegalArgumentException(
        'Major version must be non-negative.');
    if (minor < 0) throw new IllegalArgumentException(
        'Minor version must be non-negative.');
    if (patch < 0) throw new IllegalArgumentException(
        'Patch version must be non-negative.');
  }

  /**
   * Creates a new [Version] by parsing [text].
   */
  factory Version.parse(String text) {
    final match = _PARSE_REGEX.firstMatch(text);
    if (match == null) {
      throw new FormatException('Could not parse "$text".');
    }

    try {
      int major = Math.parseInt(match[1]);
      int minor = Math.parseInt(match[2]);
      int patch = Math.parseInt(match[3]);

      String preRelease = match[5];
      String build = match[8];

      return new Version(major, minor, patch, preRelease, build);
    } catch (BadNumberFormatException ex) {
      throw new FormatException('Could not parse "$text".');
    }
  }

  bool operator ==(Version other) {
    if (other is! Version) return false;
    return compareTo(other) == 0;
  }

  bool operator <(Version other) => compareTo(other) < 0;
  bool operator >(Version other) => compareTo(other) > 0;
  bool operator <=(Version other) => compareTo(other) <= 0;
  bool operator >=(Version other) => compareTo(other) >= 0;

  /** Tests if [other] matches this version exactly. */
  bool allows(Version other) => this == other;

  int compareTo(Version other) {
    if (major != other.major) return major.compareTo(other.major);
    if (minor != other.minor) return minor.compareTo(other.minor);
    if (patch != other.patch) return patch.compareTo(other.patch);

    if (preRelease != other.preRelease) {
      // Pre-releases always come before no pre-release string.
      if (preRelease == null) return 1;
      if (other.preRelease == null) return -1;

      return _compareStrings(preRelease, other.preRelease);
    }

    if (build != other.build) {
      // Builds always come after no build string.
      if (build == null) return -1;
      if (other.build == null) return 1;

      return _compareStrings(build, other.build);
    }

    return 0;
  }

  String toString() {
    var buffer = new StringBuffer();
    buffer.add('$major.$minor.$patch');
    if (preRelease != null) buffer.add('-$preRelease');
    if (build != null) buffer.add('+$build');
    return buffer.toString();
  }

  /**
   * Compares the string part of two versions. This is used for the pre-release
   * and build version parts. This follows Rule 12. of the Semantic Versioning
   * spec.
   */
  int _compareStrings(String a, String b) {
    var aParts = _splitParts(a);
    var bParts = _splitParts(b);

    for (int i = 0; i < Math.max(aParts.length, bParts.length); i++) {
      var aPart = (i < aParts.length) ? aParts[i] : null;
      var bPart = (i < bParts.length) ? bParts[i] : null;

      if (aPart != bPart) {
        // Missing parts come before present ones.
        if (aPart == null) return -1;
        if (bPart == null) return 1;

        if (aPart is int) {
          if (bPart is int) {
            // Compare two numbers.
            return aPart.compareTo(bPart);
          } else {
            // Numbers come before strings.
            return -1;
          }
        } else {
          if (bPart is int) {
            // Strings come after numbers.
            return 1;
          } else {
            // Compare two strings.
            return aPart.compareTo(bPart);
          }
        }
      }
    }
  }

  /**
   * Splits a string of dot-delimited identifiers into their component parts.
   * Identifiers that are numeric are converted to numbers.
   */
  List _splitParts(String text) {
    return text.split('.').map((part) {
      try {
        return Math.parseInt(part);
      } catch (BadNumberFormatException ex) {
        // Not a number.
        return part;
      }
    });
  }
}

/**
 * A [VersionConstraint] is a predicate that can determine whether a given
 * version is valid or not. For example, a ">= 2.0.0" constraint allows any
 * version that is "2.0.0" or greater. Version objects themselves implement
 * this to match a specific version.
 */
interface VersionConstraint {
  bool allows(Version version);
}

/**
 * Constrains versions to a fall within a given range. If there is a minimum,
 * then this only allows versions that are at that minimum or greater. If there
 * is a maximum, then only versions less than that are allowed. In other words,
 * this allows `>= min, < max`.
 */
class VersionRange implements VersionConstraint {
  final Version min;
  final Version max;

  VersionRange([this.min, this.max]) {
    if (min != null && max != null && min > max) {
      throw new IllegalArgumentException(
          'Maximum version ("$max") must be less than minimum ("$min").');
    }
  }

  /** Tests if [other] matches falls within this version range. */
  bool allows(Version other) {
    if (min != null && other < min) return false;
    if (max != null && other >= max) return false;
    return true;
  }
}

/** Thrown by [Version.parse()] if the argument isn't a valid version string. */
class FormatException implements Exception {
  final String message;

  FormatException(this.message);

  String toString() => message;
}