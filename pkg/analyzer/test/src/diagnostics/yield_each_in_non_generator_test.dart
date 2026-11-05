// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(YieldEachInNonGeneratorTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class YieldEachInNonGeneratorTest extends PubPackageResolutionTest {
  test_async() async {
    await resolveTestCodeWithDiagnostics(r'''
f() async {
  yield* 0;
//^^^^^^^^^
// [diag.yieldEachInNonGenerator] Yield-each statements must be in a generator function (one marked with either 'async*' or 'sync*').
}
''');
  }

  @FailingTest(
    reason:
        'We are currently trying to parse the yield statement as a '
        'binary expression.',
  ) // TODO(scheglov): review this
  test_sync() async {
    await resolveTestCodeWithDiagnostics(r'''
f() {
  yield* 0;
//^^^^^^^^^
// [diag.yieldEachInNonGenerator] Yield-each statements must be in a generator function (one marked with either 'async*' or 'sync*').
}
''');
  }
}
