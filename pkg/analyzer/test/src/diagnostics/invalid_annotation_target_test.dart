// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidAnnotationTarget_MustBeOverriddenTest);
    defineReflectiveTests(InvalidAnnotationTarget_MustCallSuperTest);
    defineReflectiveTests(InvalidAnnotationTarget_RedeclareTest);
    defineReflectiveTests(InvalidAnnotationTargetTest);
  });
}

@reflectiveTest
class InvalidAnnotationTarget_MustBeOverriddenTest
    extends PubPackageResolutionTest {
  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfigWithMeta();
  }

  test_class_instance_field() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

class A {
  @mustBeOverridden
  int f = 0;
}
''');
  }

  test_class_instance_field_declaredInPrimaryConstructor() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

class A(@mustBeOverridden var int f);
''');
  }

  test_class_instance_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

class A {
  @mustBeOverridden
  int get f => 0;
}
''');
  }

  test_class_instance_method() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

class A {
  @mustBeOverridden
  void m() {}
}
''');
  }

  test_class_instance_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

class A {
  @mustBeOverridden
  void set s(int value) {}
}
''');
  }

  test_class_static_field() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
class A {
  @mustBeOverridden
// ^^^^^^^^^^^^^^^^
// [diag.invalidAnnotationTarget] The annotation 'mustBeOverridden' can only be used on overridable members.
  static int f = 0;
}
''');
  }

  test_class_static_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
class A {
  @mustBeOverridden
// ^^^^^^^^^^^^^^^^
// [diag.invalidAnnotationTarget] The annotation 'mustBeOverridden' can only be used on overridable members.
  static int get f => 0;
}
''');
  }

  test_class_static_method() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
class A {
  @mustBeOverridden
// ^^^^^^^^^^^^^^^^
// [diag.invalidAnnotationTarget] The annotation 'mustBeOverridden' can only be used on overridable members.
  static void m() {}
}
''');
  }

  test_class_static_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
class A {
  @mustBeOverridden
// ^^^^^^^^^^^^^^^^
// [diag.invalidAnnotationTarget] The annotation 'mustBeOverridden' can only be used on overridable members.
  static void set f(int value) {}
}
''');
  }

  test_constructor() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

class C {
  @mustBeOverridden
// ^^^^^^^^^^^^^^^^
// [diag.invalidAnnotationTarget] The annotation 'mustBeOverridden' can only be used on overridable members.
  C();
}
''');
  }

  test_enum_member() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

enum E {
  one, two;
  @mustBeOverridden
// ^^^^^^^^^^^^^^^^
// [diag.invalidAnnotationTarget] The annotation 'mustBeOverridden' can only be used on overridable members.
  void m() {}
}
''');
  }

  test_extension_member() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

extension E on String {
  @mustBeOverridden
// ^^^^^^^^^^^^^^^^
// [diag.invalidAnnotationTarget] The annotation 'mustBeOverridden' can only be used on overridable members.
  void m() {}
}
''');
  }

  test_mixin_instance_method() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

mixin M {
  @mustBeOverridden
  void m() {}
}
''');
  }

  test_parameter_declaredInPrimaryConstructor() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

class A(@mustBeOverridden int f);
//       ^^^^^^^^^^^^^^^^
// [diag.invalidAnnotationTarget] The annotation 'mustBeOverridden' can only be used on overridable members.
''');
  }

  test_parameter_fieldFormal_declaredInPrimaryConstructor() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

class A(@mustBeOverridden this.f) {
//       ^^^^^^^^^^^^^^^^
// [diag.invalidAnnotationTarget] The annotation 'mustBeOverridden' can only be used on overridable members.
  final int f;
}
''');
  }

  test_topLevel() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

@mustBeOverridden
// [diag.invalidAnnotationTarget][column 2][length 16] The annotation 'mustBeOverridden' can only be used on overridable members.
void m() {}
''');
  }
}

@reflectiveTest
class InvalidAnnotationTarget_MustCallSuperTest
    extends PubPackageResolutionTest {
  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfigWithMeta();
  }

  test_class_instance_field() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

