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
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      nextFragment: #F1
      libraryExports
        dart:io
      parts
        part_0
          uri: package:test/a.dart
          partKeywordOffset: 18
          unit: #F1
    #F1 package:test/a.dart
      element: <testLibrary>
      enclosingFragment: #F0
      previousFragment: #F0
      libraryExports
        dart:math
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
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      nextFragment: #F1
      parts
        part_0
          uri: package:test/a.dart
          partKeywordOffset: 0
          unit: #F1
    #F1 package:test/a.dart
      element: <testLibrary>
      enclosingFragment: #F0
      previousFragment: #F0
      libraryExports
        dart:math
          metadata
            Annotation
              atSign: @ @21
              name: SimpleIdentifier
                token: deprecated @22
                element: dart:core::@getter::deprecated
                staticType: null
              element2: dart:core::@getter::deprecated
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
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      nextFragment: #F1
      libraryImports
        dart:io
      parts
        part_0
          uri: package:test/a.dart
          partKeywordOffset: 18
          unit: #F1
    #F1 package:test/a.dart
      element: <testLibrary>
      enclosingFragment: #F0
      previousFragment: #F0
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
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      nextFragment: #F1
      parts
        part_0
          uri: package:test/a.dart
          partKeywordOffset: 0
          unit: #F1
    #F1 package:test/a.dart
      element: <testLibrary>
      enclosingFragment: #F0
      previousFragment: #F0
      libraryImports
        dart:math
          metadata
            Annotation
              atSign: @ @21
              name: SimpleIdentifier
                token: deprecated @22
                element: dart:core::@getter::deprecated
                staticType: null
              element2: dart:core::@getter::deprecated
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

    _assertScopeLookups(
      withAccessibleExtensions: true,
      library,
      [
        Uri.parse('package:test/test.dart'),
        Uri.parse('package:test/a.dart'),
        Uri.parse('package:test/aa.dart'),
        Uri.parse('package:test/b.dart'),
      ],
      [],
      r'''
package:test/test.dart
  accessibleExtensions
    dart:core::@extension::EnumName
    package:test/x.dart::@extension::X
package:test/a.dart
  accessibleExtensions
    dart:core::@extension::EnumName
    package:test/x.dart::@extension::X
    package:test/y.dart::@extension::Y
package:test/aa.dart
  accessibleExtensions
    dart:core::@extension::EnumName
    package:test/x.dart::@extension::X
    package:test/y.dart::@extension::Y
package:test/b.dart
  accessibleExtensions
    dart:core::@extension::EnumName
    package:test/x.dart::@extension::X
''',
    );
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

    _assertScopeLookups(
      withAccessibleExtensions: true,
      library,
      [
        Uri.parse('package:test/test.dart'),
        Uri.parse('package:test/a.dart'),
        Uri.parse('package:test/aa.dart'),
        Uri.parse('package:test/b.dart'),
      ],
      [],
      r'''
package:test/test.dart
  accessibleExtensions
    dart:core::@extension::EnumName
    package:test/x.dart::@extension::X
package:test/a.dart
  accessibleExtensions
    dart:core::@extension::EnumName
    package:test/x.dart::@extension::X
    package:test/y.dart::@extension::Y
package:test/aa.dart
  accessibleExtensions
    dart:core::@extension::EnumName
    package:test/x.dart::@extension::X
    package:test/y.dart::@extension::Y
package:test/b.dart
  accessibleExtensions
    dart:core::@extension::EnumName
    package:test/x.dart::@extension::X
''',
    );
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

    _assertScopeLookups(
      withAccessibleExtensions: true,
      library,
      [
        Uri.parse('package:test/test.dart'),
        Uri.parse('package:test/a.dart'),
        Uri.parse('package:test/aa.dart'),
      ],
      [],
      r'''
package:test/test.dart
  accessibleExtensions
    <testLibrary>::@extension::A
    <testLibrary>::@extension::B
    dart:core::@extension::EnumName
    <testLibrary>::@extension::Z
package:test/a.dart
  accessibleExtensions
    <testLibrary>::@extension::A
    <testLibrary>::@extension::B
    dart:core::@extension::EnumName
    <testLibrary>::@extension::Z
package:test/aa.dart
  accessibleExtensions
    <testLibrary>::@extension::A
    <testLibrary>::@extension::B
    dart:core::@extension::EnumName
    <testLibrary>::@extension::Z
''',
    );
  }

  test_scope_accessibleExtensions_unnamed() async {
    var library = await buildLibrary(r'''
part 'a.dart';
extension on int {}
''');

    _assertScopeLookups(
      withAccessibleExtensions: true,
      library,
      [Uri.parse('package:test/test.dart')],
      [''],
      r'''
package:test/test.dart
  <empty>
    getter: <null>
  accessibleExtensions
    <testLibrary>::@extension::0
    dart:core::@extension::EnumName
''',
    );
  }

  test_scope_hasPrefix() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
