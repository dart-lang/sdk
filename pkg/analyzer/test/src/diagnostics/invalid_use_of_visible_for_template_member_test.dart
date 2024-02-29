// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

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
    var lib1 = newFile('$testPackageLibPath/lib1.dart', r'''
import 'package:angular_meta/angular_meta.dart';

class A {
  int _x;

  @visibleForTemplate
  A.forTemplate(this._x);
}
''');
    var lib2 = newFile('$testPackageLibPath/lib2.dart', r'''
import 'lib1.dart';

void f() {
  new A.forTemplate(0);
}
''');

    await assertErrorsInFile2(lib1, [
      error(WarningCode.UNUSED_FIELD, 66, 2),
    ]);
    await assertErrorsInFile2(lib2, [
      error(WarningCode.INVALID_USE_OF_VISIBLE_FOR_TEMPLATE_MEMBER, 38, 13),
    ]);
  }

  test_class_constructor_unnamed() async {
    var lib1 = newFile('$testPackageLibPath/lib1.dart', r'''
import 'package:angular_meta/angular_meta.dart';

class A {
  int _x;

  @visibleForTemplate
  A(this._x);
}
''');
    var lib2 = newFile('$testPackageLibPath/lib2.dart', r'''
import 'lib1.dart';

void f() {
  new A(0);
}
''');

    await assertErrorsInFile2(lib1, [
      error(WarningCode.UNUSED_FIELD, 66, 2),
    ]);
    await assertErrorsInFile2(lib2, [
      error(WarningCode.INVALID_USE_OF_VISIBLE_FOR_TEMPLATE_MEMBER, 38, 1),
    ]);
  }

  test_class_declaration() async {
    var lib1 = newFile('$testPackageLibPath/lib1.dart', r'''
import 'package:angular_meta/angular_meta.dart';

@visibleForTemplate
class A {}
''');
    var lib2 = newFile('$testPackageLibPath/lib2.dart', r'''
import 'lib1.dart';

void f() {
  A;
}
''');

    await assertErrorsInFile2(lib1, []);
    await assertErrorsInFile2(lib2, []);
  }

  test_class_getter() async {
    var lib1 = newFile('$testPackageLibPath/lib1.dart', r'''
import 'package:angular_meta/angular_meta.dart';

class A {
  @visibleForTemplate
  int get foo => 7;
}
''');
    var lib2 = newFile('$testPackageLibPath/lib2.dart', r'''
import 'lib1.dart';

void f(A a) {
  a.foo;
}
''');

    await assertErrorsInFile2(lib1, []);
    await assertErrorsInFile2(lib2, [
      error(WarningCode.INVALID_USE_OF_VISIBLE_FOR_TEMPLATE_MEMBER, 39, 3),
    ]);
  }

  test_class_getter_withVisibleOutsideTemplate() async {
    var lib1 = newFile('$testPackageLibPath/lib1.dart', r'''
import 'package:angular_meta/angular_meta.dart';

@visibleForTemplate
class A {
  @visibleOutsideTemplate
  A();

  @visibleOutsideTemplate
  int get foo => 7;
}
''');
    var lib2 = newFile('$testPackageLibPath/lib2.dart', r'''
import 'lib1.dart';

void f(A a) {
  a.foo;
}
''');

    await assertErrorsInFile2(lib1, []);
    await assertErrorsInFile2(lib2, []);
  }

  test_class_method() async {
    var lib1 = newFile('$testPackageLibPath/lib1.dart', r'''
import 'package:angular_meta/angular_meta.dart';

@visibleForTemplate
class A {
  int foo() => 1;
}
''');
    var lib2 = newFile('$testPackageLibPath/lib2.dart', r'''
import 'lib1.dart';

void f(A a) {
  a.foo();
}
''');

    await assertErrorsInFile2(lib1, []);
    await assertErrorsInFile2(lib2, [
      error(WarningCode.INVALID_USE_OF_VISIBLE_FOR_TEMPLATE_MEMBER, 39, 3),
    ]);
  }

  test_class_method_fromTemplate() async {
    var lib1 = newFile('$testPackageLibPath/lib1.dart', r'''
import 'package:angular_meta/angular_meta.dart';

class A {
  @visibleForTemplate
  void foo() {}
}
''');
    var template = newFile('$testPackageLibPath/lib1.template.dart', r'''
import 'lib1.dart';

class B {
  void b(A a) => a.foo();
}
''');

    await assertErrorsInFile2(lib1, []);
    await assertErrorsInFile2(template, []);
  }

  test_class_method_inMixin() async {
    var lib1 = newFile('$testPackageLibPath/lib1.dart', r'''
import 'package:angular_meta/angular_meta.dart';

@visibleForTemplate
mixin M {
  int foo() => 1;
}
class C with M {}
''');
    var lib2 = newFile('$testPackageLibPath/lib2.dart', r'''
import 'lib1.dart';

void f(C c) {
  c.foo();
}
''');

    await assertErrorsInFile2(lib1, []);
    await assertErrorsInFile2(lib2, [
      error(WarningCode.INVALID_USE_OF_VISIBLE_FOR_TEMPLATE_MEMBER, 39, 3),
    ]);
  }

  test_class_method_inMixin_withVisibleOutsideTemplate() async {
    var lib1 = newFile('$testPackageLibPath/lib1.dart', r'''
import 'package:angular_meta/angular_meta.dart';

@visibleForTemplate
mixin M {
  @visibleOutsideTemplate
  int foo() => 1;
}
class C with M {}
''');
    var lib2 = newFile('$testPackageLibPath/lib2.dart', r'''
import 'lib1.dart';

void f(C c) {
  c.foo();
}
''');

    await assertErrorsInFile2(lib1, []);
    await assertErrorsInFile2(lib2, []);
  }

  test_class_method_parameter_withVisibleOutsideTemplate() async {
    var lib1 = newFile('$testPackageLibPath/lib1.dart', r'''
import 'package:angular_meta/angular_meta.dart';

@visibleForTemplate
class A {
  late bool bar;

  @visibleOutsideTemplate
  void foo({required bool bar}){
    this.bar = bar;
  }
}
''');
    var lib2 = newFile('$testPackageLibPath/lib2.dart', r'''
import 'lib1.dart';

void f(A a) {
  a.foo(bar: true);
}
''');

    await assertErrorsInFile2(lib1, []);
    await assertErrorsInFile2(lib2, []);
  }

  test_class_method_withVisibleOutsideTemplate() async {
    var lib1 = newFile('$testPackageLibPath/lib1.dart', r'''
import 'package:angular_meta/angular_meta.dart';

@visibleForTemplate
class A {
  @visibleOutsideTemplate
  int foo() => 1;
}
''');
    var lib2 = newFile('$testPackageLibPath/lib2.dart', r'''
import 'lib1.dart';

void f(A a) {
  a.foo();
}
''');

    await assertErrorsInFile2(lib1, []);
    await assertErrorsInFile2(lib2, []);
  }

  test_class_setter() async {
    var lib1 = newFile('$testPackageLibPath/lib1.dart', r'''
import 'package:angular_meta/angular_meta.dart';

@visibleForTemplate
class A {
  set bar(_) => 7;
}
''');
    var lib2 = newFile('$testPackageLibPath/lib2.dart', r'''
import 'lib1.dart';

void f(A a) {
  a.bar = 6;
}
''');

    await assertErrorsInFile2(lib1, []);
    await assertErrorsInFile2(lib2, [
      error(WarningCode.INVALID_USE_OF_VISIBLE_FOR_TEMPLATE_MEMBER, 39, 3),
    ]);
  }

  test_class_setter_withVisibleOutsideTemplate() async {
    var lib1 = newFile('$testPackageLibPath/lib1.dart', r'''
import 'package:angular_meta/angular_meta.dart';

@visibleForTemplate
class A {
  @visibleOutsideTemplate
  set bar(_) => 7;
}
''');
    var lib2 = newFile('$testPackageLibPath/lib2.dart', r'''
import 'lib1.dart';

void f(A a) {
  a.bar = 6;
}
''');

    await assertErrorsInFile2(lib1, []);
    await assertErrorsInFile2(lib2, []);
  }

  test_enum_constant() async {
    var lib1 = newFile('$testPackageLibPath/lib1.dart', r'''
import 'package:angular_meta/angular_meta.dart';

@visibleForTemplate
enum E {
  a,
  b,
}
''');
    var lib2 = newFile('$testPackageLibPath/lib2.dart', r'''
import 'lib1.dart';

void f() {
  E.a;
}
''');

    await assertErrorsInFile2(lib1, []);
    await assertErrorsInFile2(lib2, [
      error(WarningCode.INVALID_USE_OF_VISIBLE_FOR_TEMPLATE_MEMBER, 36, 1),
    ]);
  }

  test_enum_constant_withVisibleOutsideTemplate() async {
    var lib1 = newFile('$testPackageLibPath/lib1.dart', r'''
import 'package:angular_meta/angular_meta.dart';

@visibleForTemplate
enum E {
  @visibleOutsideTemplate
  a,
  b,
}
''');
    var lib2 = newFile('$testPackageLibPath/lib2.dart', r'''
import 'lib1.dart';

void f() {
  E.a;
}
''');

    await assertErrorsInFile2(lib1, []);
    await assertErrorsInFile2(lib2, []);
  }

  test_enum_declaration() async {
    var lib1 = newFile('$testPackageLibPath/lib1.dart', r'''
import 'package:angular_meta/angular_meta.dart';

@visibleForTemplate
enum E {
  a,
}
''');
    var lib2 = newFile('$testPackageLibPath/lib2.dart', r'''
import 'lib1.dart';

void f() {
  E;
}
''');

    await assertErrorsInFile2(lib1, []);
    await assertErrorsInFile2(lib2, []);
  }

  test_export() async {
    var lib1 = newFile('$testPackageLibPath/lib1.dart', r'''
import 'package:angular_meta/angular_meta.dart';

@visibleForTemplate
int foo() => 1;
''');
    var lib2 = newFile('$testPackageLibPath/lib2.dart', r'''
export 'lib1.dart' show foo;
''');

    await assertErrorsInFile2(lib1, []);
    await assertErrorsInFile2(lib2, []);
  }

  test_extend_class() async {
    var lib1 = newFile('$testPackageLibPath/lib1.dart', r'''
import 'package:angular_meta/angular_meta.dart';

@visibleForTemplate
class A {
  int foo() => 1;
}
''');
    var lib2 = newFile('$testPackageLibPath/lib2.dart', r'''
import 'lib1.dart';

class B extends A {
}
void f() {
  var b = B();
  b.foo();
}
''');

    await assertErrorsInFile2(lib1, []);
    await assertErrorsInFile2(lib2, [
      error(WarningCode.INVALID_USE_OF_VISIBLE_FOR_TEMPLATE_MEMBER, 73, 3),
    ]);
  }

  test_extend_class_super() async {
    var lib1 = newFile('$testPackageLibPath/lib1.dart', r'''
import 'package:angular_meta/angular_meta.dart';

@visibleForTemplate
class A {
  int foo() => 1;
}
''');
    var lib2 = newFile('$testPackageLibPath/lib2.dart', r'''
import 'lib1.dart';

class B extends A {
  void bar() => super.foo();
}
''');

    await assertErrorsInFile2(lib1, []);
    await assertErrorsInFile2(lib2, [
      error(WarningCode.INVALID_USE_OF_VISIBLE_FOR_TEMPLATE_MEMBER, 63, 3),
    ]);
  }

  test_extend_class_withOverride() async {
    var lib1 = newFile('$testPackageLibPath/lib1.dart', r'''
import 'package:angular_meta/angular_meta.dart';

@visibleForTemplate
class A {
  int foo() => 1;
}
''');
    var lib2 = newFile('$testPackageLibPath/lib2.dart', r'''
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

    await assertErrorsInFile2(lib1, []);
    await assertErrorsInFile2(lib2, []);
  }

  test_extend_class_withProtected() async {
    var lib1 = newFile('$testPackageLibPath/lib1.dart', r'''
import 'package:angular_meta/angular_meta.dart';
import 'package:meta/meta.dart';

@visibleForTemplate
class A {
  @protected
  int foo() => 1;
}

''');
    var lib2 = newFile('$testPackageLibPath/lib2.dart', r'''
import 'lib1.dart';

class B extends A {
  int foo() => super.foo();
}
void f() {
  var b = B();
  b.foo();
}
''');

    await assertErrorsInFile2(lib1, []);
    await assertErrorsInFile2(lib2, []);
  }

  test_function_inExtension() async {
    var lib1 = newFile('$testPackageLibPath/lib1.dart', r'''
import 'package:angular_meta/angular_meta.dart';

extension E on List {
  @visibleForTemplate
  int foo() => 1;
}
''');
    var lib2 = newFile('$testPackageLibPath/lib2.dart', r'''
import 'lib1.dart';

void f() {
  E([]).foo();
}
''');

    await assertErrorsInFile2(lib1, []);
    await assertErrorsInFile2(lib2, [
      error(WarningCode.INVALID_USE_OF_VISIBLE_FOR_TEMPLATE_MEMBER, 40, 3),
    ]);
  }

  test_function_inExtension_fromTemplate() async {
    var lib1 = newFile('$testPackageLibPath/lib1.dart', r'''
import 'package:angular_meta/angular_meta.dart';

extension E on List {
  @visibleForTemplate
  int foo() => 1;
}
''');
    var template = newFile('$testPackageLibPath/lib1.template.dart', r'''
import 'lib1.dart';

void f() {
  E([]).foo();
}
''');

    await assertErrorsInFile2(lib1, []);
    await assertErrorsInFile2(template, []);
  }

  test_protectedAndForTemplate_usedAsProtected() async {
    var lib1 = newFile('$testPackageLibPath/lib1.dart', r'''
import 'package:angular_meta/angular_meta.dart';
import 'package:meta/meta.dart';

class A {
  @protected
  @visibleForTemplate
  void a(){ }
}
''');
    var lib2 = newFile('$testPackageLibPath/lib2.dart', r'''
import 'lib1.dart';

class B extends A {
  void b() => new A().a();
}
''');

    await assertErrorsInFile2(lib1, []);
    await assertErrorsInFile2(lib2, []);
  }

  test_protectedAndForTemplate_usedAsTemplate() async {
    var lib1 = newFile('$testPackageLibPath/lib1.dart', r'''
import 'package:angular_meta/angular_meta.dart';
import 'package:meta/meta.dart';

class A {
  @protected
  @visibleForTemplate
  void foo() {}
}
''');
    var template = newFile('$testPackageLibPath/lib1.template.dart', r'''
import 'lib1.dart';

void f(A a) {
  a.foo();
}
''');

    await assertErrorsInFile2(lib1, []);
    await assertErrorsInFile2(template, []);
  }

  test_static_class_member_withVisibleOutsideTemplate() async {
    var lib1 = newFile('$testPackageLibPath/lib1.dart', r'''
import 'package:angular_meta/angular_meta.dart';

@visibleForTemplate
class C {
  @visibleOutsideTemplate
  static int foo() => 1;
}
''');
    var lib2 = newFile('$testPackageLibPath/lib2.dart', r'''
import 'lib1.dart';

void f() {
  C.foo();
}
''');

    await assertErrorsInFile2(lib1, []);
    await assertErrorsInFile2(lib2, []);
  }

  test_supertype_method() async {
    var lib1 = newFile('$testPackageLibPath/lib1.dart', r'''
import 'package:angular_meta/angular_meta.dart';

@visibleForTemplate
class A {}
var a = A();
''');
    var lib2 = newFile('$testPackageLibPath/lib2.dart', r'''
import 'lib1.dart';

void f() {
  print(a.hashCode);
}
''');

    await assertErrorsInFile2(lib1, []);
    await assertErrorsInFile2(lib2, []);
  }

  test_topLevelFunction() async {
    var lib1 = newFile('$testPackageLibPath/lib1.dart', r'''
import 'package:angular_meta/angular_meta.dart';

@visibleForTemplate
int foo() => 1;
''');
    var lib2 = newFile('$testPackageLibPath/lib2.dart', r'''
import 'lib1.dart';

void f() {
  foo();
}
''');

    await assertErrorsInFile2(lib1, []);
    await assertErrorsInFile2(lib2, [
      error(WarningCode.INVALID_USE_OF_VISIBLE_FOR_TEMPLATE_MEMBER, 34, 3),
    ]);
  }

  test_topLevelVariable() async {
    var lib1 = newFile('$testPackageLibPath/lib1.dart', r'''
import 'package:angular_meta/angular_meta.dart';

@visibleForTemplate
int foo = 7;
''');
    var lib2 = newFile('$testPackageLibPath/lib2.dart', r'''
import 'lib1.dart';

void f() {
  foo;
}
''');

    await assertErrorsInFile2(lib1, []);
    await assertErrorsInFile2(lib2, [
      error(WarningCode.INVALID_USE_OF_VISIBLE_FOR_TEMPLATE_MEMBER, 34, 3),
    ]);
  }
}
