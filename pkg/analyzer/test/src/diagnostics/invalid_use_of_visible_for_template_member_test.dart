// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../generated/test_support.dart';
import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidUseOfVisibleForTemplateMemberTest);
  });
}

@reflectiveTest
class InvalidUseOfVisibleForTemplateMemberTest
    extends PubPackageResolutionTest {
  @override
  void setUp() {
    super.setUp();

    writeTestPackageConfig(PackageConfigFileBuilder(),
        angularMeta: true, meta: true);
  }

  test_class_constructor_named() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
import 'package:angular_meta/angular_meta.dart';

class A {
  int _x;

  @visibleForTemplate
  A.forTemplate(this._x);
}
''');
    newFile('$testPackageLibPath/lib2.dart', r'''
import 'lib1.dart';

void f() {
  new A.forTemplate(0);
}
''');

    await _resolveFile('$testPackageLibPath/lib1.dart', [
      error(WarningCode.UNUSED_FIELD, 66, 2),
    ]);
    await _resolveFile('$testPackageLibPath/lib2.dart', [
      error(WarningCode.INVALID_USE_OF_VISIBLE_FOR_TEMPLATE_MEMBER, 38, 13),
    ]);
  }

  test_class_constructor_unnamed() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
import 'package:angular_meta/angular_meta.dart';

class A {
  int _x;

  @visibleForTemplate
  A(this._x);
}
''');
    newFile('$testPackageLibPath/lib2.dart', r'''
import 'lib1.dart';

void f() {
  new A(0);
}
''');

    await _resolveFile('$testPackageLibPath/lib1.dart', [
      error(WarningCode.UNUSED_FIELD, 66, 2),
    ]);
    await _resolveFile('$testPackageLibPath/lib2.dart', [
      error(WarningCode.INVALID_USE_OF_VISIBLE_FOR_TEMPLATE_MEMBER, 38, 1),
    ]);
  }

  test_class_declaration() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
import 'package:angular_meta/angular_meta.dart';

@visibleForTemplate
class A {}
''');
    newFile('$testPackageLibPath/lib2.dart', r'''
import 'lib1.dart';

void f() {
  A;
}
''');

    await _resolveFile('$testPackageLibPath/lib1.dart');
    await _resolveFile('$testPackageLibPath/lib2.dart');
  }

  test_class_getter() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
import 'package:angular_meta/angular_meta.dart';

class A {
  @visibleForTemplate
  int get foo => 7;
}
''');
    newFile('$testPackageLibPath/lib2.dart', r'''
import 'lib1.dart';

void f(A a) {
  a.foo;
}
''');

    await _resolveFile('$testPackageLibPath/lib1.dart');
    await _resolveFile('$testPackageLibPath/lib2.dart', [
      error(WarningCode.INVALID_USE_OF_VISIBLE_FOR_TEMPLATE_MEMBER, 39, 3),
    ]);
  }

  test_class_getter_withVisibleOutsideTemplate() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
import 'package:angular_meta/angular_meta.dart';

@visibleForTemplate
class A {
  @visibleOutsideTemplate
  A();

  @visibleOutsideTemplate
  int get foo => 7;
}
''');
    newFile('$testPackageLibPath/lib2.dart', r'''
import 'lib1.dart';

void f(A a) {
  a.foo;
}
''');

    await _resolveFile('$testPackageLibPath/lib1.dart');
    await _resolveFile('$testPackageLibPath/lib2.dart');
  }

  test_class_method() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
import 'package:angular_meta/angular_meta.dart';

@visibleForTemplate
class A {
  int foo() => 1;
}
''');
    newFile('$testPackageLibPath/lib2.dart', r'''
import 'lib1.dart';

void f(A a) {
  a.foo();
}
''');

    await _resolveFile('$testPackageLibPath/lib1.dart');
    await _resolveFile('$testPackageLibPath/lib2.dart', [
      error(WarningCode.INVALID_USE_OF_VISIBLE_FOR_TEMPLATE_MEMBER, 39, 3),
    ]);
  }

  test_class_method_fromTemplate() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
