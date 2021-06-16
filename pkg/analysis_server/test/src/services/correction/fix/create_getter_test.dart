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
    defineReflectiveTests(CreateGetterTest);
    defineReflectiveTests(CreateGetterMixinTest);
  });
}

@reflectiveTest
class CreateGetterMixinTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.CREATE_GETTER;

  Future<void> test_qualified_instance() async {
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
  int get test => null;
}

main(M m) {
  int v = m.test;
  print(v);
}
''');
  }

  Future<void> test_unqualified_instance_assignmentLhs() async {
    await resolveTestCode('''
mixin M {
  main() {
    test = 42;
  }
}
''');
    await assertNoFix();
  }

  Future<void> test_unqualified_instance_assignmentRhs() async {
    await resolveTestCode('''
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

  Future<void> test_hint_getter() async {
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
  int get test => null;
}
main(A a) {
  var x = a;
  int v = x.test;
  print(v);
}
''');
  }

  Future<void> test_inSDK() async {
    await resolveTestCode('''
main(List p) {
  int v = p.foo;
  print(v);
}
''');
    await assertNoFix();
  }

  Future<void> test_internal_instance() async {
    await resolveTestCode('''
extension E on String {
  int m()  => g;
}
''');
    await assertHasFix('''
extension E on String {
  get g => null;

  int m()  => g;
}
''');
  }

  Future<void> test_internal_static() async {
    await resolveTestCode('''
extension E on String {
  static int m()  => g;
}
''');
    await assertHasFix('''
extension E on String {
  static get g => null;

  static int m()  => g;
}
''');
  }

  Future<void> test_location_afterLastGetter() async {
    await resolveTestCode('''
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

  Future<void> test_override() async {
    await resolveTestCode('''
extension E on String {
}

main(String s) {
  int v = E(s).test;
  print(v);
}
''');
    await assertHasFix('''
extension E on String {
  int get test => null;
}

main(String s) {
  int v = E(s).test;
  print(v);
}
''');
  }

  Future<void> test_qualified_instance() async {
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
  int get test => null;
}
main(A a) {
  int v = a.test;
  print(v);
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

  Future<void> test_qualified_instance_dynamicType() async {
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
  get test => null;
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
  int v = a.test;
  print(v);
}
''');
    await assertNoFix(errorFilter: (e) {
      return e.errorCode == CompileTimeErrorCode.UNDEFINED_GETTER;
    });
  }

  Future<void> test_qualified_instance_inPart_self() async {
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

  Future<void> test_qualified_propagatedType() async {
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

  Future<void> test_setterContext() async {
    await resolveTestCode('''
class A {
}
main(A a) {
  a.test = 42;
}
''');
    await assertNoFix();
  }

  Future<void> test_static() async {
    await resolveTestCode('''
extension E on String {
}

main(String s) {
  int v = E.test;
  print(v);
}
''');
    await assertHasFix('''
extension E on String {
  static int get test => null;
}

main(String s) {
  int v = E.test;
  print(v);
}
''');
  }

  Future<void> test_unqualified_instance_asInvocationArgument() async {
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
  String get test => null;

  main() {
    f(test);
  }
}
f(String s) {}
''');
  }

  Future<void> test_unqualified_instance_assignmentLhs() async {
    await resolveTestCode('''
class A {
  main() {
    test = 42;
  }
}
''');
    await assertNoFix();
  }

  Future<void> test_unqualified_instance_assignmentRhs() async {
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
  int get test => null;

  main() {
    int v = test;
    print(v);
  }
}
''');
  }

  Future<void> test_unqualified_instance_asStatement() async {
    await resolveTestCode('''
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
