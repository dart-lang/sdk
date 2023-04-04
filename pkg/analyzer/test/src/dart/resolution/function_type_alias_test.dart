// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FunctionTypeAliasResolutionTest);
  });
}

@reflectiveTest
class FunctionTypeAliasResolutionTest extends PubPackageResolutionTest {
  test_type_element() async {
    await resolveTestCode(r'''
G<int> g;

typedef T G<T>();
''');

    final node = findNode.namedType('G<int>');
    assertResolvedNodeText(node, r'''
NamedType
  name: SimpleIdentifier
    token: G
    staticElement: self::@typeAlias::G
    staticType: null
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: SimpleIdentifier
          token: int
          staticElement: dart:core::@class::int
          staticType: null
        type: int
    rightBracket: >
  type: int Function()
    alias: self::@typeAlias::G
      typeArguments
        int
''');
  }
}
