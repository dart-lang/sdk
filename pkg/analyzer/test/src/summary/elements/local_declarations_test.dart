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
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      functions
        #F1 f (nameOffset:0) (firstTokenOffset:0) (offset:0)
          element: <testLibrary>::@function::f
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: #F1
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
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class C (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::C
          constructors
            #F2 new (nameOffset:<null>) (firstTokenOffset:12) (offset:12)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
              typeNameOffset: 12
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      constructors
        new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
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
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class C (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::C
          constructors
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          methods
            #F3 m (nameOffset:12) (firstTokenOffset:12) (offset:12)
              element: <testLibrary>::@class::C::@method::m
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
      methods
        m
          reference: <testLibrary>::@class::C::@method::m
          firstFragment: #F3
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
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 synthetic g (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@topLevelVariable::g
      getters
        #F2 g (nameOffset:4) (firstTokenOffset:0) (offset:4)
          element: <testLibrary>::@getter::g
  topLevelVariables
    synthetic g
      reference: <testLibrary>::@topLevelVariable::g
      firstFragment: #F1
      type: dynamic
      getter: <testLibrary>::@getter::g
  getters
    static g
      reference: <testLibrary>::@getter::g
      firstFragment: #F2
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::g
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
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class C (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::C
          constructors
            #F2 new (nameOffset:<null>) (firstTokenOffset:12) (offset:12)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
              typeNameOffset: 12
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      constructors
        new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
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
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class C (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::C
          constructors
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          methods
            #F3 m (nameOffset:12) (firstTokenOffset:12) (offset:12)
              element: <testLibrary>::@class::C::@method::m
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
      methods
        m
          reference: <testLibrary>::@class::C::@method::m
          firstFragment: #F3
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
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      functions
        #F1 main (nameOffset:0) (firstTokenOffset:0) (offset:0)
          element: <testLibrary>::@function::main
  functions
    main
      reference: <testLibrary>::@function::main
      firstFragment: #F1
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
