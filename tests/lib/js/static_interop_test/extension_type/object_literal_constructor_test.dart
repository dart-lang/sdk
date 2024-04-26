// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library object_literal_constructor_test;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:expect/minitest.dart'; // ignore: deprecated_member_use_from_same_package

extension type Literal._(JSObject _) implements JSObject {
  external Literal({double? a, String b, bool? c});
  external factory Literal.fact({double? a, String b, bool? c});
}

// Test that the properties we assumed to exist in `literal` actually exist and
// that their values are as expected. If we assumed they don't exist, check that
// they do not. Note that we don't check the order of the keys in the literal.
// This is not guaranteed to be the same across different backends.
void testProperties(JSObject literal, {double? a, String? b, bool? c}) {
  if (a != null) {
    expect(literal.has('a'), true);
    expect((literal['a'] as JSNumber).toDartDouble, a);
  } else {
    expect(literal.has('a'), false);
  }
  if (b != null) {
    expect(literal.has('b'), true);
    expect((literal['b'] as JSString).toDart, b);
  } else {
    expect(literal.has('b'), false);
  }
  if (c != null) {
    expect(literal.has('c'), true);
    expect((literal['c'] as JSBoolean).toDart, c);
  } else {
    expect(literal.has('c'), false);
  }
}

void main() {
  testProperties(Literal());
  testProperties(Literal.fact(a: 0.0), a: 0.0);
  testProperties(Literal(b: ''), b: '');
  testProperties(Literal.fact(c: true), c: true);

  testProperties(Literal(a: 0.0, b: ''), a: 0.0, b: '');
  testProperties(Literal.fact(a: 0.0, c: true), a: 0.0, c: true);
  testProperties(Literal(b: '', c: true), b: '', c: true);

  testProperties(Literal.fact(a: 0.0, b: '', c: true), a: 0.0, b: '', c: true);
  // Re-run with the same shape for dart2wasm optimization check.
  testProperties(Literal(a: 0.0, b: '', c: true), a: 0.0, b: '', c: true);
  // Test that passing in a different order doesn't change the values.
  testProperties(Literal.fact(c: true, a: 0.0, b: ''), a: 0.0, b: '', c: true);
}
