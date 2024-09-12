// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../dart/resolution/node_text_expectations.dart';
import '../elements_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TopLevelFunctionElementTest_keepLinking);
    defineReflectiveTests(TopLevelFunctionElementTest_fromBytes);
    defineReflectiveTests(TopLevelFunctionElementTest_augmentation_keepLinking);
    defineReflectiveTests(TopLevelFunctionElementTest_augmentation_fromBytes);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

abstract class TopLevelFunctionElementTest extends ElementsBaseTest {
  test_function_async() async {
    var library = await buildLibrary(r'''
import 'dart:async';
Future f() async {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    dart:async
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryImports
        dart:async
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
      functions
        f @28 async
          reference: <testLibraryFragment>::@function::f
          enclosingElement: <testLibraryFragment>
          returnType: Future<dynamic>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        dart:async
      functions
        f @28
          reference: <testLibraryFragment>::@function::f
          element: <none>
  functions
    f
      reference: <none>
      returnType: Future<dynamic>
''');
  }

  test_function_asyncStar() async {
    var library = await buildLibrary(r'''
import 'dart:async';
Stream f() async* {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    dart:async
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryImports
        dart:async
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
      functions
        f @28 async*
          reference: <testLibraryFragment>::@function::f
          enclosingElement: <testLibraryFragment>
          returnType: Stream<dynamic>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        dart:async
      functions
        f @28
          reference: <testLibraryFragment>::@function::f
          element: <none>
  functions
    f
      reference: <none>
      returnType: Stream<dynamic>
''');
  }

  test_function_documented() async {
    var library = await buildLibrary('''
// Extra comment so doc comment offset != 0
/**
 * Docs
 */
f() {}''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      functions
        f @60
          reference: <testLibraryFragment>::@function::f
          enclosingElement: <testLibraryFragment>
          documentationComment: /**\n * Docs\n */
          returnType: dynamic
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      functions
        f @60
          reference: <testLibraryFragment>::@function::f
          element: <none>
          documentationComment: /**\n * Docs\n */
  functions
    f
      reference: <none>
      documentationComment: /**\n * Docs\n */
      returnType: dynamic
''');
  }

