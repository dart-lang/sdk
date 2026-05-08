// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TypeTestWithNonTypeTest);
  });
}

@reflectiveTest
class TypeTestWithNonTypeTest extends PubPackageResolutionTest {
  test_parameter() async {
    await assertErrorsInCode(
      '''
var A = 0;
f(p) {
  if (p is A) {
  }
}''',
      [error(diag.typeTestWithNonType, 29, 1)],
    );
  }
}
