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
    defineReflectiveTests(LibraryExportElementTest_keepLinking);
    defineReflectiveTests(LibraryExportElementTest_fromBytes);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

abstract class LibraryExportElementTest extends ElementsBaseTest {
  test_export_class() async {
    addSource('$testPackageLibPath/a.dart', 'class C {}');
    var library = await buildLibrary('export "a.dart";');
    configuration.withExportScope = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryExports
    package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryExports
        package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
  exportedReferences
    exported[(0, 0)] package:test/a.dart::<fragment>::@class::C
  exportNamespace
    C: package:test/a.dart::<fragment>::@class::C
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
  exportedReferences
    exported[(0, 0)] package:test/a.dart::<fragment>::@class::C
  exportNamespace
    C: package:test/a.dart::<fragment>::@class::C
''');
  }

  test_export_class_type_alias() async {
    addSource('$testPackageLibPath/a.dart', r'''
class C = _D with _E;
class _D {}
class _E {}
''');
    var library = await buildLibrary('export "a.dart";');
    configuration.withExportScope = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryExports
    package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryExports
        package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
  exportedReferences
    exported[(0, 0)] package:test/a.dart::<fragment>::@class::C
  exportNamespace
    C: package:test/a.dart::<fragment>::@class::C
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
  exportedReferences
    exported[(0, 0)] package:test/a.dart::<fragment>::@class::C
  exportNamespace
    C: package:test/a.dart::<fragment>::@class::C
''');
  }

  test_export_configurations_useDefault() async {
    declaredVariables = {
      'dart.library.io': 'false',
    };
    addSource('$testPackageLibPath/foo.dart', 'class A {}');
    addSource('$testPackageLibPath/foo_io.dart', 'class A {}');
    addSource('$testPackageLibPath/foo_html.dart', 'class A {}');
    var library = await buildLibrary(r'''
export 'foo.dart'
  if (dart.library.io) 'foo_io.dart'
  if (dart.library.html) 'foo_html.dart';
''');
    configuration.withExportScope = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryExports
    package:test/foo.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryExports
        package:test/foo.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
  exportedReferences
    exported[(0, 0)] package:test/foo.dart::<fragment>::@class::A
  exportNamespace
    A: package:test/foo.dart::<fragment>::@class::A
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
  exportedReferences
    exported[(0, 0)] package:test/foo.dart::<fragment>::@class::A
  exportNamespace
    A: package:test/foo.dart::<fragment>::@class::A
''');
    expect(library.libraryExports[0].exportedLibrary!.source.shortName,
        'foo.dart');
  }

  test_export_configurations_useFirst() async {
    declaredVariables = {
      'dart.library.io': 'true',
      'dart.library.html': 'true',
    };
    addSource('$testPackageLibPath/foo.dart', 'class A {}');
    addSource('$testPackageLibPath/foo_io.dart', 'class A {}');
    addSource('$testPackageLibPath/foo_html.dart', 'class A {}');
    var library = await buildLibrary(r'''
export 'foo.dart'
  if (dart.library.io) 'foo_io.dart'
  if (dart.library.html) 'foo_html.dart';
''');
    configuration.withExportScope = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryExports
    package:test/foo_io.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryExports
        package:test/foo_io.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
  exportedReferences
    exported[(0, 0)] package:test/foo_io.dart::<fragment>::@class::A
  exportNamespace
    A: package:test/foo_io.dart::<fragment>::@class::A
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
  exportedReferences
    exported[(0, 0)] package:test/foo_io.dart::<fragment>::@class::A
  exportNamespace
    A: package:test/foo_io.dart::<fragment>::@class::A
''');
    expect(library.libraryExports[0].exportedLibrary!.source.shortName,
        'foo_io.dart');
  }

  test_export_configurations_useSecond() async {
    declaredVariables = {
      'dart.library.io': 'false',
      'dart.library.html': 'true',
    };
    addSource('$testPackageLibPath/foo.dart', 'class A {}');
    addSource('$testPackageLibPath/foo_io.dart', 'class A {}');
    addSource('$testPackageLibPath/foo_html.dart', 'class A {}');
    var library = await buildLibrary(r'''
export 'foo.dart'
  if (dart.library.io) 'foo_io.dart'
  if (dart.library.html) 'foo_html.dart';
''');
    configuration.withExportScope = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryExports
    package:test/foo_html.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryExports
        package:test/foo_html.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
  exportedReferences
    exported[(0, 0)] package:test/foo_html.dart::<fragment>::@class::A
  exportNamespace
    A: package:test/foo_html.dart::<fragment>::@class::A
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
  exportedReferences
    exported[(0, 0)] package:test/foo_html.dart::<fragment>::@class::A
  exportNamespace
    A: package:test/foo_html.dart::<fragment>::@class::A
''');
    var export = library.libraryExports[0];
    expect(export.exportedLibrary!.source.shortName, 'foo_html.dart');
  }

  test_export_cycle() async {
    addSource('$testPackageLibPath/a.dart', r'''
export 'test.dart';
class A {}
''');

    var library = await buildLibrary(r'''
export 'a.dart';
class X {}
''');
    configuration.withExportScope = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryExports
    package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryExports
        package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
      classes
        class X @23
          reference: <testLibraryFragment>::@class::X
          enclosingElement: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::X::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::X
  exportedReferences
    exported[(0, 0)] package:test/a.dart::<fragment>::@class::A
    declared <testLibraryFragment>::@class::X
  exportNamespace
    A: package:test/a.dart::<fragment>::@class::A
    X: <testLibraryFragment>::@class::X
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
  exportedReferences
    exported[(0, 0)] package:test/a.dart::<fragment>::@class::A
    declared <testLibraryFragment>::@class::X
  exportNamespace
    A: package:test/a.dart::<fragment>::@class::A
    X: <testLibraryFragment>::@class::X
''');
  }

  test_export_function() async {
    addSource('$testPackageLibPath/a.dart', 'f() {}');
    var library = await buildLibrary('export "a.dart";');
    configuration.withExportScope = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryExports
    package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryExports
        package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
  exportedReferences
    exported[(0, 0)] package:test/a.dart::<fragment>::@function::f
  exportNamespace
    f: package:test/a.dart::<fragment>::@function::f
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
  exportedReferences
    exported[(0, 0)] package:test/a.dart::<fragment>::@function::f
  exportNamespace
    f: package:test/a.dart::<fragment>::@function::f
''');
  }

  test_export_getter() async {
    addSource('$testPackageLibPath/a.dart', 'get f() => null;');
    var library = await buildLibrary('export "a.dart";');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryExports
    package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryExports
        package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
''');
  }

  test_export_hide() async {
    addSource('$testPackageLibPath/a.dart', r'''
class A {}
class B {}
class C {}
class D {}
''');
    var library = await buildLibrary(r'''
export 'a.dart' hide A, C;
''');
    configuration.withExportScope = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryExports
    package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      combinators
        hide: A, C
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryExports
        package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          combinators
            hide: A, C
  exportedReferences
    exported[(0, 0)] package:test/a.dart::<fragment>::@class::B
    exported[(0, 0)] package:test/a.dart::<fragment>::@class::D
  exportNamespace
    B: package:test/a.dart::<fragment>::@class::B
    D: package:test/a.dart::<fragment>::@class::D
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
  exportedReferences
    exported[(0, 0)] package:test/a.dart::<fragment>::@class::B
    exported[(0, 0)] package:test/a.dart::<fragment>::@class::D
  exportNamespace
    B: package:test/a.dart::<fragment>::@class::B
    D: package:test/a.dart::<fragment>::@class::D
''');
  }

  test_export_multiple_combinators() async {
    addSource('$testPackageLibPath/a.dart', r'''
class A {}
class B {}
class C {}
class D {}
''');
    var library = await buildLibrary(r'''
export 'a.dart' hide A show C;
''');
    configuration.withExportScope = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryExports
    package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      combinators
        hide: A
        show: C
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryExports
        package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          combinators
            hide: A
            show: C
  exportedReferences
    exported[(0, 0)] package:test/a.dart::<fragment>::@class::C
  exportNamespace
    C: package:test/a.dart::<fragment>::@class::C
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
  exportedReferences
    exported[(0, 0)] package:test/a.dart::<fragment>::@class::C
  exportNamespace
    C: package:test/a.dart::<fragment>::@class::C
''');
  }

  test_export_reexport() async {
    addSource('$testPackageLibPath/a.dart', r'''
class A {}
''');

    addSource('$testPackageLibPath/b.dart', r'''
export 'a.dart';
class B {}
''');

    addSource('$testPackageLibPath/c.dart', r'''
export 'a.dart';
class C {}
''');

    var library = await buildLibrary(r'''
export 'b.dart';
export 'c.dart';
class X {}
''');

    configuration.withExportScope = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryExports
    package:test/b.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
    package:test/c.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryExports
        package:test/b.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
        package:test/c.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
      classes
        class X @40
          reference: <testLibraryFragment>::@class::X
          enclosingElement: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::X::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::X
  exportedReferences
    exported[(0, 0), (0, 1)] package:test/a.dart::<fragment>::@class::A
    exported[(0, 0)] package:test/b.dart::<fragment>::@class::B
    exported[(0, 1)] package:test/c.dart::<fragment>::@class::C
    declared <testLibraryFragment>::@class::X
  exportNamespace
    A: package:test/a.dart::<fragment>::@class::A
    B: package:test/b.dart::<fragment>::@class::B
    C: package:test/c.dart::<fragment>::@class::C
    X: <testLibraryFragment>::@class::X
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
  exportedReferences
    exported[(0, 0), (0, 1)] package:test/a.dart::<fragment>::@class::A
    exported[(0, 0)] package:test/b.dart::<fragment>::@class::B
    exported[(0, 1)] package:test/c.dart::<fragment>::@class::C
    declared <testLibraryFragment>::@class::X
  exportNamespace
    A: package:test/a.dart::<fragment>::@class::A
    B: package:test/b.dart::<fragment>::@class::B
    C: package:test/c.dart::<fragment>::@class::C
    X: <testLibraryFragment>::@class::X
''');
  }

  test_export_setter() async {
    addSource('$testPackageLibPath/a.dart', 'void set f(value) {}');
    var library = await buildLibrary('export "a.dart";');
    configuration.withExportScope = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryExports
    package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryExports
        package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
  exportedReferences
    exported[(0, 0)] package:test/a.dart::<fragment>::@setter::f
  exportNamespace
    f=: package:test/a.dart::<fragment>::@setter::f
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
  exportedReferences
    exported[(0, 0)] package:test/a.dart::<fragment>::@setter::f
  exportNamespace
    f=: package:test/a.dart::<fragment>::@setter::f
''');
  }

  test_export_show() async {
    addSource('$testPackageLibPath/a.dart', r'''
class A {}
class B {}
class C {}
class D {}
''');
    var library = await buildLibrary(r'''
export 'a.dart' show A, C;
''');
    configuration.withExportScope = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryExports
    package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      combinators
        show: A, C
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryExports
        package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          combinators
            show: A, C
  exportedReferences
    exported[(0, 0)] package:test/a.dart::<fragment>::@class::A
    exported[(0, 0)] package:test/a.dart::<fragment>::@class::C
  exportNamespace
    A: package:test/a.dart::<fragment>::@class::A
    C: package:test/a.dart::<fragment>::@class::C
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
  exportedReferences
    exported[(0, 0)] package:test/a.dart::<fragment>::@class::A
    exported[(0, 0)] package:test/a.dart::<fragment>::@class::C
  exportNamespace
    A: package:test/a.dart::<fragment>::@class::A
    C: package:test/a.dart::<fragment>::@class::C
''');
  }

  test_export_show_getter_setter() async {
    addSource('$testPackageLibPath/a.dart', '''
get f => null;
void set f(value) {}
''');
    var library = await buildLibrary('export "a.dart" show f;');
    configuration.withExportScope = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryExports
    package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      combinators
        show: f
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryExports
        package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          combinators
            show: f
  exportedReferences
    exported[(0, 0)] package:test/a.dart::<fragment>::@getter::f
    exported[(0, 0)] package:test/a.dart::<fragment>::@setter::f
  exportNamespace
    f: package:test/a.dart::<fragment>::@getter::f
    f=: package:test/a.dart::<fragment>::@setter::f
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
  exportedReferences
    exported[(0, 0)] package:test/a.dart::<fragment>::@getter::f
    exported[(0, 0)] package:test/a.dart::<fragment>::@setter::f
  exportNamespace
    f: package:test/a.dart::<fragment>::@getter::f
    f=: package:test/a.dart::<fragment>::@setter::f
''');
  }

  test_export_typedef() async {
    addSource('$testPackageLibPath/a.dart', 'typedef F();');
    var library = await buildLibrary('export "a.dart";');
    configuration.withExportScope = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryExports
    package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryExports
        package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
  exportedReferences
    exported[(0, 0)] package:test/a.dart::<fragment>::@typeAlias::F
  exportNamespace
    F: package:test/a.dart::<fragment>::@typeAlias::F
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
  exportedReferences
    exported[(0, 0)] package:test/a.dart::<fragment>::@typeAlias::F
  exportNamespace
    F: package:test/a.dart::<fragment>::@typeAlias::F
''');
  }

  test_export_uri() async {
    var library = await buildLibrary('''
export 'foo.dart';
''');

    var uri = library.libraryExports[0].uri as DirectiveUriWithLibrary;
    expect(uri.relativeUriString, 'foo.dart');
  }

  test_export_variable() async {
    addSource('$testPackageLibPath/a.dart', 'var x;');
    var library = await buildLibrary('export "a.dart";');
    configuration.withExportScope = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryExports
    package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryExports
        package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
  exportedReferences
    exported[(0, 0)] package:test/a.dart::<fragment>::@getter::x
    exported[(0, 0)] package:test/a.dart::<fragment>::@setter::x
  exportNamespace
    x: package:test/a.dart::<fragment>::@getter::x
    x=: package:test/a.dart::<fragment>::@setter::x
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
  exportedReferences
    exported[(0, 0)] package:test/a.dart::<fragment>::@getter::x
    exported[(0, 0)] package:test/a.dart::<fragment>::@setter::x
  exportNamespace
    x: package:test/a.dart::<fragment>::@getter::x
    x=: package:test/a.dart::<fragment>::@setter::x
''');
  }

  test_export_variable_const() async {
    addSource('$testPackageLibPath/a.dart', 'const x = 0;');
    var library = await buildLibrary('export "a.dart";');
    configuration.withExportScope = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryExports
    package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryExports
        package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
  exportedReferences
    exported[(0, 0)] package:test/a.dart::<fragment>::@getter::x
  exportNamespace
    x: package:test/a.dart::<fragment>::@getter::x
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
  exportedReferences
    exported[(0, 0)] package:test/a.dart::<fragment>::@getter::x
  exportNamespace
    x: package:test/a.dart::<fragment>::@getter::x
''');
  }

  test_export_variable_final() async {
    addSource('$testPackageLibPath/a.dart', 'final x = 0;');
    var library = await buildLibrary('export "a.dart";');
    configuration.withExportScope = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryExports
    package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryExports
        package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
  exportedReferences
    exported[(0, 0)] package:test/a.dart::<fragment>::@getter::x
  exportNamespace
    x: package:test/a.dart::<fragment>::@getter::x
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
  exportedReferences
    exported[(0, 0)] package:test/a.dart::<fragment>::@getter::x
  exportNamespace
    x: package:test/a.dart::<fragment>::@getter::x
''');
  }

  test_exportImport_configurations_useDefault() async {
    declaredVariables = {
      'dart.library.io': 'false',
    };
    addSource('$testPackageLibPath/foo.dart', 'class A {}');
    addSource('$testPackageLibPath/foo_io.dart', 'class A {}');
    addSource('$testPackageLibPath/foo_html.dart', 'class A {}');
    addSource('$testPackageLibPath/bar.dart', r'''
export 'foo.dart'
  if (dart.library.io) 'foo_io.dart'
  if (dart.library.html) 'foo_html.dart';
''');
    var library = await buildLibrary(r'''
import 'bar.dart';
class B extends A {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/bar.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryImports
        package:test/bar.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
      classes
        class B @25
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
        package:test/bar.dart
''');
    var typeA = library.definingCompilationUnit.getClass('B')!.supertype!;
    expect(typeA.element.source.shortName, 'foo.dart');
  }

  test_exportImport_configurations_useFirst() async {
    declaredVariables = {
      'dart.library.io': 'true',
      'dart.library.html': 'false',
    };
    addSource('$testPackageLibPath/foo.dart', 'class A {}');
    addSource('$testPackageLibPath/foo_io.dart', 'class A {}');
    addSource('$testPackageLibPath/foo_html.dart', 'class A {}');
    addSource('$testPackageLibPath/bar.dart', r'''
export 'foo.dart'
  if (dart.library.io) 'foo_io.dart'
  if (dart.library.html) 'foo_html.dart';
''');
    var library = await buildLibrary(r'''
import 'bar.dart';
class B extends A {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/bar.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryImports
        package:test/bar.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
      classes
        class B @25
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
        package:test/bar.dart
''');
    var typeA = library.definingCompilationUnit.getClass('B')!.supertype!;
    expect(typeA.element.source.shortName, 'foo_io.dart');
  }

  test_exportImport_configurations_useSecond() async {
    declaredVariables = {
      'dart.library.io': 'false',
      'dart.library.html': 'true',
    };
    addSource('$testPackageLibPath/foo.dart', 'class A {}');
    addSource('$testPackageLibPath/foo_io.dart', 'class A {}');
    addSource('$testPackageLibPath/foo_html.dart', 'class A {}');
    addSource('$testPackageLibPath/bar.dart', r'''
export 'foo.dart'
  if (dart.library.io) 'foo_io.dart'
  if (dart.library.html) 'foo_html.dart';
''');
    var library = await buildLibrary(r'''
import 'bar.dart';
class B extends A {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/bar.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryImports
        package:test/bar.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
      classes
        class B @25
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
        package:test/bar.dart
''');
    var typeA = library.definingCompilationUnit.getClass('B')!.supertype!;
    expect(typeA.element.source.shortName, 'foo_html.dart');
  }

  test_exports() async {
    addSource('$testPackageLibPath/a.dart', 'library a;');
    addSource('$testPackageLibPath/b.dart', 'library b;');
    var library = await buildLibrary('export "a.dart"; export "b.dart";');
    configuration.withExportScope = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryExports
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
      libraryExports
        package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
        package:test/b.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
  exportedReferences
  exportNamespace
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
  exportedReferences
  exportNamespace
''');
  }

  test_exportScope_augmentation_class() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
augment class A {}
class B {}
''');
    var library = await buildLibrary(r'''
import augment 'a.dart';
class A {}
''');
    configuration.withExportScope = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  augmentationImports
    package:test/a.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/a.dart
      definingUnit: <testLibrary>::@fragment::package:test/a.dart
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      classes
        class A @31
          reference: <testLibraryFragment>::@class::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::A
          augmented
            constructors
              <testLibraryFragment>::@class::A::@constructor::new
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      classes
        augment class A @43
          reference: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@class::A
        class B @54
          reference: <testLibrary>::@fragment::package:test/a.dart::@class::B
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          constructors
            synthetic @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@class::B::@constructor::new
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@class::B
  exportedReferences
    declared <testLibrary>::@fragment::package:test/a.dart::@class::B
    declared <testLibraryFragment>::@class::A
  exportNamespace
    A: <testLibraryFragment>::@class::A
    B: <testLibrary>::@fragment::package:test/a.dart::@class::B
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
    <testLibrary>::@fragment::package:test/a.dart
  exportedReferences
    declared <testLibrary>::@fragment::package:test/a.dart::@class::B
    declared <testLibraryFragment>::@class::A
  exportNamespace
    A: <testLibraryFragment>::@class::A
    B: <testLibrary>::@fragment::package:test/a.dart::@class::B