''');

    var library = await buildLibrary(r'''
import 'dart:io' as prefix;
part 'a.dart';
''');

    _assertScopeLookups(
      library,
      [Uri.parse('package:test/test.dart'), Uri.parse('package:test/a.dart')],
      ['prefix.exitCode'],
      r'''
package:test/test.dart
  prefix.exitCode
    prefix: <testLibraryFragment>::@prefix2::prefix
    getter: dart:io::@getter::exitCode
    setter: dart:io::@setter::exitCode
package:test/a.dart
  prefix.exitCode
    prefix: <testLibraryFragment>::@prefix2::prefix
    getter: dart:io::@getter::exitCode
    setter: dart:io::@setter::exitCode
''',
    );
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

    _assertScopeLookups(
      library,
      [
        Uri.parse('package:test/test.dart'),
        Uri.parse('package:test/a.dart'),
        Uri.parse('package:test/aa.dart'),
        Uri.parse('package:test/aaa.dart'),
      ],
      ['prefix.File', 'prefix.Random'],
      r'''
package:test/test.dart
  prefix.File
    prefix: <testLibraryFragment>::@prefix2::prefix
    getter: dart:io::@class::File
  prefix.Random
    prefix: <testLibraryFragment>::@prefix2::prefix
    getter: <null>
package:test/a.dart
  prefix.File
    prefix: <testLibrary>::@fragment::package:test/a.dart::@prefix2::prefix
    getter: dart:io::@class::File
  prefix.Random
    prefix: <testLibrary>::@fragment::package:test/a.dart::@prefix2::prefix
    getter: dart:math::@class::Random
package:test/aa.dart
  prefix.File
    prefix: <testLibrary>::@fragment::package:test/a.dart::@prefix2::prefix
    getter: dart:io::@class::File
  prefix.Random
    prefix: <testLibrary>::@fragment::package:test/a.dart::@prefix2::prefix
    getter: dart:math::@class::Random
package:test/aaa.dart
  prefix.File
    prefix: <testLibrary>::@fragment::package:test/a.dart::@prefix2::prefix
    getter: dart:io::@class::File
  prefix.Random
    prefix: <testLibrary>::@fragment::package:test/a.dart::@prefix2::prefix
    getter: dart:math::@class::Random
''',
    );
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

    _assertScopeLookups(
      library,
      [
        Uri.parse('package:test/test.dart'),
        Uri.parse('package:test/a.dart'),
        Uri.parse('package:test/aa.dart'),
      ],
      ['prefix.File', 'prefix.Random'],
      r'''
package:test/test.dart
  prefix.File
    prefix: <testLibraryFragment>::@prefix2::prefix
    getter: dart:io::@class::File
  prefix.Random
    prefix: <testLibraryFragment>::@prefix2::prefix
    getter: <null>
package:test/a.dart
  prefix.File
    prefix: <testLibraryFragment>::@prefix2::prefix
    getter: dart:io::@class::File
  prefix.Random
    prefix: <testLibraryFragment>::@prefix2::prefix
    getter: <null>
