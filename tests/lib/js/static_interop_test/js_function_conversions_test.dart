// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// dart2jsOptions=-O2

// Test that Function.toJS properly converts/casts arguments and return values
// when using Dart types.

import 'dart:js_interop';
import 'package:expect/expect.dart';
import 'package:expect/minitest.dart';

@JS()
external void eval(String code);

@JS()
external set jsFunction(JSFunction f);

@JS('jsFunction')
external JSString stringF(JSString s);

@JS('jsFunction')
external JSNumber numF(JSNumber n);

@JS('jsFunction')
external JSBoolean boolF(JSBoolean b);

@JS('jsFunction')
external void voidF(JSString s);

@JS('jsFunction')
external JSAny? anyF(JSAny? n);

@JS()
external JSAny? callFunctionWithUndefined();

@JS()
external JSAny? callFunctionWithJSNull();

void main() {
  jsFunction = ((String arg) => arg).toJS;
  expect(stringF('stringF'.toJS).toDart, 'stringF');
  Expect.throws(() => anyF(0.toJS));

  jsFunction = ((int arg) => arg).toJS;
  expect(numF(0.toJS).toDartInt, 0);
  expect(numF(0.0.toJS).toDartInt, 0);
  Expect.throws(() => numF(0.1.toJS));
  Expect.throws(() => anyF(true.toJS));

  jsFunction = ((double arg) => arg).toJS;
  expect(numF(0.toJS).toDartDouble, 0.0);
  expect(numF(0.0.toJS).toDartDouble, 0.0);
  expect(numF(0.1.toJS).toDartDouble, 0.1);
  Expect.throws(() => anyF(true.toJS));

  jsFunction = ((num arg) => arg).toJS;
  expect(numF(0.toJS).toDartInt, 0);
  expect(numF(0.0.toJS).toDartInt, 0);
  expect(numF(0.1.toJS).toDartDouble, 0.1);
  Expect.throws(() => anyF(true.toJS));

  jsFunction = ((bool arg) => arg).toJS;
  expect(boolF(true.toJS).toDart, true);
  Expect.throws(() => anyF(''.toJS));

  jsFunction = ((String arg) {}).toJS;
  voidF('voidF'.toJS);
  jsFunction = ((String arg) => arg).toJS;
  voidF('voidF'.toJS);

  eval('''
    globalThis.callFunctionWithUndefined = function() {
      return globalThis.jsFunction(undefined);
    }
    globalThis.callFunctionWithJSNull = function() {
      return globalThis.jsFunction(null);
    }
  ''');

  void expectNullPass(JSFunction f) {
    jsFunction = f;
    expect(anyF(null), null);
    expect(callFunctionWithUndefined(), null);
    expect(callFunctionWithJSNull(), null);
  }

  void expectNullFail(JSFunction f) {
    if (hasSoundNullSafety) {
      jsFunction = f;
      Expect.throws(() => anyF(null));
      Expect.throws(() => callFunctionWithUndefined());
      Expect.throws(() => callFunctionWithJSNull());
    }
  }

  expectNullPass(((String? arg) {
    expect(arg, null);
    return arg;
  }).toJS);

  expectNullPass(((JSString? arg) {
    expect(arg, null);
    return arg;
  }).toJS);

  expectNullFail(((String arg) => arg).toJS);

  expectNullFail(((JSString arg) => arg).toJS);
}
