// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@JS('library1')
library;

import 'dart:js_interop';

extension type CustomJSAny(JSAny _) implements JSAny {}

extension type CustomJSObject(JSObject _) implements JSObject {}

extension type CustomTypedArray(JSTypedArray _) implements JSObject {}

@JS('RenamedJSArray')
extension type CustomJSArray(JSArray _) implements JSObject {}

void test(JSAny any) {
  // Top type.
  any.isA<JSAny>();
  any.isA<JSAny?>();

  // Primitives.
  any.isA<JSString>();
  any.isA<JSString?>();
  any.isA<JSNumber>();
  any.isA<JSBoolean>();
  any.isA<JSSymbol>();
  any.isA<JSBigInt>();

  // Objects.
  any.isA<JSObject>();
  any.isA<JSObject?>();
  any.isA<JSArray>();
  // JSTypedArray is handled differently.
  any.isA<JSTypedArray>();

  // User-defined types.
  any.isA<CustomJSAny>();
  any.isA<CustomJSObject>();
  any.isA<CustomTypedArray>();
  any.isA<CustomJSArray>();

  // Non-variable expression should avoid evaluating twice.
  () {
    return any;
  }()
      .isA<JSAny>();
}

void main() {}