package:test/aa.dart
  prefix.File
    prefix: <testLibrary>::@fragment::package:test/aa.dart::@prefix2::prefix
    getter: dart:io::@class::File
  prefix.Random
    prefix: <testLibrary>::@fragment::package:test/aa.dart::@prefix2::prefix
    getter: dart:math::@class::Random
''',
    );
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

    _assertScopeLookups(
      library,
      [
        Uri.parse('package:test/test.dart'),
        Uri.parse('package:test/a.dart'),
        Uri.parse('package:test/aa.dart'),
      ],
      ['loadLibrary', 'prefix.File', 'prefix.Random'],
      r'''
package:test/test.dart
  loadLibrary
    getter: <null>
  prefix.File
    prefix: <testLibraryFragment>::@prefix2::prefix
    getter: dart:io::@class::File
  prefix.Random
    prefix: <testLibraryFragment>::@prefix2::prefix
    getter: <null>
package:test/a.dart
  loadLibrary
    getter: <null>
  prefix.File
    prefix: <testLibrary>::@fragment::package:test/a.dart::@prefix2::prefix
    getter: <null>
  prefix.Random
    prefix: <testLibrary>::@fragment::package:test/a.dart::@prefix2::prefix
    getter: dart:math::@class::Random
package:test/aa.dart
  loadLibrary
    getter: <null>
  prefix.File
    prefix: <testLibrary>::@fragment::package:test/aa.dart::@prefix2::prefix
    getter: <null>
  prefix.Random
    prefix: <testLibrary>::@fragment::package:test/aa.dart::@prefix2::prefix
    getter: dart:math::@class::Random
''',
    );
  }

  test_scope_hasPrefix_lookup_ambiguous_missingName() async {
    newFile('$testPackageLibPath/a.dart', r'''
class {}
''');

    newFile('$testPackageLibPath/b.dart', r'''
class {}
''');

    var library = await buildLibrary(r'''
import 'a.dart' as prefix;
import 'b.dart' as prefix;
''');

    _assertScopeLookups(
      library,
      [Uri.parse('package:test/test.dart')],
      ['prefix.A'],
      r'''
package:test/test.dart
  prefix.A
    prefix: <testLibraryFragment>::@prefix2::prefix
    getter: <null>
''',
    );
  }

  test_scope_hasPrefix_lookup_ambiguous_notSdk_both() async {
    newFile('$testPackageLibPath/a.dart', r'''
var foo = 0;
''');

    newFile('$testPackageLibPath/b.dart', r'''
var foo = 1.2;
''');

    var library = await buildLibrary(r'''
import 'a.dart' as prefix;
import 'b.dart' as prefix;
''');

    _assertScopeLookups(
      library,
      [Uri.parse('package:test/test.dart')],
      ['prefix.foo'],
      r'''
package:test/test.dart
  prefix.foo
    prefix: <testLibraryFragment>::@prefix2::prefix
    getter: multiplyDefinedElement
      package:test/a.dart::@getter::foo
      package:test/b.dart::@getter::foo
    setter: multiplyDefinedElement
      package:test/a.dart::@setter::foo
      package:test/b.dart::@setter::foo
''',
    );
  }

  test_scope_hasPrefix_lookup_ambiguous_notSdk_first() async {
    newFile('$testPackageLibPath/a.dart', r'''
var pi = 4;
''');

    var library = await buildLibrary(r'''
import 'a.dart' as prefix;
import 'dart:math' as prefix;
''');

    _assertScopeLookups(
      library,
      [Uri.parse('package:test/test.dart')],
      ['prefix.pi'],
      r'''
package:test/test.dart
  prefix.pi
    prefix: <testLibraryFragment>::@prefix2::prefix
    getter: package:test/a.dart::@getter::pi
    setter: package:test/a.dart::@setter::pi
''',
    );
  }

  test_scope_hasPrefix_lookup_ambiguous_notSdk_second() async {
    newFile('$testPackageLibPath/a.dart', r'''
var pi = 4;
''');

    var library = await buildLibrary(r'''
