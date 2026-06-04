// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../dart/resolution/node_text_expectations.dart';
import '../elements_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(LibraryImportElementTest_keepLinking);
    defineReflectiveTests(LibraryImportElementTest_fromBytes);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

abstract class LibraryImportElementTest extends ElementsBaseTest {
  test_import_configurations_useDefault() async {
    declaredVariables = {'dart.library.io': 'false'};
    newFile('$testPackageLibPath/foo.dart', r'''
class A {}
''');
    newFile('$testPackageLibPath/foo_io.dart', r'''
class A {}
''');
    newFile('$testPackageLibPath/foo_html.dart', r'''
class A {}
''');
    var library = await buildLibrary(r'''
import 'foo.dart'
    if (dart.library.io) 'foo_io.dart'
    if (dart.library.html) 'foo_html.dart';

class B extends A {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/foo.dart
      classes
        #F1 hasExtendsClause class B (nameOffset:108) (firstTokenOffset:102) (offset:108)
          element: <testLibrary>::@class::B
          constructors
            #F2 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:108)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
  classes
    isSimplyBounded class B
      reference: <testLibrary>::@class::B
      firstFragment: #F1
      supertype: A
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F2
          superConstructor: package:test/foo.dart::@class::A::@constructor::new
''');

    var typeA = library.getClass('B')!.supertype!;
    var fragmentA = typeA.element.firstFragment;
    var sourceA = fragmentA.libraryFragment.source;
    expect(sourceA.shortName, 'foo.dart');
  }

  test_import_configurations_useFirst() async {
    declaredVariables = {
      'dart.library.io': 'true',
      'dart.library.html': 'true',
    };
    newFile('$testPackageLibPath/foo.dart', r'''
class A {}
''');
    newFile('$testPackageLibPath/foo_io.dart', r'''
class A {}
''');
    newFile('$testPackageLibPath/foo_html.dart', r'''
class A {}
''');
    var library = await buildLibrary(r'''
import 'foo.dart'
    if (dart.library.io) 'foo_io.dart'
    if (dart.library.html) 'foo_html.dart';

class B extends A {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/foo_io.dart
      classes
        #F1 hasExtendsClause class B (nameOffset:108) (firstTokenOffset:102) (offset:108)
          element: <testLibrary>::@class::B
          constructors
            #F2 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:108)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
  classes
    isSimplyBounded class B
      reference: <testLibrary>::@class::B
      firstFragment: #F1
      supertype: A
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F2
          superConstructor: package:test/foo_io.dart::@class::A::@constructor::new
''');

    var typeA = library.getClass('B')!.supertype!;
    var fragmentA = typeA.element.firstFragment;
    var sourceA = fragmentA.libraryFragment.source;
    expect(sourceA.shortName, 'foo_io.dart');
  }

  test_import_configurations_useFirst_eqTrue() async {
    declaredVariables = {
      'dart.library.io': 'true',
      'dart.library.html': 'true',
    };
    newFile('$testPackageLibPath/foo.dart', r'''
class A {}
''');
    newFile('$testPackageLibPath/foo_io.dart', r'''
class A {}
''');
    newFile('$testPackageLibPath/foo_html.dart', r'''
class A {}
''');
    var library = await buildLibrary(r'''
import 'foo.dart'
    if (dart.library.io == 'true') 'foo_io.dart'
    if (dart.library.html == 'true') 'foo_html.dart';

class B extends A {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/foo_io.dart
      classes
        #F1 hasExtendsClause class B (nameOffset:128) (firstTokenOffset:122) (offset:128)
          element: <testLibrary>::@class::B
          constructors
            #F2 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:128)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
  classes
    isSimplyBounded class B
      reference: <testLibrary>::@class::B
      firstFragment: #F1
      supertype: A
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F2
          superConstructor: package:test/foo_io.dart::@class::A::@constructor::new
''');

    var typeA = library.getClass('B')!.supertype!;
    var fragmentA = typeA.element.firstFragment;
    var sourceA = fragmentA.libraryFragment.source;
    expect(sourceA.shortName, 'foo_io.dart');
  }

