// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnnecessaryConstTest);
  });
}

@reflectiveTest
class UnnecessaryConstTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.REMOVE_UNNECESSARY_CONST;

  @override
  String get lintCode => LintNames.unnecessary_const;

  test_instanceCreation() async {
    await resolveTestUnit('''
const list = /*LINT*/const List();
''');
    await assertHasFix('''
const list = /*LINT*/List();
''', length: 5);
  }

  test_typedLiteral() async {
    await resolveTestUnit('''
const list = /*LINT*/const [];
''');
    await assertHasFix('''
const list = /*LINT*/[];
''', length: 5);
  }
}
