// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(VoidWithTypeArgumentsTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class VoidWithTypeArgumentsTest extends PubPackageResolutionTest {
  test_noArguments() async {
    await resolveTestCodeWithDiagnostics('''
void f() {}
''');
  }

  test_withArguments() async {
    var result = await resolveTestCodeWithDiagnostics('''
void<int> f() {}
//  ^
// [diag.voidWithTypeArguments] Type 'void' can't have type arguments.
''');

    var node = result.findNode.namedType('void<int>');
    assertResolvedNodeText(node, r'''
NamedType
  name: void
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  element: <null>
  type: void
''');
  }
}
