// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/scope.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/utilities/extensions/string.dart';
import 'package:analyzer_utilities/testing/tree_string_sink.dart';
import 'package:collection/collection.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../util/element_printer.dart';
import '../../dart/resolution/node_text_expectations.dart';
import '../elements_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(LibraryFragmentElementTest_keepLinking);
    defineReflectiveTests(LibraryFragmentElementTest_fromBytes);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

abstract class LibraryFragmentElementTest extends ElementsBaseTest {
  test_libraryExports() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
export 'dart:math';
''');

    var library = await buildLibrary(r'''
export 'dart:io';
part 'a.dart';
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryExports
    dart:io
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  parts
    part_0
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryExports
        dart:io
          enclosingElement3: <testLibraryFragment>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      libraryExports
        dart:math
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
''');
  }

  test_libraryExports_metadata() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
@deprecated
export 'dart:math';
''');

    var library = await buildLibrary(r'''
part 'a.dart';
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  parts
    part_0
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      libraryExports
        dart:math
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          metadata
            Annotation
              atSign: @ @21
              name: SimpleIdentifier
                token: deprecated @22
                staticElement: dart:core::<fragment>::@getter::deprecated
                element: dart:core::<fragment>::@getter::deprecated#element
                staticType: null
              element: dart:core::<fragment>::@getter::deprecated
              element2: dart:core::<fragment>::@getter::deprecated#element
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
''');
  }

  test_libraryImports() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
import 'dart:math';
''');

    var library = await buildLibrary(r'''
import 'dart:io';
part 'a.dart';
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    dart:io
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  parts
    part_0
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        dart:io
          enclosingElement3: <testLibraryFragment>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      libraryImports
        dart:math
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      libraryImports
        dart:io
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      libraryImports
        dart:math
''');
  }

  test_libraryImports_metadata() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
@deprecated
import 'dart:math';
''');

    var library = await buildLibrary(r'''
part 'a.dart';
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  parts
    part_0
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      libraryImports
        dart:math
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          metadata
            Annotation
              atSign: @ @21
              name: SimpleIdentifier
                token: deprecated @22
                staticElement: dart:core::<fragment>::@getter::deprecated
                element: dart:core::<fragment>::@getter::deprecated#element
                staticType: null
              element: dart:core::<fragment>::@getter::deprecated
              element2: dart:core::<fragment>::@getter::deprecated#element
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      libraryImports
        dart:math
          metadata
            Annotation
              atSign: @ @21
              name: SimpleIdentifier
                token: deprecated @22
                staticElement: dart:core::<fragment>::@getter::deprecated
                element: dart:core::<fragment>::@getter::deprecated#element
                staticType: null
              element: dart:core::<fragment>::@getter::deprecated
              element2: dart:core::<fragment>::@getter::deprecated#element
''');
  }

  test_scope_accessibleExtensions_imported() async {
    newFile('$testPackageLibPath/x.dart', r'''
extension X on int {}
''');

    newFile('$testPackageLibPath/y.dart', r'''
extension Y on int {}
''');

    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
import 'y.dart';
part 'aa.dart';
''');

    newFile('$testPackageLibPath/aa.dart', r'''
part of 'a.dart';
''');

    newFile('$testPackageLibPath/b.dart', r'''
part of 'test.dart';
''');

    var library = await buildLibrary(r'''
import 'x.dart';
part 'a.dart';
part 'b.dart';
''');

    _assertScopeLookups(withAccessibleExtensions: true, library, [
      Uri.parse('package:test/test.dart'),
      Uri.parse('package:test/a.dart'),
      Uri.parse('package:test/aa.dart'),
      Uri.parse('package:test/b.dart'),
    ], [], r'''
package:test/test.dart
  accessibleExtensions
    dart:core::<fragment>::@extension::EnumName
    package:test/x.dart::<fragment>::@extension::X
package:test/a.dart
  accessibleExtensions
    dart:core::<fragment>::@extension::EnumName
    package:test/x.dart::<fragment>::@extension::X
    package:test/y.dart::<fragment>::@extension::Y
package:test/aa.dart
  accessibleExtensions
    dart:core::<fragment>::@extension::EnumName
    package:test/x.dart::<fragment>::@extension::X
    package:test/y.dart::<fragment>::@extension::Y
package:test/b.dart
  accessibleExtensions
    dart:core::<fragment>::@extension::EnumName
    package:test/x.dart::<fragment>::@extension::X
''');
  }

  test_scope_accessibleExtensions_imported_withPrefix() async {
    newFile('$testPackageLibPath/x.dart', r'''
extension X on int {}
''');

    newFile('$testPackageLibPath/y.dart', r'''
extension Y on int {}
''');

    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
import 'y.dart' as y;
part 'aa.dart';
''');

    newFile('$testPackageLibPath/aa.dart', r'''
part of 'a.dart';
''');

    newFile('$testPackageLibPath/b.dart', r'''
part of 'test.dart';
''');

    var library = await buildLibrary(r'''
import 'x.dart' as x;
part 'a.dart';
part 'b.dart';
''');

    _assertScopeLookups(withAccessibleExtensions: true, library, [
      Uri.parse('package:test/test.dart'),
      Uri.parse('package:test/a.dart'),
      Uri.parse('package:test/aa.dart'),
      Uri.parse('package:test/b.dart'),
    ], [], r'''
package:test/test.dart
  accessibleExtensions
    dart:core::<fragment>::@extension::EnumName
    package:test/x.dart::<fragment>::@extension::X
package:test/a.dart
  accessibleExtensions
    dart:core::<fragment>::@extension::EnumName
    package:test/x.dart::<fragment>::@extension::X
    package:test/y.dart::<fragment>::@extension::Y
package:test/aa.dart
  accessibleExtensions
    dart:core::<fragment>::@extension::EnumName
    package:test/x.dart::<fragment>::@extension::X
    package:test/y.dart::<fragment>::@extension::Y
package:test/b.dart
  accessibleExtensions
    dart:core::<fragment>::@extension::EnumName
    package:test/x.dart::<fragment>::@extension::X
''');
  }

  test_scope_accessibleExtensions_local() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
