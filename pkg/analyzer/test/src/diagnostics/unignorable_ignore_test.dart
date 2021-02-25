// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnignorableIgnoreTest);
  });
}

@reflectiveTest
class UnignorableIgnoreTest extends PubPackageResolutionTest {
  @failingTest
  test_file() async {
    await assertErrorsInCode(r'''
// ignore_for_file: top_level_cycle
var x = 0;
''', [
      error(HintCode.UNIGNORABLE_IGNORE, 20, 15),
    ]);
  }

  @failingTest
  test_line() async {
    await assertErrorsInCode(r'''
// ignore: top_level_cycle
var x = 0;
''', [
      error(HintCode.UNIGNORABLE_IGNORE, 11, 15),
    ]);
  }
}
