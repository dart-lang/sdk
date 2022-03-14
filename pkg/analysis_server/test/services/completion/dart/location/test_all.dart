// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'class_body_test.dart' as class_body;
import 'enum_constant_test.dart' as enum_constant;
import 'enum_test.dart' as enum_;
import 'field_formal_parameter_test.dart' as field_formal_parameter;
import 'named_expression_test.dart' as named_expression;
import 'super_formal_parameter_test.dart' as super_formal_parameter;

/// Tests suggestions produced at specific locations.
void main() {
  defineReflectiveSuite(() {
    class_body.main();
    enum_constant.main();
    enum_.main();
    field_formal_parameter.main();
    named_expression.main();
    super_formal_parameter.main();
  });
}
