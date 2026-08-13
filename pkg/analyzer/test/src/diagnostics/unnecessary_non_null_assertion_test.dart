// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnnecessaryNonNullAssertionTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class UnnecessaryNonNullAssertionTest extends PubPackageResolutionTest {
  test_nonNull_function() async {
    await resolveTestCodeWithDiagnostics('''
void g() {}

void f() {
  g!();
// ^
// [diag.unnecessaryNonNullAssertion] The '!' will have no effect because the receiver can't be null.
}
''');
  }

  test_nonNull_method() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  static void foo() {}
}

void f() {
  A.foo!();
//     ^
// [diag.unnecessaryNonNullAssertion] The '!' will have no effect because the receiver can't be null.
}
''');
  }

  test_nonNull_parameter() async {
    await resolveTestCodeWithDiagnostics('''
f(int x) {
  x!;
// ^
// [diag.unnecessaryNonNullAssertion] The '!' will have no effect because the receiver can't be null.
}
''');
  }

  test_nullable() async {
    await resolveTestCodeWithDiagnostics('''
f(int? x) {
  x!;
}
''');
  }
}
