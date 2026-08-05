// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(BuiltInIdentifierAsTypedefNameTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class BuiltInIdentifierAsTypedefNameTest extends PubPackageResolutionTest {
  test_classTypeAlias() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
mixin B {}
class as = A with B;
//    ^^
// [diag.builtInIdentifierAsTypedefName] The built-in identifier 'as' can't be used as a typedef name.
''');
  }

  test_classTypeAlias_inout() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
mixin B {}
class inout = A with B;
//    ^^^^^
// [diag.builtInIdentifierAsTypedefName] The built-in identifier 'inout' can't be used as a typedef name.
''');
  }

  test_classTypeAlias_inout_language310() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.10
class A {}
mixin B {}
class inout = A with B;
''');
  }

  test_classTypeAlias_out() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
mixin B {}
class out = A with B;
//    ^^^
// [diag.builtInIdentifierAsTypedefName] The built-in identifier 'out' can't be used as a typedef name.
''');
  }

  test_classTypeAlias_out_language310() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.10
class A {}
mixin B {}
class out = A with B;
''');
  }

  test_typedef_classic() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef void as();
//           ^^
// [diag.expectedIdentifierButGotKeyword] 'as' can't be used as an identifier because it's a keyword.
// [diag.builtInIdentifierAsTypedefName] The built-in identifier 'as' can't be used as a typedef name.
''');
  }

  test_typedef_classic_as() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef void as();
//           ^^
// [diag.expectedIdentifierButGotKeyword] 'as' can't be used as an identifier because it's a keyword.
// [diag.builtInIdentifierAsTypedefName] The built-in identifier 'as' can't be used as a typedef name.
''');
  }

  test_typedef_classic_inout() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef void inout();
//           ^^^^^
// [diag.builtInIdentifierAsTypedefName] The built-in identifier 'inout' can't be used as a typedef name.
''');
  }

  test_typedef_classic_inout_language310() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.10
typedef void inout();
''');
  }

  test_typedef_classic_out() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef void out();
//           ^^^
// [diag.builtInIdentifierAsTypedefName] The built-in identifier 'out' can't be used as a typedef name.
''');
  }

  test_typedef_classic_out_language310() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.10
typedef void out();
''');
  }

  test_typedef_generic_as() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef as = void Function();
//      ^^
// [diag.expectedIdentifierButGotKeyword] 'as' can't be used as an identifier because it's a keyword.
// [diag.builtInIdentifierAsTypedefName] The built-in identifier 'as' can't be used as a typedef name.
''');
  }

  test_typedef_generic_inout() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef inout = void Function();
//      ^^^^^
// [diag.builtInIdentifierAsTypedefName] The built-in identifier 'inout' can't be used as a typedef name.
''');
  }

  test_typedef_generic_inout_language310() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.10
typedef inout = void Function();
''');
  }

  test_typedef_generic_out() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef out = void Function();
//      ^^^
// [diag.builtInIdentifierAsTypedefName] The built-in identifier 'out' can't be used as a typedef name.
''');
  }

  test_typedef_generic_out_language310() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.10
typedef out = void Function();
''');
  }

  test_typedef_interfaceType_as() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef as = List<int>;
//      ^^
// [diag.expectedIdentifierButGotKeyword] 'as' can't be used as an identifier because it's a keyword.
// [diag.builtInIdentifierAsTypedefName] The built-in identifier 'as' can't be used as a typedef name.
''');
  }

  test_typedef_interfaceType_Function() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef Function = List<int>;
//      ^^^^^^^^
// [diag.expectedIdentifierButGotKeyword] 'Function' can't be used as an identifier because it's a keyword.
// [diag.builtInIdentifierAsTypedefName] The built-in identifier 'Function' can't be used as a typedef name.
''');
  }
}
