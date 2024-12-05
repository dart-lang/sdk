// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../dart/resolution/node_text_expectations.dart';
import '../elements_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MixinElementTest_keepLinking);
    defineReflectiveTests(MixinElementTest_fromBytes);
    defineReflectiveTests(MixinElementTest_augmentation_fromBytes);
    defineReflectiveTests(MixinElementTest_augmentation_keepLinking);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

abstract class MixinElementTest extends ElementsBaseTest {
  test_mixin() async {
    var library = await buildLibrary(r'''
class A {}
class B {}
class C {}
class D {}

mixin M<T extends num, U> on A, B implements C, D {
  T f;
  U get g => 0;
  set s(int v) {}
  int m(double v) => 0;
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
        class B @17
          reference: <testLibraryFragment>::@class::B
          enclosingElement3: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::B::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::B
        class C @28
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
        class D @39
          reference: <testLibraryFragment>::@class::D
          enclosingElement3: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::D::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::D
      mixins
        mixin M @51
          reference: <testLibraryFragment>::@mixin::M
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant T @53
              bound: num
              defaultType: num
            covariant U @68
              defaultType: dynamic
          superclassConstraints
            A
            B
          interfaces
            C
            D
          fields
            f @101
              reference: <testLibraryFragment>::@mixin::M::@field::f
              enclosingElement3: <testLibraryFragment>::@mixin::M
              type: T
            synthetic g @-1
              reference: <testLibraryFragment>::@mixin::M::@field::g
              enclosingElement3: <testLibraryFragment>::@mixin::M
              type: U
            synthetic s @-1
              reference: <testLibraryFragment>::@mixin::M::@field::s
              enclosingElement3: <testLibraryFragment>::@mixin::M
              type: int
          accessors
            synthetic get f @-1
              reference: <testLibraryFragment>::@mixin::M::@getter::f
              enclosingElement3: <testLibraryFragment>::@mixin::M
              returnType: T
            synthetic set f= @-1
              reference: <testLibraryFragment>::@mixin::M::@setter::f
              enclosingElement3: <testLibraryFragment>::@mixin::M
              parameters
                requiredPositional _f @-1
                  type: T
              returnType: void
            get g @112
              reference: <testLibraryFragment>::@mixin::M::@getter::g
              enclosingElement3: <testLibraryFragment>::@mixin::M
              returnType: U
            set s= @126
              reference: <testLibraryFragment>::@mixin::M::@setter::s
              enclosingElement3: <testLibraryFragment>::@mixin::M
              parameters
                requiredPositional v @132
                  type: int
              returnType: void
          methods
            m @144
              reference: <testLibraryFragment>::@mixin::M::@method::m
              enclosingElement3: <testLibraryFragment>::@mixin::M
              parameters
                requiredPositional v @153
                  type: double
              returnType: int
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
        class B @17
          reference: <testLibraryFragment>::@class::B
          element: <testLibraryFragment>::@class::B#element
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::B::@constructor::new
              element: <testLibraryFragment>::@class::B::@constructor::new#element
        class C @28
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C#element
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
        class D @39
          reference: <testLibraryFragment>::@class::D
          element: <testLibraryFragment>::@class::D#element
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::D::@constructor::new
              element: <testLibraryFragment>::@class::D::@constructor::new#element
      mixins
        mixin M @51
          reference: <testLibraryFragment>::@mixin::M
          element: <testLibraryFragment>::@mixin::M#element
          typeParameters
            T @53
              element: <not-implemented>
            U @68
              element: <not-implemented>
          fields
            f @101
              reference: <testLibraryFragment>::@mixin::M::@field::f
              element: <testLibraryFragment>::@mixin::M::@field::f#element
              getter2: <testLibraryFragment>::@mixin::M::@getter::f
              setter2: <testLibraryFragment>::@mixin::M::@setter::f
            g @-1
              reference: <testLibraryFragment>::@mixin::M::@field::g
              element: <testLibraryFragment>::@mixin::M::@field::g#element
              getter2: <testLibraryFragment>::@mixin::M::@getter::g
            s @-1
              reference: <testLibraryFragment>::@mixin::M::@field::s
              element: <testLibraryFragment>::@mixin::M::@field::s#element
              setter2: <testLibraryFragment>::@mixin::M::@setter::s
          getters
            get f @-1
              reference: <testLibraryFragment>::@mixin::M::@getter::f
              element: <testLibraryFragment>::@mixin::M::@getter::f#element
            get g @112
              reference: <testLibraryFragment>::@mixin::M::@getter::g
              element: <testLibraryFragment>::@mixin::M::@getter::g#element
          setters
            set f= @-1
              reference: <testLibraryFragment>::@mixin::M::@setter::f
              element: <testLibraryFragment>::@mixin::M::@setter::f#element
              formalParameters
                _f @-1
                  element: <testLibraryFragment>::@mixin::M::@setter::f::@parameter::_f#element
            set s= @126
              reference: <testLibraryFragment>::@mixin::M::@setter::s
              element: <testLibraryFragment>::@mixin::M::@setter::s#element
              formalParameters
                v @132
                  element: <testLibraryFragment>::@mixin::M::@setter::s::@parameter::v#element
          methods
            m @144
              reference: <testLibraryFragment>::@mixin::M::@method::m
              element: <testLibraryFragment>::@mixin::M::@method::m#element
              formalParameters
                v @153
                  element: <testLibraryFragment>::@mixin::M::@method::m::@parameter::v#element
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
    class B
      firstFragment: <testLibraryFragment>::@class::B
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::B::@constructor::new
    class C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
    class D
      firstFragment: <testLibraryFragment>::@class::D
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::D::@constructor::new
  mixins
    mixin M
      firstFragment: <testLibraryFragment>::@mixin::M
      typeParameters
        T
          bound: num
        U
      superclassConstraints
        A
        B
      fields
        f
          firstFragment: <testLibraryFragment>::@mixin::M::@field::f
          type: T
          getter: <testLibraryFragment>::@mixin::M::@getter::f#element
          setter: <testLibraryFragment>::@mixin::M::@setter::f#element
        synthetic g
          firstFragment: <testLibraryFragment>::@mixin::M::@field::g
          type: U
          getter: <testLibraryFragment>::@mixin::M::@getter::g#element
        synthetic s
          firstFragment: <testLibraryFragment>::@mixin::M::@field::s
          type: int
          setter: <testLibraryFragment>::@mixin::M::@setter::s#element
      getters
        synthetic get f
          firstFragment: <testLibraryFragment>::@mixin::M::@getter::f
        get g
          firstFragment: <testLibraryFragment>::@mixin::M::@getter::g
      setters
        synthetic set f=
          firstFragment: <testLibraryFragment>::@mixin::M::@setter::f
          formalParameters
            requiredPositional _f
              type: T
        set s=
          firstFragment: <testLibraryFragment>::@mixin::M::@setter::s
          formalParameters
            requiredPositional v
              type: int
      methods
        m
          firstFragment: <testLibraryFragment>::@mixin::M::@method::m
          formalParameters
            requiredPositional v
              type: double
''');
  }

  test_mixin_base() async {
    var library = await buildLibrary(r'''
base mixin M on A {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      mixins
        base mixin M @11
          reference: <testLibraryFragment>::@mixin::M
          enclosingElement3: <testLibraryFragment>
          superclassConstraints
            Object
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      mixins
        mixin M @11
          reference: <testLibraryFragment>::@mixin::M
          element: <testLibraryFragment>::@mixin::M#element
  mixins
    base mixin M
      firstFragment: <testLibraryFragment>::@mixin::M
      superclassConstraints
        Object
''');
  }

  test_mixin_field_inferredType_final() async {
    var library = await buildLibrary('''
mixin M {
  final x = 0;
}''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      mixins
        mixin M @6
          reference: <testLibraryFragment>::@mixin::M
          enclosingElement3: <testLibraryFragment>
          superclassConstraints
            Object
          fields
            final x @18
              reference: <testLibraryFragment>::@mixin::M::@field::x
              enclosingElement3: <testLibraryFragment>::@mixin::M
              type: int
              shouldUseTypeForInitializerInference: false
          accessors
            synthetic get x @-1
              reference: <testLibraryFragment>::@mixin::M::@getter::x
              enclosingElement3: <testLibraryFragment>::@mixin::M
              returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      mixins
        mixin M @6
          reference: <testLibraryFragment>::@mixin::M
          element: <testLibraryFragment>::@mixin::M#element
          fields
            x @18
              reference: <testLibraryFragment>::@mixin::M::@field::x
              element: <testLibraryFragment>::@mixin::M::@field::x#element
              getter2: <testLibraryFragment>::@mixin::M::@getter::x
          getters
            get x @-1
              reference: <testLibraryFragment>::@mixin::M::@getter::x
              element: <testLibraryFragment>::@mixin::M::@getter::x#element
  mixins
    mixin M
      firstFragment: <testLibraryFragment>::@mixin::M
      superclassConstraints
        Object
      fields
        final x
          firstFragment: <testLibraryFragment>::@mixin::M::@field::x
          type: int
          getter: <testLibraryFragment>::@mixin::M::@getter::x#element
      getters
        synthetic get x
          firstFragment: <testLibraryFragment>::@mixin::M::@getter::x
''');
  }

  test_mixin_first() async {
    var library = await buildLibrary(r'''
mixin M {}
''');

    // We intentionally ask `mixins` directly, to check that we can ask them
    // separately, without asking classes.
    var mixins = library.definingCompilationUnit.mixins;
    expect(mixins, hasLength(1));
    expect(mixins[0].name, 'M');
  }

  test_mixin_getter_invokesSuperSelf_getter() async {
    var library = await buildLibrary(r'''
mixin M on A {
  int get foo {
    super.foo;
  }
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      mixins
        mixin M @6
          reference: <testLibraryFragment>::@mixin::M
          enclosingElement3: <testLibraryFragment>
          superclassConstraints
            Object
          fields
            synthetic foo @-1
              reference: <testLibraryFragment>::@mixin::M::@field::foo
              enclosingElement3: <testLibraryFragment>::@mixin::M
              type: int
          accessors
            get foo @25 invokesSuperSelf
              reference: <testLibraryFragment>::@mixin::M::@getter::foo
              enclosingElement3: <testLibraryFragment>::@mixin::M
              returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      mixins
        mixin M @6
          reference: <testLibraryFragment>::@mixin::M
          element: <testLibraryFragment>::@mixin::M#element
          fields
            foo @-1
              reference: <testLibraryFragment>::@mixin::M::@field::foo
              element: <testLibraryFragment>::@mixin::M::@field::foo#element
              getter2: <testLibraryFragment>::@mixin::M::@getter::foo
          getters
            get foo @25
              reference: <testLibraryFragment>::@mixin::M::@getter::foo
              element: <testLibraryFragment>::@mixin::M::@getter::foo#element
  mixins
    mixin M
      firstFragment: <testLibraryFragment>::@mixin::M
      superclassConstraints
        Object
      fields
        synthetic foo
          firstFragment: <testLibraryFragment>::@mixin::M::@field::foo
          type: int
          getter: <testLibraryFragment>::@mixin::M::@getter::foo#element
      getters
        get foo
          firstFragment: <testLibraryFragment>::@mixin::M::@getter::foo
''');
  }

  test_mixin_getter_invokesSuperSelf_getter_nestedInAssignment() async {
    var library = await buildLibrary(r'''
mixin M on A {
  int get foo {
    (super.foo).foo = 0;
  }
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      mixins
        mixin M @6
          reference: <testLibraryFragment>::@mixin::M
          enclosingElement3: <testLibraryFragment>
          superclassConstraints
            Object
          fields
            synthetic foo @-1
              reference: <testLibraryFragment>::@mixin::M::@field::foo
              enclosingElement3: <testLibraryFragment>::@mixin::M
              type: int
          accessors
            get foo @25 invokesSuperSelf
              reference: <testLibraryFragment>::@mixin::M::@getter::foo
              enclosingElement3: <testLibraryFragment>::@mixin::M
              returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      mixins
        mixin M @6
          reference: <testLibraryFragment>::@mixin::M
          element: <testLibraryFragment>::@mixin::M#element
          fields
            foo @-1
              reference: <testLibraryFragment>::@mixin::M::@field::foo
              element: <testLibraryFragment>::@mixin::M::@field::foo#element
              getter2: <testLibraryFragment>::@mixin::M::@getter::foo
          getters
            get foo @25
              reference: <testLibraryFragment>::@mixin::M::@getter::foo
              element: <testLibraryFragment>::@mixin::M::@getter::foo#element
  mixins
    mixin M
      firstFragment: <testLibraryFragment>::@mixin::M
      superclassConstraints
        Object
      fields
        synthetic foo
          firstFragment: <testLibraryFragment>::@mixin::M::@field::foo
          type: int
          getter: <testLibraryFragment>::@mixin::M::@getter::foo#element
      getters
        get foo
          firstFragment: <testLibraryFragment>::@mixin::M::@getter::foo
''');
  }

  test_mixin_getter_invokesSuperSelf_setter() async {
    var library = await buildLibrary(r'''
mixin M on A {
  int get foo {
    super.foo = 0;
  }
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      mixins
        mixin M @6
          reference: <testLibraryFragment>::@mixin::M
          enclosingElement3: <testLibraryFragment>
          superclassConstraints
            Object
          fields
            synthetic foo @-1
              reference: <testLibraryFragment>::@mixin::M::@field::foo
              enclosingElement3: <testLibraryFragment>::@mixin::M
              type: int
          accessors
            get foo @25
              reference: <testLibraryFragment>::@mixin::M::@getter::foo
              enclosingElement3: <testLibraryFragment>::@mixin::M
              returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      mixins
        mixin M @6
          reference: <testLibraryFragment>::@mixin::M
          element: <testLibraryFragment>::@mixin::M#element
          fields
            foo @-1
              reference: <testLibraryFragment>::@mixin::M::@field::foo
              element: <testLibraryFragment>::@mixin::M::@field::foo#element
              getter2: <testLibraryFragment>::@mixin::M::@getter::foo
          getters
            get foo @25
              reference: <testLibraryFragment>::@mixin::M::@getter::foo
              element: <testLibraryFragment>::@mixin::M::@getter::foo#element
  mixins
    mixin M
      firstFragment: <testLibraryFragment>::@mixin::M
      superclassConstraints
        Object
      fields
        synthetic foo
          firstFragment: <testLibraryFragment>::@mixin::M::@field::foo
          type: int
          getter: <testLibraryFragment>::@mixin::M::@getter::foo#element
      getters
        get foo
          firstFragment: <testLibraryFragment>::@mixin::M::@getter::foo
''');
  }

  test_mixin_implicitObjectSuperclassConstraint() async {
    var library = await buildLibrary(r'''
mixin M {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      mixins
        mixin M @6
          reference: <testLibraryFragment>::@mixin::M
          enclosingElement3: <testLibraryFragment>
          superclassConstraints
            Object
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      mixins
        mixin M @6
          reference: <testLibraryFragment>::@mixin::M
          element: <testLibraryFragment>::@mixin::M#element
  mixins
    mixin M
      firstFragment: <testLibraryFragment>::@mixin::M
      superclassConstraints
        Object
''');
  }

  test_mixin_inference() async {
    var library = await buildLibrary(r'''
class A<T> {}
mixin M<U> on A<U> {}
class B extends A<int> with M {}
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
        class B @42
          reference: <testLibraryFragment>::@class::B
          enclosingElement3: <testLibraryFragment>
          supertype: A<int>
          mixins
            M<int>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::B::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::B
              superConstructor: ConstructorMember
                base: <testLibraryFragment>::@class::A::@constructor::new
                substitution: {T: int}
      mixins
        mixin M @20
          reference: <testLibraryFragment>::@mixin::M
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant U @22
              defaultType: dynamic
          superclassConstraints
            A<U>
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
        class B @42
          reference: <testLibraryFragment>::@class::B
          element: <testLibraryFragment>::@class::B#element
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::B::@constructor::new
              element: <testLibraryFragment>::@class::B::@constructor::new#element
              superConstructor: ConstructorMember
                base: <testLibraryFragment>::@class::A::@constructor::new
                substitution: {T: int}
      mixins
        mixin M @20
          reference: <testLibraryFragment>::@mixin::M
          element: <testLibraryFragment>::@mixin::M#element
          typeParameters
            U @22
              element: <not-implemented>
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
      typeParameters
        T
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
    class B
      firstFragment: <testLibraryFragment>::@class::B
      supertype: A<int>
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::B::@constructor::new
          superConstructor: <testLibraryFragment>::@class::A::@constructor::new#element
  mixins
    mixin M
      firstFragment: <testLibraryFragment>::@mixin::M
      typeParameters
        U
      superclassConstraints
        A<U>
''');
  }

  test_mixin_inference_classAlias_oneMixin() async {
    // In the code below, B's superclass constraints don't include A, because
    // superclass constraints are determined from the mixin's superclass, and
    // B's superclass is Object.  So no mixin type inference is attempted, and
    // "with B" is interpreted as "with B<dynamic>".
    var library = await buildLibrary(r'''
class A<T> {}
class B<T> = Object with A<T>;
class C = A<int> with B;
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
        class alias B @20
          reference: <testLibraryFragment>::@class::B
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant T @22
              defaultType: dynamic
          supertype: Object
          mixins
            A<T>
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@class::B::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::B
              constantInitializers
                SuperConstructorInvocation
                  superKeyword: super @0
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticElement: dart:core::<fragment>::@class::Object::@constructor::new
                  element: dart:core::<fragment>::@class::Object::@constructor::new#element
        class alias C @51
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          supertype: A<int>
          mixins
            B<dynamic>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
              constantInitializers
                SuperConstructorInvocation
                  superKeyword: super @0
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticElement: <testLibraryFragment>::@class::A::@constructor::new
                  element: <testLibraryFragment>::@class::A::@constructor::new#element
              superConstructor: ConstructorMember
                base: <testLibraryFragment>::@class::A::@constructor::new
                substitution: {T: int}
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
        class B @20
          reference: <testLibraryFragment>::@class::B
          element: <testLibraryFragment>::@class::B#element
          typeParameters
            T @22
              element: <not-implemented>
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@class::B::@constructor::new
              element: <testLibraryFragment>::@class::B::@constructor::new#element
              constantInitializers
                SuperConstructorInvocation
                  superKeyword: super @0
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticElement: dart:core::<fragment>::@class::Object::@constructor::new
                  element: dart:core::<fragment>::@class::Object::@constructor::new#element
        class C @51
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C#element
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
              constantInitializers
                SuperConstructorInvocation
                  superKeyword: super @0
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticElement: <testLibraryFragment>::@class::A::@constructor::new
                  element: <testLibraryFragment>::@class::A::@constructor::new#element
              superConstructor: ConstructorMember
                base: <testLibraryFragment>::@class::A::@constructor::new
                substitution: {T: int}
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
      typeParameters
        T
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
    class alias B
      firstFragment: <testLibraryFragment>::@class::B
      typeParameters
        T
      supertype: Object
      constructors
        synthetic const new
          firstFragment: <testLibraryFragment>::@class::B::@constructor::new
    class alias C
      firstFragment: <testLibraryFragment>::@class::C
      supertype: A<int>
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
          superConstructor: <testLibraryFragment>::@class::A::@constructor::new#element
''');
  }

