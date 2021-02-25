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
    defineReflectiveTests(CreateFieldTest);
    defineReflectiveTests(CreateFieldMixinTest);
  });
}

@reflectiveTest
class CreateFieldMixinTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.CREATE_FIELD;

  Future<void> test_getter_qualified_instance() async {
    await resolveTestCode('''
mixin M {
}

main(M m) {
  int v = m.test;
  print(v);
}
''');
    await assertHasFix('''
mixin M {
  int test;
}

main(M m) {
  int v = m.test;
  print(v);
}
''');
  }

  Future<void> test_setter_qualified_instance_hasField() async {
    await resolveTestCode('''
mixin M {
  int aaa;
  int zzz;

  existingMethod() {}
}

main(M m) {
  m.test = 5;
}
''');
    await assertHasFix('''
mixin M {
  int aaa;
  int zzz;

  int test;

  existingMethod() {}
}

main(M m) {
  m.test = 5;
}
''');
  }
}

@reflectiveTest
class CreateFieldTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.CREATE_FIELD;

  Future<void> test_getter_multiLevel() async {
    await resolveTestCode('''
class A {
}
class B {
  A a;
}
class C {
  B b;
}
main(C c) {
  int v = c.b.a.test;
  print(v);
}
''');
    await assertHasFix('''
class A {
  int test;
}
class B {
  A a;
}
class C {
  B b;
}
main(C c) {
  int v = c.b.a.test;
  print(v);
}
''');
  }

  Future<void> test_getter_qualified_instance() async {
    await resolveTestCode('''
class A {
}
main(A a) {
  int v = a.test;
  print(v);
}
''');
    await assertHasFix('''
class A {
  int test;
}
main(A a) {
  int v = a.test;
  print(v);
}
''');
  }

  Future<void> test_getter_qualified_instance_differentLibrary() async {
    addSource('/home/test/lib/other.dart', '''
/**
 * A comment to push the offset of the braces for the following class
 * declaration past the end of the content of the test file. Used to catch an
 * index out of bounds exception that occurs when using the test source instead
 * of the target source to compute the location at which to insert the field.
 */
class A {
}
''');

    await resolveTestCode('''
import 'package:test/other.dart';

main(A a) {
  int v = a.test;
  print(v);
}
''');

    await assertHasFix('''
/**
 * A comment to push the offset of the braces for the following class
 * declaration past the end of the content of the test file. Used to catch an
 * index out of bounds exception that occurs when using the test source instead
 * of the target source to compute the location at which to insert the field.
 */
class A {
  int test;
}
''', target: '/home/test/lib/other.dart');
  }

  Future<void> test_getter_qualified_instance_dynamicType() async {
    await resolveTestCode('''
class A {
  B b;
  void f(dynamic context) {
    context + b.test;
  }
}
class B {
}
''');
    await assertHasFix('''
class A {
  B b;
  void f(dynamic context) {
    context + b.test;
  }
}
class B {
  var test;
}
''');
  }

  Future<void> test_getter_qualified_propagatedType() async {
    await resolveTestCode('''
class A {
  A get self => this;
}
main() {
  var a = new A();
  int v = a.self.test;
  print(v);
}
''');
    await assertHasFix('''
class A {
  int test;

  A get self => this;
}
main() {
  var a = new A();
  int v = a.self.test;
  print(v);
}
''');
  }

  Future<void> test_getter_unqualified_instance_asInvocationArgument() async {
    await resolveTestCode('''
class A {
  main() {
    f(test);
  }
}
f(String s) {}
''');
    await assertHasFix('''
class A {
  String test;

  main() {
    f(test);
  }
}
f(String s) {}
''');
  }

  Future<void> test_getter_unqualified_instance_assignmentRhs() async {
    await resolveTestCode('''
class A {
  main() {
    int v = test;
    print(v);
  }
}
''');
    await assertHasFix('''
class A {
  int test;

  main() {
    int v = test;
    print(v);
  }
}
''');
  }

  Future<void> test_getter_unqualified_instance_asStatement() async {
    await resolveTestCode('''
class A {
  main() {
    test;
  }
}
''');
    await assertHasFix('''
class A {
  var test;

  main() {
    test;
  }
}
''');
  }

  Future<void> test_hint() async {
    await resolveTestCode('''
class A {
}
main(A a) {
  var x = a;
  int v = x.test;
  print(v);
}
''');
    await assertHasFix('''
class A {
  int test;
}
main(A a) {
  var x = a;
  int v = x.test;
  print(v);
}
''');
  }

  Future<void> test_hint_setter() async {
    await resolveTestCode('''
class A {
}
main(A a) {
  var x = a;
  x.test = 0;
}
''');
    await assertHasFix('''
class A {
  int test;
}
main(A a) {
  var x = a;
  x.test = 0;
}
''');
  }

  Future<void> test_importType() async {
    addSource('/home/test/lib/a.dart', r'''
class A {}
''');

    addSource('/home/test/lib/b.dart', r'''
import 'package:test/a.dart';

A getA() => null;
''');

    await resolveTestCode('''
import 'package:test/b.dart';

class C {
}

main(C c) {
  c.test = getA();
}
''');

    await assertHasFix('''
import 'package:test/a.dart';
import 'package:test/b.dart';

class C {
  A test;
}

main(C c) {
  c.test = getA();
}
''');
  }

  Future<void> test_inEnum() async {
    await resolveTestCode('''
enum MyEnum {
  AAA, BBB
}
main() {
  MyEnum.foo;
}
''');
    await assertNoFix();
  }

  Future<void> test_inPart_imported() async {
    addSource('/home/test/lib/a.dart', '''
part of lib;
class A {}
''');

    await resolveTestCode('''
import 'package:test/a.dart';

main(A a) {
  int v = a.test;
  print(v);
}
''');
    await assertNoFix(errorFilter: (e) {
      return e.errorCode == CompileTimeErrorCode.UNDEFINED_GETTER;
    });
  }

  Future<void> test_inPart_self() async {
    await resolveTestCode('''
part of lib;
class A {
}
main(A a) {
  int v = a.test;
  print(v);
}
''');
    await assertNoFix();
  }

  Future<void> test_inSDK() async {
    await resolveTestCode('''
main(List p) {
  p.foo = 1;
}
''');
    await assertNoFix();
  }

  Future<void> test_invalidInitializer_withoutType() async {
    await resolveTestCode('''
class C {
  C(this.text);
}
''');
    await assertHasFix('''
class C {
  var text;

  C(this.text);
}
''');
  }

  Future<void> test_invalidInitializer_withType() async {
    await resolveTestCode('''
class C {
  C(String this.text);
}
''');
    await assertHasFix('''
class C {
  String text;

  C(String this.text);
}
''');
  }

  Future<void> test_setter_generic_BAD() async {
    await resolveTestCode('''
class A {
}
class B<T> {
  List<T> items;
  main(A a) {
    a.test = items;
  }
}
''');
    await assertHasFix('''
class A {
  List test;
}
class B<T> {
  List<T> items;
  main(A a) {
    a.test = items;
  }
}
''');
  }

  Future<void> test_setter_generic_OK_local() async {
    await resolveTestCode('''
class A<T> {
  List<T> items;

  main(A a) {
    test = items;
  }
}
''');
    await assertHasFix('''
class A<T> {
  List<T> items;

  List<T> test;

  main(A a) {
    test = items;
  }
}
''');
  }

  Future<void> test_setter_qualified_instance_hasField() async {
    await resolveTestCode('''
class A {
  int aaa;
  int zzz;

  existingMethod() {}
}
main(A a) {
  a.test = 5;
}
''');
    await assertHasFix('''
class A {
  int aaa;
  int zzz;

  int test;

  existingMethod() {}
}
main(A a) {
  a.test = 5;
}
''');
  }

  Future<void> test_setter_qualified_instance_hasMethod() async {
    await resolveTestCode('''
class A {
  existingMethod() {}
}
main(A a) {
  a.test = 5;
}
''');
    await assertHasFix('''
class A {
  int test;

  existingMethod() {}
}
main(A a) {
  a.test = 5;
}
''');
  }

  Future<void> test_setter_qualified_static() async {
    await resolveTestCode('''
class A {
}
main() {
  A.test = 5;
}
''');
    await assertHasFix('''
class A {
  static int test;
}
main() {
  A.test = 5;
}
''');
  }

  Future<void> test_setter_unqualified_instance() async {
    await resolveTestCode('''
class A {
  main() {
    test = 5;
  }
}
''');
    await assertHasFix('''
class A {
  int test;

  main() {
    test = 5;
  }
}
''');
  }

  Future<void> test_setter_unqualified_static() async {
    await resolveTestCode('''
class A {
  static main() {
    test = 5;
  }
}
''');
    await assertHasFix('''
class A {
  static int test;

  static main() {
    test = 5;
  }
}
''');
  }
}
