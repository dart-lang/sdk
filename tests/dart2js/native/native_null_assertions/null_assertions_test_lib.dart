// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../native_testing.dart';
import 'js_invocations_in_non_web_library.dart';
import 'js_invocations_in_web_library.dart';
import 'null_assertions_lib.dart';

/// Returns an 'AAA' object that satisfies the interface.
AAA makeA() native;

/// Returns an 'AAA' object where each method breaks the interface's contract.
AAA makeAX() native;

/// Returns a 'JSInterface' object whose `JS()` invocations exist in a library
/// that is part of the allowlist.
CCCInWebLibrary makeWebC() native;

/// Returns the same as above but where each method breaks the interface's
/// contract.
CCCInWebLibrary makeWebCX() native;

/// Returns a 'JSInterface' object whose `JS()` invocations exist in a library
/// that is not part of the allowlist.
CCCInNonWebLibrary makeNonWebC() native;

/// Returns the same as above but where each method breaks the interface's
/// contract.
CCCInNonWebLibrary makeNonWebCX() native;

void setup() {
  JS('', r"""
(function(){
  function AAA(s,n,m1,m2) {
    this.size = s;
    this.name = n;
    this.optName = n;
    this._m1 = m1;
    this._m2 = m2;
  }
  AAA.prototype.method1 = function(){return this._m1};
  AAA.prototype.method2 = function(){return this._m2};
  AAA.prototype.optMethod = function(){return this._m2};

  makeA = function() {
    return new AAA(100, 'Albert', 200, 'amazing!');
  };
  makeAX = function() {
    return new AAA(void 0, void 0, void 0, void 0);
  };

  self.nativeConstructor(AAA);

  function CCCInWebLibrary(n) {
    this.name = n;
    this.optName = n;
  }
  function CCCInNonWebLibrary(n) {
    this.name = n;
    this.optName = n;
  }

  makeWebC = function() {
    return new CCCInWebLibrary('Carol');
  };
  makeWebCX = function() {
    return new CCCInWebLibrary(void 0);
  };
  makeNonWebC = function() {
    return new CCCInNonWebLibrary('Carol');
  };
  makeNonWebCX = function() {
    return new CCCInNonWebLibrary(void 0);
  };

  self.nativeConstructor(CCCInWebLibrary);
  self.nativeConstructor(CCCInNonWebLibrary);
})()""");
}

// The 'NativeInterface' version of the code is passed both native and Dart
// objects, so there will be an interceptor dispatch to the method. This tests
// that the null-check exists in the forwarding method.
//
// The 'AAA' version of the code is passed only objects of a single native
// class, so the native method can be inlined (which happens in the optimizer).
// This tests that the null-check exists in the 'inlined' code.

@pragma('dart2js:noInline')
String describeNativeInterface(NativeInterface o) {
  return '${o.name} ${o.method2()} ${o.size} ${o.method1()}';
}

@pragma('dart2js:noInline')
String describeAAA(AAA o) {
  return '${o.name} ${o.method2()} ${o.size} ${o.method1()}';
}

@pragma('dart2js:noInline')
String describeOptNativeInterface(NativeInterface o) {
  return '${o.optName} ${o.optMethod()}';
}

@pragma('dart2js:noInline')
String describeOptAAA(AAA o) {
  return '${o.optName} ${o.optMethod()}';
}

@pragma('dart2js:noInline')
String describeJSInterface(JSInterface o) {
  return '${o.name}';
}

@pragma('dart2js:noInline')
String describeOptJSInterface(JSInterface o) {
  return '${o.optName}';
}

const expectedA = 'Albert amazing! 100 200';
const expectedB = 'Brenda brilliant! 300 400';
const expectedOptA = 'Albert amazing!';
const expectedOptB = 'Brenda brilliant!';
const expectedOptX = 'null null';

const expectedC = 'Carol';
const expectedOptC = 'Carol';
const expectedOptCX = 'null';

// Test that `--native-null-assertions` injects null-checks on the returned
// value of native methods with a non-nullable return type in an opt-in library.
void testNativeNullAssertions(bool flagEnabled) {
  nativeTesting();
  setup();
  AAA a = makeA();
  BBB b = BBB();

  Expect.equals(expectedA, describeNativeInterface(a));
  Expect.equals(expectedB, describeNativeInterface(b));

  Expect.equals(expectedA, describeAAA(a));

  AAA x = makeAX(); // This object returns `null`!
  var checkExpectation = flagEnabled ? Expect.throws : (f) => f();
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

// Test that `--native-null-assertions` injects null-checks on the returned
// value of `JS()` invocations with a non-nullable static type in an opt-in
// library.
void testJSInvocationNullAssertions(bool flagEnabled) {
  nativeTesting();
  setup();

  CCCInWebLibrary webC = makeWebC();
  CCCInWebLibrary webCX = makeWebCX();

  CCCInNonWebLibrary nonWebC = makeNonWebC();
  CCCInNonWebLibrary nonWebCX = makeNonWebCX();

  Expect.equals(expectedC, describeJSInterface(webC));
  Expect.equals(expectedC, describeJSInterface(nonWebC));

  // If invocations are in a web library, this should throw if null checks are
  // enabled.
  var checkExpectationWeb = flagEnabled ? Expect.throws : (f) => f();
  checkExpectationWeb(() => describeJSInterface(webCX));

  // If invocations are not in a web library, there should not be a null check
  // regardless if the flag is enabled or not.
  var checkExpectationNonWeb = (f) => f();
  checkExpectationNonWeb(() => describeJSInterface(nonWebCX));

  // Test that invocations with a nullable static type do not have checks.
  Expect.equals(expectedOptC, describeOptJSInterface(webC));
  Expect.equals(expectedOptC, describeOptJSInterface(nonWebC));
  Expect.equals(expectedOptCX, describeOptJSInterface(webCX));
  Expect.equals(expectedOptCX, describeOptJSInterface(nonWebCX));
}
