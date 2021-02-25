// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ReplaceNullWithClosureTest);
  });
}

@reflectiveTest
class ReplaceNullWithClosureTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.REPLACE_NULL_WITH_CLOSURE;

  @override
  String get lintCode => LintNames.null_closures;

  Future<void> test_named() async {
    await resolveTestCode('''
void f(List<int> l) {
  l.firstWhere((e) => e.isEven, orElse: null);
}
''');
    await assertHasFix('''
void f(List<int> l) {
  l.firstWhere((e) => e.isEven, orElse: () => null);
}
''');
  }

  Future<void> test_named_withArgs() async {
    await resolveTestCode('''
void f(String s) {
  s.splitMapJoin('', onNonMatch: null);
}
''');
    await assertHasFix('''
void f(String s) {
  s.splitMapJoin('', onNonMatch: (String p1) => null);
}
''');
  }

  Future<void> test_required() async {
    await resolveTestCode('''
void f(List<int> l) {
  l.firstWhere(null);
}
''');
    await assertHasFix('''
void f(List<int> l) {
  l.firstWhere(() => null);
}
''');
  }
}
