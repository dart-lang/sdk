// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(BuiltInIdentifierAsTypeNameTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class BuiltInIdentifierAsTypeNameTest extends PubPackageResolutionTest {
  test_class_as() async {
    await resolveTestCodeWithDiagnostics(r'''
class as {}
//    ^^
// [diag.builtInIdentifierAsTypeName] The built-in identifier 'as' can't be used as a type name.
''');
  }

  test_class_Function() async {
    await resolveTestCodeWithDiagnostics(r'''
class Function {}
//    ^^^^^^^^
// [diag.builtInIdentifierAsTypeName] The built-in identifier 'Function' can't be used as a type name.
''');
  }

  test_class_inout() async {
    await resolveTestCodeWithDiagnostics(r'''
class inout {}
//    ^^^^^
// [diag.builtInIdentifierAsTypeName] The built-in identifier 'inout' can't be used as a type name.
''');
  }

  test_class_inout_language310() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.10
class inout {}
''');
  }

  test_class_out() async {
    await resolveTestCodeWithDiagnostics(r'''
class out {}
//    ^^^
// [diag.builtInIdentifierAsTypeName] The built-in identifier 'out' can't be used as a type name.
''');
  }

  test_class_out_language310() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.10
class out {}
''');
  }

  test_enum_as() async {
    await resolveTestCodeWithDiagnostics(r'''
enum as {
//   ^^
// [diag.builtInIdentifierAsTypeName] The built-in identifier 'as' can't be used as a type name.
  v
}
''');
  }

  test_enum_inout() async {
    await resolveTestCodeWithDiagnostics(r'''
enum inout {v}
//   ^^^^^
// [diag.builtInIdentifierAsTypeName] The built-in identifier 'inout' can't be used as a type name.
''');
  }

  test_enum_inout_language310() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.10
enum inout {v}
''');
  }

  test_enum_out() async {
    await resolveTestCodeWithDiagnostics(r'''
enum out {v}
//   ^^^
// [diag.builtInIdentifierAsTypeName] The built-in identifier 'out' can't be used as a type name.
''');
  }

  test_enum_out_language310() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.10
enum out {v}
''');
  }

  test_mixin_as() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin as {}
//    ^^
// [diag.builtInIdentifierAsTypeName] The built-in identifier 'as' can't be used as a type name.
''');
  }

  test_mixin_Function() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin Function {}
//    ^^^^^^^^
// [diag.builtInIdentifierAsTypeName] The built-in identifier 'Function' can't be used as a type name.
''');
  }

  test_mixin_inout() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin inout {}
//    ^^^^^
// [diag.builtInIdentifierAsTypeName] The built-in identifier 'inout' can't be used as a type name.
''');
  }

  test_mixin_inout_language310() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.10
mixin inout {}
''');
  }

  test_mixin_OK_on() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}

mixin on on A {}

mixin M on on {}

mixin M2 implements on {}

class B = A with on;
class C = B with M;
class D = Object with M2;
''');
  }

  test_mixin_out() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin out {}
//    ^^^
// [diag.builtInIdentifierAsTypeName] The built-in identifier 'out' can't be used as a type name.
''');
  }

  test_mixin_out_language310() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.10
mixin out {}
''');
  }
}
