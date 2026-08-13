// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../native_testing.dart';
import 'null_assertions_test_lib.dart';

// Implementations of `NativeInterface` and `JSInterface` in a folder that is
// not part of the allowlist for the `--native-null-assertions` flag. This file
// is not treated as a web library, and therefore native members and `JS()`
// invocations should not be checked.

@Native("AAA")
class AAA implements NativeInterface {
  int get size native;
  String get name native;
  String? get optName native;
  int method1() native;
  String method2() native;
  String? optMethod() native;
}

@Native('CCC')
class CCC implements JSInterface {
  String get name => JS('String', '#.name', this);
  String? get optName => JS('String|Null', '#.optName', this);
}

/// Returns an 'AAA' object that satisfies the interface.
AAA makeA() native;

/// Returns an 'AAA' object where each method breaks the interface's contract.
AAA makeAX() native;

/// Returns a 'CCC' object that satisfies the interface using `JS()`
/// invocations.
CCC makeC() native;

/// Returns a 'CCC' object where each method breaks the interface's contract.
CCC makeCX() native;

// The 'AAA' version of the code is passed only objects of a single native
// class, so the native method can be inlined (which happens in the optimizer).
// This tests that the null-check exists in the 'inlined' code.

@pragma('dart2js:noInline')
String describeAAA(AAA o) {
  return '${o.name} ${o.method2()} ${o.size} ${o.method1()}';
}

@pragma('dart2js:noInline')
String describeOptAAA(AAA o) {
  return '${o.optName} ${o.optMethod()}';
}

void testNativeNullAssertions(bool flagEnabled) {
  nativeTesting();
  setup();
  AAA a = makeA();
  BBB b = BBB();

  Expect.equals(expectedA, describeNativeInterface(a));
  Expect.equals(expectedB, describeNativeInterface(b));

  Expect.equals(expectedA, describeAAA(a));

  AAA x = makeAX(); // This object returns `null`!
  // Since native members are not in a web library, there should be no checks,
  // regardless of if the flag is enabled.
  var checkExpectation = (f) => f();
  checkExpectation(() => describeNativeInterface(x));
  checkExpectation(() => describeAAA(x));

  checkExpectation(() => x.name);
  checkExpectation(() => x.size);
  checkExpectation(() => x.method1());
  checkExpectation(() => x.method2());

  // Now test that a nullable return type does not have a check.
  Expect.equals(expectedOptA, describeOptNativeInterface(a));
  Expect.equals(expectedOptB, describeOptNativeInterface(b));
  Expect.equals(expectedOptX, describeOptNativeInterface(x));

  Expect.equals(expectedOptA, describeOptAAA(a));
  Expect.equals(expectedOptX, describeOptAAA(x));
}

void testJSInvocationNullAssertions(bool flagEnabled) {
  nativeTesting();
  setup();

  CCC c = makeC();
  CCC cx = makeCX();

  Expect.equals(expectedC, describeJSInterface(c));

  // Since invocations are not in a web library, there should be no checks,
  // regardless of if the flag is enabled.
  var checkExpectation = (f) => f();
  checkExpectation(() => describeJSInterface(cx));

  // Test that invocations with a nullable static type do not have checks.
  Expect.equals(expectedOptC, describeOptJSInterface(c));
  Expect.equals(expectedOptCX, describeOptJSInterface(cx));
}
