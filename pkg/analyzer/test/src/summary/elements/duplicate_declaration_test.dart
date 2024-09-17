// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../dart/resolution/node_text_expectations.dart';
import '../elements_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DuplicateDeclarationElementTest_keepLinking);
    defineReflectiveTests(DuplicateDeclarationElementTest_fromBytes);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

abstract class DuplicateDeclarationElementTest extends ElementsBaseTest {
  test_duplicateDeclaration_class() async {
    var library = await buildLibrary(r'''
class A {
  static const f01 = 0;
  static const f02 = f01;
}

class A {
  static const f11 = 0;
  static const f12 = f11;
}

class A {
  static const f21 = 0;
  static const f22 = f21;
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
          reference: <testLibraryFragment>::@class::A::@def::0
          enclosingElement3: <testLibraryFragment>
          fields
            static const f01 @25
              reference: <testLibraryFragment>::@class::A::@def::0::@field::f01
              enclosingElement3: <testLibraryFragment>::@class::A::@def::0
              type: int
              shouldUseTypeForInitializerInference: false
              constantInitializer
                IntegerLiteral
                  literal: 0 @31
                  staticType: int
            static const f02 @49
              reference: <testLibraryFragment>::@class::A::@def::0::@field::f02
              enclosingElement3: <testLibraryFragment>::@class::A::@def::0
              type: int
              shouldUseTypeForInitializerInference: false
              constantInitializer
                SimpleIdentifier
                  token: f01 @55
                  staticElement: <testLibraryFragment>::@class::A::@def::0::@getter::f01
                  staticType: int
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::A::@def::0::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::A::@def::0
          accessors
            synthetic static get f01 @-1
              reference: <testLibraryFragment>::@class::A::@def::0::@getter::f01
              enclosingElement3: <testLibraryFragment>::@class::A::@def::0
              returnType: int
            synthetic static get f02 @-1
              reference: <testLibraryFragment>::@class::A::@def::0::@getter::f02
              enclosingElement3: <testLibraryFragment>::@class::A::@def::0
              returnType: int
        class A @69
          reference: <testLibraryFragment>::@class::A::@def::1
          enclosingElement3: <testLibraryFragment>
          fields
            static const f11 @88
              reference: <testLibraryFragment>::@class::A::@def::1::@field::f11
              enclosingElement3: <testLibraryFragment>::@class::A::@def::1
              type: int
              shouldUseTypeForInitializerInference: false
              constantInitializer
                IntegerLiteral
                  literal: 0 @94
                  staticType: int
            static const f12 @112
              reference: <testLibraryFragment>::@class::A::@def::1::@field::f12
              enclosingElement3: <testLibraryFragment>::@class::A::@def::1
              type: int
              shouldUseTypeForInitializerInference: false
              constantInitializer
                SimpleIdentifier
                  token: f11 @118
                  staticElement: <testLibraryFragment>::@class::A::@def::1::@getter::f11
                  staticType: int
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::A::@def::1::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::A::@def::1
          accessors
            synthetic static get f11 @-1
              reference: <testLibraryFragment>::@class::A::@def::1::@getter::f11
              enclosingElement3: <testLibraryFragment>::@class::A::@def::1
              returnType: int
            synthetic static get f12 @-1
              reference: <testLibraryFragment>::@class::A::@def::1::@getter::f12
              enclosingElement3: <testLibraryFragment>::@class::A::@def::1
              returnType: int
        class A @132
          reference: <testLibraryFragment>::@class::A::@def::2
          enclosingElement3: <testLibraryFragment>
          fields
            static const f21 @151
              reference: <testLibraryFragment>::@class::A::@def::2::@field::f21
              enclosingElement3: <testLibraryFragment>::@class::A::@def::2
              type: int
              shouldUseTypeForInitializerInference: false
              constantInitializer
                IntegerLiteral
                  literal: 0 @157
                  staticType: int
            static const f22 @175
              reference: <testLibraryFragment>::@class::A::@def::2::@field::f22
              enclosingElement3: <testLibraryFragment>::@class::A::@def::2
              type: int
              shouldUseTypeForInitializerInference: false
              constantInitializer
                SimpleIdentifier
                  token: f21 @181
                  staticElement: <testLibraryFragment>::@class::A::@def::2::@getter::f21
                  staticType: int
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::A::@def::2::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::A::@def::2
          accessors
            synthetic static get f21 @-1
              reference: <testLibraryFragment>::@class::A::@def::2::@getter::f21
              enclosingElement3: <testLibraryFragment>::@class::A::@def::2
              returnType: int
            synthetic static get f22 @-1
              reference: <testLibraryFragment>::@class::A::@def::2::@getter::f22
              enclosingElement3: <testLibraryFragment>::@class::A::@def::2
              returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A::@def::0
          element: <testLibraryFragment>::@class::A::@def::0
          fields
            f01 @25
              reference: <testLibraryFragment>::@class::A::@def::0::@field::f01
              element: <none>
              getter2: <testLibraryFragment>::@class::A::@def::0::@getter::f01
            f02 @49
              reference: <testLibraryFragment>::@class::A::@def::0::@field::f02
              element: <none>
              getter2: <testLibraryFragment>::@class::A::@def::0::@getter::f02
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::A::@def::0::@constructor::new
              element: <none>
          getters
            get f01 @-1
              reference: <testLibraryFragment>::@class::A::@def::0::@getter::f01
              element: <none>
            get f02 @-1
              reference: <testLibraryFragment>::@class::A::@def::0::@getter::f02
              element: <none>
        class A @69
          reference: <testLibraryFragment>::@class::A::@def::1
          element: <testLibraryFragment>::@class::A::@def::1
          fields
            f11 @88
              reference: <testLibraryFragment>::@class::A::@def::1::@field::f11
              element: <none>
              getter2: <testLibraryFragment>::@class::A::@def::1::@getter::f11
            f12 @112
              reference: <testLibraryFragment>::@class::A::@def::1::@field::f12
              element: <none>
              getter2: <testLibraryFragment>::@class::A::@def::1::@getter::f12
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::A::@def::1::@constructor::new
              element: <none>
          getters
            get f11 @-1
              reference: <testLibraryFragment>::@class::A::@def::1::@getter::f11
              element: <none>
            get f12 @-1
              reference: <testLibraryFragment>::@class::A::@def::1::@getter::f12
              element: <none>
        class A @132
          reference: <testLibraryFragment>::@class::A::@def::2
          element: <testLibraryFragment>::@class::A::@def::2
          fields
            f21 @151
              reference: <testLibraryFragment>::@class::A::@def::2::@field::f21
              element: <none>
              getter2: <testLibraryFragment>::@class::A::@def::2::@getter::f21
            f22 @175
              reference: <testLibraryFragment>::@class::A::@def::2::@field::f22
              element: <none>
              getter2: <testLibraryFragment>::@class::A::@def::2::@getter::f22
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::A::@def::2::@constructor::new
              element: <none>
          getters
            get f21 @-1
              reference: <testLibraryFragment>::@class::A::@def::2::@getter::f21
              element: <none>
            get f22 @-1
              reference: <testLibraryFragment>::@class::A::@def::2::@getter::f22
              element: <none>
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A::@def::0
      fields
        static const f01
          firstFragment: <testLibraryFragment>::@class::A::@def::0::@field::f01
          type: int
          getter: <none>
        static const f02
          firstFragment: <testLibraryFragment>::@class::A::@def::0::@field::f02
          type: int
          getter: <none>
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::A::@def::0::@constructor::new
      getters
        synthetic static get f01
          firstFragment: <testLibraryFragment>::@class::A::@def::0::@getter::f01
        synthetic static get f02
          firstFragment: <testLibraryFragment>::@class::A::@def::0::@getter::f02
    class A
      firstFragment: <testLibraryFragment>::@class::A::@def::1
      fields
        static const f11
          firstFragment: <testLibraryFragment>::@class::A::@def::1::@field::f11
          type: int
          getter: <none>
        static const f12
          firstFragment: <testLibraryFragment>::@class::A::@def::1::@field::f12
          type: int
          getter: <none>
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::A::@def::1::@constructor::new
      getters
        synthetic static get f11
          firstFragment: <testLibraryFragment>::@class::A::@def::1::@getter::f11
        synthetic static get f12
          firstFragment: <testLibraryFragment>::@class::A::@def::1::@getter::f12
    class A
      firstFragment: <testLibraryFragment>::@class::A::@def::2
      fields
        static const f21
          firstFragment: <testLibraryFragment>::@class::A::@def::2::@field::f21
          type: int
          getter: <none>
        static const f22
          firstFragment: <testLibraryFragment>::@class::A::@def::2::@field::f22
          type: int
          getter: <none>
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::A::@def::2::@constructor::new
      getters
        synthetic static get f21
          firstFragment: <testLibraryFragment>::@class::A::@def::2::@getter::f21
        synthetic static get f22
          firstFragment: <testLibraryFragment>::@class::A::@def::2::@getter::f22
''');
  }

