// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CreateFieldTest);
    defineReflectiveTests(CreateFieldMixinTest);
  });
}

@reflectiveTest
class CreateFieldMixinTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.CREATE_FIELD;

  test_getter_qualified_instance() async {
    await resolveTestUnit('''
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

  test_setter_qualified_instance_hasField() async {
    await resolveTestUnit('''
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

  test_getter_multiLevel() async {
    await resolveTestUnit('''
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

  test_getter_qualified_instance() async {
    await resolveTestUnit('''
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

  test_getter_qualified_instance_differentLibrary() async {
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

    await resolveTestUnit('''
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

  test_getter_qualified_instance_dynamicType() async {
    await resolveTestUnit('''
class A {
  B b;
  void f(Object p) {
    p == b.test;
  }
}
class B {
}
''');
    await assertHasFix('''
class A {
  B b;
  void f(Object p) {
    p == b.test;
  }
}
class B {
  var test;
}
''');
  }

  test_getter_qualified_propagatedType() async {
    await resolveTestUnit('''
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

  test_getter_unqualified_instance_asInvocationArgument() async {
    await resolveTestUnit('''
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

  test_getter_unqualified_instance_assignmentRhs() async {
    await resolveTestUnit('''
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

  test_getter_unqualified_instance_asStatement() async {
    await resolveTestUnit('''
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

  test_hint() async {
    await resolveTestUnit('''
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

  test_hint_setter() async {
    await resolveTestUnit('''
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

  test_importType() async {
    addSource('/home/test/lib/a.dart', r'''
class A {}
''');

    addSource('/home/test/lib/b.dart', r'''
import 'package:test/a.dart';

A getA() => null;
''');

    await resolveTestUnit('''
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

  test_inEnum() async {
    await resolveTestUnit('''
enum MyEnum {
  AAA, BBB
}
main() {
  MyEnum.foo;
}
''');
    await assertNoFix();
  }

  test_inSDK() async {
    await resolveTestUnit('''
main(List p) {
  p.foo = 1;
}
''');
    await assertNoFix();
  }

  test_invalidInitializer_withoutType() async {
    await resolveTestUnit('''
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

  test_invalidInitializer_withType() async {
    await resolveTestUnit('''
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

  test_setter_generic_BAD() async {
    await resolveTestUnit('''
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

  test_setter_generic_OK_local() async {
    await resolveTestUnit('''
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

  test_setter_qualified_instance_hasField() async {
    await resolveTestUnit('''
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

  test_setter_qualified_instance_hasMethod() async {
    await resolveTestUnit('''
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

  test_setter_qualified_static() async {
    await resolveTestUnit('''
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

  test_setter_unqualified_instance() async {
    await resolveTestUnit('''
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

  test_setter_unqualified_static() async {
    await resolveTestUnit('''
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
