// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_testing/package_config_file_builder.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidUseOfVisibleForTemplateMemberTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class InvalidUseOfVisibleForTemplateMemberTest
    extends PubPackageResolutionTest {
  @override
  void setUp() {
    super.setUp();

    writeTestPackageConfig(
      PackageConfigFileBuilder(),
      angularMeta: true,
      meta: true,
    );
  }

  test_class_constructor_named() async {
    var lib1 = getFile('$testPackageLibPath/lib1.dart');
    var lib2 = getFile('$testPackageLibPath/lib2.dart');

    await resolveFileWithDiagnostics(lib1, r'''
import 'package:angular_meta/angular_meta.dart';

class A {
  int _x;
//    ^^
// [diag.unusedField] The value of the field '_x' isn't used.

  @visibleForTemplate
  A.forTemplate(this._x);
}
''');

    await resolveFileWithDiagnostics(lib2, r'''
import 'lib1.dart';

void f() {
  new A.forTemplate(0);
//    ^^^^^^^^^^^^^
// [diag.invalidUseOfVisibleForTemplateMember] The member 'A.forTemplate' can only be used within 'package:test/lib1.dart' or a template library.
}
''');
  }

  test_class_constructor_unnamed() async {
    var lib1 = getFile('$testPackageLibPath/lib1.dart');
    var lib2 = getFile('$testPackageLibPath/lib2.dart');

    await resolveFileWithDiagnostics(lib1, r'''
import 'package:angular_meta/angular_meta.dart';

class A {
  int _x;
//    ^^
// [diag.unusedField] The value of the field '_x' isn't used.

  @visibleForTemplate
  A(this._x);
}
''');

    await resolveFileWithDiagnostics(lib2, r'''
import 'lib1.dart';

void f() {
  new A(0);
//    ^
// [diag.invalidUseOfVisibleForTemplateMember] The member 'A' can only be used within 'package:test/lib1.dart' or a template library.
}
''');
  }

  test_class_declaration() async {
    var lib1 = getFile('$testPackageLibPath/lib1.dart');
    var lib2 = getFile('$testPackageLibPath/lib2.dart');

    await resolveFileWithDiagnostics(lib1, r'''
import 'package:angular_meta/angular_meta.dart';

@visibleForTemplate
class A {}
''');

    await resolveFileWithDiagnostics(lib2, r'''
import 'lib1.dart';

void f() {
  A;
}
''');
  }

  test_class_getter() async {
    var lib1 = getFile('$testPackageLibPath/lib1.dart');
    var lib2 = getFile('$testPackageLibPath/lib2.dart');

    await resolveFileWithDiagnostics(lib1, r'''
import 'package:angular_meta/angular_meta.dart';

class A {
  @visibleForTemplate
  int get foo => 7;
}
''');

    await resolveFileWithDiagnostics(lib2, r'''
import 'lib1.dart';

void f(A a) {
  a.foo;
//  ^^^
// [diag.invalidUseOfVisibleForTemplateMember] The member 'foo' can only be used within 'package:test/lib1.dart' or a template library.
}
''');
  }

  test_class_getter_withVisibleOutsideTemplate() async {
    var lib1 = getFile('$testPackageLibPath/lib1.dart');
    var lib2 = getFile('$testPackageLibPath/lib2.dart');

    await resolveFileWithDiagnostics(lib1, r'''
import 'package:angular_meta/angular_meta.dart';

@visibleForTemplate
class A {
  @visibleOutsideTemplate
  A();

  @visibleOutsideTemplate
  int get foo => 7;
}
''');

    await resolveFileWithDiagnostics(lib2, r'''
import 'lib1.dart';

void f(A a) {
  a.foo;
}
''');
  }

  test_class_method() async {
    var lib1 = getFile('$testPackageLibPath/lib1.dart');
    var lib2 = getFile('$testPackageLibPath/lib2.dart');

    await resolveFileWithDiagnostics(lib1, r'''
import 'package:angular_meta/angular_meta.dart';

@visibleForTemplate
class A {
  int foo() => 1;
}
''');

    await resolveFileWithDiagnostics(lib2, r'''
import 'lib1.dart';

void f(A a) {
  a.foo();
//  ^^^
// [diag.invalidUseOfVisibleForTemplateMember] The member 'foo' can only be used within 'package:test/lib1.dart' or a template library.
}
''');
  }

  test_class_method_fromTemplate() async {
    var lib1 = getFile('$testPackageLibPath/lib1.dart');
    var template = getFile('$testPackageLibPath/lib1.template.dart');

    await resolveFileWithDiagnostics(lib1, r'''
import 'package:angular_meta/angular_meta.dart';

class A {
  @visibleForTemplate
  void foo() {}
}
''');

    await resolveFileWithDiagnostics(template, r'''
import 'lib1.dart';

class B {
  void b(A a) => a.foo();
}
''');
  }

  test_class_method_inMixin() async {
    var lib1 = getFile('$testPackageLibPath/lib1.dart');
    var lib2 = getFile('$testPackageLibPath/lib2.dart');

    await resolveFileWithDiagnostics(lib1, r'''
import 'package:angular_meta/angular_meta.dart';

@visibleForTemplate
mixin M {
  int foo() => 1;
}
class C with M {}
''');

    await resolveFileWithDiagnostics(lib2, r'''
import 'lib1.dart';

void f(C c) {
  c.foo();
//  ^^^
// [diag.invalidUseOfVisibleForTemplateMember] The member 'foo' can only be used within 'package:test/lib1.dart' or a template library.
}
''');
  }

  test_class_method_inMixin_withVisibleOutsideTemplate() async {
    var lib1 = getFile('$testPackageLibPath/lib1.dart');
    var lib2 = getFile('$testPackageLibPath/lib2.dart');

    await resolveFileWithDiagnostics(lib1, r'''
import 'package:angular_meta/angular_meta.dart';

@visibleForTemplate
mixin M {
  @visibleOutsideTemplate
  int foo() => 1;
}
class C with M {}
''');

    await resolveFileWithDiagnostics(lib2, r'''
import 'lib1.dart';

void f(C c) {
  c.foo();
}
''');
  }

  test_class_method_parameter_withVisibleOutsideTemplate() async {
    var lib1 = getFile('$testPackageLibPath/lib1.dart');
    var lib2 = getFile('$testPackageLibPath/lib2.dart');

    await resolveFileWithDiagnostics(lib1, r'''
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

    await resolveFileWithDiagnostics(lib2, r'''
import 'lib1.dart';

void f(A a) {
  a.foo(bar: true);
}
''');
  }

  test_class_method_withVisibleOutsideTemplate() async {
    var lib1 = getFile('$testPackageLibPath/lib1.dart');
    var lib2 = getFile('$testPackageLibPath/lib2.dart');

    await resolveFileWithDiagnostics(lib1, r'''
import 'package:angular_meta/angular_meta.dart';

@visibleForTemplate
class A {
  @visibleOutsideTemplate
  int foo() => 1;
}
''');

    await resolveFileWithDiagnostics(lib2, r'''
import 'lib1.dart';

void f(A a) {
  a.foo();
}
''');
  }

  test_class_setter() async {
    var lib1 = getFile('$testPackageLibPath/lib1.dart');
    var lib2 = getFile('$testPackageLibPath/lib2.dart');

    await resolveFileWithDiagnostics(lib1, r'''
import 'package:angular_meta/angular_meta.dart';

@visibleForTemplate
class A {
  set bar(_) => 7;
}
''');

    await resolveFileWithDiagnostics(lib2, r'''
import 'lib1.dart';

void f(A a) {
  a.bar = 6;
//  ^^^
// [diag.invalidUseOfVisibleForTemplateMember] The member 'bar' can only be used within 'package:test/lib1.dart' or a template library.
}
''');
  }

  test_class_setter_withVisibleOutsideTemplate() async {
    var lib1 = getFile('$testPackageLibPath/lib1.dart');
    var lib2 = getFile('$testPackageLibPath/lib2.dart');

    await resolveFileWithDiagnostics(lib1, r'''
import 'package:angular_meta/angular_meta.dart';

@visibleForTemplate
class A {
  @visibleOutsideTemplate
  set bar(_) => 7;
}
''');

    await resolveFileWithDiagnostics(lib2, r'''
import 'lib1.dart';

void f(A a) {
  a.bar = 6;
}
''');
  }

  test_enum_constant() async {
    var lib1 = getFile('$testPackageLibPath/lib1.dart');
    var lib2 = getFile('$testPackageLibPath/lib2.dart');

    await resolveFileWithDiagnostics(lib1, r'''
import 'package:angular_meta/angular_meta.dart';

@visibleForTemplate
enum E {
  a,
  b,
}
''');

    await resolveFileWithDiagnostics(lib2, r'''
import 'lib1.dart';

void f() {
  E.a;
//  ^
// [diag.invalidUseOfVisibleForTemplateMember] The member 'a' can only be used within 'package:test/lib1.dart' or a template library.
}
''');
  }

  test_enum_constant_withVisibleOutsideTemplate() async {
    var lib1 = getFile('$testPackageLibPath/lib1.dart');
    var lib2 = getFile('$testPackageLibPath/lib2.dart');

    await resolveFileWithDiagnostics(lib1, r'''
import 'package:angular_meta/angular_meta.dart';

@visibleForTemplate
enum E {
  @visibleOutsideTemplate
  a,
  b,
}
''');

    await resolveFileWithDiagnostics(lib2, r'''
import 'lib1.dart';

void f() {
  E.a;
}
''');
  }

  test_enum_declaration() async {
    var lib1 = getFile('$testPackageLibPath/lib1.dart');
    var lib2 = getFile('$testPackageLibPath/lib2.dart');

    await resolveFileWithDiagnostics(lib1, r'''
import 'package:angular_meta/angular_meta.dart';

@visibleForTemplate
enum E {
  a,
}
''');

    await resolveFileWithDiagnostics(lib2, r'''
import 'lib1.dart';

void f() {
  E;
}
''');
  }

  test_export() async {
    var lib1 = getFile('$testPackageLibPath/lib1.dart');
    var lib2 = getFile('$testPackageLibPath/lib2.dart');

    await resolveFileWithDiagnostics(lib1, r'''
import 'package:angular_meta/angular_meta.dart';

@visibleForTemplate
int foo() => 1;
''');

    await resolveFileWithDiagnostics(lib2, r'''
export 'lib1.dart' show foo;
''');
  }

  test_extend_class() async {
    var lib1 = getFile('$testPackageLibPath/lib1.dart');
    var lib2 = getFile('$testPackageLibPath/lib2.dart');

    await resolveFileWithDiagnostics(lib1, r'''
import 'package:angular_meta/angular_meta.dart';

@visibleForTemplate
class A {
  int foo() => 1;
}
''');

    await resolveFileWithDiagnostics(lib2, r'''
import 'lib1.dart';

class B extends A {
}
void f() {
  var b = B();
  b.foo();
//  ^^^
// [diag.invalidUseOfVisibleForTemplateMember] The member 'foo' can only be used within 'package:test/lib1.dart' or a template library.
}
''');
  }

  test_extend_class_super() async {
    var lib1 = getFile('$testPackageLibPath/lib1.dart');
    var lib2 = getFile('$testPackageLibPath/lib2.dart');

    await resolveFileWithDiagnostics(lib1, r'''
import 'package:angular_meta/angular_meta.dart';

@visibleForTemplate
class A {
  int foo() => 1;
}
''');

    await resolveFileWithDiagnostics(lib2, r'''
import 'lib1.dart';

class B extends A {
  void bar() => super.foo();
//                    ^^^
// [diag.invalidUseOfVisibleForTemplateMember] The member 'foo' can only be used within 'package:test/lib1.dart' or a template library.
}
''');
  }

  test_extend_class_withOverride() async {
    var lib1 = getFile('$testPackageLibPath/lib1.dart');
    var lib2 = getFile('$testPackageLibPath/lib2.dart');

    await resolveFileWithDiagnostics(lib1, r'''
import 'package:angular_meta/angular_meta.dart';

@visibleForTemplate
class A {
  int foo() => 1;
}
''');

    await resolveFileWithDiagnostics(lib2, r'''
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
  }

  test_extend_class_withProtected() async {
    var lib1 = getFile('$testPackageLibPath/lib1.dart');
    var lib2 = getFile('$testPackageLibPath/lib2.dart');

    await resolveFileWithDiagnostics(lib1, r'''
import 'package:angular_meta/angular_meta.dart';
import 'package:meta/meta.dart';

@visibleForTemplate
class A {
  @protected
  int foo() => 1;
}

''');

    await resolveFileWithDiagnostics(lib2, r'''
import 'lib1.dart';

class B extends A {
  int foo() => super.foo();
}
void f() {
  var b = B();
  b.foo();
}
''');
  }

  test_function_inExtension() async {
    var lib1 = getFile('$testPackageLibPath/lib1.dart');
    var lib2 = getFile('$testPackageLibPath/lib2.dart');

    await resolveFileWithDiagnostics(lib1, r'''
import 'package:angular_meta/angular_meta.dart';

extension E on List {
  @visibleForTemplate
  int foo() => 1;
}
''');

    await resolveFileWithDiagnostics(lib2, r'''
import 'lib1.dart';

void f() {
  E([]).foo();
//      ^^^
// [diag.invalidUseOfVisibleForTemplateMember] The member 'foo' can only be used within 'package:test/lib1.dart' or a template library.
}
''');
  }

  test_function_inExtension_fromTemplate() async {
    var lib1 = getFile('$testPackageLibPath/lib1.dart');
    var template = getFile('$testPackageLibPath/lib1.template.dart');

    await resolveFileWithDiagnostics(lib1, r'''
import 'package:angular_meta/angular_meta.dart';

extension E on List {
  @visibleForTemplate
  int foo() => 1;
}
''');

    await resolveFileWithDiagnostics(template, r'''
import 'lib1.dart';

void f() {
  E([]).foo();
}
''');
  }

  test_protectedAndForTemplate_usedAsProtected() async {
    var lib1 = getFile('$testPackageLibPath/lib1.dart');
    var lib2 = getFile('$testPackageLibPath/lib2.dart');

    await resolveFileWithDiagnostics(lib1, r'''
import 'package:angular_meta/angular_meta.dart';
import 'package:meta/meta.dart';

class A {
  @protected
  @visibleForTemplate
  void a(){ }
}
''');

    await resolveFileWithDiagnostics(lib2, r'''
import 'lib1.dart';

class B extends A {
  void b() => new A().a();
}
''');
  }

  test_protectedAndForTemplate_usedAsTemplate() async {
    var lib1 = getFile('$testPackageLibPath/lib1.dart');
    var template = getFile('$testPackageLibPath/lib1.template.dart');

    await resolveFileWithDiagnostics(lib1, r'''
import 'package:angular_meta/angular_meta.dart';
import 'package:meta/meta.dart';

class A {
  @protected
  @visibleForTemplate
  void foo() {}
}
''');

    await resolveFileWithDiagnostics(template, r'''
import 'lib1.dart';

void f(A a) {
  a.foo();
}
''');
  }

  test_static_class_member_withVisibleOutsideTemplate() async {
    var lib1 = getFile('$testPackageLibPath/lib1.dart');
    var lib2 = getFile('$testPackageLibPath/lib2.dart');

    await resolveFileWithDiagnostics(lib1, r'''
import 'package:angular_meta/angular_meta.dart';

@visibleForTemplate
class C {
  @visibleOutsideTemplate
  static int foo() => 1;
}
''');

    await resolveFileWithDiagnostics(lib2, r'''
import 'lib1.dart';

void f() {
  C.foo();
}
''');
  }

  test_supertype_method() async {
    var lib1 = getFile('$testPackageLibPath/lib1.dart');
    var lib2 = getFile('$testPackageLibPath/lib2.dart');

    await resolveFileWithDiagnostics(lib1, r'''
import 'package:angular_meta/angular_meta.dart';

@visibleForTemplate
class A {}
var a = A();
''');

    await resolveFileWithDiagnostics(lib2, r'''
import 'lib1.dart';

void f() {
  print(a.hashCode);
}
''');
  }

  test_topLevelFunction() async {
    var lib1 = getFile('$testPackageLibPath/lib1.dart');
    var lib2 = getFile('$testPackageLibPath/lib2.dart');

    await resolveFileWithDiagnostics(lib1, r'''
import 'package:angular_meta/angular_meta.dart';

@visibleForTemplate
int foo() => 1;
''');

    await resolveFileWithDiagnostics(lib2, r'''
import 'lib1.dart';

void f() {
  foo();
//^^^
// [diag.invalidUseOfVisibleForTemplateMember] The member 'foo' can only be used within 'package:test/lib1.dart' or a template library.
}
''');
  }

  test_topLevelVariable() async {
    var lib1 = getFile('$testPackageLibPath/lib1.dart');
    var lib2 = getFile('$testPackageLibPath/lib2.dart');

    await resolveFileWithDiagnostics(lib1, r'''
import 'package:angular_meta/angular_meta.dart';

@visibleForTemplate
int foo = 7;
''');

    await resolveFileWithDiagnostics(lib2, r'''
import 'lib1.dart';

void f() {
  foo;
//^^^
// [diag.invalidUseOfVisibleForTemplateMember] The member 'foo' can only be used within 'package:test/lib1.dart' or a template library.
}
''');
  }
}
