// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

// Avoid static type optimization by running all tests using this.
@pragma('dart2js:noInline')
@pragma('dart2js:assumeDynamic')
confuse(x) => x;

void testHashCode(x) {
  var hashCodeResult = confuse(x.hashCode);
  Expect.type<int>(hashCodeResult);
  Expect.equals(x.hashCode, hashCodeResult);
}

void testRuntimeType(x) {
  var runtimeTypeResult = confuse(x.runtimeType);
  Expect.type<Type>(runtimeTypeResult);
  Expect.equals(x.runtimeType, runtimeTypeResult);
}

void testNoSuchMethod(x) {
  var noSuchMethodResult = Expect.throws(
      () => x.noSuchMethod(Invocation.method(Symbol('testMethod'), null)));
  Expect.type<NoSuchMethodError>(noSuchMethodResult);
  Expect.contains('testMethod', noSuchMethodResult.toString());
}

void testNoSuchMethodTearoff(x) {
  var noSuchMethodTearoff = confuse(x.noSuchMethod);
  Expect.type<dynamic Function(Invocation)>(noSuchMethodTearoff);
  Expect.equals(x.noSuchMethod, noSuchMethodTearoff);
  var noSuchMethodResult = Expect.throws(
      () => noSuchMethodTearoff(Invocation.method(Symbol('testMethod'), null)));
  Expect.type<NoSuchMethodError>(noSuchMethodResult);
  Expect.contains('testMethod', noSuchMethodResult.toString());
}

void testToString(x, String expected) {
  var toStringResult = confuse(x.toString());
  Expect.type<String>(toStringResult);
  Expect.isTrue(toStringResult.isNotEmpty);
  Expect.equals(toStringResult, expected);
  Expect.equals(x.toString(), toStringResult);
}

void testToStringTearoff(x, String expected) {
  var toStringTearoff = confuse(x.toString);
  Expect.type<String Function()>(toStringTearoff);
  Expect.equals(x.toString, toStringTearoff);
  var toStringResult = toStringTearoff();
  Expect.type<String>(toStringResult);
  Expect.isTrue(toStringResult.isNotEmpty);
  Expect.equals(toStringResult, expected);
  Expect.equals(x.toString(), toStringResult);
}

void testEquals(x, other) {
  var y = confuse(other);
  var equalityResult = x == y;
  Expect.type<bool>(equalityResult);
  Expect.isFalse(equalityResult);
  Expect.equals(equalityResult, x == y);
  Expect.isTrue(confuse(x) == x);
}
