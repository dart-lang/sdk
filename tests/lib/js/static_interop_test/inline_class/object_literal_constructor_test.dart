// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=inline-class

@JS()
library object_literal_constructor_test;

import 'dart:js_interop';
import 'dart:js_util';

import 'package:expect/minitest.dart';

@JS()
inline class Literal {
  final JSObject obj;
  @ObjectLiteral()
  external Literal({double? a, String b = 'unused', bool? c = null});
}

@JS('Object.keys')
external JSArray objectKeys(Literal literal);

void main() {
  // Test that the properties we assumed to exist in `literal` actually exist
  // and that their values are as expected. Note that we don't check the order
  // of the keys in the literal. This is not guaranteed to be the same across
  // different backends.
  void testProperties(Literal literal, {double? a, String? b, bool? c}) {
    if (a != null) {
      expect(hasProperty(literal, 'a'), true);
      expect(getProperty<double>(literal, 'a'), a);
    }
    if (b != null) {
      expect(hasProperty(literal, 'b'), true);
      expect(getProperty<String>(literal, 'b'), b);
    }
    if (c != null) {
      expect(hasProperty(literal, 'c'), true);
      expect(getProperty<bool>(literal, 'c'), c);
    }
  }

  testProperties(Literal());
  testProperties(Literal(a: 0.0), a: 0.0);
  testProperties(Literal(b: ''), b: '');
  testProperties(Literal(c: true), c: true);

  testProperties(Literal(a: 0.0, b: ''), a: 0.0, b: '');
  testProperties(Literal(a: 0.0, c: true), a: 0.0, c: true);
  testProperties(Literal(b: '', c: true), b: '', c: true);

  testProperties(Literal(a: 0.0, b: '', c: true), a: 0.0, b: '', c: true);
  // Re-run with the same shape for dart2wasm optimization check.
  testProperties(Literal(a: 0.0, b: '', c: true), a: 0.0, b: '', c: true);
  // Test that passing in a different order doesn't change the values.
  testProperties(Literal(c: true, a: 0.0, b: ''), a: 0.0, b: '', c: true);
}
