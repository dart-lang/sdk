// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
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

class C extends A {
  // Overrides the getters but not the setters.
  @override
  int get getterSetterPair => 999;
  @override
  int get field => 999;
}

main() {
  Expect.throws(() {
    topLevelField = null;
  }, asserted("topLevelField"));
  Expect.throws(() {
    topLevelGetterSetterPair = null;
  }, asserted("i"));
  Expect.throws(() {
    topLevelSetterOnly = null;
  }, asserted("s"));

  var a = A();
  Expect.throws(() {
    a.getterSetterPair = null;
  }, asserted("i"));
  Expect.throws(() {
    a.setterOnly = null;
  }, asserted("s"));
  Expect.throws(() {
    a.field = null;
  }, asserted("field"));
  Expect.throws(() {
    A.staticGetterSetterPair = null;
  }, asserted("i"));
  Expect.throws(() {
    A.staticSetterOnly = null;
  }, asserted("s"));
  Expect.throws(() {
    A.staticField = null;
  }, asserted("staticField"));

  var b = B();
  Expect.throws(() {
    b.getterSetterPair = null;
  }, asserted("i"));
  Expect.throws(() {
    b.field = null;
  }, asserted("field"));

  var c = C();
  Expect.throws(() {
    c.getterSetterPair = null;
  }, asserted("i"));
  Expect.throws(() {
    c.field = null;
  }, asserted("field"));
}
