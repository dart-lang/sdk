// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NonAbstractClassHasEnumSuperinterfaceTest);
  });
}

@reflectiveTest
class NonAbstractClassHasEnumSuperinterfaceTest
    extends PubPackageResolutionTest {
  test_class_abstract() async {
    await assertNoErrorsInCode('''
abstract class A implements Enum {}
''');
  }

  test_class_concrete() async {
    await assertErrorsInCode(
      '''
class A implements Enum {}
''',
      [error(diag.concreteClassHasEnumSuperinterface, 19, 4)],
    );
  }

  test_class_concrete_indirect() async {
    await assertErrorsInCode(
      '''
abstract class A implements Enum {}
class B implements A {}
''',
      [error(diag.concreteClassHasEnumSuperinterface, 42, 1)],
    );
  }

  test_classTypeAlias_concrete() async {
    await assertErrorsInCode(
      '''
class M {}
class A = Object with M implements Enum;
''',
      [error(diag.concreteClassHasEnumSuperinterface, 46, 4)],
    );
  }

  test_classTypeAlias_concrete_indirect() async {
    await assertErrorsInCode(
      '''
mixin M {}
abstract class A implements Enum {}
class B = Object with M implements A;
''',
      [error(diag.concreteClassHasEnumSuperinterface, 53, 1)],
    );
  }

  test_enum() async {
    await assertNoErrorsInCode('''
enum E implements Enum {
  v
}
''');
  }
}
