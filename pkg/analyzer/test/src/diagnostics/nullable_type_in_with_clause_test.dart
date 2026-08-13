// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NullableTypeInWithClauseTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class NullableTypeInWithClauseTest extends PubPackageResolutionTest {
  test_class_nonNullable() async {
    await resolveTestCodeWithDiagnostics('''
mixin A {}
class B with A {}
''');
  }

  test_class_nullable() async {
    await resolveTestCodeWithDiagnostics('''
mixin A {}
class B with A? {}
//           ^^
// [diag.nullableTypeInWithClause] Nullable types can't be mixed in.
''');
  }

  test_class_nullable_alias() async {
    await resolveTestCodeWithDiagnostics('''
mixin A {}
typedef B = A;
class C with B? {}
//           ^^
// [diag.nullableTypeInWithClause] Nullable types can't be mixed in.
''');
  }

  test_class_nullable_alias2() async {
    await resolveTestCodeWithDiagnostics('''
mixin A {}
typedef B = A?;
class C with B {}
//           ^
// [diag.nullableTypeInWithClause] Nullable types can't be mixed in.
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
class C = A with B?;
//               ^^
// [diag.nullableTypeInWithClause] Nullable types can't be mixed in.
''');
  }

  test_classAlias_withClass_nullable_alias() async {
    await resolveTestCodeWithDiagnostics('''
class A {}
mixin B {}
typedef C = B;
class D = A with C?;
//               ^^
// [diag.nullableTypeInWithClause] Nullable types can't be mixed in.
''');
  }

  test_classAlias_withClass_nullable_alias2() async {
    await resolveTestCodeWithDiagnostics('''
class A {}
mixin B {}
typedef C = B?;
class D = A with C;
//               ^
// [diag.nullableTypeInWithClause] Nullable types can't be mixed in.
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
class C = A with B?;
//               ^^
// [diag.nullableTypeInWithClause] Nullable types can't be mixed in.
''');
  }

  test_classAlias_withMixin_nullable_alias() async {
    await resolveTestCodeWithDiagnostics('''
class A {}
mixin B {}
typedef C = B;
class D = A with C?;
//               ^^
// [diag.nullableTypeInWithClause] Nullable types can't be mixed in.
''');
  }

  test_classAlias_withMixin_nullable_alias2() async {
    await resolveTestCodeWithDiagnostics('''
class A {}
mixin B {}
typedef C = B?;
class D = A with C;
//               ^
// [diag.nullableTypeInWithClause] Nullable types can't be mixed in.
''');
  }
}
