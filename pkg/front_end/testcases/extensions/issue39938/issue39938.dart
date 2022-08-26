// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'issue39938_lib.dart';

main() {
  expect(true, true + true);
  expect(true, true + false);
  expect(true, false + true);
  expect(false, false + false);
  expect(true, Extension(true) + true);
  expect(true, Extension(true) + false);
  expect(true, Extension(false) + true);
  expect(false, Extension(false) + false);
}

expect(expected, actual) {
  if (expected != actual) throw 'Expected $expected, actual $actual.';
}
