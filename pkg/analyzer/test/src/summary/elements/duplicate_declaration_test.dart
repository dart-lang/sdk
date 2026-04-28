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
        #F1 class A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::A
          fields
            #F2 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic f01 (nameOffset:25) (firstTokenOffset:25) (offset:25)
              element: <testLibrary>::@class::A::@field::f01
              initializer: expression_0
                IntegerLiteral
                  literal: 0 @31
                  staticType: int
            #F3 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic f02 (nameOffset:49) (firstTokenOffset:49) (offset:49)
              element: <testLibrary>::@class::A::@field::f02
              initializer: expression_1
                SimpleIdentifier
                  token: f01 @55
                  element: <testLibrary>::@class::A::@getter::f01
                  staticType: int
          constructors
            #F4 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F5 isCompleteDeclaration isOriginVariable isStatic f01 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
              element: <testLibrary>::@class::A::@getter::f01
            #F6 isCompleteDeclaration isOriginVariable isStatic f02 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:49)
              element: <testLibrary>::@class::A::@getter::f02
        #F7 class A (nameOffset:69) (firstTokenOffset:63) (offset:69)
          element: <testLibrary>::@class::A#1
          fields
            #F8 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic f11 (nameOffset:88) (firstTokenOffset:88) (offset:88)
              element: <testLibrary>::@class::A#1::@field::f11
              initializer: expression_2
                IntegerLiteral
                  literal: 0 @94
                  staticType: int
            #F9 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic f12 (nameOffset:112) (firstTokenOffset:112) (offset:112)
              element: <testLibrary>::@class::A#1::@field::f12
              initializer: expression_3
                SimpleIdentifier
                  token: f11 @118
                  element: <testLibrary>::@class::A#1::@getter::f11
                  staticType: int
          constructors
            #F10 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:69)
              element: <testLibrary>::@class::A#1::@constructor::new
              typeName: A
          getters
            #F11 isCompleteDeclaration isOriginVariable isStatic f11 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:88)
              element: <testLibrary>::@class::A#1::@getter::f11
            #F12 isCompleteDeclaration isOriginVariable isStatic f12 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:112)
              element: <testLibrary>::@class::A#1::@getter::f12
        #F13 class A (nameOffset:132) (firstTokenOffset:126) (offset:132)
          element: <testLibrary>::@class::A#2
          fields
            #F14 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic f21 (nameOffset:151) (firstTokenOffset:151) (offset:151)
              element: <testLibrary>::@class::A#2::@field::f21
              initializer: expression_4
                IntegerLiteral
                  literal: 0 @157
                  staticType: int
            #F15 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic f22 (nameOffset:175) (firstTokenOffset:175) (offset:175)
              element: <testLibrary>::@class::A#2::@field::f22
              initializer: expression_5
                SimpleIdentifier
                  token: f21 @181
                  element: <testLibrary>::@class::A#2::@getter::f21
                  staticType: int
          constructors
            #F16 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:132)
              element: <testLibrary>::@class::A#2::@constructor::new
              typeName: A
          getters
            #F17 isCompleteDeclaration isOriginVariable isStatic f21 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:151)
              element: <testLibrary>::@class::A#2::@getter::f21
            #F18 isCompleteDeclaration isOriginVariable isStatic f22 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:175)
              element: <testLibrary>::@class::A#2::@getter::f22
  classes
    isSimplyBounded class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer f01
          reference: <testLibrary>::@class::A::@field::f01
          firstFragment: #F2
          type: int
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@class::A::@getter::f01
        hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer f02
          reference: <testLibrary>::@class::A::@field::f02
          firstFragment: #F3
          type: int
          constantInitializer
            fragment: #F3
            expression: expression_1
          getter: <testLibrary>::@class::A::@getter::f02
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F4
      getters
        isOriginVariable isStatic f01
          reference: <testLibrary>::@class::A::@getter::f01
          firstFragment: #F5
          returnType: int
          variable: <testLibrary>::@class::A::@field::f01
        isOriginVariable isStatic f02
          reference: <testLibrary>::@class::A::@getter::f02
          firstFragment: #F6
          returnType: int
          variable: <testLibrary>::@class::A::@field::f02
    isSimplyBounded class A
      reference: <testLibrary>::@class::A#1
      firstFragment: #F7
      fields
        hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer f11
          reference: <testLibrary>::@class::A#1::@field::f11
          firstFragment: #F8
          type: int
          constantInitializer
            fragment: #F8
            expression: expression_2
          getter: <testLibrary>::@class::A#1::@getter::f11
        hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer f12
          reference: <testLibrary>::@class::A#1::@field::f12
          firstFragment: #F9
          type: int
          constantInitializer
            fragment: #F9
            expression: expression_3
          getter: <testLibrary>::@class::A#1::@getter::f12
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::A#1::@constructor::new
          firstFragment: #F10
      getters
        isOriginVariable isStatic f11
          reference: <testLibrary>::@class::A#1::@getter::f11
          firstFragment: #F11
          returnType: int
          variable: <testLibrary>::@class::A#1::@field::f11
        isOriginVariable isStatic f12
          reference: <testLibrary>::@class::A#1::@getter::f12
          firstFragment: #F12
          returnType: int
          variable: <testLibrary>::@class::A#1::@field::f12
    isSimplyBounded class A
      reference: <testLibrary>::@class::A#2
      firstFragment: #F13
      fields
        hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer f21
          reference: <testLibrary>::@class::A#2::@field::f21
          firstFragment: #F14
          type: int
          constantInitializer
            fragment: #F14
            expression: expression_4
          getter: <testLibrary>::@class::A#2::@getter::f21
        hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer f22
          reference: <testLibrary>::@class::A#2::@field::f22
          firstFragment: #F15
          type: int
          constantInitializer
            fragment: #F15
            expression: expression_5
          getter: <testLibrary>::@class::A#2::@getter::f22
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::A#2::@constructor::new
          firstFragment: #F16
      getters
        isOriginVariable isStatic f21
          reference: <testLibrary>::@class::A#2::@getter::f21
          firstFragment: #F17
          returnType: int
          variable: <testLibrary>::@class::A#2::@field::f21
        isOriginVariable isStatic f22
          reference: <testLibrary>::@class::A#2::@getter::f22
          firstFragment: #F18
          returnType: int
          variable: <testLibrary>::@class::A#2::@field::f22
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
        #F1 class A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::A
          constructors
            #F2 isOriginDeclaration named (nameOffset:14) (firstTokenOffset:12) (offset:14)
              element: <testLibrary>::@class::A::@constructor::named
              typeName: A
              typeNameOffset: 12
              periodOffset: 13
            #F3 isOriginDeclaration named (nameOffset:27) (firstTokenOffset:25) (offset:27)
              element: <testLibrary>::@class::A::@constructor::named#1
              typeName: A
              typeNameOffset: 25
              periodOffset: 26
  classes
    isSimplyBounded class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        isOriginDeclaration named
          reference: <testLibrary>::@class::A::@constructor::named
          firstFragment: #F2
        isOriginDeclaration named
          reference: <testLibrary>::@class::A::@constructor::named#1
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
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::A
          fields
            #F2 isOriginDeclaration foo (nameOffset:16) (firstTokenOffset:16) (offset:16)
              element: <testLibrary>::@class::A::@field::foo
            #F3 isOriginDeclaration foo (nameOffset:30) (firstTokenOffset:30) (offset:30)
              element: <testLibrary>::@class::A::@field::foo#1
          constructors
            #F4 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F5 isCompleteDeclaration isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@class::A::@getter::foo
            #F6 isCompleteDeclaration isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:30)
              element: <testLibrary>::@class::A::@getter::foo#1
          setters
            #F7 isCompleteDeclaration isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@class::A::@setter::foo
              formalParameters
                #F8 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
                  element: <testLibrary>::@class::A::@setter::foo::@formalParameter::value
            #F9 isCompleteDeclaration isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:30)
              element: <testLibrary>::@class::A::@setter::foo#1
              formalParameters
                #F10 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:30)
                  element: <testLibrary>::@class::A::@setter::foo#1::@formalParameter::value
  classes
    hasNonFinalField isSimplyBounded class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        isOriginDeclaration foo
          reference: <testLibrary>::@class::A::@field::foo
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@class::A::@getter::foo
          setter: <testLibrary>::@class::A::@setter::foo
        isOriginDeclaration foo
          reference: <testLibrary>::@class::A::@field::foo#1
          firstFragment: #F3
          type: double
          getter: <testLibrary>::@class::A::@getter::foo#1
          setter: <testLibrary>::@class::A::@setter::foo#1
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F4
      getters
        isOriginVariable foo
          reference: <testLibrary>::@class::A::@getter::foo
          firstFragment: #F5
          returnType: int
          variable: <testLibrary>::@class::A::@field::foo
        isOriginVariable foo
          reference: <testLibrary>::@class::A::@getter::foo#1
          firstFragment: #F6
          returnType: double
          variable: <testLibrary>::@class::A::@field::foo#1
      setters
        isOriginVariable foo
          reference: <testLibrary>::@class::A::@setter::foo
          firstFragment: #F7
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F8
              type: int
          returnType: void
          variable: <testLibrary>::@class::A::@field::foo
        isOriginVariable foo
          reference: <testLibrary>::@class::A::@setter::foo#1
          firstFragment: #F9
          formalParameters
            #E1 requiredPositional value
              firstFragment: #F10
              type: double
          returnType: void
          variable: <testLibrary>::@class::A::@field::foo#1
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
        #F1 class A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::A
          constructors
            #F2 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          methods
            #F3 isCompleteDeclaration isOriginDeclaration foo (nameOffset:17) (firstTokenOffset:12) (offset:17)
              element: <testLibrary>::@class::A::@method::foo
            #F4 isCompleteDeclaration isOriginDeclaration foo (nameOffset:33) (firstTokenOffset:28) (offset:33)
              element: <testLibrary>::@class::A::@method::foo#1
  classes
    isSimplyBounded class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
      methods
        isOriginDeclaration foo
          reference: <testLibrary>::@class::A::@method::foo
          firstFragment: #F3
          returnType: void
        isOriginDeclaration foo
          reference: <testLibrary>::@class::A::@method::foo#1
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
        #F1 class A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::A
          constructors
            #F2 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
        #F3 class B (nameOffset:17) (firstTokenOffset:11) (offset:17)
          element: <testLibrary>::@class::B
          constructors
            #F4 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:17)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
        #F5 isMixinApplication class X (nameOffset:28) (firstTokenOffset:22) (offset:28)
          element: <testLibrary>::@class::X
          constructors
            #F6 isOriginMixinApplication new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:28)
              element: <testLibrary>::@class::X::@constructor::new
              typeName: X
        #F7 isMixinApplication class X (nameOffset:48) (firstTokenOffset:42) (offset:48)
          element: <testLibrary>::@class::X#1
          constructors
            #F8 isOriginMixinApplication new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:48)
              element: <testLibrary>::@class::X#1::@constructor::new
              typeName: X
      mixins
        #F9 mixin M (nameOffset:68) (firstTokenOffset:62) (offset:68)
          element: <testLibrary>::@mixin::M
  classes
    isSimplyBounded class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
    isSimplyBounded class B
      reference: <testLibrary>::@class::B
      firstFragment: #F3
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F4
    isMixinApplication isSimplyBounded class X
      reference: <testLibrary>::@class::X
      firstFragment: #F5
      supertype: A
      mixins
        M
      constructors
        isOriginMixinApplication new
          reference: <testLibrary>::@class::X::@constructor::new
          firstFragment: #F6
          constantInitializers
            SuperConstructorInvocation
              superKeyword: super @0
              argumentList: ArgumentList
                leftParenthesis: ( @0
                rightParenthesis: ) @0
              element: <testLibrary>::@class::A::@constructor::new
          superConstructor: <testLibrary>::@class::A::@constructor::new
    isMixinApplication isSimplyBounded class X
      reference: <testLibrary>::@class::X#1
      firstFragment: #F7
      supertype: B
      mixins
        M
      constructors
        isOriginMixinApplication new
          reference: <testLibrary>::@class::X#1::@constructor::new
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
    isSimplyBounded mixin M
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
        #F1 enum E (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@enum::E
          fields
            #F2 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic a (nameOffset:8) (firstTokenOffset:8) (offset:8)
              element: <testLibrary>::@enum::E::@field::a
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibrary>::@enum::E
                      type: E
                    element: <testLibrary>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            #F3 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic b (nameOffset:11) (firstTokenOffset:11) (offset:11)
              element: <testLibrary>::@enum::E::@field::b
              initializer: expression_1
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibrary>::@enum::E
                      type: E
                    element: <testLibrary>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            #F4 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@field::values
              initializer: expression_2
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: a @-1
                      element: <testLibrary>::@enum::E::@getter::a
                      staticType: E
                    SimpleIdentifier
                      token: b @-1
                      element: <testLibrary>::@enum::E::@getter::b
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
          constructors
            #F5 isConst isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F6 isCompleteDeclaration isOriginVariable isStatic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:8)
              element: <testLibrary>::@enum::E::@getter::a
            #F7 isCompleteDeclaration isOriginVariable isStatic b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::E::@getter::b
            #F8 isCompleteDeclaration isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
        #F9 enum E (nameOffset:19) (firstTokenOffset:14) (offset:19)
          element: <testLibrary>::@enum::E#1
          fields
            #F10 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic c (nameOffset:22) (firstTokenOffset:22) (offset:22)
              element: <testLibrary>::@enum::E#1::@field::c
              initializer: expression_3
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibrary>::@enum::E
                      type: E
                    element: <testLibrary>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            #F11 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic d (nameOffset:25) (firstTokenOffset:25) (offset:25)
              element: <testLibrary>::@enum::E#1::@field::d
              initializer: expression_4
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibrary>::@enum::E
                      type: E
                    element: <testLibrary>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            #F12 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic e (nameOffset:28) (firstTokenOffset:28) (offset:28)
              element: <testLibrary>::@enum::E#1::@field::e
              initializer: expression_5
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibrary>::@enum::E
                      type: E
                    element: <testLibrary>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            #F13 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:19)
              element: <testLibrary>::@enum::E#1::@field::values
              initializer: expression_6
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: c @-1
                      element: <testLibrary>::@enum::E#1::@getter::c
                      staticType: E
                    SimpleIdentifier
                      token: d @-1
                      element: <testLibrary>::@enum::E#1::@getter::d
                      staticType: E
                    SimpleIdentifier
                      token: e @-1
                      element: <testLibrary>::@enum::E#1::@getter::e
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
          constructors
            #F14 isConst isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:19)
              element: <testLibrary>::@enum::E#1::@constructor::new
              typeName: E
          getters
            #F15 isCompleteDeclaration isOriginVariable isStatic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
              element: <testLibrary>::@enum::E#1::@getter::c
            #F16 isCompleteDeclaration isOriginVariable isStatic d (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
              element: <testLibrary>::@enum::E#1::@getter::d
            #F17 isCompleteDeclaration isOriginVariable isStatic e (nameOffset:<null>) (firstTokenOffset:<null>) (offset:28)
              element: <testLibrary>::@enum::E#1::@getter::e
            #F18 isCompleteDeclaration isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:19)
              element: <testLibrary>::@enum::E#1::@getter::values
  enums
    isSimplyBounded enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer a
          reference: <testLibrary>::@enum::E::@field::a
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::a
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer b
          reference: <testLibrary>::@enum::E::@field::b
          firstFragment: #F3
          type: E
          constantInitializer
            fragment: #F3
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::b
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F4
          type: List<E>
          constantInitializer
            fragment: #F4
            expression: expression_2
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        isConst isOriginImplicitDefault new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F5
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic a
          reference: <testLibrary>::@enum::E::@getter::a
          firstFragment: #F6
          returnType: E
          variable: <testLibrary>::@enum::E::@field::a
        isOriginVariable isStatic b
          reference: <testLibrary>::@enum::E::@getter::b
          firstFragment: #F7
          returnType: E
          variable: <testLibrary>::@enum::E::@field::b
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F8
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
    isSimplyBounded enum E
      reference: <testLibrary>::@enum::E#1
      firstFragment: #F9
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer c
          reference: <testLibrary>::@enum::E#1::@field::c
          firstFragment: #F10
          type: E
          constantInitializer
            fragment: #F10
            expression: expression_3
          getter: <testLibrary>::@enum::E#1::@getter::c
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer d
          reference: <testLibrary>::@enum::E#1::@field::d
          firstFragment: #F11
          type: E
          constantInitializer
            fragment: #F11
            expression: expression_4
          getter: <testLibrary>::@enum::E#1::@getter::d
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer e
          reference: <testLibrary>::@enum::E#1::@field::e
          firstFragment: #F12
          type: E
          constantInitializer
            fragment: #F12
            expression: expression_5
          getter: <testLibrary>::@enum::E#1::@getter::e
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::E#1::@field::values
          firstFragment: #F13
          type: List<E>
          constantInitializer
            fragment: #F13
            expression: expression_6
          getter: <testLibrary>::@enum::E#1::@getter::values
      constructors
        isConst isOriginImplicitDefault new
          reference: <testLibrary>::@enum::E#1::@constructor::new
          firstFragment: #F14
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic c
          reference: <testLibrary>::@enum::E#1::@getter::c
          firstFragment: #F15
          returnType: E
          variable: <testLibrary>::@enum::E#1::@field::c
        isOriginVariable isStatic d
          reference: <testLibrary>::@enum::E#1::@getter::d
          firstFragment: #F16
          returnType: E
          variable: <testLibrary>::@enum::E#1::@field::d
        isOriginVariable isStatic e
          reference: <testLibrary>::@enum::E#1::@getter::e
          firstFragment: #F17
          returnType: E
          variable: <testLibrary>::@enum::E#1::@field::e
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::E#1::@getter::values
          firstFragment: #F18
          returnType: List<E>
          variable: <testLibrary>::@enum::E#1::@field::values
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
        #F1 extension E (nameOffset:10) (firstTokenOffset:0) (offset:10)
          element: <testLibrary>::@extension::E
        #F2 extension E (nameOffset:32) (firstTokenOffset:22) (offset:32)
          element: <testLibrary>::@extension::E#1
          fields
            #F3 hasImplicitType isOriginDeclaration isStatic x (nameOffset:56) (firstTokenOffset:56) (offset:56)
              element: <testLibrary>::@extension::E#1::@field::x
          getters
            #F4 isCompleteDeclaration isOriginVariable isStatic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:56)
              element: <testLibrary>::@extension::E#1::@getter::x
          setters
            #F5 isCompleteDeclaration isOriginVariable isStatic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:56)
              element: <testLibrary>::@extension::E#1::@setter::x
              formalParameters
                #F6 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:56)
                  element: <testLibrary>::@extension::E#1::@setter::x::@formalParameter::value
        #F7 extension E (nameOffset:71) (firstTokenOffset:61) (offset:71)
          element: <testLibrary>::@extension::E#2
          fields
            #F8 hasImplicitType hasInitializer isOriginDeclaration isStatic y (nameOffset:95) (firstTokenOffset:95) (offset:95)
              element: <testLibrary>::@extension::E#2::@field::y
          getters
            #F9 isCompleteDeclaration isOriginVariable isStatic y (nameOffset:<null>) (firstTokenOffset:<null>) (offset:95)
              element: <testLibrary>::@extension::E#2::@getter::y
          setters
            #F10 isCompleteDeclaration isOriginVariable isStatic y (nameOffset:<null>) (firstTokenOffset:<null>) (offset:95)
              element: <testLibrary>::@extension::E#2::@setter::y
              formalParameters
                #F11 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:95)
                  element: <testLibrary>::@extension::E#2::@setter::y::@formalParameter::value
  extensions
    extension E
      reference: <testLibrary>::@extension::E
      firstFragment: #F1
      extendedType: int
      onDeclaration: dart:core::@class::int
    extension E
      reference: <testLibrary>::@extension::E#1
      firstFragment: #F2
      extendedType: int
      onDeclaration: dart:core::@class::int
      fields
        hasImplicitType isOriginDeclaration isStatic x
          reference: <testLibrary>::@extension::E#1::@field::x
          firstFragment: #F3
          type: dynamic
          getter: <testLibrary>::@extension::E#1::@getter::x
          setter: <testLibrary>::@extension::E#1::@setter::x
      getters
        isOriginVariable isStatic x
          reference: <testLibrary>::@extension::E#1::@getter::x
          firstFragment: #F4
          returnType: dynamic
          variable: <testLibrary>::@extension::E#1::@field::x
      setters
        isOriginVariable isStatic x
          reference: <testLibrary>::@extension::E#1::@setter::x
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F6
              type: dynamic
          returnType: void
          variable: <testLibrary>::@extension::E#1::@field::x
    extension E
      reference: <testLibrary>::@extension::E#2
      firstFragment: #F7
      extendedType: int
      onDeclaration: dart:core::@class::int
      fields
        hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer y
          reference: <testLibrary>::@extension::E#2::@field::y
          firstFragment: #F8
          type: int
          getter: <testLibrary>::@extension::E#2::@getter::y
          setter: <testLibrary>::@extension::E#2::@setter::y
      getters
        isOriginVariable isStatic y
          reference: <testLibrary>::@extension::E#2::@getter::y
          firstFragment: #F9
          returnType: int
          variable: <testLibrary>::@extension::E#2::@field::y
      setters
        isOriginVariable isStatic y
          reference: <testLibrary>::@extension::E#2::@setter::y
          firstFragment: #F10
          formalParameters
            #E1 requiredPositional value
              firstFragment: #F11
              type: int
          returnType: void
          variable: <testLibrary>::@extension::E#2::@field::y
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
        #F1 extension type E (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@extensionType::E
          fields
            #F2 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::E::@field::it
          constructors
            #F3 isCompleteDeclaration isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@extensionType::E::@constructor::new
              typeName: E
              typeNameOffset: 15
              formalParameters
                #F4 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:21) (firstTokenOffset:17) (offset:21)
                  element: <testLibrary>::@extensionType::E::@constructor::new::@formalParameter::it
          getters
            #F5 isCompleteDeclaration isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@extensionType::E::@getter::it
        #F6 extension type E (nameOffset:43) (firstTokenOffset:28) (offset:43)
          element: <testLibrary>::@extensionType::E#1
          fields
            #F7 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:43)
              element: <testLibrary>::@extensionType::E#1::@field::it
          constructors
            #F8 isCompleteDeclaration isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:43) (offset:43)
              element: <testLibrary>::@extensionType::E#1::@constructor::new
              typeName: E
              typeNameOffset: 43
              formalParameters
                #F9 requiredPositional isDeclaring isFinal isOriginDeclaration this.it (nameOffset:52) (firstTokenOffset:45) (offset:52)
                  element: <testLibrary>::@extensionType::E#1::@constructor::new::@formalParameter::it
          getters
            #F10 isCompleteDeclaration isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:43)
              element: <testLibrary>::@extensionType::E#1::@getter::it
  extensionTypes
    isSimplyBounded extension type E
      reference: <testLibrary>::@extensionType::E
      firstFragment: #F1
      representation: <testLibrary>::@extensionType::E::@field::it
      primaryConstructor: <testLibrary>::@extensionType::E::@constructor::new
      typeErasure: int
      fields
        isFinal isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::E::@field::it
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extensionType::E::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::E::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::E::@constructor::new
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional isDeclaring isFinal this.it
              firstFragment: #F4
              type: int
              field: <testLibrary>::@extensionType::E::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::E::@getter::it
          firstFragment: #F5
          returnType: int
          variable: <testLibrary>::@extensionType::E::@field::it
    isSimplyBounded extension type E
      reference: <testLibrary>::@extensionType::E#1
      firstFragment: #F6
      representation: <testLibrary>::@extensionType::E#1::@field::it
      primaryConstructor: <testLibrary>::@extensionType::E#1::@constructor::new
      typeErasure: double
      fields
        isFinal isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::E#1::@field::it
          firstFragment: #F7
          type: double
          getter: <testLibrary>::@extensionType::E#1::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::E#1::@constructor::new::@formalParameter::it
      constructors
        isExtensionTypeMember isOriginDeclaration isPrimary new
          reference: <testLibrary>::@extensionType::E#1::@constructor::new
          firstFragment: #F8
          formalParameters
            #E1 requiredPositional isDeclaring isFinal this.it
              firstFragment: #F9
              type: double
              field: <testLibrary>::@extensionType::E#1::@field::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::E#1::@getter::it
          firstFragment: #F10
          returnType: double
          variable: <testLibrary>::@extensionType::E#1::@field::it
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
        #F1 isCompleteDeclaration isOriginDeclaration isStatic f (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@function::f
        #F2 isCompleteDeclaration isOriginDeclaration isStatic f (nameOffset:17) (firstTokenOffset:12) (offset:17)
          element: <testLibrary>::@function::f#1
          formalParameters
            #F3 requiredPositional isOriginDeclaration a (nameOffset:23) (firstTokenOffset:19) (offset:23)
              element: <testLibrary>::@function::f#1::@formalParameter::a
        #F4 isCompleteDeclaration isOriginDeclaration isStatic f (nameOffset:34) (firstTokenOffset:29) (offset:34)
          element: <testLibrary>::@function::f#2
          formalParameters
            #F5 optionalPositional isOriginDeclaration b (nameOffset:41) (firstTokenOffset:37) (offset:41)
              element: <testLibrary>::@function::f#2::@formalParameter::b
            #F6 optionalPositional isOriginDeclaration c (nameOffset:51) (firstTokenOffset:44) (offset:51)
              element: <testLibrary>::@function::f#2::@formalParameter::c
  functions
    isOriginDeclaration isStatic f
      reference: <testLibrary>::@function::f
      firstFragment: #F1
      returnType: void
    isOriginDeclaration isStatic f
      reference: <testLibrary>::@function::f#1
      firstFragment: #F2
      formalParameters
        #E0 requiredPositional a
          firstFragment: #F3
          type: int
      returnType: void
    isOriginDeclaration isStatic f
      reference: <testLibrary>::@function::f#2
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
        #F1 isCompleteDeclaration isOriginDeclaration isStatic f (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@function::f
          formalParameters
            #F2 optionalNamed isOriginDeclaration a (nameOffset:12) (firstTokenOffset:8) (offset:12)
              element: <testLibrary>::@function::f::@formalParameter::a
            #F3 optionalNamed isOriginDeclaration a (nameOffset:22) (firstTokenOffset:15) (offset:22)
              element: <testLibrary>::@function::f::@formalParameter::a
  functions
    isOriginDeclaration isStatic f
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
        #F1 F (nameOffset:13) (firstTokenOffset:0) (offset:13)
          element: <testLibrary>::@typeAlias::F
        #F2 F (nameOffset:31) (firstTokenOffset:18) (offset:31)
          element: <testLibrary>::@typeAlias::F#1
        #F3 F (nameOffset:54) (firstTokenOffset:41) (offset:54)
          element: <testLibrary>::@typeAlias::F#2
  typeAliases
    isSimplyBounded F
      reference: <testLibrary>::@typeAlias::F
      firstFragment: #F1
      aliasedType: void Function()
    isSimplyBounded F
      reference: <testLibrary>::@typeAlias::F#1
      firstFragment: #F2
      aliasedType: void Function(int)
    isSimplyBounded F
      reference: <testLibrary>::@typeAlias::F#2
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
        #F1 mixin A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@mixin::A
        #F2 mixin A (nameOffset:17) (firstTokenOffset:11) (offset:17)
          element: <testLibrary>::@mixin::A#1
          fields
            #F3 hasImplicitType isOriginDeclaration x (nameOffset:27) (firstTokenOffset:27) (offset:27)
              element: <testLibrary>::@mixin::A#1::@field::x
          getters
            #F4 isCompleteDeclaration isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:27)
              element: <testLibrary>::@mixin::A#1::@getter::x
          setters
            #F5 isCompleteDeclaration isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:27)
              element: <testLibrary>::@mixin::A#1::@setter::x
              formalParameters
                #F6 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:27)
                  element: <testLibrary>::@mixin::A#1::@setter::x::@formalParameter::value
        #F7 mixin A (nameOffset:38) (firstTokenOffset:32) (offset:38)
          element: <testLibrary>::@mixin::A#2
          fields
            #F8 hasImplicitType hasInitializer isOriginDeclaration y (nameOffset:48) (firstTokenOffset:48) (offset:48)
              element: <testLibrary>::@mixin::A#2::@field::y
          getters
            #F9 isCompleteDeclaration isOriginVariable y (nameOffset:<null>) (firstTokenOffset:<null>) (offset:48)
              element: <testLibrary>::@mixin::A#2::@getter::y
          setters
            #F10 isCompleteDeclaration isOriginVariable y (nameOffset:<null>) (firstTokenOffset:<null>) (offset:48)
              element: <testLibrary>::@mixin::A#2::@setter::y
              formalParameters
                #F11 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:48)
                  element: <testLibrary>::@mixin::A#2::@setter::y::@formalParameter::value
  mixins
    isSimplyBounded mixin A
      reference: <testLibrary>::@mixin::A
      firstFragment: #F1
      superclassConstraints
        Object
    hasNonFinalField isSimplyBounded mixin A
      reference: <testLibrary>::@mixin::A#1
      firstFragment: #F2
      superclassConstraints
        Object
      fields
        hasImplicitType isOriginDeclaration x
          reference: <testLibrary>::@mixin::A#1::@field::x
          firstFragment: #F3
          type: dynamic
          getter: <testLibrary>::@mixin::A#1::@getter::x
          setter: <testLibrary>::@mixin::A#1::@setter::x
      getters
        isOriginVariable x
          reference: <testLibrary>::@mixin::A#1::@getter::x
          firstFragment: #F4
          returnType: dynamic
          variable: <testLibrary>::@mixin::A#1::@field::x
      setters
        isOriginVariable x
          reference: <testLibrary>::@mixin::A#1::@setter::x
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F6
              type: dynamic
          returnType: void
          variable: <testLibrary>::@mixin::A#1::@field::x
    hasNonFinalField isSimplyBounded mixin A
      reference: <testLibrary>::@mixin::A#2
      firstFragment: #F7
      superclassConstraints
        Object
      fields
        hasImplicitType hasInitializer isOriginDeclaration isTypeInferredFromInitializer y
          reference: <testLibrary>::@mixin::A#2::@field::y
          firstFragment: #F8
          type: int
          getter: <testLibrary>::@mixin::A#2::@getter::y
          setter: <testLibrary>::@mixin::A#2::@setter::y
      getters
        isOriginVariable y
          reference: <testLibrary>::@mixin::A#2::@getter::y
          firstFragment: #F9
          returnType: int
          variable: <testLibrary>::@mixin::A#2::@field::y
      setters
        isOriginVariable y
          reference: <testLibrary>::@mixin::A#2::@setter::y
          firstFragment: #F10
          formalParameters
            #E1 requiredPositional value
              firstFragment: #F11
              type: int
          returnType: void
          variable: <testLibrary>::@mixin::A#2::@field::y
