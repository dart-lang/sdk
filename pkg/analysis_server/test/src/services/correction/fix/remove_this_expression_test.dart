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
    defineReflectiveTests(RemoveThisExpressionTest);
  });
}

@reflectiveTest
class RemoveThisExpressionTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.REMOVE_THIS_EXPRESSION;

  @override
  String get lintCode => LintNames.unnecessary_this;

  Future<void> test_constructorInitializer() async {
    await resolveTestCode('''
class A {
  int x;
  A(int x) : this.x = x;
}
''');
    await assertHasFix('''
class A {
  int x;
  A(int x) : x = x;
}
''');
  }

  Future<void> test_methodInvocation_oneCharacterOperator() async {
    await resolveTestCode('''
class A {
  void foo() {
    this.foo();
  }
}
''');
    await assertHasFix('''
class A {
  void foo() {
    foo();
  }
}
''');
  }

  Future<void> test_propertyAccess_oneCharacterOperator() async {
    await resolveTestCode('''
class A {
  int x;
  void foo() {
    this.x = 2;
  }
}
''');
    await assertHasFix('''
class A {
  int x;
  void foo() {
    x = 2;
  }
}
''');
  }
}
