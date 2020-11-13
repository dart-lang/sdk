// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CreateSetterTest);
    defineReflectiveTests(CreateSetterMixinTest);
  });
}

@reflectiveTest
class CreateSetterMixinTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.CREATE_SETTER;

  Future<void> test_qualified_instance() async {
    await resolveTestCode('''
mixin M {
}

main(M m) {
  m.test = 0;
}
''');
    await assertHasFix('''
mixin M {
  set test(int test) {}
}

main(M m) {
  m.test = 0;
}
''');
  }

  Future<void> test_unqualified_instance_assignmentLhs() async {
    await resolveTestCode('''
mixin M {
  main() {
    test = 0;
  }
}
''');
    await assertHasFix('''
mixin M {
  set test(int test) {}

  main() {
    test = 0;
  }
}
''');
  }

  Future<void> test_unqualified_instance_assignmentRhs() async {
    await resolveTestCode('''
mixin M {
  main() {
    test;
  }
}
''');
    await assertNoFix();
  }
}

@reflectiveTest
class CreateSetterTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.CREATE_SETTER;

  Future<void> test_getterContext() async {
    await resolveTestCode('''
class A {
}
main(A a) {
  a.test;
}
''');
    await assertNoFix();
  }

  Future<void> test_inferredTargetType() async {
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
  set test(int test) {}
}
main(A a) {
  var x = a;
  x.test = 0;
}
''');
  }

  Future<void> test_inSDK() async {
    await resolveTestCode('''
main(List p) {
  p.foo = 0;
}
''');
    await assertNoFix();
  }

  Future<void> test_internal_instance() async {
    await resolveTestCode('''
extension E on String {
  int m(int x) => s = x;
}
''');
    await assertHasFix('''
extension E on String {
  set s(int s) {}

  int m(int x) => s = x;
}
''');
  }

  Future<void> test_internal_static() async {
    await resolveTestCode('''
extension E on String {
  static int m(int x) => s = x;
}
''');
    await assertHasFix('''
extension E on String {
  static set s(int s) {}

  static int m(int x) => s = x;
}
''');
  }

  Future<void> test_location_afterLastAccessor() async {
    await resolveTestCode('''
class A {
  int existingField;

  int get existingGetter => null;

  existingMethod() {}
}
main(A a) {
  a.test = 0;
}
''');
    await assertHasFix('''
class A {
  int existingField;

  int get existingGetter => null;

  set test(int test) {}

  existingMethod() {}
}
main(A a) {
  a.test = 0;
}
''');
  }

  Future<void> test_multiLevel() async {
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
  c.b.a.test = 0;
}
''');
    await assertHasFix('''
class A {
  set test(int test) {}
}
class B {
  A a;
}
class C {
  B b;
}
main(C c) {
  c.b.a.test = 0;
}
''');
  }

  Future<void> test_override() async {
    await resolveTestCode('''
extension E on String {
}

main(String s) {
  E(s).test = '0';
}
''');
    await assertHasFix('''
extension E on String {
  set test(String test) {}
}

main(String s) {
  E(s).test = '0';
}
''');
  }

  Future<void> test_qualified_instance() async {
    await resolveTestCode('''
class A {
}
main(A a) {
  a.test = 0;
}
''');
    await assertHasFix('''
class A {
  set test(int test) {}
}
main(A a) {
  a.test = 0;
}
''');
  }

  Future<void> test_qualified_instance_differentLibrary() async {
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
  a.test = 0;
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
  set test(int test) {}
}
''', target: '/home/test/lib/other.dart');
  }

  Future<void> test_qualified_instance_dynamicType() async {
    await resolveTestCode('''
class A {
  B b;
  void f(p) {
    b.test = p;
  }
}
class B {
}
''');
    await assertHasFix('''
class A {
  B b;
  void f(p) {
    b.test = p;
  }
}
class B {
  set test(test) {}
}
''');
  }

  Future<void> test_qualified_instance_inPart_imported() async {
    addSource('/home/test/lib/a.dart', '''
part of lib;

class A {}
''');

    await resolveTestCode('''
import 'package:test/a.dart';

main(A a) {
  a.test = 0;
}
''');
    await assertNoFix(errorFilter: (e) {
      return e.errorCode == CompileTimeErrorCode.UNDEFINED_SETTER;
    });
  }

  Future<void> test_qualified_instance_inPart_self() async {
    await resolveTestCode('''
part of lib;

class A {
}

main(A a) {
  a.test = 0;
}
''');
    await assertNoFix();
  }

  Future<void> test_qualified_propagatedType() async {
    await resolveTestCode('''
class A {
  A get self => this;
}
main() {
  var a = new A();
  a.self.test = 0;
}
''');
    await assertHasFix('''
class A {
  A get self => this;

  set test(int test) {}
}
main() {
  var a = new A();
  a.self.test = 0;
}
''');
  }

  Future<void> test_static() async {
    await resolveTestCode('''
extension E on String {
}

main(String s) {
  E.test = 0;
}
''');
    await assertHasFix('''
extension E on String {
  static set test(int test) {}
}

main(String s) {
  E.test = 0;
}
''');
  }

  Future<void> test_unqualified_instance_assignmentLhs() async {
    await resolveTestCode('''
class A {
  main() {
    test = 0;
  }
}
''');
    await assertHasFix('''
class A {
  set test(int test) {}

  main() {
    test = 0;
  }
}
''');
  }

  Future<void> test_unqualified_instance_assignmentRhs() async {
    await resolveTestCode('''
class A {
  main() {
    test;
  }
}
''');
    await assertNoFix();
  }
}
