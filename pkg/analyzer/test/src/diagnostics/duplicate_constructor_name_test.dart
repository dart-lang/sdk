// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
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
    newFile(testFile.path, r'''
part 'a.dart';

class A {
  A.named();
}
''');

    var a = newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';

augment class A {
  augment A.named();
}
''');

    await resolveFile2(testFile);
    assertNoErrorsInResult();

    await resolveFile2(a);
    assertNoErrorsInResult();
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_class_augmentation_augments2() async {
    newFile(testFile.path, r'''
part 'a.dart';

class A {
  A.named();
}
''');

    var a = newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';

augment class A {
  augment A.named();
  augment A.named();
}
''');

    await resolveFile2(testFile);
    assertNoErrorsInResult();

    await resolveFile2(a);
    assertNoErrorsInResult();
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_class_augmentation_declares() async {
    newFile(testFile.path, r'''
part 'a.dart';

class A {
  A.named();
}
''');

    var a = newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';

augment class A {
  A.named();
}
''');

    await resolveFile2(testFile);
    assertNoErrorsInResult();

    await resolveFile2(a);
    assertErrorsInResult([error(diag.duplicateConstructorName, 42, 7)]);
  }

  test_class_newHead_named_newHead_named() async {
    await assertErrorsInCode(
      r'''
class C {
  new foo();
  new foo();
}
''',
      [error(diag.duplicateConstructorName, 25, 7)],
    );
  }

  test_class_typeName_named_factoryHead_named() async {
    await assertErrorsInCode(
      r'''
class C {
  factory C.foo() => throw 0;
  factory foo() => throw 0;
}
''',
      [error(diag.duplicateConstructorName, 42, 11)],
    );
  }

  test_class_typeName_named_newHead_named() async {
    await assertErrorsInCode(
      r'''
class C {
  C.foo();
  new foo();
}
''',
      [error(diag.duplicateConstructorName, 23, 7)],
    );
  }

  test_class_typeName_named_typeName_named() async {
    await assertErrorsInCode(
      r'''
class C {
  C.foo();
  C.foo();
}
''',
      [error(diag.duplicateConstructorName, 23, 5)],
    );
  }

  test_class_wrongTypeName_named_typeName_named() async {
    await assertErrorsInCode(
      r'''
class A {
  factory B.foo() => throw 0;
  A.foo();
}
''',
      [error(diag.invalidFactoryNameNotAClass, 20, 1)],
    );
  }

  test_enum_typeName_named_typeName_named() async {
    await assertErrorsInCode(
      r'''
enum E {
  v.foo();
  const E.foo();
  const E.foo();
}
''',
      [
        error(diag.duplicateConstructorName, 45, 5),
        error(diag.unusedElement, 47, 3),
      ],
    );
  }

  test_extensionType_primary_typeName_named_secondary_typeName_named() async {
    await assertErrorsInCode(
      r'''
extension type A.foo(int it) {
  A.foo(this.it);
}
''',
      [error(diag.duplicateConstructorName, 33, 5)],
    );
  }

  test_extensionType_secondary_typeName_named_factoryHead_named() async {
    await assertErrorsInCode(
      r'''
extension type A(int it) {
  factory A.foo(int it) => A(it);
  factory foo(int it) => A(it);
}
''',
      [error(diag.duplicateConstructorName, 63, 11)],
    );
  }

  test_extensionType_secondary_typeName_named_newHead_named() async {
    await assertErrorsInCode(
      r'''
extension type A(int it) {
  A.foo(this.it);
  new foo(this.it);
}
''',
      [error(diag.duplicateConstructorName, 47, 7)],
    );
  }

  test_extensionType_secondary_typeName_named_secondary_typeName_named() async {
    await assertErrorsInCode(
      r'''
extension type A(int it) {
  A.foo(this.it);
  A.foo(this.it);
}
''',
      [error(diag.duplicateConstructorName, 47, 5)],
    );
  }
}
