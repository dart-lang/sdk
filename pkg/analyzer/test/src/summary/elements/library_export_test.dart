// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
    newFile('$testPackageLibPath/a.dart', 'class C {}');
    var library = await buildLibrary('export "a.dart";');
    configuration.withExportScope = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryExports
        package:test/a.dart
  exportedReferences
    exported[(0, 0)] package:test/a.dart::@class::C
  exportNamespace
    C: package:test/a.dart::@class::C
''');
  }

  test_export_class_type_alias() async {
    newFile('$testPackageLibPath/a.dart', r'''
class C = _D with _E;
class _D {}
class _E {}
''');
    var library = await buildLibrary('export "a.dart";');
    configuration.withExportScope = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryExports
        package:test/a.dart
  exportedReferences
    exported[(0, 0)] package:test/a.dart::@class::C
  exportNamespace
    C: package:test/a.dart::@class::C
''');
  }

  test_export_configurations_useDefault() async {
    declaredVariables = {'dart.library.io': 'false'};
    newFile('$testPackageLibPath/foo.dart', 'class A {}');
    newFile('$testPackageLibPath/foo_io.dart', 'class A {}');
    newFile('$testPackageLibPath/foo_html.dart', 'class A {}');
    var library = await buildLibrary(r'''
export 'foo.dart'
  if (dart.library.io) 'foo_io.dart'
  if (dart.library.html) 'foo_html.dart';
''');
    configuration.withExportScope = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryExports
        package:test/foo.dart
  exportedReferences
    exported[(0, 0)] package:test/foo.dart::@class::A
  exportNamespace
    A: package:test/foo.dart::@class::A
''');
  }

  test_export_configurations_useFirst() async {
    declaredVariables = {
      'dart.library.io': 'true',
      'dart.library.html': 'true',
    };
    newFile('$testPackageLibPath/foo.dart', 'class A {}');
    newFile('$testPackageLibPath/foo_io.dart', 'class A {}');
    newFile('$testPackageLibPath/foo_html.dart', 'class A {}');
    var library = await buildLibrary(r'''
export 'foo.dart'
  if (dart.library.io) 'foo_io.dart'
  if (dart.library.html) 'foo_html.dart';
''');
    configuration.withExportScope = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryExports
        package:test/foo_io.dart
  exportedReferences
    exported[(0, 0)] package:test/foo_io.dart::@class::A
  exportNamespace
    A: package:test/foo_io.dart::@class::A
''');
  }

  test_export_configurations_useSecond() async {
    declaredVariables = {
      'dart.library.io': 'false',
      'dart.library.html': 'true',
    };
    newFile('$testPackageLibPath/foo.dart', 'class A {}');
    newFile('$testPackageLibPath/foo_io.dart', 'class A {}');
    newFile('$testPackageLibPath/foo_html.dart', 'class A {}');
    var library = await buildLibrary(r'''
export 'foo.dart'
  if (dart.library.io) 'foo_io.dart'
  if (dart.library.html) 'foo_html.dart';
''');
    configuration.withExportScope = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryExports
        package:test/foo_html.dart
  exportedReferences
    exported[(0, 0)] package:test/foo_html.dart::@class::A
  exportNamespace
    A: package:test/foo_html.dart::@class::A
''');
  }

  test_export_cycle() async {
    newFile('$testPackageLibPath/a.dart', r'''
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
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryExports
        package:test/a.dart
      classes
        #F1 class X (nameOffset:23) (firstTokenOffset:17) (offset:23)
          element: <testLibrary>::@class::X
          constructors
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
              element: <testLibrary>::@class::X::@constructor::new
              typeName: X
  classes
    class X
      reference: <testLibrary>::@class::X
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::X::@constructor::new
          firstFragment: #F2
  exportedReferences
    exported[(0, 0)] package:test/a.dart::@class::A
    declared <testLibrary>::@class::X
  exportNamespace
    A: package:test/a.dart::@class::A
    X: <testLibrary>::@class::X
''');
  }

  test_export_function() async {
    newFile('$testPackageLibPath/a.dart', 'f() {}');
    var library = await buildLibrary('export "a.dart";');
    configuration.withExportScope = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryExports
        package:test/a.dart
  exportedReferences
    exported[(0, 0)] package:test/a.dart::@function::f
  exportNamespace
    f: package:test/a.dart::@function::f
''');
  }

  test_export_getter() async {
    newFile('$testPackageLibPath/a.dart', 'get f() => null;');
    var library = await buildLibrary('export "a.dart";');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryExports
        package:test/a.dart
''');
  }

  test_export_hide() async {
    newFile('$testPackageLibPath/a.dart', r'''
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
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryExports
        package:test/a.dart
          combinators
            hide: A, C
  exportedReferences
    exported[(0, 0)] package:test/a.dart::@class::B
    exported[(0, 0)] package:test/a.dart::@class::D
  exportNamespace
    B: package:test/a.dart::@class::B
    D: package:test/a.dart::@class::D
''');
  }

  test_export_multiple_combinators() async {
    newFile('$testPackageLibPath/a.dart', r'''
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
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryExports
        package:test/a.dart
          combinators
            hide: A
            show: C
  exportedReferences
    exported[(0, 0)] package:test/a.dart::@class::C
  exportNamespace
    C: package:test/a.dart::@class::C
''');
  }

  test_export_reexport() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {}
''');

    newFile('$testPackageLibPath/b.dart', r'''
export 'a.dart';
class B {}
''');

    newFile('$testPackageLibPath/c.dart', r'''
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
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryExports
        package:test/b.dart
        package:test/c.dart
      classes
        #F1 class X (nameOffset:40) (firstTokenOffset:34) (offset:40)
          element: <testLibrary>::@class::X
          constructors
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
              element: <testLibrary>::@class::X::@constructor::new
              typeName: X
  classes
    class X
      reference: <testLibrary>::@class::X
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::X::@constructor::new
          firstFragment: #F2
  exportedReferences
    exported[(0, 0), (0, 1)] package:test/a.dart::@class::A
    exported[(0, 0)] package:test/b.dart::@class::B
    exported[(0, 1)] package:test/c.dart::@class::C
    declared <testLibrary>::@class::X
  exportNamespace
    A: package:test/a.dart::@class::A
    B: package:test/b.dart::@class::B
    C: package:test/c.dart::@class::C
    X: <testLibrary>::@class::X
''');
  }

  test_export_setter() async {
    newFile('$testPackageLibPath/a.dart', 'void set f(value) {}');
    var library = await buildLibrary('export "a.dart";');
    configuration.withExportScope = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryExports
        package:test/a.dart
  exportedReferences
    exported[(0, 0)] package:test/a.dart::@setter::f
  exportNamespace
    f=: package:test/a.dart::@setter::f
''');
  }

  test_export_show() async {
    newFile('$testPackageLibPath/a.dart', r'''
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
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryExports
        package:test/a.dart
          combinators
            show: A, C
  exportedReferences
    exported[(0, 0)] package:test/a.dart::@class::A
    exported[(0, 0)] package:test/a.dart::@class::C
  exportNamespace
    A: package:test/a.dart::@class::A
    C: package:test/a.dart::@class::C
''');
  }

  test_export_show_getter_setter() async {
    newFile('$testPackageLibPath/a.dart', '''
get f => null;
void set f(value) {}
''');
    var library = await buildLibrary('export "a.dart" show f;');
    configuration.withExportScope = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryExports
        package:test/a.dart
          combinators
            show: f
  exportedReferences
    exported[(0, 0)] package:test/a.dart::@getter::f
    exported[(0, 0)] package:test/a.dart::@setter::f
  exportNamespace
    f: package:test/a.dart::@getter::f
    f=: package:test/a.dart::@setter::f
''');
  }

  test_export_typedef() async {
    newFile('$testPackageLibPath/a.dart', 'typedef F();');
    var library = await buildLibrary('export "a.dart";');
    configuration.withExportScope = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryExports
        package:test/a.dart
  exportedReferences
    exported[(0, 0)] package:test/a.dart::@typeAlias::F
  exportNamespace
    F: package:test/a.dart::@typeAlias::F
''');
  }

  test_export_uri() async {
    var library = await buildLibrary('''
export 'foo.dart';
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryExports
        package:test/foo.dart
''');
  }

  test_export_variable() async {
    newFile('$testPackageLibPath/a.dart', 'var x;');
    var library = await buildLibrary('export "a.dart";');
    configuration.withExportScope = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryExports
        package:test/a.dart
  exportedReferences
    exported[(0, 0)] package:test/a.dart::@getter::x
    exported[(0, 0)] package:test/a.dart::@setter::x
  exportNamespace
    x: package:test/a.dart::@getter::x
    x=: package:test/a.dart::@setter::x
''');
  }

  test_export_variable_const() async {
    newFile('$testPackageLibPath/a.dart', 'const x = 0;');
    var library = await buildLibrary('export "a.dart";');
    configuration.withExportScope = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryExports
        package:test/a.dart
  exportedReferences
    exported[(0, 0)] package:test/a.dart::@getter::x
  exportNamespace
    x: package:test/a.dart::@getter::x
''');
  }

  test_export_variable_final() async {
    newFile('$testPackageLibPath/a.dart', 'final x = 0;');
    var library = await buildLibrary('export "a.dart";');
    configuration.withExportScope = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryExports
        package:test/a.dart
  exportedReferences
    exported[(0, 0)] package:test/a.dart::@getter::x
  exportNamespace
    x: package:test/a.dart::@getter::x
''');
  }

  test_exportImport_configurations_useDefault() async {
    declaredVariables = {'dart.library.io': 'false'};
    newFile('$testPackageLibPath/foo.dart', 'class A {}');
    newFile('$testPackageLibPath/foo_io.dart', 'class A {}');
    newFile('$testPackageLibPath/foo_html.dart', 'class A {}');
    newFile('$testPackageLibPath/bar.dart', r'''
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
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/bar.dart
      classes
        #F1 class B (nameOffset:25) (firstTokenOffset:19) (offset:25)
          element: <testLibrary>::@class::B
          constructors
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
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

  test_exportImport_configurations_useFirst() async {
    declaredVariables = {
      'dart.library.io': 'true',
      'dart.library.html': 'false',
    };
    newFile('$testPackageLibPath/foo.dart', 'class A {}');
    newFile('$testPackageLibPath/foo_io.dart', 'class A {}');
    newFile('$testPackageLibPath/foo_html.dart', 'class A {}');
    newFile('$testPackageLibPath/bar.dart', r'''
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
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/bar.dart
      classes
        #F1 class B (nameOffset:25) (firstTokenOffset:19) (offset:25)
          element: <testLibrary>::@class::B
          constructors
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
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

  test_exportImport_configurations_useSecond() async {
    declaredVariables = {
      'dart.library.io': 'false',
      'dart.library.html': 'true',
    };
    newFile('$testPackageLibPath/foo.dart', 'class A {}');
    newFile('$testPackageLibPath/foo_io.dart', 'class A {}');
    newFile('$testPackageLibPath/foo_html.dart', 'class A {}');
    newFile('$testPackageLibPath/bar.dart', r'''
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
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/bar.dart
      classes
        #F1 class B (nameOffset:25) (firstTokenOffset:19) (offset:25)
          element: <testLibrary>::@class::B
          constructors
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
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

  test_exports() async {
    newFile('$testPackageLibPath/a.dart', 'library a;');
    newFile('$testPackageLibPath/b.dart', 'library b;');
    var library = await buildLibrary('export "a.dart"; export "b.dart";');
    configuration.withExportScope = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryExports
        package:test/a.dart
        package:test/b.dart
  exportedReferences
  exportNamespace
''');
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_exportScope_part_class() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment class A {}
class B {}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
class A {}
''');

    configuration.withExportScope = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      classes
        class A @21
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::A
          augmented
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      classes
        augment class A @35
          reference: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@class::A
        class B @46
          reference: <testLibrary>::@fragment::package:test/a.dart::@class::B
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          constructors
            synthetic @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@class::B::@constructor::new
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@class::B
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
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      classes
        class A @21
          reference: <testLibraryFragment>::@class::A
          element: <testLibrary>::@class::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <testLibraryFragment>::@class::A::@constructor::new#element
              typeName: A
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      classes
        class A @35
          reference: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A
          element: <testLibrary>::@class::A
          previousFragment: <testLibraryFragment>::@class::A
        class B @46
          reference: <testLibrary>::@fragment::package:test/a.dart::@class::B
          element: <testLibrary>::@class::B
          constructors
            synthetic new
              reference: <testLibrary>::@fragment::package:test/a.dart::@class::B::@constructor::new
              element: <testLibrary>::@fragment::package:test/a.dart::@class::B::@constructor::new#element
              typeName: B
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
    class B
      reference: <testLibrary>::@class::B
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@class::B
      constructors
        synthetic new
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@class::B::@constructor::new
  exportedReferences
    declared <testLibrary>::@fragment::package:test/a.dart::@class::B
    declared <testLibraryFragment>::@class::A
  exportNamespace
    A: <testLibraryFragment>::@class::A
    B: <testLibrary>::@fragment::package:test/a.dart::@class::B
''');
  }

  test_exportScope_part_export() async {
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
part of 'test.dart';
export 'a.dart';
''');

    newFile('$testPackageLibPath/e.dart', r'''
part of 'test.dart';
export 'b.dart';
export 'c.dart';
''');

    var library = await buildLibrary(r'''
part 'd.dart';
part 'e.dart';
class X {}
''');

    configuration.withExportScope = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      nextFragment: #F1
      parts
        part_0
          uri: package:test/d.dart
          partKeywordOffset: 0
          unit: #F1
        part_1
          uri: package:test/e.dart
          partKeywordOffset: 15
          unit: #F2
      classes
        #F3 class X (nameOffset:36) (firstTokenOffset:30) (offset:36)
          element: <testLibrary>::@class::X
          constructors
            #F4 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:36)
              element: <testLibrary>::@class::X::@constructor::new
              typeName: X
    #F1 package:test/d.dart
      element: <testLibrary>
      enclosingFragment: #F0
      previousFragment: #F0
      nextFragment: #F2
      libraryExports
        package:test/a.dart
    #F2 package:test/e.dart
      element: <testLibrary>
      enclosingFragment: #F0
      previousFragment: #F1
      libraryExports
        package:test/b.dart
        package:test/c.dart
  classes
    class X
      reference: <testLibrary>::@class::X
      firstFragment: #F3
      constructors
        synthetic new
          reference: <testLibrary>::@class::X::@constructor::new
          firstFragment: #F4
  exportedReferences
    exported[(1, 0)] package:test/a.dart::@class::A
    exported[(2, 0)] package:test/b.dart::@class::B1
    exported[(2, 0)] package:test/b.dart::@class::B2
    exported[(2, 1)] package:test/c.dart::@class::C
    declared <testLibrary>::@class::X
  exportNamespace
    A: package:test/a.dart::@class::A
    B1: package:test/b.dart::@class::B1
    B2: package:test/b.dart::@class::B2
    C: package:test/c.dart::@class::C
    X: <testLibrary>::@class::X
''');
  }

  test_exportScope_part_export_hide() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A1 {}
