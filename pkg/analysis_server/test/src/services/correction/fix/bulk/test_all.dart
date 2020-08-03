// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'add_override_test.dart' as add_override;
import 'convert_documentation_into_line_test.dart'
    as convert_documentation_into_line;
import 'convert_to_contains_test.dart' as convert_to_contains;
import 'create_method_test.dart' as create_method;
import 'remove_argument_test.dart' as remove_argument;
import 'remove_await_test.dart' as remove_await;
import 'remove_duplicate_case_test.dart' as remove_duplicate_case;
import 'remove_empty_catch_test.dart' as remove_empty_catch;
import 'remove_empty_constructor_body_test.dart'
    as remove_empty_constructor_body;
import 'remove_empty_else_test.dart' as remove_empty_else;
import 'remove_empty_statement_test.dart' as remove_empty_statement;
import 'remove_initializer_test.dart' as remove_initializer;
import 'remove_type_annotation_test.dart' as remove_type_annotation;
import 'remove_unnecessary_const_test.dart' as remove_unnecessary_const;
import 'remove_unnecessary_new_test.dart' as remove_unnecessary_new;
import 'replace_colon_with_equals_test.dart' as replace_colon_with_equals;
import 'replace_null_with_closure_test.dart' as replace_null_with_closure;
import 'replace_with_var_test.dart' as replace_with_var;
import 'use_curly_braces_test.dart' as use_curly_braces;

void main() {
  defineReflectiveSuite(() {
    add_override.main();
    convert_documentation_into_line.main();
    convert_to_contains.main();
    create_method.main();
    remove_argument.main();
    remove_await.main();
    remove_duplicate_case.main();
    remove_initializer.main();
    remove_empty_catch.main();
    remove_empty_constructor_body.main();
    remove_empty_else.main();
    remove_empty_statement.main();
    remove_type_annotation.main();
    remove_unnecessary_const.main();
    remove_unnecessary_new.main();
    replace_colon_with_equals.main();
    replace_null_with_closure.main();
    replace_with_var.main();
    use_curly_braces.main();
  }, name: 'bulk');
}
