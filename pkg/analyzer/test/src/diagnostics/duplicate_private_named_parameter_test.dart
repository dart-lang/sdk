// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DuplicatePrivateNamedParameterTest);
  });
}

@reflectiveTest
class DuplicatePrivateNamedParameterTest extends PubPackageResolutionTest {
  test_initializingFormal_initializingFormal() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  final String? _foo;
//              ^^^^
// [diag.unusedField] The value of the field '_foo' isn't used.
  C({required this._foo, required this._foo}) {}
//                 ^^^^
// [context 1] The first definition of this name.
//                                     ^^^^
// [diag.duplicateFieldFormalParameter][context 1] The field '_foo' can't be initialized by multiple parameters in the same constructor.
}
''');
  }

  test_initializingFormal_privateNamed() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  final String? _foo;
//              ^^^^
// [diag.unusedField] The value of the field '_foo' isn't used.
  C({required this._foo, String? _foo}) {}
//                 ^^^^
// [context 1] The first definition of this name.
//                               ^^^^
// [diag.duplicateDefinition][context 1] The name '_foo' is already defined.
// [diag.privateNamedNonFieldParameter] Named parameters that don't refer to instance variables can't start with underscore.
}
''');
  }

  test_initializingFormal_publicNamed() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  final String? _foo;
//              ^^^^
// [diag.unusedField] The value of the field '_foo' isn't used.
  C({required this._foo, String? foo}) {}
//                 ^^^^
// [diag.privateNamedParameterDuplicatePublicName][context 1] The corresponding public name 'foo' is already the name of another parameter.
//                               ^^^
// [context 1] The first definition of this name.
}
''');
  }

  test_privateNamed_initializingFormal() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  final String? _foo;
//              ^^^^
// [diag.unusedField] The value of the field '_foo' isn't used.
  C({String? _foo, required this._foo}) {}
//           ^^^^
// [context 1] The first definition of this name.
// [diag.privateNamedNonFieldParameter] Named parameters that don't refer to instance variables can't start with underscore.
//                               ^^^^
// [diag.duplicateDefinition][context 1] The name '_foo' is already defined.
}
''');
  }

  test_privatePositional_initializingFormal() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  final String? _foo;
//              ^^^^
// [diag.unusedField] The value of the field '_foo' isn't used.
  C(String _foo, {required this._foo}) {}
//         ^^^^
// [context 1] The first definition of this name.
//                              ^^^^
// [diag.duplicateDefinition][context 1] The name '_foo' is already defined.
}
''');
  }

  test_publicInitializingFormal_privateInitializingFormal() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  final String? foo;
  final String? _foo;
//              ^^^^
// [diag.unusedField] The value of the field '_foo' isn't used.
  C({required this.foo, required this._foo}) {}
//                 ^^^
// [context 1] The first definition of this name.
//                                    ^^^^
// [diag.privateNamedParameterDuplicatePublicName][context 1] The corresponding public name 'foo' is already the name of another parameter.
}
''');
  }

  test_publicNamed_initializingFormal() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  final String? _foo;
//              ^^^^
// [diag.unusedField] The value of the field '_foo' isn't used.
  C({String? foo, required this._foo}) {}
//           ^^^
// [context 1] The first definition of this name.
//                              ^^^^
// [diag.privateNamedParameterDuplicatePublicName][context 1] The corresponding public name 'foo' is already the name of another parameter.
}
''');
  }

  test_publicPositional_initializingFormal() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  final String? _foo;
//              ^^^^
// [diag.unusedField] The value of the field '_foo' isn't used.
  C(String? foo, {required this._foo}) {}
//          ^^^
// [context 1] The first definition of this name.
//                              ^^^^
// [diag.privateNamedParameterDuplicatePublicName][context 1] The corresponding public name 'foo' is already the name of another parameter.
}
''');
  }
}
