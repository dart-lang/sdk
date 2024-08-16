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
      enclosingElement: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          enclosingElement: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::A
        class B @17
          reference: <testLibraryFragment>::@class::B
          enclosingElement: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::B::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::B
        class C @28
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
        class D @39
          reference: <testLibraryFragment>::@class::D
          enclosingElement: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::D::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::D
      mixins
        mixin M @51
          reference: <testLibraryFragment>::@mixin::M
          enclosingElement: <testLibraryFragment>
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
              enclosingElement: <testLibraryFragment>::@mixin::M
              type: T
            synthetic g @-1
              reference: <testLibraryFragment>::@mixin::M::@field::g
              enclosingElement: <testLibraryFragment>::@mixin::M
              type: U
            synthetic s @-1
              reference: <testLibraryFragment>::@mixin::M::@field::s
              enclosingElement: <testLibraryFragment>::@mixin::M
              type: int
          accessors
            synthetic get f @-1
              reference: <testLibraryFragment>::@mixin::M::@getter::f
              enclosingElement: <testLibraryFragment>::@mixin::M
              returnType: T
            synthetic set f= @-1
              reference: <testLibraryFragment>::@mixin::M::@setter::f
              enclosingElement: <testLibraryFragment>::@mixin::M
              parameters
                requiredPositional _f @-1
                  type: T
              returnType: void
            get g @112
              reference: <testLibraryFragment>::@mixin::M::@getter::g
              enclosingElement: <testLibraryFragment>::@mixin::M
              returnType: U
            set s= @126
              reference: <testLibraryFragment>::@mixin::M::@setter::s
              enclosingElement: <testLibraryFragment>::@mixin::M
              parameters
                requiredPositional v @132
                  type: int
              returnType: void
          methods
            m @144
              reference: <testLibraryFragment>::@mixin::M::@method::m
              enclosingElement: <testLibraryFragment>::@mixin::M
              parameters
                requiredPositional v @153
                  type: double
              returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
        class B @17
          reference: <testLibraryFragment>::@class::B
        class C @28
          reference: <testLibraryFragment>::@class::C
        class D @39
          reference: <testLibraryFragment>::@class::D
      mixins
        mixin M @51
          reference: <testLibraryFragment>::@mixin::M
  classes
    class A
      reference: <testLibraryFragment>::@class::A
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@class::A
    class B
      reference: <testLibraryFragment>::@class::B
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@class::B
    class C
      reference: <testLibraryFragment>::@class::C
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@class::C
    class D
      reference: <testLibraryFragment>::@class::D
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@class::D
  mixins
    mixin M
      reference: <testLibraryFragment>::@mixin::M
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@mixin::M
      superclassConstraints
        A
        B
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
      enclosingElement: <testLibrary>
      mixins
        base mixin M @11
          reference: <testLibraryFragment>::@mixin::M
          enclosingElement: <testLibraryFragment>
          superclassConstraints
            Object
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      mixins
        mixin M @11
          reference: <testLibraryFragment>::@mixin::M
  mixins
    base mixin M
      reference: <testLibraryFragment>::@mixin::M
      enclosingElement2: <testLibrary>
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
      enclosingElement: <testLibrary>
      mixins
        mixin M @6
          reference: <testLibraryFragment>::@mixin::M
          enclosingElement: <testLibraryFragment>
          superclassConstraints
            Object
          fields
            final x @18
              reference: <testLibraryFragment>::@mixin::M::@field::x
              enclosingElement: <testLibraryFragment>::@mixin::M
              type: int
              shouldUseTypeForInitializerInference: false
          accessors
            synthetic get x @-1
              reference: <testLibraryFragment>::@mixin::M::@getter::x
              enclosingElement: <testLibraryFragment>::@mixin::M
              returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      mixins
        mixin M @6
          reference: <testLibraryFragment>::@mixin::M
  mixins
    mixin M
      reference: <testLibraryFragment>::@mixin::M
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@mixin::M
      superclassConstraints
        Object
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
      enclosingElement: <testLibrary>
      mixins
        mixin M @6
          reference: <testLibraryFragment>::@mixin::M
          enclosingElement: <testLibraryFragment>
          superclassConstraints
            Object
          fields
            synthetic foo @-1
              reference: <testLibraryFragment>::@mixin::M::@field::foo
              enclosingElement: <testLibraryFragment>::@mixin::M
              type: int
          accessors
            get foo @25 invokesSuperSelf
              reference: <testLibraryFragment>::@mixin::M::@getter::foo
              enclosingElement: <testLibraryFragment>::@mixin::M
              returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      mixins
        mixin M @6
          reference: <testLibraryFragment>::@mixin::M
  mixins
    mixin M
      reference: <testLibraryFragment>::@mixin::M
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@mixin::M
      superclassConstraints
        Object
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
      enclosingElement: <testLibrary>
      mixins
        mixin M @6
          reference: <testLibraryFragment>::@mixin::M
          enclosingElement: <testLibraryFragment>
          superclassConstraints
            Object
          fields
            synthetic foo @-1
              reference: <testLibraryFragment>::@mixin::M::@field::foo
              enclosingElement: <testLibraryFragment>::@mixin::M
              type: int
          accessors
            get foo @25 invokesSuperSelf
              reference: <testLibraryFragment>::@mixin::M::@getter::foo
              enclosingElement: <testLibraryFragment>::@mixin::M
              returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      mixins
        mixin M @6
          reference: <testLibraryFragment>::@mixin::M
  mixins
    mixin M
      reference: <testLibraryFragment>::@mixin::M
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@mixin::M
      superclassConstraints
        Object
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
      enclosingElement: <testLibrary>
      mixins
        mixin M @6
          reference: <testLibraryFragment>::@mixin::M
          enclosingElement: <testLibraryFragment>
          superclassConstraints
            Object
          fields
            synthetic foo @-1
              reference: <testLibraryFragment>::@mixin::M::@field::foo
              enclosingElement: <testLibraryFragment>::@mixin::M
              type: int
          accessors
            get foo @25
              reference: <testLibraryFragment>::@mixin::M::@getter::foo
              enclosingElement: <testLibraryFragment>::@mixin::M
              returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      mixins
        mixin M @6
          reference: <testLibraryFragment>::@mixin::M
  mixins
    mixin M
      reference: <testLibraryFragment>::@mixin::M
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@mixin::M
      superclassConstraints
        Object
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
      enclosingElement: <testLibrary>
      mixins
        mixin M @6
          reference: <testLibraryFragment>::@mixin::M
          enclosingElement: <testLibraryFragment>
          superclassConstraints
            Object
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      mixins
        mixin M @6
          reference: <testLibraryFragment>::@mixin::M
  mixins
    mixin M
      reference: <testLibraryFragment>::@mixin::M
      enclosingElement2: <testLibrary>
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
        class B @42
          reference: <testLibraryFragment>::@class::B
          enclosingElement: <testLibraryFragment>
          supertype: A<int>
          mixins
            M<int>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::B::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::B
              superConstructor: ConstructorMember
                base: <testLibraryFragment>::@class::A::@constructor::new
                substitution: {T: int}
      mixins
        mixin M @20
          reference: <testLibraryFragment>::@mixin::M
          enclosingElement: <testLibraryFragment>
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
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
        class B @42
          reference: <testLibraryFragment>::@class::B
      mixins
        mixin M @20
          reference: <testLibraryFragment>::@mixin::M
  classes
    class A
      reference: <testLibraryFragment>::@class::A
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@class::A
    class B
      reference: <testLibraryFragment>::@class::B
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@class::B
      supertype: A<int>
  mixins
    mixin M
      reference: <testLibraryFragment>::@mixin::M
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@mixin::M
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
        class alias B @20
          reference: <testLibraryFragment>::@class::B
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T @22
              defaultType: dynamic
          supertype: Object
          mixins
            A<T>
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@class::B::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::B
              constantInitializers
                SuperConstructorInvocation
                  superKeyword: super @0
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticElement: dart:core::<fragment>::@class::Object::@constructor::new
        class alias C @51
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          supertype: A<int>
          mixins
            B<dynamic>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
              constantInitializers
                SuperConstructorInvocation
                  superKeyword: super @0
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticElement: <testLibraryFragment>::@class::A::@constructor::new
              superConstructor: ConstructorMember
                base: <testLibraryFragment>::@class::A::@constructor::new
                substitution: {T: int}
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
        class B @20
          reference: <testLibraryFragment>::@class::B
        class C @51
          reference: <testLibraryFragment>::@class::C
  classes
    class A
      reference: <testLibraryFragment>::@class::A
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@class::A
    class alias B
      reference: <testLibraryFragment>::@class::B
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@class::B
      supertype: Object
    class alias C
      reference: <testLibraryFragment>::@class::C
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@class::C
      supertype: A<int>
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
      enclosingElement: <testLibrary>
      classes
        class A1 @6
          reference: <testLibraryFragment>::@class::A1
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T @9
              defaultType: dynamic
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::A1::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::A1
        class A2 @21
          reference: <testLibraryFragment>::@class::A2
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T @24
              defaultType: dynamic
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::A2::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::A2
        class alias B @36
          reference: <testLibraryFragment>::@class::B
          enclosingElement: <testLibraryFragment>
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
              enclosingElement: <testLibraryFragment>::@class::B
              constantInitializers
                SuperConstructorInvocation
                  superKeyword: super @0
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticElement: dart:core::<fragment>::@class::Object::@constructor::new
        class Base @75
          reference: <testLibraryFragment>::@class::Base
          enclosingElement: <testLibraryFragment>
          interfaces
            A1<int>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::Base::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::Base
        class alias C @108
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          supertype: Base
          mixins
            B<int>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
              constantInitializers
                SuperConstructorInvocation
                  superKeyword: super @0
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticElement: <testLibraryFragment>::@class::Base::@constructor::new
              superConstructor: <testLibraryFragment>::@class::Base::@constructor::new
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      classes
        class A1 @6
          reference: <testLibraryFragment>::@class::A1
        class A2 @21
          reference: <testLibraryFragment>::@class::A2
        class B @36
          reference: <testLibraryFragment>::@class::B
        class Base @75
          reference: <testLibraryFragment>::@class::Base
        class C @108
          reference: <testLibraryFragment>::@class::C
  classes
    class A1
      reference: <testLibraryFragment>::@class::A1
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@class::A1
    class A2
      reference: <testLibraryFragment>::@class::A2
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@class::A2
    class alias B
      reference: <testLibraryFragment>::@class::B
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@class::B
      supertype: Object
    class Base
      reference: <testLibraryFragment>::@class::Base
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@class::Base
    class alias C
      reference: <testLibraryFragment>::@class::C
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@class::C
      supertype: Base
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
        class C @57
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          supertype: A<int Function(String)>
          mixins
            M<int, String>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
              superConstructor: ConstructorMember
                base: <testLibraryFragment>::@class::A::@constructor::new
                substitution: {T: int Function(String)}
      mixins
        mixin M @20
          reference: <testLibraryFragment>::@mixin::M
          enclosingElement: <testLibraryFragment>
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
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
        class C @57
          reference: <testLibraryFragment>::@class::C
      mixins
        mixin M @20
          reference: <testLibraryFragment>::@mixin::M
  classes
    class A
      reference: <testLibraryFragment>::@class::A
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@class::A
    class C
      reference: <testLibraryFragment>::@class::C
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@class::C
      supertype: A<int Function(String)>
  mixins
    mixin M
      reference: <testLibraryFragment>::@mixin::M
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@mixin::M
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
      enclosingElement: <testLibrary>
      classes
        abstract class A @15
          reference: <testLibraryFragment>::@class::A
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T @17
              defaultType: dynamic
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::A
        class C @57
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          supertype: A<List<int>>
          mixins
            M<int>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
              superConstructor: ConstructorMember
                base: <testLibraryFragment>::@class::A::@constructor::new
                substitution: {T: List<int>}
      mixins
        mixin M @29
          reference: <testLibraryFragment>::@mixin::M
          enclosingElement: <testLibraryFragment>
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
      classes
        class A @15
          reference: <testLibraryFragment>::@class::A
        class C @57
          reference: <testLibraryFragment>::@class::C
      mixins
        mixin M @29
          reference: <testLibraryFragment>::@mixin::M
  classes
    abstract class A
      reference: <testLibraryFragment>::@class::A
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@class::A
    class C
      reference: <testLibraryFragment>::@class::C
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@class::C
      supertype: A<List<int>>
  mixins
    mixin M
      reference: <testLibraryFragment>::@mixin::M
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@mixin::M
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
      enclosingElement: <testLibrary>
      classes
        class I @6
          reference: <testLibraryFragment>::@class::I
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant X @8
              defaultType: dynamic
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::I::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::I
        class alias A @66
          reference: <testLibraryFragment>::@class::A
          enclosingElement: <testLibraryFragment>
          supertype: I<int>
          mixins
            M1<int>
            M2<int>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::A
              constantInitializers
                SuperConstructorInvocation
                  superKeyword: super @0
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticElement: <testLibraryFragment>::@class::I::@constructor::new
              superConstructor: ConstructorMember
                base: <testLibraryFragment>::@class::I::@constructor::new
                substitution: {X: int}
      mixins
        mixin M1 @20
          reference: <testLibraryFragment>::@mixin::M1
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T @23
              defaultType: dynamic
          superclassConstraints
            I<T>
        mixin M2 @43
          reference: <testLibraryFragment>::@mixin::M2
          enclosingElement: <testLibraryFragment>
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
      classes
        class I @6
          reference: <testLibraryFragment>::@class::I
        class A @66
          reference: <testLibraryFragment>::@class::A
      mixins
        mixin M1 @20
          reference: <testLibraryFragment>::@mixin::M1
        mixin M2 @43
          reference: <testLibraryFragment>::@mixin::M2
  classes
    class I
      reference: <testLibraryFragment>::@class::I
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@class::I
    class alias A
      reference: <testLibraryFragment>::@class::A
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@class::A
      supertype: I<int>
  mixins
    mixin M1
      reference: <testLibraryFragment>::@mixin::M1
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@mixin::M1
      superclassConstraints
        I<T>
    mixin M2
      reference: <testLibraryFragment>::@mixin::M2
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@mixin::M2
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
      enclosingElement: <testLibrary>
      classes
        class S @62
          reference: <testLibraryFragment>::@class::S
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T3 @64
              defaultType: dynamic
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::S::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::S
        class X @78
          reference: <testLibraryFragment>::@class::X
          enclosingElement: <testLibraryFragment>
          supertype: S<String>
          mixins
            M<String, int>
              alias: <testLibraryFragment>::@typeAlias::M2
                typeArguments
                  String
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::X::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::X
              superConstructor: ConstructorMember
                base: <testLibraryFragment>::@class::S::@constructor::new
                substitution: {T3: String}
      mixins
        mixin M @6
          reference: <testLibraryFragment>::@mixin::M
          enclosingElement: <testLibraryFragment>
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
      classes
        class S @62
          reference: <testLibraryFragment>::@class::S
        class X @78
          reference: <testLibraryFragment>::@class::X
      mixins
        mixin M @6
          reference: <testLibraryFragment>::@mixin::M
  classes
    class S
      reference: <testLibraryFragment>::@class::S
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@class::S
    class X
      reference: <testLibraryFragment>::@class::X
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@class::X
      supertype: S<String>
  mixins
    mixin M
      reference: <testLibraryFragment>::@mixin::M
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@mixin::M
      superclassConstraints
        S<T>
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
      enclosingElement: <testLibrary>
      classes
        class S @88
          reference: <testLibraryFragment>::@class::S
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T4 @90
              defaultType: dynamic
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::S::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::S
        class X @104
          reference: <testLibraryFragment>::@class::X
          enclosingElement: <testLibraryFragment>
          supertype: S<String>
          mixins
            M<String, int>
              alias: <testLibraryFragment>::@typeAlias::M3
                typeArguments
                  String
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::X::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::X
              superConstructor: ConstructorMember
                base: <testLibraryFragment>::@class::S::@constructor::new
                substitution: {T4: String}
      mixins
        mixin M @6
          reference: <testLibraryFragment>::@mixin::M
          enclosingElement: <testLibraryFragment>
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
      classes
        class S @88
          reference: <testLibraryFragment>::@class::S
        class X @104
          reference: <testLibraryFragment>::@class::X
      mixins
        mixin M @6
          reference: <testLibraryFragment>::@mixin::M
  classes
    class S
      reference: <testLibraryFragment>::@class::S
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@class::S
    class X
      reference: <testLibraryFragment>::@class::X
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@class::X
      supertype: S<String>
  mixins
    mixin M
      reference: <testLibraryFragment>::@mixin::M
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@mixin::M
      superclassConstraints
        S<T>
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
      enclosingElement: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          enclosingElement: <testLibraryFragment>
        class C @45
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
      extensionTypes
        B @26
          reference: <testLibraryFragment>::@extensionType::B
          enclosingElement: <testLibraryFragment>
          representation: <testLibraryFragment>::@extensionType::B::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::B::@constructor::new
          typeErasure: int
          fields
            final it @32
              reference: <testLibraryFragment>::@extensionType::B::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::B
              type: int
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::B::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::B
              returnType: int
      mixins
        mixin M @56
          reference: <testLibraryFragment>::@mixin::M
          enclosingElement: <testLibraryFragment>
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
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
        class C @45
          reference: <testLibraryFragment>::@class::C
      extensionTypes
        extension type B @26
          reference: <testLibraryFragment>::@extensionType::B
      mixins
        mixin M @56
          reference: <testLibraryFragment>::@mixin::M
  classes
    class A
      reference: <testLibraryFragment>::@class::A
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@class::A
    class C
      reference: <testLibraryFragment>::@class::C
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@class::C
  mixins
    mixin M
      reference: <testLibraryFragment>::@mixin::M
      enclosingElement2: <testLibrary>
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
      enclosingElement: <testLibrary>
      mixins
        mixin M @6
          reference: <testLibraryFragment>::@mixin::M
          enclosingElement: <testLibraryFragment>
          superclassConstraints
            Object
          methods
            foo @22 invokesSuperSelf
              reference: <testLibraryFragment>::@mixin::M::@method::foo
              enclosingElement: <testLibraryFragment>::@mixin::M
              returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      mixins
        mixin M @6
          reference: <testLibraryFragment>::@mixin::M
  mixins
    mixin M
      reference: <testLibraryFragment>::@mixin::M
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@mixin::M
      superclassConstraints
        Object
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
      enclosingElement: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          enclosingElement: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::A
      mixins
        mixin B @17
          reference: <testLibraryFragment>::@mixin::B
          enclosingElement: <testLibraryFragment>
          superclassConstraints
            A
          methods
            A @33
              reference: <testLibraryFragment>::@mixin::B::@method::A
              enclosingElement: <testLibraryFragment>::@mixin::B
              returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
      mixins
        mixin B @17
          reference: <testLibraryFragment>::@mixin::B
  classes
    class A
      reference: <testLibraryFragment>::@class::A
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@class::A
  mixins
    mixin B
      reference: <testLibraryFragment>::@mixin::B
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@mixin::B
      superclassConstraints
        A
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
      enclosingElement: <testLibrary>
      mixins
        mixin M @6
          reference: <testLibraryFragment>::@mixin::M
          enclosingElement: <testLibraryFragment>
          superclassConstraints
            Object
          fields
            synthetic foo @-1
              reference: <testLibraryFragment>::@mixin::M::@field::foo
              enclosingElement: <testLibraryFragment>::@mixin::M
              type: int
          accessors
            set foo= @21
              reference: <testLibraryFragment>::@mixin::M::@setter::foo
              enclosingElement: <testLibraryFragment>::@mixin::M
              parameters
                requiredPositional _ @29
                  type: int
              returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      mixins
        mixin M @6
          reference: <testLibraryFragment>::@mixin::M
  mixins
    mixin M
      reference: <testLibraryFragment>::@mixin::M
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@mixin::M
      superclassConstraints
        Object
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
      enclosingElement: <testLibrary>
      mixins
        mixin M @6
          reference: <testLibraryFragment>::@mixin::M
          enclosingElement: <testLibraryFragment>
          superclassConstraints
            Object
          fields
            synthetic foo @-1
              reference: <testLibraryFragment>::@mixin::M::@field::foo
              enclosingElement: <testLibraryFragment>::@mixin::M
              type: int
          accessors
            set foo= @21 invokesSuperSelf
              reference: <testLibraryFragment>::@mixin::M::@setter::foo
              enclosingElement: <testLibraryFragment>::@mixin::M
              parameters
                requiredPositional _ @29
                  type: int
              returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      mixins
        mixin M @6
          reference: <testLibraryFragment>::@mixin::M
  mixins
    mixin M
      reference: <testLibraryFragment>::@mixin::M
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@mixin::M
      superclassConstraints
        Object
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
      enclosingElement: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          enclosingElement: <testLibraryFragment>
        class C @45
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
      extensionTypes
        B @26
          reference: <testLibraryFragment>::@extensionType::B
          enclosingElement: <testLibraryFragment>
          representation: <testLibraryFragment>::@extensionType::B::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::B::@constructor::new
          typeErasure: int
          fields
            final it @32
              reference: <testLibraryFragment>::@extensionType::B::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::B
              type: int
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::B::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::B
              returnType: int
      mixins
        mixin M @56
          reference: <testLibraryFragment>::@mixin::M
          enclosingElement: <testLibraryFragment>
          superclassConstraints
            A
            C
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
        class C @45
          reference: <testLibraryFragment>::@class::C
      extensionTypes
        extension type B @26
          reference: <testLibraryFragment>::@extensionType::B
      mixins
        mixin M @56
          reference: <testLibraryFragment>::@mixin::M
  classes
    class A
      reference: <testLibraryFragment>::@class::A
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@class::A
    class C
      reference: <testLibraryFragment>::@class::C
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@class::C
  mixins
    mixin M
      reference: <testLibraryFragment>::@mixin::M
      enclosingElement2: <testLibrary>
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
      enclosingElement: <testLibrary>
      mixins
        mixin M @6
          reference: <testLibraryFragment>::@mixin::M
          enclosingElement: <testLibraryFragment>
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
      mixins
        mixin M @6
          reference: <testLibraryFragment>::@mixin::M
  mixins
    mixin M
      reference: <testLibraryFragment>::@mixin::M
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@mixin::M
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
      enclosingElement: <testLibrary>
      mixins
        mixin M @6
          reference: <testLibraryFragment>::@mixin::M
          enclosingElement: <testLibraryFragment>
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
      mixins
        mixin M @6
          reference: <testLibraryFragment>::@mixin::M
  mixins
    mixin M
      reference: <testLibraryFragment>::@mixin::M
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@mixin::M
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
      enclosingElement: <testLibrary>
      mixins
        mixin M @6
          reference: <testLibraryFragment>::@mixin::M
          enclosingElement: <testLibraryFragment>
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
      mixins
        mixin M @6
          reference: <testLibraryFragment>::@mixin::M
  mixins
    mixin M
      reference: <testLibraryFragment>::@mixin::M
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@mixin::M
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
      enclosingElement: <testLibrary>
      mixins
        mixin M @6
          reference: <testLibraryFragment>::@mixin::M
          enclosingElement: <testLibraryFragment>
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
      mixins
        mixin M @6
          reference: <testLibraryFragment>::@mixin::M
  mixins
    mixin M
      reference: <testLibraryFragment>::@mixin::M
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@mixin::M
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
      enclosingElement: <testLibrary>
      classes
        class A @17
          reference: <testLibraryFragment>::@class::A
          enclosingElement: <testLibraryFragment>
          supertype: Object
          mixins
            M
          allSupertypes
            M
            Object
      mixins
        mixin M @6
          reference: <testLibraryFragment>::@mixin::M
          enclosingElement: <testLibraryFragment>
          superclassConstraints
            Object
          allSupertypes
            Object
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      classes
        class A @17
          reference: <testLibraryFragment>::@class::A
      mixins
        mixin M @6
          reference: <testLibraryFragment>::@mixin::M
  classes
    class A
      reference: <testLibraryFragment>::@class::A
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@class::A
      supertype: Object
      allSupertypes
        M
        Object
  mixins
    mixin M
      reference: <testLibraryFragment>::@mixin::M
      enclosingElement2: <testLibrary>
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
      enclosingElement: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          enclosingElement: <testLibraryFragment>
          allSupertypes
            Object
        class B @33
          reference: <testLibraryFragment>::@class::B
          enclosingElement: <testLibraryFragment>
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
          enclosingElement: <testLibraryFragment>
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
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
        class B @33
          reference: <testLibraryFragment>::@class::B
      mixins
        mixin M @17
          reference: <testLibraryFragment>::@mixin::M
  classes
    class A
      reference: <testLibraryFragment>::@class::A
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@class::A
      allSupertypes
        Object
    class B
      reference: <testLibraryFragment>::@class::B
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@class::B
      supertype: Object
      allSupertypes
        A
        M
        Object
  mixins
    mixin M
      reference: <testLibraryFragment>::@mixin::M
      enclosingElement2: <testLibrary>
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
augment library 'test.dart';
import augment 'b.dart';
augment mixin A {}
''');

    newFile('$testPackageLibPath/b.dart', r'''