''');
  }

  test_duplicateDeclaration_topLevelVariable() async {
    var library = await buildLibrary(r'''
bool x;
var x;
final x = 1;
var x = 2.3;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 isOriginDeclaration isStatic x (nameOffset:5) (firstTokenOffset:5) (offset:5)
          element: <testLibrary>::@topLevelVariable::x
        #F2 hasImplicitType isOriginDeclaration isStatic x (nameOffset:12) (firstTokenOffset:12) (offset:12)
          element: <testLibrary>::@topLevelVariable::x#1
        #F3 hasImplicitType hasInitializer isFinal isOriginDeclaration isStatic x (nameOffset:21) (firstTokenOffset:21) (offset:21)
          element: <testLibrary>::@topLevelVariable::x#2
        #F4 hasImplicitType hasInitializer isOriginDeclaration isStatic x (nameOffset:32) (firstTokenOffset:32) (offset:32)
          element: <testLibrary>::@topLevelVariable::x#3
      getters
        #F5 isCompleteDeclaration isOriginVariable isStatic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
          element: <testLibrary>::@getter::x
        #F6 isCompleteDeclaration isOriginVariable isStatic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:12)
          element: <testLibrary>::@getter::x#1
        #F7 isCompleteDeclaration isOriginVariable isStatic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
          element: <testLibrary>::@getter::x#2
        #F8 isCompleteDeclaration isOriginVariable isStatic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:32)
          element: <testLibrary>::@getter::x#3
      setters
        #F9 isCompleteDeclaration isOriginVariable isStatic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
          element: <testLibrary>::@setter::x
          formalParameters
            #F10 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@setter::x::@formalParameter::value
        #F11 isCompleteDeclaration isOriginVariable isStatic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:12)
          element: <testLibrary>::@setter::x#1
          formalParameters
            #F12 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:12)
              element: <testLibrary>::@setter::x#1::@formalParameter::value
        #F13 isCompleteDeclaration isOriginVariable isStatic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:32)
          element: <testLibrary>::@setter::x#2
          formalParameters
            #F14 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:32)
              element: <testLibrary>::@setter::x#2::@formalParameter::value
  topLevelVariables
    isOriginDeclaration isStatic x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F1
      type: bool
      getter: <testLibrary>::@getter::x
      setter: <testLibrary>::@setter::x
    hasImplicitType isOriginDeclaration isStatic x
      reference: <testLibrary>::@topLevelVariable::x#1
      firstFragment: #F2
      type: dynamic
      getter: <testLibrary>::@getter::x#1
      setter: <testLibrary>::@setter::x#1
    hasImplicitType hasInitializer isFinal isOriginDeclaration isStatic isTypeInferredFromInitializer x
      reference: <testLibrary>::@topLevelVariable::x#2
      firstFragment: #F3
      type: int
      getter: <testLibrary>::@getter::x#2
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer x
      reference: <testLibrary>::@topLevelVariable::x#3
      firstFragment: #F4
      type: double
      getter: <testLibrary>::@getter::x#3
      setter: <testLibrary>::@setter::x#2
  getters
    isOriginVariable isStatic x
      reference: <testLibrary>::@getter::x
      firstFragment: #F5
      returnType: bool
      variable: <testLibrary>::@topLevelVariable::x
    isOriginVariable isStatic x
      reference: <testLibrary>::@getter::x#1
      firstFragment: #F6
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::x#1
    isOriginVariable isStatic x
      reference: <testLibrary>::@getter::x#2
      firstFragment: #F7
      returnType: int
      variable: <testLibrary>::@topLevelVariable::x#2
    isOriginVariable isStatic x
      reference: <testLibrary>::@getter::x#3
      firstFragment: #F8
      returnType: double
      variable: <testLibrary>::@topLevelVariable::x#3
  setters
    isOriginVariable isStatic x
      reference: <testLibrary>::@setter::x
      firstFragment: #F9
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F10
          type: bool
      returnType: void
      variable: <testLibrary>::@topLevelVariable::x
    isOriginVariable isStatic x
      reference: <testLibrary>::@setter::x#1
      firstFragment: #F11
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F12
          type: dynamic
      returnType: void
      variable: <testLibrary>::@topLevelVariable::x#1
    isOriginVariable isStatic x
      reference: <testLibrary>::@setter::x#2
      firstFragment: #F13
      formalParameters
        #E2 requiredPositional value
          firstFragment: #F14
          type: double
      returnType: void
      variable: <testLibrary>::@topLevelVariable::x#3
