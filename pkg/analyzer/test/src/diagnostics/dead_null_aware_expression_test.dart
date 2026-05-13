// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DeadNullAwareExpressionTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class DeadNullAwareExpressionTest extends PubPackageResolutionTest {
  test_assignCompound_map() async {
    await resolveTestCodeWithDiagnostics(r'''
class MyMap<K, V> {
  V? operator[](K key) => null;
  void operator[]=(K key, V value) {}
}

f(MyMap<int, int> map) {
  map[0] ??= 0;
}
''');
  }

  test_assignCompound_nonNullable() async {
    await resolveTestCodeWithDiagnostics(r'''
f(int x) {
  x ??= 0;
//      ^^
// [diag.deadCode] Dead code.
//      ^
// [diag.deadNullAwareExpression] The left operand can't be null, so the right operand is never executed.
}
''');
  }

  test_assignCompound_nullable() async {
    await resolveTestCodeWithDiagnostics(r'''
f(int? x) {
  x ??= 0;
}
''');
  }

  test_binary_nonNullable() async {
    await resolveTestCodeWithDiagnostics(r'''
f(int x) {
  x ?? 0;
//  ^^^^
// [diag.deadCode] Dead code.
//     ^
// [diag.deadNullAwareExpression] The left operand can't be null, so the right operand is never executed.
}
''');
  }

  test_binary_nullable() async {
    await resolveTestCodeWithDiagnostics(r'''
f(int? x) {
  x ?? 0;
}
''');
  }

  test_binary_nullType() async {
    await resolveTestCodeWithDiagnostics(r'''
f(Null x) {
  x ?? 1;
}
''');
  }
}
