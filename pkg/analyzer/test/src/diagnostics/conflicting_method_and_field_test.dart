// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConflictingMethodAndFieldTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class ConflictingMethodAndFieldTest extends PubPackageResolutionTest {
  test_class_inSuper_field() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int foo = 0;
}
class B extends A {
  foo() {}
//^^^
// [diag.conflictingMethodAndField] Class 'B' can't define method 'foo' and have field 'A.foo' with the same name.
}
''');
  }

  test_class_inSuper_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  get foo => 0;
}
class B extends A {
  foo() {}
//^^^
// [diag.conflictingMethodAndField] Class 'B' can't define method 'foo' and have field 'A.foo' with the same name.
}
''');
  }

  @FailingTest() // TODO(scheglov): implement augmentation
  test_class_inSuper_getter_hasAugmentation_inAugmentation() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int get foo => 0;
}

class B extends A {}

augment class B {
  void foo() {}
}
''');
  }

  @FailingTest() // TODO(scheglov): implement augmentation
  test_class_inSuper_getter_hasAugmentation_inDeclaration() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int get foo => 0;
}

class B extends A {
  void foo() {}
}

augment class B {}
''');
  }

  test_class_inSuper_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  set foo(_) {}
}
class B extends A {
  foo() {}
//^^^
// [diag.conflictingMethodAndField] Class 'B' can't define method 'foo' and have field 'A.foo' with the same name.
}
''');
  }

  test_enum_inMixin_field() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  void foo() {}
}

enum E with M {
  v;
  final int foo = 0;
//          ^^^
// [diag.conflictingFieldAndMethod] Class 'E' can't define field 'foo' and have method 'M.foo' with the same name.
}
''');
  }

  test_enum_inMixin_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  int get foo => 0;
}

enum E with M {
  v;
  void foo() {}
//     ^^^
// [diag.conflictingMethodAndField] Class 'E' can't define method 'foo' and have field 'M.foo' with the same name.
}
''');
  }

  @FailingTest() // TODO(scheglov): implement augmentation
  test_enum_inMixin_getter_hasAugmentation_inAugmentation() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  int get foo => 0;
}

enum E with M {v}

augment enum E {;
  void foo() {}
}
''');
  }

  @FailingTest() // TODO(scheglov): implement augmentation
  test_enum_inMixin_getter_hasAugmentation_inDeclaration() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  int get foo => 0;
}

enum E with M {
  v;
  void foo() {}
}

augment enum E {}
''');
  }

  test_enum_inMixin_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  set foo(int _) {}
}

enum E with M {
  v;
  void foo() {}
//     ^^^
// [diag.conflictingMethodAndField] Class 'E' can't define method 'foo' and have field 'M.foo' with the same name.
}
''');
  }

  test_extensionType_field_external() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A(int it) {
  external int foo;
}

extension type B(int it) implements A {
  void foo() {}
}
''');
  }

  test_extensionType_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A(int it) {
  int get foo => 0;
}

extension type B(int it) implements A {
  void foo() {}
}
''');
  }

  test_extensionType_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A(int it) {
  set foo(int _) {}
}

extension type B(int it) implements A {
  void foo() {}
}
''');
  }
}
