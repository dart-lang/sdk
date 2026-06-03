// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';
import 'node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AdjacentStringsResolutionTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class AdjacentStringsResolutionTest extends PubPackageResolutionTest {
  test_it() async {
    var result = await resolveTestCodeWithDiagnostics('''
void f() {
  'aaa' 'bbb' 'ccc';
}
''');

    var node = result.findNode.singleAdjacentStrings;
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