  test_import_configurations_useSecond() async {
    declaredVariables = {
      'dart.library.io': 'false',
      'dart.library.html': 'true',
    };
    newFile('$testPackageLibPath/foo.dart', r'''
class A {}
''');
    newFile('$testPackageLibPath/foo_io.dart', r'''
class A {}
''');
    newFile('$testPackageLibPath/foo_html.dart', r'''
class A {}
''');
    var library = await buildLibrary(r'''
import 'foo.dart'
    if (dart.library.io) 'foo_io.dart'
    if (dart.library.html) 'foo_html.dart';

class B extends A {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/foo_html.dart
      classes
        #F1 hasExtendsClause class B (nameOffset:108) (firstTokenOffset:102) (offset:108)
          element: <testLibrary>::@class::B
          constructors
            #F2 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:108)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
  classes
    isSimplyBounded class B
      reference: <testLibrary>::@class::B
      firstFragment: #F1
      supertype: A
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F2
          superConstructor: package:test/foo_html.dart::@class::A::@constructor::new
''');

    var typeA = library.getClass('B')!.supertype!;
    var fragmentA = typeA.element.firstFragment;
    var sourceA = fragmentA.libraryFragment.source;
    expect(sourceA.shortName, 'foo_html.dart');
  }

  test_import_configurations_useSecond_eqTrue() async {
    declaredVariables = {
      'dart.library.io': 'false',
      'dart.library.html': 'true',
    };
    newFile('$testPackageLibPath/foo.dart', r'''
class A {}
''');
    newFile('$testPackageLibPath/foo_io.dart', r'''
class A {}
''');
    newFile('$testPackageLibPath/foo_html.dart', r'''
class A {}
''');
    var library = await buildLibrary(r'''
import 'foo.dart'
    if (dart.library.io == 'true') 'foo_io.dart'
    if (dart.library.html == 'true') 'foo_html.dart';

class B extends A {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/foo_html.dart
      classes
        #F1 hasExtendsClause class B (nameOffset:128) (firstTokenOffset:122) (offset:128)
          element: <testLibrary>::@class::B
          constructors
            #F2 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:128)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
  classes
    isSimplyBounded class B
      reference: <testLibrary>::@class::B
      firstFragment: #F1
      supertype: A
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F2
          superConstructor: package:test/foo_html.dart::@class::A::@constructor::new
''');

    var typeA = library.getClass('B')!.supertype!;
    var fragmentA = typeA.element.firstFragment;
    var sourceA = fragmentA.libraryFragment.source;
    expect(sourceA.shortName, 'foo_html.dart');
  }

  test_import_dartCore_explicit() async {
    var library = await buildLibrary(r'''
import 'dart:core';
import 'dart:math';
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        dart:core
        dart:math
''');
  }

  test_import_dartCore_implicit() async {
    var library = await buildLibrary(r'''
import 'dart:math';
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        dart:math
''');
  }

  test_import_deferred() async {
    newFile('$testPackageLibPath/a.dart', r'''
f() {}
''');
    var library = await buildLibrary(r'''
import 'a.dart' deferred as p;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart deferred as p (nameOffset:28) (firstTokenOffset:<null>) (offset:28)
      prefixes
        <testLibraryFragment>::@prefix::p
          fragments: @28
''');
  }

  test_import_export() async {
    var library = await buildLibrary(r'''
import 'dart:async' as i1;
export 'dart:math';
import 'dart:async' as i2;
export 'dart:math';
import 'dart:async' as i3;
export 'dart:math';
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        dart:async as i1 (nameOffset:23) (firstTokenOffset:<null>) (offset:23)
        dart:async as i2 (nameOffset:70) (firstTokenOffset:<null>) (offset:70)
        dart:async as i3 (nameOffset:117) (firstTokenOffset:<null>) (offset:117)
      prefixes
        <testLibraryFragment>::@prefix::i1
          fragments: @23
        <testLibraryFragment>::@prefix::i2
          fragments: @70
        <testLibraryFragment>::@prefix::i3
          fragments: @117
      libraryExports
        dart:math
        dart:math
        dart:math
''');
  }

