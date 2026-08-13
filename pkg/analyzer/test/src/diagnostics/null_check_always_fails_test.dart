// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NullNeverNotNullTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class NullNeverNotNullTest extends PubPackageResolutionTest {
  test_nullable() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(int? i) {
  i!;
}
''');
  }

  test_nullLiteral() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  null!;
//^^^^^
// [diag.nullCheckAlwaysFails] This null-check will always throw an exception because the expression will always evaluate to 'null'.
}
''');
  }

  test_nullLiteral_parenthesized() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  (null)!;
//^^^^^^^
// [diag.nullCheckAlwaysFails] This null-check will always throw an exception because the expression will always evaluate to 'null'.
}
''');
  }

  test_nullType() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  g()!;
//^^^^
// [diag.nullCheckAlwaysFails] This null-check will always throw an exception because the expression will always evaluate to 'null'.
}
Null g() => null;
''');
  }

  test_nullType_awaited() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() async {
  (await g())!;
//^^^^^^^^^^^^
// [diag.nullCheckAlwaysFails] This null-check will always throw an exception because the expression will always evaluate to 'null'.
}
Future<Null> g() async => null;
''');
  }

  test_potentiallyNullableTypeVariable() async {
    await resolveTestCodeWithDiagnostics(r'''
void f<T>(T i) {
  i!;
}
''');
  }
}
