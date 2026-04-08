// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(BuiltInIdentifierAsTypeNameTest);
  });
}

@reflectiveTest
class BuiltInIdentifierAsTypeNameTest extends PubPackageResolutionTest {
  test_class_as() async {
    await assertErrorsInCode(
      '''
class as {}
''',
      [error(diag.builtInIdentifierAsTypeName, 6, 2)],
    );
  }

  test_class_Function() async {
    await assertErrorsInCode(
      '''
class Function {}
''',
      [error(diag.builtInIdentifierAsTypeName, 6, 8)],
    );
  }

  test_class_inout() async {
    await assertErrorsInCode(
      '''
class inout {}
''',
      [error(diag.builtInIdentifierAsTypeName, 6, 5)],
    );
  }

  test_class_inout_language310() async {
    await assertNoErrorsInCode('''
// @dart = 3.10
class inout {}
''');
  }

  test_class_out() async {
    await assertErrorsInCode(
      '''
class out {}
''',
      [error(diag.builtInIdentifierAsTypeName, 6, 3)],
    );
  }

  test_class_out_language310() async {
    await assertNoErrorsInCode('''
// @dart = 3.10
class out {}
''');
  }

  test_enum_as() async {
    await assertErrorsInCode(
      '''
enum as {
  v
}
''',
      [error(diag.builtInIdentifierAsTypeName, 5, 2)],
    );
  }

  test_enum_inout() async {
    await assertErrorsInCode(
      '''
enum inout {v}
''',
      [error(diag.builtInIdentifierAsTypeName, 5, 5)],
    );
  }

  test_enum_inout_language310() async {
    await assertNoErrorsInCode('''
// @dart = 3.10
enum inout {v}
''');
  }

  test_enum_out() async {
    await assertErrorsInCode(
      '''
enum out {v}
''',
      [error(diag.builtInIdentifierAsTypeName, 5, 3)],
    );
  }

  test_enum_out_language310() async {
    await assertNoErrorsInCode('''
// @dart = 3.10
enum out {v}
''');
  }

  test_mixin_as() async {
    await assertErrorsInCode(
      '''
mixin as {}
''',
      [error(diag.builtInIdentifierAsTypeName, 6, 2)],
    );
  }

  test_mixin_Function() async {
    await assertErrorsInCode(
      '''
mixin Function {}
''',
      [error(diag.builtInIdentifierAsTypeName, 6, 8)],
    );
  }

  test_mixin_inout() async {
    await assertErrorsInCode(
      '''
mixin inout {}
''',
      [error(diag.builtInIdentifierAsTypeName, 6, 5)],
    );
  }

  test_mixin_inout_language310() async {
    await assertNoErrorsInCode('''
// @dart = 3.10
mixin inout {}
''');
  }

  test_mixin_OK_on() async {
    await assertNoErrorsInCode(r'''
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
    await assertErrorsInCode(
      '''
mixin out {}
''',
      [error(diag.builtInIdentifierAsTypeName, 6, 3)],
    );
  }

  test_mixin_out_language310() async {
    await assertNoErrorsInCode('''
// @dart = 3.10
mixin out {}
''');
  }
}
