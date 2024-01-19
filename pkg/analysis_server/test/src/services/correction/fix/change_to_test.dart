// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ChangeToTest);
  });
}

@reflectiveTest
class ChangeToTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.CHANGE_TO;

  Future<void> test_annotation_constructor() async {
    await resolveTestCode('''
@MyCalss()
void f() {}

class MyClass {
  const MyClass();
}
''');
    await assertHasFix('''
@MyClass()
void f() {}

class MyClass {
  const MyClass();
}
''');
  }

  @failingTest
  Future<void> test_annotation_variable() async {
    // TODO(brianwilkerson): Add support for suggesting similar top-level
    //  variables.
    await resolveTestCode('''
const annotation = '';
@anontation
void f() {}
''');
    await assertHasFix('''
const annotation = '';
@annotation
void f() {}
''');
  }

  Future<void> test_class_extends() async {
    await resolveTestCode('''
class MyClass extends BaseClssa {}

class BaseClass {}
''');
    await assertHasFix('''
class MyClass extends BaseClass {}

class BaseClass {}
''');
  }

  Future<void> test_class_fromImport() async {
    await resolveTestCode('''
void f() {
  Stirng s = 'abc';
  print(s);
}
''');
    await assertHasFix('''
void f() {
  String s = 'abc';
  print(s);
}
''');
  }

  Future<void> test_class_fromThisLibrary() async {
    await resolveTestCode('''
class MyClass {}
void f() {
  MyCalss v = null;
  print(v);
}
''');
    await assertHasFix('''
class MyClass {}
void f() {
  MyClass v = null;
  print(v);
}
''');
  }

  Future<void> test_class_implements() async {
    await resolveTestCode('''
class MyClass implements BaseClssa {}

class BaseClass {}
''');
    await assertHasFix('''
class MyClass implements BaseClass {}

class BaseClass {}
''');
  }

  Future<void> test_class_prefixed() async {
    await resolveTestCode('''
import 'dart:async' as c;
void f() {
  c.Fture v = null;
  print(v);
}
''');
    await assertHasFix('''
import 'dart:async' as c;
void f() {
  c.Future v = null;
  print(v);
}
''');
  }

  Future<void> test_class_with() async {
    await resolveTestCode('''
class MyClass with BaseClssa {}

class BaseClass {}
''');
    await assertHasFix('''
class MyClass with BaseClass {}

class BaseClass {}
''');
  }

  Future<void> test_enum_constant() async {
    await resolveTestCode('''
enum E { ONE }

E e() {
  return E.OEN;
}
''');
    await assertHasFix('''
enum E { ONE }

E e() {
  return E.ONE;
}
''');
  }

  Future<void> test_enum_getter() async {
    await resolveTestCode('''
enum E { ONE }

void f() {
  E.ONE.indxe;
}
''');
    await assertHasFix('''
enum E { ONE }

void f() {
  E.ONE.index;
}
''');
  }

  Future<void> test_enum_method() async {
    await resolveTestCode('''
enum E { ONE }

void f() {
  E.ONE.toStrong();
}
''');
    await assertHasFix('''
enum E { ONE }

void f() {
  E.ONE.toString();
}
''');
  }

  Future<void> test_fieldFormalParameter_external() async {
    await resolveTestCode('''
class C {
  external int one;
  C(this.oen);
}
''');
    await assertNoFix();
  }

  Future<void> test_fieldFormalParameter_getter() async {
    await resolveTestCode('''
class C {
  int get one => 1;
  C(this.oen);
}
''');
    await assertNoFix();
  }

  Future<void> test_fieldFormalParameter_initializer() async {
    await resolveTestCode('''
class C {
  int one;
  C(this.oen): one = 1;
}
''');
    await assertNoFix();
  }

  Future<void> test_fieldFormalParameter_used() async {
    await resolveTestCode('''
class C {
  int one;
  C(this.one, this.oen);
}
''');
    await assertNoFix();
  }

  Future<void> test_fieldFormalParameter_withoutType() async {
    await resolveTestCode('''
class C {
  var one;
  C(this.oen);
}
''');
    await assertHasFix('''
class C {
  var one;
  C(this.one);
}
''');
  }

  Future<void> test_fieldFormalParameter_withType() async {
    await resolveTestCode('''
class C {
  int one = 1;
  var done = '';
  C(String this.on);
}
''');
    await assertHasFix('''
class C {
  int one = 1;
  var done = '';
  C(String this.done);
}
''');
  }

  Future<void> test_function_fromImport() async {
    await resolveTestCode('''
void f() {
  pritn(0);
}
''');
    await assertHasFix('''
void f() {
  print(0);
}
''');
  }

  Future<void> test_function_prefixed_fromImport() async {
    await resolveTestCode('''
import 'dart:core' as c;
void f() {
  c.prnt(42);
}
''');
    await assertHasFix('''
import 'dart:core' as c;
void f() {
  c.print(42);
}
''');
  }

  Future<void> test_function_prefixed_ignoreLocal() async {
    await resolveTestCode('''
import 'dart:async' as c;
void f() {
  c.f();
}
''');
    await assertNoFix();
  }

  Future<void> test_function_thisLibrary() async {
    await resolveTestCode('''
myFunction() {}
void f() {
  myFuntcion();
}
''');
    await assertHasFix('''
myFunction() {}
void f() {
  myFunction();
}
''');
  }

  Future<void> test_getter_hint() async {
    await resolveTestCode('''
class A {
  int myField = 0;
}
void f(A a) {
  var x = a;
  print(x.myFild);
}
''');
    await assertHasFix('''
class A {
  int myField = 0;
}
void f(A a) {
  var x = a;
  print(x.myField);
}
''');
  }

  Future<void> test_getter_override() async {
    await resolveTestCode('''
extension E on int {
  int get myGetter => 0;
}
void f() {
  E(1).myGeter;
}
''');
    await assertHasFix('''
extension E on int {
  int get myGetter => 0;
}
void f() {
  E(1).myGetter;
}
''');
  }

  Future<void> test_getter_qualified() async {
    await resolveTestCode('''
class A {
  int myField = 0;
}
void f(A a) {
  print(a.myFild);
}
''');
    await assertHasFix('''
class A {
  int myField = 0;
}
void f(A a) {
  print(a.myField);
}
''');
  }

  Future<void> test_getter_qualified_static() async {
    await resolveTestCode('''
class A {
  static int MY_NAME = 1;
}
void f() {
  A.MY_NAM;
}
''');
    await assertHasFix('''
class A {
  static int MY_NAME = 1;
}
void f() {
  A.MY_NAME;
}
''');
  }

  Future<void> test_getter_static() async {
    await resolveTestCode('''
extension E on int {
  static int get myGetter => 0;
}
void f() {
  E.myGeter;
}
''');
    await assertHasFix('''
extension E on int {
  static int get myGetter => 0;
}
void f() {
  E.myGetter;
}
''');
  }

  Future<void> test_getter_unqualified() async {
    await resolveTestCode('''
class A {
  int myField = 0;
  void f() {
    print(myFild);
  }
}
''');
    await assertHasFix('''
class A {
  int myField = 0;
  void f() {
    print(myField);
  }
}
''');
  }

  Future<void> test_getterSetter_qualified() async {
    await resolveTestCode('''
class A {
  int get foo => 0;
  set foo(int _) {}
}

void f(A a) {
  a.foo2 += 2;
}
''');
    await assertHasFix('''
class A {
  int get foo => 0;
  set foo(int _) {}
}

void f(A a) {
  a.foo += 2;
}
''', errorFilter: (e) => e.errorCode == CompileTimeErrorCode.UNDEFINED_GETTER);
  }

  Future<void> test_getterSetter_qualified_static() async {
    await resolveTestCode('''
class A {
  static int get foo => 0;
  static set foo(int _) {}
}

void f() {
  A.foo2 += 2;
}
''');
    await assertHasFix('''
class A {
  static int get foo => 0;
  static set foo(int _) {}
}

void f() {
  A.foo += 2;
}
''', errorFilter: (e) => e.errorCode == CompileTimeErrorCode.UNDEFINED_GETTER);
  }

  Future<void> test_getterSetter_unqualified() async {
    await resolveTestCode('''
class A {
  int get foo => 0;
  set foo(int _) {}

  void f() {
    foo2 += 2;
  }
}
''');
    await assertHasFix('''
class A {
  int get foo => 0;
  set foo(int _) {}

  void f() {
    foo += 2;
  }
}
''');
  }

  Future<void> test_method_ignoreOperators() async {
    await resolveTestCode('''
void f(Object object) {
  object.then();
}
''');
    await assertNoFix();
  }

  Future<void> test_method_override() async {
    await resolveTestCode('''
extension E on int {
  int myMethod() => 0;
}
void f() {
  E(1).myMetod();
}
''');
    await assertHasFix('''
extension E on int {
  int myMethod() => 0;
}
void f() {
  E(1).myMethod();
}
''');
  }

  Future<void> test_method_qualified() async {
    await resolveTestCode('''
class A {
  myMethod() {}
}
void f() {
  A a = new A();
  a.myMehtod();
}
''');
    await assertHasFix('''
class A {
  myMethod() {}
}
void f() {
  A a = new A();
  a.myMethod();
}
''');
  }

  Future<void> test_method_static() async {
    await resolveTestCode('''
extension E on int {
  static int myMethod() => 0;
}
void f() {
  E.myMetod();
}
''');
    await assertHasFix('''
extension E on int {
  static int myMethod() => 0;
}
void f() {
  E.myMethod();
}
''');
  }

  Future<void> test_method_unqualified_superClass() async {
    await resolveTestCode('''
class A {
  myMethod() {}
}
class B extends A {
  void f() {
    myMehtod();
  }
}
''');
    await assertHasFix('''
class A {
  myMethod() {}
}
class B extends A {
  void f() {
    myMethod();
  }
}
''');
  }

  Future<void> test_method_unqualified_thisClass() async {
    await resolveTestCode('''
class A {
  myMethod() {}
  void f() {
    myMehtod();
  }
}
''');
    await assertHasFix('''
class A {
  myMethod() {}
  void f() {
    myMethod();
  }
}
''');
  }

  Future<void> test_setter_hint() async {
    await resolveTestCode('''
class A {
  int myField = 0;
}
void f(A a) {
  var x = a;
  x.myFild = 42;
}
''');
    await assertHasFix('''
class A {
  int myField = 0;
}
void f(A a) {
  var x = a;
  x.myField = 42;
}
''');
  }

  Future<void> test_setter_override() async {
    await resolveTestCode('''
extension E on int {
  void set mySetter(int i) {}
}
void f() {
  E(1).mySeter = 0;
}
''');
    await assertHasFix('''
extension E on int {
  void set mySetter(int i) {}
}
void f() {
  E(1).mySetter = 0;
}
''');
  }

  Future<void> test_setter_qualified() async {
    await resolveTestCode('''
class A {
  int myField = 0;
}
void f(A a) {
  a.myFild = 42;
}
''');
    await assertHasFix('''
class A {
  int myField = 0;
}
void f(A a) {
  a.myField = 42;
}
''');
  }

  Future<void> test_setter_static() async {
    await resolveTestCode('''
extension E on int {
  static void set mySetter(int i) {}
}
void f() {
  E.mySeter = 0;
}
''');
    await assertHasFix('''
extension E on int {
  static void set mySetter(int i) {}
}
void f() {
  E.mySetter = 0;
}
''');
  }

  Future<void> test_setter_unqualified() async {
    await resolveTestCode('''
class A {
  int myField = 0;
  void f() {
    myFild = 42;
  }
}
''');
    await assertHasFix('''
class A {
  int myField = 0;
  void f() {
    myField = 42;
  }
}
''');
  }

  Future<void> test_super_formal_parameter() async {
    await resolveTestCode('''
class A {
  A({int? one});
}

class B extends A {
  B({super.oen});
}
''');
    await assertHasFix('''
class A {
  A({int? one});
}

class B extends A {
  B({super.one});
}
''');
  }

  Future<void> test_super_formal_parameter_initializer() async {
    await resolveTestCode('''
class A {
  A.n1({int? one});
}

class B extends A {
  B.n2({super.oen}) : super.n1();
}
''');
    await assertHasFix('''
class A {
  A.n1({int? one});
}

class B extends A {
  B.n2({super.one}) : super.n1();
}
''');
  }

  Future<void> test_super_formal_parameter_initializer_named() async {
    await resolveTestCode('''
class A {
  A(int? one, {int? done});
}

class B extends A {
  B.n({super.ne}) : super(1);
}
''');
    await assertHasFix('''
class A {
  A(int? one, {int? done});
}

class B extends A {
  B.n({super.done}) : super(1);
}
''');
  }

  Future<void> test_super_formal_parameter_name_empty() async {
    await resolveTestCode('''
class A {
  A(int? one, {int? done});
}

class B extends A {
  B(super.one, {super.ne});
}
''');
    await assertHasFix('''
class A {
  A(int? one, {int? done});
}

class B extends A {
  B(super.one, {super.done});
}
''');
  }

  Future<void> test_super_formal_parameter_named() async {
    await resolveTestCode('''
class A {
  A({int? one});
}

class B extends A {
  B.n({super.oen});
}
''');
    await assertHasFix('''
class A {
  A({int? one});
}

class B extends A {
  B.n({super.one});
}
''');
  }

  Future<void> test_super_formal_parameter_used() async {
    await resolveTestCode('''
class A {
  A({int? one, int? done});
}

class B extends A {
  B({super.one, super.ne});
}
''');
    await assertHasFix('''
class A {
  A({int? one, int? done});
}

class B extends A {
  B({super.one, super.done});
}
''');
  }
}
