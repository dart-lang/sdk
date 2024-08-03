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
  test_library() async {
    var library = await buildLibrary('');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
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
      enclosingElement: <testLibrary>
''');
  }

  test_library_documented_stars() async {
    var library = await buildLibrary('''
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
      enclosingElement: <testLibrary>
''');
  }

  test_library_name_with_spaces() async {
    var library = await buildLibrary('library foo . bar ;');
    checkElementText(library, r'''
library
  name: foo.bar
  nameOffset: 8
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
''');
  }

  test_library_named() async {
    var library = await buildLibrary('library foo.bar;');
    checkElementText(library, r'''
library
  name: foo.bar
  nameOffset: 8
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
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