  test_function_entry_point() async {
    var library = await buildLibrary('main() {}');
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
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      functions
        main @0
          reference: <testLibraryFragment>::@function::main
          element: <none>
  functions
    main
      reference: <none>
      returnType: dynamic
''');
  }

  test_function_entry_point_in_export() async {
    newFile('$testPackageLibPath/a.dart', 'library a; main() {}');
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
      element: <testLibrary>
''');
  }

  test_function_entry_point_in_export_hidden() async {
    newFile('$testPackageLibPath/a.dart', 'library a; main() {}');
    var library = await buildLibrary('export "a.dart" hide main;');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryExports
    package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      combinators
        hide: main
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryExports
        package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          combinators
            hide: main
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
''');
  }

  test_function_entry_point_in_part() async {
    newFile('$testPackageLibPath/a.dart', 'part of my.lib; main() {}');
    var library = await buildLibrary('library my.lib; part "a.dart";');
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
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      functions
        main @16
          reference: <testLibrary>::@fragment::package:test/a.dart::@function::main
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          returnType: dynamic
----------------------------------------
library
  reference: <testLibrary>
  name: my.lib
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      functions
        main @16
          reference: <testLibrary>::@fragment::package:test/a.dart::@function::main
          element: <none>
  functions
    main
      reference: <none>
      returnType: dynamic
''');
  }

  test_function_external() async {
    var library = await buildLibrary('external f();');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      functions
        external f @9
          reference: <testLibraryFragment>::@function::f
          enclosingElement: <testLibraryFragment>
          returnType: dynamic
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      functions
        f @9
          reference: <testLibraryFragment>::@function::f
          element: <none>
  functions
    external f
      reference: <none>
      returnType: dynamic
''');
  }

  test_function_hasImplicitReturnType_false() async {
    var library = await buildLibrary('''
int f() => 0;
''');
    var f = library.definingCompilationUnit.functions.single;
    expect(f.hasImplicitReturnType, isFalse);
  }

  test_function_hasImplicitReturnType_true() async {
    var library = await buildLibrary('''
f() => 0;
''');
    var f = library.definingCompilationUnit.functions.single;
    expect(f.hasImplicitReturnType, isTrue);
  }

  test_function_parameter_const() async {
    var library = await buildLibrary('''
void f(const x) {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      functions
        f @5
          reference: <testLibraryFragment>::@function::f
          enclosingElement: <testLibraryFragment>
          parameters
            requiredPositional x @13
              type: dynamic
          returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      functions
        f @5
          reference: <testLibraryFragment>::@function::f
          element: <none>
          parameters
            x @13
              element: <none>
  functions
    f
      reference: <none>
      parameters
        requiredPositional x
          reference: <none>
          type: dynamic
      returnType: void
''');
  }

  test_function_parameter_fieldFormal() async {
    var library = await buildLibrary('''
void f(int this.a) {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      functions
        f @5
          reference: <testLibraryFragment>::@function::f
          enclosingElement: <testLibraryFragment>
          parameters
            requiredPositional final this.a @16
              type: int
              field: <null>
          returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      functions
        f @5
          reference: <testLibraryFragment>::@function::f
          element: <none>
          parameters
            this.a @16
              element: <none>
  functions
    f
      reference: <none>
      parameters
        requiredPositional final a
          reference: <none>
          type: int
      returnType: void
''');
  }

  test_function_parameter_fieldFormal_default() async {
    var library = await buildLibrary('''
void f({int this.a: 42}) {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      functions
        f @5
          reference: <testLibraryFragment>::@function::f
          enclosingElement: <testLibraryFragment>
          parameters
            optionalNamed default final this.a @17
              reference: <testLibraryFragment>::@function::f::@parameter::a
              type: int
              constantInitializer
                IntegerLiteral
                  literal: 42 @20
                  staticType: int
              field: <null>
          returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      functions
        f @5
          reference: <testLibraryFragment>::@function::f
          element: <none>
          parameters
            default this.a @17
              reference: <testLibraryFragment>::@function::f::@parameter::a
              element: <none>
  functions
    f
      reference: <none>
      parameters
        optionalNamed final a
          reference: <none>
          type: int
      returnType: void
''');
  }

  test_function_parameter_fieldFormal_functionTyped() async {
    var library = await buildLibrary('''
void f(int this.a(int b)) {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      functions
        f @5
          reference: <testLibraryFragment>::@function::f
          enclosingElement: <testLibraryFragment>
          parameters
            requiredPositional final this.a @16
              type: int Function(int)
              parameters
                requiredPositional b @22
                  type: int
              field: <null>
          returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      functions
        f @5
          reference: <testLibraryFragment>::@function::f
          element: <none>
          parameters
            this.a @16
              element: <none>
  functions
    f
      reference: <none>
      parameters
        requiredPositional final a
          reference: <none>
          type: int Function(int)
          parameters
            requiredPositional b
              reference: <none>
              type: int
      returnType: void
''');
  }

  test_function_parameter_final() async {
    var library = await buildLibrary('f(final x) {}');
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
          parameters
            requiredPositional final x @8
              type: dynamic
          returnType: dynamic
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      functions
        f @0
          reference: <testLibraryFragment>::@function::f
          element: <none>
          parameters
            x @8
              element: <none>
  functions
    f
      reference: <none>
      parameters
        requiredPositional final x
          reference: <none>
          type: dynamic
      returnType: dynamic
''');
  }

  test_function_parameter_kind_named() async {
    var library = await buildLibrary('f({x}) {}');
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
          parameters
            optionalNamed default x @3
              reference: <testLibraryFragment>::@function::f::@parameter::x
              type: dynamic
          returnType: dynamic
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      functions
        f @0
          reference: <testLibraryFragment>::@function::f
          element: <none>
          parameters
            default x @3
              reference: <testLibraryFragment>::@function::f::@parameter::x
              element: <none>
  functions
    f
      reference: <none>
      parameters
        optionalNamed x
          reference: <none>
          type: dynamic
      returnType: dynamic
''');
  }

  test_function_parameter_kind_positional() async {
    var library = await buildLibrary('f([x]) {}');
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
          parameters
            optionalPositional default x @3
              type: dynamic
          returnType: dynamic
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      functions
        f @0
          reference: <testLibraryFragment>::@function::f
          element: <none>
          parameters
            default x @3
              element: <none>
  functions
    f
      reference: <none>
      parameters
        optionalPositional x
          reference: <none>
          type: dynamic
      returnType: dynamic
''');
  }

  test_function_parameter_kind_required() async {
    var library = await buildLibrary('f(x) {}');
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
          parameters
            requiredPositional x @2
              type: dynamic
          returnType: dynamic
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      functions
        f @0
          reference: <testLibraryFragment>::@function::f
          element: <none>
          parameters
            x @2
              element: <none>
  functions
    f
      reference: <none>
      parameters
        requiredPositional x
          reference: <none>
          type: dynamic
      returnType: dynamic
''');
  }

  test_function_parameter_parameters() async {
    var library = await buildLibrary('f(g(x, y)) {}');
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
          parameters
            requiredPositional g @2
              type: dynamic Function(dynamic, dynamic)
              parameters
                requiredPositional x @4
                  type: dynamic
                requiredPositional y @7
                  type: dynamic
          returnType: dynamic
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      functions
        f @0
          reference: <testLibraryFragment>::@function::f
          element: <none>
          parameters
            g @2
              element: <none>
  functions
    f
      reference: <none>
      parameters
        requiredPositional g
          reference: <none>
          type: dynamic Function(dynamic, dynamic)
          parameters
            requiredPositional x
              reference: <none>
              type: dynamic
            requiredPositional y
              reference: <none>
              type: dynamic
      returnType: dynamic
''');
  }

  test_function_parameter_return_type() async {
    var library = await buildLibrary('f(int g()) {}');
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
          parameters
            requiredPositional g @6
              type: int Function()
          returnType: dynamic
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      functions
        f @0
          reference: <testLibraryFragment>::@function::f
          element: <none>
          parameters
            g @6
              element: <none>
  functions
    f
      reference: <none>
      parameters
        requiredPositional g
          reference: <none>
          type: int Function()
      returnType: dynamic
''');
  }

  test_function_parameter_return_type_void() async {
    var library = await buildLibrary('f(void g()) {}');
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
          parameters
            requiredPositional g @7
              type: void Function()
          returnType: dynamic
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      functions
        f @0
          reference: <testLibraryFragment>::@function::f
          element: <none>
          parameters
            g @7
              element: <none>
  functions
    f
      reference: <none>
      parameters
        requiredPositional g
          reference: <none>
          type: void Function()
      returnType: dynamic
''');
  }

  test_function_parameter_type() async {
    var library = await buildLibrary('f(int i) {}');
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
          parameters
            requiredPositional i @6
              type: int
          returnType: dynamic
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      functions
        f @0
          reference: <testLibraryFragment>::@function::f
          element: <none>
          parameters
            i @6
              element: <none>
  functions
    f
      reference: <none>
      parameters
        requiredPositional i
          reference: <none>
          type: int
      returnType: dynamic
''');
  }

  test_function_parameter_type_typeParameter() async {
    var library = await buildLibrary('''
void f<T>(T a) {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      functions
        f @5
          reference: <testLibraryFragment>::@function::f
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T @7
              defaultType: dynamic
          parameters
            requiredPositional a @12
              type: T
          returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      functions
        f @5
          reference: <testLibraryFragment>::@function::f
          element: <none>
          typeParameters
            T @7
              element: <none>
          parameters
            a @12
              element: <none>
  functions
    f
      reference: <none>
      typeParameters
        T
      parameters
        requiredPositional a
          reference: <none>
          type: T
      returnType: void
''');
  }

  test_function_parameter_type_unresolved() async {
    var library = await buildLibrary(r'''
void f(A a) {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      functions
        f @5
          reference: <testLibraryFragment>::@function::f
          enclosingElement: <testLibraryFragment>
          parameters
            requiredPositional a @9
              type: InvalidType
          returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      functions
        f @5
          reference: <testLibraryFragment>::@function::f
          element: <none>
          parameters
            a @9
              element: <none>
  functions
    f
      reference: <none>
      parameters
        requiredPositional a
          reference: <none>
          type: InvalidType
      returnType: void
''');
  }

  test_function_parameters() async {
    var library = await buildLibrary('f(x, y) {}');
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
          parameters
            requiredPositional x @2
              type: dynamic
            requiredPositional y @5
              type: dynamic
          returnType: dynamic
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      functions
        f @0
          reference: <testLibraryFragment>::@function::f
          element: <none>
          parameters
            x @2
              element: <none>
            y @5
              element: <none>
  functions
    f
      reference: <none>
      parameters
        requiredPositional x
          reference: <none>
          type: dynamic
        requiredPositional y
          reference: <none>
          type: dynamic
      returnType: dynamic
''');
  }

  test_function_return_type_implicit() async {
    var library = await buildLibrary('f() => null;');
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
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      functions
        f @0
          reference: <testLibraryFragment>::@function::f
          element: <none>
  functions
    f
      reference: <none>
      returnType: dynamic
''');
  }

  test_function_return_type_unresolved() async {
    var library = await buildLibrary(r'''
A f() {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      functions
        f @2
          reference: <testLibraryFragment>::@function::f
          enclosingElement: <testLibraryFragment>
          returnType: InvalidType
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      functions
        f @2
          reference: <testLibraryFragment>::@function::f
          element: <none>
  functions
    f
      reference: <none>
      returnType: InvalidType
''');
  }

  test_function_return_type_void() async {
    var library = await buildLibrary('void f() {}');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      functions
        f @5
          reference: <testLibraryFragment>::@function::f
          enclosingElement: <testLibraryFragment>
          returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      functions
        f @5
          reference: <testLibraryFragment>::@function::f
          element: <none>
  functions
    f
      reference: <none>
      returnType: void
''');
  }

  test_function_returnType() async {
    var library = await buildLibrary('''
int f() => 0;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      functions
        f @4
          reference: <testLibraryFragment>::@function::f
          enclosingElement: <testLibraryFragment>
          returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      functions
        f @4
          reference: <testLibraryFragment>::@function::f
          element: <none>
  functions
    f
      reference: <none>
      returnType: int
''');
  }

  test_function_returnType_typeParameter() async {
    var library = await buildLibrary('''
T f<T>() => throw 0;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      functions
        f @2
          reference: <testLibraryFragment>::@function::f
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T @4
              defaultType: dynamic
          returnType: T
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      functions
        f @2
          reference: <testLibraryFragment>::@function::f
          element: <none>
          typeParameters
            T @4
              element: <none>
  functions
    f
      reference: <none>
      typeParameters
        T
      returnType: T
''');
  }

  test_function_type_parameter_with_function_typed_parameter() async {
    var library = await buildLibrary('void f<T, U>(T x(U u)) {}');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      functions
        f @5
          reference: <testLibraryFragment>::@function::f
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T @7
              defaultType: dynamic
            covariant U @10
              defaultType: dynamic
          parameters
            requiredPositional x @15
              type: T Function(U)
              parameters
                requiredPositional u @19
                  type: U
          returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      functions
        f @5
          reference: <testLibraryFragment>::@function::f
          element: <none>
          typeParameters
            T @7
              element: <none>
            U @10
              element: <none>
          parameters
            x @15
              element: <none>
  functions
    f
      reference: <none>
      typeParameters
        T
        U
      parameters
        requiredPositional x
          reference: <none>
          type: T Function(U)
          parameters
            requiredPositional u
              reference: <none>
              type: U
      returnType: void
''');
  }

  test_function_typed_parameter_implicit() async {
    var library = await buildLibrary('f(g()) => null;');
    expect(
        library
            .definingCompilationUnit.functions[0].parameters[0].hasImplicitType,
        isFalse);
  }

  test_function_typeParameters_hasBound() async {
    var library = await buildLibrary('''
void f<T extends num>() {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      functions
        f @5
          reference: <testLibraryFragment>::@function::f
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T @7
              bound: num
              defaultType: num
          returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      functions
        f @5
          reference: <testLibraryFragment>::@function::f
          element: <none>
          typeParameters
            T @7
              element: <none>
  functions
    f
      reference: <none>
      typeParameters
        T
          bound: num
      returnType: void
''');
  }

  test_function_typeParameters_noBound() async {
    var library = await buildLibrary('''
void f<T>() {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      functions
        f @5
          reference: <testLibraryFragment>::@function::f
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T @7
              defaultType: dynamic
          returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      functions
        f @5
          reference: <testLibraryFragment>::@function::f
          element: <none>
          typeParameters
            T @7
              element: <none>
  functions
    f
      reference: <none>
      typeParameters
        T
      returnType: void
''');
  }

  test_functions() async {
    var library = await buildLibrary('f() {} g() {}');
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
        g @7
          reference: <testLibraryFragment>::@function::g
          enclosingElement: <testLibraryFragment>
          returnType: dynamic
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      functions
        f @0
          reference: <testLibraryFragment>::@function::f
          element: <none>
        g @7
          reference: <testLibraryFragment>::@function::g
          element: <none>
  functions
    f
      reference: <none>
      returnType: dynamic
    g
      reference: <none>
      returnType: dynamic
''');
  }

  test_main_class() async {
    var library = await buildLibrary('class main {}');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      classes
        class main @6
          reference: <testLibraryFragment>::@class::main
          enclosingElement: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::main::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::main
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class main @6
          reference: <testLibraryFragment>::@class::main
          element: <testLibraryFragment>::@class::main
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::main::@constructor::new
              element: <none>
  classes
    class main
      reference: <testLibraryFragment>::@class::main
      firstFragment: <testLibraryFragment>::@class::main
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::main::@constructor::new
''');
  }

  test_main_class_alias() async {
    var library =
        await buildLibrary('class main = C with D; class C {} class D {}');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      classes
        class alias main @6
          reference: <testLibraryFragment>::@class::main
          enclosingElement: <testLibraryFragment>
          supertype: C
          mixins
            D
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::main::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::main
              constantInitializers
                SuperConstructorInvocation
                  superKeyword: super @0
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticElement: <testLibraryFragment>::@class::C::@constructor::new
              superConstructor: <testLibraryFragment>::@class::C::@constructor::new
        class C @29
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
        class D @40
          reference: <testLibraryFragment>::@class::D
          enclosingElement: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::D::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::D
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class main @6
          reference: <testLibraryFragment>::@class::main
          element: <testLibraryFragment>::@class::main
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::main::@constructor::new
              element: <none>
              constantInitializers
                SuperConstructorInvocation
                  superKeyword: super @0
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticElement: <testLibraryFragment>::@class::C::@constructor::new
              superConstructor: <testLibraryFragment>::@class::C::@constructor::new
        class C @29
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <none>
        class D @40
          reference: <testLibraryFragment>::@class::D
          element: <testLibraryFragment>::@class::D
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::D::@constructor::new
              element: <none>
  classes
    class alias main
      reference: <testLibraryFragment>::@class::main
      firstFragment: <testLibraryFragment>::@class::main
      supertype: C
      constructors
        synthetic new
          reference: <none>
          superConstructor: <none>
          firstFragment: <testLibraryFragment>::@class::main::@constructor::new
    class C
      reference: <testLibraryFragment>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
    class D
      reference: <testLibraryFragment>::@class::D
      firstFragment: <testLibraryFragment>::@class::D
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::D::@constructor::new
''');
  }

  test_main_class_alias_via_export() async {
    newFile('$testPackageLibPath/a.dart',
        'class main = C with D; class C {} class D {}');
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
      element: <testLibrary>
''');
  }

  test_main_class_via_export() async {
    newFile('$testPackageLibPath/a.dart', 'class main {}');
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
      element: <testLibrary>
''');
  }

  test_main_getter() async {
    var library = await buildLibrary('get main => null;');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      topLevelVariables
        synthetic static main @-1
          reference: <testLibraryFragment>::@topLevelVariable::main
          enclosingElement: <testLibraryFragment>
          type: dynamic
      accessors
        static get main @4
          reference: <testLibraryFragment>::@getter::main
          enclosingElement: <testLibraryFragment>
          returnType: dynamic
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        synthetic main @-1
          reference: <testLibraryFragment>::@topLevelVariable::main
          element: <none>
          getter2: <testLibraryFragment>::@getter::main
      getters
        get main @4
          reference: <testLibraryFragment>::@getter::main
          element: <none>
  topLevelVariables
    synthetic main
      reference: <none>
      type: dynamic
      firstFragment: <testLibraryFragment>::@topLevelVariable::main
      getter: <none>
  getters
    static get main
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::main
''');
  }

  test_main_getter_via_export() async {
    newFile('$testPackageLibPath/a.dart', 'get main => null;');
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
      element: <testLibrary>
''');
  }

  test_main_typedef() async {
    var library = await buildLibrary('typedef main();');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      typeAliases
        functionTypeAliasBased main @8
          reference: <testLibraryFragment>::@typeAlias::main
          aliasedType: dynamic Function()
          aliasedElement: GenericFunctionTypeElement
            returnType: dynamic
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        main @8
          reference: <testLibraryFragment>::@typeAlias::main
          element: <none>
  typeAliases
    main
      reference: <none>
      aliasedType: dynamic Function()
''');
  }

  test_main_typedef_via_export() async {
    newFile('$testPackageLibPath/a.dart', 'typedef main();');
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
      element: <testLibrary>
''');
  }

  test_main_variable() async {
    var library = await buildLibrary('var main;');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      topLevelVariables
        static main @4
          reference: <testLibraryFragment>::@topLevelVariable::main
          enclosingElement: <testLibraryFragment>
          type: dynamic
      accessors
        synthetic static get main @-1
          reference: <testLibraryFragment>::@getter::main
          enclosingElement: <testLibraryFragment>
          returnType: dynamic
        synthetic static set main= @-1
          reference: <testLibraryFragment>::@setter::main
          enclosingElement: <testLibraryFragment>
          parameters
            requiredPositional _main @-1
              type: dynamic
          returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        main @4
          reference: <testLibraryFragment>::@topLevelVariable::main
          element: <none>
          getter2: <testLibraryFragment>::@getter::main
          setter2: <testLibraryFragment>::@setter::main
      getters
        get main @-1
          reference: <testLibraryFragment>::@getter::main
          element: <none>
      setters
        set main= @-1
          reference: <testLibraryFragment>::@setter::main
          element: <none>
          parameters
            _main @-1
              element: <none>
  topLevelVariables
    main
      reference: <none>
      type: dynamic
      firstFragment: <testLibraryFragment>::@topLevelVariable::main
      getter: <none>
      setter: <none>
  getters
    synthetic static get main
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::main
  setters
    synthetic static set main=
      reference: <none>
      parameters
        requiredPositional _main
          reference: <none>
          type: dynamic
      firstFragment: <testLibraryFragment>::@setter::main
''');
  }

  test_main_variable_via_export() async {
    newFile('$testPackageLibPath/a.dart', 'var main;');
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
      element: <testLibrary>
''');
  }
}

