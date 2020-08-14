// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MixinInheritsFromNotObjectTest);
  });
}

@reflectiveTest
class MixinInheritsFromNotObjectTest extends PubPackageResolutionTest {
  test_classDeclaration_extends() async {
    await assertErrorsInCode(r'''
class A {}
class B extends A {}
class C extends Object with B {}
''', [
      error(CompileTimeErrorCode.MIXIN_INHERITS_FROM_NOT_OBJECT, 60, 1),
    ]);
  }

  test_classDeclaration_extends_new_syntax() async {
    await assertNoErrorsInCode(r'''
class A {}
mixin B on A {}
class C extends A with B {}
''');
  }

  test_classDeclaration_mixTypeAlias() async {
    await assertNoErrorsInCode(r'''
class A {}
class B = Object with A;
class C extends Object with B {}
''');
  }

  test_classDeclaration_with() async {
    await assertErrorsInCode(r'''
class A {}
class B extends Object with A {}
class C extends Object with B {}
''', [
      error(CompileTimeErrorCode.MIXIN_INHERITS_FROM_NOT_OBJECT, 72, 1),
    ]);
  }

  test_typeAlias_extends() async {
    await assertErrorsInCode(r'''
class A {}
class B extends A {}
class C = Object with B;
''', [
      error(CompileTimeErrorCode.MIXIN_INHERITS_FROM_NOT_OBJECT, 54, 1),
    ]);
  }

  test_typeAlias_extends_new_syntax() async {
    await assertNoErrorsInCode(r'''
class A {}
mixin B on A {}
class C = A with B;
''');
  }

  test_typeAlias_with() async {
    await assertErrorsInCode(r'''
class A {}
class B extends Object with A {}
class C = Object with B;
''', [
      error(CompileTimeErrorCode.MIXIN_INHERITS_FROM_NOT_OBJECT, 66, 1),
    ]);
  }

  test_typedef_mixTypeAlias() async {
    await assertNoErrorsInCode(r'''
class A {}
class B = Object with A;
class C = Object with B;
''');
  }
}
