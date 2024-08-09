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
    declaredVariables = {
      'dart.library.io': 'false',
    };
    addSource('$testPackageLibPath/foo.dart', 'class A {}');
    addSource('$testPackageLibPath/foo_io.dart', 'class A {}');
    addSource('$testPackageLibPath/foo_html.dart', 'class A {}');
    var library = await buildLibrary(r'''
import 'foo.dart'
  if (dart.library.io) 'foo_io.dart'
  if (dart.library.html) 'foo_html.dart';

class B extends A {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/foo.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryImports
        package:test/foo.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
      classes
        class B @104
          reference: <testLibraryFragment>::@class::B
          enclosingElement: <testLibraryFragment>
          supertype: A
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::B::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::B
              superConstructor: package:test/foo.dart::<fragment>::@class::A::@constructor::new
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      libraryImports
        package:test/foo.dart
''');
    var typeA = library.definingCompilationUnit.getClass('B')!.supertype!;
    expect(typeA.element.source.shortName, 'foo.dart');
  }

  test_import_configurations_useFirst() async {
    declaredVariables = {
      'dart.library.io': 'true',
      'dart.library.html': 'true',
    };
    addSource('$testPackageLibPath/foo.dart', 'class A {}');
    addSource('$testPackageLibPath/foo_io.dart', 'class A {}');
    addSource('$testPackageLibPath/foo_html.dart', 'class A {}');
    var library = await buildLibrary(r'''
import 'foo.dart'
  if (dart.library.io) 'foo_io.dart'
  if (dart.library.html) 'foo_html.dart';

class B extends A {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/foo_io.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryImports
        package:test/foo_io.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
      classes
        class B @104
          reference: <testLibraryFragment>::@class::B
          enclosingElement: <testLibraryFragment>
          supertype: A
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::B::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::B
              superConstructor: package:test/foo_io.dart::<fragment>::@class::A::@constructor::new
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      libraryImports
        package:test/foo_io.dart
''');
    var typeA = library.definingCompilationUnit.getClass('B')!.supertype!;
    expect(typeA.element.source.shortName, 'foo_io.dart');
  }

  test_import_configurations_useFirst_eqTrue() async {
    declaredVariables = {
      'dart.library.io': 'true',
      'dart.library.html': 'true',
    };
    addSource('$testPackageLibPath/foo.dart', 'class A {}');
    addSource('$testPackageLibPath/foo_io.dart', 'class A {}');
    addSource('$testPackageLibPath/foo_html.dart', 'class A {}');
    var library = await buildLibrary(r'''
import 'foo.dart'
  if (dart.library.io == 'true') 'foo_io.dart'
  if (dart.library.html == 'true') 'foo_html.dart';

class B extends A {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/foo_io.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryImports
        package:test/foo_io.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
      classes
        class B @124
          reference: <testLibraryFragment>::@class::B
          enclosingElement: <testLibraryFragment>
          supertype: A
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::B::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::B
              superConstructor: package:test/foo_io.dart::<fragment>::@class::A::@constructor::new
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      libraryImports
        package:test/foo_io.dart
''');
    var typeA = library.definingCompilationUnit.getClass('B')!.supertype!;
    expect(typeA.element.source.shortName, 'foo_io.dart');
  }

  test_import_configurations_useSecond() async {
    declaredVariables = {
      'dart.library.io': 'false',
      'dart.library.html': 'true',
    };
    addSource('$testPackageLibPath/foo.dart', 'class A {}');
    addSource('$testPackageLibPath/foo_io.dart', 'class A {}');
    addSource('$testPackageLibPath/foo_html.dart', 'class A {}');
    var library = await buildLibrary(r'''
import 'foo.dart'
  if (dart.library.io) 'foo_io.dart'
  if (dart.library.html) 'foo_html.dart';

class B extends A {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/foo_html.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryImports
        package:test/foo_html.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
      classes
        class B @104
          reference: <testLibraryFragment>::@class::B
          enclosingElement: <testLibraryFragment>
          supertype: A
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::B::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::B
              superConstructor: package:test/foo_html.dart::<fragment>::@class::A::@constructor::new
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      libraryImports
        package:test/foo_html.dart
''');
    var typeA = library.definingCompilationUnit.getClass('B')!.supertype!;
    expect(typeA.element.source.shortName, 'foo_html.dart');
  }

  test_import_configurations_useSecond_eqTrue() async {
    declaredVariables = {
      'dart.library.io': 'false',
      'dart.library.html': 'true',
    };
    addSource('$testPackageLibPath/foo.dart', 'class A {}');
    addSource('$testPackageLibPath/foo_io.dart', 'class A {}');
    addSource('$testPackageLibPath/foo_html.dart', 'class A {}');
    var library = await buildLibrary(r'''
import 'foo.dart'
  if (dart.library.io == 'true') 'foo_io.dart'
  if (dart.library.html == 'true') 'foo_html.dart';

class B extends A {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/foo_html.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryImports
        package:test/foo_html.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
      classes
        class B @124
          reference: <testLibraryFragment>::@class::B
          enclosingElement: <testLibraryFragment>
          supertype: A
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::B::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::B
              superConstructor: package:test/foo_html.dart::<fragment>::@class::A::@constructor::new
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      libraryImports
        package:test/foo_html.dart
''');
    var typeA = library.definingCompilationUnit.getClass('B')!.supertype!;
    expect(typeA.element.source.shortName, 'foo_html.dart');
  }

  test_import_dartCore_explicit() async {
    var library = await buildLibrary('''
import 'dart:core';
import 'dart:math';
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    dart:core
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
    dart:math
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryImports
        dart:core
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
        dart:math
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
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
  libraryImports
    dart:math
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryImports
        dart:math
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      libraryImports
        dart:math
''');
  }

  test_import_deferred() async {
    addSource('$testPackageLibPath/a.dart', 'f() {}');
    var library = await buildLibrary('''
import 'a.dart' deferred as p;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/a.dart deferred as p @28
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  prefixes
    p @28
      reference: <testLibraryFragment>::@prefix::p
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryImports
        package:test/a.dart deferred as p @28
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
      libraryImportPrefixes
        p @28
          reference: <testLibraryFragment>::@prefix::p
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      libraryImports
        package:test/a.dart
      prefixes
        p
          reference: <testLibraryFragment>::@prefix::p
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
  libraryImports
    dart:async as i1 @23
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
    dart:async as i2 @70
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
    dart:async as i3 @117
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  prefixes
    i1 @23
      reference: <testLibraryFragment>::@prefix::i1
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
    i2 @70
      reference: <testLibraryFragment>::@prefix::i2
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
    i3 @117
      reference: <testLibraryFragment>::@prefix::i3
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  libraryExports
    dart:math
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
    dart:math
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
    dart:math
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryImports
        dart:async as i1 @23
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
        dart:async as i2 @70
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
        dart:async as i3 @117
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
      libraryImportPrefixes
        i1 @23
          reference: <testLibraryFragment>::@prefix::i1
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
        i2 @70
          reference: <testLibraryFragment>::@prefix::i2
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
        i3 @117
          reference: <testLibraryFragment>::@prefix::i3
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
      libraryExports
        dart:math
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
        dart:math
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
        dart:math
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      libraryImports
        dart:async
        dart:async
        dart:async
      prefixes
        i1
          reference: <testLibraryFragment>::@prefix::i1
        i2
          reference: <testLibraryFragment>::@prefix::i2
        i3
          reference: <testLibraryFragment>::@prefix::i3
''');
  }

  test_import_hide() async {
    var library = await buildLibrary('''
import 'dart:async' hide Stream, Completer; Future f;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    dart:async
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      combinators
        hide: Stream, Completer
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryImports
        dart:async
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          combinators
            hide: Stream, Completer
      topLevelVariables
        static f @51
          reference: <testLibraryFragment>::@topLevelVariable::f
          enclosingElement: <testLibraryFragment>
          type: Future<dynamic>
      accessors
        synthetic static get f @-1
          reference: <testLibraryFragment>::@getter::f
          enclosingElement: <testLibraryFragment>
          returnType: Future<dynamic>
        synthetic static set f= @-1
          reference: <testLibraryFragment>::@setter::f
          enclosingElement: <testLibraryFragment>
          parameters
            requiredPositional _f @-1
              type: Future<dynamic>
          returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      libraryImports
        dart:async
''');
  }

  test_import_hide_offsetEnd() async {
    var library = await buildLibrary('''
import "dart:math" hide e, pi;
''');
    var import = library.libraryImports[0];
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
        staticElement: <null>
        staticType: null
      element: <null>
  libraryImports
    relativeUri 'ht:'
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      metadata
        Annotation
          atSign: @ @0
          name: SimpleIdentifier
            token: foo @1
            staticElement: <null>
            staticType: null
          element: <null>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryImports
        relativeUri 'ht:'
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @0
              name: SimpleIdentifier
                token: foo @1
                staticElement: <null>
                staticType: null
              element: <null>
----------------------------------------
library
  reference: <testLibrary>
  metadata
    Annotation
      atSign: @ @0
      name: SimpleIdentifier
        token: foo @1
        staticElement: <null>
        staticType: null
      element: <null>
  fragments
    <testLibraryFragment>
      libraryImports
        relativeUri 'ht:'
          metadata
            Annotation
              atSign: @ @0
              name: SimpleIdentifier
                token: foo @1
                staticElement: <null>
                staticType: null
              element: <null>
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
  libraryImports
    dart:async
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      combinators
        hide: Stream
        show: Future
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryImports
        dart:async
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          combinators
            hide: Stream
            show: Future
      topLevelVariables
        static f @52
          reference: <testLibraryFragment>::@topLevelVariable::f
          enclosingElement: <testLibraryFragment>
          type: Future<dynamic>
      accessors
        synthetic static get f @-1
          reference: <testLibraryFragment>::@getter::f
          enclosingElement: <testLibraryFragment>
          returnType: Future<dynamic>
        synthetic static set f= @-1
          reference: <testLibraryFragment>::@setter::f
          enclosingElement: <testLibraryFragment>
          parameters
            requiredPositional _f @-1
              type: Future<dynamic>
          returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      libraryImports
        dart:async
''');
  }

  test_import_prefixed() async {
    addSource('$testPackageLibPath/a.dart', 'library a; class C {}');
    var library = await buildLibrary('import "a.dart" as a; a.C c;');

    var prefixElement = library.libraryImports[0].prefix!.element;
    expect(prefixElement.nameOffset, 19);

    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/a.dart as a @19
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  prefixes
    a @19
      reference: <testLibraryFragment>::@prefix::a
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryImports
        package:test/a.dart as a @19
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
      libraryImportPrefixes
        a @19
          reference: <testLibraryFragment>::@prefix::a
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
      topLevelVariables
        static c @26
          reference: <testLibraryFragment>::@topLevelVariable::c
          enclosingElement: <testLibraryFragment>
          type: C
      accessors
        synthetic static get c @-1
          reference: <testLibraryFragment>::@getter::c
          enclosingElement: <testLibraryFragment>
          returnType: C
        synthetic static set c= @-1
          reference: <testLibraryFragment>::@setter::c
          enclosingElement: <testLibraryFragment>
          parameters
            requiredPositional _c @-1
              type: C
          returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      libraryImports
        package:test/a.dart
      prefixes
        a
          reference: <testLibraryFragment>::@prefix::a
''');
  }

  test_import_self() async {
    var library = await buildLibrary('''
import 'test.dart' as p;
class C {}
class D extends p.C {} // Prevent "unused import" warning
''');
    expect(library.libraryImports, hasLength(2));
    expect(
        library.libraryImports[0].importedLibrary!.location, library.location);
    expect(library.libraryImports[1].importedLibrary!.isDartCore, true);
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/test.dart as p @22
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  prefixes
    p @22
      reference: <testLibraryFragment>::@prefix::p
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryImports
        package:test/test.dart as p @22
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
      libraryImportPrefixes
        p @22
          reference: <testLibraryFragment>::@prefix::p
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
      classes
        class C @31
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
        class D @42
          reference: <testLibraryFragment>::@class::D
          enclosingElement: <testLibraryFragment>
          supertype: C
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::D::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::D
              superConstructor: <testLibraryFragment>::@class::C::@constructor::new
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      libraryImports
        package:test/test.dart
      prefixes
        p
          reference: <testLibraryFragment>::@prefix::p
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
  libraryImports
    dart:async
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      combinators
        show: Future, Stream
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryImports
        dart:async
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          combinators
            show: Future, Stream
      topLevelVariables
        static f @48
          reference: <testLibraryFragment>::@topLevelVariable::f
          enclosingElement: <testLibraryFragment>
          type: Future<dynamic>
        static s @58
          reference: <testLibraryFragment>::@topLevelVariable::s
          enclosingElement: <testLibraryFragment>
          type: Stream<dynamic>
      accessors
        synthetic static get f @-1
          reference: <testLibraryFragment>::@getter::f
          enclosingElement: <testLibraryFragment>
          returnType: Future<dynamic>
        synthetic static set f= @-1
          reference: <testLibraryFragment>::@setter::f
          enclosingElement: <testLibraryFragment>
          parameters
            requiredPositional _f @-1
              type: Future<dynamic>
          returnType: void
        synthetic static get s @-1
          reference: <testLibraryFragment>::@getter::s
          enclosingElement: <testLibraryFragment>
          returnType: Stream<dynamic>
        synthetic static set s= @-1
          reference: <testLibraryFragment>::@setter::s
          enclosingElement: <testLibraryFragment>
          parameters
            requiredPositional _s @-1
              type: Stream<dynamic>
          returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      libraryImports
        dart:async
''');
  }

  test_import_show_offsetEnd() async {
    var library = await buildLibrary('''
import "dart:math" show e, pi;
''');
    var import = library.libraryImports[0];
    var combinator = import.combinators[0] as ShowElementCombinator;
    expect(combinator.offset, 19);
    expect(combinator.end, 29);
  }

  test_import_uri() async {
    var library = await buildLibrary('''
import 'foo.dart';
''');

    var uri = library.libraryImports[0].uri as DirectiveUriWithLibrary;
    expect(uri.relativeUriString, 'foo.dart');
  }

  test_imports() async {
    addSource('$testPackageLibPath/a.dart', 'library a; class C {}');
    addSource('$testPackageLibPath/b.dart', 'library b; class D {}');
    var library =
        await buildLibrary('import "a.dart"; import "b.dart"; C c; D d;');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
    package:test/b.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryImports
        package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
        package:test/b.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
      topLevelVariables
        static c @36
          reference: <testLibraryFragment>::@topLevelVariable::c
          enclosingElement: <testLibraryFragment>
          type: C
        static d @41
          reference: <testLibraryFragment>::@topLevelVariable::d
          enclosingElement: <testLibraryFragment>
          type: D
      accessors
        synthetic static get c @-1
          reference: <testLibraryFragment>::@getter::c
          enclosingElement: <testLibraryFragment>
          returnType: C
        synthetic static set c= @-1
          reference: <testLibraryFragment>::@setter::c
          enclosingElement: <testLibraryFragment>
          parameters
            requiredPositional _c @-1
              type: C
          returnType: void
        synthetic static get d @-1
          reference: <testLibraryFragment>::@getter::d
          enclosingElement: <testLibraryFragment>
          returnType: D
        synthetic static set d= @-1
          reference: <testLibraryFragment>::@setter::d
          enclosingElement: <testLibraryFragment>
          parameters
            requiredPositional _d @-1
              type: D
          returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      libraryImports
        package:test/a.dart
        package:test/b.dart
''');
  }

  test_library_imports_noRelativeUriStr() async {
    var library = await buildLibrary(r'''
import '${'foo'}.dart';
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    noRelativeUriString
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryImports
        noRelativeUriString
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
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
    var p1 = library.prefixes.singleWhere((prefix) => prefix.name == 'p1');
    var import_async = library.libraryImports[0];
    var import_math = library.libraryImports[2];
    expect(p1.imports, unorderedEquals([import_async, import_math]));
  }

  test_library_imports_syntheticDartCore() async {
    var library = await buildLibrary('');
    configuration.withSyntheticDartCoreImport = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    dart:core synthetic
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryImports
        dart:core synthetic
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
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
  libraryImports
    package:test/test.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryImports
        package:test/test.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
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
  libraryImports
    relativeUri 'foo:bar'
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryImports
        relativeUri 'foo:bar'
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
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
  libraryImports
    package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryImports
        package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      libraryImports
        package:test/a.dart
''');
  }

  test_library_imports_withRelativeUri_notLibrary_augmentation() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
