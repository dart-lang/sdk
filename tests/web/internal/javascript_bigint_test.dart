// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_interceptors';
import 'package:js/js.dart';
import 'package:expect/expect.dart';

@JS()
external JavaScriptBigInt bigInt;

@JS('bigInt')
external dynamic bigIntDynamic;

@JS('BigInt')
external JavaScriptBigInt makeBigInt(String value);

@JS()
main() {
  const s = '9876543210000000000000123456789';
  bigInt = makeBigInt(s);

  /* toString */
  Expect.equals(s, bigInt.toString());
  Expect.equals(s, bigIntDynamic.toString());
  // String interpolation
  Expect.equals(s, '$bigInt');
  Expect.equals(s, '$bigIntDynamic');
  // toString tear-offs
  var toStringTearoff = bigInt.toString;
  Expect.type<String Function()>(toStringTearoff);
  Expect.equals(bigInt.toString, toStringTearoff);
  Expect.equals(bigInt.toString(), toStringTearoff());
  toStringTearoff = bigIntDynamic.toString;
  Expect.type<String Function()>(toStringTearoff);
  Expect.equals(bigInt.toString, toStringTearoff);
  Expect.equals(bigInt.toString(), toStringTearoff());

  /* hashCode */
  // This value is allowed to change, but for lack of a better existing option,
  // we return 0.
  Expect.equals(0, bigInt.hashCode);
  Expect.equals(0, bigIntDynamic.hashCode);

  /* == */
  // Prefer `==` over `Expect.equals` so we can check dynamic vs non-dynamic
  // calls.
  Expect.isTrue(bigInt == bigInt);
  Expect.isTrue(bigIntDynamic == bigInt);
  final differentBigInt = makeBigInt('1234567890000000000000987654321');
  Expect.isFalse(bigInt == differentBigInt);
  Expect.isFalse(bigIntDynamic == differentBigInt);

  /* noSuchMethod */
  final methodName = 'testMethod';
  final invocation = Invocation.method(Symbol(methodName), null);
  void testNoSuchMethodResult(noSuchMethodResult) {
    Expect.type<NoSuchMethodError>(noSuchMethodResult);
    Expect.contains(methodName, noSuchMethodResult.toString());
  }

  testNoSuchMethodResult(Expect.throws(() => bigInt.noSuchMethod(invocation)));
  testNoSuchMethodResult(
      Expect.throws(() => bigIntDynamic.noSuchMethod(invocation)));

  var noSuchMethodTearoff = bigInt.noSuchMethod;
  Expect.type<dynamic Function(Invocation)>(noSuchMethodTearoff);
  Expect.equals(bigInt.noSuchMethod, noSuchMethodTearoff);
  testNoSuchMethodResult(Expect.throws(() => noSuchMethodTearoff(invocation)));
  noSuchMethodTearoff = bigIntDynamic.noSuchMethod;
  Expect.type<dynamic Function(Invocation)>(noSuchMethodTearoff);
  Expect.equals(bigIntDynamic.noSuchMethod, noSuchMethodTearoff);
  testNoSuchMethodResult(Expect.throws(
      () => noSuchMethodTearoff(Invocation.method(Symbol(methodName), null))));

  /* runtimeType */
  var runtimeTypeResult = bigInt.runtimeType;
  Expect.type<Type>(runtimeTypeResult);
  Expect.equals(bigInt.runtimeType, runtimeTypeResult);
  runtimeTypeResult = bigIntDynamic.runtimeType;
  Expect.type<Type>(runtimeTypeResult);
  Expect.equals(bigIntDynamic.runtimeType, runtimeTypeResult);
}
