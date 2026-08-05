// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UndefinedClassBooleanTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class UndefinedClassBooleanTest extends PubPackageResolutionTest {
  test_variableDeclaration() async {
    await resolveTestCodeWithDiagnostics('''
f() { boolean v; }
//    ^^^^^^^
// [diag.undefinedClassBoolean] Undefined class 'boolean'.
//            ^
// [diag.unusedLocalVariable] The value of the local variable 'v' isn't used.
''');
  }
}
