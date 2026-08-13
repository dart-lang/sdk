// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PrivateOptionalParameterTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class PrivateOptionalParameterTest extends PubPackageResolutionTest {
  test_class_constructorDeclaration_fieldFormal() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int? _p;
//     ^^
// [diag.unusedField] The value of the field '_p' isn't used.
  A({this._p = 0});
}
''');
  }

  test_class_constructorDeclaration_nonFieldParameter() async {
    await resolveTestCodeWithDiagnostics('''
class C {
  C({int? _notField});
//        ^^^^^^^^^
// [diag.privateNamedNonFieldParameter] Named parameters that don't refer to instance variables can't start with underscore.
}
''');
  }

  test_class_constructorDeclaration_noPublicName_nonIdentifier() async {
    await resolveTestCodeWithDiagnostics('''
class C {
  int? _123;
//     ^^^^
// [diag.unusedField] The value of the field '_123' isn't used.
  C({this._123}) {}
//        ^^^^
// [diag.privateNamedParameterWithoutPublicName] A private named parameter must be a public identifier after removing the leading underscore.
}
''');
  }

  test_class_constructorDeclaration_noPublicName_preFeature() async {
    await resolveTestCodeWithDiagnostics('''
// @dart=3.10
class C {
  int? _123;
//     ^^^^
// [diag.unusedField] The value of the field '_123' isn't used.
  C({this._123}) {}
//        ^^^^
// [diag.experimentNotEnabled] This requires the 'private-named-parameters' language feature to be enabled.
}
''');
  }

  test_class_constructorDeclaration_noPublicName_reservedWord() async {
    await resolveTestCodeWithDiagnostics('''
class C {
  int? _for;
//     ^^^^
// [diag.unusedField] The value of the field '_for' isn't used.
  C({this._for}) {}
//        ^^^^
// [diag.privateNamedParameterWithoutPublicName] A private named parameter must be a public identifier after removing the leading underscore.
}
''');
  }

  test_class_constructorDeclaration_noPublicName_stillPrivate() async {
    await resolveTestCodeWithDiagnostics('''
class C {
  int? __extraPrivate;
//     ^^^^^^^^^^^^^^
// [diag.unusedField] The value of the field '__extraPrivate' isn't used.
  C({this.__extraPrivate}) {}
//        ^^^^^^^^^^^^^^
// [diag.privateNamedParameterWithoutPublicName] A private named parameter must be a public identifier after removing the leading underscore.
}
''');
  }

  test_class_constructorDeclaration_noPublicName_wildcard() async {
    await resolveTestCodeWithDiagnostics('''
class C {
  int? _;
//     ^
// [diag.unusedField] The value of the field '_' isn't used.
  C({this._}) {}
//        ^
// [diag.privateNamedParameterWithoutPublicName] A private named parameter must be a public identifier after removing the leading underscore.
}
''');
  }

  test_class_method() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  void f({int? _p}) {}
//             ^^
// [diag.privateNamedNonFieldParameter] Named parameters that don't refer to instance variables can't start with underscore.
}
''');
  }

  test_class_method_noPublicName() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  void f({int? _123}) {}
//             ^^^^
// [diag.privateNamedNonFieldParameter] Named parameters that don't refer to instance variables can't start with underscore.
}
''');
  }

  test_class_primaryConstructor_declaringFormalParameter_optionalNamed() async {
    await resolveTestCodeWithDiagnostics(r'''
class A({final int _p = 0}) {}
//                 ^^
// [diag.unusedFieldFromPrimaryConstructor] The value of the field '_p' isn't used.
''');
  }

  test_class_primaryConstructor_declaringFormalParameter_optionalNamed_noPublicName_nonIdentifier() async {
    await resolveTestCodeWithDiagnostics('''
class C({final int? _123}) {}
//                  ^^^^
// [diag.privateNamedParameterWithoutPublicName] A private named parameter must be a public identifier after removing the leading underscore.
// [diag.unusedFieldFromPrimaryConstructor] The value of the field '_123' isn't used.
''');
  }

  test_class_primaryConstructor_declaringFormalParameter_optionalNamed_noPublicName_reservedWord() async {
    await resolveTestCodeWithDiagnostics('''
class C({final int? _for}) {}
//                  ^^^^
// [diag.privateNamedParameterWithoutPublicName] A private named parameter must be a public identifier after removing the leading underscore.
// [diag.unusedFieldFromPrimaryConstructor] The value of the field '_for' isn't used.
''');
  }

  test_class_primaryConstructor_declaringFormalParameter_optionalNamed_noPublicName_stillPrivate() async {
    await resolveTestCodeWithDiagnostics('''
