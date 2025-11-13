// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NonConstantAnnotationConstructorTest);
  });
}

@reflectiveTest
class NonConstantAnnotationConstructorTest extends PubPackageResolutionTest {
  test_named() async {
    await assertErrorsInCode(
      r'''
class A {
  A.fromInt() {}
}
@A.fromInt()
main() {
}
''',
      [error(diag.nonConstantAnnotationConstructor, 29, 12)],
    );
  }

  test_unnamed() async {
    await assertErrorsInCode(
      r'''
class A {
  A() {}
}
@A()
main() {
}
''',
      [error(diag.nonConstantAnnotationConstructor, 21, 4)],
    );
  }
}
