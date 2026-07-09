// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
    await resolveTestCodeWithDiagnostics(r'''
@Deprecated.implement()
class C {}
''');
  }

  test_class_base() async {
    await resolveTestCodeWithDiagnostics(r'''
@Deprecated.implement()
// [diag.invalidDeprecatedImplementAnnotation][column 2][length 20] The annotation '@Deprecated.implement' can only be applied to implementable classes.
base class C {}
''');
  }

  test_class_final() async {
    await resolveTestCodeWithDiagnostics(r'''
@Deprecated.implement()
// [diag.invalidDeprecatedImplementAnnotation][column 2][length 20] The annotation '@Deprecated.implement' can only be applied to implementable classes.
final class C {}
''');
  }

  test_class_private() async {
    await resolveTestCodeWithDiagnostics(r'''
@Deprecated.implement()
// [diag.invalidDeprecatedImplementAnnotation][column 2][length 20] The annotation '@Deprecated.implement' can only be applied to implementable classes.
class _C {}
//    ^^
// [diag.unusedElement] The declaration '_C' isn't referenced.
''');
  }

  test_class_sealed() async {
    await resolveTestCodeWithDiagnostics(r'''
@Deprecated.implement()
// [diag.invalidDeprecatedImplementAnnotation][column 2][length 20] The annotation '@Deprecated.implement' can only be applied to implementable classes.
sealed class C {}
''');
  }

  test_classTypeAlias() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {}
@Deprecated.implement()
class C = Object with M;
''');
  }

  test_function() async {
    await resolveTestCodeWithDiagnostics(r'''
@Deprecated.implement()
// [diag.invalidDeprecatedImplementAnnotation][column 2][length 20] The annotation '@Deprecated.implement' can only be applied to implementable classes.
void f() {}
''');
  }

  test_mixin() async {
    await resolveTestCodeWithDiagnostics(r'''
@Deprecated.implement()
mixin M {}
''');
  }

  test_mixin_base() async {
    await resolveTestCodeWithDiagnostics(r'''
@Deprecated.implement()
// [diag.invalidDeprecatedImplementAnnotation][column 2][length 20] The annotation '@Deprecated.implement' can only be applied to implementable classes.
base mixin M {}
''');
  }

  test_mixin_private() async {
    await resolveTestCodeWithDiagnostics(r'''
@Deprecated.implement()
// [diag.invalidDeprecatedImplementAnnotation][column 2][length 20] The annotation '@Deprecated.implement' can only be applied to implementable classes.
mixin _M {}
//    ^^
// [diag.unusedElement] The declaration '_M' isn't referenced.
''');
  }

  test_typeAlias_forClass() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {}
@Deprecated.implement()
typedef D = C;
''');
  }

  test_typeAlias_forEnum() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E { one; }
@Deprecated.implement()
// [diag.invalidDeprecatedImplementAnnotation][column 2][length 20] The annotation '@Deprecated.implement' can only be applied to implementable classes.
typedef F = E;
''');
  }
}