  test_mixin_inference_classAlias_twoMixins() async {
    // In the code below, `B` has a single superclass constraint, A1, because
    // superclass constraints are determined from the mixin's superclass, and
    // B's superclass is "Object with A1<T>".  So mixin type inference succeeds
    // (since C's base class implements A1<int>), and "with B" is interpreted as
    // "with B<int>".
    var library = await buildLibrary(r'''
class A1<T> {}
class A2<T> {}
class B<T> = Object with A1<T>, A2<T>;
class Base implements A1<int> {}
class C = Base with B;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        class A1 @6
          reference: <testLibraryFragment>::@class::A1
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant T @9
              defaultType: dynamic
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::A1::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::A1
        class A2 @21
          reference: <testLibraryFragment>::@class::A2
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant T @24
              defaultType: dynamic
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::A2::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::A2
        class alias B @36
          reference: <testLibraryFragment>::@class::B
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant T @38
              defaultType: dynamic
          supertype: Object
          mixins
            A1<T>
            A2<T>
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@class::B::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::B
              constantInitializers
                SuperConstructorInvocation
                  superKeyword: super @0
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticElement: dart:core::<fragment>::@class::Object::@constructor::new
                  element: dart:core::<fragment>::@class::Object::@constructor::new#element
        class Base @75
          reference: <testLibraryFragment>::@class::Base
          enclosingElement3: <testLibraryFragment>
          interfaces
            A1<int>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::Base::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::Base
        class alias C @108
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          supertype: Base
          mixins
            B<int>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
              constantInitializers
                SuperConstructorInvocation
                  superKeyword: super @0
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticElement: <testLibraryFragment>::@class::Base::@constructor::new
                  element: <testLibraryFragment>::@class::Base::@constructor::new#element
              superConstructor: <testLibraryFragment>::@class::Base::@constructor::new
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A1 @6
          reference: <testLibraryFragment>::@class::A1
          element: <testLibraryFragment>::@class::A1#element
          typeParameters
            T @9
              element: <not-implemented>
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::A1::@constructor::new
              element: <testLibraryFragment>::@class::A1::@constructor::new#element
        class A2 @21
          reference: <testLibraryFragment>::@class::A2
          element: <testLibraryFragment>::@class::A2#element
          typeParameters
            T @24
              element: <not-implemented>
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::A2::@constructor::new
              element: <testLibraryFragment>::@class::A2::@constructor::new#element
        class B @36
          reference: <testLibraryFragment>::@class::B
          element: <testLibraryFragment>::@class::B#element
          typeParameters
            T @38
              element: <not-implemented>
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@class::B::@constructor::new
              element: <testLibraryFragment>::@class::B::@constructor::new#element
              constantInitializers
                SuperConstructorInvocation
                  superKeyword: super @0
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticElement: dart:core::<fragment>::@class::Object::@constructor::new
                  element: dart:core::<fragment>::@class::Object::@constructor::new#element
        class Base @75
          reference: <testLibraryFragment>::@class::Base
          element: <testLibraryFragment>::@class::Base#element
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::Base::@constructor::new
              element: <testLibraryFragment>::@class::Base::@constructor::new#element
        class C @108
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C#element
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
              constantInitializers
                SuperConstructorInvocation
                  superKeyword: super @0
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticElement: <testLibraryFragment>::@class::Base::@constructor::new
                  element: <testLibraryFragment>::@class::Base::@constructor::new#element
              superConstructor: <testLibraryFragment>::@class::Base::@constructor::new
  classes
    class A1
      firstFragment: <testLibraryFragment>::@class::A1
      typeParameters
        T
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::A1::@constructor::new
    class A2
      firstFragment: <testLibraryFragment>::@class::A2
      typeParameters
        T
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::A2::@constructor::new
    class alias B
      firstFragment: <testLibraryFragment>::@class::B
      typeParameters
        T
      supertype: Object
      constructors
        synthetic const new
          firstFragment: <testLibraryFragment>::@class::B::@constructor::new
    class Base
      firstFragment: <testLibraryFragment>::@class::Base
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::Base::@constructor::new
    class alias C
      firstFragment: <testLibraryFragment>::@class::C
      supertype: Base
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
          superConstructor: <testLibraryFragment>::@class::Base::@constructor::new#element
''');
  }

  test_mixin_inference_nested_functionType() async {
    var library = await buildLibrary(r'''
class A<T> {}
mixin M<T, U> on A<T Function(U)> {}
class C extends A<int Function(String)> with M {}
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
        class C @57
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          supertype: A<int Function(String)>
          mixins
            M<int, String>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
              superConstructor: ConstructorMember
                base: <testLibraryFragment>::@class::A::@constructor::new
                substitution: {T: int Function(String)}
      mixins
        mixin M @20
          reference: <testLibraryFragment>::@mixin::M
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant T @22
              defaultType: dynamic
            covariant U @25
              defaultType: dynamic
          superclassConstraints
            A<T Function(U)>
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
        class C @57
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C#element
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
              superConstructor: ConstructorMember
                base: <testLibraryFragment>::@class::A::@constructor::new
                substitution: {T: int Function(String)}
      mixins
        mixin M @20
          reference: <testLibraryFragment>::@mixin::M
          element: <testLibraryFragment>::@mixin::M#element
          typeParameters
            T @22
              element: <not-implemented>
            U @25
              element: <not-implemented>
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
      typeParameters
        T
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
    class C
      firstFragment: <testLibraryFragment>::@class::C
      supertype: A<int Function(String)>
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
          superConstructor: <testLibraryFragment>::@class::A::@constructor::new#element
  mixins
    mixin M
      firstFragment: <testLibraryFragment>::@mixin::M
      typeParameters
        T
        U
      superclassConstraints
        A<T Function(U)>
''');
  }

  test_mixin_inference_nested_interfaceType() async {
    var library = await buildLibrary(r'''
abstract class A<T> {}
mixin M<T> on A<List<T>> {}
class C extends A<List<int>> with M {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        abstract class A @15
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant T @17
              defaultType: dynamic
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::A
        class C @57
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          supertype: A<List<int>>
          mixins
            M<int>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
              superConstructor: ConstructorMember
                base: <testLibraryFragment>::@class::A::@constructor::new
                substitution: {T: List<int>}
      mixins
        mixin M @29
          reference: <testLibraryFragment>::@mixin::M
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant T @31
              defaultType: dynamic
          superclassConstraints
            A<List<T>>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @15
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A#element
          typeParameters
            T @17
              element: <not-implemented>
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <testLibraryFragment>::@class::A::@constructor::new#element
        class C @57
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C#element
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
              superConstructor: ConstructorMember
                base: <testLibraryFragment>::@class::A::@constructor::new
                substitution: {T: List<int>}
      mixins
        mixin M @29
          reference: <testLibraryFragment>::@mixin::M
          element: <testLibraryFragment>::@mixin::M#element
          typeParameters
            T @31
              element: <not-implemented>
  classes
    abstract class A
      firstFragment: <testLibraryFragment>::@class::A
      typeParameters
        T
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
    class C
      firstFragment: <testLibraryFragment>::@class::C
      supertype: A<List<int>>
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
          superConstructor: <testLibraryFragment>::@class::A::@constructor::new#element
  mixins
    mixin M
      firstFragment: <testLibraryFragment>::@mixin::M
      typeParameters
        T
      superclassConstraints
        A<List<T>>
''');
  }

  test_mixin_inference_twoMixins() async {
    // Both `M1` and `M2` have their type arguments inferred.
    var library = await buildLibrary(r'''
class I<X> {}
mixin M1<T> on I<T> {}
mixin M2<T> on I<T> {}
class A = I<int> with M1, M2;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        class I @6
          reference: <testLibraryFragment>::@class::I
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant X @8
              defaultType: dynamic
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::I::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::I
        class alias A @66
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          supertype: I<int>
          mixins
            M1<int>
            M2<int>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::A
              constantInitializers
                SuperConstructorInvocation
                  superKeyword: super @0
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticElement: <testLibraryFragment>::@class::I::@constructor::new
                  element: <testLibraryFragment>::@class::I::@constructor::new#element
              superConstructor: ConstructorMember
                base: <testLibraryFragment>::@class::I::@constructor::new
                substitution: {X: int}
      mixins
        mixin M1 @20
          reference: <testLibraryFragment>::@mixin::M1
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant T @23
              defaultType: dynamic
          superclassConstraints
            I<T>
        mixin M2 @43
          reference: <testLibraryFragment>::@mixin::M2
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant T @46
              defaultType: dynamic
          superclassConstraints
            I<T>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class I @6
          reference: <testLibraryFragment>::@class::I
          element: <testLibraryFragment>::@class::I#element
          typeParameters
            X @8
              element: <not-implemented>
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::I::@constructor::new
              element: <testLibraryFragment>::@class::I::@constructor::new#element
        class A @66
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A#element
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <testLibraryFragment>::@class::A::@constructor::new#element
              constantInitializers
                SuperConstructorInvocation
                  superKeyword: super @0
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticElement: <testLibraryFragment>::@class::I::@constructor::new
                  element: <testLibraryFragment>::@class::I::@constructor::new#element
              superConstructor: ConstructorMember
                base: <testLibraryFragment>::@class::I::@constructor::new
                substitution: {X: int}
      mixins
        mixin M1 @20
          reference: <testLibraryFragment>::@mixin::M1
          element: <testLibraryFragment>::@mixin::M1#element
          typeParameters
            T @23
              element: <not-implemented>
        mixin M2 @43
          reference: <testLibraryFragment>::@mixin::M2
          element: <testLibraryFragment>::@mixin::M2#element
          typeParameters
            T @46
              element: <not-implemented>
  classes
    class I
      firstFragment: <testLibraryFragment>::@class::I
      typeParameters
        X
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::I::@constructor::new
    class alias A
      firstFragment: <testLibraryFragment>::@class::A
      supertype: I<int>
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
          superConstructor: <testLibraryFragment>::@class::I::@constructor::new#element
  mixins
    mixin M1
      firstFragment: <testLibraryFragment>::@mixin::M1
      typeParameters
        T
      superclassConstraints
        I<T>
    mixin M2
      firstFragment: <testLibraryFragment>::@mixin::M2
      typeParameters
        T
      superclassConstraints
        I<T>
''');
  }

  test_mixin_inference_viaTypeAlias() async {
    var library = await buildLibrary(r'''
mixin M<T, U> on S<T> {}

typedef M2<T2> = M<T2, int>;

class S<T3> {}

class X extends S<String> with M2 {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        class S @62
          reference: <testLibraryFragment>::@class::S
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant T3 @64
              defaultType: dynamic
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::S::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::S
        class X @78
          reference: <testLibraryFragment>::@class::X
          enclosingElement3: <testLibraryFragment>
          supertype: S<String>
          mixins
            M<String, int>
              alias: <testLibraryFragment>::@typeAlias::M2
                typeArguments
                  String
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::X::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::X
              superConstructor: ConstructorMember
                base: <testLibraryFragment>::@class::S::@constructor::new
                substitution: {T3: String}
      mixins
        mixin M @6
          reference: <testLibraryFragment>::@mixin::M
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant T @8
              defaultType: dynamic
            covariant U @11
              defaultType: dynamic
          superclassConstraints
            S<T>
      typeAliases
        M2 @34
          reference: <testLibraryFragment>::@typeAlias::M2
          typeParameters
            covariant T2 @37
              defaultType: dynamic
          aliasedType: M<T2, int>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class S @62
          reference: <testLibraryFragment>::@class::S
          element: <testLibraryFragment>::@class::S#element
          typeParameters
            T3 @64
              element: <not-implemented>
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::S::@constructor::new
              element: <testLibraryFragment>::@class::S::@constructor::new#element
        class X @78
          reference: <testLibraryFragment>::@class::X
          element: <testLibraryFragment>::@class::X#element
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::X::@constructor::new
              element: <testLibraryFragment>::@class::X::@constructor::new#element
              superConstructor: ConstructorMember
                base: <testLibraryFragment>::@class::S::@constructor::new
                substitution: {T3: String}
      mixins
        mixin M @6
          reference: <testLibraryFragment>::@mixin::M
          element: <testLibraryFragment>::@mixin::M#element
          typeParameters
            T @8
              element: <not-implemented>
            U @11
              element: <not-implemented>
      typeAliases
        M2 @34
          reference: <testLibraryFragment>::@typeAlias::M2
          element: <testLibraryFragment>::@typeAlias::M2#element
          typeParameters
            T2 @37
              element: <not-implemented>
  classes
    class S
      firstFragment: <testLibraryFragment>::@class::S
      typeParameters
        T3
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::S::@constructor::new
    class X
      firstFragment: <testLibraryFragment>::@class::X
      supertype: S<String>
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::X::@constructor::new
          superConstructor: <testLibraryFragment>::@class::S::@constructor::new#element
  mixins
    mixin M
      firstFragment: <testLibraryFragment>::@mixin::M
      typeParameters
        T
        U
      superclassConstraints
        S<T>
  typeAliases
    M2
      firstFragment: <testLibraryFragment>::@typeAlias::M2
      typeParameters
        T2
      aliasedType: M<T2, int>
''');
  }

  test_mixin_inference_viaTypeAlias2() async {
    var library = await buildLibrary(r'''
mixin M<T, U> on S<T> {}

typedef M2<T2> = M<T2, int>;

typedef M3<T3> = M2<T3>;

class S<T4> {}

class X extends S<String> with M3 {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        class S @88
          reference: <testLibraryFragment>::@class::S
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant T4 @90
              defaultType: dynamic
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::S::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::S
        class X @104
          reference: <testLibraryFragment>::@class::X
          enclosingElement3: <testLibraryFragment>
          supertype: S<String>
          mixins
            M<String, int>
              alias: <testLibraryFragment>::@typeAlias::M3
                typeArguments
                  String
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::X::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::X
              superConstructor: ConstructorMember
                base: <testLibraryFragment>::@class::S::@constructor::new
                substitution: {T4: String}
      mixins
        mixin M @6
          reference: <testLibraryFragment>::@mixin::M
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant T @8
              defaultType: dynamic
            covariant U @11
              defaultType: dynamic
          superclassConstraints
            S<T>
      typeAliases
        M2 @34
          reference: <testLibraryFragment>::@typeAlias::M2
          typeParameters
            covariant T2 @37
              defaultType: dynamic
          aliasedType: M<T2, int>
        M3 @64
          reference: <testLibraryFragment>::@typeAlias::M3
          typeParameters
            covariant T3 @67
              defaultType: dynamic
          aliasedType: M<T3, int>
            alias: <testLibraryFragment>::@typeAlias::M2
              typeArguments
                T3
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class S @88
          reference: <testLibraryFragment>::@class::S
          element: <testLibraryFragment>::@class::S#element
          typeParameters
            T4 @90
              element: <not-implemented>
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::S::@constructor::new
              element: <testLibraryFragment>::@class::S::@constructor::new#element
        class X @104
          reference: <testLibraryFragment>::@class::X
          element: <testLibraryFragment>::@class::X#element
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::X::@constructor::new
              element: <testLibraryFragment>::@class::X::@constructor::new#element
              superConstructor: ConstructorMember
                base: <testLibraryFragment>::@class::S::@constructor::new
                substitution: {T4: String}
      mixins
        mixin M @6
          reference: <testLibraryFragment>::@mixin::M
          element: <testLibraryFragment>::@mixin::M#element
          typeParameters
            T @8
              element: <not-implemented>
            U @11
              element: <not-implemented>
      typeAliases
        M2 @34
          reference: <testLibraryFragment>::@typeAlias::M2
          element: <testLibraryFragment>::@typeAlias::M2#element
          typeParameters
            T2 @37
              element: <not-implemented>
        M3 @64
          reference: <testLibraryFragment>::@typeAlias::M3
          element: <testLibraryFragment>::@typeAlias::M3#element
          typeParameters
            T3 @67
              element: <not-implemented>
  classes
    class S
      firstFragment: <testLibraryFragment>::@class::S
      typeParameters
        T4
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::S::@constructor::new
    class X
      firstFragment: <testLibraryFragment>::@class::X
      supertype: S<String>
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::X::@constructor::new
          superConstructor: <testLibraryFragment>::@class::S::@constructor::new#element
  mixins
    mixin M
      firstFragment: <testLibraryFragment>::@mixin::M
      typeParameters
        T
        U
      superclassConstraints
        S<T>
  typeAliases
    M2
      firstFragment: <testLibraryFragment>::@typeAlias::M2
      typeParameters
        T2
      aliasedType: M<T2, int>
    M3
      firstFragment: <testLibraryFragment>::@typeAlias::M3
      typeParameters
        T3
      aliasedType: M<T3, int>
        alias: <testLibraryFragment>::@typeAlias::M2
          typeArguments
            T3
''');
  }

