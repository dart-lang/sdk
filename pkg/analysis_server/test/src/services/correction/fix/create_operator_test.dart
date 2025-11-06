// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:linter/src/lint_names.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CreateOperatorMixinTest);
    defineReflectiveTests(CreateOperatorTest);
  });
}

@reflectiveTest
class CreateOperatorMixinTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.createOperator;

  Future<void> test_functionType_method_targetMixin() async {
    await resolveTestCode('''
void f(M m) {
  useFunction(m + 0);
}

mixin M {
}

useFunction(int v) {}
''');
    await assertHasFix('''
void f(M m) {
  useFunction(m + 0);
}

mixin M {
  int operator +(int other) {}
}

useFunction(int v) {}
''');
  }

  Future<void> test_main_part() async {
    var partPath = join(testPackageLibPath, 'part.dart');
    newFile(partPath, '''
part of 'test.dart';

mixin M {
}
''');
    await resolveTestCode('''
part 'part.dart';

void foo(M a) {
  a + 0;
}
''');
    await assertHasFix('''
part of 'test.dart';

mixin M {
  void operator +(int other) {}
}
''', target: partPath);
  }

  Future<void> test_ordinaryTarget_instance() async {
    await resolveTestCode('''
mixin M {}

void f(M m) {
  m + 0;
}
''');
    await assertHasFix('''
mixin M {
  void operator +(int other) {}
}

void f(M m) {
  m + 0;
}
''');
  }

  Future<void> test_ordinaryTarget_static() async {
    await resolveTestCode('''
mixin M {}

void f() {
  M + 0;
}
''');
    await assertNoFix();
  }

  Future<void> test_part_main() async {
    var mainPath = join(testPackageLibPath, 'main.dart');
    newFile(mainPath, '''
part 'test.dart';

mixin M {
}
''');
    await resolveTestCode('''
part of 'main.dart';

void foo(M m) {
  m + 0;
}
''');
    await assertHasFix('''
part 'test.dart';

mixin M {
  void operator +(int other) {}
}
''', target: mainPath);
  }

  Future<void> test_part_sibling() async {
    var part1Path = join(testPackageLibPath, 'part1.dart');
    newFile(part1Path, '''
part of 'main.dart';

mixin M {
}
''');
    newFile(join(testPackageLibPath, 'main.dart'), '''
part 'part1.dart';
part 'test.dart';
''');
    await resolveTestCode('''
part of 'main.dart';

void foo(M m) {
  m + 0;
}
''');
    await assertHasFix('''
part of 'main.dart';

mixin M {
  void operator +(int other) {}
}
''', target: part1Path);
  }

  Future<void> test_thisTarget() async {
    await resolveTestCode('''
mixin M {
  void f() {
    this + 0;
  }
}
''');
    await assertHasFix('''
mixin M {
  void f() {
    this + 0;
  }

  void operator +(int other) {}
}
''');
  }
}

