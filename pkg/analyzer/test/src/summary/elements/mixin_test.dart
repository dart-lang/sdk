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
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A (nameOffset:17) (firstTokenOffset:11) (offset:17)
          element: <testLibrary>::@class::A
      mixins
        #F2 mixin M (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@mixin::M
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      supertype: Object
      mixins
        M
      allSupertypes
        M
        Object
  mixins
    mixin M
      reference: <testLibrary>::@mixin::M
      firstFragment: #F2
      superclassConstraints
        Object
      allSupertypes
        Object
''');
  }

  test_allSupertypes_generic() async {
    var library = await buildLibrary(r'''
class A<T, U> {}
class B<T> extends A<int, T> {}

mixin M1 on A<int, double> {}
mixin M2 on B<String> {}
''');

    configuration
      ..withAllSupertypes = true
      ..withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::A
          typeParameters
            #F2 T (nameOffset:8) (firstTokenOffset:8) (offset:8)
              element: #E0 T
            #F3 U (nameOffset:11) (firstTokenOffset:11) (offset:11)
              element: #E1 U
        #F4 class B (nameOffset:23) (firstTokenOffset:17) (offset:23)
          element: <testLibrary>::@class::B
          typeParameters
            #F5 T (nameOffset:25) (firstTokenOffset:25) (offset:25)
              element: #E2 T
      mixins
        #F6 mixin M1 (nameOffset:56) (firstTokenOffset:50) (offset:56)
          element: <testLibrary>::@mixin::M1
        #F7 mixin M2 (nameOffset:86) (firstTokenOffset:80) (offset:86)
          element: <testLibrary>::@mixin::M2
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
        #E1 U
          firstFragment: #F3
      allSupertypes
        Object
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F4
      typeParameters
        #E2 T
          firstFragment: #F5
      supertype: A<int, T>
      allSupertypes
        A<int, T>
        Object
  mixins
    mixin M1
      reference: <testLibrary>::@mixin::M1
      firstFragment: #F6
      superclassConstraints
        A<int, double>
      allSupertypes
        A<int, double>
        Object
    mixin M2
      reference: <testLibrary>::@mixin::M2
      firstFragment: #F7
      superclassConstraints
        B<String>
      allSupertypes
        A<int, String>
        B<String>
        Object
''');
  }

  test_allSupertypes_hasInterfaces() async {
    var library = await buildLibrary(r'''
class A {}
class B {}
class C {}

mixin M on A implements B, C {}
''');

    configuration
      ..withAllSupertypes = true
      ..withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::A
        #F2 class B (nameOffset:17) (firstTokenOffset:11) (offset:17)
          element: <testLibrary>::@class::B
        #F3 class C (nameOffset:28) (firstTokenOffset:22) (offset:28)
          element: <testLibrary>::@class::C
      mixins
        #F4 mixin M (nameOffset:40) (firstTokenOffset:34) (offset:40)
          element: <testLibrary>::@mixin::M
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      allSupertypes
        Object
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F2
      allSupertypes
        Object
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F3
      allSupertypes
        Object
  mixins
    mixin M
      reference: <testLibrary>::@mixin::M
      firstFragment: #F4
      superclassConstraints
        A
      interfaces
        B
        C
      allSupertypes
        A
        B
        C
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
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::A
        #F2 class B (nameOffset:33) (firstTokenOffset:27) (offset:33)
          element: <testLibrary>::@class::B
      mixins
        #F3 mixin M (nameOffset:17) (firstTokenOffset:11) (offset:17)
          element: <testLibrary>::@mixin::M
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      allSupertypes
        Object
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F2
      supertype: Object
      mixins
        M
      allSupertypes
        A
        M
        Object
  mixins
    mixin M
      reference: <testLibrary>::@mixin::M
      firstFragment: #F3
      superclassConstraints
        A
      allSupertypes
        A
        Object
''');
  }

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
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::A
          constructors
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
        #F3 class B (nameOffset:17) (firstTokenOffset:11) (offset:17)
          element: <testLibrary>::@class::B
          constructors
            #F4 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:17)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
        #F5 class C (nameOffset:28) (firstTokenOffset:22) (offset:28)
          element: <testLibrary>::@class::C
          constructors
            #F6 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:28)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
        #F7 class D (nameOffset:39) (firstTokenOffset:33) (offset:39)
          element: <testLibrary>::@class::D
          constructors
            #F8 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:39)
              element: <testLibrary>::@class::D::@constructor::new
              typeName: D
      mixins
        #F9 mixin M (nameOffset:51) (firstTokenOffset:45) (offset:51)
          element: <testLibrary>::@mixin::M
          typeParameters
            #F10 T (nameOffset:53) (firstTokenOffset:53) (offset:53)
              element: #E0 T
            #F11 U (nameOffset:68) (firstTokenOffset:68) (offset:68)
              element: #E1 U
          fields
            #F12 f (nameOffset:101) (firstTokenOffset:101) (offset:101)
              element: <testLibrary>::@mixin::M::@field::f
            #F13 synthetic g (nameOffset:<null>) (firstTokenOffset:<null>) (offset:51)
              element: <testLibrary>::@mixin::M::@field::g
            #F14 synthetic s (nameOffset:<null>) (firstTokenOffset:<null>) (offset:51)
              element: <testLibrary>::@mixin::M::@field::s
          getters
            #F15 synthetic f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:101)
              element: <testLibrary>::@mixin::M::@getter::f
            #F16 g (nameOffset:112) (firstTokenOffset:106) (offset:112)
              element: <testLibrary>::@mixin::M::@getter::g
          setters
            #F17 synthetic f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:101)
              element: <testLibrary>::@mixin::M::@setter::f
              formalParameters
                #F18 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:101)
                  element: <testLibrary>::@mixin::M::@setter::f::@formalParameter::value
            #F19 s (nameOffset:126) (firstTokenOffset:122) (offset:126)
              element: <testLibrary>::@mixin::M::@setter::s
              formalParameters
                #F20 v (nameOffset:132) (firstTokenOffset:128) (offset:132)
                  element: <testLibrary>::@mixin::M::@setter::s::@formalParameter::v
          methods
            #F21 m (nameOffset:144) (firstTokenOffset:140) (offset:144)
              element: <testLibrary>::@mixin::M::@method::m
              formalParameters
                #F22 v (nameOffset:153) (firstTokenOffset:146) (offset:153)
                  element: <testLibrary>::@mixin::M::@method::m::@formalParameter::v
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F3
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F4
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F5
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F6
    class D
      reference: <testLibrary>::@class::D
      firstFragment: #F7
      constructors
        synthetic new
          reference: <testLibrary>::@class::D::@constructor::new
          firstFragment: #F8
  mixins
    hasNonFinalField mixin M
      reference: <testLibrary>::@mixin::M
      firstFragment: #F9
      typeParameters
        #E0 T
          firstFragment: #F10
          bound: num
        #E1 U
          firstFragment: #F11
      superclassConstraints
        A
        B
      interfaces
        C
        D
      fields
        f
          reference: <testLibrary>::@mixin::M::@field::f
          firstFragment: #F12
          hasEnclosingTypeParameterReference: true
          type: T
          getter: <testLibrary>::@mixin::M::@getter::f
          setter: <testLibrary>::@mixin::M::@setter::f
        synthetic g
          reference: <testLibrary>::@mixin::M::@field::g
          firstFragment: #F13
          hasEnclosingTypeParameterReference: true
          type: U
          getter: <testLibrary>::@mixin::M::@getter::g
        synthetic s
          reference: <testLibrary>::@mixin::M::@field::s
          firstFragment: #F14
          type: int
          setter: <testLibrary>::@mixin::M::@setter::s
      getters
        synthetic f
          reference: <testLibrary>::@mixin::M::@getter::f
          firstFragment: #F15
          hasEnclosingTypeParameterReference: true
          returnType: T
          variable: <testLibrary>::@mixin::M::@field::f
        g
          reference: <testLibrary>::@mixin::M::@getter::g
          firstFragment: #F16
          hasEnclosingTypeParameterReference: true
          returnType: U
          variable: <testLibrary>::@mixin::M::@field::g
      setters
        synthetic f
          reference: <testLibrary>::@mixin::M::@setter::f
          firstFragment: #F17
          hasEnclosingTypeParameterReference: true
          formalParameters
            #E2 requiredPositional value
              firstFragment: #F18
              type: T
          returnType: void
          variable: <testLibrary>::@mixin::M::@field::f
        s
          reference: <testLibrary>::@mixin::M::@setter::s
          firstFragment: #F19
          formalParameters
            #E3 requiredPositional v
              firstFragment: #F20
              type: int
          returnType: void
          variable: <testLibrary>::@mixin::M::@field::s
      methods
        m
          reference: <testLibrary>::@mixin::M::@method::m
          firstFragment: #F21
          formalParameters
            #E4 requiredPositional v
              firstFragment: #F22
              type: double
          returnType: int
''');
  }

  test_mixin_base() async {
    var library = await buildLibrary(r'''
base mixin M on A {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      mixins
        #F1 mixin M (nameOffset:11) (firstTokenOffset:0) (offset:11)
          element: <testLibrary>::@mixin::M
  mixins
    base mixin M
      reference: <testLibrary>::@mixin::M
      firstFragment: #F1
      superclassConstraints
        Object
''');
  }

  test_mixin_cycle_interfaces() async {
    var library = await buildLibrary(r'''
mixin A implements B {}
mixin B implements A {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      mixins
        #F1 mixin A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@mixin::A
        #F2 mixin B (nameOffset:30) (firstTokenOffset:24) (offset:30)
          element: <testLibrary>::@mixin::B
  mixins
    mixin A
      reference: <testLibrary>::@mixin::A
      firstFragment: #F1
      superclassConstraints
        Object
    mixin B
      reference: <testLibrary>::@mixin::B
      firstFragment: #F2
      superclassConstraints
        Object
''');
  }

  test_mixin_cycle_superclassConstraints() async {
    var library = await buildLibrary(r'''
mixin A on B {}
mixin B on A {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      mixins
        #F1 mixin A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@mixin::A
        #F2 mixin B (nameOffset:22) (firstTokenOffset:16) (offset:22)
          element: <testLibrary>::@mixin::B
  mixins
    mixin A
      reference: <testLibrary>::@mixin::A
      firstFragment: #F1
      superclassConstraints
        Object
    mixin B
      reference: <testLibrary>::@mixin::B
      firstFragment: #F2
      superclassConstraints
        Object
''');
  }

  test_mixin_field_inferredType() async {
    var library = await buildLibrary('''
mixin M {
  var x = 0;
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      mixins
        #F1 mixin M (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@mixin::M
          fields
            #F2 hasInitializer x (nameOffset:16) (firstTokenOffset:16) (offset:16)
              element: <testLibrary>::@mixin::M::@field::x
          getters
            #F3 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@mixin::M::@getter::x
          setters
            #F4 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@mixin::M::@setter::x
              formalParameters
                #F5 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
                  element: <testLibrary>::@mixin::M::@setter::x::@formalParameter::value
  mixins
    hasNonFinalField mixin M
      reference: <testLibrary>::@mixin::M
      firstFragment: #F1
      superclassConstraints
        Object
      fields
        hasInitializer x
          reference: <testLibrary>::@mixin::M::@field::x
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@mixin::M::@getter::x
          setter: <testLibrary>::@mixin::M::@setter::x
      getters
        synthetic x
          reference: <testLibrary>::@mixin::M::@getter::x
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@mixin::M::@field::x
      setters
        synthetic x
          reference: <testLibrary>::@mixin::M::@setter::x
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F5
              type: int
          returnType: void
          variable: <testLibrary>::@mixin::M::@field::x
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
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      mixins
        #F1 mixin M (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@mixin::M
          fields
            #F2 hasInitializer x (nameOffset:18) (firstTokenOffset:18) (offset:18)
              element: <testLibrary>::@mixin::M::@field::x
          getters
            #F3 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:18)
              element: <testLibrary>::@mixin::M::@getter::x
  mixins
    mixin M
      reference: <testLibrary>::@mixin::M
      firstFragment: #F1
      superclassConstraints
        Object
      fields
        final hasInitializer x
          reference: <testLibrary>::@mixin::M::@field::x
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@mixin::M::@getter::x
      getters
        synthetic x
          reference: <testLibrary>::@mixin::M::@getter::x
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@mixin::M::@field::x
''');
  }

  test_mixin_first() async {
    var library = await buildLibrary(r'''
mixin M {}
''');

    // We intentionally ask `mixins` directly, to check that we can ask them
    // separately, without asking classes.
    var mixins = library.firstFragment.mixins;
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
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      mixins
        #F1 mixin M (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@mixin::M
          fields
            #F2 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@mixin::M::@field::foo
          getters
            #F3 foo (nameOffset:25) (firstTokenOffset:17) (offset:25)
              element: <testLibrary>::@mixin::M::@getter::foo
  mixins
    mixin M
      reference: <testLibrary>::@mixin::M
      firstFragment: #F1
      superclassConstraints
        Object
      fields
        synthetic foo
          reference: <testLibrary>::@mixin::M::@field::foo
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@mixin::M::@getter::foo
      getters
        foo
          reference: <testLibrary>::@mixin::M::@getter::foo
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@mixin::M::@field::foo
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
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      mixins
        #F1 mixin M (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@mixin::M
          fields
            #F2 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@mixin::M::@field::foo
          getters
            #F3 foo (nameOffset:25) (firstTokenOffset:17) (offset:25)
              element: <testLibrary>::@mixin::M::@getter::foo
  mixins
    mixin M
      reference: <testLibrary>::@mixin::M
      firstFragment: #F1
      superclassConstraints
        Object
      fields
        synthetic foo
          reference: <testLibrary>::@mixin::M::@field::foo
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@mixin::M::@getter::foo
      getters
        foo
          reference: <testLibrary>::@mixin::M::@getter::foo
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@mixin::M::@field::foo
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
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      mixins
        #F1 mixin M (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@mixin::M
          fields
            #F2 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@mixin::M::@field::foo
          getters
            #F3 foo (nameOffset:25) (firstTokenOffset:17) (offset:25)
              element: <testLibrary>::@mixin::M::@getter::foo
  mixins
    mixin M
      reference: <testLibrary>::@mixin::M
      firstFragment: #F1
      superclassConstraints
        Object
      fields
        synthetic foo
          reference: <testLibrary>::@mixin::M::@field::foo
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@mixin::M::@getter::foo
      getters
        foo
          reference: <testLibrary>::@mixin::M::@getter::foo
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@mixin::M::@field::foo
''');
  }

  test_mixin_implicitObjectSuperclassConstraint() async {
    var library = await buildLibrary(r'''
mixin M {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      mixins
        #F1 mixin M (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@mixin::M
  mixins
    mixin M
      reference: <testLibrary>::@mixin::M
      firstFragment: #F1
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
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::A
          typeParameters
            #F2 T (nameOffset:8) (firstTokenOffset:8) (offset:8)
              element: #E0 T
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
        #F4 class B (nameOffset:42) (firstTokenOffset:36) (offset:42)
          element: <testLibrary>::@class::B
          constructors
            #F5 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:42)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
      mixins
        #F6 mixin M (nameOffset:20) (firstTokenOffset:14) (offset:20)
          element: <testLibrary>::@mixin::M
          typeParameters
            #F7 U (nameOffset:22) (firstTokenOffset:22) (offset:22)
              element: #E1 U
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
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F4
      supertype: A<int>
      mixins
        M<int>
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F5
          superConstructor: ConstructorMember
            baseElement: <testLibrary>::@class::A::@constructor::new
            substitution: {T: int}
  mixins
    mixin M
      reference: <testLibrary>::@mixin::M
      firstFragment: #F6
      typeParameters
        #E1 U
          firstFragment: #F7
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
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::A
          typeParameters
            #F2 T (nameOffset:8) (firstTokenOffset:8) (offset:8)
              element: #E0 T
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
        #F4 class B (nameOffset:20) (firstTokenOffset:14) (offset:20)
          element: <testLibrary>::@class::B
          typeParameters
            #F5 T (nameOffset:22) (firstTokenOffset:22) (offset:22)
              element: #E1 T
          constructors
            #F6 synthetic const new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:20)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
        #F7 class C (nameOffset:51) (firstTokenOffset:45) (offset:51)
          element: <testLibrary>::@class::C
          constructors
            #F8 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:51)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
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
    class alias B
      reference: <testLibrary>::@class::B
      firstFragment: #F4
      typeParameters
        #E1 T
          firstFragment: #F5
      supertype: Object
      mixins
        A<T>
      constructors
        synthetic const new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F6
          constantInitializers
            SuperConstructorInvocation
              superKeyword: super @0
              argumentList: ArgumentList
                leftParenthesis: ( @0
                rightParenthesis: ) @0
              element: dart:core::@class::Object::@constructor::new
    class alias C
      reference: <testLibrary>::@class::C
      firstFragment: #F7
      supertype: A<int>
      mixins
        B<dynamic>
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F8
          constantInitializers
            SuperConstructorInvocation
              superKeyword: super @0
              argumentList: ArgumentList
                leftParenthesis: ( @0
                rightParenthesis: ) @0
              element: <testLibrary>::@class::A::@constructor::new
          superConstructor: ConstructorMember
            baseElement: <testLibrary>::@class::A::@constructor::new
            substitution: {T: int}
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
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A1 (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::A1
          typeParameters
            #F2 T (nameOffset:9) (firstTokenOffset:9) (offset:9)
              element: #E0 T
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A1::@constructor::new
              typeName: A1
        #F4 class A2 (nameOffset:21) (firstTokenOffset:15) (offset:21)
          element: <testLibrary>::@class::A2
          typeParameters
            #F5 T (nameOffset:24) (firstTokenOffset:24) (offset:24)
              element: #E1 T
          constructors
            #F6 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@class::A2::@constructor::new
              typeName: A2
        #F7 class B (nameOffset:36) (firstTokenOffset:30) (offset:36)
          element: <testLibrary>::@class::B
          typeParameters
            #F8 T (nameOffset:38) (firstTokenOffset:38) (offset:38)
              element: #E2 T
          constructors
            #F9 synthetic const new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:36)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
        #F10 class Base (nameOffset:75) (firstTokenOffset:69) (offset:75)
          element: <testLibrary>::@class::Base
          constructors
            #F11 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:75)
              element: <testLibrary>::@class::Base::@constructor::new
              typeName: Base
        #F12 class C (nameOffset:108) (firstTokenOffset:102) (offset:108)
          element: <testLibrary>::@class::C
          constructors
            #F13 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:108)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
  classes
    class A1
      reference: <testLibrary>::@class::A1
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      constructors
        synthetic new
          reference: <testLibrary>::@class::A1::@constructor::new
          firstFragment: #F3
    class A2
      reference: <testLibrary>::@class::A2
      firstFragment: #F4
      typeParameters
        #E1 T
          firstFragment: #F5
      constructors
        synthetic new
          reference: <testLibrary>::@class::A2::@constructor::new
          firstFragment: #F6
    class alias B
      reference: <testLibrary>::@class::B
      firstFragment: #F7
      typeParameters
        #E2 T
          firstFragment: #F8
      supertype: Object
      mixins
        A1<T>
        A2<T>
      constructors
        synthetic const new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F9
          constantInitializers
            SuperConstructorInvocation
              superKeyword: super @0
              argumentList: ArgumentList
                leftParenthesis: ( @0
                rightParenthesis: ) @0
              element: dart:core::@class::Object::@constructor::new
    class Base
      reference: <testLibrary>::@class::Base
      firstFragment: #F10
      interfaces
        A1<int>
      constructors
        synthetic new
          reference: <testLibrary>::@class::Base::@constructor::new
          firstFragment: #F11
    class alias C
      reference: <testLibrary>::@class::C
      firstFragment: #F12
      supertype: Base
      mixins
        B<int>
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F13
          constantInitializers
            SuperConstructorInvocation
              superKeyword: super @0
              argumentList: ArgumentList
                leftParenthesis: ( @0
                rightParenthesis: ) @0
              element: <testLibrary>::@class::Base::@constructor::new
          superConstructor: <testLibrary>::@class::Base::@constructor::new
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
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::A
          typeParameters
            #F2 T (nameOffset:8) (firstTokenOffset:8) (offset:8)
              element: #E0 T
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
        #F4 class C (nameOffset:57) (firstTokenOffset:51) (offset:57)
          element: <testLibrary>::@class::C
          constructors
            #F5 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:57)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
      mixins
        #F6 mixin M (nameOffset:20) (firstTokenOffset:14) (offset:20)
          element: <testLibrary>::@mixin::M
          typeParameters
            #F7 T (nameOffset:22) (firstTokenOffset:22) (offset:22)
              element: #E1 T
            #F8 U (nameOffset:25) (firstTokenOffset:25) (offset:25)
              element: #E2 U
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
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F4
      supertype: A<int Function(String)>
      mixins
        M<int, String>
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F5
          superConstructor: ConstructorMember
            baseElement: <testLibrary>::@class::A::@constructor::new
            substitution: {T: int Function(String)}
  mixins
    mixin M
      reference: <testLibrary>::@mixin::M
      firstFragment: #F6
      typeParameters
        #E1 T
          firstFragment: #F7
        #E2 U
          firstFragment: #F8
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
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@class::A
          typeParameters
            #F2 T (nameOffset:17) (firstTokenOffset:17) (offset:17)
              element: #E0 T
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
        #F4 class C (nameOffset:57) (firstTokenOffset:51) (offset:57)
          element: <testLibrary>::@class::C
          constructors
            #F5 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:57)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
      mixins
        #F6 mixin M (nameOffset:29) (firstTokenOffset:23) (offset:29)
          element: <testLibrary>::@mixin::M
          typeParameters
            #F7 T (nameOffset:31) (firstTokenOffset:31) (offset:31)
              element: #E1 T
  classes
    abstract class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F4
      supertype: A<List<int>>
      mixins
        M<int>
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F5
          superConstructor: ConstructorMember
            baseElement: <testLibrary>::@class::A::@constructor::new
            substitution: {T: List<int>}
  mixins
    mixin M
      reference: <testLibrary>::@mixin::M
      firstFragment: #F6
      typeParameters
        #E1 T
          firstFragment: #F7
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
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class I (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::I
          typeParameters
            #F2 X (nameOffset:8) (firstTokenOffset:8) (offset:8)
              element: #E0 X
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::I::@constructor::new
              typeName: I
        #F4 class A (nameOffset:66) (firstTokenOffset:60) (offset:66)
          element: <testLibrary>::@class::A
          constructors
            #F5 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:66)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
      mixins
        #F6 mixin M1 (nameOffset:20) (firstTokenOffset:14) (offset:20)
          element: <testLibrary>::@mixin::M1
          typeParameters
            #F7 T (nameOffset:23) (firstTokenOffset:23) (offset:23)
              element: #E1 T
        #F8 mixin M2 (nameOffset:43) (firstTokenOffset:37) (offset:43)
          element: <testLibrary>::@mixin::M2
          typeParameters
            #F9 T (nameOffset:46) (firstTokenOffset:46) (offset:46)
              element: #E2 T
  classes
    class I
      reference: <testLibrary>::@class::I
      firstFragment: #F1
      typeParameters
        #E0 X
          firstFragment: #F2
      constructors
        synthetic new
          reference: <testLibrary>::@class::I::@constructor::new
          firstFragment: #F3
    class alias A
      reference: <testLibrary>::@class::A
      firstFragment: #F4
      supertype: I<int>
      mixins
        M1<int>
        M2<int>
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F5
          constantInitializers
            SuperConstructorInvocation
              superKeyword: super @0
              argumentList: ArgumentList
                leftParenthesis: ( @0
                rightParenthesis: ) @0
              element: <testLibrary>::@class::I::@constructor::new
          superConstructor: ConstructorMember
            baseElement: <testLibrary>::@class::I::@constructor::new
            substitution: {X: int}
  mixins
    mixin M1
      reference: <testLibrary>::@mixin::M1
      firstFragment: #F6
      typeParameters
        #E1 T
          firstFragment: #F7
      superclassConstraints
        I<T>
    mixin M2
      reference: <testLibrary>::@mixin::M2
      firstFragment: #F8
      typeParameters
        #E2 T
          firstFragment: #F9
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
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class S (nameOffset:62) (firstTokenOffset:56) (offset:62)
          element: <testLibrary>::@class::S
          typeParameters
            #F2 T3 (nameOffset:64) (firstTokenOffset:64) (offset:64)
              element: #E0 T3
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:62)
              element: <testLibrary>::@class::S::@constructor::new
              typeName: S
        #F4 class X (nameOffset:78) (firstTokenOffset:72) (offset:78)
          element: <testLibrary>::@class::X
          constructors
            #F5 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:78)
              element: <testLibrary>::@class::X::@constructor::new
              typeName: X
      mixins
        #F6 mixin M (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@mixin::M
          typeParameters
            #F7 T (nameOffset:8) (firstTokenOffset:8) (offset:8)
              element: #E1 T
            #F8 U (nameOffset:11) (firstTokenOffset:11) (offset:11)
              element: #E2 U
      typeAliases
        #F9 M2 (nameOffset:34) (firstTokenOffset:26) (offset:34)
          element: <testLibrary>::@typeAlias::M2
          typeParameters
            #F10 T2 (nameOffset:37) (firstTokenOffset:37) (offset:37)
              element: #E3 T2
  classes
    class S
      reference: <testLibrary>::@class::S
      firstFragment: #F1
      typeParameters
        #E0 T3
          firstFragment: #F2
      constructors
        synthetic new
          reference: <testLibrary>::@class::S::@constructor::new
          firstFragment: #F3
    class X
      reference: <testLibrary>::@class::X
      firstFragment: #F4
      supertype: S<String>
      mixins
        M<String, int>
          alias: <testLibrary>::@typeAlias::M2
            typeArguments
              String
      constructors
        synthetic new
          reference: <testLibrary>::@class::X::@constructor::new
          firstFragment: #F5
          superConstructor: ConstructorMember
            baseElement: <testLibrary>::@class::S::@constructor::new
            substitution: {T3: String}
  mixins
    mixin M
      reference: <testLibrary>::@mixin::M
      firstFragment: #F6
      typeParameters
        #E1 T
          firstFragment: #F7
        #E2 U
          firstFragment: #F8
      superclassConstraints
        S<T>
  typeAliases
    M2
      reference: <testLibrary>::@typeAlias::M2
      firstFragment: #F9
      typeParameters
        #E3 T2
          firstFragment: #F10
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
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class S (nameOffset:88) (firstTokenOffset:82) (offset:88)
          element: <testLibrary>::@class::S
          typeParameters
            #F2 T4 (nameOffset:90) (firstTokenOffset:90) (offset:90)
              element: #E0 T4
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:88)
              element: <testLibrary>::@class::S::@constructor::new
              typeName: S
        #F4 class X (nameOffset:104) (firstTokenOffset:98) (offset:104)
          element: <testLibrary>::@class::X
          constructors
            #F5 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:104)
              element: <testLibrary>::@class::X::@constructor::new
              typeName: X
      mixins
        #F6 mixin M (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@mixin::M
          typeParameters
            #F7 T (nameOffset:8) (firstTokenOffset:8) (offset:8)
              element: #E1 T
            #F8 U (nameOffset:11) (firstTokenOffset:11) (offset:11)
              element: #E2 U
      typeAliases
        #F9 M2 (nameOffset:34) (firstTokenOffset:26) (offset:34)
          element: <testLibrary>::@typeAlias::M2
          typeParameters
            #F10 T2 (nameOffset:37) (firstTokenOffset:37) (offset:37)
              element: #E3 T2
        #F11 M3 (nameOffset:64) (firstTokenOffset:56) (offset:64)
          element: <testLibrary>::@typeAlias::M3
          typeParameters
            #F12 T3 (nameOffset:67) (firstTokenOffset:67) (offset:67)
              element: #E4 T3
  classes
    class S
      reference: <testLibrary>::@class::S
      firstFragment: #F1
      typeParameters
        #E0 T4
          firstFragment: #F2
      constructors
        synthetic new
          reference: <testLibrary>::@class::S::@constructor::new
          firstFragment: #F3
    class X
      reference: <testLibrary>::@class::X
      firstFragment: #F4
      supertype: S<String>
      mixins
        M<String, int>
          alias: <testLibrary>::@typeAlias::M3
            typeArguments
              String
      constructors
        synthetic new
          reference: <testLibrary>::@class::X::@constructor::new
          firstFragment: #F5
          superConstructor: ConstructorMember
            baseElement: <testLibrary>::@class::S::@constructor::new
            substitution: {T4: String}
  mixins
    mixin M
      reference: <testLibrary>::@mixin::M
      firstFragment: #F6
      typeParameters
        #E1 T
          firstFragment: #F7
        #E2 U
          firstFragment: #F8
      superclassConstraints
        S<T>
  typeAliases
    M2
      reference: <testLibrary>::@typeAlias::M2
      firstFragment: #F9
      typeParameters
        #E3 T2
          firstFragment: #F10
      aliasedType: M<T2, int>
    M3
      reference: <testLibrary>::@typeAlias::M3
      firstFragment: #F11
      typeParameters
        #E4 T3
          firstFragment: #F12
      aliasedType: M<T3, int>
        alias: <testLibrary>::@typeAlias::M2
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
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::A
        #F2 class C (nameOffset:45) (firstTokenOffset:39) (offset:45)
          element: <testLibrary>::@class::C
      extensionTypes
        #F3 extension type B (nameOffset:26) (firstTokenOffset:11) (offset:26)
          element: <testLibrary>::@extensionType::B
          fields
            #F4 it (nameOffset:32) (firstTokenOffset:27) (offset:32)
              element: <testLibrary>::@extensionType::B::@field::it
          getters
            #F5 synthetic it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:32)
              element: <testLibrary>::@extensionType::B::@getter::it
      mixins
        #F6 mixin M (nameOffset:56) (firstTokenOffset:50) (offset:56)
          element: <testLibrary>::@mixin::M
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F2
  extensionTypes
    extension type B
      reference: <testLibrary>::@extensionType::B
      firstFragment: #F3
      representation: <testLibrary>::@extensionType::B::@field::it
      primaryConstructor: <testLibrary>::@extensionType::B::@constructor::new
      typeErasure: int
      fields
        final it
          reference: <testLibrary>::@extensionType::B::@field::it
          firstFragment: #F4
          type: int
          getter: <testLibrary>::@extensionType::B::@getter::it
      getters
        synthetic isExtensionTypeMember it
          reference: <testLibrary>::@extensionType::B::@getter::it
          firstFragment: #F5
          returnType: int
          variable: <testLibrary>::@extensionType::B::@field::it
  mixins
    mixin M
      reference: <testLibrary>::@mixin::M
      firstFragment: #F6
      superclassConstraints
        Object
      interfaces
        A
        C
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
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      mixins
        #F1 mixin M (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@mixin::M
          methods
            #F2 foo (nameOffset:22) (firstTokenOffset:17) (offset:22) invokesSuperSelf
              element: <testLibrary>::@mixin::M::@method::foo
  mixins
    mixin M
      reference: <testLibrary>::@mixin::M
      firstFragment: #F1
      superclassConstraints
        Object
      methods
        foo
          reference: <testLibrary>::@mixin::M::@method::foo
          firstFragment: #F2
          returnType: void
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
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::A
          constructors
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
      mixins
        #F3 mixin B (nameOffset:17) (firstTokenOffset:11) (offset:17)
          element: <testLibrary>::@mixin::B
          methods
            #F4 A (nameOffset:33) (firstTokenOffset:28) (offset:33)
              element: <testLibrary>::@mixin::B::@method::A
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
  mixins
    mixin B
      reference: <testLibrary>::@mixin::B
      firstFragment: #F3
      superclassConstraints
        A
      methods
        A
          reference: <testLibrary>::@mixin::B::@method::A
          firstFragment: #F4
          returnType: void
''');
  }

  test_mixin_method_ofGeneric_refEnclosingTypeParameter_false() async {
    var library = await buildLibrary('''
mixin M<T> {
  void foo() {}
}
''');
    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      mixins
        #F1 mixin M (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@mixin::M
          typeParameters
            #F2 T (nameOffset:8) (firstTokenOffset:8) (offset:8)
              element: #E0 T
          methods
            #F3 foo (nameOffset:20) (firstTokenOffset:15) (offset:20)
              element: <testLibrary>::@mixin::M::@method::foo
  mixins
    mixin M
      reference: <testLibrary>::@mixin::M
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      superclassConstraints
        Object
      methods
        foo
          reference: <testLibrary>::@mixin::M::@method::foo
          firstFragment: #F3
          returnType: void
''');
  }

  test_mixin_method_ofGeneric_refEnclosingTypeParameter_true() async {
    var library = await buildLibrary('''
mixin M<T> {
  void foo(T _) {}
}
''');
    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      mixins
        #F1 mixin M (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@mixin::M
          typeParameters
            #F2 T (nameOffset:8) (firstTokenOffset:8) (offset:8)
              element: #E0 T
          methods
            #F3 foo (nameOffset:20) (firstTokenOffset:15) (offset:20)
              element: <testLibrary>::@mixin::M::@method::foo
              formalParameters
                #F4 _ (nameOffset:26) (firstTokenOffset:24) (offset:26)
                  element: <testLibrary>::@mixin::M::@method::foo::@formalParameter::_
  mixins
    mixin M
      reference: <testLibrary>::@mixin::M
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      superclassConstraints
        Object
      methods
        foo
          reference: <testLibrary>::@mixin::M::@method::foo
          firstFragment: #F3
          hasEnclosingTypeParameterReference: true
          formalParameters
            #E1 requiredPositional _
              firstFragment: #F4
              type: T
          returnType: void
''');
  }

  test_mixin_missingName() async {
    var library = await buildLibrary(r'''
mixin {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      mixins
        #F1 mixin <null-name> (nameOffset:<null>) (firstTokenOffset:0) (offset:0)
          element: <testLibrary>::@mixin::0
  mixins
    mixin <null-name>
      reference: <testLibrary>::@mixin::0
      firstFragment: #F1
      superclassConstraints
        Object
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
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      mixins
        #F1 mixin M (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@mixin::M
          fields
            #F2 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@mixin::M::@field::foo
          setters
            #F3 foo (nameOffset:21) (firstTokenOffset:17) (offset:21)
              element: <testLibrary>::@mixin::M::@setter::foo
              formalParameters
                #F4 _ (nameOffset:29) (firstTokenOffset:25) (offset:29)
                  element: <testLibrary>::@mixin::M::@setter::foo::@formalParameter::_
  mixins
    mixin M
      reference: <testLibrary>::@mixin::M
      firstFragment: #F1
      superclassConstraints
        Object
      fields
        synthetic foo
          reference: <testLibrary>::@mixin::M::@field::foo
          firstFragment: #F2
          type: int
          setter: <testLibrary>::@mixin::M::@setter::foo
      setters
        foo
          reference: <testLibrary>::@mixin::M::@setter::foo
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional _
              firstFragment: #F4
              type: int
          returnType: void
          variable: <testLibrary>::@mixin::M::@field::foo
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
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      mixins
        #F1 mixin M (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@mixin::M
          fields
            #F2 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@mixin::M::@field::foo
          setters
            #F3 foo (nameOffset:21) (firstTokenOffset:17) (offset:21)
              element: <testLibrary>::@mixin::M::@setter::foo
              formalParameters
                #F4 _ (nameOffset:29) (firstTokenOffset:25) (offset:29)
                  element: <testLibrary>::@mixin::M::@setter::foo::@formalParameter::_
  mixins
    mixin M
      reference: <testLibrary>::@mixin::M
      firstFragment: #F1
      superclassConstraints
        Object
      fields
        synthetic foo
          reference: <testLibrary>::@mixin::M::@field::foo
          firstFragment: #F2
          type: int
          setter: <testLibrary>::@mixin::M::@setter::foo
      setters
        foo
          reference: <testLibrary>::@mixin::M::@setter::foo
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional _
              firstFragment: #F4
              type: int
          returnType: void
          variable: <testLibrary>::@mixin::M::@field::foo
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
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::A
        #F2 class C (nameOffset:45) (firstTokenOffset:39) (offset:45)
          element: <testLibrary>::@class::C
      extensionTypes
        #F3 extension type B (nameOffset:26) (firstTokenOffset:11) (offset:26)
          element: <testLibrary>::@extensionType::B
          fields
            #F4 it (nameOffset:32) (firstTokenOffset:27) (offset:32)
              element: <testLibrary>::@extensionType::B::@field::it
          getters
            #F5 synthetic it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:32)
              element: <testLibrary>::@extensionType::B::@getter::it
      mixins
        #F6 mixin M (nameOffset:56) (firstTokenOffset:50) (offset:56)
          element: <testLibrary>::@mixin::M
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F2
  extensionTypes
    extension type B
      reference: <testLibrary>::@extensionType::B
      firstFragment: #F3
      representation: <testLibrary>::@extensionType::B::@field::it
      primaryConstructor: <testLibrary>::@extensionType::B::@constructor::new
      typeErasure: int
      fields
        final it
          reference: <testLibrary>::@extensionType::B::@field::it
          firstFragment: #F4
          type: int
          getter: <testLibrary>::@extensionType::B::@getter::it
      getters
        synthetic isExtensionTypeMember it
          reference: <testLibrary>::@extensionType::B::@getter::it
          firstFragment: #F5
          returnType: int
          variable: <testLibrary>::@extensionType::B::@field::it
  mixins
    mixin M
      reference: <testLibrary>::@mixin::M
      firstFragment: #F6
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
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      mixins
        #F1 mixin M (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@mixin::M
          typeParameters
            #F2 T (nameOffset:11) (firstTokenOffset:8) (offset:11)
              element: #E0 T
  mixins
    mixin M
      reference: <testLibrary>::@mixin::M
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      superclassConstraints
        Object
''');
  }

  test_mixin_typeParameters_variance_covariant() async {
    var library = await buildLibrary('mixin M<out T> {}');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      mixins
        #F1 mixin M (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@mixin::M
          typeParameters
            #F2 T (nameOffset:12) (firstTokenOffset:8) (offset:12)
              element: #E0 T
  mixins
    mixin M
      reference: <testLibrary>::@mixin::M
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      superclassConstraints
        Object
''');
  }

  test_mixin_typeParameters_variance_invariant() async {
    var library = await buildLibrary('mixin M<inout T> {}');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      mixins
        #F1 mixin M (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@mixin::M
          typeParameters
            #F2 T (nameOffset:14) (firstTokenOffset:8) (offset:14)
              element: #E0 T
  mixins
    mixin M
      reference: <testLibrary>::@mixin::M
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      superclassConstraints
        Object
''');
  }

  test_mixin_typeParameters_variance_multiple() async {
    var library = await buildLibrary('mixin M<inout T, in U, out V> {}');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      mixins
        #F1 mixin M (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@mixin::M
          typeParameters
            #F2 T (nameOffset:14) (firstTokenOffset:8) (offset:14)
              element: #E0 T
            #F3 U (nameOffset:20) (firstTokenOffset:17) (offset:20)
              element: #E1 U
            #F4 V (nameOffset:27) (firstTokenOffset:23) (offset:27)
              element: #E2 V
  mixins
    mixin M
      reference: <testLibrary>::@mixin::M
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
        #E1 U
          firstFragment: #F3
        #E2 V
          firstFragment: #F4
      superclassConstraints
        Object
''');
  }
}

