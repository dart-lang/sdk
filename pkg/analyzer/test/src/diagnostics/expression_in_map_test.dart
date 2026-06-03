// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExpressionInMapTest);
  });
}

@reflectiveTest
class ExpressionInMapTest extends PubPackageResolutionTest {
  test_map() async {
    await resolveTestCodeWithDiagnostics(r'''
var m = <String, int>{'a', 'b' : 2};
//                    ^^^
// [diag.expressionInMap] Expressions can't be used in a map literal.
''');
  }

  test_map_const() async {
    await resolveTestCodeWithDiagnostics(r'''
const m = <String, int>{'a', 'b' : 2};
//                      ^^^
// [diag.expressionInMap] Expressions can't be used in a map literal.
''');
  }
}
