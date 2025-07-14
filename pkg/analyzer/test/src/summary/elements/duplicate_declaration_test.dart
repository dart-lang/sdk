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
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A @6
          element: <testLibrary>::@class::A::@def::0
          fields
            #F2 hasInitializer f01 @25
              element: <testLibrary>::@class::A::@def::0::@field::f01
              initializer: expression_0
                IntegerLiteral
                  literal: 0 @31
                  staticType: int
            #F3 hasInitializer f02 @49
              element: <testLibrary>::@class::A::@def::0::@field::f02
              initializer: expression_1
                SimpleIdentifier
                  token: f01 @55
                  element: <testLibrary>::@class::A::@def::0::@getter::f01
                  staticType: int
          constructors
            #F4 synthetic new
              element: <testLibrary>::@class::A::@def::0::@constructor::new
              typeName: A
          getters
            #F5 synthetic f01
              element: <testLibrary>::@class::A::@def::0::@getter::f01
            #F6 synthetic f02
              element: <testLibrary>::@class::A::@def::0::@getter::f02
        #F7 class A @69
          element: <testLibrary>::@class::A::@def::1
          fields
            #F8 hasInitializer f11 @88
              element: <testLibrary>::@class::A::@def::1::@field::f11
              initializer: expression_2
                IntegerLiteral
                  literal: 0 @94
                  staticType: int
            #F9 hasInitializer f12 @112
              element: <testLibrary>::@class::A::@def::1::@field::f12
              initializer: expression_3
                SimpleIdentifier
                  token: f11 @118
                  element: <testLibrary>::@class::A::@def::1::@getter::f11
                  staticType: int
          constructors
            #F10 synthetic new
              element: <testLibrary>::@class::A::@def::1::@constructor::new
              typeName: A
          getters
            #F11 synthetic f11
              element: <testLibrary>::@class::A::@def::1::@getter::f11
            #F12 synthetic f12
              element: <testLibrary>::@class::A::@def::1::@getter::f12
        #F13 class A @132
          element: <testLibrary>::@class::A::@def::2
          fields
            #F14 hasInitializer f21 @151
              element: <testLibrary>::@class::A::@def::2::@field::f21
              initializer: expression_4
                IntegerLiteral
                  literal: 0 @157
                  staticType: int
            #F15 hasInitializer f22 @175
              element: <testLibrary>::@class::A::@def::2::@field::f22
              initializer: expression_5
                SimpleIdentifier
                  token: f21 @181
                  element: <testLibrary>::@class::A::@def::2::@getter::f21
                  staticType: int
          constructors
            #F16 synthetic new
              element: <testLibrary>::@class::A::@def::2::@constructor::new
              typeName: A
          getters
            #F17 synthetic f21
              element: <testLibrary>::@class::A::@def::2::@getter::f21
            #F18 synthetic f22
              element: <testLibrary>::@class::A::@def::2::@getter::f22
  classes
    class A
      reference: <testLibrary>::@class::A::@def::0
      firstFragment: #F1
      fields
        static const hasInitializer f01
          reference: <testLibrary>::@class::A::@def::0::@field::f01
          firstFragment: #F2
          type: int
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@class::A::@def::0::@getter::f01
        static const hasInitializer f02
          reference: <testLibrary>::@class::A::@def::0::@field::f02
          firstFragment: #F3
          type: int
          constantInitializer
            fragment: #F3
            expression: expression_1
          getter: <testLibrary>::@class::A::@def::0::@getter::f02
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@def::0::@constructor::new
          firstFragment: #F4
      getters
        synthetic static f01
          reference: <testLibrary>::@class::A::@def::0::@getter::f01
          firstFragment: #F5
          returnType: int
          variable: <testLibrary>::@class::A::@def::0::@field::f01
        synthetic static f02
          reference: <testLibrary>::@class::A::@def::0::@getter::f02
          firstFragment: #F6
          returnType: int
          variable: <testLibrary>::@class::A::@def::0::@field::f02
    class A
      reference: <testLibrary>::@class::A::@def::1
      firstFragment: #F7
      fields
        static const hasInitializer f11
          reference: <testLibrary>::@class::A::@def::1::@field::f11
          firstFragment: #F8
          type: int
          constantInitializer
            fragment: #F8
            expression: expression_2
          getter: <testLibrary>::@class::A::@def::1::@getter::f11
        static const hasInitializer f12
          reference: <testLibrary>::@class::A::@def::1::@field::f12
          firstFragment: #F9
          type: int
          constantInitializer
            fragment: #F9
            expression: expression_3
          getter: <testLibrary>::@class::A::@def::1::@getter::f12
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@def::1::@constructor::new
          firstFragment: #F10
      getters
        synthetic static f11
          reference: <testLibrary>::@class::A::@def::1::@getter::f11
          firstFragment: #F11
          returnType: int
          variable: <testLibrary>::@class::A::@def::1::@field::f11
        synthetic static f12
          reference: <testLibrary>::@class::A::@def::1::@getter::f12
          firstFragment: #F12
          returnType: int
          variable: <testLibrary>::@class::A::@def::1::@field::f12
    class A
      reference: <testLibrary>::@class::A::@def::2
      firstFragment: #F13
      fields
        static const hasInitializer f21
          reference: <testLibrary>::@class::A::@def::2::@field::f21
          firstFragment: #F14
          type: int
          constantInitializer
            fragment: #F14
            expression: expression_4
          getter: <testLibrary>::@class::A::@def::2::@getter::f21
        static const hasInitializer f22
          reference: <testLibrary>::@class::A::@def::2::@field::f22
          firstFragment: #F15
          type: int
          constantInitializer
            fragment: #F15
            expression: expression_5
          getter: <testLibrary>::@class::A::@def::2::@getter::f22
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@def::2::@constructor::new
          firstFragment: #F16
      getters
        synthetic static f21
          reference: <testLibrary>::@class::A::@def::2::@getter::f21
          firstFragment: #F17
          returnType: int
          variable: <testLibrary>::@class::A::@def::2::@field::f21
        synthetic static f22
          reference: <testLibrary>::@class::A::@def::2::@getter::f22
          firstFragment: #F18
          returnType: int
          variable: <testLibrary>::@class::A::@def::2::@field::f22
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
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A @6
          element: <testLibrary>::@class::A
          constructors
            #F2 named @14
              element: <testLibrary>::@class::A::@constructor::named::@def::0
              typeName: A
              typeNameOffset: 12
              periodOffset: 13
            #F3 named @27
              element: <testLibrary>::@class::A::@constructor::named::@def::1
              typeName: A
              typeNameOffset: 25
              periodOffset: 26
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        named
          reference: <testLibrary>::@class::A::@constructor::named::@def::0
          firstFragment: #F2
        named
          reference: <testLibrary>::@class::A::@constructor::named::@def::1
          firstFragment: #F3
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
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A @6
          element: <testLibrary>::@class::A
          fields
            #F2 foo @16
              element: <testLibrary>::@class::A::@field::foo::@def::0
            #F3 foo @30
              element: <testLibrary>::@class::A::@field::foo::@def::1
          constructors
            #F4 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F5 synthetic foo
              element: <testLibrary>::@class::A::@getter::foo::@def::0
            #F6 synthetic foo
              element: <testLibrary>::@class::A::@getter::foo::@def::1
          setters
            #F7 synthetic foo
              element: <testLibrary>::@class::A::@setter::foo::@def::0
              formalParameters
                #F8 _foo
                  element: <testLibrary>::@class::A::@setter::foo::@def::0::@formalParameter::_foo
            #F9 synthetic foo
              element: <testLibrary>::@class::A::@setter::foo::@def::1
              formalParameters
                #F10 _foo
                  element: <testLibrary>::@class::A::@setter::foo::@def::1::@formalParameter::_foo
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        foo
          reference: <testLibrary>::@class::A::@field::foo::@def::0
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@class::A::@getter::foo::@def::0
          setter: <testLibrary>::@class::A::@setter::foo::@def::0
        foo
          reference: <testLibrary>::@class::A::@field::foo::@def::1
          firstFragment: #F3
          type: double
          getter: <testLibrary>::@class::A::@getter::foo::@def::1
          setter: <testLibrary>::@class::A::@setter::foo::@def::1
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F4
      getters
        synthetic foo
          reference: <testLibrary>::@class::A::@getter::foo::@def::0
          firstFragment: #F5
          returnType: int
          variable: <testLibrary>::@class::A::@field::foo::@def::0
        synthetic foo
          reference: <testLibrary>::@class::A::@getter::foo::@def::1
          firstFragment: #F6
          returnType: double
          variable: <testLibrary>::@class::A::@field::foo::@def::1
      setters
        synthetic foo
          reference: <testLibrary>::@class::A::@setter::foo::@def::0
          firstFragment: #F7
          formalParameters
            #E0 requiredPositional _foo
              firstFragment: #F8
              type: int
          returnType: void
        synthetic foo
          reference: <testLibrary>::@class::A::@setter::foo::@def::1
          firstFragment: #F9
          formalParameters
            #E1 requiredPositional _foo
              firstFragment: #F10
              type: double
          returnType: void
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
            #F3 foo @17
              element: <testLibrary>::@class::A::@method::foo::@def::0
            #F4 foo @33
              element: <testLibrary>::@class::A::@method::foo::@def::1
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
          reference: <testLibrary>::@class::A::@method::foo::@def::0
          firstFragment: #F3
          returnType: void
        foo
          reference: <testLibrary>::@class::A::@method::foo::@def::1
          firstFragment: #F4
          returnType: void
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
        #F3 class B @17
          element: <testLibrary>::@class::B
          constructors
            #F4 synthetic new
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
        #F5 class X @28
          element: <testLibrary>::@class::X::@def::0
          constructors
            #F6 synthetic new
              element: <testLibrary>::@class::X::@def::0::@constructor::new
              typeName: X
        #F7 class X @48
          element: <testLibrary>::@class::X::@def::1
          constructors
            #F8 synthetic new
              element: <testLibrary>::@class::X::@def::1::@constructor::new
              typeName: X
      mixins
        #F9 mixin M @68
          element: <testLibrary>::@mixin::M
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
    class alias X
      reference: <testLibrary>::@class::X::@def::0
      firstFragment: #F5
      supertype: A
      mixins
        M
      constructors
        synthetic new
          reference: <testLibrary>::@class::X::@def::0::@constructor::new
          firstFragment: #F6
          constantInitializers
            SuperConstructorInvocation
              superKeyword: super @0
              argumentList: ArgumentList
                leftParenthesis: ( @0
                rightParenthesis: ) @0
              element: <testLibrary>::@class::A::@constructor::new
          superConstructor: <testLibrary>::@class::A::@constructor::new
    class alias X
      reference: <testLibrary>::@class::X::@def::1
      firstFragment: #F7
      supertype: B
      mixins
        M
      constructors
        synthetic new
          reference: <testLibrary>::@class::X::@def::1::@constructor::new
          firstFragment: #F8
          constantInitializers
            SuperConstructorInvocation
              superKeyword: super @0
              argumentList: ArgumentList
                leftParenthesis: ( @0
                rightParenthesis: ) @0
              element: <testLibrary>::@class::B::@constructor::new
          superConstructor: <testLibrary>::@class::B::@constructor::new
  mixins
    mixin M
      reference: <testLibrary>::@mixin::M
      firstFragment: #F9
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
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      enums
        #F1 enum E @5
          element: <testLibrary>::@enum::E::@def::0
          fields
            #F2 hasInitializer a @8
              element: <testLibrary>::@enum::E::@def::0::@field::a
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element2: <testLibrary>::@enum::E::@def::0
                      type: E
                    element: <testLibrary>::@enum::E::@def::0::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            #F3 hasInitializer b @11
              element: <testLibrary>::@enum::E::@def::0::@field::b
              initializer: expression_1
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element2: <testLibrary>::@enum::E::@def::0
                      type: E
                    element: <testLibrary>::@enum::E::@def::0::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            #F4 synthetic values
              element: <testLibrary>::@enum::E::@def::0::@field::values
              initializer: expression_2
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: a @-1
                      element: <testLibrary>::@enum::E::@def::0::@getter::a
                      staticType: E
                    SimpleIdentifier
                      token: b @-1
                      element: <testLibrary>::@enum::E::@def::0::@getter::b
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
          constructors
            #F5 synthetic const new
              element: <testLibrary>::@enum::E::@def::0::@constructor::new
              typeName: E
          getters
            #F6 synthetic a
              element: <testLibrary>::@enum::E::@def::0::@getter::a
            #F7 synthetic b
              element: <testLibrary>::@enum::E::@def::0::@getter::b
            #F8 synthetic values
              element: <testLibrary>::@enum::E::@def::0::@getter::values
        #F9 enum E @19
          element: <testLibrary>::@enum::E::@def::1
          fields
            #F10 hasInitializer c @22
              element: <testLibrary>::@enum::E::@def::1::@field::c
              initializer: expression_3
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element2: <testLibrary>::@enum::E::@def::0
                      type: E
                    element: <testLibrary>::@enum::E::@def::0::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            #F11 hasInitializer d @25
              element: <testLibrary>::@enum::E::@def::1::@field::d
              initializer: expression_4
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element2: <testLibrary>::@enum::E::@def::0
                      type: E
                    element: <testLibrary>::@enum::E::@def::0::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            #F12 hasInitializer e @28
              element: <testLibrary>::@enum::E::@def::1::@field::e
              initializer: expression_5
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element2: <testLibrary>::@enum::E::@def::0
                      type: E
                    element: <testLibrary>::@enum::E::@def::0::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            #F13 synthetic values
              element: <testLibrary>::@enum::E::@def::1::@field::values
              initializer: expression_6
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: c @-1
                      element: <testLibrary>::@enum::E::@def::1::@getter::c
                      staticType: E
                    SimpleIdentifier
                      token: d @-1
                      element: <testLibrary>::@enum::E::@def::1::@getter::d
                      staticType: E
                    SimpleIdentifier
                      token: e @-1
                      element: <testLibrary>::@enum::E::@def::1::@getter::e
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
          constructors
            #F14 synthetic const new
              element: <testLibrary>::@enum::E::@def::1::@constructor::new
              typeName: E
          getters
            #F15 synthetic c
              element: <testLibrary>::@enum::E::@def::1::@getter::c
            #F16 synthetic d
              element: <testLibrary>::@enum::E::@def::1::@getter::d
            #F17 synthetic e
              element: <testLibrary>::@enum::E::@def::1::@getter::e
            #F18 synthetic values
              element: <testLibrary>::@enum::E::@def::1::@getter::values
  enums
    enum E
      reference: <testLibrary>::@enum::E::@def::0
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasInitializer a
          reference: <testLibrary>::@enum::E::@def::0::@field::a
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@def::0::@getter::a
        static const enumConstant hasInitializer b
          reference: <testLibrary>::@enum::E::@def::0::@field::b
          firstFragment: #F3
          type: E
          constantInitializer
            fragment: #F3
            expression: expression_1
          getter: <testLibrary>::@enum::E::@def::0::@getter::b
        synthetic static const values
          reference: <testLibrary>::@enum::E::@def::0::@field::values
          firstFragment: #F4
          type: List<E>
          constantInitializer
            fragment: #F4
            expression: expression_2
          getter: <testLibrary>::@enum::E::@def::0::@getter::values
      constructors
        synthetic const new
          reference: <testLibrary>::@enum::E::@def::0::@constructor::new
          firstFragment: #F5
      getters
        synthetic static a
          reference: <testLibrary>::@enum::E::@def::0::@getter::a
          firstFragment: #F6
          returnType: E
          variable: <testLibrary>::@enum::E::@def::0::@field::a
        synthetic static b
          reference: <testLibrary>::@enum::E::@def::0::@getter::b
          firstFragment: #F7
          returnType: E
          variable: <testLibrary>::@enum::E::@def::0::@field::b
        synthetic static values
          reference: <testLibrary>::@enum::E::@def::0::@getter::values
          firstFragment: #F8
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@def::0::@field::values
    enum E
      reference: <testLibrary>::@enum::E::@def::1
      firstFragment: #F9
      supertype: Enum
      fields
        static const enumConstant hasInitializer c
          reference: <testLibrary>::@enum::E::@def::1::@field::c
          firstFragment: #F10
          type: E
          constantInitializer
            fragment: #F10
            expression: expression_3
          getter: <testLibrary>::@enum::E::@def::1::@getter::c
        static const enumConstant hasInitializer d
          reference: <testLibrary>::@enum::E::@def::1::@field::d
          firstFragment: #F11
          type: E
          constantInitializer
            fragment: #F11
            expression: expression_4
          getter: <testLibrary>::@enum::E::@def::1::@getter::d
        static const enumConstant hasInitializer e
          reference: <testLibrary>::@enum::E::@def::1::@field::e
          firstFragment: #F12
          type: E
          constantInitializer
            fragment: #F12
            expression: expression_5
          getter: <testLibrary>::@enum::E::@def::1::@getter::e
        synthetic static const values
          reference: <testLibrary>::@enum::E::@def::1::@field::values
          firstFragment: #F13
          type: List<E>
          constantInitializer
            fragment: #F13
            expression: expression_6
          getter: <testLibrary>::@enum::E::@def::1::@getter::values
      constructors
        synthetic const new
          reference: <testLibrary>::@enum::E::@def::1::@constructor::new
          firstFragment: #F14
      getters
        synthetic static c
          reference: <testLibrary>::@enum::E::@def::1::@getter::c
          firstFragment: #F15
          returnType: E
          variable: <testLibrary>::@enum::E::@def::1::@field::c
        synthetic static d
          reference: <testLibrary>::@enum::E::@def::1::@getter::d
          firstFragment: #F16
          returnType: E
          variable: <testLibrary>::@enum::E::@def::1::@field::d
        synthetic static e
          reference: <testLibrary>::@enum::E::@def::1::@getter::e
          firstFragment: #F17
          returnType: E
          variable: <testLibrary>::@enum::E::@def::1::@field::e
        synthetic static values
          reference: <testLibrary>::@enum::E::@def::1::@getter::values
          firstFragment: #F18
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@def::1::@field::values
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
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensions
        #F1 extension E @10
          element: <testLibrary>::@extension::E::@def::0
        #F2 extension E @32
          element: <testLibrary>::@extension::E::@def::1
          fields
            #F3 x @56
              element: <testLibrary>::@extension::E::@def::1::@field::x
          getters
            #F4 synthetic x
              element: <testLibrary>::@extension::E::@def::1::@getter::x
          setters
            #F5 synthetic x
              element: <testLibrary>::@extension::E::@def::1::@setter::x
              formalParameters
                #F6 _x
                  element: <testLibrary>::@extension::E::@def::1::@setter::x::@formalParameter::_x
        #F7 extension E @71
          element: <testLibrary>::@extension::E::@def::2
          fields
            #F8 hasInitializer y @95
              element: <testLibrary>::@extension::E::@def::2::@field::y
          getters
            #F9 synthetic y
              element: <testLibrary>::@extension::E::@def::2::@getter::y
          setters
            #F10 synthetic y
              element: <testLibrary>::@extension::E::@def::2::@setter::y
              formalParameters
                #F11 _y
                  element: <testLibrary>::@extension::E::@def::2::@setter::y::@formalParameter::_y
  extensions
    extension E
      reference: <testLibrary>::@extension::E::@def::0
      firstFragment: #F1
      extendedType: int
    extension E
      reference: <testLibrary>::@extension::E::@def::1
      firstFragment: #F2
      extendedType: int
      fields
        static x
          reference: <testLibrary>::@extension::E::@def::1::@field::x
          firstFragment: #F3
          type: dynamic
          getter: <testLibrary>::@extension::E::@def::1::@getter::x
          setter: <testLibrary>::@extension::E::@def::1::@setter::x
      getters
        synthetic static x
          reference: <testLibrary>::@extension::E::@def::1::@getter::x
          firstFragment: #F4
          returnType: dynamic
          variable: <testLibrary>::@extension::E::@def::1::@field::x
      setters
        synthetic static x
          reference: <testLibrary>::@extension::E::@def::1::@setter::x
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional _x
              firstFragment: #F6
              type: dynamic
          returnType: void
    extension E
      reference: <testLibrary>::@extension::E::@def::2
      firstFragment: #F7
      extendedType: int
      fields
        static hasInitializer y
          reference: <testLibrary>::@extension::E::@def::2::@field::y
          firstFragment: #F8
          type: int
          getter: <testLibrary>::@extension::E::@def::2::@getter::y
          setter: <testLibrary>::@extension::E::@def::2::@setter::y
      getters
        synthetic static y
          reference: <testLibrary>::@extension::E::@def::2::@getter::y
          firstFragment: #F9
          returnType: int
          variable: <testLibrary>::@extension::E::@def::2::@field::y
      setters
        synthetic static y
          reference: <testLibrary>::@extension::E::@def::2::@setter::y
          firstFragment: #F10
          formalParameters
            #E1 requiredPositional _y
              firstFragment: #F11
              type: int
          returnType: void
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
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensionTypes
        #F1 extension type E @15
          element: <testLibrary>::@extensionType::E::@def::0
          fields
            #F2 it @21
              element: <testLibrary>::@extensionType::E::@def::0::@field::it
          constructors
            #F3 new
              element: <testLibrary>::@extensionType::E::@def::0::@constructor::new
              typeName: E
              typeNameOffset: 15
              formalParameters
                #F4 this.it @21
                  element: <testLibrary>::@extensionType::E::@def::0::@constructor::new::@formalParameter::it
          getters
            #F5 synthetic it
              element: <testLibrary>::@extensionType::E::@def::0::@getter::it
        #F6 extension type E @43
          element: <testLibrary>::@extensionType::E::@def::1
          fields
            #F7 it @52
              element: <testLibrary>::@extensionType::E::@def::1::@field::it
          constructors
            #F8 new
              element: <testLibrary>::@extensionType::E::@def::1::@constructor::new
              typeName: E
              typeNameOffset: 43
              formalParameters
                #F9 this.it @52
                  element: <testLibrary>::@extensionType::E::@def::1::@constructor::new::@formalParameter::it
          getters
            #F10 synthetic it
              element: <testLibrary>::@extensionType::E::@def::1::@getter::it
  extensionTypes
    extension type E
      reference: <testLibrary>::@extensionType::E::@def::0
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::E::@def::0::@field::it
      primaryConstructor: <testLibrary>::@extensionType::E::@def::0::@constructor::new
      typeErasure: int
      fields
        final it
          reference: <testLibrary>::@extensionType::E::@def::0::@field::it
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::E::@def::0::@getter::it
      constructors
        new
          reference: <testLibrary>::@extensionType::E::@def::0::@constructor::new
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional final hasImplicitType it
              firstFragment: #F4
              type: int
      getters
        synthetic it
          reference: <testLibrary>::@extensionType::E::@def::0::@getter::it
          firstFragment: #F5
          returnType: int
          variable: <testLibrary>::@extensionType::E::@def::0::@field::it
    extension type E
      reference: <testLibrary>::@extensionType::E::@def::1
      firstFragment: #F6
      representation: <testLibrary>::@extensionType::E::@def::1::@field::it
      primaryConstructor: <testLibrary>::@extensionType::E::@def::1::@constructor::new
      typeErasure: double
      fields
        final it
          reference: <testLibrary>::@extensionType::E::@def::1::@field::it
          firstFragment: #F7
          type: double
          getter: <testLibrary>::@extensionType::E::@def::1::@getter::it
      constructors
        new
          reference: <testLibrary>::@extensionType::E::@def::1::@constructor::new
          firstFragment: #F8
          formalParameters
            #E1 requiredPositional final hasImplicitType it
              firstFragment: #F9
              type: double
      getters
        synthetic it
          reference: <testLibrary>::@extensionType::E::@def::1::@getter::it
          firstFragment: #F10
          returnType: double
          variable: <testLibrary>::@extensionType::E::@def::1::@field::it
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
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      functions
        #F1 f @5
          element: <testLibrary>::@function::f::@def::0
        #F2 f @17
          element: <testLibrary>::@function::f::@def::1
          formalParameters
            #F3 a @23
              element: <testLibrary>::@function::f::@def::1::@formalParameter::a
        #F4 f @34
          element: <testLibrary>::@function::f::@def::2
          formalParameters
            #F5 b @41
              element: <testLibrary>::@function::f::@def::2::@formalParameter::b
            #F6 c @51
              element: <testLibrary>::@function::f::@def::2::@formalParameter::c
  functions
    f
      reference: <testLibrary>::@function::f::@def::0
      firstFragment: #F1
      returnType: void
    f
      reference: <testLibrary>::@function::f::@def::1
      firstFragment: #F2
      formalParameters
        #E0 requiredPositional a
          firstFragment: #F3
          type: int
      returnType: void
    f
      reference: <testLibrary>::@function::f::@def::2
      firstFragment: #F4
      formalParameters
        #E1 optionalPositional b
          firstFragment: #F5
          type: int
        #E2 optionalPositional c
          firstFragment: #F6
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
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      functions
        #F1 f @5
          element: <testLibrary>::@function::f
          formalParameters
            #F2 a @12
              element: <testLibrary>::@function::f::@formalParameter::a
            #F3 a @22
              element: <testLibrary>::@function::f::@formalParameter::a
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: #F1
      formalParameters
        #E0 optionalNamed a
          firstFragment: #F2
          type: int
        #E1 optionalNamed a
          firstFragment: #F3
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
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        #F1 F @13
          element: <testLibrary>::@typeAlias::F::@def::0
        #F2 F @31
          element: <testLibrary>::@typeAlias::F::@def::1
        #F3 F @54
          element: <testLibrary>::@typeAlias::F::@def::2
  typeAliases
    F
      reference: <testLibrary>::@typeAlias::F::@def::0
      firstFragment: #F1
      aliasedType: void Function()
    F
      reference: <testLibrary>::@typeAlias::F::@def::1
      firstFragment: #F2
      aliasedType: void Function(int)
    F
      reference: <testLibrary>::@typeAlias::F::@def::2
      firstFragment: #F3
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
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      mixins
        #F1 mixin A @6
          element: <testLibrary>::@mixin::A::@def::0
        #F2 mixin A @17
          element: <testLibrary>::@mixin::A::@def::1
          fields
            #F3 x @27
              element: <testLibrary>::@mixin::A::@def::1::@field::x
          getters
            #F4 synthetic x
              element: <testLibrary>::@mixin::A::@def::1::@getter::x
          setters
            #F5 synthetic x
              element: <testLibrary>::@mixin::A::@def::1::@setter::x
              formalParameters
                #F6 _x
                  element: <testLibrary>::@mixin::A::@def::1::@setter::x::@formalParameter::_x
        #F7 mixin A @38
          element: <testLibrary>::@mixin::A::@def::2
          fields
            #F8 hasInitializer y @48
              element: <testLibrary>::@mixin::A::@def::2::@field::y
          getters
            #F9 synthetic y
              element: <testLibrary>::@mixin::A::@def::2::@getter::y
          setters
            #F10 synthetic y
              element: <testLibrary>::@mixin::A::@def::2::@setter::y
              formalParameters
                #F11 _y
                  element: <testLibrary>::@mixin::A::@def::2::@setter::y::@formalParameter::_y
  mixins
    mixin A
      reference: <testLibrary>::@mixin::A::@def::0
      firstFragment: #F1
      superclassConstraints
        Object
    mixin A
      reference: <testLibrary>::@mixin::A::@def::1
      firstFragment: #F2
      superclassConstraints
        Object
      fields
        x
          reference: <testLibrary>::@mixin::A::@def::1::@field::x
          firstFragment: #F3
          type: dynamic
          getter: <testLibrary>::@mixin::A::@def::1::@getter::x
          setter: <testLibrary>::@mixin::A::@def::1::@setter::x
      getters
        synthetic x
          reference: <testLibrary>::@mixin::A::@def::1::@getter::x
          firstFragment: #F4
          returnType: dynamic
          variable: <testLibrary>::@mixin::A::@def::1::@field::x
      setters
        synthetic x
          reference: <testLibrary>::@mixin::A::@def::1::@setter::x
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional _x
              firstFragment: #F6
              type: dynamic
          returnType: void
    mixin A
      reference: <testLibrary>::@mixin::A::@def::2
      firstFragment: #F7
      superclassConstraints
        Object
      fields
        hasInitializer y
          reference: <testLibrary>::@mixin::A::@def::2::@field::y
          firstFragment: #F8
          type: int
          getter: <testLibrary>::@mixin::A::@def::2::@getter::y
          setter: <testLibrary>::@mixin::A::@def::2::@setter::y
      getters
        synthetic y
          reference: <testLibrary>::@mixin::A::@def::2::@getter::y
          firstFragment: #F9
          returnType: int
          variable: <testLibrary>::@mixin::A::@def::2::@field::y
      setters
        synthetic y
          reference: <testLibrary>::@mixin::A::@def::2::@setter::y
          firstFragment: #F10
          formalParameters
            #E1 requiredPositional _y
              firstFragment: #F11
              type: int
          returnType: void
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
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 x @5
          element: <testLibrary>::@topLevelVariable::x::@def::0
        #F2 x @12
          element: <testLibrary>::@topLevelVariable::x::@def::1
        #F3 hasInitializer x @21
          element: <testLibrary>::@topLevelVariable::x::@def::2
        #F4 hasInitializer x @32
          element: <testLibrary>::@topLevelVariable::x::@def::3
      getters
        #F5 synthetic x
          element: <testLibrary>::@getter::x::@def::0
        #F6 synthetic x
          element: <testLibrary>::@getter::x::@def::1
        #F7 synthetic x
          element: <testLibrary>::@getter::x::@def::2
        #F8 synthetic x
          element: <testLibrary>::@getter::x::@def::3
      setters
        #F9 synthetic x
          element: <testLibrary>::@setter::x::@def::0
          formalParameters
            #F10 _x
              element: <testLibrary>::@setter::x::@def::0::@formalParameter::_x
        #F11 synthetic x
          element: <testLibrary>::@setter::x::@def::1
          formalParameters
            #F12 _x
              element: <testLibrary>::@setter::x::@def::1::@formalParameter::_x
        #F13 synthetic x
          element: <testLibrary>::@setter::x::@def::2
          formalParameters
            #F14 _x
              element: <testLibrary>::@setter::x::@def::2::@formalParameter::_x
  topLevelVariables
    x
      reference: <testLibrary>::@topLevelVariable::x::@def::0
      firstFragment: #F1
      type: bool
      getter: <testLibrary>::@getter::x::@def::0
      setter: <testLibrary>::@setter::x::@def::0
    x
      reference: <testLibrary>::@topLevelVariable::x::@def::1
      firstFragment: #F2
      type: dynamic
      getter: <testLibrary>::@getter::x::@def::1
      setter: <testLibrary>::@setter::x::@def::1
    final hasInitializer x
      reference: <testLibrary>::@topLevelVariable::x::@def::2
      firstFragment: #F3
      type: int
      getter: <testLibrary>::@getter::x::@def::2
    hasInitializer x
      reference: <testLibrary>::@topLevelVariable::x::@def::3
      firstFragment: #F4
      type: double
      getter: <testLibrary>::@getter::x::@def::3
      setter: <testLibrary>::@setter::x::@def::2
  getters
    synthetic static x
      reference: <testLibrary>::@getter::x::@def::0
      firstFragment: #F5
      returnType: bool
      variable: <testLibrary>::@topLevelVariable::x::@def::0
    synthetic static x
      reference: <testLibrary>::@getter::x::@def::1
      firstFragment: #F6
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::x::@def::1
    synthetic static x
      reference: <testLibrary>::@getter::x::@def::2
      firstFragment: #F7
      returnType: int
      variable: <testLibrary>::@topLevelVariable::x::@def::2
    synthetic static x
      reference: <testLibrary>::@getter::x::@def::3
      firstFragment: #F8
      returnType: double
      variable: <testLibrary>::@topLevelVariable::x::@def::3
  setters
    synthetic static x
      reference: <testLibrary>::@setter::x::@def::0
      firstFragment: #F9
      formalParameters
        #E0 requiredPositional _x
          firstFragment: #F10
          type: bool
      returnType: void
    synthetic static x
      reference: <testLibrary>::@setter::x::@def::1
      firstFragment: #F11
      formalParameters
        #E1 requiredPositional _x
          firstFragment: #F12
          type: dynamic
      returnType: void
    synthetic static x
      reference: <testLibrary>::@setter::x::@def::2
      firstFragment: #F13
      formalParameters
        #E2 requiredPositional _x
          firstFragment: #F14
          type: double
      returnType: void
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
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 synthetic foo (offset=8)
          element: <testLibrary>::@topLevelVariable::foo::@def::0
        #F2 synthetic foo (offset=26)
          element: <testLibrary>::@topLevelVariable::foo::@def::1
      getters
        #F3 foo @8
          element: <testLibrary>::@getter::foo::@def::0
        #F4 foo @26
          element: <testLibrary>::@getter::foo::@def::1
  topLevelVariables
    synthetic foo
      reference: <testLibrary>::@topLevelVariable::foo::@def::0
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::foo::@def::0
    synthetic foo
      reference: <testLibrary>::@topLevelVariable::foo::@def::1
      firstFragment: #F2
      type: double
      getter: <testLibrary>::@getter::foo::@def::1
  getters
    static foo
      reference: <testLibrary>::@getter::foo::@def::0
      firstFragment: #F3
      returnType: int
      variable: <testLibrary>::@topLevelVariable::foo::@def::0
    static foo
      reference: <testLibrary>::@getter::foo::@def::1
      firstFragment: #F4
      returnType: double
      variable: <testLibrary>::@topLevelVariable::foo::@def::1
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
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 synthetic foo (offset=4)
          element: <testLibrary>::@topLevelVariable::foo::@def::0
        #F2 synthetic foo (offset=22)
          element: <testLibrary>::@topLevelVariable::foo::@def::1
      setters
        #F3 foo @4
          element: <testLibrary>::@setter::foo::@def::0
          formalParameters
            #F4 _ @12
              element: <testLibrary>::@setter::foo::@def::0::@formalParameter::_
        #F5 foo @22
          element: <testLibrary>::@setter::foo::@def::1
          formalParameters
            #F6 _ @33
              element: <testLibrary>::@setter::foo::@def::1::@formalParameter::_
  topLevelVariables
    synthetic foo
      reference: <testLibrary>::@topLevelVariable::foo::@def::0
      firstFragment: #F1
      type: int
      setter: <testLibrary>::@setter::foo::@def::0
    synthetic foo
      reference: <testLibrary>::@topLevelVariable::foo::@def::1
      firstFragment: #F2
      type: double
      setter: <testLibrary>::@setter::foo::@def::1
  setters
    static foo
      reference: <testLibrary>::@setter::foo::@def::0
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional _
          firstFragment: #F4
          type: int
      returnType: void
    static foo
      reference: <testLibrary>::@setter::foo::@def::1
      firstFragment: #F5
      formalParameters
        #E1 requiredPositional _
          firstFragment: #F6
          type: double
      returnType: void
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
