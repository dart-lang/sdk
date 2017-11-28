// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import 'break_statement_test.dart' as break_statement;
import 'class_declaration_test.dart' as class_declaration;
import 'continue_statement_test.dart' as continue_statement;
import 'do_statement_test.dart' as do_statement;
import 'export_directive_test.dart' as export_directive;
import 'if_statement_test.dart' as if_statement;
import 'import_directive_test.dart' as import_directive;
import 'library_directive_test.dart' as library_directive;
import 'local_variable_test.dart' as local_variable;
import 'part_directive_test.dart' as part_directive;
import 'part_of_directive_test.dart' as part_of_directive;
import 'return_statement_test.dart' as return_statement;
import 'switch_statement_test.dart' as switch_statement;
import 'top_level_variable_test.dart' as top_level_variable;
import 'while_statement_test.dart' as while_statement;

main() {
  group('partial_code', () {
    break_statement.main();
    class_declaration.main();
    continue_statement.main();
    do_statement.main();
    export_directive.main();
    if_statement.main();
    import_directive.main();
    library_directive.main();
    local_variable.main();
    part_directive.main();
    part_of_directive.main();
    return_statement.main();
    switch_statement.main();
    top_level_variable.main();
    while_statement.main();
  });
}
