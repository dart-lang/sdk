// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TypeCheckIsNotNullTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class TypeCheckIsNotNullTest extends PubPackageResolutionTest {
  test_not_Null() async {
    await resolveTestCodeWithDiagnostics(r'''
bool m(i) {
  return i is! Null;
//       ^^^^^^^^^^
// [diag.typeCheckIsNotNull] Tests for non-null should be done with '!= null'.
}
''');
  }
}
