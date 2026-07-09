// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnusedFieldFromPrimaryConstructorTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class UnusedFieldFromPrimaryConstructorTest extends PubPackageResolutionTest {
  test_isUsed_class_declaringFormal_requiredPositional() async {
    await resolveTestCodeWithDiagnostics(r'''
class A(final int _i) {
  int get x => _i;
}
''');
  }

  test_isUsed_class_declaringFormal_requiredPositional_public() async {
    await resolveTestCodeWithDiagnostics(r'''
class A(final int i) {}
''');
  }

  test_isUsed_class_fieldFormal() async {
    await resolveTestCodeWithDiagnostics(r'''
class A(this._f) {
  int _f;
  int get x => _f;
}
''');
  }

  test_isUsed_extensionType_declaringFormal_requiredPositional() async {
    // The representation is not actually used, but we don't report unused
    // extension type representation types.
    await resolveTestCodeWithDiagnostics(r'''
extension type A(final int _i) {}
''');
  }

  test_isUsed_extensionType_declaringFormal_requiredPositional_underscore() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A(final int _) {}
''');
  }

  test_notUsed_class_declaringFormal_optionalNamed() async {
    await resolveTestCodeWithDiagnostics(r'''
class A({final int _i = 0}) {}
//                 ^^
// [diag.unusedFieldFromPrimaryConstructor] The value of the field '_i' isn't used.
''');
  }

  test_notUsed_class_declaringFormal_optionalNamed_functionTyped() async {
    await resolveTestCodeWithDiagnostics(r'''
class A({final void _f() = _g}) {}
//                  ^^
// [diag.unusedFieldFromPrimaryConstructor] The value of the field '_f' isn't used.
void _g() {}
''');
  }

  test_notUsed_class_declaringFormal_requiredPositional() async {
    await resolveTestCodeWithDiagnostics(r'''
class A(final int _i) {}
//                ^^
// [diag.unusedFieldFromPrimaryConstructor] The value of the field '_i' isn't used.
''');
  }

  test_notUsed_class_declaringFormal_requiredPositional_functionTyped() async {
    await resolveTestCodeWithDiagnostics(r'''
class A(final int _f()) {}
//                ^^
// [diag.unusedFieldFromPrimaryConstructor] The value of the field '_f' isn't used.
''');
  }

  test_notUsed_class_declaringFormal_requiredPositional_underscore() async {
    await resolveTestCodeWithDiagnostics(r'''
class A(final int _) {}
//                ^
// [diag.unusedFieldFromPrimaryConstructor] The value of the field '_' isn't used.
''');
  }

  test_notUsed_class_fieldFormal() async {
    await resolveTestCodeWithDiagnostics(r'''
class A(this._f) {
  int _f;
//    ^^
// [diag.unusedField] The value of the field '_f' isn't used.
}
''');
  }
}
