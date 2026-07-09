// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'deferred_explicit_access_lib.dart' deferred as prefix hide Extension;

main() async {
  await prefix.loadLibrary();
  expect(0, prefix.topLevelField);
  expect(42, prefix.topLevelField = 42);
  expect(42, prefix.topLevelField);

  expect(0, prefix.topLevelProperty);
  expect(87, prefix.topLevelProperty = 87);
  expect(87, prefix.topLevelProperty);
  expect(87, prefix.topLevelMethod());
}

expect(expected, actual) {
  if (expected != actual) throw 'Expected $expected, actual $actual';
}
