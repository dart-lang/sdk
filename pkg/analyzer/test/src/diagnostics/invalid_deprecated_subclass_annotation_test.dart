// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidDeprecatedSubclassAnnotationTest);
  });
}

@reflectiveTest
class InvalidDeprecatedSubclassAnnotationTest extends PubPackageResolutionTest {
  test_class() async {
    await assertNoErrorsInCode(r'''
@Deprecated.subclass()
class C {}
''');
  }

  test_class_final() async {
    await assertErrorsInCode(
      r'''
@Deprecated.subclass()
final class C {}
''',
      [error(WarningCode.invalidDeprecatedSubclassAnnotation, 1, 19)],
    );
  }

  test_class_private() async {
    await assertErrorsInCode(
      r'''
@Deprecated.subclass()
class _C {}
''',
      [
        error(WarningCode.invalidDeprecatedSubclassAnnotation, 1, 19),
        error(WarningCode.unusedElement, 29, 2),
      ],
    );
  }

  test_class_sealed() async {
    await assertErrorsInCode(
      r'''
@Deprecated.subclass()
sealed class C {}
''',
      [error(WarningCode.invalidDeprecatedSubclassAnnotation, 1, 19)],
    );
  }

  test_enum() async {
    await assertErrorsInCode(
      r'''
@Deprecated.subclass()
enum E { one; }
''',
      [error(WarningCode.invalidDeprecatedSubclassAnnotation, 1, 19)],
    );
  }

  test_mixin() async {
    await assertNoErrorsInCode(r'''
@Deprecated.subclass()
mixin M {}
''');
  }

  test_mixin_base() async {
    await assertErrorsInCode(
      r'''
@Deprecated.subclass()
base mixin M {}
''',
      [error(WarningCode.invalidDeprecatedSubclassAnnotation, 1, 19)],
    );
  }

  test_mixin_private() async {
    await assertErrorsInCode(
      r'''
@Deprecated.subclass()
mixin _M {}
''',
      [
        error(WarningCode.invalidDeprecatedSubclassAnnotation, 1, 19),
        error(WarningCode.unusedElement, 29, 2),
      ],
    );
  }

  test_typeAlias_ofClass() async {
    await assertNoErrorsInCode(r'''
class C {}
@Deprecated.subclass()
typedef D = C;
''');
  }

  test_typeAlias_ofFinalClass() async {
    await assertErrorsInCode(
      r'''
final class C {}
@Deprecated.subclass()
typedef D = C;
''',
      [error(WarningCode.invalidDeprecatedSubclassAnnotation, 18, 19)],
    );
  }
}