class A {
  @mustCallSuper
  int f = 0;
}
''');
  }

  test_class_instance_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

class A {
  @mustCallSuper
  int get f => 0;
}
''');
  }

  test_class_instance_method() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

class A {
  @mustCallSuper
  void m() {}
}
''');
  }

  test_class_instance_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

class A {
  @mustCallSuper
  void set s(int value) {}
}
''');
  }

  test_class_static_field() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
class A {
  @mustCallSuper
// ^^^^^^^^^^^^^
// [diag.invalidAnnotationTarget] The annotation 'mustCallSuper' can only be used on overridable members.
  static int f = 0;
}
''');
  }

  test_class_static_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
class A {
  @mustCallSuper
// ^^^^^^^^^^^^^
// [diag.invalidAnnotationTarget] The annotation 'mustCallSuper' can only be used on overridable members.
  static int get f => 0;
}
''');
  }

  test_class_static_method() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
class A {
  @mustCallSuper
// ^^^^^^^^^^^^^
// [diag.invalidAnnotationTarget] The annotation 'mustCallSuper' can only be used on overridable members.
  static void m() {}
}
''');
  }

  test_class_static_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
class A {
  @mustCallSuper
// ^^^^^^^^^^^^^
// [diag.invalidAnnotationTarget] The annotation 'mustCallSuper' can only be used on overridable members.
  static void set f(int value) {}
}
''');
  }

  test_constructor() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

class C {
  @mustCallSuper
// ^^^^^^^^^^^^^
// [diag.invalidAnnotationTarget] The annotation 'mustCallSuper' can only be used on overridable members.
  C();
}
''');
  }

  test_enum_member() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

enum E {
  one, two;
  @mustCallSuper
// ^^^^^^^^^^^^^
// [diag.invalidAnnotationTarget] The annotation 'mustCallSuper' can only be used on overridable members.
  void m() {}
}
''');
  }

  test_extension_member() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

extension E on String {
  @mustCallSuper
// ^^^^^^^^^^^^^
// [diag.invalidAnnotationTarget] The annotation 'mustCallSuper' can only be used on overridable members.
  void m() {}
}
''');
  }

  test_mixin_instance_method() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

mixin M {
  @mustCallSuper
  void m() {}
}
''');
  }

  test_topLevel() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

@mustCallSuper
// [diag.invalidAnnotationTarget][column 2][length 13] The annotation 'mustCallSuper' can only be used on overridable members.
void m() {}
''');
  }
}

@reflectiveTest
class InvalidAnnotationTarget_RedeclareTest extends PubPackageResolutionTest {
  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfigWithMeta();
  }

  test_class_instance_method() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

class C {
  @redeclare
// ^^^^^^^^^
// [diag.invalidAnnotationTarget] The annotation 'redeclare' can only be used on instance members of extension types.
  void m() {}
}
''');
  }

  test_extensionType_instance_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

class C {
  int get g => 0; 
}

extension type E(C c) implements C {
  @redeclare
  int get g => 0; 
}
''');
  }

  test_extensionType_instance_method() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

class C {
  void m() {}
}

extension type E(C c) implements C {
  @redeclare
  void m() {}
}
''');
  }

  test_extensionType_instance_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

class C {
  set g(int i) {}
}

extension type E(C c) implements C {
  @redeclare
  set g(int i) {}
}
''');
  }

  test_extensionType_static_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

class C {
  static int get g => 0; 
}

extension type E(C c) {
  @redeclare
// ^^^^^^^^^
// [diag.invalidAnnotationTarget] The annotation 'redeclare' can only be used on instance members of extension types.
  static int get g => 0; 
}
''');
  }

  test_extensionType_static_method() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

class C {
  static void m() {}
}

extension type E(C c) {
  @redeclare
// ^^^^^^^^^
// [diag.invalidAnnotationTarget] The annotation 'redeclare' can only be used on instance members of extension types.
  static void m() {}
}
''');
  }

  test_extensionType_static_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

class C {
  static set g(int i) {}
}

extension type E(C c) {
  @redeclare
// ^^^^^^^^^
// [diag.invalidAnnotationTarget] The annotation 'redeclare' can only be used on instance members of extension types.
  static set g(int i) {}
}
''');
  }
}

