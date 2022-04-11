// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'const_lib.dart';

const crossModule = B();

main() {
  expect(2.71, crossModule.d);
  expect('default', crossModule.s);
}

expect(expected, actual) {
  if (expected != actual) throw 'Expected $expected, actual $actual';
}