part 'aa.dart';
extension A on int {}
''');

    newFile('$testPackageLibPath/aa.dart', r'''
part of 'a.dart';
extension B on int {}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
extension Z on int {}
''');

    _assertScopeLookups(withAccessibleExtensions: true, library, [
      Uri.parse('package:test/test.dart'),
      Uri.parse('package:test/a.dart'),
      Uri.parse('package:test/aa.dart'),
    ], [], r'''
package:test/test.dart
  accessibleExtensions
    <testLibrary>::@fragment::package:test/a.dart::@extension::A
    <testLibrary>::@fragment::package:test/aa.dart::@extension::B
    dart:core::<fragment>::@extension::EnumName
    <testLibraryFragment>::@extension::Z
package:test/a.dart
  accessibleExtensions
    <testLibrary>::@fragment::package:test/a.dart::@extension::A
    <testLibrary>::@fragment::package:test/aa.dart::@extension::B
    dart:core::<fragment>::@extension::EnumName
    <testLibraryFragment>::@extension::Z
package:test/aa.dart
  accessibleExtensions
    <testLibrary>::@fragment::package:test/a.dart::@extension::A
    <testLibrary>::@fragment::package:test/aa.dart::@extension::B
    dart:core::<fragment>::@extension::EnumName
    <testLibraryFragment>::@extension::Z
''');
  }

  test_scope_accessibleExtensions_unnamed() async {
    var library = await buildLibrary(r'''
part 'a.dart';
extension on int {}
''');

    _assertScopeLookups(withAccessibleExtensions: true, library, [
      Uri.parse('package:test/test.dart'),
    ], [
      ''
    ], r'''
package:test/test.dart
  <empty>
    getter: <null>
  accessibleExtensions
    <testLibraryFragment>::@extension::0
    dart:core::<fragment>::@extension::EnumName
