// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
    await resolveTestCodeWithDiagnostics(r'''
@Deprecated.extend()
class C {}
''');
  }

  test_class_final() async {
    await resolveTestCodeWithDiagnostics(r'''
@Deprecated.extend()
// [diag.invalidDeprecatedExtendAnnotation][column 2][length 17] The annotation '@Deprecated.extend' can only be applied to extendable classes.
final class C {}
''');
  }

  test_class_interface() async {
    await resolveTestCodeWithDiagnostics(r'''
@Deprecated.extend()
// [diag.invalidDeprecatedExtendAnnotation][column 2][length 17] The annotation '@Deprecated.extend' can only be applied to extendable classes.
interface class C {}
''');
  }

  test_class_noPublicGenerativeConstructor() async {
    await resolveTestCodeWithDiagnostics(r'''
@Deprecated.extend()
// [diag.invalidDeprecatedExtendAnnotation][column 2][length 17] The annotation '@Deprecated.extend' can only be applied to extendable classes.
class C {
  C._();
}
''');
  }

  test_class_private() async {
    await resolveTestCodeWithDiagnostics(r'''
@Deprecated.extend()
// [diag.invalidDeprecatedExtendAnnotation][column 2][length 17] The annotation '@Deprecated.extend' can only be applied to extendable classes.
class _C {}
//    ^^
// [diag.unusedElement] The declaration '_C' isn't referenced.
''');
  }

  test_class_sealed() async {
    await resolveTestCodeWithDiagnostics(r'''
@Deprecated.extend()
// [diag.invalidDeprecatedExtendAnnotation][column 2][length 17] The annotation '@Deprecated.extend' can only be applied to extendable classes.
sealed class C {}
''');
  }

  test_classTypeAlias() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {}
@Deprecated.extend()
class C = Object with M;
''');
  }

  test_mixin() async {
    await resolveTestCodeWithDiagnostics(r'''
@Deprecated.extend()
// [diag.invalidDeprecatedExtendAnnotation][column 2][length 17] The annotation '@Deprecated.extend' can only be applied to extendable classes.
mixin M {}
''');
  }

  test_typeAlias_forClass() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {}
@Deprecated.extend()
typedef D = C;
''');
  }

  test_typeAlias_forEnum() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E { one; }
@Deprecated.extend()
// [diag.invalidDeprecatedExtendAnnotation][column 2][length 17] The annotation '@Deprecated.extend' can only be applied to extendable classes.
typedef F = E;
''');
  }
}
