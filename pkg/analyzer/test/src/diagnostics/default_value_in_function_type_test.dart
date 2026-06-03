// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DefaultValueInFunctionTypeTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class DefaultValueInFunctionTypeTest extends PubPackageResolutionTest {
  test_new_named() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef F = int Function({Map<String, String> m = const {}});
//                                              ^
// [diag.defaultValueInFunctionType] Parameters in a function type can't have default values.
''');
  }

  test_new_named_ambiguous() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef F = int Function({Object m = const {1, 2: 3}});
//                                 ^
// [diag.defaultValueInFunctionType] Parameters in a function type can't have default values.
//                                   ^^^^^^^^^^^^^^^
// [diag.ambiguousSetOrMapLiteralBoth] The literal can't be either a map or a set because it contains at least one literal map entry or a spread operator spreading a 'Map', and at least one element which is neither of these.
''');
  }

  test_new_positional() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef F = int Function([Map<String, String> m = const {}]);
//                                              ^
// [diag.defaultValueInFunctionType] Parameters in a function type can't have default values.
''');
  }

  test_old_named() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef F([x = 0]);
//           ^
// [diag.defaultValueInFunctionType] Parameters in a function type can't have default values.
''');
  }

  test_old_positional() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef F([x = 0]);
//           ^
// [diag.defaultValueInFunctionType] Parameters in a function type can't have default values.
''');
  }

  test_typeArgument_ofInstanceCreation() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A<T> {}

void f() {
  A<void Function([int x = 42])>();
//                       ^
// [diag.defaultValueInFunctionType] Parameters in a function type can't have default values.
}
''');
    assertType(result.findNode.integerLiteral('42'), 'int');
  }
}
