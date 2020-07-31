// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";

// Test that local variable reads and writes are sequenced correctly with
// respect to reads and writes in an awaited Future.  See issue 26175.

// Reads are sequenced correctly with respect to writes in a Future.
Future test1() async {
  var x = 'a';
  f() async => x = 'b';
  Expect.equals('abb', '${x}${await f()}${x}');
}

// Writes are sequenced correctly with respect to writes in a Future.
Future test2(ignore) async {
  var x;
  f() async => x = 'b';
  Expect.equals('abb', '${x = 'a'}${await f()}${x}');
}

// Writes are sequenced correctly with respect to reads in a Future.
Future test3(ignore) async {
  var x = 'a';
  f() async => x;
  Expect.equals('bbb', '${x = 'b'}${await f()}${x}');
}

// Repeat the same tests for static variables.
var cell = 'a';

asyncReadCell() async => cell;
asyncWriteCell(value) async => cell = value;

Future test4(ignore) async {
  // This test assumes that it can read the initial value of cell.
  Expect.equals('abb', '${cell}${await asyncWriteCell('b')}${cell}');
}

Future test5(ignore) async {
  Expect.equals('abb', '${cell = 'a'}${await asyncWriteCell('b')}${cell}');
}

Future test6(ignore) async {
  Expect.equals('bbb', '${cell = 'b'}${await asyncReadCell()}${cell}');
}

// Test that throwing is sequenced correctly with respect to other effects.
Future test7(ignore) async {
  cell = 'a';
  try {
    Expect.equals(
        'unreachable', '${throw 0}${await asyncWriteCell('b')}${cell}');
  } catch (_) {
    Expect.equals('a', cell);
  }
}

main() {
  asyncStart();
  test1()
      .then(test2)
      .then(test3)
      .then(test4)
      .then(test5)
      .then(test6)
      .then(test7)
      .then((_) => asyncEnd());
}