import 'dart:math' as prefix;
import 'a.dart' as prefix;
''');

    _assertScopeLookups(
      library,
      [Uri.parse('package:test/test.dart')],
      ['prefix.pi'],
      r'''
package:test/test.dart
  prefix.pi
    prefix: <testLibraryFragment>::@prefix2::prefix
    getter: package:test/a.dart::@getter::pi
    setter: package:test/a.dart::@setter::pi
''',
    );
  }

  test_scope_hasPrefix_lookup_ambiguous_same() async {
    newFile('$testPackageLibPath/a.dart', r'''
var foo = 0;
''');

    newFile('$testPackageLibPath/b.dart', r'''
export 'a.dart';
''');

    var library = await buildLibrary(r'''
import 'a.dart' as prefix;
import 'b.dart' as prefix;
''');

    _assertScopeLookups(
      library,
      [Uri.parse('package:test/test.dart')],
      ['prefix.foo'],
      r'''
package:test/test.dart
  prefix.foo
    prefix: <testLibraryFragment>::@prefix2::prefix
    getter: package:test/a.dart::@getter::foo
    setter: package:test/a.dart::@setter::foo
''',
    );
  }

  test_scope_hasPrefix_lookup_differentPrefix() async {
    newFile('$testPackageLibPath/a.dart', r'''
var foo = 0;
''');

    newFile('$testPackageLibPath/b.dart', r'''
var bar = 0;
''');

    var library = await buildLibrary(r'''
import 'a.dart' as prefix;
import 'b.dart' as prefix2;
''');

    _assertScopeLookups(
      library,
      [Uri.parse('package:test/test.dart')],
      ['prefix.foo', 'prefix.bar', 'prefix2.foo', 'prefix2.bar'],
      r'''
package:test/test.dart
  prefix.foo
    prefix: <testLibraryFragment>::@prefix2::prefix
    getter: package:test/a.dart::@getter::foo
    setter: package:test/a.dart::@setter::foo
  prefix.bar
    prefix: <testLibraryFragment>::@prefix2::prefix
    getter: <null>
  prefix2.foo
    prefix2: <testLibraryFragment>::@prefix2::prefix2
    getter: <null>
  prefix2.bar
    prefix2: <testLibraryFragment>::@prefix2::prefix2
    getter: package:test/b.dart::@getter::bar
    setter: package:test/b.dart::@setter::bar
''',
    );
  }

  test_scope_hasPrefix_lookup_notFound() async {
    var library = await buildLibrary(r'''
import 'dart:math' as math;
''');

    _assertScopeLookups(
      library,
      [Uri.parse('package:test/test.dart')],
      ['math.noSuchElement'],
      r'''
package:test/test.dart
  math.noSuchElement
    math: <testLibraryFragment>::@prefix2::math
    getter: <null>
''',
    );
  }

  test_scope_hasPrefix_lookup_respectsCombinator_hide() async {
    var library = await buildLibrary(r'''
import 'dart:math' as math hide sin;
''');

    _assertScopeLookups(
      library,
      [Uri.parse('package:test/test.dart')],
      ['math.sin', 'math.cos'],
      r'''
package:test/test.dart
  math.sin
    math: <testLibraryFragment>::@prefix2::math
    getter: <null>
  math.cos
    math: <testLibraryFragment>::@prefix2::math
    getter: dart:math::@function::cos
''',
    );
  }

  test_scope_hasPrefix_lookup_respectsCombinator_show() async {
    var library = await buildLibrary(r'''
import 'dart:math' as math show sin;
''');

    _assertScopeLookups(
      library,
      [Uri.parse('package:test/test.dart')],
      ['math.sin', 'math.cos'],
      r'''
package:test/test.dart
  math.sin
    math: <testLibraryFragment>::@prefix2::math
    getter: dart:math::@function::sin
  math.cos
    math: <testLibraryFragment>::@prefix2::math
    getter: <null>
''',
    );
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

    _assertScopeLookups(
      library,
      [
        Uri.parse('package:test/test.dart'),
        Uri.parse('package:test/a.dart'),
        Uri.parse('package:test/aa.dart'),
      ],
      ['prefix.File', 'prefix.Directory'],
      r'''
