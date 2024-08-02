// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../dart/resolution/node_text_expectations.dart';
import '../elements_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(LocalDeclarationElementTest_keepLinking);
    defineReflectiveTests(LocalDeclarationElementTest_fromBytes);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

abstract class LocalDeclarationElementTest extends ElementsBaseTest {
  test_localFunctions() async {
    var library = await buildLibrary(r'''
f() {
  f1() {}
  {
    f2() {}
  }
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      functions
        f @0
          reference: <testLibraryFragment>::@function::f
          enclosingElement: <testLibraryFragment>
          returnType: dynamic
''');
  }

  test_localFunctions_inConstructor() async {
    var library = await buildLibrary(r'''
class C {
  C() {
    f() {}
  }
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          constructors
            @12
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
''');
  }

  test_localFunctions_inMethod() async {
    var library = await buildLibrary(r'''
class C {
  m() {
    f() {}
  }
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
          methods
            m @12
              reference: <testLibraryFragment>::@class::C::@method::m
              enclosingElement: <testLibraryFragment>::@class::C
              returnType: dynamic
''');
  }

  test_localFunctions_inTopLevelGetter() async {
    var library = await buildLibrary(r'''
get g {
  f() {}
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      topLevelVariables
        synthetic static g @-1
          reference: <testLibraryFragment>::@topLevelVariable::g
          enclosingElement: <testLibraryFragment>
          type: dynamic
      accessors
        static get g @4
          reference: <testLibraryFragment>::@getter::g
          enclosingElement: <testLibraryFragment>
          returnType: dynamic
''');
  }

  test_localLabels_inConstructor() async {
    var library = await buildLibrary(r'''
class C {
  C() {
    aaa: while (true) {}
    bbb: switch (42) {
      ccc: case 0:
        break;
    }
  }
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          constructors
            @12
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
''');
  }

  test_localLabels_inMethod() async {
    var library = await buildLibrary(r'''
class C {
  m() {
    aaa: while (true) {}
    bbb: switch (42) {
      ccc: case 0:
        break;
    }
  }
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
          methods
            m @12
              reference: <testLibraryFragment>::@class::C::@method::m
              enclosingElement: <testLibraryFragment>::@class::C
              returnType: dynamic
''');
  }

  test_localLabels_inTopLevelFunction() async {
    var library = await buildLibrary(r'''
main() {
  aaa: while (true) {}
  bbb: switch (42) {
    ccc: case 0:
      break;
  }
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      functions
        main @0
          reference: <testLibraryFragment>::@function::main
          enclosingElement: <testLibraryFragment>
          returnType: dynamic
''');
  }
}

@reflectiveTest
class LocalDeclarationElementTest_fromBytes
    extends LocalDeclarationElementTest {
  @override
  bool get keepLinkingLibraries => false;
}

@reflectiveTest
class LocalDeclarationElementTest_keepLinking
    extends LocalDeclarationElementTest {
  @override
  bool get keepLinkingLibraries => true;
}
