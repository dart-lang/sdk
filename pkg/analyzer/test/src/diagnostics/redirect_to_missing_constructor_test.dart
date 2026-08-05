// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RedirectToMissingConstructorTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class RedirectToMissingConstructorTest extends PubPackageResolutionTest {
  test_named() async {
    await resolveTestCodeWithDiagnostics(r'''
class A implements B{
  A() {}
}
class B {
  factory B() = A.name;
//              ^^^^^^
// [diag.redirectToMissingConstructor] The constructor 'A.name' couldn't be found in 'A'.
}''');
  }

  test_unnamed() async {
    await resolveTestCodeWithDiagnostics(r'''
class A implements B{
  A.name() {}
}
class B {
  factory B() = A;
//              ^
// [diag.redirectToMissingConstructor] The constructor 'A' couldn't be found in 'A'.
}''');
  }
}