package:test/test.dart
  prefix.File
    prefix: <testLibraryFragment>::@prefix2::prefix
    getter: dart:io::@class::File
  prefix.Directory
    prefix: <testLibraryFragment>::@prefix2::prefix
    getter: dart:io::@class::Directory
package:test/a.dart
  prefix.File
    prefix: <testLibrary>::@fragment::package:test/a.dart::@prefix2::prefix
    getter: dart:io::@class::File
  prefix.Directory
    prefix: <testLibrary>::@fragment::package:test/a.dart::@prefix2::prefix
    getter: package:test/x.dart::@class::Directory
package:test/aa.dart
  prefix.File
    prefix: <testLibrary>::@fragment::package:test/a.dart::@prefix2::prefix
    getter: dart:io::@class::File
  prefix.Directory
    prefix: <testLibrary>::@fragment::package:test/a.dart::@prefix2::prefix
    getter: package:test/x.dart::@class::Directory
''',
    );
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

    _assertScopeLookups(
      library,
      [
        Uri.parse('package:test/test.dart'),
        Uri.parse('package:test/a.dart'),
        Uri.parse('package:test/b.dart'),
      ],
      ['foo'],
      r'''
package:test/test.dart
  foo
    getter: <testLibrary>::@function::foo
package:test/a.dart
  foo
    getter: <testLibrary>::@function::foo
package:test/b.dart
  foo
    getter: <testLibrary>::@function::foo
''',
    );
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

    _assertScopeLookups(
      library,
      [Uri.parse('package:test/test.dart'), Uri.parse('package:test/a.dart')],
      ['A', 'B', 'C', 'D'],
      r'''
package:test/test.dart
  A
    getter: <null>
  B
    getter: package:test/x.dart::@class::B
  C
    getter: <null>
  D
    getter: package:test/x.dart::@class::D
package:test/a.dart
  A
    getter: <null>
  B
    getter: package:test/x.dart::@class::B
  C
    getter: <null>
  D
    getter: package:test/x.dart::@class::D
''',
    );
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

    _assertScopeLookups(
      library,
      [Uri.parse('package:test/test.dart'), Uri.parse('package:test/a.dart')],
      ['A', 'B', 'C', 'D'],
      r'''
package:test/test.dart
  A
    getter: <null>
  B
    getter: package:test/x.dart::@class::B
  C
    getter: <null>
  D
    getter: <null>
package:test/a.dart
  A
    getter: <null>
  B
    getter: package:test/x.dart::@class::B
  C
    getter: <null>
  D
    getter: <null>
''',
    );
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

    _assertScopeLookups(
      library,
      [Uri.parse('package:test/test.dart'), Uri.parse('package:test/a.dart')],
      ['A', 'B', 'C', 'D'],
      r'''
package:test/test.dart
  A
    getter: package:test/x.dart::@class::A
  B
    getter: <null>
  C
    getter: package:test/x.dart::@class::C
  D
    getter: <null>
package:test/a.dart
  A
    getter: package:test/x.dart::@class::A
  B
    getter: <null>
  C
    getter: package:test/x.dart::@class::C
  D
    getter: <null>
''',
    );
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

    _assertScopeLookups(
      library,
      [Uri.parse('package:test/test.dart'), Uri.parse('package:test/a.dart')],
      ['A', 'B', 'C', 'D'],
      r'''
package:test/test.dart
  A
    getter: package:test/x.dart::@class::A
  B
    getter: <null>
  C
    getter: <null>
  D
    getter: <null>
package:test/a.dart
  A
    getter: package:test/x.dart::@class::A
  B
    getter: <null>
  C
    getter: <null>
  D
    getter: <null>
''',
    );
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

    _assertScopeLookups(
      library,
      [
        Uri.parse('package:test/test.dart'),
        Uri.parse('package:test/a.dart'),
        Uri.parse('package:test/aa.dart'),
        Uri.parse('package:test/b.dart'),
      ],
      ['exitCode'],
      r'''
