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
    // TODO(scheglov): implement augmentation
    // defineReflectiveTests(TopLevelFunctionElementTest_augmentation_keepLinking);
    // defineReflectiveTests(TopLevelFunctionElementTest_augmentation_fromBytes);
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
        #F1 f @28
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
        #F1 f @28
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
        #F1 f @60
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
        #F1 main @0
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
    #F0 <testLibraryFragment> (offset=8)
      element: <testLibrary>
      nextFragment: #F1
      parts
        part_0
          uri: package:test/a.dart
          unit: #F1
    #F1 package:test/a.dart
      element: <testLibrary>
      enclosingFragment: #F0
      previousFragment: #F0
      functions
        #F2 main @16
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
        #F1 f @9
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
        #F1 f @5
          element: <testLibrary>::@function::f
          formalParameters
            #F2 x @13
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
        #F1 f @5
          element: <testLibrary>::@function::f
          formalParameters
            #F2 this.a @16
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
        #F1 f @5
          element: <testLibrary>::@function::f
          formalParameters
            #F2 this.a @17
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
        #F1 f @5
          element: <testLibrary>::@function::f
          formalParameters
            #F2 this.a @16
              element: <testLibrary>::@function::f::@formalParameter::a
              parameters
                #F3 b @22
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
        #F1 f @0
          element: <testLibrary>::@function::f
          formalParameters
            #F2 x @8
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
        #F1 f @0
          element: <testLibrary>::@function::f
          formalParameters
            #F2 x @3
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
        #F1 f @0
          element: <testLibrary>::@function::f
          formalParameters
            #F2 x @3
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
        #F1 f @0
          element: <testLibrary>::@function::f
          formalParameters
            #F2 x @2
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
        #F1 f @0
          element: <testLibrary>::@function::f
          formalParameters
            #F2 g @2
              element: <testLibrary>::@function::f::@formalParameter::g
              parameters
                #F3 x @4
                  element: x@4
                #F4 y @7
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
        #F1 f @0
          element: <testLibrary>::@function::f
          formalParameters
            #F2 g @6
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
        #F1 f @0
          element: <testLibrary>::@function::f
          formalParameters
            #F2 g @7
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
        #F1 f @0
          element: <testLibrary>::@function::f
          formalParameters
            #F2 i @6
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
        #F1 f @5
          element: <testLibrary>::@function::f
          typeParameters
            #F2 T @7
              element: #E0 T
          formalParameters
            #F3 a @12
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
        #F1 f @5
          element: <testLibrary>::@function::f
          formalParameters
            #F2 a @9
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
        #F1 f @0
          element: <testLibrary>::@function::f
          formalParameters
            #F2 x @2
              element: <testLibrary>::@function::f::@formalParameter::x
            #F3 y @5
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
        #F1 f @0
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
        #F1 f @2
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
        #F1 f @5
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
        #F1 f @4
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
        #F1 f @2
          element: <testLibrary>::@function::f
          typeParameters
            #F2 T @4
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
        #F1 f @5
          element: <testLibrary>::@function::f
          typeParameters
            #F2 T @7
              element: #E0 T
            #F3 U @10
              element: #E1 U
          formalParameters
            #F4 x @15
              element: <testLibrary>::@function::f::@formalParameter::x
              parameters
                #F5 u @19
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
        #F1 f @5
          element: <testLibrary>::@function::f
          typeParameters
            #F2 T @7
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
        #F1 f @5
          element: <testLibrary>::@function::f
          typeParameters
            #F2 T @7
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
        #F1 f @0
          element: <testLibrary>::@function::f
        #F2 g @7
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
        #F1 get @0
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
        #F1 class main @6
          element: <testLibrary>::@class::main
          constructors
            #F2 synthetic new
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
        #F1 class main @6
          element: <testLibrary>::@class::main
          constructors
            #F2 synthetic new
              element: <testLibrary>::@class::main::@constructor::new
              typeName: main
        #F3 class C @29
          element: <testLibrary>::@class::C
          constructors
            #F4 synthetic new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
        #F5 class D @40
          element: <testLibrary>::@class::D
          constructors
            #F6 synthetic new
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
        #F1 synthetic main (offset=4)
          element: <testLibrary>::@topLevelVariable::main
      getters
        #F2 main @4
          element: <testLibrary>::@getter::main
          returnType: dynamic
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
        #F1 main @8
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
        #F1 main @4
          element: <testLibrary>::@topLevelVariable::main
      getters
        #F2 synthetic main
          element: <testLibrary>::@getter::main
          returnType: dynamic
      setters
        #F3 synthetic main
          element: <testLibrary>::@setter::main
          formalParameters
            #F4 _main
              element: <testLibrary>::@setter::main::@formalParameter::_main
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
        #E0 requiredPositional _main
          firstFragment: #F4
          type: dynamic
      returnType: void
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
        #F1 set @0
          element: <testLibrary>::@function::set
          formalParameters
            #F2 _ @9
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
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      parts
        part_0
          uri: package:test/a1.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a1.dart
        part_1
          uri: package:test/a2.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a2.dart
      functions
        foo @37
          reference: <testLibraryFragment>::@function::foo
          enclosingElement3: <testLibraryFragment>
          returnType: void
          augmentation: <testLibrary>::@fragment::package:test/a1.dart::@functionAugmentation::foo
    <testLibrary>::@fragment::package:test/a1.dart
      enclosingElement3: <testLibraryFragment>
      parts
        part_2
          uri: package:test/a11.dart
          enclosingElement3: <testLibrary>::@fragment::package:test/a1.dart
          unit: <testLibrary>::@fragment::package:test/a11.dart
        part_3
          uri: package:test/a12.dart
          enclosingElement3: <testLibrary>::@fragment::package:test/a1.dart
          unit: <testLibrary>::@fragment::package:test/a12.dart
      functions
        augment foo @68
          reference: <testLibrary>::@fragment::package:test/a1.dart::@functionAugmentation::foo
          enclosingElement3: <testLibrary>::@fragment::package:test/a1.dart
          returnType: void
          augmentationTarget: <testLibraryFragment>::@function::foo
          augmentation: <testLibrary>::@fragment::package:test/a11.dart::@functionAugmentation::foo
    <testLibrary>::@fragment::package:test/a11.dart
      enclosingElement3: <testLibrary>::@fragment::package:test/a1.dart
      functions
        augment foo @32
          reference: <testLibrary>::@fragment::package:test/a11.dart::@functionAugmentation::foo
          enclosingElement3: <testLibrary>::@fragment::package:test/a11.dart
          returnType: void
          augmentationTarget: <testLibrary>::@fragment::package:test/a1.dart::@functionAugmentation::foo
          augmentation: <testLibrary>::@fragment::package:test/a12.dart::@functionAugmentation::foo
    <testLibrary>::@fragment::package:test/a12.dart
      enclosingElement3: <testLibrary>::@fragment::package:test/a1.dart
      functions
        augment foo @32
          reference: <testLibrary>::@fragment::package:test/a12.dart::@functionAugmentation::foo
          enclosingElement3: <testLibrary>::@fragment::package:test/a12.dart
          returnType: void
          augmentationTarget: <testLibrary>::@fragment::package:test/a11.dart::@functionAugmentation::foo
          augmentation: <testLibrary>::@fragment::package:test/a2.dart::@functionAugmentation::foo
    <testLibrary>::@fragment::package:test/a2.dart
      enclosingElement3: <testLibraryFragment>
      parts
        part_4
          uri: package:test/a21.dart
          enclosingElement3: <testLibrary>::@fragment::package:test/a2.dart
          unit: <testLibrary>::@fragment::package:test/a21.dart
        part_5
          uri: package:test/a22.dart
          enclosingElement3: <testLibrary>::@fragment::package:test/a2.dart
          unit: <testLibrary>::@fragment::package:test/a22.dart
      functions
        augment foo @68
          reference: <testLibrary>::@fragment::package:test/a2.dart::@functionAugmentation::foo
          enclosingElement3: <testLibrary>::@fragment::package:test/a2.dart
          returnType: void
          augmentationTarget: <testLibrary>::@fragment::package:test/a12.dart::@functionAugmentation::foo
          augmentation: <testLibrary>::@fragment::package:test/a21.dart::@functionAugmentation::foo
    <testLibrary>::@fragment::package:test/a21.dart
      enclosingElement3: <testLibrary>::@fragment::package:test/a2.dart
      functions
        augment foo @32
          reference: <testLibrary>::@fragment::package:test/a21.dart::@functionAugmentation::foo
          enclosingElement3: <testLibrary>::@fragment::package:test/a21.dart
          returnType: void
          augmentationTarget: <testLibrary>::@fragment::package:test/a2.dart::@functionAugmentation::foo
          augmentation: <testLibrary>::@fragment::package:test/a22.dart::@functionAugmentation::foo
    <testLibrary>::@fragment::package:test/a22.dart
      enclosingElement3: <testLibrary>::@fragment::package:test/a2.dart
      functions
        augment foo @32
          reference: <testLibrary>::@fragment::package:test/a22.dart::@functionAugmentation::foo
          enclosingElement3: <testLibrary>::@fragment::package:test/a22.dart
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
          element: <testLibrary>::@function::foo
    <testLibrary>::@fragment::package:test/a1.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/a11.dart
      functions
        foo @68
          reference: <testLibrary>::@fragment::package:test/a1.dart::@functionAugmentation::foo
          element: <testLibrary>::@function::foo
    <testLibrary>::@fragment::package:test/a11.dart
      element: <testLibrary>
      enclosingFragment: <testLibrary>::@fragment::package:test/a1.dart
      previousFragment: <testLibrary>::@fragment::package:test/a1.dart
      nextFragment: <testLibrary>::@fragment::package:test/a12.dart
      functions
        foo @32
          reference: <testLibrary>::@fragment::package:test/a11.dart::@functionAugmentation::foo
          element: <testLibrary>::@function::foo
    <testLibrary>::@fragment::package:test/a12.dart
      element: <testLibrary>
      enclosingFragment: <testLibrary>::@fragment::package:test/a1.dart
      previousFragment: <testLibrary>::@fragment::package:test/a11.dart
      nextFragment: <testLibrary>::@fragment::package:test/a2.dart
      functions
        foo @32
          reference: <testLibrary>::@fragment::package:test/a12.dart::@functionAugmentation::foo
          element: <testLibrary>::@function::foo
    <testLibrary>::@fragment::package:test/a2.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibrary>::@fragment::package:test/a12.dart
      nextFragment: <testLibrary>::@fragment::package:test/a21.dart
      functions
        foo @68
          reference: <testLibrary>::@fragment::package:test/a2.dart::@functionAugmentation::foo
          element: <testLibrary>::@function::foo
    <testLibrary>::@fragment::package:test/a21.dart
      element: <testLibrary>
      enclosingFragment: <testLibrary>::@fragment::package:test/a2.dart
      previousFragment: <testLibrary>::@fragment::package:test/a2.dart
      nextFragment: <testLibrary>::@fragment::package:test/a22.dart
      functions
        foo @32
          reference: <testLibrary>::@fragment::package:test/a21.dart::@functionAugmentation::foo
          element: <testLibrary>::@function::foo
    <testLibrary>::@fragment::package:test/a22.dart
      element: <testLibrary>
      enclosingFragment: <testLibrary>::@fragment::package:test/a2.dart
      previousFragment: <testLibrary>::@fragment::package:test/a21.dart
      functions
        foo @32
          reference: <testLibrary>::@fragment::package:test/a22.dart::@functionAugmentation::foo
          element: <testLibrary>::@function::foo
  functions
    foo
      reference: <testLibrary>::@function::foo
      firstFragment: <testLibraryFragment>::@function::foo
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
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      classes
        class foo @22
          reference: <testLibraryFragment>::@class::foo
          enclosingElement3: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::foo::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::foo
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      functions
        augment foo @35
          reference: <testLibrary>::@fragment::package:test/a.dart::@functionAugmentation::foo
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
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
          element: <testLibrary>::@class::foo
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::foo::@constructor::new
              element: <testLibraryFragment>::@class::foo::@constructor::new#element
              typeName: foo
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      functions
        foo @35
          reference: <testLibrary>::@fragment::package:test/a.dart::@functionAugmentation::foo
          element: <testLibrary>::@function::foo
  classes
    class foo
      reference: <testLibrary>::@class::foo
      firstFragment: <testLibraryFragment>::@class::foo
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::foo::@constructor::new
  functions
    foo
      reference: <testLibrary>::@function::foo
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@functionAugmentation::foo
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
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      functions
        foo @20
          reference: <testLibraryFragment>::@function::foo
          enclosingElement3: <testLibraryFragment>
          returnType: void
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@functionAugmentation::foo
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      functions
        augment foo @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@functionAugmentation::foo
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          returnType: void
          augmentationTarget: <testLibraryFragment>::@function::foo
  exportedReferences
    declared <testLibraryFragment>::@function::foo
  exportNamespace
    foo: <testLibrary>::@fragment::package:test/a.dart::@functionAugmentation::foo
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
          element: <testLibrary>::@function::foo
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      functions
        foo @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@functionAugmentation::foo
          element: <testLibrary>::@function::foo
  functions
    foo
      reference: <testLibrary>::@function::foo
      firstFragment: <testLibraryFragment>::@function::foo
      returnType: void
  exportedReferences
    declared <testLibraryFragment>::@function::foo
  exportNamespace
    foo: <testLibrary>::@fragment::package:test/a.dart::@functionAugmentation::foo
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
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      functions
        foo @26
          reference: <testLibrary>::@fragment::package:test/a.dart::@function::foo
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          returnType: void
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@functionAugmentation::foo
        augment foo @48
          reference: <testLibrary>::@fragment::package:test/a.dart::@functionAugmentation::foo
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          returnType: void
          augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@function::foo
  exportedReferences
    declared <testLibrary>::@fragment::package:test/a.dart::@function::foo
  exportNamespace
    foo: <testLibrary>::@fragment::package:test/a.dart::@functionAugmentation::foo
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      functions
        foo @26
          reference: <testLibrary>::@fragment::package:test/a.dart::@function::foo
          element: <testLibrary>::@function::foo
        foo @48
          reference: <testLibrary>::@fragment::package:test/a.dart::@functionAugmentation::foo
          element: <testLibrary>::@function::foo
  functions
    foo
      reference: <testLibrary>::@function::foo
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@function::foo
      returnType: void
  exportedReferences
    declared <testLibrary>::@fragment::package:test/a.dart::@function::foo
  exportNamespace
    foo: <testLibrary>::@fragment::package:test/a.dart::@functionAugmentation::foo
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
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      topLevelVariables
        synthetic static foo @-1
          reference: <testLibraryFragment>::@topLevelVariable::foo
          enclosingElement3: <testLibraryFragment>
          type: int
      accessors
        static get foo @24
          reference: <testLibraryFragment>::@getter::foo
          enclosingElement3: <testLibraryFragment>
          returnType: int
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      functions
        augment foo @35
          reference: <testLibrary>::@fragment::package:test/a.dart::@functionAugmentation::foo
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
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
        synthetic foo (offset=-1)
          reference: <testLibraryFragment>::@topLevelVariable::foo
          element: <testLibrary>::@topLevelVariable::foo
          getter2: <testLibraryFragment>::@getter::foo
      getters
        get foo @24
          reference: <testLibraryFragment>::@getter::foo
          element: <testLibraryFragment>::@getter::foo#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      functions
        foo @35
          reference: <testLibrary>::@fragment::package:test/a.dart::@functionAugmentation::foo
          element: <testLibrary>::@function::foo
  topLevelVariables
    synthetic foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo
      type: int
      getter: <testLibraryFragment>::@getter::foo#element
  getters
    static get foo
      firstFragment: <testLibraryFragment>::@getter::foo
  functions
    foo
      reference: <testLibrary>::@function::foo
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@functionAugmentation::foo
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
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      topLevelVariables
        synthetic static foo @-1
          reference: <testLibraryFragment>::@topLevelVariable::foo
          enclosingElement3: <testLibraryFragment>
          type: int
      accessors
        static set foo= @20
          reference: <testLibraryFragment>::@setter::foo
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _ @28
              type: int
          returnType: void
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      functions
        augment foo @35
          reference: <testLibrary>::@fragment::package:test/a.dart::@functionAugmentation::foo
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
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
        synthetic foo (offset=-1)
          reference: <testLibraryFragment>::@topLevelVariable::foo
          element: <testLibrary>::@topLevelVariable::foo
          setter2: <testLibraryFragment>::@setter::foo
      setters
        set foo @20
          reference: <testLibraryFragment>::@setter::foo
          element: <testLibraryFragment>::@setter::foo#element
          formalParameters
            _ @28
              element: <testLibraryFragment>::@setter::foo::@parameter::_#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      functions
        foo @35
          reference: <testLibrary>::@fragment::package:test/a.dart::@functionAugmentation::foo
          element: <testLibrary>::@function::foo
  topLevelVariables
    synthetic foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo
      type: int
      setter: <testLibraryFragment>::@setter::foo#element
  setters
    static set foo
      firstFragment: <testLibraryFragment>::@setter::foo
      formalParameters
        requiredPositional _
          type: int
  functions
    foo
      reference: <testLibrary>::@function::foo
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@functionAugmentation::foo
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
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      topLevelVariables
        static foo @20
          reference: <testLibraryFragment>::@topLevelVariable::foo
          enclosingElement3: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: true
      accessors
        synthetic static get foo @-1
          reference: <testLibraryFragment>::@getter::foo
          enclosingElement3: <testLibraryFragment>
          returnType: int
        synthetic static set foo= @-1
          reference: <testLibraryFragment>::@setter::foo
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _foo @-1
              type: int
          returnType: void
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      functions
        augment foo @35
          reference: <testLibrary>::@fragment::package:test/a.dart::@functionAugmentation::foo
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
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
        hasInitializer foo @20
          reference: <testLibraryFragment>::@topLevelVariable::foo
          element: <testLibrary>::@topLevelVariable::foo
          getter2: <testLibraryFragment>::@getter::foo
          setter2: <testLibraryFragment>::@setter::foo
      getters
        synthetic get foo
          reference: <testLibraryFragment>::@getter::foo
          element: <testLibraryFragment>::@getter::foo#element
      setters
        synthetic set foo
          reference: <testLibraryFragment>::@setter::foo
          element: <testLibraryFragment>::@setter::foo#element
          formalParameters
            _foo
              element: <testLibraryFragment>::@setter::foo::@parameter::_foo#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      functions
        foo @35
          reference: <testLibrary>::@fragment::package:test/a.dart::@functionAugmentation::foo
          element: <testLibrary>::@function::foo
  topLevelVariables
    hasInitializer foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo
      type: int
      getter: <testLibraryFragment>::@getter::foo#element
      setter: <testLibraryFragment>::@setter::foo#element
  getters
    synthetic static get foo
      firstFragment: <testLibraryFragment>::@getter::foo
  setters
    synthetic static set foo
      firstFragment: <testLibraryFragment>::@setter::foo
      formalParameters
        requiredPositional _foo
          type: int
  functions
    foo
      reference: <testLibrary>::@function::foo
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@functionAugmentation::foo
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
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      classes
        class foo @21
          reference: <testLibraryFragment>::@class::foo
          enclosingElement3: <testLibraryFragment>
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      accessors
        augment static get foo @37
          reference: <testLibrary>::@fragment::package:test/a.dart::@getterAugmentation::foo
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
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
          element: <testLibrary>::@class::foo
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      getters
        augment get foo @37
          reference: <testLibrary>::@fragment::package:test/a.dart::@getterAugmentation::foo
          element: <testLibrary>::@fragment::package:test/a.dart::@getterAugmentation::foo#element
  classes
    class foo
      reference: <testLibrary>::@class::foo
      firstFragment: <testLibraryFragment>::@class::foo
  getters
    static get foo
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
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      functions
        foo @20
          reference: <testLibraryFragment>::@function::foo
          enclosingElement3: <testLibraryFragment>
          returnType: void
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      accessors
        augment static get foo @37
          reference: <testLibrary>::@fragment::package:test/a.dart::@getterAugmentation::foo
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
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
          element: <testLibrary>::@function::foo
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      getters
        augment get foo @37
          reference: <testLibrary>::@fragment::package:test/a.dart::@getterAugmentation::foo
          element: <testLibrary>::@fragment::package:test/a.dart::@getterAugmentation::foo#element
  getters
    static get foo
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@getterAugmentation::foo
  functions
    foo
      reference: <testLibrary>::@function::foo
      firstFragment: <testLibraryFragment>::@function::foo
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
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      topLevelVariables
        synthetic static foo @-1
          reference: <testLibraryFragment>::@topLevelVariable::foo
          enclosingElement3: <testLibraryFragment>
          type: int
          id: variable_0
          getter: getter_0
      accessors
        static get foo @23
          reference: <testLibraryFragment>::@getter::foo
          enclosingElement3: <testLibraryFragment>
          returnType: int
          id: getter_0
          variable: variable_0
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@getterAugmentation::foo
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      accessors
        augment static get foo @37
          reference: <testLibrary>::@fragment::package:test/a.dart::@getterAugmentation::foo
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          returnType: int
          id: getter_1
          variable: <null>
          augmentationTarget: <testLibraryFragment>::@getter::foo
  exportedReferences
    declared <testLibraryFragment>::@getter::foo
  exportNamespace
    foo: <testLibrary>::@fragment::package:test/a.dart::@getterAugmentation::foo
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      topLevelVariables
        synthetic foo (offset=-1)
          reference: <testLibraryFragment>::@topLevelVariable::foo
          element: <testLibrary>::@topLevelVariable::foo
          getter2: <testLibraryFragment>::@getter::foo
      getters
        get foo @23
          reference: <testLibraryFragment>::@getter::foo
          element: <testLibraryFragment>::@getter::foo#element
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@getterAugmentation::foo
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      getters
        augment get foo @37
          reference: <testLibrary>::@fragment::package:test/a.dart::@getterAugmentation::foo
          element: <testLibraryFragment>::@getter::foo#element
          previousFragment: <testLibraryFragment>::@getter::foo
  topLevelVariables
    synthetic foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo
      type: int
      getter: <testLibraryFragment>::@getter::foo#element
  getters
    static get foo
      firstFragment: <testLibraryFragment>::@getter::foo
  exportedReferences
    declared <testLibraryFragment>::@getter::foo
  exportNamespace
    foo: <testLibrary>::@fragment::package:test/a.dart::@getterAugmentation::foo
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
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      accessors
        augment static get foo @37
          reference: <testLibrary>::@fragment::package:test/a.dart::@getterAugmentation::foo
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
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
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      getters
        augment get foo @37
          reference: <testLibrary>::@fragment::package:test/a.dart::@getterAugmentation::foo
          element: <testLibrary>::@fragment::package:test/a.dart::@getterAugmentation::foo#element
  getters
    static get foo
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
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      topLevelVariables
        synthetic static foo @-1
          reference: <testLibraryFragment>::@topLevelVariable::foo
          enclosingElement3: <testLibraryFragment>
          type: int
          id: variable_0
          setter: setter_0
      accessors
        static set foo= @19
          reference: <testLibraryFragment>::@setter::foo
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _ @27
              type: int
          returnType: void
          id: setter_0
          variable: variable_0
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      accessors
        augment static get foo @37
          reference: <testLibrary>::@fragment::package:test/a.dart::@getterAugmentation::foo
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
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
        synthetic foo (offset=-1)
          reference: <testLibraryFragment>::@topLevelVariable::foo
          element: <testLibrary>::@topLevelVariable::foo
          setter2: <testLibraryFragment>::@setter::foo
      setters
        set foo @19
          reference: <testLibraryFragment>::@setter::foo
          element: <testLibraryFragment>::@setter::foo#element
          formalParameters
            _ @27
              element: <testLibraryFragment>::@setter::foo::@parameter::_#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      getters
        augment get foo @37
          reference: <testLibrary>::@fragment::package:test/a.dart::@getterAugmentation::foo
          element: <testLibrary>::@fragment::package:test/a.dart::@getterAugmentation::foo#element
  topLevelVariables
    synthetic foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo
      type: int
      setter: <testLibraryFragment>::@setter::foo#element
  getters
    static get foo
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@getterAugmentation::foo
  setters
    static set foo
      firstFragment: <testLibraryFragment>::@setter::foo
      formalParameters
        requiredPositional _
          type: int
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
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      topLevelVariables
        static foo @19
          reference: <testLibraryFragment>::@topLevelVariable::foo
          enclosingElement3: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: true
          id: variable_0
          getter: getter_0
          setter: setter_0
      accessors
        synthetic static get foo @-1
          reference: <testLibraryFragment>::@getter::foo
          enclosingElement3: <testLibraryFragment>
          returnType: int
          id: getter_0
          variable: variable_0
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@getterAugmentation::foo
        synthetic static set foo= @-1
          reference: <testLibraryFragment>::@setter::foo
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _foo @-1
              type: int
          returnType: void
          id: setter_0
          variable: variable_0
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      accessors
        augment static get foo @37
          reference: <testLibrary>::@fragment::package:test/a.dart::@getterAugmentation::foo
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          returnType: int
          id: getter_1
          variable: <null>
          augmentationTarget: <testLibraryFragment>::@getter::foo
  exportedReferences
    declared <testLibraryFragment>::@getter::foo
    declared <testLibraryFragment>::@setter::foo
  exportNamespace
    foo: <testLibrary>::@fragment::package:test/a.dart::@getterAugmentation::foo
    foo=: <testLibraryFragment>::@setter::foo
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      topLevelVariables
        hasInitializer foo @19
          reference: <testLibraryFragment>::@topLevelVariable::foo
          element: <testLibrary>::@topLevelVariable::foo
          getter2: <testLibraryFragment>::@getter::foo
          setter2: <testLibraryFragment>::@setter::foo
      getters
        synthetic get foo
          reference: <testLibraryFragment>::@getter::foo
          element: <testLibraryFragment>::@getter::foo#element
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@getterAugmentation::foo
      setters
        synthetic set foo
          reference: <testLibraryFragment>::@setter::foo
          element: <testLibraryFragment>::@setter::foo#element
          formalParameters
            _foo
              element: <testLibraryFragment>::@setter::foo::@parameter::_foo#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      getters
        augment get foo @37
          reference: <testLibrary>::@fragment::package:test/a.dart::@getterAugmentation::foo
          element: <testLibraryFragment>::@getter::foo#element
          previousFragment: <testLibraryFragment>::@getter::foo
  topLevelVariables
    hasInitializer foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo
      type: int
      getter: <testLibraryFragment>::@getter::foo#element
      setter: <testLibraryFragment>::@setter::foo#element
  getters
    synthetic static get foo
      firstFragment: <testLibraryFragment>::@getter::foo
  setters
    synthetic static set foo
      firstFragment: <testLibraryFragment>::@setter::foo
      formalParameters
        requiredPositional _foo
          type: int
  exportedReferences
    declared <testLibraryFragment>::@getter::foo
    declared <testLibraryFragment>::@setter::foo
  exportNamespace
    foo: <testLibrary>::@fragment::package:test/a.dart::@getterAugmentation::foo
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
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      classes
        class foo @21
          reference: <testLibraryFragment>::@class::foo
          enclosingElement3: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::foo::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::foo
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      accessors
        augment static set foo= @33
          reference: <testLibrary>::@fragment::package:test/a.dart::@setterAugmentation::foo
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
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
          element: <testLibrary>::@class::foo
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::foo::@constructor::new
              element: <testLibraryFragment>::@class::foo::@constructor::new#element
              typeName: foo
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      setters
        augment set foo @33
          reference: <testLibrary>::@fragment::package:test/a.dart::@setterAugmentation::foo
          element: <testLibrary>::@fragment::package:test/a.dart::@setterAugmentation::foo#element
          formalParameters
            _ @41
              element: <testLibrary>::@fragment::package:test/a.dart::@setterAugmentation::foo::@parameter::_#element
  classes
    class foo
      reference: <testLibrary>::@class::foo
      firstFragment: <testLibraryFragment>::@class::foo
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::foo::@constructor::new
  setters
    static set foo
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@setterAugmentation::foo
      formalParameters
        requiredPositional _
          type: int
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
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      topLevelVariables
        synthetic static foo @-1
          reference: <testLibraryFragment>::@topLevelVariable::foo
          enclosingElement3: <testLibraryFragment>
          type: int
          id: variable_0
          getter: getter_0
      accessors
        static get foo @23
          reference: <testLibraryFragment>::@getter::foo
          enclosingElement3: <testLibraryFragment>
          returnType: int
          id: getter_0
          variable: variable_0
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      accessors
        augment static set foo= @33
          reference: <testLibrary>::@fragment::package:test/a.dart::@setterAugmentation::foo
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
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
        synthetic foo (offset=-1)
          reference: <testLibraryFragment>::@topLevelVariable::foo
          element: <testLibrary>::@topLevelVariable::foo
          getter2: <testLibraryFragment>::@getter::foo
      getters
        get foo @23
          reference: <testLibraryFragment>::@getter::foo
          element: <testLibraryFragment>::@getter::foo#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      setters
        augment set foo @33
          reference: <testLibrary>::@fragment::package:test/a.dart::@setterAugmentation::foo
          element: <testLibrary>::@fragment::package:test/a.dart::@setterAugmentation::foo#element
          formalParameters
            _ @41
              element: <testLibrary>::@fragment::package:test/a.dart::@setterAugmentation::foo::@parameter::_#element
  topLevelVariables
    synthetic foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo
      type: int
      getter: <testLibraryFragment>::@getter::foo#element
  getters
    static get foo
      firstFragment: <testLibraryFragment>::@getter::foo
  setters
    static set foo
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@setterAugmentation::foo
      formalParameters
        requiredPositional _
          type: int
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
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      accessors
        augment static set foo= @33
          reference: <testLibrary>::@fragment::package:test/a.dart::@setterAugmentation::foo
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
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
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      setters
        augment set foo @33
          reference: <testLibrary>::@fragment::package:test/a.dart::@setterAugmentation::foo
          element: <testLibrary>::@fragment::package:test/a.dart::@setterAugmentation::foo#element
          formalParameters
            _ @41
              element: <testLibrary>::@fragment::package:test/a.dart::@setterAugmentation::foo::@parameter::_#element
  setters
    static set foo
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@setterAugmentation::foo
      formalParameters
        requiredPositional _
          type: int
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
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      topLevelVariables
        synthetic static foo @-1
          reference: <testLibraryFragment>::@topLevelVariable::foo
          enclosingElement3: <testLibraryFragment>
          type: int
          id: variable_0
          setter: setter_0
      accessors
        static set foo= @19
          reference: <testLibraryFragment>::@setter::foo
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _ @27
              type: int
          returnType: void
          id: setter_0
          variable: variable_0
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@setterAugmentation::foo
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      accessors
        augment static set foo= @33
          reference: <testLibrary>::@fragment::package:test/a.dart::@setterAugmentation::foo
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          parameters
            requiredPositional _ @41
              type: int
          returnType: void
          id: setter_1
          variable: <null>
          augmentationTarget: <testLibraryFragment>::@setter::foo
  exportedReferences
    declared <testLibraryFragment>::@setter::foo
  exportNamespace
    foo=: <testLibrary>::@fragment::package:test/a.dart::@setterAugmentation::foo
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      topLevelVariables
        synthetic foo (offset=-1)
          reference: <testLibraryFragment>::@topLevelVariable::foo
          element: <testLibrary>::@topLevelVariable::foo
          setter2: <testLibraryFragment>::@setter::foo
      setters
        set foo @19
          reference: <testLibraryFragment>::@setter::foo
          element: <testLibraryFragment>::@setter::foo#element
          formalParameters
            _ @27
              element: <testLibraryFragment>::@setter::foo::@parameter::_#element
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@setterAugmentation::foo
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      setters
        augment set foo @33
          reference: <testLibrary>::@fragment::package:test/a.dart::@setterAugmentation::foo
          element: <testLibraryFragment>::@setter::foo#element
          formalParameters
            _ @41
              element: <testLibrary>::@fragment::package:test/a.dart::@setterAugmentation::foo::@parameter::_#element
          previousFragment: <testLibraryFragment>::@setter::foo
  topLevelVariables
    synthetic foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo
      type: int
      setter: <testLibraryFragment>::@setter::foo#element
  setters
    static set foo
      firstFragment: <testLibraryFragment>::@setter::foo
      formalParameters
        requiredPositional _
          type: int
  exportedReferences
    declared <testLibraryFragment>::@setter::foo
  exportNamespace
    foo=: <testLibrary>::@fragment::package:test/a.dart::@setterAugmentation::foo
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
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      topLevelVariables
        static foo @19
          reference: <testLibraryFragment>::@topLevelVariable::foo
          enclosingElement3: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: true
          id: variable_0
          getter: getter_0
          setter: setter_0
      accessors
        synthetic static get foo @-1
          reference: <testLibraryFragment>::@getter::foo
          enclosingElement3: <testLibraryFragment>
          returnType: int
          id: getter_0
          variable: variable_0
        synthetic static set foo= @-1
          reference: <testLibraryFragment>::@setter::foo
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _foo @-1
              type: int
          returnType: void
          id: setter_0
          variable: variable_0
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@setterAugmentation::foo
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      accessors
        augment static set foo= @33
          reference: <testLibrary>::@fragment::package:test/a.dart::@setterAugmentation::foo
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          parameters
            requiredPositional _ @41
              type: int
          returnType: void
          id: setter_1
          variable: <null>
          augmentationTarget: <testLibraryFragment>::@setter::foo
  exportedReferences
    declared <testLibraryFragment>::@getter::foo
    declared <testLibraryFragment>::@setter::foo
  exportNamespace
    foo: <testLibraryFragment>::@getter::foo
    foo=: <testLibrary>::@fragment::package:test/a.dart::@setterAugmentation::foo
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      topLevelVariables
        hasInitializer foo @19
          reference: <testLibraryFragment>::@topLevelVariable::foo
          element: <testLibrary>::@topLevelVariable::foo
          getter2: <testLibraryFragment>::@getter::foo
          setter2: <testLibraryFragment>::@setter::foo
      getters
        synthetic get foo
          reference: <testLibraryFragment>::@getter::foo
          element: <testLibraryFragment>::@getter::foo#element
      setters
        synthetic set foo
          reference: <testLibraryFragment>::@setter::foo
          element: <testLibraryFragment>::@setter::foo#element
          formalParameters
            _foo
              element: <testLibraryFragment>::@setter::foo::@parameter::_foo#element
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@setterAugmentation::foo
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      setters
        augment set foo @33
          reference: <testLibrary>::@fragment::package:test/a.dart::@setterAugmentation::foo
          element: <testLibraryFragment>::@setter::foo#element
          formalParameters
            _ @41
              element: <testLibrary>::@fragment::package:test/a.dart::@setterAugmentation::foo::@parameter::_#element
          previousFragment: <testLibraryFragment>::@setter::foo
  topLevelVariables
    hasInitializer foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo
      type: int
      getter: <testLibraryFragment>::@getter::foo#element
      setter: <testLibraryFragment>::@setter::foo#element
  getters
    synthetic static get foo
      firstFragment: <testLibraryFragment>::@getter::foo
  setters
    synthetic static set foo
      firstFragment: <testLibraryFragment>::@setter::foo
      formalParameters
        requiredPositional _foo
          type: int
  exportedReferences
    declared <testLibraryFragment>::@getter::foo
    declared <testLibraryFragment>::@setter::foo
  exportNamespace
    foo: <testLibraryFragment>::@getter::foo
    foo=: <testLibrary>::@fragment::package:test/a.dart::@setterAugmentation::foo
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
