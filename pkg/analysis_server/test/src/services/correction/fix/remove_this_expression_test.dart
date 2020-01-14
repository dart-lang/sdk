// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

main() {
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

  test_constructorInitializer() async {
    await resolveTestUnit('''
class A {
  int x;
  A(int x) : /*LINT*/this.x = x;
}
''');
    await assertHasFix('''
class A {
  int x;
  A(int x) : /*LINT*/x = x;
}
''');
  }

  test_methodInvocation_oneCharacterOperator() async {
    await resolveTestUnit('''
class A {
  void foo() {
    /*LINT*/this.foo();
  }
}
''');
    await assertHasFix('''
class A {
  void foo() {
    /*LINT*/foo();
  }
}
''');
  }

  test_methodInvocation_twoCharactersOperator() async {
    await resolveTestUnit('''
class A {
  void foo() {
    /*LINT*/this?.foo();
  }
}
''');
    await assertHasFix('''
class A {
  void foo() {
    /*LINT*/foo();
  }
}
''');
  }

  test_notAThisExpression() async {
    await resolveTestUnit('''
void foo() {
  final /*LINT*/this.id;
}
''');
    await assertNoFix();
  }

  test_propertyAccess_oneCharacterOperator() async {
    await resolveTestUnit('''
class A {
  int x;
  void foo() {
    /*LINT*/this.x = 2;
  }
}
''');
    await assertHasFix('''
class A {
  int x;
  void foo() {
    /*LINT*/x = 2;
  }
}
''');
  }

  test_propertyAccess_twoCharactersOperator() async {
    await resolveTestUnit('''
class A {
  int x;
  void foo() {
    /*LINT*/this?.x = 2;
  }
}
''');
    await assertHasFix('''
class A {
  int x;
  void foo() {
    /*LINT*/x = 2;
  }
}
''');
  }
}