abstract class TopLevelFunctionElementTest_augmentation
    extends ElementsBaseTest {
  test_function_augmentationTarget() async {
    newFile('$testPackageLibPath/a1.dart', r'''
part of 'test.dart';
part 'a11.dart';
part 'a12.dart';
augment void foo() {}
''');

    newFile('$testPackageLibPath/a11.dart', r'''
part of 'a1.dart';
augment void foo() {}
''');

    newFile('$testPackageLibPath/a12.dart', r'''
part of 'a1.dart';
augment void foo() {}
''');

    newFile('$testPackageLibPath/a2.dart', r'''
part of 'test.dart';
part 'a21.dart';
part 'a22.dart';
augment void foo() {}
''');

    newFile('$testPackageLibPath/a21.dart', r'''
part of 'a2.dart';
augment void foo() {}
''');

    newFile('$testPackageLibPath/a22.dart', r'''
part of 'a2.dart';
augment void foo() {}
''');

    var library = await buildLibrary(r'''
part 'a1.dart';
part 'a2.dart';
void foo() {}
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
          uri: package:test/a1.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a1.dart
        part_1
          uri: package:test/a2.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a2.dart
      functions
        foo @37
          reference: <testLibraryFragment>::@function::foo
          enclosingElement: <testLibraryFragment>
          returnType: void
          augmentation: <testLibrary>::@fragment::package:test/a1.dart::@functionAugmentation::foo
    <testLibrary>::@fragment::package:test/a1.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      parts
        part_2
          uri: package:test/a11.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibrary>::@fragment::package:test/a1.dart
          unit: <testLibrary>::@fragment::package:test/a11.dart
        part_3
          uri: package:test/a12.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibrary>::@fragment::package:test/a1.dart
          unit: <testLibrary>::@fragment::package:test/a12.dart
      functions
        augment foo @68
          reference: <testLibrary>::@fragment::package:test/a1.dart::@functionAugmentation::foo
          enclosingElement: <testLibrary>::@fragment::package:test/a1.dart
          returnType: void
          augmentationTarget: <testLibraryFragment>::@function::foo
          augmentation: <testLibrary>::@fragment::package:test/a11.dart::@functionAugmentation::foo
    <testLibrary>::@fragment::package:test/a11.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibrary>::@fragment::package:test/a1.dart
      functions
        augment foo @32
          reference: <testLibrary>::@fragment::package:test/a11.dart::@functionAugmentation::foo
          enclosingElement: <testLibrary>::@fragment::package:test/a11.dart
          returnType: void
          augmentationTarget: <testLibrary>::@fragment::package:test/a1.dart::@functionAugmentation::foo
          augmentation: <testLibrary>::@fragment::package:test/a12.dart::@functionAugmentation::foo
    <testLibrary>::@fragment::package:test/a12.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibrary>::@fragment::package:test/a1.dart
      functions
        augment foo @32
          reference: <testLibrary>::@fragment::package:test/a12.dart::@functionAugmentation::foo
          enclosingElement: <testLibrary>::@fragment::package:test/a12.dart
          returnType: void
          augmentationTarget: <testLibrary>::@fragment::package:test/a11.dart::@functionAugmentation::foo
          augmentation: <testLibrary>::@fragment::package:test/a2.dart::@functionAugmentation::foo
    <testLibrary>::@fragment::package:test/a2.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      parts
        part_4
          uri: package:test/a21.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibrary>::@fragment::package:test/a2.dart
          unit: <testLibrary>::@fragment::package:test/a21.dart
        part_5
          uri: package:test/a22.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibrary>::@fragment::package:test/a2.dart
          unit: <testLibrary>::@fragment::package:test/a22.dart
      functions
        augment foo @68
          reference: <testLibrary>::@fragment::package:test/a2.dart::@functionAugmentation::foo
          enclosingElement: <testLibrary>::@fragment::package:test/a2.dart
          returnType: void
          augmentationTarget: <testLibrary>::@fragment::package:test/a12.dart::@functionAugmentation::foo
          augmentation: <testLibrary>::@fragment::package:test/a21.dart::@functionAugmentation::foo
    <testLibrary>::@fragment::package:test/a21.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibrary>::@fragment::package:test/a2.dart
      functions
        augment foo @32
          reference: <testLibrary>::@fragment::package:test/a21.dart::@functionAugmentation::foo
          enclosingElement: <testLibrary>::@fragment::package:test/a21.dart
          returnType: void
          augmentationTarget: <testLibrary>::@fragment::package:test/a2.dart::@functionAugmentation::foo
          augmentation: <testLibrary>::@fragment::package:test/a22.dart::@functionAugmentation::foo
    <testLibrary>::@fragment::package:test/a22.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibrary>::@fragment::package:test/a2.dart
      functions
        augment foo @32
          reference: <testLibrary>::@fragment::package:test/a22.dart::@functionAugmentation::foo
          enclosingElement: <testLibrary>::@fragment::package:test/a22.dart
          returnType: void
          augmentationTarget: <testLibrary>::@fragment::package:test/a21.dart::@functionAugmentation::foo
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a1.dart
      functions
        foo @37
          reference: <testLibraryFragment>::@function::foo
          element: <none>
    <testLibrary>::@fragment::package:test/a1.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/a11.dart
      functions
        foo @68
          reference: <testLibrary>::@fragment::package:test/a1.dart::@functionAugmentation::foo
          element: <none>
    <testLibrary>::@fragment::package:test/a11.dart
      element: <testLibrary>
      previousFragment: <testLibrary>::@fragment::package:test/a1.dart
      nextFragment: <testLibrary>::@fragment::package:test/a12.dart
      functions
        foo @32
          reference: <testLibrary>::@fragment::package:test/a11.dart::@functionAugmentation::foo
          element: <none>
    <testLibrary>::@fragment::package:test/a12.dart
      element: <testLibrary>
      previousFragment: <testLibrary>::@fragment::package:test/a11.dart
      nextFragment: <testLibrary>::@fragment::package:test/a2.dart
      functions
        foo @32
          reference: <testLibrary>::@fragment::package:test/a12.dart::@functionAugmentation::foo
          element: <none>
    <testLibrary>::@fragment::package:test/a2.dart
      element: <testLibrary>
      previousFragment: <testLibrary>::@fragment::package:test/a12.dart
      nextFragment: <testLibrary>::@fragment::package:test/a21.dart
      functions
        foo @68
          reference: <testLibrary>::@fragment::package:test/a2.dart::@functionAugmentation::foo
          element: <none>
    <testLibrary>::@fragment::package:test/a21.dart
      element: <testLibrary>
      previousFragment: <testLibrary>::@fragment::package:test/a2.dart
      nextFragment: <testLibrary>::@fragment::package:test/a22.dart
      functions
        foo @32
          reference: <testLibrary>::@fragment::package:test/a21.dart::@functionAugmentation::foo
          element: <none>
    <testLibrary>::@fragment::package:test/a22.dart
      element: <testLibrary>
      previousFragment: <testLibrary>::@fragment::package:test/a21.dart
      functions
        foo @32
          reference: <testLibrary>::@fragment::package:test/a22.dart::@functionAugmentation::foo
          element: <none>
  functions
    foo
      reference: <none>
      returnType: void
    foo
      reference: <none>
      returnType: void
    foo
      reference: <none>
      returnType: void
    foo
      reference: <none>
      returnType: void
    foo
      reference: <none>
      returnType: void
    foo
      reference: <none>
      returnType: void
    foo
      reference: <none>
      returnType: void
''');
  }

  test_function_augments_class() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';

augment void foo() {}
''');

    var library = await buildLibrary(r'''
part 'a.dart';

class foo {}
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
        class foo @22
          reference: <testLibraryFragment>::@class::foo
          enclosingElement: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::foo::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::foo
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      functions
        augment foo @35
          reference: <testLibrary>::@fragment::package:test/a.dart::@functionAugmentation::foo
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          returnType: void
          augmentationTargetAny: <testLibraryFragment>::@class::foo
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      classes
        class foo @22
          reference: <testLibraryFragment>::@class::foo
          element: <testLibraryFragment>::@class::foo
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::foo::@constructor::new
              element: <none>
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      functions
        foo @35
          reference: <testLibrary>::@fragment::package:test/a.dart::@functionAugmentation::foo
          element: <none>
  classes
    class foo
      reference: <testLibraryFragment>::@class::foo
      firstFragment: <testLibraryFragment>::@class::foo
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::foo::@constructor::new
  functions
    foo
      reference: <none>
      returnType: void
''');
  }

  test_function_augments_function() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment void foo() {}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
void foo() {}
''');

    configuration.withExportScope = true;
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
      functions
        foo @20
          reference: <testLibraryFragment>::@function::foo
          enclosingElement: <testLibraryFragment>
          returnType: void
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@functionAugmentation::foo
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      functions
        augment foo @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@functionAugmentation::foo
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          returnType: void
          augmentationTarget: <testLibraryFragment>::@function::foo
  exportedReferences
    declared <testLibraryFragment>::@function::foo
  exportNamespace
    foo: <testLibraryFragment>::@function::foo
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      functions
        foo @20
          reference: <testLibraryFragment>::@function::foo
          element: <none>
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      functions
        foo @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@functionAugmentation::foo
          element: <none>
  functions
    foo
      reference: <none>
      returnType: void
    foo
      reference: <none>
      returnType: void
  exportedReferences
    declared <testLibraryFragment>::@function::foo
  exportNamespace
    foo: <testLibraryFragment>::@function::foo
