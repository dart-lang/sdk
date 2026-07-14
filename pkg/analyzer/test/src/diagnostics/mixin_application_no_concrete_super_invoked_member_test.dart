// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MixinApplicationNoConcreteSuperInvokedMemberTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class MixinApplicationNoConcreteSuperInvokedMemberTest
    extends PubPackageResolutionTest {
  test_class_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  int get foo;
}

mixin M on A {
  void bar() {
    super.foo;
  }
}

abstract class X extends A with M {}
//                              ^
// [diag.mixinApplicationNoConcreteSuperInvokedMember] The class doesn't have a concrete implementation of the super-invoked member 'foo'.
''');
  }

  test_class_inNextMixin() async {
    await resolveTestCodeWithDiagnostics('''
abstract class A {
  void foo();
}

mixin M1 on A {
  void foo() {
    super.foo();
  }
}

mixin M2 on A {
  void foo() {}
}

class X extends A with M1, M2 {}
//                     ^^
// [diag.mixinApplicationNoConcreteSuperInvokedMember] The class doesn't have a concrete implementation of the super-invoked member 'foo'.
''');
  }

  test_class_inSameMixin() async {
    await resolveTestCodeWithDiagnostics('''
abstract class A {
  void foo();
}

mixin M on A {
  void foo() {
    super.foo();
  }
}

class X extends A with M {}
//                     ^
// [diag.mixinApplicationNoConcreteSuperInvokedMember] The class doesn't have a concrete implementation of the super-invoked member 'foo'.
''');
  }

  test_class_method() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  void foo();
}

mixin M on A {
  void bar() {
    super.foo();
  }
}

abstract class X extends A with M {}
//                              ^
// [diag.mixinApplicationNoConcreteSuperInvokedMember] The class doesn't have a concrete implementation of the super-invoked member 'foo'.
''');
  }

  test_class_OK_hasNSM() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  void foo();
}

mixin M on A {
  void bar() {
    super.foo();
  }
}

class C implements A {
  noSuchMethod(_) {}
}

class X extends C with M {}
''');
  }

  test_class_OK_hasNSM2() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  void foo();
}

mixin M on A {
  void bar() {
    super.foo();
  }
}

/// Class `B` has noSuchMethod forwarder for `foo`.
class B implements A {
  noSuchMethod(_) {}
}

/// Class `C` is abstract, but it inherits noSuchMethod forwarders from `B`.
abstract class C extends B {}

class X extends C with M {}
''');
  }

  test_class_OK_inPreviousMixin() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  void foo();
}

mixin M1 {
  void foo() {}
}

mixin M2 on A {
  void bar() {
    super.foo();
  }
}

class X extends A with M1, M2 {}
''');
  }

  test_class_OK_inPreviousMixin_fromAugmentation() async {
    await resolveTestCodeWithDiagnostics('''
mixin M1 {
  void foo() {}
}

mixin M2 on M1 {
  void bar() {
    super.foo();
  }
}

class X with M1 {}
augment class X with M2 {}
''');
  }

  test_class_OK_inSuper_fromMixin() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  void foo();
}

mixin M1 {
  void foo() {}
}

class B extends A with M1 {}

mixin M2 on A {
  void bar() {
    super.foo();
  }
}

class X extends B with M2 {}
''');
  }

  test_class_OK_notInvoked() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  void foo();
}

mixin M on A {}

abstract class X extends A with M {}
''');
  }

  test_class_OK_super_covariant() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  bar(num n) {}
}

mixin M on A {
  test() {
    super.bar(3.14);
  }
}

class B implements A {
  bar(covariant int i) {}
}

class C extends B with M {}
''');
  }

  test_class_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  void set foo(_);
}

mixin M on A {
  void bar() {
    super.foo = 0;
  }
}

abstract class X extends A with M {}
//                              ^
// [diag.mixinApplicationNoConcreteSuperInvokedSetter] The class doesn't have a concrete implementation of the super-invoked setter 'foo'.
''');
  }

  test_enum_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M1 {
  int get foo;
}

mixin M2 on M1 {
  void bar() {
    super.foo;
  }
}

enum E with M1, M2 {
//              ^^
// [diag.mixinApplicationNoConcreteSuperInvokedMember] The class doesn't have a concrete implementation of the super-invoked member 'foo'.
  v;
  int get foo => 0;
}
''');
  }

  test_enum_getter_exists() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M1 {
  int get foo => 0;
}

mixin M2 on M1 {
  void bar() {
    super.foo;
  }
}

enum E with M1, M2 {
  v
}
''');
  }

  test_enum_getter_index() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M on Enum {
  void foo() {
    super.index;
  }
}

enum E with M {
  v
}
''');
  }

  test_enum_method() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M1 {
  void foo();
}

mixin M2 on M1 {
  void bar() {
    super.foo();
  }
}

enum E with M1, M2 {
//              ^^
// [diag.mixinApplicationNoConcreteSuperInvokedMember] The class doesn't have a concrete implementation of the super-invoked member 'foo'.
  v;
  void foo() {}
}
''');
  }

  test_enum_method_exists() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M1 {
  void foo() {}
}

mixin M2 on M1 {
  void bar() {
    super.foo();
  }
}

enum E with M1, M2 {
  v
}
''');
  }

  test_enum_OK_getter_inPreviousMixin() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M1 {
  int get foo => 0;
}

mixin M2 on M1 {
  void bar() {
    super.foo;
  }
}

enum E with M1, M2 {
  v;
}
''');
  }

  test_enum_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M1 {
  set foo(int _);
}

mixin M2 on M1 {
  void bar() {
    super.foo = 0;
  }
}

enum E with M1, M2 {
//              ^^
// [diag.mixinApplicationNoConcreteSuperInvokedSetter] The class doesn't have a concrete implementation of the super-invoked setter 'foo'.
  v;
  set foo(int _) {}
}
''');
  }
}
