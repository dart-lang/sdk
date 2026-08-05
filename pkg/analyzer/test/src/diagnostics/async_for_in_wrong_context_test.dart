// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AsyncForInWrongContextTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class AsyncForInWrongContextTest extends PubPackageResolutionTest {
  test_syncFunction() async {
    await resolveTestCodeWithDiagnostics(r'''
f(list) {
  await for (var e in list) {
//^^^^^
// [diag.asyncForInWrongContext] The async for-in loop can only be used in an async function.
//               ^
// [diag.unusedLocalVariable] The value of the local variable 'e' isn't used.
  }
}
''');
  }
}
