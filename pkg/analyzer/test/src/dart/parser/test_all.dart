// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'augmented_expression_test.dart' as augmented_expression;
import 'class_test.dart' as class_;
import 'doc_comment_test.dart' as doc_comment;
import 'enum_test.dart' as enum_;
import 'export_directive_test.dart' as export_directive;
import 'extension_test.dart' as extension_;
import 'extension_type_test.dart' as extension_type;
import 'import_directive_test.dart' as import_directive;
import 'mixin_test.dart' as mixin_;
import 'null_aware_elements_test.dart' as null_aware_elements_test;
import 'part_directive_test.dart' as part_directive;
import 'part_of_directive_test.dart' as part_of_directive;
import 'top_level_function_test.dart' as top_level_function;
import 'top_level_variable_test.dart' as top_level_variable;
import 'type_alias_test.dart' as type_alias;
import 'variable_declaration_statement_test.dart'
    as variable_declaration_statement;

/// Utility for manually running all tests.
main() {
  defineReflectiveSuite(() {
    augmented_expression.main();
    class_.main();
    doc_comment.main();
    enum_.main();
    export_directive.main();
    extension_.main();
    extension_type.main();
    import_directive.main();
    mixin_.main();
    null_aware_elements_test.main();
    part_directive.main();
    part_of_directive.main();
    top_level_function.main();
    top_level_variable.main();
    type_alias.main();
    variable_declaration_statement.main();
  }, name: 'parser');
}