  test_mixin_interfaces_extensionType() async {
    var library = await buildLibrary(r'''
class A {}
extension type B(int it) {}
class C {}
mixin M implements A, B, C {}
''');
    configuration.withConstructors = false;
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
        class C @45
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
      extensionTypes
        B @26
          reference: <testLibraryFragment>::@extensionType::B
          enclosingElement3: <testLibraryFragment>
          representation: <testLibraryFragment>::@extensionType::B::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::B::@constructor::new
          typeErasure: int
          fields
            final it @32
              reference: <testLibraryFragment>::@extensionType::B::@field::it
              enclosingElement3: <testLibraryFragment>::@extensionType::B
              type: int
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::B::@getter::it
              enclosingElement3: <testLibraryFragment>::@extensionType::B
              returnType: int
      mixins
        mixin M @56
          reference: <testLibraryFragment>::@mixin::M
          enclosingElement3: <testLibraryFragment>
          superclassConstraints
            Object
          interfaces
            A
            C
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
        class C @45
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C#element
      extensionTypes
        extension type B @26
          reference: <testLibraryFragment>::@extensionType::B
          element: <testLibraryFragment>::@extensionType::B#element
          fields
            it @32
              reference: <testLibraryFragment>::@extensionType::B::@field::it
              element: <testLibraryFragment>::@extensionType::B::@field::it#element
              getter2: <testLibraryFragment>::@extensionType::B::@getter::it
          getters
            get it @-1
              reference: <testLibraryFragment>::@extensionType::B::@getter::it
              element: <testLibraryFragment>::@extensionType::B::@getter::it#element
      mixins
        mixin M @56
          reference: <testLibraryFragment>::@mixin::M
          element: <testLibraryFragment>::@mixin::M#element
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
    class C
      firstFragment: <testLibraryFragment>::@class::C
  extensionTypes
    extension type B
      firstFragment: <testLibraryFragment>::@extensionType::B
      typeErasure: int
      fields
        final it
          firstFragment: <testLibraryFragment>::@extensionType::B::@field::it
          type: int
          getter: <testLibraryFragment>::@extensionType::B::@getter::it#element
      getters
        synthetic get it
          firstFragment: <testLibraryFragment>::@extensionType::B::@getter::it
  mixins
    mixin M
      firstFragment: <testLibraryFragment>::@mixin::M
      superclassConstraints
        Object
''');
  }

  test_mixin_method_invokesSuperSelf() async {
    var library = await buildLibrary(r'''
mixin M on A {
  void foo() {
    super.foo();
  }
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      mixins
        mixin M @6
          reference: <testLibraryFragment>::@mixin::M
          enclosingElement3: <testLibraryFragment>
          superclassConstraints
            Object
          methods
            foo @22 invokesSuperSelf
              reference: <testLibraryFragment>::@mixin::M::@method::foo
              enclosingElement3: <testLibraryFragment>::@mixin::M
              returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      mixins
        mixin M @6
          reference: <testLibraryFragment>::@mixin::M
          element: <testLibraryFragment>::@mixin::M#element
          methods
            foo @22 invokesSuperSelf
              reference: <testLibraryFragment>::@mixin::M::@method::foo
              element: <testLibraryFragment>::@mixin::M::@method::foo#element
  mixins
    mixin M
      firstFragment: <testLibraryFragment>::@mixin::M
      superclassConstraints
        Object
      methods
        foo
          firstFragment: <testLibraryFragment>::@mixin::M::@method::foo
''');
  }

  test_mixin_method_namedAsConstraint() async {
    var library = await buildLibrary(r'''
class A {}
mixin B on A {
  void A() {}
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
      mixins
        mixin B @17
          reference: <testLibraryFragment>::@mixin::B
          enclosingElement3: <testLibraryFragment>
          superclassConstraints
            A
          methods
            A @33
              reference: <testLibraryFragment>::@mixin::B::@method::A
              enclosingElement3: <testLibraryFragment>::@mixin::B
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
      mixins
        mixin B @17
          reference: <testLibraryFragment>::@mixin::B
          element: <testLibraryFragment>::@mixin::B#element
          methods
            A @33
              reference: <testLibraryFragment>::@mixin::B::@method::A
              element: <testLibraryFragment>::@mixin::B::@method::A#element
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
  mixins
    mixin B
      firstFragment: <testLibraryFragment>::@mixin::B
      superclassConstraints
        A
      methods
        A
          firstFragment: <testLibraryFragment>::@mixin::B::@method::A
''');
  }

  test_mixin_setter_invokesSuperSelf_getter() async {
    var library = await buildLibrary(r'''
mixin M on A {
  set foo(int _) {
    super.foo;
  }
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      mixins
        mixin M @6
          reference: <testLibraryFragment>::@mixin::M
          enclosingElement3: <testLibraryFragment>
          superclassConstraints
            Object
          fields
            synthetic foo @-1
              reference: <testLibraryFragment>::@mixin::M::@field::foo
              enclosingElement3: <testLibraryFragment>::@mixin::M
              type: int
          accessors
            set foo= @21
              reference: <testLibraryFragment>::@mixin::M::@setter::foo
              enclosingElement3: <testLibraryFragment>::@mixin::M
              parameters
                requiredPositional _ @29
                  type: int
              returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      mixins
        mixin M @6
          reference: <testLibraryFragment>::@mixin::M
          element: <testLibraryFragment>::@mixin::M#element
          fields
            foo @-1
              reference: <testLibraryFragment>::@mixin::M::@field::foo
              element: <testLibraryFragment>::@mixin::M::@field::foo#element
              setter2: <testLibraryFragment>::@mixin::M::@setter::foo
          setters
            set foo= @21
              reference: <testLibraryFragment>::@mixin::M::@setter::foo
              element: <testLibraryFragment>::@mixin::M::@setter::foo#element
              formalParameters
                _ @29
                  element: <testLibraryFragment>::@mixin::M::@setter::foo::@parameter::_#element
  mixins
    mixin M
      firstFragment: <testLibraryFragment>::@mixin::M
      superclassConstraints
        Object
      fields
        synthetic foo
          firstFragment: <testLibraryFragment>::@mixin::M::@field::foo
          type: int
          setter: <testLibraryFragment>::@mixin::M::@setter::foo#element
      setters
        set foo=
          firstFragment: <testLibraryFragment>::@mixin::M::@setter::foo
          formalParameters
            requiredPositional _
              type: int
''');
  }

  test_mixin_setter_invokesSuperSelf_setter() async {
    var library = await buildLibrary(r'''
mixin M on A {
  set foo(int _) {
    super.foo = 0;
  }
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      mixins
        mixin M @6
          reference: <testLibraryFragment>::@mixin::M
          enclosingElement3: <testLibraryFragment>
          superclassConstraints
            Object
          fields
            synthetic foo @-1
              reference: <testLibraryFragment>::@mixin::M::@field::foo
              enclosingElement3: <testLibraryFragment>::@mixin::M
              type: int
          accessors
            set foo= @21 invokesSuperSelf
              reference: <testLibraryFragment>::@mixin::M::@setter::foo
              enclosingElement3: <testLibraryFragment>::@mixin::M
              parameters
                requiredPositional _ @29
                  type: int
              returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      mixins
        mixin M @6
          reference: <testLibraryFragment>::@mixin::M
          element: <testLibraryFragment>::@mixin::M#element
          fields
            foo @-1
              reference: <testLibraryFragment>::@mixin::M::@field::foo
              element: <testLibraryFragment>::@mixin::M::@field::foo#element
              setter2: <testLibraryFragment>::@mixin::M::@setter::foo
          setters
            set foo= @21
              reference: <testLibraryFragment>::@mixin::M::@setter::foo
              element: <testLibraryFragment>::@mixin::M::@setter::foo#element
              formalParameters
                _ @29
                  element: <testLibraryFragment>::@mixin::M::@setter::foo::@parameter::_#element
  mixins
    mixin M
      firstFragment: <testLibraryFragment>::@mixin::M
      superclassConstraints
        Object
      fields
        synthetic foo
          firstFragment: <testLibraryFragment>::@mixin::M::@field::foo
          type: int
          setter: <testLibraryFragment>::@mixin::M::@setter::foo#element
      setters
        set foo=
          firstFragment: <testLibraryFragment>::@mixin::M::@setter::foo
          formalParameters
            requiredPositional _
              type: int
''');
  }

  test_mixin_superclassConstraints_extensionType() async {
    var library = await buildLibrary(r'''
class A {}
extension type B(int it) {}
class C {}
mixin M on A, B, C {}
''');
    configuration.withConstructors = false;
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
        class C @45
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
      extensionTypes
        B @26
          reference: <testLibraryFragment>::@extensionType::B
          enclosingElement3: <testLibraryFragment>
          representation: <testLibraryFragment>::@extensionType::B::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::B::@constructor::new
          typeErasure: int
          fields
            final it @32
              reference: <testLibraryFragment>::@extensionType::B::@field::it
              enclosingElement3: <testLibraryFragment>::@extensionType::B
              type: int
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::B::@getter::it
              enclosingElement3: <testLibraryFragment>::@extensionType::B
              returnType: int
      mixins
        mixin M @56
          reference: <testLibraryFragment>::@mixin::M
          enclosingElement3: <testLibraryFragment>
          superclassConstraints
            A
            C
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
        class C @45
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C#element
      extensionTypes
        extension type B @26
          reference: <testLibraryFragment>::@extensionType::B
          element: <testLibraryFragment>::@extensionType::B#element
          fields
            it @32
              reference: <testLibraryFragment>::@extensionType::B::@field::it
              element: <testLibraryFragment>::@extensionType::B::@field::it#element
              getter2: <testLibraryFragment>::@extensionType::B::@getter::it
          getters
            get it @-1
              reference: <testLibraryFragment>::@extensionType::B::@getter::it
              element: <testLibraryFragment>::@extensionType::B::@getter::it#element
      mixins
        mixin M @56
          reference: <testLibraryFragment>::@mixin::M
          element: <testLibraryFragment>::@mixin::M#element
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
    class C
      firstFragment: <testLibraryFragment>::@class::C
  extensionTypes
    extension type B
      firstFragment: <testLibraryFragment>::@extensionType::B
      typeErasure: int
      fields
        final it
          firstFragment: <testLibraryFragment>::@extensionType::B::@field::it
          type: int
          getter: <testLibraryFragment>::@extensionType::B::@getter::it#element
      getters
        synthetic get it
          firstFragment: <testLibraryFragment>::@extensionType::B::@getter::it
  mixins
    mixin M
      firstFragment: <testLibraryFragment>::@mixin::M
      superclassConstraints
        A
        C
''');
  }

  test_mixin_typeParameters_variance_contravariant() async {
    var library = await buildLibrary('mixin M<in T> {}');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      mixins
        mixin M @6
          reference: <testLibraryFragment>::@mixin::M
          enclosingElement3: <testLibraryFragment>
          typeParameters
            contravariant T @11
              defaultType: dynamic
          superclassConstraints
            Object
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      mixins
        mixin M @6
          reference: <testLibraryFragment>::@mixin::M
          element: <testLibraryFragment>::@mixin::M#element
          typeParameters
            T @11
              element: <not-implemented>
  mixins
    mixin M
      firstFragment: <testLibraryFragment>::@mixin::M
      typeParameters
        T
      superclassConstraints
        Object
''');
  }

  test_mixin_typeParameters_variance_covariant() async {
    var library = await buildLibrary('mixin M<out T> {}');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      mixins
        mixin M @6
          reference: <testLibraryFragment>::@mixin::M
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant T @12
              defaultType: dynamic
          superclassConstraints
            Object
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      mixins
        mixin M @6
          reference: <testLibraryFragment>::@mixin::M
          element: <testLibraryFragment>::@mixin::M#element
          typeParameters
            T @12
              element: <not-implemented>
  mixins
    mixin M
      firstFragment: <testLibraryFragment>::@mixin::M
      typeParameters
        T
      superclassConstraints
        Object
''');
  }

  test_mixin_typeParameters_variance_invariant() async {
    var library = await buildLibrary('mixin M<inout T> {}');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      mixins
        mixin M @6
          reference: <testLibraryFragment>::@mixin::M
          enclosingElement3: <testLibraryFragment>
          typeParameters
            invariant T @14
              defaultType: dynamic
          superclassConstraints
            Object
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      mixins
        mixin M @6
          reference: <testLibraryFragment>::@mixin::M
          element: <testLibraryFragment>::@mixin::M#element
          typeParameters
            T @14
              element: <not-implemented>
  mixins
    mixin M
      firstFragment: <testLibraryFragment>::@mixin::M
      typeParameters
        T
      superclassConstraints
        Object
''');
  }

  test_mixin_typeParameters_variance_multiple() async {
    var library = await buildLibrary('mixin M<inout T, in U, out V> {}');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      mixins
        mixin M @6
          reference: <testLibraryFragment>::@mixin::M
          enclosingElement3: <testLibraryFragment>
          typeParameters
            invariant T @14
              defaultType: dynamic
            contravariant U @20
              defaultType: dynamic
            covariant V @27
              defaultType: dynamic
          superclassConstraints
            Object
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      mixins
        mixin M @6
          reference: <testLibraryFragment>::@mixin::M
          element: <testLibraryFragment>::@mixin::M#element
          typeParameters
            T @14
              element: <not-implemented>
            U @20
              element: <not-implemented>
            V @27
              element: <not-implemented>
  mixins
    mixin M
      firstFragment: <testLibraryFragment>::@mixin::M
      typeParameters
        T
        U
        V
      superclassConstraints
        Object
''');
  }
}

abstract class MixinElementTest_augmentation extends ElementsBaseTest {
  test_allSupertypes() async {
    var library = await buildLibrary(r'''
mixin M {}
class A with M {}
''');

    configuration
      ..withAllSupertypes = true
      ..withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        class A @17
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          supertype: Object
          mixins
            M
          allSupertypes
            M
            Object
      mixins
        mixin M @6
          reference: <testLibraryFragment>::@mixin::M
          enclosingElement3: <testLibraryFragment>
          superclassConstraints
            Object
          allSupertypes
            Object
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @17
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A#element
      mixins
        mixin M @6
          reference: <testLibraryFragment>::@mixin::M
          element: <testLibraryFragment>::@mixin::M#element
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
      supertype: Object
      allSupertypes
        M
        Object
  mixins
    mixin M
      firstFragment: <testLibraryFragment>::@mixin::M
      superclassConstraints
        Object
      allSupertypes
        Object
''');
  }

  test_allSupertypes_hasSuperclassConstraints() async {
    var library = await buildLibrary(r'''
class A {}
mixin M on A {}
class B with M {}
''');

    configuration
      ..withAllSupertypes = true
      ..withConstructors = false;
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
          allSupertypes
            Object
        class B @33
          reference: <testLibraryFragment>::@class::B
          enclosingElement3: <testLibraryFragment>
          supertype: Object
          mixins
            M
          allSupertypes
            A
            M
            Object
      mixins
        mixin M @17
          reference: <testLibraryFragment>::@mixin::M
          enclosingElement3: <testLibraryFragment>
          superclassConstraints
            A
          allSupertypes
            A
            Object
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
        class B @33
          reference: <testLibraryFragment>::@class::B
          element: <testLibraryFragment>::@class::B#element
      mixins
        mixin M @17
          reference: <testLibraryFragment>::@mixin::M
          element: <testLibraryFragment>::@mixin::M#element
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
      allSupertypes
        Object
    class B
      firstFragment: <testLibraryFragment>::@class::B
      supertype: Object
      allSupertypes
        A
        M
        Object
  mixins
    mixin M
      firstFragment: <testLibraryFragment>::@mixin::M
      superclassConstraints
        A
      allSupertypes
        A
        Object
''');
  }

  test_augmentationTarget() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
part 'b.dart';
augment mixin A {}
''');

    newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';
augment mixin A {}
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
  parts
    part_0
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
      parts
        part_1
          uri: package:test/b.dart
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          unit: <testLibrary>::@fragment::package:test/b.dart
      mixins
        augment mixin A @50
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@mixin::A
          augmentation: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
      mixins
        augment mixin A @32
          reference: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/b.dart
          augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
  exportedReferences
    declared <testLibraryFragment>::@mixin::A
  exportNamespace
    A: <testLibraryFragment>::@mixin::A
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
          element: <testLibraryFragment>::@mixin::A#element
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      mixins
        mixin A @50
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          element: <testLibraryFragment>::@mixin::A#element
          previousFragment: <testLibraryFragment>::@mixin::A
          nextFragment: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A
    <testLibrary>::@fragment::package:test/b.dart
      element: <testLibrary>
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      mixins
        mixin A @32
          reference: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A
          element: <testLibraryFragment>::@mixin::A#element
          previousFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
  mixins
    mixin A
      firstFragment: <testLibraryFragment>::@mixin::A
      superclassConstraints
        Object
  exportedReferences
    declared <testLibraryFragment>::@mixin::A
  exportNamespace
    A: <testLibraryFragment>::@mixin::A
''');
  }

  test_augmentationTarget_augmentationThenDeclaration() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';

augment class A {
  void foo1() {}
}

class A {
  void foo2() {}
}

augment class A {
  void foo3() {}
}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  parts
    part_0
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
      classes
        augment class A @36
          reference: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@def::0
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          constructors
            synthetic @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@def::0::@constructor::new
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@def::0
          methods
            foo1 @47
              reference: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@def::0::@method::foo1
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@def::0
              returnType: void
        class A @66
          reference: <testLibrary>::@fragment::package:test/a.dart::@class::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@def::1
          constructors
            synthetic @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@class::A::@constructor::new
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@class::A
          methods
            foo2 @77
              reference: <testLibrary>::@fragment::package:test/a.dart::@class::A::@method::foo2
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@class::A
              returnType: void
          augmented
            constructors
              <testLibrary>::@fragment::package:test/a.dart::@class::A::@constructor::new
            methods
              <testLibrary>::@fragment::package:test/a.dart::@class::A::@method::foo2
              <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@def::1::@method::foo3
        augment class A @104
          reference: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@def::1
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@class::A
          methods
            foo3 @115
              reference: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@def::1::@method::foo3
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@def::1
              returnType: void
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
      classes
        class A @36
          reference: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@def::0
          element: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@def::0#element
          constructors
            synthetic new @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@def::0::@constructor::new
              element: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@def::0::@constructor::new#element
          methods
            foo1 @47
              reference: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@def::0::@method::foo1
              element: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@def::0::@method::foo1#element
        class A @66
          reference: <testLibrary>::@fragment::package:test/a.dart::@class::A
          element: <testLibrary>::@fragment::package:test/a.dart::@class::A#element
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@def::1
          constructors
            synthetic new @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@class::A::@constructor::new
              element: <testLibrary>::@fragment::package:test/a.dart::@class::A::@constructor::new#element
          methods
            foo2 @77
              reference: <testLibrary>::@fragment::package:test/a.dart::@class::A::@method::foo2
              element: <testLibrary>::@fragment::package:test/a.dart::@class::A::@method::foo2#element
        class A @104
          reference: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@def::1
          element: <testLibrary>::@fragment::package:test/a.dart::@class::A#element
          previousFragment: <testLibrary>::@fragment::package:test/a.dart::@class::A
          methods
            foo3 @115
              reference: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@def::1::@method::foo3
              element: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@def::1::@method::foo3#element
  classes
    class A
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@def::0
      constructors
        synthetic new
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@def::0::@constructor::new
      methods
        foo1
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@def::0::@method::foo1
    class A
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@class::A
      constructors
        synthetic new
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@class::A::@constructor::new
      methods
        foo2
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@class::A::@method::foo2
        foo3
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@def::1::@method::foo3
''');
  }

  test_augmentationTarget_no2() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
part 'b.dart';
augment mixin A {
  void foo1() {}
}
''');

    newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';
augment mixin A {
  void foo2() {}
}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
mixin B {}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  parts
    part_0
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      mixins
        mixin B @21
          reference: <testLibraryFragment>::@mixin::B
          enclosingElement3: <testLibraryFragment>
          superclassConstraints
            Object
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      parts
        part_1
          uri: package:test/b.dart
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          unit: <testLibrary>::@fragment::package:test/b.dart
      mixins
        augment mixin A @50
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          augmentation: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A
          superclassConstraints
            Object
          methods
            foo1 @61
              reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@method::foo1
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
              returnType: void
          augmented
            superclassConstraints
              Object
            methods
              <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@method::foo1
              <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A::@method::foo2
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
      mixins
        augment mixin A @32
          reference: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/b.dart
          augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          methods
            foo2 @43
              reference: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A::@method::foo2
              enclosingElement3: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A
              returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      mixins
        mixin B @21
          reference: <testLibraryFragment>::@mixin::B
          element: <testLibraryFragment>::@mixin::B#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      mixins
        mixin A @50
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          element: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A#element
          nextFragment: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A
          methods
            foo1 @61
              reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@method::foo1
              element: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@method::foo1#element
    <testLibrary>::@fragment::package:test/b.dart
      element: <testLibrary>
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      mixins
        mixin A @32
          reference: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A
          element: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A#element
          previousFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          methods
            foo2 @43
              reference: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A::@method::foo2
              element: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A::@method::foo2#element
  mixins
    mixin B
      firstFragment: <testLibraryFragment>::@mixin::B
      superclassConstraints
        Object
    mixin A
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
      superclassConstraints
        Object
      methods
        foo1
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@method::foo1
        foo2
          firstFragment: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A::@method::foo2
''');
  }

  test_augmented_field_augment_field() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment mixin A {
  augment int foo = 1;
}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
mixin A {
  int foo = 0;
}
''');

    configuration.withPropertyLinking = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  parts
    part_0
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
          fields
            foo @31
              reference: <testLibraryFragment>::@mixin::A::@field::foo
              enclosingElement3: <testLibraryFragment>::@mixin::A
              type: int
              shouldUseTypeForInitializerInference: true
              id: field_0
              getter: getter_0
              setter: setter_0
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@fieldAugmentation::foo
          accessors
            synthetic get foo @-1
              reference: <testLibraryFragment>::@mixin::A::@getter::foo
              enclosingElement3: <testLibraryFragment>::@mixin::A
              returnType: int
              id: getter_0
              variable: field_0
            synthetic set foo= @-1
              reference: <testLibraryFragment>::@mixin::A::@setter::foo
              enclosingElement3: <testLibraryFragment>::@mixin::A
              parameters
                requiredPositional _foo @-1
                  type: int
              returnType: void
              id: setter_0
              variable: field_0
          augmented
            superclassConstraints
              Object
            fields
              <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@fieldAugmentation::foo
            accessors
              <testLibraryFragment>::@mixin::A::@getter::foo
              <testLibraryFragment>::@mixin::A::@setter::foo
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      mixins
        augment mixin A @35
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@mixin::A
          fields
            augment foo @53
              reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@fieldAugmentation::foo
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
              type: int
              shouldUseTypeForInitializerInference: true
              id: field_1
              augmentationTarget: <testLibraryFragment>::@mixin::A::@field::foo
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
          element: <testLibraryFragment>::@mixin::A#element
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          fields
            foo @31
              reference: <testLibraryFragment>::@mixin::A::@field::foo
              element: <testLibraryFragment>::@mixin::A::@field::foo#element
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@fieldAugmentation::foo
              getter2: <testLibraryFragment>::@mixin::A::@getter::foo
              setter2: <testLibraryFragment>::@mixin::A::@setter::foo
          getters
            get foo @-1
              reference: <testLibraryFragment>::@mixin::A::@getter::foo
              element: <testLibraryFragment>::@mixin::A::@getter::foo#element
          setters
            set foo= @-1
              reference: <testLibraryFragment>::@mixin::A::@setter::foo
              element: <testLibraryFragment>::@mixin::A::@setter::foo#element
              formalParameters
                _foo @-1
                  element: <testLibraryFragment>::@mixin::A::@setter::foo::@parameter::_foo#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      mixins
        mixin A @35
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          element: <testLibraryFragment>::@mixin::A#element
          previousFragment: <testLibraryFragment>::@mixin::A
          fields
            foo @53
              reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@fieldAugmentation::foo
              element: <testLibraryFragment>::@mixin::A::@field::foo#element
              previousFragment: <testLibraryFragment>::@mixin::A::@field::foo
  mixins
    mixin A
      firstFragment: <testLibraryFragment>::@mixin::A
      superclassConstraints
        Object
      fields
        foo
          firstFragment: <testLibraryFragment>::@mixin::A::@field::foo
          type: int
          getter: <testLibraryFragment>::@mixin::A::@getter::foo#element
          setter: <testLibraryFragment>::@mixin::A::@setter::foo#element
      getters
        synthetic get foo
          firstFragment: <testLibraryFragment>::@mixin::A::@getter::foo
      setters
        synthetic set foo=
          firstFragment: <testLibraryFragment>::@mixin::A::@setter::foo
          formalParameters
            requiredPositional _foo
              type: int