class A2 {}
class A3 {}
class A4 {}
''');

    newFile('$testPackageLibPath/b.dart', r'''
part of 'test.dart';
export 'a.dart' hide A2, A4;
''');

    var library = await buildLibrary(r'''
part 'b.dart';
class X {}
''');

    configuration.withExportScope = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      nextFragment: #F1
      parts
        part_0
          uri: package:test/b.dart
          partKeywordOffset: 0
          unit: #F1
      classes
        #F2 class X (nameOffset:21) (firstTokenOffset:15) (offset:21)
          element: <testLibrary>::@class::X
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@class::X::@constructor::new
              typeName: X
    #F1 package:test/b.dart
      element: <testLibrary>
      enclosingFragment: #F0
      previousFragment: #F0
      libraryExports
        package:test/a.dart
          combinators
            hide: A2, A4
  classes
    class X
      reference: <testLibrary>::@class::X
      firstFragment: #F2
      constructors
        synthetic new
          reference: <testLibrary>::@class::X::@constructor::new
          firstFragment: #F3
  exportedReferences
    exported[(1, 0)] package:test/a.dart::@class::A1
    exported[(1, 0)] package:test/a.dart::@class::A3
    declared <testLibrary>::@class::X
  exportNamespace
    A1: package:test/a.dart::@class::A1
    A3: package:test/a.dart::@class::A3
    X: <testLibrary>::@class::X
''');
  }

  test_exportScope_part_export_show() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A1 {}