class C({final int? __extraPrivate}) {}
//                  ^^^^^^^^^^^^^^
// [diag.privateNamedParameterWithoutPublicName] A private named parameter must be a public identifier after removing the leading underscore.
// [diag.unusedFieldFromPrimaryConstructor] The value of the field '__extraPrivate' isn't used.
''');
  }

  test_class_primaryConstructor_declaringFormalParameter_optionalNamed_noPublicName_wildcard() async {
    await resolveTestCodeWithDiagnostics('''
class C({final int? _}) {}
//                  ^
// [diag.privateNamedParameterWithoutPublicName] A private named parameter must be a public identifier after removing the leading underscore.
// [diag.unusedFieldFromPrimaryConstructor] The value of the field '_' isn't used.
''');
  }

  test_class_primaryConstructor_formalParameter_optionalNamed_fieldFormal() async {
    await resolveTestCodeWithDiagnostics(r'''
class A({this._p = 0}) {
  int? _p;
//     ^^
// [diag.unusedField] The value of the field '_p' isn't used.
}
''');
  }

  test_class_primaryConstructor_formalParameter_optionalNamed_fieldFormal_noPublicName_nonIdentifier() async {
    await resolveTestCodeWithDiagnostics('''
class C({this._123}) {
//            ^^^^
// [diag.privateNamedParameterWithoutPublicName] A private named parameter must be a public identifier after removing the leading underscore.
  int? _123;
//     ^^^^
// [diag.unusedField] The value of the field '_123' isn't used.
}
''');
  }

  test_class_primaryConstructor_formalParameter_optionalNamed_fieldFormal_noPublicName_reservedWord() async {
    await resolveTestCodeWithDiagnostics('''
class C({this._for}) {
//            ^^^^
// [diag.privateNamedParameterWithoutPublicName] A private named parameter must be a public identifier after removing the leading underscore.
  int? _for;
//     ^^^^
// [diag.unusedField] The value of the field '_for' isn't used.
}
''');
  }

  test_class_primaryConstructor_formalParameter_optionalNamed_fieldFormal_noPublicName_stillPrivate() async {
    await resolveTestCodeWithDiagnostics('''
class C({this.__extraPrivate}) {
//            ^^^^^^^^^^^^^^
// [diag.privateNamedParameterWithoutPublicName] A private named parameter must be a public identifier after removing the leading underscore.
  int? __extraPrivate;
//     ^^^^^^^^^^^^^^
// [diag.unusedField] The value of the field '__extraPrivate' isn't used.
}
''');
  }

  test_class_primaryConstructor_formalParameter_optionalNamed_fieldFormal_noPublicName_wildcard() async {
    await resolveTestCodeWithDiagnostics('''
class C({this._}) {
//            ^
// [diag.privateNamedParameterWithoutPublicName] A private named parameter must be a public identifier after removing the leading underscore.
  int? _;
//     ^
// [diag.unusedField] The value of the field '_' isn't used.
}
''');
  }

  test_class_primaryConstructor_formalParameter_optionalNamed_nonFieldFormal() async {
    await resolveTestCodeWithDiagnostics('''
class C({int? _notField}) {}
//            ^^^^^^^^^
// [diag.privateNamedNonFieldParameter] Named parameters that don't refer to instance variables can't start with underscore.
''');
  }

  test_extensionType_method() async {
    await resolveTestCodeWithDiagnostics('''
extension type E(int it) {
  void f({int? _p}) {}
//             ^^
// [diag.privateNamedNonFieldParameter] Named parameters that don't refer to instance variables can't start with underscore.
}
''');
  }

  test_extensionType_primaryConstructor_requiredNamed() async {
    await resolveTestCodeWithDiagnostics('''
extension type E({required int _it});
''');
  }

  test_extensionType_primaryConstructor_requiredNamed_noPublicName_nonIdentifier() async {
    await resolveTestCodeWithDiagnostics('''
extension type E({required int _123});
//                             ^^^^
// [diag.privateNamedParameterWithoutPublicName] A private named parameter must be a public identifier after removing the leading underscore.
''');
  }

  test_topLevel_function() async {
    await resolveTestCodeWithDiagnostics('''
void f({int? _p}) {}
//           ^^
// [diag.privateNamedNonFieldParameter] Named parameters that don't refer to instance variables can't start with underscore.
''');
  }

  test_topLevel_function_withDefaultValue() async {
    await resolveTestCodeWithDiagnostics('''
void f({int _p = 0}) {}
//          ^^
// [diag.privateNamedNonFieldParameter] Named parameters that don't refer to instance variables can't start with underscore.
''');
  }
}