import 'package:angular_meta/angular_meta.dart';

class A {
  @visibleForTemplate
  void foo() {}
}
''');
    newFile('$testPackageLibPath/lib1.template.dart', r'''
import 'lib1.dart';

class B {
  void b(A a) => a.foo();
}
''');

    await _resolveFile('$testPackageLibPath/lib1.dart');
    await _resolveFile('$testPackageLibPath/lib1.template.dart');
  }

  test_class_method_inMixin() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
import 'package:angular_meta/angular_meta.dart';

@visibleForTemplate
mixin M {
  int foo() => 1;
}
class C with M {}
''');
    newFile('$testPackageLibPath/lib2.dart', r'''
import 'lib1.dart';

void f(C c) {
  c.foo();
}
''');

    await _resolveFile('$testPackageLibPath/lib1.dart');
    await _resolveFile('$testPackageLibPath/lib2.dart', [
      error(WarningCode.INVALID_USE_OF_VISIBLE_FOR_TEMPLATE_MEMBER, 39, 3),
    ]);
  }

  test_class_method_inMixin_withVisibleOutsideTemplate() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
import 'package:angular_meta/angular_meta.dart';

@visibleForTemplate
mixin M {
  @visibleOutsideTemplate
  int foo() => 1;
}
class C with M {}
''');
    newFile('$testPackageLibPath/lib2.dart', r'''
import 'lib1.dart';

void f(C c) {
  c.foo();
}
''');

    await _resolveFile('$testPackageLibPath/lib1.dart');
    await _resolveFile('$testPackageLibPath/lib2.dart');
  }

  test_class_method_withVisibleOutsideTemplate() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
import 'package:angular_meta/angular_meta.dart';

@visibleForTemplate
class A {
  @visibleOutsideTemplate
  int foo() => 1;
}
''');
    newFile('$testPackageLibPath/lib2.dart', r'''
import 'lib1.dart';

void f(A a) {
  a.foo();
}
''');

    await _resolveFile('$testPackageLibPath/lib1.dart');
    await _resolveFile('$testPackageLibPath/lib2.dart');
  }

  test_class_setter() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
import 'package:angular_meta/angular_meta.dart';

@visibleForTemplate
class A {
  set bar(_) => 7;
}
''');
    newFile('$testPackageLibPath/lib2.dart', r'''
import 'lib1.dart';

void f(A a) {
  a.bar = 6;
}
''');

    await _resolveFile('$testPackageLibPath/lib1.dart');
    await _resolveFile('$testPackageLibPath/lib2.dart', [
      error(WarningCode.INVALID_USE_OF_VISIBLE_FOR_TEMPLATE_MEMBER, 39, 3),
    ]);
  }

  test_class_setter_withVisibleOutsideTemplate() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
import 'package:angular_meta/angular_meta.dart';

@visibleForTemplate
class A {
  @visibleOutsideTemplate
  set bar(_) => 7;
}
''');
    newFile('$testPackageLibPath/lib2.dart', r'''
import 'lib1.dart';

void f(A a) {
  a.bar = 6;
}
''');

    await _resolveFile('$testPackageLibPath/lib1.dart');
    await _resolveFile('$testPackageLibPath/lib2.dart');
  }

  test_enum_constant() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
import 'package:angular_meta/angular_meta.dart';

@visibleForTemplate
enum E {
  a,
  b,
}
''');
    newFile('$testPackageLibPath/lib2.dart', r'''
import 'lib1.dart';

