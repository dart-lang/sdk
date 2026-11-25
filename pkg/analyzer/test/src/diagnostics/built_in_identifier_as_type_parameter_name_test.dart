// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(BuiltInIdentifierAsTypeParameterNameTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class BuiltInIdentifierAsTypeParameterNameTest
    extends PubPackageResolutionTest {
  test_class_as() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<as> {}
//      ^^
// [diag.builtInIdentifierAsTypeParameterName] The built-in identifier 'as' can't be used as a type parameter name.
''');
  }

  test_class_Function() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<Function> {}
//      ^^^^^^^^
// [diag.builtInIdentifierAsTypeParameterName] The built-in identifier 'Function' can't be used as a type parameter name.
''');
  }

  test_extension_as() async {
    await resolveTestCodeWithDiagnostics(r'''
extension <as> on List {}
//         ^^
// [diag.builtInIdentifierAsTypeParameterName] The built-in identifier 'as' can't be used as a type parameter name.
''');
  }

  test_function_as() async {
    await resolveTestCodeWithDiagnostics(r'''
void f<as>() {}
//     ^^
// [diag.builtInIdentifierAsTypeParameterName] The built-in identifier 'as' can't be used as a type parameter name.
''');
  }
}
