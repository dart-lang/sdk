// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension StringExtension on String {
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
}
