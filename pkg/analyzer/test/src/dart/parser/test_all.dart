// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'class_test.dart' as class_;
import 'doc_comment_test.dart' as doc_comment;
import 'dot_shorthand_test.dart' as dot_shorthand;
import 'enum_test.dart' as enum_;
import 'export_directive_test.dart' as export_directive;
import 'extension_test.dart' as extension_;
import 'extension_type_test.dart' as extension_type;
import 'import_directive_test.dart' as import_directive;
import 'library_directive_test.dart' as library_directive;
import 'mixin_test.dart' as mixin_;
import 'null_aware_elements_test.dart' as null_aware_elements_test;
import 'part_directive_test.dart' as part_directive;
import 'part_of_directive_test.dart' as part_of_directive;
import 'record_literal_test.dart' as record_literal;
import 'record_type_annotation_test.dart' as record_type_annotation;
import 'switch_statement_test.dart' as switch_statement;
import 'top_level_function_test.dart' as top_level_function;
import 'top_level_variable_test.dart' as top_level_variable;
import 'type_alias_test.dart' as type_alias;
import 'variable_declaration_statement_test.dart'
    as variable_declaration_statement;

/// Utility for manually running all tests.
main() {
  defineReflectiveSuite(() {
    class_.main();
    doc_comment.main();
    dot_shorthand.main();
    enum_.main();
    export_directive.main();
    extension_.main();
    extension_type.main();
    import_directive.main();
    library_directive.main();
    mixin_.main();
    null_aware_elements_test.main();
    part_directive.main();
    part_of_directive.main();
    record_literal.main();
    record_type_annotation.main();
    switch_statement.main();
    top_level_function.main();
    top_level_variable.main();
    type_alias.main();
    variable_declaration_statement.main();
  }, name: 'parser');
}
