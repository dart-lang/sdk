// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RedirectToInvalidReturnTypeTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class RedirectToInvalidReturnTypeTest extends PubPackageResolutionTest {
  test_redirectToInvalidReturnType() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A() {}
}
class B {
  factory B() = A;
//              ^
// [diag.redirectToInvalidReturnType] The return type 'A' of the redirected constructor isn't a subtype of 'B'.
}''');
  }
}
