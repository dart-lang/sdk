// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(LibraryDirectiveResolutionTest_UseDottedName);
    defineReflectiveTests(LibraryDirectiveResolutionTest_NoUseDottedName);
  });
}

abstract class LibraryDirectiveResolutionTest extends PubPackageResolutionTest {
  @override
  Future<void> tearDown() async {
    useDottedNameInLibraryDirective = false;
    await super.tearDown();
  }

  test_named() async {
    await assertNoErrorsInCode(r'''
library foo.bar;
''');

    var node = findNode.singleLibraryDirective;
    if (useDottedNameInLibraryDirective) {
      assertResolvedNodeText(node, r'''
LibraryDirective
  libraryKeyword: library
  name2: DottedName
    tokens
      foo
      .
      bar
  semicolon: ;
  element: <testLibrary>
''');
    } else {
      assertResolvedNodeText(node, r'''
LibraryDirective
  libraryKeyword: library
  name: LibraryIdentifier
    components
      SimpleIdentifier
        token: foo
        element: <null>
        staticType: null
      SimpleIdentifier
        token: bar
        element: <null>
        staticType: null
    element: <null>
    staticType: null
  semicolon: ;
  element: <testLibrary>
''');
    }
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
''');
  }
}

@reflectiveTest
class LibraryDirectiveResolutionTest_NoUseDottedName
    extends LibraryDirectiveResolutionTest {
  @override
  void setUp() {
    super.setUp();
    useDottedNameInLibraryDirective = false;
  }
}

@reflectiveTest
class LibraryDirectiveResolutionTest_UseDottedName
    extends LibraryDirectiveResolutionTest {
  @override
  void setUp() {
    super.setUp();
    useDottedNameInLibraryDirective = true;
  }
}