''');
  }

  test_exportScope_augmentation_export() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {}
''');
    newFile('$testPackageLibPath/b.dart', r'''
class B1 {}
class B2 {}
''');
    newFile('$testPackageLibPath/c.dart', r'''
class C {}
''');
    newFile('$testPackageLibPath/d.dart', r'''
augment library 'test.dart';
export 'a.dart';
''');
    newFile('$testPackageLibPath/e.dart', r'''
augment library 'test.dart';
export 'b.dart';
export 'c.dart';
''');
    var library = await buildLibrary(r'''
import augment 'd.dart';
import augment 'e.dart';
class X {}
''');
    configuration.withExportScope = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  augmentationImports
    package:test/d.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/d.dart
      libraryExports
        package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibrary>::@fragment::package:test/d.dart
      definingUnit: <testLibrary>::@fragment::package:test/d.dart
    package:test/e.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/e.dart
      libraryExports
        package:test/b.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibrary>::@fragment::package:test/e.dart
        package:test/c.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibrary>::@fragment::package:test/e.dart
      definingUnit: <testLibrary>::@fragment::package:test/e.dart
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      classes
        class X @56
          reference: <testLibraryFragment>::@class::X
          enclosingElement: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::X::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::X
    <testLibrary>::@fragment::package:test/d.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/d.dart
      enclosingElement3: <testLibraryFragment>
      libraryExports
        package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibrary>::@fragment::package:test/d.dart
    <testLibrary>::@fragment::package:test/e.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/e.dart
      enclosingElement3: <testLibraryFragment>
      libraryExports
        package:test/b.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibrary>::@fragment::package:test/e.dart
        package:test/c.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibrary>::@fragment::package:test/e.dart
  exportedReferences
    exported[(1, 0)] package:test/a.dart::<fragment>::@class::A
    exported[(2, 0)] package:test/b.dart::<fragment>::@class::B1
    exported[(2, 0)] package:test/b.dart::<fragment>::@class::B2
    exported[(2, 1)] package:test/c.dart::<fragment>::@class::C
    declared <testLibraryFragment>::@class::X
  exportNamespace
    A: package:test/a.dart::<fragment>::@class::A
    B1: package:test/b.dart::<fragment>::@class::B1
    B2: package:test/b.dart::<fragment>::@class::B2
    C: package:test/c.dart::<fragment>::@class::C
    X: <testLibraryFragment>::@class::X
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
    <testLibrary>::@fragment::package:test/d.dart
    <testLibrary>::@fragment::package:test/e.dart
  exportedReferences
    exported[(1, 0)] package:test/a.dart::<fragment>::@class::A
    exported[(2, 0)] package:test/b.dart::<fragment>::@class::B1
    exported[(2, 0)] package:test/b.dart::<fragment>::@class::B2
    exported[(2, 1)] package:test/c.dart::<fragment>::@class::C
    declared <testLibraryFragment>::@class::X
  exportNamespace
    A: package:test/a.dart::<fragment>::@class::A
    B1: package:test/b.dart::<fragment>::@class::B1
    B2: package:test/b.dart::<fragment>::@class::B2
    C: package:test/c.dart::<fragment>::@class::C
    X: <testLibraryFragment>::@class::X
