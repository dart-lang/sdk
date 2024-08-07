// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../dart/resolution/node_text_expectations.dart';
import '../elements_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PartIncludeElementTest_keepLinking);
    defineReflectiveTests(PartIncludeElementTest_fromBytes);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

abstract class PartIncludeElementTest extends ElementsBaseTest {
  test_library_parts() async {
    addSource('$testPackageLibPath/a.dart', 'part of my.lib;');
    addSource('$testPackageLibPath/b.dart', 'part of my.lib;');
    var library =
        await buildLibrary('library my.lib; part "a.dart"; part "b.dart";');
    checkElementText(library, r'''
library
  name: my.lib
  nameOffset: 8
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  parts
    part_0
    part_1
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
        part_1
          uri: package:test/b.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/b.dart
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
----------------------------------------
library
  reference: <testLibrary>
  name: my.lib
  fragments
    <testLibraryFragment>
    <testLibrary>::@fragment::package:test/a.dart
    <testLibrary>::@fragment::package:test/b.dart
''');
  }

  test_library_parts_nested() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
part 'a11.dart';
part 'a12.dart';
class A {}
''');

    newFile('$testPackageLibPath/a11.dart', r'''
part of 'a.dart';
class A11 {}
''');

    newFile('$testPackageLibPath/a12.dart', r'''
part of 'a.dart';
class A12 {}
''');

    newFile('$testPackageLibPath/b.dart', r'''
part of 'test.dart';
part 'b11.dart';
part 'b12.dart';
''');

    newFile('$testPackageLibPath/b11.dart', r'''
part of 'b.dart';
class B11 {}
''');

    newFile('$testPackageLibPath/b12.dart', r'''
part of 'b.dart';
class B12 {}
''');

    var library = await buildLibrary('''
part 'a.dart';
part 'b.dart';
class Z {}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  parts
    part_0
    part_1
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
        part_1
          uri: package:test/b.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/b.dart
      classes
        class Z @36
          reference: <testLibraryFragment>::@class::Z
          enclosingElement: <testLibraryFragment>
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      parts
        part_2
          uri: package:test/a11.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          unit: <testLibrary>::@fragment::package:test/a11.dart
        part_3
          uri: package:test/a12.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          unit: <testLibrary>::@fragment::package:test/a12.dart
      classes
        class A @61
          reference: <testLibrary>::@fragment::package:test/a.dart::@class::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
    <testLibrary>::@fragment::package:test/a11.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
      classes
        class A11 @24
          reference: <testLibrary>::@fragment::package:test/a11.dart::@class::A11
          enclosingElement: <testLibrary>::@fragment::package:test/a11.dart
    <testLibrary>::@fragment::package:test/a12.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
      classes
        class A12 @24
          reference: <testLibrary>::@fragment::package:test/a12.dart::@class::A12
          enclosingElement: <testLibrary>::@fragment::package:test/a12.dart
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      parts
        part_4
          uri: package:test/b11.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibrary>::@fragment::package:test/b.dart
          unit: <testLibrary>::@fragment::package:test/b11.dart
        part_5
          uri: package:test/b12.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibrary>::@fragment::package:test/b.dart
          unit: <testLibrary>::@fragment::package:test/b12.dart
    <testLibrary>::@fragment::package:test/b11.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibrary>::@fragment::package:test/b.dart
      classes
        class B11 @24
          reference: <testLibrary>::@fragment::package:test/b11.dart::@class::B11
          enclosingElement: <testLibrary>::@fragment::package:test/b11.dart
    <testLibrary>::@fragment::package:test/b12.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibrary>::@fragment::package:test/b.dart
      classes
        class B12 @24
          reference: <testLibrary>::@fragment::package:test/b12.dart::@class::B12
          enclosingElement: <testLibrary>::@fragment::package:test/b12.dart
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
    <testLibrary>::@fragment::package:test/a.dart
    <testLibrary>::@fragment::package:test/a11.dart
    <testLibrary>::@fragment::package:test/a12.dart
    <testLibrary>::@fragment::package:test/b.dart
    <testLibrary>::@fragment::package:test/b11.dart
    <testLibrary>::@fragment::package:test/b12.dart
''');
  }

  test_library_parts_noRelativeUriStr() async {
    var library = await buildLibrary(r'''
part '${'foo'}.dart';
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  parts
    part_0
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      parts
        part_0
          uri: noRelativeUriString
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
''');
  }

  test_partDirective_withPart_partOfName() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of my.lib;
class B {}
''');
    var library = await buildLibrary(r'''
library my.lib;
part 'a.dart';
class A {}
''');
    checkElementText(library, r'''
library
  name: my.lib
  nameOffset: 8
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  parts
    part_0
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      classes
        class A @37
          reference: <testLibraryFragment>::@class::A
          enclosingElement: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::A
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      classes
        class B @22
          reference: <testLibrary>::@fragment::package:test/a.dart::@class::B
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          constructors
            synthetic @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@class::B::@constructor::new
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@class::B
----------------------------------------
library
  reference: <testLibrary>
  name: my.lib
  fragments
    <testLibraryFragment>
    <testLibrary>::@fragment::package:test/a.dart
''');
  }

  test_partDirective_withPart_partOfUri() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
class B {}
''');
    var library = await buildLibrary(r'''
