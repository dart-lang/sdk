// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConflictingStaticAndInstanceClassTest);
    defineReflectiveTests(ConflictingStaticAndInstanceEnumTest);
    defineReflectiveTests(ConflictingStaticAndInstanceMixinTest);
    defineReflectiveTests(ConflictingStaticAndInstanceExtensionTypeTest);
  });
}

@reflectiveTest
class ConflictingStaticAndInstanceClassTest extends PubPackageResolutionTest {
  test_inClass_instanceMethod_staticMethod() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  void foo() {}
  static void foo() {}
//            ^^^
// [diag.conflictingStaticAndInstance] Class 'C' can't define static member 'foo' and have instance member 'C.foo' with the same name.
}
''');
  }

  test_inClass_instanceMethod_staticMethodInAugmentation() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  void foo() {}
}

augment class A {
  static void foo() {}
//            ^^^
// [diag.conflictingStaticAndInstance] Class 'A' can't define static member 'foo' and have instance member 'A.foo' with the same name.
}
''');
  }

  test_inClass_staticGetter_instanceGetter() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  static int get foo => 0;
//               ^^^
// [diag.conflictingStaticAndInstance] Class 'C' can't define static member 'foo' and have instance member 'C.foo' with the same name.
  int get foo => 0;
}
''');
  }

  test_inClass_staticGetter_instanceMethod() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  static int get foo => 0;
//               ^^^
// [diag.conflictingStaticAndInstance] Class 'C' can't define static member 'foo' and have instance member 'C.foo' with the same name.
  void foo() {}
}
''');
  }

  test_inClass_staticGetter_instanceSetter() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  static int get foo => 0;
//               ^^^
// [diag.conflictingStaticAndInstance] Class 'C' can't define static member 'foo' and have instance member 'C.foo' with the same name.
  set foo(_) {}
}
''');
  }

  test_inClass_staticMethod_instanceGetter() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  static void foo() {}
//            ^^^
// [diag.conflictingStaticAndInstance] Class 'C' can't define static member 'foo' and have instance member 'C.foo' with the same name.
  int get foo => 0;
}
''');
  }

  test_inClass_staticMethod_instanceMethod() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  static void foo() {}
//            ^^^
// [diag.conflictingStaticAndInstance] Class 'C' can't define static member 'foo' and have instance member 'C.foo' with the same name.
  void foo() {}
}
''');
  }

  test_inClass_staticMethod_instanceMethodInAugmentation() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static void foo() {}
//            ^^^
// [diag.conflictingStaticAndInstance] Class 'A' can't define static member 'foo' and have instance member 'A.foo' with the same name.
}

augment class A {
  void foo() {}
}
''');
  }

  test_inClass_staticMethod_instanceSetter() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  static void foo() {}
//            ^^^
// [diag.conflictingStaticAndInstance] Class 'C' can't define static member 'foo' and have instance member 'C.foo' with the same name.
  set foo(_) {}
}
''');
  }

  test_inClass_staticSetter_instanceGetter() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  static set foo(_) {}
//           ^^^
// [diag.conflictingStaticAndInstance] Class 'C' can't define static member 'foo' and have instance member 'C.foo' with the same name.
  int get foo => 0;
}
''');
  }

  test_inClass_staticSetter_instanceMethod() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  static set foo(_) {}
