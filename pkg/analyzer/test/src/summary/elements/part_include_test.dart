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
    declaredVariables = {'dart.library.io': 'false'};

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
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      nextFragment: #F1
      parts
        part_0
          uri: package:test/foo.dart
          partKeywordOffset: 0
          unit: #F1
      classes
        #F2 class B (nameOffset:102) (firstTokenOffset:96) (offset:102)
          element: <testLibrary>::@class::B
    #F1 package:test/foo.dart
      element: <testLibrary>
      enclosingFragment: #F0
      previousFragment: #F0
      classes
        #F3 class A (nameOffset:27) (firstTokenOffset:21) (offset:27)
          element: <testLibrary>::@class::A
  classes
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F2
      supertype: A
        element: <testLibrary>::@class::A
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F3
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
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      nextFragment: #F1
      parts
        part_0
          uri: package:test/foo_io.dart
          partKeywordOffset: 0
          unit: #F1
      classes
        #F2 class B (nameOffset:102) (firstTokenOffset:96) (offset:102)
          element: <testLibrary>::@class::B
    #F1 package:test/foo_io.dart
      element: <testLibrary>
      enclosingFragment: #F0
      previousFragment: #F0
      classes
        #F3 class A (nameOffset:27) (firstTokenOffset:21) (offset:27)
          element: <testLibrary>::@class::A
  classes
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F2
      supertype: A
        element: <testLibrary>::@class::A
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F3
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
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      nextFragment: #F1
      parts
        part_0
          uri: package:test/foo_io.dart
          partKeywordOffset: 0
          unit: #F1
      classes
        #F2 class B (nameOffset:122) (firstTokenOffset:116) (offset:122)
          element: <testLibrary>::@class::B
    #F1 package:test/foo_io.dart
      element: <testLibrary>
      enclosingFragment: #F0
      previousFragment: #F0
      classes
        #F3 class A (nameOffset:27) (firstTokenOffset:21) (offset:27)
          element: <testLibrary>::@class::A
  classes
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F2
      supertype: A
        element: <testLibrary>::@class::A
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F3
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
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      nextFragment: #F1
      parts
        part_0
          uri: package:test/foo_html.dart
          partKeywordOffset: 0
          unit: #F1
      classes
        #F2 class B (nameOffset:102) (firstTokenOffset:96) (offset:102)
          element: <testLibrary>::@class::B
    #F1 package:test/foo_html.dart
      element: <testLibrary>
      enclosingFragment: #F0
      previousFragment: #F0
      classes
        #F3 class A (nameOffset:27) (firstTokenOffset:21) (offset:27)
          element: <testLibrary>::@class::A
  classes
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F2
      supertype: A
        element: <testLibrary>::@class::A
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F3
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
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      nextFragment: #F1
      parts
        part_0
          uri: package:test/foo_html.dart
          partKeywordOffset: 0
          unit: #F1
      classes
        #F2 class B (nameOffset:122) (firstTokenOffset:116) (offset:122)
          element: <testLibrary>::@class::B
    #F1 package:test/foo_html.dart
      element: <testLibrary>
      enclosingFragment: #F0
      previousFragment: #F0
      classes
        #F3 class A (nameOffset:27) (firstTokenOffset:21) (offset:27)
          element: <testLibrary>::@class::A
  classes
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F2
      supertype: A
        element: <testLibrary>::@class::A
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F3
''');
  }

  test_library_parts() async {
    newFile('$testPackageLibPath/a.dart', 'part of my.lib;');
    newFile('$testPackageLibPath/b.dart', 'part of my.lib;');
    var library = await buildLibrary(
      'library my.lib; part "a.dart"; part "b.dart";',
    );
    checkElementText(library, r'''
