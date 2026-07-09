// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UndefinedIdentifierAwaitTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class UndefinedIdentifierAwaitTest extends PubPackageResolutionTest {
  test_function() async {
    await resolveTestCodeWithDiagnostics('''
void a() { await; }
//         ^^^^^
// [diag.undefinedIdentifierAwait] Undefined name 'await' in function body not marked with 'async'.
''');
  }
}
