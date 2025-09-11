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
    newFile('$testPackageLibPath/foo.dart', 'class A {}');
    newFile('$testPackageLibPath/foo_io.dart', 'class A {}');
    newFile('$testPackageLibPath/foo_html.dart', 'class A {}');
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
        #F1 class B (nameOffset:104) (firstTokenOffset:98) (offset:104)
          element: <testLibrary>::@class::B
          constructors
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:104)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
  classes
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F1
      supertype: A
      constructors
        synthetic new
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
    newFile('$testPackageLibPath/foo.dart', 'class A {}');
    newFile('$testPackageLibPath/foo_io.dart', 'class A {}');
    newFile('$testPackageLibPath/foo_html.dart', 'class A {}');
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
        #F1 class B (nameOffset:104) (firstTokenOffset:98) (offset:104)
          element: <testLibrary>::@class::B
          constructors
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:104)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
  classes
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F1
      supertype: A
      constructors
        synthetic new
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
    newFile('$testPackageLibPath/foo.dart', 'class A {}');
    newFile('$testPackageLibPath/foo_io.dart', 'class A {}');
    newFile('$testPackageLibPath/foo_html.dart', 'class A {}');
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
        #F1 class B (nameOffset:124) (firstTokenOffset:118) (offset:124)
          element: <testLibrary>::@class::B
          constructors
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:124)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
  classes
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F1
      supertype: A
      constructors
        synthetic new
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
    newFile('$testPackageLibPath/foo.dart', 'class A {}');
    newFile('$testPackageLibPath/foo_io.dart', 'class A {}');
    newFile('$testPackageLibPath/foo_html.dart', 'class A {}');
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
        #F1 class B (nameOffset:104) (firstTokenOffset:98) (offset:104)
          element: <testLibrary>::@class::B
          constructors
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:104)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
  classes
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F1
      supertype: A
      constructors
        synthetic new
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
    newFile('$testPackageLibPath/foo.dart', 'class A {}');
    newFile('$testPackageLibPath/foo_io.dart', 'class A {}');
    newFile('$testPackageLibPath/foo_html.dart', 'class A {}');
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
        #F1 class B (nameOffset:124) (firstTokenOffset:118) (offset:124)
          element: <testLibrary>::@class::B
          constructors
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:124)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
  classes
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F1
      supertype: A
      constructors
        synthetic new
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
    var library = await buildLibrary('''
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
    var library = await buildLibrary('''
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
    newFile('$testPackageLibPath/a.dart', 'f() {}');
    var library = await buildLibrary('''
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
        <testLibraryFragment>::@prefix2::p
          fragments: @28
''');
  }

  test_import_export() async {
    var library = await buildLibrary('''
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
        <testLibraryFragment>::@prefix2::i1
          fragments: @23
        <testLibraryFragment>::@prefix2::i2
          fragments: @70
        <testLibraryFragment>::@prefix2::i3
          fragments: @117
      libraryExports
        dart:math
        dart:math
        dart:math
''');
  }

  test_import_hide() async {
    var library = await buildLibrary('''
import 'dart:async' hide Stream, Completer; Future f;
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
        #F1 f (nameOffset:51) (firstTokenOffset:51) (offset:51)
          element: <testLibrary>::@topLevelVariable::f
      getters
        #F2 synthetic f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:51)
          element: <testLibrary>::@getter::f
      setters
        #F3 synthetic f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:51)
          element: <testLibrary>::@setter::f
          formalParameters
            #F4 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:51)
              element: <testLibrary>::@setter::f::@formalParameter::value
  topLevelVariables
    f
      reference: <testLibrary>::@topLevelVariable::f
      firstFragment: #F1
      type: Future<dynamic>
      getter: <testLibrary>::@getter::f
      setter: <testLibrary>::@setter::f
  getters
    synthetic static f
      reference: <testLibrary>::@getter::f
      firstFragment: #F2
      returnType: Future<dynamic>
      variable: <testLibrary>::@topLevelVariable::f
  setters
    synthetic static f
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
    var library = await buildLibrary('''
import "dart:math" hide e, pi;
''');
    var import = library.firstFragment.libraryImports[0];
    var combinator = import.combinators[0] as HideElementCombinator;
    expect(combinator.offset, 19);
    expect(combinator.end, 29);
  }

  test_import_invalidUri_metadata() async {
    var library = await buildLibrary('''
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
      element2: <null>
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
              element2: <null>
''');
  }

  test_import_multiple_combinators() async {
    var library = await buildLibrary('''
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
        #F1 f (nameOffset:52) (firstTokenOffset:52) (offset:52)
          element: <testLibrary>::@topLevelVariable::f
      getters
        #F2 synthetic f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:52)
          element: <testLibrary>::@getter::f
      setters
        #F3 synthetic f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:52)
          element: <testLibrary>::@setter::f
          formalParameters
            #F4 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:52)
              element: <testLibrary>::@setter::f::@formalParameter::value
  topLevelVariables
    f
      reference: <testLibrary>::@topLevelVariable::f
      firstFragment: #F1
      type: Future<dynamic>
      getter: <testLibrary>::@getter::f
      setter: <testLibrary>::@setter::f
  getters
    synthetic static f
      reference: <testLibrary>::@getter::f
      firstFragment: #F2
      returnType: Future<dynamic>
      variable: <testLibrary>::@topLevelVariable::f
  setters
    synthetic static f
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
    newFile('$testPackageLibPath/a.dart', 'library a; class C {}');
    var library = await buildLibrary('import "a.dart" as a; a.C c;');

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
        <testLibraryFragment>::@prefix2::a
          fragments: @19
      topLevelVariables
        #F1 c (nameOffset:26) (firstTokenOffset:26) (offset:26)
          element: <testLibrary>::@topLevelVariable::c
      getters
        #F2 synthetic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:26)
          element: <testLibrary>::@getter::c
      setters
        #F3 synthetic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:26)
          element: <testLibrary>::@setter::c
          formalParameters
            #F4 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:26)
              element: <testLibrary>::@setter::c::@formalParameter::value
  topLevelVariables
    c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: #F1
      type: C
      getter: <testLibrary>::@getter::c
      setter: <testLibrary>::@setter::c
  getters
    synthetic static c
      reference: <testLibrary>::@getter::c
      firstFragment: #F2
      returnType: C
      variable: <testLibrary>::@topLevelVariable::c
  setters
    synthetic static c
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
        <testLibraryFragment>::@prefix2::0
          fragments: @null
''');
  }

  test_import_self() async {
    var library = await buildLibrary('''
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
        <testLibraryFragment>::@prefix2::p
          fragments: @22
      classes
        #F1 class C (nameOffset:31) (firstTokenOffset:25) (offset:31)
          element: <testLibrary>::@class::C
          constructors
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
        #F3 class D (nameOffset:42) (firstTokenOffset:36) (offset:42)
          element: <testLibrary>::@class::D
          constructors
            #F4 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:42)
              element: <testLibrary>::@class::D::@constructor::new
              typeName: D
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
    class D
      reference: <testLibrary>::@class::D
      firstFragment: #F3
      supertype: C
      constructors
        synthetic new
          reference: <testLibrary>::@class::D::@constructor::new
          firstFragment: #F4
          superConstructor: <testLibrary>::@class::C::@constructor::new
''');
  }

  test_import_show() async {
    var library = await buildLibrary('''
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
        #F1 f (nameOffset:48) (firstTokenOffset:48) (offset:48)
          element: <testLibrary>::@topLevelVariable::f
        #F2 s (nameOffset:58) (firstTokenOffset:58) (offset:58)
          element: <testLibrary>::@topLevelVariable::s
      getters
        #F3 synthetic f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:48)
          element: <testLibrary>::@getter::f
        #F4 synthetic s (nameOffset:<null>) (firstTokenOffset:<null>) (offset:58)
          element: <testLibrary>::@getter::s
      setters
        #F5 synthetic f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:48)
          element: <testLibrary>::@setter::f
          formalParameters
            #F6 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:48)
              element: <testLibrary>::@setter::f::@formalParameter::value
        #F7 synthetic s (nameOffset:<null>) (firstTokenOffset:<null>) (offset:58)
          element: <testLibrary>::@setter::s
          formalParameters
            #F8 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:58)
              element: <testLibrary>::@setter::s::@formalParameter::value
  topLevelVariables
    f
      reference: <testLibrary>::@topLevelVariable::f
      firstFragment: #F1
      type: Future<dynamic>
      getter: <testLibrary>::@getter::f
      setter: <testLibrary>::@setter::f
    s
      reference: <testLibrary>::@topLevelVariable::s
      firstFragment: #F2
      type: Stream<dynamic>
      getter: <testLibrary>::@getter::s
      setter: <testLibrary>::@setter::s
  getters
    synthetic static f
      reference: <testLibrary>::@getter::f
      firstFragment: #F3
      returnType: Future<dynamic>
      variable: <testLibrary>::@topLevelVariable::f
    synthetic static s
      reference: <testLibrary>::@getter::s
      firstFragment: #F4
      returnType: Stream<dynamic>
      variable: <testLibrary>::@topLevelVariable::s
  setters
    synthetic static f
      reference: <testLibrary>::@setter::f
      firstFragment: #F5
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F6
          type: Future<dynamic>
      returnType: void
      variable: <testLibrary>::@topLevelVariable::f
    synthetic static s
      reference: <testLibrary>::@setter::s
      firstFragment: #F7
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F8
          type: Stream<dynamic>
      returnType: void
      variable: <testLibrary>::@topLevelVariable::s
''');
  }

  test_import_show_offsetEnd() async {
    var library = await buildLibrary('''
import "dart:math" show e, pi;
''');
    var import = library.firstFragment.libraryImports[0];
    var combinator = import.combinators[0] as ShowElementCombinator;
    expect(combinator.offset, 19);
    expect(combinator.end, 29);
  }

  test_import_uri() async {
    var library = await buildLibrary('''
import 'foo.dart';
''');

    var libraryImports = library.firstFragment.libraryImports;
    var uri = libraryImports[0].uri as DirectiveUriWithLibrary;
    expect(uri.relativeUriString, 'foo.dart');
  }

  test_imports() async {
    newFile('$testPackageLibPath/a.dart', 'library a; class C {}');
    newFile('$testPackageLibPath/b.dart', 'library b; class D {}');
    var library = await buildLibrary(
      'import "a.dart"; import "b.dart"; C c; D d;',
    );
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
        #F1 c (nameOffset:36) (firstTokenOffset:36) (offset:36)
          element: <testLibrary>::@topLevelVariable::c
        #F2 d (nameOffset:41) (firstTokenOffset:41) (offset:41)
          element: <testLibrary>::@topLevelVariable::d
      getters
        #F3 synthetic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:36)
          element: <testLibrary>::@getter::c
        #F4 synthetic d (nameOffset:<null>) (firstTokenOffset:<null>) (offset:41)
          element: <testLibrary>::@getter::d
      setters
        #F5 synthetic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:36)
          element: <testLibrary>::@setter::c
          formalParameters
            #F6 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:36)
              element: <testLibrary>::@setter::c::@formalParameter::value
        #F7 synthetic d (nameOffset:<null>) (firstTokenOffset:<null>) (offset:41)
          element: <testLibrary>::@setter::d
          formalParameters
            #F8 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:41)
              element: <testLibrary>::@setter::d::@formalParameter::value
  topLevelVariables
    c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: #F1
      type: C
      getter: <testLibrary>::@getter::c
      setter: <testLibrary>::@setter::c
    d
      reference: <testLibrary>::@topLevelVariable::d
      firstFragment: #F2
      type: D
      getter: <testLibrary>::@getter::d
      setter: <testLibrary>::@setter::d
  getters
    synthetic static c
      reference: <testLibrary>::@getter::c
      firstFragment: #F3
      returnType: C
      variable: <testLibrary>::@topLevelVariable::c
    synthetic static d
      reference: <testLibrary>::@getter::d
      firstFragment: #F4
      returnType: D
      variable: <testLibrary>::@topLevelVariable::d
  setters
    synthetic static c
      reference: <testLibrary>::@setter::c
      firstFragment: #F5
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F6
          type: C
      returnType: void
      variable: <testLibrary>::@topLevelVariable::c
    synthetic static d
      reference: <testLibrary>::@setter::d
      firstFragment: #F7
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
    var library = await buildLibrary('');
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
        <testLibraryFragment>::@prefix2::p1
          fragments: @23 @81
        <testLibraryFragment>::@prefix2::p2
          fragments: @55
''');
  }

  test_metadata_importDirective() async {
    var library = await buildLibrary('''
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
      element2: <testLibrary>::@getter::a
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
              element2: <testLibrary>::@getter::a
      topLevelVariables
        #F1 hasInitializer a (nameOffset:29) (firstTokenOffset:29) (offset:29)
          element: <testLibrary>::@topLevelVariable::a
          initializer: expression_0
            IntegerLiteral
              literal: 0 @33
              staticType: int
      getters
        #F2 synthetic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:29)
          element: <testLibrary>::@getter::a
  topLevelVariables
    const hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F1
      type: int
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::a
  getters
    synthetic static a
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
      element2: <testLibrary>::@getter::a
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
              element2: <testLibrary>::@getter::a
          combinators
            show: Random
      topLevelVariables
        #F1 hasInitializer a (nameOffset:42) (firstTokenOffset:42) (offset:42)
          element: <testLibrary>::@topLevelVariable::a
          initializer: expression_0
            IntegerLiteral
              literal: 0 @46
              staticType: int
      getters
        #F2 synthetic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:42)
          element: <testLibrary>::@getter::a
  topLevelVariables
    const hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F1
      type: int
      constantInitializer
        fragment: #F1
        expression: expression_0
      getter: <testLibrary>::@getter::a
  getters
    synthetic static a
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

    newFile('$testPackageLibPath/a.dart', 'class A {}');
    newFile('$testPackageLibPath/b.dart', 'export "/a.dart";');
    var library = await buildLibrary('''
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
        #F1 hasInitializer v (nameOffset:36) (firstTokenOffset:36) (offset:36)
          element: <testLibrary>::@topLevelVariable::v
      getters
        #F2 synthetic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:36)
          element: <testLibrary>::@getter::v
      setters
        #F3 synthetic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:36)
          element: <testLibrary>::@setter::v
          formalParameters
            #F4 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:36)
              element: <testLibrary>::@setter::v::@formalParameter::value
  topLevelVariables
    hasInitializer v
      reference: <testLibrary>::@topLevelVariable::v
      firstFragment: #F1
      type: A
      getter: <testLibrary>::@getter::v
      setter: <testLibrary>::@setter::v
  getters
    synthetic static v
      reference: <testLibrary>::@getter::v
      firstFragment: #F2
      returnType: A
      variable: <testLibrary>::@topLevelVariable::v
  setters
    synthetic static v
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
    var library = await buildLibrary("import 'foo.dart';");
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