library
  reference: <testLibrary>
  name: my.lib
  fragments
    #F0 <testLibraryFragment> (nameOffset:<null>) (firstTokenOffset:0) (offset:8)
      element: <testLibrary>
      nextFragment: #F1
      parts
        part_0
          uri: package:test/a.dart
          partKeywordOffset: 16
          unit: #F1
        part_1
          uri: package:test/b.dart
          partKeywordOffset: 31
          unit: #F2
    #F1 package:test/a.dart
      element: <testLibrary>
      enclosingFragment: #F0
      previousFragment: #F0
      nextFragment: #F2
    #F2 package:test/b.dart
      element: <testLibrary>
      enclosingFragment: #F0
      previousFragment: #F1
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
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      nextFragment: #F1
      parts
        part_0
          uri: package:test/a.dart
          partKeywordOffset: 0
          unit: #F1
        part_1
          uri: package:test/b.dart
          partKeywordOffset: 15
          unit: #F2
      classes
        #F3 class Z (nameOffset:36) (firstTokenOffset:30) (offset:36)
          element: <testLibrary>::@class::Z
    #F1 package:test/a.dart
      element: <testLibrary>
      enclosingFragment: #F0
      previousFragment: #F0
      nextFragment: #F4
      parts
        part_2
          uri: package:test/a11.dart
          partKeywordOffset: 21
          unit: #F4
        part_3
          uri: package:test/a12.dart
          partKeywordOffset: 38
          unit: #F5
      classes
        #F6 class A (nameOffset:61) (firstTokenOffset:55) (offset:61)
          element: <testLibrary>::@class::A
    #F4 package:test/a11.dart
      element: <testLibrary>
      enclosingFragment: #F1
      previousFragment: #F1
      nextFragment: #F5
      classes
        #F7 class A11 (nameOffset:24) (firstTokenOffset:18) (offset:24)
          element: <testLibrary>::@class::A11
    #F5 package:test/a12.dart
      element: <testLibrary>
      enclosingFragment: #F1
      previousFragment: #F4
      nextFragment: #F2
      classes
        #F8 class A12 (nameOffset:24) (firstTokenOffset:18) (offset:24)
          element: <testLibrary>::@class::A12
    #F2 package:test/b.dart
      element: <testLibrary>
      enclosingFragment: #F0
      previousFragment: #F5
      nextFragment: #F9
      parts
        part_4
          uri: package:test/b11.dart
          partKeywordOffset: 21
          unit: #F9
        part_5
          uri: package:test/b12.dart
          partKeywordOffset: 38
          unit: #F10
    #F9 package:test/b11.dart
      element: <testLibrary>
      enclosingFragment: #F2
      previousFragment: #F2
      nextFragment: #F10
      classes
        #F11 class B11 (nameOffset:24) (firstTokenOffset:18) (offset:24)
          element: <testLibrary>::@class::B11
    #F10 package:test/b12.dart
      element: <testLibrary>
      enclosingFragment: #F2
      previousFragment: #F9
      classes
        #F12 class B12 (nameOffset:24) (firstTokenOffset:18) (offset:24)
          element: <testLibrary>::@class::B12
  classes
    class Z
      reference: <testLibrary>::@class::Z
      firstFragment: #F3
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F6
    class A11
      reference: <testLibrary>::@class::A11
      firstFragment: #F7
    class A12
      reference: <testLibrary>::@class::A12
      firstFragment: #F8
    class B11
      reference: <testLibrary>::@class::B11
      firstFragment: #F11
    class B12
      reference: <testLibrary>::@class::B12
      firstFragment: #F12
''');
  }

  test_library_parts_noRelativeUriStr() async {
    var library = await buildLibrary(r'''
part '${'foo'}.dart';
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      parts
        part_0
          uri: noRelativeUriString
          partKeywordOffset: 0
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
  reference: <testLibrary>
  name: my.lib
  fragments
    #F0 <testLibraryFragment> (nameOffset:<null>) (firstTokenOffset:0) (offset:8)
      element: <testLibrary>
      nextFragment: #F1
      parts
        part_0
          uri: package:test/a.dart
          partKeywordOffset: 16
          unit: #F1
      classes
        #F2 class A (nameOffset:37) (firstTokenOffset:31) (offset:37)
          element: <testLibrary>::@class::A
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:37)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
    #F1 package:test/a.dart
      element: <testLibrary>
      enclosingFragment: #F0
      previousFragment: #F0
      classes
        #F4 class B (nameOffset:22) (firstTokenOffset:16) (offset:22)
          element: <testLibrary>::@class::B
          constructors
            #F5 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F2
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F4
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F5
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
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      nextFragment: #F1
      parts
        part_0
          uri: package:test/a.dart
          partKeywordOffset: 0
          unit: #F1
      classes
        #F2 class A (nameOffset:21) (firstTokenOffset:15) (offset:21)
          element: <testLibrary>::@class::A
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
    #F1 package:test/a.dart
      element: <testLibrary>
      enclosingFragment: #F0
      previousFragment: #F0
      classes
        #F4 class B (nameOffset:27) (firstTokenOffset:21) (offset:27)
          element: <testLibrary>::@class::B
          constructors
            #F5 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:27)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F2
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F4
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F5
''');
  }

  test_partDirective_withRelativeUri_noSource() async {
    var library = await buildLibrary(r'''