''');
  }

  test_duplicateDeclaration_unit_getter() async {
    var library = await buildLibrary(r'''
int get foo {}
double get foo {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 isOriginGetterSetter isStatic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:8)
          element: <testLibrary>::@topLevelVariable::foo
        #F2 isOriginGetterSetter isStatic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:26)
          element: <testLibrary>::@topLevelVariable::foo#1
      getters
        #F3 isCompleteDeclaration isOriginDeclaration isStatic foo (nameOffset:8) (firstTokenOffset:0) (offset:8)
          element: <testLibrary>::@getter::foo
        #F4 isCompleteDeclaration isOriginDeclaration isStatic foo (nameOffset:26) (firstTokenOffset:15) (offset:26)
          element: <testLibrary>::@getter::foo#1
  topLevelVariables
    isOriginGetterSetter isStatic foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::foo
    isOriginGetterSetter isStatic foo
      reference: <testLibrary>::@topLevelVariable::foo#1
      firstFragment: #F2
      type: double
      getter: <testLibrary>::@getter::foo#1
  getters
    isOriginDeclaration isStatic foo
      reference: <testLibrary>::@getter::foo
      firstFragment: #F3
      returnType: int
      variable: <testLibrary>::@topLevelVariable::foo
    isOriginDeclaration isStatic foo
      reference: <testLibrary>::@getter::foo#1
      firstFragment: #F4
      returnType: double
      variable: <testLibrary>::@topLevelVariable::foo#1
