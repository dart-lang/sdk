// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AddMissingParameterNamedTest);
  });
}

@reflectiveTest
class AddMissingParameterNamedTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.addMissingParameterNamed;

  Future<void> test_constructor_hasNamed() async {
    await resolveTestCode('''
class A {
  A(int a, {int b = 0}) {}
}

void f() {
  new A(1, b: 2, named: 3.0);
}
''');
    await assertHasFix('''
class A {
  A(int a, {int b = 0, required double named}) {}
}

void f() {
  new A(1, b: 2, named: 3.0);
}
''');
  }

  Future<void> test_constructor_hasRequired() async {
    await resolveTestCode('''
class A {
  A(int a) {}
}

void f() {
  new A(1, named: 2.0);
}
''');
    await assertHasFix('''
class A {
  A(int a, {required double named}) {}
}

void f() {
  new A(1, named: 2.0);
}
''');
  }

  Future<void> test_constructor_noParameters() async {
    await resolveTestCode('''
class A {
  A() {}
}

void f() {
  new A(named: 42);
}
''');
    await assertHasFix('''
class A {
  A({required int named}) {}
}

void f() {
  new A(named: 42);
}
''');
  }

  Future<void> test_constructor_noParameters_named() async {
    await resolveTestCode('''
class A {
  A.aaa() {}
}

void f() {
  new A.aaa(named: 42);
}
''');
    await assertHasFix('''
class A {
  A.aaa({required int named}) {}
}

void f() {
  new A.aaa(named: 42);
}
''');
  }

  Future<void> test_function_hasNamed() async {
    await resolveTestCode('''
test(int a, {int b = 0}) {}

void f() {
  test(1, b: 2, named: 3.0);
}
''');
    await assertHasFix('''
test(int a, {int b = 0, required double named}) {}

void f() {
  test(1, b: 2, named: 3.0);
}
''');
  }

  Future<void> test_function_hasRequired() async {
    await resolveTestCode('''
test(int a) {}

void f() {
  test(1, named: 2.0);
}
''');
    await assertHasFix('''
test(int a, {required double named}) {}

void f() {
  test(1, named: 2.0);
}
''');
  }

  Future<void> test_function_noParameters() async {
    await resolveTestCode('''
test() {}

void f() {
  test(named: 42);
}
''');
    await assertHasFix('''
test({required int named}) {}

void f() {
  test(named: 42);
}
''');
  }

  Future<void> test_method_hasNamed() async {
    await resolveTestCode('''
class A {
  test(int a, {int b = 0}) {}

  void f() {
    test(1, b: 2, named: 3.0);
  }
}
''');
    await assertHasFix('''
class A {
  test(int a, {int b = 0, required double named}) {}

  void f() {
    test(1, b: 2, named: 3.0);
  }
}
''');
  }

  Future<void> test_method_hasOptionalPositional() async {
    await resolveTestCode('''
class A {
  test(int a, [int b = 0]) {}

  void f() {
    test(1, 2, named: 3.0);
  }
}
''');
    await assertNoFix();
  }

  Future<void> test_method_hasRequired() async {
    await resolveTestCode('''
class A {
  test(int a) {}

  void f() {
    test(1, named: 2.0);
  }
}
''');
    await assertHasFix('''
class A {
  test(int a, {required double named}) {}

  void f() {
    test(1, named: 2.0);
  }
}
''');
  }

  Future<void> test_method_noParameters() async {
    await resolveTestCode('''
class A {
  test() {}

  void f() {
    test(named: 42);
  }
}
''');
    await assertHasFix('''
class A {
  test({required int named}) {}

  void f() {
    test(named: 42);
  }
}
''');
  }
}