''');
  }

  test_augmented_field_augment_field2() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment mixin A {
  augment int foo = 1;
}
''');

    newFile('$testPackageLibPath/b.dart', r'''
part of 'test.dart';
augment mixin A {
  augment int foo = 2;
}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
part 'b.dart';
mixin A {
  int foo = 0;
}
''');

    configuration.withPropertyLinking = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  parts
    part_0
    part_1
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
        part_1
          uri: package:test/b.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/b.dart
      mixins
        mixin A @36
          reference: <testLibraryFragment>::@mixin::A
          enclosingElement3: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          superclassConstraints
            Object
          fields
            foo @46
              reference: <testLibraryFragment>::@mixin::A::@field::foo
              enclosingElement3: <testLibraryFragment>::@mixin::A
              type: int
              shouldUseTypeForInitializerInference: true
              id: field_0
              getter: getter_0
              setter: setter_0
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@fieldAugmentation::foo
          accessors
            synthetic get foo @-1
              reference: <testLibraryFragment>::@mixin::A::@getter::foo
              enclosingElement3: <testLibraryFragment>::@mixin::A
              returnType: int
              id: getter_0
              variable: field_0
            synthetic set foo= @-1
              reference: <testLibraryFragment>::@mixin::A::@setter::foo
              enclosingElement3: <testLibraryFragment>::@mixin::A
              parameters
                requiredPositional _foo @-1
                  type: int
              returnType: void
              id: setter_0
              variable: field_0
          augmented
            superclassConstraints
              Object
            fields
              <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A::@fieldAugmentation::foo
            accessors
              <testLibraryFragment>::@mixin::A::@getter::foo
              <testLibraryFragment>::@mixin::A::@setter::foo
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      mixins
        augment mixin A @35
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@mixin::A
          augmentation: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A
          fields
            augment foo @53
              reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@fieldAugmentation::foo
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
              type: int
              shouldUseTypeForInitializerInference: true
              id: field_1
              augmentationTarget: <testLibraryFragment>::@mixin::A::@field::foo
              augmentation: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A::@fieldAugmentation::foo
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement3: <testLibraryFragment>
      mixins
        augment mixin A @35
          reference: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/b.dart
          augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          fields
            augment foo @53
              reference: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A::@fieldAugmentation::foo
              enclosingElement3: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A
              type: int
              shouldUseTypeForInitializerInference: true
              id: field_2
              augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@fieldAugmentation::foo
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      mixins
        mixin A @36
          reference: <testLibraryFragment>::@mixin::A
          element: <testLibraryFragment>::@mixin::A#element
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          fields
            foo @46
              reference: <testLibraryFragment>::@mixin::A::@field::foo
              element: <testLibraryFragment>::@mixin::A::@field::foo#element
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@fieldAugmentation::foo
              getter2: <testLibraryFragment>::@mixin::A::@getter::foo
              setter2: <testLibraryFragment>::@mixin::A::@setter::foo
          getters
            get foo @-1
              reference: <testLibraryFragment>::@mixin::A::@getter::foo
              element: <testLibraryFragment>::@mixin::A::@getter::foo#element
          setters
            set foo= @-1
              reference: <testLibraryFragment>::@mixin::A::@setter::foo
              element: <testLibraryFragment>::@mixin::A::@setter::foo#element
              formalParameters
                _foo @-1
                  element: <testLibraryFragment>::@mixin::A::@setter::foo::@parameter::_foo#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      mixins
        mixin A @35
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          element: <testLibraryFragment>::@mixin::A#element
          previousFragment: <testLibraryFragment>::@mixin::A
          nextFragment: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A
          fields
            foo @53
              reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@fieldAugmentation::foo
              element: <testLibraryFragment>::@mixin::A::@field::foo#element
              previousFragment: <testLibraryFragment>::@mixin::A::@field::foo
              nextFragment: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A::@fieldAugmentation::foo
    <testLibrary>::@fragment::package:test/b.dart
      element: <testLibrary>
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      mixins
        mixin A @35
          reference: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A
          element: <testLibraryFragment>::@mixin::A#element
          previousFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          fields
            foo @53
              reference: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A::@fieldAugmentation::foo
              element: <testLibraryFragment>::@mixin::A::@field::foo#element
              previousFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@fieldAugmentation::foo
  mixins
    mixin A
      firstFragment: <testLibraryFragment>::@mixin::A
      superclassConstraints
        Object
      fields
        foo
          firstFragment: <testLibraryFragment>::@mixin::A::@field::foo
          type: int
          getter: <testLibraryFragment>::@mixin::A::@getter::foo#element
          setter: <testLibraryFragment>::@mixin::A::@setter::foo#element
      getters
        synthetic get foo
          firstFragment: <testLibraryFragment>::@mixin::A::@getter::foo
      setters
        synthetic set foo=
          firstFragment: <testLibraryFragment>::@mixin::A::@setter::foo
          formalParameters
            requiredPositional _foo
              type: int
''');
  }

  test_augmented_field_augment_field_afterGetter() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment mixin A {
  augment int get foo => 1;
}
''');

    newFile('$testPackageLibPath/b.dart', r'''
part of 'test.dart';
augment mixin A {
  augment int foo = 2;
}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
part 'b.dart';
mixin A {
  int foo = 0;
}
''');

    configuration.withPropertyLinking = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  parts
    part_0
    part_1
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
        part_1
          uri: package:test/b.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/b.dart
      mixins
        mixin A @36
          reference: <testLibraryFragment>::@mixin::A
          enclosingElement3: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          superclassConstraints
            Object
          fields
            foo @46
              reference: <testLibraryFragment>::@mixin::A::@field::foo
              enclosingElement3: <testLibraryFragment>::@mixin::A
              type: int
              shouldUseTypeForInitializerInference: true
              id: field_0
              getter: getter_0
              setter: setter_0
              augmentation: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A::@fieldAugmentation::foo
          accessors
            synthetic get foo @-1
              reference: <testLibraryFragment>::@mixin::A::@getter::foo
              enclosingElement3: <testLibraryFragment>::@mixin::A
              returnType: int
              id: getter_0
              variable: field_0
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@getterAugmentation::foo
            synthetic set foo= @-1
              reference: <testLibraryFragment>::@mixin::A::@setter::foo
              enclosingElement3: <testLibraryFragment>::@mixin::A
              parameters
                requiredPositional _foo @-1
                  type: int
              returnType: void
              id: setter_0
              variable: field_0
          augmented
            superclassConstraints
              Object
            fields
              <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A::@fieldAugmentation::foo
            accessors
              <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@getterAugmentation::foo
              <testLibraryFragment>::@mixin::A::@setter::foo
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      mixins
        augment mixin A @35
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@mixin::A
          augmentation: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A
          accessors
            augment get foo @57
              reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@getterAugmentation::foo
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
              returnType: int
              id: getter_1
              variable: field_0
              augmentationTarget: <testLibraryFragment>::@mixin::A::@getter::foo
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement3: <testLibraryFragment>
      mixins
        augment mixin A @35
          reference: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/b.dart
          augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          fields
            augment foo @53
              reference: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A::@fieldAugmentation::foo
              enclosingElement3: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A
              type: int
              shouldUseTypeForInitializerInference: true
              id: field_1
              augmentationTarget: <testLibraryFragment>::@mixin::A::@field::foo
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      mixins
        mixin A @36
          reference: <testLibraryFragment>::@mixin::A
          element: <testLibraryFragment>::@mixin::A#element
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          fields
            foo @46
              reference: <testLibraryFragment>::@mixin::A::@field::foo
              element: <testLibraryFragment>::@mixin::A::@field::foo#element
              nextFragment: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A::@fieldAugmentation::foo
              getter2: <testLibraryFragment>::@mixin::A::@getter::foo
              setter2: <testLibraryFragment>::@mixin::A::@setter::foo
          getters
            get foo @-1
              reference: <testLibraryFragment>::@mixin::A::@getter::foo
              element: <testLibraryFragment>::@mixin::A::@getter::foo#element
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@getterAugmentation::foo
          setters
            set foo= @-1
              reference: <testLibraryFragment>::@mixin::A::@setter::foo
              element: <testLibraryFragment>::@mixin::A::@setter::foo#element
              formalParameters
                _foo @-1
                  element: <testLibraryFragment>::@mixin::A::@setter::foo::@parameter::_foo#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      mixins
        mixin A @35
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          element: <testLibraryFragment>::@mixin::A#element
          previousFragment: <testLibraryFragment>::@mixin::A
          nextFragment: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A
          getters
            augment get foo @57
              reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@getterAugmentation::foo
              element: <testLibraryFragment>::@mixin::A::@getter::foo#element
              previousFragment: <testLibraryFragment>::@mixin::A::@getter::foo
    <testLibrary>::@fragment::package:test/b.dart
      element: <testLibrary>
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      mixins
        mixin A @35
          reference: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A
          element: <testLibraryFragment>::@mixin::A#element
          previousFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          fields
            foo @53
              reference: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A::@fieldAugmentation::foo
              element: <testLibraryFragment>::@mixin::A::@field::foo#element
              previousFragment: <testLibraryFragment>::@mixin::A::@field::foo
  mixins
    mixin A
      firstFragment: <testLibraryFragment>::@mixin::A
      superclassConstraints
        Object
      fields
        foo
          firstFragment: <testLibraryFragment>::@mixin::A::@field::foo
          type: int
          getter: <testLibraryFragment>::@mixin::A::@getter::foo#element
          setter: <testLibraryFragment>::@mixin::A::@setter::foo#element
      getters
        synthetic get foo
          firstFragment: <testLibraryFragment>::@mixin::A::@getter::foo
      setters
        synthetic set foo=
          firstFragment: <testLibraryFragment>::@mixin::A::@setter::foo
          formalParameters
            requiredPositional _foo
              type: int
''');
  }

  test_augmented_field_augment_field_afterSetter() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment mixin A {
  augment set foo(int _) {}
}
''');

    newFile('$testPackageLibPath/b.dart', r'''
part of 'test.dart';
augment mixin A {
  augment int foo = 2;
}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
part 'b.dart';
mixin A {
  int foo = 0;
}
''');

    configuration.withPropertyLinking = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  parts
    part_0
    part_1
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
        part_1
          uri: package:test/b.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/b.dart
      mixins
        mixin A @36
          reference: <testLibraryFragment>::@mixin::A
          enclosingElement3: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          superclassConstraints
            Object
          fields
            foo @46
              reference: <testLibraryFragment>::@mixin::A::@field::foo
              enclosingElement3: <testLibraryFragment>::@mixin::A
              type: int
              shouldUseTypeForInitializerInference: true
              id: field_0
              getter: getter_0
              setter: setter_0
              augmentation: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A::@fieldAugmentation::foo
          accessors
            synthetic get foo @-1
              reference: <testLibraryFragment>::@mixin::A::@getter::foo
              enclosingElement3: <testLibraryFragment>::@mixin::A
              returnType: int
              id: getter_0
              variable: field_0
            synthetic set foo= @-1
              reference: <testLibraryFragment>::@mixin::A::@setter::foo
              enclosingElement3: <testLibraryFragment>::@mixin::A
              parameters
                requiredPositional _foo @-1
                  type: int
              returnType: void
              id: setter_0
              variable: field_0
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@setterAugmentation::foo
          augmented
            superclassConstraints
              Object
            fields
              <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A::@fieldAugmentation::foo
            accessors
              <testLibraryFragment>::@mixin::A::@getter::foo
              <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@setterAugmentation::foo
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      mixins
        augment mixin A @35
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@mixin::A
          augmentation: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A
          accessors
            augment set foo= @53
              reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@setterAugmentation::foo
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
              parameters
                requiredPositional _ @61
                  type: int
              returnType: void
              id: setter_1
              variable: field_0
              augmentationTarget: <testLibraryFragment>::@mixin::A::@setter::foo
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement3: <testLibraryFragment>
      mixins
        augment mixin A @35
          reference: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/b.dart
          augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          fields
            augment foo @53
              reference: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A::@fieldAugmentation::foo
              enclosingElement3: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A
              type: int
              shouldUseTypeForInitializerInference: true
              id: field_1
              augmentationTarget: <testLibraryFragment>::@mixin::A::@field::foo
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      mixins
        mixin A @36
          reference: <testLibraryFragment>::@mixin::A
          element: <testLibraryFragment>::@mixin::A#element
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          fields
            foo @46
              reference: <testLibraryFragment>::@mixin::A::@field::foo
              element: <testLibraryFragment>::@mixin::A::@field::foo#element
              nextFragment: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A::@fieldAugmentation::foo
              getter2: <testLibraryFragment>::@mixin::A::@getter::foo
              setter2: <testLibraryFragment>::@mixin::A::@setter::foo
          getters
            get foo @-1
              reference: <testLibraryFragment>::@mixin::A::@getter::foo
              element: <testLibraryFragment>::@mixin::A::@getter::foo#element
          setters
            set foo= @-1
              reference: <testLibraryFragment>::@mixin::A::@setter::foo
              element: <testLibraryFragment>::@mixin::A::@setter::foo#element
              formalParameters
                _foo @-1
                  element: <testLibraryFragment>::@mixin::A::@setter::foo::@parameter::_foo#element
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@setterAugmentation::foo
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      mixins
        mixin A @35
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          element: <testLibraryFragment>::@mixin::A#element
          previousFragment: <testLibraryFragment>::@mixin::A
          nextFragment: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A
          setters
            augment set foo= @53
              reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@setterAugmentation::foo
              element: <testLibraryFragment>::@mixin::A::@setter::foo#element
              formalParameters
                _ @61
                  element: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@setterAugmentation::foo::@parameter::_#element
              previousFragment: <testLibraryFragment>::@mixin::A::@setter::foo
    <testLibrary>::@fragment::package:test/b.dart
      element: <testLibrary>
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      mixins
        mixin A @35
          reference: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A
          element: <testLibraryFragment>::@mixin::A#element
          previousFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          fields
            foo @53
              reference: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A::@fieldAugmentation::foo
              element: <testLibraryFragment>::@mixin::A::@field::foo#element
              previousFragment: <testLibraryFragment>::@mixin::A::@field::foo
  mixins
    mixin A
      firstFragment: <testLibraryFragment>::@mixin::A
      superclassConstraints
        Object
      fields
        foo
          firstFragment: <testLibraryFragment>::@mixin::A::@field::foo
          type: int
          getter: <testLibraryFragment>::@mixin::A::@getter::foo#element
          setter: <testLibraryFragment>::@mixin::A::@setter::foo#element
      getters
        synthetic get foo
          firstFragment: <testLibraryFragment>::@mixin::A::@getter::foo
      setters
        synthetic set foo=
          firstFragment: <testLibraryFragment>::@mixin::A::@setter::foo
          formalParameters
            requiredPositional _foo
              type: int
''');
  }

  test_augmented_field_augment_field_differentTypes() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment mixin A {
  augment double foo = 1.2;
}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
mixin A {
  int foo = 0;
}
''');

    configuration.withPropertyLinking = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  parts
    part_0
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
          fields
            foo @31
              reference: <testLibraryFragment>::@mixin::A::@field::foo
              enclosingElement3: <testLibraryFragment>::@mixin::A
              type: int
              shouldUseTypeForInitializerInference: true
              id: field_0
              getter: getter_0
              setter: setter_0
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@fieldAugmentation::foo
          accessors
            synthetic get foo @-1
              reference: <testLibraryFragment>::@mixin::A::@getter::foo
              enclosingElement3: <testLibraryFragment>::@mixin::A
              returnType: int
              id: getter_0
              variable: field_0
            synthetic set foo= @-1
              reference: <testLibraryFragment>::@mixin::A::@setter::foo
              enclosingElement3: <testLibraryFragment>::@mixin::A
              parameters
                requiredPositional _foo @-1
                  type: int
              returnType: void
              id: setter_0
              variable: field_0
          augmented
            superclassConstraints
              Object
            fields
              <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@fieldAugmentation::foo
            accessors
              <testLibraryFragment>::@mixin::A::@getter::foo
              <testLibraryFragment>::@mixin::A::@setter::foo
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      mixins
        augment mixin A @35
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@mixin::A
          fields
            augment foo @56
              reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@fieldAugmentation::foo
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
              type: double
              shouldUseTypeForInitializerInference: true
              id: field_1
              augmentationTarget: <testLibraryFragment>::@mixin::A::@field::foo
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
          element: <testLibraryFragment>::@mixin::A#element
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          fields
            foo @31
              reference: <testLibraryFragment>::@mixin::A::@field::foo
              element: <testLibraryFragment>::@mixin::A::@field::foo#element
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@fieldAugmentation::foo
              getter2: <testLibraryFragment>::@mixin::A::@getter::foo
              setter2: <testLibraryFragment>::@mixin::A::@setter::foo
          getters
            get foo @-1
              reference: <testLibraryFragment>::@mixin::A::@getter::foo
              element: <testLibraryFragment>::@mixin::A::@getter::foo#element
          setters
            set foo= @-1
              reference: <testLibraryFragment>::@mixin::A::@setter::foo
              element: <testLibraryFragment>::@mixin::A::@setter::foo#element
              formalParameters
                _foo @-1
                  element: <testLibraryFragment>::@mixin::A::@setter::foo::@parameter::_foo#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      mixins
        mixin A @35
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          element: <testLibraryFragment>::@mixin::A#element
          previousFragment: <testLibraryFragment>::@mixin::A
          fields
            foo @56
              reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@fieldAugmentation::foo
              element: <testLibraryFragment>::@mixin::A::@field::foo#element
              previousFragment: <testLibraryFragment>::@mixin::A::@field::foo
  mixins
    mixin A
      firstFragment: <testLibraryFragment>::@mixin::A
      superclassConstraints
        Object
      fields
        foo
          firstFragment: <testLibraryFragment>::@mixin::A::@field::foo
          type: int
          getter: <testLibraryFragment>::@mixin::A::@getter::foo#element
          setter: <testLibraryFragment>::@mixin::A::@setter::foo#element
      getters
        synthetic get foo
          firstFragment: <testLibraryFragment>::@mixin::A::@getter::foo
      setters
        synthetic set foo=
          firstFragment: <testLibraryFragment>::@mixin::A::@setter::foo
          formalParameters
            requiredPositional _foo
              type: int
''');
  }

  /// This is not allowed by the specification, but allowed syntactically,
  /// so we need a way to handle it.
  test_augmented_field_augment_getter() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment mixin A {
  augment int foo = 1;
}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
mixin A {
  int get foo => 0;
}
''');

    configuration.withPropertyLinking = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  parts
    part_0
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
          fields
            synthetic foo @-1
              reference: <testLibraryFragment>::@mixin::A::@field::foo
              enclosingElement3: <testLibraryFragment>::@mixin::A
              type: int
              id: field_0
              getter: getter_0
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@fieldAugmentation::foo
          accessors
            get foo @35
              reference: <testLibraryFragment>::@mixin::A::@getter::foo
              enclosingElement3: <testLibraryFragment>::@mixin::A
              returnType: int
              id: getter_0
              variable: field_0
          augmented
            superclassConstraints
              Object
            fields
              <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@fieldAugmentation::foo
            accessors
              <testLibraryFragment>::@mixin::A::@getter::foo
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      mixins
        augment mixin A @35
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@mixin::A
          fields
            augment foo @53
              reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@fieldAugmentation::foo
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
              type: int
              shouldUseTypeForInitializerInference: true
              id: field_1
              augmentationTarget: <testLibraryFragment>::@mixin::A::@field::foo
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
          element: <testLibraryFragment>::@mixin::A#element
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          fields
            foo @-1
              reference: <testLibraryFragment>::@mixin::A::@field::foo
              element: <testLibraryFragment>::@mixin::A::@field::foo#element
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@fieldAugmentation::foo
              getter2: <testLibraryFragment>::@mixin::A::@getter::foo
          getters
            get foo @35
              reference: <testLibraryFragment>::@mixin::A::@getter::foo
              element: <testLibraryFragment>::@mixin::A::@getter::foo#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      mixins
        mixin A @35
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          element: <testLibraryFragment>::@mixin::A#element
          previousFragment: <testLibraryFragment>::@mixin::A
          fields
            foo @53
              reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@fieldAugmentation::foo
              element: <testLibraryFragment>::@mixin::A::@field::foo#element
              previousFragment: <testLibraryFragment>::@mixin::A::@field::foo
  mixins
    mixin A
      firstFragment: <testLibraryFragment>::@mixin::A
      superclassConstraints
        Object
      fields
        synthetic foo
          firstFragment: <testLibraryFragment>::@mixin::A::@field::foo
          type: int
          getter: <testLibraryFragment>::@mixin::A::@getter::foo#element
      getters
        get foo
          firstFragment: <testLibraryFragment>::@mixin::A::@getter::foo
