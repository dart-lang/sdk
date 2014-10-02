// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library diff;

import 'dart:math';


/**
 * Return the number of characters common to the start of [a] and [b].
 */
int findCommonPrefix(String a, String b) {
  int n = min(a.length, b.length);
  for (int i = 0; i < n; i++) {
    if (a.codeUnitAt(i) != b.codeUnitAt(i)) {
      return i;
    }
  }
  return n;
}


/**
 * Return the number of characters common to the end of [a] and [b].
 */
int findCommonSuffix(String a, String b) {
  int a_length = a.length;
  int b_length = b.length;
  int n = min(a_length, b_length);
  for (int i = 1; i <= n; i++) {
    if (a.codeUnitAt(a_length - i) != b.codeUnitAt(b_length - i)) {
      return i - 1;
    }
  }
  return n;
}
