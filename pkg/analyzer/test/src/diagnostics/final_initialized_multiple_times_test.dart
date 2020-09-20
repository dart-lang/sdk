// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FinalInitializedMultipleTimesTest);
  });
}

@reflectiveTest
class FinalInitializedMultipleTimesTest extends PubPackageResolutionTest {
  test_initializingFormals_withDefaultValues() async {
    await assertErrorsInCode(r'''
class A {
  final x;
  A([this.x = 1, this.x = 2]) {}
}
''', [
      error(CompileTimeErrorCode.FINAL_INITIALIZED_MULTIPLE_TIMES, 43, 1),
    ]);
  }

  test_initializingFormals_withoutDefaultValues() async {
    await assertErrorsInCode(r'''
class A {
  final x;
  A(this.x, this.x) {}
}
''', [
      error(CompileTimeErrorCode.FINAL_INITIALIZED_MULTIPLE_TIMES, 38, 1),
    ]);
  }
}
