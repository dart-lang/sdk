// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension StringExtension on String {
  static final _toSnakeCaseRegExp = RegExp('_?[A-Z]');
  static final _startsWithLowerCaseRegExp = RegExp('^[a-z]');
  static final _startsWithUpperCaseRegExp = RegExp('^[A-Z]');

  /// Returns `true` if the string is a `camelCase` string.
  bool get isCamelCase {
    if (contains('_')) return false;
    if (_startsWithLowerCaseRegExp.matchAsPrefix(this) == null) return false;
    return true;
  }

  /// Returns `true` if the string is a `PascalCase` string.
  bool get isPascalCase {
    if (contains('_')) return false;
    if (_startsWithUpperCaseRegExp.matchAsPrefix(this) == null) return false;
    return true;
  }

  /// Converts `SCREAMING_SNAKE_CASE` or `snake_case` to `camelCase`.
  String toCamelCase() {
    var parts = toLowerCase().split('_');
    var buffer = StringBuffer();
    var i = 0;
    // Preserve initial '_'s
    while (i < parts.length - 1 && parts[i].isEmpty) {
      buffer.write('_');
      ++i;
    }
    if (i < parts.length) {
      // Convert first word to lower case
      buffer.write(parts[i].toLowerCase());
      ++i;
      // Convert remaining words to initial upper case
      while (i < parts.length) {
        var part = parts[i];
        if (part.isNotEmpty) {
          buffer.write(part[0].toUpperCase());
          buffer.write(part.substring(1));
        }
        ++i;
      }
    }
    return buffer.toString();
  }

  /// Converts `SCREAMING_SNAKE_CASE` or `snake_case` to `PascalCase`.
  String toPascalCase() {
    var parts = toLowerCase().split('_');
    var buffer = StringBuffer();
    var i = 0;
    // Preserve initial '_'s
    while (i < parts.length - 1 && parts[i].isEmpty) {
      buffer.write('_');
      ++i;
    }
    // Convert words to initial upper case
    while (i < parts.length) {
      var part = parts[i];
      if (part.isNotEmpty) {
        buffer.write(part[0].toUpperCase());
        buffer.write(part.substring(1));
      }
      ++i;
    }
    return buffer.toString();
  }

  /// Converts `camelCase` or `PascalCase` to `snake_case`
  String toSnakeCase() {
    var parts = <String>[];
    var i = 0;
    var wordStarts = _toSnakeCaseRegExp.allMatches(this);
    for (var RegExpMatch(:start) in wordStarts) {
      if (i < start) {
        parts.add(substring(i, start).toLowerCase());
        i = start;
      }
      if (this[i] == '_' && parts.isNotEmpty) {
        // Avoid doubling up the `_`. This handles strings that are already in
        // snake case like `foo_Bar` (which translates to `foo_bar`).
        i++;
      }
    }
    if (i < length) {
      parts.add(substring(i).toLowerCase());
    }
    return parts.join('_');
  }
}
