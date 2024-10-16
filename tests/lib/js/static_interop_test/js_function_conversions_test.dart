// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Requirements=checked-implicit-downcasts

// Test that Function.toJS properly converts/casts arguments and return values
// when using non-JS types.

import 'dart:js_interop';
import 'package:expect/expect.dart';
import 'package:expect/legacy/minitest.dart'; // ignore: deprecated_member_use_from_same_package
import 'package:expect/variations.dart';

const isJSBackend = 0 is JSNumber;

const soundNullSafety = !unsoundNullSafety;

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
external JSAny? anyF([JSAny? a, JSAny? b, JSAny? c, JSAny? d, JSAny? e]);

@JS('jsFunction')
external ExternalDartReference? externalDartReferenceF(
    ExternalDartReference? e);

@JS()
external JSAny? callFunctionWithUndefined();

@JS()
external JSAny? callFunctionWithJSNull();

extension type IntE(int _) {}

extension type NullableIntE(int? _) {}

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

  // Extension type on primitives.
  jsFunction = ((IntE i) => i).toJS;
  expect(numF(0.toJS).toDartInt, 0);
  Expect.throwsWhen(soundNullSafety, () => anyF(null));
  jsFunction = ((IntE? i) => i).toJS;
  expect(numF(0.toJS).toDartInt, 0);
  expect(anyF(null), null);
  jsFunction = ((NullableIntE i) => i).toJS;
  expect(numF(0.toJS).toDartInt, 0);
  expect(anyF(null), null);

  // Test ExternalDartReference.
  Set set = {};
  jsFunction = ((ExternalDartReference<Set> arg) => arg).toJS;
  expect(externalDartReferenceF(set.toExternalReference)!.toDartObject, set);

  // However, if we try to internalize it to the wrong value, that should fail.
  // In the JS backends, it fails in the cast. In dart2wasm, it fails in the
  // internalization.
  Expect.throwsWhen(
      isJSBackend && soundNullSafety, () => externalDartReferenceF(null));
  Expect.throwsWhen(
      isJSBackend, () => externalDartReferenceF([].toExternalReference));
  Expect.throwsWhen(isJSBackend, () => anyF(''.toJS));
  jsFunction = ((ExternalDartReference<Set> arg) {
    arg.toDartObject;
  }).toJS;
  Expect.throwsWhen(soundNullSafety, () => externalDartReferenceF(null));
  Expect.throws(() => externalDartReferenceF([].toExternalReference));
  // TODO(srujzs): On dart2wasm, this is a `RuntimeError: illegal cast` because
  // of the call to `internalize`. Is there any way to first check that the
  // value can be internalized and throw if not? Would that slow down the
  // round-trip? Most likely, so just check the JS compilers for now.
  if (isJSBackend) Expect.throws(() => anyF(''.toJS));

  // Test nullability with JS null and JS undefined.
  eval('''
    globalThis.callFunctionWithUndefined = function() {
      return globalThis.jsFunction(undefined, undefined, undefined, undefined, undefined);
    }
    globalThis.callFunctionWithJSNull = function() {
      return globalThis.jsFunction(null, null, null, null, null);
    }
  ''');

  void expectNullPass(JSFunction f) {
    jsFunction = f;
    expect(anyF(null), null);
    expect(callFunctionWithUndefined(), null);
    expect(callFunctionWithJSNull(), null);
  }

  void expectNullFail(JSFunction f) {
    if (soundNullSafety) {
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
  Expect.throwsWhen(soundNullSafety, () => anyF(null));
  expect(anyF(zero), zero);
  setBoundAnyFunction<JSNumber>();
  Expect.throwsWhen(soundNullSafety, () => anyF(null));
  Expect.throws(() {
    final any = anyF(empty);
    // TODO(54179): Better way of writing this is to cast to JSNumber and
    // convert, but currently that does not throw on dart2wasm.
    if (!any.isA<JSNumber>()) throw TypeError();
  });
  expect(anyF(zero), zero);

  void setBoundNonNullAnyFunction<T extends JSAny>() {
    jsFunction = ((T t) => t).toJS;
  }

  setBoundNonNullAnyFunction();
  Expect.throwsWhen(soundNullSafety, () => anyF(null));
  expect(anyF(zero), zero);
  setBoundNonNullAnyFunction<JSNumber>();
  Expect.throwsWhen(soundNullSafety, () => anyF(null));
  Expect.throws(() {
    final any = anyF(empty);
    // TODO(54179): Better way of writing this is to cast to JSNumber and
    // convert, but currently that does not throw on dart2wasm.
    if (!any.isA<JSNumber>()) throw TypeError();
  });
  expect(anyF(zero), zero);

  void setBoundJSNumberFunction<T extends JSNumber>() {
    jsFunction = ((T t) => t).toJS;
  }

  setBoundJSNumberFunction();
  Expect.throwsWhen(soundNullSafety, () => anyF(null));
  Expect.throws(() {
    final any = anyF(empty);
    // TODO(54179): Better way of writing this is to cast to JSNumber and
    // convert, but currently that does not throw on dart2wasm.
    if (!any.isA<JSNumber>()) throw TypeError();
  });
  expect(anyF(zero), zero);

  void setBoundNonNullAnyMultipleParametersFunction<T extends JSAny,
      U extends JSAny, V extends JSAny>({bool captureThis = false}) {
    if (captureThis) {
      jsFunction = ((T this_, U u, [V? v]) => this_).toJSCaptureThis;
    } else {
      jsFunction = ((T t, U u, [V? v]) => t).toJS;
    }
  }

  setBoundNonNullAnyMultipleParametersFunction();
  Expect.throwsWhen(soundNullSafety, () => anyF(null, zero, zero));
  Expect.throwsWhen(soundNullSafety, () => anyF(zero, null, zero));
  anyF(zero, zero, null);
  anyF(zero, zero, zero);

  setBoundNonNullAnyMultipleParametersFunction(captureThis: true);
  Expect.throwsWhen(soundNullSafety, () => anyF(null, zero));
  anyF(zero, null);
  anyF(zero, zero);
  // TODO(srujzs): It'd be nice if we can test that passing a null value for
  // `this` throws. However, unless we're in strict mode, that isn't possible
  // on all backends. While we can define local functions in strict mode, the
  // wrapping of the function when converting a Dart function to JS may not be
  // in a strict mode context, and therefore `this` will still be non-nullable.
  // https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Function/call#thisarg

  void setBoundExternalDartReference<T extends ExternalDartReference<U>?, U>() {
    jsFunction = ((T t) => t?.toDartObject.toExternalReference).toJS;
  }

  setBoundExternalDartReference<ExternalDartReference<Object?>, Object?>();
  expect(externalDartReferenceF(null), null);
  expect(externalDartReferenceF(0.toExternalReference)!.toDartObject, 0);
  setBoundExternalDartReference<ExternalDartReference<Object>?, Object>();
  expect(externalDartReferenceF(null), null);
  expect(externalDartReferenceF(0.toExternalReference)!.toDartObject, 0);

  void setBoundNonNullExternalDartReference<T extends ExternalDartReference<U>,
      U>() {
    jsFunction = ((T t) => t.toDartObject.toExternalReference).toJS;
  }

  setBoundNonNullExternalDartReference<ExternalDartReference<Object>, Object>();
  Expect.throwsWhen(soundNullSafety, () => externalDartReferenceF(null));
  expect(externalDartReferenceF(0.toExternalReference)!.toDartObject, 0);

  // Test that type parameters local to the expression can still be casted to.
  T Function(T) getF<T extends JSAny?>() {
    return (T t) => t;
  }

  jsFunction = (getF<JSAny>()).toJS;
  Expect.throwsWhen(soundNullSafety, () => anyF(null));
  anyF(zero);
  jsFunction = ((<T extends JSAny?>() => (T t) => t)<JSAny>()).toJS;
  Expect.throwsWhen(soundNullSafety, () => anyF(null));
  anyF(zero);

  // Make sure function expression is only evaluated once in lowerings.
  var evalCount = 0;
  jsFunction = (() {
    evalCount++;
    return () {};
  }())
      .toJS;
  anyF();
  anyF();
  expect(evalCount, 1);
}
