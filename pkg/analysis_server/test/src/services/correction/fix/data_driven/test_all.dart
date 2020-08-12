// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'add_type_parameter_change_test.dart' as add_type_parameter_change;
import 'rename_change_test.dart' as rename_change;

void main() {
  defineReflectiveSuite(() {
    add_type_parameter_change.main();
    rename_change.main();
  });
}