class A2 {}
class A3 {}
''');

    newFile('$testPackageLibPath/b.dart', r'''
part of 'test.dart';
export 'a.dart' show A1, A3;
''');

    var library = await buildLibrary(r'''
part 'b.dart';
class X {}
''');

    configuration.withExportScope = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      nextFragment: #F1
      parts
        part_0
          uri: package:test/b.dart
          partKeywordOffset: 0
          unit: #F1
      classes
        #F2 class X (nameOffset:21) (firstTokenOffset:15) (offset:21)
          element: <testLibrary>::@class::X
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@class::X::@constructor::new
              typeName: X
    #F1 package:test/b.dart
      element: <testLibrary>
      enclosingFragment: #F0
      previousFragment: #F0
      libraryExports
        package:test/a.dart
          combinators
            show: A1, A3
  classes
    class X
      reference: <testLibrary>::@class::X
      firstFragment: #F2
      constructors
        synthetic new
          reference: <testLibrary>::@class::X::@constructor::new
          firstFragment: #F3
  exportedReferences
    exported[(1, 0)] package:test/a.dart::@class::A1
    exported[(1, 0)] package:test/a.dart::@class::A3
    declared <testLibrary>::@class::X
  exportNamespace
    A1: package:test/a.dart::@class::A1
    A3: package:test/a.dart::@class::A3
    X: <testLibrary>::@class::X
''');
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_exportScope_part_mixin() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment mixin A {}
mixin B {}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
mixin A {}
''');

    configuration.withExportScope = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      mixins
        mixin A @21
          reference: <testLibraryFragment>::@mixin::A
          enclosingElement3: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          superclassConstraints
            Object
          augmented
            superclassConstraints
              Object
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      mixins
        augment mixin A @35
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@mixin::A
        mixin B @46
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixin::B
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
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
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      mixins
        mixin A @21
          reference: <testLibraryFragment>::@mixin::A
          element: <testLibrary>::@mixin::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      mixins
        mixin A @35
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          element: <testLibrary>::@mixin::A
          previousFragment: <testLibraryFragment>::@mixin::A
        mixin B @46
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixin::B
          element: <testLibrary>::@mixin::B
  mixins
    mixin A
      reference: <testLibrary>::@mixin::A
      firstFragment: <testLibraryFragment>::@mixin::A
      superclassConstraints
        Object
    mixin B
      reference: <testLibrary>::@mixin::B
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@mixin::B
      superclassConstraints
        Object
  exportedReferences
    declared <testLibrary>::@fragment::package:test/a.dart::@mixin::B
    declared <testLibraryFragment>::@mixin::A
  exportNamespace
    A: <testLibraryFragment>::@mixin::A
    B: <testLibrary>::@fragment::package:test/a.dart::@mixin::B
''');
  }

  test_exportScope_part_nested_class() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
