// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NullableTypeInImplementsClauseTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class NullableTypeInImplementsClauseTest extends PubPackageResolutionTest {
  test_class_nonNullable() async {
    await resolveTestCodeWithDiagnostics('''
class A {}
class B implements A {}
''');
  }

  test_class_nullable() async {
    await resolveTestCodeWithDiagnostics('''
class A {}
class B implements A? {}
//                 ^^
// [diag.nullableTypeInImplementsClause] Nullable types can't be implemented.
''');
  }

  test_class_nullable_alias() async {
    await resolveTestCodeWithDiagnostics('''
class A {}
typedef B = A;
class C implements B? {}
//                 ^^
// [diag.nullableTypeInImplementsClause] Nullable types can't be implemented.
''');
  }

  test_class_nullable_alias2() async {
    await resolveTestCodeWithDiagnostics('''
class A {}
typedef B = A?;
class C implements B {}
//                 ^
// [diag.nullableTypeInImplementsClause] Nullable types can't be implemented.
''');
  }

  test_extensionType_nonNullable() async {
    await resolveTestCodeWithDiagnostics('''
class A {}
extension type E(A _) implements A {}
''');
  }

  test_extensionType_nullable() async {
    await resolveTestCodeWithDiagnostics('''
class A {}
extension type E(A _) implements A? {}
//                               ^^
// [diag.nullableTypeInImplementsClause] Nullable types can't be implemented.
''');
  }

  test_extensionType_nullable_alias() async {
    await resolveTestCodeWithDiagnostics('''
class A {}
typedef B = A;
extension type E(A _) implements B? {}
//                               ^^
// [diag.nullableTypeInImplementsClause] Nullable types can't be implemented.
''');
  }

  test_extensionType_nullable_alias2() async {
    await resolveTestCodeWithDiagnostics('''
class A {}
typedef B = A?;
extension type E(A _) implements B {}
//                               ^
// [diag.nullableTypeInImplementsClause] Nullable types can't be implemented.
''');
  }

  test_mixin_nonNullable() async {
    await resolveTestCodeWithDiagnostics('''
class A {}
mixin B implements A {}
''');
  }

  test_mixin_nullable() async {
    await resolveTestCodeWithDiagnostics('''
class A {}
mixin B implements A? {}
//                 ^^
// [diag.nullableTypeInImplementsClause] Nullable types can't be implemented.
''');
  }

  test_mixin_nullable_alias() async {
    await resolveTestCodeWithDiagnostics('''
class A {}
typedef B = A;
mixin C implements B? {}
//                 ^^
// [diag.nullableTypeInImplementsClause] Nullable types can't be implemented.
''');
  }

  test_mixin_nullable_alias2() async {
    await resolveTestCodeWithDiagnostics('''
class A {}
typedef B = A?;
mixin C implements B {}
//                 ^
// [diag.nullableTypeInImplementsClause] Nullable types can't be implemented.
''');
  }
}
