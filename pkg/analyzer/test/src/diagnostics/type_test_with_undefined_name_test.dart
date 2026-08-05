// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TypeTestWithUndefinedNameTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class TypeTestWithUndefinedNameTest extends PubPackageResolutionTest {
  test_undefined() async {
    await resolveTestCodeWithDiagnostics(r'''
f(p) {
  if (p is A) {
//         ^
// [diag.typeTestWithUndefinedName] The name 'A' isn't defined, so it can't be used in an 'is' expression.
  }
}
''');
  }
}
