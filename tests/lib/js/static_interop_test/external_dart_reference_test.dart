// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Requirements=checked-implicit-downcasts

import 'dart:js_interop';

import 'package:expect/expect.dart';

const isJSBackend = const bool.fromEnvironment('dart.library.html');

extension type EExternalDartReference(ExternalDartReference _)
    implements ExternalDartReference {}

@JS()
external ExternalDartReference externalDartReference;

@JS()
external EExternalDartReference eExternalDartReference;

@JS('externalDartReference')
external ExternalDartReference? nullableExternalDartReference;

// Use a function so that we can use a type parameter that extends an
// `ExternalDartReference` type.
@JS('identity')
external set _identity(JSFunction _);
@JS()
external T identity<T extends EExternalDartReference>(T t);

extension type ObjectLiteral(JSObject _) {
  external void operator []=(String key, ExternalDartReference value);
}

class DartClass {
  int field;

  DartClass(this.field);
}

void main() {
  final dartObject = DartClass(42);

  externalDartReference = dartObject.toExternalReference;
  Expect.equals(dartObject, externalDartReference.toDartObject as DartClass);
  Expect.isTrue(
      identical(dartObject, externalDartReference.toDartObject as DartClass));
  eExternalDartReference = EExternalDartReference(externalDartReference);
  Expect.equals(dartObject, eExternalDartReference.toDartObject as DartClass);
  Expect.isTrue(
      identical(dartObject, eExternalDartReference.toDartObject as DartClass));
  _identity = ((ExternalDartReference e) => e).toJS;
  final externalDartReferenceTypeParam = identity(eExternalDartReference);
  Expect.equals(
      dartObject, externalDartReferenceTypeParam.toDartObject as DartClass);
  Expect.isTrue(identical(
      dartObject, externalDartReferenceTypeParam.toDartObject as DartClass));

  // Multiple invocations should return the same underlying value, which is
  // tested by `==`.
  Expect.equals(externalDartReference, dartObject.toExternalReference);
  // However, they may or may not be identical depending on the compiler due to
  // dart2wasm wrapping values with new JSValue instances.
  if (isJSBackend) {
    Expect.isTrue(
        identical(externalDartReference, dartObject.toExternalReference));
  } else {
    Expect.isFalse(
        identical(externalDartReference, dartObject.toExternalReference));
  }

  final jsString = ''.toJS;
  // We don't validate that the input is a Dart object or a JS value as that may
  // be expensive to validate. We end up externalizing the JSValue wrapper in
  // this case.
  Expect.equals(jsString.toExternalReference.toDartObject, jsString);
  Expect.isTrue(identical(jsString.toExternalReference.toDartObject, jsString));

  // Check that we do the right thing with nullability still.
  nullableExternalDartReference = null;
  if (hasSoundNullSafety) Expect.throws(() => externalDartReference);

  // Functions should not trigger `assertInterop`.
  externalDartReference = () {}.toExternalReference;
  identity(EExternalDartReference(() {}.toExternalReference));
  final literal = ObjectLiteral(JSObject());
  literal['ref'] = externalDartReference;
}
