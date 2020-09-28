// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'invalid_value_one_of_test.dart' as invalid_value_one_of;
import 'invalid_value_test.dart' as invalid_value;
import 'missing_key_test.dart' as missing_key;
import 'missing_template_end_test.dart' as missing_template_end;
import 'undefined_variable_test.dart' as undefined_variable;
import 'unsupported_key_test.dart' as unsupported_key;
import 'yaml_syntax_error_test.dart' as yaml_syntax_error;

void main() {
  defineReflectiveSuite(() {
    invalid_value_one_of.main();
    invalid_value.main();
    missing_key.main();
    missing_template_end.main();
    undefined_variable.main();
    unsupported_key.main();
    yaml_syntax_error.main();
  });
}