void f() {
  E.a;
}
''');

    await _resolveFile('$testPackageLibPath/lib1.dart');
    await _resolveFile('$testPackageLibPath/lib2.dart', [
      error(WarningCode.INVALID_USE_OF_VISIBLE_FOR_TEMPLATE_MEMBER, 36, 1),
    ]);
  }

  test_enum_constant_withVisibleOutsideTemplate() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
import 'package:angular_meta/angular_meta.dart';

@visibleForTemplate
enum E {
  @visibleOutsideTemplate
  a,
  b,
}
''');
    newFile('$testPackageLibPath/lib2.dart', r'''
import 'lib1.dart';

void f() {
  E.a;
}
''');

    await _resolveFile('$testPackageLibPath/lib1.dart');
    await _resolveFile('$testPackageLibPath/lib2.dart');
  }

  test_enum_declaration() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
import 'package:angular_meta/angular_meta.dart';

@visibleForTemplate
enum E {
  a,
}
''');
    newFile('$testPackageLibPath/lib2.dart', r'''
import 'lib1.dart';

void f() {
  E;
}
''');

    await _resolveFile('$testPackageLibPath/lib1.dart');
    await _resolveFile('$testPackageLibPath/lib2.dart');
  }

  test_export() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
import 'package:angular_meta/angular_meta.dart';

@visibleForTemplate
int foo() => 1;
''');
    newFile('$testPackageLibPath/lib2.dart', r'''
export 'lib1.dart' show foo;
''');

    await _resolveFile('$testPackageLibPath/lib1.dart');
    await _resolveFile('$testPackageLibPath/lib2.dart');
  }

  test_extend_class() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
import 'package:angular_meta/angular_meta.dart';

@visibleForTemplate
class A {
  int foo() => 1;
}
''');
    newFile('$testPackageLibPath/lib2.dart', r'''
import 'lib1.dart';

class B extends A {
}
void f() {
  var b = B();
  b.foo();
}
''');

    await _resolveFile('$testPackageLibPath/lib1.dart');
    await _resolveFile('$testPackageLibPath/lib2.dart', [
      error(WarningCode.INVALID_USE_OF_VISIBLE_FOR_TEMPLATE_MEMBER, 73, 3),
    ]);
  }

  test_extend_class_super() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
import 'package:angular_meta/angular_meta.dart';

@visibleForTemplate
class A {
  int foo() => 1;
}
''');
    newFile('$testPackageLibPath/lib2.dart', r'''
import 'lib1.dart';

class B extends A {
  void bar() => super.foo();
}
''');

    await _resolveFile('$testPackageLibPath/lib1.dart');
    await _resolveFile('$testPackageLibPath/lib2.dart', [
      error(WarningCode.INVALID_USE_OF_VISIBLE_FOR_TEMPLATE_MEMBER, 63, 3),
    ]);
  }

  test_extend_class_withOverride() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
import 'package:angular_meta/angular_meta.dart';

@visibleForTemplate
class A {
  int foo() => 1;
}
''');
    newFile('$testPackageLibPath/lib2.dart', r'''
import 'lib1.dart';

class B extends A {
  @override
  int foo() => 2;
}
void f() {
  var b = B();
  b.foo();
}
''');

    await _resolveFile('$testPackageLibPath/lib1.dart');
    await _resolveFile('$testPackageLibPath/lib2.dart');
  }

  test_extend_class_withProtected() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
import 'package:angular_meta/angular_meta.dart';
import 'package:meta/meta.dart';

@visibleForTemplate
class A {
  @protected
  int foo() => 1;
}

''');
    newFile('$testPackageLibPath/lib2.dart', r'''
import 'lib1.dart';

class B extends A {
  int foo() => super.foo();
}
void f() {
  var b = B();
  b.foo();
}
''');

    await _resolveFile('$testPackageLibPath/lib1.dart');
    await _resolveFile('$testPackageLibPath/lib2.dart');
  }

  test_function_inExtension() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
import 'package:angular_meta/angular_meta.dart';

extension E on List {
  @visibleForTemplate
  int foo() => 1;
}
''');
    newFile('$testPackageLibPath/lib2.dart', r'''
import 'lib1.dart';

