// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AwaitInWrongContextTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class AwaitInWrongContextTest extends PubPackageResolutionTest {
  test_sync() async {
    await resolveTestCodeWithDiagnostics(r'''
f(x) {
  return await x;
//       ^^^^^
// [diag.awaitInWrongContext] The await expression can only be used in an async function.
}
''');
  }

  test_syncStar() async {
    await resolveTestCodeWithDiagnostics(r'''
f(x) sync* {
  yield await x;
//      ^^^^^
// [diag.awaitInWrongContext] The await expression can only be used in an async function.
}
''');
  }
}
