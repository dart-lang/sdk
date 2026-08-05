// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SuperInEnumConstructorTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class SuperInEnumConstructorTest extends PubPackageResolutionTest {
  test_primary_one() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E() {
  v;
  this : super();
//       ^^^^^
// [diag.superInEnumConstructor] The enum constructor can't have a 'super' initializer.
}
''');
  }

  test_typeName_hasRedirect() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  const E.named();
  const E() : this.named(), super();
//                          ^^^^^
// [diag.superInEnumConstructor] The enum constructor can't have a 'super' initializer.
}
''');
  }

  test_typeName_one() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  const E() : super();
//            ^^^^^
// [diag.superInEnumConstructor] The enum constructor can't have a 'super' initializer.
}
''');
  }

  test_typeName_two() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  const E() : super(), super();
//            ^^^^^
// [diag.superInEnumConstructor] The enum constructor can't have a 'super' initializer.
//                     ^^^^^
// [diag.superInEnumConstructor] The enum constructor can't have a 'super' initializer.
}
''');
  }
}