''');
  }

  test_augmented_fields_add() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment mixin A {
  int foo2 = 0;
}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
mixin A {
  int foo1 = 0;
}
''');

    configuration.withPropertyLinking = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  parts
    part_0
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
          fields
            foo1 @31
              reference: <testLibraryFragment>::@mixin::A::@field::foo1
              enclosingElement3: <testLibraryFragment>::@mixin::A
              type: int
              shouldUseTypeForInitializerInference: true
              id: field_0
              getter: getter_0
              setter: setter_0
          accessors
            synthetic get foo1 @-1
              reference: <testLibraryFragment>::@mixin::A::@getter::foo1
              enclosingElement3: <testLibraryFragment>::@mixin::A
              returnType: int
              id: getter_0
              variable: field_0
            synthetic set foo1= @-1
              reference: <testLibraryFragment>::@mixin::A::@setter::foo1
              enclosingElement3: <testLibraryFragment>::@mixin::A
              parameters
                requiredPositional _foo1 @-1
                  type: int
              returnType: void
              id: setter_0
              variable: field_0
          augmented
            superclassConstraints
              Object
            fields
              <testLibraryFragment>::@mixin::A::@field::foo1
              <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@field::foo2
            accessors
              <testLibraryFragment>::@mixin::A::@getter::foo1
              <testLibraryFragment>::@mixin::A::@setter::foo1
              <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@getter::foo2
              <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@setter::foo2
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      mixins
        augment mixin A @35
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@mixin::A
          fields
            foo2 @45
              reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@field::foo2
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
              type: int
              shouldUseTypeForInitializerInference: true
              id: field_1
              getter: getter_1
              setter: setter_1
          accessors
            synthetic get foo2 @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@getter::foo2
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
              returnType: int
              id: getter_1
              variable: field_1
            synthetic set foo2= @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@setter::foo2
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
              parameters
                requiredPositional _foo2 @-1
                  type: int
              returnType: void
              id: setter_1
              variable: field_1
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
          element: <testLibraryFragment>::@mixin::A#element
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          fields
            foo1 @31
              reference: <testLibraryFragment>::@mixin::A::@field::foo1
              element: <testLibraryFragment>::@mixin::A::@field::foo1#element
              getter2: <testLibraryFragment>::@mixin::A::@getter::foo1
              setter2: <testLibraryFragment>::@mixin::A::@setter::foo1
          getters
            get foo1 @-1
              reference: <testLibraryFragment>::@mixin::A::@getter::foo1
              element: <testLibraryFragment>::@mixin::A::@getter::foo1#element
          setters
            set foo1= @-1
              reference: <testLibraryFragment>::@mixin::A::@setter::foo1
              element: <testLibraryFragment>::@mixin::A::@setter::foo1#element
              formalParameters
                _foo1 @-1
                  element: <testLibraryFragment>::@mixin::A::@setter::foo1::@parameter::_foo1#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      mixins
        mixin A @35
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          element: <testLibraryFragment>::@mixin::A#element
          previousFragment: <testLibraryFragment>::@mixin::A
          fields
            foo2 @45
              reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@field::foo2
              element: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@field::foo2#element
              getter2: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@getter::foo2
              setter2: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@setter::foo2
          getters
            get foo2 @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@getter::foo2
              element: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@getter::foo2#element
          setters
            set foo2= @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@setter::foo2
              element: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@setter::foo2#element
              formalParameters
                _foo2 @-1
                  element: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@setter::foo2::@parameter::_foo2#element
  mixins
    mixin A
      firstFragment: <testLibraryFragment>::@mixin::A
      superclassConstraints
        Object
      fields
        foo1
          firstFragment: <testLibraryFragment>::@mixin::A::@field::foo1
          type: int
          getter: <testLibraryFragment>::@mixin::A::@getter::foo1#element
          setter: <testLibraryFragment>::@mixin::A::@setter::foo1#element
        foo2
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@field::foo2
          type: int
          getter: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@getter::foo2#element
          setter: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@setter::foo2#element
      getters
        synthetic get foo1
          firstFragment: <testLibraryFragment>::@mixin::A::@getter::foo1
        synthetic get foo2
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@getter::foo2
      setters
        synthetic set foo1=
          firstFragment: <testLibraryFragment>::@mixin::A::@setter::foo1
          formalParameters
            requiredPositional _foo1
              type: int
        synthetic set foo2=
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@setter::foo2
          formalParameters
            requiredPositional _foo2
              type: int
''');
  }

  test_augmented_fields_add_generic() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment mixin A<T1> {
  T1 foo2;
}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
mixin A<T1> {
  T1 foo1;
}
''');

    configuration.withPropertyLinking = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  parts
    part_0
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
          typeParameters
            covariant T1 @23
              defaultType: dynamic
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          superclassConstraints
            Object
          fields
            foo1 @34
              reference: <testLibraryFragment>::@mixin::A::@field::foo1
              enclosingElement3: <testLibraryFragment>::@mixin::A
              type: T1
              id: field_0
              getter: getter_0
              setter: setter_0
          accessors
            synthetic get foo1 @-1
              reference: <testLibraryFragment>::@mixin::A::@getter::foo1
              enclosingElement3: <testLibraryFragment>::@mixin::A
              returnType: T1
              id: getter_0
              variable: field_0
            synthetic set foo1= @-1
              reference: <testLibraryFragment>::@mixin::A::@setter::foo1
              enclosingElement3: <testLibraryFragment>::@mixin::A
              parameters
                requiredPositional _foo1 @-1
                  type: T1
              returnType: void
              id: setter_0
              variable: field_0
          augmented
            superclassConstraints
              Object
            fields
              <testLibraryFragment>::@mixin::A::@field::foo1
              FieldMember
                base: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@field::foo2
                augmentationSubstitution: {T1: T1}
            accessors
              <testLibraryFragment>::@mixin::A::@getter::foo1
              <testLibraryFragment>::@mixin::A::@setter::foo1
              GetterMember
                base: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@getter::foo2
                augmentationSubstitution: {T1: T1}
              SetterMember
                base: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@setter::foo2
                augmentationSubstitution: {T1: T1}
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      mixins
        augment mixin A @35
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          typeParameters
            covariant T1 @37
              defaultType: dynamic
          augmentationTarget: <testLibraryFragment>::@mixin::A
          fields
            foo2 @48
              reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@field::foo2
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
              type: T1
              id: field_1
              getter: getter_1
              setter: setter_1
          accessors
            synthetic get foo2 @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@getter::foo2
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
              returnType: T1
              id: getter_1
              variable: field_1
            synthetic set foo2= @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@setter::foo2
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
              parameters
                requiredPositional _foo2 @-1
                  type: T1
              returnType: void
              id: setter_1
              variable: field_1
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
          element: <testLibraryFragment>::@mixin::A#element
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          typeParameters
            T1 @23
              element: <not-implemented>
          fields
            foo1 @34
              reference: <testLibraryFragment>::@mixin::A::@field::foo1
              element: <testLibraryFragment>::@mixin::A::@field::foo1#element
              getter2: <testLibraryFragment>::@mixin::A::@getter::foo1
              setter2: <testLibraryFragment>::@mixin::A::@setter::foo1
          getters
            get foo1 @-1
              reference: <testLibraryFragment>::@mixin::A::@getter::foo1
              element: <testLibraryFragment>::@mixin::A::@getter::foo1#element
          setters
            set foo1= @-1
              reference: <testLibraryFragment>::@mixin::A::@setter::foo1
              element: <testLibraryFragment>::@mixin::A::@setter::foo1#element
              formalParameters
                _foo1 @-1
                  element: <testLibraryFragment>::@mixin::A::@setter::foo1::@parameter::_foo1#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      mixins
        mixin A @35
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          element: <testLibraryFragment>::@mixin::A#element
          previousFragment: <testLibraryFragment>::@mixin::A
          typeParameters
            T1 @37
              element: <not-implemented>
          fields
            foo2 @48
              reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@field::foo2
              element: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@field::foo2#element
              getter2: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@getter::foo2
              setter2: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@setter::foo2
          getters
            get foo2 @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@getter::foo2
              element: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@getter::foo2#element
          setters
            set foo2= @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@setter::foo2
              element: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@setter::foo2#element
              formalParameters
                _foo2 @-1
                  element: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@setter::foo2::@parameter::_foo2#element
  mixins
    mixin A
      firstFragment: <testLibraryFragment>::@mixin::A
      typeParameters
        T1
      superclassConstraints
        Object
      fields
        foo1
          firstFragment: <testLibraryFragment>::@mixin::A::@field::foo1
          type: T1
          getter: <testLibraryFragment>::@mixin::A::@getter::foo1#element
          setter: <testLibraryFragment>::@mixin::A::@setter::foo1#element
        foo2
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@field::foo2
          type: T1
          getter: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@getter::foo2#element
          setter: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@setter::foo2#element
      getters
        synthetic get foo1
          firstFragment: <testLibraryFragment>::@mixin::A::@getter::foo1
        synthetic get foo2
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@getter::foo2
      setters
        synthetic set foo1=
          firstFragment: <testLibraryFragment>::@mixin::A::@setter::foo1
          formalParameters
            requiredPositional _foo1
              type: T1
        synthetic set foo2=
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@setter::foo2
          formalParameters
            requiredPositional _foo2
              type: T1
''');
  }

  test_augmented_getters_add() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment mixin A {
  int get foo2 => 0;
}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
mixin A {
  int get foo1 => 0;
}
''');

    configuration.withPropertyLinking = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  parts
    part_0
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
          fields
            synthetic foo1 @-1
              reference: <testLibraryFragment>::@mixin::A::@field::foo1
              enclosingElement3: <testLibraryFragment>::@mixin::A
              type: int
              id: field_0
              getter: getter_0
          accessors
            get foo1 @35
              reference: <testLibraryFragment>::@mixin::A::@getter::foo1
              enclosingElement3: <testLibraryFragment>::@mixin::A
              returnType: int
              id: getter_0
              variable: field_0
          augmented
            superclassConstraints
              Object
            fields
              <testLibraryFragment>::@mixin::A::@field::foo1
              <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@field::foo2
            accessors
              <testLibraryFragment>::@mixin::A::@getter::foo1
              <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@getter::foo2
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      mixins
        augment mixin A @35
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@mixin::A
          fields
            synthetic foo2 @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@field::foo2
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
              type: int
              id: field_1
              getter: getter_1
          accessors
            get foo2 @49
              reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@getter::foo2
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
              returnType: int
              id: getter_1
              variable: field_1
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
          element: <testLibraryFragment>::@mixin::A#element
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          fields
            foo1 @-1
              reference: <testLibraryFragment>::@mixin::A::@field::foo1
              element: <testLibraryFragment>::@mixin::A::@field::foo1#element
              getter2: <testLibraryFragment>::@mixin::A::@getter::foo1
          getters
            get foo1 @35
              reference: <testLibraryFragment>::@mixin::A::@getter::foo1
              element: <testLibraryFragment>::@mixin::A::@getter::foo1#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      mixins
        mixin A @35
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          element: <testLibraryFragment>::@mixin::A#element
          previousFragment: <testLibraryFragment>::@mixin::A
          fields
            foo2 @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@field::foo2
              element: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@field::foo2#element
              getter2: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@getter::foo2
          getters
            get foo2 @49
              reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@getter::foo2
              element: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@getter::foo2#element
  mixins
    mixin A
      firstFragment: <testLibraryFragment>::@mixin::A
      superclassConstraints
        Object
      fields
        synthetic foo1
          firstFragment: <testLibraryFragment>::@mixin::A::@field::foo1
          type: int
          getter: <testLibraryFragment>::@mixin::A::@getter::foo1#element
        synthetic foo2
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@field::foo2
          type: int
          getter: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@getter::foo2#element
      getters
        get foo1
          firstFragment: <testLibraryFragment>::@mixin::A::@getter::foo1
        get foo2
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@getter::foo2
''');
  }

  test_augmented_getters_add_generic() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment mixin A<T1> {
  T1 get foo2;
}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
mixin A<T1> {
  T1 get foo1;
}
''');

    configuration.withPropertyLinking = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  parts
    part_0
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
          typeParameters
            covariant T1 @23
              defaultType: dynamic
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          superclassConstraints
            Object
          fields
            synthetic foo1 @-1
              reference: <testLibraryFragment>::@mixin::A::@field::foo1
              enclosingElement3: <testLibraryFragment>::@mixin::A
              type: T1
              id: field_0
              getter: getter_0
          accessors
            abstract get foo1 @38
              reference: <testLibraryFragment>::@mixin::A::@getter::foo1
              enclosingElement3: <testLibraryFragment>::@mixin::A
              returnType: T1
              id: getter_0
              variable: field_0
          augmented
            superclassConstraints
              Object
            fields
              <testLibraryFragment>::@mixin::A::@field::foo1
              FieldMember
                base: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@field::foo2
                augmentationSubstitution: {T1: T1}
            accessors
              <testLibraryFragment>::@mixin::A::@getter::foo1
              GetterMember
                base: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@getter::foo2
                augmentationSubstitution: {T1: T1}
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      mixins
        augment mixin A @35
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          typeParameters
            covariant T1 @37
              defaultType: dynamic
          augmentationTarget: <testLibraryFragment>::@mixin::A
          fields
            synthetic foo2 @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@field::foo2
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
              type: T1
              id: field_1
              getter: getter_1
          accessors
            abstract get foo2 @52
              reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@getter::foo2
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
              returnType: T1
              id: getter_1
              variable: field_1
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
          element: <testLibraryFragment>::@mixin::A#element
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          typeParameters
            T1 @23
              element: <not-implemented>
          fields
            foo1 @-1
              reference: <testLibraryFragment>::@mixin::A::@field::foo1
              element: <testLibraryFragment>::@mixin::A::@field::foo1#element
              getter2: <testLibraryFragment>::@mixin::A::@getter::foo1
          getters
            get foo1 @38
              reference: <testLibraryFragment>::@mixin::A::@getter::foo1
              element: <testLibraryFragment>::@mixin::A::@getter::foo1#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      mixins
        mixin A @35
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          element: <testLibraryFragment>::@mixin::A#element
          previousFragment: <testLibraryFragment>::@mixin::A
          typeParameters
            T1 @37
              element: <not-implemented>
          fields
            foo2 @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@field::foo2
              element: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@field::foo2#element
              getter2: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@getter::foo2
          getters
            get foo2 @52
              reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@getter::foo2
              element: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@getter::foo2#element
  mixins
    mixin A
      firstFragment: <testLibraryFragment>::@mixin::A
      typeParameters
        T1
      superclassConstraints
        Object
      fields
        synthetic foo1
          firstFragment: <testLibraryFragment>::@mixin::A::@field::foo1
          type: T1
          getter: <testLibraryFragment>::@mixin::A::@getter::foo1#element
        synthetic foo2
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@field::foo2
          type: T1
          getter: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@getter::foo2#element
      getters
        abstract get foo1
          firstFragment: <testLibraryFragment>::@mixin::A::@getter::foo1
        abstract get foo2
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@getter::foo2
''');
  }

  test_augmented_getters_augment_field() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment mixin A {
  augment int get foo => 0;
}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
mixin A {
  int foo = 0;
}
''');

    configuration.withPropertyLinking = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  parts
    part_0
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
          fields
            foo @31
              reference: <testLibraryFragment>::@mixin::A::@field::foo
              enclosingElement3: <testLibraryFragment>::@mixin::A
              type: int
              shouldUseTypeForInitializerInference: true
              id: field_0
              getter: getter_0
              setter: setter_0
          accessors
            synthetic get foo @-1
              reference: <testLibraryFragment>::@mixin::A::@getter::foo
              enclosingElement3: <testLibraryFragment>::@mixin::A
              returnType: int
              id: getter_0
              variable: field_0
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@getterAugmentation::foo
            synthetic set foo= @-1
              reference: <testLibraryFragment>::@mixin::A::@setter::foo
              enclosingElement3: <testLibraryFragment>::@mixin::A
              parameters
                requiredPositional _foo @-1
                  type: int
              returnType: void
              id: setter_0
              variable: field_0
          augmented
            superclassConstraints
              Object
            fields
              <testLibraryFragment>::@mixin::A::@field::foo
            accessors
              <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@getterAugmentation::foo
              <testLibraryFragment>::@mixin::A::@setter::foo
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      mixins
        augment mixin A @35
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@mixin::A
          accessors
            augment get foo @57
              reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@getterAugmentation::foo
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
              returnType: int
              id: getter_1
              variable: field_0
              augmentationTarget: <testLibraryFragment>::@mixin::A::@getter::foo
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
          element: <testLibraryFragment>::@mixin::A#element
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          fields
            foo @31
              reference: <testLibraryFragment>::@mixin::A::@field::foo
              element: <testLibraryFragment>::@mixin::A::@field::foo#element
              getter2: <testLibraryFragment>::@mixin::A::@getter::foo
              setter2: <testLibraryFragment>::@mixin::A::@setter::foo
          getters
            get foo @-1
              reference: <testLibraryFragment>::@mixin::A::@getter::foo
              element: <testLibraryFragment>::@mixin::A::@getter::foo#element
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@getterAugmentation::foo
          setters
            set foo= @-1
              reference: <testLibraryFragment>::@mixin::A::@setter::foo
              element: <testLibraryFragment>::@mixin::A::@setter::foo#element
              formalParameters
                _foo @-1
                  element: <testLibraryFragment>::@mixin::A::@setter::foo::@parameter::_foo#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      mixins
        mixin A @35
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          element: <testLibraryFragment>::@mixin::A#element
          previousFragment: <testLibraryFragment>::@mixin::A
          getters
            augment get foo @57
              reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@getterAugmentation::foo
              element: <testLibraryFragment>::@mixin::A::@getter::foo#element
              previousFragment: <testLibraryFragment>::@mixin::A::@getter::foo
  mixins
    mixin A
      firstFragment: <testLibraryFragment>::@mixin::A
      superclassConstraints
        Object
      fields
        foo
          firstFragment: <testLibraryFragment>::@mixin::A::@field::foo
          type: int
          getter: <testLibraryFragment>::@mixin::A::@getter::foo#element
          setter: <testLibraryFragment>::@mixin::A::@setter::foo#element
      getters
        synthetic get foo
          firstFragment: <testLibraryFragment>::@mixin::A::@getter::foo
      setters
        synthetic set foo=
          firstFragment: <testLibraryFragment>::@mixin::A::@setter::foo
          formalParameters
            requiredPositional _foo
              type: int
''');
  }

  test_augmented_getters_augment_field2() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment mixin A {
  augment int get foo => 0;
}
''');

    newFile('$testPackageLibPath/b.dart', r'''
part of 'test.dart';
augment mixin A {
  augment int get foo => 0;
}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
part 'b.dart';
mixin A {
  int foo = 0;
}
''');

    configuration.withPropertyLinking = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  parts
    part_0
    part_1
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
        part_1
          uri: package:test/b.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/b.dart
      mixins
        mixin A @36
          reference: <testLibraryFragment>::@mixin::A
          enclosingElement3: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          superclassConstraints
            Object
          fields
            foo @46
              reference: <testLibraryFragment>::@mixin::A::@field::foo
              enclosingElement3: <testLibraryFragment>::@mixin::A
              type: int
              shouldUseTypeForInitializerInference: true
              id: field_0
              getter: getter_0
              setter: setter_0
          accessors
            synthetic get foo @-1
              reference: <testLibraryFragment>::@mixin::A::@getter::foo
              enclosingElement3: <testLibraryFragment>::@mixin::A
              returnType: int
              id: getter_0
              variable: field_0
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@getterAugmentation::foo
            synthetic set foo= @-1
              reference: <testLibraryFragment>::@mixin::A::@setter::foo
              enclosingElement3: <testLibraryFragment>::@mixin::A
              parameters
                requiredPositional _foo @-1
                  type: int
              returnType: void
              id: setter_0
              variable: field_0
          augmented
            superclassConstraints
              Object
            fields
              <testLibraryFragment>::@mixin::A::@field::foo
            accessors
              <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A::@getterAugmentation::foo
              <testLibraryFragment>::@mixin::A::@setter::foo
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      mixins
        augment mixin A @35
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@mixin::A
          augmentation: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A
          accessors
            augment get foo @57
              reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@getterAugmentation::foo
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
              returnType: int
              id: getter_1
              variable: field_0
              augmentationTarget: <testLibraryFragment>::@mixin::A::@getter::foo
              augmentation: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A::@getterAugmentation::foo
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement3: <testLibraryFragment>
      mixins
        augment mixin A @35
          reference: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/b.dart
          augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          accessors
            augment get foo @57
              reference: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A::@getterAugmentation::foo
              enclosingElement3: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A
              returnType: int
              id: getter_2
              variable: field_0
              augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@getterAugmentation::foo
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      mixins
        mixin A @36
          reference: <testLibraryFragment>::@mixin::A
          element: <testLibraryFragment>::@mixin::A#element
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          fields
            foo @46
              reference: <testLibraryFragment>::@mixin::A::@field::foo
              element: <testLibraryFragment>::@mixin::A::@field::foo#element
              getter2: <testLibraryFragment>::@mixin::A::@getter::foo
              setter2: <testLibraryFragment>::@mixin::A::@setter::foo
          getters
            get foo @-1
              reference: <testLibraryFragment>::@mixin::A::@getter::foo
              element: <testLibraryFragment>::@mixin::A::@getter::foo#element
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@getterAugmentation::foo
          setters
            set foo= @-1
              reference: <testLibraryFragment>::@mixin::A::@setter::foo
              element: <testLibraryFragment>::@mixin::A::@setter::foo#element
              formalParameters
                _foo @-1
                  element: <testLibraryFragment>::@mixin::A::@setter::foo::@parameter::_foo#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      mixins
        mixin A @35
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          element: <testLibraryFragment>::@mixin::A#element
          previousFragment: <testLibraryFragment>::@mixin::A
          nextFragment: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A
          getters
            augment get foo @57
              reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@getterAugmentation::foo
              element: <testLibraryFragment>::@mixin::A::@getter::foo#element
              previousFragment: <testLibraryFragment>::@mixin::A::@getter::foo
              nextFragment: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A::@getterAugmentation::foo
    <testLibrary>::@fragment::package:test/b.dart
      element: <testLibrary>
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      mixins
        mixin A @35
          reference: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A
          element: <testLibraryFragment>::@mixin::A#element
          previousFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          getters
            augment get foo @57
              reference: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A::@getterAugmentation::foo
              element: <testLibraryFragment>::@mixin::A::@getter::foo#element
              previousFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@getterAugmentation::foo
  mixins
    mixin A
      firstFragment: <testLibraryFragment>::@mixin::A
      superclassConstraints
        Object
      fields
        foo
          firstFragment: <testLibraryFragment>::@mixin::A::@field::foo
          type: int
          getter: <testLibraryFragment>::@mixin::A::@getter::foo#element
          setter: <testLibraryFragment>::@mixin::A::@setter::foo#element
      getters
        synthetic get foo
          firstFragment: <testLibraryFragment>::@mixin::A::@getter::foo
      setters
        synthetic set foo=
          firstFragment: <testLibraryFragment>::@mixin::A::@setter::foo
          formalParameters
            requiredPositional _foo
              type: int