''');
  }

  test_function_augments_function2() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
void foo() {}
augment void foo() {}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
''');

    configuration.withExportScope = true;
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
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      functions
        foo @26
          reference: <testLibrary>::@fragment::package:test/a.dart::@function::foo
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          returnType: void
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@functionAugmentation::foo
        augment foo @48
          reference: <testLibrary>::@fragment::package:test/a.dart::@functionAugmentation::foo
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          returnType: void
          augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@function::foo
  exportedReferences
    declared <testLibrary>::@fragment::package:test/a.dart::@function::foo
  exportNamespace
    foo: <testLibrary>::@fragment::package:test/a.dart::@function::foo
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      functions
        foo @26
          reference: <testLibrary>::@fragment::package:test/a.dart::@function::foo
          element: <none>
        foo @48
          reference: <testLibrary>::@fragment::package:test/a.dart::@functionAugmentation::foo
          element: <none>
  functions
    foo
      reference: <none>
      returnType: void
    foo
      reference: <none>
      returnType: void
  exportedReferences
    declared <testLibrary>::@fragment::package:test/a.dart::@function::foo
  exportNamespace
    foo: <testLibrary>::@fragment::package:test/a.dart::@function::foo
''');
  }

  test_function_augments_getter() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';

augment void foo() {}
''');

    var library = await buildLibrary(r'''
part 'a.dart';

int get foo => 0;
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
      topLevelVariables
        synthetic static foo @-1
          reference: <testLibraryFragment>::@topLevelVariable::foo
          enclosingElement: <testLibraryFragment>
          type: int
      accessors
        static get foo @24
          reference: <testLibraryFragment>::@getter::foo
          enclosingElement: <testLibraryFragment>
          returnType: int
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      functions
        augment foo @35
          reference: <testLibrary>::@fragment::package:test/a.dart::@functionAugmentation::foo
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          returnType: void
          augmentationTargetAny: <testLibraryFragment>::@getter::foo
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      topLevelVariables
        synthetic foo @-1
          reference: <testLibraryFragment>::@topLevelVariable::foo
          element: <none>
          getter2: <testLibraryFragment>::@getter::foo
      getters
        get foo @24
          reference: <testLibraryFragment>::@getter::foo
          element: <none>
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      functions
        foo @35
          reference: <testLibrary>::@fragment::package:test/a.dart::@functionAugmentation::foo
          element: <none>
  topLevelVariables
    synthetic foo
      reference: <none>
      type: int
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo
      getter: <none>
  getters
    static get foo
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::foo
  functions
    foo
      reference: <none>
      returnType: void
''');
  }

  test_function_augments_setter() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';

