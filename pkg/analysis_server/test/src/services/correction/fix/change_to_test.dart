// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
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
    await resolveTestUnit('''
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
    // TODO(brianwilkerson) Add support for suggesting similar top-level
    //  variables.
    await resolveTestUnit('''
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
    await resolveTestUnit('''
class MyClass extends BaseClssa {}

class BaseClass {}
''');
    await assertHasFix('''
class MyClass extends BaseClass {}

class BaseClass {}
''');
  }

  Future<void> test_class_fromImport() async {
    await resolveTestUnit('''
main() {
  Stirng s = 'abc';
  print(s);
}
''');
    await assertHasFix('''
main() {
  String s = 'abc';
  print(s);
}
''');
  }

  Future<void> test_class_fromThisLibrary() async {
    await resolveTestUnit('''
class MyClass {}
main() {
  MyCalss v = null;
  print(v);
}
''');
    await assertHasFix('''
class MyClass {}
main() {
  MyClass v = null;
  print(v);
}
''');
  }

  Future<void> test_class_implements() async {
    await resolveTestUnit('''
class MyClass implements BaseClssa {}

class BaseClass {}
''');
    await assertHasFix('''
class MyClass implements BaseClass {}

class BaseClass {}
''');
  }

  Future<void> test_class_prefixed() async {
    await resolveTestUnit('''
import 'dart:async' as c;
main() {
  c.Fture v = null;
  print(v);
}
''');
    await assertHasFix('''
import 'dart:async' as c;
main() {
  c.Future v = null;
  print(v);
}
''');
  }

  Future<void> test_class_with() async {
    await resolveTestUnit('''
class MyClass with BaseClssa {}

class BaseClass {}
''');
    await assertHasFix('''
class MyClass with BaseClass {}

class BaseClass {}
''');
  }

  Future<void> test_function_fromImport() async {
    await resolveTestUnit('''
main() {
  pritn(0);
}
''');
    await assertHasFix('''
main() {
  print(0);
}
''');
  }

  Future<void> test_function_prefixed_fromImport() async {
    await resolveTestUnit('''
import 'dart:core' as c;
main() {
  c.prnt(42);
}
''');
    await assertHasFix('''
import 'dart:core' as c;
main() {
  c.print(42);
}
''');
  }

  Future<void> test_function_prefixed_ignoreLocal() async {
    await resolveTestUnit('''
import 'dart:async' as c;
main() {
  c.main();
}
''');
    await assertNoFix();
  }

  Future<void> test_function_thisLibrary() async {
    await resolveTestUnit('''
myFunction() {}
main() {
  myFuntcion();
}
''');
    await assertHasFix('''
myFunction() {}
main() {
  myFunction();
}
''');
  }

  Future<void> test_getter_hint() async {
    await resolveTestUnit('''
class A {
  int myField;
}
main(A a) {
  var x = a;
  print(x.myFild);
}
''');
    await assertHasFix('''
class A {
  int myField;
}
main(A a) {
  var x = a;
  print(x.myField);
}
''');
  }

  Future<void> test_getter_override() async {
    await resolveTestUnit('''
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
    await resolveTestUnit('''
class A {
  int myField;
}
main(A a) {
  print(a.myFild);
}
''');
    await assertHasFix('''
class A {
  int myField;
}
main(A a) {
  print(a.myField);
}
''');
  }

  Future<void> test_getter_qualified_static() async {
    await resolveTestUnit('''
class A {
  static int MY_NAME = 1;
}
main() {
  A.MY_NAM;
}
''');
    await assertHasFix('''
class A {
  static int MY_NAME = 1;
}
main() {
  A.MY_NAME;
}
''');
  }

  Future<void> test_getter_static() async {
    await resolveTestUnit('''
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
    await resolveTestUnit('''
class A {
  int myField;
  main() {
    print(myFild);
  }
}
''');
    await assertHasFix('''
class A {
  int myField;
  main() {
    print(myField);
  }
}
''');
  }

  Future<void> test_method_ignoreOperators() async {
    await resolveTestUnit('''
main(Object object) {
  object.then();
}
''');
    await assertNoFix();
  }

  Future<void> test_method_override() async {
    await resolveTestUnit('''
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
    await resolveTestUnit('''
class A {
  myMethod() {}
}
main() {
  A a = new A();
  a.myMehtod();
}
''');
    await assertHasFix('''
class A {
  myMethod() {}
}
main() {
  A a = new A();
  a.myMethod();
}
''');
  }

  Future<void> test_method_static() async {
    await resolveTestUnit('''
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
    await resolveTestUnit('''
class A {
  myMethod() {}
}
class B extends A {
  main() {
    myMehtod();
  }
}
''');
    await assertHasFix('''
class A {
  myMethod() {}
}
class B extends A {
  main() {
    myMethod();
  }
}
''');
  }

  Future<void> test_method_unqualified_thisClass() async {
    await resolveTestUnit('''
class A {
  myMethod() {}
  main() {
    myMehtod();
  }
}
''');
    await assertHasFix('''
class A {
  myMethod() {}
  main() {
    myMethod();
  }
}
''');
  }

  Future<void> test_setter_hint() async {
    await resolveTestUnit('''
class A {
  int myField;
}
main(A a) {
  var x = a;
  x.myFild = 42;
}
''');
    await assertHasFix('''
class A {
  int myField;
}
main(A a) {
  var x = a;
  x.myField = 42;
}
''');
  }

  Future<void> test_setter_override() async {
    await resolveTestUnit('''
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
    await resolveTestUnit('''
class A {
  int myField;
}
main(A a) {
  a.myFild = 42;
}
''');
    await assertHasFix('''
class A {
  int myField;
}
main(A a) {
  a.myField = 42;
}
''');
  }

  Future<void> test_setter_static() async {
    await resolveTestUnit('''
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
    await resolveTestUnit('''
class A {
  int myField;
  main() {
    myFild = 42;
  }
}
''');
    await assertHasFix('''
class A {
  int myField;
  main() {
    myField = 42;
  }
}
''');
  }
}