''');
  }

  test_augmented_getters_augment_getter() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment mixin A {
  augment int get foo1 => 0;
}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
mixin A {
  int get foo1 => 0;
  int get foo2 => 0;
}
''');

    configuration.withPropertyLinking = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  parts
    part_0
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
          fields
            synthetic foo1 @-1
              reference: <testLibraryFragment>::@mixin::A::@field::foo1
              enclosingElement3: <testLibraryFragment>::@mixin::A
              type: int
              id: field_0
              getter: getter_0
            synthetic foo2 @-1
              reference: <testLibraryFragment>::@mixin::A::@field::foo2
              enclosingElement3: <testLibraryFragment>::@mixin::A
              type: int
              id: field_1
              getter: getter_1
          accessors
            get foo1 @35
              reference: <testLibraryFragment>::@mixin::A::@getter::foo1
              enclosingElement3: <testLibraryFragment>::@mixin::A
              returnType: int
              id: getter_0
              variable: field_0
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@getterAugmentation::foo1
            get foo2 @56
              reference: <testLibraryFragment>::@mixin::A::@getter::foo2
              enclosingElement3: <testLibraryFragment>::@mixin::A
              returnType: int
              id: getter_1
              variable: field_1
          augmented
            superclassConstraints
              Object
            fields
              <testLibraryFragment>::@mixin::A::@field::foo1
              <testLibraryFragment>::@mixin::A::@field::foo2
            accessors
              <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@getterAugmentation::foo1
              <testLibraryFragment>::@mixin::A::@getter::foo2
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      mixins
        augment mixin A @35
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@mixin::A
          accessors
            augment get foo1 @57
              reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@getterAugmentation::foo1
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
              returnType: int
              id: getter_2
              variable: field_0
              augmentationTarget: <testLibraryFragment>::@mixin::A::@getter::foo1
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
          element: <testLibraryFragment>::@mixin::A#element
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          fields
            foo1 @-1
              reference: <testLibraryFragment>::@mixin::A::@field::foo1
              element: <testLibraryFragment>::@mixin::A::@field::foo1#element
              getter2: <testLibraryFragment>::@mixin::A::@getter::foo1
            foo2 @-1
              reference: <testLibraryFragment>::@mixin::A::@field::foo2
              element: <testLibraryFragment>::@mixin::A::@field::foo2#element
              getter2: <testLibraryFragment>::@mixin::A::@getter::foo2
          getters
            get foo1 @35
              reference: <testLibraryFragment>::@mixin::A::@getter::foo1
              element: <testLibraryFragment>::@mixin::A::@getter::foo1#element
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@getterAugmentation::foo1
            get foo2 @56
              reference: <testLibraryFragment>::@mixin::A::@getter::foo2
              element: <testLibraryFragment>::@mixin::A::@getter::foo2#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      mixins
        mixin A @35
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          element: <testLibraryFragment>::@mixin::A#element
          previousFragment: <testLibraryFragment>::@mixin::A
          getters
            augment get foo1 @57
              reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@getterAugmentation::foo1
              element: <testLibraryFragment>::@mixin::A::@getter::foo1#element
              previousFragment: <testLibraryFragment>::@mixin::A::@getter::foo1
  mixins
    mixin A
      firstFragment: <testLibraryFragment>::@mixin::A
      superclassConstraints
        Object
      fields
        synthetic foo1
          firstFragment: <testLibraryFragment>::@mixin::A::@field::foo1
          type: int
          getter: <testLibraryFragment>::@mixin::A::@getter::foo1#element
        synthetic foo2
          firstFragment: <testLibraryFragment>::@mixin::A::@field::foo2
          type: int
          getter: <testLibraryFragment>::@mixin::A::@getter::foo2#element
      getters
        get foo2
          firstFragment: <testLibraryFragment>::@mixin::A::@getter::foo2
        get foo1
          firstFragment: <testLibraryFragment>::@mixin::A::@getter::foo1
''');
  }

  test_augmented_getters_augment_getter2() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment mixin A {
  augment int get foo => 0;
}
''');

    newFile('$testPackageLibPath/b.dart', r'''
part of 'test.dart';
augment mixin A {
  augment int get foo => 0;
}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
part 'b.dart';
mixin A {
  int get foo => 0;
}
''');

    configuration.withPropertyLinking = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  parts
    part_0
    part_1
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
        part_1
          uri: package:test/b.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/b.dart
      mixins
        mixin A @36
          reference: <testLibraryFragment>::@mixin::A
          enclosingElement3: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          superclassConstraints
            Object
          fields
            synthetic foo @-1
              reference: <testLibraryFragment>::@mixin::A::@field::foo
              enclosingElement3: <testLibraryFragment>::@mixin::A
              type: int
              id: field_0
              getter: getter_0
          accessors
            get foo @50
              reference: <testLibraryFragment>::@mixin::A::@getter::foo
              enclosingElement3: <testLibraryFragment>::@mixin::A
              returnType: int
              id: getter_0
              variable: field_0
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@getterAugmentation::foo
          augmented
            superclassConstraints
              Object
            fields
              <testLibraryFragment>::@mixin::A::@field::foo
            accessors
              <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A::@getterAugmentation::foo
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      mixins
        augment mixin A @35
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@mixin::A
          augmentation: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A
          accessors
            augment get foo @57
              reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@getterAugmentation::foo
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
              returnType: int
              id: getter_1
              variable: field_0
              augmentationTarget: <testLibraryFragment>::@mixin::A::@getter::foo
              augmentation: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A::@getterAugmentation::foo
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement3: <testLibraryFragment>
      mixins
        augment mixin A @35
          reference: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/b.dart
          augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          accessors
            augment get foo @57
              reference: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A::@getterAugmentation::foo
              enclosingElement3: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A
              returnType: int
              id: getter_2
              variable: field_0
              augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@getterAugmentation::foo
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      mixins
        mixin A @36
          reference: <testLibraryFragment>::@mixin::A
          element: <testLibraryFragment>::@mixin::A#element
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          fields
            foo @-1
              reference: <testLibraryFragment>::@mixin::A::@field::foo
              element: <testLibraryFragment>::@mixin::A::@field::foo#element
              getter2: <testLibraryFragment>::@mixin::A::@getter::foo
          getters
            get foo @50
              reference: <testLibraryFragment>::@mixin::A::@getter::foo
              element: <testLibraryFragment>::@mixin::A::@getter::foo#element
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@getterAugmentation::foo
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      mixins
        mixin A @35
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          element: <testLibraryFragment>::@mixin::A#element
          previousFragment: <testLibraryFragment>::@mixin::A
          nextFragment: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A
          getters
            augment get foo @57
              reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@getterAugmentation::foo
              element: <testLibraryFragment>::@mixin::A::@getter::foo#element
              previousFragment: <testLibraryFragment>::@mixin::A::@getter::foo
              nextFragment: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A::@getterAugmentation::foo
    <testLibrary>::@fragment::package:test/b.dart
      element: <testLibrary>
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      mixins
        mixin A @35
          reference: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A
          element: <testLibraryFragment>::@mixin::A#element
          previousFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          getters
            augment get foo @57
              reference: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A::@getterAugmentation::foo
              element: <testLibraryFragment>::@mixin::A::@getter::foo#element
              previousFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@getterAugmentation::foo
  mixins
    mixin A
      firstFragment: <testLibraryFragment>::@mixin::A
      superclassConstraints
        Object
      fields
        synthetic foo
          firstFragment: <testLibraryFragment>::@mixin::A::@field::foo
          type: int
          getter: <testLibraryFragment>::@mixin::A::@getter::foo#element
      getters
        get foo
          firstFragment: <testLibraryFragment>::@mixin::A::@getter::foo
''');
  }

  test_augmented_interfaces() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment mixin A implements I2 {}
class I2 {}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
mixin A implements I1 {}
class I1 {}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  parts
    part_0
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      classes
        class I1 @46
          reference: <testLibraryFragment>::@class::I1
          enclosingElement3: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::I1::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::I1
      mixins
        mixin A @21
          reference: <testLibraryFragment>::@mixin::A
          enclosingElement3: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          superclassConstraints
            Object
          interfaces
            I1
          augmented
            superclassConstraints
              Object
            interfaces
              I1
              I2
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      classes
        class I2 @60
          reference: <testLibrary>::@fragment::package:test/a.dart::@class::I2
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          constructors
            synthetic @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@class::I2::@constructor::new
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@class::I2
      mixins
        augment mixin A @35
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@mixin::A
          interfaces
            I2
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      classes
        class I1 @46
          reference: <testLibraryFragment>::@class::I1
          element: <testLibraryFragment>::@class::I1#element
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::I1::@constructor::new
              element: <testLibraryFragment>::@class::I1::@constructor::new#element
      mixins
        mixin A @21
          reference: <testLibraryFragment>::@mixin::A
          element: <testLibraryFragment>::@mixin::A#element
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      classes
        class I2 @60
          reference: <testLibrary>::@fragment::package:test/a.dart::@class::I2
          element: <testLibrary>::@fragment::package:test/a.dart::@class::I2#element
          constructors
            synthetic new @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@class::I2::@constructor::new
              element: <testLibrary>::@fragment::package:test/a.dart::@class::I2::@constructor::new#element
      mixins
        mixin A @35
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          element: <testLibraryFragment>::@mixin::A#element
          previousFragment: <testLibraryFragment>::@mixin::A
  classes
    class I1
      firstFragment: <testLibraryFragment>::@class::I1
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::I1::@constructor::new
    class I2
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@class::I2
      constructors
        synthetic new
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@class::I2::@constructor::new
  mixins
    mixin A
      firstFragment: <testLibraryFragment>::@mixin::A
      superclassConstraints
        Object
''');
  }

  test_augmented_interfaces_chain() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
part 'b.dart';
augment mixin A implements I2 {}
class I2 {}
''');

    newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';
augment mixin A implements I3 {}
class I3 {}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
mixin A implements I1 {}
class I1 {}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  parts
    part_0
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      classes
        class I1 @46
          reference: <testLibraryFragment>::@class::I1
          enclosingElement3: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::I1::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::I1
      mixins
        mixin A @21
          reference: <testLibraryFragment>::@mixin::A
          enclosingElement3: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          superclassConstraints
            Object
          interfaces
            I1
          augmented
            superclassConstraints
              Object
            interfaces
              I1
              I2
              I3
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      parts
        part_1
          uri: package:test/b.dart
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          unit: <testLibrary>::@fragment::package:test/b.dart
      classes
        class I2 @75
          reference: <testLibrary>::@fragment::package:test/a.dart::@class::I2
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          constructors
            synthetic @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@class::I2::@constructor::new
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@class::I2
      mixins
        augment mixin A @50
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@mixin::A
          augmentation: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A
          interfaces
            I2
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
      classes
        class I3 @57
          reference: <testLibrary>::@fragment::package:test/b.dart::@class::I3
          enclosingElement3: <testLibrary>::@fragment::package:test/b.dart
          constructors
            synthetic @-1
              reference: <testLibrary>::@fragment::package:test/b.dart::@class::I3::@constructor::new
              enclosingElement3: <testLibrary>::@fragment::package:test/b.dart::@class::I3
      mixins
        augment mixin A @32
          reference: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/b.dart
          augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          interfaces
            I3
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      classes
        class I1 @46
          reference: <testLibraryFragment>::@class::I1
          element: <testLibraryFragment>::@class::I1#element
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::I1::@constructor::new
              element: <testLibraryFragment>::@class::I1::@constructor::new#element
      mixins
        mixin A @21
          reference: <testLibraryFragment>::@mixin::A
          element: <testLibraryFragment>::@mixin::A#element
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      classes
        class I2 @75
          reference: <testLibrary>::@fragment::package:test/a.dart::@class::I2
          element: <testLibrary>::@fragment::package:test/a.dart::@class::I2#element
          constructors
            synthetic new @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@class::I2::@constructor::new
              element: <testLibrary>::@fragment::package:test/a.dart::@class::I2::@constructor::new#element
      mixins
        mixin A @50
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          element: <testLibraryFragment>::@mixin::A#element
          previousFragment: <testLibraryFragment>::@mixin::A
          nextFragment: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A
    <testLibrary>::@fragment::package:test/b.dart
      element: <testLibrary>
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      classes
        class I3 @57
          reference: <testLibrary>::@fragment::package:test/b.dart::@class::I3
          element: <testLibrary>::@fragment::package:test/b.dart::@class::I3#element
          constructors
            synthetic new @-1
              reference: <testLibrary>::@fragment::package:test/b.dart::@class::I3::@constructor::new
              element: <testLibrary>::@fragment::package:test/b.dart::@class::I3::@constructor::new#element
      mixins
        mixin A @32
          reference: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A
          element: <testLibraryFragment>::@mixin::A#element
          previousFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
  classes
    class I1
      firstFragment: <testLibraryFragment>::@class::I1
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::I1::@constructor::new
    class I2
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@class::I2
      constructors
        synthetic new
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@class::I2::@constructor::new
    class I3
      firstFragment: <testLibrary>::@fragment::package:test/b.dart::@class::I3
      constructors
        synthetic new
          firstFragment: <testLibrary>::@fragment::package:test/b.dart::@class::I3::@constructor::new
  mixins
    mixin A
      firstFragment: <testLibraryFragment>::@mixin::A
      superclassConstraints
        Object
''');
  }

  test_augmented_methods() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment mixin A {
  void bar() {}
}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
mixin A {
  void foo() {}
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  parts
    part_0
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
          methods
            foo @32
              reference: <testLibraryFragment>::@mixin::A::@method::foo
              enclosingElement3: <testLibraryFragment>::@mixin::A
              returnType: void
          augmented
            superclassConstraints
              Object
            methods
              <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@method::bar
              <testLibraryFragment>::@mixin::A::@method::foo
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      mixins
        augment mixin A @35
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@mixin::A
          methods
            bar @46
              reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@method::bar
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
              returnType: void
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
          element: <testLibraryFragment>::@mixin::A#element
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          methods
            foo @32
              reference: <testLibraryFragment>::@mixin::A::@method::foo
              element: <testLibraryFragment>::@mixin::A::@method::foo#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      mixins
        mixin A @35
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          element: <testLibraryFragment>::@mixin::A#element
          previousFragment: <testLibraryFragment>::@mixin::A
          methods
            bar @46
              reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@method::bar
              element: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@method::bar#element
  mixins
    mixin A
      firstFragment: <testLibraryFragment>::@mixin::A
      superclassConstraints
        Object
      methods
        foo
          firstFragment: <testLibraryFragment>::@mixin::A::@method::foo
        bar
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@method::bar
''');
  }

  test_augmented_methods_augment() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment mixin A {
  augment void foo1() {}
}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
mixin A {
  void foo1() {}
  void foo2() {}
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  parts
    part_0
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
          methods
            foo1 @32
              reference: <testLibraryFragment>::@mixin::A::@method::foo1
              enclosingElement3: <testLibraryFragment>::@mixin::A
              returnType: void
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@methodAugmentation::foo1
            foo2 @49
              reference: <testLibraryFragment>::@mixin::A::@method::foo2
              enclosingElement3: <testLibraryFragment>::@mixin::A
              returnType: void
          augmented
            superclassConstraints
              Object
            methods
              <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@methodAugmentation::foo1
              <testLibraryFragment>::@mixin::A::@method::foo2
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      mixins
        augment mixin A @35
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@mixin::A
          methods
            augment foo1 @54
              reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@methodAugmentation::foo1
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
              returnType: void
              augmentationTarget: <testLibraryFragment>::@mixin::A::@method::foo1
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
          element: <testLibraryFragment>::@mixin::A#element
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          methods
            foo1 @32
              reference: <testLibraryFragment>::@mixin::A::@method::foo1
              element: <testLibraryFragment>::@mixin::A::@method::foo1#element
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@methodAugmentation::foo1
            foo2 @49
              reference: <testLibraryFragment>::@mixin::A::@method::foo2
              element: <testLibraryFragment>::@mixin::A::@method::foo2#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      mixins
        mixin A @35
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          element: <testLibraryFragment>::@mixin::A#element
          previousFragment: <testLibraryFragment>::@mixin::A
          methods
            augment foo1 @54
              reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@methodAugmentation::foo1
              element: <testLibraryFragment>::@mixin::A::@method::foo1#element
              previousFragment: <testLibraryFragment>::@mixin::A::@method::foo1
  mixins
    mixin A
      firstFragment: <testLibraryFragment>::@mixin::A
      superclassConstraints
        Object
      methods
        foo2
          firstFragment: <testLibraryFragment>::@mixin::A::@method::foo2
        foo1
          firstFragment: <testLibraryFragment>::@mixin::A::@method::foo1
''');
  }

  test_augmented_methods_augment2() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
