// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnusedFieldFromPrimaryConstructorTest);
  });
}

@reflectiveTest
class UnusedFieldFromPrimaryConstructorTest extends PubPackageResolutionTest {
  test_isUsed_class_declaringFormal_requiredPositional() async {
    await assertNoErrorsInCode(r'''
class A(final int _i) {
  int get x => _i;
}
''');
  }

  test_isUsed_class_declaringFormal_requiredPositional_public() async {
    await assertNoErrorsInCode(r'''
class A(final int i) {}
''');
  }

  test_isUsed_class_fieldFormal() async {
    await assertNoErrorsInCode(r'''
class A(this._f) {
  int _f;
  int get x => _f;
}
''');
  }

  test_isUsed_extensionType_declaringFormal_requiredPositional() async {
    // The representation is not actually used, but we don't report unused
    // extension type representation types.
    await assertNoErrorsInCode(r'''
extension type A(final int _i) {}
''');
  }

  test_isUsed_extensionType_declaringFormal_requiredPositional_underscore() async {
    await assertNoErrorsInCode(r'''
extension type A(final int _) {}
''');
  }

  test_notUsed_class_declaringFormal_optionalNamed() async {
    await assertErrorsInCode(
      r'''
class A({final int _i = 0}) {}
''',
      [error(diag.unusedFieldFromPrimaryConstructor, 19, 2)],
    );
  }

  test_notUsed_class_declaringFormal_optionalNamed_functionTyped() async {
    await assertErrorsInCode(
      r'''
class A({final void _f() = _g}) {}
void _g() {}
''',
      [error(diag.unusedFieldFromPrimaryConstructor, 20, 2)],
    );
  }

  test_notUsed_class_declaringFormal_requiredPositional() async {
    await assertErrorsInCode(
      r'''
class A(final int _i) {}
''',
      [error(diag.unusedFieldFromPrimaryConstructor, 18, 2)],
    );
  }

  test_notUsed_class_declaringFormal_requiredPositional_functionTyped() async {
    await assertErrorsInCode(
      r'''
class A(final int _f()) {}
''',
      [error(diag.unusedFieldFromPrimaryConstructor, 18, 2)],
    );
  }

  test_notUsed_class_declaringFormal_requiredPositional_underscore() async {
    await assertErrorsInCode(
      r'''
class A(final int _) {}
''',
      [error(diag.unusedFieldFromPrimaryConstructor, 18, 1)],
    );
  }

  test_notUsed_class_fieldFormal() async {
    await assertErrorsInCode(
      r'''
class A(this._f) {
  int _f;
}
''',
      [error(diag.unusedField, 25, 2)],
    );
  }
}
