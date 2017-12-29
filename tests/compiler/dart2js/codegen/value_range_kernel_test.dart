// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:async_helper/async_helper.dart';
import 'value_range_test_helper.dart';

main() {
  asyncTest(() async {
    // AST part tested in 'value_range_test.dart'.
    print('--test from kernel------------------------------------------------');
    await runTests(useKernel: true);
  });
}