part 'b.dart';
augment mixin A {
  augment void foo() {}
}
''');

    newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';
augment mixin A {
  augment void foo() {}
}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
mixin A {
  void foo() {}
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  parts
    part_0
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
          methods
            foo @32
              reference: <testLibraryFragment>::@mixin::A::@method::foo
              enclosingElement3: <testLibraryFragment>::@mixin::A
              returnType: void
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@methodAugmentation::foo
          augmented
            superclassConstraints
              Object
            methods
              <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A::@methodAugmentation::foo
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      parts
        part_1
          uri: package:test/b.dart
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          unit: <testLibrary>::@fragment::package:test/b.dart
      mixins
        augment mixin A @50
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@mixin::A
          augmentation: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A
          methods
            augment foo @69
              reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@methodAugmentation::foo
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
              returnType: void
              augmentationTarget: <testLibraryFragment>::@mixin::A::@method::foo
              augmentation: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A::@methodAugmentation::foo
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
      mixins
        augment mixin A @32
          reference: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/b.dart
          augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          methods
            augment foo @51
              reference: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A::@methodAugmentation::foo
              enclosingElement3: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A
              returnType: void
              augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@methodAugmentation::foo
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
          element: <testLibraryFragment>::@mixin::A#element
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          methods
            foo @32
              reference: <testLibraryFragment>::@mixin::A::@method::foo
              element: <testLibraryFragment>::@mixin::A::@method::foo#element
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@methodAugmentation::foo
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      mixins
        mixin A @50
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          element: <testLibraryFragment>::@mixin::A#element
          previousFragment: <testLibraryFragment>::@mixin::A
          nextFragment: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A
          methods
            augment foo @69
              reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@methodAugmentation::foo
              element: <testLibraryFragment>::@mixin::A::@method::foo#element
              previousFragment: <testLibraryFragment>::@mixin::A::@method::foo
              nextFragment: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A::@methodAugmentation::foo
    <testLibrary>::@fragment::package:test/b.dart
      element: <testLibrary>
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      mixins
        mixin A @32
          reference: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A
          element: <testLibraryFragment>::@mixin::A#element
          previousFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          methods
            augment foo @51
              reference: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A::@methodAugmentation::foo
              element: <testLibraryFragment>::@mixin::A::@method::foo#element
              previousFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@methodAugmentation::foo
  mixins
    mixin A
      firstFragment: <testLibraryFragment>::@mixin::A
      superclassConstraints
        Object
      methods
        foo
          firstFragment: <testLibraryFragment>::@mixin::A::@method::foo
''');
  }

  test_augmented_methods_generic() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment mixin A<T2> {
  T2 bar() => throw 0;
}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
mixin A<T> {
  T foo() => throw 0;
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  parts
    part_0
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
          typeParameters
            covariant T @23
              defaultType: dynamic
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          superclassConstraints
            Object
          methods
            foo @32
              reference: <testLibraryFragment>::@mixin::A::@method::foo
              enclosingElement3: <testLibraryFragment>::@mixin::A
              returnType: T
          augmented
            superclassConstraints
              Object
            methods
              MethodMember
                base: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@method::bar
                augmentationSubstitution: {T2: T}
              <testLibraryFragment>::@mixin::A::@method::foo
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      mixins
        augment mixin A @35
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          typeParameters
            covariant T2 @37
              defaultType: dynamic
          augmentationTarget: <testLibraryFragment>::@mixin::A
          methods
            bar @48
              reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@method::bar
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
              returnType: T2
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
          element: <testLibraryFragment>::@mixin::A#element
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          typeParameters
            T @23
              element: <not-implemented>
          methods
            foo @32
              reference: <testLibraryFragment>::@mixin::A::@method::foo
              element: <testLibraryFragment>::@mixin::A::@method::foo#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      mixins
        mixin A @35
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          element: <testLibraryFragment>::@mixin::A#element
          previousFragment: <testLibraryFragment>::@mixin::A
          typeParameters
            T2 @37
              element: <not-implemented>
          methods
            bar @48
              reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@method::bar
              element: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@method::bar#element
  mixins
    mixin A
      firstFragment: <testLibraryFragment>::@mixin::A
      typeParameters
        T
      superclassConstraints
        Object
      methods
        foo
          firstFragment: <testLibraryFragment>::@mixin::A::@method::foo
        bar
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@method::bar
''');
  }

  test_augmented_methods_generic_augment() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment mixin A<T2> {
  augment T2 foo() => throw 0;
}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
mixin A<T> {
  T foo() => throw 0;
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  parts
    part_0
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
          typeParameters
            covariant T @23
              defaultType: dynamic
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          superclassConstraints
            Object
          methods
            foo @32
              reference: <testLibraryFragment>::@mixin::A::@method::foo
              enclosingElement3: <testLibraryFragment>::@mixin::A
              returnType: T
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@methodAugmentation::foo
          augmented
            superclassConstraints
              Object
            methods
              MethodMember
                base: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@methodAugmentation::foo
                augmentationSubstitution: {T2: T}
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      mixins
        augment mixin A @35
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          typeParameters
            covariant T2 @37
              defaultType: dynamic
          augmentationTarget: <testLibraryFragment>::@mixin::A
          methods
            augment foo @56
              reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@methodAugmentation::foo
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
              returnType: T2
              augmentationTarget: <testLibraryFragment>::@mixin::A::@method::foo
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
          element: <testLibraryFragment>::@mixin::A#element
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          typeParameters
            T @23
              element: <not-implemented>
          methods
            foo @32
              reference: <testLibraryFragment>::@mixin::A::@method::foo
              element: <testLibraryFragment>::@mixin::A::@method::foo#element
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@methodAugmentation::foo
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      mixins
        mixin A @35
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          element: <testLibraryFragment>::@mixin::A#element
          previousFragment: <testLibraryFragment>::@mixin::A
          typeParameters
            T2 @37
              element: <not-implemented>
          methods
            augment foo @56
              reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@methodAugmentation::foo
              element: <testLibraryFragment>::@mixin::A::@method::foo#element
              previousFragment: <testLibraryFragment>::@mixin::A::@method::foo
  mixins
    mixin A
      firstFragment: <testLibraryFragment>::@mixin::A
      typeParameters
        T
      superclassConstraints
        Object
      methods
        foo
          firstFragment: <testLibraryFragment>::@mixin::A::@method::foo
''');
  }

  test_augmented_methods_typeParameterCountMismatch() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment mixin A<T> {
  augment void foo() {}
}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
mixin A {
  void foo() {}
  void bar() {}
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  parts
    part_0
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
          methods
            foo @32
              reference: <testLibraryFragment>::@mixin::A::@method::foo
              enclosingElement3: <testLibraryFragment>::@mixin::A
              returnType: void
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@methodAugmentation::foo
            bar @48
              reference: <testLibraryFragment>::@mixin::A::@method::bar
              enclosingElement3: <testLibraryFragment>::@mixin::A
              returnType: void
          augmented
            superclassConstraints
              Object
            methods
              <testLibraryFragment>::@mixin::A::@method::bar
              MethodMember
                base: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@methodAugmentation::foo
                augmentationSubstitution: {T: InvalidType}
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      mixins
        augment mixin A @35
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          typeParameters
            covariant T @37
              defaultType: dynamic
          augmentationTarget: <testLibraryFragment>::@mixin::A
          methods
            augment foo @57
              reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@methodAugmentation::foo
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
              returnType: void
              augmentationTarget: <testLibraryFragment>::@mixin::A::@method::foo
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
          element: <testLibraryFragment>::@mixin::A#element
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          methods
            foo @32
              reference: <testLibraryFragment>::@mixin::A::@method::foo
              element: <testLibraryFragment>::@mixin::A::@method::foo#element
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@methodAugmentation::foo
            bar @48
              reference: <testLibraryFragment>::@mixin::A::@method::bar
              element: <testLibraryFragment>::@mixin::A::@method::bar#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      mixins
        mixin A @35
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          element: <testLibraryFragment>::@mixin::A#element
          previousFragment: <testLibraryFragment>::@mixin::A
          typeParameters
            T @37
              element: <not-implemented>
          methods
            augment foo @57
              reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@methodAugmentation::foo
              element: <testLibraryFragment>::@mixin::A::@method::foo#element
              previousFragment: <testLibraryFragment>::@mixin::A::@method::foo
  mixins
    mixin A
      firstFragment: <testLibraryFragment>::@mixin::A
      superclassConstraints
        Object
      methods
        bar
          firstFragment: <testLibraryFragment>::@mixin::A::@method::bar
        foo
          firstFragment: <testLibraryFragment>::@mixin::A::@method::foo
''');
  }

  test_augmented_setters_add() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment mixin A {
  set foo2(int _) {}
}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
mixin A {
  set foo1(int _) {}
}
''');

    configuration.withPropertyLinking = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  parts
    part_0
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
          fields
            synthetic foo1 @-1
              reference: <testLibraryFragment>::@mixin::A::@field::foo1
              enclosingElement3: <testLibraryFragment>::@mixin::A
              type: int
              id: field_0
              setter: setter_0
          accessors
            set foo1= @31
              reference: <testLibraryFragment>::@mixin::A::@setter::foo1
              enclosingElement3: <testLibraryFragment>::@mixin::A
              parameters
                requiredPositional _ @40
                  type: int
              returnType: void
              id: setter_0
              variable: field_0
          augmented
            superclassConstraints
              Object
            fields
              <testLibraryFragment>::@mixin::A::@field::foo1
              <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@field::foo2
            accessors
              <testLibraryFragment>::@mixin::A::@setter::foo1
              <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@setter::foo2
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      mixins
        augment mixin A @35
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@mixin::A
          fields
            synthetic foo2 @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@field::foo2
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
              type: int
              id: field_1
              setter: setter_1
          accessors
            set foo2= @45
              reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@setter::foo2
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
              parameters
                requiredPositional _ @54
                  type: int
              returnType: void
              id: setter_1
              variable: field_1
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
          element: <testLibraryFragment>::@mixin::A#element
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          fields
            foo1 @-1
              reference: <testLibraryFragment>::@mixin::A::@field::foo1
              element: <testLibraryFragment>::@mixin::A::@field::foo1#element
              setter2: <testLibraryFragment>::@mixin::A::@setter::foo1
          setters
            set foo1= @31
              reference: <testLibraryFragment>::@mixin::A::@setter::foo1
              element: <testLibraryFragment>::@mixin::A::@setter::foo1#element
              formalParameters
                _ @40
                  element: <testLibraryFragment>::@mixin::A::@setter::foo1::@parameter::_#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      mixins
        mixin A @35
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          element: <testLibraryFragment>::@mixin::A#element
          previousFragment: <testLibraryFragment>::@mixin::A
          fields
            foo2 @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@field::foo2
              element: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@field::foo2#element
              setter2: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@setter::foo2
          setters
            set foo2= @45
              reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@setter::foo2
              element: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@setter::foo2#element
              formalParameters
                _ @54
                  element: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@setter::foo2::@parameter::_#element
  mixins
    mixin A
      firstFragment: <testLibraryFragment>::@mixin::A
      superclassConstraints
        Object
      fields
        synthetic foo1
          firstFragment: <testLibraryFragment>::@mixin::A::@field::foo1
          type: int
          setter: <testLibraryFragment>::@mixin::A::@setter::foo1#element
        synthetic foo2
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@field::foo2
          type: int
          setter: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@setter::foo2#element
      setters
        set foo1=
          firstFragment: <testLibraryFragment>::@mixin::A::@setter::foo1
          formalParameters
            requiredPositional _
              type: int
        set foo2=
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@setter::foo2
          formalParameters
            requiredPositional _
              type: int
''');
  }

  test_augmented_setters_augment_field() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment mixin A {
  augment set foo(int _) {}
}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
mixin A {
  int foo = 0;
}
''');

    configuration.withPropertyLinking = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  parts
    part_0
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
          fields
            foo @31
              reference: <testLibraryFragment>::@mixin::A::@field::foo
              enclosingElement3: <testLibraryFragment>::@mixin::A
              type: int
              shouldUseTypeForInitializerInference: true
              id: field_0
              getter: getter_0
              setter: setter_0
          accessors
            synthetic get foo @-1
              reference: <testLibraryFragment>::@mixin::A::@getter::foo
              enclosingElement3: <testLibraryFragment>::@mixin::A
              returnType: int
              id: getter_0
              variable: field_0
            synthetic set foo= @-1
              reference: <testLibraryFragment>::@mixin::A::@setter::foo
              enclosingElement3: <testLibraryFragment>::@mixin::A
              parameters
                requiredPositional _foo @-1
                  type: int
              returnType: void
              id: setter_0
              variable: field_0
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@setterAugmentation::foo
          augmented
            superclassConstraints
              Object
            fields
              <testLibraryFragment>::@mixin::A::@field::foo
            accessors
              <testLibraryFragment>::@mixin::A::@getter::foo
              <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@setterAugmentation::foo
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      mixins
        augment mixin A @35
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@mixin::A
          accessors
            augment set foo= @53
              reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@setterAugmentation::foo
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
              parameters
                requiredPositional _ @61
                  type: int
              returnType: void
              id: setter_1
              variable: field_0
              augmentationTarget: <testLibraryFragment>::@mixin::A::@setter::foo
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
          element: <testLibraryFragment>::@mixin::A#element
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          fields
            foo @31
              reference: <testLibraryFragment>::@mixin::A::@field::foo
              element: <testLibraryFragment>::@mixin::A::@field::foo#element
              getter2: <testLibraryFragment>::@mixin::A::@getter::foo
              setter2: <testLibraryFragment>::@mixin::A::@setter::foo
          getters
            get foo @-1
              reference: <testLibraryFragment>::@mixin::A::@getter::foo
              element: <testLibraryFragment>::@mixin::A::@getter::foo#element
          setters
            set foo= @-1
              reference: <testLibraryFragment>::@mixin::A::@setter::foo
              element: <testLibraryFragment>::@mixin::A::@setter::foo#element
              formalParameters
                _foo @-1
                  element: <testLibraryFragment>::@mixin::A::@setter::foo::@parameter::_foo#element
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@setterAugmentation::foo
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      mixins
        mixin A @35
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          element: <testLibraryFragment>::@mixin::A#element
          previousFragment: <testLibraryFragment>::@mixin::A
          setters
            augment set foo= @53
              reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@setterAugmentation::foo
              element: <testLibraryFragment>::@mixin::A::@setter::foo#element
              formalParameters
                _ @61
                  element: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@setterAugmentation::foo::@parameter::_#element
              previousFragment: <testLibraryFragment>::@mixin::A::@setter::foo
  mixins
    mixin A
      firstFragment: <testLibraryFragment>::@mixin::A
      superclassConstraints
        Object
      fields
        foo
          firstFragment: <testLibraryFragment>::@mixin::A::@field::foo
          type: int
          getter: <testLibraryFragment>::@mixin::A::@getter::foo#element
          setter: <testLibraryFragment>::@mixin::A::@setter::foo#element
      getters
        synthetic get foo
          firstFragment: <testLibraryFragment>::@mixin::A::@getter::foo
      setters
        synthetic set foo=
          firstFragment: <testLibraryFragment>::@mixin::A::@setter::foo
          formalParameters
            requiredPositional _foo
              type: int
''');
  }

  test_augmented_setters_augment_setter() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment mixin A {
  augment set foo1(int _) {}
}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
mixin A {
  set foo1(int _) {}
  set foo2(int _) {}
}
''');

    configuration.withPropertyLinking = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  parts
    part_0
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
          fields
            synthetic foo1 @-1
              reference: <testLibraryFragment>::@mixin::A::@field::foo1
              enclosingElement3: <testLibraryFragment>::@mixin::A
              type: int
              id: field_0
              setter: setter_0
            synthetic foo2 @-1
              reference: <testLibraryFragment>::@mixin::A::@field::foo2
              enclosingElement3: <testLibraryFragment>::@mixin::A
              type: int
              id: field_1
              setter: setter_1
          accessors
            set foo1= @31
              reference: <testLibraryFragment>::@mixin::A::@setter::foo1
              enclosingElement3: <testLibraryFragment>::@mixin::A
              parameters
                requiredPositional _ @40
                  type: int
              returnType: void
              id: setter_0
              variable: field_0
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@setterAugmentation::foo1
            set foo2= @52
              reference: <testLibraryFragment>::@mixin::A::@setter::foo2
              enclosingElement3: <testLibraryFragment>::@mixin::A
              parameters
                requiredPositional _ @61
                  type: int
              returnType: void
              id: setter_1
              variable: field_1
          augmented
            superclassConstraints
              Object
            fields
              <testLibraryFragment>::@mixin::A::@field::foo1
              <testLibraryFragment>::@mixin::A::@field::foo2
            accessors
              <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@setterAugmentation::foo1
              <testLibraryFragment>::@mixin::A::@setter::foo2
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      mixins
        augment mixin A @35
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@mixin::A
          accessors
            augment set foo1= @53
              reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@setterAugmentation::foo1
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
              parameters
                requiredPositional _ @62
                  type: int
              returnType: void
              id: setter_2
              variable: field_0
              augmentationTarget: <testLibraryFragment>::@mixin::A::@setter::foo1
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
          element: <testLibraryFragment>::@mixin::A#element
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          fields
            foo1 @-1
              reference: <testLibraryFragment>::@mixin::A::@field::foo1
              element: <testLibraryFragment>::@mixin::A::@field::foo1#element
              setter2: <testLibraryFragment>::@mixin::A::@setter::foo1
            foo2 @-1
              reference: <testLibraryFragment>::@mixin::A::@field::foo2
              element: <testLibraryFragment>::@mixin::A::@field::foo2#element
              setter2: <testLibraryFragment>::@mixin::A::@setter::foo2
          setters
            set foo1= @31
              reference: <testLibraryFragment>::@mixin::A::@setter::foo1
              element: <testLibraryFragment>::@mixin::A::@setter::foo1#element
              formalParameters
                _ @40
                  element: <testLibraryFragment>::@mixin::A::@setter::foo1::@parameter::_#element
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@setterAugmentation::foo1
            set foo2= @52
              reference: <testLibraryFragment>::@mixin::A::@setter::foo2
              element: <testLibraryFragment>::@mixin::A::@setter::foo2#element
              formalParameters
                _ @61
                  element: <testLibraryFragment>::@mixin::A::@setter::foo2::@parameter::_#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      mixins
        mixin A @35
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          element: <testLibraryFragment>::@mixin::A#element
          previousFragment: <testLibraryFragment>::@mixin::A
          setters
            augment set foo1= @53
              reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@setterAugmentation::foo1
              element: <testLibraryFragment>::@mixin::A::@setter::foo1#element
              formalParameters
                _ @62
                  element: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@setterAugmentation::foo1::@parameter::_#element
              previousFragment: <testLibraryFragment>::@mixin::A::@setter::foo1
  mixins
    mixin A
      firstFragment: <testLibraryFragment>::@mixin::A
      superclassConstraints
        Object
      fields
        synthetic foo1
          firstFragment: <testLibraryFragment>::@mixin::A::@field::foo1
          type: int
          setter: <testLibraryFragment>::@mixin::A::@setter::foo1#element
        synthetic foo2
          firstFragment: <testLibraryFragment>::@mixin::A::@field::foo2
          type: int
          setter: <testLibraryFragment>::@mixin::A::@setter::foo2#element
      setters
        set foo2=
          firstFragment: <testLibraryFragment>::@mixin::A::@setter::foo2
          formalParameters
            requiredPositional _
              type: int
        set foo1=
          firstFragment: <testLibraryFragment>::@mixin::A::@setter::foo1
          formalParameters
            requiredPositional _
              type: int
''');
  }

  test_augmented_superclassConstraints() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment mixin A on B2 {}
class B2 {}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
mixin A on B1 {}
class B1 {}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  parts
    part_0
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      classes
        class B1 @38
          reference: <testLibraryFragment>::@class::B1
          enclosingElement3: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::B1::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::B1
      mixins
        mixin A @21
          reference: <testLibraryFragment>::@mixin::A
          enclosingElement3: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          superclassConstraints
            B1
          augmented
            superclassConstraints
              B1
              B2
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      classes
        class B2 @52
          reference: <testLibrary>::@fragment::package:test/a.dart::@class::B2
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          constructors
            synthetic @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@class::B2::@constructor::new
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@class::B2
      mixins
        augment mixin A @35
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@mixin::A
          superclassConstraints
            B2
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      classes
        class B1 @38
          reference: <testLibraryFragment>::@class::B1
          element: <testLibraryFragment>::@class::B1#element
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::B1::@constructor::new
              element: <testLibraryFragment>::@class::B1::@constructor::new#element
      mixins
        mixin A @21
          reference: <testLibraryFragment>::@mixin::A
          element: <testLibraryFragment>::@mixin::A#element
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      classes
        class B2 @52
          reference: <testLibrary>::@fragment::package:test/a.dart::@class::B2
          element: <testLibrary>::@fragment::package:test/a.dart::@class::B2#element
          constructors
            synthetic new @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@class::B2::@constructor::new
              element: <testLibrary>::@fragment::package:test/a.dart::@class::B2::@constructor::new#element
      mixins
        mixin A @35
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          element: <testLibraryFragment>::@mixin::A#element
          previousFragment: <testLibraryFragment>::@mixin::A
  classes
    class B1
      firstFragment: <testLibraryFragment>::@class::B1
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::B1::@constructor::new
    class B2
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@class::B2
      constructors
        synthetic new
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@class::B2::@constructor::new
  mixins
    mixin A
      firstFragment: <testLibraryFragment>::@mixin::A
      superclassConstraints
        B1
        B2
''');
  }

  test_augmented_superclassConstraints_chain() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
part 'b.dart';
augment mixin A on I2 {}
class I2 {}
''');

    newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';
augment mixin A on I3 {}
class I3 {}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
mixin A on I1 {}
class I1 {}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  parts
    part_0
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      classes
        class I1 @38
          reference: <testLibraryFragment>::@class::I1
          enclosingElement3: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::I1::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::I1
      mixins
        mixin A @21
          reference: <testLibraryFragment>::@mixin::A
          enclosingElement3: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          superclassConstraints
            I1
          augmented
            superclassConstraints
              I1
              I2
              I3
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      parts
        part_1
          uri: package:test/b.dart
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          unit: <testLibrary>::@fragment::package:test/b.dart
      classes
        class I2 @67
          reference: <testLibrary>::@fragment::package:test/a.dart::@class::I2
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          constructors
            synthetic @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@class::I2::@constructor::new
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@class::I2
      mixins
        augment mixin A @50
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@mixin::A
          augmentation: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A
          superclassConstraints
            I2
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
      classes
        class I3 @49
          reference: <testLibrary>::@fragment::package:test/b.dart::@class::I3
          enclosingElement3: <testLibrary>::@fragment::package:test/b.dart
          constructors
            synthetic @-1
              reference: <testLibrary>::@fragment::package:test/b.dart::@class::I3::@constructor::new
              enclosingElement3: <testLibrary>::@fragment::package:test/b.dart::@class::I3
      mixins
        augment mixin A @32
          reference: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/b.dart
          augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          superclassConstraints
            I3
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      classes
        class I1 @38
          reference: <testLibraryFragment>::@class::I1
          element: <testLibraryFragment>::@class::I1#element
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::I1::@constructor::new
              element: <testLibraryFragment>::@class::I1::@constructor::new#element
      mixins
        mixin A @21
          reference: <testLibraryFragment>::@mixin::A
          element: <testLibraryFragment>::@mixin::A#element
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      classes
        class I2 @67
          reference: <testLibrary>::@fragment::package:test/a.dart::@class::I2
          element: <testLibrary>::@fragment::package:test/a.dart::@class::I2#element
          constructors
            synthetic new @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@class::I2::@constructor::new
              element: <testLibrary>::@fragment::package:test/a.dart::@class::I2::@constructor::new#element
      mixins
        mixin A @50
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          element: <testLibraryFragment>::@mixin::A#element
          previousFragment: <testLibraryFragment>::@mixin::A
          nextFragment: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A
    <testLibrary>::@fragment::package:test/b.dart
      element: <testLibrary>
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      classes
        class I3 @49
          reference: <testLibrary>::@fragment::package:test/b.dart::@class::I3
          element: <testLibrary>::@fragment::package:test/b.dart::@class::I3#element
          constructors
            synthetic new @-1
              reference: <testLibrary>::@fragment::package:test/b.dart::@class::I3::@constructor::new
              element: <testLibrary>::@fragment::package:test/b.dart::@class::I3::@constructor::new#element
      mixins
        mixin A @32
          reference: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A
          element: <testLibraryFragment>::@mixin::A#element
          previousFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
  classes
    class I1
      firstFragment: <testLibraryFragment>::@class::I1
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::I1::@constructor::new
    class I2
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@class::I2
      constructors
        synthetic new
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@class::I2::@constructor::new
    class I3
      firstFragment: <testLibrary>::@fragment::package:test/b.dart::@class::I3
      constructors
        synthetic new
          firstFragment: <testLibrary>::@fragment::package:test/b.dart::@class::I3::@constructor::new
  mixins
    mixin A
      firstFragment: <testLibraryFragment>::@mixin::A
      superclassConstraints
        I1
        I2
        I3
''');
  }

  test_augmented_superclassConstraints_fromAugmentation() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment mixin A on B {}
