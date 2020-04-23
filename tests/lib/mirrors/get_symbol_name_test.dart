// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:mirrors' show MirrorSystem;

expect(expected, actual) {
  if (expected != actual) {
    throw 'Expected: "$expected", but got "$actual"';
  }
}

main() {
  expect('fisk', MirrorSystem.getName(const Symbol('fisk')));
  expect('fisk', MirrorSystem.getName(new Symbol('fisk')));
}
