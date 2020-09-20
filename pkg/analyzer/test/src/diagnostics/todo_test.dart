// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TodoTest);
  });
}

@reflectiveTest
class TodoTest extends PubPackageResolutionTest {
  test_todo_multiLineComment() async {
    await assertErrorsInCode(r'''
main() {
  /* TODO: Implement */
  /* TODO: Implement*/
}
''', [
      error(TodoCode.TODO, 14, 15, text: 'TODO: Implement'),
      error(TodoCode.TODO, 38, 15, text: 'TODO: Implement'),
    ]);
  }

  test_todo_singleLineComment() async {
    await assertErrorsInCode(r'''
main() {
  // TODO: Implement
}
''', [
      error(TodoCode.TODO, 14, 15, text: 'TODO: Implement'),
    ]);
  }
}
