// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test was adapted from language_2/await_in_cascade_  test

import 'dart:async';

class C {
  Future<List<int>> m() async => []..add(await _m());
  Future<int> _m() async => 42;
}

main() async {
  expect(42, (await new C().m()).first);
}

expect(expected, actual) {
  if (expected != actual) throw 'Expected $expected, actual $actual';
}
