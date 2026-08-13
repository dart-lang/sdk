// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'deferred_explicit_access_lib.dart' deferred as prefix;

main() async {
  await prefix.loadLibrary();
  expect(0, prefix.Extension.staticField);

  expect(0, prefix.Extension(0).property);
  expect(42, prefix.Extension(0).property = 42);
  expect(84, prefix.Extension(42).property);
  expect(85, prefix.Extension(43).method());

  expect(42, prefix.Extension.staticProperty);
  expect(87, prefix.Extension.staticProperty = 87);
  expect(87, prefix.Extension.staticMethod());
}

expect(expected, actual) {
  if (expected != actual) throw 'Expected $expected, actual $actual';
}
