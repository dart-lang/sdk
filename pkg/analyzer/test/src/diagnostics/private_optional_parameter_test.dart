// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PrivateOptionalParameterTest);
  });
}

@reflectiveTest
class PrivateOptionalParameterTest extends PubPackageResolutionTest {
  test_class_constructorDeclaration_fieldFormal() async {
    await assertErrorsInCode(
      r'''
class A {
  int? _p;
  A({this._p = 0});
}
''',
      [error(diag.unusedField, 17, 2)],
    );
  }

  test_class_constructorDeclaration_nonFieldParameter() async {
    await assertErrorsInCode(
      '''
class C {
  C({int? _notField});
}
''',
      [error(diag.privateNamedNonFieldParameter, 20, 9)],
    );
  }

  test_class_constructorDeclaration_noPublicName_nonIdentifier() async {
    await assertErrorsInCode(
      '''
class C {
  int? _123;
  C({this._123}) {}
}
''',
      [
        error(diag.unusedField, 17, 4),
        error(diag.privateNamedParameterWithoutPublicName, 33, 4),
      ],
    );
  }

  test_class_constructorDeclaration_noPublicName_preFeature() async {
    await assertErrorsInCode(
      '''
// @dart=3.10
class C {
  int? _123;
  C({this._123}) {}
}
''',
      [error(diag.unusedField, 31, 4), error(diag.experimentNotEnabled, 47, 4)],
    );
  }

  test_class_constructorDeclaration_noPublicName_reservedWord() async {
    await assertErrorsInCode(
      '''
class C {
  int? _for;
  C({this._for}) {}
}
''',
      [
        error(diag.unusedField, 17, 4),
        error(diag.privateNamedParameterWithoutPublicName, 33, 4),
      ],
    );
  }

  test_class_constructorDeclaration_noPublicName_stillPrivate() async {
    await assertErrorsInCode(
      '''
class C {
  int? __extraPrivate;
  C({this.__extraPrivate}) {}
}
''',
      [
        error(diag.unusedField, 17, 14),
        error(diag.privateNamedParameterWithoutPublicName, 43, 14),
      ],
    );
  }

  test_class_constructorDeclaration_noPublicName_wildcard() async {
    await assertErrorsInCode(
      '''
class C {
  int? _;
  C({this._}) {}
}
''',
      [
        error(diag.unusedField, 17, 1),
        error(diag.privateNamedParameterWithoutPublicName, 30, 1),
      ],
    );
  }

  test_class_method() async {
    await assertErrorsInCode(
      '''
class A {
  void f({int? _p}) {}
}
''',
      [error(diag.privateNamedNonFieldParameter, 25, 2)],
    );
  }

  test_class_method_noPublicName() async {
    await assertErrorsInCode(
      '''
class A {
  void f({int? _123}) {}
}
''',
      [error(diag.privateNamedNonFieldParameter, 25, 4)],
    );
  }

  test_class_primaryConstructor_declaringFormalParameter_optionalNamed() async {
    await assertErrorsInCode(
      r'''
class A({final int _p = 0}) {}
''',
      [error(diag.unusedFieldFromPrimaryConstructor, 19, 2)],
    );
  }

  test_class_primaryConstructor_declaringFormalParameter_optionalNamed_noPublicName_nonIdentifier() async {
    await assertErrorsInCode(
      '''
class C({final int? _123}) {}
''',
      [
        error(diag.privateNamedParameterWithoutPublicName, 20, 4),
        error(diag.unusedFieldFromPrimaryConstructor, 20, 4),
      ],
    );
  }

  test_class_primaryConstructor_declaringFormalParameter_optionalNamed_noPublicName_reservedWord() async {
    await assertErrorsInCode(
      '''
class C({final int? _for}) {}
''',
      [
        error(diag.privateNamedParameterWithoutPublicName, 20, 4),
        error(diag.unusedFieldFromPrimaryConstructor, 20, 4),
      ],
    );
  }

