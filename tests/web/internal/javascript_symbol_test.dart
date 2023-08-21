// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_interceptors';
import 'package:js/js.dart';
import 'package:expect/expect.dart';

@JS()
external void eval(String code);

@JS()
external JavaScriptSymbol symbol;

@JS('symbol')
external dynamic symbolDynamic;

@JS('Symbol')
external JavaScriptSymbol makeSymbol(String value);

@JS()
main() {
  const s = 'symbolValue';
  symbol = makeSymbol(s);

  /* toString */
  final toStringVal = 'Symbol($s)';
  Expect.equals(toStringVal, symbol.toString());
  Expect.equals(toStringVal, symbolDynamic.toString());
  // String interpolation
  Expect.equals(toStringVal, '$symbol');
  Expect.equals(toStringVal, '$symbolDynamic');
  // toString tear-offs
  var toStringTearoff = symbol.toString;
  Expect.type<String Function()>(toStringTearoff);
  Expect.equals(symbol.toString, toStringTearoff);
  Expect.equals(symbol.toString(), toStringTearoff());
  toStringTearoff = symbolDynamic.toString;
  Expect.type<String Function()>(toStringTearoff);
  Expect.equals(symbol.toString, toStringTearoff);
  Expect.equals(symbol.toString(), toStringTearoff());

  /* hashCode */
  // This value is allowed to change, but for lack of a better existing option,
  // we return 0.
  Expect.equals(0, symbol.hashCode);
  Expect.equals(0, symbolDynamic.hashCode);

  /* == */
  // Prefer `==` over `Expect.equals` so we can check dynamic vs non-dynamic
  // calls.
  Expect.isTrue(symbol == symbol);
  Expect.isTrue(symbolDynamic == symbol);
  // Different symbols with the same values are not equal.
  final differentSymbol = makeSymbol(s);
  Expect.isFalse(symbol == differentSymbol);
  Expect.isFalse(symbolDynamic == differentSymbol);

  /* noSuchMethod */
  final methodName = 'testMethod';
  final invocation = Invocation.method(Symbol(methodName), null);
  void testNoSuchMethodResult(noSuchMethodResult) {
    Expect.type<NoSuchMethodError>(noSuchMethodResult);
    Expect.contains(methodName, noSuchMethodResult.toString());
  }

  testNoSuchMethodResult(Expect.throws(() => symbol.noSuchMethod(invocation)));
  testNoSuchMethodResult(
      Expect.throws(() => symbolDynamic.noSuchMethod(invocation)));

  var noSuchMethodTearoff = symbol.noSuchMethod;
  Expect.type<dynamic Function(Invocation)>(noSuchMethodTearoff);
  Expect.equals(symbol.noSuchMethod, noSuchMethodTearoff);
  testNoSuchMethodResult(Expect.throws(() => noSuchMethodTearoff(invocation)));
  noSuchMethodTearoff = symbolDynamic.noSuchMethod;
  Expect.type<dynamic Function(Invocation)>(noSuchMethodTearoff);
  Expect.equals(symbolDynamic.noSuchMethod, noSuchMethodTearoff);
  testNoSuchMethodResult(Expect.throws(
      () => noSuchMethodTearoff(Invocation.method(Symbol(methodName), null))));

  /* runtimeType */
  var runtimeTypeResult = symbol.runtimeType;
  Expect.type<Type>(runtimeTypeResult);
  Expect.equals(symbol.runtimeType, runtimeTypeResult);
  runtimeTypeResult = symbolDynamic.runtimeType;
  Expect.type<Type>(runtimeTypeResult);
  Expect.equals(symbolDynamic.runtimeType, runtimeTypeResult);
}
