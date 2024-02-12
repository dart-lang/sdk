// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidUseOfProtectedMemberTest);
  });
}

@reflectiveTest
class InvalidUseOfProtectedMemberTest extends PubPackageResolutionTest {
  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfigWithMeta();
  }

  test_closure() async {
    var lib1 = newFile('$testPackageLibPath/lib1.dart', r'''
import 'package:meta/meta.dart';

class A {
  @protected
  int a() => 42;
}
''');
    var lib2 = newFile('$testPackageLibPath/lib2.dart', r'''
import 'lib1.dart';

void main() {
  var leak = new A().a;
  print(leak);
}
''');

    await assertErrorsInFile2(lib1, []);
    await assertErrorsInFile2(lib2, [
      error(WarningCode.INVALID_USE_OF_PROTECTED_MEMBER, 56, 1),
    ]);
  }

  test_extendingSubclass() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';
class A {
  @protected
  void a(){ }
}
class B extends A {
  void b() => a();
}''');
  }

  test_extension_outsideClassAndFile() async {
    var lib1 = newFile('$testPackageLibPath/lib1.dart', r'''
import 'package:meta/meta.dart';
class A {
  @protected
  void a(int i) {}
}
''');
    var lib2 = newFile('$testPackageLibPath/lib2.dart', r'''
import 'lib1.dart';
extension E on A {
  e() {
    a(7);
  }
}
''');

    await assertErrorsInFile2(lib1, []);
    await assertErrorsInFile2(lib2, [
      error(WarningCode.INVALID_USE_OF_PROTECTED_MEMBER, 51, 1),
    ]);
  }

  test_extensionType_implementedMember() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';
class C {
  @protected
  void f(){}
}
extension type E(C c) implements C { }

void main() {
  E(C()).f();
}
''');
  }

  test_extensionType_implementedMember_outsideClassAndLibrary() async {
    var lib1 = newFile('$testPackageLibPath/lib1.dart', r'''
import 'package:meta/meta.dart';
class C {
  @protected
  void f(){}
}
extension type E(C c) implements C { }
''');
    var lib2 = newFile('$testPackageLibPath/lib2.dart', r'''
import 'lib1.dart';
void main() {
  E(C()).f();
}
''');
    await assertErrorsInFile2(lib1, []);
    await assertErrorsInFile2(lib2, [
      error(WarningCode.INVALID_USE_OF_PROTECTED_MEMBER, 43, 1),
    ]);
  }

  test_extensionType_member() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';
extension type E(int i) {
  @protected
  void f(){}
}
void main() {
  E(1).f();
}
''');
  }

  test_extensionType_member_outsideClassAndLibrary() async {
    var lib1 = newFile('$testPackageLibPath/lib1.dart', r'''
import 'package:meta/meta.dart';
extension type E(int i) {
  @protected
  void f(){}
}
''');
    var lib2 = newFile('$testPackageLibPath/lib2.dart', r'''
import 'lib1.dart';
void main() {
  E(1).f();
}
''');
    await assertErrorsInFile2(lib1, []);
    await assertErrorsInFile2(lib2, [
      error(WarningCode.INVALID_USE_OF_PROTECTED_MEMBER, 41, 1),
    ]);
  }

  test_field() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';
class A {
  @protected
  int a = 42;
}
class B extends A {
  int b() => a;
}
''');
  }

  test_field_outsideClassAndLibrary() async {
    var lib1 = newFile('$testPackageLibPath/lib1.dart', r'''
import 'package:meta/meta.dart';
class A {
  @protected
  int a = 0;
}
''');
    var lib2 = newFile('$testPackageLibPath/lib2.dart', r'''
import 'lib1.dart';
abstract class B {
  int b() => new A().a;
}
''');

    await assertErrorsInFile2(lib1, []);
    await assertErrorsInFile2(lib2, [
      error(WarningCode.INVALID_USE_OF_PROTECTED_MEMBER, 60, 1),
    ]);
  }

  test_field_subclassAndSameLibrary() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';
class A {
  @protected
  int a = 0;
}
abstract class B implements A {
  int b() => a;
}''');
  }

  test_fromSuperclassConstraint() async {
    var lib1 = newFile('$testPackageLibPath/lib1.dart', r'''
import 'package:meta/meta.dart';
abstract class A {
  @protected
  void foo() {}
}
''');
    var lib2 = newFile('$testPackageLibPath/lib2.dart', r'''
import 'lib1.dart';
mixin M on A {
  @override
  void foo() {
    super.foo();
  }
}
''');

    await assertErrorsInFile2(lib1, []);
    await assertErrorsInFile2(lib2, []);
  }

  test_function_outsideClassAndLibrary() async {
    var lib1 = newFile('$testPackageLibPath/lib1.dart', r'''
import 'package:meta/meta.dart';
class A {
  @protected
  void a(){ }
}
''');
    var lib2 = newFile('$testPackageLibPath/lib2.dart', r'''
import 'lib1.dart';

main() {
  new A().a();
}
''');

    await assertErrorsInFile2(lib1, []);
    await assertErrorsInFile2(lib2, [
      error(WarningCode.INVALID_USE_OF_PROTECTED_MEMBER, 40, 1),
    ]);
  }

  test_function_sameLibrary() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';
class A {
  @protected
  void a(){ }
}
main() {
  new A().a();
}''');
  }

  test_function_subclass() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';
