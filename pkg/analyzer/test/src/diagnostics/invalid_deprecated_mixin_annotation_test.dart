// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidDeprecatedMixinAnnotationTest);
  });
}

@reflectiveTest
class InvalidDeprecatedMixinAnnotationTest extends PubPackageResolutionTest {
  test_class_mixin() async {
    await assertNoErrorsInCode(r'''
@Deprecated.mixin()
mixin class C {}
''');
  }

  test_class_mixin_private() async {
    await assertErrorsInCode(
      r'''
@Deprecated.mixin()
mixin class _C {}
''',
      [
        error(WarningCode.invalidDeprecatedMixinAnnotation, 1, 16),
        error(WarningCode.unusedElement, 32, 2),
      ],
    );
  }

  test_class_noMixin() async {
    await assertErrorsInCode(
      r'''
@Deprecated.mixin()
class C {}
''',
      [error(WarningCode.invalidDeprecatedMixinAnnotation, 1, 16)],
    );
  }

  test_mixin() async {
    await assertErrorsInCode(
      r'''
@Deprecated.mixin()
mixin M {}
''',
      [error(WarningCode.invalidDeprecatedMixinAnnotation, 1, 16)],
    );
  }
}
