// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AdjacentStringsResolutionTest);
  });
}

@reflectiveTest
class AdjacentStringsResolutionTest extends PubPackageResolutionTest {
  test_it() async {
    await assertNoErrorsInCode('''
void f() {
  'aaa' 'bbb' 'ccc';
}
''');

    var node = findNode.singleAdjacentStrings;
    assertResolvedNodeText(node, r'''
AdjacentStrings
  strings
    SimpleStringLiteral
      literal: 'aaa'
    SimpleStringLiteral
      literal: 'bbb'
    SimpleStringLiteral
      literal: 'ccc'
  staticType: String
  stringValue: aaabbbccc
''');
  }
}
