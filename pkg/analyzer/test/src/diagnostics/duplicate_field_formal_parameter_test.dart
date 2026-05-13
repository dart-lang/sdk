// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DuplicateFieldFormalParameterTest);
  });
}

@reflectiveTest
class DuplicateFieldFormalParameterTest extends PubPackageResolutionTest {
  test_constructor_optional_named() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int a;
  A({this.a = 0, this.a = 1});
//        ^
// [context 1] The first definition of this name.
//                    ^
// [diag.duplicateFieldFormalParameter][context 1] The field 'a' can't be initialized by multiple parameters in the same constructor.
}
''');
  }

  test_constructor_optional_named_wildcard() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int _;
//    ^
// [diag.unusedField] The value of the field '_' isn't used.
  A({this._ = 0, this._ = 1});
//        ^
// [context 1] The first definition of this name.
// [diag.privateNamedParameterWithoutPublicName] A private named parameter must be a public identifier after removing the leading underscore.
//                    ^
// [diag.duplicateFieldFormalParameter][context 1] The field '_' can't be initialized by multiple parameters in the same constructor.
// [diag.privateNamedParameterWithoutPublicName] A private named parameter must be a public identifier after removing the leading underscore.
}
''');
  }

  test_constructor_optional_named_wildcard_preWildcards() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.4
// (pre wildcard-variables)

class A {
  int _;
//    ^
// [diag.unusedField] The value of the field '_' isn't used.
  A({this._ = 0, this._ = 1});
//        ^
// [context 1] The first definition of this name.
// [diag.experimentNotEnabled] This requires the 'private-named-parameters' language feature to be enabled.
//                    ^
// [diag.duplicateFieldFormalParameter][context 1] The field '_' can't be initialized by multiple parameters in the same constructor.
// [diag.experimentNotEnabled] This requires the 'private-named-parameters' language feature to be enabled.
}
''');
  }

  test_constructor_optional_positional() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int a;
  A([this.a = 0, this.a = 1]);
//        ^
// [context 1] The first definition of this name.
//                    ^
// [diag.duplicateFieldFormalParameter][context 1] The field 'a' can't be initialized by multiple parameters in the same constructor.
}
''');
  }

  test_constructor_optional_positional_final() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  final x;
  A([this.x = 1, this.x = 2]) {}
//        ^
// [context 1] The first definition of this name.
//                    ^
// [diag.duplicateFieldFormalParameter][context 1] The field 'x' can't be initialized by multiple parameters in the same constructor.
}
''');
  }

  test_constructor_optional_positional_final_wildcard() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  final _;
//      ^
// [diag.unusedField] The value of the field '_' isn't used.
  A([this._ = 1, this._ = 2]) {}
//        ^
// [context 1] The first definition of this name.
//                    ^
// [diag.duplicateFieldFormalParameter][context 1] The field '_' can't be initialized by multiple parameters in the same constructor.
}
''');
  }

  test_constructor_optional_positional_final_wildcard_preWildcards() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.4
// (pre wildcard-variables)

class A {
  final _;
//      ^
// [diag.unusedField] The value of the field '_' isn't used.
  A([this._ = 1, this._ = 2]) {}
//        ^
// [context 1] The first definition of this name.
//                    ^
// [diag.duplicateFieldFormalParameter][context 1] The field '_' can't be initialized by multiple parameters in the same constructor.
}
''');
  }

  test_constructor_optional_positional_wildcard() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int _;
//    ^
// [diag.unusedField] The value of the field '_' isn't used.
  A([this._ = 0, this._ = 1]);
//        ^
// [context 1] The first definition of this name.
//                    ^
// [diag.duplicateFieldFormalParameter][context 1] The field '_' can't be initialized by multiple parameters in the same constructor.
}
''');
  }

  test_constructor_optional_positional_wildcard_preWildcards() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.4
// (pre wildcard-variables)

class A {
  int _;
//    ^
// [diag.unusedField] The value of the field '_' isn't used.
  A([this._ = 0, this._ = 1]);
//        ^
// [context 1] The first definition of this name.
//                    ^
// [diag.duplicateFieldFormalParameter][context 1] The field '_' can't be initialized by multiple parameters in the same constructor.
}
''');
  }

  test_constructor_required_named() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int a;
  A({required this.a, required this.a});
//                 ^
// [context 1] The first definition of this name.
//                                  ^
// [diag.duplicateFieldFormalParameter][context 1] The field 'a' can't be initialized by multiple parameters in the same constructor.
}
''');
  }

  test_constructor_required_named_wildcard() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int _;
//    ^
// [diag.unusedField] The value of the field '_' isn't used.
  A({required this._, required this._});
