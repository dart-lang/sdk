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
    defineReflectiveTests(ReplaceWithIdentifierTest);
  });
}

@reflectiveTest
class ReplaceWithIdentifierTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.REPLACE_WITH_IDENTIFIER;

  @override
  String get lintCode => LintNames.avoid_types_on_closure_parameters;

  Future<void> test_functionTypedFormalParameter() async {
    await resolveTestCode('''
var functionWithFunction = (int f(int x)) => f(0);
''');
    await assertHasFix('''
var functionWithFunction = (f) => f(0);
''');
  }
}