''');
  }

  test_scope_hasPrefix() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
''');

    var library = await buildLibrary(r'''
import 'dart:io' as prefix;
part 'a.dart';
''');

    _assertScopeLookups(library, [
      Uri.parse('package:test/test.dart'),
      Uri.parse('package:test/a.dart'),
    ], [
      'prefix.exitCode',
    ], r'''
package:test/test.dart
  prefix.exitCode
    prefix: <testLibraryFragment>::@prefix::prefix
    getter: dart:io::<fragment>::@getter::exitCode
    setter: dart:io::<fragment>::@setter::exitCode
package:test/a.dart
  prefix.exitCode
    prefix: <testLibraryFragment>::@prefix::prefix
    getter: dart:io::<fragment>::@getter::exitCode
    setter: dart:io::<fragment>::@setter::exitCode
''');
  }

  test_scope_hasPrefix_append() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
import 'dart:math' as prefix;
part 'aa.dart';
''');

    newFile('$testPackageLibPath/aa.dart', r'''
part of 'a.dart';
part 'aaa.dart';
''');

    newFile('$testPackageLibPath/aaa.dart', r'''
part of 'aa.dart';
''');

    var library = await buildLibrary(r'''
import 'dart:io' as prefix;
part 'a.dart';
''');

    _assertScopeLookups(library, [
      Uri.parse('package:test/test.dart'),
      Uri.parse('package:test/a.dart'),
      Uri.parse('package:test/aa.dart'),
      Uri.parse('package:test/aaa.dart'),
    ], [
      'prefix.File',
      'prefix.Random',
    ], r'''
package:test/test.dart
  prefix.File
    prefix: <testLibraryFragment>::@prefix::prefix
    getter: dart:io::<fragment>::@class::File
  prefix.Random
    prefix: <testLibraryFragment>::@prefix::prefix
    getter: <null>
package:test/a.dart
  prefix.File
    prefix: <testLibrary>::@fragment::package:test/a.dart::@prefix::prefix
    getter: dart:io::<fragment>::@class::File
  prefix.Random
    prefix: <testLibrary>::@fragment::package:test/a.dart::@prefix::prefix
    getter: dart:math::<fragment>::@class::Random
package:test/aa.dart
  prefix.File
    prefix: <testLibrary>::@fragment::package:test/a.dart::@prefix::prefix
    getter: dart:io::<fragment>::@class::File
  prefix.Random
    prefix: <testLibrary>::@fragment::package:test/a.dart::@prefix::prefix
    getter: dart:math::<fragment>::@class::Random
package:test/aaa.dart
  prefix.File
    prefix: <testLibrary>::@fragment::package:test/a.dart::@prefix::prefix
    getter: dart:io::<fragment>::@class::File
  prefix.Random
    prefix: <testLibrary>::@fragment::package:test/a.dart::@prefix::prefix
    getter: dart:math::<fragment>::@class::Random
''');
  }

  test_scope_hasPrefix_append_skipFile() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
part 'aa.dart';
''');

    newFile('$testPackageLibPath/aa.dart', r'''
part of 'a.dart';
import 'dart:math' as prefix;
''');

    var library = await buildLibrary(r'''
import 'dart:io' as prefix;
part 'a.dart';
''');

    _assertScopeLookups(library, [
      Uri.parse('package:test/test.dart'),
      Uri.parse('package:test/a.dart'),
      Uri.parse('package:test/aa.dart'),
    ], [
      'prefix.File',
      'prefix.Random',
    ], r'''
package:test/test.dart
  prefix.File
    prefix: <testLibraryFragment>::@prefix::prefix
    getter: dart:io::<fragment>::@class::File
  prefix.Random
    prefix: <testLibraryFragment>::@prefix::prefix
    getter: <null>
package:test/a.dart
  prefix.File
    prefix: <testLibraryFragment>::@prefix::prefix
    getter: dart:io::<fragment>::@class::File
  prefix.Random
    prefix: <testLibraryFragment>::@prefix::prefix
    getter: <null>
package:test/aa.dart
  prefix.File
    prefix: <testLibrary>::@fragment::package:test/aa.dart::@prefix::prefix
    getter: dart:io::<fragment>::@class::File
  prefix.Random
    prefix: <testLibrary>::@fragment::package:test/aa.dart::@prefix::prefix
    getter: dart:math::<fragment>::@class::Random
''');
  }

  test_scope_hasPrefix_deferred() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
import 'dart:math' deferred as prefix;
part 'aa.dart';
''');

    newFile('$testPackageLibPath/aa.dart', r'''
