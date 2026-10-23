// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math' show max;

/// A dotted numeric version, such as `156.0.8078.12` or `323183`.
///
/// Versions are compared numerically component by component, with missing
/// trailing components treated as zero.
final class Version implements Comparable<Version> {
  /// The original textual form of this version.
  final String text;

  final List<int> _parts;

  Version._(this.text, this._parts);

  /// Parses [text], throwing a [FormatException] if it isn't a dotted
  /// sequence of non-negative integers.
  factory Version.parse(String text) {
    final parts = text.split('.').map(int.tryParse).toList();
    if (parts.any((part) => part == null || part < 0)) {
      throw FormatException('Invalid version', text);
    }
    return Version._(text, List.unmodifiable(parts.cast<int>()));
  }

  /// The first component of the version.
  int get major => _parts.first;

  @override
  int compareTo(Version other) {
    final length = max(_parts.length, other._parts.length);
    for (var i = 0; i < length; i++) {
      final difference = _partAt(i) - other._partAt(i);
      if (difference != 0) return difference.sign;
    }
    return 0;
  }

  bool operator >(Version other) => compareTo(other) > 0;

  int _partAt(int index) => index < _parts.length ? _parts[index] : 0;

  @override
  String toString() => text;
}

/// Returns the greatest of [versions], or `null` if it is empty.
Version? maxVersion(Iterable<Version> versions) {
  Version? result;
  for (final version in versions) {
    if (result == null || version > result) result = version;
  }
  return result;
}