  test_import_hide() async {
    var library = await buildLibrary(r'''
import 'dart:async' hide Stream, Completer;

Future f;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        dart:async
          combinators
            hide: Stream, Completer
      topLevelVariables
        #F1 isOriginDeclaration isStatic f (nameOffset:52) (firstTokenOffset:52) (offset:52)
          element: <testLibrary>::@topLevelVariable::f
          inducedGetter: #F2
          inducedSetter: #F3
      getters
        #F2 isComplete isOriginVariable isStatic f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:52)
          element: <testLibrary>::@getter::f
          inducingVariable: #F1
      setters
        #F3 isComplete isOriginVariable isStatic f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:52)
          element: <testLibrary>::@setter::f
          inducingVariable: #F1
          formalParameters
            #F4 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:52)
              element: <testLibrary>::@setter::f::@formalParameter::value
  topLevelVariables
    isOriginDeclaration isStatic f
      reference: <testLibrary>::@topLevelVariable::f
      firstFragment: #F1
      type: Future<dynamic>
      getter: <testLibrary>::@getter::f
      setter: <testLibrary>::@setter::f
  getters
    isOriginVariable isStatic f
      reference: <testLibrary>::@getter::f
      firstFragment: #F2
      returnType: Future<dynamic>
      variable: <testLibrary>::@topLevelVariable::f
  setters
    isOriginVariable isStatic f
      reference: <testLibrary>::@setter::f
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F4
          type: Future<dynamic>
      returnType: void
      variable: <testLibrary>::@topLevelVariable::f
''');
  }

  test_import_hide_offsetEnd() async {
    var library = await buildLibrary(r'''
import "dart:math" hide e, pi;
''');
    var import = library.firstFragment.libraryImports[0];
    var combinator = import.combinators[0] as HideElementCombinator;
    expect(combinator.offset, 19);
    expect(combinator.end, 29);
  }

  test_import_invalidUri_metadata() async {
    var library = await buildLibrary(r'''
@foo
import 'ht:';
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  metadata
    Annotation
      atSign: @ @0
      name: SimpleIdentifier
        token: foo @1
        element: <null>
        staticType: null
      element: <null>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        relativeUri 'ht:'
          metadata
            Annotation
              atSign: @ @0
              name: SimpleIdentifier
                token: foo @1
                element: <null>
                staticType: null
              element: <null>
''');
  }

  test_import_multiple_combinators() async {
    var library = await buildLibrary(r'''
import "dart:async" hide Stream show Future;

Future f;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        dart:async
          combinators
            hide: Stream
            show: Future
      topLevelVariables
        #F1 isOriginDeclaration isStatic f (nameOffset:53) (firstTokenOffset:53) (offset:53)
          element: <testLibrary>::@topLevelVariable::f
          inducedGetter: #F2
          inducedSetter: #F3
      getters
        #F2 isComplete isOriginVariable isStatic f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:53)
          element: <testLibrary>::@getter::f
          inducingVariable: #F1
      setters
        #F3 isComplete isOriginVariable isStatic f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:53)
          element: <testLibrary>::@setter::f
          inducingVariable: #F1
          formalParameters
            #F4 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:53)
              element: <testLibrary>::@setter::f::@formalParameter::value
  topLevelVariables
    isOriginDeclaration isStatic f
      reference: <testLibrary>::@topLevelVariable::f
      firstFragment: #F1
      type: Future<dynamic>
      getter: <testLibrary>::@getter::f
      setter: <testLibrary>::@setter::f
  getters
    isOriginVariable isStatic f
      reference: <testLibrary>::@getter::f
      firstFragment: #F2
      returnType: Future<dynamic>
      variable: <testLibrary>::@topLevelVariable::f
  setters
    isOriginVariable isStatic f
      reference: <testLibrary>::@setter::f
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F4
          type: Future<dynamic>
      returnType: void
      variable: <testLibrary>::@topLevelVariable::f
''');
  }