@reflectiveTest
class InvalidAnnotationTargetTest extends PubPackageResolutionTest {
  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfigWithMeta();
  }

  // TODO(pq): add tests for topLevelVariables:
  // https://dart-review.googlesource.com/c/sdk/+/200301
  void test_classType_class() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.classType})
class A {
  const A();
}

@A()
class C {}
''');
  }

  void test_classType_classTypeAlias() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.classType})
class A {
  const A();
}

mixin M {}

@A()
class C = Object with M;
''');
  }

  void test_classType_mixin() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.classType})
class A {
  const A();
}

@A()
// [diag.invalidAnnotationTarget][column 2][length 1] The annotation 'A.new' can only be used on classes.
mixin M {}
''');
  }

  void test_classType_topLevelVariable_constructor() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.classType})
class A {
  const A();
}

@A()
// [diag.invalidAnnotationTarget][column 2][length 1] The annotation 'A.new' can only be used on classes.
int x = 0;
''');
  }

  void test_classType_topLevelVariable_topLevelConstant() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.classType})
class A {
  const A();
}

const a = A();

@a
// [diag.invalidAnnotationTarget][column 2][length 1] The annotation 'a' can only be used on classes.
int x = 0;
''');
  }

  void test_constructor_class() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.constructor})
class A {
  const A();
}

@A()
// [diag.invalidAnnotationTarget][column 2][length 1] The annotation 'A.new' can only be used on constructors.
class C {}
''');
  }

  void test_constructor_classWithPrimaryConstructor() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.constructor})
class A {
  const A();
}

@A()
// [diag.invalidAnnotationTarget][column 2][length 1] The annotation 'A.new' can only be used on constructors.
class C(final int i);
''');
  }

  void test_constructor_constructor() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.constructor})
class A {
  const A();
}

class C {
  @A() C();
}
''');
  }

  void test_constructor_enumWithPrimaryConstructor() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.constructor})
class A {
  const A();
}

@A()
// [diag.invalidAnnotationTarget][column 2][length 1] The annotation 'A.new' can only be used on constructors.
enum C(int i) {
  a(1), b(2), c(3);
}
''');
  }

  void test_constructor_extensionType() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.constructor})
class A {
  const A();
}

@A()
// [diag.invalidAnnotationTarget][column 2][length 1] The annotation 'A.new' can only be used on constructors.
extension type C(int i);
''');
  }

  void test_constructor_method() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.constructor})
class A {
  const A();
}

class C {
  @A()
// ^
// [diag.invalidAnnotationTarget] The annotation 'A.new' can only be used on constructors.
  void m() {}
}
''');
  }

  void test_constructor_primaryConstructorBody() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.constructor})
class A {
  const A();
}


class C(final int i) {
  @A()
  this;
}
''');
  }

  void test_directive_class() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta_meta.dart';

// ignore: deprecated_member_use
@Target({TargetKind.directive})
class A {
  const A();
}

@A()
// [diag.invalidAnnotationTarget][column 2][length 1] The annotation 'A.new' can only be used on directives.
class C {}
''');
  }

  void test_directive_directive() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta_meta.dart';

@A()
import 'dart:core';

// ignore: deprecated_member_use
@Target({TargetKind.directive})
class A {
  const A();
}
''');
  }

  void test_enumType_class() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.enumType})
class A {
  const A();
}

@A()
// [diag.invalidAnnotationTarget][column 2][length 1] The annotation 'A.new' can only be used on enums.
class C {}
''');
  }

  void test_enumType_enum() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.enumType})
class A {
  const A();
}

@A()
enum E {a, b}
''');
  }

  void test_enumValue_enumValue() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.enumValue})
class A {
  const A();
}

enum E {
  @A() one, two;
}
''');
  }

  void test_enumValue_field() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.enumValue})
class A {
  const A();
}

class C {
  @A()
// ^
// [diag.invalidAnnotationTarget] The annotation 'A.new' can only be used on enum values.
  int f = 7;
}
''');
  }

  void test_exportDirective_exportDirective() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta_meta.dart';

