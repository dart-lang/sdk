// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NullableTypeInExtendsClauseTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class NullableTypeInExtendsClauseTest extends PubPackageResolutionTest {
  test_class_nonNullable() async {
    await resolveTestCodeWithDiagnostics('''
class A {}
class B extends A {}
''');
  }

  test_class_nullable() async {
    await resolveTestCodeWithDiagnostics('''
class A {}
class B extends A? {}
//              ^^
// [diag.nullableTypeInExtendsClause] Nullable types can't be extended.
''');
  }

  test_class_nullable_alias() async {
    await resolveTestCodeWithDiagnostics('''
class A {}
typedef B = A;
class C extends B? {}
//              ^^
// [diag.nullableTypeInExtendsClause] Nullable types can't be extended.
''');
  }

  test_class_nullable_alias2() async {
    await resolveTestCodeWithDiagnostics('''
class A {}
typedef B = A?;
class C extends B {}
//              ^
// [diag.nullableTypeInExtendsClause] Nullable types can't be extended.
''');
  }

  test_classAlias_withClass_nonNullable() async {
    await resolveTestCodeWithDiagnostics('''
class A {}
mixin B {}
class C = A with B;
''');
  }

  test_classAlias_withClass_nullable() async {
    await resolveTestCodeWithDiagnostics('''
class A {}
mixin B {}
class C = A? with B;
//        ^^
// [diag.nullableTypeInExtendsClause] Nullable types can't be extended.
''');
  }

  test_classAlias_withClass_nullable_alias() async {
    await resolveTestCodeWithDiagnostics('''
class A {}
mixin B {}
typedef C = A;
class D = C? with B;
//        ^^
// [diag.nullableTypeInExtendsClause] Nullable types can't be extended.
''');
  }

  test_classAlias_withClass_nullable_alias2() async {
    await resolveTestCodeWithDiagnostics('''
class A {}
mixin B {}
typedef C = A?;
class D = C with B;
//        ^
// [diag.nullableTypeInExtendsClause] Nullable types can't be extended.
''');
  }

  test_classAlias_withMixin_nonNullable() async {
    await resolveTestCodeWithDiagnostics('''
class A {}
mixin B {}
class C = A with B;
''');
  }

  test_classAlias_withMixin_nullable() async {
    await resolveTestCodeWithDiagnostics('''
class A {}
mixin B {}
class C = A? with B;
//        ^^
// [diag.nullableTypeInExtendsClause] Nullable types can't be extended.
''');
  }

  test_classAlias_withMixin_nullable_alias() async {
    await resolveTestCodeWithDiagnostics('''
class A {}
mixin B {}
typedef C = A;
class D = C? with B;
//        ^^
// [diag.nullableTypeInExtendsClause] Nullable types can't be extended.
''');
  }

  test_classAlias_withMixin_nullable_alias2() async {
    await resolveTestCodeWithDiagnostics('''
class A {}
mixin B {}
typedef C = A?;
class D = C with B;
//        ^
// [diag.nullableTypeInExtendsClause] Nullable types can't be extended.
''');
  }
}
