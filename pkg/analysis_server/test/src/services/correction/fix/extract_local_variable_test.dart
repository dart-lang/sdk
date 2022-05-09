// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExtractLocalVariableTest);
  });
}

@reflectiveTest
class ExtractLocalVariableTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.EXTRACT_LOCAL_VARIABLE;

  Future<void> test_ifCondition_notBangEq() async {
    await resolveTestCode('''
abstract class A {
  int? get foo;

  void bar() {
    if (foo == 0) {
      foo.isEven;
    }
  }
}
''');
    await assertNoFix();
  }

  Future<void> test_ifCondition_notBinaryExpression() async {
    await resolveTestCode('''
abstract class A {
  int? get foo;

  void bar() {
    if (!(1 == 0)) {
      foo.isEven;
    }
  }
}
''');
    await assertNoFix();
  }

  Future<void> test_ifCondition_notNull() async {
    await resolveTestCode('''
abstract class A {
  int? get foo;

  void bar() {
    if (foo != 0) {
      foo.isEven;
    }
  }
}
''');
    await assertNoFix();
  }

  Future<void> test_noEnclosingIf() async {
    await resolveTestCode('''
abstract class A {
  int? get foo;

  void bar() {
    foo.isEven;
  }
}
''');
    await assertNoFix();
  }

  Future<void> test_prefixedIdentifier() async {
    await resolveTestCode('''
abstract class A {
  int? get foo;

  void bar() {
    if (foo != null) {
      foo.isEven;
    }
  }
}
''');
    await assertHasFix('''
abstract class A {
  int? get foo;

  void bar() {
    final foo = this.foo;
    if (foo != null) {
      foo.isEven;
    }
  }
}
''');
  }

  Future<void> test_prefixedIdentifier_methodInvocation() async {
    await resolveTestCode('''
abstract class A {
  int? get foo;
}
void f(A a) {
  if (a.foo != null) {
    a.foo.abs();
  }
}
''');
    await assertHasFix('''
abstract class A {
  int? get foo;
}
void f(A a) {
  final foo = a.foo;
  if (foo != null) {
    foo.abs();
  }
}
''');
  }

  Future<void> test_prefixedIdentifier_propertyAccess() async {
    await resolveTestCode('''
abstract class A {
  int? get foo;
}
void f(A a) {
  if (a.foo != null) {
    a.foo.isEven;
  }
}
''');
    await assertHasFix('''
abstract class A {
  int? get foo;
}
void f(A a) {
  final foo = a.foo;
  if (foo != null) {
    foo.isEven;
  }
}
''');
  }

  Future<void> test_propertyAccess_methodInvocation() async {
    await resolveTestCode('''
abstract class A {
  int? get foo;
}
abstract class B {
  A get a;
}
void f(B b) {
  if (b.a.foo != null) {
    b.a.foo.abs();
  }
}
''');
    await assertHasFix('''
abstract class A {
  int? get foo;
}
abstract class B {
  A get a;
}
void f(B b) {
  final foo = b.a.foo;
  if (foo != null) {
    foo.abs();
  }
}
''');
  }
}