  test_import_prefixed() async {
    newFile('$testPackageLibPath/a.dart', r'''
library a;
class C {}
''');
    var library = await buildLibrary(r'''
import "a.dart" as a;

a.C c;
''');

    var prefixElement = library.firstFragment.libraryImports[0].prefix!;
    expect(prefixElement.nameOffset, 19);

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart as a (nameOffset:19) (firstTokenOffset:<null>) (offset:19)
      prefixes
        <testLibraryFragment>::@prefix::a
          fragments: @19
      topLevelVariables
        #F1 isOriginDeclaration isStatic c (nameOffset:27) (firstTokenOffset:27) (offset:27)
          element: <testLibrary>::@topLevelVariable::c
          inducedGetter: #F2
          inducedSetter: #F3
      getters
        #F2 isComplete isOriginVariable isStatic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:27)
          element: <testLibrary>::@getter::c
          inducingVariable: #F1
      setters
        #F3 isComplete isOriginVariable isStatic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:27)
          element: <testLibrary>::@setter::c
          inducingVariable: #F1
          formalParameters
            #F4 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:27)
              element: <testLibrary>::@setter::c::@formalParameter::value
  topLevelVariables
    isOriginDeclaration isStatic c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: #F1
      type: C
      getter: <testLibrary>::@getter::c
      setter: <testLibrary>::@setter::c
  getters
    isOriginVariable isStatic c
      reference: <testLibrary>::@getter::c
      firstFragment: #F2
      returnType: C
      variable: <testLibrary>::@topLevelVariable::c
  setters
    isOriginVariable isStatic c
      reference: <testLibrary>::@setter::c
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F4
          type: C
      returnType: void
      variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_import_prefixed_missingName() async {
    var library = await buildLibrary(r'''
import 'dart:math' as;
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        dart:math as <null-name> (nameOffset:<null>) (firstTokenOffset:<null>) (offset:0)
      prefixes
        <testLibraryFragment>::@prefix::#0
          fragments: @null
''');
  }

  test_import_self() async {
    var library = await buildLibrary(r'''
import 'test.dart' as p;

class C {}

class D extends p.C {} // Prevent "unused import" warning
''');
    var libraryImports = library.firstFragment.libraryImports;
    expect(libraryImports, hasLength(2));
    expect(libraryImports[1].importedLibrary!.isDartCore, true);
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/test.dart as p (nameOffset:22) (firstTokenOffset:<null>) (offset:22)
      prefixes
        <testLibraryFragment>::@prefix::p
          fragments: @22
      classes
        #F1 class C (nameOffset:32) (firstTokenOffset:26) (offset:32)
          element: <testLibrary>::@class::C
          constructors
            #F2 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:32)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
        #F3 hasExtendsClause class D (nameOffset:44) (firstTokenOffset:38) (offset:44)
          element: <testLibrary>::@class::D
          constructors
            #F4 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:44)
              element: <testLibrary>::@class::D::@constructor::new
              typeName: D
  classes
    isSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
    isSimplyBounded class D
      reference: <testLibrary>::@class::D
      firstFragment: #F3
      supertype: C
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::D::@constructor::new
          firstFragment: #F4
          superConstructor: <testLibrary>::@class::C::@constructor::new
''');
  }

  test_import_show() async {
    var library = await buildLibrary(r'''
import "dart:async" show Future, Stream;

Future f;
Stream s;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        dart:async
          combinators
            show: Future, Stream
      topLevelVariables
        #F1 isOriginDeclaration isStatic f (nameOffset:49) (firstTokenOffset:49) (offset:49)
          element: <testLibrary>::@topLevelVariable::f
          inducedGetter: #F2
          inducedSetter: #F3
        #F4 isOriginDeclaration isStatic s (nameOffset:59) (firstTokenOffset:59) (offset:59)
          element: <testLibrary>::@topLevelVariable::s
          inducedGetter: #F5
          inducedSetter: #F6
      getters
        #F2 isComplete isOriginVariable isStatic f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:49)
          element: <testLibrary>::@getter::f
          inducingVariable: #F1
        #F5 isComplete isOriginVariable isStatic s (nameOffset:<null>) (firstTokenOffset:<null>) (offset:59)
          element: <testLibrary>::@getter::s
          inducingVariable: #F4
      setters
        #F3 isComplete isOriginVariable isStatic f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:49)
          element: <testLibrary>::@setter::f
          inducingVariable: #F1
          formalParameters
            #F7 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:49)
              element: <testLibrary>::@setter::f::@formalParameter::value
        #F6 isComplete isOriginVariable isStatic s (nameOffset:<null>) (firstTokenOffset:<null>) (offset:59)
          element: <testLibrary>::@setter::s
          inducingVariable: #F4
          formalParameters
            #F8 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:59)
              element: <testLibrary>::@setter::s::@formalParameter::value
  topLevelVariables
    isOriginDeclaration isStatic f
      reference: <testLibrary>::@topLevelVariable::f
      firstFragment: #F1
      type: Future<dynamic>
      getter: <testLibrary>::@getter::f
      setter: <testLibrary>::@setter::f
    isOriginDeclaration isStatic s
      reference: <testLibrary>::@topLevelVariable::s
      firstFragment: #F4
      type: Stream<dynamic>
      getter: <testLibrary>::@getter::s
      setter: <testLibrary>::@setter::s
  getters
    isOriginVariable isStatic f
      reference: <testLibrary>::@getter::f
      firstFragment: #F2
      returnType: Future<dynamic>
      variable: <testLibrary>::@topLevelVariable::f
    isOriginVariable isStatic s
      reference: <testLibrary>::@getter::s
      firstFragment: #F5
      returnType: Stream<dynamic>
      variable: <testLibrary>::@topLevelVariable::s
  setters
    isOriginVariable isStatic f
      reference: <testLibrary>::@setter::f
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F7
          type: Future<dynamic>
      returnType: void
      variable: <testLibrary>::@topLevelVariable::f
    isOriginVariable isStatic s
      reference: <testLibrary>::@setter::s
      firstFragment: #F6
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F8
          type: Stream<dynamic>
      returnType: void
      variable: <testLibrary>::@topLevelVariable::s
''');
  }

  test_import_show_loadLibrary_declared() async {
    newFile('$testPackageLibPath/a.dart', r'''
void loadLibrary() {}
''');

    var library = await buildLibrary(r'''
import "a.dart" show loadLibrary;

final x = loadLibrary;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart
          combinators
            show: loadLibrary
      topLevelVariables
        #F1 hasImplicitType hasInitializer isFinal isOriginDeclaration isStatic x (nameOffset:41) (firstTokenOffset:41) (offset:41)
          element: <testLibrary>::@topLevelVariable::x
          inducedGetter: #F2
      getters
        #F2 isComplete isOriginVariable isStatic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:41)
          element: <testLibrary>::@getter::x
          inducingVariable: #F1
  topLevelVariables
    hasImplicitType hasInitializer isFinal isOriginDeclaration isStatic isTypeInferredFromInitializer x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F1
      type: void Function()
      getter: <testLibrary>::@getter::x
  getters
    isOriginVariable isStatic x
      reference: <testLibrary>::@getter::x
      firstFragment: #F2
      returnType: void Function()
      variable: <testLibrary>::@topLevelVariable::x
''');
  }

  test_import_show_offsetEnd() async {
    var library = await buildLibrary(r'''
import "dart:math" show e, pi;
''');
    var import = library.firstFragment.libraryImports[0];
    var combinator = import.combinators[0] as ShowElementCombinator;
    expect(combinator.offset, 19);
    expect(combinator.end, 29);
  }

  test_import_uri() async {
    var library = await buildLibrary(r'''
import 'foo.dart';
''');

    var libraryImports = library.firstFragment.libraryImports;
    var uri = libraryImports[0].uri as DirectiveUriWithLibrary;
    expect(uri.relativeUriString, 'foo.dart');
  }

  test_imports() async {
    newFile('$testPackageLibPath/a.dart', r'''
library a;
class C {}
''');
    newFile('$testPackageLibPath/b.dart', r'''
library b;
class D {}
''');
    var library = await buildLibrary(r'''
import "a.dart";
import "b.dart";

C c;
D d;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart
        package:test/b.dart
      topLevelVariables
        #F1 isOriginDeclaration isStatic c (nameOffset:37) (firstTokenOffset:37) (offset:37)
          element: <testLibrary>::@topLevelVariable::c
          inducedGetter: #F2
          inducedSetter: #F3
        #F4 isOriginDeclaration isStatic d (nameOffset:42) (firstTokenOffset:42) (offset:42)
          element: <testLibrary>::@topLevelVariable::d
          inducedGetter: #F5
          inducedSetter: #F6
      getters
        #F2 isComplete isOriginVariable isStatic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:37)
          element: <testLibrary>::@getter::c
          inducingVariable: #F1
        #F5 isComplete isOriginVariable isStatic d (nameOffset:<null>) (firstTokenOffset:<null>) (offset:42)
          element: <testLibrary>::@getter::d
          inducingVariable: #F4
      setters
        #F3 isComplete isOriginVariable isStatic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:37)
          element: <testLibrary>::@setter::c
          inducingVariable: #F1
          formalParameters
            #F7 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:37)
              element: <testLibrary>::@setter::c::@formalParameter::value
        #F6 isComplete isOriginVariable isStatic d (nameOffset:<null>) (firstTokenOffset:<null>) (offset:42)
          element: <testLibrary>::@setter::d
          inducingVariable: #F4
          formalParameters
            #F8 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:42)
              element: <testLibrary>::@setter::d::@formalParameter::value
  topLevelVariables
    isOriginDeclaration isStatic c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: #F1
      type: C
      getter: <testLibrary>::@getter::c
      setter: <testLibrary>::@setter::c
    isOriginDeclaration isStatic d
      reference: <testLibrary>::@topLevelVariable::d
      firstFragment: #F4
      type: D
      getter: <testLibrary>::@getter::d
      setter: <testLibrary>::@setter::d
  getters
    isOriginVariable isStatic c
      reference: <testLibrary>::@getter::c
      firstFragment: #F2
      returnType: C
      variable: <testLibrary>::@topLevelVariable::c
    isOriginVariable isStatic d
      reference: <testLibrary>::@getter::d
      firstFragment: #F5
      returnType: D
      variable: <testLibrary>::@topLevelVariable::d
  setters
    isOriginVariable isStatic c
      reference: <testLibrary>::@setter::c
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F7
          type: C
      returnType: void
      variable: <testLibrary>::@topLevelVariable::c
    isOriginVariable isStatic d
      reference: <testLibrary>::@setter::d
      firstFragment: #F6
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F8
          type: D
      returnType: void
      variable: <testLibrary>::@topLevelVariable::d
''');
  }

  test_library_imports_noRelativeUriStr() async {
    var library = await buildLibrary(r'''
import '${'foo'}.dart';
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        noRelativeUriString
''');
  }

  test_library_imports_prefix_importedLibraries() async {
    var library = await buildLibrary(r'''
import 'dart:async' as p1;
import 'dart:collection' as p2;
import 'dart:math' as p1;
''');
    var p1 = library.firstFragment.prefixes.singleWhere(
      (prefix) => prefix.name == 'p1',
    );
    var libraryImports = library.firstFragment.libraryImports;
    var import_async = libraryImports[0];
    var import_math = libraryImports[2];
    expect(p1.imports, unorderedEquals([import_async, import_math]));
  }

  test_library_imports_syntheticDartCore() async {
    var library = await buildLibrary(r'''
''');
    configuration.withSyntheticDartCoreImport = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        dart:core synthetic
''');
  }