part 'b.dart';
class A {}
''');

    newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';
class B {}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
class C {}
''');

    configuration.withExportScope = true;
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
        #F2 class C (nameOffset:21) (firstTokenOffset:15) (offset:21)
          element: <testLibrary>::@class::C
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
    #F1 package:test/a.dart
      element: <testLibrary>
      enclosingFragment: #F0
      previousFragment: #F0
      nextFragment: #F4
      parts
        part_1
          uri: package:test/b.dart
          partKeywordOffset: 21
          unit: #F4
      classes
        #F5 class A (nameOffset:42) (firstTokenOffset:36) (offset:42)
          element: <testLibrary>::@class::A
          constructors
            #F6 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:42)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
    #F4 package:test/b.dart
      element: <testLibrary>
      enclosingFragment: #F1
      previousFragment: #F1
      classes
        #F7 class B (nameOffset:24) (firstTokenOffset:18) (offset:24)
          element: <testLibrary>::@class::B
          constructors
            #F8 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:24)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F2
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F5
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F6
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F7
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F8
  exportedReferences
    declared <testLibrary>::@class::A
    declared <testLibrary>::@class::B
    declared <testLibrary>::@class::C
  exportNamespace
    A: <testLibrary>::@class::A
    B: <testLibrary>::@class::B
    C: <testLibrary>::@class::C
