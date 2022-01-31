// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'field_formal_parameter_test.dart' as field_formal_parameter;
import 'super_formal_parameter_test.dart' as super_formal_parameter;

/// Tests suggestions produced at specific locations.
void main() {
  defineReflectiveSuite(() {
    field_formal_parameter.main();
    super_formal_parameter.main();
  });
}