''');
    var library = await buildLibrary(r'''
import 'a.dart';
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    source 'package:test/a.dart'
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryImports
        source 'package:test/a.dart'
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      libraryImports
        source 'package:test/a.dart'
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
  libraryImports
    source 'package:test/a.dart'
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryImports
        source 'package:test/a.dart'
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
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
  libraryImports
    relativeUriString ':'
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryImports
        relativeUriString ':'
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
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
    var prefixNames = library.prefixes.map((e) => e.name).toList();
    expect(prefixNames, unorderedEquals(['p1', 'p2']));
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
        staticElement: <testLibraryFragment>::@getter::a
        staticType: null
      element: <testLibraryFragment>::@getter::a
  libraryImports
    dart:math
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      metadata
        Annotation
          atSign: @ @0
          name: SimpleIdentifier
            token: a @1
            staticElement: <testLibraryFragment>::@getter::a
            staticType: null
          element: <testLibraryFragment>::@getter::a
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryImports
        dart:math
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @0
              name: SimpleIdentifier
                token: a @1
                staticElement: <testLibraryFragment>::@getter::a
                staticType: null
              element: <testLibraryFragment>::@getter::a
      topLevelVariables
        static const a @29
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            IntegerLiteral
              literal: 0 @33
              staticType: int
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement: <testLibraryFragment>
          returnType: int