augment void foo() {}
''');

    var library = await buildLibrary(r'''
part 'a.dart';

set foo(int _) {}
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
      topLevelVariables
        synthetic static foo @-1
          reference: <testLibraryFragment>::@topLevelVariable::foo
          enclosingElement: <testLibraryFragment>
          type: int
      accessors
        static set foo= @20
          reference: <testLibraryFragment>::@setter::foo
          enclosingElement: <testLibraryFragment>
          parameters
            requiredPositional _ @28
              type: int
          returnType: void
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      functions
        augment foo @35
          reference: <testLibrary>::@fragment::package:test/a.dart::@functionAugmentation::foo
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          returnType: void
          augmentationTargetAny: <testLibraryFragment>::@setter::foo
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      topLevelVariables
        synthetic foo @-1
          reference: <testLibraryFragment>::@topLevelVariable::foo
          element: <none>
          setter2: <testLibraryFragment>::@setter::foo
      setters
        set foo= @20
          reference: <testLibraryFragment>::@setter::foo
          element: <none>
          parameters
            _ @28
              element: <none>
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      functions
        foo @35
          reference: <testLibrary>::@fragment::package:test/a.dart::@functionAugmentation::foo
          element: <none>
  topLevelVariables
    synthetic foo
      reference: <none>
      type: int
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo
      setter: <none>
  setters
    static set foo=
      reference: <none>
      parameters
        requiredPositional _
          reference: <none>
          type: int
      firstFragment: <testLibraryFragment>::@setter::foo
  functions
    foo
      reference: <none>
      returnType: void