  test_class_primaryConstructor_declaringFormalParameter_optionalNamed_noPublicName_stillPrivate() async {
    await assertErrorsInCode(
      '''
class C({final int? __extraPrivate}) {}
''',
      [
        error(diag.privateNamedParameterWithoutPublicName, 20, 14),
        error(diag.unusedFieldFromPrimaryConstructor, 20, 14),
      ],
    );
  }

  test_class_primaryConstructor_declaringFormalParameter_optionalNamed_noPublicName_wildcard() async {
    await assertErrorsInCode(
      '''
class C({final int? _}) {}
''',
      [
        error(diag.privateNamedParameterWithoutPublicName, 20, 1),
        error(diag.unusedFieldFromPrimaryConstructor, 20, 1),
      ],
    );
  }

  test_class_primaryConstructor_formalParameter_optionalNamed_fieldFormal() async {
    await assertErrorsInCode(
      r'''
class A({this._p = 0}) {
  int? _p;
}
''',
      [error(diag.unusedField, 32, 2)],
    );
  }

  test_class_primaryConstructor_formalParameter_optionalNamed_fieldFormal_noPublicName_nonIdentifier() async {
    await assertErrorsInCode(
      '''
class C({this._123}) {
  int? _123;
}
''',
      [
        error(diag.privateNamedParameterWithoutPublicName, 14, 4),
        error(diag.unusedField, 30, 4),
      ],
    );
  }

  test_class_primaryConstructor_formalParameter_optionalNamed_fieldFormal_noPublicName_reservedWord() async {
    await assertErrorsInCode(
      '''
class C({this._for}) {
  int? _for;
}
''',
      [
        error(diag.privateNamedParameterWithoutPublicName, 14, 4),
        error(diag.unusedField, 30, 4),
      ],
    );
  }

  test_class_primaryConstructor_formalParameter_optionalNamed_fieldFormal_noPublicName_stillPrivate() async {
    await assertErrorsInCode(
      '''
class C({this.__extraPrivate}) {
  int? __extraPrivate;
}
''',
      [
        error(diag.privateNamedParameterWithoutPublicName, 14, 14),
        error(diag.unusedField, 40, 14),
      ],
    );
  }

  test_class_primaryConstructor_formalParameter_optionalNamed_fieldFormal_noPublicName_wildcard() async {
    await assertErrorsInCode(
      '''
class C({this._}) {
  int? _;
}
''',
      [
        error(diag.privateNamedParameterWithoutPublicName, 14, 1),
        error(diag.unusedField, 27, 1),
      ],
    );
  }

  test_class_primaryConstructor_formalParameter_optionalNamed_nonFieldFormal() async {
    await assertErrorsInCode(
      '''
class C({int? _notField}) {}
''',
      [error(diag.privateNamedNonFieldParameter, 14, 9)],
    );
  }

  test_extensionType_method() async {
    await assertErrorsInCode(
      '''
extension type E(int it) {
  void f({int? _p}) {}
}
''',
      [error(diag.privateNamedNonFieldParameter, 42, 2)],
    );
  }

  test_extensionType_primaryConstructor_requiredNamed() async {
    await assertNoErrorsInCode('''
extension type E({required int _it});
''');
  }

  test_extensionType_primaryConstructor_requiredNamed_noPublicName_nonIdentifier() async {
    await assertErrorsInCode(
      '''
extension type E({required int _123});
''',
      [error(diag.privateNamedParameterWithoutPublicName, 31, 4)],
    );
  }

  test_topLevel_function() async {
    await assertErrorsInCode(
      '''
void f({int? _p}) {}
''',
      [error(diag.privateNamedNonFieldParameter, 13, 2)],
    );
  }

  test_topLevel_function_withDefaultValue() async {
    await assertErrorsInCode(
      '''
void f({int _p = 0}) {}
''',
      [error(diag.privateNamedNonFieldParameter, 12, 2)],
    );
  }
}