part 'foo:bar';
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      parts
        part_0
          uri: relativeUri 'foo:bar'
          partKeywordOffset: 0
''');
  }

  test_partDirective_withRelativeUri_notPart_emptyUriSelf() async {
    var library = await buildLibrary(r'''
part '';
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      parts
        part_0
          uri: source 'package:test/test.dart'
          partKeywordOffset: 0
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
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      parts
        part_0
          uri: source 'package:test/a.dart'
          partKeywordOffset: 0
''');
  }

  test_partDirective_withRelativeUri_notPart_notExists() async {
    var library = await buildLibrary(r'''
part 'a.dart';
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      parts
        part_0
          uri: source 'package:test/a.dart'
          partKeywordOffset: 0
''');
  }

  test_partDirective_withRelativeUriString() async {
    var library = await buildLibrary(r'''
part ':';
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      parts
        part_0
          uri: relativeUriString ':'
          partKeywordOffset: 0
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
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      nextFragment: #F1
      parts
        part_0
          uri: package:test/a.dart
          partKeywordOffset: 0
          unit: #F1
        part_1
          uri: package:test/b.dart
          partKeywordOffset: 15
          unit: #F2
    #F1 package:test/a.dart
      element: <testLibrary>
      enclosingFragment: #F0
      previousFragment: #F0
      nextFragment: #F2
    #F2 package:test/b.dart
      element: <testLibrary>
      enclosingFragment: #F0
      previousFragment: #F1
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
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      nextFragment: #F1
      parts
        part_0
          uri: package:test/a.dart
          partKeywordOffset: 0
          unit: #F1
        part_1
          uri: package:test/b.dart
          partKeywordOffset: 15
          unit: #F2
      classes
        #F3 class Z (nameOffset:36) (firstTokenOffset:30) (offset:36)
          element: <testLibrary>::@class::Z
    #F1 package:test/a.dart
      element: <testLibrary>
      enclosingFragment: #F0
      previousFragment: #F0
      nextFragment: #F4
      parts
        part_2
          uri: package:test/a11.dart
          partKeywordOffset: 21
          unit: #F4
        part_3
          uri: package:test/a12.dart
          partKeywordOffset: 38
          unit: #F5
      classes
        #F6 class A (nameOffset:61) (firstTokenOffset:55) (offset:61)
          element: <testLibrary>::@class::A
    #F4 package:test/a11.dart
      element: <testLibrary>
      enclosingFragment: #F1
      previousFragment: #F1
      nextFragment: #F5
      classes
        #F7 class A11 (nameOffset:24) (firstTokenOffset:18) (offset:24)
          element: <testLibrary>::@class::A11
    #F5 package:test/a12.dart
      element: <testLibrary>
      enclosingFragment: #F1
      previousFragment: #F4
      nextFragment: #F2
      classes
        #F8 class A12 (nameOffset:24) (firstTokenOffset:18) (offset:24)
          element: <testLibrary>::@class::A12
    #F2 package:test/b.dart
      element: <testLibrary>
      enclosingFragment: #F0
      previousFragment: #F5
      nextFragment: #F9
      parts
        part_4
          uri: package:test/b11.dart
          partKeywordOffset: 21
          unit: #F9
        part_5
          uri: package:test/b12.dart
          partKeywordOffset: 38
          unit: #F10
    #F9 package:test/b11.dart
      element: <testLibrary>
      enclosingFragment: #F2
      previousFragment: #F2
      nextFragment: #F10
      classes
        #F11 class B11 (nameOffset:24) (firstTokenOffset:18) (offset:24)
          element: <testLibrary>::@class::B11
    #F10 package:test/b12.dart
      element: <testLibrary>
      enclosingFragment: #F2
      previousFragment: #F9
      classes
        #F12 class B12 (nameOffset:24) (firstTokenOffset:18) (offset:24)
          element: <testLibrary>::@class::B12
  classes
    class Z
      reference: <testLibrary>::@class::Z
      firstFragment: #F3
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F6
    class A11
      reference: <testLibrary>::@class::A11
      firstFragment: #F7
    class A12
      reference: <testLibrary>::@class::A12
      firstFragment: #F8
    class B11
      reference: <testLibrary>::@class::B11
      firstFragment: #F11
    class B12
      reference: <testLibrary>::@class::B12
      firstFragment: #F12
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