augment library 'a.dart';
augment mixin A {}
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
      augmentationImports
        package:test/b.dart
          enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
          reference: <testLibrary>::@augmentation::package:test/b.dart
          definingUnit: <testLibrary>::@fragment::package:test/b.dart
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
        augment mixin A @68
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@mixin::A
          augmentation: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/b.dart
      enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
      mixins
        augment mixin A @40
          reference: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/b.dart
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
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      mixins
        mixin A @31
          reference: <testLibraryFragment>::@mixin::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
    <testLibrary>::@fragment::package:test/a.dart
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      mixins
        mixin A @68
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          previousFragment: <testLibraryFragment>::@mixin::A
          nextFragment: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A
    <testLibrary>::@fragment::package:test/b.dart
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      mixins
        mixin A @40
          reference: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A
          previousFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
  mixins
    mixin A
      reference: <testLibraryFragment>::@mixin::A
      enclosingElement2: <testLibrary>
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
augment library 'test.dart';

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
import augment 'a.dart';
''');

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
      classes
        augment class A @44
          reference: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@def::0
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          constructors
            synthetic @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@def::0::@constructor::new
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@def::0
          methods
            foo1 @55
              reference: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@def::0::@method::foo1
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@def::0
              returnType: void
        class A @74
          reference: <testLibrary>::@fragment::package:test/a.dart::@class::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@def::1
          constructors
            synthetic @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@class::A::@constructor::new
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@class::A
          methods
            foo2 @85
              reference: <testLibrary>::@fragment::package:test/a.dart::@class::A::@method::foo2
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@class::A
              returnType: void
          augmented
            constructors
              <testLibrary>::@fragment::package:test/a.dart::@class::A::@constructor::new
            methods
              <testLibrary>::@fragment::package:test/a.dart::@class::A::@method::foo2
              <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@def::1::@method::foo3
        augment class A @112
          reference: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@def::1
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@class::A
          methods
            foo3 @123
              reference: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@def::1::@method::foo3
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@def::1
              returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
    <testLibrary>::@fragment::package:test/a.dart
      previousFragment: <testLibraryFragment>
      classes
        class A @44
          reference: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@def::0
        class A @74
          reference: <testLibrary>::@fragment::package:test/a.dart::@class::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@def::1
        class A @112
          reference: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@def::1
          previousFragment: <testLibrary>::@fragment::package:test/a.dart::@class::A
  classes
    class A
      reference: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@def::0
      enclosingElement2: <testLibrary>
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@def::0
    class A
      reference: <testLibrary>::@fragment::package:test/a.dart::@class::A
      enclosingElement2: <testLibrary>
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@class::A
''');
  }

  test_augmentationTarget_no2() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
