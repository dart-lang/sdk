// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(BuiltInIdentifierAsTypeParameterNameTest);
  });
}

@reflectiveTest
class BuiltInIdentifierAsTypeParameterNameTest
    extends PubPackageResolutionTest {
  test_class_as() async {
    await assertErrorsInCode(
      '''
class A<as> {}
''',
      [error(diag.builtInIdentifierAsTypeParameterName, 8, 2)],
    );
  }

  test_class_Function() async {
    await assertErrorsInCode(
      '''
class A<Function> {}
''',
      [error(diag.builtInIdentifierAsTypeParameterName, 8, 8)],
    );
  }

  test_extension_as() async {
    await assertErrorsInCode(
      '''
extension <as> on List {}
''',
      [error(diag.builtInIdentifierAsTypeParameterName, 11, 2)],
    );
  }

  test_function_as() async {
    await assertErrorsInCode(
      '''
void f<as>() {}
''',
      [error(diag.builtInIdentifierAsTypeParameterName, 7, 2)],
    );
  }
}
