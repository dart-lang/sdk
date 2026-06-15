// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DuplicateConstructorNameTest);
  });
}

@reflectiveTest
class DuplicateConstructorNameTest extends PubPackageResolutionTest {
  @SkippedTest() // TODO(scheglov): implement augmentation
  test_class_augmentation_augments() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A.named();
}

augment class A {
  augment A.named();
}
''');
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_class_augmentation_augments2() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A.named();
}

augment class A {
  augment A.named();
  augment A.named();
}
''');
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_class_augmentation_declares() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A.named();
}

augment class A {
  A.named();
//  ^^^^^
// [diag.duplicateConstructorName] The constructor with name 'named' is already defined.
}
''');
  }

  test_class_newHead_named_newHead_named() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  new foo();
  new foo();
//^^^^^^^
// [diag.duplicateConstructorName] The constructor with name 'foo' is already defined.
}
''');
  }

  test_class_primary_named_typeName_named() async {
    await resolveTestCodeWithDiagnostics(r'''
class C.foo() {
  C.foo() : this.foo();
//^^^^^
// [diag.duplicateConstructorName] The constructor with name 'foo' is already defined.
}
''');
  }

  test_class_typeName_named_factoryHead_named() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  factory C.foo() => throw 0;
  factory foo() => throw 0;
//^^^^^^^^^^^
// [diag.duplicateConstructorName] The constructor with name 'foo' is already defined.
}
''');
  }

  test_class_typeName_named_newHead_named() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  C.foo();
  new foo();
//^^^^^^^
// [diag.duplicateConstructorName] The constructor with name 'foo' is already defined.
}
''');
  }

  test_class_typeName_named_typeName_named() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  C.foo();
  C.foo();
//^^^^^
// [diag.duplicateConstructorName] The constructor with name 'foo' is already defined.
}
''');
  }

  test_class_wrongTypeName_named_typeName_named() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  factory B.foo() => throw 0;
//        ^
// [diag.invalidFactoryNameNotAClass] The name of a factory constructor must be the same as the name of the immediately enclosing class.
  A.foo();
}
''');
  }

  test_enum_primary_named_typeName_named() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E.foo() {
  v.foo();
  factory E.foo() => v;
//        ^^^^^
// [diag.duplicateConstructorName] The constructor with name 'foo' is already defined.
}
''');
  }

  test_enum_typeName_named_typeName_named() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v.foo();
  const E.foo();
  const E.foo();
//      ^^^^^
// [diag.duplicateConstructorName] The constructor with name 'foo' is already defined.
//        ^^^
// [diag.unusedElement] The declaration 'E.foo' isn't referenced.
}
''');
  }

  test_extensionType_primary_typeName_named_secondary_typeName_named() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A.foo(int it) {
  A.foo(this.it);
//^^^^^
// [diag.duplicateConstructorName] The constructor with name 'foo' is already defined.
}
''');
  }

  test_extensionType_secondary_typeName_named_factoryHead_named() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A(int it) {
  factory A.foo(int it) => A(it);
  factory foo(int it) => A(it);
//^^^^^^^^^^^
// [diag.duplicateConstructorName] The constructor with name 'foo' is already defined.
}
''');
  }

  test_extensionType_secondary_typeName_named_newHead_named() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A(int it) {
  A.foo(this.it);
  new foo(this.it);
//^^^^^^^
// [diag.duplicateConstructorName] The constructor with name 'foo' is already defined.
}
''');
  }

  test_extensionType_secondary_typeName_named_secondary_typeName_named() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A(int it) {
  A.foo(this.it);
  A.foo(this.it);
//^^^^^
// [diag.duplicateConstructorName] The constructor with name 'foo' is already defined.
}
''');
  }
}
