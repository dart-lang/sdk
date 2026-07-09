// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ForInWithConstVariableTest);
  });
}

@reflectiveTest
class ForInWithConstVariableTest extends PubPackageResolutionTest {
  test_forEach_loopVariable() async {
    await resolveTestCodeWithDiagnostics(r'''
f() {
  for (const x in [0, 1, 2]) {
//     ^^^^^
// [diag.forInWithConstVariable] A for-in loop variable can't be a 'const'.
    print(x);
  }
}
''');
  }
}