''');
  }

  test_exportScope_part_nested_export() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {}
''');

    newFile('$testPackageLibPath/b.dart', r'''
class B {}
''');

    newFile('$testPackageLibPath/c.dart', r'''
part of 'test.dart';
part 'd.dart';
export 'a.dart';
''');

    newFile('$testPackageLibPath/d.dart', r'''
part of 'c.dart';
export 'b.dart';
''');

    var library = await buildLibrary(r'''
part 'c.dart';
class X {}
''');

    configuration.withExportScope = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      nextFragment: #F1
      parts
        part_0
          uri: package:test/c.dart
          partKeywordOffset: 0
          unit: #F1
      classes
        #F2 class X (nameOffset:21) (firstTokenOffset:15) (offset:21)
          element: <testLibrary>::@class::X
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@class::X::@constructor::new
              typeName: X
    #F1 package:test/c.dart
      element: <testLibrary>
      enclosingFragment: #F0
      previousFragment: #F0
      nextFragment: #F4
      libraryExports
        package:test/a.dart
      parts
        part_1
          uri: package:test/d.dart
          partKeywordOffset: 21
          unit: #F4
    #F4 package:test/d.dart
      element: <testLibrary>
      enclosingFragment: #F1
      previousFragment: #F1
      libraryExports
        package:test/b.dart
  classes
    class X
      reference: <testLibrary>::@class::X
      firstFragment: #F2
      constructors
        synthetic new
          reference: <testLibrary>::@class::X::@constructor::new
          firstFragment: #F3
  exportedReferences
    exported[(1, 0)] package:test/a.dart::@class::A
    exported[(2, 0)] package:test/b.dart::@class::B
    declared <testLibrary>::@class::X
  exportNamespace
    A: package:test/a.dart::@class::A
    B: package:test/b.dart::@class::B
    X: <testLibrary>::@class::X
