// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../dart/resolution/node_text_expectations.dart';
import '../elements_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(LibraryElementTest_keepLinking);
    defineReflectiveTests(LibraryElementTest_fromBytes);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

abstract class LibraryElementTest extends ElementsBaseTest {
  test_documentationComment_stars() async {
    var library = await buildLibrary(r'''
/**
 * aaa
 * bbb
 */
library test;''');

    checkElementText(library, r'''
library
  name: test
  nameOffset: 30
  reference: <testLibrary>
  documentationComment: /**\n * aaa\n * bbb\n */
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
----------------------------------------
library
  reference: <testLibrary>
  name: test
  documentationComment: /**\n * aaa\n * bbb\n */
  fragments
    <testLibraryFragment>
      element: <testLibrary>
''');
  }

  test_empty() async {
    var library = await buildLibrary('');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
''');
  }

  test_library() async {
    var library = await buildLibrary('');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
''');
  }

  test_library_documented_lines() async {
    var library = await buildLibrary('''
/// aaa
/// bbb
library test;
''');

    checkElementText(library, r'''
library
  name: test
  nameOffset: 24
  reference: <testLibrary>
  documentationComment: /// aaa\n/// bbb
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
----------------------------------------
library
  reference: <testLibrary>
  name: test
  documentationComment: /// aaa\n/// bbb
  fragments
    <testLibraryFragment>
      element: <testLibrary>
''');
  }

  test_name() async {
    var library = await buildLibrary(r'''
library foo.bar;
''');

    checkElementText(library, r'''
library
  name: foo.bar
  nameOffset: 8
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
----------------------------------------
library
  reference: <testLibrary>
  name: foo.bar
  fragments
    <testLibraryFragment>
      element: <testLibrary>
''');
  }

  test_name_empty() async {
    var library = await buildLibrary(r'''
library;
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
''');
  }

  test_name_withSpaces() async {
    var library = await buildLibrary(r'''
library foo . bar ;
''');

    checkElementText(library, r'''
library
  name: foo.bar
  nameOffset: 8
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
----------------------------------------
library
  reference: <testLibrary>
  name: foo.bar
  fragments
    <testLibraryFragment>
      element: <testLibrary>
''');
  }
}

@reflectiveTest
class LibraryElementTest_fromBytes extends LibraryElementTest {
  @override
  bool get keepLinkingLibraries => false;
}

@reflectiveTest
class LibraryElementTest_keepLinking extends LibraryElementTest {
  @override
  bool get keepLinkingLibraries => true;
}
