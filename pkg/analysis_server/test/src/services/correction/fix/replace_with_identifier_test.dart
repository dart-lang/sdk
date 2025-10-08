// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:linter/src/lint_names.dart';
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
  FixKind get kind => DartFixKind.replaceWithIdentifier;

  @override
  String get lintCode => LintNames.avoid_types_on_closure_parameters;

  Future<void> test_functionTypedFormalParameter() async {
    await resolveTestCode('''
void f(List<int Function(int)> list) {
  list.forEach((int p(int x)) {p(0);});
}
''');
    await assertHasFix('''
void f(List<int Function(int)> list) {
  list.forEach((p) {p(0);});
}
''');
  }
}
