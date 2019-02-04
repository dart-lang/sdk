// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CreateGetterTest);
    defineReflectiveTests(CreateGetterMixinTest);
  });
}

@reflectiveTest
class CreateGetterMixinTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.CREATE_GETTER;

  test_qualified_instance() async {
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
  int get test => null;
}

main(M m) {
  int v = m.test;
  print(v);
}
''');
  }

  test_unqualified_instance_assignmentLhs() async {
    await resolveTestUnit('''
mixin M {
  main() {
    test = 42;
  }
}
''');
    await assertNoFix();
  }

  test_unqualified_instance_assignmentRhs() async {
    await resolveTestUnit('''
mixin M {
  main() {
    int v = test;
    print(v);
  }
}
''');
    await assertHasFix('''
mixin M {
  int get test => null;

  main() {
    int v = test;
    print(v);
  }
}
''');
  }
}

@reflectiveTest
class CreateGetterTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.CREATE_GETTER;

  test_hint_getter() async {
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
  int get test => null;
}
main(A a) {
  var x = a;
  int v = x.test;
  print(v);
}
''');
  }

  test_inSDK() async {
    await resolveTestUnit('''
main(List p) {
  int v = p.foo;
  print(v);
}
''');
    await assertNoFix();
  }

  test_location_afterLastGetter() async {
    await resolveTestUnit('''
class A {
  int existingField;

  int get existingGetter => null;

  existingMethod() {}
}
main(A a) {
  int v = a.test;
  print(v);
}
''');
    await assertHasFix('''
class A {
  int existingField;

  int get existingGetter => null;

  int get test => null;

  existingMethod() {}
}
main(A a) {
  int v = a.test;
  print(v);
}
''');
  }

  test_multiLevel() async {
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
  int get test => null;
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

  test_qualified_instance() async {
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
  int get test => null;
}
main(A a) {
  int v = a.test;
  print(v);
}
''');
  }

  test_qualified_instance_differentLibrary() async {
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
  int get test => null;
}
''', target: '/home/test/lib/other.dart');
  }

  test_qualified_instance_dynamicType() async {
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
  get test => null;
}
''');
  }

  test_qualified_propagatedType() async {
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
  A get self => this;

  int get test => null;
}
main() {
  var a = new A();
  int v = a.self.test;
  print(v);
}
''');
  }

  test_setterContext() async {
    await resolveTestUnit('''
class A {
}
main(A a) {
  a.test = 42;
}
''');
    await assertNoFix();
  }

  test_unqualified_instance_asInvocationArgument() async {
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
  String get test => null;

  main() {
    f(test);
  }
}
f(String s) {}
''');
  }

  test_unqualified_instance_assignmentLhs() async {
    await resolveTestUnit('''
class A {
  main() {
    test = 42;
  }
}
''');
    await assertNoFix();
  }

  test_unqualified_instance_assignmentRhs() async {
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
  int get test => null;

  main() {
    int v = test;
    print(v);
  }
}
''');
  }

  test_unqualified_instance_asStatement() async {
    await resolveTestUnit('''
class A {
  main() {
    test;
  }
}
''');
    await assertHasFix('''
class A {
  get test => null;

  main() {
    test;
  }
}
''');
  }
}
