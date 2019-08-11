// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AmbiguousSetOrMapLiteralBothTest);
    defineReflectiveTests(AmbiguousSetOrMapLiteralEitherTest);
  });
}

@reflectiveTest
class AmbiguousSetOrMapLiteralBothTest extends DriverResolutionTest {
  test_setAndMap() async {
    await assertErrorsInCode('''
Map<int, int> map;
Set<int> set;
var c = {...set, ...map};
''', [
      error(CompileTimeErrorCode.AMBIGUOUS_SET_OR_MAP_LITERAL_BOTH, 41, 16),
    ]);
  }
}

@reflectiveTest
class AmbiguousSetOrMapLiteralEitherTest extends DriverResolutionTest {
  test_invalidPrefixOperator() async {
    // Guard against an exception being thrown.
    await assertErrorsInCode('''
union(a, b) => !{...a, ...b};
''', [
      error(CompileTimeErrorCode.AMBIGUOUS_SET_OR_MAP_LITERAL_EITHER, 16, 12),
    ]);
  }

  test_setAndMap() async {
    await assertErrorsInCode('''
var map;
var set;
var c = {...set, ...map};
''', [
      error(CompileTimeErrorCode.AMBIGUOUS_SET_OR_MAP_LITERAL_EITHER, 26, 16),
    ]);
  }
}