----------------------------------------
library
  reference: <testLibrary>
  metadata
    Annotation
      atSign: @ @0
      name: SimpleIdentifier
        token: a @1
        staticElement: <testLibraryFragment>::@getter::a
        staticType: null
      element: <testLibraryFragment>::@getter::a
  fragments
    <testLibraryFragment>
      libraryImports
        dart:math
          metadata
            Annotation
              atSign: @ @0
              name: SimpleIdentifier
                token: a @1
                staticElement: <testLibraryFragment>::@getter::a
                staticType: null
              element: <testLibraryFragment>::@getter::a
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
        staticElement: <testLibraryFragment>::@getter::a
        staticType: null
      element: <testLibraryFragment>::@getter::a
  libraryImports
    dart:math
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      metadata
        Annotation
          atSign: @ @0
          name: SimpleIdentifier
            token: a @1
            staticElement: <testLibraryFragment>::@getter::a
            staticType: null
          element: <testLibraryFragment>::@getter::a
      combinators
        show: Random
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryImports
        dart:math
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @0
              name: SimpleIdentifier
                token: a @1
                staticElement: <testLibraryFragment>::@getter::a
                staticType: null
              element: <testLibraryFragment>::@getter::a
          combinators
            show: Random
      topLevelVariables
        static const a @42
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            IntegerLiteral
              literal: 0 @46
              staticType: int
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement: <testLibraryFragment>
          returnType: int
