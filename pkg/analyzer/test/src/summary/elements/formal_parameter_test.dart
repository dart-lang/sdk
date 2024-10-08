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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      functions
        main @5
          reference: <testLibraryFragment>::@function::main
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional p @14
              type: int
          returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      functions
        main @5
          reference: <testLibraryFragment>::@function::main
          element: <testLibraryFragment>::@function::main#element
          formalParameters
            p @14
              element: <testLibraryFragment>::@function::main::@parameter::p#element
  functions
    main
      firstFragment: <testLibraryFragment>::@function::main
      formalParameters
        requiredPositional p
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::A
          methods
            m @17
              reference: <testLibraryFragment>::@class::A::@method::m
              enclosingElement3: <testLibraryFragment>::@class::A
              parameters
                optionalNamed default covariant a @32
                  reference: <testLibraryFragment>::@class::A::@method::m::@parameter::a
                  type: A
              returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A#element
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <testLibraryFragment>::@class::A::@constructor::new#element
          methods
            m @17
              reference: <testLibraryFragment>::@class::A::@method::m
              element: <testLibraryFragment>::@class::A::@method::m#element
              formalParameters
                default a @32
                  reference: <testLibraryFragment>::@class::A::@method::m::@parameter::a
                  element: <testLibraryFragment>::@class::A::@method::m::@parameter::a#element
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
      methods
        m
          firstFragment: <testLibraryFragment>::@class::A::@method::m
          formalParameters
            optionalNamed covariant a
              firstFragment: <testLibraryFragment>::@class::A::@method::m::@parameter::a
              type: A
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::A
          methods
            m @17
              reference: <testLibraryFragment>::@class::A::@method::m
              enclosingElement3: <testLibraryFragment>::@class::A
              parameters
                optionalPositional default covariant a @32
                  type: A
              returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A#element
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <testLibraryFragment>::@class::A::@constructor::new#element
          methods
            m @17
              reference: <testLibraryFragment>::@class::A::@method::m
              element: <testLibraryFragment>::@class::A::@method::m#element
              formalParameters
                default a @32
                  element: <testLibraryFragment>::@class::A::@method::m::@parameter::a#element
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
      methods
        m
          firstFragment: <testLibraryFragment>::@class::A::@method::m
          formalParameters
            optionalPositional covariant a
              type: A
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::A
          methods
            m @17
              reference: <testLibraryFragment>::@class::A::@method::m
              enclosingElement3: <testLibraryFragment>::@class::A
              parameters
                requiredPositional covariant a @31
                  type: A
              returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A#element
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <testLibraryFragment>::@class::A::@constructor::new#element
          methods
            m @17
              reference: <testLibraryFragment>::@class::A::@method::m
              element: <testLibraryFragment>::@class::A::@method::m#element
              formalParameters
                a @31
                  element: <testLibraryFragment>::@class::A::@method::m::@parameter::a#element
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
      methods
        m
          firstFragment: <testLibraryFragment>::@class::A::@method::m
          formalParameters
            requiredPositional covariant a
              type: A
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant T @8
              defaultType: dynamic
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::A
          methods
            f @20
              reference: <testLibraryFragment>::@class::A::@method::f
              enclosingElement3: <testLibraryFragment>::@class::A
              parameters
                requiredPositional covariant t @34
                  type: T
              returnType: void
        class B @48
          reference: <testLibraryFragment>::@class::B
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant T @50
              defaultType: dynamic
          supertype: A<T>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::B::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::B
              superConstructor: ConstructorMember
                base: <testLibraryFragment>::@class::A::@constructor::new
                substitution: {T: T}
          methods
            f @75
              reference: <testLibraryFragment>::@class::B::@method::f
              enclosingElement3: <testLibraryFragment>::@class::B
              parameters
                requiredPositional covariant t @79
                  type: T
              returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A#element
          typeParameters
            T @8
              element: <not-implemented>
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <testLibraryFragment>::@class::A::@constructor::new#element
          methods
            f @20
              reference: <testLibraryFragment>::@class::A::@method::f
              element: <testLibraryFragment>::@class::A::@method::f#element
              formalParameters
                t @34
                  element: <testLibraryFragment>::@class::A::@method::f::@parameter::t#element
        class B @48
          reference: <testLibraryFragment>::@class::B
          element: <testLibraryFragment>::@class::B#element
          typeParameters
            T @50
              element: <not-implemented>
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::B::@constructor::new
              element: <testLibraryFragment>::@class::B::@constructor::new#element
              superConstructor: ConstructorMember
                base: <testLibraryFragment>::@class::A::@constructor::new
                substitution: {T: T}
          methods
            f @75
              reference: <testLibraryFragment>::@class::B::@method::f
              element: <testLibraryFragment>::@class::B::@method::f#element
              formalParameters
                t @79
                  element: <testLibraryFragment>::@class::B::@method::f::@parameter::t#element
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
      typeParameters
        T
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
      methods
        f
          firstFragment: <testLibraryFragment>::@class::A::@method::f
          formalParameters
            requiredPositional covariant t
              type: T
    class B
      firstFragment: <testLibraryFragment>::@class::B
      typeParameters
        T
      supertype: A<T>
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::B::@constructor::new
          superConstructor: <testLibraryFragment>::@class::A::@constructor::new#element
      methods
        f
          firstFragment: <testLibraryFragment>::@class::B::@method::f
          formalParameters
            requiredPositional covariant t
              type: T
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::A
          methods
            m @17
              reference: <testLibraryFragment>::@class::A::@method::m
              enclosingElement3: <testLibraryFragment>::@class::A
              parameters
                optionalNamed default covariant a @32
                  reference: <testLibraryFragment>::@class::A::@method::m::@parameter::a
                  type: A
              returnType: void
        class B @47
          reference: <testLibraryFragment>::@class::B
          enclosingElement3: <testLibraryFragment>
          supertype: A
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::B::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::B
              superConstructor: <testLibraryFragment>::@class::A::@constructor::new
          methods
            m @68
              reference: <testLibraryFragment>::@class::B::@method::m
              enclosingElement3: <testLibraryFragment>::@class::B
              parameters
                optionalNamed default covariant a @73
                  reference: <testLibraryFragment>::@class::B::@method::m::@parameter::a
                  type: B
              returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A#element
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <testLibraryFragment>::@class::A::@constructor::new#element
          methods
            m @17
              reference: <testLibraryFragment>::@class::A::@method::m
              element: <testLibraryFragment>::@class::A::@method::m#element
              formalParameters
                default a @32
                  reference: <testLibraryFragment>::@class::A::@method::m::@parameter::a
                  element: <testLibraryFragment>::@class::A::@method::m::@parameter::a#element
        class B @47
          reference: <testLibraryFragment>::@class::B
          element: <testLibraryFragment>::@class::B#element
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::B::@constructor::new
              element: <testLibraryFragment>::@class::B::@constructor::new#element
              superConstructor: <testLibraryFragment>::@class::A::@constructor::new
          methods
            m @68
              reference: <testLibraryFragment>::@class::B::@method::m
              element: <testLibraryFragment>::@class::B::@method::m#element
              formalParameters
                default a @73
                  reference: <testLibraryFragment>::@class::B::@method::m::@parameter::a
                  element: <testLibraryFragment>::@class::B::@method::m::@parameter::a#element
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
      methods
        m
          firstFragment: <testLibraryFragment>::@class::A::@method::m
          formalParameters
            optionalNamed covariant a
              firstFragment: <testLibraryFragment>::@class::A::@method::m::@parameter::a
              type: A
    class B
      firstFragment: <testLibraryFragment>::@class::B
      supertype: A
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::B::@constructor::new
          superConstructor: <testLibraryFragment>::@class::A::@constructor::new#element
      methods
        m
          firstFragment: <testLibraryFragment>::@class::B::@method::m
          formalParameters
            optionalNamed covariant a
              firstFragment: <testLibraryFragment>::@class::B::@method::m::@parameter::a
              type: B
