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
      enclosingElement: <testLibrary>
      functions
        main @5
          reference: <testLibraryFragment>::@function::main
          enclosingElement: <testLibraryFragment>
          parameters
            requiredPositional p @14
              type: int
          returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
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
      enclosingElement: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          enclosingElement: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::A
          methods
            m @17
              reference: <testLibraryFragment>::@class::A::@method::m
              enclosingElement: <testLibraryFragment>::@class::A
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
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingFragment: <testLibraryFragment>::@class::A
          methods
            m @17
              reference: <testLibraryFragment>::@class::A::@method::m
              enclosingFragment: <testLibraryFragment>::@class::A
  classes
    class A
      reference: <testLibraryFragment>::@class::A
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
      methods
        m
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::A::@method::m
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
      enclosingElement: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          enclosingElement: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::A
          methods
            m @17
              reference: <testLibraryFragment>::@class::A::@method::m
              enclosingElement: <testLibraryFragment>::@class::A
              parameters
                optionalPositional default covariant a @32
                  type: A
              returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingFragment: <testLibraryFragment>::@class::A
          methods
            m @17
              reference: <testLibraryFragment>::@class::A::@method::m
              enclosingFragment: <testLibraryFragment>::@class::A
  classes
    class A
      reference: <testLibraryFragment>::@class::A
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
      methods
        m
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::A::@method::m
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
      enclosingElement: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          enclosingElement: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::A
          methods
            m @17
              reference: <testLibraryFragment>::@class::A::@method::m
              enclosingElement: <testLibraryFragment>::@class::A
              parameters
                requiredPositional covariant a @31
                  type: A
              returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingFragment: <testLibraryFragment>::@class::A
          methods
            m @17
              reference: <testLibraryFragment>::@class::A::@method::m
              enclosingFragment: <testLibraryFragment>::@class::A
  classes
    class A
      reference: <testLibraryFragment>::@class::A
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
      methods
        m
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::A::@method::m
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
      enclosingElement: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T @8
              defaultType: dynamic
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::A
          methods
            f @20
              reference: <testLibraryFragment>::@class::A::@method::f
              enclosingElement: <testLibraryFragment>::@class::A
              parameters
                requiredPositional covariant t @34
                  type: T
              returnType: void
        class B @48
          reference: <testLibraryFragment>::@class::B
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T @50
              defaultType: dynamic
          supertype: A<T>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::B::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::B
              superConstructor: ConstructorMember
                base: <testLibraryFragment>::@class::A::@constructor::new
                substitution: {T: T}
          methods
            f @75
              reference: <testLibraryFragment>::@class::B::@method::f
              enclosingElement: <testLibraryFragment>::@class::B
              parameters
                requiredPositional covariant t @79
                  type: T
              returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingFragment: <testLibraryFragment>::@class::A
          methods
            f @20
              reference: <testLibraryFragment>::@class::A::@method::f
              enclosingFragment: <testLibraryFragment>::@class::A
        class B @48
          reference: <testLibraryFragment>::@class::B
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::B::@constructor::new
              enclosingFragment: <testLibraryFragment>::@class::B
              superConstructor: ConstructorMember
                base: <testLibraryFragment>::@class::A::@constructor::new
                substitution: {T: T}
          methods
            f @75
              reference: <testLibraryFragment>::@class::B::@method::f
              enclosingFragment: <testLibraryFragment>::@class::B
  classes
    class A
      reference: <testLibraryFragment>::@class::A
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
      methods
        f
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::A::@method::f
    class B
      reference: <testLibraryFragment>::@class::B
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@class::B
      supertype: A<T>
      constructors
        synthetic new
          reference: <none>
          superConstructor: <none>
          firstFragment: <testLibraryFragment>::@class::B::@constructor::new
      methods
        f
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::B::@method::f
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
      enclosingElement: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          enclosingElement: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::A
          methods
            m @17
              reference: <testLibraryFragment>::@class::A::@method::m
              enclosingElement: <testLibraryFragment>::@class::A
              parameters
                optionalNamed default covariant a @32
                  reference: <testLibraryFragment>::@class::A::@method::m::@parameter::a
                  type: A
              returnType: void
        class B @47
          reference: <testLibraryFragment>::@class::B
          enclosingElement: <testLibraryFragment>
          supertype: A
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::B::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::B
              superConstructor: <testLibraryFragment>::@class::A::@constructor::new
          methods
            m @68
              reference: <testLibraryFragment>::@class::B::@method::m
              enclosingElement: <testLibraryFragment>::@class::B
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
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingFragment: <testLibraryFragment>::@class::A
          methods
            m @17
              reference: <testLibraryFragment>::@class::A::@method::m
              enclosingFragment: <testLibraryFragment>::@class::A
        class B @47
          reference: <testLibraryFragment>::@class::B
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::B::@constructor::new
              enclosingFragment: <testLibraryFragment>::@class::B
              superConstructor: <testLibraryFragment>::@class::A::@constructor::new
          methods
            m @68
              reference: <testLibraryFragment>::@class::B::@method::m
              enclosingFragment: <testLibraryFragment>::@class::B
  classes
    class A
      reference: <testLibraryFragment>::@class::A
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
      methods
        m
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::A::@method::m
    class B
      reference: <testLibraryFragment>::@class::B
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@class::B
      supertype: A
      constructors
        synthetic new
          reference: <none>
          superConstructor: <none>
          firstFragment: <testLibraryFragment>::@class::B::@constructor::new
      methods
        m
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::B::@method::m
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
      enclosingElement: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
          methods
            f @10
              reference: <testLibraryFragment>::@class::C::@method::f
              enclosingElement: <testLibraryFragment>::@class::C
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
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingFragment: <testLibraryFragment>::@class::C
          methods
            f @10
              reference: <testLibraryFragment>::@class::C::@method::f
              enclosingFragment: <testLibraryFragment>::@class::C
  classes
    class C
      reference: <testLibraryFragment>::@class::C
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      methods
        f
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@method::f
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
      enclosingElement: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant A @8
              defaultType: dynamic
            covariant B @11
              defaultType: dynamic
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
          methods
            f @16
              reference: <testLibraryFragment>::@class::C::@method::f
              enclosingElement: <testLibraryFragment>::@class::C
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
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingFragment: <testLibraryFragment>::@class::C
          methods
            f @16
              reference: <testLibraryFragment>::@class::C::@method::f
              enclosingFragment: <testLibraryFragment>::@class::C
  classes
    class C
      reference: <testLibraryFragment>::@class::C
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      methods
        f
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@method::f
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
      enclosingElement: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
          methods
            f @10
              reference: <testLibraryFragment>::@class::C::@method::f
              enclosingElement: <testLibraryFragment>::@class::C
              parameters
                requiredPositional g @16
                  type: int Function()
              returnType: dynamic
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingFragment: <testLibraryFragment>::@class::C
          methods
            f @10
              reference: <testLibraryFragment>::@class::C::@method::f
              enclosingFragment: <testLibraryFragment>::@class::C
  classes
    class C
      reference: <testLibraryFragment>::@class::C
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      methods
        f
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@method::f
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
      enclosingElement: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
          methods
            f @10
              reference: <testLibraryFragment>::@class::C::@method::f
              enclosingElement: <testLibraryFragment>::@class::C
              parameters
                requiredPositional g @17
                  type: void Function()
              returnType: dynamic
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingFragment: <testLibraryFragment>::@class::C
          methods
            f @10
              reference: <testLibraryFragment>::@class::C::@method::f
              enclosingFragment: <testLibraryFragment>::@class::C
  classes
    class C
      reference: <testLibraryFragment>::@class::C
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      methods
        f
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@method::f
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
      enclosingElement: <testLibrary>
      functions
        f @5
          reference: <testLibraryFragment>::@function::f
          enclosingElement: <testLibraryFragment>
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
      enclosingElement: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          constructors
            positional @14
              reference: <testLibraryFragment>::@class::C::@constructor::positional
              enclosingElement: <testLibraryFragment>::@class::C
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
              enclosingElement: <testLibraryFragment>::@class::C
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
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          constructors
            positional @14
              reference: <testLibraryFragment>::@class::C::@constructor::positional
              enclosingFragment: <testLibraryFragment>::@class::C
              periodOffset: 13
              nameEnd: 24
            named @39
              reference: <testLibraryFragment>::@class::C::@constructor::named
              enclosingFragment: <testLibraryFragment>::@class::C
              periodOffset: 38
              nameEnd: 44
  classes
    class C
      reference: <testLibraryFragment>::@class::C
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        positional
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@constructor::positional
        named
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@constructor::named
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
      enclosingElement: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          fields
            x @16
              reference: <testLibraryFragment>::@class::C::@field::x
              enclosingElement: <testLibraryFragment>::@class::C
              type: dynamic
          constructors
            positional @23
              reference: <testLibraryFragment>::@class::C::@constructor::positional
              enclosingElement: <testLibraryFragment>::@class::C
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
              enclosingElement: <testLibraryFragment>::@class::C
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
              enclosingElement: <testLibraryFragment>::@class::C
              returnType: dynamic
            synthetic set x= @-1
              reference: <testLibraryFragment>::@class::C::@setter::x
              enclosingElement: <testLibraryFragment>::@class::C
              parameters
                requiredPositional _x @-1
                  type: dynamic
              returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          fields
            x @16
              reference: <testLibraryFragment>::@class::C::@field::x
              enclosingFragment: <testLibraryFragment>::@class::C
          constructors
            positional @23
              reference: <testLibraryFragment>::@class::C::@constructor::positional
              enclosingFragment: <testLibraryFragment>::@class::C
              periodOffset: 22
              nameEnd: 33
            named @53
              reference: <testLibraryFragment>::@class::C::@constructor::named
              enclosingFragment: <testLibraryFragment>::@class::C
              periodOffset: 52
              nameEnd: 58
          getters
            get x @-1
              reference: <testLibraryFragment>::@class::C::@getter::x
              enclosingFragment: <testLibraryFragment>::@class::C
          setters
            set x= @-1
              reference: <testLibraryFragment>::@class::C::@setter::x
              enclosingFragment: <testLibraryFragment>::@class::C
  classes
    class C
      reference: <testLibraryFragment>::@class::C
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@class::C
      fields
        x
          reference: <none>
          enclosingElement: <testLibraryFragment>::@class::C
          type: dynamic
          firstFragment: <testLibraryFragment>::@class::C::@field::x
      constructors
        positional
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@constructor::positional
        named
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@constructor::named
      getters
        synthetic get x
          reference: <none>
          enclosingElement: <testLibraryFragment>::@class::C
          firstFragment: <testLibraryFragment>::@class::C::@getter::x
      setters
        synthetic set x=
          reference: <none>
          enclosingElement: <testLibraryFragment>::@class::C
          firstFragment: <testLibraryFragment>::@class::C::@setter::x
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
      enclosingElement: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
          methods
            static positional @24
              reference: <testLibraryFragment>::@class::C::@method::positional
              enclosingElement: <testLibraryFragment>::@class::C
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
              enclosingElement: <testLibraryFragment>::@class::C
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
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingFragment: <testLibraryFragment>::@class::C
          methods
            positional @24
              reference: <testLibraryFragment>::@class::C::@method::positional
              enclosingFragment: <testLibraryFragment>::@class::C
            named @61
              reference: <testLibraryFragment>::@class::C::@method::named
              enclosingFragment: <testLibraryFragment>::@class::C
  classes
    class C
      reference: <testLibraryFragment>::@class::C
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      methods
        static positional
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@method::positional
        static named
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@method::named
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
      enclosingElement: <testLibrary>
      functions
        positional @5
          reference: <testLibraryFragment>::@function::positional
          enclosingElement: <testLibraryFragment>
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
          enclosingElement: <testLibraryFragment>
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
