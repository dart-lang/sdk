// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.src.dart.constant.test_all;

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'evaluation_test.dart' as evaluation;
import 'utilities_test.dart' as utilities;
import 'value_test.dart' as value;

/// Utility for manually running all tests.
main() {
  defineReflectiveSuite(() {
    evaluation.main();
    utilities.main();
    value.main();
  }, name: 'constant');
}
