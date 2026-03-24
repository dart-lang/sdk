// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(BuiltInIdentifierAsTypedefNameTest);
  });
}

@reflectiveTest
class BuiltInIdentifierAsTypedefNameTest extends PubPackageResolutionTest {
  test_classTypeAlias() async {
    await assertErrorsInCode(
      r'''
class A {}
mixin B {}
class as = A with B;
''',
      [error(diag.builtInIdentifierAsTypedefName, 28, 2)],
    );
  }

  test_classTypeAlias_inout() async {
    await assertErrorsInCode(
      '''
class A {}
mixin B {}
class inout = A with B;
''',
      [error(diag.builtInIdentifierAsTypedefName, 28, 5)],
    );
  }

  test_classTypeAlias_inout_language310() async {
    await assertNoErrorsInCode('''
// @dart = 3.10
class A {}
mixin B {}
class inout = A with B;
''');
  }

  test_classTypeAlias_out() async {
    await assertErrorsInCode(
      '''
class A {}
mixin B {}
class out = A with B;
''',
      [error(diag.builtInIdentifierAsTypedefName, 28, 3)],
    );
  }

  test_classTypeAlias_out_language310() async {
    await assertNoErrorsInCode('''
// @dart = 3.10
class A {}
mixin B {}
class out = A with B;
''');
  }

  test_typedef_classic() async {
    await assertErrorsInCode(
      r'''
typedef void as();
''',
      [
        error(diag.expectedIdentifierButGotKeyword, 13, 2),
        error(diag.builtInIdentifierAsTypedefName, 13, 2),
      ],
    );
  }

  test_typedef_classic_as() async {
    await assertErrorsInCode(
      r'''
typedef void as();
''',
      [
        error(diag.expectedIdentifierButGotKeyword, 13, 2),
        error(diag.builtInIdentifierAsTypedefName, 13, 2),
      ],
    );
  }

  test_typedef_classic_inout() async {
    await assertErrorsInCode(
      '''
typedef void inout();
''',
      [error(diag.builtInIdentifierAsTypedefName, 13, 5)],
    );
  }

  test_typedef_classic_inout_language310() async {
    await assertNoErrorsInCode('''
// @dart = 3.10
typedef void inout();
''');
  }

  test_typedef_classic_out() async {
    await assertErrorsInCode(
      '''
typedef void out();
''',
      [error(diag.builtInIdentifierAsTypedefName, 13, 3)],
    );
  }

  test_typedef_classic_out_language310() async {
    await assertNoErrorsInCode('''
// @dart = 3.10
typedef void out();
''');
  }

  test_typedef_generic_as() async {
    await assertErrorsInCode(
      r'''
typedef as = void Function();
''',
      [
        error(diag.builtInIdentifierAsTypedefName, 8, 2),
        error(diag.expectedIdentifierButGotKeyword, 8, 2),
      ],
    );
  }

  test_typedef_generic_inout() async {
    await assertErrorsInCode(
      '''
typedef inout = void Function();
''',
      [error(diag.builtInIdentifierAsTypedefName, 8, 5)],
    );
  }

  test_typedef_generic_inout_language310() async {
    await assertNoErrorsInCode('''
// @dart = 3.10
typedef inout = void Function();
''');
  }

  test_typedef_generic_out() async {
    await assertErrorsInCode(
      '''
typedef out = void Function();
''',
      [error(diag.builtInIdentifierAsTypedefName, 8, 3)],
    );
  }

  test_typedef_generic_out_language310() async {
    await assertNoErrorsInCode('''
// @dart = 3.10
typedef out = void Function();
''');
  }

  test_typedef_interfaceType_as() async {
    await assertErrorsInCode(
      r'''
typedef as = List<int>;
''',
      [
        error(diag.builtInIdentifierAsTypedefName, 8, 2),
        error(diag.expectedIdentifierButGotKeyword, 8, 2),
      ],
    );
  }

  test_typedef_interfaceType_Function() async {
    await assertErrorsInCode(
      r'''
typedef Function = List<int>;
''',
      [
        error(diag.builtInIdentifierAsTypedefName, 8, 8),
        error(diag.expectedIdentifierButGotKeyword, 8, 8),
      ],
    );
  }
}