//           ^^^
// [diag.conflictingStaticAndInstance] Class 'C' can't define static member 'foo' and have instance member 'C.foo' with the same name.
  void foo() {}
}
''');
  }

  test_inClass_staticSetter_instanceSetter() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  static set foo(_) {}
//           ^^^
// [diag.conflictingStaticAndInstance] Class 'C' can't define static member 'foo' and have instance member 'C.foo' with the same name.
  set foo(_) {}
}
''');
  }

  test_inInterface_instanceGetter_staticGetter() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  int get foo => 0;
}
abstract class B implements A {
  static int get foo => 0;
//               ^^^
// [diag.conflictingStaticAndInstance] Class 'B' can't define static member 'foo' and have instance member 'A.foo' with the same name.
}
''');
  }

  test_inInterface_instanceGetter_staticMethod() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  int get foo => 0;
}
abstract class B implements A {
  static void foo() {}
//            ^^^
// [diag.conflictingStaticAndInstance] Class 'B' can't define static member 'foo' and have instance member 'A.foo' with the same name.
}
''');
  }

  test_inInterface_instanceMethod_staticMethod() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  void foo() {}
}
abstract class B implements A {
  static void foo() {}
//            ^^^
// [diag.conflictingStaticAndInstance] Class 'B' can't define static member 'foo' and have instance member 'A.foo' with the same name.
}
''');
  }

  test_inInterface_instanceMethod_staticSetter() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  void foo() {}
}
abstract class B implements A {
  static set foo(_) {}
//           ^^^
// [diag.conflictingStaticAndInstance] Class 'B' can't define static member 'foo' and have instance member 'A.foo' with the same name.
}
''');
  }

  test_inInterface_instanceSetter_staticGetter() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  set foo(_) {}
}
abstract class B implements A {
  static int get foo => 0;
//               ^^^
// [diag.conflictingStaticAndInstance] Class 'B' can't define static member 'foo' and have instance member 'A.foo' with the same name.
}
''');
  }

  test_inInterface_instanceSetter_staticMethod() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  set foo(_) {}
}
abstract class B implements A {
  static void foo() {}
//            ^^^
// [diag.conflictingStaticAndInstance] Class 'B' can't define static member 'foo' and have instance member 'A.foo' with the same name.
}
''');
  }

  test_inInterface_instanceSetter_staticSetter() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  set foo(_) {}
}
abstract class B implements A {
  static set foo(_) {}
//           ^^^
// [diag.conflictingStaticAndInstance] Class 'B' can't define static member 'foo' and have instance member 'A.foo' with the same name.
}
''');
  }

  test_inMixin_instanceGetter_staticGetter() async {
    await resolveTestCodeWithDiagnostics('''
mixin A {
  int get foo => 0;
}
class B extends Object with A {
  static int get foo => 0;
//               ^^^
// [diag.conflictingStaticAndInstance] Class 'B' can't define static member 'foo' and have instance member 'A.foo' with the same name.
}
''');
  }

  test_inMixin_instanceGetter_staticMethod() async {
    await resolveTestCodeWithDiagnostics('''
mixin A {
  int get foo => 0;
}
class B extends Object with A {
  static void foo() {}
//            ^^^
// [diag.conflictingStaticAndInstance] Class 'B' can't define static member 'foo' and have instance member 'A.foo' with the same name.
}
''');
  }

  test_inMixin_instanceMethod_staticMethod() async {
    await resolveTestCodeWithDiagnostics('''
mixin M {
  void foo() {}
}
class B extends Object with M {
  static void foo() {}
//            ^^^
// [diag.conflictingStaticAndInstance] Class 'B' can't define static member 'foo' and have instance member 'M.foo' with the same name.
}
''');
  }

  test_inMixin_instanceMethod_staticMethodInAugmentation() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin A {
  void foo() {}
}

augment mixin A {
  static void foo() {}
//            ^^^
// [diag.conflictingStaticAndInstance] Class 'A' can't define static member 'foo' and have instance member 'A.foo' with the same name.
}
''');
  }

  test_inMixin_instanceMethod_staticSetter() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin A {
  void foo() {}
}
class B extends Object with A {
  static set foo(_) {}
//           ^^^
// [diag.conflictingStaticAndInstance] Class 'B' can't define static member 'foo' and have instance member 'A.foo' with the same name.
}
''');
  }

  test_inMixin_instanceSetter_staticGetter() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin A {
  set foo(_) {}
}
class B extends Object with A {
  static int get foo => 0;
//               ^^^
// [diag.conflictingStaticAndInstance] Class 'B' can't define static member 'foo' and have instance member 'A.foo' with the same name.
}
''');
  }

  test_inMixin_instanceSetter_staticMethod() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin A {
  set foo(_) {}
}
class B extends Object with A {
  static void foo() {}
//            ^^^
// [diag.conflictingStaticAndInstance] Class 'B' can't define static member 'foo' and have instance member 'A.foo' with the same name.
}
''');
  }

  test_inMixin_instanceSetter_staticSetter() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin A {
  set foo(_) {}
}
class B extends Object with A {
  static set foo(_) {}
//           ^^^
// [diag.conflictingStaticAndInstance] Class 'B' can't define static member 'foo' and have instance member 'A.foo' with the same name.
}
''');
  }

  test_inMixin_staticMethod_instanceMethodInAugmentation() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin A {
  static void foo() {}
//            ^^^
// [diag.conflictingStaticAndInstance] Class 'A' can't define static member 'foo' and have instance member 'A.foo' with the same name.
}