  test_duplicateDeclaration_class_constructor_unnamed() async {
    var library = await buildLibrary(r'''
class A {
  A.named();
  A.named();
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
            named @14
              reference: <testLibraryFragment>::@class::A::@constructor::named::@def::0
              enclosingElement3: <testLibraryFragment>::@class::A
              periodOffset: 13
              nameEnd: 19
            named @27
              reference: <testLibraryFragment>::@class::A::@constructor::named::@def::1
              enclosingElement3: <testLibraryFragment>::@class::A
              periodOffset: 26
              nameEnd: 32
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A
          constructors
            named @14
              reference: <testLibraryFragment>::@class::A::@constructor::named::@def::0
              element: <none>
              periodOffset: 13
              nameEnd: 19
            named @27
              reference: <testLibraryFragment>::@class::A::@constructor::named::@def::1
              element: <none>
              periodOffset: 26
              nameEnd: 32
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        named
          firstFragment: <testLibraryFragment>::@class::A::@constructor::named::@def::0
        named
          firstFragment: <testLibraryFragment>::@class::A::@constructor::named::@def::1
''');
  }

  test_duplicateDeclaration_class_field() async {
    var library = await buildLibrary(r'''
class A {
  int foo;
  double foo;
}
''');
    configuration.withPropertyLinking = true;
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
          fields
            foo @16
              reference: <testLibraryFragment>::@class::A::@field::foo::@def::0
              enclosingElement3: <testLibraryFragment>::@class::A
              type: int
              id: field_0
              getter: getter_0
              setter: setter_0
            foo @30
              reference: <testLibraryFragment>::@class::A::@field::foo::@def::1
              enclosingElement3: <testLibraryFragment>::@class::A
              type: double
              id: field_1
              getter: getter_1
              setter: setter_1
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::A
          accessors
            synthetic get foo @-1
              reference: <testLibraryFragment>::@class::A::@getter::foo::@def::0
              enclosingElement3: <testLibraryFragment>::@class::A
              returnType: int
              id: getter_0
              variable: field_0
            synthetic set foo= @-1
              reference: <testLibraryFragment>::@class::A::@setter::foo::@def::0
              enclosingElement3: <testLibraryFragment>::@class::A
              parameters
                requiredPositional _foo @-1
                  type: int
              returnType: void
              id: setter_0
              variable: field_0
            synthetic get foo @-1
              reference: <testLibraryFragment>::@class::A::@getter::foo::@def::1
              enclosingElement3: <testLibraryFragment>::@class::A
              returnType: double
              id: getter_1
              variable: field_1
            synthetic set foo= @-1
              reference: <testLibraryFragment>::@class::A::@setter::foo::@def::1
              enclosingElement3: <testLibraryFragment>::@class::A
              parameters
                requiredPositional _foo @-1
                  type: double
              returnType: void
              id: setter_1
              variable: field_1
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A
          fields
            foo @16
              reference: <testLibraryFragment>::@class::A::@field::foo::@def::0
              element: <none>
              getter2: <testLibraryFragment>::@class::A::@getter::foo::@def::0
              setter2: <testLibraryFragment>::@class::A::@setter::foo::@def::0
            foo @30
              reference: <testLibraryFragment>::@class::A::@field::foo::@def::1
              element: <none>
              getter2: <testLibraryFragment>::@class::A::@getter::foo::@def::1
              setter2: <testLibraryFragment>::@class::A::@setter::foo::@def::1
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <none>
          getters
            get foo @-1
              reference: <testLibraryFragment>::@class::A::@getter::foo::@def::0
              element: <none>
            get foo @-1
              reference: <testLibraryFragment>::@class::A::@getter::foo::@def::1
              element: <none>
          setters
            set foo= @-1
              reference: <testLibraryFragment>::@class::A::@setter::foo::@def::0
              element: <none>
              parameters
                _foo @-1
                  element: <none>
            set foo= @-1
              reference: <testLibraryFragment>::@class::A::@setter::foo::@def::1
              element: <none>
              parameters
                _foo @-1
                  element: <none>
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
      fields
        foo
          firstFragment: <testLibraryFragment>::@class::A::@field::foo::@def::0
          type: int
          getter: <none>
          setter: <none>
        foo
          firstFragment: <testLibraryFragment>::@class::A::@field::foo::@def::1
          type: double
          getter: <none>
          setter: <none>
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
      getters
        synthetic get foo
          firstFragment: <testLibraryFragment>::@class::A::@getter::foo::@def::0
        synthetic get foo
          firstFragment: <testLibraryFragment>::@class::A::@getter::foo::@def::1
      setters
        synthetic set foo=
          firstFragment: <testLibraryFragment>::@class::A::@setter::foo::@def::0
          parameters
            requiredPositional _foo
              type: int
        synthetic set foo=
          firstFragment: <testLibraryFragment>::@class::A::@setter::foo::@def::1
          parameters
            requiredPositional _foo
              type: double
''');
  }

  test_duplicateDeclaration_class_method() async {
    var library = await buildLibrary(r'''
class A {
  void foo() {}
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
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::A
          methods
            foo @17
              reference: <testLibraryFragment>::@class::A::@method::foo::@def::0
              enclosingElement3: <testLibraryFragment>::@class::A
              returnType: void
            foo @33
              reference: <testLibraryFragment>::@class::A::@method::foo::@def::1
              enclosingElement3: <testLibraryFragment>::@class::A
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
          element: <testLibraryFragment>::@class::A
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <none>
          methods
            foo @17
              reference: <testLibraryFragment>::@class::A::@method::foo::@def::0
              element: <none>
            foo @33
              reference: <testLibraryFragment>::@class::A::@method::foo::@def::1
              element: <none>
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
      methods
        foo
          firstFragment: <testLibraryFragment>::@class::A::@method::foo::@def::0
        foo
          firstFragment: <testLibraryFragment>::@class::A::@method::foo::@def::1
''');
  }

  test_duplicateDeclaration_classTypeAlias() async {
    var library = await buildLibrary(r'''
class A {}
class B {}
class X = A with M;
class X = B with M;
mixin M {}
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
        class alias X @28
          reference: <testLibraryFragment>::@class::X::@def::0
          enclosingElement3: <testLibraryFragment>
          supertype: A
          mixins
            M
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::X::@def::0::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::X::@def::0
              constantInitializers
                SuperConstructorInvocation
                  superKeyword: super @0
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticElement: <testLibraryFragment>::@class::A::@constructor::new
              superConstructor: <testLibraryFragment>::@class::A::@constructor::new
        class alias X @48
          reference: <testLibraryFragment>::@class::X::@def::1
          enclosingElement3: <testLibraryFragment>
          supertype: B
          mixins
            M
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::X::@def::1::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::X::@def::1
              constantInitializers
                SuperConstructorInvocation
                  superKeyword: super @0
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticElement: <testLibraryFragment>::@class::B::@constructor::new
              superConstructor: <testLibraryFragment>::@class::B::@constructor::new
      mixins
        mixin M @68
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
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <none>
        class B @17
          reference: <testLibraryFragment>::@class::B
          element: <testLibraryFragment>::@class::B
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::B::@constructor::new
              element: <none>
        class X @28
          reference: <testLibraryFragment>::@class::X::@def::0
          element: <testLibraryFragment>::@class::X::@def::0
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::X::@def::0::@constructor::new
              element: <none>
              constantInitializers
                SuperConstructorInvocation
                  superKeyword: super @0
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticElement: <testLibraryFragment>::@class::A::@constructor::new
              superConstructor: <testLibraryFragment>::@class::A::@constructor::new
        class X @48
          reference: <testLibraryFragment>::@class::X::@def::1
          element: <testLibraryFragment>::@class::X::@def::1
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::X::@def::1::@constructor::new
              element: <none>
              constantInitializers
                SuperConstructorInvocation
                  superKeyword: super @0
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticElement: <testLibraryFragment>::@class::B::@constructor::new
              superConstructor: <testLibraryFragment>::@class::B::@constructor::new
      mixins
        mixin M @68
          reference: <testLibraryFragment>::@mixin::M
          element: <testLibraryFragment>::@mixin::M
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
    class alias X
      firstFragment: <testLibraryFragment>::@class::X::@def::0
      supertype: A
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::X::@def::0::@constructor::new
          superConstructor: <none>
    class alias X
      firstFragment: <testLibraryFragment>::@class::X::@def::1
      supertype: B
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::X::@def::1::@constructor::new
          superConstructor: <none>
  mixins
    mixin M
      firstFragment: <testLibraryFragment>::@mixin::M
      superclassConstraints
        Object
''');
  }

  test_duplicateDeclaration_enum() async {
    var library = await buildLibrary(r'''
enum E {a, b}
enum E {c, d, e}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E::@def::0
          enclosingElement3: <testLibraryFragment>
          supertype: Enum
          fields
            static const enumConstant a @8
              reference: <testLibraryFragment>::@enum::E::@def::0::@field::a
              enclosingElement3: <testLibraryFragment>::@enum::E::@def::0
              type: E
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E::@def::0
                      type: E
                    staticElement: <testLibraryFragment>::@enum::E::@def::0::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            static const enumConstant b @11
              reference: <testLibraryFragment>::@enum::E::@def::0::@field::b
              enclosingElement3: <testLibraryFragment>::@enum::E::@def::0
              type: E
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E::@def::0
                      type: E
                    staticElement: <testLibraryFragment>::@enum::E::@def::0::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::E::@def::0::@field::values
              enclosingElement3: <testLibraryFragment>::@enum::E::@def::0
              type: List<E>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: a @-1
                      staticElement: <testLibraryFragment>::@enum::E::@def::0::@getter::a
                      staticType: E
                    SimpleIdentifier
                      token: b @-1
                      staticElement: <testLibraryFragment>::@enum::E::@def::0::@getter::b
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::E::@def::0::@constructor::new
              enclosingElement3: <testLibraryFragment>::@enum::E::@def::0
          accessors
            synthetic static get a @-1
              reference: <testLibraryFragment>::@enum::E::@def::0::@getter::a
              enclosingElement3: <testLibraryFragment>::@enum::E::@def::0
              returnType: E
            synthetic static get b @-1
              reference: <testLibraryFragment>::@enum::E::@def::0::@getter::b
              enclosingElement3: <testLibraryFragment>::@enum::E::@def::0
              returnType: E
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::E::@def::0::@getter::values
              enclosingElement3: <testLibraryFragment>::@enum::E::@def::0
              returnType: List<E>
        enum E @19
          reference: <testLibraryFragment>::@enum::E::@def::1
          enclosingElement3: <testLibraryFragment>
          supertype: Enum
          fields
            static const enumConstant c @22
              reference: <testLibraryFragment>::@enum::E::@def::1::@field::c
              enclosingElement3: <testLibraryFragment>::@enum::E::@def::1
              type: E
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E::@def::0
                      type: E
                    staticElement: <testLibraryFragment>::@enum::E::@def::0::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            static const enumConstant d @25
              reference: <testLibraryFragment>::@enum::E::@def::1::@field::d
              enclosingElement3: <testLibraryFragment>::@enum::E::@def::1
              type: E
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E::@def::0
                      type: E
                    staticElement: <testLibraryFragment>::@enum::E::@def::0::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            static const enumConstant e @28
              reference: <testLibraryFragment>::@enum::E::@def::1::@field::e
              enclosingElement3: <testLibraryFragment>::@enum::E::@def::1
              type: E
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E::@def::0
                      type: E
                    staticElement: <testLibraryFragment>::@enum::E::@def::0::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::E::@def::1::@field::values
              enclosingElement3: <testLibraryFragment>::@enum::E::@def::1
              type: List<E>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: c @-1
                      staticElement: <testLibraryFragment>::@enum::E::@def::1::@getter::c
                      staticType: E
                    SimpleIdentifier
                      token: d @-1
                      staticElement: <testLibraryFragment>::@enum::E::@def::1::@getter::d
                      staticType: E
                    SimpleIdentifier
                      token: e @-1
                      staticElement: <testLibraryFragment>::@enum::E::@def::1::@getter::e
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::E::@def::1::@constructor::new
              enclosingElement3: <testLibraryFragment>::@enum::E::@def::1
          accessors
            synthetic static get c @-1
              reference: <testLibraryFragment>::@enum::E::@def::1::@getter::c
              enclosingElement3: <testLibraryFragment>::@enum::E::@def::1
              returnType: E
            synthetic static get d @-1
              reference: <testLibraryFragment>::@enum::E::@def::1::@getter::d
              enclosingElement3: <testLibraryFragment>::@enum::E::@def::1
              returnType: E
            synthetic static get e @-1
              reference: <testLibraryFragment>::@enum::E::@def::1::@getter::e
              enclosingElement3: <testLibraryFragment>::@enum::E::@def::1
              returnType: E
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::E::@def::1::@getter::values
              enclosingElement3: <testLibraryFragment>::@enum::E::@def::1
              returnType: List<E>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E::@def::0
          element: <testLibraryFragment>::@enum::E::@def::0
          fields
            enumConstant a @8
              reference: <testLibraryFragment>::@enum::E::@def::0::@field::a
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@def::0::@getter::a
            enumConstant b @11
              reference: <testLibraryFragment>::@enum::E::@def::0::@field::b
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@def::0::@getter::b
            values @-1
              reference: <testLibraryFragment>::@enum::E::@def::0::@field::values
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@def::0::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::E::@def::0::@constructor::new
              element: <none>
          getters
            get a @-1
              reference: <testLibraryFragment>::@enum::E::@def::0::@getter::a
              element: <none>
            get b @-1
              reference: <testLibraryFragment>::@enum::E::@def::0::@getter::b
              element: <none>
            get values @-1
              reference: <testLibraryFragment>::@enum::E::@def::0::@getter::values
              element: <none>
        enum E @19
          reference: <testLibraryFragment>::@enum::E::@def::1
          element: <testLibraryFragment>::@enum::E::@def::1
          fields
            enumConstant c @22
              reference: <testLibraryFragment>::@enum::E::@def::1::@field::c
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@def::1::@getter::c
            enumConstant d @25
              reference: <testLibraryFragment>::@enum::E::@def::1::@field::d
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@def::1::@getter::d
            enumConstant e @28
              reference: <testLibraryFragment>::@enum::E::@def::1::@field::e
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@def::1::@getter::e
            values @-1
              reference: <testLibraryFragment>::@enum::E::@def::1::@field::values
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@def::1::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::E::@def::1::@constructor::new
              element: <none>
          getters
            get c @-1
              reference: <testLibraryFragment>::@enum::E::@def::1::@getter::c
              element: <none>
            get d @-1
              reference: <testLibraryFragment>::@enum::E::@def::1::@getter::d
              element: <none>
            get e @-1
              reference: <testLibraryFragment>::@enum::E::@def::1::@getter::e
              element: <none>
            get values @-1
              reference: <testLibraryFragment>::@enum::E::@def::1::@getter::values
              element: <none>
  enums
    enum E
      firstFragment: <testLibraryFragment>::@enum::E::@def::0
      supertype: Enum
      fields
        static const a
          firstFragment: <testLibraryFragment>::@enum::E::@def::0::@field::a
          type: E
          getter: <none>
        static const b
          firstFragment: <testLibraryFragment>::@enum::E::@def::0::@field::b
          type: E
          getter: <none>
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::E::@def::0::@field::values
          type: List<E>
          getter: <none>
      constructors
        synthetic const new
          firstFragment: <testLibraryFragment>::@enum::E::@def::0::@constructor::new
      getters
        synthetic static get a
          firstFragment: <testLibraryFragment>::@enum::E::@def::0::@getter::a
        synthetic static get b
          firstFragment: <testLibraryFragment>::@enum::E::@def::0::@getter::b
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::E::@def::0::@getter::values
    enum E
      firstFragment: <testLibraryFragment>::@enum::E::@def::1
      supertype: Enum
      fields
        static const c
          firstFragment: <testLibraryFragment>::@enum::E::@def::1::@field::c
          type: E
          getter: <none>
        static const d
          firstFragment: <testLibraryFragment>::@enum::E::@def::1::@field::d
          type: E
          getter: <none>
        static const e
          firstFragment: <testLibraryFragment>::@enum::E::@def::1::@field::e
          type: E
          getter: <none>
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::E::@def::1::@field::values
          type: List<E>
          getter: <none>
      constructors
        synthetic const new
          firstFragment: <testLibraryFragment>::@enum::E::@def::1::@constructor::new
      getters
        synthetic static get c
          firstFragment: <testLibraryFragment>::@enum::E::@def::1::@getter::c
        synthetic static get d
          firstFragment: <testLibraryFragment>::@enum::E::@def::1::@getter::d
        synthetic static get e
          firstFragment: <testLibraryFragment>::@enum::E::@def::1::@getter::e
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::E::@def::1::@getter::values
''');
  }

  test_duplicateDeclaration_extension() async {
    var library = await buildLibrary(r'''
extension E on int {}
extension E on int {
  static var x;
}
extension E on int {
  static var y = 0;
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      extensions
        E @10
          reference: <testLibraryFragment>::@extension::E::@def::0
          enclosingElement3: <testLibraryFragment>
          extendedType: int
        E @32
          reference: <testLibraryFragment>::@extension::E::@def::1
          enclosingElement3: <testLibraryFragment>
          extendedType: int
          fields
            static x @56
              reference: <testLibraryFragment>::@extension::E::@def::1::@field::x
              enclosingElement3: <testLibraryFragment>::@extension::E::@def::1
              type: dynamic
          accessors
            synthetic static get x @-1
              reference: <testLibraryFragment>::@extension::E::@def::1::@getter::x
              enclosingElement3: <testLibraryFragment>::@extension::E::@def::1
              returnType: dynamic
            synthetic static set x= @-1
              reference: <testLibraryFragment>::@extension::E::@def::1::@setter::x
              enclosingElement3: <testLibraryFragment>::@extension::E::@def::1
              parameters
                requiredPositional _x @-1
                  type: dynamic
              returnType: void
        E @71
          reference: <testLibraryFragment>::@extension::E::@def::2
          enclosingElement3: <testLibraryFragment>
          extendedType: int
          fields
            static y @95
              reference: <testLibraryFragment>::@extension::E::@def::2::@field::y
              enclosingElement3: <testLibraryFragment>::@extension::E::@def::2
              type: int
              shouldUseTypeForInitializerInference: false
          accessors
            synthetic static get y @-1
              reference: <testLibraryFragment>::@extension::E::@def::2::@getter::y
              enclosingElement3: <testLibraryFragment>::@extension::E::@def::2
              returnType: int
            synthetic static set y= @-1
              reference: <testLibraryFragment>::@extension::E::@def::2::@setter::y
              enclosingElement3: <testLibraryFragment>::@extension::E::@def::2
              parameters
                requiredPositional _y @-1
                  type: int
              returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      extensions
        extension E @10
          reference: <testLibraryFragment>::@extension::E::@def::0
          element: <testLibraryFragment>::@extension::E::@def::0
        extension E @32
          reference: <testLibraryFragment>::@extension::E::@def::1
          element: <testLibraryFragment>::@extension::E::@def::1
          fields
            x @56
              reference: <testLibraryFragment>::@extension::E::@def::1::@field::x
              element: <none>
              getter2: <testLibraryFragment>::@extension::E::@def::1::@getter::x
              setter2: <testLibraryFragment>::@extension::E::@def::1::@setter::x
          getters
            get x @-1
              reference: <testLibraryFragment>::@extension::E::@def::1::@getter::x
              element: <none>
          setters
            set x= @-1
              reference: <testLibraryFragment>::@extension::E::@def::1::@setter::x
              element: <none>
              parameters
                _x @-1
                  element: <none>
        extension E @71
          reference: <testLibraryFragment>::@extension::E::@def::2
          element: <testLibraryFragment>::@extension::E::@def::2
          fields
            y @95
              reference: <testLibraryFragment>::@extension::E::@def::2::@field::y
              element: <none>
              getter2: <testLibraryFragment>::@extension::E::@def::2::@getter::y
              setter2: <testLibraryFragment>::@extension::E::@def::2::@setter::y
          getters
            get y @-1
              reference: <testLibraryFragment>::@extension::E::@def::2::@getter::y
              element: <none>
          setters
            set y= @-1
              reference: <testLibraryFragment>::@extension::E::@def::2::@setter::y
              element: <none>
              parameters
                _y @-1
                  element: <none>
  extensions
    extension E
      firstFragment: <testLibraryFragment>::@extension::E::@def::0
    extension E
      firstFragment: <testLibraryFragment>::@extension::E::@def::1
      fields
        static x
          firstFragment: <testLibraryFragment>::@extension::E::@def::1::@field::x
          type: dynamic
          getter: <none>
          setter: <none>
      getters
        synthetic static get x
          firstFragment: <testLibraryFragment>::@extension::E::@def::1::@getter::x
      setters
        synthetic static set x=
          firstFragment: <testLibraryFragment>::@extension::E::@def::1::@setter::x
          parameters
            requiredPositional _x
              type: dynamic
    extension E
      firstFragment: <testLibraryFragment>::@extension::E::@def::2
      fields
        static y
          firstFragment: <testLibraryFragment>::@extension::E::@def::2::@field::y
          type: int
          getter: <none>
          setter: <none>
      getters
        synthetic static get y
          firstFragment: <testLibraryFragment>::@extension::E::@def::2::@getter::y
      setters
        synthetic static set y=
          firstFragment: <testLibraryFragment>::@extension::E::@def::2::@setter::y
          parameters
            requiredPositional _y
              type: int
''');
  }

  test_duplicateDeclaration_extensionType() async {
    var library = await buildLibrary(r'''
extension type E(int it) {}
extension type E(double it) {}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      extensionTypes
        E @15
          reference: <testLibraryFragment>::@extensionType::E::@def::0
          enclosingElement3: <testLibraryFragment>
          representation: <testLibraryFragment>::@extensionType::E::@def::0::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::E::@def::0::@constructor::new
          typeErasure: int
          fields
            final it @21
              reference: <testLibraryFragment>::@extensionType::E::@def::0::@field::it
              enclosingElement3: <testLibraryFragment>::@extensionType::E::@def::0
              type: int
          constructors
            @15
              reference: <testLibraryFragment>::@extensionType::E::@def::0::@constructor::new
              enclosingElement3: <testLibraryFragment>::@extensionType::E::@def::0
              parameters
                requiredPositional final this.it @21
                  type: int
                  field: <testLibraryFragment>::@extensionType::E::@def::0::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::E::@def::0::@getter::it
              enclosingElement3: <testLibraryFragment>::@extensionType::E::@def::0
              returnType: int
        E @43
          reference: <testLibraryFragment>::@extensionType::E::@def::1
          enclosingElement3: <testLibraryFragment>
          representation: <testLibraryFragment>::@extensionType::E::@def::1::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::E::@def::1::@constructor::new
          typeErasure: double
          fields
            final it @52
              reference: <testLibraryFragment>::@extensionType::E::@def::1::@field::it
              enclosingElement3: <testLibraryFragment>::@extensionType::E::@def::1
              type: double
          constructors
            @43
              reference: <testLibraryFragment>::@extensionType::E::@def::1::@constructor::new
              enclosingElement3: <testLibraryFragment>::@extensionType::E::@def::1
              parameters
                requiredPositional final this.it @52
                  type: double
                  field: <testLibraryFragment>::@extensionType::E::@def::1::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::E::@def::1::@getter::it
              enclosingElement3: <testLibraryFragment>::@extensionType::E::@def::1
              returnType: double
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        extension type E @15
          reference: <testLibraryFragment>::@extensionType::E::@def::0
          element: <testLibraryFragment>::@extensionType::E::@def::0
          fields
            it @21
              reference: <testLibraryFragment>::@extensionType::E::@def::0::@field::it
              element: <none>
              getter2: <testLibraryFragment>::@extensionType::E::@def::0::@getter::it
          constructors
            new @15
              reference: <testLibraryFragment>::@extensionType::E::@def::0::@constructor::new
              element: <none>
              parameters
                this.it @21
                  element: <none>
          getters
            get it @-1
              reference: <testLibraryFragment>::@extensionType::E::@def::0::@getter::it
              element: <none>
        extension type E @43
          reference: <testLibraryFragment>::@extensionType::E::@def::1
          element: <testLibraryFragment>::@extensionType::E::@def::1
          fields
            it @52
              reference: <testLibraryFragment>::@extensionType::E::@def::1::@field::it
              element: <none>
              getter2: <testLibraryFragment>::@extensionType::E::@def::1::@getter::it
          constructors
            new @43
              reference: <testLibraryFragment>::@extensionType::E::@def::1::@constructor::new
              element: <none>
              parameters
                this.it @52
                  element: <none>
          getters
            get it @-1
              reference: <testLibraryFragment>::@extensionType::E::@def::1::@getter::it
              element: <none>
  extensionTypes
    extension type E
      firstFragment: <testLibraryFragment>::@extensionType::E::@def::0
      typeErasure: int
      fields
        final it
          firstFragment: <testLibraryFragment>::@extensionType::E::@def::0::@field::it
          type: int
          getter: <none>
      constructors
        new
          firstFragment: <testLibraryFragment>::@extensionType::E::@def::0::@constructor::new
          parameters
            requiredPositional final it
              type: int
      getters
        synthetic get it
          firstFragment: <testLibraryFragment>::@extensionType::E::@def::0::@getter::it
    extension type E
      firstFragment: <testLibraryFragment>::@extensionType::E::@def::1
      typeErasure: double
      fields
        final it
          firstFragment: <testLibraryFragment>::@extensionType::E::@def::1::@field::it
          type: double
          getter: <none>
      constructors
        new
          firstFragment: <testLibraryFragment>::@extensionType::E::@def::1::@constructor::new
          parameters
            requiredPositional final it
              type: double
      getters
        synthetic get it
          firstFragment: <testLibraryFragment>::@extensionType::E::@def::1::@getter::it
''');
  }

  test_duplicateDeclaration_function() async {
    var library = await buildLibrary(r'''
void f() {}
void f(int a) {}
void f([int b, double c]) {}
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
          reference: <testLibraryFragment>::@function::f::@def::0
          enclosingElement3: <testLibraryFragment>
          returnType: void
        f @17
          reference: <testLibraryFragment>::@function::f::@def::1
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional a @23
              type: int
          returnType: void
        f @34
          reference: <testLibraryFragment>::@function::f::@def::2
          enclosingElement3: <testLibraryFragment>
          parameters
            optionalPositional default b @41
              type: int
            optionalPositional default c @51
              type: double
          returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      functions
        f @5
          reference: <testLibraryFragment>::@function::f::@def::0
          element: <none>
        f @17
          reference: <testLibraryFragment>::@function::f::@def::1
          element: <none>
          parameters
            a @23
              element: <none>
        f @34
          reference: <testLibraryFragment>::@function::f::@def::2
          element: <none>
          parameters
            default b @41
              element: <none>
            default c @51
              element: <none>
  functions
    f
      firstFragment: <testLibraryFragment>::@function::f::@def::0
      returnType: void
    f
      firstFragment: <testLibraryFragment>::@function::f::@def::1
      parameters
        requiredPositional a
          type: int
      returnType: void
    f
      firstFragment: <testLibraryFragment>::@function::f::@def::2
      parameters
        optionalPositional b
          type: int
        optionalPositional c
          type: double
      returnType: void
''');
  }

  test_duplicateDeclaration_function_namedParameter() async {
    var library = await buildLibrary(r'''
void f({int a, double a}) {}
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
            optionalNamed default a @12
              reference: <testLibraryFragment>::@function::f::@parameter::a::@def::0
              type: int
            optionalNamed default a @22
              reference: <testLibraryFragment>::@function::f::@parameter::a::@def::1
              type: double
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
            default a @12
              reference: <testLibraryFragment>::@function::f::@parameter::a::@def::0
              element: <none>
            default a @22
              reference: <testLibraryFragment>::@function::f::@parameter::a::@def::1
              element: <none>
  functions
    f
      firstFragment: <testLibraryFragment>::@function::f
      parameters
        optionalNamed a
          firstFragment: <testLibraryFragment>::@function::f::@parameter::a::@def::0
          type: int
        optionalNamed a
          firstFragment: <testLibraryFragment>::@function::f::@parameter::a::@def::1
          type: double
      returnType: void
''');
  }

  test_duplicateDeclaration_functionTypeAlias() async {
    var library = await buildLibrary(r'''
typedef void F();
typedef void F(int a);
typedef void F([int b, double c]);
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      typeAliases
        functionTypeAliasBased F @13
          reference: <testLibraryFragment>::@typeAlias::F::@def::0
          aliasedType: void Function()
          aliasedElement: GenericFunctionTypeElement
            returnType: void
        functionTypeAliasBased F @31
          reference: <testLibraryFragment>::@typeAlias::F::@def::1
          aliasedType: void Function(int)
          aliasedElement: GenericFunctionTypeElement
            parameters
              requiredPositional a @37
                type: int
            returnType: void
        functionTypeAliasBased F @54
          reference: <testLibraryFragment>::@typeAlias::F::@def::2
          aliasedType: void Function([int, double])
          aliasedElement: GenericFunctionTypeElement
            parameters
              optionalPositional b @61
                type: int
              optionalPositional c @71
                type: double
            returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        F @13
          reference: <testLibraryFragment>::@typeAlias::F::@def::0
          element: <none>
        F @31
          reference: <testLibraryFragment>::@typeAlias::F::@def::1
          element: <none>
        F @54
          reference: <testLibraryFragment>::@typeAlias::F::@def::2
          element: <none>
  typeAliases
    F
      firstFragment: <testLibraryFragment>::@typeAlias::F::@def::0
      aliasedType: void Function()
    F
      firstFragment: <testLibraryFragment>::@typeAlias::F::@def::1
      aliasedType: void Function(int)
    F
      firstFragment: <testLibraryFragment>::@typeAlias::F::@def::2
      aliasedType: void Function([int, double])
''');
  }

  test_duplicateDeclaration_mixin() async {
    var library = await buildLibrary(r'''
mixin A {}
mixin A {
  var x;
}
mixin A {
  var y = 0;
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
        mixin A @6
          reference: <testLibraryFragment>::@mixin::A::@def::0
          enclosingElement3: <testLibraryFragment>
          superclassConstraints
            Object
        mixin A @17
          reference: <testLibraryFragment>::@mixin::A::@def::1
          enclosingElement3: <testLibraryFragment>
          superclassConstraints
            Object
          fields
            x @27
              reference: <testLibraryFragment>::@mixin::A::@def::1::@field::x
              enclosingElement3: <testLibraryFragment>::@mixin::A::@def::1
              type: dynamic
          accessors
            synthetic get x @-1
              reference: <testLibraryFragment>::@mixin::A::@def::1::@getter::x
              enclosingElement3: <testLibraryFragment>::@mixin::A::@def::1
              returnType: dynamic
            synthetic set x= @-1
              reference: <testLibraryFragment>::@mixin::A::@def::1::@setter::x
              enclosingElement3: <testLibraryFragment>::@mixin::A::@def::1
              parameters
                requiredPositional _x @-1
                  type: dynamic
              returnType: void
        mixin A @38
          reference: <testLibraryFragment>::@mixin::A::@def::2
          enclosingElement3: <testLibraryFragment>
          superclassConstraints
            Object
          fields
            y @48
              reference: <testLibraryFragment>::@mixin::A::@def::2::@field::y
              enclosingElement3: <testLibraryFragment>::@mixin::A::@def::2
              type: int
              shouldUseTypeForInitializerInference: false
          accessors
            synthetic get y @-1
              reference: <testLibraryFragment>::@mixin::A::@def::2::@getter::y
              enclosingElement3: <testLibraryFragment>::@mixin::A::@def::2
              returnType: int
            synthetic set y= @-1
              reference: <testLibraryFragment>::@mixin::A::@def::2::@setter::y
              enclosingElement3: <testLibraryFragment>::@mixin::A::@def::2
              parameters
                requiredPositional _y @-1
                  type: int
              returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      mixins
        mixin A @6
          reference: <testLibraryFragment>::@mixin::A::@def::0
          element: <testLibraryFragment>::@mixin::A::@def::0
        mixin A @17
          reference: <testLibraryFragment>::@mixin::A::@def::1
          element: <testLibraryFragment>::@mixin::A::@def::1
          fields
            x @27
              reference: <testLibraryFragment>::@mixin::A::@def::1::@field::x
              element: <none>
              getter2: <testLibraryFragment>::@mixin::A::@def::1::@getter::x
              setter2: <testLibraryFragment>::@mixin::A::@def::1::@setter::x
          getters
            get x @-1
              reference: <testLibraryFragment>::@mixin::A::@def::1::@getter::x
              element: <none>
          setters
            set x= @-1
              reference: <testLibraryFragment>::@mixin::A::@def::1::@setter::x
              element: <none>
              parameters
                _x @-1
                  element: <none>
        mixin A @38
          reference: <testLibraryFragment>::@mixin::A::@def::2
          element: <testLibraryFragment>::@mixin::A::@def::2
          fields
            y @48
              reference: <testLibraryFragment>::@mixin::A::@def::2::@field::y
              element: <none>
              getter2: <testLibraryFragment>::@mixin::A::@def::2::@getter::y
              setter2: <testLibraryFragment>::@mixin::A::@def::2::@setter::y
          getters
            get y @-1
              reference: <testLibraryFragment>::@mixin::A::@def::2::@getter::y
              element: <none>
          setters
            set y= @-1
              reference: <testLibraryFragment>::@mixin::A::@def::2::@setter::y
              element: <none>
              parameters
                _y @-1
                  element: <none>
  mixins
    mixin A
      firstFragment: <testLibraryFragment>::@mixin::A::@def::0
      superclassConstraints
        Object
    mixin A
      firstFragment: <testLibraryFragment>::@mixin::A::@def::1
      superclassConstraints
        Object
      fields
        x
          firstFragment: <testLibraryFragment>::@mixin::A::@def::1::@field::x
          type: dynamic
          getter: <none>
          setter: <none>
      getters
        synthetic get x
          firstFragment: <testLibraryFragment>::@mixin::A::@def::1::@getter::x
      setters
        synthetic set x=
          firstFragment: <testLibraryFragment>::@mixin::A::@def::1::@setter::x
          parameters
            requiredPositional _x
              type: dynamic
    mixin A
      firstFragment: <testLibraryFragment>::@mixin::A::@def::2
      superclassConstraints
        Object
      fields
        y
          firstFragment: <testLibraryFragment>::@mixin::A::@def::2::@field::y
          type: int
          getter: <none>
          setter: <none>
      getters
        synthetic get y
          firstFragment: <testLibraryFragment>::@mixin::A::@def::2::@getter::y
      setters
        synthetic set y=
          firstFragment: <testLibraryFragment>::@mixin::A::@def::2::@setter::y
          parameters
            requiredPositional _y
              type: int
''');
  }

  test_duplicateDeclaration_topLevelVariable() async {
    var library = await buildLibrary(r'''
bool x;
var x;
final x = 1;
var x = 2.3;
''');
    configuration.withPropertyLinking = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        static x @5
          reference: <testLibraryFragment>::@topLevelVariable::x::@def::0
          enclosingElement3: <testLibraryFragment>
          type: bool
          id: variable_0
          getter: getter_0
          setter: setter_0
        static x @12
          reference: <testLibraryFragment>::@topLevelVariable::x::@def::1
          enclosingElement3: <testLibraryFragment>
          type: dynamic
          id: variable_1
          getter: getter_1
          setter: setter_1
        static final x @21
          reference: <testLibraryFragment>::@topLevelVariable::x::@def::2
          enclosingElement3: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          id: variable_2
          getter: getter_2
        static x @32
          reference: <testLibraryFragment>::@topLevelVariable::x::@def::3
          enclosingElement3: <testLibraryFragment>
          type: double
          shouldUseTypeForInitializerInference: false
          id: variable_3
          getter: getter_3
          setter: setter_2
      accessors
        synthetic static get x @-1
          reference: <testLibraryFragment>::@getter::x::@def::0
          enclosingElement3: <testLibraryFragment>
          returnType: bool
          id: getter_0
          variable: variable_0
        synthetic static set x= @-1
          reference: <testLibraryFragment>::@setter::x::@def::0
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _x @-1
              type: bool
          returnType: void
          id: setter_0
          variable: variable_0
        synthetic static get x @-1
          reference: <testLibraryFragment>::@getter::x::@def::1
          enclosingElement3: <testLibraryFragment>
          returnType: dynamic
          id: getter_1
          variable: variable_1
        synthetic static set x= @-1
          reference: <testLibraryFragment>::@setter::x::@def::1
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _x @-1
              type: dynamic
          returnType: void
          id: setter_1
          variable: variable_1
        synthetic static get x @-1
          reference: <testLibraryFragment>::@getter::x::@def::2
          enclosingElement3: <testLibraryFragment>
          returnType: int
          id: getter_2
          variable: variable_2
        synthetic static get x @-1
          reference: <testLibraryFragment>::@getter::x::@def::3
          enclosingElement3: <testLibraryFragment>
          returnType: double
          id: getter_3
          variable: variable_3
        synthetic static set x= @-1
          reference: <testLibraryFragment>::@setter::x::@def::2
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _x @-1
              type: double
          returnType: void
          id: setter_2
          variable: variable_3
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        x @5
          reference: <testLibraryFragment>::@topLevelVariable::x::@def::0
          element: <none>
          getter2: <testLibraryFragment>::@getter::x::@def::0
          setter2: <testLibraryFragment>::@setter::x::@def::0
        x @12
          reference: <testLibraryFragment>::@topLevelVariable::x::@def::1
          element: <none>
          getter2: <testLibraryFragment>::@getter::x::@def::1
          setter2: <testLibraryFragment>::@setter::x::@def::1
        final x @21
          reference: <testLibraryFragment>::@topLevelVariable::x::@def::2
          element: <none>
          getter2: <testLibraryFragment>::@getter::x::@def::2
        x @32
          reference: <testLibraryFragment>::@topLevelVariable::x::@def::3
          element: <none>
          getter2: <testLibraryFragment>::@getter::x::@def::3
          setter2: <testLibraryFragment>::@setter::x::@def::2
      getters
        get x @-1
          reference: <testLibraryFragment>::@getter::x::@def::0
          element: <none>
        get x @-1
          reference: <testLibraryFragment>::@getter::x::@def::1
          element: <none>
        get x @-1
          reference: <testLibraryFragment>::@getter::x::@def::2
          element: <none>
        get x @-1
          reference: <testLibraryFragment>::@getter::x::@def::3
          element: <none>
      setters
        set x= @-1
          reference: <testLibraryFragment>::@setter::x::@def::0
          element: <none>
          parameters
            _x @-1
              element: <none>
        set x= @-1
          reference: <testLibraryFragment>::@setter::x::@def::1
          element: <none>
          parameters
            _x @-1
              element: <none>
        set x= @-1
          reference: <testLibraryFragment>::@setter::x::@def::2
          element: <none>
          parameters
            _x @-1
              element: <none>
  topLevelVariables
    x
      firstFragment: <testLibraryFragment>::@topLevelVariable::x::@def::0
      type: bool
      getter: <none>
      setter: <none>
    x
      firstFragment: <testLibraryFragment>::@topLevelVariable::x::@def::1
      type: dynamic
      getter: <none>
      setter: <none>
    final x
      firstFragment: <testLibraryFragment>::@topLevelVariable::x::@def::2
      type: int
      getter: <none>
    x
      firstFragment: <testLibraryFragment>::@topLevelVariable::x::@def::3
      type: double
      getter: <none>
      setter: <none>
  getters
    synthetic static get x
      firstFragment: <testLibraryFragment>::@getter::x::@def::0
    synthetic static get x
      firstFragment: <testLibraryFragment>::@getter::x::@def::1
    synthetic static get x
      firstFragment: <testLibraryFragment>::@getter::x::@def::2
    synthetic static get x
      firstFragment: <testLibraryFragment>::@getter::x::@def::3
  setters
    synthetic static set x=
      firstFragment: <testLibraryFragment>::@setter::x::@def::0
      parameters
        requiredPositional _x
          type: bool
    synthetic static set x=
      firstFragment: <testLibraryFragment>::@setter::x::@def::1
      parameters
        requiredPositional _x
          type: dynamic
    synthetic static set x=
      firstFragment: <testLibraryFragment>::@setter::x::@def::2
      parameters
        requiredPositional _x
          type: double
''');
  }

  test_duplicateDeclaration_unit_getter() async {
    var library = await buildLibrary(r'''
int get foo {}
double get foo {}
''');
    configuration.withPropertyLinking = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        synthetic static foo @-1
          reference: <testLibraryFragment>::@topLevelVariable::foo
          enclosingElement3: <testLibraryFragment>
          type: double
          id: variable_0
          getter: getter_0
      accessors
        static get foo @8
          reference: <testLibraryFragment>::@getter::foo::@def::0
          enclosingElement3: <testLibraryFragment>
          returnType: int
          id: getter_1
          variable: variable_0
        static get foo @26
          reference: <testLibraryFragment>::@getter::foo::@def::1
          enclosingElement3: <testLibraryFragment>
          returnType: double
          id: getter_0
          variable: variable_0
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        synthetic foo @-1
          reference: <testLibraryFragment>::@topLevelVariable::foo
          element: <none>
          getter2: <testLibraryFragment>::@getter::foo::@def::1
      getters
        get foo @8
          reference: <testLibraryFragment>::@getter::foo::@def::0
          element: <none>
        get foo @26
          reference: <testLibraryFragment>::@getter::foo::@def::1
          element: <none>
  topLevelVariables
    synthetic foo
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo
      type: double
      getter: <none>
  getters
    static get foo
      firstFragment: <testLibraryFragment>::@getter::foo::@def::0
    static get foo
      firstFragment: <testLibraryFragment>::@getter::foo::@def::1
''');
  }

  test_duplicateDeclaration_unit_setter() async {
    var library = await buildLibrary(r'''
set foo(int _) {}
set foo(double _) {}
''');
    configuration.withPropertyLinking = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        synthetic static foo @-1
          reference: <testLibraryFragment>::@topLevelVariable::foo
          enclosingElement3: <testLibraryFragment>
          type: double
          id: variable_0
          setter: setter_0
      accessors
        static set foo= @4
          reference: <testLibraryFragment>::@setter::foo::@def::0
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _ @12
              type: int
          returnType: void
          id: setter_1
          variable: variable_0
        static set foo= @22
          reference: <testLibraryFragment>::@setter::foo::@def::1
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional _ @33
              type: double
          returnType: void
          id: setter_0
          variable: variable_0
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        synthetic foo @-1
          reference: <testLibraryFragment>::@topLevelVariable::foo
          element: <none>
          setter2: <testLibraryFragment>::@setter::foo::@def::1
      setters
        set foo= @4
          reference: <testLibraryFragment>::@setter::foo::@def::0
          element: <none>
          parameters
            _ @12
              element: <none>
        set foo= @22
          reference: <testLibraryFragment>::@setter::foo::@def::1
          element: <none>
          parameters
            _ @33
              element: <none>
  topLevelVariables
    synthetic foo
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo
      type: double
      setter: <none>
  setters
    static set foo=
      firstFragment: <testLibraryFragment>::@setter::foo::@def::0
      parameters
        requiredPositional _
          type: int
    static set foo=
      firstFragment: <testLibraryFragment>::@setter::foo::@def::1
      parameters
        requiredPositional _
          type: double
''');
  }
}

@reflectiveTest
class DuplicateDeclarationElementTest_fromBytes
    extends DuplicateDeclarationElementTest {
  @override
  bool get keepLinkingLibraries => false;
}

@reflectiveTest
class DuplicateDeclarationElementTest_keepLinking
    extends DuplicateDeclarationElementTest {
  @override
  bool get keepLinkingLibraries => true;
}
