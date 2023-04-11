// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MixinClassDeclarationExtendsNotObjectTest);
  });
}

@reflectiveTest
class MixinClassDeclarationExtendsNotObjectTest
    extends PubPackageResolutionTest {
  test_class_extends_class() async {
    await assertErrorsInCode(r'''
class A {}
mixin class B extends A {}
''', [
      error(CompileTimeErrorCode.MIXIN_CLASS_DECLARATION_EXTENDS_NOT_OBJECT, 33,
          1),
    ]);
  }

  test_class_extends_Object() async {
    await assertNoErrorsInCode(r'''
mixin class A extends Object {}
''');
  }

  test_class_extends_Object_with() async {
    await assertErrorsInCode(r'''
mixin M {}
mixin class A extends Object with M {}
''', [
      error(CompileTimeErrorCode.MIXIN_CLASS_DECLARATION_EXTENDS_NOT_OBJECT, 40,
          6),
    ]);
  }

  test_classTypeAlias_with() async {
    await assertNoErrorsInCode(r'''
mixin M {}
mixin class A = Object with M;
''');
  }

  test_classTypeAlias_with2() async {
    await assertErrorsInCode(r'''
mixin M1 {}
mixin M2 {}
mixin class A = Object with M1, M2;
''', [
      error(CompileTimeErrorCode.MIXIN_CLASS_DECLARATION_EXTENDS_NOT_OBJECT, 47,
          11),
    ]);
  }
}