augment mixin A {
  void foo() {}
}
''');
  }

  test_inSuper_implicitObject_staticMethod_instanceGetter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static String runtimeType() => 'x';
//              ^^^^^^^^^^^
// [diag.conflictingStaticAndInstance] Class 'A' can't define static member 'runtimeType' and have instance member 'Object.runtimeType' with the same name.
}
''');
  }

  test_inSuper_implicitObject_staticMethod_instanceMethod() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static String toString() => 'x';
//              ^^^^^^^^
// [diag.conflictingStaticAndInstance] Class 'A' can't define static member 'toString' and have instance member 'Object.toString' with the same name.
}
''');
  }

  test_inSuper_instanceGetter_staticGetter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int get foo => 0;
}
class B extends A {
  static int get foo => 0;
//               ^^^
// [diag.conflictingStaticAndInstance] Class 'B' can't define static member 'foo' and have instance member 'A.foo' with the same name.
}
''');
  }

  test_inSuper_instanceGetter_staticMethod() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int get foo => 0;
}
class B extends A {
  static void foo() {}
//            ^^^
// [diag.conflictingStaticAndInstance] Class 'B' can't define static member 'foo' and have instance member 'A.foo' with the same name.
}
''');
  }

  test_inSuper_instanceMethod_staticGetter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  void foo() {}
}
class B extends A {
  static int get foo => 0;
//               ^^^
// [diag.conflictingStaticAndInstance] Class 'B' can't define static member 'foo' and have instance member 'A.foo' with the same name.
}
''');
  }

  test_inSuper_instanceMethod_staticMethod() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  void foo() {}
}
class B extends A {
  static void foo() {}
//            ^^^
// [diag.conflictingStaticAndInstance] Class 'B' can't define static member 'foo' and have instance member 'A.foo' with the same name.
}
''');
  }

  test_inSuper_instanceMethod_staticSetter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  void foo() {}
}
class B extends A {
  static set foo(_) {}
//           ^^^
// [diag.conflictingStaticAndInstance] Class 'B' can't define static member 'foo' and have instance member 'A.foo' with the same name.
}
''');
  }

  test_inSuper_instanceSetter_staticGetter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  set foo(_) {}
}
class B extends A {
  static int get foo => 0;
//               ^^^
// [diag.conflictingStaticAndInstance] Class 'B' can't define static member 'foo' and have instance member 'A.foo' with the same name.
}
''');
  }

  test_inSuper_instanceSetter_staticMethod() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  set foo(_) {}
}
class B extends A {
  static void foo() {}
//            ^^^
// [diag.conflictingStaticAndInstance] Class 'B' can't define static member 'foo' and have instance member 'A.foo' with the same name.
}
''');
  }

  test_inSuper_instanceSetter_staticSetter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  set foo(_) {}
}
class B extends A {
  static set foo(_) {}
//           ^^^
// [diag.conflictingStaticAndInstance] Class 'B' can't define static member 'foo' and have instance member 'A.foo' with the same name.
}
''');
  }
}

@reflectiveTest
class ConflictingStaticAndInstanceEnumTest extends PubPackageResolutionTest {
  test_constant_hashCode() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  a, hashCode, b
//   ^^^^^^^^
// [diag.conflictingStaticAndInstance] Class 'E' can't define static member 'hashCode' and have instance member 'E.hashCode' with the same name.
}
''');
  }

  test_constant_index() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  a, index, b