part of 'a.dart';
import 'dart:math' deferred as prefix;
''');

    var library = await buildLibrary(r'''
import 'dart:io' deferred as prefix;
part 'a.dart';
''');

    _assertScopeLookups(library, [
      Uri.parse('package:test/test.dart'),
      Uri.parse('package:test/a.dart'),
      Uri.parse('package:test/aa.dart'),
    ], [
      'loadLibrary',
      'prefix.File',
      'prefix.Random',
    ], r'''
package:test/test.dart
  loadLibrary
    getter: <null>
  prefix.File
    prefix: <testLibraryFragment>::@prefix::prefix
    getter: dart:io::<fragment>::@class::File
  prefix.Random
    prefix: <testLibraryFragment>::@prefix::prefix
    getter: <null>
package:test/a.dart
  loadLibrary
    getter: <null>
  prefix.File
    prefix: <testLibrary>::@fragment::package:test/a.dart::@prefix::prefix
    getter: <null>
  prefix.Random
    prefix: <testLibrary>::@fragment::package:test/a.dart::@prefix::prefix
    getter: dart:math::<fragment>::@class::Random
package:test/aa.dart
  loadLibrary
    getter: <null>
  prefix.File
    prefix: <testLibrary>::@fragment::package:test/aa.dart::@prefix::prefix
    getter: <null>
  prefix.Random
    prefix: <testLibrary>::@fragment::package:test/aa.dart::@prefix::prefix
    getter: dart:math::<fragment>::@class::Random
''');
  }

  test_scope_hasPrefix_shadow() async {
    newFile('$testPackageLibPath/x.dart', r'''
class Directory {}
''');

    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
import 'x.dart' as prefix;
part 'aa.dart';
''');

    newFile('$testPackageLibPath/aa.dart', r'''
part of 'a.dart';
part 'aaa.dart';
''');

    var library = await buildLibrary(r'''
import 'dart:io' as prefix;
part 'a.dart';
''');

    _assertScopeLookups(library, [
      Uri.parse('package:test/test.dart'),
      Uri.parse('package:test/a.dart'),
      Uri.parse('package:test/aa.dart'),
    ], [
      'prefix.File',
      'prefix.Directory',
    ], r'''
package:test/test.dart
  prefix.File
    prefix: <testLibraryFragment>::@prefix::prefix
    getter: dart:io::<fragment>::@class::File
  prefix.Directory
    prefix: <testLibraryFragment>::@prefix::prefix
    getter: dart:io::<fragment>::@class::Directory
package:test/a.dart
  prefix.File
    prefix: <testLibrary>::@fragment::package:test/a.dart::@prefix::prefix
    getter: dart:io::<fragment>::@class::File
  prefix.Directory
    prefix: <testLibrary>::@fragment::package:test/a.dart::@prefix::prefix
    getter: package:test/x.dart::<fragment>::@class::Directory
package:test/aa.dart
  prefix.File
    prefix: <testLibrary>::@fragment::package:test/a.dart::@prefix::prefix
    getter: dart:io::<fragment>::@class::File
  prefix.Directory
    prefix: <testLibrary>::@fragment::package:test/a.dart::@prefix::prefix
    getter: package:test/x.dart::<fragment>::@class::Directory
''');
  }

  test_scope_localShadowsPrefix() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
void foo() {}
''');

    newFile('$testPackageLibPath/b.dart', r'''
part of 'test.dart';
''');

    var library = await buildLibrary(r'''
import 'dart:io' as foo;
part 'a.dart';
part 'b.dart';
''');

    _assertScopeLookups(library, [
      Uri.parse('package:test/test.dart'),
      Uri.parse('package:test/a.dart'),
      Uri.parse('package:test/b.dart'),
    ], [
      'foo'
    ], r'''
package:test/test.dart
  foo
    getter: <testLibrary>::@fragment::package:test/a.dart::@function::foo
package:test/a.dart
  foo
    getter: <testLibrary>::@fragment::package:test/a.dart::@function::foo
package:test/b.dart
  foo
    getter: <testLibrary>::@fragment::package:test/a.dart::@function::foo
''');
  }

  test_scope_noPrefix_combinators_hide() async {
    newFile('$testPackageLibPath/x.dart', r'''
