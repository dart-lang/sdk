// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidUseOfProtectedMemberTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
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
    var lib1 = getFile('$testPackageLibPath/lib1.dart');
    var lib2 = getFile('$testPackageLibPath/lib2.dart');

    await resolveFileWithDiagnostics(lib1, r'''
import 'package:meta/meta.dart';

class A {
  @protected
  int a() => 42;
}
''');

    await resolveFileWithDiagnostics(lib2, r'''
import 'lib1.dart';

void main() {
  var leak = new A().a;
//                   ^
// [diag.invalidUseOfProtectedMember] The member 'a' can only be used within instance members of subclasses of 'A'.
  print(leak);
}
''');
  }

  test_extendingSubclass() async {
    await resolveTestCodeWithDiagnostics(r'''
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
    var lib1 = getFile('$testPackageLibPath/lib1.dart');
    var lib2 = getFile('$testPackageLibPath/lib2.dart');

    await resolveFileWithDiagnostics(lib1, r'''
import 'package:meta/meta.dart';
class A {
  @protected
  void a(int i) {}
}
''');

    await resolveFileWithDiagnostics(lib2, r'''
import 'lib1.dart';
extension E on A {
  e() {
    a(7);
//  ^
// [diag.invalidUseOfProtectedMember] The member 'a' can only be used within instance members of subclasses of 'A'.
  }
}
''');
  }

  test_extensionType_implementedMember() async {
    await resolveTestCodeWithDiagnostics(r'''
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
    var lib1 = getFile('$testPackageLibPath/lib1.dart');
    var lib2 = getFile('$testPackageLibPath/lib2.dart');

    await resolveFileWithDiagnostics(lib1, r'''
import 'package:meta/meta.dart';
class C {
  @protected
  void f(){}
}
extension type E(C c) implements C { }
''');

    await resolveFileWithDiagnostics(lib2, r'''
import 'lib1.dart';
void main() {
  E(C()).f();
//       ^
// [diag.invalidUseOfProtectedMember] The member 'f' can only be used within instance members of subclasses of 'C'.
}
''');
  }

  test_extensionType_member() async {
    await resolveTestCodeWithDiagnostics(r'''
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
    var lib1 = getFile('$testPackageLibPath/lib1.dart');
    var lib2 = getFile('$testPackageLibPath/lib2.dart');

    await resolveFileWithDiagnostics(lib1, r'''
import 'package:meta/meta.dart';
extension type E(int i) {
  @protected
  void f(){}
}
''');

    await resolveFileWithDiagnostics(lib2, r'''
import 'lib1.dart';
void main() {
  E(1).f();
//     ^
// [diag.invalidUseOfProtectedMember] The member 'f' can only be used within instance members of subclasses of 'E'.
}
''');
  }

  test_field() async {
    await resolveTestCodeWithDiagnostics(r'''
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
    var lib1 = getFile('$testPackageLibPath/lib1.dart');
    var lib2 = getFile('$testPackageLibPath/lib2.dart');

    await resolveFileWithDiagnostics(lib1, r'''
import 'package:meta/meta.dart';
class A {
  @protected
  int f = 0;
}
''');

    await resolveFileWithDiagnostics(lib2, r'''
import 'lib1.dart';
abstract class B {
  int m(A a) => a.f;
//                ^
// [diag.invalidUseOfProtectedMember] The member 'f' can only be used within instance members of subclasses of 'A'.
}
''');
  }

  test_field_outsideClassAndLibrary_originPrimaryConstructor() async {
    var lib1 = getFile('$testPackageLibPath/lib1.dart');
    var lib2 = getFile('$testPackageLibPath/lib2.dart');

    await resolveFileWithDiagnostics(lib1, r'''
import 'package:meta/meta.dart';
class A(@protected var int f);
''');

    await resolveFileWithDiagnostics(lib2, r'''
import 'lib1.dart';
abstract class B {
  int m(A a) => a.f;
//                ^
// [diag.invalidUseOfProtectedMember] The member 'f' can only be used within instance members of subclasses of 'A'.
}
''');
  }

  test_field_subclassAndSameLibrary() async {
    await resolveTestCodeWithDiagnostics(r'''
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
    var lib1 = getFile('$testPackageLibPath/lib1.dart');
    var lib2 = getFile('$testPackageLibPath/lib2.dart');

    await resolveFileWithDiagnostics(lib1, r'''
import 'package:meta/meta.dart';
abstract class A {
  @protected
  void foo() {}
}
''');

    await resolveFileWithDiagnostics(lib2, r'''
import 'lib1.dart';
mixin M on A {
  @override
  void foo() {
    super.foo();
  }
}
''');
  }

  test_function_outsideClassAndLibrary() async {
    var lib1 = getFile('$testPackageLibPath/lib1.dart');
    var lib2 = getFile('$testPackageLibPath/lib2.dart');

    await resolveFileWithDiagnostics(lib1, r'''
import 'package:meta/meta.dart';
class A {
  @protected
  void a(){ }
}
''');

    await resolveFileWithDiagnostics(lib2, r'''
import 'lib1.dart';

main() {
  new A().a();
//        ^
// [diag.invalidUseOfProtectedMember] The member 'a' can only be used within instance members of subclasses of 'A'.
}
''');
  }

  test_function_sameLibrary() async {
    await resolveTestCodeWithDiagnostics(r'''
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
    await resolveTestCodeWithDiagnostics(r'''
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
    await resolveTestCodeWithDiagnostics(r'''
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
    var lib1 = getFile('$testPackageLibPath/lib1.dart');
    var lib2 = getFile('$testPackageLibPath/lib2.dart');

    await resolveFileWithDiagnostics(lib1, r'''
import 'package:meta/meta.dart';
class A {
  @protected
  int get a => 42;
}
''');

    await resolveFileWithDiagnostics(lib2, r'''
import 'lib1.dart';
class B {
  A a = A();
  int b() => a.a;
//             ^
// [diag.invalidUseOfProtectedMember] The member 'a' can only be used within instance members of subclasses of 'A'.
}
''');
  }

  test_getter_outsideClassAndLibrary_inObjectPattern() async {
    var lib1 = getFile('$testPackageLibPath/lib1.dart');
    var lib2 = getFile('$testPackageLibPath/lib2.dart');

    await resolveFileWithDiagnostics(lib1, r'''
import 'package:meta/meta.dart';
class A {
  @protected
  int get a => 42;
}
''');

    await resolveFileWithDiagnostics(lib2, r'''
import 'lib1.dart';
void f(Object o) {
  switch (o) {
    case A(a: 7): print('yes');
//         ^
// [diag.invalidUseOfProtectedMember] The member 'a' can only be used within instance members of subclasses of 'A'.
  }
}
''');
  }

  test_getter_subclass() async {
    await resolveTestCodeWithDiagnostics(r'''
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
    var lib1 = getFile('$testPackageLibPath/lib1.dart');
    var lib2 = getFile('$testPackageLibPath/lib2.dart');

    await resolveFileWithDiagnostics(lib1, r'''
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

    await resolveFileWithDiagnostics(lib2, r'''
import 'lib1.dart';
/// OK: [A.a], [A.b], [A.c].
f() {}
''');
  }

  test_method_outsideClassAndLibrary() async {
    var lib1 = getFile('$testPackageLibPath/lib1.dart');
    var lib2 = getFile('$testPackageLibPath/lib2.dart');

    await resolveFileWithDiagnostics(lib1, r'''
import 'package:meta/meta.dart';
class A {
  @protected
  void a() {}
}
''');

    await resolveFileWithDiagnostics(lib2, r'''
import 'lib1.dart';

class B {
  void b() => new A().a();
//                    ^
// [diag.invalidUseOfProtectedMember] The member 'a' can only be used within instance members of subclasses of 'A'.
}
''');
  }

  test_method_subclass() async {
    // https://github.com/dart-lang/linter/issues/257
    await resolveTestCodeWithDiagnostics(r'''
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
    await resolveTestCodeWithDiagnostics(r'''
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
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
class A {
  @protected m1() {}
}
class B extends A {
  static m2(A a) => a.m1();
}''');
  }

  test_sameLibrary() async {
    await resolveTestCodeWithDiagnostics(r'''
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
    var lib1 = getFile('$testPackageLibPath/lib1.dart');
    var lib2 = getFile('$testPackageLibPath/lib2.dart');

    await resolveFileWithDiagnostics(lib1, r'''
import 'package:meta/meta.dart';
class A {
  @protected
  void set a(int i) { }
}
''');

    await resolveFileWithDiagnostics(lib2, r'''
import 'lib1.dart';
class B {
  A a = A();
  b(int i) {
    a.a = i;
//    ^
// [diag.invalidUseOfProtectedMember] The member 'a' can only be used within instance members of subclasses of 'A'.
  }
}
''');
  }

  test_setter_sameClass() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
class A {
  int _a = 0;
//    ^^
// [diag.unusedField] The value of the field '_a' isn't used.
  @protected
  void set a(int a) { _a = a; }
  A(int a) {
    this.a = a;
  }
}
''');
  }

  test_setter_subclass() async {
    await resolveTestCodeWithDiagnostics(r'''
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
    await resolveTestCodeWithDiagnostics(r'''
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
    await resolveTestCodeWithDiagnostics(r'''
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
