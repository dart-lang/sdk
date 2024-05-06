// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test `dart:js_interop`'s `isA` method with library renames.

@JS('library1.library2')
library;

import 'dart:js_interop';

import 'package:expect/expect.dart';

import 'functional_test.dart' as functional_test;

extension type Date._(JSObject _) implements JSObject {
  external Date();
}

@JS('Date')
extension type RenamedDate._(JSObject _) implements JSObject {
  external RenamedDate();
}

void main() {
  functional_test.eval('''
    globalThis.library1 = {};
    globalThis.library1.library2 = {};
    globalThis.library1.library2.Date = function Date() {}
  ''');

  final date = Date();
  final unscopedDate = functional_test.Date();
  Expect.isTrue(date.isA<Date>());
  Expect.isTrue(date.isA<Date?>());
  Expect.isFalse(unscopedDate.isA<Date>());
  Expect.isFalse(unscopedDate.isA<Date?>());
  Expect.isFalse(date.isA<functional_test.Date>());
  Expect.isFalse(date.isA<functional_test.Date?>());
  Expect.isTrue(date.isA<JSObject>());
  Expect.isTrue(date.isA<JSObject?>());

  final renamedDate = RenamedDate();
  Expect.isTrue(renamedDate.isA<RenamedDate>());
  Expect.isTrue(renamedDate.isA<RenamedDate?>());
  Expect.isTrue(date.isA<RenamedDate>());
  Expect.isTrue(date.isA<RenamedDate?>());
  Expect.isTrue(renamedDate.isA<Date>());
  Expect.isTrue(renamedDate.isA<Date?>());
  Expect.isFalse(unscopedDate.isA<RenamedDate>());
  Expect.isFalse(unscopedDate.isA<RenamedDate?>());
  Expect.isFalse(renamedDate.isA<functional_test.Date>());
  Expect.isFalse(renamedDate.isA<functional_test.Date?>());
}