''');
  }

  test_parameter_parameters() async {
    var library = await buildLibrary('class C { f(g(x, y)) {} }');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
          methods
            f @10
              reference: <testLibraryFragment>::@class::C::@method::f
              enclosingElement3: <testLibraryFragment>::@class::C
              parameters
                requiredPositional g @12
                  type: dynamic Function(dynamic, dynamic)
                  parameters
                    requiredPositional x @14
                      type: dynamic
                    requiredPositional y @17
                      type: dynamic
              returnType: dynamic
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C#element
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
          methods
            f @10
              reference: <testLibraryFragment>::@class::C::@method::f
              element: <testLibraryFragment>::@class::C::@method::f#element
              formalParameters
                g @12
                  element: <testLibraryFragment>::@class::C::@method::f::@parameter::g#element
  classes
    class C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      methods
        f
          firstFragment: <testLibraryFragment>::@class::C::@method::f
          formalParameters
            requiredPositional g
              type: dynamic Function(dynamic, dynamic)
              formalParameters
                requiredPositional x
                  type: dynamic
                requiredPositional y
                  type: dynamic
''');
  }

  test_parameter_parameters_in_generic_class() async {
    var library = await buildLibrary('class C<A, B> { f(A g(B x)) {} }');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant A @8
              defaultType: dynamic
            covariant B @11
              defaultType: dynamic
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
          methods
            f @16
              reference: <testLibraryFragment>::@class::C::@method::f
              enclosingElement3: <testLibraryFragment>::@class::C
              parameters
                requiredPositional g @20
                  type: A Function(B)
                  parameters
                    requiredPositional x @24
                      type: B
              returnType: dynamic
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C#element
          typeParameters
            A @8
              element: <not-implemented>
            B @11
              element: <not-implemented>
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
          methods
            f @16
              reference: <testLibraryFragment>::@class::C::@method::f
              element: <testLibraryFragment>::@class::C::@method::f#element
              formalParameters
                g @20
                  element: <testLibraryFragment>::@class::C::@method::f::@parameter::g#element
  classes
    class C
      firstFragment: <testLibraryFragment>::@class::C
      typeParameters
        A
        B
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      methods
        f
          firstFragment: <testLibraryFragment>::@class::C::@method::f
          formalParameters
            requiredPositional g
              type: A Function(B)
              formalParameters
                requiredPositional x
                  type: B
''');
  }

  test_parameter_return_type() async {
    var library = await buildLibrary('class C { f(int g()) {} }');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
          methods
            f @10
              reference: <testLibraryFragment>::@class::C::@method::f
              enclosingElement3: <testLibraryFragment>::@class::C
              parameters
                requiredPositional g @16
                  type: int Function()
              returnType: dynamic
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C#element
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
          methods
            f @10
              reference: <testLibraryFragment>::@class::C::@method::f
              element: <testLibraryFragment>::@class::C::@method::f#element
              formalParameters
                g @16
                  element: <testLibraryFragment>::@class::C::@method::f::@parameter::g#element
  classes
    class C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      methods
        f
          firstFragment: <testLibraryFragment>::@class::C::@method::f
          formalParameters
            requiredPositional g
              type: int Function()
''');
  }

  test_parameter_return_type_void() async {
    var library = await buildLibrary('class C { f(void g()) {} }');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
          methods
            f @10
              reference: <testLibraryFragment>::@class::C::@method::f
              enclosingElement3: <testLibraryFragment>::@class::C
              parameters
                requiredPositional g @17
                  type: void Function()
              returnType: dynamic
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C#element
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
          methods
            f @10
              reference: <testLibraryFragment>::@class::C::@method::f
              element: <testLibraryFragment>::@class::C::@method::f#element
              formalParameters
                g @17
                  element: <testLibraryFragment>::@class::C::@method::f::@parameter::g#element
  classes
    class C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      methods
        f
          firstFragment: <testLibraryFragment>::@class::C::@method::f
          formalParameters
            requiredPositional g
              type: void Function()
''');
  }

  test_parameter_typeParameters() async {
    var library = await buildLibrary(r'''
void f(T a<T, U>(U u)) {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      functions
        f @5
          reference: <testLibraryFragment>::@function::f
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional a @9
              type: T Function<T, U>(U)
              typeParameters
                covariant T @11
                covariant U @14
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
          element: <testLibraryFragment>::@function::f#element
          formalParameters
            a @9
              element: <testLibraryFragment>::@function::f::@parameter::a#element
  functions
    f
      firstFragment: <testLibraryFragment>::@function::f
      formalParameters
        requiredPositional a
          type: T Function<T, U>(U)
          formalParameters
            requiredPositional u
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          constructors
            positional @14
              reference: <testLibraryFragment>::@class::C::@constructor::positional
              enclosingElement3: <testLibraryFragment>::@class::C
              periodOffset: 13
              nameEnd: 24
              parameters
                optionalPositional default x @26
                  type: dynamic
                  constantInitializer
                    IntegerLiteral
                      literal: 1 @30
                      staticType: int
            named @39
              reference: <testLibraryFragment>::@class::C::@constructor::named
              enclosingElement3: <testLibraryFragment>::@class::C
              periodOffset: 38
              nameEnd: 44
              parameters
                optionalNamed default x @46
                  reference: <testLibraryFragment>::@class::C::@constructor::named::@parameter::x
                  type: dynamic
                  constantInitializer
                    IntegerLiteral
                      literal: 1 @49
                      staticType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C#element
          constructors
            positional @14
              reference: <testLibraryFragment>::@class::C::@constructor::positional
              element: <testLibraryFragment>::@class::C::@constructor::positional#element
              periodOffset: 13
              nameEnd: 24
              formalParameters
                default x @26
                  element: <testLibraryFragment>::@class::C::@constructor::positional::@parameter::x#element
            named @39
              reference: <testLibraryFragment>::@class::C::@constructor::named
              element: <testLibraryFragment>::@class::C::@constructor::named#element
              periodOffset: 38
              nameEnd: 44
              formalParameters
                default x @46
                  reference: <testLibraryFragment>::@class::C::@constructor::named::@parameter::x
                  element: <testLibraryFragment>::@class::C::@constructor::named::@parameter::x#element
  classes
    class C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        positional
          firstFragment: <testLibraryFragment>::@class::C::@constructor::positional
          formalParameters
            optionalPositional x
              type: dynamic
        named
          firstFragment: <testLibraryFragment>::@class::C::@constructor::named
          formalParameters
            optionalNamed x
              firstFragment: <testLibraryFragment>::@class::C::@constructor::named::@parameter::x
              type: dynamic
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          fields
            x @16
              reference: <testLibraryFragment>::@class::C::@field::x
              enclosingElement3: <testLibraryFragment>::@class::C
              type: dynamic
          constructors
            positional @23
              reference: <testLibraryFragment>::@class::C::@constructor::positional
              enclosingElement3: <testLibraryFragment>::@class::C
              periodOffset: 22
              nameEnd: 33
              parameters
                optionalPositional default final this.x @40
                  type: dynamic
                  constantInitializer
                    IntegerLiteral
                      literal: 1 @44
                      staticType: int
                  field: <testLibraryFragment>::@class::C::@field::x
            named @53
              reference: <testLibraryFragment>::@class::C::@constructor::named
              enclosingElement3: <testLibraryFragment>::@class::C
              periodOffset: 52
              nameEnd: 58
              parameters
                optionalNamed default final this.x @65
                  reference: <testLibraryFragment>::@class::C::@constructor::named::@parameter::x
                  type: dynamic
                  constantInitializer
                    IntegerLiteral
                      literal: 1 @68
                      staticType: int
                  field: <testLibraryFragment>::@class::C::@field::x
          accessors
            synthetic get x @-1
              reference: <testLibraryFragment>::@class::C::@getter::x
              enclosingElement3: <testLibraryFragment>::@class::C
              returnType: dynamic
            synthetic set x= @-1
              reference: <testLibraryFragment>::@class::C::@setter::x
              enclosingElement3: <testLibraryFragment>::@class::C
              parameters
                requiredPositional _x @-1
                  type: dynamic
              returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C#element
          fields
            x @16
              reference: <testLibraryFragment>::@class::C::@field::x
              element: <testLibraryFragment>::@class::C::@field::x#element
              getter2: <testLibraryFragment>::@class::C::@getter::x
              setter2: <testLibraryFragment>::@class::C::@setter::x
          constructors
            positional @23
              reference: <testLibraryFragment>::@class::C::@constructor::positional
              element: <testLibraryFragment>::@class::C::@constructor::positional#element
              periodOffset: 22
              nameEnd: 33
              formalParameters
                default this.x @40
                  element: <testLibraryFragment>::@class::C::@constructor::positional::@parameter::x#element
            named @53
              reference: <testLibraryFragment>::@class::C::@constructor::named
              element: <testLibraryFragment>::@class::C::@constructor::named#element
              periodOffset: 52
              nameEnd: 58
              formalParameters
                default this.x @65
                  reference: <testLibraryFragment>::@class::C::@constructor::named::@parameter::x
                  element: <testLibraryFragment>::@class::C::@constructor::named::@parameter::x#element
          getters
            get x @-1
              reference: <testLibraryFragment>::@class::C::@getter::x
              element: <testLibraryFragment>::@class::C::@getter::x#element
          setters
            set x= @-1
              reference: <testLibraryFragment>::@class::C::@setter::x
              element: <testLibraryFragment>::@class::C::@setter::x#element
              formalParameters
                _x @-1
                  element: <testLibraryFragment>::@class::C::@setter::x::@parameter::_x#element
  classes
    class C
      firstFragment: <testLibraryFragment>::@class::C
      fields
        x
          firstFragment: <testLibraryFragment>::@class::C::@field::x
          type: dynamic
          getter: <testLibraryFragment>::@class::C::@getter::x#element
          setter: <testLibraryFragment>::@class::C::@setter::x#element
      constructors
        positional
          firstFragment: <testLibraryFragment>::@class::C::@constructor::positional
          formalParameters
            optionalPositional final x
              type: dynamic
        named
          firstFragment: <testLibraryFragment>::@class::C::@constructor::named
          formalParameters
            optionalNamed final x
              firstFragment: <testLibraryFragment>::@class::C::@constructor::named::@parameter::x
              type: dynamic
      getters
        synthetic get x
          firstFragment: <testLibraryFragment>::@class::C::@getter::x
      setters
        synthetic set x=
          firstFragment: <testLibraryFragment>::@class::C::@setter::x
          formalParameters
            requiredPositional _x
              type: dynamic
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
          methods
            static positional @24
              reference: <testLibraryFragment>::@class::C::@method::positional
              enclosingElement3: <testLibraryFragment>::@class::C
              parameters
                optionalPositional default x @36
                  type: dynamic
                  constantInitializer
                    IntegerLiteral
                      literal: 1 @40
                      staticType: int
              returnType: void
            static named @61
              reference: <testLibraryFragment>::@class::C::@method::named
              enclosingElement3: <testLibraryFragment>::@class::C
              parameters
                optionalNamed default x @68
                  reference: <testLibraryFragment>::@class::C::@method::named::@parameter::x
                  type: dynamic
                  constantInitializer
                    IntegerLiteral
                      literal: 1 @71
                      staticType: int
              returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C#element
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
          methods
            positional @24
              reference: <testLibraryFragment>::@class::C::@method::positional
              element: <testLibraryFragment>::@class::C::@method::positional#element
              formalParameters
                default x @36
                  element: <testLibraryFragment>::@class::C::@method::positional::@parameter::x#element
            named @61
              reference: <testLibraryFragment>::@class::C::@method::named
              element: <testLibraryFragment>::@class::C::@method::named#element
              formalParameters
                default x @68
                  reference: <testLibraryFragment>::@class::C::@method::named::@parameter::x
                  element: <testLibraryFragment>::@class::C::@method::named::@parameter::x#element
  classes
    class C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      methods
        static positional
          firstFragment: <testLibraryFragment>::@class::C::@method::positional
          formalParameters
            optionalPositional x
              type: dynamic
        static named
          firstFragment: <testLibraryFragment>::@class::C::@method::named
          formalParameters
            optionalNamed x
              firstFragment: <testLibraryFragment>::@class::C::@method::named::@parameter::x
              type: dynamic
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      functions
        positional @5
          reference: <testLibraryFragment>::@function::positional
          enclosingElement3: <testLibraryFragment>
          parameters
            optionalPositional default x @17
              type: dynamic
              constantInitializer
                IntegerLiteral
                  literal: 1 @21
                  staticType: int
          returnType: void
        named @33
          reference: <testLibraryFragment>::@function::named
          enclosingElement3: <testLibraryFragment>
          parameters
            optionalNamed default x @40
              reference: <testLibraryFragment>::@function::named::@parameter::x
              type: dynamic
              constantInitializer
                IntegerLiteral
                  literal: 1 @43
                  staticType: int
          returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      functions
        positional @5
          reference: <testLibraryFragment>::@function::positional
          element: <testLibraryFragment>::@function::positional#element
          formalParameters
            default x @17
              element: <testLibraryFragment>::@function::positional::@parameter::x#element
        named @33
          reference: <testLibraryFragment>::@function::named
          element: <testLibraryFragment>::@function::named#element
          formalParameters
            default x @40
              reference: <testLibraryFragment>::@function::named::@parameter::x
              element: <testLibraryFragment>::@function::named::@parameter::x#element
  functions
    positional
      firstFragment: <testLibraryFragment>::@function::positional
      formalParameters
        optionalPositional x
          type: dynamic
      returnType: void
    named
      firstFragment: <testLibraryFragment>::@function::named
      formalParameters
        optionalNamed x
          firstFragment: <testLibraryFragment>::@function::named::@parameter::x
          type: dynamic
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
