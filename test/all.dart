// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:unittest/unittest.dart';

import 'linter_test.dart' as linter_test;
import 'pub_test.dart' as pub_test;

main() {
  // Tidy up the unittest output.
  filterStacks = true;
  formatStacks = true;
  // useCompactVMConfiguration();

  linter_test.main();
  pub_test.main();
}
