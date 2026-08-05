// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConflictingFieldAndMethodTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class ConflictingFieldAndMethodTest extends PubPackageResolutionTest {
  test_class_inSuper_field() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  foo() {}
}
class B extends A {
  int foo = 0;
//    ^^^
// [diag.conflictingFieldAndMethod] Class 'B' can't define field 'foo' and have method 'A.foo' with the same name.
}
''');
  }

  test_class_inSuper_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  foo() {}
}
class B extends A {
  get foo => 0;
//    ^^^
// [diag.conflictingFieldAndMethod] Class 'B' can't define field 'foo' and have method 'A.foo' with the same name.
}
''');
  }

  @FailingTest() // TODO(scheglov): implement augmentation
  test_class_inSuper_getter_withAugmentation_inAugmentation() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  void foo() {}
}

class B extends A {}

augment class B {
  int get foo => 0;
}
''');
  }

  @FailingTest() // TODO(scheglov): implement augmentation
  test_class_inSuper_getter_withAugmentation_inDeclaration() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  void foo() {}
}

class B {
  int get foo => 0;
}

augment class B extends A {}
''');
  }

  test_class_inSuper_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  foo() {}
}
class B extends A {
  set foo(_) {}
//    ^^^
// [diag.conflictingFieldAndMethod] Class 'B' can't define field 'foo' and have method 'A.foo' with the same name.
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
  void foo() {}
}

enum E with M {
  v;
  int get foo => 0;
//        ^^^
// [diag.conflictingFieldAndMethod] Class 'E' can't define field 'foo' and have method 'M.foo' with the same name.
}
''');
  }

  @FailingTest() // TODO(scheglov): implement augmentation
  test_enum_inMixin_getter_withAugmentation_inAugmentation() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  void foo() {}
}

enum E with M {v}

augment enum E {;
  int get foo => 0;
}
''');
  }

  @FailingTest() // TODO(scheglov): implement augmentation
  test_enum_inMixin_getter_withAugmentation_inDeclaration() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  void foo() {}
}

enum E {
  v;
  int get foo => 0;
}

augment enum E with M {}
''');
  }

  test_enum_inMixin_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  void foo() {}
}

enum E with M {
  v;
  set foo(int _) {}
//    ^^^
// [diag.conflictingFieldAndMethod] Class 'E' can't define field 'foo' and have method 'M.foo' with the same name.
}
''');
  }

  test_extensionType_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A(int it) {
  void foo() {}
}

extension type B(int it) implements A {
  int get foo => 0;
}
''');
  }

  test_extensionType_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A(int it) {
  void foo() {}
}

extension type B(int it) implements A {
  set foo(int _) {}
}
''');
  }

  @FailingTest() // TODO(scheglov): implement augmentation
  test_mixin_inSuper_getter_withAugmentation_inAugmentation() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  void foo() {}
}

mixin B on A {}

augment mixin B {
  int get foo => 0;
}
''');
  }

  @FailingTest() // TODO(scheglov): implement augmentation
  test_mixin_inSuper_getter_withAugmentation_inDeclaration() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  void foo() {}
}

mixin B {
  int get foo => 0;
}

augment mixin B on A {}
''');
  }
}
