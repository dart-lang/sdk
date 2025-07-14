// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../dart/resolution/node_text_expectations.dart';
import '../elements_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FormalParameterElementTest_keepLinking);
    defineReflectiveTests(FormalParameterElementTest_fromBytes);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

abstract class FormalParameterElementTest extends ElementsBaseTest {
  test_parameter() async {
    var library = await buildLibrary('void main(int p) {}');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      functions
        #F1 main @5
          element: <testLibrary>::@function::main
          formalParameters
            #F2 p @14
              element: <testLibrary>::@function::main::@formalParameter::p
  functions
    main
      reference: <testLibrary>::@function::main
      firstFragment: #F1
      formalParameters
        #E0 requiredPositional p
          firstFragment: #F2
          type: int
      returnType: void
''');
  }

  test_parameter_covariant_explicit_named() async {
    var library = await buildLibrary('''
class A {
  void m({covariant A a}) {}
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A @6
          element: <testLibrary>::@class::A
          constructors
            #F2 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          methods
            #F3 m @17
              element: <testLibrary>::@class::A::@method::m
              formalParameters
                #F4 a @32
                  element: <testLibrary>::@class::A::@method::m::@formalParameter::a
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
      methods
        m
          reference: <testLibrary>::@class::A::@method::m
          firstFragment: #F3
          formalParameters
            #E0 optionalNamed covariant a
              firstFragment: #F4
              type: A
          returnType: void
''');
  }

  test_parameter_covariant_explicit_positional() async {
    var library = await buildLibrary('''
class A {
  void m([covariant A a]) {}
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A @6
          element: <testLibrary>::@class::A
          constructors
            #F2 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          methods
            #F3 m @17
              element: <testLibrary>::@class::A::@method::m
              formalParameters
                #F4 a @32
                  element: <testLibrary>::@class::A::@method::m::@formalParameter::a
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
      methods
        m
          reference: <testLibrary>::@class::A::@method::m
          firstFragment: #F3
          formalParameters
            #E0 optionalPositional covariant a
              firstFragment: #F4
              type: A
          returnType: void
''');
  }

  test_parameter_covariant_explicit_required() async {
    var library = await buildLibrary('''
class A {
  void m(covariant A a) {}
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A @6
          element: <testLibrary>::@class::A
          constructors
            #F2 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          methods
            #F3 m @17
              element: <testLibrary>::@class::A::@method::m
              formalParameters
                #F4 a @31
                  element: <testLibrary>::@class::A::@method::m::@formalParameter::a
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
      methods
        m
          reference: <testLibrary>::@class::A::@method::m
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional covariant a
              firstFragment: #F4
              type: A
          returnType: void
''');
  }

  test_parameter_covariant_inherited() async {
    var library = await buildLibrary(r'''
class A<T> {
  void f(covariant T t) {}
}
class B<T> extends A<T> {
  void f(T t) {}
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A @6
          element: <testLibrary>::@class::A
          typeParameters
            #F2 T @8
              element: #E0 T
          constructors
            #F3 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          methods
            #F4 f @20
              element: <testLibrary>::@class::A::@method::f
              formalParameters
                #F5 t @34
                  element: <testLibrary>::@class::A::@method::f::@formalParameter::t
        #F6 class B @48
          element: <testLibrary>::@class::B
          typeParameters
            #F7 T @50
              element: #E1 T
          constructors
            #F8 synthetic new
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          methods
            #F9 f @75
              element: <testLibrary>::@class::B::@method::f
              formalParameters
                #F10 t @79
                  element: <testLibrary>::@class::B::@method::f::@formalParameter::t
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
      methods
        f
          reference: <testLibrary>::@class::A::@method::f
          firstFragment: #F4
          hasEnclosingTypeParameterReference: true
          formalParameters
            #E2 requiredPositional covariant t
              firstFragment: #F5
              type: T
          returnType: void
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F6
      typeParameters
        #E1 T
          firstFragment: #F7
      supertype: A<T>
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F8
          superConstructor: ConstructorMember
            baseElement: <testLibrary>::@class::A::@constructor::new
            substitution: {T: T}
      methods
        f
          reference: <testLibrary>::@class::B::@method::f
          firstFragment: #F9
          hasEnclosingTypeParameterReference: true
          formalParameters
            #E3 requiredPositional covariant t
              firstFragment: #F10
              type: T
          returnType: void
''');
  }

  test_parameter_covariant_inherited_named() async {
    var library = await buildLibrary('''
class A {
  void m({covariant A a}) {}
}
class B extends A {
  void m({B a}) {}
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A @6
          element: <testLibrary>::@class::A
          constructors
            #F2 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          methods
            #F3 m @17
              element: <testLibrary>::@class::A::@method::m
              formalParameters
                #F4 a @32
                  element: <testLibrary>::@class::A::@method::m::@formalParameter::a
        #F5 class B @47
          element: <testLibrary>::@class::B
          constructors
            #F6 synthetic new
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          methods
            #F7 m @68
              element: <testLibrary>::@class::B::@method::m
              formalParameters
                #F8 a @73
                  element: <testLibrary>::@class::B::@method::m::@formalParameter::a
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
      methods
        m
          reference: <testLibrary>::@class::A::@method::m
          firstFragment: #F3
          formalParameters
            #E0 optionalNamed covariant a
              firstFragment: #F4
              type: A
          returnType: void
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F5
      supertype: A
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F6
          superConstructor: <testLibrary>::@class::A::@constructor::new
      methods
        m
          reference: <testLibrary>::@class::B::@method::m
          firstFragment: #F7
          formalParameters
            #E1 optionalNamed covariant a
              firstFragment: #F8
              type: B
          returnType: void
''');
  }

  test_parameter_parameters() async {
    var library = await buildLibrary('class C { f(g(x, y)) {} }');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class C @6
          element: <testLibrary>::@class::C
          constructors
            #F2 synthetic new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          methods
            #F3 f @10
              element: <testLibrary>::@class::C::@method::f
              formalParameters
                #F4 g @12
                  element: <testLibrary>::@class::C::@method::f::@formalParameter::g
                  parameters
                    #F5 x @14
                      element: x@14
                    #F6 y @17
                      element: y@17
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
      methods
        f
          reference: <testLibrary>::@class::C::@method::f
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional g
              firstFragment: #F4
              type: dynamic Function(dynamic, dynamic)
              formalParameters
                #E1 requiredPositional hasImplicitType x
                  firstFragment: #F5
                  type: dynamic
                #E2 requiredPositional hasImplicitType y
                  firstFragment: #F6
                  type: dynamic
          returnType: dynamic
''');
  }

  test_parameter_parameters_in_generic_class() async {
    var library = await buildLibrary('class C<A, B> { f(A g(B x)) {} }');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class C @6
          element: <testLibrary>::@class::C
          typeParameters
            #F2 A @8
              element: #E0 A
            #F3 B @11
              element: #E1 B
          constructors
            #F4 synthetic new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          methods
            #F5 f @16
              element: <testLibrary>::@class::C::@method::f
              formalParameters
                #F6 g @20
                  element: <testLibrary>::@class::C::@method::f::@formalParameter::g
                  parameters
                    #F7 x @24
                      element: x@24
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      typeParameters
        #E0 A
          firstFragment: #F2
        #E1 B
          firstFragment: #F3
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F4
      methods
        f
          reference: <testLibrary>::@class::C::@method::f
          firstFragment: #F5
          hasEnclosingTypeParameterReference: true
          formalParameters
            #E2 requiredPositional g
              firstFragment: #F6
              type: A Function(B)
              formalParameters
                #E3 requiredPositional x
                  firstFragment: #F7
                  type: B
          returnType: dynamic
''');
  }

  test_parameter_return_type() async {
    var library = await buildLibrary('class C { f(int g()) {} }');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class C @6
          element: <testLibrary>::@class::C
          constructors
            #F2 synthetic new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          methods
            #F3 f @10
              element: <testLibrary>::@class::C::@method::f
              formalParameters
                #F4 g @16
                  element: <testLibrary>::@class::C::@method::f::@formalParameter::g
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
      methods
        f
          reference: <testLibrary>::@class::C::@method::f
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional g
              firstFragment: #F4
              type: int Function()
          returnType: dynamic
''');
  }

  test_parameter_return_type_void() async {
    var library = await buildLibrary('class C { f(void g()) {} }');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class C @6
          element: <testLibrary>::@class::C
          constructors
            #F2 synthetic new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          methods
            #F3 f @10
              element: <testLibrary>::@class::C::@method::f
              formalParameters
                #F4 g @17
                  element: <testLibrary>::@class::C::@method::f::@formalParameter::g
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
      methods
        f
          reference: <testLibrary>::@class::C::@method::f
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional g
              firstFragment: #F4
              type: void Function()
          returnType: dynamic
''');
  }

  test_parameter_typeParameters() async {
    var library = await buildLibrary(r'''
void f(T a<T, U>(U u)) {}
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
              typeParameters
                #F3 T @11
                  element: #E0 T
                #F4 U @14
                  element: #E1 U
              parameters
                #F5 u @19
                  element: u@19
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: #F1
      formalParameters
        #E2 requiredPositional a
          firstFragment: #F2
          type: T Function<T, U>(U)
          typeParameters
            #E0 T
              firstFragment: #F3
            #E1 U
              firstFragment: #F4
          formalParameters
            #E3 requiredPositional u
              firstFragment: #F5
              type: U
      returnType: void
''');
  }

  test_parameterTypeNotInferred_constructor() async {
    // Strong mode doesn't do type inference on constructor parameters, so it's
    // ok that we don't store inferred type info for them in summaries.
    var library = await buildLibrary('''
class C {
  C.positional([x = 1]);
  C.named({x: 1});
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class C @6
          element: <testLibrary>::@class::C
          constructors
            #F2 positional @14
              element: <testLibrary>::@class::C::@constructor::positional
              typeName: C
              typeNameOffset: 12
              periodOffset: 13
              formalParameters
                #F3 x @26
                  element: <testLibrary>::@class::C::@constructor::positional::@formalParameter::x
                  initializer: expression_0
                    IntegerLiteral
                      literal: 1 @30
                      staticType: int
            #F4 named @39
              element: <testLibrary>::@class::C::@constructor::named
              typeName: C
              typeNameOffset: 37
              periodOffset: 38
              formalParameters
                #F5 x @46
                  element: <testLibrary>::@class::C::@constructor::named::@formalParameter::x
                  initializer: expression_1
                    IntegerLiteral
                      literal: 1 @49
                      staticType: int
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      constructors
        positional
          reference: <testLibrary>::@class::C::@constructor::positional
          firstFragment: #F2
          formalParameters
            #E0 optionalPositional hasImplicitType x
              firstFragment: #F3
              type: dynamic
              constantInitializer
                fragment: #F3
                expression: expression_0
        named
          reference: <testLibrary>::@class::C::@constructor::named
          firstFragment: #F4
          formalParameters
            #E1 optionalNamed hasImplicitType x
              firstFragment: #F5
              type: dynamic
              constantInitializer
                fragment: #F5
                expression: expression_1
''');
  }

  test_parameterTypeNotInferred_initializingFormal() async {
    // Strong mode doesn't do type inference on initializing formals, so it's
    // ok that we don't store inferred type info for them in summaries.
    var library = await buildLibrary('''
class C {
  var x;
  C.positional([this.x = 1]);
  C.named({this.x: 1});
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class C @6
          element: <testLibrary>::@class::C
          fields
            #F2 x @16
              element: <testLibrary>::@class::C::@field::x
          constructors
            #F3 positional @23
              element: <testLibrary>::@class::C::@constructor::positional
              typeName: C
              typeNameOffset: 21
              periodOffset: 22
              formalParameters
                #F4 this.x @40
                  element: <testLibrary>::@class::C::@constructor::positional::@formalParameter::x
                  initializer: expression_0
                    IntegerLiteral
                      literal: 1 @44
                      staticType: int
            #F5 named @53
              element: <testLibrary>::@class::C::@constructor::named
              typeName: C
              typeNameOffset: 51
              periodOffset: 52
              formalParameters
                #F6 this.x @65
                  element: <testLibrary>::@class::C::@constructor::named::@formalParameter::x
                  initializer: expression_1
                    IntegerLiteral
                      literal: 1 @68
                      staticType: int
          getters
            #F7 synthetic x
              element: <testLibrary>::@class::C::@getter::x
          setters
            #F8 synthetic x
              element: <testLibrary>::@class::C::@setter::x
              formalParameters
                #F9 _x
                  element: <testLibrary>::@class::C::@setter::x::@formalParameter::_x
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        x
          reference: <testLibrary>::@class::C::@field::x
          firstFragment: #F2
          type: dynamic
          getter: <testLibrary>::@class::C::@getter::x
          setter: <testLibrary>::@class::C::@setter::x
      constructors
        positional
          reference: <testLibrary>::@class::C::@constructor::positional
          firstFragment: #F3
          formalParameters
            #E0 optionalPositional final hasImplicitType x
              firstFragment: #F4
              type: dynamic
              constantInitializer
                fragment: #F4
                expression: expression_0
        named
          reference: <testLibrary>::@class::C::@constructor::named
          firstFragment: #F5
          formalParameters
            #E1 optionalNamed final hasImplicitType x
              firstFragment: #F6
              type: dynamic
              constantInitializer
                fragment: #F6
                expression: expression_1
      getters
        synthetic x
          reference: <testLibrary>::@class::C::@getter::x
          firstFragment: #F7
          returnType: dynamic
          variable: <testLibrary>::@class::C::@field::x
      setters
        synthetic x
          reference: <testLibrary>::@class::C::@setter::x
          firstFragment: #F8
          formalParameters
            #E2 requiredPositional _x
              firstFragment: #F9
              type: dynamic
          returnType: void
''');
  }

  test_parameterTypeNotInferred_staticMethod() async {
    // Strong mode doesn't do type inference on parameters of static methods,
    // so it's ok that we don't store inferred type info for them in summaries.
    var library = await buildLibrary('''
class C {
  static void positional([x = 1]) {}
  static void named({x: 1}) {}
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class C @6
          element: <testLibrary>::@class::C
          constructors
            #F2 synthetic new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          methods
            #F3 positional @24
              element: <testLibrary>::@class::C::@method::positional
              formalParameters
                #F4 x @36
                  element: <testLibrary>::@class::C::@method::positional::@formalParameter::x
                  initializer: expression_0
                    IntegerLiteral
                      literal: 1 @40
                      staticType: int
            #F5 named @61
              element: <testLibrary>::@class::C::@method::named
              formalParameters
                #F6 x @68
                  element: <testLibrary>::@class::C::@method::named::@formalParameter::x
                  initializer: expression_1
                    IntegerLiteral
                      literal: 1 @71
                      staticType: int
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
      methods
        static positional
          reference: <testLibrary>::@class::C::@method::positional
          firstFragment: #F3
          formalParameters
            #E0 optionalPositional hasImplicitType x
              firstFragment: #F4
              type: dynamic
              constantInitializer
                fragment: #F4
                expression: expression_0
          returnType: void
        static named
          reference: <testLibrary>::@class::C::@method::named
          firstFragment: #F5
          formalParameters
            #E1 optionalNamed hasImplicitType x
              firstFragment: #F6
              type: dynamic
              constantInitializer
                fragment: #F6
                expression: expression_1
          returnType: void
''');
  }

  test_parameterTypeNotInferred_topLevelFunction() async {
    // Strong mode doesn't do type inference on parameters of top level
    // functions, so it's ok that we don't store inferred type info for them in
    // summaries.
    var library = await buildLibrary('''
void positional([x = 1]) {}
void named({x: 1}) {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      functions
        #F1 positional @5
          element: <testLibrary>::@function::positional
          formalParameters
            #F2 x @17
              element: <testLibrary>::@function::positional::@formalParameter::x
              initializer: expression_0
                IntegerLiteral
                  literal: 1 @21
                  staticType: int
        #F3 named @33
          element: <testLibrary>::@function::named
          formalParameters
            #F4 x @40
              element: <testLibrary>::@function::named::@formalParameter::x
              initializer: expression_1
                IntegerLiteral
                  literal: 1 @43
                  staticType: int
  functions
    positional
      reference: <testLibrary>::@function::positional
      firstFragment: #F1
      formalParameters
        #E0 optionalPositional hasImplicitType x
          firstFragment: #F2
          type: dynamic
          constantInitializer
            fragment: #F2
            expression: expression_0
      returnType: void
    named
      reference: <testLibrary>::@function::named
      firstFragment: #F3
      formalParameters
        #E1 optionalNamed hasImplicitType x
          firstFragment: #F4
          type: dynamic
          constantInitializer
            fragment: #F4
            expression: expression_1
      returnType: void
''');
  }
}

@reflectiveTest
class FormalParameterElementTest_fromBytes extends FormalParameterElementTest {
  @override
  bool get keepLinkingLibraries => false;
}

@reflectiveTest
class FormalParameterElementTest_keepLinking
    extends FormalParameterElementTest {
  @override
  bool get keepLinkingLibraries => true;
}
