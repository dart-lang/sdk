// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DefaultValueInFunctionTypeTest);
  });
}

@reflectiveTest
class DefaultValueInFunctionTypeTest extends PubPackageResolutionTest {
  test_new_named() async {
    await assertErrorsInCode(
      '''
typedef F = int Function({Map<String, String> m = const {}});
''',
      [error(diag.defaultValueInFunctionType, 48, 1)],
    );
  }

  test_new_named_ambiguous() async {
    // Test that the strong checker does not crash when given an ambiguous set
    // or map literal.
    await assertErrorsInCode(
      '''
typedef F = int Function({Object m = const {1, 2: 3}});
''',
      [
        error(diag.defaultValueInFunctionType, 35, 1),
        error(diag.ambiguousSetOrMapLiteralBoth, 37, 15),
      ],
    );
  }

  test_new_positional() async {
    await assertErrorsInCode(
      '''
typedef F = int Function([Map<String, String> m = const {}]);
''',
      [error(diag.defaultValueInFunctionType, 48, 1)],
    );
  }

  test_old_named() async {
    await assertErrorsInCode(
      '''
typedef F([x = 0]);
''',
      [error(diag.defaultValueInFunctionType, 13, 1)],
    );
  }

  test_old_positional() async {
    await assertErrorsInCode(
      '''
typedef F([x = 0]);
''',
      [error(diag.defaultValueInFunctionType, 13, 1)],
    );
  }

  test_typeArgument_ofInstanceCreation() async {
    await assertErrorsInCode(
      '''
class A<T> {}

void f() {
  A<void Function([int x = 42])>();
}
''',
      [error(diag.defaultValueInFunctionType, 51, 1)],
    );
    // The expression is resolved, even if it is invalid.
    assertType(findNode.integerLiteral('42'), 'int');
  }
}