import augment 'b.dart';
augment mixin A {
  void foo1() {}
}
''');

    newFile('$testPackageLibPath/b.dart', r'''
augment library 'a.dart';
augment mixin A {
  void foo2() {}
}
''');

    var library = await buildLibrary(r'''
import augment 'a.dart';
mixin B {}
''');

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
      mixins
        mixin B @31
          reference: <testLibraryFragment>::@mixin::B
          enclosingElement: <testLibraryFragment>
          superclassConstraints
            Object
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      mixins
        augment mixin A @68
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentation: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A
          superclassConstraints
            Object
          methods
            foo1 @79
              reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@method::foo1
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
              returnType: void
          augmented
            superclassConstraints
              Object
            methods
              <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@method::foo1
              <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A::@method::foo2
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/b.dart
      enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
      mixins
        augment mixin A @40
          reference: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/b.dart
          augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          methods
            foo2 @51
              reference: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A::@method::foo2
              enclosingElement: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A
              returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      mixins
        mixin B @31
          reference: <testLibraryFragment>::@mixin::B
    <testLibrary>::@fragment::package:test/a.dart
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      mixins
        mixin A @68
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          nextFragment: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A
    <testLibrary>::@fragment::package:test/b.dart
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      mixins
        mixin A @40
          reference: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A
          previousFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
  mixins
    mixin B
      reference: <testLibraryFragment>::@mixin::B
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@mixin::B
      superclassConstraints
        Object
    mixin A
      reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
      enclosingElement2: <testLibrary>
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
      superclassConstraints
        Object
''');
  }

  test_augmented_field_augment_field() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
augment mixin A {
  augment int foo = 1;
}
''');

    var library = await buildLibrary(r'''
import augment 'a.dart';
mixin A {
  int foo = 0;
}
''');

    configuration.withPropertyLinking = true;
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
          fields
            foo @41
              reference: <testLibraryFragment>::@mixin::A::@field::foo
              enclosingElement: <testLibraryFragment>::@mixin::A
              type: int
              shouldUseTypeForInitializerInference: true
              id: field_0
              getter: getter_0
              setter: setter_0
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@fieldAugmentation::foo
          accessors
            synthetic get foo @-1
              reference: <testLibraryFragment>::@mixin::A::@getter::foo
              enclosingElement: <testLibraryFragment>::@mixin::A
              returnType: int
              id: getter_0
              variable: field_0
            synthetic set foo= @-1
              reference: <testLibraryFragment>::@mixin::A::@setter::foo
              enclosingElement: <testLibraryFragment>::@mixin::A
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
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      mixins
        augment mixin A @43
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@mixin::A
          fields
            augment foo @61
              reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@fieldAugmentation::foo
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
              type: int
              shouldUseTypeForInitializerInference: true
              id: field_1
              augmentationTarget: <testLibraryFragment>::@mixin::A::@field::foo
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      mixins
        mixin A @31
          reference: <testLibraryFragment>::@mixin::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
    <testLibrary>::@fragment::package:test/a.dart
      previousFragment: <testLibraryFragment>
      mixins
        mixin A @43
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          previousFragment: <testLibraryFragment>::@mixin::A
  mixins
    mixin A
      reference: <testLibraryFragment>::@mixin::A
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@mixin::A
      superclassConstraints
        Object
''');
  }

  test_augmented_field_augment_field2() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
augment mixin A {
  augment int foo = 1;
}
''');

    newFile('$testPackageLibPath/b.dart', r'''
augment library 'test.dart';
augment mixin A {
  augment int foo = 2;
}
''');

    var library = await buildLibrary(r'''
import augment 'a.dart';
import augment 'b.dart';
mixin A {
  int foo = 0;
}
''');

    configuration.withPropertyLinking = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  augmentationImports
    package:test/a.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/a.dart
      definingUnit: <testLibrary>::@fragment::package:test/a.dart
    package:test/b.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/b.dart
      definingUnit: <testLibrary>::@fragment::package:test/b.dart
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      mixins
        mixin A @56
          reference: <testLibraryFragment>::@mixin::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          superclassConstraints
            Object
          fields
            foo @66
              reference: <testLibraryFragment>::@mixin::A::@field::foo
              enclosingElement: <testLibraryFragment>::@mixin::A
              type: int
              shouldUseTypeForInitializerInference: true
              id: field_0
              getter: getter_0
              setter: setter_0
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@fieldAugmentation::foo
          accessors
            synthetic get foo @-1
              reference: <testLibraryFragment>::@mixin::A::@getter::foo
              enclosingElement: <testLibraryFragment>::@mixin::A
              returnType: int
              id: getter_0
              variable: field_0
            synthetic set foo= @-1
              reference: <testLibraryFragment>::@mixin::A::@setter::foo
              enclosingElement: <testLibraryFragment>::@mixin::A
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
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      mixins
        augment mixin A @43
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@mixin::A
          augmentation: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A
          fields
            augment foo @61
              reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@fieldAugmentation::foo
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
              type: int
              shouldUseTypeForInitializerInference: true
              id: field_1
              augmentationTarget: <testLibraryFragment>::@mixin::A::@field::foo
              augmentation: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A::@fieldAugmentation::foo
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/b.dart
      enclosingElement3: <testLibraryFragment>
      mixins
        augment mixin A @43
          reference: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/b.dart
          augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          fields
            augment foo @61
              reference: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A::@fieldAugmentation::foo
              enclosingElement: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A
              type: int
              shouldUseTypeForInitializerInference: true
              id: field_2
              augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@fieldAugmentation::foo
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      mixins
        mixin A @56
          reference: <testLibraryFragment>::@mixin::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
    <testLibrary>::@fragment::package:test/a.dart
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      mixins
        mixin A @43
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          previousFragment: <testLibraryFragment>::@mixin::A
          nextFragment: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A
    <testLibrary>::@fragment::package:test/b.dart
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      mixins
        mixin A @43
          reference: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A
          previousFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
  mixins
    mixin A
      reference: <testLibraryFragment>::@mixin::A
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@mixin::A
      superclassConstraints
        Object
''');
  }

  test_augmented_field_augment_field_afterGetter() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
augment mixin A {
  augment int get foo => 1;
}
''');

    newFile('$testPackageLibPath/b.dart', r'''
augment library 'test.dart';
augment mixin A {
  augment int foo = 2;
}
''');

    var library = await buildLibrary(r'''
import augment 'a.dart';
import augment 'b.dart';
mixin A {
  int foo = 0;
}
''');

    configuration.withPropertyLinking = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  augmentationImports
    package:test/a.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/a.dart
      definingUnit: <testLibrary>::@fragment::package:test/a.dart
    package:test/b.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/b.dart
      definingUnit: <testLibrary>::@fragment::package:test/b.dart
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      mixins
        mixin A @56
          reference: <testLibraryFragment>::@mixin::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          superclassConstraints
            Object
          fields
            foo @66
              reference: <testLibraryFragment>::@mixin::A::@field::foo
              enclosingElement: <testLibraryFragment>::@mixin::A
              type: int
              shouldUseTypeForInitializerInference: true
              id: field_0
              getter: getter_0
              setter: setter_0
              augmentation: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A::@fieldAugmentation::foo
          accessors
            synthetic get foo @-1
              reference: <testLibraryFragment>::@mixin::A::@getter::foo
              enclosingElement: <testLibraryFragment>::@mixin::A
              returnType: int
              id: getter_0
              variable: field_0
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@getterAugmentation::foo
            synthetic set foo= @-1
              reference: <testLibraryFragment>::@mixin::A::@setter::foo
              enclosingElement: <testLibraryFragment>::@mixin::A
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
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      mixins
        augment mixin A @43
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@mixin::A
          augmentation: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A
          accessors
            augment get foo @65
              reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@getterAugmentation::foo
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
              returnType: int
              id: getter_1
              variable: field_0
              augmentationTarget: <testLibraryFragment>::@mixin::A::@getter::foo
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/b.dart
      enclosingElement3: <testLibraryFragment>
      mixins
        augment mixin A @43
          reference: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/b.dart
          augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          fields
            augment foo @61
              reference: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A::@fieldAugmentation::foo
              enclosingElement: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A
              type: int
              shouldUseTypeForInitializerInference: true
              id: field_1
              augmentationTarget: <testLibraryFragment>::@mixin::A::@field::foo
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      mixins
        mixin A @56
          reference: <testLibraryFragment>::@mixin::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
    <testLibrary>::@fragment::package:test/a.dart
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      mixins
        mixin A @43
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          previousFragment: <testLibraryFragment>::@mixin::A
          nextFragment: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A
    <testLibrary>::@fragment::package:test/b.dart
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      mixins
        mixin A @43
          reference: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A
          previousFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
  mixins
    mixin A
      reference: <testLibraryFragment>::@mixin::A
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@mixin::A
      superclassConstraints
        Object
''');
  }

  test_augmented_field_augment_field_afterSetter() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