  test_library_imports_withRelativeUri_emptyUriSelf() async {
    var library = await buildLibrary(r'''
import '';
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/test.dart
''');
  }

  test_library_imports_withRelativeUri_noSource() async {
    var library = await buildLibrary(r'''
import 'foo:bar';
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        relativeUri 'foo:bar'
''');
  }

  test_library_imports_withRelativeUri_notExists() async {
    var library = await buildLibrary(r'''
import 'a.dart';
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart
''');
  }

  test_library_imports_withRelativeUri_notLibrary_part() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of other.lib;
''');
    var library = await buildLibrary(r'''
import 'a.dart';
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        source 'package:test/a.dart'
''');
  }

  test_library_imports_withRelativeUriString() async {
    var library = await buildLibrary(r'''
import ':';
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        relativeUriString ':'
''');
  }

  test_library_prefixes() async {
    var library = await buildLibrary(r'''
import 'dart:async' as p1;
import 'dart:collection' as p2;
import 'dart:math' as p1;
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        dart:async as p1 (nameOffset:23) (firstTokenOffset:<null>) (offset:23)
        dart:collection as p2 (nameOffset:55) (firstTokenOffset:<null>) (offset:55)
        dart:math as p1 (nameOffset:81) (firstTokenOffset:<null>) (offset:81)
      prefixes
        <testLibraryFragment>::@prefix::p1
          fragments: @23 @81
        <testLibraryFragment>::@prefix::p2
          fragments: @55
''');
  }

  test_metadata_importDirective() async {
    var library = await buildLibrary(r'''
@a
import "dart:math";

const a = 0;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  metadata
    Annotation
      atSign: @ @0
      name: SimpleIdentifier
        token: a @1
        element: <testLibrary>::@getter::a
        staticType: null
      element: <testLibrary>::@getter::a
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        dart:math
          metadata
            Annotation
              atSign: @ @0
              name: SimpleIdentifier
                token: a @1
                element: <testLibrary>::@getter::a
                staticType: null
              element: <testLibrary>::@getter::a
      topLevelVariables
        #F1 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic a (nameOffset:30) (firstTokenOffset:30) (offset:30)
          element: <testLibrary>::@topLevelVariable::a
          initializer: expression_0
            IntegerLiteral
              literal: 0 @34
              staticType: int
          inducedGetter: #F2
      getters
        #F2 isComplete isOriginVariable isStatic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:30)
          element: <testLibrary>::@getter::a
          inducingVariable: #F1
  topLevelVariables
    hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F1
      type: int
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::a
  getters
    isOriginVariable isStatic a
      reference: <testLibrary>::@getter::a
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_metadata_importDirective_hasShow() async {
    var library = await buildLibrary(r'''
@a
import "dart:math" show Random;

const a = 0;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  metadata
    Annotation
      atSign: @ @0
      name: SimpleIdentifier
        token: a @1
        element: <testLibrary>::@getter::a
        staticType: null
      element: <testLibrary>::@getter::a
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        dart:math
          metadata
            Annotation
              atSign: @ @0
              name: SimpleIdentifier
                token: a @1
                element: <testLibrary>::@getter::a
                staticType: null
              element: <testLibrary>::@getter::a
          combinators
            show: Random
      topLevelVariables
        #F1 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic a (nameOffset:42) (firstTokenOffset:42) (offset:42)
          element: <testLibrary>::@topLevelVariable::a
          initializer: expression_0
            IntegerLiteral
              literal: 0 @46
              staticType: int
          inducedGetter: #F2
      getters
        #F2 isComplete isOriginVariable isStatic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:42)
          element: <testLibrary>::@getter::a
          inducingVariable: #F1
  topLevelVariables
    hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F1
      type: int
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::a
  getters
    isOriginVariable isStatic a
      reference: <testLibrary>::@getter::a
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_nameConflict_importWithRelativeUri_exportWithAbsolute() async {
    if (resourceProvider.pathContext.separator != '/') {
      return;
    }

    newFile('$testPackageLibPath/a.dart', r'''
class A {}
''');
    newFile('$testPackageLibPath/b.dart', r'''
export "/a.dart";
''');
    var library = await buildLibrary(r'''
import 'a.dart';
import 'b.dart';

A v = null;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart
        package:test/b.dart
      topLevelVariables
        #F1 hasInitializer isOriginDeclaration isStatic v (nameOffset:37) (firstTokenOffset:37) (offset:37)
          element: <testLibrary>::@topLevelVariable::v
          inducedGetter: #F2
          inducedSetter: #F3
      getters
        #F2 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:37)
          element: <testLibrary>::@getter::v
          inducingVariable: #F1
      setters
        #F3 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:37)
          element: <testLibrary>::@setter::v
          inducingVariable: #F1
          formalParameters
            #F4 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:37)
              element: <testLibrary>::@setter::v::@formalParameter::value
  topLevelVariables
    hasInitializer isOriginDeclaration isStatic v
      reference: <testLibrary>::@topLevelVariable::v
      firstFragment: #F1
      type: A
      getter: <testLibrary>::@getter::v
      setter: <testLibrary>::@setter::v
  getters
    isOriginVariable isStatic v
      reference: <testLibrary>::@getter::v
      firstFragment: #F2
      returnType: A
      variable: <testLibrary>::@topLevelVariable::v
  setters
    isOriginVariable isStatic v
      reference: <testLibrary>::@setter::v
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F4
          type: A
      returnType: void
      variable: <testLibrary>::@topLevelVariable::v
''');
  }

  test_unresolved_import() async {
    var library = await buildLibrary(r'''
import 'foo.dart';
''');
    var libraryImports = library.firstFragment.libraryImports;
    var importedLibrary = libraryImports[0].importedLibrary!;
    expect(importedLibrary.loadLibraryFunction, isNotNull);
    expect(importedLibrary.publicNamespace, isNotNull);
    expect(importedLibrary.exportNamespace, isNotNull);
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/foo.dart
''');
  }
}

@reflectiveTest
class LibraryImportElementTest_fromBytes extends LibraryImportElementTest {
  @override
  bool get keepLinkingLibraries => false;
}

@reflectiveTest
class LibraryImportElementTest_keepLinking extends LibraryImportElementTest {
  @override
  bool get keepLinkingLibraries => true;
}
