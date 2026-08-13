// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'b_lib.dart';

main() {
  var bInst = B();
  expect(2.71, bInst.d);
  expect('default', bInst.doStringy('DEFAULT'));
}

expect(expected, actual) {
  if (expected != actual) throw 'Expected $expected, actual $actual.';
}