augment mixin A {
  augment set foo(int _) {}
}
''');

    newFile('$testPackageLibPath/b.dart', r'''
augment library 'test.dart';
augment mixin A {
  augment int foo = 2;
}
''');

    var library = await buildLibrary(r'''
import augment 'a.dart';
import augment 'b.dart';
mixin A {
  int foo = 0;
}
''');

    configuration.withPropertyLinking = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  augmentationImports
    package:test/a.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/a.dart
      definingUnit: <testLibrary>::@fragment::package:test/a.dart
    package:test/b.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/b.dart
      definingUnit: <testLibrary>::@fragment::package:test/b.dart
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      mixins
        mixin A @56
          reference: <testLibraryFragment>::@mixin::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          superclassConstraints
            Object
          fields
            foo @66
              reference: <testLibraryFragment>::@mixin::A::@field::foo
              enclosingElement: <testLibraryFragment>::@mixin::A
              type: int
              shouldUseTypeForInitializerInference: true
              id: field_0
              getter: getter_0
              setter: setter_0
              augmentation: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A::@fieldAugmentation::foo
          accessors
            synthetic get foo @-1
              reference: <testLibraryFragment>::@mixin::A::@getter::foo
              enclosingElement: <testLibraryFragment>::@mixin::A
              returnType: int
              id: getter_0
              variable: field_0
            synthetic set foo= @-1
              reference: <testLibraryFragment>::@mixin::A::@setter::foo
              enclosingElement: <testLibraryFragment>::@mixin::A
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
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      mixins
        augment mixin A @43
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@mixin::A
          augmentation: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A
          accessors
            augment set foo= @61
              reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@setterAugmentation::foo
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
              parameters
                requiredPositional _ @69
                  type: int
              returnType: void
              id: setter_1
              variable: field_0
              augmentationTarget: <testLibraryFragment>::@mixin::A::@setter::foo
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/b.dart
      enclosingElement3: <testLibraryFragment>
      mixins
        augment mixin A @43
          reference: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/b.dart
          augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          fields
            augment foo @61
              reference: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A::@fieldAugmentation::foo
              enclosingElement: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A
              type: int
              shouldUseTypeForInitializerInference: true
              id: field_1
              augmentationTarget: <testLibraryFragment>::@mixin::A::@field::foo
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      mixins
        mixin A @56
          reference: <testLibraryFragment>::@mixin::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
    <testLibrary>::@fragment::package:test/a.dart
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      mixins
        mixin A @43
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          previousFragment: <testLibraryFragment>::@mixin::A
          nextFragment: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A
    <testLibrary>::@fragment::package:test/b.dart
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      mixins
        mixin A @43
          reference: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A
          previousFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
  mixins
    mixin A
      reference: <testLibraryFragment>::@mixin::A
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@mixin::A
      superclassConstraints
        Object
''');
  }

  test_augmented_field_augment_field_differentTypes() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
augment mixin A {
  augment double foo = 1.2;
}
''');

    var library = await buildLibrary(r'''
import augment 'a.dart';
mixin A {
  int foo = 0;
}
''');

    configuration.withPropertyLinking = true;
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
          fields
            foo @41
              reference: <testLibraryFragment>::@mixin::A::@field::foo
              enclosingElement: <testLibraryFragment>::@mixin::A
              type: int
              shouldUseTypeForInitializerInference: true
              id: field_0
              getter: getter_0
              setter: setter_0
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@fieldAugmentation::foo
          accessors
            synthetic get foo @-1
              reference: <testLibraryFragment>::@mixin::A::@getter::foo
              enclosingElement: <testLibraryFragment>::@mixin::A
              returnType: int
              id: getter_0
              variable: field_0
            synthetic set foo= @-1
              reference: <testLibraryFragment>::@mixin::A::@setter::foo
              enclosingElement: <testLibraryFragment>::@mixin::A
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
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      mixins
        augment mixin A @43
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@mixin::A
          fields
            augment foo @64
              reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@fieldAugmentation::foo
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
              type: double
              shouldUseTypeForInitializerInference: true
              id: field_1
              augmentationTarget: <testLibraryFragment>::@mixin::A::@field::foo
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      mixins
        mixin A @31
          reference: <testLibraryFragment>::@mixin::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
    <testLibrary>::@fragment::package:test/a.dart
      previousFragment: <testLibraryFragment>
      mixins
        mixin A @43
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          previousFragment: <testLibraryFragment>::@mixin::A
  mixins
    mixin A
      reference: <testLibraryFragment>::@mixin::A
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@mixin::A
      superclassConstraints
        Object
''');
  }

  /// This is not allowed by the specification, but allowed syntactically,
  /// so we need a way to handle it.
  test_augmented_field_augment_getter() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
augment mixin A {
  augment int foo = 1;
}
''');

    var library = await buildLibrary(r'''
import augment 'a.dart';
mixin A {
  int get foo => 0;
}
''');

    configuration.withPropertyLinking = true;
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
          fields
            synthetic foo @-1
              reference: <testLibraryFragment>::@mixin::A::@field::foo
              enclosingElement: <testLibraryFragment>::@mixin::A
              type: int
              id: field_0
              getter: getter_0
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@fieldAugmentation::foo
          accessors
            get foo @45
              reference: <testLibraryFragment>::@mixin::A::@getter::foo
              enclosingElement: <testLibraryFragment>::@mixin::A
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
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      mixins
        augment mixin A @43
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@mixin::A
          fields
            augment foo @61
              reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@fieldAugmentation::foo
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
              type: int
              shouldUseTypeForInitializerInference: true
              id: field_1
              augmentationTarget: <testLibraryFragment>::@mixin::A::@field::foo
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      mixins
        mixin A @31
          reference: <testLibraryFragment>::@mixin::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
    <testLibrary>::@fragment::package:test/a.dart
      previousFragment: <testLibraryFragment>
      mixins
        mixin A @43
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          previousFragment: <testLibraryFragment>::@mixin::A
  mixins
    mixin A
      reference: <testLibraryFragment>::@mixin::A
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@mixin::A
      superclassConstraints
        Object
''');
  }

  test_augmented_fields_add() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
augment mixin A {
  int foo2 = 0;
}
''');

    var library = await buildLibrary(r'''
import augment 'a.dart';
mixin A {
  int foo1 = 0;
}
''');

    configuration.withPropertyLinking = true;
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
          fields
            foo1 @41
              reference: <testLibraryFragment>::@mixin::A::@field::foo1
              enclosingElement: <testLibraryFragment>::@mixin::A
              type: int
              shouldUseTypeForInitializerInference: true
              id: field_0
              getter: getter_0
              setter: setter_0
          accessors
            synthetic get foo1 @-1
              reference: <testLibraryFragment>::@mixin::A::@getter::foo1
              enclosingElement: <testLibraryFragment>::@mixin::A
              returnType: int
              id: getter_0
              variable: field_0
            synthetic set foo1= @-1
              reference: <testLibraryFragment>::@mixin::A::@setter::foo1
              enclosingElement: <testLibraryFragment>::@mixin::A
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
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      mixins
        augment mixin A @43
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@mixin::A
          fields
            foo2 @53
              reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@field::foo2
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
              type: int
              shouldUseTypeForInitializerInference: true
              id: field_1
              getter: getter_1
              setter: setter_1
          accessors
            synthetic get foo2 @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@getter::foo2
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
              returnType: int
              id: getter_1
              variable: field_1
            synthetic set foo2= @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@setter::foo2
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
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
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      mixins
        mixin A @31
          reference: <testLibraryFragment>::@mixin::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
    <testLibrary>::@fragment::package:test/a.dart
      previousFragment: <testLibraryFragment>
      mixins
        mixin A @43
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          previousFragment: <testLibraryFragment>::@mixin::A
  mixins
    mixin A
      reference: <testLibraryFragment>::@mixin::A
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@mixin::A
      superclassConstraints
        Object
''');
  }

  test_augmented_fields_add_generic() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
augment mixin A<T2> {
  T2 foo2;
}
''');

    var library = await buildLibrary(r'''
import augment 'a.dart';
mixin A<T1> {
  T1 foo1;
}
''');

    configuration.withPropertyLinking = true;
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
          typeParameters
            covariant T1 @33
              defaultType: dynamic
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          superclassConstraints
            Object
          fields
            foo1 @44
              reference: <testLibraryFragment>::@mixin::A::@field::foo1
              enclosingElement: <testLibraryFragment>::@mixin::A
              type: T1
              id: field_0
              getter: getter_0
              setter: setter_0
          accessors
            synthetic get foo1 @-1
              reference: <testLibraryFragment>::@mixin::A::@getter::foo1
              enclosingElement: <testLibraryFragment>::@mixin::A
              returnType: T1
              id: getter_0
              variable: field_0
            synthetic set foo1= @-1
              reference: <testLibraryFragment>::@mixin::A::@setter::foo1
              enclosingElement: <testLibraryFragment>::@mixin::A
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
                augmentationSubstitution: {T2: T1}
            accessors
              <testLibraryFragment>::@mixin::A::@getter::foo1
              <testLibraryFragment>::@mixin::A::@setter::foo1
              PropertyAccessorMember
                base: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@getter::foo2
                augmentationSubstitution: {T2: T1}
              PropertyAccessorMember
                base: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@setter::foo2
                augmentationSubstitution: {T2: T1}
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      mixins
        augment mixin A @43
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          typeParameters
            covariant T2 @45
              defaultType: dynamic
          augmentationTarget: <testLibraryFragment>::@mixin::A
          fields
            foo2 @56
              reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@field::foo2
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
              type: T2
              id: field_1
              getter: getter_1
              setter: setter_1
          accessors
            synthetic get foo2 @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@getter::foo2
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
              returnType: T2
              id: getter_1
              variable: field_1
            synthetic set foo2= @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@setter::foo2
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
              parameters
                requiredPositional _foo2 @-1
                  type: T2
              returnType: void
              id: setter_1
              variable: field_1
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      mixins
        mixin A @31
          reference: <testLibraryFragment>::@mixin::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
    <testLibrary>::@fragment::package:test/a.dart
      previousFragment: <testLibraryFragment>
      mixins
        mixin A @43
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          previousFragment: <testLibraryFragment>::@mixin::A
  mixins
    mixin A
      reference: <testLibraryFragment>::@mixin::A
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@mixin::A
      superclassConstraints
        Object
''');
  }

  test_augmented_getters_add() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
augment mixin A {
  int get foo2 => 0;
}
''');

    var library = await buildLibrary(r'''
import augment 'a.dart';
mixin A {
  int get foo1 => 0;
}
''');

    configuration.withPropertyLinking = true;
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
          fields
            synthetic foo1 @-1
              reference: <testLibraryFragment>::@mixin::A::@field::foo1
              enclosingElement: <testLibraryFragment>::@mixin::A
              type: int
              id: field_0
              getter: getter_0
          accessors
            get foo1 @45
              reference: <testLibraryFragment>::@mixin::A::@getter::foo1
              enclosingElement: <testLibraryFragment>::@mixin::A
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
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      mixins
        augment mixin A @43
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@mixin::A
          fields
            synthetic foo2 @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@field::foo2
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
              type: int
              id: field_1
              getter: getter_1
          accessors
            get foo2 @57
              reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@getter::foo2
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
              returnType: int
              id: getter_1
              variable: field_1
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      mixins
        mixin A @31
          reference: <testLibraryFragment>::@mixin::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
    <testLibrary>::@fragment::package:test/a.dart
      previousFragment: <testLibraryFragment>
      mixins
        mixin A @43
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          previousFragment: <testLibraryFragment>::@mixin::A
  mixins
    mixin A
      reference: <testLibraryFragment>::@mixin::A
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@mixin::A
      superclassConstraints
        Object
''');
  }

  test_augmented_getters_add_generic() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
augment mixin A<T2> {
  T2 get foo2;
}
''');

    var library = await buildLibrary(r'''