package:test/test.dart
  exitCode
    getter: dart:io::@getter::exitCode
    setter: dart:io::@setter::exitCode
package:test/a.dart
  exitCode
    getter: package:test/x.dart::@getter::exitCode
package:test/aa.dart
  exitCode
    getter: package:test/x.dart::@getter::exitCode
package:test/b.dart
  exitCode
    getter: dart:io::@getter::exitCode
    setter: dart:io::@setter::exitCode
''',
    );
  }

  test_scope_noPrefix_implicitDartCore() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
''');

    var library = await buildLibrary(r'''
part 'a.dart';
''');

    _assertScopeLookups(
      library,
      [Uri.parse('package:test/test.dart'), Uri.parse('package:test/a.dart')],
      ['Object'],
      r'''
package:test/test.dart
  Object
    getter: dart:core::@class::Object
package:test/a.dart
  Object
    getter: dart:core::@class::Object
''',
    );
  }

  test_scope_noPrefix_inheritsFromParentFragment_fromDefining() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
''');

    var library = await buildLibrary(r'''
import 'dart:io';
part 'a.dart';
''');

    _assertScopeLookups(
      library,
      [Uri.parse('package:test/test.dart'), Uri.parse('package:test/a.dart')],
      ['exit', 'exitCode'],
      r'''
package:test/test.dart
  exit
    getter: dart:io::@function::exit
  exitCode
    getter: dart:io::@getter::exitCode
    setter: dart:io::@setter::exitCode
package:test/a.dart
  exit
    getter: dart:io::@function::exit
  exitCode
    getter: dart:io::@getter::exitCode
    setter: dart:io::@setter::exitCode
''',
    );
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

    _assertScopeLookups(
      library,
      [
        Uri.parse('package:test/test.dart'),
        Uri.parse('package:test/a.dart'),
        Uri.parse('package:test/aa.dart'),
        Uri.parse('package:test/b.dart'),
      ],
      ['exitCode'],
      r'''
package:test/test.dart
  exitCode
    getter: <null>
package:test/a.dart
  exitCode
    getter: dart:io::@getter::exitCode
    setter: dart:io::@setter::exitCode
package:test/aa.dart
  exitCode
    getter: dart:io::@getter::exitCode
    setter: dart:io::@setter::exitCode
package:test/b.dart
  exitCode
    getter: <null>
''',
    );
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

    _assertScopeLookups(
      library,
      [
        Uri.parse('package:test/test.dart'),
        Uri.parse('package:test/a.dart'),
        Uri.parse('package:test/b.dart'),
      ],
      ['exitCode'],
      r'''
package:test/test.dart
  exitCode
    getter: <testLibrary>::@getter::exitCode
package:test/a.dart
  exitCode
    getter: <testLibrary>::@getter::exitCode
package:test/b.dart
  exitCode
    getter: <testLibrary>::@getter::exitCode
''',
    );
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

    _assertScopeLookups(
      library,
      [
        Uri.parse('package:test/test.dart'),
        Uri.parse('package:test/a.dart'),
        Uri.parse('package:test/b.dart'),
      ],
      ['exitCode'],
      r'''
package:test/test.dart
  exitCode
    getter: <null>
    setter: <testLibrary>::@setter::exitCode
package:test/a.dart
  exitCode
    getter: <null>
    setter: <testLibrary>::@setter::exitCode
package:test/b.dart
  exitCode
    getter: <null>
    setter: <testLibrary>::@setter::exitCode
''',
    );
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

    _assertScopeLookups(
      library,
      [
        Uri.parse('package:test/test.dart'),
        Uri.parse('package:test/a.dart'),
        Uri.parse('package:test/aa.dart'),
      ],
      ['A', 'B', 'Z'],
      r'''
package:test/test.dart
  A
    getter: <testLibrary>::@class::A
  B
    getter: <testLibrary>::@class::B
  Z
    getter: <testLibrary>::@class::Z
package:test/a.dart
  A
    getter: <testLibrary>::@class::A
  B
    getter: <testLibrary>::@class::B
  Z
    getter: <testLibrary>::@class::Z