//   ^^^^^
// [diag.conflictingStaticAndInstance] Class 'E' can't define static member 'index' and have instance member 'E.index' with the same name.
}
''');
  }

  test_constant_instanceSetter() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  foo;
//^^^
// [diag.conflictingStaticAndInstance] Class 'E' can't define static member 'foo' and have instance member 'E.foo' with the same name.
  set foo(_) {}
}
''');
  }

  test_constant_noSuchMethod() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  a, noSuchMethod, b
//   ^^^^^^^^^^^^
// [diag.conflictingStaticAndInstance] Class 'E' can't define static member 'noSuchMethod' and have instance member 'E.noSuchMethod' with the same name.
}
''');
  }

  test_constant_runtimeType() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  a, runtimeType, b
//   ^^^^^^^^^^^
// [diag.conflictingStaticAndInstance] Class 'E' can't define static member 'runtimeType' and have instance member 'E.runtimeType' with the same name.
}
''');
  }

  test_constant_staticMethod() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  foo;
//^^^
// [diag.conflictingStaticAndInstance] Class 'E' can't define static member 'foo' and have instance member 'E.foo' with the same name.
  void foo() {}
}
''');
  }

  test_constant_toString() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  a, toString, b
//   ^^^^^^^^
// [diag.conflictingStaticAndInstance] Class 'E' can't define static member 'toString' and have instance member 'E.toString' with the same name.
}
''');
  }

  test_field_dartCoreEnum() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  static final int hashCode = 0;
//                 ^^^^^^^^
// [diag.conflictingStaticAndInstance] Class 'E' can't define static member 'hashCode' and have instance member 'E.hashCode' with the same name.
}
''');
  }

  test_field_mixin_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  int get foo => 0;
}

enum E with M {
  v;
  static final int foo = 0;
//                 ^^^
// [diag.conflictingStaticAndInstance] Class 'E' can't define static member 'foo' and have instance member 'E.foo' with the same name.
}
''');
  }

  test_field_mixin_method() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  void foo() {}
}

enum E with M {
  v;
  static final int foo = 0;
//                 ^^^
// [diag.conflictingStaticAndInstance] Class 'E' can't define static member 'foo' and have instance member 'E.foo' with the same name.
}
''');
  }

  test_field_mixin_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  set foo(int _) {}
}

enum E with M {
  v;
  static final int foo = 0;
//                 ^^^
// [diag.conflictingStaticAndInstance] Class 'E' can't define static member 'foo' and have instance member 'E.foo' with the same name.
}
''');
  }

  test_field_this_constant() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  foo;
//^^^
// [diag.conflictingStaticAndInstance] Class 'E' can't define static member 'foo' and have instance member 'E.foo' with the same name.
  int get foo => 0;
}
''');
  }

  test_field_this_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  static final int foo = 0;
//                 ^^^
// [diag.conflictingStaticAndInstance] Class 'E' can't define static member 'foo' and have instance member 'E.foo' with the same name.
  int get foo => 0;
}
''');
  }

  test_field_this_method() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  static final int foo = 0;
//                 ^^^
// [diag.conflictingStaticAndInstance] Class 'E' can't define static member 'foo' and have instance member 'E.foo' with the same name.
  void foo() {}
}
''');
  }

  test_field_this_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  static final int foo = 0;
//                 ^^^
// [diag.conflictingStaticAndInstance] Class 'E' can't define static member 'foo' and have instance member 'E.foo' with the same name.
  set foo(int _) {}
}
''');
  }

  test_method_dartCoreEnum() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  static int hashCode() => 0;
//           ^^^^^^^^
// [diag.conflictingStaticAndInstance] Class 'E' can't define static member 'hashCode' and have instance member 'E.hashCode' with the same name.
}
''');
  }

  test_method_mixin_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  int get foo => 0;
}

enum E with M {
  v;
  static void foo() {}
//            ^^^
// [diag.conflictingStaticAndInstance] Class 'E' can't define static member 'foo' and have instance member 'E.foo' with the same name.
}
''');
  }

  test_method_mixin_method() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  void foo() {}
}

