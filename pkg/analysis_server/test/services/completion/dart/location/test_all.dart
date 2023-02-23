// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'block_test.dart' as block;
import 'case_clause_test.dart' as case_clause;
import 'cast_pattern_test.dart' as cast_pattern;
import 'class_body_test.dart' as class_body;
import 'compilation_unit_member_test.dart' as compilation_unit_member;
import 'compilation_unit_test.dart' as compilation_unit;
import 'directive_uri_test.dart' as directive_uri;
import 'enum_constant_test.dart' as enum_constant;
import 'enum_test.dart' as enum_;
import 'extends_clause_test.dart' as extends_clause;
import 'field_formal_parameter_test.dart' as field_formal_parameter;
import 'for_statement_test.dart' as for_statement;
import 'if_element_test.dart' as if_element;
import 'if_statement_test.dart' as if_statement;
import 'implements_clause_test.dart' as implements_clause;
import 'list_pattern_test.dart' as list_pattern;
import 'logical_and_pattern_test.dart' as logical_and_pattern;
import 'logical_or_pattern_test.dart' as logical_or_pattern;
import 'map_pattern_test.dart' as map_pattern;
import 'named_expression_test.dart' as named_expression;
import 'object_pattern_test.dart' as object_pattern;
import 'parenthesized_pattern_test.dart' as parenthesized_pattern;
import 'pattern_assignment_test.dart' as pattern_assignment;
import 'pattern_variable_declaration_test.dart' as pattern_variable_declaration;
import 'record_literal_test.dart' as record_literal;
import 'record_pattern_test.dart' as record_pattern;
import 'record_type_annotation_test.dart' as record_type_annotation;
import 'relational_pattern_test.dart' as relational_pattern;
import 'rest_pattern_test.dart' as rest_pattern;
import 'super_formal_parameter_test.dart' as super_formal_parameter;
import 'switch_expression_test.dart' as switch_expression;
import 'switch_pattern_case_test.dart' as switch_pattern_case;
import 'type_argument_list_test.dart' as type_argument_list;
import 'variable_declaration_list_test.dart' as variable_declaration_list;
import 'with_clause_test.dart' as with_clause;

/// Tests suggestions produced at specific locations.
void main() {
  defineReflectiveSuite(() {
    block.main();
    case_clause.main();
    cast_pattern.main();
    class_body.main();
    compilation_unit_member.main();
    compilation_unit.main();
    directive_uri.main();
    enum_constant.main();
    enum_.main();
    extends_clause.main();
    field_formal_parameter.main();
    for_statement.main();
    if_element.main();
    if_statement.main();
    implements_clause.main();
    list_pattern.main();
    logical_and_pattern.main();
    logical_or_pattern.main();
    map_pattern.main();
    named_expression.main();
    object_pattern.main();
    parenthesized_pattern.main();
    pattern_assignment.main();
    pattern_variable_declaration.main();
    record_literal.main();
    record_pattern.main();
    record_type_annotation.main();
    relational_pattern.main();
    rest_pattern.main();
    super_formal_parameter.main();
    switch_expression.main();
    switch_pattern_case.main();
    type_argument_list.main();
    variable_declaration_list.main();
    with_clause.main();
  });
}