package:test/aa.dart
  A
    getter: <testLibrary>::@class::A
  B
    getter: <testLibrary>::@class::B
  Z
    getter: <testLibrary>::@class::Z
''',
    );
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

    _assertScopeLookups(
      library,
      [Uri.parse('package:test/test.dart'), Uri.parse('package:test/a.dart')],
      ['_A', '_Z', '_foo'],
      r'''
package:test/test.dart
  _A
    getter: <testLibrary>::@class::_A
  _Z
    getter: <testLibrary>::@class::_Z
  _foo
    getter: <null>
    setter: <testLibrary>::@setter::_foo
package:test/a.dart
  _A
    getter: <testLibrary>::@class::_A
  _Z
    getter: <testLibrary>::@class::_Z
  _foo
    getter: <null>
    setter: <testLibrary>::@setter::_foo
''',
    );
  }

  test_scope_wildcardName_class() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
class _ {}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
''');

    _assertScopeLookups(
      library,
      [Uri.parse('package:test/test.dart'), Uri.parse('package:test/a.dart')],
      ['_'],
      r'''
package:test/test.dart
  _
    getter: <testLibrary>::@class::_
package:test/a.dart
  _
    getter: <testLibrary>::@class::_
''',
    );
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

    _assertScopeLookups(
      withAccessibleExtensions: true,
      library,
      [Uri.parse('package:test/test.dart'), Uri.parse('package:test/a.dart')],
      ['_.X'],
      r'''
package:test/test.dart
  _.X
    _: <null>
  accessibleExtensions
    dart:core::@extension::EnumName
    package:test/x.dart::@extension::X
package:test/a.dart
  _.X
    _: <null>
  accessibleExtensions
    dart:core::@extension::EnumName
    package:test/x.dart::@extension::X
''',
    );
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

    _assertScopeLookups(
      withAccessibleExtensions: true,
      library,
      [Uri.parse('package:test/test.dart'), Uri.parse('package:test/a.dart')],
      ['_.X'],
      r'''
package:test/test.dart
  _.X
    _: <testLibraryFragment>::@prefix2::_
    getter: package:test/x.dart::@extension::X
  accessibleExtensions
    dart:core::@extension::EnumName
    package:test/x.dart::@extension::X
package:test/a.dart
  _.X
    _: <testLibraryFragment>::@prefix2::_
    getter: package:test/x.dart::@extension::X
  accessibleExtensions
    dart:core::@extension::EnumName
    package:test/x.dart::@extension::X
''',
    );
  }

  void _assertScopeLookups(
    LibraryElementImpl library,
    List<Uri> fragmentUris,
    List<String> requests,
    String expected, {
    bool withAccessibleExtensions = false,
  }) {
    var buffer = StringBuffer();

    var sink = TreeStringSink(sink: buffer, indent: '');

    var elementPrinter = ElementPrinter(
      sink: sink,
      configuration: ElementPrinterConfiguration(),
    );

    for (var fragmentUri in fragmentUris) {
      sink.writelnWithIndent(fragmentUri);
      sink.withIndent(() {
        var fragment = library.fragments.singleWhere((fragment) {
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
              elementPrinter.writeNamedElement2('getter', result.getter);
              if (result.setter case var setter?) {
                elementPrinter.writeNamedElement2('setter', setter);
              }
            });
          }

          sink.writelnWithIndent(request.ifNotEmptyOrElse('<empty>'));

          if (prefixName != null) {
            var prefixLookup = fragment.scope.lookup(prefixName);
            expect(prefixLookup.setter, isNull);
            var importPrefix = prefixLookup.getter;
            if (importPrefix == null) {
              sink.withIndent(() {
                elementPrinter.writeNamedElement2(prefixName, importPrefix);
              });
            } else {
              importPrefix as PrefixElementImpl;
              sink.withIndent(() {
                elementPrinter.writeNamedElement2(prefixName, importPrefix);
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
          elementPrinter.writeElementList2(
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
