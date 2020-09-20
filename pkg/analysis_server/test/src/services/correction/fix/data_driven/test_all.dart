// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'add_type_parameter_test.dart' as add_type_parameter_change;
import 'code_template_test.dart' as code_template;
import 'diagnostics/test_all.dart' as diagnostics;
import 'end_to_end_test.dart' as end_to_end;
import 'modify_parameters_test.dart' as modify_parameters;
import 'rename_test.dart' as rename_change;
import 'transform_set_manager_test.dart' as transform_set_manager;
import 'transform_set_parser_test.dart' as transform_set_parser;

void main() {
  defineReflectiveSuite(() {
    add_type_parameter_change.main();
    code_template.main();
    diagnostics.main();
    end_to_end.main();
    modify_parameters.main();
    rename_change.main();
    transform_set_manager.main();
    transform_set_parser.main();
  });
}