''');
  }

  test_function_augments_variable() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';

augment void foo() {}
''');

    var library = await buildLibrary(r'''
part 'a.dart';

int foo = 0;
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
      topLevelVariables
        static foo @20
          reference: <testLibraryFragment>::@topLevelVariable::foo
          enclosingElement: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: true
      accessors
        synthetic static get foo @-1
          reference: <testLibraryFragment>::@getter::foo
          enclosingElement: <testLibraryFragment>
          returnType: int
        synthetic static set foo= @-1
          reference: <testLibraryFragment>::@setter::foo
          enclosingElement: <testLibraryFragment>
          parameters
            requiredPositional _foo @-1
              type: int
          returnType: void
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      functions
        augment foo @35
          reference: <testLibrary>::@fragment::package:test/a.dart::@functionAugmentation::foo
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          returnType: void
          augmentationTargetAny: <testLibraryFragment>::@getter::foo
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      topLevelVariables
        foo @20
          reference: <testLibraryFragment>::@topLevelVariable::foo
          element: <none>
          getter2: <testLibraryFragment>::@getter::foo
          setter2: <testLibraryFragment>::@setter::foo
      getters
        get foo @-1
          reference: <testLibraryFragment>::@getter::foo
          element: <none>
      setters
        set foo= @-1
          reference: <testLibraryFragment>::@setter::foo
          element: <none>
          parameters
            _foo @-1
              element: <none>
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      functions
        foo @35
          reference: <testLibrary>::@fragment::package:test/a.dart::@functionAugmentation::foo
          element: <none>
  topLevelVariables
    foo
      reference: <none>
      type: int
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo
      getter: <none>
      setter: <none>
  getters
    synthetic static get foo
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::foo
  setters
    synthetic static set foo=
      reference: <none>
      parameters
        requiredPositional _foo
          reference: <none>
          type: int
      firstFragment: <testLibraryFragment>::@setter::foo
  functions
    foo
      reference: <none>
      returnType: void
''');
  }

  test_getter_augments_class() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment int get foo => 0;
''');

    var library = await buildLibrary(r'''
part 'a.dart';
class foo {}
''');

    configuration
      ..withConstructors = false
      ..withExportScope = true
      ..withPropertyLinking = true;
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
        class foo @21
          reference: <testLibraryFragment>::@class::foo
          enclosingElement: <testLibraryFragment>
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      accessors
        augment static get foo @37
          reference: <testLibrary>::@fragment::package:test/a.dart::@getterAugmentation::foo
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          returnType: int
          id: getter_0
          variable: <null>
          augmentationTargetAny: <testLibraryFragment>::@class::foo
  exportedReferences
    declared <testLibraryFragment>::@class::foo
  exportNamespace
    foo: <testLibraryFragment>::@class::foo
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      classes
        class foo @21
          reference: <testLibraryFragment>::@class::foo
          element: <testLibraryFragment>::@class::foo
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      getters
        augment get foo @37
          reference: <testLibrary>::@fragment::package:test/a.dart::@getterAugmentation::foo
          element: <none>
  classes
    class foo
      reference: <testLibraryFragment>::@class::foo
      firstFragment: <testLibraryFragment>::@class::foo
  getters
    static get foo
      reference: <none>
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@getterAugmentation::foo
  exportedReferences
    declared <testLibraryFragment>::@class::foo
  exportNamespace
    foo: <testLibraryFragment>::@class::foo
''');
  }

  test_getter_augments_function() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment int get foo => 0;
''');

    var library = await buildLibrary(r'''
part 'a.dart';
void foo() {}
''');

    configuration
      ..withConstructors = false
      ..withExportScope = true
      ..withPropertyLinking = true;
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
      functions
        foo @20
          reference: <testLibraryFragment>::@function::foo
          enclosingElement: <testLibraryFragment>
          returnType: void
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      accessors
        augment static get foo @37
          reference: <testLibrary>::@fragment::package:test/a.dart::@getterAugmentation::foo
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          returnType: int
          id: getter_0
          variable: <null>
          augmentationTargetAny: <testLibraryFragment>::@function::foo
  exportedReferences
    declared <testLibraryFragment>::@function::foo
  exportNamespace
    foo: <testLibraryFragment>::@function::foo
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      functions
        foo @20
          reference: <testLibraryFragment>::@function::foo
          element: <none>
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      getters
        augment get foo @37
          reference: <testLibrary>::@fragment::package:test/a.dart::@getterAugmentation::foo
          element: <none>
  getters
    static get foo
      reference: <none>
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@getterAugmentation::foo
  functions
    foo
      reference: <none>
      returnType: void
  exportedReferences
    declared <testLibraryFragment>::@function::foo
  exportNamespace
    foo: <testLibraryFragment>::@function::foo
''');
  }

  test_getter_augments_getter() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment int get foo => 0;
''');

    var library = await buildLibrary(r'''
part 'a.dart';
int get foo => 0;
''');

    configuration
      ..withExportScope = true
      ..withPropertyLinking = true;
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
      topLevelVariables
        synthetic static foo @-1
          reference: <testLibraryFragment>::@topLevelVariable::foo
          enclosingElement: <testLibraryFragment>
          type: int
          id: variable_0
          getter: getter_0
      accessors
        static get foo @23
          reference: <testLibraryFragment>::@getter::foo
          enclosingElement: <testLibraryFragment>
          returnType: int
          id: getter_0
          variable: variable_0
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@getterAugmentation::foo
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      accessors
        augment static get foo @37
          reference: <testLibrary>::@fragment::package:test/a.dart::@getterAugmentation::foo
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          returnType: int
          id: getter_1
          variable: variable_0
          augmentationTarget: <testLibraryFragment>::@getter::foo
  exportedReferences
    declared <testLibraryFragment>::@getter::foo
  exportNamespace
    foo: <testLibraryFragment>::@getter::foo
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      topLevelVariables
        synthetic foo @-1
          reference: <testLibraryFragment>::@topLevelVariable::foo
          element: <none>
          getter2: <testLibraryFragment>::@getter::foo
      getters
        get foo @23
          reference: <testLibraryFragment>::@getter::foo
          element: <none>
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@getterAugmentation::foo
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      getters
        augment get foo @37
          reference: <testLibrary>::@fragment::package:test/a.dart::@getterAugmentation::foo
          element: <none>
          previousFragment: <testLibraryFragment>::@getter::foo
  topLevelVariables
    synthetic foo
      reference: <none>
      type: int
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo
      getter: <none>
  getters
    static get foo
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::foo
  exportedReferences
    declared <testLibraryFragment>::@getter::foo
  exportNamespace
    foo: <testLibraryFragment>::@getter::foo
''');
  }

  test_getter_augments_nothing() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment int get foo => 0;
''');

    var library = await buildLibrary(r'''
part 'a.dart';
''');

    configuration
      ..withExportScope = true
      ..withPropertyLinking = true;
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
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      accessors
        augment static get foo @37
          reference: <testLibrary>::@fragment::package:test/a.dart::@getterAugmentation::foo
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          returnType: int
          id: getter_0
          variable: <null>
  exportedReferences
  exportNamespace
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      getters
        augment get foo @37
          reference: <testLibrary>::@fragment::package:test/a.dart::@getterAugmentation::foo
          element: <none>
  getters
    static get foo
      reference: <none>
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@getterAugmentation::foo
  exportedReferences
  exportNamespace
''');
  }

  test_getter_augments_setter() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment int get foo => 0;
''');

    var library = await buildLibrary(r'''