class A {}
class B {}
class C {}
class D {}
''');

    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
''');

    var library = await buildLibrary(r'''
import 'x.dart' hide A, C;
part 'a.dart';
''');

    _assertScopeLookups(library, [
      Uri.parse('package:test/test.dart'),
      Uri.parse('package:test/a.dart'),
    ], [
      'A',
      'B',
      'C',
      'D',
    ], r'''
package:test/test.dart
  A
    getter: <null>
  B
    getter: package:test/x.dart::<fragment>::@class::B
  C
    getter: <null>
  D
    getter: package:test/x.dart::<fragment>::@class::D
package:test/a.dart
  A
    getter: <null>
  B
    getter: package:test/x.dart::<fragment>::@class::B
  C
    getter: <null>
  D
    getter: package:test/x.dart::<fragment>::@class::D
''');
  }

  test_scope_noPrefix_combinators_hide_show() async {
    newFile('$testPackageLibPath/x.dart', r'''
class A {}
class B {}
class C {}
class D {}
''');

    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
''');

    var library = await buildLibrary(r'''
import 'x.dart' hide A, C show B;
part 'a.dart';
''');

    _assertScopeLookups(library, [
      Uri.parse('package:test/test.dart'),
      Uri.parse('package:test/a.dart'),
    ], [
      'A',
      'B',
      'C',
      'D',
    ], r'''
package:test/test.dart
  A
    getter: <null>
  B
    getter: package:test/x.dart::<fragment>::@class::B
  C
    getter: <null>
  D
    getter: <null>
package:test/a.dart
  A
    getter: <null>
  B
    getter: package:test/x.dart::<fragment>::@class::B
  C
    getter: <null>
  D
    getter: <null>
''');
  }

  test_scope_noPrefix_combinators_show() async {
    newFile('$testPackageLibPath/x.dart', r'''
class A {}
class B {}
class C {}
class D {}
''');

    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
''');

    var library = await buildLibrary(r'''
import 'x.dart' show A, C;
part 'a.dart';
''');

    _assertScopeLookups(library, [
      Uri.parse('package:test/test.dart'),
      Uri.parse('package:test/a.dart'),
    ], [
      'A',
      'B',
      'C',
      'D',
    ], r'''
package:test/test.dart
  A
    getter: package:test/x.dart::<fragment>::@class::A
  B
    getter: <null>
  C
    getter: package:test/x.dart::<fragment>::@class::C
  D
    getter: <null>
package:test/a.dart
  A
    getter: package:test/x.dart::<fragment>::@class::A
  B
    getter: <null>
  C
    getter: package:test/x.dart::<fragment>::@class::C
  D
    getter: <null>
''');
  }

  test_scope_noPrefix_combinators_show_gide() async {
    newFile('$testPackageLibPath/x.dart', r'''
class A {}
class B {}
class C {}
class D {}
''');

    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
''');

    var library = await buildLibrary(r'''
import 'x.dart' show A, C hide B, C;
part 'a.dart';
''');

    _assertScopeLookups(library, [
      Uri.parse('package:test/test.dart'),
      Uri.parse('package:test/a.dart'),
    ], [
      'A',
      'B',
      'C',
      'D',
    ], r'''
package:test/test.dart
  A
    getter: package:test/x.dart::<fragment>::@class::A
  B
    getter: <null>
  C
    getter: <null>
  D
    getter: <null>
package:test/a.dart
  A
    getter: package:test/x.dart::<fragment>::@class::A
  B
    getter: <null>
  C
    getter: <null>
  D
    getter: <null>
''');
  }

  test_scope_noPrefix_fragmentImportShadowsParent() async {
    newFile('$testPackageLibPath/x.dart', r'''
int get exitCode => 0;
''');

    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
import 'x.dart';
part 'aa.dart';
''');

    newFile('$testPackageLibPath/aa.dart', r'''
part of 'a.dart';
''');

    newFile('$testPackageLibPath/b.dart', r'''
part of 'test.dart';
''');

    var library = await buildLibrary(r'''
import 'dart:io';
part 'a.dart';
part 'b.dart';
''');

    _assertScopeLookups(library, [
      Uri.parse('package:test/test.dart'),
      Uri.parse('package:test/a.dart'),
      Uri.parse('package:test/aa.dart'),
      Uri.parse('package:test/b.dart'),
    ], [
      'exitCode',
    ], r'''
package:test/test.dart
  exitCode
    getter: dart:io::<fragment>::@getter::exitCode
    setter: dart:io::<fragment>::@setter::exitCode
package:test/a.dart
  exitCode
    getter: package:test/x.dart::<fragment>::@getter::exitCode
package:test/aa.dart
  exitCode
    getter: package:test/x.dart::<fragment>::@getter::exitCode
package:test/b.dart
  exitCode
    getter: dart:io::<fragment>::@getter::exitCode
    setter: dart:io::<fragment>::@setter::exitCode
''');
  }

  test_scope_noPrefix_implicitDartCore() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