@A()
export 'dart:core';

@Target({TargetKind.exportDirective})
class A {
  const A();
}
''');
  }

  void test_exportDirective_importDirective() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta_meta.dart';

@A()
// [diag.invalidAnnotationTarget][column 2][length 1] The annotation 'A.new' can only be used on export directives.
import 'dart:core';

@Target({TargetKind.exportDirective})
class A {
  const A();
}
''');
  }

  void test_extension_class() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.extension})
class A {
  const A();
}

@A()
// [diag.invalidAnnotationTarget][column 2][length 1] The annotation 'A.new' can only be used on extensions.
class C {}
''');
  }

  void test_extension_extension() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.extension})
class A {
  const A();
}

@A()
extension on C {}
class C {}
''');
  }

  void test_extension_type_parameter() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.parameter})
class A {
  const A();
}

extension type const E(@A() int x) {}
''');
  }

  void test_field_enumValue() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.field})
class A {
  const A();
}

enum E {
  @A()
// ^
// [diag.invalidAnnotationTarget] The annotation 'A.new' can only be used on fields.
  one
}
''');
  }

  void test_field_field() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.field})
class A {
  const A();
}

class C {
  @A()
  int f = 0;
}
''');
  }

  void test_field_field_declaredInPrimaryConstructor() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.field})
class A {
  const A();
}

class C(@A() final int f);
''');
  }

  void test_function_localFunction() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.function})
class A {
  const A();
}

void f() {
  @A()
  // ignore: unused_element
  int g(int x) => 0;
}
''');
  }

  void test_function_method() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.function})
class A {
  const A();
}

class C {
  @A()
// ^
// [diag.invalidAnnotationTarget] The annotation 'A.new' can only be used on top-level functions.
  int M(int x) => 0;
}
''');
  }

  void test_function_topLevelFunction() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.function})
class A {
  const A();
}

@A()
int f(int x) => 0;
''');
  }

  void test_function_topLevelGetter() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.function})
class A {
  const A();
}

@A()
// [diag.invalidAnnotationTarget][column 2][length 1] The annotation 'A.new' can only be used on top-level functions.
int get x => 0;
''');
  }

  void test_function_topLevelSetter() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.function})
class A {
  const A();
}

@A()
// [diag.invalidAnnotationTarget][column 2][length 1] The annotation 'A.new' can only be used on top-level functions.
set x(_x) {}
''');
  }

  void test_getter_field() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.getter})
class A {
  const A();
}

class C {
  @A()
// ^
// [diag.invalidAnnotationTarget] The annotation 'A.new' can only be used on getters.
  int x = 0;
}
''');
  }

  void test_getter_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.getter})
class A {
  const A();
}

class C {
  @A()
  int get x => 0;
}
''');
  }

  void test_getter_method() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.getter})
class A {
  const A();
}

class C {
  @A()
// ^
// [diag.invalidAnnotationTarget] The annotation 'A.new' can only be used on getters.
  int m(int x) => x;
}
''');
  }

  void test_getter_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.getter})
class A {
  const A();
}

class C {
  @A()
// ^
// [diag.invalidAnnotationTarget] The annotation 'A.new' can only be used on getters.
  set x(int _x) {}
}
''');
  }

  void test_getter_topLevelGetter() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.getter})
class A {
  const A();
}

@A()
int get x => 0;
''');
  }

  void test_importDirective_exportDirective() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta_meta.dart';

@A()
// [diag.invalidAnnotationTarget][column 2][length 1] The annotation 'A.new' can only be used on import directives.
export 'dart:core';

@Target({TargetKind.importDirective})
class A {
  const A();
}
''');
  }

  void test_importDirective_importDirective() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta_meta.dart';

@A()
import 'dart:core';

@Target({TargetKind.importDirective})
class A {
  const A();
}
''');
  }

  void test_library_class() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.library})
class A {
  const A();
}

@A()
// [diag.invalidAnnotationTarget][column 2][length 1] The annotation 'A.new' can only be used on libraries.
class C {}
''');
  }

  void test_library_import() async {
    await resolveTestCodeWithDiagnostics(r'''