import augment 'a.dart';
mixin A<T1> {
  T1 get foo1;
}
''');

    configuration.withPropertyLinking = true;
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
          typeParameters
            covariant T1 @33
              defaultType: dynamic
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          superclassConstraints
            Object
          fields
            synthetic foo1 @-1
              reference: <testLibraryFragment>::@mixin::A::@field::foo1
              enclosingElement: <testLibraryFragment>::@mixin::A
              type: T1
              id: field_0
              getter: getter_0
          accessors
            abstract get foo1 @48
              reference: <testLibraryFragment>::@mixin::A::@getter::foo1
              enclosingElement: <testLibraryFragment>::@mixin::A
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
                augmentationSubstitution: {T2: T1}
            accessors
              <testLibraryFragment>::@mixin::A::@getter::foo1
              PropertyAccessorMember
                base: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@getter::foo2
                augmentationSubstitution: {T2: T1}
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      mixins
        augment mixin A @43
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          typeParameters
            covariant T2 @45
              defaultType: dynamic
          augmentationTarget: <testLibraryFragment>::@mixin::A
          fields
            synthetic foo2 @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@field::foo2
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
              type: T2
              id: field_1
              getter: getter_1
          accessors
            abstract get foo2 @60
              reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@getter::foo2
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
              returnType: T2
              id: getter_1
              variable: field_1
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      mixins
        mixin A @31
          reference: <testLibraryFragment>::@mixin::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
    <testLibrary>::@fragment::package:test/a.dart
      previousFragment: <testLibraryFragment>
      mixins
        mixin A @43
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          previousFragment: <testLibraryFragment>::@mixin::A
  mixins
    mixin A
      reference: <testLibraryFragment>::@mixin::A
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@mixin::A
      superclassConstraints
        Object
''');
  }

  test_augmented_getters_augment_field() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
augment mixin A {
  augment int get foo => 0;
}
''');

    var library = await buildLibrary(r'''
import augment 'a.dart';
mixin A {
  int foo = 0;
}
''');

    configuration.withPropertyLinking = true;
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
          fields
            foo @41
              reference: <testLibraryFragment>::@mixin::A::@field::foo
              enclosingElement: <testLibraryFragment>::@mixin::A
              type: int
              shouldUseTypeForInitializerInference: true
              id: field_0
              getter: getter_0
              setter: setter_0
          accessors
            synthetic get foo @-1
              reference: <testLibraryFragment>::@mixin::A::@getter::foo
              enclosingElement: <testLibraryFragment>::@mixin::A
              returnType: int
              id: getter_0
              variable: field_0
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@getterAugmentation::foo
            synthetic set foo= @-1
              reference: <testLibraryFragment>::@mixin::A::@setter::foo
              enclosingElement: <testLibraryFragment>::@mixin::A
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
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      mixins
        augment mixin A @43
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@mixin::A
          accessors
            augment get foo @65
              reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@getterAugmentation::foo
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
              returnType: int
              id: getter_1
              variable: field_0
              augmentationTarget: <testLibraryFragment>::@mixin::A::@getter::foo
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      mixins
        mixin A @31
          reference: <testLibraryFragment>::@mixin::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
    <testLibrary>::@fragment::package:test/a.dart
      previousFragment: <testLibraryFragment>
      mixins
        mixin A @43
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          previousFragment: <testLibraryFragment>::@mixin::A
  mixins
    mixin A
      reference: <testLibraryFragment>::@mixin::A
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@mixin::A
      superclassConstraints
        Object
''');
  }

  test_augmented_getters_augment_field2() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
augment mixin A {
  augment int get foo => 0;
}
''');

    newFile('$testPackageLibPath/b.dart', r'''
augment library 'test.dart';
augment mixin A {
  augment int get foo => 0;
}
''');

    var library = await buildLibrary(r'''
import augment 'a.dart';
import augment 'b.dart';
mixin A {
  int foo = 0;
}
''');

    configuration.withPropertyLinking = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  augmentationImports
    package:test/a.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/a.dart
      definingUnit: <testLibrary>::@fragment::package:test/a.dart
    package:test/b.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/b.dart
      definingUnit: <testLibrary>::@fragment::package:test/b.dart
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      mixins
        mixin A @56
          reference: <testLibraryFragment>::@mixin::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          superclassConstraints
            Object
          fields
            foo @66
              reference: <testLibraryFragment>::@mixin::A::@field::foo
              enclosingElement: <testLibraryFragment>::@mixin::A
              type: int
              shouldUseTypeForInitializerInference: true
              id: field_0
              getter: getter_0
              setter: setter_0
          accessors
            synthetic get foo @-1
              reference: <testLibraryFragment>::@mixin::A::@getter::foo
              enclosingElement: <testLibraryFragment>::@mixin::A
              returnType: int
              id: getter_0
              variable: field_0
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@getterAugmentation::foo
            synthetic set foo= @-1
              reference: <testLibraryFragment>::@mixin::A::@setter::foo
              enclosingElement: <testLibraryFragment>::@mixin::A
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
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      mixins
        augment mixin A @43
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@mixin::A
          augmentation: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A
          accessors
            augment get foo @65
              reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@getterAugmentation::foo
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
              returnType: int
              id: getter_1
              variable: field_0
              augmentationTarget: <testLibraryFragment>::@mixin::A::@getter::foo
              augmentation: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A::@getterAugmentation::foo
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/b.dart
      enclosingElement3: <testLibraryFragment>
      mixins
        augment mixin A @43
          reference: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/b.dart
          augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          accessors
            augment get foo @65
              reference: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A::@getterAugmentation::foo
              enclosingElement: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A
              returnType: int
              id: getter_2
              variable: field_0
              augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@getterAugmentation::foo
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      mixins
        mixin A @56
          reference: <testLibraryFragment>::@mixin::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
    <testLibrary>::@fragment::package:test/a.dart
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      mixins
        mixin A @43
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          previousFragment: <testLibraryFragment>::@mixin::A
          nextFragment: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A
    <testLibrary>::@fragment::package:test/b.dart
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      mixins
        mixin A @43
          reference: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A
          previousFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
  mixins
    mixin A
      reference: <testLibraryFragment>::@mixin::A
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@mixin::A
      superclassConstraints
        Object
''');
  }

  test_augmented_getters_augment_getter() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
augment mixin A {
  augment int get foo1 => 0;
}
''');

    var library = await buildLibrary(r'''
import augment 'a.dart';
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
          fields
            synthetic foo1 @-1
              reference: <testLibraryFragment>::@mixin::A::@field::foo1
              enclosingElement: <testLibraryFragment>::@mixin::A
              type: int
              id: field_0
              getter: getter_0
            synthetic foo2 @-1
              reference: <testLibraryFragment>::@mixin::A::@field::foo2
              enclosingElement: <testLibraryFragment>::@mixin::A
              type: int
              id: field_1
              getter: getter_1
          accessors
            get foo1 @45
              reference: <testLibraryFragment>::@mixin::A::@getter::foo1
              enclosingElement: <testLibraryFragment>::@mixin::A
              returnType: int
              id: getter_0
              variable: field_0
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@getterAugmentation::foo1
            get foo2 @66
              reference: <testLibraryFragment>::@mixin::A::@getter::foo2
              enclosingElement: <testLibraryFragment>::@mixin::A
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
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      mixins
        augment mixin A @43
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@mixin::A
          accessors
            augment get foo1 @65
              reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@getterAugmentation::foo1
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
              returnType: int
              id: getter_2
              variable: field_0
              augmentationTarget: <testLibraryFragment>::@mixin::A::@getter::foo1
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      mixins
        mixin A @31
          reference: <testLibraryFragment>::@mixin::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
    <testLibrary>::@fragment::package:test/a.dart
      previousFragment: <testLibraryFragment>
      mixins
        mixin A @43
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          previousFragment: <testLibraryFragment>::@mixin::A
  mixins
    mixin A
      reference: <testLibraryFragment>::@mixin::A
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@mixin::A
      superclassConstraints
        Object
''');
  }

  test_augmented_getters_augment_getter2() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
augment mixin A {
  augment int get foo => 0;
}
''');

    newFile('$testPackageLibPath/b.dart', r'''
augment library 'test.dart';
augment mixin A {
  augment int get foo => 0;
}
''');

    var library = await buildLibrary(r'''
import augment 'a.dart';
import augment 'b.dart';
mixin A {
  int get foo => 0;
}
''');

    configuration.withPropertyLinking = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  augmentationImports
    package:test/a.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/a.dart
      definingUnit: <testLibrary>::@fragment::package:test/a.dart
    package:test/b.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/b.dart
      definingUnit: <testLibrary>::@fragment::package:test/b.dart
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      mixins
        mixin A @56
          reference: <testLibraryFragment>::@mixin::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          superclassConstraints
            Object
          fields
            synthetic foo @-1
              reference: <testLibraryFragment>::@mixin::A::@field::foo
              enclosingElement: <testLibraryFragment>::@mixin::A
              type: int
              id: field_0
              getter: getter_0
          accessors
            get foo @70
              reference: <testLibraryFragment>::@mixin::A::@getter::foo
              enclosingElement: <testLibraryFragment>::@mixin::A
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
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      mixins
        augment mixin A @43
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@mixin::A
          augmentation: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A
          accessors
            augment get foo @65
              reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@getterAugmentation::foo
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
              returnType: int
              id: getter_1
              variable: field_0
              augmentationTarget: <testLibraryFragment>::@mixin::A::@getter::foo
              augmentation: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A::@getterAugmentation::foo
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/b.dart
      enclosingElement3: <testLibraryFragment>
      mixins
        augment mixin A @43
          reference: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/b.dart
          augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          accessors
            augment get foo @65
              reference: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A::@getterAugmentation::foo
              enclosingElement: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A
              returnType: int
              id: getter_2
              variable: field_0
              augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@getterAugmentation::foo
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      mixins
        mixin A @56
          reference: <testLibraryFragment>::@mixin::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
    <testLibrary>::@fragment::package:test/a.dart
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      mixins
        mixin A @43
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          previousFragment: <testLibraryFragment>::@mixin::A
          nextFragment: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A
    <testLibrary>::@fragment::package:test/b.dart
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      mixins
        mixin A @43
          reference: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A
          previousFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
  mixins
    mixin A
      reference: <testLibraryFragment>::@mixin::A
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@mixin::A
      superclassConstraints
        Object
''');
  }

  test_augmented_interfaces() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
augment mixin A implements I2 {}
class I2 {}
''');

    var library = await buildLibrary(r'''
import augment 'a.dart';
mixin A implements I1 {}
class I1 {}
''');

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
        class I1 @56
          reference: <testLibraryFragment>::@class::I1
          enclosingElement: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::I1::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::I1
      mixins
        mixin A @31
          reference: <testLibraryFragment>::@mixin::A
          enclosingElement: <testLibraryFragment>
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
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      classes
        class I2 @68
          reference: <testLibrary>::@fragment::package:test/a.dart::@class::I2
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          constructors
            synthetic @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@class::I2::@constructor::new
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@class::I2
      mixins
        augment mixin A @43
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@mixin::A
          interfaces
            I2
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      classes
        class I1 @56
          reference: <testLibraryFragment>::@class::I1
      mixins
        mixin A @31
          reference: <testLibraryFragment>::@mixin::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
    <testLibrary>::@fragment::package:test/a.dart
      previousFragment: <testLibraryFragment>
      classes
        class I2 @68
          reference: <testLibrary>::@fragment::package:test/a.dart::@class::I2
      mixins
        mixin A @43
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          previousFragment: <testLibraryFragment>::@mixin::A
  classes
    class I1
      reference: <testLibraryFragment>::@class::I1
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@class::I1
    class I2
      reference: <testLibrary>::@fragment::package:test/a.dart::@class::I2
      enclosingElement2: <testLibrary>
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@class::I2
  mixins
    mixin A
      reference: <testLibraryFragment>::@mixin::A
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@mixin::A
      superclassConstraints
        Object
