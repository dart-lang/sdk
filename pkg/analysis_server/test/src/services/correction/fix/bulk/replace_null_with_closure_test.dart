// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'bulk_fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ReplaceNullWithClosureTest);
  });
}

@reflectiveTest
class ReplaceNullWithClosureTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.null_closures;

  Future<void> test_singleFile() async {
    await resolveTestCode('''
void f(List<int> l) {
  l.firstWhere((e) => e.isEven, orElse: null);
}

void f2(String s) {
  s.splitMapJoin('', onNonMatch: null);
}
''');
    await assertHasFix('''
void f(List<int> l) {
  l.firstWhere((e) => e.isEven, orElse: () => null);
}

void f2(String s) {
  s.splitMapJoin('', onNonMatch: (String p1) => null);
}
''');
  }
}
