// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(EqualElementsInSetTest);
  });
}

@reflectiveTest
class EqualElementsInSetTest extends PubPackageResolutionTest {
  test_constant_constant() async {
    await resolveTestCodeWithDiagnostics(r'''
const a = 1;
const b = 1;
var s = {a, b};
//          ^
// [diag.equalElementsInSet] Two elements in a set literal shouldn't be equal.
''');
  }

  test_literal_constant() async {
    await resolveTestCodeWithDiagnostics(r'''
const one = 1;
var s = {1, one};
//          ^^^
// [diag.equalElementsInSet] Two elements in a set literal shouldn't be equal.
''');
  }

  test_literal_literal() async {
    await resolveTestCodeWithDiagnostics(r'''
var s = {1, 1};
//          ^
// [diag.equalElementsInSet] Two elements in a set literal shouldn't be equal.
''');
  }
}