''');
  }

  test_augmented_interfaces_chain() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
import augment 'b.dart';
augment mixin A implements I2 {}
class I2 {}
''');

    newFile('$testPackageLibPath/b.dart', r'''
augment library 'a.dart';
augment mixin A implements I3 {}
class I3 {}
''');

    var library = await buildLibrary(r'''
import augment 'a.dart';
mixin A implements I1 {}
class I1 {}
''');

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
        class I1 @56
          reference: <testLibraryFragment>::@class::I1
          enclosingElement: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::I1::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::I1
      mixins
        mixin A @31
          reference: <testLibraryFragment>::@mixin::A
          enclosingElement: <testLibraryFragment>
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
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      classes
        class I2 @93
          reference: <testLibrary>::@fragment::package:test/a.dart::@class::I2
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          constructors
            synthetic @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@class::I2::@constructor::new
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@class::I2
      mixins
        augment mixin A @68
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@mixin::A
          augmentation: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A
          interfaces
            I2
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/b.dart
      enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
      classes
        class I3 @65
          reference: <testLibrary>::@fragment::package:test/b.dart::@class::I3
          enclosingElement: <testLibrary>::@fragment::package:test/b.dart
          constructors
            synthetic @-1
              reference: <testLibrary>::@fragment::package:test/b.dart::@class::I3::@constructor::new
              enclosingElement: <testLibrary>::@fragment::package:test/b.dart::@class::I3
      mixins
        augment mixin A @40
          reference: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/b.dart
          augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          interfaces
            I3
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      classes
        class I1 @56
          reference: <testLibraryFragment>::@class::I1
      mixins
        mixin A @31
          reference: <testLibraryFragment>::@mixin::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
    <testLibrary>::@fragment::package:test/a.dart
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      classes
        class I2 @93
          reference: <testLibrary>::@fragment::package:test/a.dart::@class::I2
      mixins
        mixin A @68
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          previousFragment: <testLibraryFragment>::@mixin::A
          nextFragment: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A
    <testLibrary>::@fragment::package:test/b.dart
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      classes
        class I3 @65
          reference: <testLibrary>::@fragment::package:test/b.dart::@class::I3
      mixins
        mixin A @40
          reference: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A
          previousFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
  classes
    class I1
      reference: <testLibraryFragment>::@class::I1
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@class::I1
    class I2
      reference: <testLibrary>::@fragment::package:test/a.dart::@class::I2
      enclosingElement2: <testLibrary>
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@class::I2
    class I3
      reference: <testLibrary>::@fragment::package:test/b.dart::@class::I3
      enclosingElement2: <testLibrary>
      firstFragment: <testLibrary>::@fragment::package:test/b.dart::@class::I3
  mixins
    mixin A
      reference: <testLibraryFragment>::@mixin::A
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@mixin::A
      superclassConstraints
        Object
''');
  }

  test_augmented_methods() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
augment mixin A {
  void bar() {}
}
''');

    var library = await buildLibrary(r'''
import augment 'a.dart';
mixin A {
  void foo() {}
}
''');

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
          methods
            foo @42
              reference: <testLibraryFragment>::@mixin::A::@method::foo
              enclosingElement: <testLibraryFragment>::@mixin::A
              returnType: void
          augmented
            superclassConstraints
              Object
            methods
              <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@method::bar
              <testLibraryFragment>::@mixin::A::@method::foo
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      mixins
        augment mixin A @43
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@mixin::A
          methods
            bar @54
              reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@method::bar
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
              returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      mixins
        mixin A @31
          reference: <testLibraryFragment>::@mixin::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
    <testLibrary>::@fragment::package:test/a.dart
      previousFragment: <testLibraryFragment>
      mixins
        mixin A @43
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          previousFragment: <testLibraryFragment>::@mixin::A
  mixins
    mixin A
      reference: <testLibraryFragment>::@mixin::A
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@mixin::A
      superclassConstraints
        Object
''');
  }

  test_augmented_methods_augment() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
augment mixin A {
  augment void foo1() {}
}
''');

    var library = await buildLibrary(r'''
import augment 'a.dart';
mixin A {
  void foo1() {}
  void foo2() {}
}
''');

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
          methods
            foo1 @42
              reference: <testLibraryFragment>::@mixin::A::@method::foo1
              enclosingElement: <testLibraryFragment>::@mixin::A
              returnType: void
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@methodAugmentation::foo1
            foo2 @59
              reference: <testLibraryFragment>::@mixin::A::@method::foo2
              enclosingElement: <testLibraryFragment>::@mixin::A
              returnType: void
          augmented
            superclassConstraints
              Object
            methods
              <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@methodAugmentation::foo1
              <testLibraryFragment>::@mixin::A::@method::foo2
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      mixins
        augment mixin A @43
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@mixin::A
          methods
            augment foo1 @62
              reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@methodAugmentation::foo1
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
              returnType: void
              augmentationTarget: <testLibraryFragment>::@mixin::A::@method::foo1
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      mixins
        mixin A @31
          reference: <testLibraryFragment>::@mixin::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
    <testLibrary>::@fragment::package:test/a.dart
      previousFragment: <testLibraryFragment>
      mixins
        mixin A @43
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          previousFragment: <testLibraryFragment>::@mixin::A
  mixins
    mixin A
      reference: <testLibraryFragment>::@mixin::A
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@mixin::A
      superclassConstraints
        Object
''');
  }

  test_augmented_methods_augment2() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
import augment 'b.dart';
augment mixin A {
  augment void foo() {}
}
''');

    newFile('$testPackageLibPath/b.dart', r'''
augment library 'a.dart';
augment mixin A {
  augment void foo() {}
}
''');

    var library = await buildLibrary(r'''
import augment 'a.dart';
mixin A {
  void foo() {}
}
''');

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
      mixins
        mixin A @31
          reference: <testLibraryFragment>::@mixin::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          superclassConstraints
            Object
          methods
            foo @42
              reference: <testLibraryFragment>::@mixin::A::@method::foo
              enclosingElement: <testLibraryFragment>::@mixin::A
              returnType: void
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@methodAugmentation::foo
          augmented
            superclassConstraints
              Object
            methods
              <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A::@methodAugmentation::foo
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      mixins
        augment mixin A @68
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@mixin::A
          augmentation: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A
          methods
            augment foo @87
              reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@methodAugmentation::foo
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
              returnType: void
              augmentationTarget: <testLibraryFragment>::@mixin::A::@method::foo
              augmentation: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A::@methodAugmentation::foo
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/b.dart
      enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
      mixins
        augment mixin A @40
          reference: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/b.dart
          augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          methods
            augment foo @59
              reference: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A::@methodAugmentation::foo
              enclosingElement: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A
              returnType: void
              augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@methodAugmentation::foo
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      mixins
        mixin A @31
          reference: <testLibraryFragment>::@mixin::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
    <testLibrary>::@fragment::package:test/a.dart
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      mixins
        mixin A @68
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          previousFragment: <testLibraryFragment>::@mixin::A
          nextFragment: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A
    <testLibrary>::@fragment::package:test/b.dart
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      mixins
        mixin A @40
          reference: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A
          previousFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
  mixins
    mixin A
      reference: <testLibraryFragment>::@mixin::A
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@mixin::A
      superclassConstraints
        Object
''');
  }

  test_augmented_methods_generic() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
augment mixin A<T2> {
  T2 bar() => throw 0;
}
''');

    var library = await buildLibrary(r'''
import augment 'a.dart';
mixin A<T> {
  T foo() => throw 0;
}
''');

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
          typeParameters
            covariant T @33
              defaultType: dynamic
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          superclassConstraints
            Object
          methods
            foo @42
              reference: <testLibraryFragment>::@mixin::A::@method::foo
              enclosingElement: <testLibraryFragment>::@mixin::A
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
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      mixins
        augment mixin A @43
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          typeParameters
            covariant T2 @45
              defaultType: dynamic
          augmentationTarget: <testLibraryFragment>::@mixin::A
          methods
            bar @56
              reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@method::bar
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
              returnType: T2
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      mixins
        mixin A @31
          reference: <testLibraryFragment>::@mixin::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
    <testLibrary>::@fragment::package:test/a.dart
      previousFragment: <testLibraryFragment>
      mixins
        mixin A @43
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          previousFragment: <testLibraryFragment>::@mixin::A
  mixins
    mixin A
      reference: <testLibraryFragment>::@mixin::A
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@mixin::A
      superclassConstraints
        Object
''');
  }

  test_augmented_methods_generic_augment() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
augment mixin A<T2> {
  augment T2 foo() => throw 0;
}
''');

    var library = await buildLibrary(r'''
import augment 'a.dart';
mixin A<T> {
  T foo() => throw 0;
}
''');

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
          typeParameters
            covariant T @33
              defaultType: dynamic
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          superclassConstraints
            Object
          methods
            foo @42
              reference: <testLibraryFragment>::@mixin::A::@method::foo
              enclosingElement: <testLibraryFragment>::@mixin::A
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
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      mixins
        augment mixin A @43
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          typeParameters
            covariant T2 @45
              defaultType: dynamic
          augmentationTarget: <testLibraryFragment>::@mixin::A
          methods
            augment foo @64
              reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@methodAugmentation::foo
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
              returnType: T2
              augmentationTarget: <testLibraryFragment>::@mixin::A::@method::foo
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      mixins
        mixin A @31
          reference: <testLibraryFragment>::@mixin::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
    <testLibrary>::@fragment::package:test/a.dart
      previousFragment: <testLibraryFragment>
      mixins
        mixin A @43
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          previousFragment: <testLibraryFragment>::@mixin::A
  mixins
    mixin A
      reference: <testLibraryFragment>::@mixin::A
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@mixin::A
      superclassConstraints
        Object
''');
  }

  test_augmented_methods_typeParameterCountMismatch() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
augment mixin A<T> {
  augment void foo() {}
}
''');

    var library = await buildLibrary(r'''
import augment 'a.dart';
mixin A {
  void foo() {}
  void bar() {}
}
''');

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
          methods
            foo @42
              reference: <testLibraryFragment>::@mixin::A::@method::foo
              enclosingElement: <testLibraryFragment>::@mixin::A
              returnType: void
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@methodAugmentation::foo
            bar @58
              reference: <testLibraryFragment>::@mixin::A::@method::bar
              enclosingElement: <testLibraryFragment>::@mixin::A
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
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      mixins
        augment mixin A @43
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          typeParameters
            covariant T @45
              defaultType: dynamic
          augmentationTarget: <testLibraryFragment>::@mixin::A
          methods
            augment foo @65
              reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@methodAugmentation::foo
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
              returnType: void
              augmentationTarget: <testLibraryFragment>::@mixin::A::@method::foo
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      mixins
        mixin A @31
          reference: <testLibraryFragment>::@mixin::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
    <testLibrary>::@fragment::package:test/a.dart
      previousFragment: <testLibraryFragment>
      mixins
        mixin A @43
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          previousFragment: <testLibraryFragment>::@mixin::A
  mixins
    mixin A
      reference: <testLibraryFragment>::@mixin::A
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@mixin::A
      superclassConstraints
        Object
''');
  }

  test_augmented_setters_add() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
augment mixin A {
  set foo2(int _) {}
}
''');

    var library = await buildLibrary(r'''
import augment 'a.dart';
mixin A {
  set foo1(int _) {}
}
''');

    configuration.withPropertyLinking = true;
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
          fields
            synthetic foo1 @-1
              reference: <testLibraryFragment>::@mixin::A::@field::foo1
              enclosingElement: <testLibraryFragment>::@mixin::A
              type: int
              id: field_0
              setter: setter_0
          accessors
            set foo1= @41
              reference: <testLibraryFragment>::@mixin::A::@setter::foo1
              enclosingElement: <testLibraryFragment>::@mixin::A
              parameters
                requiredPositional _ @50
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
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      mixins
        augment mixin A @43
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@mixin::A
          fields
            synthetic foo2 @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@field::foo2
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
              type: int
              id: field_1
              setter: setter_1
          accessors
            set foo2= @53
              reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@setter::foo2
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
              parameters
                requiredPositional _ @62
                  type: int
              returnType: void
              id: setter_1
              variable: field_1
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      mixins
        mixin A @31
          reference: <testLibraryFragment>::@mixin::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
    <testLibrary>::@fragment::package:test/a.dart
      previousFragment: <testLibraryFragment>
      mixins
        mixin A @43
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          previousFragment: <testLibraryFragment>::@mixin::A
  mixins
    mixin A
      reference: <testLibraryFragment>::@mixin::A
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@mixin::A
      superclassConstraints
        Object