''');

    var library = await buildLibrary(r'''
part 'a.dart';
''');

    _assertScopeLookups(library, [
      Uri.parse('package:test/test.dart'),
      Uri.parse('package:test/a.dart'),
    ], [
      'Object',
    ], r'''
package:test/test.dart
  Object
    getter: dart:core::<fragment>::@class::Object
package:test/a.dart
  Object
    getter: dart:core::<fragment>::@class::Object
''');
  }

  test_scope_noPrefix_inheritsFromParentFragment_fromDefining() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
''');

    var library = await buildLibrary(r'''
import 'dart:io';
part 'a.dart';
''');

    _assertScopeLookups(library, [
      Uri.parse('package:test/test.dart'),
      Uri.parse('package:test/a.dart'),
    ], [
      'exit',
      'exitCode',
    ], r'''
package:test/test.dart
  exit
    getter: dart:io::<fragment>::@function::exit
  exitCode
    getter: dart:io::<fragment>::@getter::exitCode
    setter: dart:io::<fragment>::@setter::exitCode
package:test/a.dart
  exit
    getter: dart:io::<fragment>::@function::exit
  exitCode
    getter: dart:io::<fragment>::@getter::exitCode
    setter: dart:io::<fragment>::@setter::exitCode
''');
  }

  test_scope_noPrefix_inheritsFromParentFragment_fromPart() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
import 'dart:io';
part 'aa.dart';
''');

    newFile('$testPackageLibPath/aa.dart', r'''
part of 'a.dart';
''');

    newFile('$testPackageLibPath/b.dart', r'''
part of 'test.dart';
''');

    var library = await buildLibrary(r'''
part 'a.dart';
part 'b.dart';
''');

    _assertScopeLookups(library, [
      Uri.parse('package:test/test.dart'),
      Uri.parse('package:test/a.dart'),
      Uri.parse('package:test/aa.dart'),
      Uri.parse('package:test/b.dart'),
    ], [
      'exitCode',
    ], r'''
package:test/test.dart
  exitCode
    getter: <null>
package:test/a.dart
  exitCode
    getter: dart:io::<fragment>::@getter::exitCode
    setter: dart:io::<fragment>::@setter::exitCode
package:test/aa.dart
  exitCode
    getter: dart:io::<fragment>::@getter::exitCode
    setter: dart:io::<fragment>::@setter::exitCode
package:test/b.dart
  exitCode
    getter: <null>
''');
  }

  test_scope_noPrefix_localShadowsImported_getter() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
int get exitCode => 0;
''');

    newFile('$testPackageLibPath/b.dart', r'''
part of 'test.dart';
''');

    var library = await buildLibrary(r'''
import 'dart:io';
part 'a.dart';
part 'b.dart';
''');

    _assertScopeLookups(library, [
      Uri.parse('package:test/test.dart'),
      Uri.parse('package:test/a.dart'),
      Uri.parse('package:test/b.dart'),
    ], [
      'exitCode',
    ], r'''
package:test/test.dart
  exitCode
    getter: <testLibrary>::@fragment::package:test/a.dart::@getter::exitCode
package:test/a.dart
  exitCode
    getter: <testLibrary>::@fragment::package:test/a.dart::@getter::exitCode
package:test/b.dart
  exitCode
    getter: <testLibrary>::@fragment::package:test/a.dart::@getter::exitCode
''');
  }

  test_scope_noPrefix_localShadowsImported_setter() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
