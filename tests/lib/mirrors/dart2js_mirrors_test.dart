// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test should be removed when dart2js can pass all mirror tests.
// TODO(ahe): Remove this test.

import 'mirrors_test.dart' as test;

main() {
  test.isDart2js = true;
  test.main();
}