enum E with M {
  v;
  static void foo() {}
//            ^^^
// [diag.conflictingStaticAndInstance] Class 'E' can't define static member 'foo' and have instance member 'E.foo' with the same name.
}
''');
  }

  test_method_mixin_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  set foo(int _) {}
}

enum E with M {
  v;
  static void foo() {}
//            ^^^
// [diag.conflictingStaticAndInstance] Class 'E' can't define static member 'foo' and have instance member 'E.foo' with the same name.
}
''');
  }

  test_staticGetter_instanceSetter() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  static int get foo => 0;
//               ^^^
// [diag.conflictingStaticAndInstance] Class 'E' can't define static member 'foo' and have instance member 'E.foo' with the same name.
  set foo(_) {}
}
''');
  }

  test_staticMethod_instanceGetter() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  static void foo() {}
//            ^^^
// [diag.conflictingStaticAndInstance] Class 'E' can't define static member 'foo' and have instance member 'E.foo' with the same name.
  int get foo => 0;
}
''');
  }

  test_staticMethod_instanceMethod() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  static void foo() {}
//            ^^^
// [diag.conflictingStaticAndInstance] Class 'E' can't define static member 'foo' and have instance member 'E.foo' with the same name.
  void foo() {}
}
''');
  }

  test_staticMethod_instanceSetter() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  static void foo() {}
//            ^^^
// [diag.conflictingStaticAndInstance] Class 'E' can't define static member 'foo' and have instance member 'E.foo' with the same name.
  set foo(int _) {}
}
''');
  }

  test_staticSetter_instanceGetter() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  static set foo(_) {}
//           ^^^
// [diag.conflictingStaticAndInstance] Class 'E' can't define static member 'foo' and have instance member 'E.foo' with the same name.
  int get foo => 0;
}
''');
  }
}

@reflectiveTest
class ConflictingStaticAndInstanceExtensionTypeTest
    extends PubPackageResolutionTest {
  test_inExtensionType_staticGetter_instanceGetter() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A(int it) {
  static int get foo => 0;
//               ^^^
// [diag.conflictingStaticAndInstance] Class 'A' can't define static member 'foo' and have instance member 'A.foo' with the same name.
  int get foo => 0;
}
''');
  }

  test_inExtensionType_staticGetter_instanceMethod() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A(int t) {
  static int get foo => 0;
//               ^^^
// [diag.conflictingStaticAndInstance] Class 'A' can't define static member 'foo' and have instance member 'A.foo' with the same name.
  void foo() {}
}
''');
  }

  test_inExtensionType_staticGetter_instanceSetter() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A(int it) {
  static int get foo => 0;
//               ^^^
// [diag.conflictingStaticAndInstance] Class 'A' can't define static member 'foo' and have instance member 'A.foo' with the same name.
  set foo(_) {}
}
''');
  }

  test_inExtensionType_staticMethod_instanceGetter() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A(int it) {
  static void foo() {}
//            ^^^
// [diag.conflictingStaticAndInstance] Class 'A' can't define static member 'foo' and have instance member 'A.foo' with the same name.
  int get foo => 0;
}
''');
  }

  test_inExtensionType_staticMethod_instanceMethod() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A(int it) {
  static void foo() {}
//            ^^^
// [diag.conflictingStaticAndInstance] Class 'A' can't define static member 'foo' and have instance member 'A.foo' with the same name.
  void foo() {}
}
''');
  }

  test_inExtensionType_staticMethod_instanceSetter() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A(int it) {
  static void foo() {}
//            ^^^
// [diag.conflictingStaticAndInstance] Class 'A' can't define static member 'foo' and have instance member 'A.foo' with the same name.
  set foo(_) {}
}
''');
  }

  test_inExtensionType_staticSetter_instanceGetter() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A(int it) {
  static set foo(_) {}
//           ^^^
// [diag.conflictingStaticAndInstance] Class 'A' can't define static member 'foo' and have instance member 'A.foo' with the same name.
  int get foo => 0;
}
''');
  }

  test_inExtensionType_staticSetter_instanceMethod() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A(int it) {
  static set foo(_) {}
//           ^^^
// [diag.conflictingStaticAndInstance] Class 'A' can't define static member 'foo' and have instance member 'A.foo' with the same name.
  void foo() {}
}
''');
  }

  test_inExtensionType_staticSetter_instanceSetter() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A(int it) {
  static set foo(_) {}
//           ^^^
// [diag.conflictingStaticAndInstance] Class 'A' can't define static member 'foo' and have instance member 'A.foo' with the same name.
  set foo(_) {}
}
''');
  }

  test_inInterface_instanceGetter_staticGetter() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A(int it) {
  int get foo => 0;
}