//                 ^
// [context 1] The first definition of this name.
// [diag.privateNamedParameterWithoutPublicName] A private named parameter must be a public identifier after removing the leading underscore.
//                                  ^
// [diag.duplicateFieldFormalParameter][context 1] The field '_' can't be initialized by multiple parameters in the same constructor.
// [diag.privateNamedParameterWithoutPublicName] A private named parameter must be a public identifier after removing the leading underscore.
}
''');
  }

  test_constructor_required_named_wildcard_preWildcards() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.4
// (pre wildcard-variables)

class A {
  int _;
//    ^
// [diag.unusedField] The value of the field '_' isn't used.
  A({required this._, required this._});
//                 ^
// [context 1] The first definition of this name.
// [diag.experimentNotEnabled] This requires the 'private-named-parameters' language feature to be enabled.
//                                  ^
// [diag.duplicateFieldFormalParameter][context 1] The field '_' can't be initialized by multiple parameters in the same constructor.
// [diag.experimentNotEnabled] This requires the 'private-named-parameters' language feature to be enabled.
}
''');
  }

  test_constructor_required_positional() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int a;
  A(this.a, this.a);
//       ^
// [context 1] The first definition of this name.
//               ^
// [diag.duplicateFieldFormalParameter][context 1] The field 'a' can't be initialized by multiple parameters in the same constructor.
}
''');
  }

  test_constructor_required_positional_final() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  final x;
  A(this.x, this.x) {}
//       ^
// [context 1] The first definition of this name.
//               ^
// [diag.duplicateFieldFormalParameter][context 1] The field 'x' can't be initialized by multiple parameters in the same constructor.
}
''');
  }

  test_constructor_required_positional_final_wildcard() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  final _;
//      ^
// [diag.unusedField] The value of the field '_' isn't used.
  A(this._, this._) {}
//       ^
// [context 1] The first definition of this name.
//               ^
// [diag.duplicateFieldFormalParameter][context 1] The field '_' can't be initialized by multiple parameters in the same constructor.
}
''');
  }

  test_constructor_required_positional_final_wildcard_preWildcards() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.4
// (pre wildcard-variables)

class A {
  final _;
//      ^
// [diag.unusedField] The value of the field '_' isn't used.
  A(this._, this._) {}
//       ^
// [context 1] The first definition of this name.
//               ^
// [diag.duplicateFieldFormalParameter][context 1] The field '_' can't be initialized by multiple parameters in the same constructor.
}
''');
  }

  test_constructor_required_positional_preWildcards() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.4
// (pre wildcard-variables)

class A {
  int? _;
//     ^
// [diag.unusedField] The value of the field '_' isn't used.
  A(this._, this._);
//       ^
// [context 1] The first definition of this name.
//               ^
// [diag.duplicateFieldFormalParameter][context 1] The field '_' can't be initialized by multiple parameters in the same constructor.
}
''');
  }

  test_constructor_required_positional_primaryConstructor() async {
    await resolveTestCodeWithDiagnostics(r'''
class A(this.f, this.f) {
//           ^
// [context 1] The first definition of this name.
//                   ^
// [diag.duplicateFieldFormalParameter][context 1] The field 'f' can't be initialized by multiple parameters in the same constructor.
  int f;
}
''');
  }

  // TODO(pq): add more tests (https://github.com/dart-lang/sdk/issues/56092)
  test_constructor_required_positional_wildcard() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int? _;
//     ^
// [diag.unusedField] The value of the field '_' isn't used.
  A(this._, this._);
//       ^
// [context 1] The first definition of this name.
//               ^
// [diag.duplicateFieldFormalParameter][context 1] The field '_' can't be initialized by multiple parameters in the same constructor.
}
''');
  }

  test_primaryConstructor_optional_named() async {
    await resolveTestCodeWithDiagnostics(r'''
class A({this.a = 0, this.a = 1}) {
//            ^
// [context 1] The first definition of this name.
//                        ^
// [diag.duplicateFieldFormalParameter][context 1] The field 'a' can't be initialized by multiple parameters in the same constructor.
  int a;
}
''');
  }

  test_primaryConstructor_optional_positional() async {
    await resolveTestCodeWithDiagnostics(r'''
class A([this.a = 0, this.a = 1]) {
//            ^
// [context 1] The first definition of this name.
//                        ^
// [diag.duplicateFieldFormalParameter][context 1] The field 'a' can't be initialized by multiple parameters in the same constructor.
  int a;
}
''');
  }

  test_primaryConstructor_required_named() async {
    await resolveTestCodeWithDiagnostics(r'''
class A({required this.a, required this.a}) {
//                     ^
// [context 1] The first definition of this name.
//                                      ^
// [diag.duplicateFieldFormalParameter][context 1] The field 'a' can't be initialized by multiple parameters in the same constructor.
  int a;
}
''');
  }

  test_primaryConstructor_required_positional() async {
    await resolveTestCodeWithDiagnostics(r'''
class A(this.a, this.a) {
//           ^
// [context 1] The first definition of this name.
//                   ^
// [diag.duplicateFieldFormalParameter][context 1] The field 'a' can't be initialized by multiple parameters in the same constructor.
  int a;
}
''');
  }
}
