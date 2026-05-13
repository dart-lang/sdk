// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstEvalMethodInvocationTest);
  });
}

@reflectiveTest
class ConstEvalMethodInvocationTest extends PubPackageResolutionTest {
  test_function() async {
    await resolveTestCodeWithDiagnostics(r'''
int f() {
  return 3;
}
const a = f();
//        ^^^
// [diag.constEvalMethodInvocation] Methods can't be invoked in constant expressions.
''');
  }

  test_identical() async {
    await resolveTestCodeWithDiagnostics(r'''
const a = identical(1, 1);
''');
  }
}
