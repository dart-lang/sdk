// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NullableTypeInExtendsClauseTest);
  });
}

@reflectiveTest
class NullableTypeInExtendsClauseTest extends PubPackageResolutionTest {
  test_class_nonNullable() async {
    await assertNoErrorsInCode('''
class A {}
class B extends A {}
''');
  }

  test_class_nullable() async {
    await assertErrorsInCode(
      '''
class A {}
class B extends A? {}
''',
      [error(diag.nullableTypeInExtendsClause, 27, 2)],
    );
  }

  test_class_nullable_alias() async {
    await assertErrorsInCode(
      '''
class A {}
typedef B = A;
class C extends B? {}
''',
      [error(diag.nullableTypeInExtendsClause, 42, 2)],
    );
  }

  test_class_nullable_alias2() async {
    await assertErrorsInCode(
      '''
class A {}
typedef B = A?;
class C extends B {}
''',
      [error(diag.nullableTypeInExtendsClause, 43, 1)],
    );
  }

  test_classAlias_withClass_nonNullable() async {
    await assertNoErrorsInCode('''
class A {}
mixin B {}
class C = A with B;
''');
  }

  test_classAlias_withClass_nullable() async {
    await assertErrorsInCode(
      '''
class A {}
mixin B {}
class C = A? with B;
''',
      [error(diag.nullableTypeInExtendsClause, 32, 2)],
    );
  }

  test_classAlias_withClass_nullable_alias() async {
    await assertErrorsInCode(
      '''
class A {}
mixin B {}
typedef C = A;
class D = C? with B;
''',
      [error(diag.nullableTypeInExtendsClause, 47, 2)],
    );
  }

  test_classAlias_withClass_nullable_alias2() async {
    await assertErrorsInCode(
      '''
class A {}
mixin B {}
typedef C = A?;
class D = C with B;
''',
      [error(diag.nullableTypeInExtendsClause, 48, 1)],
    );
  }

  test_classAlias_withMixin_nonNullable() async {
    await assertNoErrorsInCode('''
class A {}
mixin B {}
class C = A with B;
''');
  }

  test_classAlias_withMixin_nullable() async {
    await assertErrorsInCode(
      '''
class A {}
mixin B {}
class C = A? with B;
''',
      [error(diag.nullableTypeInExtendsClause, 32, 2)],
    );
  }

  test_classAlias_withMixin_nullable_alias() async {
    await assertErrorsInCode(
      '''
class A {}
mixin B {}
typedef C = A;
class D = C? with B;
''',
      [error(diag.nullableTypeInExtendsClause, 47, 2)],
    );
  }

  test_classAlias_withMixin_nullable_alias2() async {
    await assertErrorsInCode(
      '''
class A {}
mixin B {}
typedef C = A?;
class D = C with B;
''',
      [error(diag.nullableTypeInExtendsClause, 48, 1)],
    );
  }
}
