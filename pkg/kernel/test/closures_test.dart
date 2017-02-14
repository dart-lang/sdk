// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

library test.kernel.closures_test;

import 'package:test/test.dart' show Timeout, test;

import 'package:testing/testing.dart' show run;

main() {
  test("closures",
      () => run([], ["closures"], "pkg/kernel/test/closures/testing.json"),
      timeout: new Timeout(new Duration(minutes: 5)));
}
