// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(YieldInNonGeneratorTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class YieldInNonGeneratorTest extends PubPackageResolutionTest {
  test_async() async {
    await resolveTestCodeWithDiagnostics(r'''
f() async {
  yield 0;
//^^^^^^^^
// [diag.yieldInNonGenerator] Yield statements must be in a generator function (one marked with either 'async*' or 'sync*').
}
''');
  }

  test_asyncStar() async {
    await resolveTestCodeWithDiagnostics(r'''
f() async* {
  yield 0;
}
''');
  }

  @FailingTest(
    reason:
        'We are currently trying to parse the yield statement as a '
        'binary expression.',
  )
  test_sync() async {
    await assertErrorsInCode(
      r'''
f() {
  yield 0;
}
''',
      [error(diag.yieldInNonGenerator, 0, 0)],
    );
  }

  test_syncStar() async {
    await resolveTestCodeWithDiagnostics(r'''
f() sync* {
  yield 0;
}
''');
  }
}
