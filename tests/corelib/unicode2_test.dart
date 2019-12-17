// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

const String testPhrase = "The quick brown fox jumps over the lazy dog.";

const List<int> testCodepoints = const <int>[
  84,
  104,
  101,
  32,
  113,
  117,
  105,
  99,
  107,
  32,
  98,
  114,
  111,
  119,
  110,
  32,
  102,
  111,
  120,
  32,
  106,
  117,
  109,
  112,
  115,
  32,
  111,
  118,
  101,
  114,
  32,
  116,
  104,
  101,
  32,
  108,
  97,
  122,
  121,
  32,
  100,
  111,
  103,
  46
];

main() {
  testCodepointsToString();
  testStringCharCodes();
  testEmptyStringFromCharCodes();
  testEmptyStringCharCodes();
}

void testStringCharCodes() {
  Expect.listEquals(testCodepoints, testPhrase.codeUnits);
}

void testCodepointsToString() {
  Expect.stringEquals(testPhrase, new String.fromCharCodes(testCodepoints));
}

void testEmptyStringFromCharCodes() {
  Expect.stringEquals("", new String.fromCharCodes(<int>[]));
}

void testEmptyStringCharCodes() {
  Expect.listEquals([], "".codeUnits);
}
