// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RedirectToMissingConstructorTest);
  });
}

@reflectiveTest
class RedirectToMissingConstructorTest extends PubPackageResolutionTest {
  test_named() async {
    await assertErrorsInCode(
      '''
class A implements B{
  A() {}
}
class B {
  factory B() = A.name;
}''',
      [error(diag.redirectToMissingConstructor, 59, 6)],
    );
  }

  test_unnamed() async {
    await assertErrorsInCode(
      '''
class A implements B{
  A.name() {}
}
class B {
  factory B() = A;
}''',
      [error(diag.redirectToMissingConstructor, 64, 1)],
    );
  }
}
