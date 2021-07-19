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
    defineReflectiveTests(RemoveUnnecessaryNewBulkTest);
    defineReflectiveTests(RemoveUnnecessaryNewTest);
  });
}

@reflectiveTest
class RemoveUnnecessaryNewBulkTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.unnecessary_new;

  Future<void> test_singleFile() async {
    await resolveTestCode('''
C f() => new C();

class C {
  C();

  void m() {
    new C();
  }
}
''');
    await assertHasFix('''
C f() => C();

class C {
  C();

  void m() {
    C();
  }
}
''');
  }
}

@reflectiveTest
class RemoveUnnecessaryNewTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.REMOVE_UNNECESSARY_NEW;

  @override
  String get lintCode => LintNames.unnecessary_new;

  Future<void> test_constructor() async {
    await resolveTestCode('''
class A { A(); }
f() {
  final a = new A();
  print(a);
}
''');
    await assertHasFix('''
class A { A(); }
f() {
  final a = A();
  print(a);
}
''');
  }
}