''');
  }

  test_exportScope_augmentation_export_hide() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A1 {}
class A2 {}
class A3 {}
class A4 {}
''');
    newFile('$testPackageLibPath/b.dart', r'''
augment library 'test.dart';
export 'a.dart' hide A2, A4;
''');
    var library = await buildLibrary(r'''
import augment 'b.dart';
class X {}
''');
    configuration.withExportScope = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  augmentationImports
    package:test/b.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/b.dart
      libraryExports
        package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibrary>::@fragment::package:test/b.dart
          combinators
            hide: A2, A4
      definingUnit: <testLibrary>::@fragment::package:test/b.dart
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      classes
        class X @31
          reference: <testLibraryFragment>::@class::X
          enclosingElement: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::X::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::X
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/b.dart
      enclosingElement3: <testLibraryFragment>
      libraryExports
        package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibrary>::@fragment::package:test/b.dart
          combinators
            hide: A2, A4
  exportedReferences
    exported[(1, 0)] package:test/a.dart::<fragment>::@class::A1
    exported[(1, 0)] package:test/a.dart::<fragment>::@class::A3
    declared <testLibraryFragment>::@class::X
  exportNamespace
    A1: package:test/a.dart::<fragment>::@class::A1
    A3: package:test/a.dart::<fragment>::@class::A3
    X: <testLibraryFragment>::@class::X
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
    <testLibrary>::@fragment::package:test/b.dart
  exportedReferences
    exported[(1, 0)] package:test/a.dart::<fragment>::@class::A1
    exported[(1, 0)] package:test/a.dart::<fragment>::@class::A3
    declared <testLibraryFragment>::@class::X
  exportNamespace
    A1: package:test/a.dart::<fragment>::@class::A1
    A3: package:test/a.dart::<fragment>::@class::A3
    X: <testLibraryFragment>::@class::X
