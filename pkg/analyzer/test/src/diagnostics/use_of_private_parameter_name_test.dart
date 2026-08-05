// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UseOfPrivateParameterNameTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class UseOfPrivateParameterNameTest extends PubPackageResolutionTest {
  test_andVoidLhsError() async {
    await resolveTestCodeWithDiagnostics('''
class C {
  int? _x;
//     ^^
// [diag.unusedField] The value of the field '_x' isn't used.
  C({this._x});
}
void f() {
  C(_x: 123);
//  ^^
// [diag.useOfPrivateParameterName] The named parameter '_x' should use the corresponding public name 'x' at the callsite.
}
''');
  }
}
