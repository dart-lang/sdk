// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
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
    await assertNoErrorsInCode(r'''
@Deprecated.instantiate()
class C {}
''');
  }

  test_class_abstract() async {
    await assertErrorsInCode(
      r'''
@Deprecated.instantiate()
abstract class C {}
''',
      [error(WarningCode.invalidDeprecatedInstantiateAnnotation, 1, 22)],
    );
  }

  test_class_private() async {
    await assertErrorsInCode(
      r'''
@Deprecated.instantiate()
class _C {}
''',
      [
        error(WarningCode.invalidDeprecatedInstantiateAnnotation, 1, 22),
        error(WarningCode.unusedElement, 32, 2),
      ],
    );
  }

  test_class_privateConstructor() async {
    await assertErrorsInCode(
      r'''
@Deprecated.instantiate()
sealed class C {
  C._();
}
''',
      [error(WarningCode.invalidDeprecatedInstantiateAnnotation, 1, 22)],
    );
  }

  test_class_sealed() async {
    await assertErrorsInCode(
      r'''
@Deprecated.instantiate()
sealed class C {}
''',
      [error(WarningCode.invalidDeprecatedInstantiateAnnotation, 1, 22)],
    );
  }

  test_classTypeAlias() async {
    await assertNoErrorsInCode(r'''
mixin M {}
@Deprecated.instantiate()
class C = Object with M;
''');
  }

  test_enum() async {
    await assertErrorsInCode(
      r'''
@Deprecated.instantiate()
enum E { one; }
''',
      [error(WarningCode.invalidDeprecatedInstantiateAnnotation, 1, 22)],
    );
  }

  test_function() async {
    await assertErrorsInCode(
      r'''
@Deprecated.instantiate()
void f() {}
''',
      [error(WarningCode.invalidDeprecatedInstantiateAnnotation, 1, 22)],
    );
  }

  test_typeAlias_forClass() async {
    await assertNoErrorsInCode(r'''
class C {}
@Deprecated.instantiate()
typedef D = C;
''');
  }

  test_typeAlias_forEnum() async {
    await assertErrorsInCode(
      r'''
enum E { one; }
@Deprecated.instantiate()
typedef F = E;
''',
      [error(WarningCode.invalidDeprecatedInstantiateAnnotation, 17, 22)],
    );
  }
}