part 'a.dart';
set foo(int _) {}
''');

    configuration
      ..withConstructors = false
      ..withExportScope = true
      ..withPropertyLinking = true;
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
      topLevelVariables
        synthetic static foo @-1
          reference: <testLibraryFragment>::@topLevelVariable::foo
          enclosingElement: <testLibraryFragment>
          type: int
          id: variable_0
          setter: setter_0
      accessors
        static set foo= @19
          reference: <testLibraryFragment>::@setter::foo
          enclosingElement: <testLibraryFragment>
          parameters
            requiredPositional _ @27
              type: int
          returnType: void
          id: setter_0
          variable: variable_0
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      accessors
        augment static get foo @37
          reference: <testLibrary>::@fragment::package:test/a.dart::@getterAugmentation::foo
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          returnType: int
          id: getter_0
          variable: <null>
          augmentationTargetAny: <testLibraryFragment>::@setter::foo
  exportedReferences
    declared <testLibraryFragment>::@setter::foo
  exportNamespace
    foo=: <testLibraryFragment>::@setter::foo
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      topLevelVariables
        synthetic foo @-1
          reference: <testLibraryFragment>::@topLevelVariable::foo
          element: <none>
          setter2: <testLibraryFragment>::@setter::foo
      setters
        set foo= @19
          reference: <testLibraryFragment>::@setter::foo
          element: <none>
          parameters
            _ @27
              element: <none>
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      getters
        augment get foo @37
          reference: <testLibrary>::@fragment::package:test/a.dart::@getterAugmentation::foo
          element: <none>
  topLevelVariables
    synthetic foo
      reference: <none>
      type: int
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo
      setter: <none>
  getters
    static get foo
      reference: <none>
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@getterAugmentation::foo
  setters
    static set foo=
      reference: <none>
      parameters
        requiredPositional _
          reference: <none>
          type: int
      firstFragment: <testLibraryFragment>::@setter::foo
  exportedReferences
    declared <testLibraryFragment>::@setter::foo
  exportNamespace
    foo=: <testLibraryFragment>::@setter::foo
''');
  }

  test_getter_augments_topVariable() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment int get foo => 0;
''');

    var library = await buildLibrary(r'''
part 'a.dart';
int foo = 0;
''');

    configuration
      ..withExportScope = true
      ..withPropertyLinking = true;
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
      topLevelVariables
        static foo @19
          reference: <testLibraryFragment>::@topLevelVariable::foo
          enclosingElement: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: true
          id: variable_0
          getter: getter_0
          setter: setter_0
      accessors
        synthetic static get foo @-1
          reference: <testLibraryFragment>::@getter::foo
          enclosingElement: <testLibraryFragment>
          returnType: int
          id: getter_0
          variable: variable_0
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@getterAugmentation::foo
        synthetic static set foo= @-1
          reference: <testLibraryFragment>::@setter::foo
          enclosingElement: <testLibraryFragment>
          parameters
            requiredPositional _foo @-1
              type: int
          returnType: void
          id: setter_0
          variable: variable_0
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      accessors
        augment static get foo @37
          reference: <testLibrary>::@fragment::package:test/a.dart::@getterAugmentation::foo
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          returnType: int
          id: getter_1
          variable: variable_0
          augmentationTarget: <testLibraryFragment>::@getter::foo
  exportedReferences
    declared <testLibraryFragment>::@getter::foo
    declared <testLibraryFragment>::@setter::foo
  exportNamespace
    foo: <testLibraryFragment>::@getter::foo
    foo=: <testLibraryFragment>::@setter::foo
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      topLevelVariables
        foo @19
          reference: <testLibraryFragment>::@topLevelVariable::foo
          element: <none>
          getter2: <testLibraryFragment>::@getter::foo
          setter2: <testLibraryFragment>::@setter::foo
      getters
        get foo @-1
          reference: <testLibraryFragment>::@getter::foo
          element: <none>
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@getterAugmentation::foo
      setters
        set foo= @-1
          reference: <testLibraryFragment>::@setter::foo
          element: <none>
          parameters
            _foo @-1
              element: <none>
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      getters
        augment get foo @37
          reference: <testLibrary>::@fragment::package:test/a.dart::@getterAugmentation::foo
          element: <none>
          previousFragment: <testLibraryFragment>::@getter::foo
  topLevelVariables
    foo
      reference: <none>
      type: int
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo
      getter: <none>
      setter: <none>
  getters
    synthetic static get foo
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::foo
  setters
    synthetic static set foo=
      reference: <none>
      parameters
        requiredPositional _foo
          reference: <none>
          type: int
      firstFragment: <testLibraryFragment>::@setter::foo
  exportedReferences
    declared <testLibraryFragment>::@getter::foo
    declared <testLibraryFragment>::@setter::foo
  exportNamespace
    foo: <testLibraryFragment>::@getter::foo
    foo=: <testLibraryFragment>::@setter::foo
''');
  }

  test_setter_augments_class() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment set foo(int _) {}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
class foo {}
''');

    configuration
      ..withExportScope = true
      ..withPropertyLinking = true;
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
        class foo @21
          reference: <testLibraryFragment>::@class::foo
          enclosingElement: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::foo::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::foo
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      accessors
        augment static set foo= @33
          reference: <testLibrary>::@fragment::package:test/a.dart::@setterAugmentation::foo
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          parameters
            requiredPositional _ @41
              type: int
          returnType: void
          id: setter_0
          variable: <null>
          augmentationTargetAny: <testLibraryFragment>::@class::foo
  exportedReferences
    declared <testLibraryFragment>::@class::foo
  exportNamespace
    foo: <testLibraryFragment>::@class::foo
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      classes
        class foo @21
          reference: <testLibraryFragment>::@class::foo
          element: <testLibraryFragment>::@class::foo
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::foo::@constructor::new
              element: <none>
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      setters
        augment set foo= @33
          reference: <testLibrary>::@fragment::package:test/a.dart::@setterAugmentation::foo
          element: <none>
          parameters
            _ @41
              element: <none>
  classes
    class foo
      reference: <testLibraryFragment>::@class::foo
      firstFragment: <testLibraryFragment>::@class::foo
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::foo::@constructor::new
  setters
    static set foo=
      reference: <none>
      parameters
        requiredPositional _
          reference: <none>
          type: int
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@setterAugmentation::foo
  exportedReferences
    declared <testLibraryFragment>::@class::foo
  exportNamespace
    foo: <testLibraryFragment>::@class::foo
''');
  }

  test_setter_augments_getter() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment set foo(int _) {}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
int get foo => 0;
''');

    configuration
      ..withExportScope = true
      ..withPropertyLinking = true;
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
      topLevelVariables
        synthetic static foo @-1
          reference: <testLibraryFragment>::@topLevelVariable::foo
          enclosingElement: <testLibraryFragment>
          type: int
          id: variable_0
          getter: getter_0
      accessors
        static get foo @23
          reference: <testLibraryFragment>::@getter::foo
          enclosingElement: <testLibraryFragment>
          returnType: int
          id: getter_0
          variable: variable_0
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      accessors
        augment static set foo= @33
          reference: <testLibrary>::@fragment::package:test/a.dart::@setterAugmentation::foo
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          parameters
            requiredPositional _ @41
              type: int
          returnType: void
          id: setter_0
          variable: <null>
          augmentationTargetAny: <testLibraryFragment>::@getter::foo
  exportedReferences
    declared <testLibraryFragment>::@getter::foo
  exportNamespace
    foo: <testLibraryFragment>::@getter::foo
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      topLevelVariables
        synthetic foo @-1
          reference: <testLibraryFragment>::@topLevelVariable::foo
          element: <none>
          getter2: <testLibraryFragment>::@getter::foo
      getters
        get foo @23
          reference: <testLibraryFragment>::@getter::foo
          element: <none>
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      setters
        augment set foo= @33
          reference: <testLibrary>::@fragment::package:test/a.dart::@setterAugmentation::foo
          element: <none>
          parameters
            _ @41
              element: <none>
  topLevelVariables
    synthetic foo
      reference: <none>
      type: int
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo
      getter: <none>
  getters
    static get foo
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::foo
  setters
    static set foo=
      reference: <none>
      parameters
        requiredPositional _
          reference: <none>
          type: int
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@setterAugmentation::foo
  exportedReferences
    declared <testLibraryFragment>::@getter::foo
  exportNamespace
    foo: <testLibraryFragment>::@getter::foo
''');
  }

  test_setter_augments_nothing() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment set foo(int _) {}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
