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
external JSAny? anyF([JSAny? n]);

@JS()
external JSAny? callFunctionWithUndefined();

@JS()
external JSAny? callFunctionWithJSNull();

void main() {
  // Test primitive conversions.
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

  // Test nullability with JS null and JS undefined.
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

  // Test conversions with allowed type parameters.
  void setBoundAnyFunction<T extends JSAny?>() {
    jsFunction = ((T t) => t).toJS;
  }

  final zero = 0.toJS;
  final empty = ''.toJS;

  setBoundAnyFunction();
  expect(anyF(null), null);
  expect(anyF(zero), zero);
  setBoundAnyFunction<JSAny>();
  // TODO(srujzs): The commented out null checks do not throw. There should be a
  // check within the body of the callback that the parameter is the right
  // generic type, but there isn't.
  // Expect.throws(() => anyF());
  // Expect.throws(() => anyF(null));
  expect(anyF(zero), zero);
  setBoundAnyFunction<JSNumber>();
  // Expect.throws(() => anyF(null));
  Expect.throws(() {
    final any = anyF(empty);
    // TODO(54179): Better way of writing this is to cast to JSNumber and
    // convert, but currently that does not throw on dart2wasm.
    if (!any.typeofEquals('number')) {
      throw TypeError();
    }
  });
  expect(anyF(zero), zero);

  void setBoundNonNullAnyFunction<T extends JSAny>() {
    jsFunction = ((T t) => t).toJS;
  }

  setBoundNonNullAnyFunction();
  Expect.throws(() => anyF());
  if (hasSoundNullSafety) Expect.throws(() => anyF(null));
  expect(anyF(zero), zero);
  setBoundNonNullAnyFunction<JSNumber>();
  if (hasSoundNullSafety) Expect.throws(() => anyF(null));
  Expect.throws(() {
    final any = anyF(empty);
    // TODO(54179): Better way of writing this is to cast to JSNumber and
    // convert, but currently that does not throw on dart2wasm.
    if (!any.typeofEquals('number')) {
      throw TypeError();
    }
  });
  expect(anyF(zero), zero);

  void setBoundJSNumberFunction<T extends JSNumber>() {
    jsFunction = ((T t) => t).toJS;
  }

  setBoundJSNumberFunction();
  Expect.throws(() => anyF());
  if (hasSoundNullSafety) Expect.throws(() => anyF(null));
  Expect.throws(() {
    final any = anyF(empty);
    // TODO(54179): Better way of writing this is to cast to JSNumber and
    // convert, but currently that does not throw on dart2wasm.
    if (!any.typeofEquals('number')) {
      throw TypeError();
    }
  });
  expect(anyF(zero), zero);
}
