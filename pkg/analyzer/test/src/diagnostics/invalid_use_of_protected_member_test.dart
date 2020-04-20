// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/test_utilities/package_mixin.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../generated/test_support.dart';
import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidUseOfProtectedMemberTest);
  });
}

@reflectiveTest
class InvalidUseOfProtectedMemberTest extends DriverResolutionTest
    with PackageMixin {
  test_closure() async {
    addMetaPackage();
    newFile('/lib1.dart', content: r'''
import 'package:meta/meta.dart';

class A {
  @protected
  int a() => 42;
}
''');
    newFile('/lib2.dart', content: r'''
import 'lib1.dart';

void main() {
  var leak = new A().a;
  print(leak);
}
''');

    await _resolveFile('/lib1.dart');
    await _resolveFile('/lib2.dart', [
      error(HintCode.INVALID_USE_OF_PROTECTED_MEMBER, 56, 1),
    ]);
  }

  test_extendingSubclass() async {
    addMetaPackage();
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
    addMetaPackage();
    newFile('/lib1.dart', content: r'''
import 'package:meta/meta.dart';
class A {
  @protected
  void a(int i) {}
}
''');
    newFile('/lib2.dart', content: r'''
import 'lib1.dart';
extension E on A {
  e() {
    a(7);
  }
}
''');

    await _resolveFile('/lib1.dart');
    await _resolveFile('/lib2.dart', [
      error(HintCode.INVALID_USE_OF_PROTECTED_MEMBER, 51, 1),
    ]);
  }

  test_field() async {
    addMetaPackage();
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
    addMetaPackage();
    newFile('/lib1.dart', content: r'''
import 'package:meta/meta.dart';
class A {
  @protected
  int a;
}
''');
    newFile('/lib2.dart', content: r'''
import 'lib1.dart';
abstract class B {
  int b() => new A().a;
}
''');

    await _resolveFile('/lib1.dart');
    await _resolveFile('/lib2.dart', [
      error(HintCode.INVALID_USE_OF_PROTECTED_MEMBER, 60, 1),
    ]);
  }

  test_field_subclassAndSameLibrary() async {
    addMetaPackage();
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';
class A {
  @protected
  int a;
}
abstract class B implements A {
  int b() => a;
}''');
  }

  test_fromSuperclassConstraint() async {
    addMetaPackage();
    newFile('/lib1.dart', content: r'''
import 'package:meta/meta.dart';
abstract class A {
  @protected
  void foo() {}
}
''');
    newFile('/lib2.dart', content: r'''
import 'lib1.dart';
mixin M on A {
  @override
  void foo() {
    super.foo();
  }
}
''');

    await _resolveFile('/lib1.dart');
    await _resolveFile('/lib2.dart');
  }

  test_function_outsideClassAndLibrary() async {
    addMetaPackage();
    newFile('/lib1.dart', content: r'''
import 'package:meta/meta.dart';
class A {
  @protected
  void a(){ }
}
''');
    newFile('/lib2.dart', content: r'''
import 'lib1.dart';

main() {
  new A().a();
}
''');

    await _resolveFile('/lib1.dart');
    await _resolveFile('/lib2.dart', [
      error(HintCode.INVALID_USE_OF_PROTECTED_MEMBER, 40, 1),
    ]);
  }

  test_function_sameLibrary() async {
    addMetaPackage();
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
    addMetaPackage();
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
    addMetaPackage();
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
    addMetaPackage();
    newFile('/lib1.dart', content: r'''
import 'package:meta/meta.dart';
class A {
  @protected
  int get a => 42;
}
''');
    newFile('/lib2.dart', content: r'''
import 'lib1.dart';
class B {
  A a;
  int b() => a.a;
}
''');

    await _resolveFile('/lib1.dart');
    await _resolveFile('/lib2.dart', [
      error(HintCode.INVALID_USE_OF_PROTECTED_MEMBER, 52, 1),
    ]);
  }

  test_getter_subclass() async {
    addMetaPackage();
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
    addMetaPackage();
    newFile('/lib1.dart', content: r'''
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
    newFile('/lib2.dart', content: r'''
import 'lib1.dart';
/// OK: [A.a], [A.b], [A.c].
f() {}
''');

    await _resolveFile('/lib1.dart');
    await _resolveFile('/lib2.dart');
  }

  test_method_outsideClassAndLibrary() async {
    addMetaPackage();
    newFile('/lib1.dart', content: r'''
import 'package:meta/meta.dart';
class A {
  @protected
  void a() {}
}
''');
    newFile('/lib2.dart', content: r'''
import 'lib1.dart';

class B {
  void b() => new A().a();
}
''');

    await _resolveFile('/lib1.dart');
    await _resolveFile('/lib2.dart', [
      error(HintCode.INVALID_USE_OF_PROTECTED_MEMBER, 53, 1),
    ]);
  }

  test_method_subclass() async {
    // https://github.com/dart-lang/linter/issues/257
    addMetaPackage();
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
    addMetaPackage();
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';
class A {
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
    addMetaPackage();
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
    addMetaPackage();
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
    addMetaPackage();
    newFile('/lib1.dart', content: r'''
import 'package:meta/meta.dart';
class A {
  @protected
  void set a(int i) { }
}
''');
    newFile('/lib2.dart', content: r'''
import 'lib1.dart';
class B {
  A a;
  b(int i) {
    a.a = i;
  }
}
''');

    await _resolveFile('/lib1.dart');
    await _resolveFile('/lib2.dart', [
      error(HintCode.INVALID_USE_OF_PROTECTED_MEMBER, 56, 1),
    ]);
  }

  test_setter_sameClass() async {
    addMetaPackage();
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';
class A {
  int _a;
  @protected
  void set a(int a) { _a = a; }
  A(int a) {
    this.a = a;
  }
}
''', [
      error(HintCode.UNUSED_FIELD, 49, 2),
    ]);
  }

  test_setter_subclass() async {
    addMetaPackage();
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
    addMetaPackage();
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
    addMetaPackage();
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';
@protected
int x = 0;
main() {
  print(x);
}''');
    // TODO(brianwilkerson) This should produce a hint because the
    // annotation is being applied to the wrong kind of declaration.
  }

  /// Resolve the file with the given [path].
  ///
  /// Similar to ResolutionTest.resolveTestFile, but a custom path is supported.
  Future<void> _resolveFile(
    String path, [
    List<ExpectedError> expectedErrors = const [],
  ]) async {
    result = await resolveFile(convertPath(path));
    assertErrorsInResolvedUnit(result, expectedErrors);
  }
}
