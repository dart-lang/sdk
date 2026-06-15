// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TypeTestWithNonTypeTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class TypeTestWithNonTypeTest extends PubPackageResolutionTest {
  test_parameter() async {
    await resolveTestCodeWithDiagnostics(r'''
var A = 0;
f(p) {
  if (p is A) {
//         ^
// [diag.typeTestWithNonType] The name 'A' isn't a type and can't be used in an 'is' expression.
  }
}
''');
  }
}
