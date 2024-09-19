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

    var node = findNode.namedType('G<int>');
    assertResolvedNodeText(node, r'''
NamedType
  name: G
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::<fragment>::@class::int
        element2: dart:core::<fragment>::@class::int#element
        type: int
    rightBracket: >
  element: <testLibraryFragment>::@typeAlias::G
  element2: <testLibraryFragment>::@typeAlias::G#element
  type: int Function()
    alias: <testLibraryFragment>::@typeAlias::G
      typeArguments
        int
''');
  }
}
