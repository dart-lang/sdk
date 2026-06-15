// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RedirectToNonClassTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class RedirectToNonClassTest extends PubPackageResolutionTest {
  test_notAType() async {
    await resolveTestCodeWithDiagnostics(r'''
class B {
  int A = 0;
  factory B() = A;
//              ^
// [diag.redirectToNonClass] The name 'A' isn't a type and can't be used in a redirected constructor.
}''');
  }

  test_undefinedIdentifier() async {
    await resolveTestCodeWithDiagnostics(r'''
class B {
  factory B() = A;
//              ^
// [diag.redirectToNonClass] The name 'A' isn't a type and can't be used in a redirected constructor.
}''');
  }
}
