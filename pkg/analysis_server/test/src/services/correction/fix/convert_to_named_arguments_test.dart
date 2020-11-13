// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConvertToNamedArgumentsTest);
  });
}

@reflectiveTest
class ConvertToNamedArgumentsTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.CONVERT_TO_NAMED_ARGUMENTS;

  Future<void> test_ambiguous() async {
    await resolveTestCode('''
class A {
  A({int a, int b});
}

main() {
  new A(1, 2);
}
''');
    await assertNoFix();
  }

  Future<void> test_functionExpressionInvocation_getter() async {
    await resolveTestCode('''
class A {
  void Function({int aaa}) get g => null;
}

main(A a) {
  a.g(0);
}
''');
    await assertHasFix('''
class A {
  void Function({int aaa}) get g => null;
}

main(A a) {
  a.g(aaa: 0);
}
''');
  }

  Future<void> test_functionExpressionInvocation_variable() async {
    await resolveTestCode('''
typedef F = void Function({int aaa});

main(F f) {
  f(0);
}
''');
    await assertHasFix('''
typedef F = void Function({int aaa});

main(F f) {
  f(aaa: 0);
}
''');
  }

  Future<void> test_instanceCreation() async {
    await resolveTestCode('''
class A {
  A({int a, double b});
}

main() {
  new A(1.2, 3);
}
''');
    await assertHasFix('''
class A {
  A({int a, double b});
}

main() {
  new A(b: 1.2, a: 3);
}
''');
  }

  Future<void> test_instanceCreation_hasPositional() async {
    await resolveTestCode('''
class A {
  A(int a, {int b});
}

main() {
  new A(1, 2);
}
''');
    await assertHasFix('''
class A {
  A(int a, {int b});
}

main() {
  new A(1, b: 2);
}
''');
  }

  Future<void> test_methodInvocation() async {
    await resolveTestCode('''
class C {
  void foo({int a}) {}
}

main(C c) {
  c.foo(1);
}
''');
    await assertHasFix('''
class C {
  void foo({int a}) {}
}

main(C c) {
  c.foo(a: 1);
}
''');
  }

  Future<void> test_noCompatibleParameter() async {
    await resolveTestCode('''
class A {
  A({String a});
}

main() {
  new A(1);
}
''');
    await assertNoFix();
  }
}