@A()
import 'package:meta/meta_meta.dart';

@Target({TargetKind.library})
class A {
  const A();
}
''');
  }

  void test_library_library() async {
    await resolveTestCodeWithDiagnostics('''
@A()
library test;

import 'package:meta/meta_meta.dart';

@Target({TargetKind.library})
class A {
  const A();
}
''');
  }

  void test_method_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.method})
class A {
  const A();
}

class C {
  @A()
// ^
// [diag.invalidAnnotationTarget] The annotation 'A.new' can only be used on methods.
  int get x => 0;
}
''');
  }

  void test_method_method() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.method})
class A {
  const A();
}

class C {
  @A()
  int m(int x) => x;
}
''');
  }

  void test_method_operator() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.method})
class A {
  const A();
}

class C {
  @A()
  int operator +(int x) => x;
}
''');
  }

  void test_method_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.method})
class A {
  const A();
}

class C {
  @A()
// ^
// [diag.invalidAnnotationTarget] The annotation 'A.new' can only be used on methods.
  set x(int _x) {}
}
''');
  }

  void test_method_topLevelFunction() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.method})
class A {
  const A();
}

@A()
// [diag.invalidAnnotationTarget][column 2][length 1] The annotation 'A.new' can only be used on methods.
int f(int x) => x;
''');
  }

  void test_mixinType_class() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.mixinType})
class A {
  const A();
}

@A()
// [diag.invalidAnnotationTarget][column 2][length 1] The annotation 'A.new' can only be used on mixins.
class C {}
''');
  }

  void test_mixinType_mixin() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.mixinType})
class A {
  const A();
}

@A()
mixin M {}
''');
  }

  void test_multiple_invalid() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.classType, TargetKind.method})
class A {
  const A();
}

@A()
// [diag.invalidAnnotationTarget][column 2][length 1] The annotation 'A.new' can only be used on classes or methods.
int x = 0;
''');
  }

  void test_multiple_valid() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.classType, TargetKind.method})
class A {
  const A();
}

@A()
class C {
  @A()
  int m(int x) => x;
}
''');
  }

  void test_optionalParameter_optionalNamed() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.optionalParameter})
class A {
  const A();
}

void f({@A() int? x}) {}
''');
  }

  void test_optionalParameter_optionalPositional() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.optionalParameter})
class A {
  const A();
}

void f([@A() int? x]) {}
''');
  }

  void test_optionalParameter_requiredNamed() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.optionalParameter})
class A {
  const A();
}

void f({@A() required int x}) {}
//       ^
// [diag.invalidAnnotationTarget] The annotation 'A.new' can only be used on optional parameters.
''');
  }

  void test_optionalParameter_requiredPositional() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.optionalParameter})
class A {
  const A();
}

void f(@A() int x) {}
//      ^
// [diag.invalidAnnotationTarget] The annotation 'A.new' can only be used on optional parameters.
''');
  }

  void test_overridableMember_class_visibleForOverriding() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
@visibleForOverriding
// [diag.invalidAnnotationTarget][column 2][length 20] The annotation 'visibleForOverriding' can only be used on overridable members.
class C {}
''');
  }

  void test_overridableMember_constructor() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.overridableMember})
class A {
  const A();
}

class C {
  @A()
// ^
// [diag.invalidAnnotationTarget] The annotation 'A.new' can only be used on overridable members.
  C();
}
''');
  }

  void test_overridableMember_enumConstant() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
enum E {
  @nonVirtual
// ^^^^^^^^^^
// [diag.invalidAnnotationTarget] The annotation 'nonVirtual' can only be used on overridable members.
  a,
  b, c
}
''');
  }

  void test_overridableMember_extensionType_visibleForOverride() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
@visibleForOverriding
// [diag.invalidAnnotationTarget][column 2][length 20] The annotation 'visibleForOverriding' can only be used on overridable members.
extension type E(int i) {}
''');
  }

  void test_overridableMember_instanceGetter() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.overridableMember})
class A {
  const A();
}