extension type B(int it) implements A {
  static int get foo => 0;
//               ^^^
// [diag.conflictingStaticAndInstance] Class 'B' can't define static member 'foo' and have instance member 'A.foo' with the same name.
}
''');
  }

  test_inInterface_instanceGetter_staticMethod() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A(int it) {
  int get foo => 0;
}

extension type B(int it) implements A {
  static void foo() {}
//            ^^^
// [diag.conflictingStaticAndInstance] Class 'B' can't define static member 'foo' and have instance member 'A.foo' with the same name.
}
''');
  }

  test_inInterface_instanceMethod_staticGetter() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A(int it) {
  int get foo => 0;
}

extension type B(int it) implements A {
  static void foo() {}
//            ^^^
// [diag.conflictingStaticAndInstance] Class 'B' can't define static member 'foo' and have instance member 'A.foo' with the same name.
}
''');
  }

  test_inInterface_instanceMethod_staticMethod() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A(int it) {
  void foo() {}
}

extension type B(int it) implements A {
  static void foo() {}
//            ^^^
// [diag.conflictingStaticAndInstance] Class 'B' can't define static member 'foo' and have instance member 'A.foo' with the same name.
}
''');
  }

  test_inInterface_instanceMethod_staticSetter() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A(int it) {
  void foo() {}
}

extension type B(int it) implements A {
  static set foo(_) {}
//           ^^^
// [diag.conflictingStaticAndInstance] Class 'B' can't define static member 'foo' and have instance member 'A.foo' with the same name.
}
''');
  }

  test_inInterface_instanceSetter_staticGetter() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A(int it) {
  set foo(_) {}
}

extension type B(int it) implements A {
  static int get foo => 0;
//               ^^^
// [diag.conflictingStaticAndInstance] Class 'B' can't define static member 'foo' and have instance member 'A.foo' with the same name.
}
''');
  }

  test_inInterface_instanceSetter_staticMethod() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A(int it) {
  set foo(_) {}
}

extension type B(int it) implements A {
  static void foo() {}
//            ^^^
// [diag.conflictingStaticAndInstance] Class 'B' can't define static member 'foo' and have instance member 'A.foo' with the same name.
}
''');
  }

  test_inInterface_instanceSetter_staticSetter() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A(int it) {
  set foo(_) {}
}

extension type B(int it) implements A {
  static set foo(_) {}
//           ^^^
// [diag.conflictingStaticAndInstance] Class 'B' can't define static member 'foo' and have instance member 'A.foo' with the same name.
}
''');
  }
}

@reflectiveTest
class ConflictingStaticAndInstanceMixinTest extends PubPackageResolutionTest {
  test_dartCoreEnum_index_field() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M on Enum {
  static int index = 0;
//           ^^^^^
// [diag.conflictingStaticAndInstance] Class 'M' can't define static member 'index' and have instance member 'Enum.index' with the same name.
}
''');
  }

  test_dartCoreEnum_index_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M on Enum {
  static int get index => 0;
//               ^^^^^
// [diag.conflictingStaticAndInstance] Class 'M' can't define static member 'index' and have instance member 'Enum.index' with the same name.
}
''');
  }

  test_dartCoreEnum_index_method() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M on Enum {
  static int index() => 0;
//           ^^^^^
// [diag.conflictingStaticAndInstance] Class 'M' can't define static member 'index' and have instance member 'Enum.index' with the same name.
}
''');
  }

  test_dartCoreEnum_index_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M on Enum {
  static set index(int _) {}
//           ^^^^^
// [diag.conflictingStaticAndInstance] Class 'M' can't define static member 'index' and have instance member 'Enum.index' with the same name.
}
''');
  }

  test_inConstraint_implicitObject_staticMethod_instanceGetter() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  static String runtimeType() => 'x';
