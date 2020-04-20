// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'from_environment_evaluator_test.dart' as declared_variables;
import 'utilities_test.dart' as utilities;

main() {
  defineReflectiveSuite(() {
    declared_variables.main();
    utilities.main();
  }, name: 'analysis');
}
