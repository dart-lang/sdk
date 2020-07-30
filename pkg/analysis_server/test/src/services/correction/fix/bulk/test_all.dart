// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'add_override_test.dart' as add_override;
import 'convert_documentation_into_line_test.dart'
    as convert_documentation_into_line;
import 'convert_to_contains_test.dart' as convert_to_contains;
import 'remove_argument_test.dart' as remove_argument;
import 'remove_empty_else_test.dart' as remove_empty_else;
import 'remove_initializer_test.dart' as remove_initializer;
import 'remove_type_annotation_test.dart' as remove_type_annotation;
import 'remove_unnecessary_const_test.dart' as remove_unnecessary_const;
import 'remove_unnecessary_new_test.dart' as remove_unnecessary_new;
import 'replace_colon_with_equals_test.dart' as replace_colon_with_equals;

void main() {
  defineReflectiveSuite(() {
    add_override.main();
    convert_documentation_into_line.main();
    convert_to_contains.main();
    remove_argument.main();
    remove_initializer.main();
    remove_empty_else.main();
    remove_type_annotation.main();
    remove_unnecessary_const.main();
    remove_unnecessary_new.main();
    replace_colon_with_equals.main();
  }, name: 'bulk');
}