set exitCode(int _) {}
''');

    newFile('$testPackageLibPath/b.dart', r'''
part of 'test.dart';
''');

    var library = await buildLibrary(r'''
import 'dart:io';
part 'a.dart';
part 'b.dart';
''');

    _assertScopeLookups(library, [
      Uri.parse('package:test/test.dart'),
      Uri.parse('package:test/a.dart'),
      Uri.parse('package:test/b.dart'),
    ], [
      'exitCode',
    ], r'''
package:test/test.dart
  exitCode
    getter: <null>
    setter: <testLibrary>::@fragment::package:test/a.dart::@setter::exitCode
package:test/a.dart
  exitCode
    getter: <null>
    setter: <testLibrary>::@fragment::package:test/a.dart::@setter::exitCode
package:test/b.dart
  exitCode
    getter: <null>
    setter: <testLibrary>::@fragment::package:test/a.dart::@setter::exitCode
''');
  }

  test_scope_noPrefix_localsOfFragments() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
part 'aa.dart';
class A {}
''');

    newFile('$testPackageLibPath/aa.dart', r'''
part of 'a.dart';
class B {}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
class Z {}
''');

    _assertScopeLookups(library, [
      Uri.parse('package:test/test.dart'),
      Uri.parse('package:test/a.dart'),
      Uri.parse('package:test/aa.dart'),
    ], [
      'A',
      'B',
      'Z',
    ], r'''
package:test/test.dart
  A
    getter: <testLibrary>::@fragment::package:test/a.dart::@class::A
  B
    getter: <testLibrary>::@fragment::package:test/aa.dart::@class::B
  Z
    getter: <testLibraryFragment>::@class::Z
package:test/a.dart
  A
    getter: <testLibrary>::@fragment::package:test/a.dart::@class::A
  B
    getter: <testLibrary>::@fragment::package:test/aa.dart::@class::B
  Z
    getter: <testLibraryFragment>::@class::Z
package:test/aa.dart
  A
    getter: <testLibrary>::@fragment::package:test/a.dart::@class::A
  B
    getter: <testLibrary>::@fragment::package:test/aa.dart::@class::B
  Z
    getter: <testLibraryFragment>::@class::Z
''');
  }

  test_scope_noPrefix_localsOfFragments_private() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
class _A {}
set _foo(int _) {}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
class _Z {}
''');

    _assertScopeLookups(library, [
      Uri.parse('package:test/test.dart'),
      Uri.parse('package:test/a.dart'),
    ], [
      '_A',
      '_Z',
      '_foo',
    ], r'''
package:test/test.dart
  _A
    getter: <testLibrary>::@fragment::package:test/a.dart::@class::_A
  _Z
    getter: <testLibraryFragment>::@class::_Z
  _foo
    getter: <null>
    setter: <testLibrary>::@fragment::package:test/a.dart::@setter::_foo
package:test/a.dart
  _A
    getter: <testLibrary>::@fragment::package:test/a.dart::@class::_A
  _Z
    getter: <testLibraryFragment>::@class::_Z
  _foo
    getter: <null>
    setter: <testLibrary>::@fragment::package:test/a.dart::@setter::_foo