abstract class MixinElementTest_augmentation extends ElementsBaseTest {
  test_augmentationTarget() async {
    var library = await buildLibrary(r'''
mixin A {}

augment mixin A {}
augment mixin A {}
''');

    configuration.withExportScope = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      mixins
        #F1 mixin A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@mixin::A
          nextFragment: #F2
        #F2 mixin A (nameOffset:26) (firstTokenOffset:12) (offset:26)
          element: <testLibrary>::@mixin::A
          previousFragment: #F1
          nextFragment: #F3
        #F3 mixin A (nameOffset:45) (firstTokenOffset:31) (offset:45)
          element: <testLibrary>::@mixin::A
          previousFragment: #F2
  mixins
    mixin A
      reference: <testLibrary>::@mixin::A
      firstFragment: #F1
      superclassConstraints
        Object
  exportedReferences
    declared <testLibrary>::@mixin::A
  exportNamespace
    A: <testLibrary>::@mixin::A
''');
  }

  test_augmentationTarget_augmentationThenDeclaration() async {
    var library = await buildLibrary(r'''
augment mixin A {
  void foo1() {}
}

mixin A {
  void foo2() {}
}

augment mixin A {
  void foo3() {}
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      mixins
        #F1 mixin A (nameOffset:14) (firstTokenOffset:0) (offset:14)
          element: <testLibrary>::@mixin::A::@def::0
          methods
            #F2 foo1 (nameOffset:25) (firstTokenOffset:20) (offset:25)
              element: <testLibrary>::@mixin::A::@def::0::@method::foo1
        #F3 mixin A (nameOffset:44) (firstTokenOffset:38) (offset:44)
          element: <testLibrary>::@mixin::A::@def::1
          nextFragment: #F4
          methods
            #F5 foo2 (nameOffset:55) (firstTokenOffset:50) (offset:55)
              element: <testLibrary>::@mixin::A::@def::1::@method::foo2
        #F4 mixin A (nameOffset:82) (firstTokenOffset:68) (offset:82)
          element: <testLibrary>::@mixin::A::@def::1
          previousFragment: #F3
          methods
            #F6 foo3 (nameOffset:93) (firstTokenOffset:88) (offset:93)
              element: <testLibrary>::@mixin::A::@def::1::@method::foo3
  mixins
    mixin A
      reference: <testLibrary>::@mixin::A::@def::0
      firstFragment: #F1
      superclassConstraints
        Object
      methods
        foo1
          reference: <testLibrary>::@mixin::A::@def::0::@method::foo1
          firstFragment: #F2
          returnType: void
    mixin A
      reference: <testLibrary>::@mixin::A::@def::1
      firstFragment: #F3
      superclassConstraints
        Object
      methods
        foo2
          reference: <testLibrary>::@mixin::A::@def::1::@method::foo2
          firstFragment: #F5
          returnType: void
        foo3
          reference: <testLibrary>::@mixin::A::@def::1::@method::foo3
          firstFragment: #F6
          returnType: void
''');
  }

  test_augmentationTarget_no2() async {
    var library = await buildLibrary(r'''
mixin B {}

augment mixin A {
  void foo1() {}
}

augment mixin A {
  void foo2() {}
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      mixins
        #F1 mixin B (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@mixin::B
        #F2 mixin A (nameOffset:26) (firstTokenOffset:12) (offset:26)
          element: <testLibrary>::@mixin::A
          nextFragment: #F3
          methods
            #F4 foo1 (nameOffset:37) (firstTokenOffset:32) (offset:37)
              element: <testLibrary>::@mixin::A::@method::foo1
        #F3 mixin A (nameOffset:64) (firstTokenOffset:50) (offset:64)
          element: <testLibrary>::@mixin::A
          previousFragment: #F2
          methods
            #F5 foo2 (nameOffset:75) (firstTokenOffset:70) (offset:75)
              element: <testLibrary>::@mixin::A::@method::foo2
  mixins
    mixin B
      reference: <testLibrary>::@mixin::B
      firstFragment: #F1
      superclassConstraints
        Object
    mixin A
      reference: <testLibrary>::@mixin::A
      firstFragment: #F2
      superclassConstraints
        Object
      methods
        foo1
          reference: <testLibrary>::@mixin::A::@method::foo1
          firstFragment: #F4
          returnType: void
        foo2
          reference: <testLibrary>::@mixin::A::@method::foo2
          firstFragment: #F5
          returnType: void
''');
  }

  test_augmented_field_augment_field() async {
    var library = await buildLibrary(r'''
mixin A {
  int foo = 0;
}

augment mixin A {
  augment int foo = 1;
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      mixins
        #F1 mixin A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@mixin::A
          nextFragment: #F2
          fields
            #F3 hasInitializer foo (nameOffset:16) (firstTokenOffset:16) (offset:16)
              element: <testLibrary>::@mixin::A::@field::foo
              nextFragment: #F4
          getters
            #F5 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@mixin::A::@getter::foo
          setters
            #F6 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@mixin::A::@setter::foo
              formalParameters
                #F7 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
                  element: <testLibrary>::@mixin::A::@setter::foo::@formalParameter::value
        #F2 mixin A (nameOffset:42) (firstTokenOffset:28) (offset:42)
          element: <testLibrary>::@mixin::A
          previousFragment: #F1
          fields
            #F4 augment hasInitializer foo (nameOffset:60) (firstTokenOffset:60) (offset:60)
              element: <testLibrary>::@mixin::A::@field::foo
              previousFragment: #F3
  mixins
    hasNonFinalField mixin A
      reference: <testLibrary>::@mixin::A
      firstFragment: #F1
      superclassConstraints
        Object
      fields
        hasInitializer foo
          reference: <testLibrary>::@mixin::A::@field::foo
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@mixin::A::@getter::foo
          setter: <testLibrary>::@mixin::A::@setter::foo
      getters
        synthetic foo
          reference: <testLibrary>::@mixin::A::@getter::foo
          firstFragment: #F5
          returnType: int
          variable: <testLibrary>::@mixin::A::@field::foo
      setters
        synthetic foo
          reference: <testLibrary>::@mixin::A::@setter::foo
          firstFragment: #F6
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F7
              type: int
          returnType: void
          variable: <testLibrary>::@mixin::A::@field::foo
''');
  }

  test_augmented_field_augment_field2() async {
    var library = await buildLibrary(r'''
mixin A {
  int foo = 0;
}

augment mixin A {
  augment int foo = 1;
}

augment mixin A {
  augment int foo = 2;
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      mixins
        #F1 mixin A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@mixin::A
          nextFragment: #F2
          fields
            #F3 hasInitializer foo (nameOffset:16) (firstTokenOffset:16) (offset:16)
              element: <testLibrary>::@mixin::A::@field::foo
              nextFragment: #F4
          getters
            #F5 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@mixin::A::@getter::foo
          setters
            #F6 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@mixin::A::@setter::foo
              formalParameters
                #F7 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
                  element: <testLibrary>::@mixin::A::@setter::foo::@formalParameter::value
        #F2 mixin A (nameOffset:42) (firstTokenOffset:28) (offset:42)
          element: <testLibrary>::@mixin::A
          previousFragment: #F1
          nextFragment: #F8
          fields
            #F4 augment hasInitializer foo (nameOffset:60) (firstTokenOffset:60) (offset:60)
              element: <testLibrary>::@mixin::A::@field::foo
              previousFragment: #F3
              nextFragment: #F9
        #F8 mixin A (nameOffset:86) (firstTokenOffset:72) (offset:86)
          element: <testLibrary>::@mixin::A
          previousFragment: #F2
          fields
            #F9 augment hasInitializer foo (nameOffset:104) (firstTokenOffset:104) (offset:104)
              element: <testLibrary>::@mixin::A::@field::foo
              previousFragment: #F4
  mixins
    hasNonFinalField mixin A
      reference: <testLibrary>::@mixin::A
      firstFragment: #F1
      superclassConstraints
        Object
      fields
        hasInitializer foo
          reference: <testLibrary>::@mixin::A::@field::foo
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@mixin::A::@getter::foo
          setter: <testLibrary>::@mixin::A::@setter::foo
      getters
        synthetic foo
          reference: <testLibrary>::@mixin::A::@getter::foo
          firstFragment: #F5
          returnType: int
          variable: <testLibrary>::@mixin::A::@field::foo
      setters
        synthetic foo
          reference: <testLibrary>::@mixin::A::@setter::foo
          firstFragment: #F6
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F7
              type: int
          returnType: void
          variable: <testLibrary>::@mixin::A::@field::foo
''');
  }

  test_augmented_field_augment_field_afterGetter() async {
    var library = await buildLibrary(r'''
mixin A {
  int foo = 0;
}

augment mixin A {
  augment int get foo => 1;
}

augment mixin A {
  augment int foo = 2;
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      mixins
        #F1 mixin A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@mixin::A
          nextFragment: #F2
          fields
            #F3 hasInitializer foo (nameOffset:16) (firstTokenOffset:16) (offset:16)
              element: <testLibrary>::@mixin::A::@field::foo
              nextFragment: #F4
          getters
            #F5 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@mixin::A::@getter::foo
              nextFragment: #F6
          setters
            #F7 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@mixin::A::@setter::foo
              formalParameters
                #F8 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
                  element: <testLibrary>::@mixin::A::@setter::foo::@formalParameter::value
        #F2 mixin A (nameOffset:42) (firstTokenOffset:28) (offset:42)
          element: <testLibrary>::@mixin::A
          previousFragment: #F1
          nextFragment: #F9
          getters
            #F6 augment foo (nameOffset:64) (firstTokenOffset:48) (offset:64)
              element: <testLibrary>::@mixin::A::@getter::foo
              previousFragment: #F5
        #F9 mixin A (nameOffset:91) (firstTokenOffset:77) (offset:91)
          element: <testLibrary>::@mixin::A
          previousFragment: #F2
          fields
            #F4 augment hasInitializer foo (nameOffset:109) (firstTokenOffset:109) (offset:109)
              element: <testLibrary>::@mixin::A::@field::foo
              previousFragment: #F3
  mixins
    hasNonFinalField mixin A
      reference: <testLibrary>::@mixin::A
      firstFragment: #F1
      superclassConstraints
        Object
      fields
        hasInitializer foo
          reference: <testLibrary>::@mixin::A::@field::foo
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@mixin::A::@getter::foo
          setter: <testLibrary>::@mixin::A::@setter::foo
      getters
        synthetic foo
          reference: <testLibrary>::@mixin::A::@getter::foo
          firstFragment: #F5
          returnType: int
          variable: <testLibrary>::@mixin::A::@field::foo
      setters
        synthetic foo
          reference: <testLibrary>::@mixin::A::@setter::foo
          firstFragment: #F7
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F8
              type: int
          returnType: void
          variable: <testLibrary>::@mixin::A::@field::foo
''');
  }

  test_augmented_field_augment_field_afterSetter() async {
    var library = await buildLibrary(r'''
mixin A {
  int foo = 0;
}

augment mixin A {
  augment set foo(int _) {}
}

augment mixin A {
  augment int foo = 2;
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      mixins
        #F1 mixin A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@mixin::A
          nextFragment: #F2
          fields
            #F3 hasInitializer foo (nameOffset:16) (firstTokenOffset:16) (offset:16)
              element: <testLibrary>::@mixin::A::@field::foo
              nextFragment: #F4
          getters
            #F5 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@mixin::A::@getter::foo
          setters
            #F6 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@mixin::A::@setter::foo
              formalParameters
                #F7 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
                  element: <testLibrary>::@mixin::A::@setter::foo::@formalParameter::value
              nextFragment: #F8
        #F2 mixin A (nameOffset:42) (firstTokenOffset:28) (offset:42)
          element: <testLibrary>::@mixin::A
          previousFragment: #F1
          nextFragment: #F9
          setters
            #F8 augment foo (nameOffset:60) (firstTokenOffset:48) (offset:60)
              element: <testLibrary>::@mixin::A::@setter::foo
              formalParameters
                #F10 _ (nameOffset:68) (firstTokenOffset:64) (offset:68)
                  element: <testLibrary>::@mixin::A::@setter::foo::@formalParameter::_
              previousFragment: #F6
        #F9 mixin A (nameOffset:91) (firstTokenOffset:77) (offset:91)
          element: <testLibrary>::@mixin::A
          previousFragment: #F2
          fields
            #F4 augment hasInitializer foo (nameOffset:109) (firstTokenOffset:109) (offset:109)
              element: <testLibrary>::@mixin::A::@field::foo
              previousFragment: #F3
  mixins
    hasNonFinalField mixin A
      reference: <testLibrary>::@mixin::A
      firstFragment: #F1
      superclassConstraints
        Object
      fields
        hasInitializer foo
          reference: <testLibrary>::@mixin::A::@field::foo
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@mixin::A::@getter::foo
          setter: <testLibrary>::@mixin::A::@setter::foo
      getters
        synthetic foo
          reference: <testLibrary>::@mixin::A::@getter::foo
          firstFragment: #F5
          returnType: int
          variable: <testLibrary>::@mixin::A::@field::foo
      setters
        synthetic foo
          reference: <testLibrary>::@mixin::A::@setter::foo
          firstFragment: #F6
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F7
              type: int
          returnType: void
          variable: <testLibrary>::@mixin::A::@field::foo
''');
  }

  test_augmented_field_augment_field_differentTypes() async {
    var library = await buildLibrary(r'''
mixin A {
  int foo = 0;
}

augment mixin A {
  augment double foo = 1.2;
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      mixins
        #F1 mixin A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@mixin::A
          nextFragment: #F2
          fields
            #F3 hasInitializer foo (nameOffset:16) (firstTokenOffset:16) (offset:16)
              element: <testLibrary>::@mixin::A::@field::foo
              nextFragment: #F4
          getters
            #F5 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@mixin::A::@getter::foo
          setters
            #F6 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@mixin::A::@setter::foo
              formalParameters
                #F7 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
                  element: <testLibrary>::@mixin::A::@setter::foo::@formalParameter::value
        #F2 mixin A (nameOffset:42) (firstTokenOffset:28) (offset:42)
          element: <testLibrary>::@mixin::A
          previousFragment: #F1
          fields
            #F4 augment hasInitializer foo (nameOffset:63) (firstTokenOffset:63) (offset:63)
              element: <testLibrary>::@mixin::A::@field::foo
              previousFragment: #F3
  mixins
    hasNonFinalField mixin A
      reference: <testLibrary>::@mixin::A
      firstFragment: #F1
      superclassConstraints
        Object
      fields
        hasInitializer foo
          reference: <testLibrary>::@mixin::A::@field::foo
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@mixin::A::@getter::foo
          setter: <testLibrary>::@mixin::A::@setter::foo
      getters
        synthetic foo
          reference: <testLibrary>::@mixin::A::@getter::foo
          firstFragment: #F5
          returnType: int
          variable: <testLibrary>::@mixin::A::@field::foo
      setters
        synthetic foo
          reference: <testLibrary>::@mixin::A::@setter::foo
          firstFragment: #F6
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F7
              type: int
          returnType: void
          variable: <testLibrary>::@mixin::A::@field::foo
''');
  }

  /// This is not allowed by the specification, but allowed syntactically,
  /// so we need a way to handle it.
  test_augmented_field_augment_getter() async {
    var library = await buildLibrary(r'''
mixin A {
  int get foo => 0;
}

augment mixin A {
  augment int foo = 1;
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      mixins
        #F1 mixin A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@mixin::A
          nextFragment: #F2
          fields
            #F3 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@mixin::A::@field::foo
              nextFragment: #F4
          getters
            #F5 foo (nameOffset:20) (firstTokenOffset:12) (offset:20)
              element: <testLibrary>::@mixin::A::@getter::foo
        #F2 mixin A (nameOffset:47) (firstTokenOffset:33) (offset:47)
          element: <testLibrary>::@mixin::A
          previousFragment: #F1
          fields
            #F4 augment hasInitializer foo (nameOffset:65) (firstTokenOffset:65) (offset:65)
              element: <testLibrary>::@mixin::A::@field::foo
              previousFragment: #F3
  mixins
    mixin A
      reference: <testLibrary>::@mixin::A
      firstFragment: #F1
      superclassConstraints
        Object
      fields
        synthetic hasInitializer foo
          reference: <testLibrary>::@mixin::A::@field::foo
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@mixin::A::@getter::foo
      getters
        foo
          reference: <testLibrary>::@mixin::A::@getter::foo
          firstFragment: #F5
          returnType: int
          variable: <testLibrary>::@mixin::A::@field::foo
''');
  }

  test_augmented_fields_add() async {
    var library = await buildLibrary(r'''
mixin A {
  int foo1 = 0;
}

augment mixin A {
  int foo2 = 0;
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      mixins
        #F1 mixin A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@mixin::A
          nextFragment: #F2
          fields
            #F3 hasInitializer foo1 (nameOffset:16) (firstTokenOffset:16) (offset:16)
              element: <testLibrary>::@mixin::A::@field::foo1
          getters
            #F4 synthetic foo1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@mixin::A::@getter::foo1
          setters
            #F5 synthetic foo1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@mixin::A::@setter::foo1
              formalParameters
                #F6 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
                  element: <testLibrary>::@mixin::A::@setter::foo1::@formalParameter::value
        #F2 mixin A (nameOffset:43) (firstTokenOffset:29) (offset:43)
          element: <testLibrary>::@mixin::A
          previousFragment: #F1
          fields
            #F7 hasInitializer foo2 (nameOffset:53) (firstTokenOffset:53) (offset:53)
              element: <testLibrary>::@mixin::A::@field::foo2
          getters
            #F8 synthetic foo2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:53)
              element: <testLibrary>::@mixin::A::@getter::foo2
          setters
            #F9 synthetic foo2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:53)
              element: <testLibrary>::@mixin::A::@setter::foo2
              formalParameters
                #F10 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:53)
                  element: <testLibrary>::@mixin::A::@setter::foo2::@formalParameter::value
  mixins
    hasNonFinalField mixin A
      reference: <testLibrary>::@mixin::A
      firstFragment: #F1
      superclassConstraints
        Object
      fields
        hasInitializer foo1
          reference: <testLibrary>::@mixin::A::@field::foo1
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@mixin::A::@getter::foo1
          setter: <testLibrary>::@mixin::A::@setter::foo1
        hasInitializer foo2
          reference: <testLibrary>::@mixin::A::@field::foo2
          firstFragment: #F7
          type: int
          getter: <testLibrary>::@mixin::A::@getter::foo2
          setter: <testLibrary>::@mixin::A::@setter::foo2
      getters
        synthetic foo1
          reference: <testLibrary>::@mixin::A::@getter::foo1
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@mixin::A::@field::foo1
        synthetic foo2
          reference: <testLibrary>::@mixin::A::@getter::foo2
          firstFragment: #F8
          returnType: int
          variable: <testLibrary>::@mixin::A::@field::foo2
      setters
        synthetic foo1
          reference: <testLibrary>::@mixin::A::@setter::foo1
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F6
              type: int
          returnType: void
          variable: <testLibrary>::@mixin::A::@field::foo1
        synthetic foo2
          reference: <testLibrary>::@mixin::A::@setter::foo2
          firstFragment: #F9
          formalParameters
            #E1 requiredPositional value
              firstFragment: #F10
              type: int
          returnType: void
          variable: <testLibrary>::@mixin::A::@field::foo2
''');
  }

  test_augmented_fields_add_generic() async {
    var library = await buildLibrary(r'''
mixin A<T> {
  T foo1;
}

augment mixin A<T> {
  T foo2;
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      mixins
        #F1 mixin A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@mixin::A
          nextFragment: #F2
          typeParameters
            #F3 T (nameOffset:8) (firstTokenOffset:8) (offset:8)
              element: #E0 T
              nextFragment: #F4
          fields
            #F5 foo1 (nameOffset:17) (firstTokenOffset:17) (offset:17)
              element: <testLibrary>::@mixin::A::@field::foo1
          getters
            #F6 synthetic foo1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:17)
              element: <testLibrary>::@mixin::A::@getter::foo1
          setters
            #F7 synthetic foo1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:17)
              element: <testLibrary>::@mixin::A::@setter::foo1
              formalParameters
                #F8 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:17)
                  element: <testLibrary>::@mixin::A::@setter::foo1::@formalParameter::value
        #F2 mixin A (nameOffset:40) (firstTokenOffset:26) (offset:40)
          element: <testLibrary>::@mixin::A
          previousFragment: #F1
          typeParameters
            #F4 T (nameOffset:42) (firstTokenOffset:42) (offset:42)
              element: #E0 T
              previousFragment: #F3
          fields
            #F9 foo2 (nameOffset:51) (firstTokenOffset:51) (offset:51)
              element: <testLibrary>::@mixin::A::@field::foo2
          getters
            #F10 synthetic foo2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:51)
              element: <testLibrary>::@mixin::A::@getter::foo2
          setters
            #F11 synthetic foo2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:51)
              element: <testLibrary>::@mixin::A::@setter::foo2
              formalParameters
                #F12 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:51)
                  element: <testLibrary>::@mixin::A::@setter::foo2::@formalParameter::value
  mixins
    hasNonFinalField mixin A
      reference: <testLibrary>::@mixin::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F3
      superclassConstraints
        Object
      fields
        foo1
          reference: <testLibrary>::@mixin::A::@field::foo1
          firstFragment: #F5
          hasEnclosingTypeParameterReference: true
          type: T
          getter: <testLibrary>::@mixin::A::@getter::foo1
          setter: <testLibrary>::@mixin::A::@setter::foo1
        foo2
          reference: <testLibrary>::@mixin::A::@field::foo2
          firstFragment: #F9
          hasEnclosingTypeParameterReference: true
          type: T
          getter: <testLibrary>::@mixin::A::@getter::foo2
          setter: <testLibrary>::@mixin::A::@setter::foo2
      getters
        synthetic foo1
          reference: <testLibrary>::@mixin::A::@getter::foo1
          firstFragment: #F6
          hasEnclosingTypeParameterReference: true
          returnType: T
          variable: <testLibrary>::@mixin::A::@field::foo1
        synthetic foo2
          reference: <testLibrary>::@mixin::A::@getter::foo2
          firstFragment: #F10
          hasEnclosingTypeParameterReference: true
          returnType: T
          variable: <testLibrary>::@mixin::A::@field::foo2
      setters
        synthetic foo1
          reference: <testLibrary>::@mixin::A::@setter::foo1
          firstFragment: #F7
          hasEnclosingTypeParameterReference: true
          formalParameters
            #E1 requiredPositional value
              firstFragment: #F8
              type: T
          returnType: void
          variable: <testLibrary>::@mixin::A::@field::foo1
        synthetic foo2
          reference: <testLibrary>::@mixin::A::@setter::foo2
          firstFragment: #F11
          hasEnclosingTypeParameterReference: true
          formalParameters
            #E2 requiredPositional value
              firstFragment: #F12
              type: T
          returnType: void
          variable: <testLibrary>::@mixin::A::@field::foo2
''');
  }

  test_augmented_getters_add() async {
    var library = await buildLibrary(r'''
mixin A {
  int get foo1 => 0;
}

augment mixin A {
  int get foo2 => 0;
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      mixins
        #F1 mixin A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@mixin::A
          nextFragment: #F2
          fields
            #F3 synthetic foo1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@mixin::A::@field::foo1
          getters
            #F4 foo1 (nameOffset:20) (firstTokenOffset:12) (offset:20)
              element: <testLibrary>::@mixin::A::@getter::foo1
        #F2 mixin A (nameOffset:48) (firstTokenOffset:34) (offset:48)
          element: <testLibrary>::@mixin::A
          previousFragment: #F1
          fields
            #F5 synthetic foo2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:48)
              element: <testLibrary>::@mixin::A::@field::foo2
          getters
            #F6 foo2 (nameOffset:62) (firstTokenOffset:54) (offset:62)
              element: <testLibrary>::@mixin::A::@getter::foo2
  mixins
    mixin A
      reference: <testLibrary>::@mixin::A
      firstFragment: #F1
      superclassConstraints
        Object
      fields
        synthetic foo1
          reference: <testLibrary>::@mixin::A::@field::foo1
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@mixin::A::@getter::foo1
        synthetic foo2
          reference: <testLibrary>::@mixin::A::@field::foo2
          firstFragment: #F5
          type: int
          getter: <testLibrary>::@mixin::A::@getter::foo2
      getters
        foo1
          reference: <testLibrary>::@mixin::A::@getter::foo1
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@mixin::A::@field::foo1
        foo2
          reference: <testLibrary>::@mixin::A::@getter::foo2
          firstFragment: #F6
          returnType: int
          variable: <testLibrary>::@mixin::A::@field::foo2
''');
  }

  test_augmented_getters_add_generic() async {
    var library = await buildLibrary(r'''
mixin A<T> {
  T get foo1;
}

augment mixin A<T> {
  T get foo2;
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      mixins
        #F1 mixin A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@mixin::A
          nextFragment: #F2
          typeParameters
            #F3 T (nameOffset:8) (firstTokenOffset:8) (offset:8)
              element: #E0 T
              nextFragment: #F4
          fields
            #F5 synthetic foo1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@mixin::A::@field::foo1
          getters
            #F6 foo1 (nameOffset:21) (firstTokenOffset:15) (offset:21)
              element: <testLibrary>::@mixin::A::@getter::foo1
        #F2 mixin A (nameOffset:44) (firstTokenOffset:30) (offset:44)
          element: <testLibrary>::@mixin::A
          previousFragment: #F1
          typeParameters
            #F4 T (nameOffset:46) (firstTokenOffset:46) (offset:46)
              element: #E0 T
              previousFragment: #F3
          fields
            #F7 synthetic foo2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:44)
              element: <testLibrary>::@mixin::A::@field::foo2
          getters
            #F8 foo2 (nameOffset:59) (firstTokenOffset:53) (offset:59)
              element: <testLibrary>::@mixin::A::@getter::foo2
  mixins
    mixin A
      reference: <testLibrary>::@mixin::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F3
      superclassConstraints
        Object
      fields
        synthetic foo1
          reference: <testLibrary>::@mixin::A::@field::foo1
          firstFragment: #F5
          hasEnclosingTypeParameterReference: true
          type: T
          getter: <testLibrary>::@mixin::A::@getter::foo1
        synthetic foo2
          reference: <testLibrary>::@mixin::A::@field::foo2
          firstFragment: #F7
          hasEnclosingTypeParameterReference: true
          type: T
          getter: <testLibrary>::@mixin::A::@getter::foo2
      getters
        abstract foo1
          reference: <testLibrary>::@mixin::A::@getter::foo1
          firstFragment: #F6
          hasEnclosingTypeParameterReference: true
          returnType: T
          variable: <testLibrary>::@mixin::A::@field::foo1
        abstract foo2
          reference: <testLibrary>::@mixin::A::@getter::foo2
          firstFragment: #F8
          hasEnclosingTypeParameterReference: true
          returnType: T
          variable: <testLibrary>::@mixin::A::@field::foo2
''');
  }

  test_augmented_getters_augment_field() async {
    var library = await buildLibrary(r'''
mixin A {
  int foo = 0;
}

augment mixin A {
  augment int get foo => 0;
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      mixins
        #F1 mixin A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@mixin::A
          nextFragment: #F2
          fields
            #F3 hasInitializer foo (nameOffset:16) (firstTokenOffset:16) (offset:16)
              element: <testLibrary>::@mixin::A::@field::foo
          getters
            #F4 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@mixin::A::@getter::foo
              nextFragment: #F5
          setters
            #F6 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@mixin::A::@setter::foo
              formalParameters
                #F7 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
                  element: <testLibrary>::@mixin::A::@setter::foo::@formalParameter::value
        #F2 mixin A (nameOffset:42) (firstTokenOffset:28) (offset:42)
          element: <testLibrary>::@mixin::A
          previousFragment: #F1
          getters
            #F5 augment foo (nameOffset:64) (firstTokenOffset:48) (offset:64)
              element: <testLibrary>::@mixin::A::@getter::foo
              previousFragment: #F4
  mixins
    hasNonFinalField mixin A
      reference: <testLibrary>::@mixin::A
      firstFragment: #F1
      superclassConstraints
        Object
      fields
        hasInitializer foo
          reference: <testLibrary>::@mixin::A::@field::foo
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@mixin::A::@getter::foo
          setter: <testLibrary>::@mixin::A::@setter::foo
      getters
        synthetic foo
          reference: <testLibrary>::@mixin::A::@getter::foo
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@mixin::A::@field::foo
      setters
        synthetic foo
          reference: <testLibrary>::@mixin::A::@setter::foo
          firstFragment: #F6
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F7
              type: int
          returnType: void
          variable: <testLibrary>::@mixin::A::@field::foo
''');
  }

  test_augmented_getters_augment_field2() async {
    var library = await buildLibrary(r'''
mixin A {
  int foo = 0;
}

augment mixin A {
  augment int get foo => 0;
}

augment mixin A {
  augment int get foo => 0;
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      mixins
        #F1 mixin A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@mixin::A
          nextFragment: #F2
          fields
            #F3 hasInitializer foo (nameOffset:16) (firstTokenOffset:16) (offset:16)
              element: <testLibrary>::@mixin::A::@field::foo
          getters
            #F4 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@mixin::A::@getter::foo
              nextFragment: #F5
          setters
            #F6 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@mixin::A::@setter::foo
              formalParameters
                #F7 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
                  element: <testLibrary>::@mixin::A::@setter::foo::@formalParameter::value
        #F2 mixin A (nameOffset:42) (firstTokenOffset:28) (offset:42)
          element: <testLibrary>::@mixin::A
          previousFragment: #F1
          nextFragment: #F8
          getters
            #F5 augment foo (nameOffset:64) (firstTokenOffset:48) (offset:64)
              element: <testLibrary>::@mixin::A::@getter::foo
              previousFragment: #F4
              nextFragment: #F9
        #F8 mixin A (nameOffset:91) (firstTokenOffset:77) (offset:91)
          element: <testLibrary>::@mixin::A
          previousFragment: #F2
          getters
            #F9 augment foo (nameOffset:113) (firstTokenOffset:97) (offset:113)
              element: <testLibrary>::@mixin::A::@getter::foo
              previousFragment: #F5
  mixins
    hasNonFinalField mixin A
      reference: <testLibrary>::@mixin::A
      firstFragment: #F1
      superclassConstraints
        Object
      fields
        hasInitializer foo
          reference: <testLibrary>::@mixin::A::@field::foo
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@mixin::A::@getter::foo
          setter: <testLibrary>::@mixin::A::@setter::foo
      getters
        synthetic foo
          reference: <testLibrary>::@mixin::A::@getter::foo
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@mixin::A::@field::foo
      setters
        synthetic foo
          reference: <testLibrary>::@mixin::A::@setter::foo
          firstFragment: #F6
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F7
              type: int
          returnType: void
          variable: <testLibrary>::@mixin::A::@field::foo
''');
  }

  test_augmented_getters_augment_getter() async {
    var library = await buildLibrary(r'''
mixin A {
  int get foo1 => 0;
  int get foo2 => 0;
}

augment mixin A {
  augment int get foo1 => 0;
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      mixins
        #F1 mixin A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@mixin::A
          nextFragment: #F2
          fields
            #F3 synthetic foo1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@mixin::A::@field::foo1
            #F4 synthetic foo2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@mixin::A::@field::foo2
          getters
            #F5 foo1 (nameOffset:20) (firstTokenOffset:12) (offset:20)
              element: <testLibrary>::@mixin::A::@getter::foo1
              nextFragment: #F6
            #F7 foo2 (nameOffset:41) (firstTokenOffset:33) (offset:41)
              element: <testLibrary>::@mixin::A::@getter::foo2
        #F2 mixin A (nameOffset:69) (firstTokenOffset:55) (offset:69)
          element: <testLibrary>::@mixin::A
          previousFragment: #F1
          getters
            #F6 augment foo1 (nameOffset:91) (firstTokenOffset:75) (offset:91)
              element: <testLibrary>::@mixin::A::@getter::foo1
              previousFragment: #F5
  mixins
    mixin A
      reference: <testLibrary>::@mixin::A
      firstFragment: #F1
      superclassConstraints
        Object
      fields
        synthetic foo1
          reference: <testLibrary>::@mixin::A::@field::foo1
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@mixin::A::@getter::foo1
        synthetic foo2
          reference: <testLibrary>::@mixin::A::@field::foo2
          firstFragment: #F4
          type: int
          getter: <testLibrary>::@mixin::A::@getter::foo2
      getters
        foo1
          reference: <testLibrary>::@mixin::A::@getter::foo1
          firstFragment: #F5
          returnType: int
          variable: <testLibrary>::@mixin::A::@field::foo1
        foo2
          reference: <testLibrary>::@mixin::A::@getter::foo2
          firstFragment: #F7
          returnType: int
          variable: <testLibrary>::@mixin::A::@field::foo2
''');
  }

  test_augmented_getters_augment_getter2() async {
    var library = await buildLibrary(r'''
mixin A {
  int get foo => 0;
}

augment mixin A {
  augment int get foo => 0;
}

augment mixin A {
  augment int get foo => 0;
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      mixins
        #F1 mixin A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@mixin::A
          nextFragment: #F2
          fields
            #F3 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@mixin::A::@field::foo
          getters
            #F4 foo (nameOffset:20) (firstTokenOffset:12) (offset:20)
              element: <testLibrary>::@mixin::A::@getter::foo
              nextFragment: #F5
        #F2 mixin A (nameOffset:47) (firstTokenOffset:33) (offset:47)
          element: <testLibrary>::@mixin::A
          previousFragment: #F1
          nextFragment: #F6
          getters
            #F5 augment foo (nameOffset:69) (firstTokenOffset:53) (offset:69)
              element: <testLibrary>::@mixin::A::@getter::foo
              previousFragment: #F4
              nextFragment: #F7
        #F6 mixin A (nameOffset:96) (firstTokenOffset:82) (offset:96)
          element: <testLibrary>::@mixin::A
          previousFragment: #F2
          getters
            #F7 augment foo (nameOffset:118) (firstTokenOffset:102) (offset:118)
              element: <testLibrary>::@mixin::A::@getter::foo
              previousFragment: #F5
  mixins
    mixin A
      reference: <testLibrary>::@mixin::A
      firstFragment: #F1
      superclassConstraints
        Object
      fields
        synthetic foo
          reference: <testLibrary>::@mixin::A::@field::foo
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@mixin::A::@getter::foo
      getters
        foo
          reference: <testLibrary>::@mixin::A::@getter::foo
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@mixin::A::@field::foo
''');
  }

  test_augmented_interfaces() async {
    var library = await buildLibrary(r'''
mixin A implements I1 {}
class I1 {}

augment mixin A implements I2 {}
class I2 {}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class I1 (nameOffset:31) (firstTokenOffset:25) (offset:31)
          element: <testLibrary>::@class::I1
          constructors
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
              element: <testLibrary>::@class::I1::@constructor::new
              typeName: I1
        #F3 class I2 (nameOffset:77) (firstTokenOffset:71) (offset:77)
          element: <testLibrary>::@class::I2
          constructors
            #F4 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:77)
              element: <testLibrary>::@class::I2::@constructor::new
              typeName: I2
      mixins
        #F5 mixin A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@mixin::A
          nextFragment: #F6
        #F6 mixin A (nameOffset:52) (firstTokenOffset:38) (offset:52)
          element: <testLibrary>::@mixin::A
          previousFragment: #F5
  classes
    class I1
      reference: <testLibrary>::@class::I1
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::I1::@constructor::new
          firstFragment: #F2
    class I2
      reference: <testLibrary>::@class::I2
      firstFragment: #F3
      constructors
        synthetic new
          reference: <testLibrary>::@class::I2::@constructor::new
          firstFragment: #F4
  mixins
    mixin A
      reference: <testLibrary>::@mixin::A
      firstFragment: #F5
      superclassConstraints
        Object
      interfaces
        I1
        I2
''');
  }

  test_augmented_interfaces_chain() async {
    var library = await buildLibrary(r'''
mixin A implements I1 {}
class I1 {}

augment mixin A implements I2 {}
class I2 {}

augment mixin A implements I3 {}
class I3 {}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class I1 (nameOffset:31) (firstTokenOffset:25) (offset:31)
          element: <testLibrary>::@class::I1
          constructors
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
              element: <testLibrary>::@class::I1::@constructor::new
              typeName: I1
        #F3 class I2 (nameOffset:77) (firstTokenOffset:71) (offset:77)
          element: <testLibrary>::@class::I2
          constructors
            #F4 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:77)
              element: <testLibrary>::@class::I2::@constructor::new
              typeName: I2
        #F5 class I3 (nameOffset:123) (firstTokenOffset:117) (offset:123)
          element: <testLibrary>::@class::I3
          constructors
            #F6 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:123)
              element: <testLibrary>::@class::I3::@constructor::new
              typeName: I3
      mixins
        #F7 mixin A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@mixin::A
          nextFragment: #F8
        #F8 mixin A (nameOffset:52) (firstTokenOffset:38) (offset:52)
          element: <testLibrary>::@mixin::A
          previousFragment: #F7
          nextFragment: #F9
        #F9 mixin A (nameOffset:98) (firstTokenOffset:84) (offset:98)
          element: <testLibrary>::@mixin::A
          previousFragment: #F8
  classes
    class I1
      reference: <testLibrary>::@class::I1
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::I1::@constructor::new
          firstFragment: #F2
    class I2
      reference: <testLibrary>::@class::I2
      firstFragment: #F3
      constructors
        synthetic new
          reference: <testLibrary>::@class::I2::@constructor::new
          firstFragment: #F4
    class I3
      reference: <testLibrary>::@class::I3
      firstFragment: #F5
      constructors
        synthetic new
          reference: <testLibrary>::@class::I3::@constructor::new
          firstFragment: #F6
  mixins
    mixin A
      reference: <testLibrary>::@mixin::A
      firstFragment: #F7
      superclassConstraints
        Object
      interfaces
        I1
        I2
        I3
''');
  }

  test_augmented_methods() async {
    var library = await buildLibrary(r'''
mixin A {
  void foo() {}
}

augment mixin A {
  void bar() {}
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      mixins
        #F1 mixin A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@mixin::A
          nextFragment: #F2
          methods
            #F3 foo (nameOffset:17) (firstTokenOffset:12) (offset:17)
              element: <testLibrary>::@mixin::A::@method::foo
        #F2 mixin A (nameOffset:43) (firstTokenOffset:29) (offset:43)
          element: <testLibrary>::@mixin::A
          previousFragment: #F1
          methods
            #F4 bar (nameOffset:54) (firstTokenOffset:49) (offset:54)
              element: <testLibrary>::@mixin::A::@method::bar
  mixins
    mixin A
      reference: <testLibrary>::@mixin::A
      firstFragment: #F1
      superclassConstraints
        Object
      methods
        foo
          reference: <testLibrary>::@mixin::A::@method::foo
          firstFragment: #F3
          returnType: void
        bar
          reference: <testLibrary>::@mixin::A::@method::bar
          firstFragment: #F4
          returnType: void
''');
  }

  test_augmented_methods_augment() async {
    var library = await buildLibrary(r'''
mixin A {
  void foo1() {}
  void foo2() {}
}

augment mixin A {
  augment void foo1() {}
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      mixins
        #F1 mixin A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@mixin::A
          nextFragment: #F2
          methods
            #F3 foo1 (nameOffset:17) (firstTokenOffset:12) (offset:17)
              element: <testLibrary>::@mixin::A::@method::foo1
              nextFragment: #F4
            #F5 foo2 (nameOffset:34) (firstTokenOffset:29) (offset:34)
              element: <testLibrary>::@mixin::A::@method::foo2
        #F2 mixin A (nameOffset:61) (firstTokenOffset:47) (offset:61)
          element: <testLibrary>::@mixin::A
          previousFragment: #F1
          methods
            #F4 augment foo1 (nameOffset:80) (firstTokenOffset:67) (offset:80)
              element: <testLibrary>::@mixin::A::@method::foo1
              previousFragment: #F3
  mixins
    mixin A
      reference: <testLibrary>::@mixin::A
      firstFragment: #F1
      superclassConstraints
        Object
      methods
        foo1
          reference: <testLibrary>::@mixin::A::@method::foo1
          firstFragment: #F3
          returnType: void
        foo2
          reference: <testLibrary>::@mixin::A::@method::foo2
          firstFragment: #F5
          returnType: void
''');
  }

  test_augmented_methods_augment2() async {
    var library = await buildLibrary(r'''
mixin A {
  void foo() {}
}

augment mixin A {
  augment void foo() {}
}

augment mixin A {
  augment void foo() {}
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      mixins
        #F1 mixin A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@mixin::A
          nextFragment: #F2
          methods
            #F3 foo (nameOffset:17) (firstTokenOffset:12) (offset:17)
              element: <testLibrary>::@mixin::A::@method::foo
              nextFragment: #F4
        #F2 mixin A (nameOffset:43) (firstTokenOffset:29) (offset:43)
          element: <testLibrary>::@mixin::A
          previousFragment: #F1
          nextFragment: #F5
          methods
            #F4 augment foo (nameOffset:62) (firstTokenOffset:49) (offset:62)
              element: <testLibrary>::@mixin::A::@method::foo
              previousFragment: #F3
              nextFragment: #F6
        #F5 mixin A (nameOffset:88) (firstTokenOffset:74) (offset:88)
          element: <testLibrary>::@mixin::A
          previousFragment: #F2
          methods
            #F6 augment foo (nameOffset:107) (firstTokenOffset:94) (offset:107)
              element: <testLibrary>::@mixin::A::@method::foo
              previousFragment: #F4
  mixins
    mixin A
      reference: <testLibrary>::@mixin::A
      firstFragment: #F1
      superclassConstraints
        Object
      methods
        foo
          reference: <testLibrary>::@mixin::A::@method::foo
          firstFragment: #F3
          returnType: void
''');
  }

  test_augmented_methods_generic() async {
    var library = await buildLibrary(r'''
mixin A<T> {
  T foo() => throw 0;
}

augment mixin A<T> {
  T bar() => throw 0;
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      mixins
        #F1 mixin A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@mixin::A
          nextFragment: #F2
          typeParameters
            #F3 T (nameOffset:8) (firstTokenOffset:8) (offset:8)
              element: #E0 T
              nextFragment: #F4
          methods
            #F5 foo (nameOffset:17) (firstTokenOffset:15) (offset:17)
              element: <testLibrary>::@mixin::A::@method::foo
        #F2 mixin A (nameOffset:52) (firstTokenOffset:38) (offset:52)
          element: <testLibrary>::@mixin::A
          previousFragment: #F1
          typeParameters
            #F4 T (nameOffset:54) (firstTokenOffset:54) (offset:54)
              element: #E0 T
              previousFragment: #F3
          methods
            #F6 bar (nameOffset:63) (firstTokenOffset:61) (offset:63)
              element: <testLibrary>::@mixin::A::@method::bar
  mixins
    mixin A
      reference: <testLibrary>::@mixin::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F3
      superclassConstraints
        Object
      methods
        foo
          reference: <testLibrary>::@mixin::A::@method::foo
          firstFragment: #F5
          hasEnclosingTypeParameterReference: true
          returnType: T
        bar
          reference: <testLibrary>::@mixin::A::@method::bar
          firstFragment: #F6
          hasEnclosingTypeParameterReference: true
          returnType: T
''');
  }

  test_augmented_methods_generic_augment() async {
    var library = await buildLibrary(r'''
mixin A<T> {
  T foo() => throw 0;
}

augment mixin A<T> {
  augment T foo() => throw 0;
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      mixins
        #F1 mixin A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@mixin::A
          nextFragment: #F2
          typeParameters
            #F3 T (nameOffset:8) (firstTokenOffset:8) (offset:8)
              element: #E0 T
              nextFragment: #F4
          methods
            #F5 foo (nameOffset:17) (firstTokenOffset:15) (offset:17)
              element: <testLibrary>::@mixin::A::@method::foo
              nextFragment: #F6
        #F2 mixin A (nameOffset:52) (firstTokenOffset:38) (offset:52)
          element: <testLibrary>::@mixin::A
          previousFragment: #F1
          typeParameters
            #F4 T (nameOffset:54) (firstTokenOffset:54) (offset:54)
              element: #E0 T
              previousFragment: #F3
          methods
            #F6 augment foo (nameOffset:71) (firstTokenOffset:61) (offset:71)
              element: <testLibrary>::@mixin::A::@method::foo
              previousFragment: #F5
  mixins
    mixin A
      reference: <testLibrary>::@mixin::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F3
      superclassConstraints
        Object
      methods
        foo
          reference: <testLibrary>::@mixin::A::@method::foo
          firstFragment: #F5
          hasEnclosingTypeParameterReference: true
          returnType: T
''');
  }

  test_augmented_methods_typeParameterCountMismatch() async {
    var library = await buildLibrary(r'''
mixin A {
  void foo() {}
  void bar() {}
}

augment mixin A<T> {
  augment void foo() {}
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      mixins
        #F1 mixin A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@mixin::A
          nextFragment: #F2
          methods
            #F3 foo (nameOffset:17) (firstTokenOffset:12) (offset:17)
              element: <testLibrary>::@mixin::A::@method::foo
              nextFragment: #F4
            #F5 bar (nameOffset:33) (firstTokenOffset:28) (offset:33)
              element: <testLibrary>::@mixin::A::@method::bar
        #F2 mixin A (nameOffset:59) (firstTokenOffset:45) (offset:59)
          element: <testLibrary>::@mixin::A
          previousFragment: #F1
          methods
            #F4 augment foo (nameOffset:81) (firstTokenOffset:68) (offset:81)
              element: <testLibrary>::@mixin::A::@method::foo
              previousFragment: #F3
  mixins
    mixin A
      reference: <testLibrary>::@mixin::A
      firstFragment: #F1
      superclassConstraints
        Object
      methods
        foo
          reference: <testLibrary>::@mixin::A::@method::foo
          firstFragment: #F3
          returnType: void
        bar
          reference: <testLibrary>::@mixin::A::@method::bar
          firstFragment: #F5
          returnType: void
''');
  }

  test_augmented_setters_add() async {
    var library = await buildLibrary(r'''
mixin A {
  set foo1(int _) {}
}

augment mixin A {
  set foo2(int _) {}
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      mixins
        #F1 mixin A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@mixin::A
          nextFragment: #F2
          fields
            #F3 synthetic foo1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@mixin::A::@field::foo1
          setters
            #F4 foo1 (nameOffset:16) (firstTokenOffset:12) (offset:16)
              element: <testLibrary>::@mixin::A::@setter::foo1
              formalParameters
                #F5 _ (nameOffset:25) (firstTokenOffset:21) (offset:25)
                  element: <testLibrary>::@mixin::A::@setter::foo1::@formalParameter::_
        #F2 mixin A (nameOffset:48) (firstTokenOffset:34) (offset:48)
          element: <testLibrary>::@mixin::A
          previousFragment: #F1
          fields
            #F6 synthetic foo2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:48)
              element: <testLibrary>::@mixin::A::@field::foo2
          setters
            #F7 foo2 (nameOffset:58) (firstTokenOffset:54) (offset:58)
              element: <testLibrary>::@mixin::A::@setter::foo2
              formalParameters
                #F8 _ (nameOffset:67) (firstTokenOffset:63) (offset:67)
                  element: <testLibrary>::@mixin::A::@setter::foo2::@formalParameter::_
  mixins
    mixin A
      reference: <testLibrary>::@mixin::A
      firstFragment: #F1
      superclassConstraints
        Object
      fields
        synthetic foo1
          reference: <testLibrary>::@mixin::A::@field::foo1
          firstFragment: #F3
          type: int
          setter: <testLibrary>::@mixin::A::@setter::foo1
        synthetic foo2
          reference: <testLibrary>::@mixin::A::@field::foo2
          firstFragment: #F6
          type: int
          setter: <testLibrary>::@mixin::A::@setter::foo2
      setters
        foo1
          reference: <testLibrary>::@mixin::A::@setter::foo1
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional _
              firstFragment: #F5
              type: int
          returnType: void
          variable: <testLibrary>::@mixin::A::@field::foo1
        foo2
          reference: <testLibrary>::@mixin::A::@setter::foo2
          firstFragment: #F7
          formalParameters
            #E1 requiredPositional _
              firstFragment: #F8
              type: int
          returnType: void
          variable: <testLibrary>::@mixin::A::@field::foo2
''');
  }

  test_augmented_setters_augment_field() async {
    var library = await buildLibrary(r'''
mixin A {
  int foo = 0;
}

augment mixin A {
  augment set foo(int _) {}
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      mixins
        #F1 mixin A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@mixin::A
          nextFragment: #F2
          fields
            #F3 hasInitializer foo (nameOffset:16) (firstTokenOffset:16) (offset:16)
              element: <testLibrary>::@mixin::A::@field::foo
          getters
            #F4 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@mixin::A::@getter::foo
          setters
            #F5 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@mixin::A::@setter::foo
              formalParameters
                #F6 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
                  element: <testLibrary>::@mixin::A::@setter::foo::@formalParameter::value
              nextFragment: #F7
        #F2 mixin A (nameOffset:42) (firstTokenOffset:28) (offset:42)
          element: <testLibrary>::@mixin::A
          previousFragment: #F1
          setters
            #F7 augment foo (nameOffset:60) (firstTokenOffset:48) (offset:60)
              element: <testLibrary>::@mixin::A::@setter::foo
              formalParameters
                #F8 _ (nameOffset:68) (firstTokenOffset:64) (offset:68)
                  element: <testLibrary>::@mixin::A::@setter::foo::@formalParameter::_
              previousFragment: #F5
  mixins
    hasNonFinalField mixin A
      reference: <testLibrary>::@mixin::A
      firstFragment: #F1
      superclassConstraints
        Object
      fields
        hasInitializer foo
          reference: <testLibrary>::@mixin::A::@field::foo
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@mixin::A::@getter::foo
          setter: <testLibrary>::@mixin::A::@setter::foo
      getters
        synthetic foo
          reference: <testLibrary>::@mixin::A::@getter::foo
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@mixin::A::@field::foo
      setters
        synthetic foo
          reference: <testLibrary>::@mixin::A::@setter::foo
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F6
              type: int
          returnType: void
          variable: <testLibrary>::@mixin::A::@field::foo
''');
  }

  test_augmented_setters_augment_setter() async {
    var library = await buildLibrary(r'''
mixin A {
  set foo1(int _) {}
  set foo2(int _) {}
}

augment mixin A {
  augment set foo1(int _) {}
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      mixins
        #F1 mixin A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@mixin::A
          nextFragment: #F2
          fields
            #F3 synthetic foo1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@mixin::A::@field::foo1
            #F4 synthetic foo2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@mixin::A::@field::foo2
          setters
            #F5 foo1 (nameOffset:16) (firstTokenOffset:12) (offset:16)
              element: <testLibrary>::@mixin::A::@setter::foo1
              formalParameters
                #F6 _ (nameOffset:25) (firstTokenOffset:21) (offset:25)
                  element: <testLibrary>::@mixin::A::@setter::foo1::@formalParameter::_
              nextFragment: #F7
            #F8 foo2 (nameOffset:37) (firstTokenOffset:33) (offset:37)
              element: <testLibrary>::@mixin::A::@setter::foo2
              formalParameters
                #F9 _ (nameOffset:46) (firstTokenOffset:42) (offset:46)
                  element: <testLibrary>::@mixin::A::@setter::foo2::@formalParameter::_
        #F2 mixin A (nameOffset:69) (firstTokenOffset:55) (offset:69)
          element: <testLibrary>::@mixin::A
          previousFragment: #F1
          setters
            #F7 augment foo1 (nameOffset:87) (firstTokenOffset:75) (offset:87)
              element: <testLibrary>::@mixin::A::@setter::foo1
              formalParameters
                #F10 _ (nameOffset:96) (firstTokenOffset:92) (offset:96)
                  element: <testLibrary>::@mixin::A::@setter::foo1::@formalParameter::_
              previousFragment: #F5
  mixins
    mixin A
      reference: <testLibrary>::@mixin::A
      firstFragment: #F1
      superclassConstraints
        Object
      fields
        synthetic foo1
          reference: <testLibrary>::@mixin::A::@field::foo1
          firstFragment: #F3
          type: int
          setter: <testLibrary>::@mixin::A::@setter::foo1
        synthetic foo2
          reference: <testLibrary>::@mixin::A::@field::foo2
          firstFragment: #F4
          type: int
          setter: <testLibrary>::@mixin::A::@setter::foo2
      setters
        foo1
          reference: <testLibrary>::@mixin::A::@setter::foo1
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional _
              firstFragment: #F6
              type: int
          returnType: void
          variable: <testLibrary>::@mixin::A::@field::foo1
        foo2
          reference: <testLibrary>::@mixin::A::@setter::foo2
          firstFragment: #F8
          formalParameters
            #E1 requiredPositional _
              firstFragment: #F9
              type: int
          returnType: void
          variable: <testLibrary>::@mixin::A::@field::foo2
''');
  }

  test_augmented_superclassConstraints() async {
    var library = await buildLibrary(r'''
mixin A on B1 {}
class B1 {}

augment mixin A on B2 {}
class B2 {}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class B1 (nameOffset:23) (firstTokenOffset:17) (offset:23)
          element: <testLibrary>::@class::B1
          constructors
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
              element: <testLibrary>::@class::B1::@constructor::new
              typeName: B1
        #F3 class B2 (nameOffset:61) (firstTokenOffset:55) (offset:61)
          element: <testLibrary>::@class::B2
          constructors
            #F4 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:61)
              element: <testLibrary>::@class::B2::@constructor::new
              typeName: B2
      mixins
        #F5 mixin A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@mixin::A
          nextFragment: #F6
        #F6 mixin A (nameOffset:44) (firstTokenOffset:30) (offset:44)
          element: <testLibrary>::@mixin::A
          previousFragment: #F5
  classes
    class B1
      reference: <testLibrary>::@class::B1
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::B1::@constructor::new
          firstFragment: #F2
    class B2
      reference: <testLibrary>::@class::B2
      firstFragment: #F3
      constructors
        synthetic new
          reference: <testLibrary>::@class::B2::@constructor::new
          firstFragment: #F4
  mixins
    mixin A
      reference: <testLibrary>::@mixin::A
      firstFragment: #F5
      superclassConstraints
        B1
        B2
''');
  }

  test_augmented_superclassConstraints_chain() async {
    var library = await buildLibrary(r'''
mixin A on I1 {}
class I1 {}

augment mixin A on I2 {}
class I2 {}

augment mixin A on I3 {}
class I3 {}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class I1 (nameOffset:23) (firstTokenOffset:17) (offset:23)
          element: <testLibrary>::@class::I1
          constructors
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
              element: <testLibrary>::@class::I1::@constructor::new
              typeName: I1
        #F3 class I2 (nameOffset:61) (firstTokenOffset:55) (offset:61)
          element: <testLibrary>::@class::I2
          constructors
            #F4 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:61)
              element: <testLibrary>::@class::I2::@constructor::new
              typeName: I2
        #F5 class I3 (nameOffset:99) (firstTokenOffset:93) (offset:99)
          element: <testLibrary>::@class::I3
          constructors
            #F6 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:99)
              element: <testLibrary>::@class::I3::@constructor::new
              typeName: I3
      mixins
        #F7 mixin A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@mixin::A
          nextFragment: #F8
        #F8 mixin A (nameOffset:44) (firstTokenOffset:30) (offset:44)
          element: <testLibrary>::@mixin::A
          previousFragment: #F7
          nextFragment: #F9
        #F9 mixin A (nameOffset:82) (firstTokenOffset:68) (offset:82)
          element: <testLibrary>::@mixin::A
          previousFragment: #F8
  classes
    class I1
      reference: <testLibrary>::@class::I1
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::I1::@constructor::new
          firstFragment: #F2
    class I2
      reference: <testLibrary>::@class::I2
      firstFragment: #F3
      constructors
        synthetic new
          reference: <testLibrary>::@class::I2::@constructor::new
          firstFragment: #F4
    class I3
      reference: <testLibrary>::@class::I3
      firstFragment: #F5
      constructors
        synthetic new
          reference: <testLibrary>::@class::I3::@constructor::new
          firstFragment: #F6
  mixins
    mixin A
      reference: <testLibrary>::@mixin::A
      firstFragment: #F7
      superclassConstraints
        I1
        I2
        I3
''');
  }

  test_augmented_superclassConstraints_fromAugmentation() async {
    var library = await buildLibrary(r'''
mixin A {}

augment mixin A on B {}
class B {}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class B (nameOffset:42) (firstTokenOffset:36) (offset:42)
          element: <testLibrary>::@class::B
          constructors
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:42)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
      mixins
        #F3 mixin A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@mixin::A
          nextFragment: #F4
        #F4 mixin A (nameOffset:26) (firstTokenOffset:12) (offset:26)
          element: <testLibrary>::@mixin::A
          previousFragment: #F3
  classes
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F2
  mixins
    mixin A
      reference: <testLibrary>::@mixin::A
      firstFragment: #F3
      superclassConstraints
        B
''');
  }

  test_augmented_superclassConstraints_generic() async {
    var library = await buildLibrary(r'''
mixin A<T> on I1 {}
class I1 {}

augment mixin A<T> on I2<T> {}
class I2<E> {}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class I1 (nameOffset:26) (firstTokenOffset:20) (offset:26)
          element: <testLibrary>::@class::I1
          constructors
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:26)
              element: <testLibrary>::@class::I1::@constructor::new
              typeName: I1
        #F3 class I2 (nameOffset:70) (firstTokenOffset:64) (offset:70)
          element: <testLibrary>::@class::I2
          typeParameters
            #F4 E (nameOffset:73) (firstTokenOffset:73) (offset:73)
              element: #E0 E
          constructors
            #F5 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:70)
              element: <testLibrary>::@class::I2::@constructor::new
              typeName: I2
      mixins
        #F6 mixin A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@mixin::A
          nextFragment: #F7
          typeParameters
            #F8 T (nameOffset:8) (firstTokenOffset:8) (offset:8)
              element: #E1 T
              nextFragment: #F9
        #F7 mixin A (nameOffset:47) (firstTokenOffset:33) (offset:47)
          element: <testLibrary>::@mixin::A
          previousFragment: #F6
          typeParameters
            #F9 T (nameOffset:49) (firstTokenOffset:49) (offset:49)
              element: #E1 T
              previousFragment: #F8
  classes
    class I1
      reference: <testLibrary>::@class::I1
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::I1::@constructor::new
          firstFragment: #F2
    class I2
      reference: <testLibrary>::@class::I2
      firstFragment: #F3
      typeParameters
        #E0 E
          firstFragment: #F4
      constructors
        synthetic new
          reference: <testLibrary>::@class::I2::@constructor::new
          firstFragment: #F5
  mixins
    mixin A
      reference: <testLibrary>::@mixin::A
      firstFragment: #F6
      typeParameters
        #E1 T
          firstFragment: #F8
      superclassConstraints
        I1
        I2<T>
''');
  }

  test_augmentedBy_class2() async {
    var library = await buildLibrary(r'''
mixin A {}
augment class A {}
augment class A {}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A (nameOffset:25) (firstTokenOffset:11) (offset:25)
          element: <testLibrary>::@class::A
          nextFragment: #F2
        #F2 class A (nameOffset:44) (firstTokenOffset:30) (offset:44)
          element: <testLibrary>::@class::A
          previousFragment: #F1
      mixins
        #F3 mixin A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@mixin::A
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
  mixins
    mixin A
      reference: <testLibrary>::@mixin::A
      firstFragment: #F3
      superclassConstraints
        Object
''');
  }

  test_augmentedBy_class_mixin() async {
    var library = await buildLibrary(r'''
mixin A {}

augment class A {}
augment mixin A {}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A (nameOffset:26) (firstTokenOffset:12) (offset:26)
          element: <testLibrary>::@class::A
          constructors
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:26)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
      mixins
        #F3 mixin A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@mixin::A::@def::0
        #F4 mixin A (nameOffset:45) (firstTokenOffset:31) (offset:45)
          element: <testLibrary>::@mixin::A::@def::1
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
  mixins
    mixin A
      reference: <testLibrary>::@mixin::A::@def::0
      firstFragment: #F3
      superclassConstraints
        Object
    mixin A
      reference: <testLibrary>::@mixin::A::@def::1
      firstFragment: #F4
      superclassConstraints
        Object
''');
  }

  test_inferTypes_method_ofAugment() async {
    var library = await buildLibrary(r'''
mixin B on A {}

class A {
  int foo(String a) => 0;
}

augment mixin B {
  foo(a) => 0;
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A (nameOffset:23) (firstTokenOffset:17) (offset:23)
          element: <testLibrary>::@class::A
          constructors
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          methods
            #F3 foo (nameOffset:33) (firstTokenOffset:29) (offset:33)
              element: <testLibrary>::@class::A::@method::foo
              formalParameters
                #F4 a (nameOffset:44) (firstTokenOffset:37) (offset:44)
                  element: <testLibrary>::@class::A::@method::foo::@formalParameter::a
      mixins
        #F5 mixin B (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@mixin::B
          nextFragment: #F6
        #F6 mixin B (nameOffset:70) (firstTokenOffset:56) (offset:70)
          element: <testLibrary>::@mixin::B
          previousFragment: #F5
          methods
            #F7 foo (nameOffset:76) (firstTokenOffset:76) (offset:76)
              element: <testLibrary>::@mixin::B::@method::foo
              formalParameters
                #F8 a (nameOffset:80) (firstTokenOffset:80) (offset:80)
                  element: <testLibrary>::@mixin::B::@method::foo::@formalParameter::a
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
      methods
        foo
          reference: <testLibrary>::@class::A::@method::foo
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional a
              firstFragment: #F4
              type: String
          returnType: int
  mixins
    mixin B
      reference: <testLibrary>::@mixin::B
      firstFragment: #F5
      superclassConstraints
        A
      methods
        foo
          reference: <testLibrary>::@mixin::B::@method::foo
          firstFragment: #F7
          formalParameters
            #E1 requiredPositional hasImplicitType a
              firstFragment: #F8
              type: String
          returnType: int
''');
  }

  test_inferTypes_method_usingAugmentation_interface() async {
    var library = await buildLibrary(r'''
mixin B {
  foo(a) => 0;
}

class A {
  int foo(String a) => 0;
}

augment mixin B implements A {}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A (nameOffset:34) (firstTokenOffset:28) (offset:34)
          element: <testLibrary>::@class::A
          constructors
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:34)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          methods
            #F3 foo (nameOffset:44) (firstTokenOffset:40) (offset:44)
              element: <testLibrary>::@class::A::@method::foo
              formalParameters
                #F4 a (nameOffset:55) (firstTokenOffset:48) (offset:55)
                  element: <testLibrary>::@class::A::@method::foo::@formalParameter::a
      mixins
        #F5 mixin B (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@mixin::B
          nextFragment: #F6
          methods
            #F7 foo (nameOffset:12) (firstTokenOffset:12) (offset:12)
              element: <testLibrary>::@mixin::B::@method::foo
              formalParameters
                #F8 a (nameOffset:16) (firstTokenOffset:16) (offset:16)
                  element: <testLibrary>::@mixin::B::@method::foo::@formalParameter::a
        #F6 mixin B (nameOffset:81) (firstTokenOffset:67) (offset:81)
          element: <testLibrary>::@mixin::B
          previousFragment: #F5
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
      methods
        foo
          reference: <testLibrary>::@class::A::@method::foo
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional a
              firstFragment: #F4
              type: String
          returnType: int
  mixins
    mixin B
      reference: <testLibrary>::@mixin::B
      firstFragment: #F5
      superclassConstraints
        Object
      interfaces
        A
      methods
        foo
          reference: <testLibrary>::@mixin::B::@method::foo
          firstFragment: #F7
          formalParameters
            #E1 requiredPositional hasImplicitType a
              firstFragment: #F8
              type: String
          returnType: int
''');
  }

  test_inferTypes_method_usingAugmentation_superclassConstraint() async {
    var library = await buildLibrary(r'''
mixin B {
  foo(a) => 0;
}

class A {
  int foo(String a) => 0;
}

augment mixin B on A {}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A (nameOffset:34) (firstTokenOffset:28) (offset:34)
          element: <testLibrary>::@class::A
          constructors
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:34)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          methods
            #F3 foo (nameOffset:44) (firstTokenOffset:40) (offset:44)
              element: <testLibrary>::@class::A::@method::foo
              formalParameters
                #F4 a (nameOffset:55) (firstTokenOffset:48) (offset:55)
                  element: <testLibrary>::@class::A::@method::foo::@formalParameter::a
      mixins
        #F5 mixin B (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@mixin::B
          nextFragment: #F6
          methods
            #F7 foo (nameOffset:12) (firstTokenOffset:12) (offset:12)
              element: <testLibrary>::@mixin::B::@method::foo
              formalParameters
                #F8 a (nameOffset:16) (firstTokenOffset:16) (offset:16)
                  element: <testLibrary>::@mixin::B::@method::foo::@formalParameter::a
        #F6 mixin B (nameOffset:81) (firstTokenOffset:67) (offset:81)
          element: <testLibrary>::@mixin::B
          previousFragment: #F5
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
      methods
        foo
          reference: <testLibrary>::@class::A::@method::foo
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional a
              firstFragment: #F4
              type: String
          returnType: int
  mixins
    mixin B
      reference: <testLibrary>::@mixin::B
      firstFragment: #F5
      superclassConstraints
        A
      methods
        foo
          reference: <testLibrary>::@mixin::B::@method::foo
          firstFragment: #F7
          formalParameters
            #E1 requiredPositional hasImplicitType a
              firstFragment: #F8
              type: String
          returnType: int
''');
  }

  test_inferTypes_method_withAugment() async {
    var library = await buildLibrary(r'''
mixin B on A {
  foo(a) => 0;
}

class A {
  int foo(String a) => 0;
}

augment mixin B {
  augment foo(a) => 0;
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A (nameOffset:39) (firstTokenOffset:33) (offset:39)
          element: <testLibrary>::@class::A
          constructors
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:39)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          methods
            #F3 foo (nameOffset:49) (firstTokenOffset:45) (offset:49)
              element: <testLibrary>::@class::A::@method::foo
              formalParameters
                #F4 a (nameOffset:60) (firstTokenOffset:53) (offset:60)
                  element: <testLibrary>::@class::A::@method::foo::@formalParameter::a
      mixins
        #F5 mixin B (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@mixin::B
          nextFragment: #F6
          methods
            #F7 foo (nameOffset:17) (firstTokenOffset:17) (offset:17)
              element: <testLibrary>::@mixin::B::@method::foo
              nextFragment: #F8
              formalParameters
                #F9 a (nameOffset:21) (firstTokenOffset:21) (offset:21)
                  element: <testLibrary>::@mixin::B::@method::foo::@formalParameter::a
        #F6 mixin B (nameOffset:86) (firstTokenOffset:72) (offset:86)
          element: <testLibrary>::@mixin::B
          previousFragment: #F5
          methods
            #F8 augment foo (nameOffset:100) (firstTokenOffset:92) (offset:100)
              element: <testLibrary>::@mixin::B::@method::foo
              previousFragment: #F7
              formalParameters
                #F10 a (nameOffset:104) (firstTokenOffset:104) (offset:104)
                  element: <testLibrary>::@mixin::B::@method::foo::@formalParameter::a
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
      methods
        foo
          reference: <testLibrary>::@class::A::@method::foo
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional a
              firstFragment: #F4
              type: String
          returnType: int
  mixins
    mixin B
      reference: <testLibrary>::@mixin::B
      firstFragment: #F5
      superclassConstraints
        A
      methods
        foo
          reference: <testLibrary>::@mixin::B::@method::foo
          firstFragment: #F7
          formalParameters
            #E1 requiredPositional hasImplicitType a
              firstFragment: #F9
              type: String
          returnType: int
''');
  }

  test_method_typeParameters_111() async {
    var library = await buildLibrary(r'''
mixin A {
  void foo<T>(){}
}
augment mixin A {
  augment void foo<T>(){}
}
augment mixin A {
  augment void foo<T>(){}
}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      mixins
        #F1 mixin A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@mixin::A
          nextFragment: #F2
          methods
            #F3 foo (nameOffset:17) (firstTokenOffset:12) (offset:17)
              element: <testLibrary>::@mixin::A::@method::foo
              nextFragment: #F4
              typeParameters
                #F5 T (nameOffset:21) (firstTokenOffset:21) (offset:21)
                  element: #E0 T
                  nextFragment: #F6
        #F2 mixin A (nameOffset:44) (firstTokenOffset:30) (offset:44)
          element: <testLibrary>::@mixin::A
          previousFragment: #F1
          nextFragment: #F7
          methods
            #F4 augment foo (nameOffset:63) (firstTokenOffset:50) (offset:63)
              element: <testLibrary>::@mixin::A::@method::foo
              previousFragment: #F3
              nextFragment: #F8
              typeParameters
                #F6 T (nameOffset:67) (firstTokenOffset:67) (offset:67)
                  element: #E0 T
                  previousFragment: #F5
                  nextFragment: #F9
        #F7 mixin A (nameOffset:90) (firstTokenOffset:76) (offset:90)
          element: <testLibrary>::@mixin::A
          previousFragment: #F2
          methods
            #F8 augment foo (nameOffset:109) (firstTokenOffset:96) (offset:109)
              element: <testLibrary>::@mixin::A::@method::foo
              previousFragment: #F4
              typeParameters
                #F9 T (nameOffset:113) (firstTokenOffset:113) (offset:113)
                  element: #E0 T
                  previousFragment: #F6
  mixins
    mixin A
      reference: <testLibrary>::@mixin::A
      firstFragment: #F1
      superclassConstraints
        Object
      methods
        foo
          reference: <testLibrary>::@mixin::A::@method::foo
          firstFragment: #F3
          typeParameters
            #E0 T
              firstFragment: #F5
          returnType: void
''');
  }

  test_method_typeParameters_121() async {
    var library = await buildLibrary(r'''
mixin A {
  void foo<T>(){}
}
augment mixin A {
  augment void foo<T, U>(){}
}
augment mixin A {
  augment void foo<T>(){}
}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      mixins
        #F1 mixin A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@mixin::A
          nextFragment: #F2
          methods
            #F3 foo (nameOffset:17) (firstTokenOffset:12) (offset:17)
              element: <testLibrary>::@mixin::A::@method::foo
              nextFragment: #F4
              typeParameters
                #F5 T (nameOffset:21) (firstTokenOffset:21) (offset:21)
                  element: #E0 T
                  nextFragment: #F6
        #F2 mixin A (nameOffset:44) (firstTokenOffset:30) (offset:44)
          element: <testLibrary>::@mixin::A
          previousFragment: #F1
          nextFragment: #F7
          methods
            #F4 augment foo (nameOffset:63) (firstTokenOffset:50) (offset:63)
              element: <testLibrary>::@mixin::A::@method::foo
              previousFragment: #F3
              nextFragment: #F8
              typeParameters
                #F6 T (nameOffset:67) (firstTokenOffset:67) (offset:67)
                  element: #E0 T
                  previousFragment: #F5
                  nextFragment: #F9
        #F7 mixin A (nameOffset:93) (firstTokenOffset:79) (offset:93)
          element: <testLibrary>::@mixin::A
          previousFragment: #F2
          methods
            #F8 augment foo (nameOffset:112) (firstTokenOffset:99) (offset:112)
              element: <testLibrary>::@mixin::A::@method::foo
              previousFragment: #F4
              typeParameters
                #F9 T (nameOffset:116) (firstTokenOffset:116) (offset:116)
                  element: #E0 T
                  previousFragment: #F6
  mixins
    mixin A
      reference: <testLibrary>::@mixin::A
      firstFragment: #F1
      superclassConstraints
        Object
      methods
        foo
          reference: <testLibrary>::@mixin::A::@method::foo
          firstFragment: #F3
          typeParameters
            #E0 T
              firstFragment: #F5
          returnType: void
''');
  }

  test_method_typeParameters_212() async {
    var library = await buildLibrary(r'''
mixin A {
  void foo<T, U>(){}
}
augment mixin A {
  augment void foo<T>(){}
}
augment mixin A {
  augment void foo<T, U>(){}
}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      mixins
        #F1 mixin A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@mixin::A
          nextFragment: #F2
          methods
            #F3 foo (nameOffset:17) (firstTokenOffset:12) (offset:17)
              element: <testLibrary>::@mixin::A::@method::foo
              nextFragment: #F4
              typeParameters
                #F5 T (nameOffset:21) (firstTokenOffset:21) (offset:21)
                  element: #E0 T
                  nextFragment: #F6
                #F7 U (nameOffset:24) (firstTokenOffset:24) (offset:24)
                  element: #E1 U
                  nextFragment: #F8
        #F2 mixin A (nameOffset:47) (firstTokenOffset:33) (offset:47)
          element: <testLibrary>::@mixin::A
          previousFragment: #F1
          nextFragment: #F9
          methods
            #F4 augment foo (nameOffset:66) (firstTokenOffset:53) (offset:66)
              element: <testLibrary>::@mixin::A::@method::foo
              previousFragment: #F3
              nextFragment: #F10
              typeParameters
                #F6 T (nameOffset:70) (firstTokenOffset:70) (offset:70)
                  element: #E0 T
                  previousFragment: #F5
                  nextFragment: #F11
                #F8 U (nameOffset:<null>) (firstTokenOffset:<null>) (offset:66)
                  element: #E1 U
                  previousFragment: #F7
                  nextFragment: #F12
        #F9 mixin A (nameOffset:93) (firstTokenOffset:79) (offset:93)
          element: <testLibrary>::@mixin::A
          previousFragment: #F2
          methods
            #F10 augment foo (nameOffset:112) (firstTokenOffset:99) (offset:112)
              element: <testLibrary>::@mixin::A::@method::foo
              previousFragment: #F4
              typeParameters
                #F11 T (nameOffset:116) (firstTokenOffset:116) (offset:116)
                  element: #E0 T
                  previousFragment: #F6
                #F12 U (nameOffset:119) (firstTokenOffset:119) (offset:119)
                  element: #E1 U
                  previousFragment: #F8
  mixins
    mixin A
      reference: <testLibrary>::@mixin::A
      firstFragment: #F1
      superclassConstraints
        Object
      methods
        foo
          reference: <testLibrary>::@mixin::A::@method::foo
          firstFragment: #F3
          typeParameters
            #E0 T
              firstFragment: #F5
            #E1 U
              firstFragment: #F7
          returnType: void
''');
  }

  test_method_typeParameters_bounds_bounds_int_int() async {
    var library = await buildLibrary(r'''
mixin A {
  void foo<T extends int>() {}
}
augment mixin A {
  augment void foo<T extends int>() {}
}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      mixins
        #F1 mixin A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@mixin::A
          nextFragment: #F2
          methods
            #F3 foo (nameOffset:17) (firstTokenOffset:12) (offset:17)
              element: <testLibrary>::@mixin::A::@method::foo
              nextFragment: #F4
              typeParameters
                #F5 T (nameOffset:21) (firstTokenOffset:21) (offset:21)
                  element: #E0 T
                  nextFragment: #F6
        #F2 mixin A (nameOffset:57) (firstTokenOffset:43) (offset:57)
          element: <testLibrary>::@mixin::A
          previousFragment: #F1
          methods
            #F4 augment foo (nameOffset:76) (firstTokenOffset:63) (offset:76)
              element: <testLibrary>::@mixin::A::@method::foo
              previousFragment: #F3
              typeParameters
                #F6 T (nameOffset:80) (firstTokenOffset:80) (offset:80)
                  element: #E0 T
                  previousFragment: #F5
  mixins
    mixin A
      reference: <testLibrary>::@mixin::A
      firstFragment: #F1
      superclassConstraints
        Object
      methods
        foo
          reference: <testLibrary>::@mixin::A::@method::foo
          firstFragment: #F3
          typeParameters
            #E0 T
              firstFragment: #F5
              bound: int
          returnType: void
''');
  }

  test_method_typeParameters_bounds_int_nothing() async {
    var library = await buildLibrary(r'''
mixin A {
  void foo<T extends int>() {}
}
augment mixin A {
  augment void foo<T>() {}
}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      mixins
        #F1 mixin A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@mixin::A
          nextFragment: #F2
          methods
            #F3 foo (nameOffset:17) (firstTokenOffset:12) (offset:17)
              element: <testLibrary>::@mixin::A::@method::foo
              nextFragment: #F4
              typeParameters
                #F5 T (nameOffset:21) (firstTokenOffset:21) (offset:21)
                  element: #E0 T
                  nextFragment: #F6
        #F2 mixin A (nameOffset:57) (firstTokenOffset:43) (offset:57)
          element: <testLibrary>::@mixin::A
          previousFragment: #F1
          methods
            #F4 augment foo (nameOffset:76) (firstTokenOffset:63) (offset:76)
              element: <testLibrary>::@mixin::A::@method::foo
              previousFragment: #F3
              typeParameters
                #F6 T (nameOffset:80) (firstTokenOffset:80) (offset:80)
                  element: #E0 T
                  previousFragment: #F5
  mixins
    mixin A
      reference: <testLibrary>::@mixin::A
      firstFragment: #F1
      superclassConstraints
        Object
      methods
        foo
          reference: <testLibrary>::@mixin::A::@method::foo
          firstFragment: #F3
          typeParameters
            #E0 T
              firstFragment: #F5
              bound: int
          returnType: void
''');
  }

  test_method_typeParameters_bounds_int_string() async {
    var library = await buildLibrary(r'''
mixin A {
  void foo<T extends int>() {}
}
augment mixin A {
  augment void foo<T extends String>() {}
}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      mixins
        #F1 mixin A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@mixin::A
          nextFragment: #F2
          methods
            #F3 foo (nameOffset:17) (firstTokenOffset:12) (offset:17)
              element: <testLibrary>::@mixin::A::@method::foo
              nextFragment: #F4
              typeParameters
                #F5 T (nameOffset:21) (firstTokenOffset:21) (offset:21)
                  element: #E0 T
                  nextFragment: #F6
        #F2 mixin A (nameOffset:57) (firstTokenOffset:43) (offset:57)
          element: <testLibrary>::@mixin::A
          previousFragment: #F1
          methods
            #F4 augment foo (nameOffset:76) (firstTokenOffset:63) (offset:76)
              element: <testLibrary>::@mixin::A::@method::foo
              previousFragment: #F3
              typeParameters
                #F6 T (nameOffset:80) (firstTokenOffset:80) (offset:80)
                  element: #E0 T
                  previousFragment: #F5
  mixins
    mixin A
      reference: <testLibrary>::@mixin::A
      firstFragment: #F1
      superclassConstraints
        Object
      methods
        foo
          reference: <testLibrary>::@mixin::A::@method::foo
          firstFragment: #F3
          typeParameters
            #E0 T
              firstFragment: #F5
              bound: int
          returnType: void
''');
  }

  test_method_typeParameters_bounds_nothing_int() async {
    var library = await buildLibrary(r'''
mixin A {
  void foo<T>() {}
}
augment mixin A {
  augment void foo<T extends int>() {}
}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      mixins
        #F1 mixin A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@mixin::A
          nextFragment: #F2
          methods
            #F3 foo (nameOffset:17) (firstTokenOffset:12) (offset:17)
              element: <testLibrary>::@mixin::A::@method::foo
              nextFragment: #F4
              typeParameters
                #F5 T (nameOffset:21) (firstTokenOffset:21) (offset:21)
                  element: #E0 T
                  nextFragment: #F6
        #F2 mixin A (nameOffset:45) (firstTokenOffset:31) (offset:45)
          element: <testLibrary>::@mixin::A
          previousFragment: #F1
          methods
            #F4 augment foo (nameOffset:64) (firstTokenOffset:51) (offset:64)
              element: <testLibrary>::@mixin::A::@method::foo
              previousFragment: #F3
              typeParameters
                #F6 T (nameOffset:68) (firstTokenOffset:68) (offset:68)
                  element: #E0 T
                  previousFragment: #F5
  mixins
    mixin A
      reference: <testLibrary>::@mixin::A
      firstFragment: #F1
      superclassConstraints
        Object
      methods
        foo
          reference: <testLibrary>::@mixin::A::@method::foo
          firstFragment: #F3
          typeParameters
            #E0 T
              firstFragment: #F5
          returnType: void
''');
  }

  test_method_typeParameters_differentNames() async {
    var library = await buildLibrary(r'''
mixin A {
  void foo<T, U>() {}
}

augment mixin A {
  augment void foo<U, T>() {}
}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      mixins
        #F1 mixin A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@mixin::A
          nextFragment: #F2
          methods
            #F3 foo (nameOffset:17) (firstTokenOffset:12) (offset:17)
              element: <testLibrary>::@mixin::A::@method::foo
              nextFragment: #F4
              typeParameters
                #F5 T (nameOffset:21) (firstTokenOffset:21) (offset:21)
                  element: #E0 T
                  nextFragment: #F6
                #F7 U (nameOffset:24) (firstTokenOffset:24) (offset:24)
                  element: #E1 U
                  nextFragment: #F8
        #F2 mixin A (nameOffset:49) (firstTokenOffset:35) (offset:49)
          element: <testLibrary>::@mixin::A
          previousFragment: #F1
          methods
            #F4 augment foo (nameOffset:68) (firstTokenOffset:55) (offset:68)
              element: <testLibrary>::@mixin::A::@method::foo
              previousFragment: #F3
              typeParameters
                #F6 U (nameOffset:72) (firstTokenOffset:72) (offset:72)
                  element: #E0 T
                  previousFragment: #F5
                #F8 T (nameOffset:75) (firstTokenOffset:75) (offset:75)
                  element: #E1 U
                  previousFragment: #F7
  mixins
    mixin A
      reference: <testLibrary>::@mixin::A
      firstFragment: #F1
      superclassConstraints
        Object
      methods
        foo
          reference: <testLibrary>::@mixin::A::@method::foo
          firstFragment: #F3
          typeParameters
            #E0 T
              firstFragment: #F5
            #E1 U
              firstFragment: #F7
          returnType: void
''');
  }

  test_modifiers_base() async {
    var library = await buildLibrary(r'''
base mixin A {}
augment base mixin A {}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      mixins
        #F1 mixin A (nameOffset:11) (firstTokenOffset:0) (offset:11)
          element: <testLibrary>::@mixin::A
          nextFragment: #F2
        #F2 mixin A (nameOffset:35) (firstTokenOffset:16) (offset:35)
          element: <testLibrary>::@mixin::A
          previousFragment: #F1
  mixins
    base mixin A
      reference: <testLibrary>::@mixin::A
      firstFragment: #F1
      superclassConstraints
        Object
''');
  }

  test_notAugmented_interfaces() async {
    var library = await buildLibrary(r'''
mixin A implements I {}
class I {}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class I (nameOffset:30) (firstTokenOffset:24) (offset:30)
          element: <testLibrary>::@class::I
          constructors
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:30)
              element: <testLibrary>::@class::I::@constructor::new
              typeName: I
      mixins
        #F3 mixin A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@mixin::A
  classes
    class I
      reference: <testLibrary>::@class::I
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::I::@constructor::new
          firstFragment: #F2
  mixins
    mixin A
      reference: <testLibrary>::@mixin::A
      firstFragment: #F3
      superclassConstraints
        Object
      interfaces
        I
''');
  }

  test_notAugmented_superclassConstraints() async {
    var library = await buildLibrary(r'''
mixin A on B {}
class B {}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class B (nameOffset:22) (firstTokenOffset:16) (offset:22)
          element: <testLibrary>::@class::B
          constructors
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
      mixins
        #F3 mixin A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@mixin::A
  classes
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F2
  mixins
    mixin A
      reference: <testLibrary>::@mixin::A
      firstFragment: #F3
      superclassConstraints
        B
''');
  }

  test_notSimplyBounded_self() async {
    var library = await buildLibrary(r'''
mixin A<T extends A> {}

augment mixin A<T extends A> {}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      mixins
        #F1 mixin A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@mixin::A
          nextFragment: #F2
          typeParameters
            #F3 T (nameOffset:8) (firstTokenOffset:8) (offset:8)
              element: #E0 T
              nextFragment: #F4
        #F2 mixin A (nameOffset:39) (firstTokenOffset:25) (offset:39)
          element: <testLibrary>::@mixin::A
          previousFragment: #F1
          typeParameters
            #F4 T (nameOffset:41) (firstTokenOffset:41) (offset:41)
              element: #E0 T
              previousFragment: #F3
  mixins
    notSimplyBounded mixin A
      reference: <testLibrary>::@mixin::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F3
          bound: A<dynamic>
      superclassConstraints
        Object
''');
  }

  test_typeParameters_111() async {
    var library = await buildLibrary(r'''
mixin A<T> {}
augment mixin A<T> {}
augment mixin A<T> {}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      mixins
        #F1 mixin A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@mixin::A
          nextFragment: #F2
          typeParameters
            #F3 T (nameOffset:8) (firstTokenOffset:8) (offset:8)
              element: #E0 T
              nextFragment: #F4
        #F2 mixin A (nameOffset:28) (firstTokenOffset:14) (offset:28)
          element: <testLibrary>::@mixin::A
          previousFragment: #F1
          nextFragment: #F5
          typeParameters
            #F4 T (nameOffset:30) (firstTokenOffset:30) (offset:30)
              element: #E0 T
              previousFragment: #F3
              nextFragment: #F6
        #F5 mixin A (nameOffset:50) (firstTokenOffset:36) (offset:50)
          element: <testLibrary>::@mixin::A
          previousFragment: #F2
          typeParameters
            #F6 T (nameOffset:52) (firstTokenOffset:52) (offset:52)
              element: #E0 T
              previousFragment: #F4
  mixins
    mixin A
      reference: <testLibrary>::@mixin::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F3
      superclassConstraints
        Object
''');
  }

  test_typeParameters_121() async {
    var library = await buildLibrary(r'''
mixin A<T> {}
augment mixin A<T, U> {}
augment mixin A<T> {}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      mixins
        #F1 mixin A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@mixin::A
          nextFragment: #F2
          typeParameters
            #F3 T (nameOffset:8) (firstTokenOffset:8) (offset:8)
              element: #E0 T
              nextFragment: #F4
        #F2 mixin A (nameOffset:28) (firstTokenOffset:14) (offset:28)
          element: <testLibrary>::@mixin::A
          previousFragment: #F1
          nextFragment: #F5
          typeParameters
            #F4 T (nameOffset:30) (firstTokenOffset:30) (offset:30)
              element: #E0 T
              previousFragment: #F3
              nextFragment: #F6
        #F5 mixin A (nameOffset:53) (firstTokenOffset:39) (offset:53)
          element: <testLibrary>::@mixin::A
          previousFragment: #F2
          typeParameters
            #F6 T (nameOffset:55) (firstTokenOffset:55) (offset:55)
              element: #E0 T
              previousFragment: #F4
  mixins
    mixin A
      reference: <testLibrary>::@mixin::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F3
      superclassConstraints
        Object
''');
  }

  test_typeParameters_212() async {
    var library = await buildLibrary(r'''
mixin A<T, U> {}
augment mixin A<T> {}
augment mixin A<T, U> {}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      mixins
        #F1 mixin A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@mixin::A
          nextFragment: #F2
          typeParameters
            #F3 T (nameOffset:8) (firstTokenOffset:8) (offset:8)
              element: #E0 T
              nextFragment: #F4
            #F5 U (nameOffset:11) (firstTokenOffset:11) (offset:11)
              element: #E1 U
              nextFragment: #F6
        #F2 mixin A (nameOffset:31) (firstTokenOffset:17) (offset:31)
          element: <testLibrary>::@mixin::A
          previousFragment: #F1
          nextFragment: #F7
          typeParameters
            #F4 T (nameOffset:33) (firstTokenOffset:33) (offset:33)
              element: #E0 T
              previousFragment: #F3
              nextFragment: #F8
            #F6 U (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
              element: #E1 U
              previousFragment: #F5
              nextFragment: #F9
        #F7 mixin A (nameOffset:53) (firstTokenOffset:39) (offset:53)
          element: <testLibrary>::@mixin::A
          previousFragment: #F2
          typeParameters
            #F8 T (nameOffset:55) (firstTokenOffset:55) (offset:55)
              element: #E0 T
              previousFragment: #F4
            #F9 U (nameOffset:58) (firstTokenOffset:58) (offset:58)
              element: #E1 U
              previousFragment: #F6
  mixins
    mixin A
      reference: <testLibrary>::@mixin::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F3
        #E1 U
          firstFragment: #F5
      superclassConstraints
        Object
''');
  }

  test_typeParameters_bounds_int_int() async {
    var library = await buildLibrary(r'''
mixin A<T extends int> {}
augment mixin A<T extends int> {}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      mixins
        #F1 mixin A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@mixin::A
          nextFragment: #F2
          typeParameters
            #F3 T (nameOffset:8) (firstTokenOffset:8) (offset:8)
              element: #E0 T
              nextFragment: #F4
        #F2 mixin A (nameOffset:40) (firstTokenOffset:26) (offset:40)
          element: <testLibrary>::@mixin::A
          previousFragment: #F1
          typeParameters
            #F4 T (nameOffset:42) (firstTokenOffset:42) (offset:42)
              element: #E0 T
              previousFragment: #F3
  mixins
    mixin A
      reference: <testLibrary>::@mixin::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F3
          bound: int
      superclassConstraints
        Object
''');
  }

  test_typeParameters_bounds_int_nothing() async {
    var library = await buildLibrary(r'''
mixin A<T extends int> {}
augment mixin A<T> {}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      mixins
        #F1 mixin A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@mixin::A
          nextFragment: #F2
          typeParameters
            #F3 T (nameOffset:8) (firstTokenOffset:8) (offset:8)
              element: #E0 T
              nextFragment: #F4
        #F2 mixin A (nameOffset:40) (firstTokenOffset:26) (offset:40)
          element: <testLibrary>::@mixin::A
          previousFragment: #F1
          typeParameters
            #F4 T (nameOffset:42) (firstTokenOffset:42) (offset:42)
              element: #E0 T
              previousFragment: #F3
  mixins
    mixin A
      reference: <testLibrary>::@mixin::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F3
          bound: int
      superclassConstraints
        Object
''');
  }

  test_typeParameters_bounds_int_string() async {
    var library = await buildLibrary(r'''
mixin A<T extends int> {}
augment mixin A<T extends String> {}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      mixins
        #F1 mixin A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@mixin::A
          nextFragment: #F2
          typeParameters
            #F3 T (nameOffset:8) (firstTokenOffset:8) (offset:8)
              element: #E0 T
              nextFragment: #F4
        #F2 mixin A (nameOffset:40) (firstTokenOffset:26) (offset:40)
          element: <testLibrary>::@mixin::A
          previousFragment: #F1
          typeParameters
            #F4 T (nameOffset:42) (firstTokenOffset:42) (offset:42)
              element: #E0 T
              previousFragment: #F3
  mixins
    mixin A
      reference: <testLibrary>::@mixin::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F3
          bound: int
      superclassConstraints
        Object
''');
  }

  test_typeParameters_bounds_nothing_int() async {
    var library = await buildLibrary(r'''
mixin A<T> {}
augment mixin A<T extends int> {}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      mixins
        #F1 mixin A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@mixin::A
          nextFragment: #F2
          typeParameters
            #F3 T (nameOffset:8) (firstTokenOffset:8) (offset:8)
              element: #E0 T
              nextFragment: #F4
        #F2 mixin A (nameOffset:28) (firstTokenOffset:14) (offset:28)
          element: <testLibrary>::@mixin::A
          previousFragment: #F1
          typeParameters
            #F4 T (nameOffset:30) (firstTokenOffset:30) (offset:30)
              element: #E0 T
              previousFragment: #F3
  mixins
    mixin A
      reference: <testLibrary>::@mixin::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F3
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