''');
  }

  test_exportScope_augmentation_export_show() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A1 {}
class A2 {}
class A3 {}
''');
    newFile('$testPackageLibPath/b.dart', r'''
augment library 'test.dart';
export 'a.dart' show A1, A3;
''');
    var library = await buildLibrary(r'''
import augment 'b.dart';
class X {}
''');
    configuration.withExportScope = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  augmentationImports
    package:test/b.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/b.dart
      libraryExports
        package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibrary>::@fragment::package:test/b.dart
          combinators
            show: A1, A3
      definingUnit: <testLibrary>::@fragment::package:test/b.dart
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      classes
        class X @31
          reference: <testLibraryFragment>::@class::X
          enclosingElement: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::X::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::X
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/b.dart
      enclosingElement3: <testLibraryFragment>
      libraryExports
        package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibrary>::@fragment::package:test/b.dart
          combinators
            show: A1, A3
  exportedReferences
    exported[(1, 0)] package:test/a.dart::<fragment>::@class::A1
    exported[(1, 0)] package:test/a.dart::<fragment>::@class::A3
    declared <testLibraryFragment>::@class::X
  exportNamespace
    A1: package:test/a.dart::<fragment>::@class::A1
    A3: package:test/a.dart::<fragment>::@class::A3
    X: <testLibraryFragment>::@class::X
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
    <testLibrary>::@fragment::package:test/b.dart
  exportedReferences
    exported[(1, 0)] package:test/a.dart::<fragment>::@class::A1
    exported[(1, 0)] package:test/a.dart::<fragment>::@class::A3
    declared <testLibraryFragment>::@class::X
  exportNamespace
    A1: package:test/a.dart::<fragment>::@class::A1
    A3: package:test/a.dart::<fragment>::@class::A3
    X: <testLibraryFragment>::@class::X
