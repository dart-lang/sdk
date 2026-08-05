// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MixinApplicationConcreteSuperInvokedMemberTypeTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class MixinApplicationConcreteSuperInvokedMemberTypeTest
    extends PubPackageResolutionTest {
  test_class_method() async {
    await resolveTestCodeWithDiagnostics(r'''
class I {
  void foo([int? p]) {}
}

class A {
  void foo(int? p) {}
}

abstract class B extends A implements I {
  void foo([int? p]);
}

mixin M on I {
  void bar() {
    super.foo(42);
  }
}

abstract class X extends B with M {}
//                              ^
// [diag.mixinApplicationConcreteSuperInvokedMemberType] The super-invoked member 'foo' has the type 'void Function([int?])', and the concrete member in the class has the type 'void Function(int?)'.
''');
  }

  test_class_method_OK_overriddenInMixin() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<T> {
  void remove(T x) {}
}

mixin M<U> on A<U> {
  void remove(Object? x) {
    super.remove(x as U);
  }
}

class X<T> = A<T> with M<T>;
''');
  }

  test_enum_method() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class I {
  void foo([int? p]);
}

mixin M1 {
  void foo(int? p) {}
}

mixin M2 implements I {}

mixin M3 on I {
  void bar() {
    super.foo(42);
  }
}

enum E with M1, M2, M3 {
//                  ^^
// [diag.mixinApplicationConcreteSuperInvokedMemberType] The super-invoked member 'foo' has the type 'void Function([int?])', and the concrete member in the class has the type 'void Function(int?)'.
  v;
  void foo([int? p]) {}
}
''');
  }
}