''');

    configuration
      ..withExportScope = true
      ..withPropertyLinking = true;
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
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      accessors
        augment static set foo= @33
          reference: <testLibrary>::@fragment::package:test/a.dart::@setterAugmentation::foo
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          parameters
            requiredPositional _ @41
              type: int
          returnType: void
          id: setter_0
          variable: <null>
  exportedReferences
  exportNamespace
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      setters
        augment set foo= @33
          reference: <testLibrary>::@fragment::package:test/a.dart::@setterAugmentation::foo
          element: <none>
          parameters
            _ @41
              element: <none>
  setters
    static set foo=
      reference: <none>
      parameters
        requiredPositional _
          reference: <none>
          type: int
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@setterAugmentation::foo
  exportedReferences
  exportNamespace
''');
  }

  test_setter_augments_setter() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment set foo(int _) {}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
set foo(int _) {}
''');

    configuration
      ..withExportScope = true
      ..withPropertyLinking = true;
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
      topLevelVariables
        synthetic static foo @-1
          reference: <testLibraryFragment>::@topLevelVariable::foo
          enclosingElement: <testLibraryFragment>
          type: int
          id: variable_0
          setter: setter_0
      accessors
        static set foo= @19
          reference: <testLibraryFragment>::@setter::foo
          enclosingElement: <testLibraryFragment>
          parameters
            requiredPositional _ @27
              type: int
          returnType: void
          id: setter_0
          variable: variable_0
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@setterAugmentation::foo
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      accessors
        augment static set foo= @33
          reference: <testLibrary>::@fragment::package:test/a.dart::@setterAugmentation::foo
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          parameters
            requiredPositional _ @41
              type: int
          returnType: void
          id: setter_1
          variable: variable_0
          augmentationTarget: <testLibraryFragment>::@setter::foo
  exportedReferences
    declared <testLibraryFragment>::@setter::foo
  exportNamespace
    foo=: <testLibraryFragment>::@setter::foo
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      topLevelVariables
        synthetic foo @-1
          reference: <testLibraryFragment>::@topLevelVariable::foo
          element: <none>
          setter2: <testLibraryFragment>::@setter::foo
      setters
        set foo= @19
          reference: <testLibraryFragment>::@setter::foo
          element: <none>
          parameters
            _ @27
              element: <none>
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@setterAugmentation::foo
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      setters
        augment set foo= @33
          reference: <testLibrary>::@fragment::package:test/a.dart::@setterAugmentation::foo
          element: <none>
          parameters
            _ @41
              element: <none>
          previousFragment: <testLibraryFragment>::@setter::foo
  topLevelVariables
    synthetic foo
      reference: <none>
      type: int
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo
      setter: <none>
  setters
    static set foo=
      reference: <none>
      parameters
        requiredPositional _
          reference: <none>
          type: int
      firstFragment: <testLibraryFragment>::@setter::foo
  exportedReferences
    declared <testLibraryFragment>::@setter::foo
  exportNamespace
    foo=: <testLibraryFragment>::@setter::foo
''');
  }

  test_setter_augments_topVariable() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment set foo(int _) {}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
int foo = 0;
''');

    configuration
      ..withExportScope = true
      ..withPropertyLinking = true;
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
      topLevelVariables
        static foo @19
          reference: <testLibraryFragment>::@topLevelVariable::foo
          enclosingElement: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: true
          id: variable_0
          getter: getter_0
          setter: setter_0
      accessors
        synthetic static get foo @-1
          reference: <testLibraryFragment>::@getter::foo
          enclosingElement: <testLibraryFragment>
          returnType: int
          id: getter_0
          variable: variable_0
        synthetic static set foo= @-1
          reference: <testLibraryFragment>::@setter::foo
          enclosingElement: <testLibraryFragment>
          parameters
            requiredPositional _foo @-1
              type: int
          returnType: void
          id: setter_0
          variable: variable_0
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@setterAugmentation::foo
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      accessors
        augment static set foo= @33
          reference: <testLibrary>::@fragment::package:test/a.dart::@setterAugmentation::foo
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          parameters
            requiredPositional _ @41
              type: int
          returnType: void
          id: setter_1
          variable: variable_0
          augmentationTarget: <testLibraryFragment>::@setter::foo
  exportedReferences
    declared <testLibraryFragment>::@getter::foo
    declared <testLibraryFragment>::@setter::foo
  exportNamespace
    foo: <testLibraryFragment>::@getter::foo
    foo=: <testLibraryFragment>::@setter::foo
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      topLevelVariables
        foo @19
          reference: <testLibraryFragment>::@topLevelVariable::foo
          element: <none>
          getter2: <testLibraryFragment>::@getter::foo
          setter2: <testLibraryFragment>::@setter::foo
      getters
        get foo @-1
          reference: <testLibraryFragment>::@getter::foo
          element: <none>
      setters
        set foo= @-1
          reference: <testLibraryFragment>::@setter::foo
          element: <none>
          parameters
            _foo @-1
              element: <none>
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@setterAugmentation::foo
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      setters
        augment set foo= @33
          reference: <testLibrary>::@fragment::package:test/a.dart::@setterAugmentation::foo
          element: <none>
          parameters
            _ @41
              element: <none>
          previousFragment: <testLibraryFragment>::@setter::foo
  topLevelVariables
    foo
      reference: <none>
      type: int
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo
      getter: <none>
      setter: <none>
  getters
    synthetic static get foo
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::foo
  setters
    synthetic static set foo=
      reference: <none>
      parameters
        requiredPositional _foo
          reference: <none>
          type: int
      firstFragment: <testLibraryFragment>::@setter::foo
  exportedReferences
    declared <testLibraryFragment>::@getter::foo
    declared <testLibraryFragment>::@setter::foo
  exportNamespace
    foo: <testLibraryFragment>::@getter::foo
    foo=: <testLibraryFragment>::@setter::foo
''');
  }
}

@reflectiveTest
class TopLevelFunctionElementTest_augmentation_fromBytes
    extends TopLevelFunctionElementTest_augmentation {
  @override
  bool get keepLinkingLibraries => false;
}

@reflectiveTest
class TopLevelFunctionElementTest_augmentation_keepLinking
    extends TopLevelFunctionElementTest_augmentation {
  @override
  bool get keepLinkingLibraries => true;
}

@reflectiveTest
class TopLevelFunctionElementTest_fromBytes
    extends TopLevelFunctionElementTest {
  @override
  bool get keepLinkingLibraries => false;
}

@reflectiveTest
class TopLevelFunctionElementTest_keepLinking
    extends TopLevelFunctionElementTest {
  @override
  bool get keepLinkingLibraries => true;
}
