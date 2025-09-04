// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidDeprecatedExtendAnnotationTest);
  });
}

@reflectiveTest
class InvalidDeprecatedExtendAnnotationTest extends PubPackageResolutionTest {
  test_class() async {
    await assertNoErrorsInCode(r'''
@Deprecated.extend()
class C {}
''');
  }

  test_class_final() async {
    await assertErrorsInCode(
      r'''
@Deprecated.extend()
final class C {}
''',
      [error(WarningCode.invalidDeprecatedExtendAnnotation, 1, 17)],
    );
  }

  test_class_interface() async {
    await assertErrorsInCode(
      r'''
@Deprecated.extend()
interface class C {}
''',
      [error(WarningCode.invalidDeprecatedExtendAnnotation, 1, 17)],
    );
  }

  test_class_noPublicGenerativeConstructor() async {
    await assertErrorsInCode(
      r'''
@Deprecated.extend()
class C {
  C._();
}
''',
      [error(WarningCode.invalidDeprecatedExtendAnnotation, 1, 17)],
    );
  }

  test_class_private() async {
    await assertErrorsInCode(
      r'''
@Deprecated.extend()
class _C {}
''',
      [
        error(WarningCode.invalidDeprecatedExtendAnnotation, 1, 17),
        error(WarningCode.unusedElement, 27, 2),
      ],
    );
  }

  test_class_sealed() async {
    await assertErrorsInCode(
      r'''
@Deprecated.extend()
sealed class C {}
''',
      [error(WarningCode.invalidDeprecatedExtendAnnotation, 1, 17)],
    );
  }

  test_classTypeAlias() async {
    await assertNoErrorsInCode(r'''
mixin M {}
@Deprecated.extend()
class C = Object with M;
''');
  }

  test_mixin() async {
    await assertErrorsInCode(
      r'''
@Deprecated.extend()
mixin M {}
''',
      [error(WarningCode.invalidDeprecatedExtendAnnotation, 1, 17)],
    );
  }

  test_typeAlias_forClass() async {
    await assertNoErrorsInCode(r'''
class C {}
@Deprecated.extend()
typedef D = C;
''');
  }

  test_typeAlias_forEnum() async {
    await assertErrorsInCode(
      r'''
enum E { one; }
@Deprecated.extend()
typedef F = E;
''',
      [error(WarningCode.invalidDeprecatedExtendAnnotation, 17, 17)],
    );
  }
}