''');
  }

  test_exportScope_part_variable() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
int a = 0;
''');

    var library = await buildLibrary(r'''
part 'a.dart';
''');

    configuration.withExportScope = true;
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
      topLevelVariables
        #F2 hasInitializer a (nameOffset:25) (firstTokenOffset:25) (offset:25)
          element: <testLibrary>::@topLevelVariable::a
      getters
        #F3 synthetic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
          element: <testLibrary>::@getter::a
      setters
        #F4 synthetic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
          element: <testLibrary>::@setter::a
          formalParameters
            #F5 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
              element: <testLibrary>::@setter::a::@formalParameter::value
  topLevelVariables
    hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F2
      type: int
      getter: <testLibrary>::@getter::a
      setter: <testLibrary>::@setter::a
  getters
    synthetic static a
      reference: <testLibrary>::@getter::a
      firstFragment: #F3
      returnType: int
      variable: <testLibrary>::@topLevelVariable::a
  setters
    synthetic static a
      reference: <testLibrary>::@setter::a
      firstFragment: #F4
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F5
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::a
  exportedReferences
    declared <testLibrary>::@getter::a
    declared <testLibrary>::@setter::a
  exportNamespace
    a: <testLibrary>::@getter::a
    a=: <testLibrary>::@setter::a
''');
  }

  test_exportScope_part_variable_const() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
const a = 0;
''');

    var library = await buildLibrary(r'''
part 'a.dart';
''');

    configuration.withExportScope = true;
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
      topLevelVariables
        #F2 hasInitializer a (nameOffset:27) (firstTokenOffset:27) (offset:27)
          element: <testLibrary>::@topLevelVariable::a
          initializer: expression_0
            IntegerLiteral
              literal: 0 @31
              staticType: int
      getters
        #F3 synthetic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:27)
          element: <testLibrary>::@getter::a
  topLevelVariables
    const hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F2
      type: int
      constantInitializer
        fragment: #F2
        expression: expression_0
      getter: <testLibrary>::@getter::a
  getters
    synthetic static a
      reference: <testLibrary>::@getter::a
      firstFragment: #F3
      returnType: int
      variable: <testLibrary>::@topLevelVariable::a
  exportedReferences
    declared <testLibrary>::@getter::a
  exportNamespace
    a: <testLibrary>::@getter::a
''');
  }

  test_library_exports_noRelativeUriStr() async {
    var library = await buildLibrary(r'''
export '${'foo'}.dart';
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryExports
        noRelativeUriString
''');
  }

  test_library_exports_withRelativeUri_emptyUriSelf() async {
    var library = await buildLibrary(r'''
export '';
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryExports
        package:test/test.dart
''');
  }

  test_library_exports_withRelativeUri_noSource() async {
    var library = await buildLibrary(r'''
export 'foo:bar';
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryExports
        relativeUri 'foo:bar'
''');
  }

  test_library_exports_withRelativeUri_notExists() async {
    var library = await buildLibrary(r'''
export 'a.dart';
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryExports
        package:test/a.dart
''');
  }

  test_library_exports_withRelativeUri_notLibrary_part() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
''');
    var library = await buildLibrary(r'''
export 'a.dart';
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryExports
        source 'package:test/a.dart'
''');
  }

  test_library_exports_withRelativeUriString() async {
    var library = await buildLibrary(r'''
export ':';
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryExports
        relativeUriString ':'
''');
  }

  test_unresolved_export() async {
    var library = await buildLibrary("export 'foo.dart';");
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryExports
        package:test/foo.dart
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
