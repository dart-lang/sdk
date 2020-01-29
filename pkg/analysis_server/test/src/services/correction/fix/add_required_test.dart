// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AddRequiredTest);
  });
}

@reflectiveTest
class AddRequiredTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.ADD_REQUIRED;

  @override
  String get lintCode => LintNames.always_require_non_null_named_parameters;

  Future<void> test_withAssert() async {
    await resolveTestUnit('''
void function({String /*LINT*/param}) {
  assert(param != null);
}
''');
    await assertHasFix('''
void function({@required String param}) {
  assert(param != null);
}
''');
  }
}