''');
  }

  test_augmented_setters_augment_field() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
augment mixin A {
  augment set foo(int _) {}
}
''');

    var library = await buildLibrary(r'''
import augment 'a.dart';
mixin A {
  int foo = 0;
}
''');

    configuration.withPropertyLinking = true;
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
          fields
            foo @41
              reference: <testLibraryFragment>::@mixin::A::@field::foo
              enclosingElement: <testLibraryFragment>::@mixin::A
              type: int
              shouldUseTypeForInitializerInference: true
              id: field_0
              getter: getter_0
              setter: setter_0
          accessors
            synthetic get foo @-1
              reference: <testLibraryFragment>::@mixin::A::@getter::foo
              enclosingElement: <testLibraryFragment>::@mixin::A
              returnType: int
              id: getter_0
              variable: field_0
            synthetic set foo= @-1
              reference: <testLibraryFragment>::@mixin::A::@setter::foo
              enclosingElement: <testLibraryFragment>::@mixin::A
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
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      mixins
        augment mixin A @43
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@mixin::A
          accessors
            augment set foo= @61
              reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@setterAugmentation::foo
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
              parameters
                requiredPositional _ @69
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
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      mixins
        mixin A @31
          reference: <testLibraryFragment>::@mixin::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
    <testLibrary>::@fragment::package:test/a.dart
      previousFragment: <testLibraryFragment>
      mixins
        mixin A @43
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          previousFragment: <testLibraryFragment>::@mixin::A
  mixins
    mixin A
      reference: <testLibraryFragment>::@mixin::A
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@mixin::A
      superclassConstraints
        Object
''');
  }

  test_augmented_setters_augment_setter() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
augment mixin A {
  augment set foo1(int _) {}
}
''');

    var library = await buildLibrary(r'''
import augment 'a.dart';
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
          fields
            synthetic foo1 @-1
              reference: <testLibraryFragment>::@mixin::A::@field::foo1
              enclosingElement: <testLibraryFragment>::@mixin::A
              type: int
              id: field_0
              setter: setter_0
            synthetic foo2 @-1
              reference: <testLibraryFragment>::@mixin::A::@field::foo2
              enclosingElement: <testLibraryFragment>::@mixin::A
              type: int
              id: field_1
              setter: setter_1
          accessors
            set foo1= @41
              reference: <testLibraryFragment>::@mixin::A::@setter::foo1
              enclosingElement: <testLibraryFragment>::@mixin::A
              parameters
                requiredPositional _ @50
                  type: int
              returnType: void
              id: setter_0
              variable: field_0
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@setterAugmentation::foo1
            set foo2= @62
              reference: <testLibraryFragment>::@mixin::A::@setter::foo2
              enclosingElement: <testLibraryFragment>::@mixin::A
              parameters
                requiredPositional _ @71
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
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      mixins
        augment mixin A @43
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@mixin::A
          accessors
            augment set foo1= @61
              reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@setterAugmentation::foo1
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
              parameters
                requiredPositional _ @70
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
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      mixins
        mixin A @31
          reference: <testLibraryFragment>::@mixin::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
    <testLibrary>::@fragment::package:test/a.dart
      previousFragment: <testLibraryFragment>
      mixins
        mixin A @43
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          previousFragment: <testLibraryFragment>::@mixin::A
  mixins
    mixin A
      reference: <testLibraryFragment>::@mixin::A
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@mixin::A
      superclassConstraints
        Object
''');
  }

  test_augmented_superclassConstraints() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
augment mixin A on B2 {}
class B2 {}
''');

    var library = await buildLibrary(r'''
import augment 'a.dart';
mixin A on B1 {}
class B1 {}
''');

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
        class B1 @48
          reference: <testLibraryFragment>::@class::B1
          enclosingElement: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::B1::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::B1
      mixins
        mixin A @31
          reference: <testLibraryFragment>::@mixin::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          superclassConstraints
            B1
          augmented
            superclassConstraints
              B1
              B2
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      classes
        class B2 @60
          reference: <testLibrary>::@fragment::package:test/a.dart::@class::B2
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          constructors
            synthetic @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@class::B2::@constructor::new
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@class::B2
      mixins
        augment mixin A @43
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@mixin::A
          superclassConstraints
            B2
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      classes
        class B1 @48
          reference: <testLibraryFragment>::@class::B1
      mixins
        mixin A @31
          reference: <testLibraryFragment>::@mixin::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
    <testLibrary>::@fragment::package:test/a.dart
      previousFragment: <testLibraryFragment>
      classes
        class B2 @60
          reference: <testLibrary>::@fragment::package:test/a.dart::@class::B2
      mixins
        mixin A @43
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          previousFragment: <testLibraryFragment>::@mixin::A
  classes
    class B1
      reference: <testLibraryFragment>::@class::B1
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@class::B1
    class B2
      reference: <testLibrary>::@fragment::package:test/a.dart::@class::B2
      enclosingElement2: <testLibrary>
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@class::B2
  mixins
    mixin A
      reference: <testLibraryFragment>::@mixin::A
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@mixin::A
      superclassConstraints
        B1
        B2
''');
  }

  test_augmented_superclassConstraints_chain() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
import augment 'b.dart';
augment mixin A on I2 {}
class I2 {}
''');

    newFile('$testPackageLibPath/b.dart', r'''
augment library 'a.dart';
augment mixin A on I3 {}
class I3 {}
''');

    var library = await buildLibrary(r'''
import augment 'a.dart';
mixin A on I1 {}
class I1 {}
''');

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
        class I1 @48
          reference: <testLibraryFragment>::@class::I1
          enclosingElement: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::I1::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::I1
      mixins
        mixin A @31
          reference: <testLibraryFragment>::@mixin::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          superclassConstraints
            I1
          augmented
            superclassConstraints
              I1
              I2
              I3
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      classes
        class I2 @85
          reference: <testLibrary>::@fragment::package:test/a.dart::@class::I2
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          constructors
            synthetic @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@class::I2::@constructor::new
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@class::I2
      mixins
        augment mixin A @68
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@mixin::A
          augmentation: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A
          superclassConstraints
            I2
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/b.dart
      enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
      classes
        class I3 @57
          reference: <testLibrary>::@fragment::package:test/b.dart::@class::I3
          enclosingElement: <testLibrary>::@fragment::package:test/b.dart
          constructors
            synthetic @-1
              reference: <testLibrary>::@fragment::package:test/b.dart::@class::I3::@constructor::new
              enclosingElement: <testLibrary>::@fragment::package:test/b.dart::@class::I3
      mixins
        augment mixin A @40
          reference: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/b.dart
          augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          superclassConstraints
            I3
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      classes
        class I1 @48
          reference: <testLibraryFragment>::@class::I1
      mixins
        mixin A @31
          reference: <testLibraryFragment>::@mixin::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
    <testLibrary>::@fragment::package:test/a.dart
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      classes
        class I2 @85
          reference: <testLibrary>::@fragment::package:test/a.dart::@class::I2
      mixins
        mixin A @68
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          previousFragment: <testLibraryFragment>::@mixin::A
          nextFragment: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A
    <testLibrary>::@fragment::package:test/b.dart
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      classes
        class I3 @57
          reference: <testLibrary>::@fragment::package:test/b.dart::@class::I3
      mixins
        mixin A @40
          reference: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A
          previousFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
  classes
    class I1
      reference: <testLibraryFragment>::@class::I1
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@class::I1
    class I2
      reference: <testLibrary>::@fragment::package:test/a.dart::@class::I2
      enclosingElement2: <testLibrary>
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@class::I2
    class I3
      reference: <testLibrary>::@fragment::package:test/b.dart::@class::I3
      enclosingElement2: <testLibrary>
      firstFragment: <testLibrary>::@fragment::package:test/b.dart::@class::I3
  mixins
    mixin A
      reference: <testLibraryFragment>::@mixin::A
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@mixin::A
      superclassConstraints
        I1
        I2
        I3
''');
  }

  test_augmented_superclassConstraints_fromAugmentation() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
augment mixin A on B {}
class B {}
''');

    var library = await buildLibrary(r'''
import augment 'a.dart';
mixin A {}
''');

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
          augmented
            superclassConstraints
              B
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      classes
        class B @59
          reference: <testLibrary>::@fragment::package:test/a.dart::@class::B
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          constructors
            synthetic @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@class::B::@constructor::new
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@class::B
      mixins
        augment mixin A @43
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@mixin::A
          superclassConstraints
            B
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      mixins
        mixin A @31
          reference: <testLibraryFragment>::@mixin::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
    <testLibrary>::@fragment::package:test/a.dart
      previousFragment: <testLibraryFragment>
      classes
        class B @59
          reference: <testLibrary>::@fragment::package:test/a.dart::@class::B
      mixins
        mixin A @43
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          previousFragment: <testLibraryFragment>::@mixin::A
  classes
    class B
      reference: <testLibrary>::@fragment::package:test/a.dart::@class::B
      enclosingElement2: <testLibrary>
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@class::B
  mixins
    mixin A
      reference: <testLibraryFragment>::@mixin::A
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@mixin::A
      superclassConstraints
        B
''');
  }

  test_augmented_superclassConstraints_generic() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
augment mixin A<T2> on I2<T2> {}
class I2<E> {}
''');

    var library = await buildLibrary(r'''
import augment 'a.dart';
mixin A<T> on I1 {}
class I1 {}
''');

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
        class I1 @51
          reference: <testLibraryFragment>::@class::I1
          enclosingElement: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::I1::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::I1
      mixins
        mixin A @31
          reference: <testLibraryFragment>::@mixin::A
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T @33
              defaultType: dynamic
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          superclassConstraints
            I1
          augmented
            superclassConstraints
              I1
              I2<T>
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      classes
        class I2 @68
          reference: <testLibrary>::@fragment::package:test/a.dart::@class::I2
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          typeParameters
            covariant E @71
              defaultType: dynamic
          constructors
            synthetic @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@class::I2::@constructor::new
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@class::I2
      mixins
        augment mixin A @43
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          typeParameters
            covariant T2 @45
              defaultType: dynamic
          augmentationTarget: <testLibraryFragment>::@mixin::A
          superclassConstraints
            I2<T2>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      classes
        class I1 @51
          reference: <testLibraryFragment>::@class::I1
      mixins
        mixin A @31
          reference: <testLibraryFragment>::@mixin::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
    <testLibrary>::@fragment::package:test/a.dart
      previousFragment: <testLibraryFragment>
      classes
        class I2 @68
          reference: <testLibrary>::@fragment::package:test/a.dart::@class::I2
      mixins
        mixin A @43
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          previousFragment: <testLibraryFragment>::@mixin::A
  classes
    class I1
      reference: <testLibraryFragment>::@class::I1
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@class::I1
    class I2
      reference: <testLibrary>::@fragment::package:test/a.dart::@class::I2
      enclosingElement2: <testLibrary>
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@class::I2
  mixins
    mixin A
      reference: <testLibraryFragment>::@mixin::A
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@mixin::A
      superclassConstraints
        I1
        I2<T>
''');
  }

  test_augmentedBy_class2() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';

augment class A {}
''');

    newFile('$testPackageLibPath/b.dart', r'''
augment library 'test.dart';

augment class A {}
''');

    var library = await buildLibrary(r'''
import augment 'a.dart';
import augment 'b.dart';

mixin A {}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  augmentationImports
    package:test/a.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/a.dart
      definingUnit: <testLibrary>::@fragment::package:test/a.dart
    package:test/b.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/b.dart
      definingUnit: <testLibrary>::@fragment::package:test/b.dart
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      mixins
        mixin A @57
          reference: <testLibraryFragment>::@mixin::A
          enclosingElement: <testLibraryFragment>
          superclassConstraints
            Object
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      classes
        augment class A @44
          reference: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTargetAny: <testLibraryFragment>::@mixin::A
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/b.dart
      enclosingElement3: <testLibraryFragment>
      classes
        augment class A @44
          reference: <testLibrary>::@fragment::package:test/b.dart::@classAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/b.dart
          augmentationTargetAny: <testLibraryFragment>::@mixin::A
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      mixins
        mixin A @57
          reference: <testLibraryFragment>::@mixin::A
    <testLibrary>::@fragment::package:test/a.dart
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      classes
        class A @44
          reference: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A
    <testLibrary>::@fragment::package:test/b.dart
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      classes
        class A @44
          reference: <testLibrary>::@fragment::package:test/b.dart::@classAugmentation::A
  classes
    class A
      reference: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A
      enclosingElement2: <testLibrary>
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A
    class A
      reference: <testLibrary>::@fragment::package:test/b.dart::@classAugmentation::A
      enclosingElement2: <testLibrary>
      firstFragment: <testLibrary>::@fragment::package:test/b.dart::@classAugmentation::A
  mixins
    mixin A
      reference: <testLibraryFragment>::@mixin::A
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@mixin::A
      superclassConstraints
        Object
