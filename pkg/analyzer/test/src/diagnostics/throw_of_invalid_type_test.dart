// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ThrowOfInvalidTypeTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class ThrowOfInvalidTypeTest extends PubPackageResolutionTest {
  test_dynamic() async {
    await resolveTestCodeWithDiagnostics(r'''
f(dynamic a) {
  throw a;
}
''');
  }

  test_nonNullable() async {
    await resolveTestCodeWithDiagnostics(r'''
f(int a) {
  throw a;
}
''');
  }

  test_nullable() async {
    await resolveTestCodeWithDiagnostics(r'''
f(int? a) {
  throw a;
//      ^
// [diag.throwOfInvalidType] The type 'int?' of the thrown expression must be assignable to 'Object'.
}
''');
  }
}
