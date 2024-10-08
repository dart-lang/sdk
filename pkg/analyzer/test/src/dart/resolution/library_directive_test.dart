// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(LibraryDirectiveResolutionTest);
  });
}

@reflectiveTest
class LibraryDirectiveResolutionTest extends PubPackageResolutionTest {
  test_named() async {
    await assertNoErrorsInCode(r'''
library foo.bar;
''');

    var node = findNode.singleLibraryDirective;
    assertResolvedNodeText(node, r'''
LibraryDirective
  libraryKeyword: library
  name: LibraryIdentifier
    components
      SimpleIdentifier
        token: foo
        staticElement: <null>
        element: <null>
        staticType: null
      SimpleIdentifier
        token: bar
        staticElement: <null>
        element: <null>
        staticType: null
    staticElement: <null>
    element: <null>
    staticType: null
  semicolon: ;
  element: <testLibrary>
  element2: <testLibrary>
''');
  }

  test_unnamed() async {
    await assertNoErrorsInCode(r'''
library;
''');

    var node = findNode.singleLibraryDirective;
    assertResolvedNodeText(node, r'''
LibraryDirective
  libraryKeyword: library
  semicolon: ;
  element: <testLibrary>
  element2: <testLibrary>
''');
  }
}
