// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'block_test.dart' as block;
import 'case_clause_test.dart' as case_clause;
import 'class_body_test.dart' as class_body;
import 'compilation_unit_test.dart' as compilation_unit;
import 'directive_uri_test.dart' as directive_uri;
import 'enum_constant_test.dart' as enum_constant;
import 'enum_test.dart' as enum_;
import 'field_formal_parameter_test.dart' as field_formal_parameter;
import 'if_element_test.dart' as if_element;
import 'if_statement_test.dart' as if_statement;
import 'named_expression_test.dart' as named_expression;
import 'record_literal_test.dart' as record_literal;
import 'record_pattern_test.dart' as record_pattern;
import 'record_type_annotation_test.dart' as record_type_annotation;
import 'super_formal_parameter_test.dart' as super_formal_parameter;
import 'switch_pattern_case_test.dart' as switch_pattern_case;

/// Tests suggestions produced at specific locations.
void main() {
  defineReflectiveSuite(() {
    block.main();
    case_clause.main();
    class_body.main();
    compilation_unit.main();
    directive_uri.main();
    enum_constant.main();
    enum_.main();
    field_formal_parameter.main();
    if_element.main();
    if_statement.main();
    named_expression.main();
    record_literal.main();
    record_pattern.main();
    record_type_annotation.main();
    super_formal_parameter.main();
    switch_pattern_case.main();
  });
}
