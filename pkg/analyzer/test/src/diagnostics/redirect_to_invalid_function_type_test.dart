// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RedirectToInvalidFunctionTypeTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class RedirectToInvalidFunctionTypeTest extends PubPackageResolutionTest {
  test_redirectToInvalidFunctionType() async {
    await resolveTestCodeWithDiagnostics(r'''
class A implements B {
  A(int p) {}
}
class B {
  factory B() = A;
//              ^
// [diag.redirectToInvalidFunctionType] The redirected constructor 'A Function(int)' has incompatible parameters with 'B Function()'.
}''');
  }

  test_valid_redirect() async {
    await resolveTestCodeWithDiagnostics(r'''
class A implements B {
  A(int p) {}
}
class B {
  factory B(int p) = A;
}
''');
  }
}