class C {
  @A()
  int get x => 0;
}
''');
  }

  void test_overridableMember_instanceMethod() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.overridableMember})
class A {
  const A();
}

class C {
  @A()
  int x() => 0;
}
''');
  }

  void test_overridableMember_instanceMethod_onEnum() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.overridableMember})
class A {
  const A();
}

enum E {
  one, two;
  @A()
// ^
// [diag.invalidAnnotationTarget] The annotation 'A.new' can only be used on overridable members.
  int x() => 0;
}
''');
  }

  void test_overridableMember_instanceMethod_onExtension() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.overridableMember})
class A {
  const A();
}

extension E on int {
  @A()
// ^
// [diag.invalidAnnotationTarget] The annotation 'A.new' can only be used on overridable members.
  int x() => 0;
}
''');
  }

  void test_overridableMember_instanceMethod_onMixin() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.overridableMember})
class A {
  const A();
}

mixin M {
  @A()
  int x() => 0;
}
''');
  }

  void test_overridableMember_instanceOperator() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.overridableMember})
class A {
  const A();
}

class C {
  @A()
  int operator +(int value) => 0;
}
''');
  }

  void test_overridableMember_instanceSetter() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.overridableMember})
class A {
  const A();
}

class C {
  @A()
  set x(int value) {}
}
''');
  }

  void test_overridableMember_staticField() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.overridableMember})
class A {
  const A();
}

class C {
  @A()
// ^
// [diag.invalidAnnotationTarget] The annotation 'A.new' can only be used on overridable members.
  static int x = 0;
}
''');
  }

  void test_overridableMember_staticMethod() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.overridableMember})
class A {
  const A();
}

class C {
  @A()
// ^
// [diag.invalidAnnotationTarget] The annotation 'A.new' can only be used on overridable members.
  static int x() => 0;
}
''');
  }

  void test_overridableMember_topLevelField_visibleForOverriding() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
@visibleForOverriding
// [diag.invalidAnnotationTarget][column 2][length 20] The annotation 'visibleForOverriding' can only be used on overridable members.
var a = 1, b;
''');
  }

  void test_overridableMember_topLevelFunction_visibleForOverriding() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
@visibleForOverriding void foo() {}
// [diag.invalidAnnotationTarget][column 2][length 20] The annotation 'visibleForOverriding' can only be used on overridable members.
''');
  }

  void test_overridableMember_topLevelGetter_nonVirtual() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

@nonVirtual
// [diag.invalidAnnotationTarget][column 2][length 10] The annotation 'nonVirtual' can only be used on overridable members.
int get a => 1;
''');
  }

  void test_overridableMember_topLevelSetter_nonVirtual() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

@nonVirtual
// [diag.invalidAnnotationTarget][column 2][length 10] The annotation 'nonVirtual' can only be used on overridable members.
set a(int value) {}
''');
  }

  void test_overridableMember_typedef() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
@nonVirtual
// [diag.invalidAnnotationTarget][column 2][length 10] The annotation 'nonVirtual' can only be used on overridable members.
typedef bool predicate(Object o);
''');
  }

  void test_override_field() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  int a = 0;
}
class D extends C {
  @override
  int a = 0;
}
''');
  }

  void test_override_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  int get a => 0;
}
class D extends C {
  @override
  int get a => 0;
}
''');
  }

  void test_override_method() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  void m() {}
}
class D extends C {
  @override
  void m() {}
}
''');
  }

  void test_override_setter() async {
    await resolveTestCodeWithDiagnostics('''
class C {
  set a(int p) {}
}
class D extends C {
  @override
  set a(int p) {}
}
''');
  }

  void test_override_topLevelField() async {
    await resolveTestCodeWithDiagnostics(r'''
@override
// [diag.invalidAnnotationTarget][column 2][length 8] The annotation 'override' can only be used on fields, getters, methods, or setters.
int a = 1;
''');
  }

  void test_override_topLevelFunction() async {
    await resolveTestCodeWithDiagnostics(r'''
