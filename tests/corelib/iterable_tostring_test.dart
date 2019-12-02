// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test the IterableBase/IterableMixin toString method.

import "package:expect/expect.dart";
import "dart:collection";

String mkIt(int len, [func]) {
  var list;
  if (func == null) {
    list = new List.generate(len, (x) => x);
  } else {
    list = new List.generate(len, func);
  }
  return new MyIterable(list).toString();
}

class MyIterable extends IterableBase {
  final Iterable _base;
  MyIterable(this._base);
  Iterator get iterator => _base.iterator;
}

void main() {
  Expect.equals("()", mkIt(0));
  Expect.equals("(0)", mkIt(1));
  Expect.equals("(0, 1)", mkIt(2));
  Expect.equals("(0, 1, 2, 3, 4, 5, 6, 7, 8)", mkIt(9));

  // Builds string up to 60 characters, then finishes with last two
  // elements.
  Expect.equals(
      //0123456789012345678901234567890123456789 - 40 characters
      "(0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 1"
      "2, 13, 14, 15, 16, 17, 18, ..., 98, 99)",
      mkIt(100));

  Expect.equals(
      //0123456789012345678901234567890123456789
      "(0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 1"
      "2, 13, 14, 15, 16, 17, 18)",
      mkIt(19));

  Expect.equals(
      //0123456789012345678901234567890123456789
      "(0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 1"
      "2, 13, 14, 15, 16, 17, 18, 19)",
      mkIt(20));

  Expect.equals(
      //0123456789012345678901234567890123456789
      "(0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 1"
      "2, 13, 14, 15, 16, 17, 18, 19, 20)",
      mkIt(21));

  // Don't show last two elements if more than 100 elements total
  // (can't be 100 elements in 80 characters including commas).
  Expect.equals(
      //0123456789012345678901234567890123456789
      "(0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 1"
      "2, 13, 14, 15, 16, 17, 18, 19, 20, ...)",
      mkIt(101));

  // If last two elements bring total over 80 characters, drop some of
  // the previous ones as well.

  Expect.equals(
      //0123456789012345678901234567890123456789
      "(0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 1"
      "2, 13, ..., 18, xxxxxxxxxxxxxxxxxxxx)",
      mkIt(20, (x) => x == 19 ? "xxxxxxxxxxxxxxxxxxxx" : "$x"));

  // Never drop the first three or the last two.
  Expect.equals(
      //0123456789012345678901234567890123456789
      "(xxxxxxxxxxxxxxxxx, xxxxxxxxxxxxxxxxx, x"
      "xxxxxxxxxxxxxxxx, ..., 18, xxxxxxxxxxxxx"
      "xxxx)",
      mkIt(20, (x) => (x < 3 || x == 19) ? "xxxxxxxxxxxxxxxxx" : "$x"));

  // Never drop the first three or the last two.
  Expect.equals(
      //0123456789012345678901234567890123456789
      "(xxxxxxxxxxxxxxxxx, xxxxxxxxxxxxxxxxx, x"
      "xxxxxxxxxxxxxxxx, ..., xxxxxxxxxxxxxxxxx"
      ", 19)",
      mkIt(20, (x) => (x < 3 || x == 18) ? "xxxxxxxxxxxxxxxxx" : "$x"));

  // If the first three are very long, always include them anyway.
  Expect.equals(
      //0123456789012345678901234567890123456789
      "(xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx,"
      " xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx,"
      " xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx,"
      " ..., 98, 99)",
      mkIt(100,
          (x) => (x < 3) ? "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" : "$x"));

  Expect.equals(
      //0123456789012345678901234567890123456789
      "(, , , , , , , , , , , , , , , , , , , ,"
      " , , , , , , , , , , , , , , , ..., , )",
      mkIt(100, (_) => ""));
}