part 'a.dart';
class A {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  parts
    part_0
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      classes
        class A @21
          reference: <testLibraryFragment>::@class::A
          enclosingElement: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::A
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      classes
        class B @27
          reference: <testLibrary>::@fragment::package:test/a.dart::@class::B
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          constructors
            synthetic @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@class::B::@constructor::new
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@class::B
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
    <testLibrary>::@fragment::package:test/a.dart
''');
  }

  test_partDirective_withRelativeUri_noSource() async {
    var library = await buildLibrary(r'''
part 'foo:bar';
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  parts
    part_0
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      parts
        part_0
          uri: relativeUri 'foo:bar'
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
''');
  }

  test_partDirective_withRelativeUri_notPart_emptyUriSelf() async {
    var library = await buildLibrary(r'''
part '';
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  parts
    part_0
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      parts
        part_0
          uri: source 'package:test/test.dart'
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
''');
  }

  test_partDirective_withRelativeUri_notPart_library() async {
    newFile('$testPackageLibPath/a.dart', '');
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
      enclosingElement: <testLibrary>
      parts
        part_0
          uri: source 'package:test/a.dart'
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
''');
  }

  test_partDirective_withRelativeUri_notPart_notExists() async {
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
      enclosingElement: <testLibrary>
      parts
        part_0
          uri: source 'package:test/a.dart'
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
''');
  }

  test_partDirective_withRelativeUriString() async {
    var library = await buildLibrary(r'''
part ':';
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  parts
    part_0
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      parts
        part_0
          uri: relativeUriString ':'
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
''');
  }

  test_parts() async {
    addSource('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
''');

    addSource('$testPackageLibPath/b.dart', r'''
part of 'test.dart';
''');

    var library = await buildLibrary(r'''
part 'a.dart';
part 'b.dart';
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  parts
    part_0
    part_1
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
        part_1
          uri: package:test/b.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/b.dart
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
    <testLibrary>::@fragment::package:test/a.dart
    <testLibrary>::@fragment::package:test/b.dart
''');
  }

  test_parts_nested() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
part 'a11.dart';
part 'a12.dart';
class A {}
''');

    newFile('$testPackageLibPath/a11.dart', r'''
part of 'a.dart';
class A11 {}
''');

    newFile('$testPackageLibPath/a12.dart', r'''
part of 'a.dart';
class A12 {}
''');

    newFile('$testPackageLibPath/b.dart', r'''
part of 'test.dart';
part 'b11.dart';
part 'b12.dart';
''');

    newFile('$testPackageLibPath/b11.dart', r'''
part of 'b.dart';
class B11 {}
''');

    newFile('$testPackageLibPath/b12.dart', r'''
part of 'b.dart';
class B12 {}
''');

    var library = await buildLibrary('''
part 'a.dart';
part 'b.dart';
class Z {}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  parts
    part_0
    part_1
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
        part_1
          uri: package:test/b.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/b.dart
      classes
        class Z @36
          reference: <testLibraryFragment>::@class::Z
          enclosingElement: <testLibraryFragment>
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      parts
        part_2
          uri: package:test/a11.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          unit: <testLibrary>::@fragment::package:test/a11.dart
        part_3
          uri: package:test/a12.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          unit: <testLibrary>::@fragment::package:test/a12.dart
      classes
        class A @61
          reference: <testLibrary>::@fragment::package:test/a.dart::@class::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
    <testLibrary>::@fragment::package:test/a11.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
      classes
        class A11 @24
          reference: <testLibrary>::@fragment::package:test/a11.dart::@class::A11
          enclosingElement: <testLibrary>::@fragment::package:test/a11.dart
    <testLibrary>::@fragment::package:test/a12.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
      classes
        class A12 @24
          reference: <testLibrary>::@fragment::package:test/a12.dart::@class::A12
          enclosingElement: <testLibrary>::@fragment::package:test/a12.dart
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      parts
        part_4
          uri: package:test/b11.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibrary>::@fragment::package:test/b.dart
          unit: <testLibrary>::@fragment::package:test/b11.dart
        part_5
          uri: package:test/b12.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibrary>::@fragment::package:test/b.dart
          unit: <testLibrary>::@fragment::package:test/b12.dart
    <testLibrary>::@fragment::package:test/b11.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibrary>::@fragment::package:test/b.dart
      classes
        class B11 @24
          reference: <testLibrary>::@fragment::package:test/b11.dart::@class::B11
          enclosingElement: <testLibrary>::@fragment::package:test/b11.dart
    <testLibrary>::@fragment::package:test/b12.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibrary>::@fragment::package:test/b.dart
      classes
        class B12 @24
          reference: <testLibrary>::@fragment::package:test/b12.dart::@class::B12
          enclosingElement: <testLibrary>::@fragment::package:test/b12.dart
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
    <testLibrary>::@fragment::package:test/a.dart
    <testLibrary>::@fragment::package:test/a11.dart
    <testLibrary>::@fragment::package:test/a12.dart
    <testLibrary>::@fragment::package:test/b.dart
    <testLibrary>::@fragment::package:test/b11.dart
    <testLibrary>::@fragment::package:test/b12.dart
''');
  }
}

@reflectiveTest
class PartIncludeElementTest_fromBytes extends PartIncludeElementTest {
  @override
  bool get keepLinkingLibraries => false;
}

@reflectiveTest
class PartIncludeElementTest_keepLinking extends PartIncludeElementTest {
  @override
  bool get keepLinkingLibraries => true;
}
