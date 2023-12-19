// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test for null assertions for parameters in NNBD weak mode.

// Requirements=nnbd-weak
// VMOptions=--enable-asserts
// dart2jsOptions=--enable-asserts -DcheckString=false
// SharedOptions=--null-assertions

// Opt out of Null Safety:
// @dart = 2.6

import "package:expect/expect.dart";

import 'parameter_checks_opted_in.dart';

bool Function(Object) asserted(String name) {
  if (const bool.fromEnvironment('checkString', defaultValue: true)) {
    return (e) => e is AssertionError && e.toString().contains("$name != null");
  } else {
    return (e) => e is AssertionError;
  }
}

main() {
  Expect.throws(() {
    foo1(null);
  }, asserted("a"));
  Expect.throws(() {
    foo2(1, null);
  }, asserted("b"));
  Expect.throws(() {
    foo3();
  }, asserted("b"));
  Expect.throws(() {
    foo3(b: null);
  }, asserted("b"));
  foo4a<int>(null);
  Expect.throws(() {
    foo4b<int>(null);
  }, asserted("a"));
  foo5a<int>(null);
  Expect.throws(() {
    foo5b<int>(null);
  }, asserted("a"));
  foo6a<int, int, int>(null);
  Expect.throws(() {
    foo6b<int, int, int>(null);
  }, asserted("a"));
  Expect.throws(() {
    bar().call(null);
  }, asserted("x"));
}
