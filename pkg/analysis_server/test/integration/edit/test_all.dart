// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'bulk_fixes_test.dart' as bulk_fixes_test;
import 'dartfix_test.dart' as dartfix_test;
import 'format_test.dart' as format_test;
import 'get_assists_test.dart' as get_assists_test;
import 'get_available_refactorings_test.dart'
    as get_available_refactorings_test;
import 'get_dartfix_info_test.dart' as get_dartfix_info_test;
import 'get_fixes_test.dart' as get_fixes_test;
import 'get_postfix_completion_test.dart' as get_postfix_completion_test;
import 'get_refactoring_test.dart' as get_refactoring_test;
import 'get_statement_completion_test.dart' as get_statement_completion_test;
import 'import_elements_test.dart' as import_elements_test;
import 'is_postfix_completion_applicable_test.dart'
    as is_postfix_completion_applicable_test;
import 'list_postfix_completion_templates_test.dart'
    as list_postfix_completion_templates_test;
import 'organize_directives_test.dart' as organize_directives_test;
import 'sort_members_test.dart' as sort_members_test;

void main() {
  defineReflectiveSuite(() {
    bulk_fixes_test.main();
    dartfix_test.main();
    format_test.main();
    get_assists_test.main();
    get_available_refactorings_test.main();
    get_dartfix_info_test.main();
    get_fixes_test.main();
    get_refactoring_test.main();
    get_postfix_completion_test.main();
    get_statement_completion_test.main();
    import_elements_test.main();
    is_postfix_completion_applicable_test.main();
    list_postfix_completion_templates_test.main();
    organize_directives_test.main();
    sort_members_test.main();
  }, name: 'edit');
}
