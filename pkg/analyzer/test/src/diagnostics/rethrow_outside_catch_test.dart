// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RethrowOutsideCatchTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class RethrowOutsideCatchTest extends PubPackageResolutionTest {
  test_insideCatch() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  try {} catch (e) {
    rethrow;
  }
}
''');
  }

  test_insideCatch_insideClosure() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  try {} catch (e) {
    () {
      rethrow;
//    ^^^^^^^
// [diag.rethrowOutsideCatch] A rethrow must be inside of a catch clause.
    };
  }
}
''');
  }

  test_insideCatch_insideClosure_insideCatch() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  try {} catch (e1) {
    () {
      try {} catch (e2) {
        rethrow;
      }
    };
  }
}
''');
  }

  test_withoutCatch() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  rethrow;
//^^^^^^^
// [diag.rethrowOutsideCatch] A rethrow must be inside of a catch clause.
}
''');

    var node = result.findNode.singleRethrowExpression;
    assertResolvedNodeText(node, r'''
RethrowExpression
  rethrowKeyword: rethrow
  staticType: Never
''');
  }
}