@reflectiveTest
class CreateOperatorTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.createOperator;

  Future<void> test_await_expression_statement() async {
    await resolveTestCode('''
class A {
  Future<void> f() async {
    await (this + 0);
  }
}
''');
    await assertHasFix('''
class A {
  Future<void> f() async {
    await (this + 0);
  }

  Future<void> operator +(int other) async {}
}
''');
  }

  Future<void> test_await_field_assignment() async {
    await resolveTestCode('''
class A {
  int x = 1;
  Future<void> f() async {
    x = await (this + 0);
    print(x);
  }
}
''');
    await assertHasFix('''
class A {
  int x = 1;
  Future<void> f() async {
    x = await (this + 0);
    print(x);
  }

  Future<int> operator +(int other) async {}
}
''');
  }

  Future<void> test_await_infer_from_parent() async {
    await resolveTestCode('''
class A {
  Future<void> f() async {
    if (await (this < 0)) {}
  }
}
''');
    await assertHasFix('''
class A {
  Future<void> f() async {
    if (await (this < 0)) {}
  }

  Future<bool> operator <(int other) async {}
}
''');
  }

  Future<void> test_enum_invocation() async {
    await resolveTestCode('''
enum E {
  e1,
  e2;
}

void test(E e) {
  e + 0;
}
''');
    await assertHasFix('''
enum E {
  e1,
  e2;

  void operator +(int other) {}
}

void test(E e) {
  e + 0;
}
''');
  }

  Future<void> test_generic_argumentType() async {
    await resolveTestCode('''
class A<T> {
  B b = B();
  Map<int, T> items = {};
  void f() {
    b + items;
  }
}

class B {
}
''');
    await assertHasFix('''
class A<T> {
  B b = B();
  Map<int, T> items = {};
  void f() {
    b + items;
  }
}

class B {
  void operator +(Map<int, Object?> other) {}
}
''');
  }

  Future<void> test_generic_returnType() async {
    await resolveTestCode('''
class A<T> {
  void f() {
    T t = new B() + 0;
    print(t);
  }
}

class B {
}
''');
    await assertHasFix('''
class A<T> {
  void f() {
    T t = new B() + 0;
    print(t);
  }
}

class B {
  operator +(int other) {}
}
''');
  }

  Future<void> test_generic_returnType_lint() async {
    createAnalysisOptionsFile(lints: [LintNames.always_declare_return_types]);
    await resolveTestCode('''
class A<T> {
  void f() {
    T t = new B() + 0;
    print(t);
  }
}

class B {
}
''');
    await assertHasFix('''
class A<T> {
  void f() {
    T t = new B() + 0;
    print(t);
  }
}

class B {
  dynamic operator +(int other) {}
}
''');
  }

  Future<void> test_index() async {
    await resolveTestCode('''
class A {
}

void f(A a) {
  a[0];
}
''');
    await assertHasFix('''
class A {
  void operator [](int other) {}
}

void f(A a) {
  a[0];
}
''');
  }

  Future<void> test_indexAssignment() async {
    await resolveTestCode('''
class A {
}

void f(A a) {
  a[0] = 0;
}
''');
    await assertHasFix('''
class A {
  void operator []=(int other, int value) {}
}

void f(A a) {
  a[0] = 0;
}
''');
  }

  Future<void> test_inSDK() async {
    await resolveTestCode('''
void f() {
  [] + 0;
}
''');
    await assertNoFix();
  }

  Future<void> test_main_part() async {
    var partPath = join(testPackageLibPath, 'part.dart');
    newFile(partPath, '''
part of 'test.dart';

class A {
}
''');
    await resolveTestCode('''
part 'part.dart';

void foo(A a) {
  a + 0;
}
''');
    await assertHasFix('''
part of 'test.dart';

class A {
  void operator +(int other) {}
}
''', target: partPath);
  }

  Future<void> test_ordinaryTarget_emptyClassBody() async {
    await resolveTestCode('''
class A {}
void f() {
  A + 0;
}
''');
    await assertNoFix();
  }

  Future<void> test_ordinaryTarget_fromInstance() async {
    await resolveTestCode('''
class A {
}
void f(A a) {
  a + 0;
}
''');
    await assertHasFix('''
class A {
  void operator +(int other) {}
}
void f(A a) {
  a + 0;
}
''');
  }

  Future<void> test_ordinaryTarget_instance_fromExtensionType() async {
    await resolveTestCode('''
extension type A(String s) {
}
void f(A a) {
  a + 0;
}
''');
    await assertHasFix('''
extension type A(String s) {
  void operator +(int other) {}
}
void f(A a) {
  a + 0;
}
''');
  }

  Future<void> test_ordinaryTarget_targetIsFunctionType() async {
    await resolveTestCode('''
typedef A();
void f() {
  A + 0;
}
''');
    await assertNoFix();
  }

  Future<void> test_ordinaryTarget_targetIsUnresolved() async {
    await resolveTestCode('''
void f() {
  NoSuchClass + 0;
}
''');
    await assertNoFix();
  }

  Future<void> test_parameterType_differentPrefixInTargetUnit() async {
    var code2 = r'''
import 'test3.dart' as bbb;
export 'test3.dart';

class D {
}
''';

    newFile('$testPackageLibPath/test2.dart', code2);
    newFile('$testPackageLibPath/test3.dart', r'''
library test3;
class E {}
''');

    await resolveTestCode('''
import 'test2.dart' as aaa;

void f(aaa.D d, aaa.E e) {
  d + e;
}
''');

    await assertHasFix('''
import 'test3.dart' as bbb;
export 'test3.dart';

class D {
  void operator +(bbb.E other) {}
}
''', target: '$testPackageLibPath/test2.dart');
  }

  Future<void> test_part_main() async {
    var mainPath = join(testPackageLibPath, 'main.dart');
    newFile(mainPath, '''
part 'test.dart';

class A {
}
''');
    await resolveTestCode('''
part of 'main.dart';

void foo(A a) {
  a + 0;
}
''');
    await assertHasFix('''
part 'test.dart';

class A {
  void operator +(int other) {}
}
''', target: mainPath);
  }

  Future<void> test_part_sibling() async {
    var part1Path = join(testPackageLibPath, 'part1.dart');
    newFile(part1Path, '''
part of 'main.dart';

class A {
}
''');
    newFile(join(testPackageLibPath, 'main.dart'), '''
part 'part1.dart';
part 'test.dart';
''');
    await resolveTestCode('''
part of 'main.dart';

void foo(A a) {
  a + 0;
}
''');
    await assertHasFix('''
part of 'main.dart';

class A {
  void operator +(int other) {}
}
''', target: part1Path);
  }

  Future<void> test_returnType_closure_expression() async {
    await resolveTestCode('''
class A {
  void m(List<A> list) {
    list.where((a) => a + 0);
  }
}
''');
    await assertHasFix('''
class A {
  void m(List<A> list) {
    list.where((a) => a + 0);
  }

  bool operator +(int other) {}
}
''');
  }

  Future<void> test_returnType_closure_return() async {
    await resolveTestCode('''
class A {
  void m(List<A> list) {
    list.where((a) {
      return a + 0;
    });
  }
}
''');
    await assertHasFix('''
class A {
  void m(List<A> list) {
    list.where((a) {
      return a + 0;
    });
  }

  bool operator +(int other) {}
}
''');
  }

  Future<void> test_thisTarget_returnType() async {
    await resolveTestCode('''
class A {
  void f() {
    int v = this / 0;
    print(v);
  }
}
''');
    await assertHasFix('''
class A {
  void f() {
    int v = this / 0;
    print(v);
  }

  int operator /(int other) {}
}
''');
  }

  Future<void> test_unary() async {
    await resolveTestCode('''
class A {
}

void f(A a) {
  ~a;
}
''');
    await assertHasFix('''
class A {
  void operator ~() {}
}

void f(A a) {
  ~a;
}
''');
  }
}
