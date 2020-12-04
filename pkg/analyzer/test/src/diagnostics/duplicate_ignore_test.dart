// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DuplicateIgnoreTest);
  });
}

@reflectiveTest
class DuplicateIgnoreTest extends PubPackageResolutionTest {
  test_file() async {
    await assertErrorsInCode(r'''
// ignore_for_file: unused_local_variable, unused_local_variable
void f() {
  var x = 0;
}
''', [
      error(HintCode.DUPLICATE_IGNORE, 43, 21),
    ]);
  }

  test_line() async {
    await assertErrorsInCode(r'''
void f() {
  // ignore: unused_local_variable, unused_local_variable
  var x = 0;
}
''', [
      error(HintCode.DUPLICATE_IGNORE, 47, 21),
    ]);
  }

  test_lineAndFile() async {
    await assertErrorsInCode(r'''
// ignore_for_file: unused_local_variable
void f() {
  // ignore: unused_local_variable
  var x = 0;
}
''', [
      error(HintCode.DUPLICATE_IGNORE, 66, 21),
    ]);
  }
}