@override
// [diag.invalidAnnotationTarget][column 2][length 8] The annotation 'override' can only be used on fields, getters, methods, or setters.
class C {}
''');
  }

  void test_parameter_function() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.parameter})
class A {
  const A();
}

@A()
// [diag.invalidAnnotationTarget][column 2][length 1] The annotation 'A.new' can only be used on parameters.
void f(int x) {}
''');
  }

  void test_parameter_parameter() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.parameter})
class A {
  const A();
}

void f(@A() int x) {}
''');
  }

  void test_partOfDirective_importDirective() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta_meta.dart';

@A()
// [diag.invalidAnnotationTarget][column 2][length 1] The annotation 'A.new' can only be used on "part of" directives.
import 'dart:core';

@Target({TargetKind.partOfDirective})
class A {
  const A();
}
''');
  }

  void test_partOfDirective_partOfDirective() async {
    newFile('$testPackageLibPath/b.dart', '''
import 'package:meta/meta_meta.dart';

part 'test.dart';
''');
    await resolveTestCodeWithDiagnostics(r'''

@A()
part of 'b.dart';

@Target({TargetKind.partOfDirective})
class A {
  const A();
}
''');
  }

  void test_setter_field_final() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.setter})
class A {
  const A();
}

class C {
  @A()
// ^
// [diag.invalidAnnotationTarget] The annotation 'A.new' can only be used on setters.
  final int x = 0;
}
''');
  }

  void test_setter_field_mutable() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.setter})
class A {
  const A();
}

class C {
  @A()
// ^
// [diag.invalidAnnotationTarget] The annotation 'A.new' can only be used on setters.
  int x = 0;
}
''');
  }

  void test_setter_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.setter})
class A {
  const A();
}

class C {
  @A()
// ^
// [diag.invalidAnnotationTarget] The annotation 'A.new' can only be used on setters.
  int get x => 0;
}
''');
  }

  void test_setter_method() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.setter})
class A {
  const A();
}

class C {
  @A()
// ^
// [diag.invalidAnnotationTarget] The annotation 'A.new' can only be used on setters.
  int m(int x) => x;
}
''');
  }

  void test_setter_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.setter})
class A {
  const A();
}

class C {
  @A()
  set x(int _x) {}
}
''');
  }

  void test_setter_topLevelSetter() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.setter})
class A {
  const A();
}

@A()
set x(_x) {}
''');
  }

  void test_topLevelVariable_field() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.topLevelVariable})
class A {
  const A();
}

class B {
  @A()
// ^
// [diag.invalidAnnotationTarget] The annotation 'A.new' can only be used on top-level variables.
  int f = 0;
}
''');
  }

  void test_topLevelVariable_topLevelVariable() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.topLevelVariable})
class A {
  const A();
}

@A()
int f = 0;
''');
  }

  void test_type_class() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.type})
class A {
  const A();
}

@A()
class C {}
''');
  }

  void test_type_classTypeAlias() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.type})
class A {
  const A();
}

mixin M {}

@A()
class C = Object with M;
''');
  }

  void test_type_enum() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.type})
class A {
  const A();
}

@A()
enum E {a, b}
''');
  }

  void test_type_extension() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.type})
class A {
  const A();
}

@A()
// [diag.invalidAnnotationTarget][column 2][length 1] The annotation 'A.new' can only be used on types (classes, enums, mixins, or typedefs).
extension on C {}
class C {}
''');
  }

  void test_type_genericTypeAlias() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.type})
class A {
  const A();
}

@A()
typedef F = void Function(int);
''');
  }

  void test_type_mixin() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.type})
class A {
  const A();
}

@A()
mixin M {}
''');
  }

  void test_typedefType_genericTypeAlias() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.typedefType})
class A {
  const A();
}

@A()
typedef F = void Function(int);
''');
  }

  void test_typeParameter_parameter() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.typeParameter})
class A {
  const A();
}

void f(@A() p) {}
//      ^
// [diag.invalidAnnotationTarget] The annotation 'A.new' can only be used on type parameters.
''');
  }

  void test_typeParameter_typeParameter() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.typeParameter})
class A {
  const A();
}

class C<@A() T> {}
''');
  }
}
