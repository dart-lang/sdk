// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidDeprecatedImplementAnnotationTest);
  });
}

@reflectiveTest
class InvalidDeprecatedImplementAnnotationTest
    extends PubPackageResolutionTest {
  test_class() async {
    await assertNoErrorsInCode(r'''
@Deprecated.implement()
class C {}
''');
  }

  test_class_base() async {
    await assertErrorsInCode(
      r'''
@Deprecated.implement()
base class C {}
''',
      [error(WarningCode.invalidDeprecatedImplementAnnotation, 1, 20)],
    );
  }

  test_class_final() async {
    await assertErrorsInCode(
      r'''
@Deprecated.implement()
final class C {}
''',
      [error(WarningCode.invalidDeprecatedImplementAnnotation, 1, 20)],
    );
  }

  test_class_private() async {
    await assertErrorsInCode(
      r'''
@Deprecated.implement()
class _C {}
''',
      [
        error(WarningCode.invalidDeprecatedImplementAnnotation, 1, 20),
        error(WarningCode.unusedElement, 30, 2),
      ],
    );
  }

  test_class_sealed() async {
    await assertErrorsInCode(
      r'''
@Deprecated.implement()
sealed class C {}
''',
      [error(WarningCode.invalidDeprecatedImplementAnnotation, 1, 20)],
    );
  }

  test_classTypeAlias() async {
    await assertNoErrorsInCode(r'''
mixin M {}
@Deprecated.implement()
class C = Object with M;
''');
  }

  test_function() async {
    await assertErrorsInCode(
      r'''
@Deprecated.implement()
void f() {}
''',
      [error(WarningCode.invalidDeprecatedImplementAnnotation, 1, 20)],
    );
  }

  test_mixin() async {
    await assertNoErrorsInCode(r'''
@Deprecated.implement()
mixin M {}
''');
  }

  test_mixin_base() async {
    await assertErrorsInCode(
      r'''
@Deprecated.implement()
base mixin M {}
''',
      [error(WarningCode.invalidDeprecatedImplementAnnotation, 1, 20)],
    );
  }

  test_mixin_private() async {
    await assertErrorsInCode(
      r'''
@Deprecated.implement()
mixin _M {}
''',
      [
        error(WarningCode.invalidDeprecatedImplementAnnotation, 1, 20),
        error(WarningCode.unusedElement, 30, 2),
      ],
    );
  }

  test_typeAlias_forClass() async {
    await assertNoErrorsInCode(r'''
class C {}
@Deprecated.implement()
typedef D = C;
''');
  }

  test_typeAlias_forEnum() async {
    await assertErrorsInCode(
      r'''
enum E { one; }
@Deprecated.implement()
typedef F = E;
''',
      [error(WarningCode.invalidDeprecatedImplementAnnotation, 17, 20)],
    );
  }
}
