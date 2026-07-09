// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'class_declaration_test.dart' as class_declaration;
import 'do_statement_test.dart' as do_statement;
import 'flutter_stateful_widget_test.dart' as flutter_stateful_widget;
import 'flutter_stateful_widget_with_animation_controller_test.dart'
    as flutter_stateful_widget_with_animation_controller;
import 'flutter_stateless_widget_test.dart' as flutter_stateless_widget;
import 'for_in_statement_test.dart' as for_in_statement;
import 'for_statement_test.dart' as for_statement;
import 'function_declaration_test.dart' as function_declaration;
import 'if_else_statement_test.dart' as if_else_statement;
import 'if_statement_test.dart' as if_statement;
import 'main_function_test.dart' as main_function;
import 'switch_expression_test.dart' as switch_expression;
import 'switch_statement_test.dart' as switch_statement;
import 'test_definition_test.dart' as test_definition;
import 'test_group_definition_test.dart' as test_group_definition;
import 'try_catch_statement_test.dart' as try_catch_statement;
import 'while_statement_test.dart' as while_statement;

void main() {
  defineReflectiveSuite(() {
    class_declaration.main();
    do_statement.main();
    flutter_stateful_widget.main();
    flutter_stateful_widget_with_animation_controller.main();
    flutter_stateless_widget.main();
    for_in_statement.main();
    for_statement.main();
    function_declaration.main();
    if_else_statement.main();
    if_statement.main();
    main_function.main();
    switch_expression.main();
    switch_statement.main();
    test_definition.main();
    test_group_definition.main();
    try_catch_statement.main();
    while_statement.main();
  }, name: 'dart');
}
