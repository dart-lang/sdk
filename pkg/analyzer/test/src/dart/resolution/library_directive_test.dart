// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(LibraryDirectiveResolutionTest);
  });
}

@reflectiveTest
class LibraryDirectiveResolutionTest extends PubPackageResolutionTest {
  test_inAugmentation() async {
    newFile('$testPackageLibPath/a.dart', r'''
import augment 'b.dart';
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
augment library 'a.dart';
library;
''');

    await resolveFile2(b);
    assertErrorsInResult([
      error(ParserErrorCode.MULTIPLE_LIBRARY_DIRECTIVES, 26, 7),
    ]);

    var node = findNode.singleLibraryDirective;
    assertResolvedNodeText(node, r'''
LibraryDirective
  libraryKeyword: library
  semicolon: ;
  element: <null>
''');
  }

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
        staticType: null
      SimpleIdentifier
        token: bar
        staticElement: <null>
        staticType: null
    staticElement: <null>
    staticType: null
  semicolon: ;
  element: self
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
  element: self
''');
  }
}
