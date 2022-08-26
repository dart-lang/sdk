// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'import_via_prefix_lib.dart' as prefix;

main() {
  expect(3, "foo".method());
}

expect(expected, actual) {
  if (expected != actual) throw "Expected $expected, actual $actual";
}
