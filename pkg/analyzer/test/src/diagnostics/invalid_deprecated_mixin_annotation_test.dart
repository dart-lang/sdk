// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
    await resolveTestCodeWithDiagnostics(r'''
@Deprecated.mixin()
mixin class C {}
''');
  }

  test_class_mixin_private() async {
    await resolveTestCodeWithDiagnostics(r'''
@Deprecated.mixin()
// [diag.invalidDeprecatedMixinAnnotation][column 2][length 16] The annotation '@Deprecated.mixin' can only be applied to classes.
mixin class _C {}
//          ^^
// [diag.unusedElement] The declaration '_C' isn't referenced.
''');
  }

  test_class_noMixin() async {
    await resolveTestCodeWithDiagnostics(r'''
@Deprecated.mixin()
// [diag.invalidDeprecatedMixinAnnotation][column 2][length 16] The annotation '@Deprecated.mixin' can only be applied to classes.
class C {}
''');
  }

  test_mixin() async {
    await resolveTestCodeWithDiagnostics(r'''
@Deprecated.mixin()
// [diag.invalidDeprecatedMixinAnnotation][column 2][length 16] The annotation '@Deprecated.mixin' can only be applied to classes.
mixin M {}
''');
  }
}
