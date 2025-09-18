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
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        dart:async
      functions
        #F1 f (nameOffset:28) (firstTokenOffset:21) (offset:28)
          element: <testLibrary>::@function::f
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: #F1
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
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        dart:async
      functions
        #F1 f (nameOffset:28) (firstTokenOffset:21) (offset:28)
          element: <testLibrary>::@function::f
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: #F1
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
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      functions
        #F1 f (nameOffset:60) (firstTokenOffset:44) (offset:60)
          element: <testLibrary>::@function::f
          documentationComment: /**\n * Docs\n */
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: #F1
      documentationComment: /**\n * Docs\n */
      returnType: dynamic
''');
  }

  test_function_entry_point() async {
    var library = await buildLibrary('main() {}');
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

  test_function_entry_point_in_export() async {
    newFile('$testPackageLibPath/a.dart', 'library a; main() {}');
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

  test_function_entry_point_in_export_hidden() async {
    newFile('$testPackageLibPath/a.dart', 'library a; main() {}');
    var library = await buildLibrary('export "a.dart" hide main;');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryExports
        package:test/a.dart
          combinators
            hide: main
''');
  }

  test_function_entry_point_in_part() async {
    newFile('$testPackageLibPath/a.dart', 'part of my.lib; main() {}');
    var library = await buildLibrary('library my.lib; part "a.dart";');
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
    #F1 package:test/a.dart
      element: <testLibrary>
      enclosingFragment: #F0
      previousFragment: #F0
      functions
        #F2 main (nameOffset:16) (firstTokenOffset:16) (offset:16)
          element: <testLibrary>::@function::main
  functions
    main
      reference: <testLibrary>::@function::main
      firstFragment: #F2
      returnType: dynamic
''');
  }

  test_function_external() async {
    var library = await buildLibrary('external f();');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      functions
        #F1 f (nameOffset:9) (firstTokenOffset:0) (offset:9)
          element: <testLibrary>::@function::f
  functions
    external f
      reference: <testLibrary>::@function::f
      firstFragment: #F1
      returnType: dynamic
''');
  }

  test_function_hasImplicitReturnType_false() async {
    var library = await buildLibrary('''
int f() => 0;
''');
    var f = library.firstFragment.functions.single;
    expect(f.hasImplicitReturnType, isFalse);
  }

  test_function_hasImplicitReturnType_true() async {
    var library = await buildLibrary('''
f() => 0;
''');
    var f = library.firstFragment.functions.single;
    expect(f.hasImplicitReturnType, isTrue);
  }

  test_function_missingName() async {
    var library = await buildLibrary('''
() {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
''');
  }

  test_function_parameter_const() async {
    var library = await buildLibrary('''
void f(const x) {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      functions
        #F1 f (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@function::f
          formalParameters
            #F2 x (nameOffset:13) (firstTokenOffset:7) (offset:13)
              element: <testLibrary>::@function::f::@formalParameter::x
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: #F1
      formalParameters
        #E0 requiredPositional hasImplicitType x
          firstFragment: #F2
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
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      functions
        #F1 f (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@function::f
          formalParameters
            #F2 this.a (nameOffset:16) (firstTokenOffset:7) (offset:16)
              element: <testLibrary>::@function::f::@formalParameter::a
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: #F1
      formalParameters
        #E0 requiredPositional final a
          firstFragment: #F2
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
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      functions
        #F1 f (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@function::f
          formalParameters
            #F2 this.a (nameOffset:17) (firstTokenOffset:8) (offset:17)
              element: <testLibrary>::@function::f::@formalParameter::a
              initializer: expression_0
                IntegerLiteral
                  literal: 42 @20
                  staticType: int
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: #F1
      formalParameters
        #E0 optionalNamed final a
          firstFragment: #F2
          type: int
          constantInitializer
            fragment: #F2
            expression: expression_0
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
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      functions
        #F1 f (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@function::f
          formalParameters
            #F2 this.a (nameOffset:16) (firstTokenOffset:7) (offset:16)
              element: <testLibrary>::@function::f::@formalParameter::a
              parameters
                #F3 b (nameOffset:22) (firstTokenOffset:18) (offset:22)
                  element: b@22
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: #F1
      formalParameters
        #E0 requiredPositional final a
          firstFragment: #F2
          type: int Function(int)
          formalParameters
            #E1 requiredPositional b
              firstFragment: #F3
              type: int
      returnType: void
''');
  }

  test_function_parameter_final() async {
    var library = await buildLibrary('f(final x) {}');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      functions
        #F1 f (nameOffset:0) (firstTokenOffset:0) (offset:0)
          element: <testLibrary>::@function::f
          formalParameters
            #F2 x (nameOffset:8) (firstTokenOffset:2) (offset:8)
              element: <testLibrary>::@function::f::@formalParameter::x
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: #F1
      formalParameters
        #E0 requiredPositional final hasImplicitType x
          firstFragment: #F2
          type: dynamic
      returnType: dynamic
''');
  }

  test_function_parameter_kind_named() async {
    var library = await buildLibrary('f({x}) {}');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      functions
        #F1 f (nameOffset:0) (firstTokenOffset:0) (offset:0)
          element: <testLibrary>::@function::f
          formalParameters
            #F2 x (nameOffset:3) (firstTokenOffset:3) (offset:3)
              element: <testLibrary>::@function::f::@formalParameter::x
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: #F1
      formalParameters
        #E0 optionalNamed hasImplicitType x
          firstFragment: #F2
          type: dynamic
      returnType: dynamic
''');
  }

  test_function_parameter_kind_positional() async {
    var library = await buildLibrary('f([x]) {}');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      functions
        #F1 f (nameOffset:0) (firstTokenOffset:0) (offset:0)
          element: <testLibrary>::@function::f
          formalParameters
            #F2 x (nameOffset:3) (firstTokenOffset:3) (offset:3)
              element: <testLibrary>::@function::f::@formalParameter::x
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: #F1
      formalParameters
        #E0 optionalPositional hasImplicitType x
          firstFragment: #F2
          type: dynamic
      returnType: dynamic
''');
  }

  test_function_parameter_kind_required() async {
    var library = await buildLibrary('f(x) {}');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      functions
        #F1 f (nameOffset:0) (firstTokenOffset:0) (offset:0)
          element: <testLibrary>::@function::f
          formalParameters
            #F2 x (nameOffset:2) (firstTokenOffset:2) (offset:2)
              element: <testLibrary>::@function::f::@formalParameter::x
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: #F1
      formalParameters
        #E0 requiredPositional hasImplicitType x
          firstFragment: #F2
          type: dynamic
      returnType: dynamic
''');
  }

  test_function_parameter_parameters() async {
    var library = await buildLibrary('f(g(x, y)) {}');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      functions
        #F1 f (nameOffset:0) (firstTokenOffset:0) (offset:0)
          element: <testLibrary>::@function::f
          formalParameters
            #F2 g (nameOffset:2) (firstTokenOffset:2) (offset:2)
              element: <testLibrary>::@function::f::@formalParameter::g
              parameters
                #F3 x (nameOffset:4) (firstTokenOffset:4) (offset:4)
                  element: x@4
                #F4 y (nameOffset:7) (firstTokenOffset:7) (offset:7)
                  element: y@7
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: #F1
      formalParameters
        #E0 requiredPositional g
          firstFragment: #F2
          type: dynamic Function(dynamic, dynamic)
          formalParameters
            #E1 requiredPositional hasImplicitType x
              firstFragment: #F3
              type: dynamic
            #E2 requiredPositional hasImplicitType y
              firstFragment: #F4
              type: dynamic
      returnType: dynamic
''');
  }

  test_function_parameter_return_type() async {
    var library = await buildLibrary('f(int g()) {}');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      functions
        #F1 f (nameOffset:0) (firstTokenOffset:0) (offset:0)
          element: <testLibrary>::@function::f
          formalParameters
            #F2 g (nameOffset:6) (firstTokenOffset:2) (offset:6)
              element: <testLibrary>::@function::f::@formalParameter::g
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: #F1
      formalParameters
        #E0 requiredPositional g
          firstFragment: #F2
          type: int Function()
      returnType: dynamic
''');
  }

  test_function_parameter_return_type_void() async {
    var library = await buildLibrary('f(void g()) {}');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      functions
        #F1 f (nameOffset:0) (firstTokenOffset:0) (offset:0)
          element: <testLibrary>::@function::f
          formalParameters
            #F2 g (nameOffset:7) (firstTokenOffset:2) (offset:7)
              element: <testLibrary>::@function::f::@formalParameter::g
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: #F1
      formalParameters
        #E0 requiredPositional g
          firstFragment: #F2
          type: void Function()
      returnType: dynamic
''');
  }

  test_function_parameter_type() async {
    var library = await buildLibrary('f(int i) {}');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      functions
        #F1 f (nameOffset:0) (firstTokenOffset:0) (offset:0)
          element: <testLibrary>::@function::f
          formalParameters
            #F2 i (nameOffset:6) (firstTokenOffset:2) (offset:6)
              element: <testLibrary>::@function::f::@formalParameter::i
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: #F1
      formalParameters
        #E0 requiredPositional i
          firstFragment: #F2
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
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      functions
        #F1 f (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@function::f
          typeParameters
            #F2 T (nameOffset:7) (firstTokenOffset:7) (offset:7)
              element: #E0 T
          formalParameters
            #F3 a (nameOffset:12) (firstTokenOffset:10) (offset:12)
              element: <testLibrary>::@function::f::@formalParameter::a
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      formalParameters
        #E1 requiredPositional a
          firstFragment: #F3
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
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      functions
        #F1 f (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@function::f
          formalParameters
            #F2 a (nameOffset:9) (firstTokenOffset:7) (offset:9)
              element: <testLibrary>::@function::f::@formalParameter::a
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: #F1
      formalParameters
        #E0 requiredPositional a
          firstFragment: #F2
          type: InvalidType
      returnType: void
''');
  }

  test_function_parameters() async {
    var library = await buildLibrary('f(x, y) {}');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      functions
        #F1 f (nameOffset:0) (firstTokenOffset:0) (offset:0)
          element: <testLibrary>::@function::f
          formalParameters
            #F2 x (nameOffset:2) (firstTokenOffset:2) (offset:2)
              element: <testLibrary>::@function::f::@formalParameter::x
            #F3 y (nameOffset:5) (firstTokenOffset:5) (offset:5)
              element: <testLibrary>::@function::f::@formalParameter::y
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: #F1
      formalParameters
        #E0 requiredPositional hasImplicitType x
          firstFragment: #F2
          type: dynamic
        #E1 requiredPositional hasImplicitType y
          firstFragment: #F3
          type: dynamic
      returnType: dynamic
''');
  }

  test_function_return_type_implicit() async {
    var library = await buildLibrary('f() => null;');
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

  test_function_return_type_unresolved() async {
    var library = await buildLibrary(r'''
A f() {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      functions
        #F1 f (nameOffset:2) (firstTokenOffset:0) (offset:2)
          element: <testLibrary>::@function::f
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: #F1
      returnType: InvalidType
''');
  }

  test_function_return_type_void() async {
    var library = await buildLibrary('void f() {}');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      functions
        #F1 f (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@function::f
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: #F1
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
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      functions
        #F1 f (nameOffset:4) (firstTokenOffset:0) (offset:4)
          element: <testLibrary>::@function::f
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: #F1
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
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      functions
        #F1 f (nameOffset:2) (firstTokenOffset:0) (offset:2)
          element: <testLibrary>::@function::f
          typeParameters
            #F2 T (nameOffset:4) (firstTokenOffset:4) (offset:4)
              element: #E0 T
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      returnType: T
''');
  }

  test_function_type_parameter_with_function_typed_parameter() async {
    var library = await buildLibrary('void f<T, U>(T x(U u)) {}');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      functions
        #F1 f (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@function::f
          typeParameters
            #F2 T (nameOffset:7) (firstTokenOffset:7) (offset:7)
              element: #E0 T
            #F3 U (nameOffset:10) (firstTokenOffset:10) (offset:10)
              element: #E1 U
          formalParameters
            #F4 x (nameOffset:15) (firstTokenOffset:13) (offset:15)
              element: <testLibrary>::@function::f::@formalParameter::x
              parameters
                #F5 u (nameOffset:19) (firstTokenOffset:17) (offset:19)
                  element: u@19
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
        #E1 U
          firstFragment: #F3
      formalParameters
        #E2 requiredPositional x
          firstFragment: #F4
          type: T Function(U)
          formalParameters
            #E3 requiredPositional u
              firstFragment: #F5
              type: U
      returnType: void
''');
  }

  test_function_typed_parameter_implicit() async {
    var library = await buildLibrary('f(g()) => null;');
    expect(
      library.topLevelFunctions.first.formalParameters.first.hasImplicitType,
      isFalse,
    );
  }

  test_function_typeParameters_hasBound() async {
    var library = await buildLibrary('''
void f<T extends num>() {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      functions
        #F1 f (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@function::f
          typeParameters
            #F2 T (nameOffset:7) (firstTokenOffset:7) (offset:7)
              element: #E0 T
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
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
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      functions
        #F1 f (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@function::f
          typeParameters
            #F2 T (nameOffset:7) (firstTokenOffset:7) (offset:7)
              element: #E0 T
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      returnType: void
''');
  }

  test_functions() async {
    var library = await buildLibrary('f() {} g() {}');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      functions
        #F1 f (nameOffset:0) (firstTokenOffset:0) (offset:0)
          element: <testLibrary>::@function::f
        #F2 g (nameOffset:7) (firstTokenOffset:7) (offset:7)
          element: <testLibrary>::@function::g
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: #F1
      returnType: dynamic
    g
      reference: <testLibrary>::@function::g
      firstFragment: #F2
      returnType: dynamic
''');
  }

  test_getter_missingName() async {
    var library = await buildLibrary('''
get () => 0;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      functions
        #F1 get (nameOffset:0) (firstTokenOffset:0) (offset:0)
          element: <testLibrary>::@function::get
  functions
    get
      reference: <testLibrary>::@function::get
      firstFragment: #F1
      returnType: dynamic
''');
  }

  test_main_class() async {
    var library = await buildLibrary('class main {}');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class main (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::main
          constructors
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::main::@constructor::new
              typeName: main
  classes
    class main
      reference: <testLibrary>::@class::main
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::main::@constructor::new
          firstFragment: #F2
''');
  }

  test_main_class_alias() async {
    var library = await buildLibrary(
      'class main = C with D; class C {} class D {}',
    );
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class main (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::main
          constructors
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::main::@constructor::new
              typeName: main
        #F3 class C (nameOffset:29) (firstTokenOffset:23) (offset:29)
          element: <testLibrary>::@class::C
          constructors
            #F4 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:29)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
        #F5 class D (nameOffset:40) (firstTokenOffset:34) (offset:40)
          element: <testLibrary>::@class::D
          constructors
            #F6 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
              element: <testLibrary>::@class::D::@constructor::new
              typeName: D
  classes
    class alias main
      reference: <testLibrary>::@class::main
      firstFragment: #F1
      supertype: C
      mixins
        D
      constructors
        synthetic new
          reference: <testLibrary>::@class::main::@constructor::new
          firstFragment: #F2
          constantInitializers
            SuperConstructorInvocation
              superKeyword: super @0
              argumentList: ArgumentList
                leftParenthesis: ( @0
                rightParenthesis: ) @0
              element: <testLibrary>::@class::C::@constructor::new
          superConstructor: <testLibrary>::@class::C::@constructor::new
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F3
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F4
    class D
      reference: <testLibrary>::@class::D
      firstFragment: #F5
      constructors
        synthetic new
          reference: <testLibrary>::@class::D::@constructor::new
          firstFragment: #F6
''');
  }

  test_main_class_alias_via_export() async {
    newFile(
      '$testPackageLibPath/a.dart',
      'class main = C with D; class C {} class D {}',
    );
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

  test_main_class_via_export() async {
    newFile('$testPackageLibPath/a.dart', 'class main {}');
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

  test_main_getter() async {
    var library = await buildLibrary('get main => null;');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 synthetic main (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@topLevelVariable::main
      getters
        #F2 main (nameOffset:4) (firstTokenOffset:0) (offset:4)
          element: <testLibrary>::@getter::main
  topLevelVariables
    synthetic main
      reference: <testLibrary>::@topLevelVariable::main
      firstFragment: #F1
      type: dynamic
      getter: <testLibrary>::@getter::main
  getters
    static main
      reference: <testLibrary>::@getter::main
      firstFragment: #F2
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::main
''');
  }

  test_main_getter_via_export() async {
    newFile('$testPackageLibPath/a.dart', 'get main => null;');
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

  test_main_typedef() async {
    var library = await buildLibrary('typedef main();');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        #F1 main (nameOffset:8) (firstTokenOffset:0) (offset:8)
          element: <testLibrary>::@typeAlias::main
  typeAliases
    main
      reference: <testLibrary>::@typeAlias::main
      firstFragment: #F1
      aliasedType: dynamic Function()
''');
  }

  test_main_typedef_via_export() async {
    newFile('$testPackageLibPath/a.dart', 'typedef main();');
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

  test_main_variable() async {
    var library = await buildLibrary('var main;');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 main (nameOffset:4) (firstTokenOffset:4) (offset:4)
          element: <testLibrary>::@topLevelVariable::main
      getters
        #F2 synthetic main (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@getter::main
      setters
        #F3 synthetic main (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@setter::main
          formalParameters
            #F4 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
              element: <testLibrary>::@setter::main::@formalParameter::value
  topLevelVariables
    main
      reference: <testLibrary>::@topLevelVariable::main
      firstFragment: #F1
      type: dynamic
      getter: <testLibrary>::@getter::main
      setter: <testLibrary>::@setter::main
  getters
    synthetic static main
      reference: <testLibrary>::@getter::main
      firstFragment: #F2
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::main
  setters
    synthetic static main
      reference: <testLibrary>::@setter::main
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F4
          type: dynamic
      returnType: void
      variable: <testLibrary>::@topLevelVariable::main
''');
  }

  test_main_variable_via_export() async {
    newFile('$testPackageLibPath/a.dart', 'var main;');
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

  test_setter_missingName() async {
    var library = await buildLibrary('''
set (int _) {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      functions
        #F1 set (nameOffset:0) (firstTokenOffset:0) (offset:0)
          element: <testLibrary>::@function::set
          formalParameters
            #F2 _ (nameOffset:9) (firstTokenOffset:5) (offset:9)
              element: <testLibrary>::@function::set::@formalParameter::_
  functions
    set
      reference: <testLibrary>::@function::set
      firstFragment: #F1
      formalParameters
        #E0 requiredPositional _
          firstFragment: #F2
          type: int
      returnType: dynamic
''');
  }
}

abstract class TopLevelFunctionElementTest_augmentation
    extends ElementsBaseTest {
  test_augment_function() async {
    var library = await buildLibrary(r'''
void foo() {}
augment void foo() {}
''');

    configuration.withExportScope = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      functions
        #F1 foo (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@function::foo
          nextFragment: #F2
        #F2 foo (nameOffset:27) (firstTokenOffset:14) (offset:27)
          element: <testLibrary>::@function::foo
          previousFragment: #F1
  functions
    foo
      reference: <testLibrary>::@function::foo
      firstFragment: #F1
      returnType: void
  exportedReferences
    declared <testLibrary>::@function::foo
  exportNamespace
    foo: <testLibrary>::@function::foo
''');
  }

  test_augment_getter() async {
    var library = await buildLibrary(r'''
int get foo => 0;
augment void foo() {}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:8)
          element: <testLibrary>::@topLevelVariable::foo
      getters
        #F2 foo (nameOffset:8) (firstTokenOffset:0) (offset:8)
          element: <testLibrary>::@getter::foo
      functions
        #F3 foo (nameOffset:31) (firstTokenOffset:18) (offset:31)
          element: <testLibrary>::@function::foo
  topLevelVariables
    synthetic foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::foo
  getters
    static foo
      reference: <testLibrary>::@getter::foo
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::foo
  functions
    foo
      reference: <testLibrary>::@function::foo
      firstFragment: #F3
      returnType: void
''');
  }

  test_augment_setter() async {
    var library = await buildLibrary(r'''
set foo(int _) {}
augment void foo() {}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@topLevelVariable::foo
      setters
        #F2 foo (nameOffset:4) (firstTokenOffset:0) (offset:4)
          element: <testLibrary>::@setter::foo
          formalParameters
            #F3 _ (nameOffset:12) (firstTokenOffset:8) (offset:12)
              element: <testLibrary>::@setter::foo::@formalParameter::_
      functions
        #F4 foo (nameOffset:31) (firstTokenOffset:18) (offset:31)
          element: <testLibrary>::@function::foo
  topLevelVariables
    synthetic foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: #F1
      type: int
      setter: <testLibrary>::@setter::foo
  setters
    static foo
      reference: <testLibrary>::@setter::foo
      firstFragment: #F2
      formalParameters
        #E0 requiredPositional _
          firstFragment: #F3
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::foo
  functions
    foo
      reference: <testLibrary>::@function::foo
      firstFragment: #F4
      returnType: void
''');
  }

  test_augment_variable() async {
    var library = await buildLibrary(r'''
int foo = 0;
augment void foo() {}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer foo (nameOffset:4) (firstTokenOffset:4) (offset:4)
          element: <testLibrary>::@topLevelVariable::foo
      getters
        #F2 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@getter::foo
      setters
        #F3 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@setter::foo
          formalParameters
            #F4 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
              element: <testLibrary>::@setter::foo::@formalParameter::value
      functions
        #F5 foo (nameOffset:26) (firstTokenOffset:13) (offset:26)
          element: <testLibrary>::@function::foo
  topLevelVariables
    hasInitializer foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::foo
      setter: <testLibrary>::@setter::foo
  getters
    synthetic static foo
      reference: <testLibrary>::@getter::foo
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::foo
  setters
    synthetic static foo
      reference: <testLibrary>::@setter::foo
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F4
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::foo
  functions
    foo
      reference: <testLibrary>::@function::foo
      firstFragment: #F5
      returnType: void
''');
  }

  test_augmentationTarget() async {
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
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      nextFragment: #F1
      parts
        part_0
          uri: package:test/a1.dart
          partKeywordOffset: 0
          unit: #F1
        part_1
          uri: package:test/a2.dart
          partKeywordOffset: 16
          unit: #F2
      functions
        #F3 foo (nameOffset:37) (firstTokenOffset:32) (offset:37)
          element: <testLibrary>::@function::foo
          nextFragment: #F4
    #F1 package:test/a1.dart
      element: <testLibrary>
      enclosingFragment: #F0
      previousFragment: #F0
      nextFragment: #F5
      parts
        part_2
          uri: package:test/a11.dart
          partKeywordOffset: 21
          unit: #F5
        part_3
          uri: package:test/a12.dart
          partKeywordOffset: 38
          unit: #F6
      functions
        #F4 foo (nameOffset:68) (firstTokenOffset:55) (offset:68)
          element: <testLibrary>::@function::foo
          previousFragment: #F3
          nextFragment: #F7
    #F5 package:test/a11.dart
      element: <testLibrary>
      enclosingFragment: #F1
      previousFragment: #F1
      nextFragment: #F6
      functions
        #F7 foo (nameOffset:32) (firstTokenOffset:19) (offset:32)
          element: <testLibrary>::@function::foo
          previousFragment: #F4
          nextFragment: #F8
    #F6 package:test/a12.dart
      element: <testLibrary>
      enclosingFragment: #F1
      previousFragment: #F5
      nextFragment: #F2
      functions
        #F8 foo (nameOffset:32) (firstTokenOffset:19) (offset:32)
          element: <testLibrary>::@function::foo
          previousFragment: #F7
          nextFragment: #F9
    #F2 package:test/a2.dart
      element: <testLibrary>
      enclosingFragment: #F0
      previousFragment: #F6
      nextFragment: #F10
      parts
        part_4
          uri: package:test/a21.dart
          partKeywordOffset: 21
          unit: #F10
        part_5
          uri: package:test/a22.dart
          partKeywordOffset: 38
          unit: #F11
      functions
        #F9 foo (nameOffset:68) (firstTokenOffset:55) (offset:68)
          element: <testLibrary>::@function::foo
          previousFragment: #F8
          nextFragment: #F12
    #F10 package:test/a21.dart
      element: <testLibrary>
      enclosingFragment: #F2
      previousFragment: #F2
      nextFragment: #F11
      functions
        #F12 foo (nameOffset:32) (firstTokenOffset:19) (offset:32)
          element: <testLibrary>::@function::foo
          previousFragment: #F9
          nextFragment: #F13
    #F11 package:test/a22.dart
      element: <testLibrary>
      enclosingFragment: #F2
      previousFragment: #F10
      functions
        #F13 foo (nameOffset:32) (firstTokenOffset:19) (offset:32)
          element: <testLibrary>::@function::foo
          previousFragment: #F12
  functions
    foo
      reference: <testLibrary>::@function::foo
      firstFragment: #F3
      returnType: void
''');
  }

  test_augments_class() async {
    var library = await buildLibrary(r'''
class foo {}
augment void foo() {}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class foo (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::foo
          constructors
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::foo::@constructor::new
              typeName: foo
      functions
        #F3 foo (nameOffset:26) (firstTokenOffset:13) (offset:26)
          element: <testLibrary>::@function::foo
  classes
    class foo
      reference: <testLibrary>::@class::foo
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::foo::@constructor::new
          firstFragment: #F2
  functions
    foo
      reference: <testLibrary>::@function::foo
      firstFragment: #F3
      returnType: void
''');
  }

  test_formalParameters_optionalPositional_11() async {
    var library = await buildLibrary(r'''
void foo([int p1]) {}
augment void foo([int p1]) {}
''');

    configuration.withExportScope = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      functions
        #F1 foo (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@function::foo
          nextFragment: #F2
          formalParameters
            #F3 p1 (nameOffset:14) (firstTokenOffset:10) (offset:14)
              element: <testLibrary>::@function::foo::@formalParameter::p1
              nextFragment: #F4
        #F2 foo (nameOffset:35) (firstTokenOffset:22) (offset:35)
          element: <testLibrary>::@function::foo
          previousFragment: #F1
          formalParameters
            #F4 p1 (nameOffset:44) (firstTokenOffset:40) (offset:44)
              element: <testLibrary>::@function::foo::@formalParameter::p1
              previousFragment: #F3
  functions
    foo
      reference: <testLibrary>::@function::foo
      firstFragment: #F1
      formalParameters
        #E0 optionalPositional p1
          firstFragment: #F3
          type: int
      returnType: void
  exportedReferences
    declared <testLibrary>::@function::foo
  exportNamespace
    foo: <testLibrary>::@function::foo
''');
  }

  test_formalParameters_optionalPositional_12() async {
    var library = await buildLibrary(r'''
void foo([int p1]) {}
augment void foo([int p1, int p2]) {}
''');

    configuration.withExportScope = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      functions
        #F1 foo (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@function::foo
          nextFragment: #F2
          formalParameters
            #F3 p1 (nameOffset:14) (firstTokenOffset:10) (offset:14)
              element: <testLibrary>::@function::foo::@formalParameter::p1
              nextFragment: #F4
        #F2 foo (nameOffset:35) (firstTokenOffset:22) (offset:35)
          element: <testLibrary>::@function::foo
          previousFragment: #F1
          formalParameters
            #F4 p1 (nameOffset:44) (firstTokenOffset:40) (offset:44)
              element: <testLibrary>::@function::foo::@formalParameter::p1
              previousFragment: #F3
  functions
    foo
      reference: <testLibrary>::@function::foo
      firstFragment: #F1
      formalParameters
        #E0 optionalPositional p1
          firstFragment: #F3
          type: int
      returnType: void
  exportedReferences
    declared <testLibrary>::@function::foo
  exportNamespace
    foo: <testLibrary>::@function::foo
''');
  }

  test_formalParameters_optionalPositional_21() async {
    var library = await buildLibrary(r'''
void foo([int p1, int p2]) {}
augment void foo([int p1]) {}
''');

    configuration.withExportScope = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      functions
        #F1 foo (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@function::foo
          nextFragment: #F2
          formalParameters
            #F3 p1 (nameOffset:14) (firstTokenOffset:10) (offset:14)
              element: <testLibrary>::@function::foo::@formalParameter::p1
              nextFragment: #F4
            #F5 p2 (nameOffset:22) (firstTokenOffset:18) (offset:22)
              element: <testLibrary>::@function::foo::@formalParameter::p2
              nextFragment: #F6
        #F2 foo (nameOffset:43) (firstTokenOffset:30) (offset:43)
          element: <testLibrary>::@function::foo
          previousFragment: #F1
          formalParameters
            #F4 p1 (nameOffset:52) (firstTokenOffset:48) (offset:52)
              element: <testLibrary>::@function::foo::@formalParameter::p1
              previousFragment: #F3
            #F6 p2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:43)
              element: <testLibrary>::@function::foo::@formalParameter::p2
              previousFragment: #F5
  functions
    foo
      reference: <testLibrary>::@function::foo
      firstFragment: #F1
      formalParameters
        #E0 optionalPositional p1
          firstFragment: #F3
          type: int
        #E1 optionalPositional p2
          firstFragment: #F5
          type: int
      returnType: void
  exportedReferences
    declared <testLibrary>::@function::foo
  exportNamespace
    foo: <testLibrary>::@function::foo
''');
  }

  test_formalParameters_optionalPositional_differentType() async {
    var library = await buildLibrary(r'''
void foo([int p1]) {}
augment void foo([double p1]) {}
''');

    configuration.withExportScope = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      functions
        #F1 foo (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@function::foo
          nextFragment: #F2
          formalParameters
            #F3 p1 (nameOffset:14) (firstTokenOffset:10) (offset:14)
              element: <testLibrary>::@function::foo::@formalParameter::p1
              nextFragment: #F4
        #F2 foo (nameOffset:35) (firstTokenOffset:22) (offset:35)
          element: <testLibrary>::@function::foo
          previousFragment: #F1
          formalParameters
            #F4 p1 (nameOffset:47) (firstTokenOffset:40) (offset:47)
              element: <testLibrary>::@function::foo::@formalParameter::p1
              previousFragment: #F3
  functions
    foo
      reference: <testLibrary>::@function::foo
      firstFragment: #F1
      formalParameters
        #E0 optionalPositional p1
          firstFragment: #F3
          type: int
      returnType: void
  exportedReferences
    declared <testLibrary>::@function::foo
  exportNamespace
    foo: <testLibrary>::@function::foo
''');
  }

  test_formalParameters_optionalPositional_swapped() async {
    var library = await buildLibrary(r'''
void foo([int p2, int p1]) {}
augment void foo([int p1, int p2]) {}
''');

    configuration.withExportScope = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      functions
        #F1 foo (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@function::foo
          nextFragment: #F2
          formalParameters
            #F3 p2 (nameOffset:14) (firstTokenOffset:10) (offset:14)
              element: <testLibrary>::@function::foo::@formalParameter::p2
              nextFragment: #F4
            #F5 p1 (nameOffset:22) (firstTokenOffset:18) (offset:22)
              element: <testLibrary>::@function::foo::@formalParameter::p1
              nextFragment: #F6
        #F2 foo (nameOffset:43) (firstTokenOffset:30) (offset:43)
          element: <testLibrary>::@function::foo
          previousFragment: #F1
          formalParameters
            #F4 p1 (nameOffset:52) (firstTokenOffset:48) (offset:52)
              element: <testLibrary>::@function::foo::@formalParameter::p2
              previousFragment: #F3
            #F6 p2 (nameOffset:60) (firstTokenOffset:56) (offset:60)
              element: <testLibrary>::@function::foo::@formalParameter::p1
              previousFragment: #F5
  functions
    foo
      reference: <testLibrary>::@function::foo
      firstFragment: #F1
      formalParameters
        #E0 optionalPositional p2
          firstFragment: #F3
          type: int
        #E1 optionalPositional p1
          firstFragment: #F5
          type: int
      returnType: void
  exportedReferences
    declared <testLibrary>::@function::foo
  exportNamespace
    foo: <testLibrary>::@function::foo
''');
  }

  test_formalParameters_positional_11() async {
    var library = await buildLibrary(r'''
void foo(int n1) {}
augment void foo(int n1) {}
''');

    configuration.withExportScope = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      functions
        #F1 foo (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@function::foo
          nextFragment: #F2
          formalParameters
            #F3 n1 (nameOffset:13) (firstTokenOffset:9) (offset:13)
              element: <testLibrary>::@function::foo::@formalParameter::n1
              nextFragment: #F4
        #F2 foo (nameOffset:33) (firstTokenOffset:20) (offset:33)
          element: <testLibrary>::@function::foo
          previousFragment: #F1
          formalParameters
            #F4 n1 (nameOffset:41) (firstTokenOffset:37) (offset:41)
              element: <testLibrary>::@function::foo::@formalParameter::n1
              previousFragment: #F3
  functions
    foo
      reference: <testLibrary>::@function::foo
      firstFragment: #F1
      formalParameters
        #E0 requiredPositional n1
          firstFragment: #F3
          type: int
      returnType: void
  exportedReferences
    declared <testLibrary>::@function::foo
  exportNamespace
    foo: <testLibrary>::@function::foo
''');
  }

  test_formalParameters_positional_12() async {
    var library = await buildLibrary(r'''
void foo(int n1) {}
augment void foo(int n1, int n2) {}
''');

    configuration.withExportScope = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      functions
        #F1 foo (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@function::foo
          nextFragment: #F2
          formalParameters
            #F3 n1 (nameOffset:13) (firstTokenOffset:9) (offset:13)
              element: <testLibrary>::@function::foo::@formalParameter::n1
              nextFragment: #F4
        #F2 foo (nameOffset:33) (firstTokenOffset:20) (offset:33)
          element: <testLibrary>::@function::foo
          previousFragment: #F1
          formalParameters
            #F4 n1 (nameOffset:41) (firstTokenOffset:37) (offset:41)
              element: <testLibrary>::@function::foo::@formalParameter::n1
              previousFragment: #F3
  functions
    foo
      reference: <testLibrary>::@function::foo
      firstFragment: #F1
      formalParameters
        #E0 requiredPositional n1
          firstFragment: #F3
          type: int
      returnType: void
  exportedReferences
    declared <testLibrary>::@function::foo
  exportNamespace
    foo: <testLibrary>::@function::foo
''');
  }

  test_formalParameters_positional_21() async {
    var library = await buildLibrary(r'''
void foo(int n1, int n2) {}
augment void foo(int n1) {}
''');

    configuration.withExportScope = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      functions
        #F1 foo (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@function::foo
          nextFragment: #F2
          formalParameters
            #F3 n1 (nameOffset:13) (firstTokenOffset:9) (offset:13)
              element: <testLibrary>::@function::foo::@formalParameter::n1
              nextFragment: #F4
            #F5 n2 (nameOffset:21) (firstTokenOffset:17) (offset:21)
              element: <testLibrary>::@function::foo::@formalParameter::n2
              nextFragment: #F6
        #F2 foo (nameOffset:41) (firstTokenOffset:28) (offset:41)
          element: <testLibrary>::@function::foo
          previousFragment: #F1
          formalParameters
            #F4 n1 (nameOffset:49) (firstTokenOffset:45) (offset:49)
              element: <testLibrary>::@function::foo::@formalParameter::n1
              previousFragment: #F3
            #F6 n2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:41)
              element: <testLibrary>::@function::foo::@formalParameter::n2
              previousFragment: #F5
  functions
    foo
      reference: <testLibrary>::@function::foo
      firstFragment: #F1
      formalParameters
        #E0 requiredPositional n1
          firstFragment: #F3
          type: int
        #E1 requiredPositional n2
          firstFragment: #F5
          type: int
      returnType: void
  exportedReferences
    declared <testLibrary>::@function::foo
  exportNamespace
    foo: <testLibrary>::@function::foo
''');
  }

  test_formalParameters_positional_differentName() async {
    var library = await buildLibrary(r'''
void foo(int p1) {}
augment void foo(int p2) {}
''');

    configuration.withExportScope = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      functions
        #F1 foo (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@function::foo
          nextFragment: #F2
          formalParameters
            #F3 p1 (nameOffset:13) (firstTokenOffset:9) (offset:13)
              element: <testLibrary>::@function::foo::@formalParameter::p1
              nextFragment: #F4
        #F2 foo (nameOffset:33) (firstTokenOffset:20) (offset:33)
          element: <testLibrary>::@function::foo
          previousFragment: #F1
          formalParameters
            #F4 p2 (nameOffset:41) (firstTokenOffset:37) (offset:41)
              element: <testLibrary>::@function::foo::@formalParameter::p1
              previousFragment: #F3
  functions
    foo
      reference: <testLibrary>::@function::foo
      firstFragment: #F1
      formalParameters
        #E0 requiredPositional p1
          firstFragment: #F3
          type: int
      returnType: void
  exportedReferences
    declared <testLibrary>::@function::foo
  exportNamespace
    foo: <testLibrary>::@function::foo
''');
  }

  test_formalParameters_positional_differentType() async {
    var library = await buildLibrary(r'''
void foo(int p1) {}
augment void foo(double p1) {}
''');

    configuration.withExportScope = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      functions
        #F1 foo (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@function::foo
          nextFragment: #F2
          formalParameters
            #F3 p1 (nameOffset:13) (firstTokenOffset:9) (offset:13)
              element: <testLibrary>::@function::foo::@formalParameter::p1
              nextFragment: #F4
        #F2 foo (nameOffset:33) (firstTokenOffset:20) (offset:33)
          element: <testLibrary>::@function::foo
          previousFragment: #F1
          formalParameters
            #F4 p1 (nameOffset:44) (firstTokenOffset:37) (offset:44)
              element: <testLibrary>::@function::foo::@formalParameter::p1
              previousFragment: #F3
  functions
    foo
      reference: <testLibrary>::@function::foo
      firstFragment: #F1
      formalParameters
        #E0 requiredPositional p1
          firstFragment: #F3
          type: int
      returnType: void
  exportedReferences
    declared <testLibrary>::@function::foo
  exportNamespace
    foo: <testLibrary>::@function::foo
''');
  }

  test_formalParameters_positional_requiredNamed_11() async {
    var library = await buildLibrary(r'''
void foo(int p1, {required int n1}) {}
augment void foo(int p1, {required int n1}) {}
''');

    configuration.withExportScope = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      functions
        #F1 foo (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@function::foo
          nextFragment: #F2
          formalParameters
            #F3 p1 (nameOffset:13) (firstTokenOffset:9) (offset:13)
              element: <testLibrary>::@function::foo::@formalParameter::p1
              nextFragment: #F4
            #F5 n1 (nameOffset:31) (firstTokenOffset:18) (offset:31)
              element: <testLibrary>::@function::foo::@formalParameter::n1
              nextFragment: #F6
        #F2 foo (nameOffset:52) (firstTokenOffset:39) (offset:52)
          element: <testLibrary>::@function::foo
          previousFragment: #F1
          formalParameters
            #F4 p1 (nameOffset:60) (firstTokenOffset:56) (offset:60)
              element: <testLibrary>::@function::foo::@formalParameter::p1
              previousFragment: #F3
            #F6 n1 (nameOffset:78) (firstTokenOffset:65) (offset:78)
              element: <testLibrary>::@function::foo::@formalParameter::n1
              previousFragment: #F5
  functions
    foo
      reference: <testLibrary>::@function::foo
      firstFragment: #F1
      formalParameters
        #E0 requiredPositional p1
          firstFragment: #F3
          type: int
        #E1 requiredNamed n1
          firstFragment: #F5
          type: int
      returnType: void
  exportedReferences
    declared <testLibrary>::@function::foo
  exportNamespace
    foo: <testLibrary>::@function::foo
''');
  }

  test_formalParameters_positional_requiredNamed_12() async {
    var library = await buildLibrary(r'''
void foo(int p1, {required int n1}) {}
augment void foo(int p1, int p2, {required int n1, required int n2}) {}
''');

    configuration.withExportScope = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      functions
        #F1 foo (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@function::foo
          nextFragment: #F2
          formalParameters
            #F3 p1 (nameOffset:13) (firstTokenOffset:9) (offset:13)
              element: <testLibrary>::@function::foo::@formalParameter::p1
              nextFragment: #F4
            #F5 n1 (nameOffset:31) (firstTokenOffset:18) (offset:31)
              element: <testLibrary>::@function::foo::@formalParameter::n1
              nextFragment: #F6
        #F2 foo (nameOffset:52) (firstTokenOffset:39) (offset:52)
          element: <testLibrary>::@function::foo
          previousFragment: #F1
          formalParameters
            #F4 p1 (nameOffset:60) (firstTokenOffset:56) (offset:60)
              element: <testLibrary>::@function::foo::@formalParameter::p1
              previousFragment: #F3
            #F6 n1 (nameOffset:68) (firstTokenOffset:64) (offset:68)
              element: <testLibrary>::@function::foo::@formalParameter::n1
              previousFragment: #F5
  functions
    foo
      reference: <testLibrary>::@function::foo
      firstFragment: #F1
      formalParameters
        #E0 requiredPositional p1
          firstFragment: #F3
          type: int
        #E1 requiredNamed n1
          firstFragment: #F5
          type: int
      returnType: void
  exportedReferences
    declared <testLibrary>::@function::foo
  exportNamespace
    foo: <testLibrary>::@function::foo
''');
  }

  test_formalParameters_positional_requiredNamed_21() async {
    var library = await buildLibrary(r'''
void foo(int p1, int p2, {required int n1, required int n2}) {}
augment void foo(int p1, {required int n1}) {}
''');

    configuration.withExportScope = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      functions
        #F1 foo (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@function::foo
          nextFragment: #F2
          formalParameters
            #F3 p1 (nameOffset:13) (firstTokenOffset:9) (offset:13)
              element: <testLibrary>::@function::foo::@formalParameter::p1
              nextFragment: #F4
            #F5 p2 (nameOffset:21) (firstTokenOffset:17) (offset:21)
              element: <testLibrary>::@function::foo::@formalParameter::p2
              nextFragment: #F6
            #F7 n1 (nameOffset:39) (firstTokenOffset:26) (offset:39)
              element: <testLibrary>::@function::foo::@formalParameter::n1
              nextFragment: #F8
            #F9 n2 (nameOffset:56) (firstTokenOffset:43) (offset:56)
              element: <testLibrary>::@function::foo::@formalParameter::n2
              nextFragment: #F10
        #F2 foo (nameOffset:77) (firstTokenOffset:64) (offset:77)
          element: <testLibrary>::@function::foo
          previousFragment: #F1
          formalParameters
            #F4 p1 (nameOffset:85) (firstTokenOffset:81) (offset:85)
              element: <testLibrary>::@function::foo::@formalParameter::p1
              previousFragment: #F3
            #F6 p2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:77)
              element: <testLibrary>::@function::foo::@formalParameter::p2
              previousFragment: #F5
            #F8 n1 (nameOffset:103) (firstTokenOffset:90) (offset:103)
              element: <testLibrary>::@function::foo::@formalParameter::n1
              previousFragment: #F7
            #F10 n2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:77)
              element: <testLibrary>::@function::foo::@formalParameter::n2
              previousFragment: #F9
  functions
    foo
      reference: <testLibrary>::@function::foo
      firstFragment: #F1
      formalParameters
        #E0 requiredPositional p1
          firstFragment: #F3
          type: int
        #E1 requiredPositional p2
          firstFragment: #F5
          type: int
        #E2 requiredNamed n1
          firstFragment: #F7
          type: int
        #E3 requiredNamed n2
          firstFragment: #F9
          type: int
      returnType: void
  exportedReferences
    declared <testLibrary>::@function::foo
  exportNamespace
    foo: <testLibrary>::@function::foo
''');
  }

  test_formalParameters_positional_requiredNamed_differentType() async {
    var library = await buildLibrary(r'''
void foo(int p1, {required int n1}) {}
augment void foo(double p1, {required double n1}) {}
''');

    configuration.withExportScope = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      functions
        #F1 foo (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@function::foo
          nextFragment: #F2
          formalParameters
            #F3 p1 (nameOffset:13) (firstTokenOffset:9) (offset:13)
              element: <testLibrary>::@function::foo::@formalParameter::p1
              nextFragment: #F4
            #F5 n1 (nameOffset:31) (firstTokenOffset:18) (offset:31)
              element: <testLibrary>::@function::foo::@formalParameter::n1
              nextFragment: #F6
        #F2 foo (nameOffset:52) (firstTokenOffset:39) (offset:52)
          element: <testLibrary>::@function::foo
          previousFragment: #F1
          formalParameters
            #F4 p1 (nameOffset:63) (firstTokenOffset:56) (offset:63)
              element: <testLibrary>::@function::foo::@formalParameter::p1
              previousFragment: #F3
            #F6 n1 (nameOffset:84) (firstTokenOffset:68) (offset:84)
              element: <testLibrary>::@function::foo::@formalParameter::n1
              previousFragment: #F5
  functions
    foo
      reference: <testLibrary>::@function::foo
      firstFragment: #F1
      formalParameters
        #E0 requiredPositional p1
          firstFragment: #F3
          type: int
        #E1 requiredNamed n1
          firstFragment: #F5
          type: int
      returnType: void
  exportedReferences
    declared <testLibrary>::@function::foo
  exportNamespace
    foo: <testLibrary>::@function::foo
''');
  }

  test_formalParameters_positional_swapped() async {
    var library = await buildLibrary(r'''
void foo(int p1, int p2) {}
augment void foo(int p2, int p1) {}
''');

    configuration.withExportScope = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      functions
        #F1 foo (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@function::foo
          nextFragment: #F2
          formalParameters
            #F3 p1 (nameOffset:13) (firstTokenOffset:9) (offset:13)
              element: <testLibrary>::@function::foo::@formalParameter::p1
              nextFragment: #F4
            #F5 p2 (nameOffset:21) (firstTokenOffset:17) (offset:21)
              element: <testLibrary>::@function::foo::@formalParameter::p2
              nextFragment: #F6
        #F2 foo (nameOffset:41) (firstTokenOffset:28) (offset:41)
          element: <testLibrary>::@function::foo
          previousFragment: #F1
          formalParameters
            #F4 p2 (nameOffset:49) (firstTokenOffset:45) (offset:49)
              element: <testLibrary>::@function::foo::@formalParameter::p1
              previousFragment: #F3
            #F6 p1 (nameOffset:57) (firstTokenOffset:53) (offset:57)
              element: <testLibrary>::@function::foo::@formalParameter::p2
              previousFragment: #F5
  functions
    foo
      reference: <testLibrary>::@function::foo
      firstFragment: #F1
      formalParameters
        #E0 requiredPositional p1
          firstFragment: #F3
          type: int
        #E1 requiredPositional p2
          firstFragment: #F5
          type: int
      returnType: void
  exportedReferences
    declared <testLibrary>::@function::foo
  exportNamespace
    foo: <testLibrary>::@function::foo
''');
  }

  test_formalParameters_requiredNamed_11() async {
    var library = await buildLibrary(r'''
void foo({required int n1}) {}
augment void foo({required int n1}) {}
''');

    configuration.withExportScope = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      functions
        #F1 foo (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@function::foo
          nextFragment: #F2
          formalParameters
            #F3 n1 (nameOffset:23) (firstTokenOffset:10) (offset:23)
              element: <testLibrary>::@function::foo::@formalParameter::n1
              nextFragment: #F4
        #F2 foo (nameOffset:44) (firstTokenOffset:31) (offset:44)
          element: <testLibrary>::@function::foo
          previousFragment: #F1
          formalParameters
            #F4 n1 (nameOffset:62) (firstTokenOffset:49) (offset:62)
              element: <testLibrary>::@function::foo::@formalParameter::n1
              previousFragment: #F3
  functions
    foo
      reference: <testLibrary>::@function::foo
      firstFragment: #F1
      formalParameters
        #E0 requiredNamed n1
          firstFragment: #F3
          type: int
      returnType: void
  exportedReferences
    declared <testLibrary>::@function::foo
  exportNamespace
    foo: <testLibrary>::@function::foo
''');
  }

  test_formalParameters_requiredNamed_12() async {
    var library = await buildLibrary(r'''
void foo({required int n1}) {}
augment void foo({required int n1, required int n2}) {}
''');

    configuration.withExportScope = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      functions
        #F1 foo (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@function::foo
          nextFragment: #F2
          formalParameters
            #F3 n1 (nameOffset:23) (firstTokenOffset:10) (offset:23)
              element: <testLibrary>::@function::foo::@formalParameter::n1
              nextFragment: #F4
        #F2 foo (nameOffset:44) (firstTokenOffset:31) (offset:44)
          element: <testLibrary>::@function::foo
          previousFragment: #F1
          formalParameters
            #F4 n1 (nameOffset:62) (firstTokenOffset:49) (offset:62)
              element: <testLibrary>::@function::foo::@formalParameter::n1
              previousFragment: #F3
  functions
    foo
      reference: <testLibrary>::@function::foo
      firstFragment: #F1
      formalParameters
        #E0 requiredNamed n1
          firstFragment: #F3
          type: int
      returnType: void
  exportedReferences
    declared <testLibrary>::@function::foo
  exportNamespace
    foo: <testLibrary>::@function::foo
''');
  }

  test_formalParameters_requiredNamed_21() async {
    var library = await buildLibrary(r'''
void foo({required int n1, required int n2}) {}
augment void foo({required int n1}) {}
''');

    configuration.withExportScope = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      functions
        #F1 foo (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@function::foo
          nextFragment: #F2
          formalParameters
            #F3 n1 (nameOffset:23) (firstTokenOffset:10) (offset:23)
              element: <testLibrary>::@function::foo::@formalParameter::n1
              nextFragment: #F4
            #F5 n2 (nameOffset:40) (firstTokenOffset:27) (offset:40)
              element: <testLibrary>::@function::foo::@formalParameter::n2
              nextFragment: #F6
        #F2 foo (nameOffset:61) (firstTokenOffset:48) (offset:61)
          element: <testLibrary>::@function::foo
          previousFragment: #F1
          formalParameters
            #F4 n1 (nameOffset:79) (firstTokenOffset:66) (offset:79)
              element: <testLibrary>::@function::foo::@formalParameter::n1
              previousFragment: #F3
            #F6 n2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:61)
              element: <testLibrary>::@function::foo::@formalParameter::n2
              previousFragment: #F5
  functions
    foo
      reference: <testLibrary>::@function::foo
      firstFragment: #F1
      formalParameters
        #E0 requiredNamed n1
          firstFragment: #F3
          type: int
        #E1 requiredNamed n2
          firstFragment: #F5
          type: int
      returnType: void
  exportedReferences
    declared <testLibrary>::@function::foo
  exportNamespace
    foo: <testLibrary>::@function::foo
''');
  }

  test_formalParameters_requiredNamed_differentType() async {
    var library = await buildLibrary(r'''
void foo({required int n1}) {}
augment void foo({required double n1}) {}
''');

    configuration.withExportScope = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      functions
        #F1 foo (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@function::foo
          nextFragment: #F2
          formalParameters
            #F3 n1 (nameOffset:23) (firstTokenOffset:10) (offset:23)
              element: <testLibrary>::@function::foo::@formalParameter::n1
              nextFragment: #F4
        #F2 foo (nameOffset:44) (firstTokenOffset:31) (offset:44)
          element: <testLibrary>::@function::foo
          previousFragment: #F1
          formalParameters
            #F4 n1 (nameOffset:65) (firstTokenOffset:49) (offset:65)
              element: <testLibrary>::@function::foo::@formalParameter::n1
              previousFragment: #F3
  functions
    foo
      reference: <testLibrary>::@function::foo
      firstFragment: #F1
      formalParameters
        #E0 requiredNamed n1
          firstFragment: #F3
          type: int
      returnType: void
  exportedReferences
    declared <testLibrary>::@function::foo
  exportNamespace
    foo: <testLibrary>::@function::foo
''');
  }

  test_formalParameters_requiredNamed_swapped() async {
    var library = await buildLibrary(r'''
void foo({required int n2, required int n1}) {}
augment void foo({required int n1, required int n2}) {}
''');

    configuration.withExportScope = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      functions
        #F1 foo (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@function::foo
          nextFragment: #F2
          formalParameters
            #F3 n2 (nameOffset:23) (firstTokenOffset:10) (offset:23)
              element: <testLibrary>::@function::foo::@formalParameter::n2
              nextFragment: #F4
            #F5 n1 (nameOffset:40) (firstTokenOffset:27) (offset:40)
              element: <testLibrary>::@function::foo::@formalParameter::n1
              nextFragment: #F6
        #F2 foo (nameOffset:61) (firstTokenOffset:48) (offset:61)
          element: <testLibrary>::@function::foo
          previousFragment: #F1
          formalParameters
            #F4 n2 (nameOffset:79) (firstTokenOffset:66) (offset:79)
              element: <testLibrary>::@function::foo::@formalParameter::n2
              previousFragment: #F3
            #F6 n1 (nameOffset:96) (firstTokenOffset:83) (offset:96)
              element: <testLibrary>::@function::foo::@formalParameter::n1
              previousFragment: #F5
  functions
    foo
      reference: <testLibrary>::@function::foo
      firstFragment: #F1
      formalParameters
        #E0 requiredNamed n2
          firstFragment: #F3
          type: int
        #E1 requiredNamed n1
          firstFragment: #F5
          type: int
      returnType: void
  exportedReferences
    declared <testLibrary>::@function::foo
  exportNamespace
    foo: <testLibrary>::@function::foo
''');
  }

  test_typeParameter() async {
    var library = await buildLibrary(r'''
void foo<T>() {}
augment void foo<T>() {}
''');

    configuration.withExportScope = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      functions
        #F1 foo (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@function::foo
          nextFragment: #F2
          typeParameters
            #F3 T (nameOffset:9) (firstTokenOffset:9) (offset:9)
              element: #E0 T
              nextFragment: #F4
        #F2 foo (nameOffset:30) (firstTokenOffset:17) (offset:30)
          element: <testLibrary>::@function::foo
          previousFragment: #F1
          typeParameters
            #F4 T (nameOffset:34) (firstTokenOffset:34) (offset:34)
              element: #E0 T
              previousFragment: #F3
  functions
    foo
      reference: <testLibrary>::@function::foo
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F3
      returnType: void
  exportedReferences
    declared <testLibrary>::@function::foo
  exportNamespace
    foo: <testLibrary>::@function::foo
''');
  }

  test_typeParameters_111() async {
    var library = await buildLibrary(r'''
void foo<T>() {}
augment void foo<T>() {}
augment void foo<T>() {}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      functions
        #F1 foo (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@function::foo
          nextFragment: #F2
          typeParameters
            #F3 T (nameOffset:9) (firstTokenOffset:9) (offset:9)
              element: #E0 T
              nextFragment: #F4
        #F2 foo (nameOffset:30) (firstTokenOffset:17) (offset:30)
          element: <testLibrary>::@function::foo
          previousFragment: #F1
          nextFragment: #F5
          typeParameters
            #F4 T (nameOffset:34) (firstTokenOffset:34) (offset:34)
              element: #E0 T
              previousFragment: #F3
              nextFragment: #F6
        #F5 foo (nameOffset:55) (firstTokenOffset:42) (offset:55)
          element: <testLibrary>::@function::foo
          previousFragment: #F2
          typeParameters
            #F6 T (nameOffset:59) (firstTokenOffset:59) (offset:59)
              element: #E0 T
              previousFragment: #F4
  functions
    foo
      reference: <testLibrary>::@function::foo
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F3
      returnType: void
''');
  }

  test_typeParameters_121() async {
    var library = await buildLibrary(r'''
void foo<T>() {}
augment void foo<T, U>() {}
augment void foo<T>() {}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      functions
        #F1 foo (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@function::foo
          nextFragment: #F2
          typeParameters
            #F3 T (nameOffset:9) (firstTokenOffset:9) (offset:9)
              element: #E0 T
              nextFragment: #F4
        #F2 foo (nameOffset:30) (firstTokenOffset:17) (offset:30)
          element: <testLibrary>::@function::foo
          previousFragment: #F1
          nextFragment: #F5
          typeParameters
            #F4 T (nameOffset:34) (firstTokenOffset:34) (offset:34)
              element: #E0 T
              previousFragment: #F3
              nextFragment: #F6
        #F5 foo (nameOffset:58) (firstTokenOffset:45) (offset:58)
          element: <testLibrary>::@function::foo
          previousFragment: #F2
          typeParameters
            #F6 T (nameOffset:62) (firstTokenOffset:62) (offset:62)
              element: #E0 T
              previousFragment: #F4
  functions
    foo
      reference: <testLibrary>::@function::foo
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F3
      returnType: void
''');
  }

  test_typeParameters_212() async {
    var library = await buildLibrary(r'''
void foo<T, U>() {}
augment void foo<T>() {}
augment void foo<T, U>() {}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      functions
        #F1 foo (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@function::foo
          nextFragment: #F2
          typeParameters
            #F3 T (nameOffset:9) (firstTokenOffset:9) (offset:9)
              element: #E0 T
              nextFragment: #F4
            #F5 U (nameOffset:12) (firstTokenOffset:12) (offset:12)
              element: #E1 U
              nextFragment: #F6
        #F2 foo (nameOffset:33) (firstTokenOffset:20) (offset:33)
          element: <testLibrary>::@function::foo
          previousFragment: #F1
          nextFragment: #F7
          typeParameters
            #F4 T (nameOffset:37) (firstTokenOffset:37) (offset:37)
              element: #E0 T
              previousFragment: #F3
              nextFragment: #F8
            #F6 U (nameOffset:<null>) (firstTokenOffset:<null>) (offset:33)
              element: #E1 U
              previousFragment: #F5
              nextFragment: #F9
        #F7 foo (nameOffset:58) (firstTokenOffset:45) (offset:58)
          element: <testLibrary>::@function::foo
          previousFragment: #F2
          typeParameters
            #F8 T (nameOffset:62) (firstTokenOffset:62) (offset:62)
              element: #E0 T
              previousFragment: #F4
            #F9 U (nameOffset:65) (firstTokenOffset:65) (offset:65)
              element: #E1 U
              previousFragment: #F6
  functions
    foo
      reference: <testLibrary>::@function::foo
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F3
        #E1 U
          firstFragment: #F5
      returnType: void
''');
  }

  test_typeParameters_int_string() async {
    var library = await buildLibrary(r'''
void foo<T extends int>() {}
augment void foo<T extends String>() {}
''');

    configuration.withExportScope = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      functions
        #F1 foo (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@function::foo
          nextFragment: #F2
          typeParameters
            #F3 T (nameOffset:9) (firstTokenOffset:9) (offset:9)
              element: #E0 T
              nextFragment: #F4
        #F2 foo (nameOffset:42) (firstTokenOffset:29) (offset:42)
          element: <testLibrary>::@function::foo
          previousFragment: #F1
          typeParameters
            #F4 T (nameOffset:46) (firstTokenOffset:46) (offset:46)
              element: #E0 T
              previousFragment: #F3
  functions
    foo
      reference: <testLibrary>::@function::foo
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F3
          bound: int
      returnType: void
  exportedReferences
    declared <testLibrary>::@function::foo
  exportNamespace
    foo: <testLibrary>::@function::foo
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
