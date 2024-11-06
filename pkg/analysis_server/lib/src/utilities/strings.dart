// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math';

import 'package:analyzer/src/utilities/extensions/string.dart';

/// "$"
const int CHAR_DOLLAR = 0x24;

/// "_"
const int CHAR_UNDERSCORE = 0x5F;

String? capitalize(String? str) {
  if (str == null || str.isEmpty) {
    return str;
  }
  return str.substring(0, 1).toUpperCase() + str.substring(1);
}

int compareStrings(String? a, String? b) {
  if (a == b) {
    return 0;
  }
  if (a == null) {
    return 1;
  }
  if (b == null) {
    return -1;
  }
  return a.compareTo(b);
}

/// Return a simple difference between the given [oldStr] and [newStr].
SimpleDiff computeSimpleDiff(String oldStr, String newStr) {
  var prefixLength = findCommonPrefix(oldStr, newStr);
  var suffixLength = findCommonSuffix(oldStr, newStr);
  while (prefixLength >= 0) {
    var oldReplaceLength = oldStr.length - prefixLength - suffixLength;
    var newReplaceLength = newStr.length - prefixLength - suffixLength;
    if (oldReplaceLength >= 0 && newReplaceLength >= 0) {
      return SimpleDiff(
        prefixLength,
        oldReplaceLength,
        newStr.substring(prefixLength, newStr.length - suffixLength),
      );
    }
    prefixLength--;
  }
  return SimpleDiff(0, oldStr.length, newStr);
}

int countLeadingWhitespaces(String str) {
  var i = 0;
  for (; i < str.length; i++) {
    var c = str.codeUnitAt(i);
    if (!c.isWhitespace) {
      break;
    }
  }
  return i;
}

/// Counts how many times [sub] appears in [str].
int countMatches(String? str, String? sub) {
  if (str == null || str.isEmpty || sub == null || sub.isEmpty) {
    return 0;
  }
  var count = 0;
  var idx = 0;
  while ((idx = str.indexOf(sub, idx)) != -1) {
    count++;
    idx += sub.length;
  }
  return count;
}

int countTrailingWhitespaces(String str) {
  var i = 0;
  for (; i < str.length; i++) {
    var c = str.codeUnitAt(str.length - 1 - i);
    if (!c.isWhitespace) {
      break;
    }
  }
  return i;
}

/// Returns the number of characters common to the start of [a] and [b].
int findCommonPrefix(String a, String b) {
  var n = min(a.length, b.length);
  for (var i = 0; i < n; i++) {
    if (a.codeUnitAt(i) != b.codeUnitAt(i)) {
      return i;
    }
  }
  return n;
}

/// Returns the number of characters common to the end of [a] and [b].
int findCommonSuffix(String a, String b) {
  var a_length = a.length;
  var b_length = b.length;
  var n = min(a_length, b_length);
  for (var i = 1; i <= n; i++) {
    if (a.codeUnitAt(a_length - i) != b.codeUnitAt(b_length - i)) {
      return i - 1;
    }
  }
  return n;
}

/// Checks if [str] is `null`, empty or whitespace.
bool isBlank(String? str) {
  if (str == null || str.isEmpty) {
    return true;
  }
  return str.codeUnits.every((c) => c.isSpace);
}

String? removeEnd(String? str, String? remove) {
  if (str == null || str.isEmpty || remove == null || remove.isEmpty) {
    return str;
  }
  if (str.endsWith(remove)) {
    return str.substring(0, str.length - remove.length);
  }
  return str;
}

/// Information about a single replacement that should be made to convert the
/// "old" string to the "new" one.
class SimpleDiff {
  final int offset;
  final int length;
  final String replacement;

  SimpleDiff(this.offset, this.length, this.replacement);
}
