// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'add_type_parameter_test.dart' as add_type_parameter_change;
import 'modify_parameters_test.dart' as modify_parameters;
import 'rename_test.dart' as rename_change;

void main() {
  defineReflectiveSuite(() {
    add_type_parameter_change.main();
    modify_parameters.main();
    rename_change.main();
  });
}
