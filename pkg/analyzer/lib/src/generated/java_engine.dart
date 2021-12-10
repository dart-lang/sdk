// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/generated/interner.dart';

export 'package:analyzer/exception/exception.dart';

/// A predicate is a one-argument function that returns a boolean value.
typedef Predicate<E> = bool Function(E argument);

class StringUtilities {
  static const String EMPTY = '';
  static const List<String> EMPTY_ARRAY = <String>[];

  static Interner INTERNER = NullInterner();

  /// Compute line starts for the given [content].
  /// Lines end with `\r`, `\n` or `\r\n`.
  static List<int> computeLineStarts(String content) {
    List<int> lineStarts = <int>[0];
    int length = content.length;
    int unit;
    for (int index = 0; index < length; index++) {
      unit = content.codeUnitAt(index);
      // Special-case \r\n.
      if (unit == 0x0D /* \r */) {
        // Peek ahead to detect a following \n.
        if ((index + 1 < length) && content.codeUnitAt(index + 1) == 0x0A) {
          // Line start will get registered at next index at the \n.
        } else {
          lineStarts.add(index + 1);
        }
      }
      // \n
      if (unit == 0x0A) {
        lineStarts.add(index + 1);
      }
    }
    return lineStarts;
  }

  static bool endsWithChar(String str, int c) {
    int length = str.length;
    return length > 0 && str.codeUnitAt(length - 1) == c;
  }

  static String intern(String string) => INTERNER.intern(string);

  /// Produce a string containing all of the names in the given array,
  /// surrounded by single quotes, and separated by commas.
  ///
  /// The list must contain at least two elements.
  ///
  /// @param names the names to be printed
  /// @return the result of printing the names
  static String printListOfQuotedNames(List<String>? names) {
    if (names == null) {
      throw ArgumentError("The list must not be null");
    }
    int count = names.length;
    if (count < 2) {
      throw ArgumentError("The list must contain at least two names");
    }
    StringBuffer buffer = StringBuffer();
    buffer.write("'");
    buffer.write(names[0]);
    buffer.write("'");
    for (int i = 1; i < count - 1; i++) {
      buffer.write(", '");
      buffer.write(names[i]);
      buffer.write("'");
    }
    buffer.write(" and '");
    buffer.write(names[count - 1]);
    buffer.write("'");
    return buffer.toString();
  }
}