//              ^^^^^^^^^^^
// [diag.conflictingStaticAndInstance] Class 'M' can't define static member 'runtimeType' and have instance member 'Object.runtimeType' with the same name.
}
''');
  }

  test_inConstraint_implicitObject_staticMethod_instanceMethod() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  static String toString() => 'x';
//              ^^^^^^^^
// [diag.conflictingStaticAndInstance] Class 'M' can't define static member 'toString' and have instance member 'Object.toString' with the same name.
}
''');
  }

  test_inConstraint_instanceGetter_staticGetter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int get foo => 0;
}
mixin M on A {
  static int get foo => 0;
//               ^^^
// [diag.conflictingStaticAndInstance] Class 'M' can't define static member 'foo' and have instance member 'A.foo' with the same name.
}
''');
  }

  test_inConstraint_instanceGetter_staticMethod() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int get foo => 0;
}
mixin M on A {
  static void foo() {}
//            ^^^
// [diag.conflictingStaticAndInstance] Class 'M' can't define static member 'foo' and have instance member 'A.foo' with the same name.
}
''');
  }

  test_inConstraint_instanceMethod_staticMethod() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  void foo() {}
}
mixin M on A {
  static void foo() {}
//            ^^^
// [diag.conflictingStaticAndInstance] Class 'M' can't define static member 'foo' and have instance member 'A.foo' with the same name.
}
''');
  }

  test_inConstraint_instanceMethod_staticSetter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  void foo() {}
}
mixin M on A {
  static set foo(_) {}
//           ^^^
// [diag.conflictingStaticAndInstance] Class 'M' can't define static member 'foo' and have instance member 'A.foo' with the same name.
}
''');
  }

  test_inConstraint_instanceSetter_staticGetter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  set foo(_) {}
}
mixin M on A {
  static int get foo => 0;
//               ^^^
// [diag.conflictingStaticAndInstance] Class 'M' can't define static member 'foo' and have instance member 'A.foo' with the same name.
}
''');
  }

  test_inConstraint_instanceSetter_staticMethod() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  set foo(_) {}
}
mixin M on A {
  static void foo() {}
//            ^^^
// [diag.conflictingStaticAndInstance] Class 'M' can't define static member 'foo' and have instance member 'A.foo' with the same name.
}
''');
  }

  test_inConstraint_instanceSetter_staticSetter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  set foo(_) {}
}
mixin M on A {
  static set foo(_) {}
//           ^^^
// [diag.conflictingStaticAndInstance] Class 'M' can't define static member 'foo' and have instance member 'A.foo' with the same name.
}
''');
  }

  test_inInterface_instanceGetter_staticGetter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int get foo => 0;
}
mixin M implements A {
  static int get foo => 0;
//               ^^^
// [diag.conflictingStaticAndInstance] Class 'M' can't define static member 'foo' and have instance member 'A.foo' with the same name.
}
''');
  }

  test_inInterface_instanceGetter_staticMethod() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int get foo => 0;
}
mixin M implements A {
  static void foo() {}
//            ^^^
// [diag.conflictingStaticAndInstance] Class 'M' can't define static member 'foo' and have instance member 'A.foo' with the same name.
}
''');
  }

  test_inInterface_instanceMethod_staticGetter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int get foo => 0;
}
mixin M implements A {
  static void foo() {}
//            ^^^
// [diag.conflictingStaticAndInstance] Class 'M' can't define static member 'foo' and have instance member 'A.foo' with the same name.
}
''');
  }

  test_inInterface_instanceMethod_staticMethod() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  void foo() {}
}
mixin M implements A {
  static void foo() {}
//            ^^^
// [diag.conflictingStaticAndInstance] Class 'M' can't define static member 'foo' and have instance member 'A.foo' with the same name.
}
''');
  }

  test_inInterface_instanceMethod_staticSetter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  void foo() {}
}
mixin M implements A {
  static set foo(_) {}
//           ^^^
// [diag.conflictingStaticAndInstance] Class 'M' can't define static member 'foo' and have instance member 'A.foo' with the same name.
}
''');
  }

  test_inInterface_instanceSetter_staticGetter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  set foo(_) {}
}
mixin M implements A {
  static int get foo => 0;
//               ^^^
// [diag.conflictingStaticAndInstance] Class 'M' can't define static member 'foo' and have instance member 'A.foo' with the same name.
}
''');
  }

  test_inInterface_instanceSetter_staticMethod() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  set foo(_) {}
}
mixin M implements A {
  static void foo() {}
//            ^^^
// [diag.conflictingStaticAndInstance] Class 'M' can't define static member 'foo' and have instance member 'A.foo' with the same name.
}
''');
  }

  test_inInterface_instanceSetter_staticSetter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  set foo(_) {}
}
mixin M implements A {
  static set foo(_) {}
//           ^^^
// [diag.conflictingStaticAndInstance] Class 'M' can't define static member 'foo' and have instance member 'A.foo' with the same name.
}
''');
  }

  test_inMixin_staticGetter_instanceGetter() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  static int get foo => 0;
//               ^^^
// [diag.conflictingStaticAndInstance] Class 'M' can't define static member 'foo' and have instance member 'M.foo' with the same name.
  int get foo => 0;
}
''');
  }

  test_inMixin_staticGetter_instanceMethod() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  static int get foo => 0;