''');
  }

  test_augmentedBy_class_mixin() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';

augment class A {}
''');

    newFile('$testPackageLibPath/b.dart', r'''
augment library 'test.dart';

augment mixin A {}
''');

    var library = await buildLibrary(r'''
import augment 'a.dart';
import augment 'b.dart';

mixin A {}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  augmentationImports
    package:test/a.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/a.dart
      definingUnit: <testLibrary>::@fragment::package:test/a.dart
    package:test/b.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/b.dart
      definingUnit: <testLibrary>::@fragment::package:test/b.dart
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      mixins
        mixin A @57
          reference: <testLibraryFragment>::@mixin::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A
          superclassConstraints
            Object
          augmented
            superclassConstraints
              Object
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      classes
        augment class A @44
          reference: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTargetAny: <testLibraryFragment>::@mixin::A
          constructors
            synthetic @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@constructor::new
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/b.dart
      enclosingElement3: <testLibraryFragment>
      mixins
        augment mixin A @44
          reference: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/b.dart
          augmentationTarget: <testLibraryFragment>::@mixin::A
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      mixins
        mixin A @57
          reference: <testLibraryFragment>::@mixin::A
          nextFragment: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A
    <testLibrary>::@fragment::package:test/a.dart
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      classes
        class A @44
          reference: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A
    <testLibrary>::@fragment::package:test/b.dart
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      mixins
        mixin A @44
          reference: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A
          previousFragment: <testLibraryFragment>::@mixin::A
  classes
    class A
      reference: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A
      enclosingElement2: <testLibrary>
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A
  mixins
    mixin A
      reference: <testLibraryFragment>::@mixin::A
      enclosingElement2: <testLibrary>
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
augment library 'test.dart';
augment mixin B {
  foo(a) => 0;
}
''');

    var library = await buildLibrary(r'''
import 'a.dart';
import augment 'b.dart';

mixin B on A {}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  augmentationImports
    package:test/b.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/b.dart
      definingUnit: <testLibrary>::@fragment::package:test/b.dart
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryImports
        package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
      mixins
        mixin B @49
          reference: <testLibraryFragment>::@mixin::B
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::B
          superclassConstraints
            A
          augmented
            superclassConstraints
              A
            methods
              <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::B::@method::foo
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/b.dart
      enclosingElement3: <testLibraryFragment>
      mixins
        augment mixin B @43
          reference: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::B
          enclosingElement: <testLibrary>::@fragment::package:test/b.dart
          augmentationTarget: <testLibraryFragment>::@mixin::B
          methods
            foo @49
              reference: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::B::@method::foo
              enclosingElement: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::B
              parameters
                requiredPositional a @53
                  type: String
              returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      libraryImports
        package:test/a.dart
      mixins
        mixin B @49
          reference: <testLibraryFragment>::@mixin::B
          nextFragment: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::B
    <testLibrary>::@fragment::package:test/b.dart
      previousFragment: <testLibraryFragment>
      mixins
        mixin B @43
          reference: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::B
          previousFragment: <testLibraryFragment>::@mixin::B
  mixins
    mixin B
      reference: <testLibraryFragment>::@mixin::B
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@mixin::B
      superclassConstraints
        A
''');
  }

  test_inferTypes_method_usingAugmentation_interface() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  int foo(String a) => 0;
}
''');

    newFile('$testPackageLibPath/b.dart', r'''
augment library 'test.dart';
import 'a.dart';
augment mixin B implements A {}
''');

    var library = await buildLibrary(r'''
import augment 'b.dart';

mixin B {
  foo(a) => 0;
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  augmentationImports
    package:test/b.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/b.dart
      libraryImports
        package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibrary>::@fragment::package:test/b.dart
      definingUnit: <testLibrary>::@fragment::package:test/b.dart
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      mixins
        mixin B @32
          reference: <testLibraryFragment>::@mixin::B
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::B
          superclassConstraints
            Object
          methods
            foo @38
              reference: <testLibraryFragment>::@mixin::B::@method::foo
              enclosingElement: <testLibraryFragment>::@mixin::B
              parameters
                requiredPositional a @42
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
      enclosingElement: <testLibrary>::@augmentation::package:test/b.dart
      enclosingElement3: <testLibraryFragment>
      libraryImports
        package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibrary>::@fragment::package:test/b.dart
      mixins
        augment mixin B @60
          reference: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::B
          enclosingElement: <testLibrary>::@fragment::package:test/b.dart
          augmentationTarget: <testLibraryFragment>::@mixin::B
          interfaces
            A
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      mixins
        mixin B @32
          reference: <testLibraryFragment>::@mixin::B
          nextFragment: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::B
    <testLibrary>::@fragment::package:test/b.dart
      previousFragment: <testLibraryFragment>
      libraryImports
        package:test/a.dart
      mixins
        mixin B @60
          reference: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::B
          previousFragment: <testLibraryFragment>::@mixin::B
  mixins
    mixin B
      reference: <testLibraryFragment>::@mixin::B
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@mixin::B
      superclassConstraints
        Object
''');
  }

  test_inferTypes_method_usingAugmentation_superclassConstraint() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  int foo(String a) => 0;
}
''');

    newFile('$testPackageLibPath/b.dart', r'''
augment library 'test.dart';
import 'a.dart';
augment mixin B on A {}
''');

    var library = await buildLibrary(r'''
import augment 'b.dart';

mixin B {
  foo(a) => 0;
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  augmentationImports
    package:test/b.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/b.dart
      libraryImports
        package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibrary>::@fragment::package:test/b.dart
      definingUnit: <testLibrary>::@fragment::package:test/b.dart
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      mixins
        mixin B @32
          reference: <testLibraryFragment>::@mixin::B
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::B
          methods
            foo @38
              reference: <testLibraryFragment>::@mixin::B::@method::foo
              enclosingElement: <testLibraryFragment>::@mixin::B
              parameters
                requiredPositional a @42
                  type: String
              returnType: int
          augmented
            superclassConstraints
              A
            methods
              <testLibraryFragment>::@mixin::B::@method::foo
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/b.dart
      enclosingElement3: <testLibraryFragment>
      libraryImports
        package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibrary>::@fragment::package:test/b.dart
      mixins
        augment mixin B @60
          reference: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::B
          enclosingElement: <testLibrary>::@fragment::package:test/b.dart
          augmentationTarget: <testLibraryFragment>::@mixin::B
          superclassConstraints
            A
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      mixins
        mixin B @32
          reference: <testLibraryFragment>::@mixin::B
          nextFragment: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::B
    <testLibrary>::@fragment::package:test/b.dart
      previousFragment: <testLibraryFragment>
      libraryImports
        package:test/a.dart
      mixins
        mixin B @60
          reference: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::B
          previousFragment: <testLibraryFragment>::@mixin::B
  mixins
    mixin B
      reference: <testLibraryFragment>::@mixin::B
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@mixin::B
      superclassConstraints
        A
''');
  }

  test_inferTypes_method_withAugment() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  int foo(String a) => 0;
}
''');

    newFile('$testPackageLibPath/b.dart', r'''
augment library 'test.dart';
augment mixin B {
  augment foo(a) => 0;
}
''');

    var library = await buildLibrary(r'''
import 'a.dart';
import augment 'b.dart';

mixin B on A {
  foo(a) => 0;
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  augmentationImports
    package:test/b.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/b.dart
      definingUnit: <testLibrary>::@fragment::package:test/b.dart
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryImports
        package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
      mixins
        mixin B @49
          reference: <testLibraryFragment>::@mixin::B
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::B
          superclassConstraints
            A
          methods
            foo @60
              reference: <testLibraryFragment>::@mixin::B::@method::foo
              enclosingElement: <testLibraryFragment>::@mixin::B
              parameters
                requiredPositional a @64
                  type: String
              returnType: int
              augmentation: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::B::@methodAugmentation::foo
          augmented
            superclassConstraints
              A
            methods
              <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::B::@methodAugmentation::foo
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/b.dart
      enclosingElement3: <testLibraryFragment>
      mixins
        augment mixin B @43
          reference: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::B
          enclosingElement: <testLibrary>::@fragment::package:test/b.dart
          augmentationTarget: <testLibraryFragment>::@mixin::B
          methods
            augment foo @57
              reference: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::B::@methodAugmentation::foo
              enclosingElement: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::B
              parameters
                requiredPositional a @61
                  type: String
              returnType: int
              augmentationTarget: <testLibraryFragment>::@mixin::B::@method::foo
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      libraryImports
        package:test/a.dart
      mixins
        mixin B @49
          reference: <testLibraryFragment>::@mixin::B
          nextFragment: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::B
    <testLibrary>::@fragment::package:test/b.dart
      previousFragment: <testLibraryFragment>
      mixins
        mixin B @43
          reference: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::B
          previousFragment: <testLibraryFragment>::@mixin::B
  mixins
    mixin B
      reference: <testLibraryFragment>::@mixin::B
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@mixin::B
      superclassConstraints
        A
''');
  }

  test_modifiers_base() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
augment base mixin A {}
''');

    var library = await buildLibrary(r'''
import augment 'a.dart';
base mixin A {}
''');

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
        base mixin A @36
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
        augment base mixin A @48
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@mixin::A
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      mixins
        mixin A @36
          reference: <testLibraryFragment>::@mixin::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
    <testLibrary>::@fragment::package:test/a.dart
      previousFragment: <testLibraryFragment>
      mixins
        mixin A @48
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          previousFragment: <testLibraryFragment>::@mixin::A
  mixins
    base mixin A
      reference: <testLibraryFragment>::@mixin::A
      enclosingElement2: <testLibrary>
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
      enclosingElement: <testLibrary>
      classes
        class I @30
          reference: <testLibraryFragment>::@class::I
          enclosingElement: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::I::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::I
          augmented
      mixins
        mixin A @6
          reference: <testLibraryFragment>::@mixin::A
          enclosingElement: <testLibraryFragment>
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
      classes
        class I @30
          reference: <testLibraryFragment>::@class::I
      mixins
        mixin A @6
          reference: <testLibraryFragment>::@mixin::A
  classes
    class I
      reference: <testLibraryFragment>::@class::I
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@class::I
  mixins
    mixin A
      reference: <testLibraryFragment>::@mixin::A
      enclosingElement2: <testLibrary>
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
      enclosingElement: <testLibrary>
      classes
        class B @22
          reference: <testLibraryFragment>::@class::B
          enclosingElement: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::B::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::B
          augmented
      mixins
        mixin A @6
          reference: <testLibraryFragment>::@mixin::A
          enclosingElement: <testLibraryFragment>
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
      classes
        class B @22
          reference: <testLibraryFragment>::@class::B
      mixins
        mixin A @6
          reference: <testLibraryFragment>::@mixin::A
  classes
    class B
      reference: <testLibraryFragment>::@class::B
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@class::B
  mixins
    mixin A
      reference: <testLibraryFragment>::@mixin::A
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@mixin::A
      superclassConstraints
        B
''');
  }

  test_notSimplyBounded_self() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
augment mixin A<T extends A> {}
''');

    var library = await buildLibrary(r'''
import augment 'a.dart';
mixin A<T extends A> {}
''');

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
        notSimplyBounded mixin A @31
          reference: <testLibraryFragment>::@mixin::A
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T @33
              bound: A<dynamic>
              defaultType: dynamic
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
          typeParameters
            covariant T @45
              bound: A<dynamic>
              defaultType: A<dynamic>
          augmentationTarget: <testLibraryFragment>::@mixin::A
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      mixins
        mixin A @31
          reference: <testLibraryFragment>::@mixin::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
    <testLibrary>::@fragment::package:test/a.dart
      previousFragment: <testLibraryFragment>
      mixins
        mixin A @43
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          previousFragment: <testLibraryFragment>::@mixin::A
  mixins
    mixin A
      reference: <testLibraryFragment>::@mixin::A
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@mixin::A
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
