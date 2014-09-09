library pub.version;
import 'dart:math';
import 'package:collection/equality.dart';
final _START_VERSION = new RegExp(
    r'^' r'(\d+).(\d+).(\d+)' r'(-([0-9A-Za-z-]+(\.[0-9A-Za-z-]+)*))?'
        r'(\+([0-9A-Za-z-]+(\.[0-9A-Za-z-]+)*))?');
final _COMPLETE_VERSION = new RegExp("${_START_VERSION.pattern}\$");
final _START_COMPARISON = new RegExp(r"^[<>]=?");
final _equality = const IterableEquality();
class Version implements Comparable<Version>, VersionConstraint {
  static Version get none => new Version(0, 0, 0);
  static int prioritize(Version a, Version b) {
    if (a.isPreRelease && !b.isPreRelease) return -1;
    if (!a.isPreRelease && b.isPreRelease) return 1;
    return a.compareTo(b);
  }
  static int antiPrioritize(Version a, Version b) {
    if (a.isPreRelease && !b.isPreRelease) return -1;
    if (!a.isPreRelease && b.isPreRelease) return 1;
    return b.compareTo(a);
  }
  final int major;
  final int minor;
  final int patch;
  final List preRelease;
  final List build;
  final String _text;
  Version._(this.major, this.minor, this.patch, String preRelease, String build,
      this._text)
      : preRelease = preRelease == null ? [] : _splitParts(preRelease),
        build = build == null ? [] : _splitParts(build) {
    if (major <
        0) throw new ArgumentError('Major version must be non-negative.');
    if (minor <
        0) throw new ArgumentError('Minor version must be non-negative.');
    if (patch <
        0) throw new ArgumentError('Patch version must be non-negative.');
  }
  factory Version(int major, int minor, int patch, {String pre, String build}) {
    var text = "$major.$minor.$patch";
    if (pre != null) text += "-$pre";
    if (build != null) text += "+$build";
    return new Version._(major, minor, patch, pre, build, text);
  }
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
  static Version primary(List<Version> versions) {
    var primary;
    for (var version in versions) {
      if (primary == null ||
          (!version.isPreRelease && primary.isPreRelease) ||
          (version.isPreRelease == primary.isPreRelease && version > primary)) {
        primary = version;
      }
    }
    return primary;
  }
  static List _splitParts(String text) {
    return text.split('.').map((part) {
      try {
        return int.parse(part);
      } on FormatException catch (ex) {
        return part;
      }
    }).toList();
  }
  bool operator ==(other) {
    if (other is! Version) return false;
    return major == other.major &&
        minor == other.minor &&
        patch == other.patch &&
        _equality.equals(preRelease, other.preRelease) &&
        _equality.equals(build, other.build);
  }
  int get hashCode =>
      major ^ minor ^ patch ^ _equality.hash(preRelease) ^ _equality.hash(build);
  bool operator <(Version other) => compareTo(other) < 0;
  bool operator >(Version other) => compareTo(other) > 0;
  bool operator <=(Version other) => compareTo(other) <= 0;
  bool operator >=(Version other) => compareTo(other) >= 0;
  bool get isAny => false;
  bool get isEmpty => false;
  bool get isPreRelease => preRelease.isNotEmpty;
  Version get nextMajor {
    if (isPreRelease && minor == 0 && patch == 0) {
      return new Version(major, minor, patch);
    }
    return new Version(major + 1, 0, 0);
  }
  Version get nextMinor {
    if (isPreRelease && patch == 0) {
      return new Version(major, minor, patch);
    }
    return new Version(major, minor + 1, 0);
  }
  Version get nextPatch {
    if (isPreRelease) {
      return new Version(major, minor, patch);
    }
    return new Version(major, minor, patch + 1);
  }
  bool allows(Version other) => this == other;
  VersionConstraint intersect(VersionConstraint other) {
    if (other.isEmpty) return other;
    if (other is VersionRange) return other.intersect(this);
    if (other is Version) {
      return this == other ? this : VersionConstraint.empty;
    }
    throw new ArgumentError('Unknown VersionConstraint type $other.');
  }
  int compareTo(Version other) {
    if (major != other.major) return major.compareTo(other.major);
    if (minor != other.minor) return minor.compareTo(other.minor);
    if (patch != other.patch) return patch.compareTo(other.patch);
    if (!isPreRelease && other.isPreRelease) return 1;
    if (!other.isPreRelease && isPreRelease) return -1;
    var comparison = _compareLists(preRelease, other.preRelease);
    if (comparison != 0) return comparison;
    if (build.isEmpty && other.build.isNotEmpty) return -1;
    if (other.build.isEmpty && build.isNotEmpty) return 1;
    return _compareLists(build, other.build);
  }
  String toString() => _text;
  int _compareLists(List a, List b) {
    for (var i = 0; i < max(a.length, b.length); i++) {
      var aPart = (i < a.length) ? a[i] : null;
      var bPart = (i < b.length) ? b[i] : null;
      if (aPart == bPart) continue;
      if (aPart == null) return -1;
      if (bPart == null) return 1;
      if (aPart is num) {
        if (bPart is num) {
          return aPart.compareTo(bPart);
        } else {
          return -1;
        }
      } else {
        if (bPart is num) {
          return 1;
        } else {
          return aPart.compareTo(bPart);
        }
      }
    }
    return 0;
  }
}
abstract class VersionConstraint {
  static VersionConstraint any = new VersionRange();
  static VersionConstraint empty = const _EmptyVersion();
  factory VersionConstraint.parse(String text) {
    if (text.trim() == "any") return new VersionRange();
    var originalText = text;
    var constraints = <VersionConstraint>[];
    void skipWhitespace() {
      text = text.trim();
    }
    Version matchVersion() {
      var version = _START_VERSION.firstMatch(text);
      if (version == null) return null;
      text = text.substring(version.end);
      return new Version.parse(version[0]);
    }
    VersionConstraint matchComparison() {
      var comparison = _START_COMPARISON.firstMatch(text);
      if (comparison == null) return null;
      var op = comparison[0];
      text = text.substring(comparison.end);
      skipWhitespace();
      var version = matchVersion();
      if (version == null) {
        throw new FormatException(
            'Expected version number after "$op" in ' '"$originalText", got "$text".');
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
      throw new FormatException(
          'Could not parse version "$originalText". ' 'Unknown text at "$text".');
    }
    if (constraints.isEmpty) {
      throw new FormatException('Cannot parse an empty string.');
    }
    return new VersionConstraint.intersection(constraints);
  }
  factory
      VersionConstraint.intersection(Iterable<VersionConstraint> constraints) {
    var constraint = new VersionRange();
    for (var other in constraints) {
      constraint = constraint.intersect(other);
    }
    return constraint;
  }
  bool get isEmpty;
  bool get isAny;
  bool allows(Version version);
  VersionConstraint intersect(VersionConstraint other);
}
class VersionRange implements VersionConstraint {
  final Version min;
  final Version max;
  final bool includeMin;
  final bool includeMax;
  VersionRange({this.min, this.max, this.includeMin: false, this.includeMax:
      false}) {
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
  bool allows(Version other) {
    if (min != null) {
      if (other < min) return false;
      if (!includeMin && other == min) return false;
    }
    if (max != null) {
      if (other > max) return false;
      if (!includeMax && other == max) return false;
      if (!includeMax &&
          !max.isPreRelease &&
          other.isPreRelease &&
          other.major == max.major &&
          other.minor == max.minor &&
          other.patch == max.patch) {
        return false;
      }
    }
    return true;
  }
  VersionConstraint intersect(VersionConstraint other) {
    if (other.isEmpty) return other;
    if (other is Version) {
      return allows(other) ? other : VersionConstraint.empty;
    }
    if (other is VersionRange) {
      var intersectMin = min;
      var intersectIncludeMin = includeMin;
      var intersectMax = max;
      var intersectIncludeMax = includeMax;
      if (other.min ==
          null) {} else if (intersectMin == null || intersectMin < other.min) {
        intersectMin = other.min;
        intersectIncludeMin = other.includeMin;
      } else if (intersectMin == other.min && !other.includeMin) {
        intersectIncludeMin = false;
      }
      if (other.max ==
          null) {} else if (intersectMax == null || intersectMax > other.max) {
        intersectMax = other.max;
        intersectIncludeMax = other.includeMax;
      } else if (intersectMax == other.max && !other.includeMax) {
        intersectIncludeMax = false;
      }
      if (intersectMin == null && intersectMax == null) {
        return new VersionRange();
      }
      if (intersectMin == intersectMax) {
        if (intersectIncludeMin && intersectIncludeMax) return intersectMin;
        return VersionConstraint.empty;
      }
      if (intersectMin != null &&
          intersectMax != null &&
          intersectMin > intersectMax) {
        return VersionConstraint.empty;
      }
      return new VersionRange(
          min: intersectMin,
          max: intersectMax,
          includeMin: intersectIncludeMin,
          includeMax: intersectIncludeMax);
    }
    throw new ArgumentError('Unknown VersionConstraint type $other.');
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
