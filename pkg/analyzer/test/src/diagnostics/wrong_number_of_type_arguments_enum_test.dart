// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(WrongNumberOfTypeArgumentsEnumTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class WrongNumberOfTypeArgumentsEnumTest extends PubPackageResolutionTest {
  test_tooFew() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E<T, U> {
  v<int>()
// ^^^^^
// [diag.wrongNumberOfTypeArgumentsEnum] The enum is declared with 2 type parameters, but 1 type arguments were given.
}
''');
  }

  test_tooMany() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E<T> {
  v<int, int>()
// ^^^^^^^^^^
// [diag.wrongNumberOfTypeArgumentsEnum] The enum is declared with 1 type parameters, but 2 type arguments were given.
}
''');
  }
}
