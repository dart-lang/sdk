// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'add_async_test.dart' as add_async;
import 'add_explicit_cast_test.dart' as add_explicit_cast;
import 'add_field_formal_parameters_test.dart' as add_field_formal_parameters;
import 'add_missing_parameter_named_test.dart' as add_missing_parameter_named;
import 'add_missing_parameter_positional_test.dart'
    as add_missing_parameter_positional;
import 'add_missing_parameter_required_test.dart'
    as add_missing_parameter_required;
import 'add_missing_required_argument_test.dart'
    as add_missing_required_argument;
import 'add_static_test.dart' as add_static;
import 'change_to_static_access_test.dart' as change_to_static_access;
import 'change_type_annotation_test.dart' as change_type_annotation;
import 'convert_to_named_arguments_test.dart' as convert_to_named_arguments;
import 'extend_class_for_mixin_test.dart' as extend_class_for_mixin;
import 'replace_boolean_with_bool_test.dart' as replace_boolean_with_bool;
import 'replace_with_null_aware_test.dart' as replace_with_null_aware;

main() {
  defineReflectiveSuite(() {
    add_async.main();
    add_explicit_cast.main();
    add_field_formal_parameters.main();
    add_missing_parameter_named.main();
    add_missing_parameter_positional.main();
    add_missing_parameter_required.main();
    add_missing_required_argument.main();
    add_static.main();
    change_to_static_access.main();
    change_type_annotation.main();
    convert_to_named_arguments.main();
    extend_class_for_mixin.main();
    replace_boolean_with_bool.main();
    replace_with_null_aware.main();
  }, name: 'fix');
}
