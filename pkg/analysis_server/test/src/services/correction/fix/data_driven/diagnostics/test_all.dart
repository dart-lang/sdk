// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'conflicting_key_test.dart' as conflicting_key;
import 'expected_primary_test.dart' as expected_primary;
import 'invalid_character_test.dart' as invalid_character;
import 'invalid_key_test.dart' as invalid_key;
import 'invalid_parameter_style_test.dart' as invalid_parameter_style;
import 'invalid_required_if_test.dart' as invalid_required_if;
import 'invalid_value_one_of_test.dart' as invalid_value_one_of;
import 'invalid_value_test.dart' as invalid_value;
import 'missing_key_test.dart' as missing_key;
import 'missing_one_of_multiple_keys_test.dart' as missing_one_of_multiple_keys;
import 'missing_template_end_test.dart' as missing_template_end;
import 'missing_token_test.dart' as missing_token;
import 'missing_uri_test.dart' as missing_uri;
import 'undefined_variable_test.dart' as undefined_variable;
import 'unexpected_token_test.dart' as unexpected_token;
import 'unknown_accessor_test.dart' as unknown_accessor;
import 'unsupported_key_test.dart' as unsupported_key;
import 'unsupported_version_test.dart' as unsupported_version;
import 'wrong_token_test.dart' as wrong_token;
import 'yaml_syntax_error_test.dart' as yaml_syntax_error;

void main() {
  defineReflectiveSuite(() {
    conflicting_key.main();
    expected_primary.main();
    invalid_character.main();
    invalid_key.main();
    invalid_parameter_style.main();
    invalid_required_if.main();
    invalid_value_one_of.main();
    invalid_value.main();
    missing_key.main();
    missing_one_of_multiple_keys.main();
    missing_template_end.main();
    missing_token.main();
    missing_uri.main();
    undefined_variable.main();
    unexpected_token.main();
    unknown_accessor.main();
    unsupported_key.main();
    unsupported_version.main();
    wrong_token.main();
    yaml_syntax_error.main();
  });
}