''');
  }

  test_exportScope_augmentation_mixin() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
augment mixin A {}
mixin B {}
''');
    var library = await buildLibrary(r'''
import augment 'a.dart';
mixin A {}
''');
    configuration.withExportScope = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  augmentationImports
    package:test/a.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/a.dart
      definingUnit: <testLibrary>::@fragment::package:test/a.dart
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      mixins
        mixin A @31
          reference: <testLibraryFragment>::@mixin::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          superclassConstraints
            Object
          augmented
            superclassConstraints
              Object
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      mixins
        augment mixin A @43
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@mixin::A
        mixin B @54
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixin::B
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          superclassConstraints
            Object
  exportedReferences
    declared <testLibrary>::@fragment::package:test/a.dart::@mixin::B
    declared <testLibraryFragment>::@mixin::A
  exportNamespace
    A: <testLibraryFragment>::@mixin::A
    B: <testLibrary>::@fragment::package:test/a.dart::@mixin::B
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
    <testLibrary>::@fragment::package:test/a.dart
  exportedReferences
    declared <testLibrary>::@fragment::package:test/a.dart::@mixin::B
    declared <testLibraryFragment>::@mixin::A
  exportNamespace
    A: <testLibraryFragment>::@mixin::A
    B: <testLibrary>::@fragment::package:test/a.dart::@mixin::B
