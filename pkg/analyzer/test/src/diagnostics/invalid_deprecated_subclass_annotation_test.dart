// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
    await resolveTestCodeWithDiagnostics(r'''
@Deprecated.subclass()
class C {}
''');
  }

  test_class_final() async {
    await resolveTestCodeWithDiagnostics(r'''
@Deprecated.subclass()
// [diag.invalidDeprecatedSubclassAnnotation][column 2][length 19] The annotation '@Deprecated.subclass' can only be applied to subclassable classes and mixins.
final class C {}
''');
  }

  test_class_private() async {
    await resolveTestCodeWithDiagnostics(r'''
@Deprecated.subclass()
// [diag.invalidDeprecatedSubclassAnnotation][column 2][length 19] The annotation '@Deprecated.subclass' can only be applied to subclassable classes and mixins.
class _C {}
//    ^^
// [diag.unusedElement] The declaration '_C' isn't referenced.
''');
  }

  test_class_sealed() async {
    await resolveTestCodeWithDiagnostics(r'''
@Deprecated.subclass()
// [diag.invalidDeprecatedSubclassAnnotation][column 2][length 19] The annotation '@Deprecated.subclass' can only be applied to subclassable classes and mixins.
sealed class C {}
''');
  }

  test_enum() async {
    await resolveTestCodeWithDiagnostics(r'''
@Deprecated.subclass()
// [diag.invalidDeprecatedSubclassAnnotation][column 2][length 19] The annotation '@Deprecated.subclass' can only be applied to subclassable classes and mixins.
enum E { one; }
''');
  }

  test_mixin() async {
    await resolveTestCodeWithDiagnostics(r'''
@Deprecated.subclass()
mixin M {}
''');
  }

  test_mixin_base() async {
    await resolveTestCodeWithDiagnostics(r'''
@Deprecated.subclass()
// [diag.invalidDeprecatedSubclassAnnotation][column 2][length 19] The annotation '@Deprecated.subclass' can only be applied to subclassable classes and mixins.
base mixin M {}
''');
  }

  test_mixin_private() async {
    await resolveTestCodeWithDiagnostics(r'''
@Deprecated.subclass()
// [diag.invalidDeprecatedSubclassAnnotation][column 2][length 19] The annotation '@Deprecated.subclass' can only be applied to subclassable classes and mixins.
mixin _M {}
//    ^^
// [diag.unusedElement] The declaration '_M' isn't referenced.
''');
  }

  test_typeAlias_ofClass() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {}
@Deprecated.subclass()
typedef D = C;
''');
  }

  test_typeAlias_ofFinalClass() async {
    await resolveTestCodeWithDiagnostics(r'''
final class C {}
@Deprecated.subclass()
// [diag.invalidDeprecatedSubclassAnnotation][column 2][length 19] The annotation '@Deprecated.subclass' can only be applied to subclassable classes and mixins.
typedef D = C;
''');
  }
}