----------------------------------------
library
  reference: <testLibrary>
  metadata
    Annotation
      atSign: @ @0
      name: SimpleIdentifier
        token: a @1
        staticElement: <testLibraryFragment>::@getter::a
        staticType: null
      element: <testLibraryFragment>::@getter::a
  fragments
    <testLibraryFragment>
      libraryImports
        dart:math
          metadata
            Annotation
              atSign: @ @0
              name: SimpleIdentifier
                token: a @1
                staticElement: <testLibraryFragment>::@getter::a
                staticType: null
              element: <testLibraryFragment>::@getter::a
''');
  }

  test_nameConflict_importWithRelativeUri_exportWithAbsolute() async {
    if (resourceProvider.pathContext.separator != '/') {
      return;
    }

    addSource('$testPackageLibPath/a.dart', 'class A {}');
    addSource('$testPackageLibPath/b.dart', 'export "/a.dart";');
    var library = await buildLibrary('''
import 'a.dart';
import 'b.dart';
A v = null;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
    package:test/b.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryImports
        package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
        package:test/b.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
      topLevelVariables
        static v @36
          reference: <testLibraryFragment>::@topLevelVariable::v
          enclosingElement: <testLibraryFragment>
          type: A
          shouldUseTypeForInitializerInference: true
      accessors
        synthetic static get v @-1
          reference: <testLibraryFragment>::@getter::v
          enclosingElement: <testLibraryFragment>
          returnType: A
        synthetic static set v= @-1
          reference: <testLibraryFragment>::@setter::v
          enclosingElement: <testLibraryFragment>
          parameters
            requiredPositional _v @-1
              type: A
          returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      libraryImports
        package:test/a.dart
        package:test/b.dart
''');
  }

  test_unresolved_import() async {
    var library = await buildLibrary("import 'foo.dart';");
    var importedLibrary = library.libraryImports[0].importedLibrary!;
    expect(importedLibrary.loadLibraryFunction, isNotNull);
    expect(importedLibrary.publicNamespace, isNotNull);
    expect(importedLibrary.exportNamespace, isNotNull);
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/foo.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryImports
        package:test/foo.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
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
