// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MainHasRequiredNamedParametersTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class MainHasRequiredNamedParametersTest extends PubPackageResolutionTest {
  test_namedOptional() async {
    await resolveTestCodeWithDiagnostics('''
void main({int a = 0}) {}
''');
  }

  test_namedRequired() async {
    await resolveTestCodeWithDiagnostics('''
void main({required List<String> a}) {}
//   ^^^^
// [diag.mainHasRequiredNamedParameters] The function 'main' can't have any required named parameters.
''');
  }
}