void f() {
  E([]).foo();
}
''');

    await _resolveFile('$testPackageLibPath/lib1.dart');
    await _resolveFile('$testPackageLibPath/lib2.dart', [
      error(WarningCode.INVALID_USE_OF_VISIBLE_FOR_TEMPLATE_MEMBER, 40, 3),
    ]);
  }

  test_function_inExtension_fromTemplate() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
import 'package:angular_meta/angular_meta.dart';

extension E on List {
  @visibleForTemplate
  int foo() => 1;
}
''');
    newFile('$testPackageLibPath/lib1.template.dart', r'''
import 'lib1.dart';

void f() {
  E([]).foo();
}
''');

    await _resolveFile('$testPackageLibPath/lib1.dart');
    await _resolveFile('$testPackageLibPath/lib1.template.dart');
  }

  test_protectedAndForTemplate_usedAsProtected() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
import 'package:angular_meta/angular_meta.dart';
import 'package:meta/meta.dart';

class A {
  @protected
  @visibleForTemplate
  void a(){ }
}
''');
    newFile('$testPackageLibPath/lib2.dart', r'''
import 'lib1.dart';

class B extends A {
  void b() => new A().a();
}
''');

    await _resolveFile('$testPackageLibPath/lib1.dart');
    await _resolveFile('$testPackageLibPath/lib2.dart');
  }

  test_protectedAndForTemplate_usedAsTemplate() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
import 'package:angular_meta/angular_meta.dart';
import 'package:meta/meta.dart';

class A {
  @protected
  @visibleForTemplate
  void foo() {}
}
''');
    newFile('$testPackageLibPath/lib1.template.dart', r'''
import 'lib1.dart';

void f(A a) {
  a.foo();
}
''');

    await _resolveFile('$testPackageLibPath/lib1.dart');
    await _resolveFile('$testPackageLibPath/lib1.template.dart');
  }

  test_static_class_member_withVisibleOutsideTemplate() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
import 'package:angular_meta/angular_meta.dart';

@visibleForTemplate
class C {
  @visibleOutsideTemplate
  static int foo() => 1;
}
''');
    newFile('$testPackageLibPath/lib2.dart', r'''
import 'lib1.dart';

void f() {
  C.foo();
}
''');

    await _resolveFile('$testPackageLibPath/lib1.dart');
    await _resolveFile('$testPackageLibPath/lib2.dart');
  }

  test_supertype_method() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
import 'package:angular_meta/angular_meta.dart';

@visibleForTemplate
class A {}
var a = A();
''');
    newFile('$testPackageLibPath/lib2.dart', r'''
import 'lib1.dart';

void f() {
  print(a.hashCode);
}
''');

    await _resolveFile('$testPackageLibPath/lib1.dart');
    await _resolveFile('$testPackageLibPath/lib2.dart');
  }

  test_topLevelFunction() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
import 'package:angular_meta/angular_meta.dart';

@visibleForTemplate
int foo() => 1;
''');
    newFile('$testPackageLibPath/lib2.dart', r'''
import 'lib1.dart';

void f() {
  foo();
}
''');

    await _resolveFile('$testPackageLibPath/lib1.dart');
    await _resolveFile('$testPackageLibPath/lib2.dart', [
      error(WarningCode.INVALID_USE_OF_VISIBLE_FOR_TEMPLATE_MEMBER, 34, 3),
    ]);
  }

  test_topLevelVariable() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
import 'package:angular_meta/angular_meta.dart';

@visibleForTemplate
int foo = 7;
''');
    newFile('$testPackageLibPath/lib2.dart', r'''
import 'lib1.dart';

void f() {
  foo;
}
''');

    await _resolveFile('$testPackageLibPath/lib1.dart');
    await _resolveFile('$testPackageLibPath/lib2.dart', [
      error(WarningCode.INVALID_USE_OF_VISIBLE_FOR_TEMPLATE_MEMBER, 34, 3),
    ]);
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
