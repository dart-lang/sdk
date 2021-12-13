// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'add_type_parameter_test.dart' as add_type_parameter;
import 'code_fragment_parser_test.dart' as code_fragment_parser;
import 'code_template_test.dart' as code_template;
import 'data_driven_test.dart' as data_driven;
import 'diagnostics/test_all.dart' as diagnostics;
import 'element_matcher_test.dart' as element_matcher;
import 'end_to_end_test.dart' as end_to_end;
import 'flutter_use_case_test.dart' as flutter_use_case;
import 'modify_parameters_test.dart' as modify_parameters;
import 'rename_parameter_test.dart' as rename_parameter;
import 'rename_test.dart' as rename;
import 'replaced_by_test.dart' as replaced_by;
import 'sdk_fix_test.dart' as sdk_fix;
import 'transform_override_set_parser_test.dart'
    as transform_override_set_parser;
import 'transform_set_manager_test.dart' as transform_set_manager;
import 'transform_set_parser_test.dart' as transform_set_parser;

void main() {
  defineReflectiveSuite(() {
    add_type_parameter.main();
    code_fragment_parser.main();
    code_template.main();
    data_driven.main();
    diagnostics.main();
    element_matcher.main();
    end_to_end.main();
    flutter_use_case.main();
    modify_parameters.main();
    rename_parameter.main();
    rename.main();
    replaced_by.main();
    sdk_fix.main();
    transform_override_set_parser.main();
    transform_set_manager.main();
    transform_set_parser.main();
  });
}
