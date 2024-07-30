// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Requirements=checked-implicit-downcasts

import 'dart:js_interop';

import 'package:expect/expect.dart';
import 'package:expect/variations.dart';

final bool isJSBackend = 1 is ExternalDartReference<int>;

extension type EExternalDartReference<T>(ExternalDartReference<T> _)
    implements ExternalDartReference<T> {}

@JS()
external ExternalDartReference<Object> externalDartReference;

@JS()
external EExternalDartReference<DartClass> eExternalDartReference;

@JS('externalDartReference')
external ExternalDartReference<Object?> externalDartNullableReference;

@JS('externalDartReference')
external ExternalDartReference<Object>? nullableExternalDartReference;

// Use a function so that we can use a type parameter that extends an
// `ExternalDartReference` type.
@JS('identity')
external set _identity(JSFunction _);
@JS()
external T identity<T extends ExternalDartReference?>(T t);

extension type ObjectLiteral(JSObject _) {
  external void operator []=(String key, ExternalDartReference<Object> value);
}

class DartClass {
  int field;

  DartClass(this.field);
}

class DartSubclass extends DartClass {
  DartSubclass(super.field);
}

void generalTest() {
  var dartObject = DartClass(42);

  // `Object` test.
  externalDartReference = dartObject.toExternalReference;
  Expect.equals(dartObject, externalDartReference.toDartObject as DartClass);
  Expect.identical(dartObject, externalDartReference.toDartObject as DartClass);

  // Generic test.
  var externalDartClassReference = dartObject.toExternalReference;
  Expect.equals(dartObject, externalDartClassReference.toDartObject);
  Expect.identical(dartObject, externalDartClassReference.toDartObject);
  // Ensure we get assignability.
  dartObject = externalDartClassReference.toDartObject;

  // Check that we do the right thing with extension types on
  // `ExternalDartReference`.
  eExternalDartReference = EExternalDartReference(externalDartClassReference);
  Expect.equals(dartObject, eExternalDartReference.toDartObject);
  Expect.identical(dartObject, eExternalDartReference.toDartObject);

  // Check that `ExternalDartReference` can be used as a parameter and return
  // type for `Function.toJS`'d functions.
  _identity = ((ExternalDartReference<DartClass> e) => e).toJS;
  final externalDartReferenceTypeParam = identity(eExternalDartReference);
  Expect.equals(dartObject, externalDartReferenceTypeParam.toDartObject);
  Expect.identical(dartObject, externalDartReferenceTypeParam.toDartObject);

  // Multiple invocations should return the same underlying value, which is
  // tested by `==`.
  Expect.equals(externalDartReference, dartObject.toExternalReference);
  // However, they may or may not be identical depending on the compiler due to
  // dart2wasm wrapping values with new JSValue instances.
  if (isJSBackend) {
    Expect.identical(externalDartReference, dartObject.toExternalReference);
  } else {
    Expect.isFalse(
        identical(externalDartReference, dartObject.toExternalReference));
  }

  // We don't validate that the input is a Dart object or a JS value as that may
  // be expensive to validate. We end up externalizing the JSValue wrapper in
  // this case.
  final jsString = ''.toJS;
  Expect.equals(jsString.toExternalReference.toDartObject, jsString);
  Expect.identical(jsString.toExternalReference.toDartObject, jsString);

  // Check that the type is checked when internalized for soundness.
  externalDartReference = dartObject.toExternalReference;
  Expect.throws(
      () => (externalDartReference as ExternalDartReference<DartSubclass>)
          // The cast is deferred until `toDartObject` for dart2wasm, so call it
          // explicitly.
          .toDartObject);

  _identity = ((ExternalDartReference<DartSubclass> et) =>
      et.toDartObject.toExternalReference).toJS;
  Expect.throws(() => identity(externalDartReference));

  // Check that we do the right thing with nullability still, both in the type
  // parameter and outside it.
  _identity = ((ExternalDartReference<Object> et) =>
      et.toDartObject.toExternalReference).toJS;
  nullableExternalDartReference = null?.toExternalReference;
  Expect.isTrue(nullableExternalDartReference == null);
  Expect.throwsWhen(
      !unsoundNullSafety, () => externalDartReference.toDartObject);
  Expect.throwsWhen(
      !unsoundNullSafety, () => identity(nullableExternalDartReference));
  externalDartNullableReference = null.toExternalReference;
  Expect.isTrue(externalDartNullableReference == null);
  Expect.throwsWhen(
      !unsoundNullSafety, () => externalDartReference.toDartObject);
  Expect.throwsWhen(
      !unsoundNullSafety, () => identity(externalDartNullableReference));
  // Check that they're both Dart `null`.
  Expect.identical(
      nullableExternalDartReference, externalDartNullableReference);

  // Functions should not trigger `assertInterop`.
  externalDartReference = () {}.toExternalReference;
  identity(EExternalDartReference(() {}.toExternalReference));
  ObjectLiteral(JSObject())['ref'] = externalDartReference;
}

// An example interface for a generic `WritableSignal` from
// https://angular.dev/guide/signals that avoids unnecessary casts and wrapper
// functions in the JS compilers. The functions are stubbed to just test casts
// and assignability.
extension type WritableSignal<T>(JSFunction _) {
  void _set(ExternalDartReference<T> value) {}

  void set(T value) => _set(value.toExternalReference);

  void _update(JSExportedDartFunction update) {}

  void update(T Function(T) function) {
    // Because `ExternalDartReference<T>`s are `T` on the JS backends, we can
    // avoid the wrapper function that is needed for dart2wasm. If we want code
    // that is guaranteed to work on all backends, the wrapper function will
    // work, but will be slower on the JS backends. See
    // https://github.com/dart-lang/sdk/issues/55342 for more details.
    if (isJSBackend) {
      _update((function as ExternalDartReference<T> Function(
              ExternalDartReference<T>))
          .toJS);
    }
    // Should work on all backends.
    _update(((ExternalDartReference<T> e) =>
        function(e.toDartObject).toExternalReference).toJS);
  }
}

WritableSignal<T> signal<T>(T initialValue) =>
    WritableSignal<T>((() => initialValue.toExternalReference).toJS);

void signalsTest() {
  final writableSignal = signal<Object?>(0);
  writableSignal.set(null);
  writableSignal.set(true);
  writableSignal.set(DartClass(42));
  writableSignal.update((Object? x) => x);
  writableSignal.update((_) => false);
  writableSignal.update((Object? _) => null);
  final writableIntSignal = signal(null as int?);
  writableIntSignal.set(null);
  writableIntSignal.set(0);
  writableIntSignal.update((int? x) => x);
  writableIntSignal.update((int? _) => null);
  writableIntSignal.update((num? _) => 0);
  final writableDartSignal = signal<DartClass?>(DartClass(42));
  writableDartSignal.set(null);
  writableDartSignal.set(DartSubclass(42));
  writableDartSignal.update((DartClass? x) => x);
  writableDartSignal.update((DartClass? x) => x as DartSubclass);
  writableDartSignal.update((Object? _) => DartClass(42));
}

void main() {
  generalTest();
  signalsTest();
}