''');
  }

  test_exportScope_augmentation_nested_class() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
import augment 'b.dart';
class A {}
''');
    newFile('$testPackageLibPath/b.dart', r'''
augment library 'a.dart';
class B {}
''');
    var library = await buildLibrary(r'''
import augment 'a.dart';
class C {}
''');
    configuration.withExportScope = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  augmentationImports
    package:test/a.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/a.dart
      definingUnit: <testLibrary>::@fragment::package:test/a.dart
      augmentationImports
        package:test/b.dart
          enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
          reference: <testLibrary>::@augmentation::package:test/b.dart
          definingUnit: <testLibrary>::@fragment::package:test/b.dart
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      classes
        class C @31
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      classes
        class A @60
          reference: <testLibrary>::@fragment::package:test/a.dart::@class::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          constructors
            synthetic @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@class::A::@constructor::new
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@class::A
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/b.dart
      enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
      classes
        class B @32
          reference: <testLibrary>::@fragment::package:test/b.dart::@class::B
          enclosingElement: <testLibrary>::@fragment::package:test/b.dart
          constructors
            synthetic @-1
              reference: <testLibrary>::@fragment::package:test/b.dart::@class::B::@constructor::new
              enclosingElement: <testLibrary>::@fragment::package:test/b.dart::@class::B
  exportedReferences
    declared <testLibrary>::@fragment::package:test/a.dart::@class::A
    declared <testLibrary>::@fragment::package:test/b.dart::@class::B
    declared <testLibraryFragment>::@class::C
  exportNamespace
    A: <testLibrary>::@fragment::package:test/a.dart::@class::A
    B: <testLibrary>::@fragment::package:test/b.dart::@class::B
    C: <testLibraryFragment>::@class::C
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
    <testLibrary>::@fragment::package:test/a.dart
    <testLibrary>::@fragment::package:test/b.dart
  exportedReferences
    declared <testLibrary>::@fragment::package:test/a.dart::@class::A
    declared <testLibrary>::@fragment::package:test/b.dart::@class::B
    declared <testLibraryFragment>::@class::C
  exportNamespace
    A: <testLibrary>::@fragment::package:test/a.dart::@class::A
    B: <testLibrary>::@fragment::package:test/b.dart::@class::B
    C: <testLibraryFragment>::@class::C
