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
    // TODO(scheglov): implement augmentation
    // defineReflectiveTests(MixinElementTest_augmentation_fromBytes);
    // defineReflectiveTests(MixinElementTest_augmentation_keepLinking);
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
    mixin M
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
          element: <testLibrary>::@class::A
      mixins
        mixin M @6
          reference: <testLibraryFragment>::@mixin::M
          element: <testLibrary>::@mixin::M
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
      supertype: Object
      mixins
        M
      allSupertypes
        M
        Object
  mixins
    mixin M
      reference: <testLibrary>::@mixin::M
      firstFragment: <testLibraryFragment>::@mixin::M
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
            covariant U @11
              defaultType: dynamic
          allSupertypes
            Object
        class B @23
          reference: <testLibraryFragment>::@class::B
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant T @25
              defaultType: dynamic
          supertype: A<int, T>
          allSupertypes
            A<int, T>
            Object
      mixins
        mixin M1 @56
          reference: <testLibraryFragment>::@mixin::M1
          enclosingElement3: <testLibraryFragment>
          superclassConstraints
            A<int, double>
          allSupertypes
            A<int, double>
            Object
        mixin M2 @86
          reference: <testLibraryFragment>::@mixin::M2
          enclosingElement3: <testLibraryFragment>
          superclassConstraints
            B<String>
          allSupertypes
            A<int, String>
            B<String>
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
          element: <testLibrary>::@class::A
          typeParameters
            T @8
              element: <not-implemented>
            U @11
              element: <not-implemented>
        class B @23
          reference: <testLibraryFragment>::@class::B
          element: <testLibrary>::@class::B
          typeParameters
            T @25
              element: <not-implemented>
      mixins
        mixin M1 @56
          reference: <testLibraryFragment>::@mixin::M1
          element: <testLibrary>::@mixin::M1
        mixin M2 @86
          reference: <testLibraryFragment>::@mixin::M2
          element: <testLibrary>::@mixin::M2
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
      typeParameters
        T
        U
      allSupertypes
        Object
    class B
      reference: <testLibrary>::@class::B
      firstFragment: <testLibraryFragment>::@class::B
      typeParameters
        T
      supertype: A<int, T>
      allSupertypes
        A<int, T>
        Object
  mixins
    mixin M1
      reference: <testLibrary>::@mixin::M1
      firstFragment: <testLibraryFragment>::@mixin::M1
      superclassConstraints
        A<int, double>
      allSupertypes
        A<int, double>
        Object
    mixin M2
      reference: <testLibrary>::@mixin::M2
      firstFragment: <testLibraryFragment>::@mixin::M2
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
        class B @17
          reference: <testLibraryFragment>::@class::B
          enclosingElement3: <testLibraryFragment>
          allSupertypes
            Object
        class C @28
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          allSupertypes
            Object
      mixins
        mixin M @40
          reference: <testLibraryFragment>::@mixin::M
          enclosingElement3: <testLibraryFragment>
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
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          element: <testLibrary>::@class::A
        class B @17
          reference: <testLibraryFragment>::@class::B
          element: <testLibrary>::@class::B
        class C @28
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
      mixins
        mixin M @40
          reference: <testLibraryFragment>::@mixin::M
          element: <testLibrary>::@mixin::M
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
      allSupertypes
        Object
    class B
      reference: <testLibrary>::@class::B
      firstFragment: <testLibraryFragment>::@class::B
      allSupertypes
        Object
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      allSupertypes
        Object
  mixins
    mixin M
      reference: <testLibrary>::@mixin::M
      firstFragment: <testLibraryFragment>::@mixin::M
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
          element: <testLibrary>::@class::A
        class B @33
          reference: <testLibraryFragment>::@class::B
          element: <testLibrary>::@class::B
      mixins
        mixin M @17
          reference: <testLibraryFragment>::@mixin::M
          element: <testLibrary>::@mixin::M
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
      allSupertypes
        Object
    class B
      reference: <testLibrary>::@class::B
      firstFragment: <testLibraryFragment>::@class::B
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
          element: <testLibrary>::@mixin::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      mixins
        mixin A @50
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          element: <testLibrary>::@mixin::A
          previousFragment: <testLibraryFragment>::@mixin::A
          nextFragment: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A
    <testLibrary>::@fragment::package:test/b.dart
      element: <testLibrary>
      enclosingFragment: <testLibrary>::@fragment::package:test/a.dart
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      mixins
        mixin A @32
          reference: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A
          element: <testLibrary>::@mixin::A
          previousFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
  mixins
    mixin A
      reference: <testLibrary>::@mixin::A
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
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      classes
        class A @36
          reference: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@def::0
          element: <testLibrary>::@class::A::@def::0
          constructors
            synthetic new
              reference: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@def::0::@constructor::new
              element: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@def::0::@constructor::new#element
              typeName: A
          methods
            foo1 @47
              reference: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@def::0::@method::foo1
              element: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@def::0::@method::foo1#element
        class A @66
          reference: <testLibrary>::@fragment::package:test/a.dart::@class::A
          element: <testLibrary>::@class::A::@def::1
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@def::1
          constructors
            synthetic new
              reference: <testLibrary>::@fragment::package:test/a.dart::@class::A::@constructor::new
              element: <testLibrary>::@fragment::package:test/a.dart::@class::A::@constructor::new#element
              typeName: A
          methods
            foo2 @77
              reference: <testLibrary>::@fragment::package:test/a.dart::@class::A::@method::foo2
              element: <testLibrary>::@fragment::package:test/a.dart::@class::A::@method::foo2#element
        class A @104
          reference: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@def::1
          element: <testLibrary>::@class::A::@def::1
          previousFragment: <testLibrary>::@fragment::package:test/a.dart::@class::A
          methods
            foo3 @115
              reference: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@def::1::@method::foo3
              element: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@def::1::@method::foo3#element
  classes
    class A
      reference: <testLibrary>::@class::A::@def::0
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@def::0
      constructors
        synthetic new
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@def::0::@constructor::new
      methods
        foo1
          reference: <testLibrary>::@class::A::@def::0::@method::foo1
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@def::0::@method::foo1
    class A
      reference: <testLibrary>::@class::A::@def::1
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@class::A
      constructors
        synthetic new
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@class::A::@constructor::new
      methods
        foo2
          reference: <testLibrary>::@class::A::@def::1::@method::foo2
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@class::A::@method::foo2
        foo3
          reference: <testLibrary>::@class::A::@def::1::@method::foo3
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
          element: <testLibrary>::@mixin::B
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      mixins
        mixin A @50
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          element: <testLibrary>::@mixin::A
          nextFragment: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A
          methods
            foo1 @61
              reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@method::foo1
              element: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@method::foo1#element
    <testLibrary>::@fragment::package:test/b.dart
      element: <testLibrary>
      enclosingFragment: <testLibrary>::@fragment::package:test/a.dart
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      mixins
        mixin A @32
          reference: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A
          element: <testLibrary>::@mixin::A
          previousFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          methods
            foo2 @43
              reference: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A::@method::foo2
              element: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A::@method::foo2#element
  mixins
    mixin B
      reference: <testLibrary>::@mixin::B
      firstFragment: <testLibraryFragment>::@mixin::B
      superclassConstraints
        Object
    mixin A
      reference: <testLibrary>::@mixin::A
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
      superclassConstraints
        Object
      methods
        foo1
          reference: <testLibrary>::@mixin::A::@method::foo1
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@method::foo1
        foo2
          reference: <testLibrary>::@mixin::A::@method::foo2
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
          element: <testLibrary>::@mixin::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          fields
            hasInitializer foo @31
              reference: <testLibraryFragment>::@mixin::A::@field::foo
              element: <testLibraryFragment>::@mixin::A::@field::foo#element
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@fieldAugmentation::foo
              getter2: <testLibraryFragment>::@mixin::A::@getter::foo
              setter2: <testLibraryFragment>::@mixin::A::@setter::foo
          getters
            synthetic get foo
              reference: <testLibraryFragment>::@mixin::A::@getter::foo
              element: <testLibraryFragment>::@mixin::A::@getter::foo#element
          setters
            synthetic set foo
              reference: <testLibraryFragment>::@mixin::A::@setter::foo
              element: <testLibraryFragment>::@mixin::A::@setter::foo#element
              formalParameters
                _foo
                  element: <testLibraryFragment>::@mixin::A::@setter::foo::@parameter::_foo#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      mixins
        mixin A @35
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          element: <testLibrary>::@mixin::A
          previousFragment: <testLibraryFragment>::@mixin::A
          fields
            augment hasInitializer foo @53
              reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@fieldAugmentation::foo
              element: <testLibraryFragment>::@mixin::A::@field::foo#element
              previousFragment: <testLibraryFragment>::@mixin::A::@field::foo
  mixins
    mixin A
      reference: <testLibrary>::@mixin::A
      firstFragment: <testLibraryFragment>::@mixin::A
      superclassConstraints
        Object
      fields
        hasInitializer foo
          firstFragment: <testLibraryFragment>::@mixin::A::@field::foo
          type: int
          getter: <testLibraryFragment>::@mixin::A::@getter::foo#element
          setter: <testLibraryFragment>::@mixin::A::@setter::foo#element
      getters
        synthetic get foo
          firstFragment: <testLibraryFragment>::@mixin::A::@getter::foo
      setters
        synthetic set foo
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
          element: <testLibrary>::@mixin::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          fields
            hasInitializer foo @46
              reference: <testLibraryFragment>::@mixin::A::@field::foo
              element: <testLibraryFragment>::@mixin::A::@field::foo#element
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@fieldAugmentation::foo
              getter2: <testLibraryFragment>::@mixin::A::@getter::foo
              setter2: <testLibraryFragment>::@mixin::A::@setter::foo
          getters
            synthetic get foo
              reference: <testLibraryFragment>::@mixin::A::@getter::foo
              element: <testLibraryFragment>::@mixin::A::@getter::foo#element
          setters
            synthetic set foo
              reference: <testLibraryFragment>::@mixin::A::@setter::foo
              element: <testLibraryFragment>::@mixin::A::@setter::foo#element
              formalParameters
                _foo
                  element: <testLibraryFragment>::@mixin::A::@setter::foo::@parameter::_foo#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      mixins
        mixin A @35
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          element: <testLibrary>::@mixin::A
          previousFragment: <testLibraryFragment>::@mixin::A
          nextFragment: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A
          fields
            augment hasInitializer foo @53
              reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@fieldAugmentation::foo
              element: <testLibraryFragment>::@mixin::A::@field::foo#element
              previousFragment: <testLibraryFragment>::@mixin::A::@field::foo
              nextFragment: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A::@fieldAugmentation::foo
    <testLibrary>::@fragment::package:test/b.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      mixins
        mixin A @35
          reference: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A
          element: <testLibrary>::@mixin::A
          previousFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          fields
            augment hasInitializer foo @53
              reference: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A::@fieldAugmentation::foo
              element: <testLibraryFragment>::@mixin::A::@field::foo#element
              previousFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@fieldAugmentation::foo
  mixins
    mixin A
      reference: <testLibrary>::@mixin::A
      firstFragment: <testLibraryFragment>::@mixin::A
      superclassConstraints
        Object
      fields
        hasInitializer foo
          firstFragment: <testLibraryFragment>::@mixin::A::@field::foo
          type: int
          getter: <testLibraryFragment>::@mixin::A::@getter::foo#element
          setter: <testLibraryFragment>::@mixin::A::@setter::foo#element
      getters
        synthetic get foo
          firstFragment: <testLibraryFragment>::@mixin::A::@getter::foo
      setters
        synthetic set foo
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
              variable: <null>
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
          element: <testLibrary>::@mixin::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          fields
            hasInitializer foo @46
              reference: <testLibraryFragment>::@mixin::A::@field::foo
              element: <testLibraryFragment>::@mixin::A::@field::foo#element
              nextFragment: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A::@fieldAugmentation::foo
              getter2: <testLibraryFragment>::@mixin::A::@getter::foo
              setter2: <testLibraryFragment>::@mixin::A::@setter::foo
          getters
            synthetic get foo
              reference: <testLibraryFragment>::@mixin::A::@getter::foo
              element: <testLibraryFragment>::@mixin::A::@getter::foo#element
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@getterAugmentation::foo
          setters
            synthetic set foo
              reference: <testLibraryFragment>::@mixin::A::@setter::foo
              element: <testLibraryFragment>::@mixin::A::@setter::foo#element
              formalParameters
                _foo
                  element: <testLibraryFragment>::@mixin::A::@setter::foo::@parameter::_foo#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      mixins
        mixin A @35
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          element: <testLibrary>::@mixin::A
          previousFragment: <testLibraryFragment>::@mixin::A
          nextFragment: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A
          getters
            augment get foo @57
              reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@getterAugmentation::foo
              element: <testLibraryFragment>::@mixin::A::@getter::foo#element
              previousFragment: <testLibraryFragment>::@mixin::A::@getter::foo
    <testLibrary>::@fragment::package:test/b.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      mixins
        mixin A @35
          reference: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A
          element: <testLibrary>::@mixin::A
          previousFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          fields
            augment hasInitializer foo @53
              reference: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A::@fieldAugmentation::foo
              element: <testLibraryFragment>::@mixin::A::@field::foo#element
              previousFragment: <testLibraryFragment>::@mixin::A::@field::foo
  mixins
    mixin A
      reference: <testLibrary>::@mixin::A
      firstFragment: <testLibraryFragment>::@mixin::A
      superclassConstraints
        Object
      fields
        hasInitializer foo
          firstFragment: <testLibraryFragment>::@mixin::A::@field::foo
          type: int
          getter: <testLibraryFragment>::@mixin::A::@getter::foo#element
          setter: <testLibraryFragment>::@mixin::A::@setter::foo#element
      getters
        synthetic get foo
          firstFragment: <testLibraryFragment>::@mixin::A::@getter::foo
      setters
        synthetic set foo
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
              variable: <null>
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
          element: <testLibrary>::@mixin::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          fields
            hasInitializer foo @46
              reference: <testLibraryFragment>::@mixin::A::@field::foo
              element: <testLibraryFragment>::@mixin::A::@field::foo#element
              nextFragment: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A::@fieldAugmentation::foo
              getter2: <testLibraryFragment>::@mixin::A::@getter::foo
              setter2: <testLibraryFragment>::@mixin::A::@setter::foo
          getters
            synthetic get foo
              reference: <testLibraryFragment>::@mixin::A::@getter::foo
              element: <testLibraryFragment>::@mixin::A::@getter::foo#element
          setters
            synthetic set foo
              reference: <testLibraryFragment>::@mixin::A::@setter::foo
              element: <testLibraryFragment>::@mixin::A::@setter::foo#element
              formalParameters
                _foo
                  element: <testLibraryFragment>::@mixin::A::@setter::foo::@parameter::_foo#element
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@setterAugmentation::foo
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      mixins
        mixin A @35
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          element: <testLibrary>::@mixin::A
          previousFragment: <testLibraryFragment>::@mixin::A
          nextFragment: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A
          setters
            augment set foo @53
              reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@setterAugmentation::foo
              element: <testLibraryFragment>::@mixin::A::@setter::foo#element
              formalParameters
                _ @61
                  element: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@setterAugmentation::foo::@parameter::_#element
              previousFragment: <testLibraryFragment>::@mixin::A::@setter::foo
    <testLibrary>::@fragment::package:test/b.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      mixins
        mixin A @35
          reference: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A
          element: <testLibrary>::@mixin::A
          previousFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          fields
            augment hasInitializer foo @53
              reference: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A::@fieldAugmentation::foo
              element: <testLibraryFragment>::@mixin::A::@field::foo#element
              previousFragment: <testLibraryFragment>::@mixin::A::@field::foo
  mixins
    mixin A
      reference: <testLibrary>::@mixin::A
      firstFragment: <testLibraryFragment>::@mixin::A
      superclassConstraints
        Object
      fields
        hasInitializer foo
          firstFragment: <testLibraryFragment>::@mixin::A::@field::foo
          type: int
          getter: <testLibraryFragment>::@mixin::A::@getter::foo#element
          setter: <testLibraryFragment>::@mixin::A::@setter::foo#element
      getters
        synthetic get foo
          firstFragment: <testLibraryFragment>::@mixin::A::@getter::foo
      setters
        synthetic set foo
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
          element: <testLibrary>::@mixin::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          fields
            hasInitializer foo @31
              reference: <testLibraryFragment>::@mixin::A::@field::foo
              element: <testLibraryFragment>::@mixin::A::@field::foo#element
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@fieldAugmentation::foo
              getter2: <testLibraryFragment>::@mixin::A::@getter::foo
              setter2: <testLibraryFragment>::@mixin::A::@setter::foo
          getters
            synthetic get foo
              reference: <testLibraryFragment>::@mixin::A::@getter::foo
              element: <testLibraryFragment>::@mixin::A::@getter::foo#element
          setters
            synthetic set foo
              reference: <testLibraryFragment>::@mixin::A::@setter::foo
              element: <testLibraryFragment>::@mixin::A::@setter::foo#element
              formalParameters
                _foo
                  element: <testLibraryFragment>::@mixin::A::@setter::foo::@parameter::_foo#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      mixins
        mixin A @35
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          element: <testLibrary>::@mixin::A
          previousFragment: <testLibraryFragment>::@mixin::A
          fields
            augment hasInitializer foo @56
              reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@fieldAugmentation::foo
              element: <testLibraryFragment>::@mixin::A::@field::foo#element
              previousFragment: <testLibraryFragment>::@mixin::A::@field::foo
  mixins
    mixin A
      reference: <testLibrary>::@mixin::A
      firstFragment: <testLibraryFragment>::@mixin::A
      superclassConstraints
        Object
      fields
        hasInitializer foo
          firstFragment: <testLibraryFragment>::@mixin::A::@field::foo
          type: int
          getter: <testLibraryFragment>::@mixin::A::@getter::foo#element
          setter: <testLibraryFragment>::@mixin::A::@setter::foo#element
      getters
        synthetic get foo
          firstFragment: <testLibraryFragment>::@mixin::A::@getter::foo
      setters
        synthetic set foo
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
          element: <testLibrary>::@mixin::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          fields
            synthetic foo
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
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      mixins
        mixin A @35
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          element: <testLibrary>::@mixin::A
          previousFragment: <testLibraryFragment>::@mixin::A
          fields
            augment hasInitializer foo @53
              reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@fieldAugmentation::foo
              element: <testLibraryFragment>::@mixin::A::@field::foo#element
              previousFragment: <testLibraryFragment>::@mixin::A::@field::foo
  mixins
    mixin A
      reference: <testLibrary>::@mixin::A
      firstFragment: <testLibraryFragment>::@mixin::A
      superclassConstraints
        Object
      fields
        synthetic hasInitializer foo
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
          element: <testLibrary>::@mixin::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          fields
            hasInitializer foo1 @31
              reference: <testLibraryFragment>::@mixin::A::@field::foo1
              element: <testLibraryFragment>::@mixin::A::@field::foo1#element
              getter2: <testLibraryFragment>::@mixin::A::@getter::foo1
              setter2: <testLibraryFragment>::@mixin::A::@setter::foo1
          getters
            synthetic get foo1
              reference: <testLibraryFragment>::@mixin::A::@getter::foo1
              element: <testLibraryFragment>::@mixin::A::@getter::foo1#element
          setters
            synthetic set foo1
              reference: <testLibraryFragment>::@mixin::A::@setter::foo1
              element: <testLibraryFragment>::@mixin::A::@setter::foo1#element
              formalParameters
                _foo1
                  element: <testLibraryFragment>::@mixin::A::@setter::foo1::@parameter::_foo1#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      mixins
        mixin A @35
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          element: <testLibrary>::@mixin::A
          previousFragment: <testLibraryFragment>::@mixin::A
          fields
            hasInitializer foo2 @45
              reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@field::foo2
              element: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@field::foo2#element
              getter2: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@getter::foo2
              setter2: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@setter::foo2
          getters
            synthetic get foo2
              reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@getter::foo2
              element: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@getter::foo2#element
          setters
            synthetic set foo2
              reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@setter::foo2
              element: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@setter::foo2#element
              formalParameters
                _foo2
                  element: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@setter::foo2::@parameter::_foo2#element
  mixins
    mixin A
      reference: <testLibrary>::@mixin::A
      firstFragment: <testLibraryFragment>::@mixin::A
      superclassConstraints
        Object
      fields
        hasInitializer foo1
          firstFragment: <testLibraryFragment>::@mixin::A::@field::foo1
          type: int
          getter: <testLibraryFragment>::@mixin::A::@getter::foo1#element
          setter: <testLibraryFragment>::@mixin::A::@setter::foo1#element
        hasInitializer foo2
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
        synthetic set foo1
          firstFragment: <testLibraryFragment>::@mixin::A::@setter::foo1
          formalParameters
            requiredPositional _foo1
              type: int
        synthetic set foo2
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
          element: <testLibrary>::@mixin::A
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
            synthetic get foo1
              reference: <testLibraryFragment>::@mixin::A::@getter::foo1
              element: <testLibraryFragment>::@mixin::A::@getter::foo1#element
          setters
            synthetic set foo1
              reference: <testLibraryFragment>::@mixin::A::@setter::foo1
              element: <testLibraryFragment>::@mixin::A::@setter::foo1#element
              formalParameters
                _foo1
                  element: <testLibraryFragment>::@mixin::A::@setter::foo1::@parameter::_foo1#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      mixins
        mixin A @35
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          element: <testLibrary>::@mixin::A
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
            synthetic get foo2
              reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@getter::foo2
              element: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@getter::foo2#element
          setters
            synthetic set foo2
              reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@setter::foo2
              element: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@setter::foo2#element
              formalParameters
                _foo2
                  element: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@setter::foo2::@parameter::_foo2#element
  mixins
    mixin A
      reference: <testLibrary>::@mixin::A
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
        synthetic set foo1
          firstFragment: <testLibraryFragment>::@mixin::A::@setter::foo1
          formalParameters
            requiredPositional _foo1
              type: T1
        synthetic set foo2
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
          element: <testLibrary>::@mixin::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          fields
            synthetic foo1
              reference: <testLibraryFragment>::@mixin::A::@field::foo1
              element: <testLibraryFragment>::@mixin::A::@field::foo1#element
              getter2: <testLibraryFragment>::@mixin::A::@getter::foo1
          getters
            get foo1 @35
              reference: <testLibraryFragment>::@mixin::A::@getter::foo1
              element: <testLibraryFragment>::@mixin::A::@getter::foo1#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      mixins
        mixin A @35
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          element: <testLibrary>::@mixin::A
          previousFragment: <testLibraryFragment>::@mixin::A
          fields
            synthetic foo2
              reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@field::foo2
              element: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@field::foo2#element
              getter2: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@getter::foo2
          getters
            get foo2 @49
              reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@getter::foo2
              element: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@getter::foo2#element
  mixins
    mixin A
      reference: <testLibrary>::@mixin::A
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
          element: <testLibrary>::@mixin::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          typeParameters
            T1 @23
              element: <not-implemented>
          fields
            synthetic foo1
              reference: <testLibraryFragment>::@mixin::A::@field::foo1
              element: <testLibraryFragment>::@mixin::A::@field::foo1#element
              getter2: <testLibraryFragment>::@mixin::A::@getter::foo1
          getters
            get foo1 @38
              reference: <testLibraryFragment>::@mixin::A::@getter::foo1
              element: <testLibraryFragment>::@mixin::A::@getter::foo1#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      mixins
        mixin A @35
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          element: <testLibrary>::@mixin::A
          previousFragment: <testLibraryFragment>::@mixin::A
          typeParameters
            T1 @37
              element: <not-implemented>
          fields
            synthetic foo2
              reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@field::foo2
              element: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@field::foo2#element
              getter2: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@getter::foo2
          getters
            get foo2 @52
              reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@getter::foo2
              element: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@getter::foo2#element
  mixins
    mixin A
      reference: <testLibrary>::@mixin::A
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
              variable: <null>
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
          element: <testLibrary>::@mixin::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          fields
            hasInitializer foo @31
              reference: <testLibraryFragment>::@mixin::A::@field::foo
              element: <testLibraryFragment>::@mixin::A::@field::foo#element
              getter2: <testLibraryFragment>::@mixin::A::@getter::foo
              setter2: <testLibraryFragment>::@mixin::A::@setter::foo
          getters
            synthetic get foo
              reference: <testLibraryFragment>::@mixin::A::@getter::foo
              element: <testLibraryFragment>::@mixin::A::@getter::foo#element
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@getterAugmentation::foo
          setters
            synthetic set foo
              reference: <testLibraryFragment>::@mixin::A::@setter::foo
              element: <testLibraryFragment>::@mixin::A::@setter::foo#element
              formalParameters
                _foo
                  element: <testLibraryFragment>::@mixin::A::@setter::foo::@parameter::_foo#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      mixins
        mixin A @35
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          element: <testLibrary>::@mixin::A
          previousFragment: <testLibraryFragment>::@mixin::A
          getters
            augment get foo @57
              reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@getterAugmentation::foo
              element: <testLibraryFragment>::@mixin::A::@getter::foo#element
              previousFragment: <testLibraryFragment>::@mixin::A::@getter::foo
  mixins
    mixin A
      reference: <testLibrary>::@mixin::A
      firstFragment: <testLibraryFragment>::@mixin::A
      superclassConstraints
        Object
      fields
        hasInitializer foo
          firstFragment: <testLibraryFragment>::@mixin::A::@field::foo
          type: int
          getter: <testLibraryFragment>::@mixin::A::@getter::foo#element
          setter: <testLibraryFragment>::@mixin::A::@setter::foo#element
      getters
        synthetic get foo
          firstFragment: <testLibraryFragment>::@mixin::A::@getter::foo
      setters
        synthetic set foo
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
              variable: <null>
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
              variable: <null>
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
          element: <testLibrary>::@mixin::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          fields
            hasInitializer foo @46
              reference: <testLibraryFragment>::@mixin::A::@field::foo
              element: <testLibraryFragment>::@mixin::A::@field::foo#element
              getter2: <testLibraryFragment>::@mixin::A::@getter::foo
              setter2: <testLibraryFragment>::@mixin::A::@setter::foo
          getters
            synthetic get foo
              reference: <testLibraryFragment>::@mixin::A::@getter::foo
              element: <testLibraryFragment>::@mixin::A::@getter::foo#element
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@getterAugmentation::foo
          setters
            synthetic set foo
              reference: <testLibraryFragment>::@mixin::A::@setter::foo
              element: <testLibraryFragment>::@mixin::A::@setter::foo#element
              formalParameters
                _foo
                  element: <testLibraryFragment>::@mixin::A::@setter::foo::@parameter::_foo#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      mixins
        mixin A @35
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          element: <testLibrary>::@mixin::A
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
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      mixins
        mixin A @35
          reference: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A
          element: <testLibrary>::@mixin::A
          previousFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          getters
            augment get foo @57
              reference: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A::@getterAugmentation::foo
              element: <testLibraryFragment>::@mixin::A::@getter::foo#element
              previousFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@getterAugmentation::foo
  mixins
    mixin A
      reference: <testLibrary>::@mixin::A
      firstFragment: <testLibraryFragment>::@mixin::A
      superclassConstraints
        Object
      fields
        hasInitializer foo
          firstFragment: <testLibraryFragment>::@mixin::A::@field::foo
          type: int
          getter: <testLibraryFragment>::@mixin::A::@getter::foo#element
          setter: <testLibraryFragment>::@mixin::A::@setter::foo#element
      getters
        synthetic get foo
          firstFragment: <testLibraryFragment>::@mixin::A::@getter::foo
      setters
        synthetic set foo
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
              variable: <null>
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
          element: <testLibrary>::@mixin::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          fields
            synthetic foo1
              reference: <testLibraryFragment>::@mixin::A::@field::foo1
              element: <testLibraryFragment>::@mixin::A::@field::foo1#element
              getter2: <testLibraryFragment>::@mixin::A::@getter::foo1
            synthetic foo2
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
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      mixins
        mixin A @35
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          element: <testLibrary>::@mixin::A
          previousFragment: <testLibraryFragment>::@mixin::A
          getters
            augment get foo1 @57
              reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@getterAugmentation::foo1
              element: <testLibraryFragment>::@mixin::A::@getter::foo1#element
              previousFragment: <testLibraryFragment>::@mixin::A::@getter::foo1
  mixins
    mixin A
      reference: <testLibrary>::@mixin::A
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
              variable: <null>
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
              variable: <null>
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
          element: <testLibrary>::@mixin::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          fields
            synthetic foo
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
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      mixins
        mixin A @35
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          element: <testLibrary>::@mixin::A
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
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      mixins
        mixin A @35
          reference: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A
          element: <testLibrary>::@mixin::A
          previousFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          getters
            augment get foo @57
              reference: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A::@getterAugmentation::foo
              element: <testLibraryFragment>::@mixin::A::@getter::foo#element
              previousFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@getterAugmentation::foo
  mixins
    mixin A
      reference: <testLibrary>::@mixin::A
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
          element: <testLibrary>::@class::I1
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::I1::@constructor::new
              element: <testLibraryFragment>::@class::I1::@constructor::new#element
              typeName: I1
      mixins
        mixin A @21
          reference: <testLibraryFragment>::@mixin::A
          element: <testLibrary>::@mixin::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      classes
        class I2 @60
          reference: <testLibrary>::@fragment::package:test/a.dart::@class::I2
          element: <testLibrary>::@class::I2
          constructors
            synthetic new
              reference: <testLibrary>::@fragment::package:test/a.dart::@class::I2::@constructor::new
              element: <testLibrary>::@fragment::package:test/a.dart::@class::I2::@constructor::new#element
              typeName: I2
      mixins
        mixin A @35
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          element: <testLibrary>::@mixin::A
          previousFragment: <testLibraryFragment>::@mixin::A
  classes
    class I1
      reference: <testLibrary>::@class::I1
      firstFragment: <testLibraryFragment>::@class::I1
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::I1::@constructor::new
    class I2
      reference: <testLibrary>::@class::I2
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@class::I2
      constructors
        synthetic new
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@class::I2::@constructor::new
  mixins
    mixin A
      reference: <testLibrary>::@mixin::A
      firstFragment: <testLibraryFragment>::@mixin::A
      superclassConstraints
        Object
      interfaces
        I1
        I2
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
          element: <testLibrary>::@class::I1
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::I1::@constructor::new
              element: <testLibraryFragment>::@class::I1::@constructor::new#element
              typeName: I1
      mixins
        mixin A @21
          reference: <testLibraryFragment>::@mixin::A
          element: <testLibrary>::@mixin::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      classes
        class I2 @75
          reference: <testLibrary>::@fragment::package:test/a.dart::@class::I2
          element: <testLibrary>::@class::I2
          constructors
            synthetic new
              reference: <testLibrary>::@fragment::package:test/a.dart::@class::I2::@constructor::new
              element: <testLibrary>::@fragment::package:test/a.dart::@class::I2::@constructor::new#element
              typeName: I2
      mixins
        mixin A @50
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          element: <testLibrary>::@mixin::A
          previousFragment: <testLibraryFragment>::@mixin::A
          nextFragment: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A
    <testLibrary>::@fragment::package:test/b.dart
      element: <testLibrary>
      enclosingFragment: <testLibrary>::@fragment::package:test/a.dart
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      classes
        class I3 @57
          reference: <testLibrary>::@fragment::package:test/b.dart::@class::I3
          element: <testLibrary>::@class::I3
          constructors
            synthetic new
              reference: <testLibrary>::@fragment::package:test/b.dart::@class::I3::@constructor::new
              element: <testLibrary>::@fragment::package:test/b.dart::@class::I3::@constructor::new#element
              typeName: I3
      mixins
        mixin A @32
          reference: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A
          element: <testLibrary>::@mixin::A
          previousFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
  classes
    class I1
      reference: <testLibrary>::@class::I1
      firstFragment: <testLibraryFragment>::@class::I1
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::I1::@constructor::new
    class I2
      reference: <testLibrary>::@class::I2
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@class::I2
      constructors
        synthetic new
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@class::I2::@constructor::new
    class I3
      reference: <testLibrary>::@class::I3
      firstFragment: <testLibrary>::@fragment::package:test/b.dart::@class::I3
      constructors
        synthetic new
          firstFragment: <testLibrary>::@fragment::package:test/b.dart::@class::I3::@constructor::new
  mixins
    mixin A
      reference: <testLibrary>::@mixin::A
      firstFragment: <testLibraryFragment>::@mixin::A
      superclassConstraints
        Object
      interfaces
        I1
        I2
        I3
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
          element: <testLibrary>::@mixin::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          methods
            foo @32
              reference: <testLibraryFragment>::@mixin::A::@method::foo
              element: <testLibraryFragment>::@mixin::A::@method::foo#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      mixins
        mixin A @35
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          element: <testLibrary>::@mixin::A
          previousFragment: <testLibraryFragment>::@mixin::A
          methods
            bar @46
              reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@method::bar
              element: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@method::bar#element
  mixins
    mixin A
      reference: <testLibrary>::@mixin::A
      firstFragment: <testLibraryFragment>::@mixin::A
      superclassConstraints
        Object
      methods
        foo
          reference: <testLibrary>::@mixin::A::@method::foo
          firstFragment: <testLibraryFragment>::@mixin::A::@method::foo
        bar
          reference: <testLibrary>::@mixin::A::@method::bar
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
          element: <testLibrary>::@mixin::A
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
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      mixins
        mixin A @35
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          element: <testLibrary>::@mixin::A
          previousFragment: <testLibraryFragment>::@mixin::A
          methods
            augment foo1 @54
              reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@methodAugmentation::foo1
              element: <testLibraryFragment>::@mixin::A::@method::foo1#element
              previousFragment: <testLibraryFragment>::@mixin::A::@method::foo1
  mixins
    mixin A
      reference: <testLibrary>::@mixin::A
      firstFragment: <testLibraryFragment>::@mixin::A
      superclassConstraints
        Object
      methods
        foo1
          reference: <testLibrary>::@mixin::A::@method::foo1
          firstFragment: <testLibraryFragment>::@mixin::A::@method::foo1
        foo2
          reference: <testLibrary>::@mixin::A::@method::foo2
          firstFragment: <testLibraryFragment>::@mixin::A::@method::foo2
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
          element: <testLibrary>::@mixin::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          methods
            foo @32
              reference: <testLibraryFragment>::@mixin::A::@method::foo
              element: <testLibraryFragment>::@mixin::A::@method::foo#element
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@methodAugmentation::foo
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      mixins
        mixin A @50
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          element: <testLibrary>::@mixin::A
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
      enclosingFragment: <testLibrary>::@fragment::package:test/a.dart
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      mixins
        mixin A @32
          reference: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A
          element: <testLibrary>::@mixin::A
          previousFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          methods
            augment foo @51
              reference: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A::@methodAugmentation::foo
              element: <testLibraryFragment>::@mixin::A::@method::foo#element
              previousFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@methodAugmentation::foo
  mixins
    mixin A
      reference: <testLibrary>::@mixin::A
      firstFragment: <testLibraryFragment>::@mixin::A
      superclassConstraints
        Object
      methods
        foo
          reference: <testLibrary>::@mixin::A::@method::foo
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
          element: <testLibrary>::@mixin::A
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
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      mixins
        mixin A @35
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          element: <testLibrary>::@mixin::A
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
      reference: <testLibrary>::@mixin::A
      firstFragment: <testLibraryFragment>::@mixin::A
      typeParameters
        T
      superclassConstraints
        Object
      methods
        foo
          reference: <testLibrary>::@mixin::A::@method::foo
          firstFragment: <testLibraryFragment>::@mixin::A::@method::foo
        bar
          reference: <testLibrary>::@mixin::A::@method::bar
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
          element: <testLibrary>::@mixin::A
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
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      mixins
        mixin A @35
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          element: <testLibrary>::@mixin::A
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
      reference: <testLibrary>::@mixin::A
      firstFragment: <testLibraryFragment>::@mixin::A
      typeParameters
        T
      superclassConstraints
        Object
      methods
        foo
          reference: <testLibrary>::@mixin::A::@method::foo
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
          element: <testLibrary>::@mixin::A
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
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      mixins
        mixin A @35
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          element: <testLibrary>::@mixin::A
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
      reference: <testLibrary>::@mixin::A
      firstFragment: <testLibraryFragment>::@mixin::A
      superclassConstraints
        Object
      methods
        foo
          reference: <testLibrary>::@mixin::A::@method::foo
          firstFragment: <testLibraryFragment>::@mixin::A::@method::foo
        bar
          reference: <testLibrary>::@mixin::A::@method::bar
          firstFragment: <testLibraryFragment>::@mixin::A::@method::bar
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
          element: <testLibrary>::@mixin::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          fields
            synthetic foo1
              reference: <testLibraryFragment>::@mixin::A::@field::foo1
              element: <testLibraryFragment>::@mixin::A::@field::foo1#element
              setter2: <testLibraryFragment>::@mixin::A::@setter::foo1
          setters
            set foo1 @31
              reference: <testLibraryFragment>::@mixin::A::@setter::foo1
              element: <testLibraryFragment>::@mixin::A::@setter::foo1#element
              formalParameters
                _ @40
                  element: <testLibraryFragment>::@mixin::A::@setter::foo1::@parameter::_#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      mixins
        mixin A @35
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          element: <testLibrary>::@mixin::A
          previousFragment: <testLibraryFragment>::@mixin::A
          fields
            synthetic foo2
              reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@field::foo2
              element: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@field::foo2#element
              setter2: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@setter::foo2
          setters
            set foo2 @45
              reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@setter::foo2
              element: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@setter::foo2#element
              formalParameters
                _ @54
                  element: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@setter::foo2::@parameter::_#element
  mixins
    mixin A
      reference: <testLibrary>::@mixin::A
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
        set foo1
          firstFragment: <testLibraryFragment>::@mixin::A::@setter::foo1
          formalParameters
            requiredPositional _
              type: int
        set foo2
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
              variable: <null>
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
          element: <testLibrary>::@mixin::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          fields
            hasInitializer foo @31
              reference: <testLibraryFragment>::@mixin::A::@field::foo
              element: <testLibraryFragment>::@mixin::A::@field::foo#element
              getter2: <testLibraryFragment>::@mixin::A::@getter::foo
              setter2: <testLibraryFragment>::@mixin::A::@setter::foo
          getters
            synthetic get foo
              reference: <testLibraryFragment>::@mixin::A::@getter::foo
              element: <testLibraryFragment>::@mixin::A::@getter::foo#element
          setters
            synthetic set foo
              reference: <testLibraryFragment>::@mixin::A::@setter::foo
              element: <testLibraryFragment>::@mixin::A::@setter::foo#element
              formalParameters
                _foo
                  element: <testLibraryFragment>::@mixin::A::@setter::foo::@parameter::_foo#element
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@setterAugmentation::foo
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      mixins
        mixin A @35
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          element: <testLibrary>::@mixin::A
          previousFragment: <testLibraryFragment>::@mixin::A
          setters
            augment set foo @53
              reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@setterAugmentation::foo
              element: <testLibraryFragment>::@mixin::A::@setter::foo#element
              formalParameters
                _ @61
                  element: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@setterAugmentation::foo::@parameter::_#element
              previousFragment: <testLibraryFragment>::@mixin::A::@setter::foo
  mixins
    mixin A
      reference: <testLibrary>::@mixin::A
      firstFragment: <testLibraryFragment>::@mixin::A
      superclassConstraints
        Object
      fields
        hasInitializer foo
          firstFragment: <testLibraryFragment>::@mixin::A::@field::foo
          type: int
          getter: <testLibraryFragment>::@mixin::A::@getter::foo#element
          setter: <testLibraryFragment>::@mixin::A::@setter::foo#element
      getters
        synthetic get foo
          firstFragment: <testLibraryFragment>::@mixin::A::@getter::foo
      setters
        synthetic set foo
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
              variable: <null>
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
          element: <testLibrary>::@mixin::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          fields
            synthetic foo1
              reference: <testLibraryFragment>::@mixin::A::@field::foo1
              element: <testLibraryFragment>::@mixin::A::@field::foo1#element
              setter2: <testLibraryFragment>::@mixin::A::@setter::foo1
            synthetic foo2
              reference: <testLibraryFragment>::@mixin::A::@field::foo2
              element: <testLibraryFragment>::@mixin::A::@field::foo2#element
              setter2: <testLibraryFragment>::@mixin::A::@setter::foo2
          setters
            set foo1 @31
              reference: <testLibraryFragment>::@mixin::A::@setter::foo1
              element: <testLibraryFragment>::@mixin::A::@setter::foo1#element
              formalParameters
                _ @40
                  element: <testLibraryFragment>::@mixin::A::@setter::foo1::@parameter::_#element
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@setterAugmentation::foo1
            set foo2 @52
              reference: <testLibraryFragment>::@mixin::A::@setter::foo2
              element: <testLibraryFragment>::@mixin::A::@setter::foo2#element
              formalParameters
                _ @61
                  element: <testLibraryFragment>::@mixin::A::@setter::foo2::@parameter::_#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      mixins
        mixin A @35
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          element: <testLibrary>::@mixin::A
          previousFragment: <testLibraryFragment>::@mixin::A
          setters
            augment set foo1 @53
              reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@setterAugmentation::foo1
              element: <testLibraryFragment>::@mixin::A::@setter::foo1#element
              formalParameters
                _ @62
                  element: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@setterAugmentation::foo1::@parameter::_#element
              previousFragment: <testLibraryFragment>::@mixin::A::@setter::foo1
  mixins
    mixin A
      reference: <testLibrary>::@mixin::A
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
        set foo2
          firstFragment: <testLibraryFragment>::@mixin::A::@setter::foo2
          formalParameters
            requiredPositional _
              type: int
        set foo1
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
          element: <testLibrary>::@class::B1
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::B1::@constructor::new
              element: <testLibraryFragment>::@class::B1::@constructor::new#element
              typeName: B1
      mixins
        mixin A @21
          reference: <testLibraryFragment>::@mixin::A
          element: <testLibrary>::@mixin::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      classes
        class B2 @52
          reference: <testLibrary>::@fragment::package:test/a.dart::@class::B2
          element: <testLibrary>::@class::B2
          constructors
            synthetic new
              reference: <testLibrary>::@fragment::package:test/a.dart::@class::B2::@constructor::new
              element: <testLibrary>::@fragment::package:test/a.dart::@class::B2::@constructor::new#element
              typeName: B2
      mixins
        mixin A @35
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          element: <testLibrary>::@mixin::A
          previousFragment: <testLibraryFragment>::@mixin::A
  classes
    class B1
      reference: <testLibrary>::@class::B1
      firstFragment: <testLibraryFragment>::@class::B1
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::B1::@constructor::new
    class B2
      reference: <testLibrary>::@class::B2
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@class::B2
      constructors
        synthetic new
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@class::B2::@constructor::new
  mixins
    mixin A
      reference: <testLibrary>::@mixin::A
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
          element: <testLibrary>::@class::I1
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::I1::@constructor::new
              element: <testLibraryFragment>::@class::I1::@constructor::new#element
              typeName: I1
      mixins
        mixin A @21
          reference: <testLibraryFragment>::@mixin::A
          element: <testLibrary>::@mixin::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      classes
        class I2 @67
          reference: <testLibrary>::@fragment::package:test/a.dart::@class::I2
          element: <testLibrary>::@class::I2
          constructors
            synthetic new
              reference: <testLibrary>::@fragment::package:test/a.dart::@class::I2::@constructor::new
              element: <testLibrary>::@fragment::package:test/a.dart::@class::I2::@constructor::new#element
              typeName: I2
      mixins
        mixin A @50
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          element: <testLibrary>::@mixin::A
          previousFragment: <testLibraryFragment>::@mixin::A
          nextFragment: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A
    <testLibrary>::@fragment::package:test/b.dart
      element: <testLibrary>
      enclosingFragment: <testLibrary>::@fragment::package:test/a.dart
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      classes
        class I3 @49
          reference: <testLibrary>::@fragment::package:test/b.dart::@class::I3
          element: <testLibrary>::@class::I3
          constructors
            synthetic new
              reference: <testLibrary>::@fragment::package:test/b.dart::@class::I3::@constructor::new
              element: <testLibrary>::@fragment::package:test/b.dart::@class::I3::@constructor::new#element
              typeName: I3
      mixins
        mixin A @32
          reference: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A
          element: <testLibrary>::@mixin::A
          previousFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
  classes
    class I1
      reference: <testLibrary>::@class::I1
      firstFragment: <testLibraryFragment>::@class::I1
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::I1::@constructor::new
    class I2
      reference: <testLibrary>::@class::I2
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@class::I2
      constructors
        synthetic new
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@class::I2::@constructor::new
    class I3
      reference: <testLibrary>::@class::I3
      firstFragment: <testLibrary>::@fragment::package:test/b.dart::@class::I3
      constructors
        synthetic new
          firstFragment: <testLibrary>::@fragment::package:test/b.dart::@class::I3::@constructor::new
  mixins
    mixin A
      reference: <testLibrary>::@mixin::A
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
          element: <testLibrary>::@mixin::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      classes
        class B @51
          reference: <testLibrary>::@fragment::package:test/a.dart::@class::B
          element: <testLibrary>::@class::B
          constructors
            synthetic new
              reference: <testLibrary>::@fragment::package:test/a.dart::@class::B::@constructor::new
              element: <testLibrary>::@fragment::package:test/a.dart::@class::B::@constructor::new#element
              typeName: B
      mixins
        mixin A @35
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          element: <testLibrary>::@mixin::A
          previousFragment: <testLibraryFragment>::@mixin::A
  classes
    class B
      reference: <testLibrary>::@class::B
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@class::B
      constructors
        synthetic new
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@class::B::@constructor::new
  mixins
    mixin A
      reference: <testLibrary>::@mixin::A
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
          element: <testLibrary>::@class::I1
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::I1::@constructor::new
              element: <testLibraryFragment>::@class::I1::@constructor::new#element
              typeName: I1
      mixins
        mixin A @21
          reference: <testLibraryFragment>::@mixin::A
          element: <testLibrary>::@mixin::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          typeParameters
            T @23
              element: <not-implemented>
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      classes
        class I2 @60
          reference: <testLibrary>::@fragment::package:test/a.dart::@class::I2
          element: <testLibrary>::@class::I2
          typeParameters
            E @63
              element: <not-implemented>
          constructors
            synthetic new
              reference: <testLibrary>::@fragment::package:test/a.dart::@class::I2::@constructor::new
              element: <testLibrary>::@fragment::package:test/a.dart::@class::I2::@constructor::new#element
              typeName: I2
      mixins
        mixin A @35
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          element: <testLibrary>::@mixin::A
          previousFragment: <testLibraryFragment>::@mixin::A
          typeParameters
            T2 @37
              element: <not-implemented>
  classes
    class I1
      reference: <testLibrary>::@class::I1
      firstFragment: <testLibraryFragment>::@class::I1
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::I1::@constructor::new
    class I2
      reference: <testLibrary>::@class::I2
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@class::I2
      typeParameters
        E
      constructors
        synthetic new
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@class::I2::@constructor::new
  mixins
    mixin A
      reference: <testLibrary>::@mixin::A
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
          augmentation: <testLibrary>::@fragment::package:test/b.dart::@classAugmentation::A
          augmented
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement3: <testLibraryFragment>
      classes
        augment class A @36
          reference: <testLibrary>::@fragment::package:test/b.dart::@classAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/b.dart
          augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A
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
          element: <testLibrary>::@mixin::A
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      classes
        class A @36
          reference: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A
          element: <testLibrary>::@class::A
          nextFragment: <testLibrary>::@fragment::package:test/b.dart::@classAugmentation::A
    <testLibrary>::@fragment::package:test/b.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      classes
        class A @36
          reference: <testLibrary>::@fragment::package:test/b.dart::@classAugmentation::A
          element: <testLibrary>::@class::A
          previousFragment: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A
  mixins
    mixin A
      reference: <testLibrary>::@mixin::A
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
          augmentationTargetAny: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A
          superclassConstraints
            Object
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
          element: <testLibrary>::@mixin::A::@def::0
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      classes
        class A @36
          reference: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A
          element: <testLibrary>::@class::A
          constructors
            synthetic new
              reference: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@constructor::new
              element: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@constructor::new#element
              typeName: A
    <testLibrary>::@fragment::package:test/b.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      mixins
        mixin A @36
          reference: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A
          element: <testLibrary>::@mixin::A::@def::1
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A
      constructors
        synthetic new
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@constructor::new
  mixins
    mixin A
      reference: <testLibrary>::@mixin::A::@def::0
      firstFragment: <testLibraryFragment>::@mixin::A
      superclassConstraints
        Object
    mixin A
      reference: <testLibrary>::@mixin::A::@def::1
      firstFragment: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::A
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
  definingUnit: <testLibraryFragment>
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
                requiredPositional hasImplicitType a @45
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
          element: <testLibrary>::@mixin::B
          nextFragment: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::B
    <testLibrary>::@fragment::package:test/b.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      mixins
        mixin B @35
          reference: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::B
          element: <testLibrary>::@mixin::B
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
      reference: <testLibrary>::@mixin::B
      firstFragment: <testLibraryFragment>::@mixin::B
      superclassConstraints
        A
      methods
        foo
          reference: <testLibrary>::@mixin::B::@method::foo
          firstFragment: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::B::@method::foo
          formalParameters
            requiredPositional hasImplicitType a
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
                requiredPositional hasImplicitType a @32
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
          element: <testLibrary>::@mixin::B
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
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      libraryImports
        package:test/a.dart
      mixins
        mixin B @52
          reference: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::B
          element: <testLibrary>::@mixin::B
          previousFragment: <testLibraryFragment>::@mixin::B
  mixins
    mixin B
      reference: <testLibrary>::@mixin::B
      firstFragment: <testLibraryFragment>::@mixin::B
      superclassConstraints
        Object
      interfaces
        A
      methods
        foo
          reference: <testLibrary>::@mixin::B::@method::foo
          firstFragment: <testLibraryFragment>::@mixin::B::@method::foo
          formalParameters
            requiredPositional hasImplicitType a
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
                requiredPositional hasImplicitType a @32
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
          element: <testLibrary>::@mixin::B
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
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      libraryImports
        package:test/a.dart
      mixins
        mixin B @52
          reference: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::B
          element: <testLibrary>::@mixin::B
          previousFragment: <testLibraryFragment>::@mixin::B
  mixins
    mixin B
      reference: <testLibrary>::@mixin::B
      firstFragment: <testLibraryFragment>::@mixin::B
      superclassConstraints
        A
      methods
        foo
          reference: <testLibrary>::@mixin::B::@method::foo
          firstFragment: <testLibraryFragment>::@mixin::B::@method::foo
          formalParameters
            requiredPositional hasImplicitType a
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
  definingUnit: <testLibraryFragment>
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
                requiredPositional hasImplicitType a @54
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
                requiredPositional hasImplicitType a @53
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
          element: <testLibrary>::@mixin::B
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
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      mixins
        mixin B @35
          reference: <testLibrary>::@fragment::package:test/b.dart::@mixinAugmentation::B
          element: <testLibrary>::@mixin::B
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
      reference: <testLibrary>::@mixin::B
      firstFragment: <testLibraryFragment>::@mixin::B
      superclassConstraints
        A
      methods
        foo
          reference: <testLibrary>::@mixin::B::@method::foo
          firstFragment: <testLibraryFragment>::@mixin::B::@method::foo
          formalParameters
            requiredPositional hasImplicitType a
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
          element: <testLibrary>::@mixin::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      mixins
        mixin A @40
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          element: <testLibrary>::@mixin::A
          previousFragment: <testLibraryFragment>::@mixin::A
  mixins
    base mixin A
      reference: <testLibrary>::@mixin::A
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
            constructors
              <testLibraryFragment>::@class::I::@constructor::new
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
          element: <testLibrary>::@class::I
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::I::@constructor::new
              element: <testLibraryFragment>::@class::I::@constructor::new#element
              typeName: I
      mixins
        mixin A @6
          reference: <testLibraryFragment>::@mixin::A
          element: <testLibrary>::@mixin::A
  classes
    class I
      reference: <testLibrary>::@class::I
      firstFragment: <testLibraryFragment>::@class::I
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::I::@constructor::new
  mixins
    mixin A
      reference: <testLibrary>::@mixin::A
      firstFragment: <testLibraryFragment>::@mixin::A
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
            constructors
              <testLibraryFragment>::@class::B::@constructor::new
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
          element: <testLibrary>::@class::B
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::B::@constructor::new
              element: <testLibraryFragment>::@class::B::@constructor::new#element
              typeName: B
      mixins
        mixin A @6
          reference: <testLibraryFragment>::@mixin::A
          element: <testLibrary>::@mixin::A
  classes
    class B
      reference: <testLibrary>::@class::B
      firstFragment: <testLibraryFragment>::@class::B
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::B::@constructor::new
  mixins
    mixin A
      reference: <testLibrary>::@mixin::A
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
              defaultType: dynamic
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
          element: <testLibrary>::@mixin::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          typeParameters
            T @23
              element: <not-implemented>
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      mixins
        mixin A @35
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A
          element: <testLibrary>::@mixin::A
          previousFragment: <testLibraryFragment>::@mixin::A
          typeParameters
            T @37
              element: <not-implemented>
  mixins
    notSimplyBounded mixin A
      reference: <testLibrary>::@mixin::A
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
