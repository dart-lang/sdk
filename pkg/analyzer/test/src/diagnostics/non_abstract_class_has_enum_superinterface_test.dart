// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
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

  test_class_concrete_indirect() async {
    await assertErrorsInCode('''
abstract class A implements Enum {}
class B implements A {}
''', [
      error(CompileTimeErrorCode.NON_ABSTRACT_CLASS_HAS_ENUM_SUPERINTERFACE, 42,
          1),
    ]);
  }

  test_classTypeAlias_concrete_indirect() async {
    await assertErrorsInCode('''
mixin M {}
abstract class A implements Enum {}
class B = Object with M implements A;
''', [
      error(CompileTimeErrorCode.NON_ABSTRACT_CLASS_HAS_ENUM_SUPERINTERFACE, 53,
          1),
    ]);
  }
}