class A {
  @protected
  int a() => 0;
}

abstract class B implements A {
  int b() => a();
}''');
  }

  test_getter() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';
class A {
  @protected
  int get a => 42;
}
class B extends A {
  int b() => a;
}
''');
  }

  test_getter_outsideClassAndLibrary() async {
    var lib1 = newFile('$testPackageLibPath/lib1.dart', r'''
import 'package:meta/meta.dart';
class A {
  @protected
  int get a => 42;
}
''');
    var lib2 = newFile('$testPackageLibPath/lib2.dart', r'''
import 'lib1.dart';
class B {
  A a = A();
  int b() => a.a;
}
''');

    await assertErrorsInFile2(lib1, []);
    await assertErrorsInFile2(lib2, [
      error(WarningCode.INVALID_USE_OF_PROTECTED_MEMBER, 58, 1),
    ]);
  }

  test_getter_outsideClassAndLibrary_inObjectPattern() async {
    var lib1 = newFile('$testPackageLibPath/lib1.dart', r'''
import 'package:meta/meta.dart';
class A {
  @protected
  int get a => 42;
}
''');
    var lib2 = newFile('$testPackageLibPath/lib2.dart', r'''
import 'lib1.dart';
void f(Object o) {
  switch (o) {
    case A(a: 7): print('yes');
  }
}
''');

    await assertErrorsInFile2(lib1, []);
    await assertErrorsInFile2(lib2, [
      error(WarningCode.INVALID_USE_OF_PROTECTED_MEMBER, 65, 1),
    ]);
  }

  test_getter_subclass() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';
class A {
  @protected
  int get a => 42;
}
abstract class B implements A {
  int b() => a;
}''');
  }

  test_inDocs() async {
    var lib1 = newFile('$testPackageLibPath/lib1.dart', r'''
import 'package:meta/meta.dart';

class A {
  @protected
  int c = 0;

  @protected
  int get b => 0;

  @protected
  int a() => 0;
}
''');
    var lib2 = newFile('$testPackageLibPath/lib2.dart', r'''
import 'lib1.dart';
/// OK: [A.a], [A.b], [A.c].
f() {}
''');

    await assertErrorsInFile2(lib1, []);
    await assertErrorsInFile2(lib2, []);
  }

  test_method_outsideClassAndLibrary() async {
    var lib1 = newFile('$testPackageLibPath/lib1.dart', r'''
import 'package:meta/meta.dart';
class A {
  @protected
  void a() {}
}
''');
    var lib2 = newFile('$testPackageLibPath/lib2.dart', r'''
import 'lib1.dart';

class B {
  void b() => new A().a();
}
''');

    await assertErrorsInFile2(lib1, []);
    await assertErrorsInFile2(lib2, [
      error(WarningCode.INVALID_USE_OF_PROTECTED_MEMBER, 53, 1),
    ]);
  }

  test_method_subclass() async {
    // https://github.com/dart-lang/linter/issues/257
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

typedef void VoidCallback();

class State<E> {
  @protected
  void setState(VoidCallback fn) {}
}

class Button extends State<Object> {
  void handleSomething() {
    setState(() {});
  }
}
''');
  }

  test_mixingIn() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';
mixin A {
  @protected
  void a(){ }
}
class B extends Object with A {
  void b() => a();
}''');
  }

  test_mixingIn_asParameter() async {
    // TODO(srawlins): This test verifies that the analyzer **allows**
    // protected members to be called from static members, which violates the
    // protected spec.
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';
class A {
  @protected m1() {}
}
class B extends A {
  static m2(A a) => a.m1();
}''');
  }

  test_sameLibrary() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';
class A {
  @protected
  void a(){ }
}
class B extends A {
  void a() => a();
}
main() {
  new B().a();
}''');
  }

  test_setter_outsideClassAndFile() async {
    // TODO(srawlins): This test verifies that the analyzer **allows**
    // protected members to be called on objects other than `this`, which
    // violates the protected spec.
    var lib1 = newFile('$testPackageLibPath/lib1.dart', r'''
import 'package:meta/meta.dart';
class A {
  @protected
  void set a(int i) { }
}
''');
    var lib2 = newFile('$testPackageLibPath/lib2.dart', r'''
import 'lib1.dart';
class B {
  A a = A();
  b(int i) {
    a.a = i;
  }
}
''');

    await assertErrorsInFile2(lib1, []);
    await assertErrorsInFile2(lib2, [
      error(WarningCode.INVALID_USE_OF_PROTECTED_MEMBER, 62, 1),
    ]);
  }

  test_setter_sameClass() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';
class A {
  int _a = 0;
  @protected
  void set a(int a) { _a = a; }
  A(int a) {
    this.a = a;
  }
}
''', [
      error(WarningCode.UNUSED_FIELD, 49, 2),
    ]);
  }

  test_setter_subclass() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';
class A {
  @protected
  void set a(int i) { }
}
class B extends A {
  void b(int i) {
    a = i;
  }
}
''');
  }

  test_setter_subclassImplementing() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';
class A {
  @protected
  void set a(int i) { }
}
abstract class B implements A {
  b(int i) {
    a = i;
  }
}''');
  }

  test_topLevelVariable() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';
@protected
int x = 0;
main() {
  print(x);
}''');
    // TODO(brianwilkerson): This should produce a hint because the
    // annotation is being applied to the wrong kind of declaration.
  }
}
