// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/expect.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../dart/resolution/node_text_expectations.dart';
import '../elements_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(EnumElementTest_keepLinking);
    defineReflectiveTests(EnumElementTest_fromBytes);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

abstract class EnumElementTest extends ElementsBaseTest {
  test_constant_arguments_symbolLiteral() async {
    var library = await buildLibrary(r'''
enum E {
  v(#foo.bar);

  const E(Object _);
}
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
            #F2 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:11) (firstTokenOffset:11) (offset:11)
              element: <testLibrary>::@enum::E::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibrary>::@enum::E
                      type: E
                    element: <testLibrary>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @12
                    arguments
                      SymbolLiteral
                        poundSign: # @13
                        components
                          foo @14
                          bar @18
                    rightParenthesis: ) @21
                  staticType: E
              inducedGetter: #F3
            #F4 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::E::@getter::v
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
              inducedGetter: #F5
          constructors
            #F6 isConst isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:27) (offset:33)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
              typeNameOffset: 33
              formalParameters
                #F7 requiredPositional isOriginDeclaration _ (nameOffset:42) (firstTokenOffset:35) (offset:42)
                  element: <testLibrary>::@enum::E::@constructor::new::@formalParameter::_
          getters
            #F3 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::E::@getter::v
              inducingVariable: #F2
            #F5 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
              inducingVariable: #F4
  enums
    isSimplyBounded enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F4
          type: List<E>
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        isConst isOriginDeclaration new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F6
          formalParameters
            #E0 requiredPositional _
              firstFragment: #F7
              type: Object
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F3
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F5
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
''');
  }

  test_constant_augmentation_add_chain() async {
    var library = await buildLibrary(r'''
enum A {
  v1
}

augment enum A {
  v2
}

augment enum A {
  v3
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      enums
        #F1 enum A (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@enum::A
          nextFragment: #F2
          fields
            #F3 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v1 (nameOffset:11) (firstTokenOffset:11) (offset:11)
              element: <testLibrary>::@enum::A::@field::v1
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibrary>::@enum::A
                      type: A
                    element: <testLibrary>::@enum::A::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              inducedGetter: #F4
            #F5 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v1 @-1
                      element: <testLibrary>::@enum::A::@getter::v1
                      staticType: A
                    SimpleIdentifier
                      token: v2 @-1
                      element: <testLibrary>::@enum::A::@getter::v2
                      staticType: A
                    SimpleIdentifier
                      token: v3 @-1
                      element: <testLibrary>::@enum::A::@getter::v3
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
              inducedGetter: #F6
          constructors
            #F7 isConst isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
          getters
            #F4 isComplete isOriginVariable isStatic v1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::A::@getter::v1
              inducingVariable: #F3
            #F6 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
              inducingVariable: #F5
        #F2 isAugmentation enum A (nameOffset:30) (firstTokenOffset:17) (offset:30)
          element: <testLibrary>::@enum::A
          previousFragment: #F1
          nextFragment: #F8
          fields
            #F9 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v2 (nameOffset:36) (firstTokenOffset:36) (offset:36)
              element: <testLibrary>::@enum::A::@field::v2
              initializer: expression_2
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibrary>::@enum::A
                      type: A
                    element: <testLibrary>::@enum::A::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              inducedGetter: #F10
          getters
            #F10 isComplete isOriginVariable isStatic v2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:36)
              element: <testLibrary>::@enum::A::@getter::v2
              inducingVariable: #F9
        #F8 isAugmentation enum A (nameOffset:55) (firstTokenOffset:42) (offset:55)
          element: <testLibrary>::@enum::A
          previousFragment: #F2
          fields
            #F11 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v3 (nameOffset:61) (firstTokenOffset:61) (offset:61)
              element: <testLibrary>::@enum::A::@field::v3
              initializer: expression_3
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibrary>::@enum::A
                      type: A
                    element: <testLibrary>::@enum::A::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              inducedGetter: #F12
          getters
            #F12 isComplete isOriginVariable isStatic v3 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:61)
              element: <testLibrary>::@enum::A::@getter::v3
              inducingVariable: #F11
  enums
    isSimplyBounded enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v1
          reference: <testLibrary>::@enum::A::@field::v1
          firstFragment: #F3
          type: A
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v1
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F5
          type: List<A>
          constantInitializer
            fragment: #F5
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v2
          reference: <testLibrary>::@enum::A::@field::v2
          firstFragment: #F9
          type: A
          constantInitializer
            fragment: #F9
            expression: expression_2
          getter: <testLibrary>::@enum::A::@getter::v2
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v3
          reference: <testLibrary>::@enum::A::@field::v3
          firstFragment: #F11
          type: A
          constantInitializer
            fragment: #F11
            expression: expression_3
          getter: <testLibrary>::@enum::A::@getter::v3
      constructors
        isConst isOriginImplicitDefault new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F7
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v1
          reference: <testLibrary>::@enum::A::@getter::v1
          firstFragment: #F4
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v1
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F6
          returnType: List<A>
          variable: <testLibrary>::@enum::A::@field::values
        isOriginVariable isStatic v2
          reference: <testLibrary>::@enum::A::@getter::v2
          firstFragment: #F10
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v2
        isOriginVariable isStatic v3
          reference: <testLibrary>::@enum::A::@getter::v3
          firstFragment: #F12
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v3
''');
  }

  test_constant_augmentation_add_chain_twoInSameDeclaration() async {
    var library = await buildLibrary(r'''
enum A {
  v1
}

augment enum A {
  v2,
  augment v2
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      enums
        #F1 enum A (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@enum::A
          nextFragment: #F2
          fields
            #F3 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v1 (nameOffset:11) (firstTokenOffset:11) (offset:11)
              element: <testLibrary>::@enum::A::@field::v1
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibrary>::@enum::A
                      type: A
                    element: <testLibrary>::@enum::A::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              inducedGetter: #F4
            #F5 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v1 @-1
                      element: <testLibrary>::@enum::A::@getter::v1
                      staticType: A
                    SimpleIdentifier
                      token: v2 @-1
                      element: <testLibrary>::@enum::A::@getter::v2
                      staticType: A
                    SimpleIdentifier
                      token: v2 @-1
                      element: <testLibrary>::@enum::A::@getter::v2
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
              inducedGetter: #F6
          constructors
            #F7 isConst isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
          getters
            #F4 isComplete isOriginVariable isStatic v1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::A::@getter::v1
              inducingVariable: #F3
            #F6 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
              inducingVariable: #F5
        #F2 isAugmentation enum A (nameOffset:30) (firstTokenOffset:17) (offset:30)
          element: <testLibrary>::@enum::A
          previousFragment: #F1
          fields
            #F8 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v2 (nameOffset:36) (firstTokenOffset:36) (offset:36)
              element: <testLibrary>::@enum::A::@field::v2
              initializer: expression_2
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <null>
                      type: null
                    element: <null>
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: null
              inducedGetter: #F9
              nextFragment: #F10
            #F10 hasImplicitType hasInitializer isAugmentation isConst isEnumConstant isOriginDeclaration isStatic v2 (nameOffset:50) (firstTokenOffset:42) (offset:50)
              element: <testLibrary>::@enum::A::@field::v2
              initializer: expression_3
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibrary>::@enum::A
                      type: A
                    element: <testLibrary>::@enum::A::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              inducedGetter: #F11
              previousFragment: #F8
          getters
            #F9 isComplete isOriginVariable isStatic v2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:36)
              element: <testLibrary>::@enum::A::@getter::v2
              inducingVariable: #F8
              nextFragment: #F11
            #F11 isAugmentation isComplete isOriginVariable isStatic v2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:50)
              element: <testLibrary>::@enum::A::@getter::v2
              inducingVariable: #F10
              previousFragment: #F9
  enums
    isSimplyBounded enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v1
          reference: <testLibrary>::@enum::A::@field::v1
          firstFragment: #F3
          type: A
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v1
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F5
          type: List<A>
          constantInitializer
            fragment: #F5
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v2
          reference: <testLibrary>::@enum::A::@field::v2
          firstFragment: #F8
          type: A
          constantInitializer
            fragment: #F10
            expression: expression_3
          getter: <testLibrary>::@enum::A::@getter::v2
      constructors
        isConst isOriginImplicitDefault new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F7
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v1
          reference: <testLibrary>::@enum::A::@getter::v1
          firstFragment: #F4
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v1
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F6
          returnType: List<A>
          variable: <testLibrary>::@enum::A::@field::values
        isOriginVariable isStatic v2
          reference: <testLibrary>::@enum::A::@getter::v2
          firstFragment: #F9
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v2
''');
  }

  test_constant_augmentation_chain() async {
    var library = await buildLibrary(r'''
enum A {
  v1, v2, v3
}

augment enum A {
  augment v2
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      enums
        #F1 enum A (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@enum::A
          nextFragment: #F2
          fields
            #F3 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v1 (nameOffset:11) (firstTokenOffset:11) (offset:11)
              element: <testLibrary>::@enum::A::@field::v1
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibrary>::@enum::A
                      type: A
                    element: <testLibrary>::@enum::A::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              inducedGetter: #F4
            #F5 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v2 (nameOffset:15) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@enum::A::@field::v2
              initializer: expression_1
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <null>
                      type: null
                    element: <null>
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: null
              inducedGetter: #F6
              nextFragment: #F7
            #F8 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v3 (nameOffset:19) (firstTokenOffset:19) (offset:19)
              element: <testLibrary>::@enum::A::@field::v3
              initializer: expression_2
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibrary>::@enum::A
                      type: A
                    element: <testLibrary>::@enum::A::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              inducedGetter: #F9
            #F10 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@field::values
              initializer: expression_3
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v1 @-1
                      element: <testLibrary>::@enum::A::@getter::v1
                      staticType: A
                    SimpleIdentifier
                      token: v2 @-1
                      element: <testLibrary>::@enum::A::@getter::v2
                      staticType: A
                    SimpleIdentifier
                      token: v3 @-1
                      element: <testLibrary>::@enum::A::@getter::v3
                      staticType: A
                    SimpleIdentifier
                      token: v2 @-1
                      element: <testLibrary>::@enum::A::@getter::v2
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
              inducedGetter: #F11
          constructors
            #F12 isConst isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
          getters
            #F4 isComplete isOriginVariable isStatic v1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::A::@getter::v1
              inducingVariable: #F3
            #F6 isComplete isOriginVariable isStatic v2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@enum::A::@getter::v2
              inducingVariable: #F5
              nextFragment: #F13
            #F9 isComplete isOriginVariable isStatic v3 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:19)
              element: <testLibrary>::@enum::A::@getter::v3
              inducingVariable: #F8
            #F11 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
              inducingVariable: #F10
        #F2 isAugmentation enum A (nameOffset:38) (firstTokenOffset:25) (offset:38)
          element: <testLibrary>::@enum::A
          previousFragment: #F1
          fields
            #F7 hasImplicitType hasInitializer isAugmentation isConst isEnumConstant isOriginDeclaration isStatic v2 (nameOffset:52) (firstTokenOffset:44) (offset:52)
              element: <testLibrary>::@enum::A::@field::v2
              initializer: expression_4
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibrary>::@enum::A
                      type: A
                    element: <testLibrary>::@enum::A::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              inducedGetter: #F13
              previousFragment: #F5
          getters
            #F13 isAugmentation isComplete isOriginVariable isStatic v2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:52)
              element: <testLibrary>::@enum::A::@getter::v2
              inducingVariable: #F7
              previousFragment: #F6
  enums
    isSimplyBounded enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v1
          reference: <testLibrary>::@enum::A::@field::v1
          firstFragment: #F3
          type: A
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v1
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v2
          reference: <testLibrary>::@enum::A::@field::v2
          firstFragment: #F5
          type: A
          constantInitializer
            fragment: #F7
            expression: expression_4
          getter: <testLibrary>::@enum::A::@getter::v2
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v3
          reference: <testLibrary>::@enum::A::@field::v3
          firstFragment: #F8
          type: A
          constantInitializer
            fragment: #F8
            expression: expression_2
          getter: <testLibrary>::@enum::A::@getter::v3
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F10
          type: List<A>
          constantInitializer
            fragment: #F10
            expression: expression_3
          getter: <testLibrary>::@enum::A::@getter::values
      constructors
        isConst isOriginImplicitDefault new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F12
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v1
          reference: <testLibrary>::@enum::A::@getter::v1
          firstFragment: #F4
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v1
        isOriginVariable isStatic v2
          reference: <testLibrary>::@enum::A::@getter::v2
          firstFragment: #F6
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v2
        isOriginVariable isStatic v3
          reference: <testLibrary>::@enum::A::@getter::v3
          firstFragment: #F9
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v3
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F11
          returnType: List<A>
          variable: <testLibrary>::@enum::A::@field::values
''');
  }

  test_constant_augmentation_chain_typeParameters_countMismatch() async {
    var library = await buildLibrary(r'''
enum A {
  v, v2
}

augment enum A<T> {
  augment v
}
''');

    configuration
      ..withConstructors = false
      ..withConstantInitializers = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      enums
        #F1 enum A (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@enum::A
          nextFragment: #F2
          typeParameters
            #F3 isOriginOtherFragmentOfEnclosing T (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: #E0 T
              nextFragment: #F4
          fields
            #F5 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:11) (firstTokenOffset:11) (offset:11)
              element: <testLibrary>::@enum::A::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <null>
                      type: null
                    element: <null>
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: null
              inducedGetter: #F6
              nextFragment: #F7
            #F8 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v2 (nameOffset:14) (firstTokenOffset:14) (offset:14)
              element: <testLibrary>::@enum::A::@field::v2
              initializer: expression_1
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibrary>::@enum::A
                      type: A
                    element: <testLibrary>::@enum::A::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              inducedGetter: #F9
            #F10 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@field::values
              initializer: expression_2
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::A::@getter::v
                      staticType: A
                    SimpleIdentifier
                      token: v2 @-1
                      element: <testLibrary>::@enum::A::@getter::v2
                      staticType: A
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::A::@getter::v
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
              inducedGetter: #F11
          getters
            #F6 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::A::@getter::v
              inducingVariable: #F5
              nextFragment: #F12
            #F9 isComplete isOriginVariable isStatic v2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:14)
              element: <testLibrary>::@enum::A::@getter::v2
              inducingVariable: #F8
            #F11 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
              inducingVariable: #F10
        #F2 isAugmentation enum A (nameOffset:33) (firstTokenOffset:20) (offset:33)
          element: <testLibrary>::@enum::A
          previousFragment: #F1
          typeParameters
            #F4 T (nameOffset:35) (firstTokenOffset:35) (offset:35)
              element: #E0 T
              previousFragment: #F3
          fields
            #F7 hasImplicitType hasInitializer isAugmentation isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:50) (firstTokenOffset:42) (offset:50)
              element: <testLibrary>::@enum::A::@field::v
              initializer: expression_3
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibrary>::@enum::A
                      type: A
                    element: <testLibrary>::@enum::A::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              inducedGetter: #F12
              previousFragment: #F5
          getters
            #F12 isAugmentation isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:50)
              element: <testLibrary>::@enum::A::@getter::v
              inducingVariable: #F7
              previousFragment: #F6
  enums
    isSimplyBounded enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F5
          type: A
          constantInitializer
            fragment: #F7
            expression: expression_3
          getter: <testLibrary>::@enum::A::@getter::v
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v2
          reference: <testLibrary>::@enum::A::@field::v2
          firstFragment: #F8
          type: A
          constantInitializer
            fragment: #F8
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::v2
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F10
          type: List<A>
          constantInitializer
            fragment: #F10
            expression: expression_2
          getter: <testLibrary>::@enum::A::@getter::values
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F6
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v
        isOriginVariable isStatic v2
          reference: <testLibrary>::@enum::A::@getter::v2
          firstFragment: #F9
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v2
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F11
          returnType: List<A>
          variable: <testLibrary>::@enum::A::@field::values
''');
  }

  test_constant_augmentation_chain_withArguments() async {
    var library = await buildLibrary(r'''
enum A {
  v1(1), v2(2);
  const A(int value);
}

augment enum A {
  augment v1(3)
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      enums
        #F1 enum A (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@enum::A
          nextFragment: #F2
          fields
            #F3 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v1 (nameOffset:11) (firstTokenOffset:11) (offset:11)
              element: <testLibrary>::@enum::A::@field::v1
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <null>
                      type: null
                    element: <null>
                  argumentList: ArgumentList
                    leftParenthesis: ( @13
                    arguments
                      IntegerLiteral
                        literal: 1 @14
                        staticType: null
                    rightParenthesis: ) @15
                  staticType: null
              inducedGetter: #F4
              nextFragment: #F5
            #F6 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v2 (nameOffset:18) (firstTokenOffset:18) (offset:18)
              element: <testLibrary>::@enum::A::@field::v2
              initializer: expression_1
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibrary>::@enum::A
                      type: A
                    element: <testLibrary>::@enum::A::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @20
                    arguments
                      IntegerLiteral
                        literal: 2 @21
                        staticType: int
                    rightParenthesis: ) @22
                  staticType: A
              inducedGetter: #F7
            #F8 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@field::values
              initializer: expression_2
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v1 @-1
                      element: <testLibrary>::@enum::A::@getter::v1
                      staticType: A
                    SimpleIdentifier
                      token: v2 @-1
                      element: <testLibrary>::@enum::A::@getter::v2
                      staticType: A
                    SimpleIdentifier
                      token: v1 @-1
                      element: <testLibrary>::@enum::A::@getter::v1
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
              inducedGetter: #F9
          constructors
            #F10 isConst isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:27) (offset:33)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
              typeNameOffset: 33
              formalParameters
                #F11 requiredPositional isOriginDeclaration value (nameOffset:39) (firstTokenOffset:35) (offset:39)
                  element: <testLibrary>::@enum::A::@constructor::new::@formalParameter::value
          getters
            #F4 isComplete isOriginVariable isStatic v1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::A::@getter::v1
              inducingVariable: #F3
              nextFragment: #F12
            #F7 isComplete isOriginVariable isStatic v2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:18)
              element: <testLibrary>::@enum::A::@getter::v2
              inducingVariable: #F6
            #F9 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
              inducingVariable: #F8
        #F2 isAugmentation enum A (nameOffset:63) (firstTokenOffset:50) (offset:63)
          element: <testLibrary>::@enum::A
          previousFragment: #F1
          fields
            #F5 hasImplicitType hasInitializer isAugmentation isConst isEnumConstant isOriginDeclaration isStatic v1 (nameOffset:77) (firstTokenOffset:69) (offset:77)
              element: <testLibrary>::@enum::A::@field::v1
              initializer: expression_3
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibrary>::@enum::A
                      type: A
                    element: <testLibrary>::@enum::A::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @79
                    arguments
                      IntegerLiteral
                        literal: 3 @80
                        staticType: int
                    rightParenthesis: ) @81
                  staticType: A
              inducedGetter: #F12
              previousFragment: #F3
          getters
            #F12 isAugmentation isComplete isOriginVariable isStatic v1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:77)
              element: <testLibrary>::@enum::A::@getter::v1
              inducingVariable: #F5
              previousFragment: #F4
  enums
    isSimplyBounded enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v1
          reference: <testLibrary>::@enum::A::@field::v1
          firstFragment: #F3
          type: A
          constantInitializer
            fragment: #F5
            expression: expression_3
          getter: <testLibrary>::@enum::A::@getter::v1
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v2
          reference: <testLibrary>::@enum::A::@field::v2
          firstFragment: #F6
          type: A
          constantInitializer
            fragment: #F6
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::v2
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F8
          type: List<A>
          constantInitializer
            fragment: #F8
            expression: expression_2
          getter: <testLibrary>::@enum::A::@getter::values
      constructors
        isConst isOriginDeclaration new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F10
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F11
              type: int
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v1
          reference: <testLibrary>::@enum::A::@getter::v1
          firstFragment: #F4
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v1
        isOriginVariable isStatic v2
          reference: <testLibrary>::@enum::A::@getter::v2
          firstFragment: #F7
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v2
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F9
          returnType: List<A>
          variable: <testLibrary>::@enum::A::@field::values
''');
  }

  test_constant_augmentation_introductoryHasConstants_augmentationHasConstants() async {
    var library = await buildLibrary(r'''
enum A {
  v1
}

augment enum A {
  v2
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      enums
        #F1 enum A (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@enum::A
          nextFragment: #F2
          fields
            #F3 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v1 (nameOffset:11) (firstTokenOffset:11) (offset:11)
              element: <testLibrary>::@enum::A::@field::v1
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibrary>::@enum::A
                      type: A
                    element: <testLibrary>::@enum::A::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              inducedGetter: #F4
            #F5 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v1 @-1
                      element: <testLibrary>::@enum::A::@getter::v1
                      staticType: A
                    SimpleIdentifier
                      token: v2 @-1
                      element: <testLibrary>::@enum::A::@getter::v2
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
              inducedGetter: #F6
          constructors
            #F7 isConst isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
          getters
            #F4 isComplete isOriginVariable isStatic v1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::A::@getter::v1
              inducingVariable: #F3
            #F6 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
              inducingVariable: #F5
        #F2 isAugmentation enum A (nameOffset:30) (firstTokenOffset:17) (offset:30)
          element: <testLibrary>::@enum::A
          previousFragment: #F1
          fields
            #F8 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v2 (nameOffset:36) (firstTokenOffset:36) (offset:36)
              element: <testLibrary>::@enum::A::@field::v2
              initializer: expression_2
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibrary>::@enum::A
                      type: A
                    element: <testLibrary>::@enum::A::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              inducedGetter: #F9
          getters
            #F9 isComplete isOriginVariable isStatic v2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:36)
              element: <testLibrary>::@enum::A::@getter::v2
              inducingVariable: #F8
  enums
    isSimplyBounded enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v1
          reference: <testLibrary>::@enum::A::@field::v1
          firstFragment: #F3
          type: A
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v1
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F5
          type: List<A>
          constantInitializer
            fragment: #F5
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v2
          reference: <testLibrary>::@enum::A::@field::v2
          firstFragment: #F8
          type: A
          constantInitializer
            fragment: #F8
            expression: expression_2
          getter: <testLibrary>::@enum::A::@getter::v2
      constructors
        isConst isOriginImplicitDefault new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F7
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v1
          reference: <testLibrary>::@enum::A::@getter::v1
          firstFragment: #F4
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v1
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F6
          returnType: List<A>
          variable: <testLibrary>::@enum::A::@field::values
        isOriginVariable isStatic v2
          reference: <testLibrary>::@enum::A::@getter::v2
          firstFragment: #F9
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v2
''');
  }

  test_constant_augmentation_introductoryHasConstants_augmentationNoConstants_blockBody_empty() async {
    var library = await buildLibrary(r'''
enum E { v }

augment enum E {}
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
          nextFragment: #F2
          fields
            #F3 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:9) (firstTokenOffset:9) (offset:9)
              element: <testLibrary>::@enum::E::@field::v
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
              inducedGetter: #F4
            #F5 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::E::@getter::v
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
              inducedGetter: #F6
          constructors
            #F7 isConst isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F4 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:9)
              element: <testLibrary>::@enum::E::@getter::v
              inducingVariable: #F3
            #F6 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
              inducingVariable: #F5
        #F2 isAugmentation enum E (nameOffset:27) (firstTokenOffset:14) (offset:27)
          element: <testLibrary>::@enum::E
          previousFragment: #F1
  enums
    isSimplyBounded enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F3
          type: E
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F5
          type: List<E>
          constantInitializer
            fragment: #F5
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        isConst isOriginImplicitDefault new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F7
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F4
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F6
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
''');
  }

  test_constant_augmentation_introductoryHasConstants_augmentationNoConstants_blockBody_semicolon() async {
    var library = await buildLibrary(r'''
enum E { v }

augment enum E {;}
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
          nextFragment: #F2
          fields
            #F3 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:9) (firstTokenOffset:9) (offset:9)
              element: <testLibrary>::@enum::E::@field::v
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
              inducedGetter: #F4
            #F5 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::E::@getter::v
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
              inducedGetter: #F6
          constructors
            #F7 isConst isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F4 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:9)
              element: <testLibrary>::@enum::E::@getter::v
              inducingVariable: #F3
            #F6 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
              inducingVariable: #F5
        #F2 isAugmentation enum E (nameOffset:27) (firstTokenOffset:14) (offset:27)
          element: <testLibrary>::@enum::E
          previousFragment: #F1
  enums
    isSimplyBounded enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F3
          type: E
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F5
          type: List<E>
          constantInitializer
            fragment: #F5
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        isConst isOriginImplicitDefault new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F7
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F4
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F6
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
''');
  }

  test_constant_augmentation_introductoryHasConstants_augmentationNoConstants_emptyBody() async {
    var library = await buildLibrary(r'''
enum E { v }

augment enum E;
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
          nextFragment: #F2
          fields
            #F3 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:9) (firstTokenOffset:9) (offset:9)
              element: <testLibrary>::@enum::E::@field::v
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
              inducedGetter: #F4
            #F5 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::E::@getter::v
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
              inducedGetter: #F6
          constructors
            #F7 isConst isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F4 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:9)
              element: <testLibrary>::@enum::E::@getter::v
              inducingVariable: #F3
            #F6 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
              inducingVariable: #F5
        #F2 isAugmentation enum E (nameOffset:27) (firstTokenOffset:14) (offset:27)
          element: <testLibrary>::@enum::E
          previousFragment: #F1
  enums
    isSimplyBounded enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F3
          type: E
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F5
          type: List<E>
          constantInitializer
            fragment: #F5
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        isConst isOriginImplicitDefault new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F7
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F4
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F6
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
''');
  }

  test_constant_augmentation_introductoryNoConstants_augmentationHasConstants() async {
    var library = await buildLibrary(r'''
enum E {}

augment enum E { v }
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
          nextFragment: #F2
          fields
            #F3 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@field::values
              initializer: expression_0
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::E::@getter::v
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
              inducedGetter: #F4
          constructors
            #F5 isConst isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F4 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
              inducingVariable: #F3
        #F2 isAugmentation enum E (nameOffset:24) (firstTokenOffset:11) (offset:24)
          element: <testLibrary>::@enum::E
          previousFragment: #F1
          fields
            #F6 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:28) (firstTokenOffset:28) (offset:28)
              element: <testLibrary>::@enum::E::@field::v
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
              inducedGetter: #F7
          getters
            #F7 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:28)
              element: <testLibrary>::@enum::E::@getter::v
              inducingVariable: #F6
  enums
    isSimplyBounded enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F3
          type: List<E>
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::values
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F6
          type: E
          constantInitializer
            fragment: #F6
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::v
      constructors
        isConst isOriginImplicitDefault new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F5
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F4
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F7
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
''');
  }

  test_constant_augmentation_introductoryNoConstants_augmentationNoConstants() async {
    var library = await buildLibrary(r'''
enum E {}

augment enum E {}
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
          nextFragment: #F2
          fields
            #F3 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@field::values
              initializer: expression_0
                ListLiteral
                  leftBracket: [ @0
                  rightBracket: ] @0
                  staticType: List<E>
              inducedGetter: #F4
          constructors
            #F5 isConst isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F4 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
              inducingVariable: #F3
        #F2 isAugmentation enum E (nameOffset:24) (firstTokenOffset:11) (offset:24)
          element: <testLibrary>::@enum::E
          previousFragment: #F1
  enums
    isSimplyBounded enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F3
          type: List<E>
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        isConst isOriginImplicitDefault new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F5
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F4
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
''');
  }

  test_constant_augmentation_valuesGetter() async {
    var library = await buildLibrary(r'''
enum A {
  v1
}

augment enum A {
  v2
}

augment enum A {;
  static int get values => 0;
}

augment enum A {
  v3
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      enums
        #F1 enum A (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@enum::A
          nextFragment: #F2
          fields
            #F3 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v1 (nameOffset:11) (firstTokenOffset:11) (offset:11)
              element: <testLibrary>::@enum::A::@field::v1
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibrary>::@enum::A
                      type: A
                    element: <testLibrary>::@enum::A::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              inducedGetter: #F4
            #F5 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v1 @-1
                      element: <testLibrary>::@enum::A::@getter::v1
                      staticType: A
                    SimpleIdentifier
                      token: v2 @-1
                      element: <testLibrary>::@enum::A::@getter::v2
                      staticType: A
                    SimpleIdentifier
                      token: v3 @-1
                      element: <testLibrary>::@enum::A::@getter::v3
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
              inducedGetter: #F6
          constructors
            #F7 isConst isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
          getters
            #F4 isComplete isOriginVariable isStatic v1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::A::@getter::v1
              inducingVariable: #F3
            #F6 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
              inducingVariable: #F5
        #F2 isAugmentation enum A (nameOffset:30) (firstTokenOffset:17) (offset:30)
          element: <testLibrary>::@enum::A
          previousFragment: #F1
          nextFragment: #F8
          fields
            #F9 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v2 (nameOffset:36) (firstTokenOffset:36) (offset:36)
              element: <testLibrary>::@enum::A::@field::v2
              initializer: expression_2
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibrary>::@enum::A
                      type: A
                    element: <testLibrary>::@enum::A::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              inducedGetter: #F10
          getters
            #F10 isComplete isOriginVariable isStatic v2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:36)
              element: <testLibrary>::@enum::A::@getter::v2
              inducingVariable: #F9
        #F8 isAugmentation enum A (nameOffset:55) (firstTokenOffset:42) (offset:55)
          element: <testLibrary>::@enum::A
          previousFragment: #F2
          nextFragment: #F11
          fields
            #F12 isOriginGetterSetter isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:55)
              element: <testLibrary>::@enum::A::@field::values#1
          getters
            #F13 isComplete isOriginDeclaration isStatic values (nameOffset:77) (firstTokenOffset:62) (offset:77)
              element: <testLibrary>::@enum::A::@getter::values#1
        #F11 isAugmentation enum A (nameOffset:106) (firstTokenOffset:93) (offset:106)
          element: <testLibrary>::@enum::A
          previousFragment: #F8
          fields
            #F14 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v3 (nameOffset:112) (firstTokenOffset:112) (offset:112)
              element: <testLibrary>::@enum::A::@field::v3
              initializer: expression_3
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibrary>::@enum::A
                      type: A
                    element: <testLibrary>::@enum::A::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              inducedGetter: #F15
          getters
            #F15 isComplete isOriginVariable isStatic v3 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:112)
              element: <testLibrary>::@enum::A::@getter::v3
              inducingVariable: #F14
  enums
    isSimplyBounded enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v1
          reference: <testLibrary>::@enum::A::@field::v1
          firstFragment: #F3
          type: A
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v1
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F5
          type: List<A>
          constantInitializer
            fragment: #F5
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v2
          reference: <testLibrary>::@enum::A::@field::v2
          firstFragment: #F9
          type: A
          constantInitializer
            fragment: #F9
            expression: expression_2
          getter: <testLibrary>::@enum::A::@getter::v2
        isOriginGetterSetter isStatic values
          reference: <testLibrary>::@enum::A::@field::values#1
          firstFragment: #F12
          type: int
          getter: <testLibrary>::@enum::A::@getter::values#1
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v3
          reference: <testLibrary>::@enum::A::@field::v3
          firstFragment: #F14
          type: A
          constantInitializer
            fragment: #F14
            expression: expression_3
          getter: <testLibrary>::@enum::A::@getter::v3
      constructors
        isConst isOriginImplicitDefault new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F7
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v1
          reference: <testLibrary>::@enum::A::@getter::v1
          firstFragment: #F4
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v1
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F6
          returnType: List<A>
          variable: <testLibrary>::@enum::A::@field::values
        isOriginVariable isStatic v2
          reference: <testLibrary>::@enum::A::@getter::v2
          firstFragment: #F10
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v2
        isOriginDeclaration isStatic values
          reference: <testLibrary>::@enum::A::@getter::values#1
          firstFragment: #F13
          returnType: int
          variable: <testLibrary>::@enum::A::@field::values#1
        isOriginVariable isStatic v3
          reference: <testLibrary>::@enum::A::@getter::v3
          firstFragment: #F15
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v3
''');
  }

  test_constant_documented() async {
    var library = await buildLibrary(r'''
enum E {
  /**
   * aaa
   */
  a,

  /// bbb
  b,
}
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
            #F2 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic a (nameOffset:32) (firstTokenOffset:11) (offset:32)
              element: <testLibrary>::@enum::E::@field::a
              documentationComment: /**\n   * aaa\n   */
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
              inducedGetter: #F3
            #F4 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic b (nameOffset:48) (firstTokenOffset:38) (offset:48)
              element: <testLibrary>::@enum::E::@field::b
              documentationComment: /// bbb
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
              inducedGetter: #F5
            #F6 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
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
              inducedGetter: #F7
          constructors
            #F8 isConst isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F3 isComplete isOriginVariable isStatic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:32)
              element: <testLibrary>::@enum::E::@getter::a
              inducingVariable: #F2
            #F5 isComplete isOriginVariable isStatic b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:48)
              element: <testLibrary>::@enum::E::@getter::b
              inducingVariable: #F4
            #F7 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
              inducingVariable: #F6
  enums
    isSimplyBounded enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer a
          reference: <testLibrary>::@enum::E::@field::a
          firstFragment: #F2
          documentationComment: /**\n   * aaa\n   */
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::a
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer b
          reference: <testLibrary>::@enum::E::@field::b
          firstFragment: #F4
          documentationComment: /// bbb
          type: E
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::b
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F6
          type: List<E>
          constantInitializer
            fragment: #F6
            expression: expression_2
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        isConst isOriginImplicitDefault new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F8
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic a
          reference: <testLibrary>::@enum::E::@getter::a
          firstFragment: #F3
          returnType: E
          variable: <testLibrary>::@enum::E::@field::a
        isOriginVariable isStatic b
          reference: <testLibrary>::@enum::E::@getter::b
          firstFragment: #F5
          returnType: E
          variable: <testLibrary>::@enum::E::@field::b
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F7
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
''');
  }

  test_constant_documented_withMetadata() async {
    var library = await buildLibrary(r'''
enum E {
  /**
   * aaa
   */
  @annotation
  a,

  /// bbb
  @annotation
  b,
}

const int annotation = 0;
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
            #F2 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic a (nameOffset:46) (firstTokenOffset:11) (offset:46)
              element: <testLibrary>::@enum::E::@field::a
              documentationComment: /**\n   * aaa\n   */
              metadata
                Annotation
                  atSign: @ @32
                  name: SimpleIdentifier
                    token: annotation @33
                    element: <testLibrary>::@getter::annotation
                    staticType: null
                  element: <testLibrary>::@getter::annotation
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
              inducedGetter: #F3
            #F4 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic b (nameOffset:76) (firstTokenOffset:52) (offset:76)
              element: <testLibrary>::@enum::E::@field::b
              documentationComment: /// bbb
              metadata
                Annotation
                  atSign: @ @62
                  name: SimpleIdentifier
                    token: annotation @63
                    element: <testLibrary>::@getter::annotation
                    staticType: null
                  element: <testLibrary>::@getter::annotation
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
              inducedGetter: #F5
            #F6 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
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
              inducedGetter: #F7
          constructors
            #F8 isConst isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F3 isComplete isOriginVariable isStatic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:46)
              element: <testLibrary>::@enum::E::@getter::a
              inducingVariable: #F2
            #F5 isComplete isOriginVariable isStatic b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:76)
              element: <testLibrary>::@enum::E::@getter::b
              inducingVariable: #F4
            #F7 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
              inducingVariable: #F6
      topLevelVariables
        #F9 hasInitializer isConst isOriginDeclaration isStatic annotation (nameOffset:92) (firstTokenOffset:92) (offset:92)
          element: <testLibrary>::@topLevelVariable::annotation
          initializer: expression_3
            IntegerLiteral
              literal: 0 @105
              staticType: int
          inducedGetter: #F10
      getters
        #F10 isComplete isOriginVariable isStatic annotation (nameOffset:<null>) (firstTokenOffset:<null>) (offset:92)
          element: <testLibrary>::@getter::annotation
          inducingVariable: #F9
  enums
    isSimplyBounded enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer a
          reference: <testLibrary>::@enum::E::@field::a
          firstFragment: #F2
          documentationComment: /**\n   * aaa\n   */
          metadata
            Annotation
              atSign: @ @32
              name: SimpleIdentifier
                token: annotation @33
                element: <testLibrary>::@getter::annotation
                staticType: null
              element: <testLibrary>::@getter::annotation
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::a
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer b
          reference: <testLibrary>::@enum::E::@field::b
          firstFragment: #F4
          documentationComment: /// bbb
          metadata
            Annotation
              atSign: @ @62
              name: SimpleIdentifier
                token: annotation @63
                element: <testLibrary>::@getter::annotation
                staticType: null
              element: <testLibrary>::@getter::annotation
          type: E
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::b
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F6
          type: List<E>
          constantInitializer
            fragment: #F6
            expression: expression_2
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        isConst isOriginImplicitDefault new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F8
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic a
          reference: <testLibrary>::@enum::E::@getter::a
          firstFragment: #F3
          returnType: E
          variable: <testLibrary>::@enum::E::@field::a
        isOriginVariable isStatic b
          reference: <testLibrary>::@enum::E::@getter::b
          firstFragment: #F5
          returnType: E
          variable: <testLibrary>::@enum::E::@field::b
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F7
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
  topLevelVariables
    hasInitializer isConst isOriginDeclaration isStatic annotation
      reference: <testLibrary>::@topLevelVariable::annotation
      firstFragment: #F9
      type: int
      constantInitializer
        fragment: #F9
        expression: expression_3
      getter: <testLibrary>::@getter::annotation
  getters
    isOriginVariable isStatic annotation
      reference: <testLibrary>::@getter::annotation
      firstFragment: #F10
      returnType: int
      variable: <testLibrary>::@topLevelVariable::annotation
''');
  }

  test_constant_inference() async {
    var library = await buildLibrary(r'''
enum E<T> {
  int(1),
  string('2');

  const E(T a);
}
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
          typeParameters
            #F2 T (nameOffset:7) (firstTokenOffset:7) (offset:7)
              element: #E0 T
          fields
            #F3 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic int (nameOffset:14) (firstTokenOffset:14) (offset:14)
              element: <testLibrary>::@enum::E::@field::int
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibrary>::@enum::E
                      type: E<int>
                    element: SubstitutedConstructorElementImpl
                      baseElement: <testLibrary>::@enum::E::@constructor::new
                      substitution: {T: int}
                  argumentList: ArgumentList
                    leftParenthesis: ( @17
                    arguments
                      IntegerLiteral
                        literal: 1 @18
                        staticType: int
                    rightParenthesis: ) @19
                  staticType: E<int>
              inducedGetter: #F4
            #F5 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic string (nameOffset:24) (firstTokenOffset:24) (offset:24)
              element: <testLibrary>::@enum::E::@field::string
              initializer: expression_1
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibrary>::@enum::E
                      type: E<String>
                    element: SubstitutedConstructorElementImpl
                      baseElement: <testLibrary>::@enum::E::@constructor::new
                      substitution: {T: String}
                  argumentList: ArgumentList
                    leftParenthesis: ( @30
                    arguments
                      SimpleStringLiteral
                        literal: '2' @31
                    rightParenthesis: ) @34
                  staticType: E<String>
              inducedGetter: #F6
            #F7 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@field::values
              initializer: expression_2
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: int @-1
                      element: <testLibrary>::@enum::E::@getter::int
                      staticType: E<int>
                    SimpleIdentifier
                      token: string @-1
                      element: <testLibrary>::@enum::E::@getter::string
                      staticType: E<String>
                  rightBracket: ] @0
                  staticType: List<E<dynamic>>
              inducedGetter: #F8
          constructors
            #F9 isConst isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:40) (offset:46)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
              typeNameOffset: 46
              formalParameters
                #F10 requiredPositional isOriginDeclaration a (nameOffset:50) (firstTokenOffset:48) (offset:50)
                  element: <testLibrary>::@enum::E::@constructor::new::@formalParameter::a
          getters
            #F4 isComplete isOriginVariable isStatic int (nameOffset:<null>) (firstTokenOffset:<null>) (offset:14)
              element: <testLibrary>::@enum::E::@getter::int
              inducingVariable: #F3
            #F6 isComplete isOriginVariable isStatic string (nameOffset:<null>) (firstTokenOffset:<null>) (offset:24)
              element: <testLibrary>::@enum::E::@getter::string
              inducingVariable: #F5
            #F8 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
              inducingVariable: #F7
  enums
    isSimplyBounded enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer int
          reference: <testLibrary>::@enum::E::@field::int
          firstFragment: #F3
          type: E<int>
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::int
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer string
          reference: <testLibrary>::@enum::E::@field::string
          firstFragment: #F5
          type: E<String>
          constantInitializer
            fragment: #F5
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::string
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F7
          type: List<E<dynamic>>
          constantInitializer
            fragment: #F7
            expression: expression_2
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        hasEnclosingTypeParameterReference isConst isOriginDeclaration new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F9
          formalParameters
            #E1 requiredPositional a
              firstFragment: #F10
              type: T
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic int
          reference: <testLibrary>::@enum::E::@getter::int
          firstFragment: #F4
          returnType: E<int>
          variable: <testLibrary>::@enum::E::@field::int
        isOriginVariable isStatic string
          reference: <testLibrary>::@enum::E::@getter::string
          firstFragment: #F6
          returnType: E<String>
          variable: <testLibrary>::@enum::E::@field::string
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F8
          returnType: List<E<dynamic>>
          variable: <testLibrary>::@enum::E::@field::values
''');
  }

  test_constant_metadata() async {
    var library = await buildLibrary(r'''
const a = 42;

enum E {
  @a
  v,
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      enums
        #F1 enum E (nameOffset:20) (firstTokenOffset:15) (offset:20)
          element: <testLibrary>::@enum::E
          fields
            #F2 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:31) (firstTokenOffset:26) (offset:31)
              element: <testLibrary>::@enum::E::@field::v
              metadata
                Annotation
                  atSign: @ @26
                  name: SimpleIdentifier
                    token: a @27
                    element: <testLibrary>::@getter::a
                    staticType: null
                  element: <testLibrary>::@getter::a
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
              inducedGetter: #F3
            #F4 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:20)
              element: <testLibrary>::@enum::E::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::E::@getter::v
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
              inducedGetter: #F5
          constructors
            #F6 isConst isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:20)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F3 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
              element: <testLibrary>::@enum::E::@getter::v
              inducingVariable: #F2
            #F5 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:20)
              element: <testLibrary>::@enum::E::@getter::values
              inducingVariable: #F4
      topLevelVariables
        #F7 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic a (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::a
          initializer: expression_2
            IntegerLiteral
              literal: 42 @10
              staticType: int
          inducedGetter: #F8
      getters
        #F8 isComplete isOriginVariable isStatic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
          inducingVariable: #F7
  enums
    isSimplyBounded enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F2
          metadata
            Annotation
              atSign: @ @26
              name: SimpleIdentifier
                token: a @27
                element: <testLibrary>::@getter::a
                staticType: null
              element: <testLibrary>::@getter::a
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F4
          type: List<E>
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        isConst isOriginImplicitDefault new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F6
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F3
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F5
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
  topLevelVariables
    hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F7
      type: int
      constantInitializer
        fragment: #F7
        expression: expression_2
      getter: <testLibrary>::@getter::a
  getters
    isOriginVariable isStatic a
      reference: <testLibrary>::@getter::a
      firstFragment: #F8
      returnType: int
      variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_constant_metadata_instanceCreation() async {
    var library = await buildLibrary(r'''
class A {
  final dynamic value;
  const A(this.value);
}

enum E {
  @A(100)
  a,
  b,
  @A(300)
  c,
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
            #F2 isFinal isOriginDeclaration value (nameOffset:26) (firstTokenOffset:26) (offset:26)
              element: <testLibrary>::@class::A::@field::value
              inducedGetter: #F3
          constructors
            #F4 isComplete isConst isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:35) (offset:41)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
              typeNameOffset: 41
              formalParameters
                #F5 requiredPositional hasImplicitType isFinal isOriginDeclaration this.value (nameOffset:48) (firstTokenOffset:43) (offset:48)
                  element: <testLibrary>::@class::A::@constructor::new::@formalParameter::value
          getters
            #F3 isComplete isOriginVariable value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:26)
              element: <testLibrary>::@class::A::@getter::value
              inducingVariable: #F2
      enums
        #F6 enum E (nameOffset:64) (firstTokenOffset:59) (offset:64)
          element: <testLibrary>::@enum::E
          fields
            #F7 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic a (nameOffset:80) (firstTokenOffset:70) (offset:80)
              element: <testLibrary>::@enum::E::@field::a
              metadata
                Annotation
                  atSign: @ @70
                  name: SimpleIdentifier
                    token: A @71
                    element: <testLibrary>::@class::A
                    staticType: null
                  arguments: ArgumentList
                    leftParenthesis: ( @72
                    arguments
                      IntegerLiteral
                        literal: 100 @73
                        staticType: int
                    rightParenthesis: ) @76
                  element: <testLibrary>::@class::A::@constructor::new
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
              inducedGetter: #F8
            #F9 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic b (nameOffset:85) (firstTokenOffset:85) (offset:85)
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
              inducedGetter: #F10
            #F11 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic c (nameOffset:100) (firstTokenOffset:90) (offset:100)
              element: <testLibrary>::@enum::E::@field::c
              metadata
                Annotation
                  atSign: @ @90
                  name: SimpleIdentifier
                    token: A @91
                    element: <testLibrary>::@class::A
                    staticType: null
                  arguments: ArgumentList
                    leftParenthesis: ( @92
                    arguments
                      IntegerLiteral
                        literal: 300 @93
                        staticType: int
                    rightParenthesis: ) @96
                  element: <testLibrary>::@class::A::@constructor::new
              initializer: expression_2
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
              inducedGetter: #F12
            #F13 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:64)
              element: <testLibrary>::@enum::E::@field::values
              initializer: expression_3
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
                    SimpleIdentifier
                      token: c @-1
                      element: <testLibrary>::@enum::E::@getter::c
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
              inducedGetter: #F14
          constructors
            #F15 isConst isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:64)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F8 isComplete isOriginVariable isStatic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:80)
              element: <testLibrary>::@enum::E::@getter::a
              inducingVariable: #F7
            #F10 isComplete isOriginVariable isStatic b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:85)
              element: <testLibrary>::@enum::E::@getter::b
              inducingVariable: #F9
            #F12 isComplete isOriginVariable isStatic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:100)
              element: <testLibrary>::@enum::E::@getter::c
              inducingVariable: #F11
            #F14 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:64)
              element: <testLibrary>::@enum::E::@getter::values
              inducingVariable: #F13
  classes
    isSimplyBounded class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        isFinal isOriginDeclaration value
          reference: <testLibrary>::@class::A::@field::value
          firstFragment: #F2
          type: dynamic
          getter: <testLibrary>::@class::A::@getter::value
      constructors
        isConst isOriginDeclaration new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional hasImplicitType isFinal this.value
              firstFragment: #F5
              type: dynamic
              field: <testLibrary>::@class::A::@field::value
      getters
        isOriginVariable value
          reference: <testLibrary>::@class::A::@getter::value
          firstFragment: #F3
          returnType: dynamic
          variable: <testLibrary>::@class::A::@field::value
  enums
    isSimplyBounded enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F6
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer a
          reference: <testLibrary>::@enum::E::@field::a
          firstFragment: #F7
          metadata
            Annotation
              atSign: @ @70
              name: SimpleIdentifier
                token: A @71
                element: <testLibrary>::@class::A
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @72
                arguments
                  IntegerLiteral
                    literal: 100 @73
                    staticType: int
                rightParenthesis: ) @76
              element: <testLibrary>::@class::A::@constructor::new
          type: E
          constantInitializer
            fragment: #F7
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::a
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer b
          reference: <testLibrary>::@enum::E::@field::b
          firstFragment: #F9
          type: E
          constantInitializer
            fragment: #F9
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::b
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer c
          reference: <testLibrary>::@enum::E::@field::c
          firstFragment: #F11
          metadata
            Annotation
              atSign: @ @90
              name: SimpleIdentifier
                token: A @91
                element: <testLibrary>::@class::A
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @92
                arguments
                  IntegerLiteral
                    literal: 300 @93
                    staticType: int
                rightParenthesis: ) @96
              element: <testLibrary>::@class::A::@constructor::new
          type: E
          constantInitializer
            fragment: #F11
            expression: expression_2
          getter: <testLibrary>::@enum::E::@getter::c
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F13
          type: List<E>
          constantInitializer
            fragment: #F13
            expression: expression_3
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        isConst isOriginImplicitDefault new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F15
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic a
          reference: <testLibrary>::@enum::E::@getter::a
          firstFragment: #F8
          returnType: E
          variable: <testLibrary>::@enum::E::@field::a
        isOriginVariable isStatic b
          reference: <testLibrary>::@enum::E::@getter::b
          firstFragment: #F10
          returnType: E
          variable: <testLibrary>::@enum::E::@field::b
        isOriginVariable isStatic c
          reference: <testLibrary>::@enum::E::@getter::c
          firstFragment: #F12
          returnType: E
          variable: <testLibrary>::@enum::E::@field::c
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F14
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
''');
  }

  test_constant_metadata_self() async {
    var library = await buildLibrary(r'''
enum E {
  @v
  v,
}
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
            #F2 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:16) (firstTokenOffset:11) (offset:16)
              element: <testLibrary>::@enum::E::@field::v
              metadata
                Annotation
                  atSign: @ @11
                  name: SimpleIdentifier
                    token: v @12
                    element: <testLibrary>::@enum::E::@getter::v
                    staticType: null
                  element: <testLibrary>::@enum::E::@getter::v
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
              inducedGetter: #F3
            #F4 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::E::@getter::v
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
              inducedGetter: #F5
          constructors
            #F6 isConst isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F3 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@enum::E::@getter::v
              inducingVariable: #F2
            #F5 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
              inducingVariable: #F4
  enums
    isSimplyBounded enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F2
          metadata
            Annotation
              atSign: @ @11
              name: SimpleIdentifier
                token: v @12
                element: <testLibrary>::@enum::E::@getter::v
                staticType: null
              element: <testLibrary>::@enum::E::@getter::v
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F4
          type: List<E>
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        isConst isOriginImplicitDefault new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F6
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F3
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F5
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
''');
  }

  test_constant_missingName() async {
    var library = await buildLibrary(r'''
enum E {
  v,,
}
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
            #F2 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:11) (firstTokenOffset:11) (offset:11)
              element: <testLibrary>::@enum::E::@field::v
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
              inducedGetter: #F3
            #F4 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic <null-name> (nameOffset:<null>) (firstTokenOffset:13) (offset:13)
              element: <testLibrary>::@enum::E::@field::#0
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
              inducedGetter: #F5
            #F6 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@field::values
              initializer: expression_2
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::E::@getter::v
                      staticType: E
                    SimpleIdentifier
                      token: <empty> @-1 <synthetic>
                      element: <null>
                      staticType: InvalidType
                  rightBracket: ] @0
                  staticType: List<E>
              inducedGetter: #F7
          constructors
            #F8 isConst isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F3 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::E::@getter::v
              inducingVariable: #F2
            #F5 isComplete isOriginVariable isStatic <null-name> (nameOffset:<null>) (firstTokenOffset:<null>) (offset:13)
              element: <testLibrary>::@enum::E::@getter::#1
              inducingVariable: #F4
            #F7 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
              inducingVariable: #F6
  enums
    isSimplyBounded enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer <null-name>
          reference: <testLibrary>::@enum::E::@field::#0
          firstFragment: #F4
          type: E
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::#1
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F6
          type: List<E>
          constantInitializer
            fragment: #F6
            expression: expression_2
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        isConst isOriginImplicitDefault new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F8
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F3
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        isOriginVariable isStatic <null-name>
          reference: <testLibrary>::@enum::E::@getter::#1
          firstFragment: #F5
          returnType: E
          variable: <testLibrary>::@enum::E::@field::#0
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F7
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
''');
  }

  /// Test that a constant named `_name` renames the synthetic `name` field.
  test_constant_name() async {
    var library = await buildLibrary(r'''
enum E { _name }
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
            #F2 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic _name (nameOffset:9) (firstTokenOffset:9) (offset:9)
              element: <testLibrary>::@enum::E::@field::_name
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
              inducedGetter: #F3
            #F4 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: _name @-1
                      element: <testLibrary>::@enum::E::@getter::_name
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
              inducedGetter: #F5
          constructors
            #F6 isConst isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F3 isComplete isOriginVariable isStatic _name (nameOffset:<null>) (firstTokenOffset:<null>) (offset:9)
              element: <testLibrary>::@enum::E::@getter::_name
              inducingVariable: #F2
            #F5 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
              inducingVariable: #F4
  enums
    isSimplyBounded enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer _name
          reference: <testLibrary>::@enum::E::@field::_name
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::_name
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F4
          type: List<E>
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        isConst isOriginImplicitDefault new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F6
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic _name
          reference: <testLibrary>::@enum::E::@getter::_name
          firstFragment: #F3
          returnType: E
          variable: <testLibrary>::@enum::E::@field::_name
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F5
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
''');
  }

  test_constant_typeArguments() async {
    var library = await buildLibrary(r'''
enum E<T> {
  v<double>(42);

  const E(T a);
}
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
          typeParameters
            #F2 T (nameOffset:7) (firstTokenOffset:7) (offset:7)
              element: #E0 T
          fields
            #F3 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:14) (firstTokenOffset:14) (offset:14)
              element: <testLibrary>::@enum::E::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      typeArguments: TypeArgumentList
                        leftBracket: < @15
                        arguments
                          NamedType
                            name: double @16
                            element: dart:core::@class::double
                            type: double
                        rightBracket: > @22
                      element: <testLibrary>::@enum::E
                      type: E<double>
                    element: SubstitutedConstructorElementImpl
                      baseElement: <testLibrary>::@enum::E::@constructor::new
                      substitution: {T: double}
                  argumentList: ArgumentList
                    leftParenthesis: ( @23
                    arguments
                      IntegerLiteral
                        literal: 42 @24
                        staticType: double
                    rightParenthesis: ) @26
                  staticType: E<double>
              inducedGetter: #F4
            #F5 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::E::@getter::v
                      staticType: E<double>
                  rightBracket: ] @0
                  staticType: List<E<dynamic>>
              inducedGetter: #F6
          constructors
            #F7 isConst isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:32) (offset:38)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
              typeNameOffset: 38
              formalParameters
                #F8 requiredPositional isOriginDeclaration a (nameOffset:42) (firstTokenOffset:40) (offset:42)
                  element: <testLibrary>::@enum::E::@constructor::new::@formalParameter::a
          getters
            #F4 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:14)
              element: <testLibrary>::@enum::E::@getter::v
              inducingVariable: #F3
            #F6 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
              inducingVariable: #F5
  enums
    isSimplyBounded enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F3
          type: E<double>
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F5
          type: List<E<dynamic>>
          constantInitializer
            fragment: #F5
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        hasEnclosingTypeParameterReference isConst isOriginDeclaration new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F7
          formalParameters
            #E1 requiredPositional a
              firstFragment: #F8
              type: T
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F4
          returnType: E<double>
          variable: <testLibrary>::@enum::E::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F6
          returnType: List<E<dynamic>>
          variable: <testLibrary>::@enum::E::@field::values
''');
  }

  test_constant_underscore() async {
    var library = await buildLibrary(r'''
enum E { _ }
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
            #F2 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic _ (nameOffset:9) (firstTokenOffset:9) (offset:9)
              element: <testLibrary>::@enum::E::@field::_
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
              inducedGetter: #F3
            #F4 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: _ @-1
                      element: <testLibrary>::@enum::E::@getter::_
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
              inducedGetter: #F5
          constructors
            #F6 isConst isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F3 isComplete isOriginVariable isStatic _ (nameOffset:<null>) (firstTokenOffset:<null>) (offset:9)
              element: <testLibrary>::@enum::E::@getter::_
              inducingVariable: #F2
            #F5 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
              inducingVariable: #F4
  enums
    isSimplyBounded enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer _
          reference: <testLibrary>::@enum::E::@field::_
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::_
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F4
          type: List<E>
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        isConst isOriginImplicitDefault new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F6
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic _
          reference: <testLibrary>::@enum::E::@getter::_
          firstFragment: #F3
          returnType: E
          variable: <testLibrary>::@enum::E::@field::_
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F5
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
''');
  }

  test_constructor_primary_body_constantInitializers_assertInitializer() async {
    var library = await buildLibrary(r'''
enum E() {
  v;

  this : assert(true);
}
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
            #F2 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:13) (firstTokenOffset:13) (offset:13)
              element: <testLibrary>::@enum::E::@field::v
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
              inducedGetter: #F3
            #F4 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::E::@getter::v
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
              inducedGetter: #F5
          constructors
            #F6 isComplete isConst isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:5) (offset:5)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
              typeNameOffset: 5
              thisKeywordOffset: 19
          getters
            #F3 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:13)
              element: <testLibrary>::@enum::E::@getter::v
              inducingVariable: #F2
            #F5 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
              inducingVariable: #F4
  enums
    isSimplyBounded enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F4
          type: List<E>
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        isConst isOriginDeclaration isPrimary new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F6
          constantInitializers
            AssertInitializer
              assertKeyword: assert @26
              leftParenthesis: ( @32
              condition: BooleanLiteral
                literal: true @33
                staticType: bool
              rightParenthesis: ) @37
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F3
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F5
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
''');
  }

  test_constructor_primary_body_constantInitializers_fieldInitializer() async {
    var library = await buildLibrary(r'''
enum E() {
  v;

  final int x;
  this : x = 0;
}
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
            #F2 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:13) (firstTokenOffset:13) (offset:13)
              element: <testLibrary>::@enum::E::@field::v
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
              inducedGetter: #F3
            #F4 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::E::@getter::v
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
              inducedGetter: #F5
            #F6 isFinal isOriginDeclaration x (nameOffset:29) (firstTokenOffset:29) (offset:29)
              element: <testLibrary>::@enum::E::@field::x
              inducedGetter: #F7
          constructors
            #F8 isComplete isConst isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:5) (offset:5)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
              typeNameOffset: 5
              thisKeywordOffset: 34
          getters
            #F3 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:13)
              element: <testLibrary>::@enum::E::@getter::v
              inducingVariable: #F2
            #F5 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
              inducingVariable: #F4
            #F7 isComplete isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:29)
              element: <testLibrary>::@enum::E::@getter::x
              inducingVariable: #F6
  enums
    isSimplyBounded enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F4
          type: List<E>
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
        isFinal isOriginDeclaration x
          reference: <testLibrary>::@enum::E::@field::x
          firstFragment: #F6
          type: int
          getter: <testLibrary>::@enum::E::@getter::x
      constructors
        isConst isOriginDeclaration isPrimary new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F8
          constantInitializers
            ConstructorFieldInitializer
              fieldName: SimpleIdentifier
                token: x @41
                element: <testLibrary>::@enum::E::@field::x
                staticType: null
              equals: = @43
              expression: IntegerLiteral
                literal: 0 @45
                staticType: int
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F3
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F5
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
        isOriginVariable x
          reference: <testLibrary>::@enum::E::@getter::x
          firstFragment: #F7
          returnType: int
          variable: <testLibrary>::@enum::E::@field::x
''');
  }

  test_constructor_primary_body_duplicate() async {
    var library = await buildLibrary(r'''
enum E() {
  v;

  final int y;
  @Deprecated('0')
  this : y = 0;
  @Deprecated('1')
  this : y = 1;
}
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
            #F2 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:13) (firstTokenOffset:13) (offset:13)
              element: <testLibrary>::@enum::E::@field::v
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
              inducedGetter: #F3
            #F4 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::E::@getter::v
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
              inducedGetter: #F5
            #F6 isFinal isOriginDeclaration y (nameOffset:29) (firstTokenOffset:29) (offset:29)
              element: <testLibrary>::@enum::E::@field::y
              inducedGetter: #F7
          constructors
            #F8 isComplete isConst isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:5) (offset:5)
              element: <testLibrary>::@enum::E::@constructor::new
              metadata
                Annotation
                  atSign: @ @34
                  name: SimpleIdentifier
                    token: Deprecated @35
                    element: dart:core::@class::Deprecated
                    staticType: null
                  arguments: ArgumentList
                    leftParenthesis: ( @45
                    arguments
                      SimpleStringLiteral
                        literal: '0' @46
                    rightParenthesis: ) @49
                  element: dart:core::@class::Deprecated::@constructor::new
              typeName: E
              typeNameOffset: 5
              thisKeywordOffset: 53
          getters
            #F3 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:13)
              element: <testLibrary>::@enum::E::@getter::v
              inducingVariable: #F2
            #F5 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
              inducingVariable: #F4
            #F7 isComplete isOriginVariable y (nameOffset:<null>) (firstTokenOffset:<null>) (offset:29)
              element: <testLibrary>::@enum::E::@getter::y
              inducingVariable: #F6
  enums
    isSimplyBounded enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F4
          type: List<E>
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
        isFinal isOriginDeclaration y
          reference: <testLibrary>::@enum::E::@field::y
          firstFragment: #F6
          type: int
          getter: <testLibrary>::@enum::E::@getter::y
      constructors
        isConst isOriginDeclaration isPrimary new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F8
          metadata
            Annotation
              atSign: @ @34
              name: SimpleIdentifier
                token: Deprecated @35
                element: dart:core::@class::Deprecated
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @45
                arguments
                  SimpleStringLiteral
                    literal: '0' @46
                rightParenthesis: ) @49
              element: dart:core::@class::Deprecated::@constructor::new
          constantInitializers
            ConstructorFieldInitializer
              fieldName: SimpleIdentifier
                token: y @60
                element: <testLibrary>::@enum::E::@field::y
                staticType: null
              equals: = @62
              expression: IntegerLiteral
                literal: 0 @64
                staticType: int
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F3
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F5
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
        isOriginVariable y
          reference: <testLibrary>::@enum::E::@getter::y
          firstFragment: #F7
          returnType: int
          variable: <testLibrary>::@enum::E::@field::y
''');
  }

  test_constructor_primary_body_metadata() async {
    var library = await buildLibrary(r'''
enum E(int x) {
  v(0);

  @deprecated
  this;
}
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
            #F2 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:18) (firstTokenOffset:18) (offset:18)
              element: <testLibrary>::@enum::E::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibrary>::@enum::E
                      type: E
                    element: <testLibrary>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @19
                    arguments
                      IntegerLiteral
                        literal: 0 @20
                        staticType: int
                    rightParenthesis: ) @21
                  staticType: E
              inducedGetter: #F3
            #F4 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::E::@getter::v
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
              inducedGetter: #F5
          constructors
            #F6 isComplete isConst isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:5) (offset:5)
              element: <testLibrary>::@enum::E::@constructor::new
              metadata
                Annotation
                  atSign: @ @27
                  name: SimpleIdentifier
                    token: deprecated @28
                    element: dart:core::@getter::deprecated
                    staticType: null
                  element: dart:core::@getter::deprecated
              typeName: E
              typeNameOffset: 5
              thisKeywordOffset: 41
              formalParameters
                #F7 requiredPositional isOriginDeclaration x (nameOffset:11) (firstTokenOffset:7) (offset:11)
                  element: <testLibrary>::@enum::E::@constructor::new::@formalParameter::x
          getters
            #F3 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:18)
              element: <testLibrary>::@enum::E::@getter::v
              inducingVariable: #F2
            #F5 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
              inducingVariable: #F4
  enums
    isSimplyBounded enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F4
          type: List<E>
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        isConst isOriginDeclaration isPrimary new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F6
          metadata
            Annotation
              atSign: @ @27
              name: SimpleIdentifier
                token: deprecated @28
                element: dart:core::@getter::deprecated
                staticType: null
              element: dart:core::@getter::deprecated
          formalParameters
            #E0 requiredPositional x
              firstFragment: #F7
              type: int
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F3
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F5
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
''');
  }

  test_constructor_primary_body_named() async {
    var library = await buildLibrary(r'''
enum E.named() {
  v.named();

  this : assert(true);
}
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
            #F2 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:19) (firstTokenOffset:19) (offset:19)
              element: <testLibrary>::@enum::E::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibrary>::@enum::E
                      type: E
                    period: . @0
                    name: SimpleIdentifier
                      token: named @-1
                      element: <testLibrary>::@enum::E::@constructor::named
                      staticType: null
                    element: <testLibrary>::@enum::E::@constructor::named
                  argumentList: ArgumentList
                    leftParenthesis: ( @26
                    rightParenthesis: ) @27
                  staticType: E
              inducedGetter: #F3
            #F4 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::E::@getter::v
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
              inducedGetter: #F5
          constructors
            #F6 isComplete isConst isOriginDeclaration isPrimary named (nameOffset:7) (firstTokenOffset:5) (offset:7)
              element: <testLibrary>::@enum::E::@constructor::named
              typeName: E
              typeNameOffset: 5
              periodOffset: 6
              thisKeywordOffset: 33
          getters
            #F3 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:19)
              element: <testLibrary>::@enum::E::@getter::v
              inducingVariable: #F2
            #F5 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
              inducingVariable: #F4
  enums
    isSimplyBounded enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F4
          type: List<E>
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        isConst isOriginDeclaration isPrimary named
          reference: <testLibrary>::@enum::E::@constructor::named
          firstFragment: #F6
          constantInitializers
            AssertInitializer
              assertKeyword: assert @40
              leftParenthesis: ( @46
              condition: BooleanLiteral
                literal: true @47
                staticType: bool
              rightParenthesis: ) @51
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F3
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F5
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
''');
  }

  test_constructor_primary_body_noDeclaration() async {
    var library = await buildLibrary(r'''
enum E {
  v;

  this : assert(true);
}
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
            #F2 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:11) (firstTokenOffset:11) (offset:11)
              element: <testLibrary>::@enum::E::@field::v
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
              inducedGetter: #F3
            #F4 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::E::@getter::v
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
              inducedGetter: #F5
          constructors
            #F6 isConst isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F3 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::E::@getter::v
              inducingVariable: #F2
            #F5 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
              inducingVariable: #F4
  enums
    isSimplyBounded enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F4
          type: List<E>
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        isConst isOriginImplicitDefault new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F6
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F3
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F5
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
''');
  }

  test_constructor_primary_body_notConst() async {
    var library = await buildLibrary(r'''
enum E() {
  v;

  this : assert(true);
}
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
            #F2 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:13) (firstTokenOffset:13) (offset:13)
              element: <testLibrary>::@enum::E::@field::v
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
              inducedGetter: #F3
            #F4 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::E::@getter::v
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
              inducedGetter: #F5
          constructors
            #F6 isComplete isConst isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:5) (offset:5)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
              typeNameOffset: 5
              thisKeywordOffset: 19
          getters
            #F3 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:13)
              element: <testLibrary>::@enum::E::@getter::v
              inducingVariable: #F2
            #F5 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
              inducingVariable: #F4
  enums
    isSimplyBounded enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F4
          type: List<E>
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        isConst isOriginDeclaration isPrimary new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F6
          constantInitializers
            AssertInitializer
              assertKeyword: assert @26
              leftParenthesis: ( @32
              condition: BooleanLiteral
                literal: true @33
                staticType: bool
              rightParenthesis: ) @37
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F3
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F5
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
''');
  }

  test_constructor_primary_body_primaryInitializerScope() async {
    var library = await buildLibrary(r'''
enum E(int x) {
  v(1);

  this : assert(x > 0);
}
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
            #F2 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:18) (firstTokenOffset:18) (offset:18)
              element: <testLibrary>::@enum::E::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibrary>::@enum::E
                      type: E
                    element: <testLibrary>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @19
                    arguments
                      IntegerLiteral
                        literal: 1 @20
                        staticType: int
                    rightParenthesis: ) @21
                  staticType: E
              inducedGetter: #F3
            #F4 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::E::@getter::v
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
              inducedGetter: #F5
          constructors
            #F6 isComplete isConst isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:5) (offset:5)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
              typeNameOffset: 5
              thisKeywordOffset: 27
              formalParameters
                #F7 requiredPositional isOriginDeclaration x (nameOffset:11) (firstTokenOffset:7) (offset:11)
                  element: <testLibrary>::@enum::E::@constructor::new::@formalParameter::x
          getters
            #F3 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:18)
              element: <testLibrary>::@enum::E::@getter::v
              inducingVariable: #F2
            #F5 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
              inducingVariable: #F4
  enums
    isSimplyBounded enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F4
          type: List<E>
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        isConst isOriginDeclaration isPrimary new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F6
          formalParameters
            #E0 requiredPositional x
              firstFragment: #F7
              type: int
          constantInitializers
            AssertInitializer
              assertKeyword: assert @34
              leftParenthesis: ( @40
              condition: BinaryExpression
                leftOperand: SimpleIdentifier
                  token: x @41
                  element: <testLibrary>::@enum::E::@constructor::new::@formalParameter::x
                  staticType: int
                operator: > @43
                rightOperand: IntegerLiteral
                  literal: 0 @45
                  staticType: int
                element: dart:core::@class::num::@method::>
                staticInvokeType: bool Function(num)
                staticType: bool
              rightParenthesis: ) @46
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F3
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F5
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
''');
  }

  test_constructor_primary_declaringFormalParameter_optionalNamed_simple_final() async {
    var library = await buildLibrary(r'''
enum A({final int? foo}) {
  v(foo: 0)
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      enums
        #F1 enum A (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@enum::A
          fields
            #F2 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:29) (firstTokenOffset:29) (offset:29)
              element: <testLibrary>::@enum::A::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibrary>::@enum::A
                      type: A
                    element: <testLibrary>::@enum::A::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @30
                    arguments
                      NamedArgument
                        name: foo @31
                        colon: : @34
                        argumentExpression: IntegerLiteral
                          literal: 0 @36
                          staticType: int
                    rightParenthesis: ) @37
                  staticType: A
              inducedGetter: #F3
            #F4 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::A::@getter::v
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
              inducedGetter: #F5
            #F6 isFinal isOriginDeclaringFormalParameter foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@field::foo
              inducedGetter: #F7
          constructors
            #F8 isComplete isConst isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:5) (offset:5)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
              typeNameOffset: 5
              formalParameters
                #F9 optionalNamed isDeclaring isFinal isOriginDeclaration this.foo (nameOffset:19) (firstTokenOffset:8) (offset:19)
                  element: <testLibrary>::@enum::A::@constructor::new::@formalParameter::foo
          getters
            #F3 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:29)
              element: <testLibrary>::@enum::A::@getter::v
              inducingVariable: #F2
            #F5 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
              inducingVariable: #F4
            #F7 isComplete isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::foo
              inducingVariable: #F6
  enums
    isSimplyBounded enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F2
          type: A
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F4
          type: List<A>
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
        isFinal isOriginDeclaringFormalParameter foo
          reference: <testLibrary>::@enum::A::@field::foo
          firstFragment: #F6
          type: int?
          getter: <testLibrary>::@enum::A::@getter::foo
          declaringFormalParameter: <testLibrary>::@enum::A::@constructor::new::@formalParameter::foo
      constructors
        isConst isOriginDeclaration isPrimary new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F8
          formalParameters
            #E0 optionalNamed isDeclaring isFinal this.foo
              firstFragment: #F9
              type: int?
              field: <testLibrary>::@enum::A::@field::foo
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F3
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F5
          returnType: List<A>
          variable: <testLibrary>::@enum::A::@field::values
        isOriginVariable foo
          reference: <testLibrary>::@enum::A::@getter::foo
          firstFragment: #F7
          returnType: int?
          variable: <testLibrary>::@enum::A::@field::foo
''');
  }

  test_constructor_primary_declaringFormalParameter_optionalPositional_simple_final() async {
    var library = await buildLibrary(r'''
enum A([final int? foo]) {
  v(0)
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      enums
        #F1 enum A (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@enum::A
          fields
            #F2 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:29) (firstTokenOffset:29) (offset:29)
              element: <testLibrary>::@enum::A::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibrary>::@enum::A
                      type: A
                    element: <testLibrary>::@enum::A::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @30
                    arguments
                      IntegerLiteral
                        literal: 0 @31
                        staticType: int
                    rightParenthesis: ) @32
                  staticType: A
              inducedGetter: #F3
            #F4 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::A::@getter::v
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
              inducedGetter: #F5
            #F6 isFinal isOriginDeclaringFormalParameter foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@field::foo
              inducedGetter: #F7
          constructors
            #F8 isComplete isConst isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:5) (offset:5)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
              typeNameOffset: 5
              formalParameters
                #F9 optionalPositional isDeclaring isFinal isOriginDeclaration this.foo (nameOffset:19) (firstTokenOffset:8) (offset:19)
                  element: <testLibrary>::@enum::A::@constructor::new::@formalParameter::foo
          getters
            #F3 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:29)
              element: <testLibrary>::@enum::A::@getter::v
              inducingVariable: #F2
            #F5 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
              inducingVariable: #F4
            #F7 isComplete isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::foo
              inducingVariable: #F6
  enums
    isSimplyBounded enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F2
          type: A
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F4
          type: List<A>
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
        isFinal isOriginDeclaringFormalParameter foo
          reference: <testLibrary>::@enum::A::@field::foo
          firstFragment: #F6
          type: int?
          getter: <testLibrary>::@enum::A::@getter::foo
          declaringFormalParameter: <testLibrary>::@enum::A::@constructor::new::@formalParameter::foo
      constructors
        isConst isOriginDeclaration isPrimary new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F8
          formalParameters
            #E0 optionalPositional isDeclaring isFinal this.foo
              firstFragment: #F9
              type: int?
              field: <testLibrary>::@enum::A::@field::foo
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F3
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F5
          returnType: List<A>
          variable: <testLibrary>::@enum::A::@field::values
        isOriginVariable foo
          reference: <testLibrary>::@enum::A::@getter::foo
          firstFragment: #F7
          returnType: int?
          variable: <testLibrary>::@enum::A::@field::foo
''');
  }

  test_constructor_primary_declaringFormalParameter_requiredNamed_simple_final() async {
    var library = await buildLibrary(r'''
enum A({required final int foo}) {
  v(foo: 0)
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      enums
        #F1 enum A (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@enum::A
          fields
            #F2 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:37) (firstTokenOffset:37) (offset:37)
              element: <testLibrary>::@enum::A::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibrary>::@enum::A
                      type: A
                    element: <testLibrary>::@enum::A::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @38
                    arguments
                      NamedArgument
                        name: foo @39
                        colon: : @42
                        argumentExpression: IntegerLiteral
                          literal: 0 @44
                          staticType: int
                    rightParenthesis: ) @45
                  staticType: A
              inducedGetter: #F3
            #F4 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::A::@getter::v
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
              inducedGetter: #F5
            #F6 isFinal isOriginDeclaringFormalParameter foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@field::foo
              inducedGetter: #F7
          constructors
            #F8 isComplete isConst isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:5) (offset:5)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
              typeNameOffset: 5
              formalParameters
                #F9 requiredNamed isDeclaring isFinal isOriginDeclaration this.foo (nameOffset:27) (firstTokenOffset:8) (offset:27)
                  element: <testLibrary>::@enum::A::@constructor::new::@formalParameter::foo
          getters
            #F3 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:37)
              element: <testLibrary>::@enum::A::@getter::v
              inducingVariable: #F2
            #F5 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
              inducingVariable: #F4
            #F7 isComplete isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::foo
              inducingVariable: #F6
  enums
    isSimplyBounded enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F2
          type: A
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F4
          type: List<A>
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
        isFinal isOriginDeclaringFormalParameter foo
          reference: <testLibrary>::@enum::A::@field::foo
          firstFragment: #F6
          type: int
          getter: <testLibrary>::@enum::A::@getter::foo
          declaringFormalParameter: <testLibrary>::@enum::A::@constructor::new::@formalParameter::foo
      constructors
        isConst isOriginDeclaration isPrimary new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F8
          formalParameters
            #E0 requiredNamed isDeclaring isFinal this.foo
              firstFragment: #F9
              type: int
              field: <testLibrary>::@enum::A::@field::foo
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F3
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F5
          returnType: List<A>
          variable: <testLibrary>::@enum::A::@field::values
        isOriginVariable foo
          reference: <testLibrary>::@enum::A::@getter::foo
          firstFragment: #F7
          returnType: int
          variable: <testLibrary>::@enum::A::@field::foo
''');
  }

  test_constructor_primary_declaringFormalParameter_requiredPositional_functionTypedSuffix_final() async {
    var library = await buildLibrary(r'''
enum A(
  /// first
  /// second
  @deprecated final void foo(),
) {
  v();
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      enums
        #F1 enum A (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@enum::A
          fields
            #F2 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:71) (firstTokenOffset:71) (offset:71)
              element: <testLibrary>::@enum::A::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibrary>::@enum::A
                      type: A
                    element: <testLibrary>::@enum::A::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @72
                    rightParenthesis: ) @73
                  staticType: A
              inducedGetter: #F3
            #F4 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::A::@getter::v
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
              inducedGetter: #F5
            #F6 isFinal isOriginDeclaringFormalParameter foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@field::foo
              inducedGetter: #F7
          constructors
            #F8 isComplete isConst isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:5) (offset:5)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
              typeNameOffset: 5
              formalParameters
                #F9 requiredPositional isDeclaring isFinal isOriginDeclaration this.foo (nameOffset:58) (firstTokenOffset:10) (offset:58)
                  element: <testLibrary>::@enum::A::@constructor::new::@formalParameter::foo
                  documentationComment: /// first\n/// second
                  metadata
                    Annotation
                      atSign: @ @35
                      name: SimpleIdentifier
                        token: deprecated @36
                        element: dart:core::@getter::deprecated
                        staticType: null
                      element: dart:core::@getter::deprecated
          getters
            #F3 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:71)
              element: <testLibrary>::@enum::A::@getter::v
              inducingVariable: #F2
            #F5 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
              inducingVariable: #F4
            #F7 isComplete isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::foo
              inducingVariable: #F6
  enums
    isSimplyBounded enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F2
          type: A
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F4
          type: List<A>
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
        isFinal isOriginDeclaringFormalParameter foo
          reference: <testLibrary>::@enum::A::@field::foo
          firstFragment: #F6
          documentationComment: /// first\n/// second
          metadata
            Annotation
              atSign: @ @35
              name: SimpleIdentifier
                token: deprecated @36
                element: dart:core::@getter::deprecated
                staticType: null
              element: dart:core::@getter::deprecated
          type: void Function()
          getter: <testLibrary>::@enum::A::@getter::foo
          declaringFormalParameter: <testLibrary>::@enum::A::@constructor::new::@formalParameter::foo
      constructors
        isConst isOriginDeclaration isPrimary new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F8
          formalParameters
            #E0 requiredPositional isDeclaring isFinal this.foo
              firstFragment: #F9
              type: void Function()
              documentationComment: /// first\n/// second
              metadata
                Annotation
                  atSign: @ @35
                  name: SimpleIdentifier
                    token: deprecated @36
                    element: dart:core::@getter::deprecated
                    staticType: null
                  element: dart:core::@getter::deprecated
              field: <testLibrary>::@enum::A::@field::foo
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F3
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F5
          returnType: List<A>
          variable: <testLibrary>::@enum::A::@field::values
        isOriginVariable foo
          reference: <testLibrary>::@enum::A::@getter::foo
          firstFragment: #F7
          returnType: void Function()
          variable: <testLibrary>::@enum::A::@field::foo
''');
  }

  test_constructor_primary_declaringFormalParameter_requiredPositional_simple_final() async {
    var library = await buildLibrary(r'''
enum A(
  /// first
  /// second
  @deprecated final int foo,
) {
  v(0)
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      enums
        #F1 enum A (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@enum::A
          fields
            #F2 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:68) (firstTokenOffset:68) (offset:68)
              element: <testLibrary>::@enum::A::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibrary>::@enum::A
                      type: A
                    element: <testLibrary>::@enum::A::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @69
                    arguments
                      IntegerLiteral
                        literal: 0 @70
                        staticType: int
                    rightParenthesis: ) @71
                  staticType: A
              inducedGetter: #F3
            #F4 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::A::@getter::v
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
              inducedGetter: #F5
            #F6 isFinal isOriginDeclaringFormalParameter foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@field::foo
              inducedGetter: #F7
          constructors
            #F8 isComplete isConst isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:5) (offset:5)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
              typeNameOffset: 5
              formalParameters
                #F9 requiredPositional isDeclaring isFinal isOriginDeclaration this.foo (nameOffset:57) (firstTokenOffset:10) (offset:57)
                  element: <testLibrary>::@enum::A::@constructor::new::@formalParameter::foo
                  documentationComment: /// first\n/// second
                  metadata
                    Annotation
                      atSign: @ @35
                      name: SimpleIdentifier
                        token: deprecated @36
                        element: dart:core::@getter::deprecated
                        staticType: null
                      element: dart:core::@getter::deprecated
          getters
            #F3 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:68)
              element: <testLibrary>::@enum::A::@getter::v
              inducingVariable: #F2
            #F5 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
              inducingVariable: #F4
            #F7 isComplete isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::foo
              inducingVariable: #F6
  enums
    isSimplyBounded enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F2
          type: A
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F4
          type: List<A>
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
        isFinal isOriginDeclaringFormalParameter foo
          reference: <testLibrary>::@enum::A::@field::foo
          firstFragment: #F6
          documentationComment: /// first\n/// second
          metadata
            Annotation
              atSign: @ @35
              name: SimpleIdentifier
                token: deprecated @36
                element: dart:core::@getter::deprecated
                staticType: null
              element: dart:core::@getter::deprecated
          type: int
          getter: <testLibrary>::@enum::A::@getter::foo
          declaringFormalParameter: <testLibrary>::@enum::A::@constructor::new::@formalParameter::foo
      constructors
        isConst isOriginDeclaration isPrimary new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F8
          formalParameters
            #E0 requiredPositional isDeclaring isFinal this.foo
              firstFragment: #F9
              type: int
              documentationComment: /// first\n/// second
              metadata
                Annotation
                  atSign: @ @35
                  name: SimpleIdentifier
                    token: deprecated @36
                    element: dart:core::@getter::deprecated
                    staticType: null
                  element: dart:core::@getter::deprecated
              field: <testLibrary>::@enum::A::@field::foo
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F3
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F5
          returnType: List<A>
          variable: <testLibrary>::@enum::A::@field::values
        isOriginVariable foo
          reference: <testLibrary>::@enum::A::@getter::foo
          firstFragment: #F7
          returnType: int
          variable: <testLibrary>::@enum::A::@field::foo
''');
  }

  test_constructor_primary_declaringFormalParameter_requiredPositional_simple_var() async {
    var library = await buildLibrary(r'''
enum A(var int foo) {
  v(0)
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      enums
        #F1 enum A (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@enum::A
          fields
            #F2 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:24) (firstTokenOffset:24) (offset:24)
              element: <testLibrary>::@enum::A::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibrary>::@enum::A
                      type: A
                    element: <testLibrary>::@enum::A::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @25
                    arguments
                      IntegerLiteral
                        literal: 0 @26
                        staticType: int
                    rightParenthesis: ) @27
                  staticType: A
              inducedGetter: #F3
            #F4 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::A::@getter::v
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
              inducedGetter: #F5
            #F6 isOriginDeclaringFormalParameter foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@field::foo
              inducedGetter: #F7
              inducedSetter: #F8
          constructors
            #F9 isComplete isConst isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:5) (offset:5)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
              typeNameOffset: 5
              formalParameters
                #F10 requiredPositional isDeclaring isFinal isOriginDeclaration this.foo (nameOffset:15) (firstTokenOffset:7) (offset:15)
                  element: <testLibrary>::@enum::A::@constructor::new::@formalParameter::foo
          getters
            #F3 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:24)
              element: <testLibrary>::@enum::A::@getter::v
              inducingVariable: #F2
            #F5 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
              inducingVariable: #F4
            #F7 isComplete isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::foo
              inducingVariable: #F6
          setters
            #F8 isComplete isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@setter::foo
              inducingVariable: #F6
              formalParameters
                #F11 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
                  element: <testLibrary>::@enum::A::@setter::foo::@formalParameter::value
  enums
    hasNonFinalField isSimplyBounded enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F2
          type: A
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F4
          type: List<A>
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
        isOriginDeclaringFormalParameter foo
          reference: <testLibrary>::@enum::A::@field::foo
          firstFragment: #F6
          type: int
          getter: <testLibrary>::@enum::A::@getter::foo
          setter: <testLibrary>::@enum::A::@setter::foo
          declaringFormalParameter: <testLibrary>::@enum::A::@constructor::new::@formalParameter::foo
      constructors
        isConst isOriginDeclaration isPrimary new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F9
          formalParameters
            #E0 requiredPositional isDeclaring isFinal this.foo
              firstFragment: #F10
              type: int
              field: <testLibrary>::@enum::A::@field::foo
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F3
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F5
          returnType: List<A>
          variable: <testLibrary>::@enum::A::@field::values
        isOriginVariable foo
          reference: <testLibrary>::@enum::A::@getter::foo
          firstFragment: #F7
          returnType: int
          variable: <testLibrary>::@enum::A::@field::foo
      setters
        isOriginVariable foo
          reference: <testLibrary>::@enum::A::@setter::foo
          firstFragment: #F8
          formalParameters
            #E1 requiredPositional value
              firstFragment: #F11
              type: int
          returnType: void
          variable: <testLibrary>::@enum::A::@field::foo
''');
  }

  test_constructor_primary_declaringFormalParameter_requiredPositional_type_fromField_inferred() async {
    var library = await buildLibrary(r'''
class A {
  int get foo => 0;
}

enum B(final foo) implements A {
  v(0)
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
            #F2 isOriginGetterSetter foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@field::foo
          constructors
            #F3 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F4 isComplete isOriginDeclaration foo (nameOffset:20) (firstTokenOffset:12) (offset:20)
              element: <testLibrary>::@class::A::@getter::foo
      enums
        #F5 enum B (nameOffset:38) (firstTokenOffset:33) (offset:38)
          element: <testLibrary>::@enum::B
          fields
            #F6 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:68) (firstTokenOffset:68) (offset:68)
              element: <testLibrary>::@enum::B::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: B @-1
                      element: <testLibrary>::@enum::B
                      type: B
                    element: <testLibrary>::@enum::B::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @69
                    arguments
                      IntegerLiteral
                        literal: 0 @70
                        staticType: int
                    rightParenthesis: ) @71
                  staticType: B
              inducedGetter: #F7
            #F8 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:38)
              element: <testLibrary>::@enum::B::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::B::@getter::v
                      staticType: B
                  rightBracket: ] @0
                  staticType: List<B>
              inducedGetter: #F9
            #F10 hasImplicitType isFinal isOriginDeclaringFormalParameter foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:38)
              element: <testLibrary>::@enum::B::@field::foo
              inducedGetter: #F11
          constructors
            #F12 isComplete isConst isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:38) (offset:38)
              element: <testLibrary>::@enum::B::@constructor::new
              typeName: B
              typeNameOffset: 38
              formalParameters
                #F13 requiredPositional hasImplicitType isDeclaring isFinal isOriginDeclaration this.foo (nameOffset:46) (firstTokenOffset:40) (offset:46)
                  element: <testLibrary>::@enum::B::@constructor::new::@formalParameter::foo
          getters
            #F7 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:68)
              element: <testLibrary>::@enum::B::@getter::v
              inducingVariable: #F6
            #F9 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:38)
              element: <testLibrary>::@enum::B::@getter::values
              inducingVariable: #F8
            #F11 isComplete isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:38)
              element: <testLibrary>::@enum::B::@getter::foo
              inducingVariable: #F10
  classes
    isSimplyBounded class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        isOriginGetterSetter foo
          reference: <testLibrary>::@class::A::@field::foo
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@class::A::@getter::foo
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
      getters
        isOriginDeclaration foo
          reference: <testLibrary>::@class::A::@getter::foo
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@class::A::@field::foo
  enums
    isSimplyBounded enum B
      reference: <testLibrary>::@enum::B
      firstFragment: #F5
      supertype: Enum
      interfaces
        A
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::B::@field::v
          firstFragment: #F6
          type: B
          constantInitializer
            fragment: #F6
            expression: expression_0
          getter: <testLibrary>::@enum::B::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::B::@field::values
          firstFragment: #F8
          type: List<B>
          constantInitializer
            fragment: #F8
            expression: expression_1
          getter: <testLibrary>::@enum::B::@getter::values
        hasImplicitType isFinal isOriginDeclaringFormalParameter foo
          reference: <testLibrary>::@enum::B::@field::foo
          firstFragment: #F10
          type: int
          getter: <testLibrary>::@enum::B::@getter::foo
          declaringFormalParameter: <testLibrary>::@enum::B::@constructor::new::@formalParameter::foo
      constructors
        isConst isOriginDeclaration isPrimary new
          reference: <testLibrary>::@enum::B::@constructor::new
          firstFragment: #F12
          formalParameters
            #E0 requiredPositional hasImplicitType isDeclaring isFinal this.foo
              firstFragment: #F13
              type: int
              field: <testLibrary>::@enum::B::@field::foo
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::B::@getter::v
          firstFragment: #F7
          returnType: B
          variable: <testLibrary>::@enum::B::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::B::@getter::values
          firstFragment: #F9
          returnType: List<B>
          variable: <testLibrary>::@enum::B::@field::values
        isOriginVariable foo
          reference: <testLibrary>::@enum::B::@getter::foo
          firstFragment: #F11
          returnType: int
          variable: <testLibrary>::@enum::B::@field::foo
''');
  }

  test_constructor_primary_declaringFormalParameter_requiredPositional_type_typeParameter() async {
    var library = await buildLibrary(r'''
enum A<T>(final T foo) {
  v(0)
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      enums
        #F1 enum A (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@enum::A
          typeParameters
            #F2 T (nameOffset:7) (firstTokenOffset:7) (offset:7)
              element: #E0 T
          fields
            #F3 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:27) (firstTokenOffset:27) (offset:27)
              element: <testLibrary>::@enum::A::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibrary>::@enum::A
                      type: A<int>
                    element: SubstitutedConstructorElementImpl
                      baseElement: <testLibrary>::@enum::A::@constructor::new
                      substitution: {T: int}
                  argumentList: ArgumentList
                    leftParenthesis: ( @28
                    arguments
                      IntegerLiteral
                        literal: 0 @29
                        staticType: int
                    rightParenthesis: ) @30
                  staticType: A<int>
              inducedGetter: #F4
            #F5 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::A::@getter::v
                      staticType: A<int>
                  rightBracket: ] @0
                  staticType: List<A<dynamic>>
              inducedGetter: #F6
            #F7 isFinal isOriginDeclaringFormalParameter foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@field::foo
              inducedGetter: #F8
          constructors
            #F9 isComplete isConst isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:5) (offset:5)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
              typeNameOffset: 5
              formalParameters
                #F10 requiredPositional isDeclaring isFinal isOriginDeclaration this.foo (nameOffset:18) (firstTokenOffset:10) (offset:18)
                  element: <testLibrary>::@enum::A::@constructor::new::@formalParameter::foo
          getters
            #F4 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:27)
              element: <testLibrary>::@enum::A::@getter::v
              inducingVariable: #F3
            #F6 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
              inducingVariable: #F5
            #F8 isComplete isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::foo
              inducingVariable: #F7
  enums
    isSimplyBounded enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F3
          type: A<int>
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F5
          type: List<A<dynamic>>
          constantInitializer
            fragment: #F5
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
        hasEnclosingTypeParameterReference isFinal isOriginDeclaringFormalParameter foo
          reference: <testLibrary>::@enum::A::@field::foo
          firstFragment: #F7
          type: T
          getter: <testLibrary>::@enum::A::@getter::foo
          declaringFormalParameter: <testLibrary>::@enum::A::@constructor::new::@formalParameter::foo
      constructors
        hasEnclosingTypeParameterReference isConst isOriginDeclaration isPrimary new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F9
          formalParameters
            #E1 requiredPositional isDeclaring isFinal this.foo
              firstFragment: #F10
              type: T
              field: <testLibrary>::@enum::A::@field::foo
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F4
          returnType: A<int>
          variable: <testLibrary>::@enum::A::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F6
          returnType: List<A<dynamic>>
          variable: <testLibrary>::@enum::A::@field::values
        hasEnclosingTypeParameterReference isOriginVariable foo
          reference: <testLibrary>::@enum::A::@getter::foo
          firstFragment: #F8
          returnType: T
          variable: <testLibrary>::@enum::A::@field::foo
''');
  }

  test_constructor_primary_formalParameter_field_requiredPositional() async {
    var library = await buildLibrary(r'''
enum A(this.foo) {
  v(0);

  final int foo;
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      enums
        #F1 enum A (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@enum::A
          fields
            #F2 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:21) (firstTokenOffset:21) (offset:21)
              element: <testLibrary>::@enum::A::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibrary>::@enum::A
                      type: A
                    element: <testLibrary>::@enum::A::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @22
                    arguments
                      IntegerLiteral
                        literal: 0 @23
                        staticType: int
                    rightParenthesis: ) @24
                  staticType: A
              inducedGetter: #F3
            #F4 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::A::@getter::v
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
              inducedGetter: #F5
            #F6 isFinal isOriginDeclaration foo (nameOffset:40) (firstTokenOffset:40) (offset:40)
              element: <testLibrary>::@enum::A::@field::foo
              inducedGetter: #F7
          constructors
            #F8 isComplete isConst isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:5) (offset:5)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
              typeNameOffset: 5
              formalParameters
                #F9 requiredPositional hasImplicitType isFinal isOriginDeclaration this.foo (nameOffset:12) (firstTokenOffset:7) (offset:12)
                  element: <testLibrary>::@enum::A::@constructor::new::@formalParameter::foo
          getters
            #F3 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@enum::A::@getter::v
              inducingVariable: #F2
            #F5 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
              inducingVariable: #F4
            #F7 isComplete isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
              element: <testLibrary>::@enum::A::@getter::foo
              inducingVariable: #F6
  enums
    isSimplyBounded enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F2
          type: A
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F4
          type: List<A>
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
        isFinal isOriginDeclaration foo
          reference: <testLibrary>::@enum::A::@field::foo
          firstFragment: #F6
          type: int
          getter: <testLibrary>::@enum::A::@getter::foo
      constructors
        isConst isOriginDeclaration isPrimary new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F8
          formalParameters
            #E0 requiredPositional hasImplicitType isFinal this.foo
              firstFragment: #F9
              type: int
              field: <testLibrary>::@enum::A::@field::foo
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F3
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F5
          returnType: List<A>
          variable: <testLibrary>::@enum::A::@field::values
        isOriginVariable foo
          reference: <testLibrary>::@enum::A::@getter::foo
          firstFragment: #F7
          returnType: int
          variable: <testLibrary>::@enum::A::@field::foo
''');
  }

  test_constructor_primary_formalParameter_regular_requiredPositional_functionTypedSuffix() async {
    var library = await buildLibrary(r'''
enum A(int foo()) {
  v(0)
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      enums
        #F1 enum A (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@enum::A
          fields
            #F2 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:22) (firstTokenOffset:22) (offset:22)
              element: <testLibrary>::@enum::A::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibrary>::@enum::A
                      type: A
                    element: <testLibrary>::@enum::A::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @23
                    arguments
                      IntegerLiteral
                        literal: 0 @24
                        staticType: int
                    rightParenthesis: ) @25
                  staticType: A
              inducedGetter: #F3
            #F4 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::A::@getter::v
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
              inducedGetter: #F5
          constructors
            #F6 isComplete isConst isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:5) (offset:5)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
              typeNameOffset: 5
              formalParameters
                #F7 requiredPositional isOriginDeclaration foo (nameOffset:11) (firstTokenOffset:7) (offset:11)
                  element: <testLibrary>::@enum::A::@constructor::new::@formalParameter::foo
          getters
            #F3 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
              element: <testLibrary>::@enum::A::@getter::v
              inducingVariable: #F2
            #F5 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
              inducingVariable: #F4
  enums
    isSimplyBounded enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F2
          type: A
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F4
          type: List<A>
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
      constructors
        isConst isOriginDeclaration isPrimary new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F6
          formalParameters
            #E0 requiredPositional foo
              firstFragment: #F7
              type: int Function()
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F3
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F5
          returnType: List<A>
          variable: <testLibrary>::@enum::A::@field::values
''');
  }

  test_constructor_primary_formalParameter_regular_requiredPositional_simple() async {
    var library = await buildLibrary(r'''
enum A(int foo) {
  v(0)
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      enums
        #F1 enum A (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@enum::A
          fields
            #F2 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:20) (firstTokenOffset:20) (offset:20)
              element: <testLibrary>::@enum::A::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibrary>::@enum::A
                      type: A
                    element: <testLibrary>::@enum::A::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @21
                    arguments
                      IntegerLiteral
                        literal: 0 @22
                        staticType: int
                    rightParenthesis: ) @23
                  staticType: A
              inducedGetter: #F3
            #F4 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::A::@getter::v
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
              inducedGetter: #F5
          constructors
            #F6 isComplete isConst isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:5) (offset:5)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
              typeNameOffset: 5
              formalParameters
                #F7 requiredPositional isOriginDeclaration foo (nameOffset:11) (firstTokenOffset:7) (offset:11)
                  element: <testLibrary>::@enum::A::@constructor::new::@formalParameter::foo
          getters
            #F3 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:20)
              element: <testLibrary>::@enum::A::@getter::v
              inducingVariable: #F2
            #F5 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
              inducingVariable: #F4
  enums
    isSimplyBounded enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F2
          type: A
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F4
          type: List<A>
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
      constructors
        isConst isOriginDeclaration isPrimary new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F6
          formalParameters
            #E0 requiredPositional foo
              firstFragment: #F7
              type: int
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F3
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F5
          returnType: List<A>
          variable: <testLibrary>::@enum::A::@field::values
''');
  }

  test_constructor_primary_named_const() async {
    var library = await buildLibrary(r'''
enum const A.named() {
  v.named()
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      enums
        #F1 enum A (nameOffset:11) (firstTokenOffset:0) (offset:11)
          element: <testLibrary>::@enum::A
          fields
            #F2 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:25) (firstTokenOffset:25) (offset:25)
              element: <testLibrary>::@enum::A::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibrary>::@enum::A
                      type: A
                    period: . @0
                    name: SimpleIdentifier
                      token: named @-1
                      element: <testLibrary>::@enum::A::@constructor::named
                      staticType: null
                    element: <testLibrary>::@enum::A::@constructor::named
                  argumentList: ArgumentList
                    leftParenthesis: ( @32
                    rightParenthesis: ) @33
                  staticType: A
              inducedGetter: #F3
            #F4 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::A::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::A::@getter::v
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
              inducedGetter: #F5
          constructors
            #F6 isComplete isConst isOriginDeclaration isPrimary named (nameOffset:13) (firstTokenOffset:5) (offset:13)
              element: <testLibrary>::@enum::A::@constructor::named
              typeName: A
              typeNameOffset: 11
              periodOffset: 12
          getters
            #F3 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
              element: <testLibrary>::@enum::A::@getter::v
              inducingVariable: #F2
            #F5 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::A::@getter::values
              inducingVariable: #F4
  enums
    isSimplyBounded enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F2
          type: A
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F4
          type: List<A>
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
      constructors
        isConst isOriginDeclaration isPrimary named
          reference: <testLibrary>::@enum::A::@constructor::named
          firstFragment: #F6
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F3
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F5
          returnType: List<A>
          variable: <testLibrary>::@enum::A::@field::values
''');
  }

  test_constructor_primary_named_notConst() async {
    var library = await buildLibrary(r'''
enum A.named() {
  v.named()
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      enums
        #F1 enum A (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@enum::A
          fields
            #F2 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:19) (firstTokenOffset:19) (offset:19)
              element: <testLibrary>::@enum::A::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibrary>::@enum::A
                      type: A
                    period: . @0
                    name: SimpleIdentifier
                      token: named @-1
                      element: <testLibrary>::@enum::A::@constructor::named
                      staticType: null
                    element: <testLibrary>::@enum::A::@constructor::named
                  argumentList: ArgumentList
                    leftParenthesis: ( @26
                    rightParenthesis: ) @27
                  staticType: A
              inducedGetter: #F3
            #F4 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::A::@getter::v
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
              inducedGetter: #F5
          constructors
            #F6 isComplete isConst isOriginDeclaration isPrimary named (nameOffset:7) (firstTokenOffset:5) (offset:7)
              element: <testLibrary>::@enum::A::@constructor::named
              typeName: A
              typeNameOffset: 5
              periodOffset: 6
          getters
            #F3 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:19)
              element: <testLibrary>::@enum::A::@getter::v
              inducingVariable: #F2
            #F5 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
              inducingVariable: #F4
  enums
    isSimplyBounded enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F2
          type: A
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F4
          type: List<A>
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
      constructors
        isConst isOriginDeclaration isPrimary named
          reference: <testLibrary>::@enum::A::@constructor::named
          firstFragment: #F6
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F3
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F5
          returnType: List<A>
          variable: <testLibrary>::@enum::A::@field::values
''');
  }

  test_constructor_primary_scopes() async {
    var library = await buildLibrary(r'''
const foo = 0;

enum E<@foo T>([@foo int x = foo]) {
  v;

  static const foo = 1;
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      enums
        #F1 enum E (nameOffset:21) (firstTokenOffset:16) (offset:21)
          element: <testLibrary>::@enum::E
          typeParameters
            #F2 T (nameOffset:28) (firstTokenOffset:23) (offset:28)
              element: #E0 T
              metadata
                Annotation
                  atSign: @ @23
                  name: SimpleIdentifier
                    token: foo @24
                    element: <testLibrary>::@getter::foo
                    staticType: null
                  element: <testLibrary>::@getter::foo
          fields
            #F3 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:55) (firstTokenOffset:55) (offset:55)
              element: <testLibrary>::@enum::E::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibrary>::@enum::E
                      type: E<dynamic>
                    element: SubstitutedConstructorElementImpl
                      baseElement: <testLibrary>::@enum::E::@constructor::new
                      substitution: {T: dynamic}
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E<dynamic>
              inducedGetter: #F4
            #F5 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@enum::E::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::E::@getter::v
                      staticType: E<dynamic>
                  rightBracket: ] @0
                  staticType: List<E<dynamic>>
              inducedGetter: #F6
            #F7 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic foo (nameOffset:74) (firstTokenOffset:74) (offset:74)
              element: <testLibrary>::@enum::E::@field::foo
              initializer: expression_2
                IntegerLiteral
                  literal: 1 @80
                  staticType: int
              inducedGetter: #F8
          constructors
            #F9 isComplete isConst isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:21) (offset:21)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
              typeNameOffset: 21
              formalParameters
                #F10 optionalPositional isOriginDeclaration x (nameOffset:41) (firstTokenOffset:32) (offset:41)
                  element: <testLibrary>::@enum::E::@constructor::new::@formalParameter::x
                  metadata
                    Annotation
                      atSign: @ @32
                      name: SimpleIdentifier
                        token: foo @33
                        element: <testLibrary>::@enum::E::@getter::foo
                        staticType: null
                      element: <testLibrary>::@enum::E::@getter::foo
                  initializer: expression_3
                    SimpleIdentifier
                      token: foo @45
                      element: <testLibrary>::@enum::E::@getter::foo
                      staticType: int
          getters
            #F4 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:55)
              element: <testLibrary>::@enum::E::@getter::v
              inducingVariable: #F3
            #F6 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@enum::E::@getter::values
              inducingVariable: #F5
            #F8 isComplete isOriginVariable isStatic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:74)
              element: <testLibrary>::@enum::E::@getter::foo
              inducingVariable: #F7
      topLevelVariables
        #F11 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic foo (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::foo
          initializer: expression_4
            IntegerLiteral
              literal: 0 @12
              staticType: int
          inducedGetter: #F12
      getters
        #F12 isComplete isOriginVariable isStatic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::foo
          inducingVariable: #F11
  enums
    isSimplyBounded enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
          metadata
            Annotation
              atSign: @ @23
              name: SimpleIdentifier
                token: foo @24
                element: <testLibrary>::@getter::foo
                staticType: null
              element: <testLibrary>::@getter::foo
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F3
          type: E<dynamic>
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F5
          type: List<E<dynamic>>
          constantInitializer
            fragment: #F5
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
        hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer foo
          reference: <testLibrary>::@enum::E::@field::foo
          firstFragment: #F7
          type: int
          constantInitializer
            fragment: #F7
            expression: expression_2
          getter: <testLibrary>::@enum::E::@getter::foo
      constructors
        hasEnclosingTypeParameterReference isConst isOriginDeclaration isPrimary new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F9
          formalParameters
            #E1 optionalPositional hasDefaultValue x
              firstFragment: #F10
              type: int
              metadata
                Annotation
                  atSign: @ @32
                  name: SimpleIdentifier
                    token: foo @33
                    element: <testLibrary>::@enum::E::@getter::foo
                    staticType: null
                  element: <testLibrary>::@enum::E::@getter::foo
              constantInitializer
                fragment: #F10
                expression: expression_3
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F4
          returnType: E<dynamic>
          variable: <testLibrary>::@enum::E::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F6
          returnType: List<E<dynamic>>
          variable: <testLibrary>::@enum::E::@field::values
        isOriginVariable isStatic foo
          reference: <testLibrary>::@enum::E::@getter::foo
          firstFragment: #F8
          returnType: int
          variable: <testLibrary>::@enum::E::@field::foo
  topLevelVariables
    hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: #F11
      type: int
      constantInitializer
        fragment: #F11
        expression: expression_4
      getter: <testLibrary>::@getter::foo
  getters
    isOriginVariable isStatic foo
      reference: <testLibrary>::@getter::foo
      firstFragment: #F12
      returnType: int
      variable: <testLibrary>::@topLevelVariable::foo
''');
  }

  test_constructor_primary_typeParameters() async {
    var library = await buildLibrary(r'''
enum A<T extends U, U extends num>(T t, U u) {
  v(0, 0);
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      enums
        #F1 enum A (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@enum::A
          typeParameters
            #F2 T (nameOffset:7) (firstTokenOffset:7) (offset:7)
              element: #E0 T
            #F3 U (nameOffset:20) (firstTokenOffset:20) (offset:20)
              element: #E1 U
          fields
            #F4 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:49) (firstTokenOffset:49) (offset:49)
              element: <testLibrary>::@enum::A::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibrary>::@enum::A
                      type: A<int, int>
                    element: SubstitutedConstructorElementImpl
                      baseElement: <testLibrary>::@enum::A::@constructor::new
                      substitution: {T: int, U: int}
                  argumentList: ArgumentList
                    leftParenthesis: ( @50
                    arguments
                      IntegerLiteral
                        literal: 0 @51
                        staticType: int
                      IntegerLiteral
                        literal: 0 @54
                        staticType: int
                    rightParenthesis: ) @55
                  staticType: A<int, int>
              inducedGetter: #F5
            #F6 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::A::@getter::v
                      staticType: A<int, int>
                  rightBracket: ] @0
                  staticType: List<A<num, num>>
              inducedGetter: #F7
          constructors
            #F8 isComplete isConst isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:5) (offset:5)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
              typeNameOffset: 5
              formalParameters
                #F9 requiredPositional isOriginDeclaration t (nameOffset:37) (firstTokenOffset:35) (offset:37)
                  element: <testLibrary>::@enum::A::@constructor::new::@formalParameter::t
                #F10 requiredPositional isOriginDeclaration u (nameOffset:42) (firstTokenOffset:40) (offset:42)
                  element: <testLibrary>::@enum::A::@constructor::new::@formalParameter::u
          getters
            #F5 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:49)
              element: <testLibrary>::@enum::A::@getter::v
              inducingVariable: #F4
            #F7 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
              inducingVariable: #F6
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
          bound: U
        #E1 U
          firstFragment: #F3
          bound: num
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F4
          type: A<int, int>
          constantInitializer
            fragment: #F4
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F6
          type: List<A<num, num>>
          constantInitializer
            fragment: #F6
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
      constructors
        hasEnclosingTypeParameterReference isConst isOriginDeclaration isPrimary new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F8
          formalParameters
            #E2 requiredPositional t
              firstFragment: #F9
              type: T
            #E3 requiredPositional u
              firstFragment: #F10
              type: U
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F5
          returnType: A<int, int>
          variable: <testLibrary>::@enum::A::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F7
          returnType: List<A<num, num>>
          variable: <testLibrary>::@enum::A::@field::values
''');
  }

  test_constructor_primary_unnamed_const() async {
    var library = await buildLibrary(r'''
enum const A() {
  v
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      enums
        #F1 enum A (nameOffset:11) (firstTokenOffset:0) (offset:11)
          element: <testLibrary>::@enum::A
          fields
            #F2 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:19) (firstTokenOffset:19) (offset:19)
              element: <testLibrary>::@enum::A::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibrary>::@enum::A
                      type: A
                    element: <testLibrary>::@enum::A::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              inducedGetter: #F3
            #F4 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::A::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::A::@getter::v
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
              inducedGetter: #F5
          constructors
            #F6 isComplete isConst isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:5) (offset:11)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
              typeNameOffset: 11
          getters
            #F3 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:19)
              element: <testLibrary>::@enum::A::@getter::v
              inducingVariable: #F2
            #F5 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::A::@getter::values
              inducingVariable: #F4
  enums
    isSimplyBounded enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F2
          type: A
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F4
          type: List<A>
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
      constructors
        isConst isOriginDeclaration isPrimary new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F6
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F3
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F5
          returnType: List<A>
          variable: <testLibrary>::@enum::A::@field::values
''');
  }

  test_constructor_primary_unnamed_notConst() async {
    var library = await buildLibrary(r'''
enum A() {
  v
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      enums
        #F1 enum A (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@enum::A
          fields
            #F2 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:13) (firstTokenOffset:13) (offset:13)
              element: <testLibrary>::@enum::A::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibrary>::@enum::A
                      type: A
                    element: <testLibrary>::@enum::A::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              inducedGetter: #F3
            #F4 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::A::@getter::v
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
              inducedGetter: #F5
          constructors
            #F6 isComplete isConst isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:5) (offset:5)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
              typeNameOffset: 5
          getters
            #F3 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:13)
              element: <testLibrary>::@enum::A::@getter::v
              inducingVariable: #F2
            #F5 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
              inducingVariable: #F4
  enums
    isSimplyBounded enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F2
          type: A
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F4
          type: List<A>
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
      constructors
        isConst isOriginDeclaration isPrimary new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F6
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F3
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F5
          returnType: List<A>
          variable: <testLibrary>::@enum::A::@field::values
''');
  }

  test_constructor_secondary_augmentation_add_named() async {
    var library = await buildLibrary(r'''
enum A {
  v.named();
}

augment enum A {;
  const A.named();
}
''');

    configuration.withConstantInitializers = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      enums
        #F1 enum A (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@enum::A
          nextFragment: #F2
          fields
            #F3 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:11) (firstTokenOffset:11) (offset:11)
              element: <testLibrary>::@enum::A::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibrary>::@enum::A
                      type: A
                    period: . @0
                    name: SimpleIdentifier
                      token: named @-1
                      element: <testLibrary>::@enum::A::@constructor::named
                      staticType: null
                    element: <testLibrary>::@enum::A::@constructor::named
                  argumentList: ArgumentList
                    leftParenthesis: ( @18
                    rightParenthesis: ) @19
                  staticType: A
              inducedGetter: #F4
            #F5 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::A::@getter::v
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
              inducedGetter: #F6
          getters
            #F4 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::A::@getter::v
              inducingVariable: #F3
            #F6 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
              inducingVariable: #F5
        #F2 isAugmentation enum A (nameOffset:38) (firstTokenOffset:25) (offset:38)
          element: <testLibrary>::@enum::A
          previousFragment: #F1
          constructors
            #F7 isConst isOriginDeclaration named (nameOffset:53) (firstTokenOffset:45) (offset:53)
              element: <testLibrary>::@enum::A::@constructor::named
              typeName: A
              typeNameOffset: 51
              periodOffset: 52
  enums
    isSimplyBounded enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F3
          type: A
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F5
          type: List<A>
          constantInitializer
            fragment: #F5
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
      constructors
        isConst isOriginDeclaration named
          reference: <testLibrary>::@enum::A::@constructor::named
          firstFragment: #F7
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F4
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F6
          returnType: List<A>
          variable: <testLibrary>::@enum::A::@field::values
''');
  }

  test_constructor_secondary_augmentation_add_named_generic() async {
    var library = await buildLibrary(r'''
enum A<T> {
  v<int>.named()
}

augment enum A<T> {;
  const A.named(T a);
}
''');

    configuration.withConstantInitializers = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      enums
        #F1 enum A (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@enum::A
          nextFragment: #F2
          typeParameters
            #F3 T (nameOffset:7) (firstTokenOffset:7) (offset:7)
              element: #E0 T
              nextFragment: #F4
          fields
            #F5 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:14) (firstTokenOffset:14) (offset:14)
              element: <testLibrary>::@enum::A::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      typeArguments: TypeArgumentList
                        leftBracket: < @15
                        arguments
                          NamedType
                            name: int @16
                            element: dart:core::@class::int
                            type: int
                        rightBracket: > @19
                      element: <testLibrary>::@enum::A
                      type: A<int>
                    period: . @0
                    name: SimpleIdentifier
                      token: named @-1
                      element: SubstitutedConstructorElementImpl
                        baseElement: <testLibrary>::@enum::A::@constructor::named
                        substitution: {T: int}
                      staticType: null
                    element: SubstitutedConstructorElementImpl
                      baseElement: <testLibrary>::@enum::A::@constructor::named
                      substitution: {T: int}
                  argumentList: ArgumentList
                    leftParenthesis: ( @26
                    rightParenthesis: ) @27
                  staticType: A<int>
              inducedGetter: #F6
            #F7 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::A::@getter::v
                      staticType: A<int>
                  rightBracket: ] @0
                  staticType: List<A<dynamic>>
              inducedGetter: #F8
          getters
            #F6 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:14)
              element: <testLibrary>::@enum::A::@getter::v
              inducingVariable: #F5
            #F8 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
              inducingVariable: #F7
        #F2 isAugmentation enum A (nameOffset:45) (firstTokenOffset:32) (offset:45)
          element: <testLibrary>::@enum::A
          previousFragment: #F1
          typeParameters
            #F4 T (nameOffset:47) (firstTokenOffset:47) (offset:47)
              element: #E0 T
              previousFragment: #F3
          constructors
            #F9 isConst isOriginDeclaration named (nameOffset:63) (firstTokenOffset:55) (offset:63)
              element: <testLibrary>::@enum::A::@constructor::named
              typeName: A
              typeNameOffset: 61
              periodOffset: 62
              formalParameters
                #F10 requiredPositional isOriginDeclaration a (nameOffset:71) (firstTokenOffset:69) (offset:71)
                  element: <testLibrary>::@enum::A::@constructor::named::@formalParameter::a
  enums
    isSimplyBounded enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F3
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F5
          type: A<int>
          constantInitializer
            fragment: #F5
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F7
          type: List<A<dynamic>>
          constantInitializer
            fragment: #F7
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
      constructors
        hasEnclosingTypeParameterReference isConst isOriginDeclaration named
          reference: <testLibrary>::@enum::A::@constructor::named
          firstFragment: #F9
          formalParameters
            #E1 requiredPositional a
              firstFragment: #F10
              type: T
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F6
          returnType: A<int>
          variable: <testLibrary>::@enum::A::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F8
          returnType: List<A<dynamic>>
          variable: <testLibrary>::@enum::A::@field::values
''');
  }

  test_constructor_secondary_augmentation_add_named_hasUnnamed() async {
    var library = await buildLibrary(r'''
enum A {
  v;
  const A();
}

augment enum A {;
  const A.named();
}
''');

    configuration.withConstantInitializers = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      enums
        #F1 enum A (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@enum::A
          nextFragment: #F2
          fields
            #F3 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:11) (firstTokenOffset:11) (offset:11)
              element: <testLibrary>::@enum::A::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibrary>::@enum::A
                      type: A
                    element: <testLibrary>::@enum::A::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              inducedGetter: #F4
            #F5 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::A::@getter::v
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
              inducedGetter: #F6
          constructors
            #F7 isConst isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:16) (offset:22)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
              typeNameOffset: 22
          getters
            #F4 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::A::@getter::v
              inducingVariable: #F3
            #F6 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
              inducingVariable: #F5
        #F2 isAugmentation enum A (nameOffset:43) (firstTokenOffset:30) (offset:43)
          element: <testLibrary>::@enum::A
          previousFragment: #F1
          constructors
            #F8 isConst isOriginDeclaration named (nameOffset:58) (firstTokenOffset:50) (offset:58)
              element: <testLibrary>::@enum::A::@constructor::named
              typeName: A
              typeNameOffset: 56
              periodOffset: 57
  enums
    isSimplyBounded enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F3
          type: A
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F5
          type: List<A>
          constantInitializer
            fragment: #F5
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
      constructors
        isConst isOriginDeclaration new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F7
          superConstructor: dart:core::@class::Enum::@constructor::new
        isConst isOriginDeclaration named
          reference: <testLibrary>::@enum::A::@constructor::named
          firstFragment: #F8
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F4
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F6
          returnType: List<A>
          variable: <testLibrary>::@enum::A::@field::values
''');
  }

  test_constructor_secondary_augmentation_add_unnamed() async {
    var library = await buildLibrary(r'''
enum A {
  v;
}

augment enum A {;
  const A();
}
''');

    configuration.withConstantInitializers = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      enums
        #F1 enum A (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@enum::A
          nextFragment: #F2
          fields
            #F3 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:11) (firstTokenOffset:11) (offset:11)
              element: <testLibrary>::@enum::A::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibrary>::@enum::A
                      type: A
                    element: <testLibrary>::@enum::A::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              inducedGetter: #F4
            #F5 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::A::@getter::v
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
              inducedGetter: #F6
          getters
            #F4 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::A::@getter::v
              inducingVariable: #F3
            #F6 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
              inducingVariable: #F5
        #F2 isAugmentation enum A (nameOffset:30) (firstTokenOffset:17) (offset:30)
          element: <testLibrary>::@enum::A
          previousFragment: #F1
          constructors
            #F7 isConst isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:37) (offset:43)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
              typeNameOffset: 43
  enums
    isSimplyBounded enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F3
          type: A
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F5
          type: List<A>
          constantInitializer
            fragment: #F5
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
      constructors
        isConst isOriginDeclaration new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F7
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F4
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F6
          returnType: List<A>
          variable: <testLibrary>::@enum::A::@field::values
''');
  }

  test_constructor_secondary_augmentation_add_unnamed_hasNamed() async {
    var library = await buildLibrary(r'''
enum A {
  v;
  const A.named();
}

augment enum A {;
  const A();
}
''');

    configuration.withConstantInitializers = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      enums
        #F1 enum A (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@enum::A
          nextFragment: #F2
          fields
            #F3 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:11) (firstTokenOffset:11) (offset:11)
              element: <testLibrary>::@enum::A::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibrary>::@enum::A
                      type: A
                    element: <testLibrary>::@enum::A::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              inducedGetter: #F4
            #F5 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::A::@getter::v
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
              inducedGetter: #F6
          constructors
            #F7 isConst isOriginDeclaration named (nameOffset:24) (firstTokenOffset:16) (offset:24)
              element: <testLibrary>::@enum::A::@constructor::named
              typeName: A
              typeNameOffset: 22
              periodOffset: 23
          getters
            #F4 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::A::@getter::v
              inducingVariable: #F3
            #F6 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
              inducingVariable: #F5
        #F2 isAugmentation enum A (nameOffset:49) (firstTokenOffset:36) (offset:49)
          element: <testLibrary>::@enum::A
          previousFragment: #F1
          constructors
            #F8 isConst isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:56) (offset:62)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
              typeNameOffset: 62
  enums
    isSimplyBounded enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F3
          type: A
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F5
          type: List<A>
          constantInitializer
            fragment: #F5
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
      constructors
        isConst isOriginDeclaration named
          reference: <testLibrary>::@enum::A::@constructor::named
          firstFragment: #F7
          superConstructor: dart:core::@class::Enum::@constructor::new
        isConst isOriginDeclaration new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F8
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F4
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F6
          returnType: List<A>
          variable: <testLibrary>::@enum::A::@field::values
''');
  }

  test_constructor_secondary_augmentation_add_withConstructorFieldInitializer() async {
    var library = await buildLibrary(r'''
enum A {
  v;
  final int f;
}

augment enum A {;
  const A.named() : f = 0;
}
''');

    configuration.withConstantInitializers = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      enums
        #F1 enum A (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@enum::A
          nextFragment: #F2
          fields
            #F3 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:11) (firstTokenOffset:11) (offset:11)
              element: <testLibrary>::@enum::A::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibrary>::@enum::A
                      type: A
                    element: <null>
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              inducedGetter: #F4
            #F5 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::A::@getter::v
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
              inducedGetter: #F6
            #F7 isFinal isOriginDeclaration f (nameOffset:26) (firstTokenOffset:26) (offset:26)
              element: <testLibrary>::@enum::A::@field::f
              inducedGetter: #F8
          getters
            #F4 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::A::@getter::v
              inducingVariable: #F3
            #F6 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
              inducingVariable: #F5
            #F8 isComplete isOriginVariable f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:26)
              element: <testLibrary>::@enum::A::@getter::f
              inducingVariable: #F7
        #F2 isAugmentation enum A (nameOffset:45) (firstTokenOffset:32) (offset:45)
          element: <testLibrary>::@enum::A
          previousFragment: #F1
          constructors
            #F9 isComplete isConst isOriginDeclaration named (nameOffset:60) (firstTokenOffset:52) (offset:60)
              element: <testLibrary>::@enum::A::@constructor::named
              typeName: A
              typeNameOffset: 58
              periodOffset: 59
  enums
    isSimplyBounded enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F3
          type: A
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F5
          type: List<A>
          constantInitializer
            fragment: #F5
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
        isFinal isOriginDeclaration f
          reference: <testLibrary>::@enum::A::@field::f
          firstFragment: #F7
          type: int
          getter: <testLibrary>::@enum::A::@getter::f
      constructors
        isConst isOriginDeclaration named
          reference: <testLibrary>::@enum::A::@constructor::named
          firstFragment: #F9
          constantInitializers
            ConstructorFieldInitializer
              fieldName: SimpleIdentifier
                token: f @70
                element: <testLibrary>::@enum::A::@field::f
                staticType: null
              equals: = @72
              expression: IntegerLiteral
                literal: 0 @74
                staticType: int
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F4
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F6
          returnType: List<A>
          variable: <testLibrary>::@enum::A::@field::values
        isOriginVariable f
          reference: <testLibrary>::@enum::A::@getter::f
          firstFragment: #F8
          returnType: int
          variable: <testLibrary>::@enum::A::@field::f
''');
  }

  test_constructor_secondary_augmentation_add_withFieldFormalParameter() async {
    var library = await buildLibrary(r'''
enum A {
  v(0);
  final int f;
}

augment enum A {;
  const A.named(this.f);
}
''');

    configuration.withConstantInitializers = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      enums
        #F1 enum A (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@enum::A
          nextFragment: #F2
          fields
            #F3 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:11) (firstTokenOffset:11) (offset:11)
              element: <testLibrary>::@enum::A::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibrary>::@enum::A
                      type: A
                    element: <null>
                  argumentList: ArgumentList
                    leftParenthesis: ( @12
                    arguments
                      IntegerLiteral
                        literal: 0 @13
                        staticType: int
                    rightParenthesis: ) @14
                  staticType: A
              inducedGetter: #F4
            #F5 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::A::@getter::v
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
              inducedGetter: #F6
            #F7 isFinal isOriginDeclaration f (nameOffset:29) (firstTokenOffset:29) (offset:29)
              element: <testLibrary>::@enum::A::@field::f
              inducedGetter: #F8
          getters
            #F4 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::A::@getter::v
              inducingVariable: #F3
            #F6 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
              inducingVariable: #F5
            #F8 isComplete isOriginVariable f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:29)
              element: <testLibrary>::@enum::A::@getter::f
              inducingVariable: #F7
        #F2 isAugmentation enum A (nameOffset:48) (firstTokenOffset:35) (offset:48)
          element: <testLibrary>::@enum::A
          previousFragment: #F1
          constructors
            #F9 isComplete isConst isOriginDeclaration named (nameOffset:63) (firstTokenOffset:55) (offset:63)
              element: <testLibrary>::@enum::A::@constructor::named
              typeName: A
              typeNameOffset: 61
              periodOffset: 62
              formalParameters
                #F10 requiredPositional hasImplicitType isFinal isOriginDeclaration this.f (nameOffset:74) (firstTokenOffset:69) (offset:74)
                  element: <testLibrary>::@enum::A::@constructor::named::@formalParameter::f
  enums
    isSimplyBounded enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F3
          type: A
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F5
          type: List<A>
          constantInitializer
            fragment: #F5
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
        isFinal isOriginDeclaration f
          reference: <testLibrary>::@enum::A::@field::f
          firstFragment: #F7
          type: int
          getter: <testLibrary>::@enum::A::@getter::f
      constructors
        isConst isOriginDeclaration named
          reference: <testLibrary>::@enum::A::@constructor::named
          firstFragment: #F9
          formalParameters
            #E0 requiredPositional hasImplicitType isFinal this.f
              firstFragment: #F10
              type: int
              field: <testLibrary>::@enum::A::@field::f
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F4
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F6
          returnType: List<A>
          variable: <testLibrary>::@enum::A::@field::values
        isOriginVariable f
          reference: <testLibrary>::@enum::A::@getter::f
          firstFragment: #F8
          returnType: int
          variable: <testLibrary>::@enum::A::@field::f
''');
  }

  test_constructor_secondary_augmentation_chain_isComplete_factory() async {
    var library = await buildLibrary(r'''
enum A {
  v;
  factory A();
}

augment enum A {;
  augment factory A() => v;
}

augment enum A {;
  augment factory A();
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      enums
        #F1 enum A (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@enum::A
          nextFragment: #F2
          fields
            #F3 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:11) (firstTokenOffset:11) (offset:11)
              element: <testLibrary>::@enum::A::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibrary>::@enum::A
                      type: A
                    element: <testLibrary>::@enum::A::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              inducedGetter: #F4
            #F5 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::A::@getter::v
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
              inducedGetter: #F6
          constructors
            #F7 isFactory isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:16) (offset:24)
              element: <testLibrary>::@enum::A::@constructor::new
              factoryKeywordOffset: 16
              typeName: A
              typeNameOffset: 24
              nextFragment: #F8
          getters
            #F4 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::A::@getter::v
              inducingVariable: #F3
            #F6 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
              inducingVariable: #F5
        #F2 isAugmentation enum A (nameOffset:45) (firstTokenOffset:32) (offset:45)
          element: <testLibrary>::@enum::A
          previousFragment: #F1
          nextFragment: #F9
          constructors
            #F8 isAugmentation isComplete isFactory isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:52) (offset:68)
              element: <testLibrary>::@enum::A::@constructor::new
              factoryKeywordOffset: 60
              typeName: A
              typeNameOffset: 68
              nextFragment: #F10
              previousFragment: #F7
        #F9 isAugmentation enum A (nameOffset:94) (firstTokenOffset:81) (offset:94)
          element: <testLibrary>::@enum::A
          previousFragment: #F2
          constructors
            #F10 isAugmentation isFactory isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:101) (offset:117)
              element: <testLibrary>::@enum::A::@constructor::new
              factoryKeywordOffset: 109
              typeName: A
              typeNameOffset: 117
              previousFragment: #F8
  enums
    isSimplyBounded enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F3
          type: A
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F5
          type: List<A>
          constantInitializer
            fragment: #F5
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
      constructors
        isFactory isOriginDeclaration new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F7
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F4
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F6
          returnType: List<A>
          variable: <testLibrary>::@enum::A::@field::values
''');
  }

  test_constructor_secondary_factory() async {
    var library = await buildLibrary(r'''
enum E {
  v;

  factory E() => v;
}
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
            #F2 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:11) (firstTokenOffset:11) (offset:11)
              element: <testLibrary>::@enum::E::@field::v
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
              inducedGetter: #F3
            #F4 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::E::@getter::v
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
              inducedGetter: #F5
          constructors
            #F6 isComplete isFactory isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:17) (offset:25)
              element: <testLibrary>::@enum::E::@constructor::new
              factoryKeywordOffset: 17
              typeName: E
              typeNameOffset: 25
          getters
            #F3 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::E::@getter::v
              inducingVariable: #F2
            #F5 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
              inducingVariable: #F4
  enums
    isSimplyBounded enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F4
          type: List<E>
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        isFactory isOriginDeclaration new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F6
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F3
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F5
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
''');
  }

  test_constructor_secondary_factory_named() async {
    var library = await buildLibrary(r'''
enum E {
  v;

  factory E.named() => v;
}
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
            #F2 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:11) (firstTokenOffset:11) (offset:11)
              element: <testLibrary>::@enum::E::@field::v
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
              inducedGetter: #F3
            #F4 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::E::@getter::v
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
              inducedGetter: #F5
          constructors
            #F6 isComplete isFactory isOriginDeclaration named (nameOffset:27) (firstTokenOffset:17) (offset:27)
              element: <testLibrary>::@enum::E::@constructor::named
              factoryKeywordOffset: 17
              typeName: E
              typeNameOffset: 25
              periodOffset: 26
            #F7 isConst isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F3 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::E::@getter::v
              inducingVariable: #F2
            #F5 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
              inducingVariable: #F4
  enums
    isSimplyBounded enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F4
          type: List<E>
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        isFactory isOriginDeclaration named
          reference: <testLibrary>::@enum::E::@constructor::named
          firstFragment: #F6
        isConst isOriginImplicitDefault new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F7
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F3
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F5
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
''');
  }

  test_constructor_secondary_factoryHead_named() async {
    var library = await buildLibrary(r'''
enum E {
  v;

  factory named() => v;
}
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
            #F2 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:11) (firstTokenOffset:11) (offset:11)
              element: <testLibrary>::@enum::E::@field::v
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
              inducedGetter: #F3
            #F4 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::E::@getter::v
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
              inducedGetter: #F5
          constructors
            #F6 isComplete isFactory isOriginDeclaration named (nameOffset:25) (firstTokenOffset:17) (offset:25)
              element: <testLibrary>::@enum::E::@constructor::named
              factoryKeywordOffset: 17
              typeName: null
            #F7 isConst isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F3 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::E::@getter::v
              inducingVariable: #F2
            #F5 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
              inducingVariable: #F4
  enums
    isSimplyBounded enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F4
          type: List<E>
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        isFactory isOriginDeclaration named
          reference: <testLibrary>::@enum::E::@constructor::named
          firstFragment: #F6
        isConst isOriginImplicitDefault new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F7
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F3
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F5
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
''');
  }

  test_constructor_secondary_factoryHead_unnamed() async {
    var library = await buildLibrary(r'''
enum E {
  v.named();

  const E.named();
  factory() => v;
}
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
            #F2 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:11) (firstTokenOffset:11) (offset:11)
              element: <testLibrary>::@enum::E::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibrary>::@enum::E
                      type: E
                    period: . @0
                    name: SimpleIdentifier
                      token: named @-1
                      element: <testLibrary>::@enum::E::@constructor::named
                      staticType: null
                    element: <testLibrary>::@enum::E::@constructor::named
                  argumentList: ArgumentList
                    leftParenthesis: ( @18
                    rightParenthesis: ) @19
                  staticType: E
              inducedGetter: #F3
            #F4 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::E::@getter::v
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
              inducedGetter: #F5
          constructors
            #F6 isConst isOriginDeclaration named (nameOffset:33) (firstTokenOffset:25) (offset:33)
              element: <testLibrary>::@enum::E::@constructor::named
              typeName: E
              typeNameOffset: 31
              periodOffset: 32
            #F7 isComplete isFactory isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:44) (offset:44)
              element: <testLibrary>::@enum::E::@constructor::new
              factoryKeywordOffset: 44
              typeName: null
          getters
            #F3 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::E::@getter::v
              inducingVariable: #F2
            #F5 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
              inducingVariable: #F4
  enums
    isSimplyBounded enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F4
          type: List<E>
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        isConst isOriginDeclaration named
          reference: <testLibrary>::@enum::E::@constructor::named
          firstFragment: #F6
          superConstructor: dart:core::@class::Enum::@constructor::new
        isFactory isOriginDeclaration new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F7
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F3
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F5
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
''');
  }

  test_constructor_secondary_formalParameter_field_optionalNamed_withDefault() async {
    var library = await buildLibrary(r'''
enum E {
  v;

  final int x;
  const E({this.x = 1 + 2});
}
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
            #F2 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:11) (firstTokenOffset:11) (offset:11)
              element: <testLibrary>::@enum::E::@field::v
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
              inducedGetter: #F3
            #F4 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::E::@getter::v
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
              inducedGetter: #F5
            #F6 isFinal isOriginDeclaration x (nameOffset:27) (firstTokenOffset:27) (offset:27)
              element: <testLibrary>::@enum::E::@field::x
              inducedGetter: #F7
          constructors
            #F8 isComplete isConst isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:32) (offset:38)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
              typeNameOffset: 38
              formalParameters
                #F9 optionalNamed hasImplicitType isFinal isOriginDeclaration this.x (nameOffset:46) (firstTokenOffset:41) (offset:46)
                  element: <testLibrary>::@enum::E::@constructor::new::@formalParameter::x
                  initializer: expression_2
                    BinaryExpression
                      leftOperand: IntegerLiteral
                        literal: 1 @50
                        staticType: int
                      operator: + @52
                      rightOperand: IntegerLiteral
                        literal: 2 @54
                        staticType: int
                      element: dart:core::@class::num::@method::+
                      staticInvokeType: num Function(num)
                      staticType: int
          getters
            #F3 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::E::@getter::v
              inducingVariable: #F2
            #F5 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
              inducingVariable: #F4
            #F7 isComplete isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:27)
              element: <testLibrary>::@enum::E::@getter::x
              inducingVariable: #F6
  enums
    isSimplyBounded enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F4
          type: List<E>
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
        isFinal isOriginDeclaration x
          reference: <testLibrary>::@enum::E::@field::x
          firstFragment: #F6
          type: int
          getter: <testLibrary>::@enum::E::@getter::x
      constructors
        isConst isOriginDeclaration new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F8
          formalParameters
            #E0 optionalNamed hasDefaultValue hasImplicitType isFinal this.x
              firstFragment: #F9
              type: int
              constantInitializer
                fragment: #F9
                expression: expression_2
              field: <testLibrary>::@enum::E::@field::x
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F3
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F5
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
        isOriginVariable x
          reference: <testLibrary>::@enum::E::@getter::x
          firstFragment: #F7
          returnType: int
          variable: <testLibrary>::@enum::E::@field::x
''');
  }

  test_constructor_secondary_formalParameter_field_requiredPositional_fieldImplicitType_formalImplicitType() async {
    var library = await buildLibrary(r'''
enum E {
  v;

  final x;
  E(this.x);
}
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
            #F2 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:11) (firstTokenOffset:11) (offset:11)
              element: <testLibrary>::@enum::E::@field::v
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
              inducedGetter: #F3
            #F4 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::E::@getter::v
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
              inducedGetter: #F5
            #F6 hasImplicitType isFinal isOriginDeclaration x (nameOffset:23) (firstTokenOffset:23) (offset:23)
              element: <testLibrary>::@enum::E::@field::x
              inducedGetter: #F7
          constructors
            #F8 isComplete isConst isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:28) (offset:28)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
              typeNameOffset: 28
              formalParameters
                #F9 requiredPositional hasImplicitType isFinal isOriginDeclaration this.x (nameOffset:35) (firstTokenOffset:30) (offset:35)
                  element: <testLibrary>::@enum::E::@constructor::new::@formalParameter::x
          getters
            #F3 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::E::@getter::v
              inducingVariable: #F2
            #F5 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
              inducingVariable: #F4
            #F7 isComplete isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
              element: <testLibrary>::@enum::E::@getter::x
              inducingVariable: #F6
  enums
    isSimplyBounded enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F4
          type: List<E>
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
        hasImplicitType isFinal isOriginDeclaration x
          reference: <testLibrary>::@enum::E::@field::x
          firstFragment: #F6
          type: dynamic
          getter: <testLibrary>::@enum::E::@getter::x
      constructors
        isConst isOriginDeclaration new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F8
          formalParameters
            #E0 requiredPositional hasImplicitType isFinal this.x
              firstFragment: #F9
              type: dynamic
              field: <testLibrary>::@enum::E::@field::x
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F3
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F5
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
        isOriginVariable x
          reference: <testLibrary>::@enum::E::@getter::x
          firstFragment: #F7
          returnType: dynamic
          variable: <testLibrary>::@enum::E::@field::x
''');
  }

  test_constructor_secondary_formalParameter_field_requiredPositional_fieldImplicitType_formalTyped() async {
    var library = await buildLibrary(r'''
enum E {
  v;

  final x;
  E(int this.x);
}
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
            #F2 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:11) (firstTokenOffset:11) (offset:11)
              element: <testLibrary>::@enum::E::@field::v
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
              inducedGetter: #F3
            #F4 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::E::@getter::v
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
              inducedGetter: #F5
            #F6 hasImplicitType isFinal isOriginDeclaration x (nameOffset:23) (firstTokenOffset:23) (offset:23)
              element: <testLibrary>::@enum::E::@field::x
              inducedGetter: #F7
          constructors
            #F8 isComplete isConst isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:28) (offset:28)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
              typeNameOffset: 28
              formalParameters
                #F9 requiredPositional isFinal isOriginDeclaration this.x (nameOffset:39) (firstTokenOffset:30) (offset:39)
                  element: <testLibrary>::@enum::E::@constructor::new::@formalParameter::x
          getters
            #F3 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::E::@getter::v
              inducingVariable: #F2
            #F5 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
              inducingVariable: #F4
            #F7 isComplete isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
              element: <testLibrary>::@enum::E::@getter::x
              inducingVariable: #F6
  enums
    isSimplyBounded enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F4
          type: List<E>
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
        hasImplicitType isFinal isOriginDeclaration x
          reference: <testLibrary>::@enum::E::@field::x
          firstFragment: #F6
          type: dynamic
          getter: <testLibrary>::@enum::E::@getter::x
      constructors
        isConst isOriginDeclaration new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F8
          formalParameters
            #E0 requiredPositional isFinal this.x
              firstFragment: #F9
              type: int
              field: <testLibrary>::@enum::E::@field::x
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F3
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F5
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
        isOriginVariable x
          reference: <testLibrary>::@enum::E::@getter::x
          firstFragment: #F7
          returnType: dynamic
          variable: <testLibrary>::@enum::E::@field::x
''');
  }

  test_constructor_secondary_formalParameter_field_requiredPositional_fieldTyped_formalTyped() async {
    var library = await buildLibrary(r'''
enum E {
  v;

  final num x;
  const E(int this.x);
}
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
            #F2 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:11) (firstTokenOffset:11) (offset:11)
              element: <testLibrary>::@enum::E::@field::v
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
              inducedGetter: #F3
            #F4 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::E::@getter::v
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
              inducedGetter: #F5
            #F6 isFinal isOriginDeclaration x (nameOffset:27) (firstTokenOffset:27) (offset:27)
              element: <testLibrary>::@enum::E::@field::x
              inducedGetter: #F7
          constructors
            #F8 isComplete isConst isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:32) (offset:38)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
              typeNameOffset: 38
              formalParameters
                #F9 requiredPositional isFinal isOriginDeclaration this.x (nameOffset:49) (firstTokenOffset:40) (offset:49)
                  element: <testLibrary>::@enum::E::@constructor::new::@formalParameter::x
          getters
            #F3 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::E::@getter::v
              inducingVariable: #F2
            #F5 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
              inducingVariable: #F4
            #F7 isComplete isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:27)
              element: <testLibrary>::@enum::E::@getter::x
              inducingVariable: #F6
  enums
    isSimplyBounded enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F4
          type: List<E>
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
        isFinal isOriginDeclaration x
          reference: <testLibrary>::@enum::E::@field::x
          firstFragment: #F6
          type: num
          getter: <testLibrary>::@enum::E::@getter::x
      constructors
        isConst isOriginDeclaration new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F8
          formalParameters
            #E0 requiredPositional isFinal this.x
              firstFragment: #F9
              type: int
              field: <testLibrary>::@enum::E::@field::x
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F3
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F5
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
        isOriginVariable x
          reference: <testLibrary>::@enum::E::@getter::x
          firstFragment: #F7
          returnType: num
          variable: <testLibrary>::@enum::E::@field::x
''');
  }

  test_constructor_secondary_formalParameter_field_requiredPositional_functionTypedSuffix_withReturnType() async {
    var library = await buildLibrary(r'''
enum E {
  v;

  final x;
  const E(int this.x(double a));
}
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
            #F2 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:11) (firstTokenOffset:11) (offset:11)
              element: <testLibrary>::@enum::E::@field::v
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
              inducedGetter: #F3
            #F4 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::E::@getter::v
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
              inducedGetter: #F5
            #F6 hasImplicitType isFinal isOriginDeclaration x (nameOffset:23) (firstTokenOffset:23) (offset:23)
              element: <testLibrary>::@enum::E::@field::x
              inducedGetter: #F7
          constructors
            #F8 isComplete isConst isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:28) (offset:34)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
              typeNameOffset: 34
              formalParameters
                #F9 requiredPositional isFinal isOriginDeclaration this.x (nameOffset:45) (firstTokenOffset:36) (offset:45)
                  element: <testLibrary>::@enum::E::@constructor::new::@formalParameter::x
          getters
            #F3 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::E::@getter::v
              inducingVariable: #F2
            #F5 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
              inducingVariable: #F4
            #F7 isComplete isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
              element: <testLibrary>::@enum::E::@getter::x
              inducingVariable: #F6
  enums
    isSimplyBounded enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F4
          type: List<E>
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
        hasImplicitType isFinal isOriginDeclaration x
          reference: <testLibrary>::@enum::E::@field::x
          firstFragment: #F6
          type: dynamic
          getter: <testLibrary>::@enum::E::@getter::x
      constructors
        isConst isOriginDeclaration new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F8
          formalParameters
            #E0 requiredPositional isFinal this.x
              firstFragment: #F9
              type: int Function(double)
              field: <testLibrary>::@enum::E::@field::x
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F3
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F5
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
        isOriginVariable x
          reference: <testLibrary>::@enum::E::@getter::x
          firstFragment: #F7
          returnType: dynamic
          variable: <testLibrary>::@enum::E::@field::x
''');
  }

  test_constructor_secondary_formalParameter_field_requiredPositional_multipleMatchingFields() async {
    var library = await buildLibrary(r'''
enum E {
  v;

  final int x;
  final String x;
  const E(this.x);
}
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
            #F2 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:11) (firstTokenOffset:11) (offset:11)
              element: <testLibrary>::@enum::E::@field::v
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
              inducedGetter: #F3
            #F4 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::E::@getter::v
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
              inducedGetter: #F5
            #F6 isFinal isOriginDeclaration x (nameOffset:27) (firstTokenOffset:27) (offset:27)
              element: <testLibrary>::@enum::E::@field::x
              inducedGetter: #F7
            #F8 isFinal isOriginDeclaration x (nameOffset:45) (firstTokenOffset:45) (offset:45)
              element: <testLibrary>::@enum::E::@field::x#1
              inducedGetter: #F9
          constructors
            #F10 isComplete isConst isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:50) (offset:56)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
              typeNameOffset: 56
              formalParameters
                #F11 requiredPositional hasImplicitType isFinal isOriginDeclaration this.x (nameOffset:63) (firstTokenOffset:58) (offset:63)
                  element: <testLibrary>::@enum::E::@constructor::new::@formalParameter::x
          getters
            #F3 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::E::@getter::v
              inducingVariable: #F2
            #F5 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
              inducingVariable: #F4
            #F7 isComplete isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:27)
              element: <testLibrary>::@enum::E::@getter::x
              inducingVariable: #F6
            #F9 isComplete isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:45)
              element: <testLibrary>::@enum::E::@getter::x#1
              inducingVariable: #F8
  enums
    isSimplyBounded enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F4
          type: List<E>
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
        isFinal isOriginDeclaration x
          reference: <testLibrary>::@enum::E::@field::x
          firstFragment: #F6
          type: int
          getter: <testLibrary>::@enum::E::@getter::x
        isFinal isOriginDeclaration x
          reference: <testLibrary>::@enum::E::@field::x#1
          firstFragment: #F8
          type: String
          getter: <testLibrary>::@enum::E::@getter::x#1
      constructors
        isConst isOriginDeclaration new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F10
          formalParameters
            #E0 requiredPositional hasImplicitType isFinal this.x
              firstFragment: #F11
              type: int
              field: <testLibrary>::@enum::E::@field::x
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F3
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F5
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
        isOriginVariable x
          reference: <testLibrary>::@enum::E::@getter::x
          firstFragment: #F7
          returnType: int
          variable: <testLibrary>::@enum::E::@field::x
        isOriginVariable x
          reference: <testLibrary>::@enum::E::@getter::x#1
          firstFragment: #F9
          returnType: String
          variable: <testLibrary>::@enum::E::@field::x#1
''');
  }

  test_constructor_secondary_formalParameter_field_requiredPositional_noMatchingField() async {
    var library = await buildLibrary(r'''
enum E {
  v;

  const E(this.x);
}
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
            #F2 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:11) (firstTokenOffset:11) (offset:11)
              element: <testLibrary>::@enum::E::@field::v
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
              inducedGetter: #F3
            #F4 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::E::@getter::v
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
              inducedGetter: #F5
          constructors
            #F6 isComplete isConst isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:17) (offset:23)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
              typeNameOffset: 23
              formalParameters
                #F7 requiredPositional hasImplicitType isFinal isOriginDeclaration this.x (nameOffset:30) (firstTokenOffset:25) (offset:30)
                  element: <testLibrary>::@enum::E::@constructor::new::@formalParameter::x
          getters
            #F3 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::E::@getter::v
              inducingVariable: #F2
            #F5 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
              inducingVariable: #F4
  enums
    isSimplyBounded enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F4
          type: List<E>
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        isConst isOriginDeclaration new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F6
          formalParameters
            #E0 requiredPositional hasImplicitType isFinal this.x
              firstFragment: #F7
              type: dynamic
              field: <null>
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F3
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F5
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
''');
  }

  test_constructor_secondary_initializers_assertInvocation_field() async {
    var library = await buildLibrary(r'''
enum E<T> {
  v;

  final int x;
  const E(T? a) : assert(a is T), x = 0;
}
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
          typeParameters
            #F2 T (nameOffset:7) (firstTokenOffset:7) (offset:7)
              element: #E0 T
          fields
            #F3 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:14) (firstTokenOffset:14) (offset:14)
              element: <testLibrary>::@enum::E::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibrary>::@enum::E
                      type: E<dynamic>
                    element: SubstitutedConstructorElementImpl
                      baseElement: <testLibrary>::@enum::E::@constructor::new
                      substitution: {T: dynamic}
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E<dynamic>
              inducedGetter: #F4
            #F5 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::E::@getter::v
                      staticType: E<dynamic>
                  rightBracket: ] @0
                  staticType: List<E<dynamic>>
              inducedGetter: #F6
            #F7 isFinal isOriginDeclaration x (nameOffset:30) (firstTokenOffset:30) (offset:30)
              element: <testLibrary>::@enum::E::@field::x
              inducedGetter: #F8
          constructors
            #F9 isComplete isConst isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:35) (offset:41)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
              typeNameOffset: 41
              formalParameters
                #F10 requiredPositional isOriginDeclaration a (nameOffset:46) (firstTokenOffset:43) (offset:46)
                  element: <testLibrary>::@enum::E::@constructor::new::@formalParameter::a
          getters
            #F4 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:14)
              element: <testLibrary>::@enum::E::@getter::v
              inducingVariable: #F3
            #F6 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
              inducingVariable: #F5
            #F8 isComplete isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:30)
              element: <testLibrary>::@enum::E::@getter::x
              inducingVariable: #F7
  enums
    isSimplyBounded enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F3
          type: E<dynamic>
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F5
          type: List<E<dynamic>>
          constantInitializer
            fragment: #F5
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
        isFinal isOriginDeclaration x
          reference: <testLibrary>::@enum::E::@field::x
          firstFragment: #F7
          type: int
          getter: <testLibrary>::@enum::E::@getter::x
      constructors
        hasEnclosingTypeParameterReference isConst isOriginDeclaration new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F9
          formalParameters
            #E1 requiredPositional a
              firstFragment: #F10
              type: T?
          constantInitializers
            AssertInitializer
              assertKeyword: assert @51
              leftParenthesis: ( @57
              condition: IsExpression
                expression: SimpleIdentifier
                  token: a @58
                  element: <testLibrary>::@enum::E::@constructor::new::@formalParameter::a
                  staticType: T?
                isOperator: is @60
                type: NamedType
                  name: T @63
                  element: #E0 T
                  type: T
                staticType: bool
              rightParenthesis: ) @64
            ConstructorFieldInitializer
              fieldName: SimpleIdentifier
                token: x @67
                element: <testLibrary>::@enum::E::@field::x
                staticType: null
              equals: = @69
              expression: IntegerLiteral
                literal: 0 @71
                staticType: int
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F4
          returnType: E<dynamic>
          variable: <testLibrary>::@enum::E::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F6
          returnType: List<E<dynamic>>
          variable: <testLibrary>::@enum::E::@field::values
        isOriginVariable x
          reference: <testLibrary>::@enum::E::@getter::x
          firstFragment: #F8
          returnType: int
          variable: <testLibrary>::@enum::E::@field::x
''');
  }

  test_constructor_secondary_metadata() async {
    var library = await buildLibrary(r'''
const a = 42;

enum E {
  v;

  @a
  const E();
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      enums
        #F1 enum E (nameOffset:20) (firstTokenOffset:15) (offset:20)
          element: <testLibrary>::@enum::E
          fields
            #F2 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:26) (firstTokenOffset:26) (offset:26)
              element: <testLibrary>::@enum::E::@field::v
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
              inducedGetter: #F3
            #F4 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:20)
              element: <testLibrary>::@enum::E::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::E::@getter::v
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
              inducedGetter: #F5
          constructors
            #F6 isConst isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:32) (offset:43)
              element: <testLibrary>::@enum::E::@constructor::new
              metadata
                Annotation
                  atSign: @ @32
                  name: SimpleIdentifier
                    token: a @33
                    element: <testLibrary>::@getter::a
                    staticType: null
                  element: <testLibrary>::@getter::a
              typeName: E
              typeNameOffset: 43
          getters
            #F3 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:26)
              element: <testLibrary>::@enum::E::@getter::v
              inducingVariable: #F2
            #F5 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:20)
              element: <testLibrary>::@enum::E::@getter::values
              inducingVariable: #F4
      topLevelVariables
        #F7 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic a (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::a
          initializer: expression_2
            IntegerLiteral
              literal: 42 @10
              staticType: int
          inducedGetter: #F8
      getters
        #F8 isComplete isOriginVariable isStatic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
          inducingVariable: #F7
  enums
    isSimplyBounded enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F4
          type: List<E>
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        isConst isOriginDeclaration new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F6
          metadata
            Annotation
              atSign: @ @32
              name: SimpleIdentifier
                token: a @33
                element: <testLibrary>::@getter::a
                staticType: null
              element: <testLibrary>::@getter::a
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F3
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F5
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
  topLevelVariables
    hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F7
      type: int
      constantInitializer
        fragment: #F7
        expression: expression_2
      getter: <testLibrary>::@getter::a
  getters
    isOriginVariable isStatic a
      reference: <testLibrary>::@getter::a
      firstFragment: #F8
      returnType: int
      variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_constructor_secondary_named() async {
    var library = await buildLibrary(r'''
enum E {
  v.named(42);

  const E.named(int a);
}
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
            #F2 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:11) (firstTokenOffset:11) (offset:11)
              element: <testLibrary>::@enum::E::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibrary>::@enum::E
                      type: E
                    period: . @0
                    name: SimpleIdentifier
                      token: named @-1
                      element: <testLibrary>::@enum::E::@constructor::named
                      staticType: null
                    element: <testLibrary>::@enum::E::@constructor::named
                  argumentList: ArgumentList
                    leftParenthesis: ( @18
                    arguments
                      IntegerLiteral
                        literal: 42 @19
                        staticType: int
                    rightParenthesis: ) @21
                  staticType: E
              inducedGetter: #F3
            #F4 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::E::@getter::v
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
              inducedGetter: #F5
          constructors
            #F6 isConst isOriginDeclaration named (nameOffset:35) (firstTokenOffset:27) (offset:35)
              element: <testLibrary>::@enum::E::@constructor::named
              typeName: E
              typeNameOffset: 33
              periodOffset: 34
              formalParameters
                #F7 requiredPositional isOriginDeclaration a (nameOffset:45) (firstTokenOffset:41) (offset:45)
                  element: <testLibrary>::@enum::E::@constructor::named::@formalParameter::a
          getters
            #F3 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::E::@getter::v
              inducingVariable: #F2
            #F5 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
              inducingVariable: #F4
  enums
    isSimplyBounded enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F4
          type: List<E>
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        isConst isOriginDeclaration named
          reference: <testLibrary>::@enum::E::@constructor::named
          firstFragment: #F6
          formalParameters
            #E0 requiredPositional a
              firstFragment: #F7
              type: int
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F3
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F5
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
''');
  }

  test_constructor_secondary_newHead_named() async {
    var library = await buildLibrary(r'''
enum E {
  v.named();

  new named();
}
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
            #F2 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:11) (firstTokenOffset:11) (offset:11)
              element: <testLibrary>::@enum::E::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibrary>::@enum::E
                      type: E
                    period: . @0
                    name: SimpleIdentifier
                      token: named @-1
                      element: <testLibrary>::@enum::E::@constructor::named
                      staticType: null
                    element: <testLibrary>::@enum::E::@constructor::named
                  argumentList: ArgumentList
                    leftParenthesis: ( @18
                    rightParenthesis: ) @19
                  staticType: E
              inducedGetter: #F3
            #F4 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::E::@getter::v
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
              inducedGetter: #F5
          constructors
            #F6 isConst isOriginDeclaration named (nameOffset:29) (firstTokenOffset:25) (offset:29)
              element: <testLibrary>::@enum::E::@constructor::named
              newKeywordOffset: 25
              typeName: null
          getters
            #F3 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::E::@getter::v
              inducingVariable: #F2
            #F5 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
              inducingVariable: #F4
  enums
    isSimplyBounded enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F4
          type: List<E>
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        isConst isOriginDeclaration named
          reference: <testLibrary>::@enum::E::@constructor::named
          firstFragment: #F6
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F3
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F5
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
''');
  }

  test_constructor_secondary_newHead_named_const() async {
    var library = await buildLibrary(r'''
enum E {
  v.named();

  const new named();
}
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
            #F2 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:11) (firstTokenOffset:11) (offset:11)
              element: <testLibrary>::@enum::E::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibrary>::@enum::E
                      type: E
                    period: . @0
                    name: SimpleIdentifier
                      token: named @-1
                      element: <testLibrary>::@enum::E::@constructor::named
                      staticType: null
                    element: <testLibrary>::@enum::E::@constructor::named
                  argumentList: ArgumentList
                    leftParenthesis: ( @18
                    rightParenthesis: ) @19
                  staticType: E
              inducedGetter: #F3
            #F4 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::E::@getter::v
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
              inducedGetter: #F5
          constructors
            #F6 isConst isOriginDeclaration named (nameOffset:35) (firstTokenOffset:25) (offset:35)
              element: <testLibrary>::@enum::E::@constructor::named
              newKeywordOffset: 31
              typeName: null
          getters
            #F3 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::E::@getter::v
              inducingVariable: #F2
            #F5 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
              inducingVariable: #F4
  enums
    isSimplyBounded enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F4
          type: List<E>
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        isConst isOriginDeclaration named
          reference: <testLibrary>::@enum::E::@constructor::named
          firstFragment: #F6
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F3
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F5
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
''');
  }

  test_constructor_secondary_newHead_unnamed() async {
    var library = await buildLibrary(r'''
enum E {
  v;

  new();
}
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
            #F2 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:11) (firstTokenOffset:11) (offset:11)
              element: <testLibrary>::@enum::E::@field::v
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
              inducedGetter: #F3
            #F4 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::E::@getter::v
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
              inducedGetter: #F5
          constructors
            #F6 isConst isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:17) (offset:17)
              element: <testLibrary>::@enum::E::@constructor::new
              newKeywordOffset: 17
              typeName: null
          getters
            #F3 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::E::@getter::v
              inducingVariable: #F2
            #F5 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
              inducingVariable: #F4
  enums
    isSimplyBounded enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F4
          type: List<E>
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        isConst isOriginDeclaration new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F6
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F3
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F5
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
''');
  }

  test_constructor_secondary_newHead_unnamed_const() async {
    var library = await buildLibrary(r'''
enum E {
  v;

  const new();
}
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
            #F2 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:11) (firstTokenOffset:11) (offset:11)
              element: <testLibrary>::@enum::E::@field::v
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
              inducedGetter: #F3
            #F4 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::E::@getter::v
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
              inducedGetter: #F5
          constructors
            #F6 isConst isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:17) (offset:17)
              element: <testLibrary>::@enum::E::@constructor::new
              newKeywordOffset: 23
              typeName: null
          getters
            #F3 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::E::@getter::v
              inducingVariable: #F2
            #F5 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
              inducingVariable: #F4
  enums
    isSimplyBounded enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F4
          type: List<E>
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        isConst isOriginDeclaration new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F6
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F3
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F5
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
''');
  }

  test_constructor_secondary_typeName_named_language310() async {
    var library = await buildLibrary(r'''
// @dart = 3.10
enum E {
  v.named();

  E.named();
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      enums
        #F1 enum E (nameOffset:21) (firstTokenOffset:16) (offset:21)
          element: <testLibrary>::@enum::E
          fields
            #F2 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:27) (firstTokenOffset:27) (offset:27)
              element: <testLibrary>::@enum::E::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibrary>::@enum::E
                      type: E
                    period: . @0
                    name: SimpleIdentifier
                      token: named @-1
                      element: <testLibrary>::@enum::E::@constructor::named
                      staticType: null
                    element: <testLibrary>::@enum::E::@constructor::named
                  argumentList: ArgumentList
                    leftParenthesis: ( @34
                    rightParenthesis: ) @35
                  staticType: E
              inducedGetter: #F3
            #F4 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@enum::E::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::E::@getter::v
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
              inducedGetter: #F5
          constructors
            #F6 isOriginDeclaration named (nameOffset:43) (firstTokenOffset:41) (offset:43)
              element: <testLibrary>::@enum::E::@constructor::named
              typeName: E
              typeNameOffset: 41
              periodOffset: 42
          getters
            #F3 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:27)
              element: <testLibrary>::@enum::E::@getter::v
              inducingVariable: #F2
            #F5 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@enum::E::@getter::values
              inducingVariable: #F4
  enums
    isSimplyBounded enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F4
          type: List<E>
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        isOriginDeclaration named
          reference: <testLibrary>::@enum::E::@constructor::named
          firstFragment: #F6
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F3
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F5
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
''');
  }

  test_constructor_secondary_typeName_unnamed_language310() async {
    var library = await buildLibrary(r'''
// @dart = 3.10
enum E {
  v;

  E();
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      enums
        #F1 enum E (nameOffset:21) (firstTokenOffset:16) (offset:21)
          element: <testLibrary>::@enum::E
          fields
            #F2 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:27) (firstTokenOffset:27) (offset:27)
              element: <testLibrary>::@enum::E::@field::v
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
              inducedGetter: #F3
            #F4 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@enum::E::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::E::@getter::v
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
              inducedGetter: #F5
          constructors
            #F6 isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:33) (offset:33)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
              typeNameOffset: 33
          getters
            #F3 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:27)
              element: <testLibrary>::@enum::E::@getter::v
              inducingVariable: #F2
            #F5 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@enum::E::@getter::values
              inducingVariable: #F4
  enums
    isSimplyBounded enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F4
          type: List<E>
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        isOriginDeclaration new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F6
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F3
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F5
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
''');
  }

  test_constructor_secondary_unnamed() async {
    var library = await buildLibrary(r'''
enum E {
  v(42);

  const E(int a);
}
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
            #F2 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:11) (firstTokenOffset:11) (offset:11)
              element: <testLibrary>::@enum::E::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibrary>::@enum::E
                      type: E
                    element: <testLibrary>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @12
                    arguments
                      IntegerLiteral
                        literal: 42 @13
                        staticType: int
                    rightParenthesis: ) @15
                  staticType: E
              inducedGetter: #F3
            #F4 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::E::@getter::v
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
              inducedGetter: #F5
          constructors
            #F6 isConst isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:21) (offset:27)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
              typeNameOffset: 27
              formalParameters
                #F7 requiredPositional isOriginDeclaration a (nameOffset:33) (firstTokenOffset:29) (offset:33)
                  element: <testLibrary>::@enum::E::@constructor::new::@formalParameter::a
          getters
            #F3 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::E::@getter::v
              inducingVariable: #F2
            #F5 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
              inducingVariable: #F4
  enums
    isSimplyBounded enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F4
          type: List<E>
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        isConst isOriginDeclaration new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F6
          formalParameters
            #E0 requiredPositional a
              firstFragment: #F7
              type: int
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F3
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F5
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
''');
  }

  test_enum_augmentation_chain_introductoryDeclaration_afterAugmentation() async {
    var library = await buildLibrary(r'''
augment enum A {;
  void foo1() {}
}

enum A {
  v;
  void foo2() {}
}

augment enum A {;
  void foo3() {}
}
''');

    configuration.withConstantInitializers = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      enums
        #F1 isAugmentation enum A (nameOffset:13) (firstTokenOffset:0) (offset:13)
          element: <testLibrary>::@enum::A
          fields
            #F2 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:13)
              element: <testLibrary>::@enum::A::@field::values
              initializer: expression_0
                ListLiteral
                  leftBracket: [ @0
                  rightBracket: ] @0
                  staticType: List<A>
              inducedGetter: #F3
          constructors
            #F4 isConst isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:13)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
          getters
            #F3 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:13)
              element: <testLibrary>::@enum::A::@getter::values
              inducingVariable: #F2
          methods
            #F5 isComplete isOriginDeclaration foo1 (nameOffset:25) (firstTokenOffset:20) (offset:25)
              element: <testLibrary>::@enum::A::@method::foo1
        #F6 enum A (nameOffset:43) (firstTokenOffset:38) (offset:43)
          element: <testLibrary>::@enum::A#1
          nextFragment: #F7
          fields
            #F8 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:49) (firstTokenOffset:49) (offset:49)
              element: <testLibrary>::@enum::A#1::@field::v
              initializer: expression_1
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibrary>::@enum::A
                      type: A
                    element: <testLibrary>::@enum::A::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              inducedGetter: #F9
            #F10 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:43)
              element: <testLibrary>::@enum::A#1::@field::values
              initializer: expression_2
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::A#1::@getter::v
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
              inducedGetter: #F11
          constructors
            #F12 isConst isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:43)
              element: <testLibrary>::@enum::A#1::@constructor::new
              typeName: A
          getters
            #F9 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:49)
              element: <testLibrary>::@enum::A#1::@getter::v
              inducingVariable: #F8
            #F11 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:43)
              element: <testLibrary>::@enum::A#1::@getter::values
              inducingVariable: #F10
          methods
            #F13 isComplete isOriginDeclaration foo2 (nameOffset:59) (firstTokenOffset:54) (offset:59)
              element: <testLibrary>::@enum::A#1::@method::foo2
        #F7 isAugmentation enum A (nameOffset:85) (firstTokenOffset:72) (offset:85)
          element: <testLibrary>::@enum::A#1
          previousFragment: #F6
          methods
            #F14 isComplete isOriginDeclaration foo3 (nameOffset:97) (firstTokenOffset:92) (offset:97)
              element: <testLibrary>::@enum::A#1::@method::foo3
  enums
    isSimplyBounded enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      supertype: Enum
      fields
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F2
          type: List<A>
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::values
      constructors
        isConst isOriginImplicitDefault new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F4
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F3
          returnType: List<A>
          variable: <testLibrary>::@enum::A::@field::values
      methods
        isOriginDeclaration foo1
          reference: <testLibrary>::@enum::A::@method::foo1
          firstFragment: #F5
          returnType: void
    isSimplyBounded enum A
      reference: <testLibrary>::@enum::A#1
      firstFragment: #F6
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::A#1::@field::v
          firstFragment: #F8
          type: A
          constantInitializer
            fragment: #F8
            expression: expression_1
          getter: <testLibrary>::@enum::A#1::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::A#1::@field::values
          firstFragment: #F10
          type: List<A>
          constantInitializer
            fragment: #F10
            expression: expression_2
          getter: <testLibrary>::@enum::A#1::@getter::values
      constructors
        isConst isOriginImplicitDefault new
          reference: <testLibrary>::@enum::A#1::@constructor::new
          firstFragment: #F12
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::A#1::@getter::v
          firstFragment: #F9
          returnType: A
          variable: <testLibrary>::@enum::A#1::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::A#1::@getter::values
          firstFragment: #F11
          returnType: List<A>
          variable: <testLibrary>::@enum::A#1::@field::values
      methods
        isOriginDeclaration foo2
          reference: <testLibrary>::@enum::A#1::@method::foo2
          firstFragment: #F13
          returnType: void
        isOriginDeclaration foo3
          reference: <testLibrary>::@enum::A#1::@method::foo3
          firstFragment: #F14
          returnType: void
''');
  }

  test_enum_augmentation_chain_noIntroductoryDeclaration() async {
    var library = await buildLibrary(r'''
augment enum A {;
  void foo1() {}
}

augment enum A {;
  void foo2() {}
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      enums
        #F1 isAugmentation enum A (nameOffset:13) (firstTokenOffset:0) (offset:13)
          element: <testLibrary>::@enum::A
          nextFragment: #F2
          fields
            #F3 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:13)
              element: <testLibrary>::@enum::A::@field::values
              initializer: expression_0
                ListLiteral
                  leftBracket: [ @0
                  rightBracket: ] @0
                  staticType: List<A>
              inducedGetter: #F4
          constructors
            #F5 isConst isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:13)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
          getters
            #F4 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:13)
              element: <testLibrary>::@enum::A::@getter::values
              inducingVariable: #F3
          methods
            #F6 isComplete isOriginDeclaration foo1 (nameOffset:25) (firstTokenOffset:20) (offset:25)
              element: <testLibrary>::@enum::A::@method::foo1
        #F2 isAugmentation enum A (nameOffset:51) (firstTokenOffset:38) (offset:51)
          element: <testLibrary>::@enum::A
          previousFragment: #F1
          methods
            #F7 isComplete isOriginDeclaration foo2 (nameOffset:63) (firstTokenOffset:58) (offset:63)
              element: <testLibrary>::@enum::A::@method::foo2
  enums
    isSimplyBounded enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      supertype: Enum
      fields
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F3
          type: List<A>
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::values
      constructors
        isConst isOriginImplicitDefault new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F5
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F4
          returnType: List<A>
          variable: <testLibrary>::@enum::A::@field::values
      methods
        isOriginDeclaration foo1
          reference: <testLibrary>::@enum::A::@method::foo1
          firstFragment: #F6
          returnType: void
        isOriginDeclaration foo2
          reference: <testLibrary>::@enum::A::@method::foo2
          firstFragment: #F7
          returnType: void
''');
  }

  test_enum_augmentation_chain_partTreePreorder() async {
    newFile('$testPackageLibPath/a1.dart', r'''
part of 'test.dart';
part 'a11.dart';
part 'a12.dart';
augment enum A {}
''');

    newFile('$testPackageLibPath/a11.dart', r'''
part of 'a1.dart';
augment enum A {}
''');

    newFile('$testPackageLibPath/a12.dart', r'''
part of 'a1.dart';
augment enum A {}
''');

    newFile('$testPackageLibPath/a2.dart', r'''
part of 'test.dart';
part 'a21.dart';
part 'a22.dart';
augment enum A {}
''');

    newFile('$testPackageLibPath/a21.dart', r'''
part of 'a2.dart';
augment enum A {}
''');

    newFile('$testPackageLibPath/a22.dart', r'''
part of 'a2.dart';
augment enum A {}
''');

    var library = await buildLibrary(r'''
part 'a1.dart';
part 'a2.dart';

enum A { v }
''');

    configuration
      ..withConstantInitializers = false
      ..withExportScope = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      nextFragment: #F1
      parts
        part_0
          uri: package:test/a1.dart
          partKeywordOffset: 0
          unit: #F1
        part_1
          uri: package:test/a2.dart
          partKeywordOffset: 16
          unit: #F2
      enums
        #F3 enum A (nameOffset:38) (firstTokenOffset:33) (offset:38)
          element: <testLibrary>::@enum::A
          nextFragment: #F4
          fields
            #F5 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:42) (firstTokenOffset:42) (offset:42)
              element: <testLibrary>::@enum::A::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibrary>::@enum::A
                      type: A
                    element: <testLibrary>::@enum::A::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              inducedGetter: #F6
            #F7 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:38)
              element: <testLibrary>::@enum::A::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::A::@getter::v
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
              inducedGetter: #F8
          constructors
            #F9 isConst isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:38)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
          getters
            #F6 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:42)
              element: <testLibrary>::@enum::A::@getter::v
              inducingVariable: #F5
            #F8 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:38)
              element: <testLibrary>::@enum::A::@getter::values
              inducingVariable: #F7
    #F1 package:test/a1.dart
      element: <testLibrary>
      enclosingFragment: #F0
      previousFragment: #F0
      nextFragment: #F10
      parts
        part_2
          uri: package:test/a11.dart
          partKeywordOffset: 21
          unit: #F10
        part_3
          uri: package:test/a12.dart
          partKeywordOffset: 38
          unit: #F11
      enums
        #F4 isAugmentation enum A (nameOffset:68) (firstTokenOffset:55) (offset:68)
          element: <testLibrary>::@enum::A
          previousFragment: #F3
          nextFragment: #F12
    #F10 package:test/a11.dart
      element: <testLibrary>
      enclosingFragment: #F1
      previousFragment: #F1
      nextFragment: #F11
      enums
        #F12 isAugmentation enum A (nameOffset:32) (firstTokenOffset:19) (offset:32)
          element: <testLibrary>::@enum::A
          previousFragment: #F4
          nextFragment: #F13
    #F11 package:test/a12.dart
      element: <testLibrary>
      enclosingFragment: #F1
      previousFragment: #F10
      nextFragment: #F2
      enums
        #F13 isAugmentation enum A (nameOffset:32) (firstTokenOffset:19) (offset:32)
          element: <testLibrary>::@enum::A
          previousFragment: #F12
          nextFragment: #F14
    #F2 package:test/a2.dart
      element: <testLibrary>
      enclosingFragment: #F0
      previousFragment: #F11
      nextFragment: #F15
      parts
        part_4
          uri: package:test/a21.dart
          partKeywordOffset: 21
          unit: #F15
        part_5
          uri: package:test/a22.dart
          partKeywordOffset: 38
          unit: #F16
      enums
        #F14 isAugmentation enum A (nameOffset:68) (firstTokenOffset:55) (offset:68)
          element: <testLibrary>::@enum::A
          previousFragment: #F13
          nextFragment: #F17
    #F15 package:test/a21.dart
      element: <testLibrary>
      enclosingFragment: #F2
      previousFragment: #F2
      nextFragment: #F16
      enums
        #F17 isAugmentation enum A (nameOffset:32) (firstTokenOffset:19) (offset:32)
          element: <testLibrary>::@enum::A
          previousFragment: #F14
          nextFragment: #F18
    #F16 package:test/a22.dart
      element: <testLibrary>
      enclosingFragment: #F2
      previousFragment: #F15
      enums
        #F18 isAugmentation enum A (nameOffset:32) (firstTokenOffset:19) (offset:32)
          element: <testLibrary>::@enum::A
          previousFragment: #F17
  enums
    isSimplyBounded enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F3
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F5
          type: A
          constantInitializer
            fragment: #F5
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F7
          type: List<A>
          constantInitializer
            fragment: #F7
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
      constructors
        isConst isOriginImplicitDefault new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F9
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F6
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F8
          returnType: List<A>
          variable: <testLibrary>::@enum::A::@field::values
  exportEntries
    declared <testLibrary>::@enum::A
  exportNamespace
    A: <testLibrary>::@enum::A
''');
  }

  test_enum_augmentation_sameName_class_class() async {
    var library = await buildLibrary(r'''
enum A {v}

augment class A {}

augment class A {}
''');

    configuration
      ..withConstantInitializers = false
      ..withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 isAugmentation class A (nameOffset:26) (firstTokenOffset:12) (offset:26)
          element: <testLibrary>::@class::A
          nextFragment: #F2
        #F2 isAugmentation class A (nameOffset:46) (firstTokenOffset:32) (offset:46)
          element: <testLibrary>::@class::A
          previousFragment: #F1
      enums
        #F3 enum A (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@enum::A
          fields
            #F4 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:8) (firstTokenOffset:8) (offset:8)
              element: <testLibrary>::@enum::A::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibrary>::@enum::A
                      type: A
                    element: <testLibrary>::@enum::A::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              inducedGetter: #F5
            #F6 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::A::@getter::v
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
              inducedGetter: #F7
          getters
            #F5 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:8)
              element: <testLibrary>::@enum::A::@getter::v
              inducingVariable: #F4
            #F7 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
              inducingVariable: #F6
  classes
    isSimplyBounded class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      previousFragmentOfDifferentKind: #F3
  enums
    isSimplyBounded enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F3
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F4
          type: A
          constantInitializer
            fragment: #F4
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F6
          type: List<A>
          constantInitializer
            fragment: #F6
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F5
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F7
          returnType: List<A>
          variable: <testLibrary>::@enum::A::@field::values
''');
  }

  test_enum_augmentation_sameName_class_enum() async {
    var library = await buildLibrary(r'''
enum A {v}

augment class A {}
augment enum A {}
''');

    configuration
      ..withConstantInitializers = false
      ..withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 isAugmentation class A (nameOffset:26) (firstTokenOffset:12) (offset:26)
          element: <testLibrary>::@class::A
      enums
        #F2 enum A (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@enum::A
          fields
            #F3 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:8) (firstTokenOffset:8) (offset:8)
              element: <testLibrary>::@enum::A::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibrary>::@enum::A
                      type: A
                    element: <testLibrary>::@enum::A::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              inducedGetter: #F4
            #F5 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::A::@getter::v
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
              inducedGetter: #F6
          getters
            #F4 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:8)
              element: <testLibrary>::@enum::A::@getter::v
              inducingVariable: #F3
            #F6 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
              inducingVariable: #F5
        #F7 isAugmentation enum A (nameOffset:44) (firstTokenOffset:31) (offset:44)
          element: <testLibrary>::@enum::A#1
          fields
            #F8 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:44)
              element: <testLibrary>::@enum::A#1::@field::values
              initializer: expression_2
                ListLiteral
                  leftBracket: [ @0
                  rightBracket: ] @0
                  staticType: List<A>
              inducedGetter: #F9
          getters
            #F9 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:44)
              element: <testLibrary>::@enum::A#1::@getter::values
              inducingVariable: #F8
  classes
    isSimplyBounded class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      previousFragmentOfDifferentKind: #F2
  enums
    isSimplyBounded enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F2
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F3
          type: A
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F5
          type: List<A>
          constantInitializer
            fragment: #F5
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F4
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F6
          returnType: List<A>
          variable: <testLibrary>::@enum::A::@field::values
    isSimplyBounded enum A
      reference: <testLibrary>::@enum::A#1
      firstFragment: #F7
      previousFragmentOfDifferentKind: #F1
      supertype: Enum
      fields
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::A#1::@field::values
          firstFragment: #F8
          type: List<A>
          constantInitializer
            fragment: #F8
            expression: expression_2
          getter: <testLibrary>::@enum::A#1::@getter::values
      getters
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::A#1::@getter::values
          firstFragment: #F9
          returnType: List<A>
          variable: <testLibrary>::@enum::A#1::@field::values
''');
  }

  test_enum_codeRange() async {
    var library = await buildLibrary(r'''
enum E { aaa, bbb, ccc }
''');
    configuration.withCodeRanges = true;
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
            #F2 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic aaa (nameOffset:9) (firstTokenOffset:9) (offset:9)
              element: <testLibrary>::@enum::E::@field::aaa
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
              inducedGetter: #F3
            #F4 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic bbb (nameOffset:14) (firstTokenOffset:14) (offset:14)
              element: <testLibrary>::@enum::E::@field::bbb
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
              inducedGetter: #F5
            #F6 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic ccc (nameOffset:19) (firstTokenOffset:19) (offset:19)
              element: <testLibrary>::@enum::E::@field::ccc
              initializer: expression_2
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
              inducedGetter: #F7
            #F8 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@field::values
              initializer: expression_3
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: aaa @-1
                      element: <testLibrary>::@enum::E::@getter::aaa
                      staticType: E
                    SimpleIdentifier
                      token: bbb @-1
                      element: <testLibrary>::@enum::E::@getter::bbb
                      staticType: E
                    SimpleIdentifier
                      token: ccc @-1
                      element: <testLibrary>::@enum::E::@getter::ccc
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
              inducedGetter: #F9
          constructors
            #F10 isConst isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F3 isComplete isOriginVariable isStatic aaa (nameOffset:<null>) (firstTokenOffset:<null>) (offset:9)
              element: <testLibrary>::@enum::E::@getter::aaa
              inducingVariable: #F2
            #F5 isComplete isOriginVariable isStatic bbb (nameOffset:<null>) (firstTokenOffset:<null>) (offset:14)
              element: <testLibrary>::@enum::E::@getter::bbb
              inducingVariable: #F4
            #F7 isComplete isOriginVariable isStatic ccc (nameOffset:<null>) (firstTokenOffset:<null>) (offset:19)
              element: <testLibrary>::@enum::E::@getter::ccc
              inducingVariable: #F6
            #F9 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
              inducingVariable: #F8
  enums
    isSimplyBounded enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer aaa
          reference: <testLibrary>::@enum::E::@field::aaa
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::aaa
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer bbb
          reference: <testLibrary>::@enum::E::@field::bbb
          firstFragment: #F4
          type: E
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::bbb
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer ccc
          reference: <testLibrary>::@enum::E::@field::ccc
          firstFragment: #F6
          type: E
          constantInitializer
            fragment: #F6
            expression: expression_2
          getter: <testLibrary>::@enum::E::@getter::ccc
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F8
          type: List<E>
          constantInitializer
            fragment: #F8
            expression: expression_3
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        isConst isOriginImplicitDefault new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F10
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic aaa
          reference: <testLibrary>::@enum::E::@getter::aaa
          firstFragment: #F3
          returnType: E
          variable: <testLibrary>::@enum::E::@field::aaa
        isOriginVariable isStatic bbb
          reference: <testLibrary>::@enum::E::@getter::bbb
          firstFragment: #F5
          returnType: E
          variable: <testLibrary>::@enum::E::@field::bbb
        isOriginVariable isStatic ccc
          reference: <testLibrary>::@enum::E::@getter::ccc
          firstFragment: #F7
          returnType: E
          variable: <testLibrary>::@enum::E::@field::ccc
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F9
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
''');
  }

  test_enum_documented() async {
    var library = await buildLibrary(r'''
// Extra comment so doc comment offset != 0
/**
 * Docs
 */
enum E { v }
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      enums
        #F1 enum E (nameOffset:65) (firstTokenOffset:44) (offset:65)
          element: <testLibrary>::@enum::E
          fields
            #F2 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:69) (firstTokenOffset:69) (offset:69)
              element: <testLibrary>::@enum::E::@field::v
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
              inducedGetter: #F3
            #F4 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:65)
              element: <testLibrary>::@enum::E::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::E::@getter::v
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
              inducedGetter: #F5
          constructors
            #F6 isConst isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:65)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F3 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:69)
              element: <testLibrary>::@enum::E::@getter::v
              inducingVariable: #F2
            #F5 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:65)
              element: <testLibrary>::@enum::E::@getter::values
              inducingVariable: #F4
  enums
    isSimplyBounded enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      documentationComment: /**\n * Docs\n */
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F4
          type: List<E>
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        isConst isOriginImplicitDefault new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F6
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F3
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F5
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
''');
  }

  test_enum_emptyBlockBody() async {
    var library = await buildLibrary(r'''
enum E {}
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
            #F2 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@field::values
              initializer: expression_0
                ListLiteral
                  leftBracket: [ @0
                  rightBracket: ] @0
                  staticType: List<E>
              inducedGetter: #F3
          constructors
            #F4 isConst isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F3 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
              inducingVariable: #F2
  enums
    isSimplyBounded enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F2
          type: List<E>
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        isConst isOriginImplicitDefault new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F4
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F3
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
''');
  }

  test_enum_emptyBody() async {
    var library = await buildLibrary(r'''
enum E;
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
            #F2 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@field::values
              initializer: expression_0
                ListLiteral
                  leftBracket: [ @0
                  rightBracket: ] @0
                  staticType: List<E>
              inducedGetter: #F3
          constructors
            #F4 isConst isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F3 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
              inducingVariable: #F2
  enums
    isSimplyBounded enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F2
          type: List<E>
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        isConst isOriginImplicitDefault new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F4
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F3
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
''');
  }

  test_enum_emptyBody_language310() async {
    var library = await buildLibrary(r'''
// @dart = 3.10
enum E;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      enums
        #F1 enum E (nameOffset:21) (firstTokenOffset:16) (offset:21)
          element: <testLibrary>::@enum::E
          fields
            #F2 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@enum::E::@field::values
              initializer: expression_0
                ListLiteral
                  leftBracket: [ @0
                  rightBracket: ] @0
                  staticType: List<E>
              inducedGetter: #F3
          constructors
            #F4 isConst isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F3 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@enum::E::@getter::values
              inducingVariable: #F2
  enums
    isSimplyBounded enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F2
          type: List<E>
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        isConst isOriginImplicitDefault new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F4
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F3
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
''');
  }

  test_enum_error_extendsEnum() async {
    var library = await buildLibrary(r'''
enum E { a, b, c }

class M {}

class A extends E {
  foo() {}
}

class B implements E, M {
  foo() {}
}

class C extends Object with E, M {
  foo() {}
}

class D = Object with M, E;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class M (nameOffset:26) (firstTokenOffset:20) (offset:26)
          element: <testLibrary>::@class::M
          constructors
            #F2 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:26)
              element: <testLibrary>::@class::M::@constructor::new
              typeName: M
        #F3 hasExtendsClause class A (nameOffset:38) (firstTokenOffset:32) (offset:38)
          element: <testLibrary>::@class::A
          constructors
            #F4 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:38)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          methods
            #F5 hasImplicitReturnType isComplete isOriginDeclaration foo (nameOffset:54) (firstTokenOffset:54) (offset:54)
              element: <testLibrary>::@class::A::@method::foo
        #F6 class B (nameOffset:72) (firstTokenOffset:66) (offset:72)
          element: <testLibrary>::@class::B
          constructors
            #F7 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:72)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          methods
            #F8 hasImplicitReturnType isComplete isOriginDeclaration foo (nameOffset:94) (firstTokenOffset:94) (offset:94)
              element: <testLibrary>::@class::B::@method::foo
        #F9 hasExtendsClause class C (nameOffset:112) (firstTokenOffset:106) (offset:112)
          element: <testLibrary>::@class::C
          constructors
            #F10 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:112)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          methods
            #F11 hasImplicitReturnType isComplete isOriginDeclaration foo (nameOffset:143) (firstTokenOffset:143) (offset:143)
              element: <testLibrary>::@class::C::@method::foo
        #F12 isMixinApplication class D (nameOffset:161) (firstTokenOffset:155) (offset:161)
          element: <testLibrary>::@class::D
          constructors
            #F13 isConst isOriginMixinApplication new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:161)
              element: <testLibrary>::@class::D::@constructor::new
              typeName: D
      enums
        #F14 enum E (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@enum::E
          fields
            #F15 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic a (nameOffset:9) (firstTokenOffset:9) (offset:9)
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
              inducedGetter: #F16
            #F17 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic b (nameOffset:12) (firstTokenOffset:12) (offset:12)
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
              inducedGetter: #F18
            #F19 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic c (nameOffset:15) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@enum::E::@field::c
              initializer: expression_2
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
              inducedGetter: #F20
            #F21 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@field::values
              initializer: expression_3
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
                    SimpleIdentifier
                      token: c @-1
                      element: <testLibrary>::@enum::E::@getter::c
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
              inducedGetter: #F22
          constructors
            #F23 isConst isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F16 isComplete isOriginVariable isStatic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:9)
              element: <testLibrary>::@enum::E::@getter::a
              inducingVariable: #F15
            #F18 isComplete isOriginVariable isStatic b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:12)
              element: <testLibrary>::@enum::E::@getter::b
              inducingVariable: #F17
            #F20 isComplete isOriginVariable isStatic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@enum::E::@getter::c
              inducingVariable: #F19
            #F22 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
              inducingVariable: #F21
  classes
    isSimplyBounded class M
      reference: <testLibrary>::@class::M
      firstFragment: #F1
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::M::@constructor::new
          firstFragment: #F2
    isSimplyBounded class A
      reference: <testLibrary>::@class::A
      firstFragment: #F3
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F4
      methods
        isOriginDeclaration foo
          reference: <testLibrary>::@class::A::@method::foo
          firstFragment: #F5
          returnType: dynamic
    isSimplyBounded class B
      reference: <testLibrary>::@class::B
      firstFragment: #F6
      interfaces
        M
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F7
      methods
        isOriginDeclaration foo
          reference: <testLibrary>::@class::B::@method::foo
          firstFragment: #F8
          returnType: dynamic
    isSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F9
      supertype: Object
      mixins
        M
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F10
      methods
        isOriginDeclaration foo
          reference: <testLibrary>::@class::C::@method::foo
          firstFragment: #F11
          returnType: dynamic
    isMixinApplication isSimplyBounded class D
      reference: <testLibrary>::@class::D
      firstFragment: #F12
      supertype: Object
      mixins
        M
      constructors
        isConst isOriginMixinApplication new
          reference: <testLibrary>::@class::D::@constructor::new
          firstFragment: #F13
          constantInitializers
            SuperConstructorInvocation
              superKeyword: super @0
              argumentList: ArgumentList
                leftParenthesis: ( @0
                rightParenthesis: ) @0
              element: dart:core::@class::Object::@constructor::new
  enums
    isSimplyBounded enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F14
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer a
          reference: <testLibrary>::@enum::E::@field::a
          firstFragment: #F15
          type: E
          constantInitializer
            fragment: #F15
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::a
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer b
          reference: <testLibrary>::@enum::E::@field::b
          firstFragment: #F17
          type: E
          constantInitializer
            fragment: #F17
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::b
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer c
          reference: <testLibrary>::@enum::E::@field::c
          firstFragment: #F19
          type: E
          constantInitializer
            fragment: #F19
            expression: expression_2
          getter: <testLibrary>::@enum::E::@getter::c
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F21
          type: List<E>
          constantInitializer
            fragment: #F21
            expression: expression_3
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        isConst isOriginImplicitDefault new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F23
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic a
          reference: <testLibrary>::@enum::E::@getter::a
          firstFragment: #F16
          returnType: E
          variable: <testLibrary>::@enum::E::@field::a
        isOriginVariable isStatic b
          reference: <testLibrary>::@enum::E::@getter::b
          firstFragment: #F18
          returnType: E
          variable: <testLibrary>::@enum::E::@field::b
        isOriginVariable isStatic c
          reference: <testLibrary>::@enum::E::@getter::c
          firstFragment: #F20
          returnType: E
          variable: <testLibrary>::@enum::E::@field::c
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F22
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
''');
  }

  test_enum_interfaces() async {
    var library = await buildLibrary(r'''
class I {}

enum E implements I { v }
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
          constructors
            #F2 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::I::@constructor::new
              typeName: I
      enums
        #F3 enum E (nameOffset:17) (firstTokenOffset:12) (offset:17)
          element: <testLibrary>::@enum::E
          fields
            #F4 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:34) (firstTokenOffset:34) (offset:34)
              element: <testLibrary>::@enum::E::@field::v
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
              inducedGetter: #F5
            #F6 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:17)
              element: <testLibrary>::@enum::E::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::E::@getter::v
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
              inducedGetter: #F7
          constructors
            #F8 isConst isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:17)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F5 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:34)
              element: <testLibrary>::@enum::E::@getter::v
              inducingVariable: #F4
            #F7 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:17)
              element: <testLibrary>::@enum::E::@getter::values
              inducingVariable: #F6
  classes
    isSimplyBounded class I
      reference: <testLibrary>::@class::I
      firstFragment: #F1
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::I::@constructor::new
          firstFragment: #F2
  enums
    isSimplyBounded enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F3
      supertype: Enum
      interfaces
        I
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F4
          type: E
          constantInitializer
            fragment: #F4
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F6
          type: List<E>
          constantInitializer
            fragment: #F6
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        isConst isOriginImplicitDefault new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F8
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F5
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F7
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
''');
  }

  test_enum_interfaces_augmentation_add() async {
    var library = await buildLibrary(r'''
enum A implements I1 {
  v
}
class I1 {}

augment enum A implements I2 {}
class I2 {}
''');

    configuration.withConstantInitializers = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class I1 (nameOffset:35) (firstTokenOffset:29) (offset:35)
          element: <testLibrary>::@class::I1
          constructors
            #F2 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:35)
              element: <testLibrary>::@class::I1::@constructor::new
              typeName: I1
        #F3 class I2 (nameOffset:80) (firstTokenOffset:74) (offset:80)
          element: <testLibrary>::@class::I2
          constructors
            #F4 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:80)
              element: <testLibrary>::@class::I2::@constructor::new
              typeName: I2
      enums
        #F5 enum A (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@enum::A
          nextFragment: #F6
          fields
            #F7 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:25) (firstTokenOffset:25) (offset:25)
              element: <testLibrary>::@enum::A::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibrary>::@enum::A
                      type: A
                    element: <testLibrary>::@enum::A::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              inducedGetter: #F8
            #F9 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::A::@getter::v
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
              inducedGetter: #F10
          constructors
            #F11 isConst isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
          getters
            #F8 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
              element: <testLibrary>::@enum::A::@getter::v
              inducingVariable: #F7
            #F10 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
              inducingVariable: #F9
        #F6 isAugmentation enum A (nameOffset:55) (firstTokenOffset:42) (offset:55)
          element: <testLibrary>::@enum::A
          previousFragment: #F5
  classes
    isSimplyBounded class I1
      reference: <testLibrary>::@class::I1
      firstFragment: #F1
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::I1::@constructor::new
          firstFragment: #F2
    isSimplyBounded class I2
      reference: <testLibrary>::@class::I2
      firstFragment: #F3
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::I2::@constructor::new
          firstFragment: #F4
  enums
    isSimplyBounded enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F5
      supertype: Enum
      interfaces
        I1
        I2
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F7
          type: A
          constantInitializer
            fragment: #F7
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F9
          type: List<A>
          constantInitializer
            fragment: #F9
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
      constructors
        isConst isOriginImplicitDefault new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F11
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F8
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F10
          returnType: List<A>
          variable: <testLibrary>::@enum::A::@field::values
''');
  }

  test_enum_interfaces_augmentation_add_chain() async {
    var library = await buildLibrary(r'''
enum A implements I1 {
  v
}
class I1 {}

augment enum A implements I2 {}
class I2 {}

augment enum A implements I3 {}
class I3 {}
''');

    configuration.withConstantInitializers = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class I1 (nameOffset:35) (firstTokenOffset:29) (offset:35)
          element: <testLibrary>::@class::I1
          constructors
            #F2 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:35)
              element: <testLibrary>::@class::I1::@constructor::new
              typeName: I1
        #F3 class I2 (nameOffset:80) (firstTokenOffset:74) (offset:80)
          element: <testLibrary>::@class::I2
          constructors
            #F4 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:80)
              element: <testLibrary>::@class::I2::@constructor::new
              typeName: I2
        #F5 class I3 (nameOffset:125) (firstTokenOffset:119) (offset:125)
          element: <testLibrary>::@class::I3
          constructors
            #F6 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:125)
              element: <testLibrary>::@class::I3::@constructor::new
              typeName: I3
      enums
        #F7 enum A (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@enum::A
          nextFragment: #F8
          fields
            #F9 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:25) (firstTokenOffset:25) (offset:25)
              element: <testLibrary>::@enum::A::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibrary>::@enum::A
                      type: A
                    element: <testLibrary>::@enum::A::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              inducedGetter: #F10
            #F11 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::A::@getter::v
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
              inducedGetter: #F12
          constructors
            #F13 isConst isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
          getters
            #F10 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
              element: <testLibrary>::@enum::A::@getter::v
              inducingVariable: #F9
            #F12 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
              inducingVariable: #F11
        #F8 isAugmentation enum A (nameOffset:55) (firstTokenOffset:42) (offset:55)
          element: <testLibrary>::@enum::A
          previousFragment: #F7
          nextFragment: #F14
        #F14 isAugmentation enum A (nameOffset:100) (firstTokenOffset:87) (offset:100)
          element: <testLibrary>::@enum::A
          previousFragment: #F8
  classes
    isSimplyBounded class I1
      reference: <testLibrary>::@class::I1
      firstFragment: #F1
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::I1::@constructor::new
          firstFragment: #F2
    isSimplyBounded class I2
      reference: <testLibrary>::@class::I2
      firstFragment: #F3
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::I2::@constructor::new
          firstFragment: #F4
    isSimplyBounded class I3
      reference: <testLibrary>::@class::I3
      firstFragment: #F5
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::I3::@constructor::new
          firstFragment: #F6
  enums
    isSimplyBounded enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F7
      supertype: Enum
      interfaces
        I1
        I2
        I3
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F9
          type: A
          constantInitializer
            fragment: #F9
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F11
          type: List<A>
          constantInitializer
            fragment: #F11
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
      constructors
        isConst isOriginImplicitDefault new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F13
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F10
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F12
          returnType: List<A>
          variable: <testLibrary>::@enum::A::@field::values
''');
  }

  test_enum_interfaces_augmentation_add_generic() async {
    var library = await buildLibrary(r'''
enum A<T> implements I1 {
  v<int>()
}
class I1 {}

augment enum A<T> implements I2<T> {}
class I2<E> {}
''');

    configuration.withConstantInitializers = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class I1 (nameOffset:45) (firstTokenOffset:39) (offset:45)
          element: <testLibrary>::@class::I1
          constructors
            #F2 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:45)
              element: <testLibrary>::@class::I1::@constructor::new
              typeName: I1
        #F3 class I2 (nameOffset:96) (firstTokenOffset:90) (offset:96)
          element: <testLibrary>::@class::I2
          typeParameters
            #F4 E (nameOffset:99) (firstTokenOffset:99) (offset:99)
              element: #E0 E
          constructors
            #F5 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:96)
              element: <testLibrary>::@class::I2::@constructor::new
              typeName: I2
      enums
        #F6 enum A (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@enum::A
          nextFragment: #F7
          typeParameters
            #F8 T (nameOffset:7) (firstTokenOffset:7) (offset:7)
              element: #E1 T
              nextFragment: #F9
          fields
            #F10 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:28) (firstTokenOffset:28) (offset:28)
              element: <testLibrary>::@enum::A::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      typeArguments: TypeArgumentList
                        leftBracket: < @29
                        arguments
                          NamedType
                            name: int @30
                            element: dart:core::@class::int
                            type: int
                        rightBracket: > @33
                      element: <testLibrary>::@enum::A
                      type: A<int>
                    element: SubstitutedConstructorElementImpl
                      baseElement: <testLibrary>::@enum::A::@constructor::new
                      substitution: {T: int}
                  argumentList: ArgumentList
                    leftParenthesis: ( @34
                    rightParenthesis: ) @35
                  staticType: A<int>
              inducedGetter: #F11
            #F12 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::A::@getter::v
                      staticType: A<int>
                  rightBracket: ] @0
                  staticType: List<A<dynamic>>
              inducedGetter: #F13
          constructors
            #F14 isConst isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
          getters
            #F11 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:28)
              element: <testLibrary>::@enum::A::@getter::v
              inducingVariable: #F10
            #F13 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
              inducingVariable: #F12
        #F7 isAugmentation enum A (nameOffset:65) (firstTokenOffset:52) (offset:65)
          element: <testLibrary>::@enum::A
          previousFragment: #F6
          typeParameters
            #F9 T (nameOffset:67) (firstTokenOffset:67) (offset:67)
              element: #E1 T
              previousFragment: #F8
  classes
    isSimplyBounded class I1
      reference: <testLibrary>::@class::I1
      firstFragment: #F1
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::I1::@constructor::new
          firstFragment: #F2
    isSimplyBounded class I2
      reference: <testLibrary>::@class::I2
      firstFragment: #F3
      typeParameters
        #E0 E
          firstFragment: #F4
      constructors
        hasEnclosingTypeParameterReference isOriginImplicitDefault new
          reference: <testLibrary>::@class::I2::@constructor::new
          firstFragment: #F5
  enums
    isSimplyBounded enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F6
      typeParameters
        #E1 T
          firstFragment: #F8
      supertype: Enum
      interfaces
        I1
        I2<T>
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F10
          type: A<int>
          constantInitializer
            fragment: #F10
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F12
          type: List<A<dynamic>>
          constantInitializer
            fragment: #F12
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
      constructors
        hasEnclosingTypeParameterReference isConst isOriginImplicitDefault new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F14
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F11
          returnType: A<int>
          variable: <testLibrary>::@enum::A::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F13
          returnType: List<A<dynamic>>
          variable: <testLibrary>::@enum::A::@field::values
''');
  }

  test_enum_interfaces_augmentation_add_generic_mismatch() async {
    var library = await buildLibrary(r'''
enum A<T> implements I1 {
  v
}
class I1 {}

augment enum A<T, U> implements I2<T> {}
class I2<E> {}
''');

    configuration.withConstantInitializers = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class I1 (nameOffset:38) (firstTokenOffset:32) (offset:38)
          element: <testLibrary>::@class::I1
          constructors
            #F2 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:38)
              element: <testLibrary>::@class::I1::@constructor::new
              typeName: I1
        #F3 class I2 (nameOffset:92) (firstTokenOffset:86) (offset:92)
          element: <testLibrary>::@class::I2
          typeParameters
            #F4 E (nameOffset:95) (firstTokenOffset:95) (offset:95)
              element: #E0 E
          constructors
            #F5 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:92)
              element: <testLibrary>::@class::I2::@constructor::new
              typeName: I2
      enums
        #F6 enum A (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@enum::A
          nextFragment: #F7
          typeParameters
            #F8 T (nameOffset:7) (firstTokenOffset:7) (offset:7)
              element: #E1 T
              nextFragment: #F9
            #F10 isOriginOtherFragmentOfEnclosing U (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: #E2 U
              nextFragment: #F11
          fields
            #F12 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:28) (firstTokenOffset:28) (offset:28)
              element: <testLibrary>::@enum::A::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibrary>::@enum::A
                      type: A<dynamic>
                    element: SubstitutedConstructorElementImpl
                      baseElement: <testLibrary>::@enum::A::@constructor::new
                      substitution: {T: dynamic}
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A<dynamic>
              inducedGetter: #F13
            #F14 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::A::@getter::v
                      staticType: A<dynamic>
                  rightBracket: ] @0
                  staticType: List<A<dynamic>>
              inducedGetter: #F15
          constructors
            #F16 isConst isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
          getters
            #F13 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:28)
              element: <testLibrary>::@enum::A::@getter::v
              inducingVariable: #F12
            #F15 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
              inducingVariable: #F14
        #F7 isAugmentation enum A (nameOffset:58) (firstTokenOffset:45) (offset:58)
          element: <testLibrary>::@enum::A
          previousFragment: #F6
          typeParameters
            #F9 T (nameOffset:60) (firstTokenOffset:60) (offset:60)
              element: #E1 T
              previousFragment: #F8
            #F11 U (nameOffset:63) (firstTokenOffset:63) (offset:63)
              element: #E2 U
              previousFragment: #F10
  classes
    isSimplyBounded class I1
      reference: <testLibrary>::@class::I1
      firstFragment: #F1
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::I1::@constructor::new
          firstFragment: #F2
    isSimplyBounded class I2
      reference: <testLibrary>::@class::I2
      firstFragment: #F3
      typeParameters
        #E0 E
          firstFragment: #F4
      constructors
        hasEnclosingTypeParameterReference isOriginImplicitDefault new
          reference: <testLibrary>::@class::I2::@constructor::new
          firstFragment: #F5
  enums
    isSimplyBounded enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F6
      typeParameters
        #E1 T
          firstFragment: #F8
      supertype: Enum
      interfaces
        I1
        I2<T>
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F12
          type: A<dynamic>
          constantInitializer
            fragment: #F12
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F14
          type: List<A<dynamic>>
          constantInitializer
            fragment: #F14
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
      constructors
        hasEnclosingTypeParameterReference isConst isOriginImplicitDefault new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F16
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F13
          returnType: A<dynamic>
          variable: <testLibrary>::@enum::A::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F15
          returnType: List<A<dynamic>>
          variable: <testLibrary>::@enum::A::@field::values
''');
  }

  test_enum_interfaces_extensionType() async {
    var library = await buildLibrary(r'''
class A {}

extension type B(int it) {}

class C {}

enum E implements A, B, C { v }
''');
    configuration
      ..withConstructors = false
      ..withConstantInitializers = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::A
        #F2 class C (nameOffset:47) (firstTokenOffset:41) (offset:47)
          element: <testLibrary>::@class::C
      enums
        #F3 enum E (nameOffset:58) (firstTokenOffset:53) (offset:58)
          element: <testLibrary>::@enum::E
          fields
            #F4 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:81) (firstTokenOffset:81) (offset:81)
              element: <testLibrary>::@enum::E::@field::v
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
              inducedGetter: #F5
            #F6 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:58)
              element: <testLibrary>::@enum::E::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::E::@getter::v
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
              inducedGetter: #F7
          getters
            #F5 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:81)
              element: <testLibrary>::@enum::E::@getter::v
              inducingVariable: #F4
            #F7 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:58)
              element: <testLibrary>::@enum::E::@getter::values
              inducingVariable: #F6
      extensionTypes
        #F8 extension type B (nameOffset:27) (firstTokenOffset:12) (offset:27)
          element: <testLibrary>::@extensionType::B
          fields
            #F9 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:27)
              element: <testLibrary>::@extensionType::B::@field::it
              inducedGetter: #F10
          getters
            #F10 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:27)
              element: <testLibrary>::@extensionType::B::@getter::it
              inducingVariable: #F9
  classes
    isSimplyBounded class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
    isSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F2
  enums
    isSimplyBounded enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F3
      supertype: Enum
      interfaces
        A
        C
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F4
          type: E
          constantInitializer
            fragment: #F4
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F6
          type: List<E>
          constantInitializer
            fragment: #F6
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F5
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F7
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
  extensionTypes
    isSimplyBounded extension type B
      reference: <testLibrary>::@extensionType::B
      firstFragment: #F8
      representation: <testLibrary>::@extensionType::B::@field::it
      primaryConstructor: <testLibrary>::@extensionType::B::@constructor::new
      typeErasure: int
      fields
        isFinal isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::B::@field::it
          firstFragment: #F9
          type: int
          getter: <testLibrary>::@extensionType::B::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::B::@constructor::new::@formalParameter::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::B::@getter::it
          firstFragment: #F10
          returnType: int
          variable: <testLibrary>::@extensionType::B::@field::it
''');
  }

  test_enum_interfaces_generic() async {
    var library = await buildLibrary(r'''
class I<T> {}

enum E<U> implements I<U> { v }
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
            #F2 T (nameOffset:8) (firstTokenOffset:8) (offset:8)
              element: #E0 T
          constructors
            #F3 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::I::@constructor::new
              typeName: I
      enums
        #F4 enum E (nameOffset:20) (firstTokenOffset:15) (offset:20)
          element: <testLibrary>::@enum::E
          typeParameters
            #F5 U (nameOffset:22) (firstTokenOffset:22) (offset:22)
              element: #E1 U
          fields
            #F6 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:43) (firstTokenOffset:43) (offset:43)
              element: <testLibrary>::@enum::E::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibrary>::@enum::E
                      type: E<dynamic>
                    element: SubstitutedConstructorElementImpl
                      baseElement: <testLibrary>::@enum::E::@constructor::new
                      substitution: {U: dynamic}
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E<dynamic>
              inducedGetter: #F7
            #F8 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:20)
              element: <testLibrary>::@enum::E::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::E::@getter::v
                      staticType: E<dynamic>
                  rightBracket: ] @0
                  staticType: List<E<dynamic>>
              inducedGetter: #F9
          constructors
            #F10 isConst isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:20)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F7 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:43)
              element: <testLibrary>::@enum::E::@getter::v
              inducingVariable: #F6
            #F9 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:20)
              element: <testLibrary>::@enum::E::@getter::values
              inducingVariable: #F8
  classes
    isSimplyBounded class I
      reference: <testLibrary>::@class::I
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      constructors
        hasEnclosingTypeParameterReference isOriginImplicitDefault new
          reference: <testLibrary>::@class::I::@constructor::new
          firstFragment: #F3
  enums
    isSimplyBounded enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F4
      typeParameters
        #E1 U
          firstFragment: #F5
      supertype: Enum
      interfaces
        I<U>
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F6
          type: E<dynamic>
          constantInitializer
            fragment: #F6
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F8
          type: List<E<dynamic>>
          constantInitializer
            fragment: #F8
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        hasEnclosingTypeParameterReference isConst isOriginImplicitDefault new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F10
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F7
          returnType: E<dynamic>
          variable: <testLibrary>::@enum::E::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F9
          returnType: List<E<dynamic>>
          variable: <testLibrary>::@enum::E::@field::values
''');
  }

  test_enum_interfaces_unresolved() async {
    var library = await buildLibrary(r'''
class X {}

class Z {}

enum E implements X, Y, Z { v }
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class X (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::X
          constructors
            #F2 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::X::@constructor::new
              typeName: X
        #F3 class Z (nameOffset:18) (firstTokenOffset:12) (offset:18)
          element: <testLibrary>::@class::Z
          constructors
            #F4 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:18)
              element: <testLibrary>::@class::Z::@constructor::new
              typeName: Z
      enums
        #F5 enum E (nameOffset:29) (firstTokenOffset:24) (offset:29)
          element: <testLibrary>::@enum::E
          fields
            #F6 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:52) (firstTokenOffset:52) (offset:52)
              element: <testLibrary>::@enum::E::@field::v
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
              inducedGetter: #F7
            #F8 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:29)
              element: <testLibrary>::@enum::E::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::E::@getter::v
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
              inducedGetter: #F9
          constructors
            #F10 isConst isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:29)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F7 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:52)
              element: <testLibrary>::@enum::E::@getter::v
              inducingVariable: #F6
            #F9 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:29)
              element: <testLibrary>::@enum::E::@getter::values
              inducingVariable: #F8
  classes
    isSimplyBounded class X
      reference: <testLibrary>::@class::X
      firstFragment: #F1
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::X::@constructor::new
          firstFragment: #F2
    isSimplyBounded class Z
      reference: <testLibrary>::@class::Z
      firstFragment: #F3
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::Z::@constructor::new
          firstFragment: #F4
  enums
    isSimplyBounded enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F5
      supertype: Enum
      interfaces
        X
        Z
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F6
          type: E
          constantInitializer
            fragment: #F6
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F8
          type: List<E>
          constantInitializer
            fragment: #F8
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        isConst isOriginImplicitDefault new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F10
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F7
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F9
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
''');
  }

  test_enum_lazy_all_constructors() async {
    var library = await buildLibrary(r'''
enum E {
  v.foo();

  const E.foo();
}
''');

    var constructors = library.getEnum('E')!.constructors;
    expect(constructors, hasLength(1));
  }

  test_enum_lazy_all_fields() async {
    var library = await buildLibrary(r'''
enum E {
  v;

  final foo = 42;
}
''');

    var fields = library.getEnum('E')!.fields;
    expect(fields, hasLength(3));
  }

  test_enum_lazy_all_getters() async {
    var library = await buildLibrary(r'''
enum E {
  v;

  int get foo => 0;
}
''');

    var getters = library.getEnum('E')!.getters;
    expect(getters, hasLength(3));
  }

  test_enum_lazy_all_methods() async {
    var library = await buildLibrary(r'''
enum E {
  v;

  void foo() {}
}
''');

    var methods = library.getEnum('E')!.methods;
    expect(methods, hasLength(1));
  }

  test_enum_lazy_all_setters() async {
    var library = await buildLibrary(r'''
enum E {
  v;

  set foo(int _) {}
}
''');

    var setters = library.getEnum('E')!.setters;
    expect(setters, hasLength(1));
  }

  test_enum_lazy_byReference_constructor() async {
    var library = await buildLibrary(r'''
enum E {
  v.foo();

  const E.foo();
}
''');
    // Test ensureReadMembers() in LinkedElementFactory.
    var E = library.getEnum('E')!;
    var foo = getConstructorElementOfReference(E, 'foo');
    expect(foo.name, 'foo');
  }

  test_enum_lazy_byReference_field() async {
    var library = await buildLibrary(r'''
enum E {
  v;

  final foo = 42;
}
''');
    // Test ensureReadMembers() in LinkedElementFactory.
    var E = library.getEnum('E')!;
    var foo = getFieldElementOfReference(E, 'foo');
    expect(foo.name, 'foo');
  }

  test_enum_lazy_byReference_getter() async {
    var library = await buildLibrary(r'''
enum E {
  v;

  int get foo => 0;
}
''');
    // Test ensureReadMembers() in LinkedElementFactory.
    var E = library.getEnum('E')!;
    var foo = getGetterElementOfReference(E, 'foo');
    expect(foo.name, 'foo');
  }

  test_enum_lazy_byReference_method() async {
    var library = await buildLibrary(r'''
enum E {
  v;

  void foo() {}
}
''');
    // Test ensureReadMembers() in LinkedElementFactory.
    var E = library.getEnum('E')!;
    var foo = getMethodElementOfReference(E, 'foo');
    expect(foo.name, 'foo');
  }

  test_enum_lazy_byReference_setter() async {
    var library = await buildLibrary(r'''
enum E {
  v;

  set foo(int _) {}
}
''');
    // Test ensureReadMembers() in LinkedElementFactory.
    var E = library.getEnum('E')!;
    var foo = getSetterElementOfReference(E, 'foo');
    expect(foo.name, 'foo');
  }

  test_enum_metadata() async {
    var library = await buildLibrary(r'''
const a = 42;

@a
enum E { v }
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      enums
        #F1 enum E (nameOffset:23) (firstTokenOffset:15) (offset:23)
          element: <testLibrary>::@enum::E
          fields
            #F2 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:27) (firstTokenOffset:27) (offset:27)
              element: <testLibrary>::@enum::E::@field::v
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
              inducedGetter: #F3
            #F4 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
              element: <testLibrary>::@enum::E::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::E::@getter::v
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
              inducedGetter: #F5
          constructors
            #F6 isConst isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F3 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:27)
              element: <testLibrary>::@enum::E::@getter::v
              inducingVariable: #F2
            #F5 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
              element: <testLibrary>::@enum::E::@getter::values
              inducingVariable: #F4
      topLevelVariables
        #F7 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic a (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::a
          initializer: expression_2
            IntegerLiteral
              literal: 42 @10
              staticType: int
          inducedGetter: #F8
      getters
        #F8 isComplete isOriginVariable isStatic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
          inducingVariable: #F7
  enums
    isSimplyBounded enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F4
          type: List<E>
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        isConst isOriginImplicitDefault new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F6
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F3
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F5
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
  topLevelVariables
    hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F7
      type: int
      constantInitializer
        fragment: #F7
        expression: expression_2
      getter: <testLibrary>::@getter::a
  getters
    isOriginVariable isStatic a
      reference: <testLibrary>::@getter::a
      firstFragment: #F8
      returnType: int
      variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_enum_metadata_scope() async {
    var library = await buildLibrary(r'''
const foo = 0;

@foo
enum E<@foo T> {
  v;

  static const foo = 1;
  @foo
  void bar() {}
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      enums
        #F1 enum E (nameOffset:26) (firstTokenOffset:16) (offset:26)
          element: <testLibrary>::@enum::E
          typeParameters
            #F2 T (nameOffset:33) (firstTokenOffset:28) (offset:33)
              element: #E0 T
              metadata
                Annotation
                  atSign: @ @28
                  name: SimpleIdentifier
                    token: foo @29
                    element: <testLibrary>::@getter::foo
                    staticType: null
                  element: <testLibrary>::@getter::foo
          fields
            #F3 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:40) (firstTokenOffset:40) (offset:40)
              element: <testLibrary>::@enum::E::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibrary>::@enum::E
                      type: E<dynamic>
                    element: SubstitutedConstructorElementImpl
                      baseElement: <testLibrary>::@enum::E::@constructor::new
                      substitution: {T: dynamic}
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E<dynamic>
              inducedGetter: #F4
            #F5 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:26)
              element: <testLibrary>::@enum::E::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::E::@getter::v
                      staticType: E<dynamic>
                  rightBracket: ] @0
                  staticType: List<E<dynamic>>
              inducedGetter: #F6
            #F7 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic foo (nameOffset:59) (firstTokenOffset:59) (offset:59)
              element: <testLibrary>::@enum::E::@field::foo
              initializer: expression_2
                IntegerLiteral
                  literal: 1 @65
                  staticType: int
              inducedGetter: #F8
          constructors
            #F9 isConst isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:26)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F4 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
              element: <testLibrary>::@enum::E::@getter::v
              inducingVariable: #F3
            #F6 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:26)
              element: <testLibrary>::@enum::E::@getter::values
              inducingVariable: #F5
            #F8 isComplete isOriginVariable isStatic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:59)
              element: <testLibrary>::@enum::E::@getter::foo
              inducingVariable: #F7
          methods
            #F10 isComplete isOriginDeclaration bar (nameOffset:82) (firstTokenOffset:70) (offset:82)
              element: <testLibrary>::@enum::E::@method::bar
              metadata
                Annotation
                  atSign: @ @70
                  name: SimpleIdentifier
                    token: foo @71
                    element: <testLibrary>::@enum::E::@getter::foo
                    staticType: null
                  element: <testLibrary>::@enum::E::@getter::foo
      topLevelVariables
        #F11 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic foo (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::foo
          initializer: expression_3
            IntegerLiteral
              literal: 0 @12
              staticType: int
          inducedGetter: #F12
      getters
        #F12 isComplete isOriginVariable isStatic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::foo
          inducingVariable: #F11
  enums
    isSimplyBounded enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
          metadata
            Annotation
              atSign: @ @28
              name: SimpleIdentifier
                token: foo @29
                element: <testLibrary>::@getter::foo
                staticType: null
              element: <testLibrary>::@getter::foo
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F3
          type: E<dynamic>
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F5
          type: List<E<dynamic>>
          constantInitializer
            fragment: #F5
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
        hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer foo
          reference: <testLibrary>::@enum::E::@field::foo
          firstFragment: #F7
          type: int
          constantInitializer
            fragment: #F7
            expression: expression_2
          getter: <testLibrary>::@enum::E::@getter::foo
      constructors
        hasEnclosingTypeParameterReference isConst isOriginImplicitDefault new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F9
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F4
          returnType: E<dynamic>
          variable: <testLibrary>::@enum::E::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F6
          returnType: List<E<dynamic>>
          variable: <testLibrary>::@enum::E::@field::values
        isOriginVariable isStatic foo
          reference: <testLibrary>::@enum::E::@getter::foo
          firstFragment: #F8
          returnType: int
          variable: <testLibrary>::@enum::E::@field::foo
      methods
        isOriginDeclaration bar
          reference: <testLibrary>::@enum::E::@method::bar
          firstFragment: #F10
          metadata
            Annotation
              atSign: @ @70
              name: SimpleIdentifier
                token: foo @71
                element: <testLibrary>::@enum::E::@getter::foo
                staticType: null
              element: <testLibrary>::@enum::E::@getter::foo
          returnType: void
  topLevelVariables
    hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: #F11
      type: int
      constantInitializer
        fragment: #F11
        expression: expression_3
      getter: <testLibrary>::@getter::foo
  getters
    isOriginVariable isStatic foo
      reference: <testLibrary>::@getter::foo
      firstFragment: #F12
      returnType: int
      variable: <testLibrary>::@topLevelVariable::foo
''');
  }

  test_enum_missingName() async {
    var library = await buildLibrary(r'''
enum {
  v
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      enums
        #F1 enum <null-name> (nameOffset:<null>) (firstTokenOffset:0) (offset:0)
          element: <testLibrary>::@enum::#0
          fields
            #F2 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:9) (firstTokenOffset:9) (offset:9)
              element: <testLibrary>::@enum::#0::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: <empty> @-1 <synthetic>
                      element: <null>
                      type: InvalidType
                    element: <null>
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: InvalidType
              inducedGetter: #F3
            #F4 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:0)
              element: <testLibrary>::@enum::#0::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::#0::@getter::v
                      staticType: InvalidType
                  rightBracket: ] @0
                  staticType: List<<null>>
              inducedGetter: #F5
          constructors
            #F6 isConst isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:0)
              element: <testLibrary>::@enum::#0::@constructor::new
              typeName: null
          getters
            #F3 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:9)
              element: <testLibrary>::@enum::#0::@getter::v
              inducingVariable: #F2
            #F5 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:0)
              element: <testLibrary>::@enum::#0::@getter::values
              inducingVariable: #F4
  enums
    isSimplyBounded enum <null-name>
      reference: <testLibrary>::@enum::#0
      firstFragment: #F1
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::#0::@field::v
          firstFragment: #F2
          type: InvalidType
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::#0::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::#0::@field::values
          firstFragment: #F4
          type: List<<null>>
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::#0::@getter::values
      constructors
        isConst isOriginImplicitDefault new
          reference: <testLibrary>::@enum::#0::@constructor::new
          firstFragment: #F6
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::#0::@getter::v
          firstFragment: #F3
          returnType: InvalidType
          variable: <testLibrary>::@enum::#0::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::#0::@getter::values
          firstFragment: #F5
          returnType: List<<null>>
          variable: <testLibrary>::@enum::#0::@field::values
''');
  }

  test_enum_mixins() async {
    var library = await buildLibrary(r'''
mixin M {}

enum E with M { v }
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      enums
        #F1 enum E (nameOffset:17) (firstTokenOffset:12) (offset:17)
          element: <testLibrary>::@enum::E
          fields
            #F2 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:28) (firstTokenOffset:28) (offset:28)
              element: <testLibrary>::@enum::E::@field::v
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
              inducedGetter: #F3
            #F4 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:17)
              element: <testLibrary>::@enum::E::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::E::@getter::v
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
              inducedGetter: #F5
          constructors
            #F6 isConst isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:17)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F3 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:28)
              element: <testLibrary>::@enum::E::@getter::v
              inducingVariable: #F2
            #F5 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:17)
              element: <testLibrary>::@enum::E::@getter::values
              inducingVariable: #F4
      mixins
        #F7 mixin M (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@mixin::M
  enums
    isSimplyBounded enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      mixins
        M
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F4
          type: List<E>
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        isConst isOriginImplicitDefault new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F6
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F3
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F5
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
  mixins
    isSimplyBounded mixin M
      reference: <testLibrary>::@mixin::M
      firstFragment: #F7
      superclassConstraints
        Object
''');
  }

  test_enum_mixins_augmentation_add() async {
    var library = await buildLibrary(r'''
enum A with M1 {
  v
}
mixin M1 {}

augment enum A with M2 {}
mixin M2 {}
''');

    configuration.withConstantInitializers = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      enums
        #F1 enum A (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@enum::A
          nextFragment: #F2
          fields
            #F3 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:19) (firstTokenOffset:19) (offset:19)
              element: <testLibrary>::@enum::A::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibrary>::@enum::A
                      type: A
                    element: <testLibrary>::@enum::A::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              inducedGetter: #F4
            #F5 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::A::@getter::v
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
              inducedGetter: #F6
          constructors
            #F7 isConst isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
          getters
            #F4 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:19)
              element: <testLibrary>::@enum::A::@getter::v
              inducingVariable: #F3
            #F6 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
              inducingVariable: #F5
        #F2 isAugmentation enum A (nameOffset:49) (firstTokenOffset:36) (offset:49)
          element: <testLibrary>::@enum::A
          previousFragment: #F1
          withClauseMixinStartIndex: 1
      mixins
        #F8 mixin M1 (nameOffset:29) (firstTokenOffset:23) (offset:29)
          element: <testLibrary>::@mixin::M1
        #F9 mixin M2 (nameOffset:68) (firstTokenOffset:62) (offset:68)
          element: <testLibrary>::@mixin::M2
  enums
    isSimplyBounded enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      supertype: Enum
      mixins
        M1
        M2
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F3
          type: A
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F5
          type: List<A>
          constantInitializer
            fragment: #F5
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
      constructors
        isConst isOriginImplicitDefault new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F7
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F4
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F6
          returnType: List<A>
          variable: <testLibrary>::@enum::A::@field::values
  mixins
    isSimplyBounded mixin M1
      reference: <testLibrary>::@mixin::M1
      firstFragment: #F8
      superclassConstraints
        Object
    isSimplyBounded mixin M2
      reference: <testLibrary>::@mixin::M2
      firstFragment: #F9
      superclassConstraints
        Object
''');
  }

  test_enum_mixins_augmentation_add_inferredTypeArguments() async {
    var library = await buildLibrary(r'''
enum A<T> with M1<T> {
  v<int>()
}
mixin M1<U1> {}

augment enum A<T> with M2 {}
mixin M2<U2> on M1<U2> {}

augment enum A<T> with M3 {}
mixin M3<U3> on M2<U3> {}
''');

    configuration.withConstantInitializers = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      enums
        #F1 enum A (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@enum::A
          nextFragment: #F2
          typeParameters
            #F3 T (nameOffset:7) (firstTokenOffset:7) (offset:7)
              element: #E0 T
              nextFragment: #F4
          fields
            #F5 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:25) (firstTokenOffset:25) (offset:25)
              element: <testLibrary>::@enum::A::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      typeArguments: TypeArgumentList
                        leftBracket: < @26
                        arguments
                          NamedType
                            name: int @27
                            element: dart:core::@class::int
                            type: int
                        rightBracket: > @30
                      element: <testLibrary>::@enum::A
                      type: A<int>
                    element: SubstitutedConstructorElementImpl
                      baseElement: <testLibrary>::@enum::A::@constructor::new
                      substitution: {T: int}
                  argumentList: ArgumentList
                    leftParenthesis: ( @31
                    rightParenthesis: ) @32
                  staticType: A<int>
              inducedGetter: #F6
            #F7 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::A::@getter::v
                      staticType: A<int>
                  rightBracket: ] @0
                  staticType: List<A<dynamic>>
              inducedGetter: #F8
          constructors
            #F9 isConst isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
          getters
            #F6 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
              element: <testLibrary>::@enum::A::@getter::v
              inducingVariable: #F5
            #F8 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
              inducingVariable: #F7
        #F2 isAugmentation enum A (nameOffset:66) (firstTokenOffset:53) (offset:66)
          element: <testLibrary>::@enum::A
          previousFragment: #F1
          nextFragment: #F10
          withClauseMixinStartIndex: 1
          typeParameters
            #F4 T (nameOffset:68) (firstTokenOffset:68) (offset:68)
              element: #E0 T
              previousFragment: #F3
              nextFragment: #F11
        #F10 isAugmentation enum A (nameOffset:122) (firstTokenOffset:109) (offset:122)
          element: <testLibrary>::@enum::A
          previousFragment: #F2
          withClauseMixinStartIndex: 2
          typeParameters
            #F11 T (nameOffset:124) (firstTokenOffset:124) (offset:124)
              element: #E0 T
              previousFragment: #F4
      mixins
        #F12 mixin M1 (nameOffset:42) (firstTokenOffset:36) (offset:42)
          element: <testLibrary>::@mixin::M1
          typeParameters
            #F13 U1 (nameOffset:45) (firstTokenOffset:45) (offset:45)
              element: #E1 U1
        #F14 mixin M2 (nameOffset:88) (firstTokenOffset:82) (offset:88)
          element: <testLibrary>::@mixin::M2
          typeParameters
            #F15 U2 (nameOffset:91) (firstTokenOffset:91) (offset:91)
              element: #E2 U2
        #F16 mixin M3 (nameOffset:144) (firstTokenOffset:138) (offset:144)
          element: <testLibrary>::@mixin::M3
          typeParameters
            #F17 U3 (nameOffset:147) (firstTokenOffset:147) (offset:147)
              element: #E3 U3
  enums
    isSimplyBounded enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F3
      supertype: Enum
      mixins
        M1<T>
        M2<T>
        M3<T>
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F5
          type: A<int>
          constantInitializer
            fragment: #F5
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F7
          type: List<A<dynamic>>
          constantInitializer
            fragment: #F7
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
      constructors
        hasEnclosingTypeParameterReference isConst isOriginImplicitDefault new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F9
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F6
          returnType: A<int>
          variable: <testLibrary>::@enum::A::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F8
          returnType: List<A<dynamic>>
          variable: <testLibrary>::@enum::A::@field::values
  mixins
    isSimplyBounded mixin M1
      reference: <testLibrary>::@mixin::M1
      firstFragment: #F12
      typeParameters
        #E1 U1
          firstFragment: #F13
      superclassConstraints
        Object
    isSimplyBounded mixin M2
      reference: <testLibrary>::@mixin::M2
      firstFragment: #F14
      typeParameters
        #E2 U2
          firstFragment: #F15
      superclassConstraints
        M1<U2>
    isSimplyBounded mixin M3
      reference: <testLibrary>::@mixin::M3
      firstFragment: #F16
      typeParameters
        #E3 U3
          firstFragment: #F17
      superclassConstraints
        M2<U3>
''');
  }

  test_enum_mixins_extensionType() async {
    var library = await buildLibrary(r'''
class A {}

extension type B(int it) {}

class C {}

enum E with A, B, C { v }
''');
    configuration
      ..withConstructors = false
      ..withConstantInitializers = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::A
        #F2 class C (nameOffset:47) (firstTokenOffset:41) (offset:47)
          element: <testLibrary>::@class::C
      enums
        #F3 enum E (nameOffset:58) (firstTokenOffset:53) (offset:58)
          element: <testLibrary>::@enum::E
          fields
            #F4 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:75) (firstTokenOffset:75) (offset:75)
              element: <testLibrary>::@enum::E::@field::v
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
              inducedGetter: #F5
            #F6 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:58)
              element: <testLibrary>::@enum::E::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::E::@getter::v
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
              inducedGetter: #F7
          getters
            #F5 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:75)
              element: <testLibrary>::@enum::E::@getter::v
              inducingVariable: #F4
            #F7 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:58)
              element: <testLibrary>::@enum::E::@getter::values
              inducingVariable: #F6
      extensionTypes
        #F8 extension type B (nameOffset:27) (firstTokenOffset:12) (offset:27)
          element: <testLibrary>::@extensionType::B
          fields
            #F9 isFinal isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:27)
              element: <testLibrary>::@extensionType::B::@field::it
              inducedGetter: #F10
          getters
            #F10 isComplete isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:27)
              element: <testLibrary>::@extensionType::B::@getter::it
              inducingVariable: #F9
  classes
    isSimplyBounded class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
    isSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F2
  enums
    isSimplyBounded enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F3
      supertype: Enum
      mixins
        A
        C
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F4
          type: E
          constantInitializer
            fragment: #F4
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F6
          type: List<E>
          constantInitializer
            fragment: #F6
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F5
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F7
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
  extensionTypes
    isSimplyBounded extension type B
      reference: <testLibrary>::@extensionType::B
      firstFragment: #F8
      representation: <testLibrary>::@extensionType::B::@field::it
      primaryConstructor: <testLibrary>::@extensionType::B::@constructor::new
      typeErasure: int
      fields
        isFinal isOriginDeclaringFormalParameter it
          reference: <testLibrary>::@extensionType::B::@field::it
          firstFragment: #F9
          type: int
          getter: <testLibrary>::@extensionType::B::@getter::it
          declaringFormalParameter: <testLibrary>::@extensionType::B::@constructor::new::@formalParameter::it
      getters
        isExtensionTypeMember isOriginVariable it
          reference: <testLibrary>::@extensionType::B::@getter::it
          firstFragment: #F10
          returnType: int
          variable: <testLibrary>::@extensionType::B::@field::it
''');
  }

  test_enum_mixins_inference() async {
    var library = await buildLibrary(r'''
mixin M1<T> {}

mixin M2<T> on M1<T> {}

enum E with M1<int>, M2 { v }
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      enums
        #F1 enum E (nameOffset:46) (firstTokenOffset:41) (offset:46)
          element: <testLibrary>::@enum::E
          fields
            #F2 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:67) (firstTokenOffset:67) (offset:67)
              element: <testLibrary>::@enum::E::@field::v
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
              inducedGetter: #F3
            #F4 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:46)
              element: <testLibrary>::@enum::E::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::E::@getter::v
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
              inducedGetter: #F5
          constructors
            #F6 isConst isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:46)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F3 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:67)
              element: <testLibrary>::@enum::E::@getter::v
              inducingVariable: #F2
            #F5 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:46)
              element: <testLibrary>::@enum::E::@getter::values
              inducingVariable: #F4
      mixins
        #F7 mixin M1 (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@mixin::M1
          typeParameters
            #F8 T (nameOffset:9) (firstTokenOffset:9) (offset:9)
              element: #E0 T
        #F9 mixin M2 (nameOffset:22) (firstTokenOffset:16) (offset:22)
          element: <testLibrary>::@mixin::M2
          typeParameters
            #F10 T (nameOffset:25) (firstTokenOffset:25) (offset:25)
              element: #E1 T
  enums
    isSimplyBounded enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      mixins
        M1<int>
        M2<int>
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F4
          type: List<E>
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        isConst isOriginImplicitDefault new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F6
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F3
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F5
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
  mixins
    isSimplyBounded mixin M1
      reference: <testLibrary>::@mixin::M1
      firstFragment: #F7
      typeParameters
        #E0 T
          firstFragment: #F8
      superclassConstraints
        Object
    isSimplyBounded mixin M2
      reference: <testLibrary>::@mixin::M2
      firstFragment: #F9
      typeParameters
        #E1 T
          firstFragment: #F10
      superclassConstraints
        M1<T>
''');
  }

  test_enum_noConstants_semicolon() async {
    var library = await buildLibrary(r'''
enum E {;}
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
            #F2 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@field::values
              initializer: expression_0
                ListLiteral
                  leftBracket: [ @0
                  rightBracket: ] @0
                  staticType: List<E>
              inducedGetter: #F3
          constructors
            #F4 isConst isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F3 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
              inducingVariable: #F2
  enums
    isSimplyBounded enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F2
          type: List<E>
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        isConst isOriginImplicitDefault new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F4
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F3
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
''');
  }

  test_enum_typeParameters() async {
    var library = await buildLibrary(r'''
enum E<T> { v }
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
          typeParameters
            #F2 T (nameOffset:7) (firstTokenOffset:7) (offset:7)
              element: #E0 T
          fields
            #F3 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:12) (firstTokenOffset:12) (offset:12)
              element: <testLibrary>::@enum::E::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibrary>::@enum::E
                      type: E<dynamic>
                    element: SubstitutedConstructorElementImpl
                      baseElement: <testLibrary>::@enum::E::@constructor::new
                      substitution: {T: dynamic}
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E<dynamic>
              inducedGetter: #F4
            #F5 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::E::@getter::v
                      staticType: E<dynamic>
                  rightBracket: ] @0
                  staticType: List<E<dynamic>>
              inducedGetter: #F6
          constructors
            #F7 isConst isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F4 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:12)
              element: <testLibrary>::@enum::E::@getter::v
              inducingVariable: #F3
            #F6 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
              inducingVariable: #F5
  enums
    isSimplyBounded enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F3
          type: E<dynamic>
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F5
          type: List<E<dynamic>>
          constantInitializer
            fragment: #F5
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        hasEnclosingTypeParameterReference isConst isOriginImplicitDefault new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F7
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F4
          returnType: E<dynamic>
          variable: <testLibrary>::@enum::E::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F6
          returnType: List<E<dynamic>>
          variable: <testLibrary>::@enum::E::@field::values
''');
  }

  test_enum_typeParameters_augmentation_chain_bounds_int_int() async {
    var library = await buildLibrary(r'''
enum A<T extends int> {
  v
}
augment enum A<T extends int> {}
''');

    configuration.withConstantInitializers = false;
    configuration.withDefaultType = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      enums
        #F1 enum A (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@enum::A
          nextFragment: #F2
          typeParameters
            #F3 T (nameOffset:7) (firstTokenOffset:7) (offset:7)
              element: #E0 T
              nextFragment: #F4
          fields
            #F5 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:26) (firstTokenOffset:26) (offset:26)
              element: <testLibrary>::@enum::A::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibrary>::@enum::A
                      type: A<int>
                    element: SubstitutedConstructorElementImpl
                      baseElement: <testLibrary>::@enum::A::@constructor::new
                      substitution: {T: int}
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A<int>
              inducedGetter: #F6
            #F7 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::A::@getter::v
                      staticType: A<int>
                  rightBracket: ] @0
                  staticType: List<A<int>>
              inducedGetter: #F8
          constructors
            #F9 isConst isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
          getters
            #F6 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:26)
              element: <testLibrary>::@enum::A::@getter::v
              inducingVariable: #F5
            #F8 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
              inducingVariable: #F7
        #F2 isAugmentation enum A (nameOffset:43) (firstTokenOffset:30) (offset:43)
          element: <testLibrary>::@enum::A
          previousFragment: #F1
          typeParameters
            #F4 T (nameOffset:45) (firstTokenOffset:45) (offset:45)
              element: #E0 T
              previousFragment: #F3
  enums
    isSimplyBounded enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F3
          bound: int
          defaultType: int
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F5
          type: A<int>
          constantInitializer
            fragment: #F5
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F7
          type: List<A<int>>
          constantInitializer
            fragment: #F7
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
      constructors
        hasEnclosingTypeParameterReference isConst isOriginImplicitDefault new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F9
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F6
          returnType: A<int>
          variable: <testLibrary>::@enum::A::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F8
          returnType: List<A<int>>
          variable: <testLibrary>::@enum::A::@field::values
''');
  }

  test_enum_typeParameters_augmentation_chain_bounds_int_string() async {
    var library = await buildLibrary(r'''
enum A<T extends int> {
  v
}
augment enum A<T extends String> {}
''');

    configuration.withConstantInitializers = false;
    configuration.withDefaultType = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      enums
        #F1 enum A (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@enum::A
          nextFragment: #F2
          typeParameters
            #F3 T (nameOffset:7) (firstTokenOffset:7) (offset:7)
              element: #E0 T
              nextFragment: #F4
          fields
            #F5 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:26) (firstTokenOffset:26) (offset:26)
              element: <testLibrary>::@enum::A::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibrary>::@enum::A
                      type: A<int>
                    element: SubstitutedConstructorElementImpl
                      baseElement: <testLibrary>::@enum::A::@constructor::new
                      substitution: {T: int}
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A<int>
              inducedGetter: #F6
            #F7 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::A::@getter::v
                      staticType: A<int>
                  rightBracket: ] @0
                  staticType: List<A<int>>
              inducedGetter: #F8
          constructors
            #F9 isConst isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
          getters
            #F6 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:26)
              element: <testLibrary>::@enum::A::@getter::v
              inducingVariable: #F5
            #F8 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
              inducingVariable: #F7
        #F2 isAugmentation enum A (nameOffset:43) (firstTokenOffset:30) (offset:43)
          element: <testLibrary>::@enum::A
          previousFragment: #F1
          typeParameters
            #F4 T (nameOffset:45) (firstTokenOffset:45) (offset:45)
              element: #E0 T
              previousFragment: #F3
  enums
    isSimplyBounded enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F3
          bound: int
          defaultType: int
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F5
          type: A<int>
          constantInitializer
            fragment: #F5
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F7
          type: List<A<int>>
          constantInitializer
            fragment: #F7
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
      constructors
        hasEnclosingTypeParameterReference isConst isOriginImplicitDefault new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F9
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F6
          returnType: A<int>
          variable: <testLibrary>::@enum::A::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F8
          returnType: List<A<int>>
          variable: <testLibrary>::@enum::A::@field::values
''');
  }

  test_enum_typeParameters_augmentation_chain_count_112() async {
    var library = await buildLibrary(r'''
enum E<T> { v }
augment enum E<T> {}
augment enum E<T, U> {}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      enums
        #F1 enum E (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@enum::E
          nextFragment: #F2
          typeParameters
            #F3 T (nameOffset:7) (firstTokenOffset:7) (offset:7)
              element: #E0 T
              nextFragment: #F4
            #F5 isOriginOtherFragmentOfEnclosing U (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: #E1 U
              nextFragment: #F6
          fields
            #F7 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:12) (firstTokenOffset:12) (offset:12)
              element: <testLibrary>::@enum::E::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibrary>::@enum::E
                      type: E<dynamic>
                    element: SubstitutedConstructorElementImpl
                      baseElement: <testLibrary>::@enum::E::@constructor::new
                      substitution: {T: dynamic}
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E<dynamic>
              inducedGetter: #F8
            #F9 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::E::@getter::v
                      staticType: E<dynamic>
                  rightBracket: ] @0
                  staticType: List<E<dynamic>>
              inducedGetter: #F10
          getters
            #F8 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:12)
              element: <testLibrary>::@enum::E::@getter::v
              inducingVariable: #F7
            #F10 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
              inducingVariable: #F9
        #F2 isAugmentation enum E (nameOffset:29) (firstTokenOffset:16) (offset:29)
          element: <testLibrary>::@enum::E
          previousFragment: #F1
          nextFragment: #F11
          typeParameters
            #F4 T (nameOffset:31) (firstTokenOffset:31) (offset:31)
              element: #E0 T
              previousFragment: #F3
              nextFragment: #F12
            #F6 isOriginOtherFragmentOfEnclosing U (nameOffset:<null>) (firstTokenOffset:<null>) (offset:29)
              element: #E1 U
              previousFragment: #F5
              nextFragment: #F13
        #F11 isAugmentation enum E (nameOffset:50) (firstTokenOffset:37) (offset:50)
          element: <testLibrary>::@enum::E
          previousFragment: #F2
          typeParameters
            #F12 T (nameOffset:52) (firstTokenOffset:52) (offset:52)
              element: #E0 T
              previousFragment: #F4
            #F13 U (nameOffset:55) (firstTokenOffset:55) (offset:55)
              element: #E1 U
              previousFragment: #F6
  enums
    isSimplyBounded enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F3
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F7
          type: E<dynamic>
          constantInitializer
            fragment: #F7
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F9
          type: List<E<dynamic>>
          constantInitializer
            fragment: #F9
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F8
          returnType: E<dynamic>
          variable: <testLibrary>::@enum::E::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F10
          returnType: List<E<dynamic>>
          variable: <testLibrary>::@enum::E::@field::values
''');
  }

  test_enum_typeParameters_augmentation_chain_count_123() async {
    var library = await buildLibrary(r'''
enum E<T> { v }
augment enum E<T, U> {}
augment enum E<T, U, V> {}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      enums
        #F1 enum E (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@enum::E
          nextFragment: #F2
          typeParameters
            #F3 T (nameOffset:7) (firstTokenOffset:7) (offset:7)
              element: #E0 T
              nextFragment: #F4
            #F5 isOriginOtherFragmentOfEnclosing U (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: #E1 U
              nextFragment: #F6
            #F7 isOriginOtherFragmentOfEnclosing V (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: #E2 V
              nextFragment: #F8
          fields
            #F9 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:12) (firstTokenOffset:12) (offset:12)
              element: <testLibrary>::@enum::E::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibrary>::@enum::E
                      type: E<dynamic>
                    element: SubstitutedConstructorElementImpl
                      baseElement: <testLibrary>::@enum::E::@constructor::new
                      substitution: {T: dynamic}
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E<dynamic>
              inducedGetter: #F10
            #F11 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::E::@getter::v
                      staticType: E<dynamic>
                  rightBracket: ] @0
                  staticType: List<E<dynamic>>
              inducedGetter: #F12
          getters
            #F10 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:12)
              element: <testLibrary>::@enum::E::@getter::v
              inducingVariable: #F9
            #F12 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
              inducingVariable: #F11
        #F2 isAugmentation enum E (nameOffset:29) (firstTokenOffset:16) (offset:29)
          element: <testLibrary>::@enum::E
          previousFragment: #F1
          nextFragment: #F13
          typeParameters
            #F4 T (nameOffset:31) (firstTokenOffset:31) (offset:31)
              element: #E0 T
              previousFragment: #F3
              nextFragment: #F14
            #F6 U (nameOffset:34) (firstTokenOffset:34) (offset:34)
              element: #E1 U
              previousFragment: #F5
              nextFragment: #F15
            #F8 isOriginOtherFragmentOfEnclosing V (nameOffset:<null>) (firstTokenOffset:<null>) (offset:29)
              element: #E2 V
              previousFragment: #F7
              nextFragment: #F16
        #F13 isAugmentation enum E (nameOffset:53) (firstTokenOffset:40) (offset:53)
          element: <testLibrary>::@enum::E
          previousFragment: #F2
          typeParameters
            #F14 T (nameOffset:55) (firstTokenOffset:55) (offset:55)
              element: #E0 T
              previousFragment: #F4
            #F15 U (nameOffset:58) (firstTokenOffset:58) (offset:58)
              element: #E1 U
              previousFragment: #F6
            #F16 V (nameOffset:61) (firstTokenOffset:61) (offset:61)
              element: #E2 V
              previousFragment: #F8
  enums
    isSimplyBounded enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F3
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F9
          type: E<dynamic>
          constantInitializer
            fragment: #F9
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F11
          type: List<E<dynamic>>
          constantInitializer
            fragment: #F11
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F10
          returnType: E<dynamic>
          variable: <testLibrary>::@enum::E::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F12
          returnType: List<E<dynamic>>
          variable: <testLibrary>::@enum::E::@field::values
''');
  }

  test_enum_typeParameters_augmentation_chain_count_211() async {
    var library = await buildLibrary(r'''
enum E<T, U> { v }
augment enum E<T> {}
augment enum E<T> {}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      enums
        #F1 enum E (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@enum::E
          nextFragment: #F2
          typeParameters
            #F3 T (nameOffset:7) (firstTokenOffset:7) (offset:7)
              element: #E0 T
              nextFragment: #F4
            #F5 U (nameOffset:10) (firstTokenOffset:10) (offset:10)
              element: #E1 U
              nextFragment: #F6
          fields
            #F7 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:15) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@enum::E::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibrary>::@enum::E
                      type: E<dynamic, dynamic>
                    element: SubstitutedConstructorElementImpl
                      baseElement: <testLibrary>::@enum::E::@constructor::new
                      substitution: {T: dynamic, U: dynamic}
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E<dynamic, dynamic>
              inducedGetter: #F8
            #F9 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::E::@getter::v
                      staticType: E<dynamic, dynamic>
                  rightBracket: ] @0
                  staticType: List<E<dynamic, dynamic>>
              inducedGetter: #F10
          getters
            #F8 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@enum::E::@getter::v
              inducingVariable: #F7
            #F10 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
              inducingVariable: #F9
        #F2 isAugmentation enum E (nameOffset:32) (firstTokenOffset:19) (offset:32)
          element: <testLibrary>::@enum::E
          previousFragment: #F1
          nextFragment: #F11
          typeParameters
            #F4 T (nameOffset:34) (firstTokenOffset:34) (offset:34)
              element: #E0 T
              previousFragment: #F3
              nextFragment: #F12
            #F6 isOriginOtherFragmentOfEnclosing U (nameOffset:<null>) (firstTokenOffset:<null>) (offset:32)
              element: #E1 U
              previousFragment: #F5
              nextFragment: #F13
        #F11 isAugmentation enum E (nameOffset:53) (firstTokenOffset:40) (offset:53)
          element: <testLibrary>::@enum::E
          previousFragment: #F2
          typeParameters
            #F12 T (nameOffset:55) (firstTokenOffset:55) (offset:55)
              element: #E0 T
              previousFragment: #F4
            #F13 isOriginOtherFragmentOfEnclosing U (nameOffset:<null>) (firstTokenOffset:<null>) (offset:53)
              element: #E1 U
              previousFragment: #F6
  enums
    isSimplyBounded enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F3
        #E1 U
          firstFragment: #F5
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F7
          type: E<dynamic, dynamic>
          constantInitializer
            fragment: #F7
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F9
          type: List<E<dynamic, dynamic>>
          constantInitializer
            fragment: #F9
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F8
          returnType: E<dynamic, dynamic>
          variable: <testLibrary>::@enum::E::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F10
          returnType: List<E<dynamic, dynamic>>
          variable: <testLibrary>::@enum::E::@field::values
''');
  }

  test_enum_typeParameters_bound() async {
    var library = await buildLibrary(r'''
enum E<T extends num, U extends T> { v }
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
          typeParameters
            #F2 T (nameOffset:7) (firstTokenOffset:7) (offset:7)
              element: #E0 T
            #F3 U (nameOffset:22) (firstTokenOffset:22) (offset:22)
              element: #E1 U
          fields
            #F4 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:37) (firstTokenOffset:37) (offset:37)
              element: <testLibrary>::@enum::E::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibrary>::@enum::E
                      type: E<num, num>
                    element: SubstitutedConstructorElementImpl
                      baseElement: <testLibrary>::@enum::E::@constructor::new
                      substitution: {T: num, U: num}
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E<num, num>
              inducedGetter: #F5
            #F6 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::E::@getter::v
                      staticType: E<num, num>
                  rightBracket: ] @0
                  staticType: List<E<num, num>>
              inducedGetter: #F7
          constructors
            #F8 isConst isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F5 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:37)
              element: <testLibrary>::@enum::E::@getter::v
              inducingVariable: #F4
            #F7 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
              inducingVariable: #F6
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
          bound: num
        #E1 U
          firstFragment: #F3
          bound: T
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F4
          type: E<num, num>
          constantInitializer
            fragment: #F4
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F6
          type: List<E<num, num>>
          constantInitializer
            fragment: #F6
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        hasEnclosingTypeParameterReference isConst isOriginImplicitDefault new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F8
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F5
          returnType: E<num, num>
          variable: <testLibrary>::@enum::E::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F7
          returnType: List<E<num, num>>
          variable: <testLibrary>::@enum::E::@field::values
''');
  }

  test_enum_typeParameters_cycle_1of1() async {
    var library = await buildLibrary(r'''
enum E<T extends T> {}
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
          typeParameters
            #F2 T (nameOffset:7) (firstTokenOffset:7) (offset:7)
              element: #E0 T
          fields
            #F3 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@field::values
              initializer: expression_0
                ListLiteral
                  leftBracket: [ @0
                  rightBracket: ] @0
                  staticType: List<E<dynamic>>
              inducedGetter: #F4
          constructors
            #F5 isConst isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F4 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
              inducingVariable: #F3
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
          bound: dynamic
      supertype: Enum
      fields
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F3
          type: List<E<dynamic>>
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        hasEnclosingTypeParameterReference isConst isOriginImplicitDefault new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F5
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F4
          returnType: List<E<dynamic>>
          variable: <testLibrary>::@enum::E::@field::values
''');
  }

  test_enum_typeParameters_cycle_2of3() async {
    var library = await buildLibrary(r'''
enum E<T extends V, U extends num, V extends T> {}
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
          typeParameters
            #F2 T (nameOffset:7) (firstTokenOffset:7) (offset:7)
              element: #E0 T
            #F3 U (nameOffset:20) (firstTokenOffset:20) (offset:20)
              element: #E1 U
            #F4 V (nameOffset:35) (firstTokenOffset:35) (offset:35)
              element: #E2 V
          fields
            #F5 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@field::values
              initializer: expression_0
                ListLiteral
                  leftBracket: [ @0
                  rightBracket: ] @0
                  staticType: List<E<dynamic, num, dynamic>>
              inducedGetter: #F6
          constructors
            #F7 isConst isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F6 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
              inducingVariable: #F5
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
          bound: dynamic
        #E1 U
          firstFragment: #F3
          bound: num
        #E2 V
          firstFragment: #F4
          bound: dynamic
      supertype: Enum
      fields
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F5
          type: List<E<dynamic, num, dynamic>>
          constantInitializer
            fragment: #F5
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        hasEnclosingTypeParameterReference isConst isOriginImplicitDefault new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F7
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F6
          returnType: List<E<dynamic, num, dynamic>>
          variable: <testLibrary>::@enum::E::@field::values
''');
  }

  test_enum_typeParameters_defaultType_cycle_genericFunctionType() async {
    var library = await buildLibrary(r'''
enum E<T extends void Function(E)> {}
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
          typeParameters
            #F2 T (nameOffset:7) (firstTokenOffset:7) (offset:7)
              element: #E0 T
          fields
            #F3 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@field::values
              initializer: expression_0
                ListLiteral
                  leftBracket: [ @0
                  rightBracket: ] @0
                  staticType: List<E<dynamic>>
              inducedGetter: #F4
          constructors
            #F5 isConst isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F4 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
              inducingVariable: #F3
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
          bound: void Function(E<dynamic>)
      supertype: Enum
      fields
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F3
          type: List<E<dynamic>>
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        hasEnclosingTypeParameterReference isConst isOriginImplicitDefault new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F5
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F4
          returnType: List<E<dynamic>>
          variable: <testLibrary>::@enum::E::@field::values
''');
  }

  test_enum_typeParameters_metadata() async {
    var library = await buildLibrary(r'''
const a = 42;

enum E<@a T> { v }
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      enums
        #F1 enum E (nameOffset:20) (firstTokenOffset:15) (offset:20)
          element: <testLibrary>::@enum::E
          typeParameters
            #F2 T (nameOffset:25) (firstTokenOffset:22) (offset:25)
              element: #E0 T
              metadata
                Annotation
                  atSign: @ @22
                  name: SimpleIdentifier
                    token: a @23
                    element: <testLibrary>::@getter::a
                    staticType: null
                  element: <testLibrary>::@getter::a
          fields
            #F3 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:30) (firstTokenOffset:30) (offset:30)
              element: <testLibrary>::@enum::E::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibrary>::@enum::E
                      type: E<dynamic>
                    element: SubstitutedConstructorElementImpl
                      baseElement: <testLibrary>::@enum::E::@constructor::new
                      substitution: {T: dynamic}
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E<dynamic>
              inducedGetter: #F4
            #F5 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:20)
              element: <testLibrary>::@enum::E::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::E::@getter::v
                      staticType: E<dynamic>
                  rightBracket: ] @0
                  staticType: List<E<dynamic>>
              inducedGetter: #F6
          constructors
            #F7 isConst isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:20)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F4 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:30)
              element: <testLibrary>::@enum::E::@getter::v
              inducingVariable: #F3
            #F6 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:20)
              element: <testLibrary>::@enum::E::@getter::values
              inducingVariable: #F5
      topLevelVariables
        #F8 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic a (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::a
          initializer: expression_2
            IntegerLiteral
              literal: 42 @10
              staticType: int
          inducedGetter: #F9
      getters
        #F9 isComplete isOriginVariable isStatic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
          inducingVariable: #F8
  enums
    isSimplyBounded enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
          metadata
            Annotation
              atSign: @ @22
              name: SimpleIdentifier
                token: a @23
                element: <testLibrary>::@getter::a
                staticType: null
              element: <testLibrary>::@getter::a
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F3
          type: E<dynamic>
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F5
          type: List<E<dynamic>>
          constantInitializer
            fragment: #F5
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        hasEnclosingTypeParameterReference isConst isOriginImplicitDefault new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F7
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F4
          returnType: E<dynamic>
          variable: <testLibrary>::@enum::E::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F6
          returnType: List<E<dynamic>>
          variable: <testLibrary>::@enum::E::@field::values
  topLevelVariables
    hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F8
      type: int
      constantInitializer
        fragment: #F8
        expression: expression_2
      getter: <testLibrary>::@getter::a
  getters
    isOriginVariable isStatic a
      reference: <testLibrary>::@getter::a
      firstFragment: #F9
      returnType: int
      variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_enum_typeParameters_variance_contravariant() async {
    var library = await buildLibrary(r'''
enum E<in T> {}
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
          typeParameters
            #F2 T (nameOffset:10) (firstTokenOffset:7) (offset:10)
              element: #E0 T
          fields
            #F3 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@field::values
              initializer: expression_0
                ListLiteral
                  leftBracket: [ @0
                  rightBracket: ] @0
                  staticType: List<E<dynamic>>
              inducedGetter: #F4
          constructors
            #F5 isConst isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F4 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
              inducingVariable: #F3
  enums
    isSimplyBounded enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      supertype: Enum
      fields
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F3
          type: List<E<dynamic>>
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        hasEnclosingTypeParameterReference isConst isOriginImplicitDefault new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F5
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F4
          returnType: List<E<dynamic>>
          variable: <testLibrary>::@enum::E::@field::values
''');
  }

  test_enum_typeParameters_variance_covariant() async {
    var library = await buildLibrary(r'''
enum E<out T> {}
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
          typeParameters
            #F2 T (nameOffset:11) (firstTokenOffset:7) (offset:11)
              element: #E0 T
          fields
            #F3 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@field::values
              initializer: expression_0
                ListLiteral
                  leftBracket: [ @0
                  rightBracket: ] @0
                  staticType: List<E<dynamic>>
              inducedGetter: #F4
          constructors
            #F5 isConst isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F4 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
              inducingVariable: #F3
  enums
    isSimplyBounded enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      supertype: Enum
      fields
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F3
          type: List<E<dynamic>>
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        hasEnclosingTypeParameterReference isConst isOriginImplicitDefault new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F5
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F4
          returnType: List<E<dynamic>>
          variable: <testLibrary>::@enum::E::@field::values
''');
  }

  test_enum_typeParameters_variance_invariant() async {
    var library = await buildLibrary(r'''
enum E<inout T> {}
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
          typeParameters
            #F2 T (nameOffset:13) (firstTokenOffset:7) (offset:13)
              element: #E0 T
          fields
            #F3 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@field::values
              initializer: expression_0
                ListLiteral
                  leftBracket: [ @0
                  rightBracket: ] @0
                  staticType: List<E<dynamic>>
              inducedGetter: #F4
          constructors
            #F5 isConst isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F4 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
              inducingVariable: #F3
  enums
    isSimplyBounded enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      supertype: Enum
      fields
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F3
          type: List<E<dynamic>>
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        hasEnclosingTypeParameterReference isConst isOriginImplicitDefault new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F5
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F4
          returnType: List<E<dynamic>>
          variable: <testLibrary>::@enum::E::@field::values
''');
  }

  test_enum_typeParameters_variance_multiple() async {
    var library = await buildLibrary(r'''
enum E<inout T, in U, out V> {}
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
          typeParameters
            #F2 T (nameOffset:13) (firstTokenOffset:7) (offset:13)
              element: #E0 T
            #F3 U (nameOffset:19) (firstTokenOffset:16) (offset:19)
              element: #E1 U
            #F4 V (nameOffset:26) (firstTokenOffset:22) (offset:26)
              element: #E2 V
          fields
            #F5 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@field::values
              initializer: expression_0
                ListLiteral
                  leftBracket: [ @0
                  rightBracket: ] @0
                  staticType: List<E<dynamic, dynamic, dynamic>>
              inducedGetter: #F6
          constructors
            #F7 isConst isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F6 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
              inducingVariable: #F5
  enums
    isSimplyBounded enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
        #E1 U
          firstFragment: #F3
        #E2 V
          firstFragment: #F4
      supertype: Enum
      fields
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F5
          type: List<E<dynamic, dynamic, dynamic>>
          constantInitializer
            fragment: #F5
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        hasEnclosingTypeParameterReference isConst isOriginImplicitDefault new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F7
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F6
          returnType: List<E<dynamic, dynamic, dynamic>>
          variable: <testLibrary>::@enum::E::@field::values
''');
  }

  test_enum_values() async {
    var library = await buildLibrary(r'''
enum E { v1, v2 }
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
            #F2 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v1 (nameOffset:9) (firstTokenOffset:9) (offset:9)
              element: <testLibrary>::@enum::E::@field::v1
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
              inducedGetter: #F3
            #F4 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v2 (nameOffset:13) (firstTokenOffset:13) (offset:13)
              element: <testLibrary>::@enum::E::@field::v2
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
              inducedGetter: #F5
            #F6 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@field::values
              initializer: expression_2
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v1 @-1
                      element: <testLibrary>::@enum::E::@getter::v1
                      staticType: E
                    SimpleIdentifier
                      token: v2 @-1
                      element: <testLibrary>::@enum::E::@getter::v2
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
              inducedGetter: #F7
          constructors
            #F8 isConst isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F3 isComplete isOriginVariable isStatic v1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:9)
              element: <testLibrary>::@enum::E::@getter::v1
              inducingVariable: #F2
            #F5 isComplete isOriginVariable isStatic v2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:13)
              element: <testLibrary>::@enum::E::@getter::v2
              inducingVariable: #F4
            #F7 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
              inducingVariable: #F6
  enums
    isSimplyBounded enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v1
          reference: <testLibrary>::@enum::E::@field::v1
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v1
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v2
          reference: <testLibrary>::@enum::E::@field::v2
          firstFragment: #F4
          type: E
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::v2
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F6
          type: List<E>
          constantInitializer
            fragment: #F6
            expression: expression_2
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        isConst isOriginImplicitDefault new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F8
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v1
          reference: <testLibrary>::@enum::E::@getter::v1
          firstFragment: #F3
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v1
        isOriginVariable isStatic v2
          reference: <testLibrary>::@enum::E::@getter::v2
          firstFragment: #F5
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v2
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F7
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
''');
  }

  test_enums() async {
    var library = await buildLibrary(r'''
enum E1 { v1 }

enum E2 { v2 }
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      enums
        #F1 enum E1 (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@enum::E1
          fields
            #F2 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v1 (nameOffset:10) (firstTokenOffset:10) (offset:10)
              element: <testLibrary>::@enum::E1::@field::v1
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E1 @-1
                      element: <testLibrary>::@enum::E1
                      type: E1
                    element: <testLibrary>::@enum::E1::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E1
              inducedGetter: #F3
            #F4 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E1::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v1 @-1
                      element: <testLibrary>::@enum::E1::@getter::v1
                      staticType: E1
                  rightBracket: ] @0
                  staticType: List<E1>
              inducedGetter: #F5
          constructors
            #F6 isConst isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E1::@constructor::new
              typeName: E1
          getters
            #F3 isComplete isOriginVariable isStatic v1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:10)
              element: <testLibrary>::@enum::E1::@getter::v1
              inducingVariable: #F2
            #F5 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E1::@getter::values
              inducingVariable: #F4
        #F7 enum E2 (nameOffset:21) (firstTokenOffset:16) (offset:21)
          element: <testLibrary>::@enum::E2
          fields
            #F8 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v2 (nameOffset:26) (firstTokenOffset:26) (offset:26)
              element: <testLibrary>::@enum::E2::@field::v2
              initializer: expression_2
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E2 @-1
                      element: <testLibrary>::@enum::E2
                      type: E2
                    element: <testLibrary>::@enum::E2::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E2
              inducedGetter: #F9
            #F10 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@enum::E2::@field::values
              initializer: expression_3
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v2 @-1
                      element: <testLibrary>::@enum::E2::@getter::v2
                      staticType: E2
                  rightBracket: ] @0
                  staticType: List<E2>
              inducedGetter: #F11
          constructors
            #F12 isConst isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@enum::E2::@constructor::new
              typeName: E2
          getters
            #F9 isComplete isOriginVariable isStatic v2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:26)
              element: <testLibrary>::@enum::E2::@getter::v2
              inducingVariable: #F8
            #F11 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@enum::E2::@getter::values
              inducingVariable: #F10
  enums
    isSimplyBounded enum E1
      reference: <testLibrary>::@enum::E1
      firstFragment: #F1
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v1
          reference: <testLibrary>::@enum::E1::@field::v1
          firstFragment: #F2
          type: E1
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E1::@getter::v1
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::E1::@field::values
          firstFragment: #F4
          type: List<E1>
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::E1::@getter::values
      constructors
        isConst isOriginImplicitDefault new
          reference: <testLibrary>::@enum::E1::@constructor::new
          firstFragment: #F6
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v1
          reference: <testLibrary>::@enum::E1::@getter::v1
          firstFragment: #F3
          returnType: E1
          variable: <testLibrary>::@enum::E1::@field::v1
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::E1::@getter::values
          firstFragment: #F5
          returnType: List<E1>
          variable: <testLibrary>::@enum::E1::@field::values
    isSimplyBounded enum E2
      reference: <testLibrary>::@enum::E2
      firstFragment: #F7
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v2
          reference: <testLibrary>::@enum::E2::@field::v2
          firstFragment: #F8
          type: E2
          constantInitializer
            fragment: #F8
            expression: expression_2
          getter: <testLibrary>::@enum::E2::@getter::v2
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::E2::@field::values
          firstFragment: #F10
          type: List<E2>
          constantInitializer
            fragment: #F10
            expression: expression_3
          getter: <testLibrary>::@enum::E2::@getter::values
      constructors
        isConst isOriginImplicitDefault new
          reference: <testLibrary>::@enum::E2::@constructor::new
          firstFragment: #F12
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v2
          reference: <testLibrary>::@enum::E2::@getter::v2
          firstFragment: #F9
          returnType: E2
          variable: <testLibrary>::@enum::E2::@field::v2
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::E2::@getter::values
          firstFragment: #F11
          returnType: List<E2>
          variable: <testLibrary>::@enum::E2::@field::values
''');
  }

  test_field() async {
    var library = await buildLibrary(r'''
enum E {
  v;

  final foo = 42;
}
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
            #F2 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:11) (firstTokenOffset:11) (offset:11)
              element: <testLibrary>::@enum::E::@field::v
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
              inducedGetter: #F3
            #F4 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::E::@getter::v
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
              inducedGetter: #F5
            #F6 hasImplicitType hasInitializer isFinal isOriginDeclaration foo (nameOffset:23) (firstTokenOffset:23) (offset:23)
              element: <testLibrary>::@enum::E::@field::foo
              initializer: expression_2
                IntegerLiteral
                  literal: 42 @29
                  staticType: int
              inducedGetter: #F7
          constructors
            #F8 isConst isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F3 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::E::@getter::v
              inducingVariable: #F2
            #F5 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
              inducingVariable: #F4
            #F7 isComplete isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
              element: <testLibrary>::@enum::E::@getter::foo
              inducingVariable: #F6
  enums
    isSimplyBounded enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F4
          type: List<E>
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
        hasImplicitType hasInitializer isFinal isOriginDeclaration isTypeInferredFromInitializer foo
          reference: <testLibrary>::@enum::E::@field::foo
          firstFragment: #F6
          type: int
          constantInitializer
            fragment: #F6
            expression: expression_2
          getter: <testLibrary>::@enum::E::@getter::foo
      constructors
        isConst isOriginImplicitDefault new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F8
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F3
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F5
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
        isOriginVariable foo
          reference: <testLibrary>::@enum::E::@getter::foo
          firstFragment: #F7
          returnType: int
          variable: <testLibrary>::@enum::E::@field::foo
''');
  }

  test_field_augmentation_add() async {
    var library = await buildLibrary(r'''
enum A {
  v;
  final int foo1 = 0;
}

augment enum A {;
  final int foo2 = 0;
}
''');

    configuration.withConstantInitializers = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      enums
        #F1 enum A (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@enum::A
          nextFragment: #F2
          fields
            #F3 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:11) (firstTokenOffset:11) (offset:11)
              element: <testLibrary>::@enum::A::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibrary>::@enum::A
                      type: A
                    element: <testLibrary>::@enum::A::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              inducedGetter: #F4
            #F5 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::A::@getter::v
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
              inducedGetter: #F6
            #F7 hasInitializer isFinal isOriginDeclaration foo1 (nameOffset:26) (firstTokenOffset:26) (offset:26)
              element: <testLibrary>::@enum::A::@field::foo1
              initializer: expression_2
                IntegerLiteral
                  literal: 0 @33
                  staticType: int
              inducedGetter: #F8
          constructors
            #F9 isConst isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
          getters
            #F4 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::A::@getter::v
              inducingVariable: #F3
            #F6 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
              inducingVariable: #F5
            #F8 isComplete isOriginVariable foo1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:26)
              element: <testLibrary>::@enum::A::@getter::foo1
              inducingVariable: #F7
        #F2 isAugmentation enum A (nameOffset:52) (firstTokenOffset:39) (offset:52)
          element: <testLibrary>::@enum::A
          previousFragment: #F1
          fields
            #F10 hasInitializer isFinal isOriginDeclaration foo2 (nameOffset:69) (firstTokenOffset:69) (offset:69)
              element: <testLibrary>::@enum::A::@field::foo2
              initializer: expression_3
                IntegerLiteral
                  literal: 0 @76
                  staticType: int
              inducedGetter: #F11
          getters
            #F11 isComplete isOriginVariable foo2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:69)
              element: <testLibrary>::@enum::A::@getter::foo2
              inducingVariable: #F10
  enums
    isSimplyBounded enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F3
          type: A
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F5
          type: List<A>
          constantInitializer
            fragment: #F5
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
        hasInitializer isFinal isOriginDeclaration foo1
          reference: <testLibrary>::@enum::A::@field::foo1
          firstFragment: #F7
          type: int
          constantInitializer
            fragment: #F7
            expression: expression_2
          getter: <testLibrary>::@enum::A::@getter::foo1
        hasInitializer isFinal isOriginDeclaration foo2
          reference: <testLibrary>::@enum::A::@field::foo2
          firstFragment: #F10
          type: int
          constantInitializer
            fragment: #F10
            expression: expression_3
          getter: <testLibrary>::@enum::A::@getter::foo2
      constructors
        isConst isOriginImplicitDefault new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F9
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F4
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F6
          returnType: List<A>
          variable: <testLibrary>::@enum::A::@field::values
        isOriginVariable foo1
          reference: <testLibrary>::@enum::A::@getter::foo1
          firstFragment: #F8
          returnType: int
          variable: <testLibrary>::@enum::A::@field::foo1
        isOriginVariable foo2
          reference: <testLibrary>::@enum::A::@getter::foo2
          firstFragment: #F11
          returnType: int
          variable: <testLibrary>::@enum::A::@field::foo2
''');
  }

  test_field_augmentation_add_generic() async {
    var library = await buildLibrary(r'''
enum A<T> {
  v<int>();
  final T foo1;
}

augment enum A<T> {;
  final T foo2;
}
''');

    configuration.withConstantInitializers = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      enums
        #F1 enum A (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@enum::A
          nextFragment: #F2
          typeParameters
            #F3 T (nameOffset:7) (firstTokenOffset:7) (offset:7)
              element: #E0 T
              nextFragment: #F4
          fields
            #F5 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:14) (firstTokenOffset:14) (offset:14)
              element: <testLibrary>::@enum::A::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      typeArguments: TypeArgumentList
                        leftBracket: < @15
                        arguments
                          NamedType
                            name: int @16
                            element: dart:core::@class::int
                            type: int
                        rightBracket: > @19
                      element: <testLibrary>::@enum::A
                      type: A<int>
                    element: SubstitutedConstructorElementImpl
                      baseElement: <testLibrary>::@enum::A::@constructor::new
                      substitution: {T: int}
                  argumentList: ArgumentList
                    leftParenthesis: ( @20
                    rightParenthesis: ) @21
                  staticType: A<int>
              inducedGetter: #F6
            #F7 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::A::@getter::v
                      staticType: A<int>
                  rightBracket: ] @0
                  staticType: List<A<dynamic>>
              inducedGetter: #F8
            #F9 isFinal isOriginDeclaration foo1 (nameOffset:34) (firstTokenOffset:34) (offset:34)
              element: <testLibrary>::@enum::A::@field::foo1
              inducedGetter: #F10
          constructors
            #F11 isConst isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
          getters
            #F6 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:14)
              element: <testLibrary>::@enum::A::@getter::v
              inducingVariable: #F5
            #F8 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
              inducingVariable: #F7
            #F10 isComplete isOriginVariable foo1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:34)
              element: <testLibrary>::@enum::A::@getter::foo1
              inducingVariable: #F9
        #F2 isAugmentation enum A (nameOffset:56) (firstTokenOffset:43) (offset:56)
          element: <testLibrary>::@enum::A
          previousFragment: #F1
          typeParameters
            #F4 T (nameOffset:58) (firstTokenOffset:58) (offset:58)
              element: #E0 T
              previousFragment: #F3
          fields
            #F12 isFinal isOriginDeclaration foo2 (nameOffset:74) (firstTokenOffset:74) (offset:74)
              element: <testLibrary>::@enum::A::@field::foo2
              inducedGetter: #F13
          getters
            #F13 isComplete isOriginVariable foo2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:74)
              element: <testLibrary>::@enum::A::@getter::foo2
              inducingVariable: #F12
  enums
    isSimplyBounded enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F3
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F5
          type: A<int>
          constantInitializer
            fragment: #F5
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F7
          type: List<A<dynamic>>
          constantInitializer
            fragment: #F7
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
        hasEnclosingTypeParameterReference isFinal isOriginDeclaration foo1
          reference: <testLibrary>::@enum::A::@field::foo1
          firstFragment: #F9
          type: T
          getter: <testLibrary>::@enum::A::@getter::foo1
        hasEnclosingTypeParameterReference isFinal isOriginDeclaration foo2
          reference: <testLibrary>::@enum::A::@field::foo2
          firstFragment: #F12
          type: T
          getter: <testLibrary>::@enum::A::@getter::foo2
      constructors
        hasEnclosingTypeParameterReference isConst isOriginImplicitDefault new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F11
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F6
          returnType: A<int>
          variable: <testLibrary>::@enum::A::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F8
          returnType: List<A<dynamic>>
          variable: <testLibrary>::@enum::A::@field::values
        hasEnclosingTypeParameterReference isOriginVariable foo1
          reference: <testLibrary>::@enum::A::@getter::foo1
          firstFragment: #F10
          returnType: T
          variable: <testLibrary>::@enum::A::@field::foo1
        hasEnclosingTypeParameterReference isOriginVariable foo2
          reference: <testLibrary>::@enum::A::@getter::foo2
          firstFragment: #F13
          returnType: T
          variable: <testLibrary>::@enum::A::@field::foo2
''');
  }

  test_field_augmentation_add_usedByConstructorFieldInitializer() async {
    var library = await buildLibrary(r'''
enum A {
  v;
  const A() : foo = 0;
}

augment enum A {;
  final int foo;
}
''');

    configuration.withConstantInitializers = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      enums
        #F1 enum A (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@enum::A
          nextFragment: #F2
          fields
            #F3 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:11) (firstTokenOffset:11) (offset:11)
              element: <testLibrary>::@enum::A::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibrary>::@enum::A
                      type: A
                    element: <testLibrary>::@enum::A::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              inducedGetter: #F4
            #F5 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::A::@getter::v
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
              inducedGetter: #F6
          constructors
            #F7 isComplete isConst isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:16) (offset:22)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
              typeNameOffset: 22
          getters
            #F4 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::A::@getter::v
              inducingVariable: #F3
            #F6 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
              inducingVariable: #F5
        #F2 isAugmentation enum A (nameOffset:53) (firstTokenOffset:40) (offset:53)
          element: <testLibrary>::@enum::A
          previousFragment: #F1
          fields
            #F8 isFinal isOriginDeclaration foo (nameOffset:70) (firstTokenOffset:70) (offset:70)
              element: <testLibrary>::@enum::A::@field::foo
              inducedGetter: #F9
          getters
            #F9 isComplete isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:70)
              element: <testLibrary>::@enum::A::@getter::foo
              inducingVariable: #F8
  enums
    isSimplyBounded enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F3
          type: A
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F5
          type: List<A>
          constantInitializer
            fragment: #F5
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
        isFinal isOriginDeclaration foo
          reference: <testLibrary>::@enum::A::@field::foo
          firstFragment: #F8
          type: int
          getter: <testLibrary>::@enum::A::@getter::foo
      constructors
        isConst isOriginDeclaration new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F7
          constantInitializers
            ConstructorFieldInitializer
              fieldName: SimpleIdentifier
                token: foo @28
                element: <testLibrary>::@enum::A::@field::foo
                staticType: null
              equals: = @32
              expression: IntegerLiteral
                literal: 0 @34
                staticType: int
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F4
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F6
          returnType: List<A>
          variable: <testLibrary>::@enum::A::@field::values
        isOriginVariable foo
          reference: <testLibrary>::@enum::A::@getter::foo
          firstFragment: #F9
          returnType: int
          variable: <testLibrary>::@enum::A::@field::foo
''');
  }

  test_field_augmentation_add_usedByFieldFormalParameter() async {
    var library = await buildLibrary(r'''
enum A {
  v(0);
  const A(this.foo);
}

augment enum A {;
  final int foo;
}
''');

    configuration.withConstantInitializers = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      enums
        #F1 enum A (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@enum::A
          nextFragment: #F2
          fields
            #F3 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:11) (firstTokenOffset:11) (offset:11)
              element: <testLibrary>::@enum::A::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibrary>::@enum::A
                      type: A
                    element: <testLibrary>::@enum::A::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @12
                    arguments
                      IntegerLiteral
                        literal: 0 @13
                        staticType: int
                    rightParenthesis: ) @14
                  staticType: A
              inducedGetter: #F4
            #F5 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::A::@getter::v
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
              inducedGetter: #F6
          constructors
            #F7 isComplete isConst isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:19) (offset:25)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
              typeNameOffset: 25
              formalParameters
                #F8 requiredPositional hasImplicitType isFinal isOriginDeclaration this.foo (nameOffset:32) (firstTokenOffset:27) (offset:32)
                  element: <testLibrary>::@enum::A::@constructor::new::@formalParameter::foo
          getters
            #F4 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::A::@getter::v
              inducingVariable: #F3
            #F6 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
              inducingVariable: #F5
        #F2 isAugmentation enum A (nameOffset:54) (firstTokenOffset:41) (offset:54)
          element: <testLibrary>::@enum::A
          previousFragment: #F1
          fields
            #F9 isFinal isOriginDeclaration foo (nameOffset:71) (firstTokenOffset:71) (offset:71)
              element: <testLibrary>::@enum::A::@field::foo
              inducedGetter: #F10
          getters
            #F10 isComplete isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:71)
              element: <testLibrary>::@enum::A::@getter::foo
              inducingVariable: #F9
  enums
    isSimplyBounded enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F3
          type: A
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F5
          type: List<A>
          constantInitializer
            fragment: #F5
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
        isFinal isOriginDeclaration foo
          reference: <testLibrary>::@enum::A::@field::foo
          firstFragment: #F9
          type: int
          getter: <testLibrary>::@enum::A::@getter::foo
      constructors
        isConst isOriginDeclaration new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F7
          formalParameters
            #E0 requiredPositional hasImplicitType isFinal this.foo
              firstFragment: #F8
              type: int
              field: <testLibrary>::@enum::A::@field::foo
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F4
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F6
          returnType: List<A>
          variable: <testLibrary>::@enum::A::@field::values
        isOriginVariable foo
          reference: <testLibrary>::@enum::A::@getter::foo
          firstFragment: #F10
          returnType: int
          variable: <testLibrary>::@enum::A::@field::foo
''');
  }

  test_field_augmentation_chain() async {
    var library = await buildLibrary(r'''
enum A {
  v;
  final int foo = 0;
}

augment enum A {;
  augment final int foo = 1;
}
''');

    configuration.withConstantInitializers = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      enums
        #F1 enum A (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@enum::A
          nextFragment: #F2
          fields
            #F3 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:11) (firstTokenOffset:11) (offset:11)
              element: <testLibrary>::@enum::A::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibrary>::@enum::A
                      type: A
                    element: <testLibrary>::@enum::A::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              inducedGetter: #F4
            #F5 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::A::@getter::v
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
              inducedGetter: #F6
            #F7 hasInitializer isFinal isOriginDeclaration foo (nameOffset:26) (firstTokenOffset:26) (offset:26)
              element: <testLibrary>::@enum::A::@field::foo
              initializer: expression_2
                IntegerLiteral
                  literal: 0 @32
                  staticType: null
              inducedGetter: #F8
              nextFragment: #F9
          constructors
            #F10 isConst isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
          getters
            #F4 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::A::@getter::v
              inducingVariable: #F3
            #F6 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
              inducingVariable: #F5
            #F8 isComplete isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:26)
              element: <testLibrary>::@enum::A::@getter::foo
              inducingVariable: #F7
              nextFragment: #F11
        #F2 isAugmentation enum A (nameOffset:51) (firstTokenOffset:38) (offset:51)
          element: <testLibrary>::@enum::A
          previousFragment: #F1
          fields
            #F9 hasInitializer isAugmentation isFinal isOriginDeclaration foo (nameOffset:76) (firstTokenOffset:76) (offset:76)
              element: <testLibrary>::@enum::A::@field::foo
              initializer: expression_3
                IntegerLiteral
                  literal: 1 @82
                  staticType: int
              inducedGetter: #F11
              previousFragment: #F7
          getters
            #F11 isAugmentation isComplete isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:76)
              element: <testLibrary>::@enum::A::@getter::foo
              inducingVariable: #F9
              previousFragment: #F8
  enums
    isSimplyBounded enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F3
          type: A
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F5
          type: List<A>
          constantInitializer
            fragment: #F5
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
        hasInitializer isFinal isOriginDeclaration foo
          reference: <testLibrary>::@enum::A::@field::foo
          firstFragment: #F7
          type: int
          constantInitializer
            fragment: #F9
            expression: expression_3
          getter: <testLibrary>::@enum::A::@getter::foo
      constructors
        isConst isOriginImplicitDefault new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F10
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F4
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F6
          returnType: List<A>
          variable: <testLibrary>::@enum::A::@field::values
        isOriginVariable foo
          reference: <testLibrary>::@enum::A::@getter::foo
          firstFragment: #F8
          returnType: int
          variable: <testLibrary>::@enum::A::@field::foo
''');
  }

  test_field_augmentation_chain_afterGetter() async {
    var library = await buildLibrary(r'''
enum A {
  v;
  final int foo = 0;
}

augment enum A {;
  augment int get foo => 1;
}

augment enum A {;
  augment final int foo = 2;
}
''');

    configuration.withConstantInitializers = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      enums
        #F1 enum A (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@enum::A
          nextFragment: #F2
          fields
            #F3 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:11) (firstTokenOffset:11) (offset:11)
              element: <testLibrary>::@enum::A::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibrary>::@enum::A
                      type: A
                    element: <testLibrary>::@enum::A::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              inducedGetter: #F4
            #F5 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::A::@getter::v
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
              inducedGetter: #F6
            #F7 hasInitializer isFinal isOriginDeclaration foo (nameOffset:26) (firstTokenOffset:26) (offset:26)
              element: <testLibrary>::@enum::A::@field::foo
              initializer: expression_2
                IntegerLiteral
                  literal: 0 @32
                  staticType: null
              inducedGetter: #F8
              nextFragment: #F9
          constructors
            #F10 isConst isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
          getters
            #F4 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::A::@getter::v
              inducingVariable: #F3
            #F6 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
              inducingVariable: #F5
            #F8 isComplete isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:26)
              element: <testLibrary>::@enum::A::@getter::foo
              inducingVariable: #F7
              nextFragment: #F11
        #F2 isAugmentation enum A (nameOffset:51) (firstTokenOffset:38) (offset:51)
          element: <testLibrary>::@enum::A
          previousFragment: #F1
          nextFragment: #F12
          getters
            #F11 isAugmentation isComplete isOriginDeclaration foo (nameOffset:74) (firstTokenOffset:58) (offset:74)
              element: <testLibrary>::@enum::A::@getter::foo
              previousFragment: #F8
              nextFragment: #F13
        #F12 isAugmentation enum A (nameOffset:100) (firstTokenOffset:87) (offset:100)
          element: <testLibrary>::@enum::A
          previousFragment: #F2
          fields
            #F9 hasInitializer isAugmentation isFinal isOriginDeclaration foo (nameOffset:125) (firstTokenOffset:125) (offset:125)
              element: <testLibrary>::@enum::A::@field::foo
              initializer: expression_3
                IntegerLiteral
                  literal: 2 @131
                  staticType: int
              inducedGetter: #F13
              previousFragment: #F7
          getters
            #F13 isAugmentation isComplete isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:125)
              element: <testLibrary>::@enum::A::@getter::foo
              inducingVariable: #F9
              previousFragment: #F11
  enums
    isSimplyBounded enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F3
          type: A
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F5
          type: List<A>
          constantInitializer
            fragment: #F5
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
        hasInitializer isFinal isOriginDeclaration foo
          reference: <testLibrary>::@enum::A::@field::foo
          firstFragment: #F7
          type: int
          constantInitializer
            fragment: #F9
            expression: expression_3
          getter: <testLibrary>::@enum::A::@getter::foo
      constructors
        isConst isOriginImplicitDefault new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F10
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F4
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F6
          returnType: List<A>
          variable: <testLibrary>::@enum::A::@field::values
        isOriginVariable foo
          reference: <testLibrary>::@enum::A::@getter::foo
          firstFragment: #F8
          returnType: int
          variable: <testLibrary>::@enum::A::@field::foo
''');
  }

  test_field_augmentation_chain_afterSetter() async {
    var library = await buildLibrary(r'''
enum A {
  v;
  final int foo = 0;
}

augment enum A {;
  augment set foo(int _) {}
}

augment enum A {;
  augment final int foo = 2;
}
''');

    configuration.withConstantInitializers = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      enums
        #F1 enum A (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@enum::A
          nextFragment: #F2
          fields
            #F3 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:11) (firstTokenOffset:11) (offset:11)
              element: <testLibrary>::@enum::A::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibrary>::@enum::A
                      type: A
                    element: <testLibrary>::@enum::A::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              inducedGetter: #F4
            #F5 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::A::@getter::v
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
              inducedGetter: #F6
            #F7 hasInitializer isFinal isOriginDeclaration foo (nameOffset:26) (firstTokenOffset:26) (offset:26)
              element: <testLibrary>::@enum::A::@field::foo
              initializer: expression_2
                IntegerLiteral
                  literal: 0 @32
                  staticType: null
              inducedGetter: #F8
              nextFragment: #F9
          constructors
            #F10 isConst isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
          getters
            #F4 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::A::@getter::v
              inducingVariable: #F3
            #F6 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
              inducingVariable: #F5
            #F8 isComplete isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:26)
              element: <testLibrary>::@enum::A::@getter::foo
              inducingVariable: #F7
              nextFragment: #F11
        #F2 isAugmentation enum A (nameOffset:51) (firstTokenOffset:38) (offset:51)
          element: <testLibrary>::@enum::A
          previousFragment: #F1
          nextFragment: #F12
          setters
            #F13 hasImplicitReturnType isAugmentation isComplete isOriginDeclaration foo (nameOffset:70) (firstTokenOffset:58) (offset:70)
              element: <testLibrary>::@enum::A::@setter::foo
              formalParameters
                #F14 requiredPositional isOriginDeclaration _ (nameOffset:78) (firstTokenOffset:74) (offset:78)
                  element: <testLibrary>::@enum::A::@setter::foo::@formalParameter::_
        #F12 isAugmentation enum A (nameOffset:100) (firstTokenOffset:87) (offset:100)
          element: <testLibrary>::@enum::A
          previousFragment: #F2
          fields
            #F9 hasInitializer isAugmentation isFinal isOriginDeclaration foo (nameOffset:125) (firstTokenOffset:125) (offset:125)
              element: <testLibrary>::@enum::A::@field::foo
              initializer: expression_3
                IntegerLiteral
                  literal: 2 @131
                  staticType: int
              inducedGetter: #F11
              previousFragment: #F7
          getters
            #F11 isAugmentation isComplete isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:125)
              element: <testLibrary>::@enum::A::@getter::foo
              inducingVariable: #F9
              previousFragment: #F8
  enums
    isSimplyBounded enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F3
          type: A
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F5
          type: List<A>
          constantInitializer
            fragment: #F5
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
        hasInitializer isFinal isOriginDeclaration foo
          reference: <testLibrary>::@enum::A::@field::foo
          firstFragment: #F7
          type: int
          constantInitializer
            fragment: #F9
            expression: expression_3
          getter: <testLibrary>::@enum::A::@getter::foo
          setter: <testLibrary>::@enum::A::@setter::foo
      constructors
        isConst isOriginImplicitDefault new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F10
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F4
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F6
          returnType: List<A>
          variable: <testLibrary>::@enum::A::@field::values
        isOriginVariable foo
          reference: <testLibrary>::@enum::A::@getter::foo
          firstFragment: #F8
          returnType: int
          variable: <testLibrary>::@enum::A::@field::foo
      setters
        isOriginDeclaration foo
          reference: <testLibrary>::@enum::A::@setter::foo
          firstFragment: #F13
          previousFragmentOfDifferentKind: #F7
          formalParameters
            #E0 requiredPositional _
              firstFragment: #F14
              type: int
          returnType: void
          variable: <testLibrary>::@enum::A::@field::foo
''');
  }

  test_field_augmentation_chain_differentType() async {
    var library = await buildLibrary(r'''
enum A {
  v;
  final int foo = 0;
}

augment enum A {;
  augment final double foo = 1.2;
}
''');

    configuration.withConstantInitializers = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      enums
        #F1 enum A (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@enum::A
          nextFragment: #F2
          fields
            #F3 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:11) (firstTokenOffset:11) (offset:11)
              element: <testLibrary>::@enum::A::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibrary>::@enum::A
                      type: A
                    element: <testLibrary>::@enum::A::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              inducedGetter: #F4
            #F5 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::A::@getter::v
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
              inducedGetter: #F6
            #F7 hasInitializer isFinal isOriginDeclaration foo (nameOffset:26) (firstTokenOffset:26) (offset:26)
              element: <testLibrary>::@enum::A::@field::foo
              initializer: expression_2
                IntegerLiteral
                  literal: 0 @32
                  staticType: null
              inducedGetter: #F8
              nextFragment: #F9
          constructors
            #F10 isConst isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
          getters
            #F4 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::A::@getter::v
              inducingVariable: #F3
            #F6 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
              inducingVariable: #F5
            #F8 isComplete isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:26)
              element: <testLibrary>::@enum::A::@getter::foo
              inducingVariable: #F7
              nextFragment: #F11
        #F2 isAugmentation enum A (nameOffset:51) (firstTokenOffset:38) (offset:51)
          element: <testLibrary>::@enum::A
          previousFragment: #F1
          fields
            #F9 hasInitializer isAugmentation isFinal isOriginDeclaration foo (nameOffset:79) (firstTokenOffset:79) (offset:79)
              element: <testLibrary>::@enum::A::@field::foo
              initializer: expression_3
                DoubleLiteral
                  literal: 1.2 @85
                  staticType: double
              inducedGetter: #F11
              previousFragment: #F7
          getters
            #F11 isAugmentation isComplete isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:79)
              element: <testLibrary>::@enum::A::@getter::foo
              inducingVariable: #F9
              previousFragment: #F8
  enums
    isSimplyBounded enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F3
          type: A
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F5
          type: List<A>
          constantInitializer
            fragment: #F5
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
        hasInitializer isFinal isOriginDeclaration foo
          reference: <testLibrary>::@enum::A::@field::foo
          firstFragment: #F7
          type: int
          constantInitializer
            fragment: #F9
            expression: expression_3
          getter: <testLibrary>::@enum::A::@getter::foo
      constructors
        isConst isOriginImplicitDefault new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F10
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F4
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F6
          returnType: List<A>
          variable: <testLibrary>::@enum::A::@field::values
        isOriginVariable foo
          reference: <testLibrary>::@enum::A::@getter::foo
          firstFragment: #F8
          returnType: int
          variable: <testLibrary>::@enum::A::@field::foo
''');
  }

  /// This is not allowed by the specification, but allowed syntactically,
  /// so we need a way to handle it.
  test_field_augmentation_chain_fromGetter() async {
    var library = await buildLibrary(r'''
enum A {
  v;
  int get foo => 0;
}

augment enum A {;
  augment final int foo = 1;
}
''');

    configuration.withConstantInitializers = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      enums
        #F1 enum A (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@enum::A
          nextFragment: #F2
          fields
            #F3 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:11) (firstTokenOffset:11) (offset:11)
              element: <testLibrary>::@enum::A::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibrary>::@enum::A
                      type: A
                    element: <testLibrary>::@enum::A::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              inducedGetter: #F4
            #F5 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::A::@getter::v
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
              inducedGetter: #F6
            #F7 isOriginGetterSetter foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@field::foo
              nextFragment: #F8
          constructors
            #F9 isConst isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
          getters
            #F4 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::A::@getter::v
              inducingVariable: #F3
            #F6 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
              inducingVariable: #F5
            #F10 isComplete isOriginDeclaration foo (nameOffset:24) (firstTokenOffset:16) (offset:24)
              element: <testLibrary>::@enum::A::@getter::foo
              nextFragment: #F11
        #F2 isAugmentation enum A (nameOffset:50) (firstTokenOffset:37) (offset:50)
          element: <testLibrary>::@enum::A
          previousFragment: #F1
          fields
            #F8 hasInitializer isAugmentation isFinal isOriginDeclaration foo (nameOffset:75) (firstTokenOffset:75) (offset:75)
              element: <testLibrary>::@enum::A::@field::foo
              initializer: expression_2
                IntegerLiteral
                  literal: 1 @81
                  staticType: int
              inducedGetter: #F11
              previousFragment: #F7
          getters
            #F11 isAugmentation isComplete isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:75)
              element: <testLibrary>::@enum::A::@getter::foo
              inducingVariable: #F8
              previousFragment: #F10
  enums
    isSimplyBounded enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F3
          type: A
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F5
          type: List<A>
          constantInitializer
            fragment: #F5
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
        hasInitializer isOriginGetterSetter foo
          reference: <testLibrary>::@enum::A::@field::foo
          firstFragment: #F7
          type: int
          constantInitializer
            fragment: #F8
            expression: expression_2
          getter: <testLibrary>::@enum::A::@getter::foo
      constructors
        isConst isOriginImplicitDefault new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F9
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F4
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F6
          returnType: List<A>
          variable: <testLibrary>::@enum::A::@field::values
        isOriginDeclaration foo
          reference: <testLibrary>::@enum::A::@getter::foo
          firstFragment: #F10
          returnType: int
          variable: <testLibrary>::@enum::A::@field::foo
''');
  }

  test_field_augmentation_chain_functionExpression() async {
    var library = await buildLibrary(r'''
enum A {
  v;
  final int Function() foo = () {
    return 0;
  };
}

augment enum A {;
  augment final int Function() foo = () {
    return augmented() + 1;
  };
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      enums
        #F1 enum A (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@enum::A
          nextFragment: #F2
          fields
            #F3 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:11) (firstTokenOffset:11) (offset:11)
              element: <testLibrary>::@enum::A::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibrary>::@enum::A
                      type: A
                    element: <testLibrary>::@enum::A::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              inducedGetter: #F4
            #F5 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::A::@getter::v
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
              inducedGetter: #F6
            #F7 hasInitializer isFinal isOriginDeclaration foo (nameOffset:37) (firstTokenOffset:37) (offset:37)
              element: <testLibrary>::@enum::A::@field::foo
              initializer: expression_2
                SimpleIdentifier
                  token: _notSerializableExpression @-1
                  element: <null>
                  staticType: null
              inducedGetter: #F8
              nextFragment: #F9
          constructors
            #F10 isConst isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
          getters
            #F4 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::A::@getter::v
              inducingVariable: #F3
            #F6 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
              inducingVariable: #F5
            #F8 isComplete isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:37)
              element: <testLibrary>::@enum::A::@getter::foo
              inducingVariable: #F7
              nextFragment: #F11
        #F2 isAugmentation enum A (nameOffset:83) (firstTokenOffset:70) (offset:83)
          element: <testLibrary>::@enum::A
          previousFragment: #F1
          fields
            #F9 hasInitializer isAugmentation isFinal isOriginDeclaration foo (nameOffset:119) (firstTokenOffset:119) (offset:119)
              element: <testLibrary>::@enum::A::@field::foo
              initializer: expression_3
                SimpleIdentifier
                  token: _notSerializableExpression @-1
                  element: <null>
                  staticType: null
              inducedGetter: #F11
              previousFragment: #F7
          getters
            #F11 isAugmentation isComplete isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:119)
              element: <testLibrary>::@enum::A::@getter::foo
              inducingVariable: #F9
              previousFragment: #F8
  enums
    isSimplyBounded enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F3
          type: A
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F5
          type: List<A>
          constantInitializer
            fragment: #F5
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
        hasInitializer isFinal isOriginDeclaration foo
          reference: <testLibrary>::@enum::A::@field::foo
          firstFragment: #F7
          type: int Function()
          constantInitializer
            fragment: #F9
            expression: expression_3
          getter: <testLibrary>::@enum::A::@getter::foo
      constructors
        isConst isOriginImplicitDefault new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F10
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F4
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F6
          returnType: List<A>
          variable: <testLibrary>::@enum::A::@field::values
        isOriginVariable foo
          reference: <testLibrary>::@enum::A::@getter::foo
          firstFragment: #F8
          returnType: int Function()
          variable: <testLibrary>::@enum::A::@field::foo
''');
  }

  test_field_augmentation_chain_twoDeclarations() async {
    var library = await buildLibrary(r'''
enum A {
  v;
  final int foo = 0;
}

augment enum A {;
  augment final int foo = 1;
}

augment enum A {;
  augment final int foo = 2;
}
''');

    configuration.withConstantInitializers = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      enums
        #F1 enum A (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@enum::A
          nextFragment: #F2
          fields
            #F3 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:11) (firstTokenOffset:11) (offset:11)
              element: <testLibrary>::@enum::A::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibrary>::@enum::A
                      type: A
                    element: <testLibrary>::@enum::A::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              inducedGetter: #F4
            #F5 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::A::@getter::v
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
              inducedGetter: #F6
            #F7 hasInitializer isFinal isOriginDeclaration foo (nameOffset:26) (firstTokenOffset:26) (offset:26)
              element: <testLibrary>::@enum::A::@field::foo
              initializer: expression_2
                IntegerLiteral
                  literal: 0 @32
                  staticType: null
              inducedGetter: #F8
              nextFragment: #F9
          constructors
            #F10 isConst isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
          getters
            #F4 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::A::@getter::v
              inducingVariable: #F3
            #F6 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
              inducingVariable: #F5
            #F8 isComplete isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:26)
              element: <testLibrary>::@enum::A::@getter::foo
              inducingVariable: #F7
              nextFragment: #F11
        #F2 isAugmentation enum A (nameOffset:51) (firstTokenOffset:38) (offset:51)
          element: <testLibrary>::@enum::A
          previousFragment: #F1
          nextFragment: #F12
          fields
            #F9 hasInitializer isAugmentation isFinal isOriginDeclaration foo (nameOffset:76) (firstTokenOffset:76) (offset:76)
              element: <testLibrary>::@enum::A::@field::foo
              initializer: expression_3
                IntegerLiteral
                  literal: 1 @82
                  staticType: null
              inducedGetter: #F11
              previousFragment: #F7
              nextFragment: #F13
          getters
            #F11 isAugmentation isComplete isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:76)
              element: <testLibrary>::@enum::A::@getter::foo
              inducingVariable: #F9
              previousFragment: #F8
              nextFragment: #F14
        #F12 isAugmentation enum A (nameOffset:101) (firstTokenOffset:88) (offset:101)
          element: <testLibrary>::@enum::A
          previousFragment: #F2
          fields
            #F13 hasInitializer isAugmentation isFinal isOriginDeclaration foo (nameOffset:126) (firstTokenOffset:126) (offset:126)
              element: <testLibrary>::@enum::A::@field::foo
              initializer: expression_4
                IntegerLiteral
                  literal: 2 @132
                  staticType: int
              inducedGetter: #F14
              previousFragment: #F9
          getters
            #F14 isAugmentation isComplete isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:126)
              element: <testLibrary>::@enum::A::@getter::foo
              inducingVariable: #F13
              previousFragment: #F11
  enums
    isSimplyBounded enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F3
          type: A
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F5
          type: List<A>
          constantInitializer
            fragment: #F5
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
        hasInitializer isFinal isOriginDeclaration foo
          reference: <testLibrary>::@enum::A::@field::foo
          firstFragment: #F7
          type: int
          constantInitializer
            fragment: #F13
            expression: expression_4
          getter: <testLibrary>::@enum::A::@getter::foo
      constructors
        isConst isOriginImplicitDefault new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F10
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F4
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F6
          returnType: List<A>
          variable: <testLibrary>::@enum::A::@field::values
        isOriginVariable foo
          reference: <testLibrary>::@enum::A::@getter::foo
          firstFragment: #F8
          returnType: int
          variable: <testLibrary>::@enum::A::@field::foo
''');
  }

  test_field_isPromotable() async {
    var library = await buildLibrary(r'''
enum E {
  v(null);

  final int? _foo;
  E(this._foo);
}
''');
    configuration.forPromotableFields(enumNames: {'E'}, fieldNames: {'_foo'});
    checkElementText(library, r'''
library
  reference: <testLibrary>
  enums
    isSimplyBounded enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F0
      supertype: Enum
      fields
        isFinal isOriginDeclaration isPromotable _foo
          reference: <testLibrary>::@enum::E::@field::_foo
          firstFragment: #F1
          type: int?
          getter: <testLibrary>::@enum::E::@getter::_foo
''');
  }

  test_getter() async {
    var library = await buildLibrary(r'''
enum E {
  v;

  int get foo => 0;
}
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
            #F2 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:11) (firstTokenOffset:11) (offset:11)
              element: <testLibrary>::@enum::E::@field::v
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
              inducedGetter: #F3
            #F4 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::E::@getter::v
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
              inducedGetter: #F5
            #F6 isOriginGetterSetter foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@field::foo
          constructors
            #F7 isConst isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F3 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::E::@getter::v
              inducingVariable: #F2
            #F5 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
              inducingVariable: #F4
            #F8 isComplete isOriginDeclaration foo (nameOffset:25) (firstTokenOffset:17) (offset:25)
              element: <testLibrary>::@enum::E::@getter::foo
  enums
    isSimplyBounded enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F4
          type: List<E>
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
        isOriginGetterSetter foo
          reference: <testLibrary>::@enum::E::@field::foo
          firstFragment: #F6
          type: int
          getter: <testLibrary>::@enum::E::@getter::foo
      constructors
        isConst isOriginImplicitDefault new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F7
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F3
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F5
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
        isOriginDeclaration foo
          reference: <testLibrary>::@enum::E::@getter::foo
          firstFragment: #F8
          returnType: int
          variable: <testLibrary>::@enum::E::@field::foo
''');
  }

  test_getter_augmentation_add() async {
    var library = await buildLibrary(r'''
enum A {
  v;
  int get foo1 => 0;
}

augment enum A {;
  int get foo2 => 0;
}
''');

    configuration.withConstantInitializers = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      enums
        #F1 enum A (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@enum::A
          nextFragment: #F2
          fields
            #F3 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:11) (firstTokenOffset:11) (offset:11)
              element: <testLibrary>::@enum::A::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibrary>::@enum::A
                      type: A
                    element: <testLibrary>::@enum::A::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              inducedGetter: #F4
            #F5 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::A::@getter::v
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
              inducedGetter: #F6
            #F7 isOriginGetterSetter foo1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@field::foo1
          constructors
            #F8 isConst isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
          getters
            #F4 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::A::@getter::v
              inducingVariable: #F3
            #F6 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
              inducingVariable: #F5
            #F9 isComplete isOriginDeclaration foo1 (nameOffset:24) (firstTokenOffset:16) (offset:24)
              element: <testLibrary>::@enum::A::@getter::foo1
        #F2 isAugmentation enum A (nameOffset:51) (firstTokenOffset:38) (offset:51)
          element: <testLibrary>::@enum::A
          previousFragment: #F1
          fields
            #F10 isOriginGetterSetter foo2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:51)
              element: <testLibrary>::@enum::A::@field::foo2
          getters
            #F11 isComplete isOriginDeclaration foo2 (nameOffset:66) (firstTokenOffset:58) (offset:66)
              element: <testLibrary>::@enum::A::@getter::foo2
  enums
    isSimplyBounded enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F3
          type: A
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F5
          type: List<A>
          constantInitializer
            fragment: #F5
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
        isOriginGetterSetter foo1
          reference: <testLibrary>::@enum::A::@field::foo1
          firstFragment: #F7
          type: int
          getter: <testLibrary>::@enum::A::@getter::foo1
        isOriginGetterSetter foo2
          reference: <testLibrary>::@enum::A::@field::foo2
          firstFragment: #F10
          type: int
          getter: <testLibrary>::@enum::A::@getter::foo2
      constructors
        isConst isOriginImplicitDefault new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F8
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F4
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F6
          returnType: List<A>
          variable: <testLibrary>::@enum::A::@field::values
        isOriginDeclaration foo1
          reference: <testLibrary>::@enum::A::@getter::foo1
          firstFragment: #F9
          returnType: int
          variable: <testLibrary>::@enum::A::@field::foo1
        isOriginDeclaration foo2
          reference: <testLibrary>::@enum::A::@getter::foo2
          firstFragment: #F11
          returnType: int
          variable: <testLibrary>::@enum::A::@field::foo2
''');
  }

  test_getter_augmentation_add_generic() async {
    var library = await buildLibrary(r'''
enum A<T> {
  v<int>();
  T get foo1;
}

augment enum A<T> {;
  T get foo2;
}
''');

    configuration.withConstantInitializers = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      enums
        #F1 enum A (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@enum::A
          nextFragment: #F2
          typeParameters
            #F3 T (nameOffset:7) (firstTokenOffset:7) (offset:7)
              element: #E0 T
              nextFragment: #F4
          fields
            #F5 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:14) (firstTokenOffset:14) (offset:14)
              element: <testLibrary>::@enum::A::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      typeArguments: TypeArgumentList
                        leftBracket: < @15
                        arguments
                          NamedType
                            name: int @16
                            element: dart:core::@class::int
                            type: int
                        rightBracket: > @19
                      element: <testLibrary>::@enum::A
                      type: A<int>
                    element: SubstitutedConstructorElementImpl
                      baseElement: <testLibrary>::@enum::A::@constructor::new
                      substitution: {T: int}
                  argumentList: ArgumentList
                    leftParenthesis: ( @20
                    rightParenthesis: ) @21
                  staticType: A<int>
              inducedGetter: #F6
            #F7 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::A::@getter::v
                      staticType: A<int>
                  rightBracket: ] @0
                  staticType: List<A<dynamic>>
              inducedGetter: #F8
            #F9 isOriginGetterSetter foo1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@field::foo1
          constructors
            #F10 isConst isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
          getters
            #F6 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:14)
              element: <testLibrary>::@enum::A::@getter::v
              inducingVariable: #F5
            #F8 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
              inducingVariable: #F7
            #F11 isAbstract isOriginDeclaration foo1 (nameOffset:32) (firstTokenOffset:26) (offset:32)
              element: <testLibrary>::@enum::A::@getter::foo1
        #F2 isAugmentation enum A (nameOffset:54) (firstTokenOffset:41) (offset:54)
          element: <testLibrary>::@enum::A
          previousFragment: #F1
          typeParameters
            #F4 T (nameOffset:56) (firstTokenOffset:56) (offset:56)
              element: #E0 T
              previousFragment: #F3
          fields
            #F12 isOriginGetterSetter foo2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:54)
              element: <testLibrary>::@enum::A::@field::foo2
          getters
            #F13 isAbstract isOriginDeclaration foo2 (nameOffset:70) (firstTokenOffset:64) (offset:70)
              element: <testLibrary>::@enum::A::@getter::foo2
  enums
    isSimplyBounded enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F3
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F5
          type: A<int>
          constantInitializer
            fragment: #F5
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F7
          type: List<A<dynamic>>
          constantInitializer
            fragment: #F7
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
        hasEnclosingTypeParameterReference isOriginGetterSetter foo1
          reference: <testLibrary>::@enum::A::@field::foo1
          firstFragment: #F9
          type: T
          getter: <testLibrary>::@enum::A::@getter::foo1
        hasEnclosingTypeParameterReference isOriginGetterSetter foo2
          reference: <testLibrary>::@enum::A::@field::foo2
          firstFragment: #F12
          type: T
          getter: <testLibrary>::@enum::A::@getter::foo2
      constructors
        hasEnclosingTypeParameterReference isConst isOriginImplicitDefault new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F10
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F6
          returnType: A<int>
          variable: <testLibrary>::@enum::A::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F8
          returnType: List<A<dynamic>>
          variable: <testLibrary>::@enum::A::@field::values
        hasEnclosingTypeParameterReference isOriginDeclaration foo1
          reference: <testLibrary>::@enum::A::@getter::foo1
          firstFragment: #F11
          returnType: T
          variable: <testLibrary>::@enum::A::@field::foo1
        hasEnclosingTypeParameterReference isOriginDeclaration foo2
          reference: <testLibrary>::@enum::A::@getter::foo2
          firstFragment: #F13
          returnType: T
          variable: <testLibrary>::@enum::A::@field::foo2
''');
  }

  test_getter_augmentation_chain() async {
    var library = await buildLibrary(r'''
enum A {
  v;
  int get foo1 => 0;
  int get foo2 => 0;
}

augment enum A {;
  augment int get foo1 => 0;
}
''');

    configuration.withConstantInitializers = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      enums
        #F1 enum A (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@enum::A
          nextFragment: #F2
          fields
            #F3 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:11) (firstTokenOffset:11) (offset:11)
              element: <testLibrary>::@enum::A::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibrary>::@enum::A
                      type: A
                    element: <testLibrary>::@enum::A::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              inducedGetter: #F4
            #F5 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::A::@getter::v
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
              inducedGetter: #F6
            #F7 isOriginGetterSetter foo1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@field::foo1
            #F8 isOriginGetterSetter foo2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@field::foo2
          constructors
            #F9 isConst isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
          getters
            #F4 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::A::@getter::v
              inducingVariable: #F3
            #F6 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
              inducingVariable: #F5
            #F10 isComplete isOriginDeclaration foo1 (nameOffset:24) (firstTokenOffset:16) (offset:24)
              element: <testLibrary>::@enum::A::@getter::foo1
              nextFragment: #F11
            #F12 isComplete isOriginDeclaration foo2 (nameOffset:45) (firstTokenOffset:37) (offset:45)
              element: <testLibrary>::@enum::A::@getter::foo2
        #F2 isAugmentation enum A (nameOffset:72) (firstTokenOffset:59) (offset:72)
          element: <testLibrary>::@enum::A
          previousFragment: #F1
          getters
            #F11 isAugmentation isComplete isOriginDeclaration foo1 (nameOffset:95) (firstTokenOffset:79) (offset:95)
              element: <testLibrary>::@enum::A::@getter::foo1
              previousFragment: #F10
  enums
    isSimplyBounded enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F3
          type: A
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F5
          type: List<A>
          constantInitializer
            fragment: #F5
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
        isOriginGetterSetter foo1
          reference: <testLibrary>::@enum::A::@field::foo1
          firstFragment: #F7
          type: int
          getter: <testLibrary>::@enum::A::@getter::foo1
        isOriginGetterSetter foo2
          reference: <testLibrary>::@enum::A::@field::foo2
          firstFragment: #F8
          type: int
          getter: <testLibrary>::@enum::A::@getter::foo2
      constructors
        isConst isOriginImplicitDefault new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F9
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F4
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F6
          returnType: List<A>
          variable: <testLibrary>::@enum::A::@field::values
        isOriginDeclaration foo1
          reference: <testLibrary>::@enum::A::@getter::foo1
          firstFragment: #F10
          returnType: int
          variable: <testLibrary>::@enum::A::@field::foo1
        isOriginDeclaration foo2
          reference: <testLibrary>::@enum::A::@getter::foo2
          firstFragment: #F12
          returnType: int
          variable: <testLibrary>::@enum::A::@field::foo2
''');
  }

  test_getter_augmentation_chain_fromField() async {
    var library = await buildLibrary(r'''
enum A {
  v;
  final int foo = 0;
}

augment enum A {;
  augment int get foo => 0;
}
''');

    configuration.withConstantInitializers = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      enums
        #F1 enum A (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@enum::A
          nextFragment: #F2
          fields
            #F3 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:11) (firstTokenOffset:11) (offset:11)
              element: <testLibrary>::@enum::A::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibrary>::@enum::A
                      type: A
                    element: <testLibrary>::@enum::A::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              inducedGetter: #F4
            #F5 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::A::@getter::v
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
              inducedGetter: #F6
            #F7 hasInitializer isFinal isOriginDeclaration foo (nameOffset:26) (firstTokenOffset:26) (offset:26)
              element: <testLibrary>::@enum::A::@field::foo
              initializer: expression_2
                IntegerLiteral
                  literal: 0 @32
                  staticType: int
              inducedGetter: #F8
          constructors
            #F9 isConst isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
          getters
            #F4 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::A::@getter::v
              inducingVariable: #F3
            #F6 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
              inducingVariable: #F5
            #F8 isComplete isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:26)
              element: <testLibrary>::@enum::A::@getter::foo
              inducingVariable: #F7
              nextFragment: #F10
        #F2 isAugmentation enum A (nameOffset:51) (firstTokenOffset:38) (offset:51)
          element: <testLibrary>::@enum::A
          previousFragment: #F1
          getters
            #F10 isAugmentation isComplete isOriginDeclaration foo (nameOffset:74) (firstTokenOffset:58) (offset:74)
              element: <testLibrary>::@enum::A::@getter::foo
              previousFragment: #F8
  enums
    isSimplyBounded enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F3
          type: A
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F5
          type: List<A>
          constantInitializer
            fragment: #F5
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
        hasInitializer isFinal isOriginDeclaration foo
          reference: <testLibrary>::@enum::A::@field::foo
          firstFragment: #F7
          type: int
          constantInitializer
            fragment: #F7
            expression: expression_2
          getter: <testLibrary>::@enum::A::@getter::foo
      constructors
        isConst isOriginImplicitDefault new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F9
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F4
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F6
          returnType: List<A>
          variable: <testLibrary>::@enum::A::@field::values
        isOriginVariable foo
          reference: <testLibrary>::@enum::A::@getter::foo
          firstFragment: #F8
          returnType: int
          variable: <testLibrary>::@enum::A::@field::foo
''');
  }

  test_getter_augmentation_chain_fromField_twoDeclarations() async {
    var library = await buildLibrary(r'''
enum A {
  v;
  final int foo = 0;
}

augment enum A {;
  augment int get foo => 0;
}

augment enum A {;
  augment int get foo => 0;
}
''');

    configuration.withConstantInitializers = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      enums
        #F1 enum A (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@enum::A
          nextFragment: #F2
          fields
            #F3 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:11) (firstTokenOffset:11) (offset:11)
              element: <testLibrary>::@enum::A::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibrary>::@enum::A
                      type: A
                    element: <testLibrary>::@enum::A::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              inducedGetter: #F4
            #F5 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::A::@getter::v
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
              inducedGetter: #F6
            #F7 hasInitializer isFinal isOriginDeclaration foo (nameOffset:26) (firstTokenOffset:26) (offset:26)
              element: <testLibrary>::@enum::A::@field::foo
              initializer: expression_2
                IntegerLiteral
                  literal: 0 @32
                  staticType: int
              inducedGetter: #F8
          constructors
            #F9 isConst isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
          getters
            #F4 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::A::@getter::v
              inducingVariable: #F3
            #F6 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
              inducingVariable: #F5
            #F8 isComplete isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:26)
              element: <testLibrary>::@enum::A::@getter::foo
              inducingVariable: #F7
              nextFragment: #F10
        #F2 isAugmentation enum A (nameOffset:51) (firstTokenOffset:38) (offset:51)
          element: <testLibrary>::@enum::A
          previousFragment: #F1
          nextFragment: #F11
          getters
            #F10 isAugmentation isComplete isOriginDeclaration foo (nameOffset:74) (firstTokenOffset:58) (offset:74)
              element: <testLibrary>::@enum::A::@getter::foo
              previousFragment: #F8
              nextFragment: #F12
        #F11 isAugmentation enum A (nameOffset:100) (firstTokenOffset:87) (offset:100)
          element: <testLibrary>::@enum::A
          previousFragment: #F2
          getters
            #F12 isAugmentation isComplete isOriginDeclaration foo (nameOffset:123) (firstTokenOffset:107) (offset:123)
              element: <testLibrary>::@enum::A::@getter::foo
              previousFragment: #F10
  enums
    isSimplyBounded enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F3
          type: A
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F5
          type: List<A>
          constantInitializer
            fragment: #F5
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
        hasInitializer isFinal isOriginDeclaration foo
          reference: <testLibrary>::@enum::A::@field::foo
          firstFragment: #F7
          type: int
          constantInitializer
            fragment: #F7
            expression: expression_2
          getter: <testLibrary>::@enum::A::@getter::foo
      constructors
        isConst isOriginImplicitDefault new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F9
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F4
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F6
          returnType: List<A>
          variable: <testLibrary>::@enum::A::@field::values
        isOriginVariable foo
          reference: <testLibrary>::@enum::A::@getter::foo
          firstFragment: #F8
          returnType: int
          variable: <testLibrary>::@enum::A::@field::foo
''');
  }

  test_getter_augmentation_chain_noIntroductoryDeclaration() async {
    var library = await buildLibrary(r'''
enum A {
  v
}

augment enum A {;
  augment int get foo => 0;
}
''');

    configuration
      ..withConstantInitializers = false
      ..withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      enums
        #F1 enum A (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@enum::A
          nextFragment: #F2
          fields
            #F3 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:11) (firstTokenOffset:11) (offset:11)
              element: <testLibrary>::@enum::A::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibrary>::@enum::A
                      type: A
                    element: <testLibrary>::@enum::A::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              inducedGetter: #F4
            #F5 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::A::@getter::v
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
              inducedGetter: #F6
          getters
            #F4 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::A::@getter::v
              inducingVariable: #F3
            #F6 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
              inducingVariable: #F5
        #F2 isAugmentation enum A (nameOffset:29) (firstTokenOffset:16) (offset:29)
          element: <testLibrary>::@enum::A
          previousFragment: #F1
          fields
            #F7 isOriginGetterSetter foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:29)
              element: <testLibrary>::@enum::A::@field::foo
          getters
            #F8 isAugmentation isComplete isOriginDeclaration foo (nameOffset:52) (firstTokenOffset:36) (offset:52)
              element: <testLibrary>::@enum::A::@getter::foo
  enums
    isSimplyBounded enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F3
          type: A
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F5
          type: List<A>
          constantInitializer
            fragment: #F5
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
        isOriginGetterSetter foo
          reference: <testLibrary>::@enum::A::@field::foo
          firstFragment: #F7
          type: int
          getter: <testLibrary>::@enum::A::@getter::foo
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F4
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F6
          returnType: List<A>
          variable: <testLibrary>::@enum::A::@field::values
        isOriginDeclaration foo
          reference: <testLibrary>::@enum::A::@getter::foo
          firstFragment: #F8
          returnType: int
          variable: <testLibrary>::@enum::A::@field::foo
''');
  }

  test_getter_augmentation_chain_twoDeclarations() async {
    var library = await buildLibrary(r'''
enum A {
  v;
  int get foo => 0;
}

augment enum A {;
  augment int get foo => 0;
}

augment enum A {;
  augment int get foo => 0;
}
''');

    configuration.withConstantInitializers = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      enums
        #F1 enum A (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@enum::A
          nextFragment: #F2
          fields
            #F3 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:11) (firstTokenOffset:11) (offset:11)
              element: <testLibrary>::@enum::A::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibrary>::@enum::A
                      type: A
                    element: <testLibrary>::@enum::A::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              inducedGetter: #F4
            #F5 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::A::@getter::v
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
              inducedGetter: #F6
            #F7 isOriginGetterSetter foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@field::foo
          constructors
            #F8 isConst isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
          getters
            #F4 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::A::@getter::v
              inducingVariable: #F3
            #F6 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
              inducingVariable: #F5
            #F9 isComplete isOriginDeclaration foo (nameOffset:24) (firstTokenOffset:16) (offset:24)
              element: <testLibrary>::@enum::A::@getter::foo
              nextFragment: #F10
        #F2 isAugmentation enum A (nameOffset:50) (firstTokenOffset:37) (offset:50)
          element: <testLibrary>::@enum::A
          previousFragment: #F1
          nextFragment: #F11
          getters
            #F10 isAugmentation isComplete isOriginDeclaration foo (nameOffset:73) (firstTokenOffset:57) (offset:73)
              element: <testLibrary>::@enum::A::@getter::foo
              previousFragment: #F9
              nextFragment: #F12
        #F11 isAugmentation enum A (nameOffset:99) (firstTokenOffset:86) (offset:99)
          element: <testLibrary>::@enum::A
          previousFragment: #F2
          getters
            #F12 isAugmentation isComplete isOriginDeclaration foo (nameOffset:122) (firstTokenOffset:106) (offset:122)
              element: <testLibrary>::@enum::A::@getter::foo
              previousFragment: #F10
  enums
    isSimplyBounded enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F3
          type: A
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F5
          type: List<A>
          constantInitializer
            fragment: #F5
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
        isOriginGetterSetter foo
          reference: <testLibrary>::@enum::A::@field::foo
          firstFragment: #F7
          type: int
          getter: <testLibrary>::@enum::A::@getter::foo
      constructors
        isConst isOriginImplicitDefault new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F8
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F4
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F6
          returnType: List<A>
          variable: <testLibrary>::@enum::A::@field::values
        isOriginDeclaration foo
          reference: <testLibrary>::@enum::A::@getter::foo
          firstFragment: #F9
          returnType: int
          variable: <testLibrary>::@enum::A::@field::foo
''');
  }

  test_getter_augmentation_chain_twoInSameDeclaration() async {
    var library = await buildLibrary(r'''
enum A {
  v;
  int get foo => 0;
}

augment enum A {;
  augment int get foo => 0;
  augment int get foo => 0;
}
''');

    configuration.withConstantInitializers = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      enums
        #F1 enum A (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@enum::A
          nextFragment: #F2
          fields
            #F3 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:11) (firstTokenOffset:11) (offset:11)
              element: <testLibrary>::@enum::A::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibrary>::@enum::A
                      type: A
                    element: <testLibrary>::@enum::A::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              inducedGetter: #F4
            #F5 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::A::@getter::v
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
              inducedGetter: #F6
            #F7 isOriginGetterSetter foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@field::foo
          constructors
            #F8 isConst isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
          getters
            #F4 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::A::@getter::v
              inducingVariable: #F3
            #F6 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
              inducingVariable: #F5
            #F9 isComplete isOriginDeclaration foo (nameOffset:24) (firstTokenOffset:16) (offset:24)
              element: <testLibrary>::@enum::A::@getter::foo
              nextFragment: #F10
        #F2 isAugmentation enum A (nameOffset:50) (firstTokenOffset:37) (offset:50)
          element: <testLibrary>::@enum::A
          previousFragment: #F1
          getters
            #F10 isAugmentation isComplete isOriginDeclaration foo (nameOffset:73) (firstTokenOffset:57) (offset:73)
              element: <testLibrary>::@enum::A::@getter::foo
              previousFragment: #F9
              nextFragment: #F11
            #F11 isAugmentation isComplete isOriginDeclaration foo (nameOffset:101) (firstTokenOffset:85) (offset:101)
              element: <testLibrary>::@enum::A::@getter::foo
              previousFragment: #F10
  enums
    isSimplyBounded enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F3
          type: A
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F5
          type: List<A>
          constantInitializer
            fragment: #F5
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
        isOriginGetterSetter foo
          reference: <testLibrary>::@enum::A::@field::foo
          firstFragment: #F7
          type: int
          getter: <testLibrary>::@enum::A::@getter::foo
      constructors
        isConst isOriginImplicitDefault new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F8
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F4
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F6
          returnType: List<A>
          variable: <testLibrary>::@enum::A::@field::values
        isOriginDeclaration foo
          reference: <testLibrary>::@enum::A::@getter::foo
          firstFragment: #F9
          returnType: int
          variable: <testLibrary>::@enum::A::@field::foo
''');
  }

  test_method() async {
    var library = await buildLibrary(r'''
enum E<T> {
  v;

  int foo<U>(T t, U u) => 0;
}
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
          typeParameters
            #F2 T (nameOffset:7) (firstTokenOffset:7) (offset:7)
              element: #E0 T
          fields
            #F3 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:14) (firstTokenOffset:14) (offset:14)
              element: <testLibrary>::@enum::E::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibrary>::@enum::E
                      type: E<dynamic>
                    element: SubstitutedConstructorElementImpl
                      baseElement: <testLibrary>::@enum::E::@constructor::new
                      substitution: {T: dynamic}
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E<dynamic>
              inducedGetter: #F4
            #F5 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::E::@getter::v
                      staticType: E<dynamic>
                  rightBracket: ] @0
                  staticType: List<E<dynamic>>
              inducedGetter: #F6
          constructors
            #F7 isConst isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F4 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:14)
              element: <testLibrary>::@enum::E::@getter::v
              inducingVariable: #F3
            #F6 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
              inducingVariable: #F5
          methods
            #F8 isComplete isOriginDeclaration foo (nameOffset:24) (firstTokenOffset:20) (offset:24)
              element: <testLibrary>::@enum::E::@method::foo
              typeParameters
                #F9 U (nameOffset:28) (firstTokenOffset:28) (offset:28)
                  element: #E1 U
              formalParameters
                #F10 requiredPositional isOriginDeclaration t (nameOffset:33) (firstTokenOffset:31) (offset:33)
                  element: <testLibrary>::@enum::E::@method::foo::@formalParameter::t
                #F11 requiredPositional isOriginDeclaration u (nameOffset:38) (firstTokenOffset:36) (offset:38)
                  element: <testLibrary>::@enum::E::@method::foo::@formalParameter::u
  enums
    isSimplyBounded enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F3
          type: E<dynamic>
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F5
          type: List<E<dynamic>>
          constantInitializer
            fragment: #F5
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        hasEnclosingTypeParameterReference isConst isOriginImplicitDefault new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F7
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F4
          returnType: E<dynamic>
          variable: <testLibrary>::@enum::E::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F6
          returnType: List<E<dynamic>>
          variable: <testLibrary>::@enum::E::@field::values
      methods
        hasEnclosingTypeParameterReference isOriginDeclaration foo
          reference: <testLibrary>::@enum::E::@method::foo
          firstFragment: #F8
          typeParameters
            #E1 U
              firstFragment: #F9
          formalParameters
            #E2 requiredPositional t
              firstFragment: #F10
              type: T
            #E3 requiredPositional u
              firstFragment: #F11
              type: U
          returnType: int
''');
  }

  test_method_augmentation_add() async {
    var library = await buildLibrary(r'''
enum A {
  v;
  void foo() {}
}

augment enum A {;
  void bar() {}
}
''');

    configuration.withConstantInitializers = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      enums
        #F1 enum A (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@enum::A
          nextFragment: #F2
          fields
            #F3 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:11) (firstTokenOffset:11) (offset:11)
              element: <testLibrary>::@enum::A::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibrary>::@enum::A
                      type: A
                    element: <testLibrary>::@enum::A::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              inducedGetter: #F4
            #F5 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::A::@getter::v
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
              inducedGetter: #F6
          constructors
            #F7 isConst isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
          getters
            #F4 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::A::@getter::v
              inducingVariable: #F3
            #F6 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
              inducingVariable: #F5
          methods
            #F8 isComplete isOriginDeclaration foo (nameOffset:21) (firstTokenOffset:16) (offset:21)
              element: <testLibrary>::@enum::A::@method::foo
        #F2 isAugmentation enum A (nameOffset:46) (firstTokenOffset:33) (offset:46)
          element: <testLibrary>::@enum::A
          previousFragment: #F1
          methods
            #F9 isComplete isOriginDeclaration bar (nameOffset:58) (firstTokenOffset:53) (offset:58)
              element: <testLibrary>::@enum::A::@method::bar
  enums
    isSimplyBounded enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F3
          type: A
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F5
          type: List<A>
          constantInitializer
            fragment: #F5
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
      constructors
        isConst isOriginImplicitDefault new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F7
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F4
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F6
          returnType: List<A>
          variable: <testLibrary>::@enum::A::@field::values
      methods
        isOriginDeclaration foo
          reference: <testLibrary>::@enum::A::@method::foo
          firstFragment: #F8
          returnType: void
        isOriginDeclaration bar
          reference: <testLibrary>::@enum::A::@method::bar
          firstFragment: #F9
          returnType: void
''');
  }

  test_method_augmentation_add_generic() async {
    var library = await buildLibrary(r'''
enum A<T> {
  v<int>();
  T foo() => throw 0;
}

augment enum A<T> {;
  T bar() => throw 0;
}
''');

    configuration.withConstantInitializers = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      enums
        #F1 enum A (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@enum::A
          nextFragment: #F2
          typeParameters
            #F3 T (nameOffset:7) (firstTokenOffset:7) (offset:7)
              element: #E0 T
              nextFragment: #F4
          fields
            #F5 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:14) (firstTokenOffset:14) (offset:14)
              element: <testLibrary>::@enum::A::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      typeArguments: TypeArgumentList
                        leftBracket: < @15
                        arguments
                          NamedType
                            name: int @16
                            element: dart:core::@class::int
                            type: int
                        rightBracket: > @19
                      element: <testLibrary>::@enum::A
                      type: A<int>
                    element: SubstitutedConstructorElementImpl
                      baseElement: <testLibrary>::@enum::A::@constructor::new
                      substitution: {T: int}
                  argumentList: ArgumentList
                    leftParenthesis: ( @20
                    rightParenthesis: ) @21
                  staticType: A<int>
              inducedGetter: #F6
            #F7 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::A::@getter::v
                      staticType: A<int>
                  rightBracket: ] @0
                  staticType: List<A<dynamic>>
              inducedGetter: #F8
          constructors
            #F9 isConst isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
          getters
            #F6 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:14)
              element: <testLibrary>::@enum::A::@getter::v
              inducingVariable: #F5
            #F8 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
              inducingVariable: #F7
          methods
            #F10 isComplete isOriginDeclaration foo (nameOffset:28) (firstTokenOffset:26) (offset:28)
              element: <testLibrary>::@enum::A::@method::foo
        #F2 isAugmentation enum A (nameOffset:62) (firstTokenOffset:49) (offset:62)
          element: <testLibrary>::@enum::A
          previousFragment: #F1
          typeParameters
            #F4 T (nameOffset:64) (firstTokenOffset:64) (offset:64)
              element: #E0 T
              previousFragment: #F3
          methods
            #F11 isComplete isOriginDeclaration bar (nameOffset:74) (firstTokenOffset:72) (offset:74)
              element: <testLibrary>::@enum::A::@method::bar
  enums
    isSimplyBounded enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F3
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F5
          type: A<int>
          constantInitializer
            fragment: #F5
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F7
          type: List<A<dynamic>>
          constantInitializer
            fragment: #F7
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
      constructors
        hasEnclosingTypeParameterReference isConst isOriginImplicitDefault new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F9
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F6
          returnType: A<int>
          variable: <testLibrary>::@enum::A::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F8
          returnType: List<A<dynamic>>
          variable: <testLibrary>::@enum::A::@field::values
      methods
        hasEnclosingTypeParameterReference isOriginDeclaration foo
          reference: <testLibrary>::@enum::A::@method::foo
          firstFragment: #F10
          returnType: T
        hasEnclosingTypeParameterReference isOriginDeclaration bar
          reference: <testLibrary>::@enum::A::@method::bar
          firstFragment: #F11
          returnType: T
''');
  }

  test_method_augmentation_add_inferTypes_ofAugmentation() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  int foo(String a);
}
''');

    var library = await buildLibrary(r'''
import 'a.dart';
enum B implements A {
  v
}

augment enum B {;
  foo(a) => 0;
}
''');

    configuration.withConstantInitializers = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart
      enums
        #F1 enum B (nameOffset:22) (firstTokenOffset:17) (offset:22)
          element: <testLibrary>::@enum::B
          nextFragment: #F2
          fields
            #F3 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:41) (firstTokenOffset:41) (offset:41)
              element: <testLibrary>::@enum::B::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: B @-1
                      element: <testLibrary>::@enum::B
                      type: B
                    element: <testLibrary>::@enum::B::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: B
              inducedGetter: #F4
            #F5 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
              element: <testLibrary>::@enum::B::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::B::@getter::v
                      staticType: B
                  rightBracket: ] @0
                  staticType: List<B>
              inducedGetter: #F6
          constructors
            #F7 isConst isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
              element: <testLibrary>::@enum::B::@constructor::new
              typeName: B
          getters
            #F4 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:41)
              element: <testLibrary>::@enum::B::@getter::v
              inducingVariable: #F3
            #F6 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
              element: <testLibrary>::@enum::B::@getter::values
              inducingVariable: #F5
        #F2 isAugmentation enum B (nameOffset:59) (firstTokenOffset:46) (offset:59)
          element: <testLibrary>::@enum::B
          previousFragment: #F1
          methods
            #F8 hasImplicitReturnType isComplete isOriginDeclaration foo (nameOffset:66) (firstTokenOffset:66) (offset:66)
              element: <testLibrary>::@enum::B::@method::foo
              formalParameters
                #F9 requiredPositional hasImplicitType isOriginDeclaration a (nameOffset:70) (firstTokenOffset:70) (offset:70)
                  element: <testLibrary>::@enum::B::@method::foo::@formalParameter::a
  enums
    isSimplyBounded enum B
      reference: <testLibrary>::@enum::B
      firstFragment: #F1
      supertype: Enum
      interfaces
        A
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::B::@field::v
          firstFragment: #F3
          type: B
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::B::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::B::@field::values
          firstFragment: #F5
          type: List<B>
          constantInitializer
            fragment: #F5
            expression: expression_1
          getter: <testLibrary>::@enum::B::@getter::values
      constructors
        isConst isOriginImplicitDefault new
          reference: <testLibrary>::@enum::B::@constructor::new
          firstFragment: #F7
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::B::@getter::v
          firstFragment: #F4
          returnType: B
          variable: <testLibrary>::@enum::B::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::B::@getter::values
          firstFragment: #F6
          returnType: List<B>
          variable: <testLibrary>::@enum::B::@field::values
      methods
        isOriginDeclaration foo
          reference: <testLibrary>::@enum::B::@method::foo
          firstFragment: #F8
          formalParameters
            #E0 requiredPositional hasImplicitType a
              firstFragment: #F9
              type: String
          returnType: int
''');
  }

  test_method_augmentation_add_inferTypes_usingInterface() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  int foo(String a) => 0;
}
''');

    var library = await buildLibrary(r'''
import 'a.dart';

enum B {
  v;
  foo(a) => 0;
}

augment enum B implements A {}
''');

    configuration.withConstantInitializers = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart
      enums
        #F1 enum B (nameOffset:23) (firstTokenOffset:18) (offset:23)
          element: <testLibrary>::@enum::B
          nextFragment: #F2
          fields
            #F3 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:29) (firstTokenOffset:29) (offset:29)
              element: <testLibrary>::@enum::B::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: B @-1
                      element: <testLibrary>::@enum::B
                      type: B
                    element: <testLibrary>::@enum::B::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: B
              inducedGetter: #F4
            #F5 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
              element: <testLibrary>::@enum::B::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::B::@getter::v
                      staticType: B
                  rightBracket: ] @0
                  staticType: List<B>
              inducedGetter: #F6
          constructors
            #F7 isConst isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
              element: <testLibrary>::@enum::B::@constructor::new
              typeName: B
          getters
            #F4 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:29)
              element: <testLibrary>::@enum::B::@getter::v
              inducingVariable: #F3
            #F6 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
              element: <testLibrary>::@enum::B::@getter::values
              inducingVariable: #F5
          methods
            #F8 hasImplicitReturnType isComplete isOriginDeclaration foo (nameOffset:34) (firstTokenOffset:34) (offset:34)
              element: <testLibrary>::@enum::B::@method::foo
              formalParameters
                #F9 requiredPositional hasImplicitType isOriginDeclaration a (nameOffset:38) (firstTokenOffset:38) (offset:38)
                  element: <testLibrary>::@enum::B::@method::foo::@formalParameter::a
        #F2 isAugmentation enum B (nameOffset:63) (firstTokenOffset:50) (offset:63)
          element: <testLibrary>::@enum::B
          previousFragment: #F1
  enums
    isSimplyBounded enum B
      reference: <testLibrary>::@enum::B
      firstFragment: #F1
      supertype: Enum
      interfaces
        A
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::B::@field::v
          firstFragment: #F3
          type: B
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::B::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::B::@field::values
          firstFragment: #F5
          type: List<B>
          constantInitializer
            fragment: #F5
            expression: expression_1
          getter: <testLibrary>::@enum::B::@getter::values
      constructors
        isConst isOriginImplicitDefault new
          reference: <testLibrary>::@enum::B::@constructor::new
          firstFragment: #F7
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::B::@getter::v
          firstFragment: #F4
          returnType: B
          variable: <testLibrary>::@enum::B::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::B::@getter::values
          firstFragment: #F6
          returnType: List<B>
          variable: <testLibrary>::@enum::B::@field::values
      methods
        isOriginDeclaration foo
          reference: <testLibrary>::@enum::B::@method::foo
          firstFragment: #F8
          formalParameters
            #E0 requiredPositional hasImplicitType a
              firstFragment: #F9
              type: String
          returnType: int
''');
  }

  test_method_augmentation_add_inferTypes_usingMixin() async {
    newFile('$testPackageLibPath/a.dart', r'''
mixin A {
  int foo(String a) => 0;
}
''');

    var library = await buildLibrary(r'''
import 'a.dart';

enum B {
  v;
  foo(a) => 0;
}

augment enum B with A {}
''');

    configuration.withConstantInitializers = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart
      enums
        #F1 enum B (nameOffset:23) (firstTokenOffset:18) (offset:23)
          element: <testLibrary>::@enum::B
          nextFragment: #F2
          fields
            #F3 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:29) (firstTokenOffset:29) (offset:29)
              element: <testLibrary>::@enum::B::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: B @-1
                      element: <testLibrary>::@enum::B
                      type: B
                    element: <testLibrary>::@enum::B::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: B
              inducedGetter: #F4
            #F5 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
              element: <testLibrary>::@enum::B::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::B::@getter::v
                      staticType: B
                  rightBracket: ] @0
                  staticType: List<B>
              inducedGetter: #F6
          constructors
            #F7 isConst isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
              element: <testLibrary>::@enum::B::@constructor::new
              typeName: B
          getters
            #F4 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:29)
              element: <testLibrary>::@enum::B::@getter::v
              inducingVariable: #F3
            #F6 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
              element: <testLibrary>::@enum::B::@getter::values
              inducingVariable: #F5
          methods
            #F8 hasImplicitReturnType isComplete isOriginDeclaration foo (nameOffset:34) (firstTokenOffset:34) (offset:34)
              element: <testLibrary>::@enum::B::@method::foo
              formalParameters
                #F9 requiredPositional hasImplicitType isOriginDeclaration a (nameOffset:38) (firstTokenOffset:38) (offset:38)
                  element: <testLibrary>::@enum::B::@method::foo::@formalParameter::a
        #F2 isAugmentation enum B (nameOffset:63) (firstTokenOffset:50) (offset:63)
          element: <testLibrary>::@enum::B
          previousFragment: #F1
  enums
    isSimplyBounded enum B
      reference: <testLibrary>::@enum::B
      firstFragment: #F1
      supertype: Enum
      mixins
        A
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::B::@field::v
          firstFragment: #F3
          type: B
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::B::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::B::@field::values
          firstFragment: #F5
          type: List<B>
          constantInitializer
            fragment: #F5
            expression: expression_1
          getter: <testLibrary>::@enum::B::@getter::values
      constructors
        isConst isOriginImplicitDefault new
          reference: <testLibrary>::@enum::B::@constructor::new
          firstFragment: #F7
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::B::@getter::v
          firstFragment: #F4
          returnType: B
          variable: <testLibrary>::@enum::B::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::B::@getter::values
          firstFragment: #F6
          returnType: List<B>
          variable: <testLibrary>::@enum::B::@field::values
      methods
        isOriginDeclaration foo
          reference: <testLibrary>::@enum::B::@method::foo
          firstFragment: #F8
          formalParameters
            #E0 requiredPositional hasImplicitType a
              firstFragment: #F9
              type: String
          returnType: int
''');
  }

  test_method_augmentation_add_withDefaultValue() async {
    var library = await buildLibrary(r'''
enum A {
  v
}

augment enum A {;
  void foo([int x = 42]) {}
}
''');

    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      enums
        #F1 enum A (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@enum::A
          nextFragment: #F2
          fields
            #F3 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:11) (firstTokenOffset:11) (offset:11)
              element: <testLibrary>::@enum::A::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibrary>::@enum::A
                      type: A
                    element: <testLibrary>::@enum::A::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              inducedGetter: #F4
            #F5 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::A::@getter::v
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
              inducedGetter: #F6
          constructors
            #F7 isConst isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
          getters
            #F4 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::A::@getter::v
              inducingVariable: #F3
            #F6 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
              inducingVariable: #F5
        #F2 isAugmentation enum A (nameOffset:29) (firstTokenOffset:16) (offset:29)
          element: <testLibrary>::@enum::A
          previousFragment: #F1
          methods
            #F8 isComplete isOriginDeclaration foo (nameOffset:41) (firstTokenOffset:36) (offset:41)
              element: <testLibrary>::@enum::A::@method::foo
              formalParameters
                #F9 optionalPositional isOriginDeclaration x (nameOffset:50) (firstTokenOffset:46) (offset:50)
                  element: <testLibrary>::@enum::A::@method::foo::@formalParameter::x
                  initializer: expression_2
                    IntegerLiteral
                      literal: 42 @54
                      staticType: int
  enums
    isSimplyBounded enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F3
          type: A
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F5
          type: List<A>
          constantInitializer
            fragment: #F5
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
      constructors
        isConst isOriginImplicitDefault new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F7
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F4
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F6
          returnType: List<A>
          variable: <testLibrary>::@enum::A::@field::values
      methods
        isOriginDeclaration foo
          reference: <testLibrary>::@enum::A::@method::foo
          firstFragment: #F8
          formalParameters
            #E0 optionalPositional hasDefaultValue x
              firstFragment: #F9
              type: int
              constantInitializer
                fragment: #F9
                expression: expression_2
          returnType: void
''');
  }

  test_method_augmentation_chain() async {
    var library = await buildLibrary(r'''
enum A {
  v;
  void foo1() {}
  void foo2() {}
}

augment enum A {;
  augment void foo1() {}
}
''');

    configuration.withConstantInitializers = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      enums
        #F1 enum A (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@enum::A
          nextFragment: #F2
          fields
            #F3 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:11) (firstTokenOffset:11) (offset:11)
              element: <testLibrary>::@enum::A::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibrary>::@enum::A
                      type: A
                    element: <testLibrary>::@enum::A::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              inducedGetter: #F4
            #F5 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::A::@getter::v
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
              inducedGetter: #F6
          constructors
            #F7 isConst isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
          getters
            #F4 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::A::@getter::v
              inducingVariable: #F3
            #F6 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
              inducingVariable: #F5
          methods
            #F8 isComplete isOriginDeclaration foo1 (nameOffset:21) (firstTokenOffset:16) (offset:21)
              element: <testLibrary>::@enum::A::@method::foo1
              nextFragment: #F9
            #F10 isComplete isOriginDeclaration foo2 (nameOffset:38) (firstTokenOffset:33) (offset:38)
              element: <testLibrary>::@enum::A::@method::foo2
        #F2 isAugmentation enum A (nameOffset:64) (firstTokenOffset:51) (offset:64)
          element: <testLibrary>::@enum::A
          previousFragment: #F1
          methods
            #F9 isAugmentation isComplete isOriginDeclaration foo1 (nameOffset:84) (firstTokenOffset:71) (offset:84)
              element: <testLibrary>::@enum::A::@method::foo1
              previousFragment: #F8
  enums
    isSimplyBounded enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F3
          type: A
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F5
          type: List<A>
          constantInitializer
            fragment: #F5
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
      constructors
        isConst isOriginImplicitDefault new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F7
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F4
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F6
          returnType: List<A>
          variable: <testLibrary>::@enum::A::@field::values
      methods
        isOriginDeclaration foo1
          reference: <testLibrary>::@enum::A::@method::foo1
          firstFragment: #F8
          returnType: void
        isOriginDeclaration foo2
          reference: <testLibrary>::@enum::A::@method::foo2
          firstFragment: #F10
          returnType: void
''');
  }

  test_method_augmentation_chain_generic() async {
    var library = await buildLibrary(r'''
enum A<T> {
  v<int>();
  T foo() => throw 0;
}

augment enum A<T> {;
  augment T foo() => throw 0;
}
''');

    configuration.withConstantInitializers = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      enums
        #F1 enum A (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@enum::A
          nextFragment: #F2
          typeParameters
            #F3 T (nameOffset:7) (firstTokenOffset:7) (offset:7)
              element: #E0 T
              nextFragment: #F4
          fields
            #F5 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:14) (firstTokenOffset:14) (offset:14)
              element: <testLibrary>::@enum::A::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      typeArguments: TypeArgumentList
                        leftBracket: < @15
                        arguments
                          NamedType
                            name: int @16
                            element: dart:core::@class::int
                            type: int
                        rightBracket: > @19
                      element: <testLibrary>::@enum::A
                      type: A<int>
                    element: SubstitutedConstructorElementImpl
                      baseElement: <testLibrary>::@enum::A::@constructor::new
                      substitution: {T: int}
                  argumentList: ArgumentList
                    leftParenthesis: ( @20
                    rightParenthesis: ) @21
                  staticType: A<int>
              inducedGetter: #F6
            #F7 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::A::@getter::v
                      staticType: A<int>
                  rightBracket: ] @0
                  staticType: List<A<dynamic>>
              inducedGetter: #F8
          constructors
            #F9 isConst isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
          getters
            #F6 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:14)
              element: <testLibrary>::@enum::A::@getter::v
              inducingVariable: #F5
            #F8 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
              inducingVariable: #F7
          methods
            #F10 isComplete isOriginDeclaration foo (nameOffset:28) (firstTokenOffset:26) (offset:28)
              element: <testLibrary>::@enum::A::@method::foo
              nextFragment: #F11
        #F2 isAugmentation enum A (nameOffset:62) (firstTokenOffset:49) (offset:62)
          element: <testLibrary>::@enum::A
          previousFragment: #F1
          typeParameters
            #F4 T (nameOffset:64) (firstTokenOffset:64) (offset:64)
              element: #E0 T
              previousFragment: #F3
          methods
            #F11 isAugmentation isComplete isOriginDeclaration foo (nameOffset:82) (firstTokenOffset:72) (offset:82)
              element: <testLibrary>::@enum::A::@method::foo
              previousFragment: #F10
  enums
    isSimplyBounded enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F3
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F5
          type: A<int>
          constantInitializer
            fragment: #F5
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F7
          type: List<A<dynamic>>
          constantInitializer
            fragment: #F7
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
      constructors
        hasEnclosingTypeParameterReference isConst isOriginImplicitDefault new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F9
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F6
          returnType: A<int>
          variable: <testLibrary>::@enum::A::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F8
          returnType: List<A<dynamic>>
          variable: <testLibrary>::@enum::A::@field::values
      methods
        hasEnclosingTypeParameterReference isOriginDeclaration foo
          reference: <testLibrary>::@enum::A::@method::foo
          firstFragment: #F10
          returnType: T
''');
  }

  test_method_augmentation_chain_twoDeclarations() async {
    var library = await buildLibrary(r'''
enum A {
  v;
  void foo() {}
}

augment enum A {;
  augment void foo() {}
}
augment enum A {;
  augment void foo() {}
}
''');

    configuration.withConstantInitializers = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      enums
        #F1 enum A (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@enum::A
          nextFragment: #F2
          fields
            #F3 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:11) (firstTokenOffset:11) (offset:11)
              element: <testLibrary>::@enum::A::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibrary>::@enum::A
                      type: A
                    element: <testLibrary>::@enum::A::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              inducedGetter: #F4
            #F5 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::A::@getter::v
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
              inducedGetter: #F6
          constructors
            #F7 isConst isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
          getters
            #F4 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::A::@getter::v
              inducingVariable: #F3
            #F6 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
              inducingVariable: #F5
          methods
            #F8 isComplete isOriginDeclaration foo (nameOffset:21) (firstTokenOffset:16) (offset:21)
              element: <testLibrary>::@enum::A::@method::foo
              nextFragment: #F9
        #F2 isAugmentation enum A (nameOffset:46) (firstTokenOffset:33) (offset:46)
          element: <testLibrary>::@enum::A
          previousFragment: #F1
          nextFragment: #F10
          methods
            #F9 isAugmentation isComplete isOriginDeclaration foo (nameOffset:66) (firstTokenOffset:53) (offset:66)
              element: <testLibrary>::@enum::A::@method::foo
              previousFragment: #F8
              nextFragment: #F11
        #F10 isAugmentation enum A (nameOffset:90) (firstTokenOffset:77) (offset:90)
          element: <testLibrary>::@enum::A
          previousFragment: #F2
          methods
            #F11 isAugmentation isComplete isOriginDeclaration foo (nameOffset:110) (firstTokenOffset:97) (offset:110)
              element: <testLibrary>::@enum::A::@method::foo
              previousFragment: #F9
  enums
    isSimplyBounded enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F3
          type: A
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F5
          type: List<A>
          constantInitializer
            fragment: #F5
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
      constructors
        isConst isOriginImplicitDefault new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F7
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F4
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F6
          returnType: List<A>
          variable: <testLibrary>::@enum::A::@field::values
      methods
        isOriginDeclaration foo
          reference: <testLibrary>::@enum::A::@method::foo
          firstFragment: #F8
          returnType: void
''');
  }

  test_method_augmentation_chain_twoInSameDeclaration() async {
    var library = await buildLibrary(r'''
enum A {
  v;
  void foo() {}
}

augment enum A {;
  augment void foo() {}
  augment void foo() {}
}
''');

    configuration.withConstantInitializers = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      enums
        #F1 enum A (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@enum::A
          nextFragment: #F2
          fields
            #F3 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:11) (firstTokenOffset:11) (offset:11)
              element: <testLibrary>::@enum::A::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibrary>::@enum::A
                      type: A
                    element: <testLibrary>::@enum::A::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              inducedGetter: #F4
            #F5 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::A::@getter::v
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
              inducedGetter: #F6
          constructors
            #F7 isConst isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
          getters
            #F4 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::A::@getter::v
              inducingVariable: #F3
            #F6 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
              inducingVariable: #F5
          methods
            #F8 isComplete isOriginDeclaration foo (nameOffset:21) (firstTokenOffset:16) (offset:21)
              element: <testLibrary>::@enum::A::@method::foo
              nextFragment: #F9
        #F2 isAugmentation enum A (nameOffset:46) (firstTokenOffset:33) (offset:46)
          element: <testLibrary>::@enum::A
          previousFragment: #F1
          methods
            #F9 isAugmentation isComplete isOriginDeclaration foo (nameOffset:66) (firstTokenOffset:53) (offset:66)
              element: <testLibrary>::@enum::A::@method::foo
              previousFragment: #F8
              nextFragment: #F10
            #F10 isAugmentation isComplete isOriginDeclaration foo (nameOffset:90) (firstTokenOffset:77) (offset:90)
              element: <testLibrary>::@enum::A::@method::foo
              previousFragment: #F9
  enums
    isSimplyBounded enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F3
          type: A
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F5
          type: List<A>
          constantInitializer
            fragment: #F5
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
      constructors
        isConst isOriginImplicitDefault new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F7
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F4
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F6
          returnType: List<A>
          variable: <testLibrary>::@enum::A::@field::values
      methods
        isOriginDeclaration foo
          reference: <testLibrary>::@enum::A::@method::foo
          firstFragment: #F8
          returnType: void
''');
  }

  test_method_augmentation_chain_typeParameters_count_112() async {
    var library = await buildLibrary(r'''
enum A {
  v;
  void foo<T>() {}
}
augment enum A {;
  augment void foo<T>() {}
}
augment enum A {;
  augment void foo<T, U>() {}
}
''');

    configuration.withConstantInitializers = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      enums
        #F1 enum A (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@enum::A
          nextFragment: #F2
          fields
            #F3 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:11) (firstTokenOffset:11) (offset:11)
              element: <testLibrary>::@enum::A::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibrary>::@enum::A
                      type: A
                    element: <testLibrary>::@enum::A::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              inducedGetter: #F4
            #F5 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::A::@getter::v
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
              inducedGetter: #F6
          constructors
            #F7 isConst isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
          getters
            #F4 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::A::@getter::v
              inducingVariable: #F3
            #F6 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
              inducingVariable: #F5
          methods
            #F8 isComplete isOriginDeclaration foo (nameOffset:21) (firstTokenOffset:16) (offset:21)
              element: <testLibrary>::@enum::A::@method::foo
              nextFragment: #F9
              typeParameters
                #F10 T (nameOffset:25) (firstTokenOffset:25) (offset:25)
                  element: #E0 T
                  nextFragment: #F11
                #F12 isOriginOtherFragmentOfEnclosing U (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
                  element: #E1 U
                  nextFragment: #F13
        #F2 isAugmentation enum A (nameOffset:48) (firstTokenOffset:35) (offset:48)
          element: <testLibrary>::@enum::A
          previousFragment: #F1
          nextFragment: #F14
          methods
            #F9 isAugmentation isComplete isOriginDeclaration foo (nameOffset:68) (firstTokenOffset:55) (offset:68)
              element: <testLibrary>::@enum::A::@method::foo
              previousFragment: #F8
              nextFragment: #F15
              typeParameters
                #F11 T (nameOffset:72) (firstTokenOffset:72) (offset:72)
                  element: #E0 T
                  previousFragment: #F10
                  nextFragment: #F16
                #F13 isOriginOtherFragmentOfEnclosing U (nameOffset:<null>) (firstTokenOffset:<null>) (offset:68)
                  element: #E1 U
                  previousFragment: #F12
                  nextFragment: #F17
        #F14 isAugmentation enum A (nameOffset:95) (firstTokenOffset:82) (offset:95)
          element: <testLibrary>::@enum::A
          previousFragment: #F2
          methods
            #F15 isAugmentation isComplete isOriginDeclaration foo (nameOffset:115) (firstTokenOffset:102) (offset:115)
              element: <testLibrary>::@enum::A::@method::foo
              previousFragment: #F9
              typeParameters
                #F16 T (nameOffset:119) (firstTokenOffset:119) (offset:119)
                  element: #E0 T
                  previousFragment: #F11
                #F17 U (nameOffset:122) (firstTokenOffset:122) (offset:122)
                  element: #E1 U
                  previousFragment: #F13
  enums
    isSimplyBounded enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F3
          type: A
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F5
          type: List<A>
          constantInitializer
            fragment: #F5
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
      constructors
        isConst isOriginImplicitDefault new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F7
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F4
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F6
          returnType: List<A>
          variable: <testLibrary>::@enum::A::@field::values
      methods
        isOriginDeclaration foo
          reference: <testLibrary>::@enum::A::@method::foo
          firstFragment: #F8
          typeParameters
            #E0 T
              firstFragment: #F10
          returnType: void
''');
  }

  test_method_augmentation_chain_typeParameters_count_123() async {
    var library = await buildLibrary(r'''
enum A {
  v;
  void foo<T>() {}
}
augment enum A {;
  augment void foo<T, U>() {}
}
augment enum A {;
  augment void foo<T, U, V>() {}
}
''');

    configuration.withConstantInitializers = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      enums
        #F1 enum A (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@enum::A
          nextFragment: #F2
          fields
            #F3 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:11) (firstTokenOffset:11) (offset:11)
              element: <testLibrary>::@enum::A::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibrary>::@enum::A
                      type: A
                    element: <testLibrary>::@enum::A::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              inducedGetter: #F4
            #F5 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::A::@getter::v
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
              inducedGetter: #F6
          constructors
            #F7 isConst isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
          getters
            #F4 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::A::@getter::v
              inducingVariable: #F3
            #F6 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
              inducingVariable: #F5
          methods
            #F8 isComplete isOriginDeclaration foo (nameOffset:21) (firstTokenOffset:16) (offset:21)
              element: <testLibrary>::@enum::A::@method::foo
              nextFragment: #F9
              typeParameters
                #F10 T (nameOffset:25) (firstTokenOffset:25) (offset:25)
                  element: #E0 T
                  nextFragment: #F11
                #F12 isOriginOtherFragmentOfEnclosing U (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
                  element: #E1 U
                  nextFragment: #F13
                #F14 isOriginOtherFragmentOfEnclosing V (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
                  element: #E2 V
                  nextFragment: #F15
        #F2 isAugmentation enum A (nameOffset:48) (firstTokenOffset:35) (offset:48)
          element: <testLibrary>::@enum::A
          previousFragment: #F1
          nextFragment: #F16
          methods
            #F9 isAugmentation isComplete isOriginDeclaration foo (nameOffset:68) (firstTokenOffset:55) (offset:68)
              element: <testLibrary>::@enum::A::@method::foo
              previousFragment: #F8
              nextFragment: #F17
              typeParameters
                #F11 T (nameOffset:72) (firstTokenOffset:72) (offset:72)
                  element: #E0 T
                  previousFragment: #F10
                  nextFragment: #F18
                #F13 U (nameOffset:75) (firstTokenOffset:75) (offset:75)
                  element: #E1 U
                  previousFragment: #F12
                  nextFragment: #F19
                #F15 isOriginOtherFragmentOfEnclosing V (nameOffset:<null>) (firstTokenOffset:<null>) (offset:68)
                  element: #E2 V
                  previousFragment: #F14
                  nextFragment: #F20
        #F16 isAugmentation enum A (nameOffset:98) (firstTokenOffset:85) (offset:98)
          element: <testLibrary>::@enum::A
          previousFragment: #F2
          methods
            #F17 isAugmentation isComplete isOriginDeclaration foo (nameOffset:118) (firstTokenOffset:105) (offset:118)
              element: <testLibrary>::@enum::A::@method::foo
              previousFragment: #F9
              typeParameters
                #F18 T (nameOffset:122) (firstTokenOffset:122) (offset:122)
                  element: #E0 T
                  previousFragment: #F11
                #F19 U (nameOffset:125) (firstTokenOffset:125) (offset:125)
                  element: #E1 U
                  previousFragment: #F13
                #F20 V (nameOffset:128) (firstTokenOffset:128) (offset:128)
                  element: #E2 V
                  previousFragment: #F15
  enums
    isSimplyBounded enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F3
          type: A
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F5
          type: List<A>
          constantInitializer
            fragment: #F5
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
      constructors
        isConst isOriginImplicitDefault new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F7
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F4
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F6
          returnType: List<A>
          variable: <testLibrary>::@enum::A::@field::values
      methods
        isOriginDeclaration foo
          reference: <testLibrary>::@enum::A::@method::foo
          firstFragment: #F8
          typeParameters
            #E0 T
              firstFragment: #F10
          returnType: void
''');
  }

  test_method_augmentation_chain_typeParameters_count_211() async {
    var library = await buildLibrary(r'''
enum A {
  v;
  void foo<T, U>() {}
}
augment enum A {;
  augment void foo<T>() {}
}
augment enum A {;
  augment void foo<T>() {}
}
''');

    configuration.withConstantInitializers = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      enums
        #F1 enum A (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@enum::A
          nextFragment: #F2
          fields
            #F3 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:11) (firstTokenOffset:11) (offset:11)
              element: <testLibrary>::@enum::A::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibrary>::@enum::A
                      type: A
                    element: <testLibrary>::@enum::A::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              inducedGetter: #F4
            #F5 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::A::@getter::v
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
              inducedGetter: #F6
          constructors
            #F7 isConst isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
          getters
            #F4 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::A::@getter::v
              inducingVariable: #F3
            #F6 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
              inducingVariable: #F5
          methods
            #F8 isComplete isOriginDeclaration foo (nameOffset:21) (firstTokenOffset:16) (offset:21)
              element: <testLibrary>::@enum::A::@method::foo
              nextFragment: #F9
              typeParameters
                #F10 T (nameOffset:25) (firstTokenOffset:25) (offset:25)
                  element: #E0 T
                  nextFragment: #F11
                #F12 U (nameOffset:28) (firstTokenOffset:28) (offset:28)
                  element: #E1 U
                  nextFragment: #F13
        #F2 isAugmentation enum A (nameOffset:51) (firstTokenOffset:38) (offset:51)
          element: <testLibrary>::@enum::A
          previousFragment: #F1
          nextFragment: #F14
          methods
            #F9 isAugmentation isComplete isOriginDeclaration foo (nameOffset:71) (firstTokenOffset:58) (offset:71)
              element: <testLibrary>::@enum::A::@method::foo
              previousFragment: #F8
              nextFragment: #F15
              typeParameters
                #F11 T (nameOffset:75) (firstTokenOffset:75) (offset:75)
                  element: #E0 T
                  previousFragment: #F10
                  nextFragment: #F16
                #F13 isOriginOtherFragmentOfEnclosing U (nameOffset:<null>) (firstTokenOffset:<null>) (offset:71)
                  element: #E1 U
                  previousFragment: #F12
                  nextFragment: #F17
        #F14 isAugmentation enum A (nameOffset:98) (firstTokenOffset:85) (offset:98)
          element: <testLibrary>::@enum::A
          previousFragment: #F2
          methods
            #F15 isAugmentation isComplete isOriginDeclaration foo (nameOffset:118) (firstTokenOffset:105) (offset:118)
              element: <testLibrary>::@enum::A::@method::foo
              previousFragment: #F9
              typeParameters
                #F16 T (nameOffset:122) (firstTokenOffset:122) (offset:122)
                  element: #E0 T
                  previousFragment: #F11
                #F17 isOriginOtherFragmentOfEnclosing U (nameOffset:<null>) (firstTokenOffset:<null>) (offset:118)
                  element: #E1 U
                  previousFragment: #F13
  enums
    isSimplyBounded enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F3
          type: A
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F5
          type: List<A>
          constantInitializer
            fragment: #F5
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
      constructors
        isConst isOriginImplicitDefault new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F7
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F4
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F6
          returnType: List<A>
          variable: <testLibrary>::@enum::A::@field::values
      methods
        isOriginDeclaration foo
          reference: <testLibrary>::@enum::A::@method::foo
          firstFragment: #F8
          typeParameters
            #E0 T
              firstFragment: #F10
            #E1 U
              firstFragment: #F12
          returnType: void
''');
  }

  test_method_metadata() async {
    var library = await buildLibrary(r'''
const a = 42;

enum E {
  v;

  @a
  void foo() {}
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      enums
        #F1 enum E (nameOffset:20) (firstTokenOffset:15) (offset:20)
          element: <testLibrary>::@enum::E
          fields
            #F2 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:26) (firstTokenOffset:26) (offset:26)
              element: <testLibrary>::@enum::E::@field::v
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
              inducedGetter: #F3
            #F4 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:20)
              element: <testLibrary>::@enum::E::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::E::@getter::v
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
              inducedGetter: #F5
          constructors
            #F6 isConst isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:20)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F3 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:26)
              element: <testLibrary>::@enum::E::@getter::v
              inducingVariable: #F2
            #F5 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:20)
              element: <testLibrary>::@enum::E::@getter::values
              inducingVariable: #F4
          methods
            #F7 isComplete isOriginDeclaration foo (nameOffset:42) (firstTokenOffset:32) (offset:42)
              element: <testLibrary>::@enum::E::@method::foo
              metadata
                Annotation
                  atSign: @ @32
                  name: SimpleIdentifier
                    token: a @33
                    element: <testLibrary>::@getter::a
                    staticType: null
                  element: <testLibrary>::@getter::a
      topLevelVariables
        #F8 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic a (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::a
          initializer: expression_2
            IntegerLiteral
              literal: 42 @10
              staticType: int
          inducedGetter: #F9
      getters
        #F9 isComplete isOriginVariable isStatic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
          inducingVariable: #F8
  enums
    isSimplyBounded enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F4
          type: List<E>
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        isConst isOriginImplicitDefault new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F6
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F3
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F5
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
      methods
        isOriginDeclaration foo
          reference: <testLibrary>::@enum::E::@method::foo
          firstFragment: #F7
          metadata
            Annotation
              atSign: @ @32
              name: SimpleIdentifier
                token: a @33
                element: <testLibrary>::@getter::a
                staticType: null
              element: <testLibrary>::@getter::a
          returnType: void
  topLevelVariables
    hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F8
      type: int
      constantInitializer
        fragment: #F8
        expression: expression_2
      getter: <testLibrary>::@getter::a
  getters
    isOriginVariable isStatic a
      reference: <testLibrary>::@getter::a
      firstFragment: #F9
      returnType: int
      variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_method_toString() async {
    var library = await buildLibrary(r'''
enum E {
  v;

  String toString() => 'E';
}
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
            #F2 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:11) (firstTokenOffset:11) (offset:11)
              element: <testLibrary>::@enum::E::@field::v
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
              inducedGetter: #F3
            #F4 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::E::@getter::v
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
              inducedGetter: #F5
          constructors
            #F6 isConst isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F3 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::E::@getter::v
              inducingVariable: #F2
            #F5 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
              inducingVariable: #F4
          methods
            #F7 isComplete isOriginDeclaration toString (nameOffset:24) (firstTokenOffset:17) (offset:24)
              element: <testLibrary>::@enum::E::@method::toString
  enums
    isSimplyBounded enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F4
          type: List<E>
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        isConst isOriginImplicitDefault new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F6
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F3
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F5
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
      methods
        isOriginDeclaration toString
          reference: <testLibrary>::@enum::E::@method::toString
          firstFragment: #F7
          returnType: String
''');
  }

  test_primaryInitializerScope_fieldInitializer_instance() async {
    var library = await buildLibrary(r'''
enum E(int foo) {
  v(0);

  final bar = foo;
}
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
            #F2 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:20) (firstTokenOffset:20) (offset:20)
              element: <testLibrary>::@enum::E::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibrary>::@enum::E
                      type: E
                    element: <testLibrary>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @21
                    arguments
                      IntegerLiteral
                        literal: 0 @22
                        staticType: int
                    rightParenthesis: ) @23
                  staticType: E
              inducedGetter: #F3
            #F4 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::E::@getter::v
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
              inducedGetter: #F5
            #F6 hasImplicitType hasInitializer isFinal isOriginDeclaration bar (nameOffset:35) (firstTokenOffset:35) (offset:35)
              element: <testLibrary>::@enum::E::@field::bar
              initializer: expression_2
                SimpleIdentifier
                  token: foo @41
                  element: <testLibrary>::@enum::E::@constructor::new::@formalParameter::foo
                  staticType: int
              inducedGetter: #F7
          constructors
            #F8 isComplete isConst isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:5) (offset:5)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
              typeNameOffset: 5
              formalParameters
                #F9 requiredPositional isOriginDeclaration foo (nameOffset:11) (firstTokenOffset:7) (offset:11)
                  element: <testLibrary>::@enum::E::@constructor::new::@formalParameter::foo
          getters
            #F3 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:20)
              element: <testLibrary>::@enum::E::@getter::v
              inducingVariable: #F2
            #F5 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
              inducingVariable: #F4
            #F7 isComplete isOriginVariable bar (nameOffset:<null>) (firstTokenOffset:<null>) (offset:35)
              element: <testLibrary>::@enum::E::@getter::bar
              inducingVariable: #F6
  enums
    isSimplyBounded enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F4
          type: List<E>
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
        hasImplicitType hasInitializer isFinal isOriginDeclaration isTypeInferredFromInitializer bar
          reference: <testLibrary>::@enum::E::@field::bar
          firstFragment: #F6
          type: int
          constantInitializer
            fragment: #F6
            expression: expression_2
          getter: <testLibrary>::@enum::E::@getter::bar
      constructors
        isConst isOriginDeclaration isPrimary new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F8
          formalParameters
            #E0 requiredPositional foo
              firstFragment: #F9
              type: int
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F3
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F5
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
        isOriginVariable bar
          reference: <testLibrary>::@enum::E::@getter::bar
          firstFragment: #F7
          returnType: int
          variable: <testLibrary>::@enum::E::@field::bar
''');
  }

  test_primaryInitializerScope_fieldInitializer_instance_declaringFormal() async {
    var library = await buildLibrary(r'''
enum E(final int foo) {
  v(0);

  final bar = foo;
}
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
            #F2 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:26) (firstTokenOffset:26) (offset:26)
              element: <testLibrary>::@enum::E::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibrary>::@enum::E
                      type: E
                    element: <testLibrary>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @27
                    arguments
                      IntegerLiteral
                        literal: 0 @28
                        staticType: int
                    rightParenthesis: ) @29
                  staticType: E
              inducedGetter: #F3
            #F4 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::E::@getter::v
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
              inducedGetter: #F5
            #F6 isFinal isOriginDeclaringFormalParameter foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@field::foo
              inducedGetter: #F7
            #F8 hasImplicitType hasInitializer isFinal isOriginDeclaration bar (nameOffset:41) (firstTokenOffset:41) (offset:41)
              element: <testLibrary>::@enum::E::@field::bar
              initializer: expression_2
                SimpleIdentifier
                  token: foo @47
                  element: <testLibrary>::@enum::E::@constructor::new::@formalParameter::foo
                  staticType: int
              inducedGetter: #F9
          constructors
            #F10 isComplete isConst isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:5) (offset:5)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
              typeNameOffset: 5
              formalParameters
                #F11 requiredPositional isDeclaring isFinal isOriginDeclaration this.foo (nameOffset:17) (firstTokenOffset:7) (offset:17)
                  element: <testLibrary>::@enum::E::@constructor::new::@formalParameter::foo
          getters
            #F3 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:26)
              element: <testLibrary>::@enum::E::@getter::v
              inducingVariable: #F2
            #F5 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
              inducingVariable: #F4
            #F7 isComplete isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::foo
              inducingVariable: #F6
            #F9 isComplete isOriginVariable bar (nameOffset:<null>) (firstTokenOffset:<null>) (offset:41)
              element: <testLibrary>::@enum::E::@getter::bar
              inducingVariable: #F8
  enums
    isSimplyBounded enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F4
          type: List<E>
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
        isFinal isOriginDeclaringFormalParameter foo
          reference: <testLibrary>::@enum::E::@field::foo
          firstFragment: #F6
          type: int
          getter: <testLibrary>::@enum::E::@getter::foo
          declaringFormalParameter: <testLibrary>::@enum::E::@constructor::new::@formalParameter::foo
        hasImplicitType hasInitializer isFinal isOriginDeclaration isTypeInferredFromInitializer bar
          reference: <testLibrary>::@enum::E::@field::bar
          firstFragment: #F8
          type: int
          constantInitializer
            fragment: #F8
            expression: expression_2
          getter: <testLibrary>::@enum::E::@getter::bar
      constructors
        isConst isOriginDeclaration isPrimary new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F10
          formalParameters
            #E0 requiredPositional isDeclaring isFinal this.foo
              firstFragment: #F11
              type: int
              field: <testLibrary>::@enum::E::@field::foo
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F3
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F5
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
        isOriginVariable foo
          reference: <testLibrary>::@enum::E::@getter::foo
          firstFragment: #F7
          returnType: int
          variable: <testLibrary>::@enum::E::@field::foo
        isOriginVariable bar
          reference: <testLibrary>::@enum::E::@getter::bar
          firstFragment: #F9
          returnType: int
          variable: <testLibrary>::@enum::E::@field::bar
''');
  }

  test_primaryInitializerScope_fieldInitializer_instance_late() async {
    var library = await buildLibrary(r'''
enum E(int foo) {
  v(0);

  late final bar = foo;
}
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
            #F2 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:20) (firstTokenOffset:20) (offset:20)
              element: <testLibrary>::@enum::E::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibrary>::@enum::E
                      type: E
                    element: <testLibrary>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @21
                    arguments
                      IntegerLiteral
                        literal: 0 @22
                        staticType: int
                    rightParenthesis: ) @23
                  staticType: E
              inducedGetter: #F3
            #F4 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::E::@getter::v
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
              inducedGetter: #F5
            #F6 hasImplicitType hasInitializer isFinal isLate isOriginDeclaration bar (nameOffset:40) (firstTokenOffset:40) (offset:40)
              element: <testLibrary>::@enum::E::@field::bar
              initializer: expression_2
                SimpleIdentifier
                  token: foo @46
                  element: <null>
                  staticType: InvalidType
              inducedGetter: #F7
          constructors
            #F8 isComplete isConst isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:5) (offset:5)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
              typeNameOffset: 5
              formalParameters
                #F9 requiredPositional isOriginDeclaration foo (nameOffset:11) (firstTokenOffset:7) (offset:11)
                  element: <testLibrary>::@enum::E::@constructor::new::@formalParameter::foo
          getters
            #F3 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:20)
              element: <testLibrary>::@enum::E::@getter::v
              inducingVariable: #F2
            #F5 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
              inducingVariable: #F4
            #F7 isComplete isOriginVariable bar (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
              element: <testLibrary>::@enum::E::@getter::bar
              inducingVariable: #F6
  enums
    isSimplyBounded enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F4
          type: List<E>
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
        hasImplicitType hasInitializer isFinal isLate isOriginDeclaration isTypeInferredFromInitializer bar
          reference: <testLibrary>::@enum::E::@field::bar
          firstFragment: #F6
          type: InvalidType
          constantInitializer
            fragment: #F6
            expression: expression_2
          getter: <testLibrary>::@enum::E::@getter::bar
      constructors
        isConst isOriginDeclaration isPrimary new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F8
          formalParameters
            #E0 requiredPositional foo
              firstFragment: #F9
              type: int
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F3
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F5
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
        isOriginVariable bar
          reference: <testLibrary>::@enum::E::@getter::bar
          firstFragment: #F7
          returnType: InvalidType
          variable: <testLibrary>::@enum::E::@field::bar
''');
  }

  test_primaryInitializerScope_fieldInitializer_instance_typePromotion() async {
    var library = await buildLibrary(r'''
enum E(int? foo) {
  v(0);

  final bar = foo != null ? foo : 0;
}
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
            #F2 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:21) (firstTokenOffset:21) (offset:21)
              element: <testLibrary>::@enum::E::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibrary>::@enum::E
                      type: E
                    element: <testLibrary>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @22
                    arguments
                      IntegerLiteral
                        literal: 0 @23
                        staticType: int
                    rightParenthesis: ) @24
                  staticType: E
              inducedGetter: #F3
            #F4 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::E::@getter::v
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
              inducedGetter: #F5
            #F6 hasImplicitType hasInitializer isFinal isOriginDeclaration bar (nameOffset:36) (firstTokenOffset:36) (offset:36)
              element: <testLibrary>::@enum::E::@field::bar
              initializer: expression_2
                ConditionalExpression
                  condition: BinaryExpression
                    leftOperand: SimpleIdentifier
                      token: foo @42
                      element: <testLibrary>::@enum::E::@constructor::new::@formalParameter::foo
                      staticType: int?
                    operator: != @46
                    rightOperand: NullLiteral
                      literal: null @49
                      staticType: Null
                    element: dart:core::@class::num::@method::==
                    staticInvokeType: bool Function(Object)
                    staticType: bool
                  question: ? @54
                  thenExpression: SimpleIdentifier
                    token: foo @56
                    element: <testLibrary>::@enum::E::@constructor::new::@formalParameter::foo
                    staticType: int
                  colon: : @60
                  elseExpression: IntegerLiteral
                    literal: 0 @62
                    staticType: int
                  staticType: int
              inducedGetter: #F7
          constructors
            #F8 isComplete isConst isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:5) (offset:5)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
              typeNameOffset: 5
              formalParameters
                #F9 requiredPositional isOriginDeclaration foo (nameOffset:12) (firstTokenOffset:7) (offset:12)
                  element: <testLibrary>::@enum::E::@constructor::new::@formalParameter::foo
          getters
            #F3 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@enum::E::@getter::v
              inducingVariable: #F2
            #F5 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
              inducingVariable: #F4
            #F7 isComplete isOriginVariable bar (nameOffset:<null>) (firstTokenOffset:<null>) (offset:36)
              element: <testLibrary>::@enum::E::@getter::bar
              inducingVariable: #F6
  enums
    isSimplyBounded enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F4
          type: List<E>
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
        hasImplicitType hasInitializer isFinal isOriginDeclaration isTypeInferredFromInitializer bar
          reference: <testLibrary>::@enum::E::@field::bar
          firstFragment: #F6
          type: int
          constantInitializer
            fragment: #F6
            expression: expression_2
          getter: <testLibrary>::@enum::E::@getter::bar
      constructors
        isConst isOriginDeclaration isPrimary new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F8
          formalParameters
            #E0 requiredPositional foo
              firstFragment: #F9
              type: int?
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F3
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F5
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
        isOriginVariable bar
          reference: <testLibrary>::@enum::E::@getter::bar
          firstFragment: #F7
          returnType: int
          variable: <testLibrary>::@enum::E::@field::bar
''');
  }

  test_primaryInitializerScope_fieldInitializer_static() async {
    var library = await buildLibrary(r'''
enum E(int foo) {
  v(0);

  static final bar = foo;
}
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
            #F2 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:20) (firstTokenOffset:20) (offset:20)
              element: <testLibrary>::@enum::E::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibrary>::@enum::E
                      type: E
                    element: <testLibrary>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @21
                    arguments
                      IntegerLiteral
                        literal: 0 @22
                        staticType: int
                    rightParenthesis: ) @23
                  staticType: E
              inducedGetter: #F3
            #F4 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::E::@getter::v
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
              inducedGetter: #F5
            #F6 hasImplicitType hasInitializer isFinal isOriginDeclaration isStatic bar (nameOffset:42) (firstTokenOffset:42) (offset:42)
              element: <testLibrary>::@enum::E::@field::bar
              inducedGetter: #F7
          constructors
            #F8 isComplete isConst isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:5) (offset:5)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
              typeNameOffset: 5
              formalParameters
                #F9 requiredPositional isOriginDeclaration foo (nameOffset:11) (firstTokenOffset:7) (offset:11)
                  element: <testLibrary>::@enum::E::@constructor::new::@formalParameter::foo
          getters
            #F3 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:20)
              element: <testLibrary>::@enum::E::@getter::v
              inducingVariable: #F2
            #F5 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
              inducingVariable: #F4
            #F7 isComplete isOriginVariable isStatic bar (nameOffset:<null>) (firstTokenOffset:<null>) (offset:42)
              element: <testLibrary>::@enum::E::@getter::bar
              inducingVariable: #F6
  enums
    isSimplyBounded enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F4
          type: List<E>
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
        hasImplicitType hasInitializer isFinal isOriginDeclaration isStatic isTypeInferredFromInitializer bar
          reference: <testLibrary>::@enum::E::@field::bar
          firstFragment: #F6
          type: InvalidType
          getter: <testLibrary>::@enum::E::@getter::bar
      constructors
        isConst isOriginDeclaration isPrimary new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F8
          formalParameters
            #E0 requiredPositional foo
              firstFragment: #F9
              type: int
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F3
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F5
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
        isOriginVariable isStatic bar
          reference: <testLibrary>::@enum::E::@getter::bar
          firstFragment: #F7
          returnType: InvalidType
          variable: <testLibrary>::@enum::E::@field::bar
''');
  }

  test_setter() async {
    var library = await buildLibrary(r'''
enum E {
  v;

  set foo(int _) {}
}
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
            #F2 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:11) (firstTokenOffset:11) (offset:11)
              element: <testLibrary>::@enum::E::@field::v
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
              inducedGetter: #F3
            #F4 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::E::@getter::v
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
              inducedGetter: #F5
            #F6 isOriginGetterSetter foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@field::foo
          constructors
            #F7 isConst isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F3 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::E::@getter::v
              inducingVariable: #F2
            #F5 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
              inducingVariable: #F4
          setters
            #F8 hasImplicitReturnType isComplete isOriginDeclaration foo (nameOffset:21) (firstTokenOffset:17) (offset:21)
              element: <testLibrary>::@enum::E::@setter::foo
              formalParameters
                #F9 requiredPositional isOriginDeclaration _ (nameOffset:29) (firstTokenOffset:25) (offset:29)
                  element: <testLibrary>::@enum::E::@setter::foo::@formalParameter::_
  enums
    isSimplyBounded enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F4
          type: List<E>
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
        isOriginGetterSetter foo
          reference: <testLibrary>::@enum::E::@field::foo
          firstFragment: #F6
          type: int
          setter: <testLibrary>::@enum::E::@setter::foo
      constructors
        isConst isOriginImplicitDefault new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F7
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F3
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F5
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
      setters
        isOriginDeclaration foo
          reference: <testLibrary>::@enum::E::@setter::foo
          firstFragment: #F8
          formalParameters
            #E0 requiredPositional _
              firstFragment: #F9
              type: int
          returnType: void
          variable: <testLibrary>::@enum::E::@field::foo
''');
  }

  test_setter_augmentation_add() async {
    var library = await buildLibrary(r'''
enum A {
  v;
  set foo1(int _) {}
}

augment enum A {;
  set foo2(int _) {}
}
''');

    configuration.withConstantInitializers = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      enums
        #F1 enum A (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@enum::A
          nextFragment: #F2
          fields
            #F3 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:11) (firstTokenOffset:11) (offset:11)
              element: <testLibrary>::@enum::A::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibrary>::@enum::A
                      type: A
                    element: <testLibrary>::@enum::A::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              inducedGetter: #F4
            #F5 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::A::@getter::v
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
              inducedGetter: #F6
            #F7 isOriginGetterSetter foo1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@field::foo1
          constructors
            #F8 isConst isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
          getters
            #F4 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::A::@getter::v
              inducingVariable: #F3
            #F6 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
              inducingVariable: #F5
          setters
            #F9 hasImplicitReturnType isComplete isOriginDeclaration foo1 (nameOffset:20) (firstTokenOffset:16) (offset:20)
              element: <testLibrary>::@enum::A::@setter::foo1
              formalParameters
                #F10 requiredPositional isOriginDeclaration _ (nameOffset:29) (firstTokenOffset:25) (offset:29)
                  element: <testLibrary>::@enum::A::@setter::foo1::@formalParameter::_
        #F2 isAugmentation enum A (nameOffset:51) (firstTokenOffset:38) (offset:51)
          element: <testLibrary>::@enum::A
          previousFragment: #F1
          fields
            #F11 isOriginGetterSetter foo2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:51)
              element: <testLibrary>::@enum::A::@field::foo2
          setters
            #F12 hasImplicitReturnType isComplete isOriginDeclaration foo2 (nameOffset:62) (firstTokenOffset:58) (offset:62)
              element: <testLibrary>::@enum::A::@setter::foo2
              formalParameters
                #F13 requiredPositional isOriginDeclaration _ (nameOffset:71) (firstTokenOffset:67) (offset:71)
                  element: <testLibrary>::@enum::A::@setter::foo2::@formalParameter::_
  enums
    isSimplyBounded enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F3
          type: A
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F5
          type: List<A>
          constantInitializer
            fragment: #F5
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
        isOriginGetterSetter foo1
          reference: <testLibrary>::@enum::A::@field::foo1
          firstFragment: #F7
          type: int
          setter: <testLibrary>::@enum::A::@setter::foo1
        isOriginGetterSetter foo2
          reference: <testLibrary>::@enum::A::@field::foo2
          firstFragment: #F11
          type: int
          setter: <testLibrary>::@enum::A::@setter::foo2
      constructors
        isConst isOriginImplicitDefault new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F8
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F4
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F6
          returnType: List<A>
          variable: <testLibrary>::@enum::A::@field::values
      setters
        isOriginDeclaration foo1
          reference: <testLibrary>::@enum::A::@setter::foo1
          firstFragment: #F9
          formalParameters
            #E0 requiredPositional _
              firstFragment: #F10
              type: int
          returnType: void
          variable: <testLibrary>::@enum::A::@field::foo1
        isOriginDeclaration foo2
          reference: <testLibrary>::@enum::A::@setter::foo2
          firstFragment: #F12
          formalParameters
            #E1 requiredPositional _
              firstFragment: #F13
              type: int
          returnType: void
          variable: <testLibrary>::@enum::A::@field::foo2
''');
  }

  test_setter_augmentation_chain() async {
    var library = await buildLibrary(r'''
enum A {
  v;
  set foo1(int _) {}
  set foo2(int _) {}
}

augment enum A {;
  augment set foo1(int _) {}
}
''');

    configuration.withConstantInitializers = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      enums
        #F1 enum A (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@enum::A
          nextFragment: #F2
          fields
            #F3 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:11) (firstTokenOffset:11) (offset:11)
              element: <testLibrary>::@enum::A::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibrary>::@enum::A
                      type: A
                    element: <testLibrary>::@enum::A::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              inducedGetter: #F4
            #F5 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::A::@getter::v
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
              inducedGetter: #F6
            #F7 isOriginGetterSetter foo1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@field::foo1
            #F8 isOriginGetterSetter foo2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@field::foo2
          constructors
            #F9 isConst isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
          getters
            #F4 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::A::@getter::v
              inducingVariable: #F3
            #F6 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
              inducingVariable: #F5
          setters
            #F10 hasImplicitReturnType isComplete isOriginDeclaration foo1 (nameOffset:20) (firstTokenOffset:16) (offset:20)
              element: <testLibrary>::@enum::A::@setter::foo1
              formalParameters
                #F11 requiredPositional isOriginDeclaration _ (nameOffset:29) (firstTokenOffset:25) (offset:29)
                  element: <testLibrary>::@enum::A::@setter::foo1::@formalParameter::_
                  nextFragment: #F12
              nextFragment: #F13
            #F14 hasImplicitReturnType isComplete isOriginDeclaration foo2 (nameOffset:41) (firstTokenOffset:37) (offset:41)
              element: <testLibrary>::@enum::A::@setter::foo2
              formalParameters
                #F15 requiredPositional isOriginDeclaration _ (nameOffset:50) (firstTokenOffset:46) (offset:50)
                  element: <testLibrary>::@enum::A::@setter::foo2::@formalParameter::_
        #F2 isAugmentation enum A (nameOffset:72) (firstTokenOffset:59) (offset:72)
          element: <testLibrary>::@enum::A
          previousFragment: #F1
          setters
            #F13 hasImplicitReturnType isAugmentation isComplete isOriginDeclaration foo1 (nameOffset:91) (firstTokenOffset:79) (offset:91)
              element: <testLibrary>::@enum::A::@setter::foo1
              formalParameters
                #F12 requiredPositional isOriginDeclaration _ (nameOffset:100) (firstTokenOffset:96) (offset:100)
                  element: <testLibrary>::@enum::A::@setter::foo1::@formalParameter::_
                  previousFragment: #F11
              previousFragment: #F10
  enums
    isSimplyBounded enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F3
          type: A
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F5
          type: List<A>
          constantInitializer
            fragment: #F5
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
        isOriginGetterSetter foo1
          reference: <testLibrary>::@enum::A::@field::foo1
          firstFragment: #F7
          type: int
          setter: <testLibrary>::@enum::A::@setter::foo1
        isOriginGetterSetter foo2
          reference: <testLibrary>::@enum::A::@field::foo2
          firstFragment: #F8
          type: int
          setter: <testLibrary>::@enum::A::@setter::foo2
      constructors
        isConst isOriginImplicitDefault new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F9
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F4
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F6
          returnType: List<A>
          variable: <testLibrary>::@enum::A::@field::values
      setters
        isOriginDeclaration foo1
          reference: <testLibrary>::@enum::A::@setter::foo1
          firstFragment: #F10
          formalParameters
            #E0 requiredPositional _
              firstFragment: #F11
              type: int
          returnType: void
          variable: <testLibrary>::@enum::A::@field::foo1
        isOriginDeclaration foo2
          reference: <testLibrary>::@enum::A::@setter::foo2
          firstFragment: #F14
          formalParameters
            #E1 requiredPositional _
              firstFragment: #F15
              type: int
          returnType: void
          variable: <testLibrary>::@enum::A::@field::foo2
''');
  }

  test_setter_augmentation_chain_fromField() async {
    var library = await buildLibrary(r'''
enum A {
  v;
  final int foo = 0;
}

augment enum A {;
  augment set foo(int _) {}
}
''');

    configuration.withConstantInitializers = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      enums
        #F1 enum A (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@enum::A
          nextFragment: #F2
          fields
            #F3 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:11) (firstTokenOffset:11) (offset:11)
              element: <testLibrary>::@enum::A::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibrary>::@enum::A
                      type: A
                    element: <testLibrary>::@enum::A::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              inducedGetter: #F4
            #F5 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::A::@getter::v
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
              inducedGetter: #F6
            #F7 hasInitializer isFinal isOriginDeclaration foo (nameOffset:26) (firstTokenOffset:26) (offset:26)
              element: <testLibrary>::@enum::A::@field::foo
              initializer: expression_2
                IntegerLiteral
                  literal: 0 @32
                  staticType: int
              inducedGetter: #F8
          constructors
            #F9 isConst isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
          getters
            #F4 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::A::@getter::v
              inducingVariable: #F3
            #F6 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
              inducingVariable: #F5
            #F8 isComplete isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:26)
              element: <testLibrary>::@enum::A::@getter::foo
              inducingVariable: #F7
        #F2 isAugmentation enum A (nameOffset:51) (firstTokenOffset:38) (offset:51)
          element: <testLibrary>::@enum::A
          previousFragment: #F1
          setters
            #F10 hasImplicitReturnType isAugmentation isComplete isOriginDeclaration foo (nameOffset:70) (firstTokenOffset:58) (offset:70)
              element: <testLibrary>::@enum::A::@setter::foo
              formalParameters
                #F11 requiredPositional isOriginDeclaration _ (nameOffset:78) (firstTokenOffset:74) (offset:78)
                  element: <testLibrary>::@enum::A::@setter::foo::@formalParameter::_
  enums
    isSimplyBounded enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F3
          type: A
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F5
          type: List<A>
          constantInitializer
            fragment: #F5
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
        hasInitializer isFinal isOriginDeclaration foo
          reference: <testLibrary>::@enum::A::@field::foo
          firstFragment: #F7
          type: int
          constantInitializer
            fragment: #F7
            expression: expression_2
          getter: <testLibrary>::@enum::A::@getter::foo
          setter: <testLibrary>::@enum::A::@setter::foo
      constructors
        isConst isOriginImplicitDefault new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F9
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F4
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F6
          returnType: List<A>
          variable: <testLibrary>::@enum::A::@field::values
        isOriginVariable foo
          reference: <testLibrary>::@enum::A::@getter::foo
          firstFragment: #F8
          returnType: int
          variable: <testLibrary>::@enum::A::@field::foo
      setters
        isOriginDeclaration foo
          reference: <testLibrary>::@enum::A::@setter::foo
          firstFragment: #F10
          previousFragmentOfDifferentKind: #F7
          formalParameters
            #E0 requiredPositional _
              firstFragment: #F11
              type: int
          returnType: void
          variable: <testLibrary>::@enum::A::@field::foo
''');
  }

  test_setter_augmentation_chain_noIntroductoryDeclaration() async {
    var library = await buildLibrary(r'''
enum A {
  v
}

augment enum A {;
  augment set foo(int _) {}
}
''');

    configuration.withConstantInitializers = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      enums
        #F1 enum A (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@enum::A
          nextFragment: #F2
          fields
            #F3 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:11) (firstTokenOffset:11) (offset:11)
              element: <testLibrary>::@enum::A::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibrary>::@enum::A
                      type: A
                    element: <testLibrary>::@enum::A::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              inducedGetter: #F4
            #F5 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::A::@getter::v
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
              inducedGetter: #F6
          constructors
            #F7 isConst isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
          getters
            #F4 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::A::@getter::v
              inducingVariable: #F3
            #F6 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
              inducingVariable: #F5
        #F2 isAugmentation enum A (nameOffset:29) (firstTokenOffset:16) (offset:29)
          element: <testLibrary>::@enum::A
          previousFragment: #F1
          fields
            #F8 isOriginGetterSetter foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:29)
              element: <testLibrary>::@enum::A::@field::foo
          setters
            #F9 hasImplicitReturnType isAugmentation isComplete isOriginDeclaration foo (nameOffset:48) (firstTokenOffset:36) (offset:48)
              element: <testLibrary>::@enum::A::@setter::foo
              formalParameters
                #F10 requiredPositional isOriginDeclaration _ (nameOffset:56) (firstTokenOffset:52) (offset:56)
                  element: <testLibrary>::@enum::A::@setter::foo::@formalParameter::_
  enums
    isSimplyBounded enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F3
          type: A
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F5
          type: List<A>
          constantInitializer
            fragment: #F5
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
        isOriginGetterSetter foo
          reference: <testLibrary>::@enum::A::@field::foo
          firstFragment: #F8
          type: int
          setter: <testLibrary>::@enum::A::@setter::foo
      constructors
        isConst isOriginImplicitDefault new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F7
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F4
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F6
          returnType: List<A>
          variable: <testLibrary>::@enum::A::@field::values
      setters
        isOriginDeclaration foo
          reference: <testLibrary>::@enum::A::@setter::foo
          firstFragment: #F9
          formalParameters
            #E0 requiredPositional _
              firstFragment: #F10
              type: int
          returnType: void
          variable: <testLibrary>::@enum::A::@field::foo
''');
  }
}

@reflectiveTest
class EnumElementTest_fromBytes extends EnumElementTest {
  @override
  bool get keepLinkingLibraries => false;
}

@reflectiveTest
class EnumElementTest_keepLinking extends EnumElementTest {
  @override
  bool get keepLinkingLibraries => true;
}