class B {}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
mixin A {}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  parts
    part_0
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
          augmented
            superclassConstraints
              B
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      classes
        class B @51
          reference: <testLibrary>::@fragment::package:test/a.dart::@class::B
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          constructors
            synthetic @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@class::B::@constructor::new
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@class::B
      mixins
        augment mixin A @35
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@mixin::A
          superclassConstraints
            B
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
          element: <testLibraryFragment>::@mixin::A#element
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      classes
        class B @51
          reference: <testLibrary>::@fragment::package:test/a.dart::@class::B
          element: <testLibrary>::@fragment::package:test/a.dart::@class::B#element
          constructors
            synthetic new @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@class::B::@constructor::new
              element: <testLibrary>::@fragment::package:test/a.dart::@class::B::@constructor::new#element
      mixins
        mixin A @35
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          element: <testLibraryFragment>::@mixin::A#element
          previousFragment: <testLibraryFragment>::@mixin::A
  classes
    class B
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@class::B
      constructors
        synthetic new
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@class::B::@constructor::new
  mixins
    mixin A
      firstFragment: <testLibraryFragment>::@mixin::A
      superclassConstraints
        B
''');
  }

  test_augmented_superclassConstraints_generic() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment mixin A<T2> on I2<T2> {}
class I2<E> {}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
mixin A<T> on I1 {}
class I1 {}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  parts
    part_0
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      classes
        class I1 @41
          reference: <testLibraryFragment>::@class::I1
          enclosingElement3: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::I1::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::I1
      mixins
        mixin A @21
          reference: <testLibraryFragment>::@mixin::A
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant T @23
              defaultType: dynamic
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          superclassConstraints
            I1
          augmented
            superclassConstraints
              I1
              I2<T>
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      classes
        class I2 @60
          reference: <testLibrary>::@fragment::package:test/a.dart::@class::I2
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          typeParameters
            covariant E @63
              defaultType: dynamic
          constructors
            synthetic @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@class::I2::@constructor::new
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@class::I2
      mixins
        augment mixin A @35
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          typeParameters
            covariant T2 @37
              defaultType: dynamic
          augmentationTarget: <testLibraryFragment>::@mixin::A
          superclassConstraints
            I2<T2>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      classes
        class I1 @41
          reference: <testLibraryFragment>::@class::I1
          element: <testLibraryFragment>::@class::I1#element
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::I1::@constructor::new
              element: <testLibraryFragment>::@class::I1::@constructor::new#element
      mixins
        mixin A @21
          reference: <testLibraryFragment>::@mixin::A
          element: <testLibraryFragment>::@mixin::A#element
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          typeParameters
            T @23
              element: <not-implemented>
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      classes
        class I2 @60
          reference: <testLibrary>::@fragment::package:test/a.dart::@class::I2
          element: <testLibrary>::@fragment::package:test/a.dart::@class::I2#element
          typeParameters
            E @63
              element: <not-implemented>
          constructors
            synthetic new @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@class::I2::@constructor::new
              element: <testLibrary>::@fragment::package:test/a.dart::@class::I2::@constructor::new#element
      mixins
        mixin A @35
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          element: <testLibraryFragment>::@mixin::A#element
          previousFragment: <testLibraryFragment>::@mixin::A
          typeParameters
            T2 @37
              element: <not-implemented>
  classes
    class I1
      firstFragment: <testLibraryFragment>::@class::I1
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::I1::@constructor::new
    class I2
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@class::I2
      typeParameters
        E
      constructors
        synthetic new
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@class::I2::@constructor::new
  mixins
    mixin A
      firstFragment: <testLibraryFragment>::@mixin::A
      typeParameters
        T
      superclassConstraints
        I1
        I2<T>
''');
  }

  test_augmentedBy_class2() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';

augment class A {}
''');

    newFile('$testPackageLibPath/b.dart', r'''
part of 'test.dart';

augment class A {}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
part 'b.dart';

mixin A {}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  parts
    part_0
    part_1
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
        part_1
          uri: package:test/b.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/b.dart
      mixins
        mixin A @37
          reference: <testLibraryFragment>::@mixin::A
          enclosingElement3: <testLibraryFragment>
          superclassConstraints
            Object
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      classes
        augment class A @36
          reference: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          augmentationTargetAny: <testLibraryFragment>::@mixin::A
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement3: <testLibraryFragment>
      classes
        augment class A @36
          reference: <testLibrary>::@fragment::package:test/b.dart::@classAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/b.dart
          augmentationTargetAny: <testLibraryFragment>::@mixin::A
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      mixins
        mixin A @37
          reference: <testLibraryFragment>::@mixin::A
          element: <testLibraryFragment>::@mixin::A#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      classes
        class A @36
          reference: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A
          element: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A#element
    <testLibrary>::@fragment::package:test/b.dart
      element: <testLibrary>
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      classes
        class A @36
          reference: <testLibrary>::@fragment::package:test/b.dart::@classAugmentation::A
          element: <testLibrary>::@fragment::package:test/b.dart::@classAugmentation::A#element
  classes
    class A
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A
    class A
      firstFragment: <testLibrary>::@fragment::package:test/b.dart::@classAugmentation::A
  mixins
    mixin A
      firstFragment: <testLibraryFragment>::@mixin::A
      superclassConstraints
        Object
''');
  }

  test_augmentedBy_class_mixin() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';

augment class A {}
''');

    newFile('$testPackageLibPath/b.dart', r'''
part of 'test.dart';

augment mixin A {}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
part 'b.dart';

mixin A {}
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
      enclosingElement3: <null>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
        part_1
          uri: package:test/b.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/b.dart
      mixins
        mixin A @37
          reference: <testLibraryFragment>::@mixin::A
          enclosingElement3: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A
          superclassConstraints
            Object
          augmented
            superclassConstraints
              Object
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      classes
        augment class A @36
          reference: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          augmentationTargetAny: <testLibraryFragment>::@mixin::A
          constructors
            synthetic @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@constructor::new
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement3: <testLibraryFragment>
      mixins
        augment mixin A @36
          reference: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/b.dart
          augmentationTarget: <testLibraryFragment>::@mixin::A
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      mixins
        mixin A @37
          reference: <testLibraryFragment>::@mixin::A
          element: <testLibraryFragment>::@mixin::A#element
          nextFragment: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      classes
        class A @36
          reference: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A
          element: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A#element
          constructors
            synthetic new @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@constructor::new
              element: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@constructor::new#element
    <testLibrary>::@fragment::package:test/b.dart
      element: <testLibrary>
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      mixins
        mixin A @36
          reference: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A
          element: <testLibraryFragment>::@mixin::A#element
          previousFragment: <testLibraryFragment>::@mixin::A
  classes
    class A
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A
      constructors
        synthetic new
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@constructor::new
  mixins
    mixin A
      firstFragment: <testLibraryFragment>::@mixin::A
      superclassConstraints
        Object
''');
  }

  test_inferTypes_method_ofAugment() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  int foo(String a) => 0;
}
''');

    newFile('$testPackageLibPath/b.dart', r'''
part of 'test.dart';
augment mixin B {
  foo(a) => 0;
}
''');

    var library = await buildLibrary(r'''
import 'a.dart';
part 'b.dart';

mixin B on A {}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/a.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  parts
    part_0
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/a.dart
          enclosingElement3: <testLibraryFragment>
      parts
        part_0
          uri: package:test/b.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/b.dart
      mixins
        mixin B @39
          reference: <testLibraryFragment>::@mixin::B
          enclosingElement3: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::B
          superclassConstraints
            A
          augmented
            superclassConstraints
              A
            methods
              <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::B::@method::foo
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement3: <testLibraryFragment>
      mixins
        augment mixin B @35
          reference: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::B
          enclosingElement3: <testLibrary>::@fragment::package:test/b.dart
          augmentationTarget: <testLibraryFragment>::@mixin::B
          methods
            foo @41
              reference: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::B::@method::foo
              enclosingElement3: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::B
              parameters
                requiredPositional a @45
                  type: String
              returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      libraryImports
        package:test/a.dart
      mixins
        mixin B @39
          reference: <testLibraryFragment>::@mixin::B
          element: <testLibraryFragment>::@mixin::B#element
          nextFragment: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::B
    <testLibrary>::@fragment::package:test/b.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      mixins
        mixin B @35
          reference: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::B
          element: <testLibraryFragment>::@mixin::B#element
          previousFragment: <testLibraryFragment>::@mixin::B
          methods
            foo @41
              reference: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::B::@method::foo
              element: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::B::@method::foo#element
              formalParameters
                a @45
                  element: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::B::@method::foo::@parameter::a#element
  mixins
    mixin B
      firstFragment: <testLibraryFragment>::@mixin::B
      superclassConstraints
        A
      methods
        foo
          firstFragment: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::B::@method::foo
          formalParameters
            requiredPositional a
              type: String
''');
  }

  test_inferTypes_method_usingAugmentation_interface() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  int foo(String a) => 0;
}
''');

    newFile('$testPackageLibPath/b.dart', r'''
part of 'test.dart';
import 'a.dart';
augment mixin B implements A {}
''');

    var library = await buildLibrary(r'''
part 'b.dart';

mixin B {
  foo(a) => 0;
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  parts
    part_0
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      parts
        part_0
          uri: package:test/b.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/b.dart
      mixins
        mixin B @22
          reference: <testLibraryFragment>::@mixin::B
          enclosingElement3: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::B
          superclassConstraints
            Object
          methods
            foo @28
              reference: <testLibraryFragment>::@mixin::B::@method::foo
              enclosingElement3: <testLibraryFragment>::@mixin::B
              parameters
                requiredPositional a @32
                  type: String
              returnType: int
          augmented
            superclassConstraints
              Object
            interfaces
              A
            methods
              <testLibraryFragment>::@mixin::B::@method::foo
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement3: <testLibraryFragment>
      libraryImports
        package:test/a.dart
          enclosingElement3: <testLibrary>::@fragment::package:test/b.dart
      mixins
        augment mixin B @52
          reference: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::B
          enclosingElement3: <testLibrary>::@fragment::package:test/b.dart
          augmentationTarget: <testLibraryFragment>::@mixin::B
          interfaces
            A
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      mixins
        mixin B @22
          reference: <testLibraryFragment>::@mixin::B
          element: <testLibraryFragment>::@mixin::B#element
          nextFragment: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::B
          methods
            foo @28
              reference: <testLibraryFragment>::@mixin::B::@method::foo
              element: <testLibraryFragment>::@mixin::B::@method::foo#element
              formalParameters
                a @32
                  element: <testLibraryFragment>::@mixin::B::@method::foo::@parameter::a#element
    <testLibrary>::@fragment::package:test/b.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      libraryImports
        package:test/a.dart
      mixins
        mixin B @52
          reference: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::B
          element: <testLibraryFragment>::@mixin::B#element
          previousFragment: <testLibraryFragment>::@mixin::B
  mixins
    mixin B
      firstFragment: <testLibraryFragment>::@mixin::B
      superclassConstraints
        Object
      methods
        foo
          firstFragment: <testLibraryFragment>::@mixin::B::@method::foo
          formalParameters
            requiredPositional a
              type: String
''');
  }

  test_inferTypes_method_usingAugmentation_superclassConstraint() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  int foo(String a) => 0;
}
''');

    newFile('$testPackageLibPath/b.dart', r'''
part of 'test.dart';
import 'a.dart';
augment mixin B on A {}
''');

    var library = await buildLibrary(r'''
part 'b.dart';

mixin B {
  foo(a) => 0;
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  parts
    part_0
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      parts
        part_0
          uri: package:test/b.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/b.dart
      mixins
        mixin B @22
          reference: <testLibraryFragment>::@mixin::B
          enclosingElement3: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::B
          methods
            foo @28
              reference: <testLibraryFragment>::@mixin::B::@method::foo
              enclosingElement3: <testLibraryFragment>::@mixin::B
              parameters
                requiredPositional a @32
                  type: String
              returnType: int
          augmented
            superclassConstraints
              A
            methods
              <testLibraryFragment>::@mixin::B::@method::foo
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement3: <testLibraryFragment>
      libraryImports
        package:test/a.dart
          enclosingElement3: <testLibrary>::@fragment::package:test/b.dart
      mixins
        augment mixin B @52
          reference: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::B
          enclosingElement3: <testLibrary>::@fragment::package:test/b.dart
          augmentationTarget: <testLibraryFragment>::@mixin::B
          superclassConstraints
            A
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      mixins
        mixin B @22
          reference: <testLibraryFragment>::@mixin::B
          element: <testLibraryFragment>::@mixin::B#element
          nextFragment: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::B
          methods
            foo @28
              reference: <testLibraryFragment>::@mixin::B::@method::foo
              element: <testLibraryFragment>::@mixin::B::@method::foo#element
              formalParameters
                a @32
                  element: <testLibraryFragment>::@mixin::B::@method::foo::@parameter::a#element
    <testLibrary>::@fragment::package:test/b.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      libraryImports
        package:test/a.dart
      mixins
        mixin B @52
          reference: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::B
          element: <testLibraryFragment>::@mixin::B#element
          previousFragment: <testLibraryFragment>::@mixin::B
  mixins
    mixin B
      firstFragment: <testLibraryFragment>::@mixin::B
      superclassConstraints
        A
      methods
        foo
          firstFragment: <testLibraryFragment>::@mixin::B::@method::foo
          formalParameters
            requiredPositional a
              type: String
''');
  }

  test_inferTypes_method_withAugment() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  int foo(String a) => 0;
}
''');

    newFile('$testPackageLibPath/b.dart', r'''
part of 'test.dart';
augment mixin B {
  augment foo(a) => 0;
}
''');

    var library = await buildLibrary(r'''
import 'a.dart';
part 'b.dart';

mixin B on A {
  foo(a) => 0;
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/a.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  parts
    part_0
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/a.dart
          enclosingElement3: <testLibraryFragment>
      parts
        part_0
          uri: package:test/b.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/b.dart
      mixins
        mixin B @39
          reference: <testLibraryFragment>::@mixin::B
          enclosingElement3: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::B
          superclassConstraints
            A
          methods
            foo @50
              reference: <testLibraryFragment>::@mixin::B::@method::foo
              enclosingElement3: <testLibraryFragment>::@mixin::B
              parameters
                requiredPositional a @54
                  type: String
              returnType: int
              augmentation: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::B::@methodAugmentation::foo
          augmented
            superclassConstraints
              A
            methods
              <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::B::@methodAugmentation::foo
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement3: <testLibraryFragment>
      mixins
        augment mixin B @35
          reference: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::B
          enclosingElement3: <testLibrary>::@fragment::package:test/b.dart
          augmentationTarget: <testLibraryFragment>::@mixin::B
          methods
            augment foo @49
              reference: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::B::@methodAugmentation::foo
              enclosingElement3: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::B
              parameters
                requiredPositional a @53
                  type: String
              returnType: int
              augmentationTarget: <testLibraryFragment>::@mixin::B::@method::foo
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      libraryImports
        package:test/a.dart
      mixins
        mixin B @39
          reference: <testLibraryFragment>::@mixin::B
          element: <testLibraryFragment>::@mixin::B#element
          nextFragment: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::B
          methods
            foo @50
              reference: <testLibraryFragment>::@mixin::B::@method::foo
              element: <testLibraryFragment>::@mixin::B::@method::foo#element
              nextFragment: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::B::@methodAugmentation::foo
              formalParameters
                a @54
                  element: <testLibraryFragment>::@mixin::B::@method::foo::@parameter::a#element
    <testLibrary>::@fragment::package:test/b.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      mixins
        mixin B @35
          reference: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::B
          element: <testLibraryFragment>::@mixin::B#element
          previousFragment: <testLibraryFragment>::@mixin::B
          methods
            augment foo @49
              reference: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::B::@methodAugmentation::foo
              element: <testLibraryFragment>::@mixin::B::@method::foo#element
              previousFragment: <testLibraryFragment>::@mixin::B::@method::foo
              formalParameters
                a @53
                  element: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::B::@methodAugmentation::foo::@parameter::a#element
  mixins
    mixin B
      firstFragment: <testLibraryFragment>::@mixin::B
      superclassConstraints
        A
      methods
        foo
          firstFragment: <testLibraryFragment>::@mixin::B::@method::foo
          formalParameters
            requiredPositional a
              type: String
''');
  }

  test_modifiers_base() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment base mixin A {}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
base mixin A {}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  parts
    part_0
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      mixins
        base mixin A @26
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
        augment base mixin A @40
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@mixin::A
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      mixins
        mixin A @26
          reference: <testLibraryFragment>::@mixin::A
          element: <testLibraryFragment>::@mixin::A#element
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      mixins
        mixin A @40
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          element: <testLibraryFragment>::@mixin::A#element
          previousFragment: <testLibraryFragment>::@mixin::A
  mixins
    base mixin A
      firstFragment: <testLibraryFragment>::@mixin::A
      superclassConstraints
        Object
''');
  }

  test_notAugmented_interfaces() async {
    var library = await buildLibrary(r'''
mixin A implements I {}
class I {}
''');

    configuration.withAugmentedWithoutAugmentation = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        class I @30
          reference: <testLibraryFragment>::@class::I
          enclosingElement3: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::I::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::I
          augmented
      mixins
        mixin A @6
          reference: <testLibraryFragment>::@mixin::A
          enclosingElement3: <testLibraryFragment>
          superclassConstraints
            Object
          interfaces
            I
          augmented
            superclassConstraints
              Object
            interfaces
              I
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class I @30
          reference: <testLibraryFragment>::@class::I
          element: <testLibraryFragment>::@class::I#element
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::I::@constructor::new
              element: <testLibraryFragment>::@class::I::@constructor::new#element
      mixins
        mixin A @6
          reference: <testLibraryFragment>::@mixin::A
          element: <testLibraryFragment>::@mixin::A#element
  classes
    class I
      firstFragment: <testLibraryFragment>::@class::I
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::I::@constructor::new
  mixins
    mixin A
      firstFragment: <testLibraryFragment>::@mixin::A
      superclassConstraints
        Object
''');
  }

  test_notAugmented_superclassConstraints() async {
    var library = await buildLibrary(r'''
mixin A on B {}
class B {}
''');

    configuration.withAugmentedWithoutAugmentation = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        class B @22
          reference: <testLibraryFragment>::@class::B
          enclosingElement3: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::B::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::B
          augmented
      mixins
        mixin A @6
          reference: <testLibraryFragment>::@mixin::A
          enclosingElement3: <testLibraryFragment>
          superclassConstraints
            B
          augmented
            superclassConstraints
              B
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class B @22
          reference: <testLibraryFragment>::@class::B
          element: <testLibraryFragment>::@class::B#element
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::B::@constructor::new
              element: <testLibraryFragment>::@class::B::@constructor::new#element
      mixins
        mixin A @6
          reference: <testLibraryFragment>::@mixin::A
          element: <testLibraryFragment>::@mixin::A#element
  classes
    class B
      firstFragment: <testLibraryFragment>::@class::B
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::B::@constructor::new
  mixins
    mixin A
      firstFragment: <testLibraryFragment>::@mixin::A
      superclassConstraints
        B
''');
  }

  test_notSimplyBounded_self() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment mixin A<T extends A> {}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
mixin A<T extends A> {}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  parts
    part_0
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      mixins
        notSimplyBounded mixin A @21
          reference: <testLibraryFragment>::@mixin::A
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant T @23
              bound: A<dynamic>
              defaultType: dynamic
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
          typeParameters
            covariant T @37
              bound: A<dynamic>
              defaultType: A<dynamic>
          augmentationTarget: <testLibraryFragment>::@mixin::A
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
          element: <testLibraryFragment>::@mixin::A#element
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          typeParameters
            T @23
              element: <not-implemented>
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      mixins
        mixin A @35
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          element: <testLibraryFragment>::@mixin::A#element
          previousFragment: <testLibraryFragment>::@mixin::A
          typeParameters
            T @37
              element: <not-implemented>
  mixins
    mixin A
      firstFragment: <testLibraryFragment>::@mixin::A
      typeParameters
        T
          bound: A<dynamic>
      superclassConstraints
        Object
''');
  }
}

@reflectiveTest
class MixinElementTest_augmentation_fromBytes
    extends MixinElementTest_augmentation {
  @override
  bool get keepLinkingLibraries => false;
}

@reflectiveTest
class MixinElementTest_augmentation_keepLinking
    extends MixinElementTest_augmentation {
  @override
  bool get keepLinkingLibraries => true;
}

@reflectiveTest
class MixinElementTest_fromBytes extends MixinElementTest {
  @override
  bool get keepLinkingLibraries => false;
}

@reflectiveTest
class MixinElementTest_keepLinking extends MixinElementTest {
  @override
  bool get keepLinkingLibraries => true;
}
