// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assists_test.dart' as assists;
import 'bulk_fixes_test.dart' as bulk_fixes;
import 'fixes_test.dart' as fixes;
import 'format_test.dart' as format;
import 'organize_directives_test.dart' as organize_directives;
import 'postfix_completion_test.dart' as postfix_completion;
import 'refactoring_test.dart' as refactoring;
import 'sort_members_test.dart' as sort_members;
import 'statement_completion_test.dart' as statement_completion;
import 'token_details_test.dart' as token_details;

void main() {
  defineReflectiveSuite(() {
    assists.main();
    bulk_fixes.main();
    fixes.main();
    format.main();
    organize_directives.main();
    postfix_completion.main();
    refactoring.main();
    sort_members.main();
    statement_completion.main();
    token_details.main();
  }, name: 'edit');
}
