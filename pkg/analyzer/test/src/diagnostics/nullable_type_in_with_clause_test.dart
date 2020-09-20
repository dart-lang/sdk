// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NullableTypeInWithClauseTest);
  });
}

@reflectiveTest
class NullableTypeInWithClauseTest extends PubPackageResolutionTest
    with WithNullSafetyMixin {
  test_class_nonNullable() async {
    await assertNoErrorsInCode('''
class A {}
class B with A {}
''');
  }

  test_class_nullable() async {
    await assertErrorsInCode('''
class A {}
class B with A? {}
''', [
      error(CompileTimeErrorCode.NULLABLE_TYPE_IN_WITH_CLAUSE, 24, 2),
    ]);
  }

  test_classAlias_withClass_nonNullable() async {
    await assertNoErrorsInCode('''
class A {}
class B {}
class C = A with B;
''');
  }

  test_classAlias_withClass_nullable() async {
    await assertErrorsInCode('''
class A {}
class B {}
class C = A with B?;
''', [
      error(CompileTimeErrorCode.NULLABLE_TYPE_IN_WITH_CLAUSE, 39, 2),
    ]);
  }

  test_classAlias_withMixin_nonNullable() async {
    await assertNoErrorsInCode('''
class A {}
mixin B {}
class C = A with B;
''');
  }

  test_classAlias_withMixin_nullable() async {
    await assertErrorsInCode('''
class A {}
mixin B {}
class C = A with B?;
''', [
      error(CompileTimeErrorCode.NULLABLE_TYPE_IN_WITH_CLAUSE, 39, 2),
    ]);
  }
}