//               ^^^
// [diag.conflictingStaticAndInstance] Class 'M' can't define static member 'foo' and have instance member 'M.foo' with the same name.
  void foo() {}
}
''');
  }

  test_inMixin_staticGetter_instanceSetter() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  static int get foo => 0;
//               ^^^
// [diag.conflictingStaticAndInstance] Class 'M' can't define static member 'foo' and have instance member 'M.foo' with the same name.
  set foo(_) {}
}
''');
  }

  test_inMixin_staticMethod_instanceGetter() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  static void foo() {}
//            ^^^
// [diag.conflictingStaticAndInstance] Class 'M' can't define static member 'foo' and have instance member 'M.foo' with the same name.
  int get foo => 0;
}
''');
  }

  test_inMixin_staticMethod_instanceMethod() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  static void foo() {}
//            ^^^
// [diag.conflictingStaticAndInstance] Class 'M' can't define static member 'foo' and have instance member 'M.foo' with the same name.
  void foo() {}
}
''');
  }

  test_inMixin_staticMethod_instanceSetter() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  static void foo() {}
//            ^^^
// [diag.conflictingStaticAndInstance] Class 'M' can't define static member 'foo' and have instance member 'M.foo' with the same name.
  set foo(_) {}
}
''');
  }

  test_inMixin_staticSetter_instanceGetter() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  static set foo(_) {}
//           ^^^
// [diag.conflictingStaticAndInstance] Class 'M' can't define static member 'foo' and have instance member 'M.foo' with the same name.
  int get foo => 0;
}
''');
  }

  test_inMixin_staticSetter_instanceMethod() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  static set foo(_) {}
//           ^^^
// [diag.conflictingStaticAndInstance] Class 'M' can't define static member 'foo' and have instance member 'M.foo' with the same name.
  void foo() {}
}
''');
  }

  test_inMixin_staticSetter_instanceSetter() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  static set foo(_) {}
//           ^^^
// [diag.conflictingStaticAndInstance] Class 'M' can't define static member 'foo' and have instance member 'M.foo' with the same name.
  set foo(_) {}
}
''');
  }
}