''');
  }

  test_duplicateDeclaration_unit_setter() async {
    var library = await buildLibrary(r'''
set foo(int _) {}
set foo(double _) {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 isOriginGetterSetter isStatic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@topLevelVariable::foo
        #F2 isOriginGetterSetter isStatic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
          element: <testLibrary>::@topLevelVariable::foo#1
      setters
        #F3 hasImplicitReturnType isCompleteDeclaration isOriginDeclaration isStatic foo (nameOffset:4) (firstTokenOffset:0) (offset:4)
          element: <testLibrary>::@setter::foo
          formalParameters
            #F4 requiredPositional isOriginDeclaration _ (nameOffset:12) (firstTokenOffset:8) (offset:12)
              element: <testLibrary>::@setter::foo::@formalParameter::_
        #F5 hasImplicitReturnType isCompleteDeclaration isOriginDeclaration isStatic foo (nameOffset:22) (firstTokenOffset:18) (offset:22)
          element: <testLibrary>::@setter::foo#1
          formalParameters
            #F6 requiredPositional isOriginDeclaration _ (nameOffset:33) (firstTokenOffset:26) (offset:33)
              element: <testLibrary>::@setter::foo#1::@formalParameter::_
  topLevelVariables
    isOriginGetterSetter isStatic foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: #F1
      type: int
      setter: <testLibrary>::@setter::foo
    isOriginGetterSetter isStatic foo
      reference: <testLibrary>::@topLevelVariable::foo#1
      firstFragment: #F2
      type: double
      setter: <testLibrary>::@setter::foo#1
  setters
    isOriginDeclaration isStatic foo
      reference: <testLibrary>::@setter::foo
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional _
          firstFragment: #F4
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::foo
    isOriginDeclaration isStatic foo
      reference: <testLibrary>::@setter::foo#1
      firstFragment: #F5
      formalParameters
        #E1 requiredPositional _
          firstFragment: #F6
          type: double
      returnType: void
      variable: <testLibrary>::@topLevelVariable::foo#1
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
