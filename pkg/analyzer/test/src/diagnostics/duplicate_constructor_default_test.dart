// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DuplicateConstructorDefaultTest);
  });
}

@reflectiveTest
class DuplicateConstructorDefaultTest extends PubPackageResolutionTest {
  @SkippedTest() // TODO(scheglov): implement augmentation
  test_class_augmentation_augments() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A();
}

augment class A {
  augment A();
}
''');
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_class_augmentation_declares() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A();
}

augment class A {
  A();
//^
// [diag.duplicateConstructorDefault] The unnamed constructor is already defined.
}
''');
  }

  test_class_primary_unnamed_typeName_new() async {
    await resolveTestCodeWithDiagnostics(r'''
class C() {
  C.new() : this();
//^^^^^
// [diag.duplicateConstructorDefault] The unnamed constructor is already defined.
}
''');
  }

  test_class_typeName_new_typeName_new() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  C.new();
  C.new();
//^^^^^
// [diag.duplicateConstructorDefault] The unnamed constructor is already defined.
}
''');
  }

  test_class_typeName_new_typeName_unnamed() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  C.new();
  C();
//^
// [diag.duplicateConstructorDefault] The unnamed constructor is already defined.
}
''');
  }

  test_class_typeName_unnamed_factoryHead_unnamed() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  factory C() => throw 0;
  factory () => throw 0;
//^^^^^^^
// [diag.duplicateConstructorDefault] The unnamed constructor is already defined.
}
''');
  }

  test_class_typeName_unnamed_newHead_unnamed() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  C();
  new ();
//^^^
// [diag.duplicateConstructorDefault] The unnamed constructor is already defined.
}
''');
  }

  test_class_typeName_unnamed_typeName_new() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  C();
  C.new();
//^^^^^
// [diag.duplicateConstructorDefault] The unnamed constructor is already defined.
}
''');
  }

  test_class_typeName_unnamed_typeName_unnamed() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  C();
  C();
//^
// [diag.duplicateConstructorDefault] The unnamed constructor is already defined.
}
''');
  }

  test_class_wrongTypeName_unnamed_typeName_unnamed() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  factory B.new() => throw 0;
//        ^
// [diag.invalidFactoryNameNotAClass] The name of a factory constructor must be the same as the name of the immediately enclosing class.
  A();
}
''');
  }

  test_enum_newHead_unnamed_newHead_unnamed() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  const new ();
  const new ();
//      ^^^
// [diag.duplicateConstructorDefault] The unnamed constructor is already defined.
}
''');
  }

  test_enum_primary_unnamed_typeName_new() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E() {
  v;
  factory E.new() => v;
//        ^^^^^
// [diag.duplicateConstructorDefault] The unnamed constructor is already defined.
}
''');
  }

  test_enum_typeName_new_typeName_new() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  const E.new();
  const E.new();
//      ^^^^^
// [diag.duplicateConstructorDefault] The unnamed constructor is already defined.
//        ^^^
// [diag.unusedElement] The declaration 'E' isn't referenced.
}
''');
  }

  test_enum_typeName_new_typeName_unnamed() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  const E.new();
  const E();
//      ^
// [diag.duplicateConstructorDefault] The unnamed constructor is already defined.
}
''');
  }

  test_enum_typeName_unnamed_factoryHead_unnamed() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  const E();
  factory () => v;
//^^^^^^^
// [diag.duplicateConstructorDefault] The unnamed constructor is already defined.
}
''');
  }

  test_enum_typeName_unnamed_newHead_unnamed() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  const E();
  const new ();
//      ^^^
// [diag.duplicateConstructorDefault] The unnamed constructor is already defined.
}
''');
  }

  test_enum_typeName_unnamed_typeName_new() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  const E();
  const E.new();
//      ^^^^^
// [diag.duplicateConstructorDefault] The unnamed constructor is already defined.
//        ^^^
// [diag.unusedElement] The declaration 'E' isn't referenced.
}
''');
  }

  test_enum_typeName_unnamed_typeName_unnamed() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  const E();
  const E();
//      ^
// [diag.duplicateConstructorDefault] The unnamed constructor is already defined.
}
''');
  }

  test_extensionType_primary_new_secondary_typeName_new() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A.new(int it) {
  A.new(this.it);
//^^^^^
// [diag.duplicateConstructorDefault] The unnamed constructor is already defined.
}
''');
  }

  test_extensionType_primary_new_secondary_typeName_unnamed() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A.new(int it) {
  A(this.it);
//^
// [diag.duplicateConstructorDefault] The unnamed constructor is already defined.
}
''');
  }

  test_extensionType_primary_unnamed_secondary_newHead_unnamed() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A(int it) {
  new(this.it);
//^^^
// [diag.duplicateConstructorDefault] The unnamed constructor is already defined.
}
''');
  }

  test_extensionType_primary_unnamed_secondary_typeName_new() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A(int it) {
  A.new(this.it);
//^^^^^
// [diag.duplicateConstructorDefault] The unnamed constructor is already defined.
}
''');
  }

  test_extensionType_primary_unnamed_secondary_typeName_unnamed() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A(int it) {
  A(this.it);
//^
// [diag.duplicateConstructorDefault] The unnamed constructor is already defined.
}
''');
  }

  test_extensionType_secondary_factoryHead_unnamed_factoryHead_unnamed() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A.named(int it) {
  factory (int it) => A.named(it);
  factory (int it) => A.named(it);
//^^^^^^^
// [diag.duplicateConstructorDefault] The unnamed constructor is already defined.
}
''');
  }

  test_extensionType_secondary_newHead_unnamed_newHead_unnamed() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A.named(int it) {
  new(this.it);
  new(this.it);
//^^^
// [diag.duplicateConstructorDefault] The unnamed constructor is already defined.
}
''');
  }
}