''');
  }

  test_scope_wildcardName_class() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
class _ {}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
''');

    _assertScopeLookups(library, [
      Uri.parse('package:test/test.dart'),
      Uri.parse('package:test/a.dart'),
    ], [
      '_'
    ], r'''
package:test/test.dart
  _
    getter: <testLibrary>::@fragment::package:test/a.dart::@class::_
package:test/a.dart
  _
    getter: <testLibrary>::@fragment::package:test/a.dart::@class::_
''');
  }

  test_scope_wildcardName_importPrefix() async {
    newFile('$testPackageLibPath/x.dart', r'''
extension X on int {}
''');

    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
''');

    var library = await buildLibrary(r'''
import 'x.dart' as _;
part 'a.dart';
''');

    _assertScopeLookups(withAccessibleExtensions: true, library, [
      Uri.parse('package:test/test.dart'),
      Uri.parse('package:test/a.dart'),
    ], [
      '_.X'
    ], r'''
package:test/test.dart
  _.X
    _: <null>
  accessibleExtensions
    dart:core::<fragment>::@extension::EnumName
    package:test/x.dart::<fragment>::@extension::X
package:test/a.dart
  _.X
    _: <null>
  accessibleExtensions
    dart:core::<fragment>::@extension::EnumName
    package:test/x.dart::<fragment>::@extension::X
''');
  }

  test_scope_wildcardName_importPrefix_preWildcardVariables() async {
    newFile('$testPackageLibPath/x.dart', r'''
extension X on int {}
''');

    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
''');

    var library = await buildLibrary(r'''
// @dart=3.5
import 'x.dart' as _;
part 'a.dart';
''');

    _assertScopeLookups(withAccessibleExtensions: true, library, [
      Uri.parse('package:test/test.dart'),
      Uri.parse('package:test/a.dart'),
    ], [
      '_.X'
    ], r'''
package:test/test.dart
  _.X
    _: <testLibraryFragment>::@prefix::_
    getter: package:test/x.dart::<fragment>::@extension::X
  accessibleExtensions
    dart:core::<fragment>::@extension::EnumName
    package:test/x.dart::<fragment>::@extension::X
package:test/a.dart
  _.X
    _: <testLibraryFragment>::@prefix::_
    getter: package:test/x.dart::<fragment>::@extension::X
  accessibleExtensions
    dart:core::<fragment>::@extension::EnumName
    package:test/x.dart::<fragment>::@extension::X
''');
  }

  void _assertScopeLookups(
    LibraryElementImpl library,
    List<Uri> fragmentUris,
    List<String> requests,
    String expected, {
    bool withAccessibleExtensions = false,
  }) {
    var buffer = StringBuffer();

    var sink = TreeStringSink(
      sink: buffer,
      indent: '',
    );

    var elementPrinter = ElementPrinter(
      sink: sink,
      configuration: ElementPrinterConfiguration(),
    );

    for (var fragmentUri in fragmentUris) {
      sink.writelnWithIndent(fragmentUri);
      sink.withIndent(() {
        var fragment = library.units.singleWhere((fragment) {
          return fragment.source.uri == fragmentUri;
        });

        for (var request in requests) {
          var periodIndex = request.indexOf('.');
          var (prefixName, rawName) = switch (periodIndex) {
            > 0 => (
                request.substring(0, periodIndex),
                request.substring(periodIndex + 1),
              ),
            _ => (null, request),
          };

          void writeResult(ScopeLookupResult result) {
            sink.withIndent(() {
              elementPrinter.writeNamedElement('getter', result.getter);
              if (result.setter case var setter?) {
                elementPrinter.writeNamedElement('setter', setter);
              }
            });
          }

          sink.writelnWithIndent(
            request.ifNotEmptyOrElse('<empty>'),
          );

          if (prefixName != null) {
            var prefixLookup = fragment.scope.lookup(prefixName);
            expect(prefixLookup.setter, isNull);
            var importPrefix = prefixLookup.getter;
            if (importPrefix == null) {
              sink.withIndent(() {
                elementPrinter.writeNamedElement(prefixName, importPrefix);
              });
            } else {
              importPrefix as PrefixElementImpl;
              sink.withIndent(() {
                elementPrinter.writeNamedElement(prefixName, importPrefix);
              });
              var result = importPrefix.scope.lookup(rawName);
              writeResult(result);
            }
          } else {
            var result = fragment.scope.lookup(rawName);
            writeResult(result);
          }
        }

        if (withAccessibleExtensions) {
          elementPrinter.writeElementList(
            'accessibleExtensions',
            fragment.accessibleExtensions.sortedBy((e) => e.name ?? ''),
          );
        }
      });
    }

    var actual = buffer.toString();
    if (actual != expected) {
      print('-------- Actual --------');
      print('$actual------------------------');
      NodeTextExpectationsCollector.add(actual);
    }
    expect(actual, expected);
  }
}

@reflectiveTest
class LibraryFragmentElementTest_fromBytes extends LibraryFragmentElementTest {
  @override
  bool get keepLinkingLibraries => false;
}

@reflectiveTest
class LibraryFragmentElementTest_keepLinking
    extends LibraryFragmentElementTest {
  @override
  bool get keepLinkingLibraries => true;
}
