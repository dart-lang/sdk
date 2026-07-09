// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension StringExtension on String {
  /// Builds a string from `this` that includes a caret (`^`) at the given
  /// [offset].
  ///
  /// This string is useful for displaying to users in a diagnostic context.
  String withCaretAt(int offset) {
    if (offset < 0 || length < offset) {
      return '???';
    }
    var start = offset;
    while (start > 0) {
      var ch = this[start - 1];
      if (ch == '\r' || ch == '\n') {
        break;
      }
      --start;
    }
    var end = offset;
    while (end < length) {
      var ch = this[end];
      if (ch == '\r' || ch == '\n') {
        break;
      }
      ++end;
    }
    var prefix = substring(start, offset);
    var suffix = substring(offset, end);
    return '$prefix^$suffix';
  }
}
