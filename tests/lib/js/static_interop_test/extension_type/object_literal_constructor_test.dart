// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library object_literal_constructor_test;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:expect/expect.dart';

extension type Literal._(JSObject _) implements JSObject {
  external Literal({double? a, String b, bool? c});
  external factory Literal.fact({double? a, String b, bool? c});
}

extension type NamedKeysLiteral._(JSObject _) implements JSObject {
  external NamedKeysLiteral({@JS('a') double? namedA, @JS('b') String namedB});
}

extension type OriginalNamesLiteral._(JSObject _) implements JSObject {
  external OriginalNamesLiteral({@JS() double? a, @JS('') String b});
}

// Test that the properties we assumed to exist in `literal` actually exist and
// that their values are as expected. If we assumed they don't exist, check that
// they do not. Note that we don't check the order of the keys in the literal.
// This is not guaranteed to be the same across different backends.
void testProperties(JSObject literal, {double? a, String? b, bool? c}) {
  if (a != null) {
    Expect.isTrue(literal.has('a'));
    Expect.equals(a, (literal['a'] as JSNumber).toDartDouble);
  } else {
    Expect.isFalse(literal.has('a'));
  }
  if (b != null) {
    Expect.isTrue(literal.has('b'));
    Expect.equals(b, (literal['b'] as JSString).toDart);
  } else {
    Expect.isFalse(literal.has('b'));
  }
  if (c != null) {
    Expect.isTrue(literal.has('c'));
    Expect.equals(c, (literal['c'] as JSBoolean).toDart);
  } else {
    Expect.isFalse(literal.has('c'));
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

  testProperties(NamedKeysLiteral(namedA: 0.0), a: 0.0);
  testProperties(NamedKeysLiteral(namedA: 1.0, namedB: 'b'), a: 1.0, b: 'b');

  testProperties(OriginalNamesLiteral(a: 0.0), a: 0.0);
  testProperties(OriginalNamesLiteral(a: 0.0, b: 'b'), a: 0.0, b: 'b');
}
