// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AddMissingParameterPositionalTest);
  });
}

@reflectiveTest
class AddMissingParameterPositionalTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.addMissingParameterPositional;

  Future<void> test_constructor_callingViaSuper() async {
    await resolveTestCode('''
class A {
  A(int a);
}
class B extends A {
  B() : super(1, 2.0);
}
''');
    await assertHasFix('''
class A {
  A(int a, [double? d]);
}
class B extends A {
  B() : super(1, 2.0);
}
''');
  }

  Future<void> test_constructor_callingViaSuperParameter() async {
    await resolveTestCode('''
class A {
  A(int a);
}
class B extends A {
  B(super.a, int super.b);
}
''');
    await assertHasFix('''
class A {
  A(int a, [int? b]);
}
class B extends A {
  B(super.a, int super.b);
}
''');
  }

  Future<void> test_constructor_callingViaSuperParameter_default() async {
    await resolveTestCode('''
class A {
  A(int a);
}
class B extends A {
  B(super.a, [super.b = 0]);
}
''');
    await assertHasFix('''
class A {
  A(int a, [int? b]);
}
class B extends A {
  B(super.a, [super.b = 0]);
}
''');
  }

  Future<void> test_constructor_hasOne() async {
    await resolveTestCode('''
class A {
  A(int a);
}
void f() {
  A(1, 2.0);
}
''');
    await assertHasFix('''
class A {
  A(int a, [double? d]);
}
void f() {
  A(1, 2.0);
}
''');
  }

  Future<void> test_constructor_hasOneFieldFormalParameter() async {
    await resolveTestCode('''
class A {
  int a;
  A(this.a);
}
void f() {
  A(1, 2.0);
}
''');
    await assertHasFix('''
class A {
  int a;
  A(this.a, [double? d]);
}
void f() {
  A(1, 2.0);
}
''');
  }

  Future<void> test_constructor_hasOneSuperParameter() async {
    await resolveTestCode('''
class A {
  A(int a);
}
class B extends A {
  B(super.a);
}
void f() {
  B(1, 2.0);
}
''');
    await assertHasFix('''
class A {
  A(int a);
}
class B extends A {
  B(super.a, [double? d]);
}
void f() {
  B(1, 2.0);
}
''');
  }

  Future<void> test_constructor_implicitSuper() async {
    // https://github.com/dart-lang/sdk/issues/61927
    await resolveTestCode('''
class A {}
class B extends A {
  B([super.other]);
}
''');
    await assertNoFix();
  }

  Future<void> test_constructor_superParameter() async {
    await resolveTestCode('''
class A {
  A();
}
class B extends A {
  B([super.other]);
}
''');
    await assertHasFix('''
class A {
  A([Object? other]);
}
class B extends A {
  B([super.other]);
}
''');
  }

  Future<void> test_constructor_superParameter_differentConstructor() async {
    await resolveTestCode('''
class A {
  A();
  A.foo();
}
class B extends A {
  B([super.other]) : super.foo();
}
''');
    await assertHasFix('''
class A {
  A();
  A.foo([Object? other]);
}
class B extends A {
  B([super.other]) : super.foo();
}
''');
  }

  Future<void> test_function_hasNamed() async {
    await resolveTestCode('''
test({int a = 0}) {}
void f() {
  test(1);
}
''');
    await assertNoFix();
  }

  Future<void> test_function_hasZero() async {
    await resolveTestCode('''
test() {}
void f() {
  test(1);
}
''');
    await assertHasFix('''
test([int? i]) {}
void f() {
  test(1);
}
''');
  }

  Future<void> test_method_hasOne() async {
    await resolveTestCode('''
class A {
  test(int a) {}
  void f() {
    test(1, 2.0);
  }
}
''');
    await assertHasFix('''
class A {
  test(int a, [double? d]) {}
  void f() {
    test(1, 2.0);
  }
}
''');
  }
}
