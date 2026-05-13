// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NullableTypeInOnClauseTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class NullableTypeInOnClauseTest extends PubPackageResolutionTest {
  test_nonNullable() async {
    await resolveTestCodeWithDiagnostics('''
class A {}
mixin B on A {}
''');
  }

  test_nullable() async {
    await resolveTestCodeWithDiagnostics('''
class A {}
mixin B on A? {}
//         ^^
// [diag.nullableTypeInOnClause] Nullable types can't be used as a superclass constraint.
''');
  }

  test_nullable_alias() async {
    await resolveTestCodeWithDiagnostics('''
class A {}
typedef B = A;
mixin C on B? {}
//         ^^
// [diag.nullableTypeInOnClause] Nullable types can't be used as a superclass constraint.
''');
  }

  test_nullable_alias2() async {
    await resolveTestCodeWithDiagnostics('''
class A {}
typedef B = A?;
mixin C on B {}
//         ^
// [diag.nullableTypeInOnClause] Nullable types can't be used as a superclass constraint.
''');
  }
}
