// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SuperInEnumConstructorTest);
  });
}

@reflectiveTest
class SuperInEnumConstructorTest extends PubPackageResolutionTest {
  test_primary_one() async {
    await assertErrorsInCode(
      r'''
enum E() {
  v;
  this : super();
}
''',
      [error(diag.superInEnumConstructor, 25, 5)],
    );
  }

  test_typeName_hasRedirect() async {
    await assertErrorsInCode(
      r'''
enum E {
  v;
  const E.named();
  const E() : this.named(), super();
}
''',
      [error(diag.superInEnumConstructor, 61, 5)],
    );
  }

  test_typeName_one() async {
    await assertErrorsInCode(
      r'''
enum E {
  v;
  const E() : super();
}
''',
      [error(diag.superInEnumConstructor, 28, 5)],
    );
  }

  test_typeName_two() async {
    await assertErrorsInCode(
      r'''
enum E {
  v;
  const E() : super(), super();
}
''',
      [
        error(diag.superInEnumConstructor, 28, 5),
        error(diag.superInEnumConstructor, 37, 5),
      ],
    );
  }
}
