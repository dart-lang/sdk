// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'bulk_fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ReplaceWithTearOffTest);
  });
}

@reflectiveTest
class ReplaceWithTearOffTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.unnecessary_lambdas;

  Future<void> test_singleFile() async {
    await resolveTestCode('''
Function f() => (name) {
  print(name);
};

void foo(){}
Function f2() {
  return () {
    foo();
  };
}
''');
    await assertHasFix('''
Function f() => print;

void foo(){}
Function f2() {
  return foo;
}
''');
  }
}
