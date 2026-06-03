// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';
import 'node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(LibraryDirectiveResolutionTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class LibraryDirectiveResolutionTest extends PubPackageResolutionTest {
  test_named() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
library foo.bar;
''');

    var node = result.findNode.singleLibraryDirective;
    assertResolvedNodeText(node, r'''
LibraryDirective
  libraryKeyword: library
  name: DottedName
    tokens
      foo
      .
      bar
  semicolon: ;
  element: <testLibrary>
''');
  }

  test_unnamed() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
library;
''');

    var node = result.findNode.singleLibraryDirective;
    assertResolvedNodeText(node, r'''
LibraryDirective
  libraryKeyword: library
  semicolon: ;
  element: <testLibrary>
''');
  }
}