''');
  }

  test_exportScope_augmentation_nested_export() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {}
''');
    newFile('$testPackageLibPath/b.dart', r'''
class B {}
''');
    newFile('$testPackageLibPath/c.dart', r'''
augment library 'test.dart';
import augment 'd.dart';
export 'a.dart';
''');
    newFile('$testPackageLibPath/d.dart', r'''
augment library 'c.dart';
export 'b.dart';
''');
    var library = await buildLibrary(r'''
import augment 'c.dart';
class X {}
''');
    configuration.withExportScope = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  augmentationImports
    package:test/c.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/c.dart
      libraryExports
        package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibrary>::@fragment::package:test/c.dart
      definingUnit: <testLibrary>::@fragment::package:test/c.dart
      augmentationImports
        package:test/d.dart
          enclosingElement: <testLibrary>::@augmentation::package:test/c.dart
          reference: <testLibrary>::@augmentation::package:test/d.dart
          libraryExports
            package:test/b.dart
              enclosingElement: <testLibrary>
              enclosingElement3: <testLibrary>::@fragment::package:test/d.dart
          definingUnit: <testLibrary>::@fragment::package:test/d.dart
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      classes
        class X @31
          reference: <testLibraryFragment>::@class::X
          enclosingElement: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::X::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::X
    <testLibrary>::@fragment::package:test/c.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/c.dart
      enclosingElement3: <testLibraryFragment>
      libraryExports
        package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibrary>::@fragment::package:test/c.dart
    <testLibrary>::@fragment::package:test/d.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/d.dart
      enclosingElement3: <testLibrary>::@fragment::package:test/c.dart
      libraryExports
        package:test/b.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibrary>::@fragment::package:test/d.dart
  exportedReferences
    exported[(1, 0)] package:test/a.dart::<fragment>::@class::A
    exported[(2, 0)] package:test/b.dart::<fragment>::@class::B
    declared <testLibraryFragment>::@class::X
  exportNamespace
    A: package:test/a.dart::<fragment>::@class::A
    B: package:test/b.dart::<fragment>::@class::B
    X: <testLibraryFragment>::@class::X
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
    <testLibrary>::@fragment::package:test/c.dart
    <testLibrary>::@fragment::package:test/d.dart
  exportedReferences
    exported[(1, 0)] package:test/a.dart::<fragment>::@class::A
    exported[(2, 0)] package:test/b.dart::<fragment>::@class::B
    declared <testLibraryFragment>::@class::X
  exportNamespace
    A: package:test/a.dart::<fragment>::@class::A
    B: package:test/b.dart::<fragment>::@class::B
    X: <testLibraryFragment>::@class::X
