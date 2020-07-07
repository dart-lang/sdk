// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test for null assertions for parameters in NNBD weak mode.

// Requirements=nnbd-weak
// VMOptions=--enable-asserts
// SharedOptions=--null-assertions

// Opt out of Null Safety:
// @dart = 2.6

import "package:expect/expect.dart";

import 'parameter_checks_opted_in.dart';

main() {
  Expect.throws(() {
    foo1(null);
  }, (e) => e is AssertionError && e.toString().contains("a != null"));
  Expect.throws(() {
    foo2(1, null);
  }, (e) => e is AssertionError && e.toString().contains("b != null"));
  Expect.throws(() {
    foo3();
  }, (e) => e is AssertionError && e.toString().contains("b != null"));
  Expect.throws(() {
    foo3(b: null);
  }, (e) => e is AssertionError && e.toString().contains("b != null"));
  foo4a<int>(null);
  Expect.throws(() {
    foo4b<int>(null);
  }, (e) => e is AssertionError && e.toString().contains("a != null"));
  foo5a<int>(null);
  Expect.throws(() {
    foo5b<int>(null);
  }, (e) => e is AssertionError && e.toString().contains("a != null"));
  foo6a<int, int, int>(null);
  Expect.throws(() {
    foo6b<int, int, int>(null);
  }, (e) => e is AssertionError && e.toString().contains("a != null"));
  Expect.throws(() {
    bar().call(null);
  }, (e) => e is AssertionError && e.toString().contains("x != null"));
}
