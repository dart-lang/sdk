// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidDeprecatedInstantiateAnnotationTest);
  });
}

@reflectiveTest
class InvalidDeprecatedInstantiateAnnotationTest
    extends PubPackageResolutionTest {
  test_class() async {
    await resolveTestCodeWithDiagnostics(r'''
@Deprecated.instantiate()
class C {}
''');
  }

  test_class_abstract() async {
    await resolveTestCodeWithDiagnostics(r'''
@Deprecated.instantiate()
// [diag.invalidDeprecatedInstantiateAnnotation][column 2][length 22] The annotation '@Deprecated.instantiate' can only be applied to classes.
abstract class C {}
''');
  }

  test_class_private() async {
    await resolveTestCodeWithDiagnostics(r'''
@Deprecated.instantiate()
// [diag.invalidDeprecatedInstantiateAnnotation][column 2][length 22] The annotation '@Deprecated.instantiate' can only be applied to classes.
class _C {}
//    ^^
// [diag.unusedElement] The declaration '_C' isn't referenced.
''');
  }

  test_class_privateConstructor() async {
    await resolveTestCodeWithDiagnostics(r'''
@Deprecated.instantiate()
// [diag.invalidDeprecatedInstantiateAnnotation][column 2][length 22] The annotation '@Deprecated.instantiate' can only be applied to classes.
sealed class C {
  C._();
}
''');
  }

  test_class_sealed() async {
    await resolveTestCodeWithDiagnostics(r'''
@Deprecated.instantiate()
// [diag.invalidDeprecatedInstantiateAnnotation][column 2][length 22] The annotation '@Deprecated.instantiate' can only be applied to classes.
sealed class C {}
''');
  }

  test_classTypeAlias() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {}
@Deprecated.instantiate()
class C = Object with M;
''');
  }

  test_enum() async {
    await resolveTestCodeWithDiagnostics(r'''
@Deprecated.instantiate()
// [diag.invalidDeprecatedInstantiateAnnotation][column 2][length 22] The annotation '@Deprecated.instantiate' can only be applied to classes.
enum E { one; }
''');
  }

  test_function() async {
    await resolveTestCodeWithDiagnostics(r'''
@Deprecated.instantiate()
// [diag.invalidDeprecatedInstantiateAnnotation][column 2][length 22] The annotation '@Deprecated.instantiate' can only be applied to classes.
void f() {}
''');
  }

  test_typeAlias_forClass() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {}
@Deprecated.instantiate()
typedef D = C;
''');
  }

  test_typeAlias_forEnum() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E { one; }
@Deprecated.instantiate()
// [diag.invalidDeprecatedInstantiateAnnotation][column 2][length 22] The annotation '@Deprecated.instantiate' can only be applied to classes.
typedef F = E;
''');
  }
}