''');
  }

  test_exportScope_augmentation_variable() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
int a = 0;
''');
    var library = await buildLibrary(r'''
import augment 'a.dart';
''');
    configuration.withExportScope = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  augmentationImports
    package:test/a.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/a.dart
      definingUnit: <testLibrary>::@fragment::package:test/a.dart
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      topLevelVariables
        static a @33
          reference: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariable::a
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          type: int
          shouldUseTypeForInitializerInference: true
      accessors
        synthetic static get a @-1
          reference: <testLibrary>::@fragment::package:test/a.dart::@getter::a
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          returnType: int
        synthetic static set a= @-1
          reference: <testLibrary>::@fragment::package:test/a.dart::@setter::a
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          parameters
            requiredPositional _a @-1
              type: int
          returnType: void
  exportedReferences
    declared <testLibrary>::@fragment::package:test/a.dart::@getter::a
    declared <testLibrary>::@fragment::package:test/a.dart::@setter::a
  exportNamespace
    a: <testLibrary>::@fragment::package:test/a.dart::@getter::a
    a=: <testLibrary>::@fragment::package:test/a.dart::@setter::a
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
    <testLibrary>::@fragment::package:test/a.dart
  exportedReferences
    declared <testLibrary>::@fragment::package:test/a.dart::@getter::a
    declared <testLibrary>::@fragment::package:test/a.dart::@setter::a
  exportNamespace
    a: <testLibrary>::@fragment::package:test/a.dart::@getter::a
    a=: <testLibrary>::@fragment::package:test/a.dart::@setter::a
''');
  }

  test_exportScope_augmentation_variable_const() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
const a = 0;
''');
    var library = await buildLibrary(r'''
import augment 'a.dart';
''');
    configuration.withExportScope = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  augmentationImports
    package:test/a.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/a.dart
      definingUnit: <testLibrary>::@fragment::package:test/a.dart
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      topLevelVariables
        static const a @35
          reference: <testLibrary>::@fragment::package:test/a.dart::@topLevelVariable::a
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            IntegerLiteral
              literal: 0 @39
              staticType: int
      accessors
        synthetic static get a @-1
          reference: <testLibrary>::@fragment::package:test/a.dart::@getter::a
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          returnType: int
  exportedReferences
    declared <testLibrary>::@fragment::package:test/a.dart::@getter::a
  exportNamespace
    a: <testLibrary>::@fragment::package:test/a.dart::@getter::a
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
    <testLibrary>::@fragment::package:test/a.dart
  exportedReferences
    declared <testLibrary>::@fragment::package:test/a.dart::@getter::a
  exportNamespace
    a: <testLibrary>::@fragment::package:test/a.dart::@getter::a
''');
  }

  test_library_exports_noRelativeUriStr() async {
    var library = await buildLibrary(r'''
export '${'foo'}.dart';
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryExports
    noRelativeUriString
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryExports
        noRelativeUriString
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
''');
  }

  test_library_exports_withRelativeUri_emptyUriSelf() async {
    var library = await buildLibrary(r'''
export '';
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryExports
    package:test/test.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryExports
        package:test/test.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
''');
  }

  test_library_exports_withRelativeUri_noSource() async {
    var library = await buildLibrary(r'''
export 'foo:bar';
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryExports
    relativeUri 'foo:bar'
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryExports
        relativeUri 'foo:bar'
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
''');
  }

  test_library_exports_withRelativeUri_notExists() async {
    var library = await buildLibrary(r'''
export 'a.dart';
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryExports
    package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryExports
        package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
''');
  }

  test_library_exports_withRelativeUri_notLibrary_augmentation() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
''');
    var library = await buildLibrary(r'''
export 'a.dart';
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryExports
    source 'package:test/a.dart'
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryExports
        source 'package:test/a.dart'
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
''');
  }

  test_library_exports_withRelativeUri_notLibrary_part() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of other.lib;
''');
    var library = await buildLibrary(r'''
export 'a.dart';
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryExports
    source 'package:test/a.dart'
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryExports
        source 'package:test/a.dart'
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
''');
  }

  test_library_exports_withRelativeUriString() async {
    var library = await buildLibrary(r'''
export ':';
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryExports
    relativeUriString ':'
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryExports
        relativeUriString ':'
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
''');
  }

  test_libraryExports_part() async {
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
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  parts
    part_0
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryExports
        dart:io
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      libraryExports
        dart:math
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
    <testLibrary>::@fragment::package:test/a.dart
''');
  }

  test_unresolved_export() async {
    var library = await buildLibrary("export 'foo.dart';");
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryExports
    package:test/foo.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryExports
        package:test/foo.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
''');
  }
}

@reflectiveTest
class LibraryExportElementTest_fromBytes extends LibraryExportElementTest {
  @override
  bool get keepLinkingLibraries => false;
}

@reflectiveTest
class LibraryExportElementTest_keepLinking extends LibraryExportElementTest {
  @override
  bool get keepLinkingLibraries => true;
}
