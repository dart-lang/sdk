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
      enclosingElement: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A::@def::0
          enclosingElement: <testLibraryFragment>
          fields
            static const f01 @25
              reference: <testLibraryFragment>::@class::A::@def::0::@field::f01
              enclosingElement: <testLibraryFragment>::@class::A::@def::0
              type: int
              shouldUseTypeForInitializerInference: false
              constantInitializer
                IntegerLiteral
                  literal: 0 @31
                  staticType: int
            static const f02 @49
              reference: <testLibraryFragment>::@class::A::@def::0::@field::f02
              enclosingElement: <testLibraryFragment>::@class::A::@def::0
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
              enclosingElement: <testLibraryFragment>::@class::A::@def::0
          accessors
            synthetic static get f01 @-1
              reference: <testLibraryFragment>::@class::A::@def::0::@getter::f01
              enclosingElement: <testLibraryFragment>::@class::A::@def::0
              returnType: int
            synthetic static get f02 @-1
              reference: <testLibraryFragment>::@class::A::@def::0::@getter::f02
              enclosingElement: <testLibraryFragment>::@class::A::@def::0
              returnType: int
        class A @69
          reference: <testLibraryFragment>::@class::A::@def::1
          enclosingElement: <testLibraryFragment>
          fields
            static const f11 @88
              reference: <testLibraryFragment>::@class::A::@def::1::@field::f11
              enclosingElement: <testLibraryFragment>::@class::A::@def::1
              type: int
              shouldUseTypeForInitializerInference: false
              constantInitializer
                IntegerLiteral
                  literal: 0 @94
                  staticType: int
            static const f12 @112
              reference: <testLibraryFragment>::@class::A::@def::1::@field::f12
              enclosingElement: <testLibraryFragment>::@class::A::@def::1
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
              enclosingElement: <testLibraryFragment>::@class::A::@def::1
          accessors
            synthetic static get f11 @-1
              reference: <testLibraryFragment>::@class::A::@def::1::@getter::f11
              enclosingElement: <testLibraryFragment>::@class::A::@def::1
              returnType: int
            synthetic static get f12 @-1
              reference: <testLibraryFragment>::@class::A::@def::1::@getter::f12
              enclosingElement: <testLibraryFragment>::@class::A::@def::1
              returnType: int
        class A @132
          reference: <testLibraryFragment>::@class::A::@def::2
          enclosingElement: <testLibraryFragment>
          fields
            static const f21 @151
              reference: <testLibraryFragment>::@class::A::@def::2::@field::f21
              enclosingElement: <testLibraryFragment>::@class::A::@def::2
              type: int
              shouldUseTypeForInitializerInference: false
              constantInitializer
                IntegerLiteral
                  literal: 0 @157
                  staticType: int
            static const f22 @175
              reference: <testLibraryFragment>::@class::A::@def::2::@field::f22
              enclosingElement: <testLibraryFragment>::@class::A::@def::2
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
              enclosingElement: <testLibraryFragment>::@class::A::@def::2
          accessors
            synthetic static get f21 @-1
              reference: <testLibraryFragment>::@class::A::@def::2::@getter::f21
              enclosingElement: <testLibraryFragment>::@class::A::@def::2
              returnType: int
            synthetic static get f22 @-1
              reference: <testLibraryFragment>::@class::A::@def::2::@getter::f22
              enclosingElement: <testLibraryFragment>::@class::A::@def::2
              returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A::@def::0
          fields
            f01 @25
              reference: <testLibraryFragment>::@class::A::@def::0::@field::f01
              enclosingFragment: <testLibraryFragment>::@class::A::@def::0
            f02 @49
              reference: <testLibraryFragment>::@class::A::@def::0::@field::f02
              enclosingFragment: <testLibraryFragment>::@class::A::@def::0
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::A::@def::0::@constructor::new
              enclosingFragment: <testLibraryFragment>::@class::A::@def::0
          getters
            get f01 @-1
              reference: <testLibraryFragment>::@class::A::@def::0::@getter::f01
              enclosingFragment: <testLibraryFragment>::@class::A::@def::0
            get f02 @-1
              reference: <testLibraryFragment>::@class::A::@def::0::@getter::f02
              enclosingFragment: <testLibraryFragment>::@class::A::@def::0
        class A @69
          reference: <testLibraryFragment>::@class::A::@def::1
          fields
            f11 @88
              reference: <testLibraryFragment>::@class::A::@def::1::@field::f11
              enclosingFragment: <testLibraryFragment>::@class::A::@def::1
            f12 @112
              reference: <testLibraryFragment>::@class::A::@def::1::@field::f12
              enclosingFragment: <testLibraryFragment>::@class::A::@def::1
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::A::@def::1::@constructor::new
              enclosingFragment: <testLibraryFragment>::@class::A::@def::1
          getters
            get f11 @-1
              reference: <testLibraryFragment>::@class::A::@def::1::@getter::f11
              enclosingFragment: <testLibraryFragment>::@class::A::@def::1
            get f12 @-1
              reference: <testLibraryFragment>::@class::A::@def::1::@getter::f12
              enclosingFragment: <testLibraryFragment>::@class::A::@def::1
        class A @132
          reference: <testLibraryFragment>::@class::A::@def::2
          fields
            f21 @151
              reference: <testLibraryFragment>::@class::A::@def::2::@field::f21
              enclosingFragment: <testLibraryFragment>::@class::A::@def::2
            f22 @175
              reference: <testLibraryFragment>::@class::A::@def::2::@field::f22
              enclosingFragment: <testLibraryFragment>::@class::A::@def::2
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::A::@def::2::@constructor::new
              enclosingFragment: <testLibraryFragment>::@class::A::@def::2
          getters
            get f21 @-1
              reference: <testLibraryFragment>::@class::A::@def::2::@getter::f21
              enclosingFragment: <testLibraryFragment>::@class::A::@def::2
            get f22 @-1
              reference: <testLibraryFragment>::@class::A::@def::2::@getter::f22
              enclosingFragment: <testLibraryFragment>::@class::A::@def::2
  classes
    class A
      reference: <testLibraryFragment>::@class::A::@def::0
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@class::A::@def::0
      fields
        static const f01
          reference: <none>
          enclosingElement: <testLibraryFragment>::@class::A::@def::0
          type: int
          firstFragment: <testLibraryFragment>::@class::A::@def::0::@field::f01
        static const f02
          reference: <none>
          enclosingElement: <testLibraryFragment>::@class::A::@def::0
          type: int
          firstFragment: <testLibraryFragment>::@class::A::@def::0::@field::f02
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::A::@def::0::@constructor::new
      getters
        synthetic static get f01
          reference: <none>
          enclosingElement: <testLibraryFragment>::@class::A::@def::0
          firstFragment: <testLibraryFragment>::@class::A::@def::0::@getter::f01
        synthetic static get f02
          reference: <none>
          enclosingElement: <testLibraryFragment>::@class::A::@def::0
          firstFragment: <testLibraryFragment>::@class::A::@def::0::@getter::f02
    class A
      reference: <testLibraryFragment>::@class::A::@def::1
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@class::A::@def::1
      fields
        static const f11
          reference: <none>
          enclosingElement: <testLibraryFragment>::@class::A::@def::1
          type: int
          firstFragment: <testLibraryFragment>::@class::A::@def::1::@field::f11
        static const f12
          reference: <none>
          enclosingElement: <testLibraryFragment>::@class::A::@def::1
          type: int
          firstFragment: <testLibraryFragment>::@class::A::@def::1::@field::f12
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::A::@def::1::@constructor::new
      getters
        synthetic static get f11
          reference: <none>
          enclosingElement: <testLibraryFragment>::@class::A::@def::1
          firstFragment: <testLibraryFragment>::@class::A::@def::1::@getter::f11
        synthetic static get f12
          reference: <none>
          enclosingElement: <testLibraryFragment>::@class::A::@def::1
          firstFragment: <testLibraryFragment>::@class::A::@def::1::@getter::f12
    class A
      reference: <testLibraryFragment>::@class::A::@def::2
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@class::A::@def::2
      fields
        static const f21
          reference: <none>
          enclosingElement: <testLibraryFragment>::@class::A::@def::2
          type: int
          firstFragment: <testLibraryFragment>::@class::A::@def::2::@field::f21
        static const f22
          reference: <none>
          enclosingElement: <testLibraryFragment>::@class::A::@def::2
          type: int
          firstFragment: <testLibraryFragment>::@class::A::@def::2::@field::f22
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::A::@def::2::@constructor::new
      getters
        synthetic static get f21
          reference: <none>
          enclosingElement: <testLibraryFragment>::@class::A::@def::2
          firstFragment: <testLibraryFragment>::@class::A::@def::2::@getter::f21
        synthetic static get f22
          reference: <none>
          enclosingElement: <testLibraryFragment>::@class::A::@def::2
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
      enclosingElement: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          enclosingElement: <testLibraryFragment>
          constructors
            named @14
              reference: <testLibraryFragment>::@class::A::@constructor::named::@def::0
              enclosingElement: <testLibraryFragment>::@class::A
              periodOffset: 13
              nameEnd: 19
            named @27
              reference: <testLibraryFragment>::@class::A::@constructor::named::@def::1
              enclosingElement: <testLibraryFragment>::@class::A
              periodOffset: 26
              nameEnd: 32
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          constructors
            named @14
              reference: <testLibraryFragment>::@class::A::@constructor::named::@def::0
              enclosingFragment: <testLibraryFragment>::@class::A
              periodOffset: 13
              nameEnd: 19
            named @27
              reference: <testLibraryFragment>::@class::A::@constructor::named::@def::1
              enclosingFragment: <testLibraryFragment>::@class::A
              periodOffset: 26
              nameEnd: 32
  classes
    class A
      reference: <testLibraryFragment>::@class::A
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        named
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::A::@constructor::named::@def::0
        named
          reference: <none>
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
      enclosingElement: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          enclosingElement: <testLibraryFragment>
          fields
            foo @16
              reference: <testLibraryFragment>::@class::A::@field::foo::@def::0
              enclosingElement: <testLibraryFragment>::@class::A
              type: int
              id: field_0
              getter: getter_0
              setter: setter_0
            foo @30
              reference: <testLibraryFragment>::@class::A::@field::foo::@def::1
              enclosingElement: <testLibraryFragment>::@class::A
              type: double
              id: field_1
              getter: getter_1
              setter: setter_1
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::A
          accessors
            synthetic get foo @-1
              reference: <testLibraryFragment>::@class::A::@getter::foo::@def::0
              enclosingElement: <testLibraryFragment>::@class::A
              returnType: int
              id: getter_0
              variable: field_0
            synthetic set foo= @-1
              reference: <testLibraryFragment>::@class::A::@setter::foo::@def::0
              enclosingElement: <testLibraryFragment>::@class::A
              parameters
                requiredPositional _foo @-1
                  type: int
              returnType: void
              id: setter_0
              variable: field_0
            synthetic get foo @-1
              reference: <testLibraryFragment>::@class::A::@getter::foo::@def::1
              enclosingElement: <testLibraryFragment>::@class::A
              returnType: double
              id: getter_1
              variable: field_1
            synthetic set foo= @-1
              reference: <testLibraryFragment>::@class::A::@setter::foo::@def::1
              enclosingElement: <testLibraryFragment>::@class::A
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
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          fields
            foo @16
              reference: <testLibraryFragment>::@class::A::@field::foo::@def::0
              enclosingFragment: <testLibraryFragment>::@class::A
            foo @30
              reference: <testLibraryFragment>::@class::A::@field::foo::@def::1
              enclosingFragment: <testLibraryFragment>::@class::A
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingFragment: <testLibraryFragment>::@class::A
          getters
            get foo @-1
              reference: <testLibraryFragment>::@class::A::@getter::foo::@def::0
              enclosingFragment: <testLibraryFragment>::@class::A
            get foo @-1
              reference: <testLibraryFragment>::@class::A::@getter::foo::@def::1
              enclosingFragment: <testLibraryFragment>::@class::A
          setters
            set foo= @-1
              reference: <testLibraryFragment>::@class::A::@setter::foo::@def::0
              enclosingFragment: <testLibraryFragment>::@class::A
            set foo= @-1
              reference: <testLibraryFragment>::@class::A::@setter::foo::@def::1
              enclosingFragment: <testLibraryFragment>::@class::A
  classes
    class A
      reference: <testLibraryFragment>::@class::A
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@class::A
      fields
        foo
          reference: <none>
          enclosingElement: <testLibraryFragment>::@class::A
          type: int
          firstFragment: <testLibraryFragment>::@class::A::@field::foo::@def::0
        foo
          reference: <none>
          enclosingElement: <testLibraryFragment>::@class::A
          type: double
          firstFragment: <testLibraryFragment>::@class::A::@field::foo::@def::1
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
      getters
        synthetic get foo
          reference: <none>
          enclosingElement: <testLibraryFragment>::@class::A
          firstFragment: <testLibraryFragment>::@class::A::@getter::foo::@def::0
        synthetic get foo
          reference: <none>
          enclosingElement: <testLibraryFragment>::@class::A
          firstFragment: <testLibraryFragment>::@class::A::@getter::foo::@def::1
      setters
        synthetic set foo=
          reference: <none>
          enclosingElement: <testLibraryFragment>::@class::A
          firstFragment: <testLibraryFragment>::@class::A::@setter::foo::@def::0
        synthetic set foo=
          reference: <none>
          enclosingElement: <testLibraryFragment>::@class::A
          firstFragment: <testLibraryFragment>::@class::A::@setter::foo::@def::1
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
            foo @17
              reference: <testLibraryFragment>::@class::A::@method::foo::@def::0
              enclosingElement: <testLibraryFragment>::@class::A
              returnType: void
            foo @33
              reference: <testLibraryFragment>::@class::A::@method::foo::@def::1
              enclosingElement: <testLibraryFragment>::@class::A
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
            foo @17
              reference: <testLibraryFragment>::@class::A::@method::foo::@def::0
              enclosingFragment: <testLibraryFragment>::@class::A
            foo @33
              reference: <testLibraryFragment>::@class::A::@method::foo::@def::1
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
        foo
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::A::@method::foo::@def::0
        foo
          reference: <none>
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
        class alias X @28
          reference: <testLibraryFragment>::@class::X::@def::0
          enclosingElement: <testLibraryFragment>
          supertype: A
          mixins
            M
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::X::@def::0::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::X::@def::0
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
          enclosingElement: <testLibraryFragment>
          supertype: B
          mixins
            M
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::X::@def::1::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::X::@def::1
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
          enclosingElement: <testLibraryFragment>
          superclassConstraints
            Object
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
        class B @17
          reference: <testLibraryFragment>::@class::B
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::B::@constructor::new
              enclosingFragment: <testLibraryFragment>::@class::B
        class X @28
          reference: <testLibraryFragment>::@class::X::@def::0
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::X::@def::0::@constructor::new
              enclosingFragment: <testLibraryFragment>::@class::X::@def::0
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
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::X::@def::1::@constructor::new
              enclosingFragment: <testLibraryFragment>::@class::X::@def::1
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
  classes
    class A
      reference: <testLibraryFragment>::@class::A
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
    class B
      reference: <testLibraryFragment>::@class::B
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@class::B
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::B::@constructor::new
    class alias X
      reference: <testLibraryFragment>::@class::X::@def::0
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@class::X::@def::0
      supertype: A
      constructors
        synthetic new
          reference: <none>
          superConstructor: <none>
          firstFragment: <testLibraryFragment>::@class::X::@def::0::@constructor::new
    class alias X
      reference: <testLibraryFragment>::@class::X::@def::1
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@class::X::@def::1
      supertype: B
      constructors
        synthetic new
          reference: <none>
          superConstructor: <none>
          firstFragment: <testLibraryFragment>::@class::X::@def::1::@constructor::new
  mixins
    mixin M
      reference: <testLibraryFragment>::@mixin::M
      enclosingElement2: <testLibrary>
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
      enclosingElement: <testLibrary>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E::@def::0
          enclosingElement: <testLibraryFragment>
          supertype: Enum
          fields
            static const enumConstant a @8
              reference: <testLibraryFragment>::@enum::E::@def::0::@field::a
              enclosingElement: <testLibraryFragment>::@enum::E::@def::0
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
              enclosingElement: <testLibraryFragment>::@enum::E::@def::0
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
              enclosingElement: <testLibraryFragment>::@enum::E::@def::0
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
              enclosingElement: <testLibraryFragment>::@enum::E::@def::0
          accessors
            synthetic static get a @-1
              reference: <testLibraryFragment>::@enum::E::@def::0::@getter::a
              enclosingElement: <testLibraryFragment>::@enum::E::@def::0
              returnType: E
            synthetic static get b @-1
              reference: <testLibraryFragment>::@enum::E::@def::0::@getter::b
              enclosingElement: <testLibraryFragment>::@enum::E::@def::0
              returnType: E
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::E::@def::0::@getter::values
              enclosingElement: <testLibraryFragment>::@enum::E::@def::0
              returnType: List<E>
        enum E @19
          reference: <testLibraryFragment>::@enum::E::@def::1
          enclosingElement: <testLibraryFragment>
          supertype: Enum
          fields
            static const enumConstant c @22
              reference: <testLibraryFragment>::@enum::E::@def::1::@field::c
              enclosingElement: <testLibraryFragment>::@enum::E::@def::1
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
              enclosingElement: <testLibraryFragment>::@enum::E::@def::1
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
              enclosingElement: <testLibraryFragment>::@enum::E::@def::1
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
              enclosingElement: <testLibraryFragment>::@enum::E::@def::1
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
              enclosingElement: <testLibraryFragment>::@enum::E::@def::1
          accessors
            synthetic static get c @-1
              reference: <testLibraryFragment>::@enum::E::@def::1::@getter::c
              enclosingElement: <testLibraryFragment>::@enum::E::@def::1
              returnType: E
            synthetic static get d @-1
              reference: <testLibraryFragment>::@enum::E::@def::1::@getter::d
              enclosingElement: <testLibraryFragment>::@enum::E::@def::1
              returnType: E
            synthetic static get e @-1
              reference: <testLibraryFragment>::@enum::E::@def::1::@getter::e
              enclosingElement: <testLibraryFragment>::@enum::E::@def::1
              returnType: E
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::E::@def::1::@getter::values
              enclosingElement: <testLibraryFragment>::@enum::E::@def::1
              returnType: List<E>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E::@def::0
          fields
            enumConstant a @8
              reference: <testLibraryFragment>::@enum::E::@def::0::@field::a
              enclosingFragment: <testLibraryFragment>::@enum::E::@def::0
            enumConstant b @11
              reference: <testLibraryFragment>::@enum::E::@def::0::@field::b
              enclosingFragment: <testLibraryFragment>::@enum::E::@def::0
            values @-1
              reference: <testLibraryFragment>::@enum::E::@def::0::@field::values
              enclosingFragment: <testLibraryFragment>::@enum::E::@def::0
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::E::@def::0::@constructor::new
              enclosingFragment: <testLibraryFragment>::@enum::E::@def::0
          getters
            get a @-1
              reference: <testLibraryFragment>::@enum::E::@def::0::@getter::a
              enclosingFragment: <testLibraryFragment>::@enum::E::@def::0
            get b @-1
              reference: <testLibraryFragment>::@enum::E::@def::0::@getter::b
              enclosingFragment: <testLibraryFragment>::@enum::E::@def::0
            get values @-1
              reference: <testLibraryFragment>::@enum::E::@def::0::@getter::values
              enclosingFragment: <testLibraryFragment>::@enum::E::@def::0
        enum E @19
          reference: <testLibraryFragment>::@enum::E::@def::1
          fields
            enumConstant c @22
              reference: <testLibraryFragment>::@enum::E::@def::1::@field::c
              enclosingFragment: <testLibraryFragment>::@enum::E::@def::1
            enumConstant d @25
              reference: <testLibraryFragment>::@enum::E::@def::1::@field::d
              enclosingFragment: <testLibraryFragment>::@enum::E::@def::1
            enumConstant e @28
              reference: <testLibraryFragment>::@enum::E::@def::1::@field::e
              enclosingFragment: <testLibraryFragment>::@enum::E::@def::1
            values @-1
              reference: <testLibraryFragment>::@enum::E::@def::1::@field::values
              enclosingFragment: <testLibraryFragment>::@enum::E::@def::1
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::E::@def::1::@constructor::new
              enclosingFragment: <testLibraryFragment>::@enum::E::@def::1
          getters
            get c @-1
              reference: <testLibraryFragment>::@enum::E::@def::1::@getter::c
              enclosingFragment: <testLibraryFragment>::@enum::E::@def::1
            get d @-1
              reference: <testLibraryFragment>::@enum::E::@def::1::@getter::d
              enclosingFragment: <testLibraryFragment>::@enum::E::@def::1
            get e @-1
              reference: <testLibraryFragment>::@enum::E::@def::1::@getter::e
              enclosingFragment: <testLibraryFragment>::@enum::E::@def::1
            get values @-1
              reference: <testLibraryFragment>::@enum::E::@def::1::@getter::values
              enclosingFragment: <testLibraryFragment>::@enum::E::@def::1
  enums
    enum E
      reference: <testLibraryFragment>::@enum::E::@def::0
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@enum::E::@def::0
      supertype: Enum
      fields
        static const a
          reference: <none>
          enclosingElement: <testLibraryFragment>::@enum::E::@def::0
          type: E
          firstFragment: <testLibraryFragment>::@enum::E::@def::0::@field::a
        static const b
          reference: <none>
          enclosingElement: <testLibraryFragment>::@enum::E::@def::0
          type: E
          firstFragment: <testLibraryFragment>::@enum::E::@def::0::@field::b
        synthetic static const values
          reference: <none>
          enclosingElement: <testLibraryFragment>::@enum::E::@def::0
          type: List<E>
          firstFragment: <testLibraryFragment>::@enum::E::@def::0::@field::values
      constructors
        synthetic const new
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@def::0::@constructor::new
      getters
        synthetic static get a
          reference: <none>
          enclosingElement: <testLibraryFragment>::@enum::E::@def::0
          firstFragment: <testLibraryFragment>::@enum::E::@def::0::@getter::a
        synthetic static get b
          reference: <none>
          enclosingElement: <testLibraryFragment>::@enum::E::@def::0
          firstFragment: <testLibraryFragment>::@enum::E::@def::0::@getter::b
        synthetic static get values
          reference: <none>
          enclosingElement: <testLibraryFragment>::@enum::E::@def::0
          firstFragment: <testLibraryFragment>::@enum::E::@def::0::@getter::values
    enum E
      reference: <testLibraryFragment>::@enum::E::@def::1
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@enum::E::@def::1
      supertype: Enum
      fields
        static const c
          reference: <none>
          enclosingElement: <testLibraryFragment>::@enum::E::@def::1
          type: E
          firstFragment: <testLibraryFragment>::@enum::E::@def::1::@field::c
        static const d
          reference: <none>
          enclosingElement: <testLibraryFragment>::@enum::E::@def::1
          type: E
          firstFragment: <testLibraryFragment>::@enum::E::@def::1::@field::d
        static const e
          reference: <none>
          enclosingElement: <testLibraryFragment>::@enum::E::@def::1
          type: E
          firstFragment: <testLibraryFragment>::@enum::E::@def::1::@field::e
        synthetic static const values
          reference: <none>
          enclosingElement: <testLibraryFragment>::@enum::E::@def::1
          type: List<E>
          firstFragment: <testLibraryFragment>::@enum::E::@def::1::@field::values
      constructors
        synthetic const new
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@def::1::@constructor::new
      getters
        synthetic static get c
          reference: <none>
          enclosingElement: <testLibraryFragment>::@enum::E::@def::1
          firstFragment: <testLibraryFragment>::@enum::E::@def::1::@getter::c
        synthetic static get d
          reference: <none>
          enclosingElement: <testLibraryFragment>::@enum::E::@def::1
          firstFragment: <testLibraryFragment>::@enum::E::@def::1::@getter::d
        synthetic static get e
          reference: <none>
          enclosingElement: <testLibraryFragment>::@enum::E::@def::1
          firstFragment: <testLibraryFragment>::@enum::E::@def::1::@getter::e
        synthetic static get values
          reference: <none>
          enclosingElement: <testLibraryFragment>::@enum::E::@def::1
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
      enclosingElement: <testLibrary>
      extensions
        E @10
          reference: <testLibraryFragment>::@extension::E::@def::0
          enclosingElement: <testLibraryFragment>
          extendedType: int
        E @32
          reference: <testLibraryFragment>::@extension::E::@def::1
          enclosingElement: <testLibraryFragment>
          extendedType: int
          fields
            static x @56
              reference: <testLibraryFragment>::@extension::E::@def::1::@field::x
              enclosingElement: <testLibraryFragment>::@extension::E::@def::1
              type: dynamic
          accessors
            synthetic static get x @-1
              reference: <testLibraryFragment>::@extension::E::@def::1::@getter::x
              enclosingElement: <testLibraryFragment>::@extension::E::@def::1
              returnType: dynamic
            synthetic static set x= @-1
              reference: <testLibraryFragment>::@extension::E::@def::1::@setter::x
              enclosingElement: <testLibraryFragment>::@extension::E::@def::1
              parameters
                requiredPositional _x @-1
                  type: dynamic
              returnType: void
        E @71
          reference: <testLibraryFragment>::@extension::E::@def::2
          enclosingElement: <testLibraryFragment>
          extendedType: int
          fields
            static y @95
              reference: <testLibraryFragment>::@extension::E::@def::2::@field::y
              enclosingElement: <testLibraryFragment>::@extension::E::@def::2
              type: int
              shouldUseTypeForInitializerInference: false
          accessors
            synthetic static get y @-1
              reference: <testLibraryFragment>::@extension::E::@def::2::@getter::y
              enclosingElement: <testLibraryFragment>::@extension::E::@def::2
              returnType: int
            synthetic static set y= @-1
              reference: <testLibraryFragment>::@extension::E::@def::2::@setter::y
              enclosingElement: <testLibraryFragment>::@extension::E::@def::2
              parameters
                requiredPositional _y @-1
                  type: int
              returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      extensions
        extension E @10
          reference: <testLibraryFragment>::@extension::E::@def::0
        extension E @32
          reference: <testLibraryFragment>::@extension::E::@def::1
          fields
            x @56
              reference: <testLibraryFragment>::@extension::E::@def::1::@field::x
              enclosingFragment: <testLibraryFragment>::@extension::E::@def::1
          getters
            get x @-1
              reference: <testLibraryFragment>::@extension::E::@def::1::@getter::x
              enclosingFragment: <testLibraryFragment>::@extension::E::@def::1
          setters
            set x= @-1
              reference: <testLibraryFragment>::@extension::E::@def::1::@setter::x
              enclosingFragment: <testLibraryFragment>::@extension::E::@def::1
        extension E @71
          reference: <testLibraryFragment>::@extension::E::@def::2
          fields
            y @95
              reference: <testLibraryFragment>::@extension::E::@def::2::@field::y
              enclosingFragment: <testLibraryFragment>::@extension::E::@def::2
          getters
            get y @-1
              reference: <testLibraryFragment>::@extension::E::@def::2::@getter::y
              enclosingFragment: <testLibraryFragment>::@extension::E::@def::2
          setters
            set y= @-1
              reference: <testLibraryFragment>::@extension::E::@def::2::@setter::y
              enclosingFragment: <testLibraryFragment>::@extension::E::@def::2
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
      enclosingElement: <testLibrary>
      extensionTypes
        E @15
          reference: <testLibraryFragment>::@extensionType::E::@def::0
          enclosingElement: <testLibraryFragment>
          representation: <testLibraryFragment>::@extensionType::E::@def::0::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::E::@def::0::@constructor::new
          typeErasure: int
          fields
            final it @21
              reference: <testLibraryFragment>::@extensionType::E::@def::0::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::E::@def::0
              type: int
          constructors
            @15
              reference: <testLibraryFragment>::@extensionType::E::@def::0::@constructor::new
              enclosingElement: <testLibraryFragment>::@extensionType::E::@def::0
              parameters
                requiredPositional final this.it @21
                  type: int
                  field: <testLibraryFragment>::@extensionType::E::@def::0::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::E::@def::0::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::E::@def::0
              returnType: int
        E @43
          reference: <testLibraryFragment>::@extensionType::E::@def::1
          enclosingElement: <testLibraryFragment>
          representation: <testLibraryFragment>::@extensionType::E::@def::1::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::E::@def::1::@constructor::new
          typeErasure: double
          fields
            final it @52
              reference: <testLibraryFragment>::@extensionType::E::@def::1::@field::it
              enclosingElement: <testLibraryFragment>::@extensionType::E::@def::1
              type: double
          constructors
            @43
              reference: <testLibraryFragment>::@extensionType::E::@def::1::@constructor::new
              enclosingElement: <testLibraryFragment>::@extensionType::E::@def::1
              parameters
                requiredPositional final this.it @52
                  type: double
                  field: <testLibraryFragment>::@extensionType::E::@def::1::@field::it
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::E::@def::1::@getter::it
              enclosingElement: <testLibraryFragment>::@extensionType::E::@def::1
              returnType: double
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      extensionTypes
        extension type E @15
          reference: <testLibraryFragment>::@extensionType::E::@def::0
          fields
            it @21
              reference: <testLibraryFragment>::@extensionType::E::@def::0::@field::it
              enclosingFragment: <testLibraryFragment>::@extensionType::E::@def::0
          constructors
            new @15
              reference: <testLibraryFragment>::@extensionType::E::@def::0::@constructor::new
              enclosingFragment: <testLibraryFragment>::@extensionType::E::@def::0
          getters
            get it @-1
              reference: <testLibraryFragment>::@extensionType::E::@def::0::@getter::it
              enclosingFragment: <testLibraryFragment>::@extensionType::E::@def::0
        extension type E @43
          reference: <testLibraryFragment>::@extensionType::E::@def::1
          fields
            it @52
              reference: <testLibraryFragment>::@extensionType::E::@def::1::@field::it
              enclosingFragment: <testLibraryFragment>::@extensionType::E::@def::1
          constructors
            new @43
              reference: <testLibraryFragment>::@extensionType::E::@def::1::@constructor::new
              enclosingFragment: <testLibraryFragment>::@extensionType::E::@def::1
          getters
            get it @-1
              reference: <testLibraryFragment>::@extensionType::E::@def::1::@getter::it
              enclosingFragment: <testLibraryFragment>::@extensionType::E::@def::1
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
      enclosingElement: <testLibrary>
      functions
        f @5
          reference: <testLibraryFragment>::@function::f::@def::0
          enclosingElement: <testLibraryFragment>
          returnType: void
        f @17
          reference: <testLibraryFragment>::@function::f::@def::1
          enclosingElement: <testLibraryFragment>
          parameters
            requiredPositional a @23
              type: int
          returnType: void
        f @34
          reference: <testLibraryFragment>::@function::f::@def::2
          enclosingElement: <testLibraryFragment>
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
      enclosingElement: <testLibrary>
      functions
        f @5
          reference: <testLibraryFragment>::@function::f
          enclosingElement: <testLibraryFragment>
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
      enclosingElement: <testLibrary>
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
      enclosingElement: <testLibrary>
      mixins
        mixin A @6
          reference: <testLibraryFragment>::@mixin::A::@def::0
          enclosingElement: <testLibraryFragment>
          superclassConstraints
            Object
        mixin A @17
          reference: <testLibraryFragment>::@mixin::A::@def::1
          enclosingElement: <testLibraryFragment>
          superclassConstraints
            Object
          fields
            x @27
              reference: <testLibraryFragment>::@mixin::A::@def::1::@field::x
              enclosingElement: <testLibraryFragment>::@mixin::A::@def::1
              type: dynamic
          accessors
            synthetic get x @-1
              reference: <testLibraryFragment>::@mixin::A::@def::1::@getter::x
              enclosingElement: <testLibraryFragment>::@mixin::A::@def::1
              returnType: dynamic
            synthetic set x= @-1
              reference: <testLibraryFragment>::@mixin::A::@def::1::@setter::x
              enclosingElement: <testLibraryFragment>::@mixin::A::@def::1
              parameters
                requiredPositional _x @-1
                  type: dynamic
              returnType: void
        mixin A @38
          reference: <testLibraryFragment>::@mixin::A::@def::2
          enclosingElement: <testLibraryFragment>
          superclassConstraints
            Object
          fields
            y @48
              reference: <testLibraryFragment>::@mixin::A::@def::2::@field::y
              enclosingElement: <testLibraryFragment>::@mixin::A::@def::2
              type: int
              shouldUseTypeForInitializerInference: false
          accessors
            synthetic get y @-1
              reference: <testLibraryFragment>::@mixin::A::@def::2::@getter::y
              enclosingElement: <testLibraryFragment>::@mixin::A::@def::2
              returnType: int
            synthetic set y= @-1
              reference: <testLibraryFragment>::@mixin::A::@def::2::@setter::y
              enclosingElement: <testLibraryFragment>::@mixin::A::@def::2
              parameters
                requiredPositional _y @-1
                  type: int
              returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      mixins
        mixin A @6
          reference: <testLibraryFragment>::@mixin::A::@def::0
        mixin A @17
          reference: <testLibraryFragment>::@mixin::A::@def::1
          fields
            x @27
              reference: <testLibraryFragment>::@mixin::A::@def::1::@field::x
              enclosingFragment: <testLibraryFragment>::@mixin::A::@def::1
          getters
            get x @-1
              reference: <testLibraryFragment>::@mixin::A::@def::1::@getter::x
              enclosingFragment: <testLibraryFragment>::@mixin::A::@def::1
          setters
            set x= @-1
              reference: <testLibraryFragment>::@mixin::A::@def::1::@setter::x
              enclosingFragment: <testLibraryFragment>::@mixin::A::@def::1
        mixin A @38
          reference: <testLibraryFragment>::@mixin::A::@def::2
          fields
            y @48
              reference: <testLibraryFragment>::@mixin::A::@def::2::@field::y
              enclosingFragment: <testLibraryFragment>::@mixin::A::@def::2
          getters
            get y @-1
              reference: <testLibraryFragment>::@mixin::A::@def::2::@getter::y
              enclosingFragment: <testLibraryFragment>::@mixin::A::@def::2
          setters
            set y= @-1
              reference: <testLibraryFragment>::@mixin::A::@def::2::@setter::y
              enclosingFragment: <testLibraryFragment>::@mixin::A::@def::2
  mixins
    mixin A
      reference: <testLibraryFragment>::@mixin::A::@def::0
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@mixin::A::@def::0
      superclassConstraints
        Object
    mixin A
      reference: <testLibraryFragment>::@mixin::A::@def::1
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@mixin::A::@def::1
      superclassConstraints
        Object
      fields
        x
          reference: <none>
          enclosingElement: <testLibraryFragment>::@mixin::A::@def::1
          type: dynamic
          firstFragment: <testLibraryFragment>::@mixin::A::@def::1::@field::x
      getters
        synthetic get x
          reference: <none>
          enclosingElement: <testLibraryFragment>::@mixin::A::@def::1
          firstFragment: <testLibraryFragment>::@mixin::A::@def::1::@getter::x
      setters
        synthetic set x=
          reference: <none>
          enclosingElement: <testLibraryFragment>::@mixin::A::@def::1
          firstFragment: <testLibraryFragment>::@mixin::A::@def::1::@setter::x
    mixin A
      reference: <testLibraryFragment>::@mixin::A::@def::2
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@mixin::A::@def::2
      superclassConstraints
        Object
      fields
        y
          reference: <none>
          enclosingElement: <testLibraryFragment>::@mixin::A::@def::2
          type: int
          firstFragment: <testLibraryFragment>::@mixin::A::@def::2::@field::y
      getters
        synthetic get y
          reference: <none>
          enclosingElement: <testLibraryFragment>::@mixin::A::@def::2
          firstFragment: <testLibraryFragment>::@mixin::A::@def::2::@getter::y
      setters
        synthetic set y=
          reference: <none>
          enclosingElement: <testLibraryFragment>::@mixin::A::@def::2
          firstFragment: <testLibraryFragment>::@mixin::A::@def::2::@setter::y
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
      enclosingElement: <testLibrary>
      topLevelVariables
        static x @5
          reference: <testLibraryFragment>::@topLevelVariable::x::@def::0
          enclosingElement: <testLibraryFragment>
          type: bool
          id: variable_0
          getter: getter_0
          setter: setter_0
        static x @12
          reference: <testLibraryFragment>::@topLevelVariable::x::@def::1
          enclosingElement: <testLibraryFragment>
          type: dynamic
          id: variable_1
          getter: getter_1
          setter: setter_1
        static final x @21
          reference: <testLibraryFragment>::@topLevelVariable::x::@def::2
          enclosingElement: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          id: variable_2
          getter: getter_2
        static x @32
          reference: <testLibraryFragment>::@topLevelVariable::x::@def::3
          enclosingElement: <testLibraryFragment>
          type: double
          shouldUseTypeForInitializerInference: false
          id: variable_3
          getter: getter_3
          setter: setter_2
      accessors
        synthetic static get x @-1
          reference: <testLibraryFragment>::@getter::x::@def::0
          enclosingElement: <testLibraryFragment>
          returnType: bool
          id: getter_0
          variable: variable_0
        synthetic static set x= @-1
          reference: <testLibraryFragment>::@setter::x::@def::0
          enclosingElement: <testLibraryFragment>
          parameters
            requiredPositional _x @-1
              type: bool
          returnType: void
          id: setter_0
          variable: variable_0
        synthetic static get x @-1
          reference: <testLibraryFragment>::@getter::x::@def::1
          enclosingElement: <testLibraryFragment>
          returnType: dynamic
          id: getter_1
          variable: variable_1
        synthetic static set x= @-1
          reference: <testLibraryFragment>::@setter::x::@def::1
          enclosingElement: <testLibraryFragment>
          parameters
            requiredPositional _x @-1
              type: dynamic
          returnType: void
          id: setter_1
          variable: variable_1
        synthetic static get x @-1
          reference: <testLibraryFragment>::@getter::x::@def::2
          enclosingElement: <testLibraryFragment>
          returnType: int
          id: getter_2
          variable: variable_2
        synthetic static get x @-1
          reference: <testLibraryFragment>::@getter::x::@def::3
          enclosingElement: <testLibraryFragment>
          returnType: double
          id: getter_3
          variable: variable_3
        synthetic static set x= @-1
          reference: <testLibraryFragment>::@setter::x::@def::2
          enclosingElement: <testLibraryFragment>
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
      enclosingElement: <testLibrary>
      topLevelVariables
        synthetic static foo @-1
          reference: <testLibraryFragment>::@topLevelVariable::foo
          enclosingElement: <testLibraryFragment>
          type: double
          id: variable_0
          getter: getter_0
      accessors
        static get foo @8
          reference: <testLibraryFragment>::@getter::foo::@def::0
          enclosingElement: <testLibraryFragment>
          returnType: int
          id: getter_1
          variable: variable_0
        static get foo @26
          reference: <testLibraryFragment>::@getter::foo::@def::1
          enclosingElement: <testLibraryFragment>
          returnType: double
          id: getter_0
          variable: variable_0
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
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
      enclosingElement: <testLibrary>
      topLevelVariables
        synthetic static foo @-1
          reference: <testLibraryFragment>::@topLevelVariable::foo
          enclosingElement: <testLibraryFragment>
          type: double
          id: variable_0
          setter: setter_0
      accessors
        static set foo= @4
          reference: <testLibraryFragment>::@setter::foo::@def::0
          enclosingElement: <testLibraryFragment>
          parameters
            requiredPositional _ @12
              type: int
          returnType: void
          id: setter_1
          variable: variable_0
        static set foo= @22
          reference: <testLibraryFragment>::@setter::foo::@def::1
          enclosingElement: <testLibraryFragment>
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
