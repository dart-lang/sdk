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
  test_configurations_useDefault() async {
    declaredVariables = {
      'dart.library.io': 'false',
    };

    newFile('$testPackageLibPath/foo.dart', r'''
part of 'test.dart';
class A {}
''');

    newFile('$testPackageLibPath/foo_io.dart', r'''
part of 'test.dart';
class A {}
''');

    newFile('$testPackageLibPath/foo_html.dart', r'''
part of 'test.dart';
class A {}
''');

    var library = await buildLibrary(r'''
part 'foo.dart'
  if (dart.library.io) 'foo_io.dart'
  if (dart.library.html) 'foo_html.dart';

class B extends A {}
''');

    configuration
      ..elementPrinterConfiguration.withInterfaceTypeElements = true
      ..withConstructors = false;
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
          uri: package:test/foo.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/foo.dart
      classes
        class B @102
          reference: <testLibraryFragment>::@class::B
          enclosingElement: <testLibraryFragment>
          supertype: A
            element: <testLibrary>::@fragment::package:test/foo.dart::@class::A
    <testLibrary>::@fragment::package:test/foo.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      classes
        class A @27
          reference: <testLibrary>::@fragment::package:test/foo.dart::@class::A
          enclosingElement: <testLibrary>::@fragment::package:test/foo.dart
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/foo.dart
      classes
        class B @102
          reference: <testLibraryFragment>::@class::B
    <testLibrary>::@fragment::package:test/foo.dart
      previousFragment: <testLibraryFragment>
      classes
        class A @27
          reference: <testLibrary>::@fragment::package:test/foo.dart::@class::A
  classes
    class B
      reference: <testLibraryFragment>::@class::B
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@class::B
      supertype: A
        element: <testLibrary>::@fragment::package:test/foo.dart::@class::A
    class A
      reference: <testLibrary>::@fragment::package:test/foo.dart::@class::A
      enclosingElement2: <testLibrary>
      firstFragment: <testLibrary>::@fragment::package:test/foo.dart::@class::A
''');
  }

  test_configurations_useFirst() async {
    declaredVariables = {
      'dart.library.io': 'true',
      'dart.library.html': 'true',
    };

    newFile('$testPackageLibPath/foo.dart', r'''
part of 'test.dart';
class A {}
''');

    newFile('$testPackageLibPath/foo_io.dart', r'''
part of 'test.dart';
class A {}
''');

    newFile('$testPackageLibPath/foo_html.dart', r'''
part of 'test.dart';
class A {}
''');

    var library = await buildLibrary(r'''
part 'foo.dart'
  if (dart.library.io) 'foo_io.dart'
  if (dart.library.html) 'foo_html.dart';

class B extends A {}
''');

    configuration
      ..elementPrinterConfiguration.withInterfaceTypeElements = true
      ..withConstructors = false;
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
          uri: package:test/foo_io.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/foo_io.dart
      classes
        class B @102
          reference: <testLibraryFragment>::@class::B
          enclosingElement: <testLibraryFragment>
          supertype: A
            element: <testLibrary>::@fragment::package:test/foo_io.dart::@class::A
    <testLibrary>::@fragment::package:test/foo_io.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      classes
        class A @27
          reference: <testLibrary>::@fragment::package:test/foo_io.dart::@class::A
          enclosingElement: <testLibrary>::@fragment::package:test/foo_io.dart
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/foo_io.dart
      classes
        class B @102
          reference: <testLibraryFragment>::@class::B
    <testLibrary>::@fragment::package:test/foo_io.dart
      previousFragment: <testLibraryFragment>
      classes
        class A @27
          reference: <testLibrary>::@fragment::package:test/foo_io.dart::@class::A
  classes
    class B
      reference: <testLibraryFragment>::@class::B
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@class::B
      supertype: A
        element: <testLibrary>::@fragment::package:test/foo_io.dart::@class::A
    class A
      reference: <testLibrary>::@fragment::package:test/foo_io.dart::@class::A
      enclosingElement2: <testLibrary>
      firstFragment: <testLibrary>::@fragment::package:test/foo_io.dart::@class::A
''');
  }

  test_configurations_useFirst_eqTrue() async {
    declaredVariables = {
      'dart.library.io': 'true',
      'dart.library.html': 'true',
    };

    newFile('$testPackageLibPath/foo.dart', r'''
part of 'test.dart';
class A {}
''');

    newFile('$testPackageLibPath/foo_io.dart', r'''
part of 'test.dart';
class A {}
''');

    newFile('$testPackageLibPath/foo_html.dart', r'''
part of 'test.dart';
class A {}
''');

    var library = await buildLibrary(r'''
part 'foo.dart'
  if (dart.library.io == 'true') 'foo_io.dart'
  if (dart.library.html == 'true') 'foo_html.dart';

class B extends A {}
''');

    configuration
      ..elementPrinterConfiguration.withInterfaceTypeElements = true
      ..withConstructors = false;
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
          uri: package:test/foo_io.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/foo_io.dart
      classes
        class B @122
          reference: <testLibraryFragment>::@class::B
          enclosingElement: <testLibraryFragment>
          supertype: A
            element: <testLibrary>::@fragment::package:test/foo_io.dart::@class::A
    <testLibrary>::@fragment::package:test/foo_io.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      classes
        class A @27
          reference: <testLibrary>::@fragment::package:test/foo_io.dart::@class::A
          enclosingElement: <testLibrary>::@fragment::package:test/foo_io.dart
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/foo_io.dart
      classes
        class B @122
          reference: <testLibraryFragment>::@class::B
    <testLibrary>::@fragment::package:test/foo_io.dart
      previousFragment: <testLibraryFragment>
      classes
        class A @27
          reference: <testLibrary>::@fragment::package:test/foo_io.dart::@class::A
  classes
    class B
      reference: <testLibraryFragment>::@class::B
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@class::B
      supertype: A
        element: <testLibrary>::@fragment::package:test/foo_io.dart::@class::A
    class A
      reference: <testLibrary>::@fragment::package:test/foo_io.dart::@class::A
      enclosingElement2: <testLibrary>
      firstFragment: <testLibrary>::@fragment::package:test/foo_io.dart::@class::A
''');
  }

  test_configurations_useSecond() async {
    declaredVariables = {
      'dart.library.io': 'false',
      'dart.library.html': 'true',
    };

    newFile('$testPackageLibPath/foo.dart', r'''
part of 'test.dart';
class A {}
''');

    newFile('$testPackageLibPath/foo_io.dart', r'''
part of 'test.dart';
class A {}
''');

    newFile('$testPackageLibPath/foo_html.dart', r'''
part of 'test.dart';
class A {}
''');

    var library = await buildLibrary(r'''
part 'foo.dart'
  if (dart.library.io) 'foo_io.dart'
  if (dart.library.html) 'foo_html.dart';

class B extends A {}
''');

    configuration
      ..elementPrinterConfiguration.withInterfaceTypeElements = true
      ..withConstructors = false;
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
          uri: package:test/foo_html.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/foo_html.dart
      classes
        class B @102
          reference: <testLibraryFragment>::@class::B
          enclosingElement: <testLibraryFragment>
          supertype: A
            element: <testLibrary>::@fragment::package:test/foo_html.dart::@class::A
    <testLibrary>::@fragment::package:test/foo_html.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      classes
        class A @27
          reference: <testLibrary>::@fragment::package:test/foo_html.dart::@class::A
          enclosingElement: <testLibrary>::@fragment::package:test/foo_html.dart
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/foo_html.dart
      classes
        class B @102
          reference: <testLibraryFragment>::@class::B
    <testLibrary>::@fragment::package:test/foo_html.dart
      previousFragment: <testLibraryFragment>
      classes
        class A @27
          reference: <testLibrary>::@fragment::package:test/foo_html.dart::@class::A
  classes
    class B
      reference: <testLibraryFragment>::@class::B
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@class::B
      supertype: A
        element: <testLibrary>::@fragment::package:test/foo_html.dart::@class::A
    class A
      reference: <testLibrary>::@fragment::package:test/foo_html.dart::@class::A
      enclosingElement2: <testLibrary>
      firstFragment: <testLibrary>::@fragment::package:test/foo_html.dart::@class::A
''');
  }

  test_configurations_useSecond_eqTrue() async {
    declaredVariables = {
      'dart.library.io': 'false',
      'dart.library.html': 'true',
    };

    newFile('$testPackageLibPath/foo.dart', r'''
part of 'test.dart';
class A {}
''');

    newFile('$testPackageLibPath/foo_io.dart', r'''
part of 'test.dart';
class A {}
''');

    newFile('$testPackageLibPath/foo_html.dart', r'''
part of 'test.dart';
class A {}
''');

    var library = await buildLibrary(r'''
part 'foo.dart'
  if (dart.library.io == 'true') 'foo_io.dart'
  if (dart.library.html == 'true') 'foo_html.dart';

class B extends A {}
''');

    configuration
      ..elementPrinterConfiguration.withInterfaceTypeElements = true
      ..withConstructors = false;
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
          uri: package:test/foo_html.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/foo_html.dart
      classes
        class B @122
          reference: <testLibraryFragment>::@class::B
          enclosingElement: <testLibraryFragment>
          supertype: A
            element: <testLibrary>::@fragment::package:test/foo_html.dart::@class::A
    <testLibrary>::@fragment::package:test/foo_html.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      classes
        class A @27
          reference: <testLibrary>::@fragment::package:test/foo_html.dart::@class::A
          enclosingElement: <testLibrary>::@fragment::package:test/foo_html.dart
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/foo_html.dart
      classes
        class B @122
          reference: <testLibraryFragment>::@class::B
    <testLibrary>::@fragment::package:test/foo_html.dart
      previousFragment: <testLibraryFragment>
      classes
        class A @27
          reference: <testLibrary>::@fragment::package:test/foo_html.dart::@class::A
  classes
    class B
      reference: <testLibraryFragment>::@class::B
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@class::B
      supertype: A
        element: <testLibrary>::@fragment::package:test/foo_html.dart::@class::A
    class A
      reference: <testLibrary>::@fragment::package:test/foo_html.dart::@class::A
      enclosingElement2: <testLibrary>
      firstFragment: <testLibrary>::@fragment::package:test/foo_html.dart::@class::A
''');
  }

  test_library_parts() async {
    newFile('$testPackageLibPath/a.dart', 'part of my.lib;');
    newFile('$testPackageLibPath/b.dart', 'part of my.lib;');
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
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
    <testLibrary>::@fragment::package:test/a.dart
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
    <testLibrary>::@fragment::package:test/b.dart
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
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
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      classes
        class Z @36
          reference: <testLibraryFragment>::@class::Z
    <testLibrary>::@fragment::package:test/a.dart
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/a11.dart
      classes
        class A @61
          reference: <testLibrary>::@fragment::package:test/a.dart::@class::A
    <testLibrary>::@fragment::package:test/a11.dart
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      nextFragment: <testLibrary>::@fragment::package:test/a12.dart
      classes
        class A11 @24
          reference: <testLibrary>::@fragment::package:test/a11.dart::@class::A11
    <testLibrary>::@fragment::package:test/a12.dart
      previousFragment: <testLibrary>::@fragment::package:test/a11.dart
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      classes
        class A12 @24
          reference: <testLibrary>::@fragment::package:test/a12.dart::@class::A12
    <testLibrary>::@fragment::package:test/b.dart
      previousFragment: <testLibrary>::@fragment::package:test/a12.dart
      nextFragment: <testLibrary>::@fragment::package:test/b11.dart
    <testLibrary>::@fragment::package:test/b11.dart
      previousFragment: <testLibrary>::@fragment::package:test/b.dart
      nextFragment: <testLibrary>::@fragment::package:test/b12.dart
      classes
        class B11 @24
          reference: <testLibrary>::@fragment::package:test/b11.dart::@class::B11
    <testLibrary>::@fragment::package:test/b12.dart
      previousFragment: <testLibrary>::@fragment::package:test/b11.dart
      classes
        class B12 @24
          reference: <testLibrary>::@fragment::package:test/b12.dart::@class::B12
  classes
    class Z
      reference: <testLibraryFragment>::@class::Z
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@class::Z
    class A
      reference: <testLibrary>::@fragment::package:test/a.dart::@class::A
      enclosingElement2: <testLibrary>
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@class::A
    class A11
      reference: <testLibrary>::@fragment::package:test/a11.dart::@class::A11
      enclosingElement2: <testLibrary>
      firstFragment: <testLibrary>::@fragment::package:test/a11.dart::@class::A11
    class A12
      reference: <testLibrary>::@fragment::package:test/a12.dart::@class::A12
      enclosingElement2: <testLibrary>
      firstFragment: <testLibrary>::@fragment::package:test/a12.dart::@class::A12
    class B11
      reference: <testLibrary>::@fragment::package:test/b11.dart::@class::B11
      enclosingElement2: <testLibrary>
      firstFragment: <testLibrary>::@fragment::package:test/b11.dart::@class::B11
    class B12
      reference: <testLibrary>::@fragment::package:test/b12.dart::@class::B12
      enclosingElement2: <testLibrary>
      firstFragment: <testLibrary>::@fragment::package:test/b12.dart::@class::B12
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
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      classes
        class A @37
          reference: <testLibraryFragment>::@class::A
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingFragment: <testLibraryFragment>::@class::A
    <testLibrary>::@fragment::package:test/a.dart
      previousFragment: <testLibraryFragment>
      classes
        class B @22
          reference: <testLibrary>::@fragment::package:test/a.dart::@class::B
          constructors
            synthetic new @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@class::B::@constructor::new
              enclosingFragment: <testLibrary>::@fragment::package:test/a.dart::@class::B
  classes
    class A
      reference: <testLibraryFragment>::@class::A
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
    class B
      reference: <testLibrary>::@fragment::package:test/a.dart::@class::B
      enclosingElement2: <testLibrary>
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@class::B
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@class::B::@constructor::new
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
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      classes
        class A @21
          reference: <testLibraryFragment>::@class::A
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingFragment: <testLibraryFragment>::@class::A
    <testLibrary>::@fragment::package:test/a.dart
      previousFragment: <testLibraryFragment>
      classes
        class B @27
          reference: <testLibrary>::@fragment::package:test/a.dart::@class::B
          constructors
            synthetic new @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@class::B::@constructor::new
              enclosingFragment: <testLibrary>::@fragment::package:test/a.dart::@class::B
  classes
    class A
      reference: <testLibraryFragment>::@class::A
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
    class B
      reference: <testLibrary>::@fragment::package:test/a.dart::@class::B
      enclosingElement2: <testLibrary>
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@class::B
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@class::B::@constructor::new
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
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
''');

    newFile('$testPackageLibPath/b.dart', r'''
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
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
    <testLibrary>::@fragment::package:test/a.dart
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
    <testLibrary>::@fragment::package:test/b.dart
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
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
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      classes
        class Z @36
          reference: <testLibraryFragment>::@class::Z
    <testLibrary>::@fragment::package:test/a.dart
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/a11.dart
      classes
        class A @61
          reference: <testLibrary>::@fragment::package:test/a.dart::@class::A
    <testLibrary>::@fragment::package:test/a11.dart
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      nextFragment: <testLibrary>::@fragment::package:test/a12.dart
      classes
        class A11 @24
          reference: <testLibrary>::@fragment::package:test/a11.dart::@class::A11
    <testLibrary>::@fragment::package:test/a12.dart
      previousFragment: <testLibrary>::@fragment::package:test/a11.dart
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      classes
        class A12 @24
          reference: <testLibrary>::@fragment::package:test/a12.dart::@class::A12
    <testLibrary>::@fragment::package:test/b.dart
      previousFragment: <testLibrary>::@fragment::package:test/a12.dart
      nextFragment: <testLibrary>::@fragment::package:test/b11.dart
    <testLibrary>::@fragment::package:test/b11.dart
      previousFragment: <testLibrary>::@fragment::package:test/b.dart
      nextFragment: <testLibrary>::@fragment::package:test/b12.dart
      classes
        class B11 @24
          reference: <testLibrary>::@fragment::package:test/b11.dart::@class::B11
    <testLibrary>::@fragment::package:test/b12.dart
      previousFragment: <testLibrary>::@fragment::package:test/b11.dart
      classes
        class B12 @24
          reference: <testLibrary>::@fragment::package:test/b12.dart::@class::B12
  classes
    class Z
      reference: <testLibraryFragment>::@class::Z
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@class::Z
    class A
      reference: <testLibrary>::@fragment::package:test/a.dart::@class::A
      enclosingElement2: <testLibrary>
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@class::A
    class A11
      reference: <testLibrary>::@fragment::package:test/a11.dart::@class::A11
      enclosingElement2: <testLibrary>
      firstFragment: <testLibrary>::@fragment::package:test/a11.dart::@class::A11
    class A12
      reference: <testLibrary>::@fragment::package:test/a12.dart::@class::A12
      enclosingElement2: <testLibrary>
      firstFragment: <testLibrary>::@fragment::package:test/a12.dart::@class::A12
    class B11
      reference: <testLibrary>::@fragment::package:test/b11.dart::@class::B11
      enclosingElement2: <testLibrary>
      firstFragment: <testLibrary>::@fragment::package:test/b11.dart::@class::B11
    class B12
      reference: <testLibrary>::@fragment::package:test/b12.dart::@class::B12
      enclosingElement2: <testLibrary>
      firstFragment: <testLibrary>::@fragment::package:test/b12.dart::@class::B12
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
