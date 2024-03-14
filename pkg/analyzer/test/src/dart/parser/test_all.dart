// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'class_test.dart' as class_;
import 'doc_comment_test.dart' as doc_comment;
import 'extension_type_test.dart' as extension_type;
import 'mixin_test.dart' as mixin_;
import 'top_level_function_test.dart' as top_level_function;
import 'top_level_variable_test.dart' as top_level_variable;
import 'variable_declaration_statement_test.dart'
    as variable_declaration_statement;

/// Utility for manually running all tests.
main() {
  defineReflectiveSuite(() {
    class_.main();
    doc_comment.main();
    extension_type.main();
    mixin_.main();
    top_level_function.main();
    top_level_variable.main();
    variable_declaration_statement.main();
  }, name: 'parser');
}
