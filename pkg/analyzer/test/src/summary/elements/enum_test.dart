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
    defineReflectiveTests(EnumElementTest_augmentation_keepLinking);
    defineReflectiveTests(EnumElementTest_augmentation_fromBytes);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

abstract class EnumElementTest extends ElementsBaseTest {
  test_codeRange_enum() async {
    var library = await buildLibrary('''
enum E {
  aaa, bbb, ccc
}
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
            #F2 hasInitializer isOriginDeclaration aaa (nameOffset:11) (firstTokenOffset:11) (offset:11)
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
            #F3 hasInitializer isOriginDeclaration bbb (nameOffset:16) (firstTokenOffset:16) (offset:16)
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
            #F4 hasInitializer isOriginDeclaration ccc (nameOffset:21) (firstTokenOffset:21) (offset:21)
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
            #F5 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
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
          constructors
            #F6 const isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F7 isOriginVariable aaa (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::E::@getter::aaa
            #F8 isOriginVariable bbb (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@enum::E::@getter::bbb
            #F9 isOriginVariable ccc (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@enum::E::@getter::ccc
            #F10 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration aaa
          reference: <testLibrary>::@enum::E::@field::aaa
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::aaa
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration bbb
          reference: <testLibrary>::@enum::E::@field::bbb
          firstFragment: #F3
          type: E
          constantInitializer
            fragment: #F3
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::bbb
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration ccc
          reference: <testLibrary>::@enum::E::@field::ccc
          firstFragment: #F4
          type: E
          constantInitializer
            fragment: #F4
            expression: expression_2
          getter: <testLibrary>::@enum::E::@getter::ccc
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F5
          type: List<E>
          constantInitializer
            fragment: #F5
            expression: expression_3
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        const isOriginImplicitDefault new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F6
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable aaa
          reference: <testLibrary>::@enum::E::@getter::aaa
          firstFragment: #F7
          returnType: E
          variable: <testLibrary>::@enum::E::@field::aaa
        static isOriginVariable bbb
          reference: <testLibrary>::@enum::E::@getter::bbb
          firstFragment: #F8
          returnType: E
          variable: <testLibrary>::@enum::E::@field::bbb
        static isOriginVariable ccc
          reference: <testLibrary>::@enum::E::@getter::ccc
          firstFragment: #F9
          returnType: E
          variable: <testLibrary>::@enum::E::@field::ccc
        static isOriginVariable values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F10
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
''');
  }

  test_enum_constant_arguments_symbolLiteral() async {
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
            #F2 hasInitializer isOriginDeclaration v (nameOffset:11) (firstTokenOffset:11) (offset:11)
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
                          foo
                            offset: 14
                          bar
                            offset: 18
                    rightParenthesis: ) @21
                  staticType: E
            #F3 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
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
          constructors
            #F4 const isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:26) (offset:32)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
              typeNameOffset: 32
              formalParameters
                #F5 requiredPositional _ (nameOffset:41) (firstTokenOffset:34) (offset:41)
                  element: <testLibrary>::@enum::E::@constructor::new::@formalParameter::_
          getters
            #F6 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::E::@getter::v
            #F7 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F3
          type: List<E>
          constantInitializer
            fragment: #F3
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        const isOriginDeclaration new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional _
              firstFragment: #F5
              type: Object
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F6
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F7
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
''');
  }

  test_enum_constant_inference() async {
    var library = await buildLibrary(r'''
enum E<T> {
  int(1), string('2');
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
            #F3 hasInitializer isOriginDeclaration int (nameOffset:14) (firstTokenOffset:14) (offset:14)
              element: <testLibrary>::@enum::E::@field::int
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibrary>::@enum::E
                      type: E<int>
                    element: ConstructorMember
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
            #F4 hasInitializer isOriginDeclaration string (nameOffset:22) (firstTokenOffset:22) (offset:22)
              element: <testLibrary>::@enum::E::@field::string
              initializer: expression_1
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibrary>::@enum::E
                      type: E<String>
                    element: ConstructorMember
                      baseElement: <testLibrary>::@enum::E::@constructor::new
                      substitution: {T: String}
                  argumentList: ArgumentList
                    leftParenthesis: ( @28
                    arguments
                      SimpleStringLiteral
                        literal: '2' @29
                    rightParenthesis: ) @32
                  staticType: E<String>
            #F5 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
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
          constructors
            #F6 const isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:37) (offset:43)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
              typeNameOffset: 43
              formalParameters
                #F7 requiredPositional a (nameOffset:47) (firstTokenOffset:45) (offset:47)
                  element: <testLibrary>::@enum::E::@constructor::new::@formalParameter::a
          getters
            #F8 isOriginVariable int (nameOffset:<null>) (firstTokenOffset:<null>) (offset:14)
              element: <testLibrary>::@enum::E::@getter::int
            #F9 isOriginVariable string (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
              element: <testLibrary>::@enum::E::@getter::string
            #F10 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration int
          reference: <testLibrary>::@enum::E::@field::int
          firstFragment: #F3
          type: E<int>
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::int
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration string
          reference: <testLibrary>::@enum::E::@field::string
          firstFragment: #F4
          type: E<String>
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::string
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F5
          type: List<E<dynamic>>
          constantInitializer
            fragment: #F5
            expression: expression_2
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        const isOriginDeclaration new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F6
          formalParameters
            #E1 requiredPositional a
              firstFragment: #F7
              type: T
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable int
          reference: <testLibrary>::@enum::E::@getter::int
          firstFragment: #F8
          returnType: E<int>
          variable: <testLibrary>::@enum::E::@field::int
        static isOriginVariable string
          reference: <testLibrary>::@enum::E::@getter::string
          firstFragment: #F9
          returnType: E<String>
          variable: <testLibrary>::@enum::E::@field::string
        static isOriginVariable values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F10
          returnType: List<E<dynamic>>
          variable: <testLibrary>::@enum::E::@field::values
''');
  }

  /// Test that a constant named `_name` renames the synthetic `name` field.
  test_enum_constant_name() async {
    var library = await buildLibrary(r'''
enum E {
  _name;
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
            #F2 hasInitializer isOriginDeclaration _name (nameOffset:11) (firstTokenOffset:11) (offset:11)
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
            #F3 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
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
          constructors
            #F4 const isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F5 isOriginVariable _name (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::E::@getter::_name
            #F6 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration _name
          reference: <testLibrary>::@enum::E::@field::_name
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::_name
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F3
          type: List<E>
          constantInitializer
            fragment: #F3
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        const isOriginImplicitDefault new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F4
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable _name
          reference: <testLibrary>::@enum::E::@getter::_name
          firstFragment: #F5
          returnType: E
          variable: <testLibrary>::@enum::E::@field::_name
        static isOriginVariable values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F6
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
''');
  }

  test_enum_constant_typeArguments() async {
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
            #F3 hasInitializer isOriginDeclaration v (nameOffset:14) (firstTokenOffset:14) (offset:14)
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
                    element: ConstructorMember
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
            #F4 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
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
          constructors
            #F5 const isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:31) (offset:37)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
              typeNameOffset: 37
              formalParameters
                #F6 requiredPositional a (nameOffset:41) (firstTokenOffset:39) (offset:41)
                  element: <testLibrary>::@enum::E::@constructor::new::@formalParameter::a
          getters
            #F7 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:14)
              element: <testLibrary>::@enum::E::@getter::v
            #F8 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F3
          type: E<double>
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F4
          type: List<E<dynamic>>
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        const isOriginDeclaration new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F5
          formalParameters
            #E1 requiredPositional a
              firstFragment: #F6
              type: T
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F7
          returnType: E<double>
          variable: <testLibrary>::@enum::E::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F8
          returnType: List<E<dynamic>>
          variable: <testLibrary>::@enum::E::@field::values
''');
  }

  test_enum_constant_underscore() async {
    var library = await buildLibrary('''
enum E {
  _
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
            #F2 hasInitializer isOriginDeclaration _ (nameOffset:11) (firstTokenOffset:11) (offset:11)
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
            #F3 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
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
          constructors
            #F4 const isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F5 isOriginVariable _ (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::E::@getter::_
            #F6 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration _
          reference: <testLibrary>::@enum::E::@field::_
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::_
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F3
          type: List<E>
          constantInitializer
            fragment: #F3
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        const isOriginImplicitDefault new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F4
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable _
          reference: <testLibrary>::@enum::E::@getter::_
          firstFragment: #F5
          returnType: E
          variable: <testLibrary>::@enum::E::@field::_
        static isOriginVariable values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F6
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
''');
  }

  test_enum_constructor_factory_named() async {
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
            #F2 hasInitializer isOriginDeclaration v (nameOffset:11) (firstTokenOffset:11) (offset:11)
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
            #F3 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
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
          constructors
            #F4 factory isOriginDeclaration named (nameOffset:26) (firstTokenOffset:16) (offset:26)
              element: <testLibrary>::@enum::E::@constructor::named
              factoryKeywordOffset: 16
              typeName: E
              typeNameOffset: 24
              periodOffset: 25
            #F5 const isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F6 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::E::@getter::v
            #F7 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F3
          type: List<E>
          constantInitializer
            fragment: #F3
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        factory isOriginDeclaration named
          reference: <testLibrary>::@enum::E::@constructor::named
          firstFragment: #F4
        const isOriginImplicitDefault new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F5
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F6
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F7
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
''');
  }

  test_enum_constructor_factory_unnamed() async {
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
            #F2 hasInitializer isOriginDeclaration v (nameOffset:11) (firstTokenOffset:11) (offset:11)
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
            #F3 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
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
          constructors
            #F4 factory isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:16) (offset:24)
              element: <testLibrary>::@enum::E::@constructor::new
              factoryKeywordOffset: 16
              typeName: E
              typeNameOffset: 24
          getters
            #F5 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::E::@getter::v
            #F6 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F3
          type: List<E>
          constantInitializer
            fragment: #F3
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        factory isOriginDeclaration new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F4
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F5
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F6
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
''');
  }

  test_enum_constructor_factoryHead_named() async {
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
            #F2 hasInitializer isOriginDeclaration v (nameOffset:11) (firstTokenOffset:11) (offset:11)
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
            #F3 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
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
          constructors
            #F4 factory isOriginDeclaration named (nameOffset:24) (firstTokenOffset:16) (offset:24)
              element: <testLibrary>::@enum::E::@constructor::named
              factoryKeywordOffset: 16
              typeName: null
            #F5 const isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F6 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::E::@getter::v
            #F7 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F3
          type: List<E>
          constantInitializer
            fragment: #F3
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        factory isOriginDeclaration named
          reference: <testLibrary>::@enum::E::@constructor::named
          firstFragment: #F4
        const isOriginImplicitDefault new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F5
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F6
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F7
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
''');
  }

  test_enum_constructor_factoryHead_unnamed() async {
    var library = await buildLibrary(r'''
enum E {
  v.named();
  const E.named();
  factory () => v;
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
            #F2 hasInitializer isOriginDeclaration v (nameOffset:11) (firstTokenOffset:11) (offset:11)
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
            #F3 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
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
          constructors
            #F4 const isOriginDeclaration named (nameOffset:32) (firstTokenOffset:24) (offset:32)
              element: <testLibrary>::@enum::E::@constructor::named
              typeName: E
              typeNameOffset: 30
              periodOffset: 31
            #F5 factory isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:43) (offset:43)
              element: <testLibrary>::@enum::E::@constructor::new
              factoryKeywordOffset: 43
              typeName: null
          getters
            #F6 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::E::@getter::v
            #F7 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F3
          type: List<E>
          constantInitializer
            fragment: #F3
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        const isOriginDeclaration named
          reference: <testLibrary>::@enum::E::@constructor::named
          firstFragment: #F4
          superConstructor: dart:core::@class::Enum::@constructor::new
        factory isOriginDeclaration new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F5
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F6
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F7
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
''');
  }

  test_enum_constructor_fieldFormal_functionTyped_withReturnType() async {
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
            #F2 hasInitializer isOriginDeclaration v (nameOffset:11) (firstTokenOffset:11) (offset:11)
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
            #F3 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
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
            #F4 isOriginDeclaration x (nameOffset:22) (firstTokenOffset:22) (offset:22)
              element: <testLibrary>::@enum::E::@field::x
          constructors
            #F5 const isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:27) (offset:33)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
              typeNameOffset: 33
              formalParameters
                #F6 requiredPositional final this.x (nameOffset:44) (firstTokenOffset:35) (offset:44)
                  element: <testLibrary>::@enum::E::@constructor::new::@formalParameter::x
                  parameters
                    #F7 requiredPositional a (nameOffset:53) (firstTokenOffset:46) (offset:53)
                      element: a@53
          getters
            #F8 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::E::@getter::v
            #F9 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
            #F10 isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
              element: <testLibrary>::@enum::E::@getter::x
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F3
          type: List<E>
          constantInitializer
            fragment: #F3
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
        final hasImplicitType isOriginDeclaration x
          reference: <testLibrary>::@enum::E::@field::x
          firstFragment: #F4
          type: dynamic
          getter: <testLibrary>::@enum::E::@getter::x
      constructors
        const isOriginDeclaration new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional final this.x
              firstFragment: #F6
              type: int Function(double)
              formalParameters
                #E1 requiredPositional a
                  firstFragment: #F7
                  type: double
              field: <testLibrary>::@enum::E::@field::x
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F8
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F9
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
        isOriginVariable x
          reference: <testLibrary>::@enum::E::@getter::x
          firstFragment: #F10
          returnType: dynamic
          variable: <testLibrary>::@enum::E::@field::x
''');
  }

  test_enum_constructor_fieldFormal_multiple_matching_fields() async {
    var library = await buildLibrary('''
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
            #F2 hasInitializer isOriginDeclaration v (nameOffset:11) (firstTokenOffset:11) (offset:11)
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
            #F3 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
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
            #F4 isOriginDeclaration x (nameOffset:26) (firstTokenOffset:26) (offset:26)
              element: <testLibrary>::@enum::E::@field::x::@def::0
            #F5 isOriginDeclaration x (nameOffset:44) (firstTokenOffset:44) (offset:44)
              element: <testLibrary>::@enum::E::@field::x::@def::1
          constructors
            #F6 const isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:49) (offset:55)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
              typeNameOffset: 55
              formalParameters
                #F7 requiredPositional final this.x (nameOffset:62) (firstTokenOffset:57) (offset:62)
                  element: <testLibrary>::@enum::E::@constructor::new::@formalParameter::x
          getters
            #F8 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::E::@getter::v
            #F9 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
            #F10 isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:26)
              element: <testLibrary>::@enum::E::@getter::x::@def::0
            #F11 isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:44)
              element: <testLibrary>::@enum::E::@getter::x::@def::1
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F3
          type: List<E>
          constantInitializer
            fragment: #F3
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
        final isOriginDeclaration x
          reference: <testLibrary>::@enum::E::@field::x::@def::0
          firstFragment: #F4
          type: int
          getter: <testLibrary>::@enum::E::@getter::x::@def::0
        final isOriginDeclaration x
          reference: <testLibrary>::@enum::E::@field::x::@def::1
          firstFragment: #F5
          type: String
          getter: <testLibrary>::@enum::E::@getter::x::@def::1
      constructors
        const isOriginDeclaration new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F6
          formalParameters
            #E0 requiredPositional final hasImplicitType this.x
              firstFragment: #F7
              type: int
              field: <testLibrary>::@enum::E::@field::x::@def::0
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F8
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F9
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
        isOriginVariable x
          reference: <testLibrary>::@enum::E::@getter::x::@def::0
          firstFragment: #F10
          returnType: int
          variable: <testLibrary>::@enum::E::@field::x::@def::0
        isOriginVariable x
          reference: <testLibrary>::@enum::E::@getter::x::@def::1
          firstFragment: #F11
          returnType: String
          variable: <testLibrary>::@enum::E::@field::x::@def::1
''');
  }

  test_enum_constructor_fieldFormal_no_matching_field() async {
    var library = await buildLibrary('''
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
            #F2 hasInitializer isOriginDeclaration v (nameOffset:11) (firstTokenOffset:11) (offset:11)
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
            #F3 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
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
          constructors
            #F4 const isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:16) (offset:22)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
              typeNameOffset: 22
              formalParameters
                #F5 requiredPositional final this.x (nameOffset:29) (firstTokenOffset:24) (offset:29)
                  element: <testLibrary>::@enum::E::@constructor::new::@formalParameter::x
          getters
            #F6 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::E::@getter::v
            #F7 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F3
          type: List<E>
          constantInitializer
            fragment: #F3
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        const isOriginDeclaration new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional final hasImplicitType this.x
              firstFragment: #F5
              type: dynamic
              field: <null>
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F6
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F7
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
''');
  }

  test_enum_constructor_fieldFormal_optionalNamed_defaultValue() async {
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
            #F2 hasInitializer isOriginDeclaration v (nameOffset:11) (firstTokenOffset:11) (offset:11)
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
            #F3 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
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
            #F4 isOriginDeclaration x (nameOffset:26) (firstTokenOffset:26) (offset:26)
              element: <testLibrary>::@enum::E::@field::x
          constructors
            #F5 const isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:31) (offset:37)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
              typeNameOffset: 37
              formalParameters
                #F6 optionalNamed final this.x (nameOffset:45) (firstTokenOffset:40) (offset:45)
                  element: <testLibrary>::@enum::E::@constructor::new::@formalParameter::x
                  initializer: expression_2
                    BinaryExpression
                      leftOperand: IntegerLiteral
                        literal: 1 @49
                        staticType: int
                      operator: + @51
                      rightOperand: IntegerLiteral
                        literal: 2 @53
                        staticType: int
                      element: dart:core::@class::num::@method::+
                      staticInvokeType: num Function(num)
                      staticType: int
          getters
            #F7 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::E::@getter::v
            #F8 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
            #F9 isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:26)
              element: <testLibrary>::@enum::E::@getter::x
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F3
          type: List<E>
          constantInitializer
            fragment: #F3
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
        final isOriginDeclaration x
          reference: <testLibrary>::@enum::E::@field::x
          firstFragment: #F4
          type: int
          getter: <testLibrary>::@enum::E::@getter::x
      constructors
        const isOriginDeclaration new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F5
          formalParameters
            #E0 optionalNamed final hasDefaultValue hasImplicitType this.x
              firstFragment: #F6
              type: int
              constantInitializer
                fragment: #F6
                expression: expression_2
              field: <testLibrary>::@enum::E::@field::x
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F7
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F8
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
        isOriginVariable x
          reference: <testLibrary>::@enum::E::@getter::x
          firstFragment: #F9
          returnType: int
          variable: <testLibrary>::@enum::E::@field::x
''');
  }

  test_enum_constructor_fieldFormal_typed_typed() async {
    var library = await buildLibrary('''
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
            #F2 hasInitializer isOriginDeclaration v (nameOffset:11) (firstTokenOffset:11) (offset:11)
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
            #F3 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
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
            #F4 isOriginDeclaration x (nameOffset:26) (firstTokenOffset:26) (offset:26)
              element: <testLibrary>::@enum::E::@field::x
          constructors
            #F5 const isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:31) (offset:37)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
              typeNameOffset: 37
              formalParameters
                #F6 requiredPositional final this.x (nameOffset:48) (firstTokenOffset:39) (offset:48)
                  element: <testLibrary>::@enum::E::@constructor::new::@formalParameter::x
          getters
            #F7 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::E::@getter::v
            #F8 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
            #F9 isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:26)
              element: <testLibrary>::@enum::E::@getter::x
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F3
          type: List<E>
          constantInitializer
            fragment: #F3
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
        final isOriginDeclaration x
          reference: <testLibrary>::@enum::E::@field::x
          firstFragment: #F4
          type: num
          getter: <testLibrary>::@enum::E::@getter::x
      constructors
        const isOriginDeclaration new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional final this.x
              firstFragment: #F6
              type: int
              field: <testLibrary>::@enum::E::@field::x
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F7
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F8
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
        isOriginVariable x
          reference: <testLibrary>::@enum::E::@getter::x
          firstFragment: #F9
          returnType: num
          variable: <testLibrary>::@enum::E::@field::x
''');
  }

  test_enum_constructor_fieldFormal_untyped_typed() async {
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
            #F2 hasInitializer isOriginDeclaration v (nameOffset:11) (firstTokenOffset:11) (offset:11)
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
            #F3 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
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
            #F4 isOriginDeclaration x (nameOffset:22) (firstTokenOffset:22) (offset:22)
              element: <testLibrary>::@enum::E::@field::x
          constructors
            #F5 isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:27) (offset:27)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
              typeNameOffset: 27
              formalParameters
                #F6 requiredPositional final this.x (nameOffset:38) (firstTokenOffset:29) (offset:38)
                  element: <testLibrary>::@enum::E::@constructor::new::@formalParameter::x
          getters
            #F7 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::E::@getter::v
            #F8 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
            #F9 isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
              element: <testLibrary>::@enum::E::@getter::x
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F3
          type: List<E>
          constantInitializer
            fragment: #F3
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
        final hasImplicitType isOriginDeclaration x
          reference: <testLibrary>::@enum::E::@field::x
          firstFragment: #F4
          type: dynamic
          getter: <testLibrary>::@enum::E::@getter::x
      constructors
        isOriginDeclaration new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional final this.x
              firstFragment: #F6
              type: int
              field: <testLibrary>::@enum::E::@field::x
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F7
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F8
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
        isOriginVariable x
          reference: <testLibrary>::@enum::E::@getter::x
          firstFragment: #F9
          returnType: dynamic
          variable: <testLibrary>::@enum::E::@field::x
''');
  }

  test_enum_constructor_fieldFormal_untyped_untyped() async {
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
            #F2 hasInitializer isOriginDeclaration v (nameOffset:11) (firstTokenOffset:11) (offset:11)
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
            #F3 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
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
            #F4 isOriginDeclaration x (nameOffset:22) (firstTokenOffset:22) (offset:22)
              element: <testLibrary>::@enum::E::@field::x
          constructors
            #F5 isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:27) (offset:27)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
              typeNameOffset: 27
              formalParameters
                #F6 requiredPositional final this.x (nameOffset:34) (firstTokenOffset:29) (offset:34)
                  element: <testLibrary>::@enum::E::@constructor::new::@formalParameter::x
          getters
            #F7 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::E::@getter::v
            #F8 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
            #F9 isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
              element: <testLibrary>::@enum::E::@getter::x
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F3
          type: List<E>
          constantInitializer
            fragment: #F3
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
        final hasImplicitType isOriginDeclaration x
          reference: <testLibrary>::@enum::E::@field::x
          firstFragment: #F4
          type: dynamic
          getter: <testLibrary>::@enum::E::@getter::x
      constructors
        isOriginDeclaration new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional final hasImplicitType this.x
              firstFragment: #F6
              type: dynamic
              field: <testLibrary>::@enum::E::@field::x
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F7
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F8
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
        isOriginVariable x
          reference: <testLibrary>::@enum::E::@getter::x
          firstFragment: #F9
          returnType: dynamic
          variable: <testLibrary>::@enum::E::@field::x
''');
  }

  test_enum_constructor_generative_named() async {
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
            #F2 hasInitializer isOriginDeclaration v (nameOffset:11) (firstTokenOffset:11) (offset:11)
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
            #F3 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
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
          constructors
            #F4 const isOriginDeclaration named (nameOffset:34) (firstTokenOffset:26) (offset:34)
              element: <testLibrary>::@enum::E::@constructor::named
              typeName: E
              typeNameOffset: 32
              periodOffset: 33
              formalParameters
                #F5 requiredPositional a (nameOffset:44) (firstTokenOffset:40) (offset:44)
                  element: <testLibrary>::@enum::E::@constructor::named::@formalParameter::a
          getters
            #F6 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::E::@getter::v
            #F7 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F3
          type: List<E>
          constantInitializer
            fragment: #F3
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        const isOriginDeclaration named
          reference: <testLibrary>::@enum::E::@constructor::named
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional a
              firstFragment: #F5
              type: int
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F6
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F7
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
''');
  }

  test_enum_constructor_generative_unnamed() async {
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
            #F2 hasInitializer isOriginDeclaration v (nameOffset:11) (firstTokenOffset:11) (offset:11)
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
            #F3 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
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
          constructors
            #F4 const isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:20) (offset:26)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
              typeNameOffset: 26
              formalParameters
                #F5 requiredPositional a (nameOffset:32) (firstTokenOffset:28) (offset:32)
                  element: <testLibrary>::@enum::E::@constructor::new::@formalParameter::a
          getters
            #F6 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::E::@getter::v
            #F7 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F3
          type: List<E>
          constantInitializer
            fragment: #F3
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        const isOriginDeclaration new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional a
              firstFragment: #F5
              type: int
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F6
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F7
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
''');
  }

  test_enum_constructor_initializer() async {
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
            #F3 hasInitializer isOriginDeclaration v (nameOffset:14) (firstTokenOffset:14) (offset:14)
              element: <testLibrary>::@enum::E::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibrary>::@enum::E
                      type: E<dynamic>
                    element: ConstructorMember
                      baseElement: <testLibrary>::@enum::E::@constructor::new
                      substitution: {T: dynamic}
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E<dynamic>
            #F4 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
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
            #F5 isOriginDeclaration x (nameOffset:29) (firstTokenOffset:29) (offset:29)
              element: <testLibrary>::@enum::E::@field::x
          constructors
            #F6 const isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:34) (offset:40)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
              typeNameOffset: 40
              formalParameters
                #F7 requiredPositional a (nameOffset:45) (firstTokenOffset:42) (offset:45)
                  element: <testLibrary>::@enum::E::@constructor::new::@formalParameter::a
          getters
            #F8 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:14)
              element: <testLibrary>::@enum::E::@getter::v
            #F9 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
            #F10 isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:29)
              element: <testLibrary>::@enum::E::@getter::x
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F3
          type: E<dynamic>
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F4
          type: List<E<dynamic>>
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
        final isOriginDeclaration x
          reference: <testLibrary>::@enum::E::@field::x
          firstFragment: #F5
          type: int
          getter: <testLibrary>::@enum::E::@getter::x
      constructors
        const isOriginDeclaration new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F6
          formalParameters
            #E1 requiredPositional a
              firstFragment: #F7
              type: T?
          constantInitializers
            AssertInitializer
              assertKeyword: assert @50
              leftParenthesis: ( @56
              condition: IsExpression
                expression: SimpleIdentifier
                  token: a @57
                  element: <testLibrary>::@enum::E::@constructor::new::@formalParameter::a
                  staticType: T?
                isOperator: is @59
                type: NamedType
                  name: T @62
                  element: #E0 T
                  type: T
                staticType: bool
              rightParenthesis: ) @63
            ConstructorFieldInitializer
              fieldName: SimpleIdentifier
                token: x @66
                element: <testLibrary>::@enum::E::@field::x
                staticType: null
              equals: = @68
              expression: IntegerLiteral
                literal: 0 @70
                staticType: int
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F8
          returnType: E<dynamic>
          variable: <testLibrary>::@enum::E::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F9
          returnType: List<E<dynamic>>
          variable: <testLibrary>::@enum::E::@field::values
        isOriginVariable x
          reference: <testLibrary>::@enum::E::@getter::x
          firstFragment: #F10
          returnType: int
          variable: <testLibrary>::@enum::E::@field::x
''');
  }

  test_enum_constructor_newHead_named() async {
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
            #F2 hasInitializer isOriginDeclaration v (nameOffset:11) (firstTokenOffset:11) (offset:11)
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
            #F3 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
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
          constructors
            #F4 isOriginDeclaration named (nameOffset:28) (firstTokenOffset:24) (offset:28)
              element: <testLibrary>::@enum::E::@constructor::named
              newKeywordOffset: 24
              typeName: null
          getters
            #F5 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::E::@getter::v
            #F6 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F3
          type: List<E>
          constantInitializer
            fragment: #F3
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        isOriginDeclaration named
          reference: <testLibrary>::@enum::E::@constructor::named
          firstFragment: #F4
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F5
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F6
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
''');
  }

  test_enum_constructor_newHead_named_const() async {
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
            #F2 hasInitializer isOriginDeclaration v (nameOffset:11) (firstTokenOffset:11) (offset:11)
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
            #F3 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
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
          constructors
            #F4 const isOriginDeclaration named (nameOffset:34) (firstTokenOffset:24) (offset:34)
              element: <testLibrary>::@enum::E::@constructor::named
              newKeywordOffset: 30
              typeName: null
          getters
            #F5 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::E::@getter::v
            #F6 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F3
          type: List<E>
          constantInitializer
            fragment: #F3
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        const isOriginDeclaration named
          reference: <testLibrary>::@enum::E::@constructor::named
          firstFragment: #F4
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F5
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F6
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
''');
  }

  test_enum_constructor_newHead_unnamed() async {
    var library = await buildLibrary(r'''
enum E {
  v;
  new ();
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
            #F2 hasInitializer isOriginDeclaration v (nameOffset:11) (firstTokenOffset:11) (offset:11)
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
            #F3 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
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
          constructors
            #F4 isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:16) (offset:16)
              element: <testLibrary>::@enum::E::@constructor::new
              newKeywordOffset: 16
              typeName: null
          getters
            #F5 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::E::@getter::v
            #F6 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F3
          type: List<E>
          constantInitializer
            fragment: #F3
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        isOriginDeclaration new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F4
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F5
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F6
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
''');
  }

  test_enum_constructor_newHead_unnamed_const() async {
    var library = await buildLibrary(r'''
enum E {
  v;
  const new ();
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
            #F2 hasInitializer isOriginDeclaration v (nameOffset:11) (firstTokenOffset:11) (offset:11)
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
            #F3 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
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
          constructors
            #F4 const isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:16) (offset:16)
              element: <testLibrary>::@enum::E::@constructor::new
              newKeywordOffset: 22
              typeName: null
          getters
            #F5 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::E::@getter::v
            #F6 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F3
          type: List<E>
          constantInitializer
            fragment: #F3
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        const isOriginDeclaration new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F4
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F5
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F6
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
''');
  }

  test_enum_documented() async {
    var library = await buildLibrary('''
// Extra comment so doc comment offset != 0
/**
 * Docs
 */
enum E { v }''');
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
            #F2 hasInitializer isOriginDeclaration v (nameOffset:69) (firstTokenOffset:69) (offset:69)
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
            #F3 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:65)
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
          constructors
            #F4 const isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:65)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F5 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:69)
              element: <testLibrary>::@enum::E::@getter::v
            #F6 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:65)
              element: <testLibrary>::@enum::E::@getter::values
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      documentationComment: /**\n * Docs\n */
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F3
          type: List<E>
          constantInitializer
            fragment: #F3
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        const isOriginImplicitDefault new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F4
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F5
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F6
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
''');
  }

  test_enum_field() async {
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
            #F2 hasInitializer isOriginDeclaration v (nameOffset:11) (firstTokenOffset:11) (offset:11)
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
            #F3 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
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
            #F4 hasInitializer isOriginDeclaration foo (nameOffset:22) (firstTokenOffset:22) (offset:22)
              element: <testLibrary>::@enum::E::@field::foo
              initializer: expression_2
                IntegerLiteral
                  literal: 42 @28
                  staticType: int
          constructors
            #F5 const isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F6 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::E::@getter::v
            #F7 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
            #F8 isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
              element: <testLibrary>::@enum::E::@getter::foo
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F3
          type: List<E>
          constantInitializer
            fragment: #F3
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
        final hasImplicitType hasInitializer isOriginDeclaration foo
          reference: <testLibrary>::@enum::E::@field::foo
          firstFragment: #F4
          type: int
          constantInitializer
            fragment: #F4
            expression: expression_2
          getter: <testLibrary>::@enum::E::@getter::foo
      constructors
        const isOriginImplicitDefault new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F5
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F6
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F7
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
        isOriginVariable foo
          reference: <testLibrary>::@enum::E::@getter::foo
          firstFragment: #F8
          returnType: int
          variable: <testLibrary>::@enum::E::@field::foo
''');
  }

  test_enum_field_isPromotable() async {
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
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F0
      supertype: Enum
      fields
        final promotable isOriginDeclaration _foo
          reference: <testLibrary>::@enum::E::@field::_foo
          firstFragment: #F1
          type: int?
          getter: <testLibrary>::@enum::E::@getter::_foo
''');
  }

  test_enum_getter() async {
    var library = await buildLibrary(r'''
enum E{
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
            #F2 hasInitializer isOriginDeclaration v (nameOffset:10) (firstTokenOffset:10) (offset:10)
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
            #F3 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
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
            #F4 isOriginGetterSetter foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@field::foo
          constructors
            #F5 const isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F6 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:10)
              element: <testLibrary>::@enum::E::@getter::v
            #F7 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
            #F8 isOriginDeclaration foo (nameOffset:23) (firstTokenOffset:15) (offset:23)
              element: <testLibrary>::@enum::E::@getter::foo
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F3
          type: List<E>
          constantInitializer
            fragment: #F3
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
        isOriginGetterSetter foo
          reference: <testLibrary>::@enum::E::@field::foo
          firstFragment: #F4
          type: int
          getter: <testLibrary>::@enum::E::@getter::foo
      constructors
        const isOriginImplicitDefault new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F5
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F6
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F7
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
        isOriginDeclaration foo
          reference: <testLibrary>::@enum::E::@getter::foo
          firstFragment: #F8
          returnType: int
          variable: <testLibrary>::@enum::E::@field::foo
''');
  }

  test_enum_interfaces() async {
    var library = await buildLibrary(r'''
class I {}
enum E implements I {
  v;
}
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
        #F3 enum E (nameOffset:16) (firstTokenOffset:11) (offset:16)
          element: <testLibrary>::@enum::E
          fields
            #F4 hasInitializer isOriginDeclaration v (nameOffset:35) (firstTokenOffset:35) (offset:35)
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
            #F5 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
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
          constructors
            #F6 const isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F7 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:35)
              element: <testLibrary>::@enum::E::@getter::v
            #F8 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@enum::E::@getter::values
  classes
    class I
      reference: <testLibrary>::@class::I
      firstFragment: #F1
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::I::@constructor::new
          firstFragment: #F2
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F3
      supertype: Enum
      interfaces
        I
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F4
          type: E
          constantInitializer
            fragment: #F4
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F5
          type: List<E>
          constantInitializer
            fragment: #F5
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        const isOriginImplicitDefault new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F6
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F7
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F8
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
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
        #F2 class C (nameOffset:45) (firstTokenOffset:39) (offset:45)
          element: <testLibrary>::@class::C
      enums
        #F3 enum E (nameOffset:55) (firstTokenOffset:50) (offset:55)
          element: <testLibrary>::@enum::E
          fields
            #F4 hasInitializer isOriginDeclaration v (nameOffset:78) (firstTokenOffset:78) (offset:78)
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
            #F5 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:55)
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
          getters
            #F6 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:78)
              element: <testLibrary>::@enum::E::@getter::v
            #F7 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:55)
              element: <testLibrary>::@enum::E::@getter::values
      extensionTypes
        #F8 extension type B (nameOffset:26) (firstTokenOffset:11) (offset:26)
          element: <testLibrary>::@extensionType::B
          fields
            #F9 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:26)
              element: <testLibrary>::@extensionType::B::@field::it
          getters
            #F10 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:26)
              element: <testLibrary>::@extensionType::B::@getter::it
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F2
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F3
      supertype: Enum
      interfaces
        A
        C
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F4
          type: E
          constantInitializer
            fragment: #F4
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F5
          type: List<E>
          constantInitializer
            fragment: #F5
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F6
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F7
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
  extensionTypes
    extension type B
      reference: <testLibrary>::@extensionType::B
      firstFragment: #F8
      representation: <testLibrary>::@extensionType::B::@field::it
      primaryConstructor: <testLibrary>::@extensionType::B::@constructor::new
      typeErasure: int
      fields
        final isOriginDeclaringFormalParameter it
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
enum E<U> implements I<U> {
  v;
}
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
        #F4 enum E (nameOffset:19) (firstTokenOffset:14) (offset:19)
          element: <testLibrary>::@enum::E
          typeParameters
            #F5 U (nameOffset:21) (firstTokenOffset:21) (offset:21)
              element: #E1 U
          fields
            #F6 hasInitializer isOriginDeclaration v (nameOffset:44) (firstTokenOffset:44) (offset:44)
              element: <testLibrary>::@enum::E::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibrary>::@enum::E
                      type: E<dynamic>
                    element: ConstructorMember
                      baseElement: <testLibrary>::@enum::E::@constructor::new
                      substitution: {U: dynamic}
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E<dynamic>
            #F7 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:19)
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
          constructors
            #F8 const isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:19)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F9 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:44)
              element: <testLibrary>::@enum::E::@getter::v
            #F10 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:19)
              element: <testLibrary>::@enum::E::@getter::values
  classes
    class I
      reference: <testLibrary>::@class::I
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::I::@constructor::new
          firstFragment: #F3
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F4
      typeParameters
        #E1 U
          firstFragment: #F5
      supertype: Enum
      interfaces
        I<U>
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F6
          type: E<dynamic>
          constantInitializer
            fragment: #F6
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F7
          type: List<E<dynamic>>
          constantInitializer
            fragment: #F7
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        const isOriginImplicitDefault new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F8
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F9
          returnType: E<dynamic>
          variable: <testLibrary>::@enum::E::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F10
          returnType: List<E<dynamic>>
          variable: <testLibrary>::@enum::E::@field::values
''');
  }

  test_enum_interfaces_unresolved() async {
    var library = await buildLibrary('''
class X {}
class Z {}
enum E implements X, Y, Z {
  v
}
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
        #F3 class Z (nameOffset:17) (firstTokenOffset:11) (offset:17)
          element: <testLibrary>::@class::Z
          constructors
            #F4 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:17)
              element: <testLibrary>::@class::Z::@constructor::new
              typeName: Z
      enums
        #F5 enum E (nameOffset:27) (firstTokenOffset:22) (offset:27)
          element: <testLibrary>::@enum::E
          fields
            #F6 hasInitializer isOriginDeclaration v (nameOffset:52) (firstTokenOffset:52) (offset:52)
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
            #F7 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:27)
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
          constructors
            #F8 const isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:27)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F9 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:52)
              element: <testLibrary>::@enum::E::@getter::v
            #F10 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:27)
              element: <testLibrary>::@enum::E::@getter::values
  classes
    class X
      reference: <testLibrary>::@class::X
      firstFragment: #F1
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::X::@constructor::new
          firstFragment: #F2
    class Z
      reference: <testLibrary>::@class::Z
      firstFragment: #F3
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::Z::@constructor::new
          firstFragment: #F4
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F5
      supertype: Enum
      interfaces
        X
        Z
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F6
          type: E
          constantInitializer
            fragment: #F6
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F7
          type: List<E>
          constantInitializer
            fragment: #F7
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        const isOriginImplicitDefault new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F8
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F9
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F10
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
''');
  }

  test_enum_lazy_all_constructors() async {
    var library = await buildLibrary('''
enum E {
  v.foo();
  const E.foo();
}
''');

    var constructors = library.getEnum('E')!.constructors;
    expect(constructors, hasLength(1));
  }

  test_enum_lazy_all_fields() async {
    var library = await buildLibrary('''
enum E {
  v;
  final foo = 42;
}
''');

    var fields = library.getEnum('E')!.fields;
    expect(fields, hasLength(3));
  }

  test_enum_lazy_all_getters() async {
    var library = await buildLibrary('''
enum E {
  v;
  int get foo => 0;
}
''');

    var getters = library.getEnum('E')!.getters;
    expect(getters, hasLength(3));
  }

  test_enum_lazy_all_methods() async {
    var library = await buildLibrary('''
enum E {
  v;
  void foo() {}
}
''');

    var methods = library.getEnum('E')!.methods;
    expect(methods, hasLength(1));
  }

  test_enum_lazy_all_setters() async {
    var library = await buildLibrary('''
enum E {
  v;
  set foo(int _) {}
}
''');

    var setters = library.getEnum('E')!.setters;
    expect(setters, hasLength(1));
  }

  test_enum_lazy_byReference_constructor() async {
    var library = await buildLibrary('''
enum E {
  v.foo();
  const E.foo();
}
''');
    // Test ensureReadMembers() in LinkedElementFactory.
    var E = library.getEnum('E')!;
    var foo = getElementOfReference(E, ['@constructor', 'foo']);
    expect(foo.name, 'foo');
  }

  test_enum_lazy_byReference_field() async {
    var library = await buildLibrary('''
enum E {
  v;
  final foo = 42;
}
''');
    // Test ensureReadMembers() in LinkedElementFactory.
    var E = library.getEnum('E')!;
    var foo = getElementOfReference(E, ['@field', 'foo']);
    expect(foo.name, 'foo');
  }

  test_enum_lazy_byReference_getter() async {
    var library = await buildLibrary('''
enum E {
  v;
  int get foo => 0;
}
''');
    // Test ensureReadMembers() in LinkedElementFactory.
    var E = library.getEnum('E')!;
    var foo = getElementOfReference(E, ['@getter', 'foo']);
    expect(foo.name, 'foo');
  }

  test_enum_lazy_byReference_method() async {
    var library = await buildLibrary('''
enum E {
  v;
  void foo() {}
}
''');
    // Test ensureReadMembers() in LinkedElementFactory.
    var E = library.getEnum('E')!;
    var foo = getElementOfReference(E, ['@method', 'foo']);
    expect(foo.name, 'foo');
  }

  test_enum_lazy_byReference_setter() async {
    var library = await buildLibrary('''
enum E{
  v;
  set foo(int _) {}
}
''');
    // Test ensureReadMembers() in LinkedElementFactory.
    var E = library.getEnum('E')!;
    var foo = getElementOfReference(E, ['@setter', 'foo']);
    expect(foo.name, 'foo');
  }

  test_enum_method() async {
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
            #F3 hasInitializer isOriginDeclaration v (nameOffset:14) (firstTokenOffset:14) (offset:14)
              element: <testLibrary>::@enum::E::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibrary>::@enum::E
                      type: E<dynamic>
                    element: ConstructorMember
                      baseElement: <testLibrary>::@enum::E::@constructor::new
                      substitution: {T: dynamic}
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E<dynamic>
            #F4 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
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
          constructors
            #F5 const isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F6 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:14)
              element: <testLibrary>::@enum::E::@getter::v
            #F7 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
          methods
            #F8 isOriginDeclaration foo (nameOffset:23) (firstTokenOffset:19) (offset:23)
              element: <testLibrary>::@enum::E::@method::foo
              typeParameters
                #F9 U (nameOffset:27) (firstTokenOffset:27) (offset:27)
                  element: #E1 U
              formalParameters
                #F10 requiredPositional t (nameOffset:32) (firstTokenOffset:30) (offset:32)
                  element: <testLibrary>::@enum::E::@method::foo::@formalParameter::t
                #F11 requiredPositional u (nameOffset:37) (firstTokenOffset:35) (offset:37)
                  element: <testLibrary>::@enum::E::@method::foo::@formalParameter::u
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F3
          type: E<dynamic>
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F4
          type: List<E<dynamic>>
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        const isOriginImplicitDefault new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F5
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F6
          returnType: E<dynamic>
          variable: <testLibrary>::@enum::E::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F7
          returnType: List<E<dynamic>>
          variable: <testLibrary>::@enum::E::@field::values
      methods
        isOriginDeclaration foo
          reference: <testLibrary>::@enum::E::@method::foo
          firstFragment: #F8
          hasEnclosingTypeParameterReference: true
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

  test_enum_method_toString() async {
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
            #F2 hasInitializer isOriginDeclaration v (nameOffset:11) (firstTokenOffset:11) (offset:11)
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
            #F3 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
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
          constructors
            #F4 const isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F5 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::E::@getter::v
            #F6 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
          methods
            #F7 isOriginDeclaration toString (nameOffset:23) (firstTokenOffset:16) (offset:23)
              element: <testLibrary>::@enum::E::@method::toString
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F3
          type: List<E>
          constantInitializer
            fragment: #F3
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        const isOriginImplicitDefault new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F4
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F5
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F6
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
      methods
        isOriginDeclaration toString
          reference: <testLibrary>::@enum::E::@method::toString
          firstFragment: #F7
          returnType: String
''');
  }

  test_enum_missingName() async {
    var library = await buildLibrary(r'''
enum {v}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      enums
        #F1 enum <null-name> (nameOffset:<null>) (firstTokenOffset:0) (offset:0)
          element: <testLibrary>::@enum::0
          fields
            #F2 hasInitializer isOriginDeclaration v (nameOffset:6) (firstTokenOffset:6) (offset:6)
              element: <testLibrary>::@enum::0::@field::v
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
            #F3 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:0)
              element: <testLibrary>::@enum::0::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::0::@getter::v
                      staticType: InvalidType
                  rightBracket: ] @0
                  staticType: List<<null>>
          constructors
            #F4 const isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:0)
              element: <testLibrary>::@enum::0::@constructor::new
              typeName: null
          getters
            #F5 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@enum::0::@getter::v
            #F6 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:0)
              element: <testLibrary>::@enum::0::@getter::values
  enums
    enum <null-name>
      reference: <testLibrary>::@enum::0
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::0::@field::v
          firstFragment: #F2
          type: InvalidType
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::0::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::0::@field::values
          firstFragment: #F3
          type: List<<null>>
          constantInitializer
            fragment: #F3
            expression: expression_1
          getter: <testLibrary>::@enum::0::@getter::values
      constructors
        const isOriginImplicitDefault new
          reference: <testLibrary>::@enum::0::@constructor::new
          firstFragment: #F4
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::0::@getter::v
          firstFragment: #F5
          returnType: InvalidType
          variable: <testLibrary>::@enum::0::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::0::@getter::values
          firstFragment: #F6
          returnType: List<<null>>
          variable: <testLibrary>::@enum::0::@field::values
''');
  }

  test_enum_mixins() async {
    var library = await buildLibrary(r'''
mixin M {}
enum E with M {
  v;
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      enums
        #F1 enum E (nameOffset:16) (firstTokenOffset:11) (offset:16)
          element: <testLibrary>::@enum::E
          fields
            #F2 hasInitializer isOriginDeclaration v (nameOffset:29) (firstTokenOffset:29) (offset:29)
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
            #F3 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
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
          constructors
            #F4 const isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F5 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:29)
              element: <testLibrary>::@enum::E::@getter::v
            #F6 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@enum::E::@getter::values
      mixins
        #F7 mixin M (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@mixin::M
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      mixins
        M
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F3
          type: List<E>
          constantInitializer
            fragment: #F3
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        const isOriginImplicitDefault new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F4
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F5
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F6
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
  mixins
    mixin M
      reference: <testLibrary>::@mixin::M
      firstFragment: #F7
      superclassConstraints
        Object
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
        #F2 class C (nameOffset:45) (firstTokenOffset:39) (offset:45)
          element: <testLibrary>::@class::C
      enums
        #F3 enum E (nameOffset:55) (firstTokenOffset:50) (offset:55)
          element: <testLibrary>::@enum::E
          fields
            #F4 hasInitializer isOriginDeclaration v (nameOffset:72) (firstTokenOffset:72) (offset:72)
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
            #F5 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:55)
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
          getters
            #F6 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:72)
              element: <testLibrary>::@enum::E::@getter::v
            #F7 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:55)
              element: <testLibrary>::@enum::E::@getter::values
      extensionTypes
        #F8 extension type B (nameOffset:26) (firstTokenOffset:11) (offset:26)
          element: <testLibrary>::@extensionType::B
          fields
            #F9 isOriginDeclaringFormalParameter it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:26)
              element: <testLibrary>::@extensionType::B::@field::it
          getters
            #F10 isOriginVariable it (nameOffset:<null>) (firstTokenOffset:<null>) (offset:26)
              element: <testLibrary>::@extensionType::B::@getter::it
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F2
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F3
      supertype: Enum
      mixins
        A
        C
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F4
          type: E
          constantInitializer
            fragment: #F4
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F5
          type: List<E>
          constantInitializer
            fragment: #F5
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F6
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F7
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
  extensionTypes
    extension type B
      reference: <testLibrary>::@extensionType::B
      firstFragment: #F8
      representation: <testLibrary>::@extensionType::B::@field::it
      primaryConstructor: <testLibrary>::@extensionType::B::@constructor::new
      typeErasure: int
      fields
        final isOriginDeclaringFormalParameter it
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
enum E with M1<int>, M2 {
  v;
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      enums
        #F1 enum E (nameOffset:44) (firstTokenOffset:39) (offset:44)
          element: <testLibrary>::@enum::E
          fields
            #F2 hasInitializer isOriginDeclaration v (nameOffset:67) (firstTokenOffset:67) (offset:67)
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
            #F3 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:44)
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
          constructors
            #F4 const isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:44)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F5 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:67)
              element: <testLibrary>::@enum::E::@getter::v
            #F6 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:44)
              element: <testLibrary>::@enum::E::@getter::values
      mixins
        #F7 mixin M1 (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@mixin::M1
          typeParameters
            #F8 T (nameOffset:9) (firstTokenOffset:9) (offset:9)
              element: #E0 T
        #F9 mixin M2 (nameOffset:21) (firstTokenOffset:15) (offset:21)
          element: <testLibrary>::@mixin::M2
          typeParameters
            #F10 T (nameOffset:24) (firstTokenOffset:24) (offset:24)
              element: #E1 T
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      mixins
        M1<int>
        M2<int>
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F3
          type: List<E>
          constantInitializer
            fragment: #F3
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        const isOriginImplicitDefault new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F4
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F5
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F6
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
  mixins
    mixin M1
      reference: <testLibrary>::@mixin::M1
      firstFragment: #F7
      typeParameters
        #E0 T
          firstFragment: #F8
      superclassConstraints
        Object
    mixin M2
      reference: <testLibrary>::@mixin::M2
      firstFragment: #F9
      typeParameters
        #E1 T
          firstFragment: #F10
      superclassConstraints
        M1<T>
''');
  }

  test_enum_setter() async {
    var library = await buildLibrary(r'''
enum E{
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
            #F2 hasInitializer isOriginDeclaration v (nameOffset:10) (firstTokenOffset:10) (offset:10)
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
            #F3 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
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
            #F4 isOriginGetterSetter foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@field::foo
          constructors
            #F5 const isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F6 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:10)
              element: <testLibrary>::@enum::E::@getter::v
            #F7 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
          setters
            #F8 isOriginDeclaration foo (nameOffset:19) (firstTokenOffset:15) (offset:19)
              element: <testLibrary>::@enum::E::@setter::foo
              formalParameters
                #F9 requiredPositional _ (nameOffset:27) (firstTokenOffset:23) (offset:27)
                  element: <testLibrary>::@enum::E::@setter::foo::@formalParameter::_
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F3
          type: List<E>
          constantInitializer
            fragment: #F3
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
        isOriginGetterSetter foo
          reference: <testLibrary>::@enum::E::@field::foo
          firstFragment: #F4
          type: int
          setter: <testLibrary>::@enum::E::@setter::foo
      constructors
        const isOriginImplicitDefault new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F5
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F6
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F7
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

  test_enum_typeParameters() async {
    var library = await buildLibrary('''
enum E<T> {
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
        #F1 enum E (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@enum::E
          typeParameters
            #F2 T (nameOffset:7) (firstTokenOffset:7) (offset:7)
              element: #E0 T
          fields
            #F3 hasInitializer isOriginDeclaration v (nameOffset:14) (firstTokenOffset:14) (offset:14)
              element: <testLibrary>::@enum::E::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibrary>::@enum::E
                      type: E<dynamic>
                    element: ConstructorMember
                      baseElement: <testLibrary>::@enum::E::@constructor::new
                      substitution: {T: dynamic}
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E<dynamic>
            #F4 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
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
          constructors
            #F5 const isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F6 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:14)
              element: <testLibrary>::@enum::E::@getter::v
            #F7 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F3
          type: E<dynamic>
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F4
          type: List<E<dynamic>>
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        const isOriginImplicitDefault new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F5
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F6
          returnType: E<dynamic>
          variable: <testLibrary>::@enum::E::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F7
          returnType: List<E<dynamic>>
          variable: <testLibrary>::@enum::E::@field::values
''');
  }

  test_enum_typeParameters_bound() async {
    var library = await buildLibrary('''
enum E<T extends num, U extends T> {
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
        #F1 enum E (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@enum::E
          typeParameters
            #F2 T (nameOffset:7) (firstTokenOffset:7) (offset:7)
              element: #E0 T
            #F3 U (nameOffset:22) (firstTokenOffset:22) (offset:22)
              element: #E1 U
          fields
            #F4 hasInitializer isOriginDeclaration v (nameOffset:39) (firstTokenOffset:39) (offset:39)
              element: <testLibrary>::@enum::E::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibrary>::@enum::E
                      type: E<num, num>
                    element: ConstructorMember
                      baseElement: <testLibrary>::@enum::E::@constructor::new
                      substitution: {T: num, U: num}
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E<num, num>
            #F5 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
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
          constructors
            #F6 const isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F7 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:39)
              element: <testLibrary>::@enum::E::@getter::v
            #F8 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
  enums
    notSimplyBounded enum E
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
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F4
          type: E<num, num>
          constantInitializer
            fragment: #F4
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F5
          type: List<E<num, num>>
          constantInitializer
            fragment: #F5
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        const isOriginImplicitDefault new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F6
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F7
          returnType: E<num, num>
          variable: <testLibrary>::@enum::E::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F8
          returnType: List<E<num, num>>
          variable: <testLibrary>::@enum::E::@field::values
''');
  }

  test_enum_typeParameters_cycle_1of1() async {
    var library = await buildLibrary('''
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
            #F3 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@field::values
              initializer: expression_0
                ListLiteral
                  leftBracket: [ @0
                  rightBracket: ] @0
                  staticType: List<E<dynamic>>
          constructors
            #F4 const isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F5 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
  enums
    notSimplyBounded enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
          bound: dynamic
      supertype: Enum
      fields
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F3
          type: List<E<dynamic>>
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        const isOriginImplicitDefault new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F4
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F5
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
            #F5 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@field::values
              initializer: expression_0
                ListLiteral
                  leftBracket: [ @0
                  rightBracket: ] @0
                  staticType: List<E<dynamic, num, dynamic>>
          constructors
            #F6 const isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F7 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
  enums
    notSimplyBounded enum E
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
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F5
          type: List<E<dynamic, num, dynamic>>
          constantInitializer
            fragment: #F5
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        const isOriginImplicitDefault new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F6
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F7
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
            #F3 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@field::values
              initializer: expression_0
                ListLiteral
                  leftBracket: [ @0
                  rightBracket: ] @0
                  staticType: List<E<dynamic>>
          constructors
            #F4 const isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F5 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
  enums
    notSimplyBounded enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
          bound: void Function(E<dynamic>)
      supertype: Enum
      fields
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F3
          type: List<E<dynamic>>
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        const isOriginImplicitDefault new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F4
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F5
          returnType: List<E<dynamic>>
          variable: <testLibrary>::@enum::E::@field::values
''');
  }

  test_enum_typeParameters_variance_contravariant() async {
    var library = await buildLibrary('''
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
            #F3 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@field::values
              initializer: expression_0
                ListLiteral
                  leftBracket: [ @0
                  rightBracket: ] @0
                  staticType: List<E<dynamic>>
          constructors
            #F4 const isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F5 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      supertype: Enum
      fields
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F3
          type: List<E<dynamic>>
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        const isOriginImplicitDefault new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F4
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F5
          returnType: List<E<dynamic>>
          variable: <testLibrary>::@enum::E::@field::values
''');
  }

  test_enum_typeParameters_variance_covariant() async {
    var library = await buildLibrary('''
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
            #F3 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@field::values
              initializer: expression_0
                ListLiteral
                  leftBracket: [ @0
                  rightBracket: ] @0
                  staticType: List<E<dynamic>>
          constructors
            #F4 const isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F5 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      supertype: Enum
      fields
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F3
          type: List<E<dynamic>>
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        const isOriginImplicitDefault new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F4
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F5
          returnType: List<E<dynamic>>
          variable: <testLibrary>::@enum::E::@field::values
''');
  }

  test_enum_typeParameters_variance_invariant() async {
    var library = await buildLibrary('''
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
            #F3 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@field::values
              initializer: expression_0
                ListLiteral
                  leftBracket: [ @0
                  rightBracket: ] @0
                  staticType: List<E<dynamic>>
          constructors
            #F4 const isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F5 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      supertype: Enum
      fields
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F3
          type: List<E<dynamic>>
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        const isOriginImplicitDefault new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F4
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F5
          returnType: List<E<dynamic>>
          variable: <testLibrary>::@enum::E::@field::values
''');
  }

  test_enum_typeParameters_variance_multiple() async {
    var library = await buildLibrary('''
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
            #F5 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@field::values
              initializer: expression_0
                ListLiteral
                  leftBracket: [ @0
                  rightBracket: ] @0
                  staticType: List<E<dynamic, dynamic, dynamic>>
          constructors
            #F6 const isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F7 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
  enums
    enum E
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
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F5
          type: List<E<dynamic, dynamic, dynamic>>
          constantInitializer
            fragment: #F5
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        const isOriginImplicitDefault new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F6
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F7
          returnType: List<E<dynamic, dynamic, dynamic>>
          variable: <testLibrary>::@enum::E::@field::values
''');
  }

  test_enum_value_documented() async {
    var library = await buildLibrary('''
enum E {
  /**
   * aaa
   */
  a,
  /// bbb
  b
}''');
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
            #F2 hasInitializer isOriginDeclaration a (nameOffset:32) (firstTokenOffset:11) (offset:32)
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
            #F3 hasInitializer isOriginDeclaration b (nameOffset:47) (firstTokenOffset:37) (offset:47)
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
            #F4 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
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
            #F5 const isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F6 isOriginVariable a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:32)
              element: <testLibrary>::@enum::E::@getter::a
            #F7 isOriginVariable b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:47)
              element: <testLibrary>::@enum::E::@getter::b
            #F8 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration a
          reference: <testLibrary>::@enum::E::@field::a
          firstFragment: #F2
          documentationComment: /**\n   * aaa\n   */
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::a
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration b
          reference: <testLibrary>::@enum::E::@field::b
          firstFragment: #F3
          documentationComment: /// bbb
          type: E
          constantInitializer
            fragment: #F3
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::b
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F4
          type: List<E>
          constantInitializer
            fragment: #F4
            expression: expression_2
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        const isOriginImplicitDefault new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F5
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable a
          reference: <testLibrary>::@enum::E::@getter::a
          firstFragment: #F6
          returnType: E
          variable: <testLibrary>::@enum::E::@field::a
        static isOriginVariable b
          reference: <testLibrary>::@enum::E::@getter::b
          firstFragment: #F7
          returnType: E
          variable: <testLibrary>::@enum::E::@field::b
        static isOriginVariable values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F8
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
''');
  }

  test_enum_value_documented_withMetadata() async {
    var library = await buildLibrary('''
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
            #F2 hasInitializer isOriginDeclaration a (nameOffset:46) (firstTokenOffset:11) (offset:46)
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
            #F3 hasInitializer isOriginDeclaration b (nameOffset:75) (firstTokenOffset:51) (offset:75)
              element: <testLibrary>::@enum::E::@field::b
              documentationComment: /// bbb
              metadata
                Annotation
                  atSign: @ @61
                  name: SimpleIdentifier
                    token: annotation @62
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
            #F4 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
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
            #F5 const isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F6 isOriginVariable a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:46)
              element: <testLibrary>::@enum::E::@getter::a
            #F7 isOriginVariable b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:75)
              element: <testLibrary>::@enum::E::@getter::b
            #F8 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
      topLevelVariables
        #F9 hasInitializer isOriginDeclaration annotation (nameOffset:91) (firstTokenOffset:91) (offset:91)
          element: <testLibrary>::@topLevelVariable::annotation
          initializer: expression_3
            IntegerLiteral
              literal: 0 @104
              staticType: int
      getters
        #F10 isOriginVariable annotation (nameOffset:<null>) (firstTokenOffset:<null>) (offset:91)
          element: <testLibrary>::@getter::annotation
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration a
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
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration b
          reference: <testLibrary>::@enum::E::@field::b
          firstFragment: #F3
          documentationComment: /// bbb
          metadata
            Annotation
              atSign: @ @61
              name: SimpleIdentifier
                token: annotation @62
                element: <testLibrary>::@getter::annotation
                staticType: null
              element: <testLibrary>::@getter::annotation
          type: E
          constantInitializer
            fragment: #F3
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::b
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F4
          type: List<E>
          constantInitializer
            fragment: #F4
            expression: expression_2
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        const isOriginImplicitDefault new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F5
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable a
          reference: <testLibrary>::@enum::E::@getter::a
          firstFragment: #F6
          returnType: E
          variable: <testLibrary>::@enum::E::@field::a
        static isOriginVariable b
          reference: <testLibrary>::@enum::E::@getter::b
          firstFragment: #F7
          returnType: E
          variable: <testLibrary>::@enum::E::@field::b
        static isOriginVariable values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F8
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
  topLevelVariables
    const hasInitializer isOriginDeclaration annotation
      reference: <testLibrary>::@topLevelVariable::annotation
      firstFragment: #F9
      type: int
      constantInitializer
        fragment: #F9
        expression: expression_3
      getter: <testLibrary>::@getter::annotation
  getters
    static isOriginVariable annotation
      reference: <testLibrary>::@getter::annotation
      firstFragment: #F10
      returnType: int
      variable: <testLibrary>::@topLevelVariable::annotation
''');
  }

  test_enum_value_missingName() async {
    var library = await buildLibrary(r'''
enum E {v,,}
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
            #F2 hasInitializer isOriginDeclaration v (nameOffset:8) (firstTokenOffset:8) (offset:8)
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
            #F3 hasInitializer isOriginDeclaration <null-name> (nameOffset:<null>) (firstTokenOffset:10) (offset:10)
              element: <testLibrary>::@enum::E::@field::0
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
            #F4 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
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
          constructors
            #F5 const isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F6 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:8)
              element: <testLibrary>::@enum::E::@getter::v
            #F7 isOriginVariable <null-name> (nameOffset:<null>) (firstTokenOffset:<null>) (offset:10)
              element: <testLibrary>::@enum::E::@getter::1
            #F8 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration <null-name>
          reference: <testLibrary>::@enum::E::@field::0
          firstFragment: #F3
          type: E
          constantInitializer
            fragment: #F3
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::1
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F4
          type: List<E>
          constantInitializer
            fragment: #F4
            expression: expression_2
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        const isOriginImplicitDefault new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F5
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F6
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        static isOriginVariable <null-name>
          reference: <testLibrary>::@enum::E::@getter::1
          firstFragment: #F7
          returnType: E
          variable: <testLibrary>::@enum::E::@field::0
        static isOriginVariable values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F8
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
''');
  }

  test_enum_values() async {
    var library = await buildLibrary('enum E { v1, v2 }');
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
            #F2 hasInitializer isOriginDeclaration v1 (nameOffset:9) (firstTokenOffset:9) (offset:9)
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
            #F3 hasInitializer isOriginDeclaration v2 (nameOffset:13) (firstTokenOffset:13) (offset:13)
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
            #F4 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
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
          constructors
            #F5 const isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F6 isOriginVariable v1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:9)
              element: <testLibrary>::@enum::E::@getter::v1
            #F7 isOriginVariable v2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:13)
              element: <testLibrary>::@enum::E::@getter::v2
            #F8 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v1
          reference: <testLibrary>::@enum::E::@field::v1
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v1
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v2
          reference: <testLibrary>::@enum::E::@field::v2
          firstFragment: #F3
          type: E
          constantInitializer
            fragment: #F3
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::v2
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F4
          type: List<E>
          constantInitializer
            fragment: #F4
            expression: expression_2
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        const isOriginImplicitDefault new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F5
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v1
          reference: <testLibrary>::@enum::E::@getter::v1
          firstFragment: #F6
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v1
        static isOriginVariable v2
          reference: <testLibrary>::@enum::E::@getter::v2
          firstFragment: #F7
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v2
        static isOriginVariable values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F8
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
''');
  }

  test_enums() async {
    var library = await buildLibrary('enum E1 { v1 } enum E2 { v2 }');
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
            #F2 hasInitializer isOriginDeclaration v1 (nameOffset:10) (firstTokenOffset:10) (offset:10)
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
            #F3 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
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
          constructors
            #F4 const isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E1::@constructor::new
              typeName: E1
          getters
            #F5 isOriginVariable v1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:10)
              element: <testLibrary>::@enum::E1::@getter::v1
            #F6 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E1::@getter::values
        #F7 enum E2 (nameOffset:20) (firstTokenOffset:15) (offset:20)
          element: <testLibrary>::@enum::E2
          fields
            #F8 hasInitializer isOriginDeclaration v2 (nameOffset:25) (firstTokenOffset:25) (offset:25)
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
            #F9 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:20)
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
          constructors
            #F10 const isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:20)
              element: <testLibrary>::@enum::E2::@constructor::new
              typeName: E2
          getters
            #F11 isOriginVariable v2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
              element: <testLibrary>::@enum::E2::@getter::v2
            #F12 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:20)
              element: <testLibrary>::@enum::E2::@getter::values
  enums
    enum E1
      reference: <testLibrary>::@enum::E1
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v1
          reference: <testLibrary>::@enum::E1::@field::v1
          firstFragment: #F2
          type: E1
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E1::@getter::v1
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::E1::@field::values
          firstFragment: #F3
          type: List<E1>
          constantInitializer
            fragment: #F3
            expression: expression_1
          getter: <testLibrary>::@enum::E1::@getter::values
      constructors
        const isOriginImplicitDefault new
          reference: <testLibrary>::@enum::E1::@constructor::new
          firstFragment: #F4
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v1
          reference: <testLibrary>::@enum::E1::@getter::v1
          firstFragment: #F5
          returnType: E1
          variable: <testLibrary>::@enum::E1::@field::v1
        static isOriginVariable values
          reference: <testLibrary>::@enum::E1::@getter::values
          firstFragment: #F6
          returnType: List<E1>
          variable: <testLibrary>::@enum::E1::@field::values
    enum E2
      reference: <testLibrary>::@enum::E2
      firstFragment: #F7
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v2
          reference: <testLibrary>::@enum::E2::@field::v2
          firstFragment: #F8
          type: E2
          constantInitializer
            fragment: #F8
            expression: expression_2
          getter: <testLibrary>::@enum::E2::@getter::v2
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::E2::@field::values
          firstFragment: #F9
          type: List<E2>
          constantInitializer
            fragment: #F9
            expression: expression_3
          getter: <testLibrary>::@enum::E2::@getter::values
      constructors
        const isOriginImplicitDefault new
          reference: <testLibrary>::@enum::E2::@constructor::new
          firstFragment: #F10
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v2
          reference: <testLibrary>::@enum::E2::@getter::v2
          firstFragment: #F11
          returnType: E2
          variable: <testLibrary>::@enum::E2::@field::v2
        static isOriginVariable values
          reference: <testLibrary>::@enum::E2::@getter::values
          firstFragment: #F12
          returnType: List<E2>
          variable: <testLibrary>::@enum::E2::@field::values
''');
  }

  test_error_extendsEnum() async {
    var library = await buildLibrary('''
enum E {a, b, c}

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
        #F1 class M (nameOffset:24) (firstTokenOffset:18) (offset:24)
          element: <testLibrary>::@class::M
          constructors
            #F2 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:24)
              element: <testLibrary>::@class::M::@constructor::new
              typeName: M
        #F3 class A (nameOffset:36) (firstTokenOffset:30) (offset:36)
          element: <testLibrary>::@class::A
          constructors
            #F4 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:36)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          methods
            #F5 isOriginDeclaration foo (nameOffset:52) (firstTokenOffset:52) (offset:52)
              element: <testLibrary>::@class::A::@method::foo
        #F6 class B (nameOffset:70) (firstTokenOffset:64) (offset:70)
          element: <testLibrary>::@class::B
          constructors
            #F7 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:70)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          methods
            #F8 isOriginDeclaration foo (nameOffset:92) (firstTokenOffset:92) (offset:92)
              element: <testLibrary>::@class::B::@method::foo
        #F9 class C (nameOffset:110) (firstTokenOffset:104) (offset:110)
          element: <testLibrary>::@class::C
          constructors
            #F10 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:110)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          methods
            #F11 isOriginDeclaration foo (nameOffset:141) (firstTokenOffset:141) (offset:141)
              element: <testLibrary>::@class::C::@method::foo
        #F12 class D (nameOffset:159) (firstTokenOffset:153) (offset:159)
          element: <testLibrary>::@class::D
          constructors
            #F13 const isOriginMixinApplication new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:159)
              element: <testLibrary>::@class::D::@constructor::new
              typeName: D
      enums
        #F14 enum E (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@enum::E
          fields
            #F15 hasInitializer isOriginDeclaration a (nameOffset:8) (firstTokenOffset:8) (offset:8)
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
            #F16 hasInitializer isOriginDeclaration b (nameOffset:11) (firstTokenOffset:11) (offset:11)
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
            #F17 hasInitializer isOriginDeclaration c (nameOffset:14) (firstTokenOffset:14) (offset:14)
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
            #F18 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
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
          constructors
            #F19 const isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F20 isOriginVariable a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:8)
              element: <testLibrary>::@enum::E::@getter::a
            #F21 isOriginVariable b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::E::@getter::b
            #F22 isOriginVariable c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:14)
              element: <testLibrary>::@enum::E::@getter::c
            #F23 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
  classes
    class M
      reference: <testLibrary>::@class::M
      firstFragment: #F1
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::M::@constructor::new
          firstFragment: #F2
    class A
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
    class B
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
    class C
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
    class alias D
      reference: <testLibrary>::@class::D
      firstFragment: #F12
      supertype: Object
      mixins
        M
      constructors
        const isOriginMixinApplication new
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
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F14
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration a
          reference: <testLibrary>::@enum::E::@field::a
          firstFragment: #F15
          type: E
          constantInitializer
            fragment: #F15
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::a
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration b
          reference: <testLibrary>::@enum::E::@field::b
          firstFragment: #F16
          type: E
          constantInitializer
            fragment: #F16
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::b
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration c
          reference: <testLibrary>::@enum::E::@field::c
          firstFragment: #F17
          type: E
          constantInitializer
            fragment: #F17
            expression: expression_2
          getter: <testLibrary>::@enum::E::@getter::c
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F18
          type: List<E>
          constantInitializer
            fragment: #F18
            expression: expression_3
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        const isOriginImplicitDefault new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F19
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable a
          reference: <testLibrary>::@enum::E::@getter::a
          firstFragment: #F20
          returnType: E
          variable: <testLibrary>::@enum::E::@field::a
        static isOriginVariable b
          reference: <testLibrary>::@enum::E::@getter::b
          firstFragment: #F21
          returnType: E
          variable: <testLibrary>::@enum::E::@field::b
        static isOriginVariable c
          reference: <testLibrary>::@enum::E::@getter::c
          firstFragment: #F22
          returnType: E
          variable: <testLibrary>::@enum::E::@field::c
        static isOriginVariable values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F23
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
''');
  }

  test_metadata_enum_constant() async {
    var library = await buildLibrary('const a = 42; enum E { @a v }');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      enums
        #F1 enum E (nameOffset:19) (firstTokenOffset:14) (offset:19)
          element: <testLibrary>::@enum::E
          fields
            #F2 hasInitializer isOriginDeclaration v (nameOffset:26) (firstTokenOffset:23) (offset:26)
              element: <testLibrary>::@enum::E::@field::v
              metadata
                Annotation
                  atSign: @ @23
                  name: SimpleIdentifier
                    token: a @24
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
            #F3 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:19)
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
          constructors
            #F4 const isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:19)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F5 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:26)
              element: <testLibrary>::@enum::E::@getter::v
            #F6 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:19)
              element: <testLibrary>::@enum::E::@getter::values
      topLevelVariables
        #F7 hasInitializer isOriginDeclaration a (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::a
          initializer: expression_2
            IntegerLiteral
              literal: 42 @10
              staticType: int
      getters
        #F8 isOriginVariable a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F2
          metadata
            Annotation
              atSign: @ @23
              name: SimpleIdentifier
                token: a @24
                element: <testLibrary>::@getter::a
                staticType: null
              element: <testLibrary>::@getter::a
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F3
          type: List<E>
          constantInitializer
            fragment: #F3
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        const isOriginImplicitDefault new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F4
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F5
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F6
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
  topLevelVariables
    const hasImplicitType hasInitializer isOriginDeclaration a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F7
      type: int
      constantInitializer
        fragment: #F7
        expression: expression_2
      getter: <testLibrary>::@getter::a
  getters
    static isOriginVariable a
      reference: <testLibrary>::@getter::a
      firstFragment: #F8
      returnType: int
      variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_metadata_enum_constant_instanceCreation() async {
    var library = await buildLibrary('''
class A {
  final dynamic value;
  const A(this.value);
}

enum E {
  @A(100) a,
  b,
  @A(300) c,
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
            #F2 isOriginDeclaration value (nameOffset:26) (firstTokenOffset:26) (offset:26)
              element: <testLibrary>::@class::A::@field::value
          constructors
            #F3 const isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:35) (offset:41)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
              typeNameOffset: 41
              formalParameters
                #F4 requiredPositional final this.value (nameOffset:48) (firstTokenOffset:43) (offset:48)
                  element: <testLibrary>::@class::A::@constructor::new::@formalParameter::value
          getters
            #F5 isOriginVariable value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:26)
              element: <testLibrary>::@class::A::@getter::value
      enums
        #F6 enum E (nameOffset:64) (firstTokenOffset:59) (offset:64)
          element: <testLibrary>::@enum::E
          fields
            #F7 hasInitializer isOriginDeclaration a (nameOffset:78) (firstTokenOffset:70) (offset:78)
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
            #F8 hasInitializer isOriginDeclaration b (nameOffset:83) (firstTokenOffset:83) (offset:83)
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
            #F9 hasInitializer isOriginDeclaration c (nameOffset:96) (firstTokenOffset:88) (offset:96)
              element: <testLibrary>::@enum::E::@field::c
              metadata
                Annotation
                  atSign: @ @88
                  name: SimpleIdentifier
                    token: A @89
                    element: <testLibrary>::@class::A
                    staticType: null
                  arguments: ArgumentList
                    leftParenthesis: ( @90
                    arguments
                      IntegerLiteral
                        literal: 300 @91
                        staticType: int
                    rightParenthesis: ) @94
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
            #F10 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:64)
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
          constructors
            #F11 const isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:64)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F12 isOriginVariable a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:78)
              element: <testLibrary>::@enum::E::@getter::a
            #F13 isOriginVariable b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:83)
              element: <testLibrary>::@enum::E::@getter::b
            #F14 isOriginVariable c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:96)
              element: <testLibrary>::@enum::E::@getter::c
            #F15 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:64)
              element: <testLibrary>::@enum::E::@getter::values
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        final isOriginDeclaration value
          reference: <testLibrary>::@class::A::@field::value
          firstFragment: #F2
          type: dynamic
          getter: <testLibrary>::@class::A::@getter::value
      constructors
        const isOriginDeclaration new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional final hasImplicitType this.value
              firstFragment: #F4
              type: dynamic
              field: <testLibrary>::@class::A::@field::value
      getters
        isOriginVariable value
          reference: <testLibrary>::@class::A::@getter::value
          firstFragment: #F5
          returnType: dynamic
          variable: <testLibrary>::@class::A::@field::value
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F6
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration a
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
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration b
          reference: <testLibrary>::@enum::E::@field::b
          firstFragment: #F8
          type: E
          constantInitializer
            fragment: #F8
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::b
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration c
          reference: <testLibrary>::@enum::E::@field::c
          firstFragment: #F9
          metadata
            Annotation
              atSign: @ @88
              name: SimpleIdentifier
                token: A @89
                element: <testLibrary>::@class::A
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @90
                arguments
                  IntegerLiteral
                    literal: 300 @91
                    staticType: int
                rightParenthesis: ) @94
              element: <testLibrary>::@class::A::@constructor::new
          type: E
          constantInitializer
            fragment: #F9
            expression: expression_2
          getter: <testLibrary>::@enum::E::@getter::c
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F10
          type: List<E>
          constantInitializer
            fragment: #F10
            expression: expression_3
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        const isOriginImplicitDefault new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F11
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable a
          reference: <testLibrary>::@enum::E::@getter::a
          firstFragment: #F12
          returnType: E
          variable: <testLibrary>::@enum::E::@field::a
        static isOriginVariable b
          reference: <testLibrary>::@enum::E::@getter::b
          firstFragment: #F13
          returnType: E
          variable: <testLibrary>::@enum::E::@field::b
        static isOriginVariable c
          reference: <testLibrary>::@enum::E::@getter::c
          firstFragment: #F14
          returnType: E
          variable: <testLibrary>::@enum::E::@field::c
        static isOriginVariable values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F15
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
''');
  }

  test_metadata_enum_constant_self() async {
    var library = await buildLibrary(r'''
enum E {
  @v
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
        #F1 enum E (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@enum::E
          fields
            #F2 hasInitializer isOriginDeclaration v (nameOffset:16) (firstTokenOffset:11) (offset:16)
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
            #F3 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
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
          constructors
            #F4 const isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F5 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@enum::E::@getter::v
            #F6 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
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
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F3
          type: List<E>
          constantInitializer
            fragment: #F3
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        const isOriginImplicitDefault new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F4
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F5
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F6
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
''');
  }

  test_metadata_enum_constructor() async {
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
        #F1 enum E (nameOffset:19) (firstTokenOffset:14) (offset:19)
          element: <testLibrary>::@enum::E
          fields
            #F2 hasInitializer isOriginDeclaration v (nameOffset:25) (firstTokenOffset:25) (offset:25)
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
            #F3 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:19)
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
          constructors
            #F4 const isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:30) (offset:41)
              element: <testLibrary>::@enum::E::@constructor::new
              metadata
                Annotation
                  atSign: @ @30
                  name: SimpleIdentifier
                    token: a @31
                    element: <testLibrary>::@getter::a
                    staticType: null
                  element: <testLibrary>::@getter::a
              typeName: E
              typeNameOffset: 41
          getters
            #F5 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
              element: <testLibrary>::@enum::E::@getter::v
            #F6 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:19)
              element: <testLibrary>::@enum::E::@getter::values
      topLevelVariables
        #F7 hasInitializer isOriginDeclaration a (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::a
          initializer: expression_2
            IntegerLiteral
              literal: 42 @10
              staticType: int
      getters
        #F8 isOriginVariable a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F3
          type: List<E>
          constantInitializer
            fragment: #F3
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        const isOriginDeclaration new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F4
          metadata
            Annotation
              atSign: @ @30
              name: SimpleIdentifier
                token: a @31
                element: <testLibrary>::@getter::a
                staticType: null
              element: <testLibrary>::@getter::a
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F5
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F6
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
  topLevelVariables
    const hasImplicitType hasInitializer isOriginDeclaration a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F7
      type: int
      constantInitializer
        fragment: #F7
        expression: expression_2
      getter: <testLibrary>::@getter::a
  getters
    static isOriginVariable a
      reference: <testLibrary>::@getter::a
      firstFragment: #F8
      returnType: int
      variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_metadata_enum_method() async {
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
        #F1 enum E (nameOffset:19) (firstTokenOffset:14) (offset:19)
          element: <testLibrary>::@enum::E
          fields
            #F2 hasInitializer isOriginDeclaration v (nameOffset:25) (firstTokenOffset:25) (offset:25)
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
            #F3 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:19)
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
          constructors
            #F4 const isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:19)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F5 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
              element: <testLibrary>::@enum::E::@getter::v
            #F6 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:19)
              element: <testLibrary>::@enum::E::@getter::values
          methods
            #F7 isOriginDeclaration foo (nameOffset:40) (firstTokenOffset:30) (offset:40)
              element: <testLibrary>::@enum::E::@method::foo
              metadata
                Annotation
                  atSign: @ @30
                  name: SimpleIdentifier
                    token: a @31
                    element: <testLibrary>::@getter::a
                    staticType: null
                  element: <testLibrary>::@getter::a
      topLevelVariables
        #F8 hasInitializer isOriginDeclaration a (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::a
          initializer: expression_2
            IntegerLiteral
              literal: 42 @10
              staticType: int
      getters
        #F9 isOriginVariable a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F3
          type: List<E>
          constantInitializer
            fragment: #F3
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        const isOriginImplicitDefault new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F4
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F5
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F6
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
      methods
        isOriginDeclaration foo
          reference: <testLibrary>::@enum::E::@method::foo
          firstFragment: #F7
          metadata
            Annotation
              atSign: @ @30
              name: SimpleIdentifier
                token: a @31
                element: <testLibrary>::@getter::a
                staticType: null
              element: <testLibrary>::@getter::a
          returnType: void
  topLevelVariables
    const hasImplicitType hasInitializer isOriginDeclaration a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F8
      type: int
      constantInitializer
        fragment: #F8
        expression: expression_2
      getter: <testLibrary>::@getter::a
  getters
    static isOriginVariable a
      reference: <testLibrary>::@getter::a
      firstFragment: #F9
      returnType: int
      variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_metadata_enum_scope() async {
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
            #F3 hasInitializer isOriginDeclaration v (nameOffset:40) (firstTokenOffset:40) (offset:40)
              element: <testLibrary>::@enum::E::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibrary>::@enum::E
                      type: E<dynamic>
                    element: ConstructorMember
                      baseElement: <testLibrary>::@enum::E::@constructor::new
                      substitution: {T: dynamic}
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E<dynamic>
            #F4 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:26)
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
            #F5 hasInitializer isOriginDeclaration foo (nameOffset:58) (firstTokenOffset:58) (offset:58)
              element: <testLibrary>::@enum::E::@field::foo
              initializer: expression_2
                IntegerLiteral
                  literal: 1 @64
                  staticType: int
          constructors
            #F6 const isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:26)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F7 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
              element: <testLibrary>::@enum::E::@getter::v
            #F8 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:26)
              element: <testLibrary>::@enum::E::@getter::values
            #F9 isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:58)
              element: <testLibrary>::@enum::E::@getter::foo
          methods
            #F10 isOriginDeclaration bar (nameOffset:81) (firstTokenOffset:69) (offset:81)
              element: <testLibrary>::@enum::E::@method::bar
              metadata
                Annotation
                  atSign: @ @69
                  name: SimpleIdentifier
                    token: foo @70
                    element: <testLibrary>::@enum::E::@getter::foo
                    staticType: null
                  element: <testLibrary>::@enum::E::@getter::foo
      topLevelVariables
        #F11 hasInitializer isOriginDeclaration foo (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::foo
          initializer: expression_3
            IntegerLiteral
              literal: 0 @12
              staticType: int
      getters
        #F12 isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::foo
  enums
    enum E
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
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F3
          type: E<dynamic>
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F4
          type: List<E<dynamic>>
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
        static const hasImplicitType hasInitializer isOriginDeclaration foo
          reference: <testLibrary>::@enum::E::@field::foo
          firstFragment: #F5
          type: int
          constantInitializer
            fragment: #F5
            expression: expression_2
          getter: <testLibrary>::@enum::E::@getter::foo
      constructors
        const isOriginImplicitDefault new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F6
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F7
          returnType: E<dynamic>
          variable: <testLibrary>::@enum::E::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F8
          returnType: List<E<dynamic>>
          variable: <testLibrary>::@enum::E::@field::values
        static isOriginVariable foo
          reference: <testLibrary>::@enum::E::@getter::foo
          firstFragment: #F9
          returnType: int
          variable: <testLibrary>::@enum::E::@field::foo
      methods
        isOriginDeclaration bar
          reference: <testLibrary>::@enum::E::@method::bar
          firstFragment: #F10
          metadata
            Annotation
              atSign: @ @69
              name: SimpleIdentifier
                token: foo @70
                element: <testLibrary>::@enum::E::@getter::foo
                staticType: null
              element: <testLibrary>::@enum::E::@getter::foo
          returnType: void
  topLevelVariables
    const hasImplicitType hasInitializer isOriginDeclaration foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: #F11
      type: int
      constantInitializer
        fragment: #F11
        expression: expression_3
      getter: <testLibrary>::@getter::foo
  getters
    static isOriginVariable foo
      reference: <testLibrary>::@getter::foo
      firstFragment: #F12
      returnType: int
      variable: <testLibrary>::@topLevelVariable::foo
''');
  }

  test_metadata_enum_typeParameter() async {
    var library = await buildLibrary('''
const a = 42;
enum E<@a T> {
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
        #F1 enum E (nameOffset:19) (firstTokenOffset:14) (offset:19)
          element: <testLibrary>::@enum::E
          typeParameters
            #F2 T (nameOffset:24) (firstTokenOffset:21) (offset:24)
              element: #E0 T
              metadata
                Annotation
                  atSign: @ @21
                  name: SimpleIdentifier
                    token: a @22
                    element: <testLibrary>::@getter::a
                    staticType: null
                  element: <testLibrary>::@getter::a
          fields
            #F3 hasInitializer isOriginDeclaration v (nameOffset:31) (firstTokenOffset:31) (offset:31)
              element: <testLibrary>::@enum::E::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibrary>::@enum::E
                      type: E<dynamic>
                    element: ConstructorMember
                      baseElement: <testLibrary>::@enum::E::@constructor::new
                      substitution: {T: dynamic}
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E<dynamic>
            #F4 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:19)
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
          constructors
            #F5 const isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:19)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F6 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
              element: <testLibrary>::@enum::E::@getter::v
            #F7 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:19)
              element: <testLibrary>::@enum::E::@getter::values
      topLevelVariables
        #F8 hasInitializer isOriginDeclaration a (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::a
          initializer: expression_2
            IntegerLiteral
              literal: 42 @10
              staticType: int
      getters
        #F9 isOriginVariable a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
          metadata
            Annotation
              atSign: @ @21
              name: SimpleIdentifier
                token: a @22
                element: <testLibrary>::@getter::a
                staticType: null
              element: <testLibrary>::@getter::a
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F3
          type: E<dynamic>
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F4
          type: List<E<dynamic>>
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        const isOriginImplicitDefault new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F5
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F6
          returnType: E<dynamic>
          variable: <testLibrary>::@enum::E::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F7
          returnType: List<E<dynamic>>
          variable: <testLibrary>::@enum::E::@field::values
  topLevelVariables
    const hasImplicitType hasInitializer isOriginDeclaration a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F8
      type: int
      constantInitializer
        fragment: #F8
        expression: expression_2
      getter: <testLibrary>::@getter::a
  getters
    static isOriginVariable a
      reference: <testLibrary>::@getter::a
      firstFragment: #F9
      returnType: int
      variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_metadata_enumDeclaration() async {
    var library = await buildLibrary('const a = 42; @a enum E { v }');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      enums
        #F1 enum E (nameOffset:22) (firstTokenOffset:14) (offset:22)
          element: <testLibrary>::@enum::E
          fields
            #F2 hasInitializer isOriginDeclaration v (nameOffset:26) (firstTokenOffset:26) (offset:26)
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
            #F3 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
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
          constructors
            #F4 const isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F5 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:26)
              element: <testLibrary>::@enum::E::@getter::v
            #F6 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
              element: <testLibrary>::@enum::E::@getter::values
      topLevelVariables
        #F7 hasInitializer isOriginDeclaration a (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::a
          initializer: expression_2
            IntegerLiteral
              literal: 42 @10
              staticType: int
      getters
        #F8 isOriginVariable a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F3
          type: List<E>
          constantInitializer
            fragment: #F3
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        const isOriginImplicitDefault new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F4
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F5
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F6
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
  topLevelVariables
    const hasImplicitType hasInitializer isOriginDeclaration a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F7
      type: int
      constantInitializer
        fragment: #F7
        expression: expression_2
      getter: <testLibrary>::@getter::a
  getters
    static isOriginVariable a
      reference: <testLibrary>::@getter::a
      firstFragment: #F8
      returnType: int
      variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_primaryConstructor_declaringFormalParameter_optionalNamed_simple_final() async {
    var library = await buildLibrary('''
enum A({final int? foo}) {v(foo: 0)}
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
            #F2 hasInitializer isOriginDeclaration v (nameOffset:26) (firstTokenOffset:26) (offset:26)
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
                    leftParenthesis: ( @27
                    arguments
                      NamedExpression
                        name: Label
                          label: SimpleIdentifier
                            token: foo @28
                            element: <testLibrary>::@enum::A::@constructor::new::@formalParameter::foo
                            staticType: null
                          colon: : @31
                        expression: IntegerLiteral
                          literal: 0 @33
                          staticType: int
                    rightParenthesis: ) @34
                  staticType: A
            #F3 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
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
            #F4 isOriginDeclaringFormalParameter foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@field::foo
          constructors
            #F5 const isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:5) (offset:5)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
              typeNameOffset: 5
              formalParameters
                #F6 optionalNamed final this.foo (nameOffset:19) (firstTokenOffset:8) (offset:19)
                  element: <testLibrary>::@enum::A::@constructor::new::@formalParameter::foo
          getters
            #F7 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:26)
              element: <testLibrary>::@enum::A::@getter::v
            #F8 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
            #F9 isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::foo
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F2
          type: A
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F3
          type: List<A>
          constantInitializer
            fragment: #F3
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
        final isOriginDeclaringFormalParameter foo
          reference: <testLibrary>::@enum::A::@field::foo
          firstFragment: #F4
          type: int?
          getter: <testLibrary>::@enum::A::@getter::foo
          declaringFormalParameter: <testLibrary>::@enum::A::@constructor::new::@formalParameter::foo
      constructors
        const isOriginDeclaration isPrimary new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F5
          formalParameters
            #E0 optionalNamed final declaring this.foo
              firstFragment: #F6
              type: int?
              field: <testLibrary>::@enum::A::@field::foo
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F7
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F8
          returnType: List<A>
          variable: <testLibrary>::@enum::A::@field::values
        isOriginVariable foo
          reference: <testLibrary>::@enum::A::@getter::foo
          firstFragment: #F9
          returnType: int?
          variable: <testLibrary>::@enum::A::@field::foo
''');
  }

  test_primaryConstructor_declaringFormalParameter_optionalPositional_simple_final() async {
    var library = await buildLibrary('''
enum A([final int? foo]) {v(0)}
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
            #F2 hasInitializer isOriginDeclaration v (nameOffset:26) (firstTokenOffset:26) (offset:26)
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
                    leftParenthesis: ( @27
                    arguments
                      IntegerLiteral
                        literal: 0 @28
                        staticType: int
                    rightParenthesis: ) @29
                  staticType: A
            #F3 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
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
            #F4 isOriginDeclaringFormalParameter foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@field::foo
          constructors
            #F5 const isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:5) (offset:5)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
              typeNameOffset: 5
              formalParameters
                #F6 optionalPositional final this.foo (nameOffset:19) (firstTokenOffset:8) (offset:19)
                  element: <testLibrary>::@enum::A::@constructor::new::@formalParameter::foo
          getters
            #F7 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:26)
              element: <testLibrary>::@enum::A::@getter::v
            #F8 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
            #F9 isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::foo
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F2
          type: A
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F3
          type: List<A>
          constantInitializer
            fragment: #F3
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
        final isOriginDeclaringFormalParameter foo
          reference: <testLibrary>::@enum::A::@field::foo
          firstFragment: #F4
          type: int?
          getter: <testLibrary>::@enum::A::@getter::foo
          declaringFormalParameter: <testLibrary>::@enum::A::@constructor::new::@formalParameter::foo
      constructors
        const isOriginDeclaration isPrimary new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F5
          formalParameters
            #E0 optionalPositional final declaring this.foo
              firstFragment: #F6
              type: int?
              field: <testLibrary>::@enum::A::@field::foo
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F7
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F8
          returnType: List<A>
          variable: <testLibrary>::@enum::A::@field::values
        isOriginVariable foo
          reference: <testLibrary>::@enum::A::@getter::foo
          firstFragment: #F9
          returnType: int?
          variable: <testLibrary>::@enum::A::@field::foo
''');
  }

  test_primaryConstructor_declaringFormalParameter_requiredNamed_simple_final() async {
    var library = await buildLibrary('''
enum A({required final int foo}) {v(foo: 0)}
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
            #F2 hasInitializer isOriginDeclaration v (nameOffset:34) (firstTokenOffset:34) (offset:34)
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
                    leftParenthesis: ( @35
                    arguments
                      NamedExpression
                        name: Label
                          label: SimpleIdentifier
                            token: foo @36
                            element: <testLibrary>::@enum::A::@constructor::new::@formalParameter::foo
                            staticType: null
                          colon: : @39
                        expression: IntegerLiteral
                          literal: 0 @41
                          staticType: int
                    rightParenthesis: ) @42
                  staticType: A
            #F3 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
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
            #F4 isOriginDeclaringFormalParameter foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@field::foo
          constructors
            #F5 const isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:5) (offset:5)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
              typeNameOffset: 5
              formalParameters
                #F6 requiredNamed final this.foo (nameOffset:27) (firstTokenOffset:8) (offset:27)
                  element: <testLibrary>::@enum::A::@constructor::new::@formalParameter::foo
          getters
            #F7 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:34)
              element: <testLibrary>::@enum::A::@getter::v
            #F8 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
            #F9 isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::foo
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F2
          type: A
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F3
          type: List<A>
          constantInitializer
            fragment: #F3
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
        final isOriginDeclaringFormalParameter foo
          reference: <testLibrary>::@enum::A::@field::foo
          firstFragment: #F4
          type: int
          getter: <testLibrary>::@enum::A::@getter::foo
          declaringFormalParameter: <testLibrary>::@enum::A::@constructor::new::@formalParameter::foo
      constructors
        const isOriginDeclaration isPrimary new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F5
          formalParameters
            #E0 requiredNamed final declaring this.foo
              firstFragment: #F6
              type: int
              field: <testLibrary>::@enum::A::@field::foo
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F7
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F8
          returnType: List<A>
          variable: <testLibrary>::@enum::A::@field::values
        isOriginVariable foo
          reference: <testLibrary>::@enum::A::@getter::foo
          firstFragment: #F9
          returnType: int
          variable: <testLibrary>::@enum::A::@field::foo
''');
  }

  test_primaryConstructor_declaringFormalParameter_requiredPositional_functionTyped_final() async {
    var library = await buildLibrary(r'''
enum A(
  /// first
  /// second
  @deprecated
  final void foo(),
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
            #F2 hasInitializer isOriginDeclaration v (nameOffset:73) (firstTokenOffset:73) (offset:73)
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
                    leftParenthesis: ( @74
                    rightParenthesis: ) @75
                  staticType: A
            #F3 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
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
            #F4 isOriginDeclaringFormalParameter foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@field::foo
          constructors
            #F5 const isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:5) (offset:5)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
              typeNameOffset: 5
              formalParameters
                #F6 requiredPositional final this.foo (nameOffset:60) (firstTokenOffset:10) (offset:60)
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
            #F7 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:73)
              element: <testLibrary>::@enum::A::@getter::v
            #F8 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
            #F9 isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::foo
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F2
          type: A
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F3
          type: List<A>
          constantInitializer
            fragment: #F3
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
        final isOriginDeclaringFormalParameter foo
          reference: <testLibrary>::@enum::A::@field::foo
          firstFragment: #F4
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
        const isOriginDeclaration isPrimary new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional final declaring this.foo
              firstFragment: #F6
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
        static isOriginVariable v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F7
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F8
          returnType: List<A>
          variable: <testLibrary>::@enum::A::@field::values
        isOriginVariable foo
          reference: <testLibrary>::@enum::A::@getter::foo
          firstFragment: #F9
          returnType: void Function()
          variable: <testLibrary>::@enum::A::@field::foo
''');
  }

  test_primaryConstructor_declaringFormalParameter_requiredPositional_simple_final() async {
    var library = await buildLibrary(r'''
enum A(
  /// first
  /// second
  @deprecated
  final int foo,
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
            #F2 hasInitializer isOriginDeclaration v (nameOffset:70) (firstTokenOffset:70) (offset:70)
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
                    leftParenthesis: ( @71
                    arguments
                      IntegerLiteral
                        literal: 0 @72
                        staticType: int
                    rightParenthesis: ) @73
                  staticType: A
            #F3 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
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
            #F4 isOriginDeclaringFormalParameter foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@field::foo
          constructors
            #F5 const isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:5) (offset:5)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
              typeNameOffset: 5
              formalParameters
                #F6 requiredPositional final this.foo (nameOffset:59) (firstTokenOffset:10) (offset:59)
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
            #F7 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:70)
              element: <testLibrary>::@enum::A::@getter::v
            #F8 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
            #F9 isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::foo
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F2
          type: A
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F3
          type: List<A>
          constantInitializer
            fragment: #F3
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
        final isOriginDeclaringFormalParameter foo
          reference: <testLibrary>::@enum::A::@field::foo
          firstFragment: #F4
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
        const isOriginDeclaration isPrimary new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional final declaring this.foo
              firstFragment: #F6
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
        static isOriginVariable v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F7
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F8
          returnType: List<A>
          variable: <testLibrary>::@enum::A::@field::values
        isOriginVariable foo
          reference: <testLibrary>::@enum::A::@getter::foo
          firstFragment: #F9
          returnType: int
          variable: <testLibrary>::@enum::A::@field::foo
''');
  }

  test_primaryConstructor_declaringFormalParameter_requiredPositional_simple_var() async {
    var library = await buildLibrary('''
enum A(var int foo) {v(0)}
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
            #F2 hasInitializer isOriginDeclaration v (nameOffset:21) (firstTokenOffset:21) (offset:21)
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
            #F3 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
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
            #F4 isOriginDeclaringFormalParameter foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@field::foo
          constructors
            #F5 const isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:5) (offset:5)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
              typeNameOffset: 5
              formalParameters
                #F6 requiredPositional final this.foo (nameOffset:15) (firstTokenOffset:7) (offset:15)
                  element: <testLibrary>::@enum::A::@constructor::new::@formalParameter::foo
          getters
            #F7 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@enum::A::@getter::v
            #F8 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
            #F9 isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::foo
          setters
            #F10 isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@setter::foo
              formalParameters
                #F11 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
                  element: <testLibrary>::@enum::A::@setter::foo::@formalParameter::value
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F2
          type: A
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F3
          type: List<A>
          constantInitializer
            fragment: #F3
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
        isOriginDeclaringFormalParameter foo
          reference: <testLibrary>::@enum::A::@field::foo
          firstFragment: #F4
          type: int
          getter: <testLibrary>::@enum::A::@getter::foo
          setter: <testLibrary>::@enum::A::@setter::foo
          declaringFormalParameter: <testLibrary>::@enum::A::@constructor::new::@formalParameter::foo
      constructors
        const isOriginDeclaration isPrimary new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional final declaring this.foo
              firstFragment: #F6
              type: int
              field: <testLibrary>::@enum::A::@field::foo
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F7
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F8
          returnType: List<A>
          variable: <testLibrary>::@enum::A::@field::values
        isOriginVariable foo
          reference: <testLibrary>::@enum::A::@getter::foo
          firstFragment: #F9
          returnType: int
          variable: <testLibrary>::@enum::A::@field::foo
      setters
        isOriginVariable foo
          reference: <testLibrary>::@enum::A::@setter::foo
          firstFragment: #F10
          formalParameters
            #E1 requiredPositional value
              firstFragment: #F11
              type: int
          returnType: void
          variable: <testLibrary>::@enum::A::@field::foo
''');
  }

  test_primaryConstructor_declaringFormalParameter_requiredPositional_type_fromField_inferred() async {
    var library = await buildLibrary('''
class A {
  int get foo => 0;
}
enum B(final foo) implements A {v(0)}
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
            #F4 isOriginDeclaration foo (nameOffset:20) (firstTokenOffset:12) (offset:20)
              element: <testLibrary>::@class::A::@getter::foo
      enums
        #F5 enum B (nameOffset:37) (firstTokenOffset:32) (offset:37)
          element: <testLibrary>::@enum::B
          fields
            #F6 hasInitializer isOriginDeclaration v (nameOffset:64) (firstTokenOffset:64) (offset:64)
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
                    leftParenthesis: ( @65
                    arguments
                      IntegerLiteral
                        literal: 0 @66
                        staticType: int
                    rightParenthesis: ) @67
                  staticType: B
            #F7 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:37)
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
            #F8 isOriginDeclaringFormalParameter foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:37)
              element: <testLibrary>::@enum::B::@field::foo
          constructors
            #F9 const isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:37) (offset:37)
              element: <testLibrary>::@enum::B::@constructor::new
              typeName: B
              typeNameOffset: 37
              formalParameters
                #F10 requiredPositional final this.foo (nameOffset:45) (firstTokenOffset:39) (offset:45)
                  element: <testLibrary>::@enum::B::@constructor::new::@formalParameter::foo
          getters
            #F11 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:64)
              element: <testLibrary>::@enum::B::@getter::v
            #F12 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:37)
              element: <testLibrary>::@enum::B::@getter::values
            #F13 isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:37)
              element: <testLibrary>::@enum::B::@getter::foo
  classes
    class A
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
    enum B
      reference: <testLibrary>::@enum::B
      firstFragment: #F5
      supertype: Enum
      interfaces
        A
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::B::@field::v
          firstFragment: #F6
          type: B
          constantInitializer
            fragment: #F6
            expression: expression_0
          getter: <testLibrary>::@enum::B::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::B::@field::values
          firstFragment: #F7
          type: List<B>
          constantInitializer
            fragment: #F7
            expression: expression_1
          getter: <testLibrary>::@enum::B::@getter::values
        final hasImplicitType isOriginDeclaringFormalParameter foo
          reference: <testLibrary>::@enum::B::@field::foo
          firstFragment: #F8
          type: int
          getter: <testLibrary>::@enum::B::@getter::foo
          declaringFormalParameter: <testLibrary>::@enum::B::@constructor::new::@formalParameter::foo
      constructors
        const isOriginDeclaration isPrimary new
          reference: <testLibrary>::@enum::B::@constructor::new
          firstFragment: #F9
          formalParameters
            #E0 requiredPositional final hasImplicitType declaring this.foo
              firstFragment: #F10
              type: int
              field: <testLibrary>::@enum::B::@field::foo
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::B::@getter::v
          firstFragment: #F11
          returnType: B
          variable: <testLibrary>::@enum::B::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::B::@getter::values
          firstFragment: #F12
          returnType: List<B>
          variable: <testLibrary>::@enum::B::@field::values
        isOriginVariable foo
          reference: <testLibrary>::@enum::B::@getter::foo
          firstFragment: #F13
          returnType: int
          variable: <testLibrary>::@enum::B::@field::foo
''');
  }

  test_primaryConstructor_declaringFormalParameter_requiredPositional_type_typeParameter() async {
    var library = await buildLibrary('''
enum A<T>(final T foo) {v(0)}
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
            #F3 hasInitializer isOriginDeclaration v (nameOffset:24) (firstTokenOffset:24) (offset:24)
              element: <testLibrary>::@enum::A::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibrary>::@enum::A
                      type: A<int>
                    element: ConstructorMember
                      baseElement: <testLibrary>::@enum::A::@constructor::new
                      substitution: {T: int}
                  argumentList: ArgumentList
                    leftParenthesis: ( @25
                    arguments
                      IntegerLiteral
                        literal: 0 @26
                        staticType: int
                    rightParenthesis: ) @27
                  staticType: A<int>
            #F4 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
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
            #F5 isOriginDeclaringFormalParameter foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@field::foo
          constructors
            #F6 const isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:5) (offset:5)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
              typeNameOffset: 5
              formalParameters
                #F7 requiredPositional final this.foo (nameOffset:18) (firstTokenOffset:10) (offset:18)
                  element: <testLibrary>::@enum::A::@constructor::new::@formalParameter::foo
          getters
            #F8 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:24)
              element: <testLibrary>::@enum::A::@getter::v
            #F9 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
            #F10 isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::foo
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F3
          type: A<int>
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F4
          type: List<A<dynamic>>
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
        final isOriginDeclaringFormalParameter foo
          reference: <testLibrary>::@enum::A::@field::foo
          firstFragment: #F5
          hasEnclosingTypeParameterReference: true
          type: T
          getter: <testLibrary>::@enum::A::@getter::foo
          declaringFormalParameter: <testLibrary>::@enum::A::@constructor::new::@formalParameter::foo
      constructors
        const isOriginDeclaration isPrimary new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F6
          formalParameters
            #E1 requiredPositional final declaring this.foo
              firstFragment: #F7
              type: T
              field: <testLibrary>::@enum::A::@field::foo
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F8
          returnType: A<int>
          variable: <testLibrary>::@enum::A::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F9
          returnType: List<A<dynamic>>
          variable: <testLibrary>::@enum::A::@field::values
        isOriginVariable foo
          reference: <testLibrary>::@enum::A::@getter::foo
          firstFragment: #F10
          hasEnclosingTypeParameterReference: true
          returnType: T
          variable: <testLibrary>::@enum::A::@field::foo
''');
  }

  test_primaryConstructor_formalParameter_requiredPositional_functionTyped() async {
    var library = await buildLibrary('''
enum A(int foo()) {v(0)}
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
            #F2 hasInitializer isOriginDeclaration v (nameOffset:19) (firstTokenOffset:19) (offset:19)
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
                    leftParenthesis: ( @20
                    arguments
                      IntegerLiteral
                        literal: 0 @21
                        staticType: int
                    rightParenthesis: ) @22
                  staticType: A
            #F3 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
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
          constructors
            #F4 const isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:5) (offset:5)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
              typeNameOffset: 5
              formalParameters
                #F5 requiredPositional foo (nameOffset:11) (firstTokenOffset:7) (offset:11)
                  element: <testLibrary>::@enum::A::@constructor::new::@formalParameter::foo
          getters
            #F6 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:19)
              element: <testLibrary>::@enum::A::@getter::v
            #F7 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F2
          type: A
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F3
          type: List<A>
          constantInitializer
            fragment: #F3
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
      constructors
        const isOriginDeclaration isPrimary new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional foo
              firstFragment: #F5
              type: int Function()
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F6
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F7
          returnType: List<A>
          variable: <testLibrary>::@enum::A::@field::values
''');
  }

  test_primaryConstructor_formalParameter_requiredPositional_simple() async {
    var library = await buildLibrary('''
enum A(int foo) {v(0)}
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
            #F2 hasInitializer isOriginDeclaration v (nameOffset:17) (firstTokenOffset:17) (offset:17)
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
                    leftParenthesis: ( @18
                    arguments
                      IntegerLiteral
                        literal: 0 @19
                        staticType: int
                    rightParenthesis: ) @20
                  staticType: A
            #F3 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
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
          constructors
            #F4 const isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:5) (offset:5)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
              typeNameOffset: 5
              formalParameters
                #F5 requiredPositional foo (nameOffset:11) (firstTokenOffset:7) (offset:11)
                  element: <testLibrary>::@enum::A::@constructor::new::@formalParameter::foo
          getters
            #F6 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:17)
              element: <testLibrary>::@enum::A::@getter::v
            #F7 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F2
          type: A
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F3
          type: List<A>
          constantInitializer
            fragment: #F3
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
      constructors
        const isOriginDeclaration isPrimary new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional foo
              firstFragment: #F5
              type: int
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F6
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F7
          returnType: List<A>
          variable: <testLibrary>::@enum::A::@field::values
''');
  }

  test_primaryConstructor_formalParameter_requiredPositional_this() async {
    var library = await buildLibrary('''
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
            #F2 hasInitializer isOriginDeclaration v (nameOffset:21) (firstTokenOffset:21) (offset:21)
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
            #F3 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
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
            #F4 isOriginDeclaration foo (nameOffset:39) (firstTokenOffset:39) (offset:39)
              element: <testLibrary>::@enum::A::@field::foo
          constructors
            #F5 const isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:5) (offset:5)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
              typeNameOffset: 5
              formalParameters
                #F6 requiredPositional final this.foo (nameOffset:12) (firstTokenOffset:7) (offset:12)
                  element: <testLibrary>::@enum::A::@constructor::new::@formalParameter::foo
          getters
            #F7 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@enum::A::@getter::v
            #F8 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
            #F9 isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:39)
              element: <testLibrary>::@enum::A::@getter::foo
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F2
          type: A
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F3
          type: List<A>
          constantInitializer
            fragment: #F3
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
        final isOriginDeclaration foo
          reference: <testLibrary>::@enum::A::@field::foo
          firstFragment: #F4
          type: int
          getter: <testLibrary>::@enum::A::@getter::foo
      constructors
        const isOriginDeclaration isPrimary new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional final hasImplicitType this.foo
              firstFragment: #F6
              type: int
              field: <testLibrary>::@enum::A::@field::foo
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F7
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F8
          returnType: List<A>
          variable: <testLibrary>::@enum::A::@field::values
        isOriginVariable foo
          reference: <testLibrary>::@enum::A::@getter::foo
          firstFragment: #F9
          returnType: int
          variable: <testLibrary>::@enum::A::@field::foo
''');
  }

  test_primaryConstructor_named_const() async {
    var library = await buildLibrary('''
enum const A.named() {v.named()}
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
            #F2 hasInitializer isOriginDeclaration v (nameOffset:22) (firstTokenOffset:22) (offset:22)
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
                    leftParenthesis: ( @29
                    rightParenthesis: ) @30
                  staticType: A
            #F3 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
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
          constructors
            #F4 const isOriginDeclaration isPrimary named (nameOffset:13) (firstTokenOffset:5) (offset:13)
              element: <testLibrary>::@enum::A::@constructor::named
              typeName: A
              typeNameOffset: 11
              periodOffset: 12
          getters
            #F5 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
              element: <testLibrary>::@enum::A::@getter::v
            #F6 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::A::@getter::values
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F2
          type: A
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F3
          type: List<A>
          constantInitializer
            fragment: #F3
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
      constructors
        const isOriginDeclaration isPrimary named
          reference: <testLibrary>::@enum::A::@constructor::named
          firstFragment: #F4
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F5
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F6
          returnType: List<A>
          variable: <testLibrary>::@enum::A::@field::values
''');
  }

  test_primaryConstructor_named_notConst() async {
    var library = await buildLibrary('''
enum A.named() {v.named()}
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
            #F2 hasInitializer isOriginDeclaration v (nameOffset:16) (firstTokenOffset:16) (offset:16)
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
                    leftParenthesis: ( @23
                    rightParenthesis: ) @24
                  staticType: A
            #F3 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
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
          constructors
            #F4 const isOriginDeclaration isPrimary named (nameOffset:7) (firstTokenOffset:5) (offset:7)
              element: <testLibrary>::@enum::A::@constructor::named
              typeName: A
              typeNameOffset: 5
              periodOffset: 6
          getters
            #F5 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@enum::A::@getter::v
            #F6 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F2
          type: A
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F3
          type: List<A>
          constantInitializer
            fragment: #F3
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
      constructors
        const isOriginDeclaration isPrimary named
          reference: <testLibrary>::@enum::A::@constructor::named
          firstFragment: #F4
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F5
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F6
          returnType: List<A>
          variable: <testLibrary>::@enum::A::@field::values
''');
  }

  test_primaryConstructor_scopes() async {
    var library = await buildLibrary('''
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
        #F1 enum E (nameOffset:20) (firstTokenOffset:15) (offset:20)
          element: <testLibrary>::@enum::E
          typeParameters
            #F2 T (nameOffset:27) (firstTokenOffset:22) (offset:27)
              element: #E0 T
              metadata
                Annotation
                  atSign: @ @22
                  name: SimpleIdentifier
                    token: foo @23
                    element: <testLibrary>::@getter::foo
                    staticType: null
                  element: <testLibrary>::@getter::foo
          fields
            #F3 hasInitializer isOriginDeclaration v (nameOffset:54) (firstTokenOffset:54) (offset:54)
              element: <testLibrary>::@enum::E::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibrary>::@enum::E
                      type: E<dynamic>
                    element: ConstructorMember
                      baseElement: <testLibrary>::@enum::E::@constructor::new
                      substitution: {T: dynamic}
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E<dynamic>
            #F4 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:20)
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
            #F5 hasInitializer isOriginDeclaration foo (nameOffset:72) (firstTokenOffset:72) (offset:72)
              element: <testLibrary>::@enum::E::@field::foo
              initializer: expression_2
                IntegerLiteral
                  literal: 1 @78
                  staticType: int
          constructors
            #F6 const isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:20) (offset:20)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
              typeNameOffset: 20
              formalParameters
                #F7 optionalPositional x (nameOffset:40) (firstTokenOffset:31) (offset:40)
                  element: <testLibrary>::@enum::E::@constructor::new::@formalParameter::x
                  metadata
                    Annotation
                      atSign: @ @31
                      name: SimpleIdentifier
                        token: foo @32
                        element: <testLibrary>::@enum::E::@getter::foo
                        staticType: null
                      element: <testLibrary>::@enum::E::@getter::foo
                  initializer: expression_3
                    SimpleIdentifier
                      token: foo @44
                      element: <testLibrary>::@enum::E::@getter::foo
                      staticType: int
          getters
            #F8 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:54)
              element: <testLibrary>::@enum::E::@getter::v
            #F9 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:20)
              element: <testLibrary>::@enum::E::@getter::values
            #F10 isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:72)
              element: <testLibrary>::@enum::E::@getter::foo
      topLevelVariables
        #F11 hasInitializer isOriginDeclaration foo (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::foo
          initializer: expression_4
            IntegerLiteral
              literal: 0 @12
              staticType: int
      getters
        #F12 isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::foo
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
          metadata
            Annotation
              atSign: @ @22
              name: SimpleIdentifier
                token: foo @23
                element: <testLibrary>::@getter::foo
                staticType: null
              element: <testLibrary>::@getter::foo
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F3
          type: E<dynamic>
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F4
          type: List<E<dynamic>>
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
        static const hasImplicitType hasInitializer isOriginDeclaration foo
          reference: <testLibrary>::@enum::E::@field::foo
          firstFragment: #F5
          type: int
          constantInitializer
            fragment: #F5
            expression: expression_2
          getter: <testLibrary>::@enum::E::@getter::foo
      constructors
        const isOriginDeclaration isPrimary new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F6
          formalParameters
            #E1 optionalPositional hasDefaultValue x
              firstFragment: #F7
              type: int
              metadata
                Annotation
                  atSign: @ @31
                  name: SimpleIdentifier
                    token: foo @32
                    element: <testLibrary>::@enum::E::@getter::foo
                    staticType: null
                  element: <testLibrary>::@enum::E::@getter::foo
              constantInitializer
                fragment: #F7
                expression: expression_3
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F8
          returnType: E<dynamic>
          variable: <testLibrary>::@enum::E::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F9
          returnType: List<E<dynamic>>
          variable: <testLibrary>::@enum::E::@field::values
        static isOriginVariable foo
          reference: <testLibrary>::@enum::E::@getter::foo
          firstFragment: #F10
          returnType: int
          variable: <testLibrary>::@enum::E::@field::foo
  topLevelVariables
    const hasImplicitType hasInitializer isOriginDeclaration foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: #F11
      type: int
      constantInitializer
        fragment: #F11
        expression: expression_4
      getter: <testLibrary>::@getter::foo
  getters
    static isOriginVariable foo
      reference: <testLibrary>::@getter::foo
      firstFragment: #F12
      returnType: int
      variable: <testLibrary>::@topLevelVariable::foo
''');
  }

  test_primaryConstructor_typeParameters() async {
    var library = await buildLibrary('''
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
            #F4 hasInitializer isOriginDeclaration v (nameOffset:49) (firstTokenOffset:49) (offset:49)
              element: <testLibrary>::@enum::A::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibrary>::@enum::A
                      type: A<int, int>
                    element: ConstructorMember
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
            #F5 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
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
          constructors
            #F6 const isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:5) (offset:5)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
              typeNameOffset: 5
              formalParameters
                #F7 requiredPositional t (nameOffset:37) (firstTokenOffset:35) (offset:37)
                  element: <testLibrary>::@enum::A::@constructor::new::@formalParameter::t
                #F8 requiredPositional u (nameOffset:42) (firstTokenOffset:40) (offset:42)
                  element: <testLibrary>::@enum::A::@constructor::new::@formalParameter::u
          getters
            #F9 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:49)
              element: <testLibrary>::@enum::A::@getter::v
            #F10 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
  enums
    notSimplyBounded enum A
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
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F4
          type: A<int, int>
          constantInitializer
            fragment: #F4
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F5
          type: List<A<num, num>>
          constantInitializer
            fragment: #F5
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
      constructors
        const isOriginDeclaration isPrimary new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F6
          formalParameters
            #E2 requiredPositional t
              firstFragment: #F7
              type: T
            #E3 requiredPositional u
              firstFragment: #F8
              type: U
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F9
          returnType: A<int, int>
          variable: <testLibrary>::@enum::A::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F10
          returnType: List<A<num, num>>
          variable: <testLibrary>::@enum::A::@field::values
''');
  }

  test_primaryConstructor_unnamed_const() async {
    var library = await buildLibrary('''
enum const A() {v}
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
            #F2 hasInitializer isOriginDeclaration v (nameOffset:16) (firstTokenOffset:16) (offset:16)
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
            #F3 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
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
          constructors
            #F4 const isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:5) (offset:11)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
              typeNameOffset: 11
          getters
            #F5 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@enum::A::@getter::v
            #F6 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::A::@getter::values
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F2
          type: A
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F3
          type: List<A>
          constantInitializer
            fragment: #F3
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
      constructors
        const isOriginDeclaration isPrimary new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F4
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F5
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F6
          returnType: List<A>
          variable: <testLibrary>::@enum::A::@field::values
''');
  }

  test_primaryConstructor_unnamed_notConst() async {
    var library = await buildLibrary('''
enum A() {v}
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
            #F2 hasInitializer isOriginDeclaration v (nameOffset:10) (firstTokenOffset:10) (offset:10)
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
            #F3 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
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
          constructors
            #F4 const isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:5) (offset:5)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
              typeNameOffset: 5
          getters
            #F5 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:10)
              element: <testLibrary>::@enum::A::@getter::v
            #F6 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F2
          type: A
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F3
          type: List<A>
          constantInitializer
            fragment: #F3
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
      constructors
        const isOriginDeclaration isPrimary new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F4
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F5
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F6
          returnType: List<A>
          variable: <testLibrary>::@enum::A::@field::values
''');
  }

  test_primaryConstructorBody_constantInitializers_assertInitializer() async {
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
            #F2 hasInitializer isOriginDeclaration v (nameOffset:13) (firstTokenOffset:13) (offset:13)
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
            #F3 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
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
          constructors
            #F4 const isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:5) (offset:5)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
              typeNameOffset: 5
              thisKeywordOffset: 18
          getters
            #F5 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:13)
              element: <testLibrary>::@enum::E::@getter::v
            #F6 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F3
          type: List<E>
          constantInitializer
            fragment: #F3
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        const isOriginDeclaration isPrimary new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F4
          constantInitializers
            AssertInitializer
              assertKeyword: assert @25
              leftParenthesis: ( @31
              condition: BooleanLiteral
                literal: true @32
                staticType: bool
              rightParenthesis: ) @36
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F5
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F6
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
''');
  }

  test_primaryConstructorBody_constantInitializers_fieldInitializer() async {
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
            #F2 hasInitializer isOriginDeclaration v (nameOffset:13) (firstTokenOffset:13) (offset:13)
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
            #F3 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
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
            #F4 isOriginDeclaration x (nameOffset:28) (firstTokenOffset:28) (offset:28)
              element: <testLibrary>::@enum::E::@field::x
          constructors
            #F5 const isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:5) (offset:5)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
              typeNameOffset: 5
              thisKeywordOffset: 33
          getters
            #F6 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:13)
              element: <testLibrary>::@enum::E::@getter::v
            #F7 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
            #F8 isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:28)
              element: <testLibrary>::@enum::E::@getter::x
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F3
          type: List<E>
          constantInitializer
            fragment: #F3
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
        final isOriginDeclaration x
          reference: <testLibrary>::@enum::E::@field::x
          firstFragment: #F4
          type: int
          getter: <testLibrary>::@enum::E::@getter::x
      constructors
        const isOriginDeclaration isPrimary new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F5
          constantInitializers
            ConstructorFieldInitializer
              fieldName: SimpleIdentifier
                token: x @40
                element: <testLibrary>::@enum::E::@field::x
                staticType: null
              equals: = @42
              expression: IntegerLiteral
                literal: 0 @44
                staticType: int
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F6
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F7
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
        isOriginVariable x
          reference: <testLibrary>::@enum::E::@getter::x
          firstFragment: #F8
          returnType: int
          variable: <testLibrary>::@enum::E::@field::x
''');
  }

  test_primaryConstructorBody_duplicate() async {
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
            #F2 hasInitializer isOriginDeclaration v (nameOffset:13) (firstTokenOffset:13) (offset:13)
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
            #F3 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
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
            #F4 isOriginDeclaration y (nameOffset:28) (firstTokenOffset:28) (offset:28)
              element: <testLibrary>::@enum::E::@field::y
          constructors
            #F5 const isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:5) (offset:5)
              element: <testLibrary>::@enum::E::@constructor::new
              metadata
                Annotation
                  atSign: @ @33
                  name: SimpleIdentifier
                    token: Deprecated @34
                    element: dart:core::@class::Deprecated
                    staticType: null
                  arguments: ArgumentList
                    leftParenthesis: ( @44
                    arguments
                      SimpleStringLiteral
                        literal: '0' @45
                    rightParenthesis: ) @48
                  element: dart:core::@class::Deprecated::@constructor::new
              typeName: E
              typeNameOffset: 5
              thisKeywordOffset: 52
          getters
            #F6 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:13)
              element: <testLibrary>::@enum::E::@getter::v
            #F7 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
            #F8 isOriginVariable y (nameOffset:<null>) (firstTokenOffset:<null>) (offset:28)
              element: <testLibrary>::@enum::E::@getter::y
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F3
          type: List<E>
          constantInitializer
            fragment: #F3
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
        final isOriginDeclaration y
          reference: <testLibrary>::@enum::E::@field::y
          firstFragment: #F4
          type: int
          getter: <testLibrary>::@enum::E::@getter::y
      constructors
        const isOriginDeclaration isPrimary new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F5
          metadata
            Annotation
              atSign: @ @33
              name: SimpleIdentifier
                token: Deprecated @34
                element: dart:core::@class::Deprecated
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @44
                arguments
                  SimpleStringLiteral
                    literal: '0' @45
                rightParenthesis: ) @48
              element: dart:core::@class::Deprecated::@constructor::new
          constantInitializers
            ConstructorFieldInitializer
              fieldName: SimpleIdentifier
                token: y @59
                element: <testLibrary>::@enum::E::@field::y
                staticType: null
              equals: = @61
              expression: IntegerLiteral
                literal: 0 @63
                staticType: int
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F6
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F7
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
        isOriginVariable y
          reference: <testLibrary>::@enum::E::@getter::y
          firstFragment: #F8
          returnType: int
          variable: <testLibrary>::@enum::E::@field::y
''');
  }

  test_primaryConstructorBody_metadata() async {
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
            #F2 hasInitializer isOriginDeclaration v (nameOffset:18) (firstTokenOffset:18) (offset:18)
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
            #F3 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
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
          constructors
            #F4 const isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:5) (offset:5)
              element: <testLibrary>::@enum::E::@constructor::new
              metadata
                Annotation
                  atSign: @ @26
                  name: SimpleIdentifier
                    token: deprecated @27
                    element: dart:core::@getter::deprecated
                    staticType: null
                  element: dart:core::@getter::deprecated
              typeName: E
              typeNameOffset: 5
              thisKeywordOffset: 40
              formalParameters
                #F5 requiredPositional x (nameOffset:11) (firstTokenOffset:7) (offset:11)
                  element: <testLibrary>::@enum::E::@constructor::new::@formalParameter::x
          getters
            #F6 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:18)
              element: <testLibrary>::@enum::E::@getter::v
            #F7 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F3
          type: List<E>
          constantInitializer
            fragment: #F3
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        const isOriginDeclaration isPrimary new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F4
          metadata
            Annotation
              atSign: @ @26
              name: SimpleIdentifier
                token: deprecated @27
                element: dart:core::@getter::deprecated
                staticType: null
              element: dart:core::@getter::deprecated
          formalParameters
            #E0 requiredPositional x
              firstFragment: #F5
              type: int
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F6
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F7
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
''');
  }

  test_primaryConstructorBody_named() async {
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
            #F2 hasInitializer isOriginDeclaration v (nameOffset:19) (firstTokenOffset:19) (offset:19)
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
            #F3 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
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
          constructors
            #F4 const isOriginDeclaration isPrimary named (nameOffset:7) (firstTokenOffset:5) (offset:7)
              element: <testLibrary>::@enum::E::@constructor::named
              typeName: E
              typeNameOffset: 5
              periodOffset: 6
              thisKeywordOffset: 32
          getters
            #F5 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:19)
              element: <testLibrary>::@enum::E::@getter::v
            #F6 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F3
          type: List<E>
          constantInitializer
            fragment: #F3
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        const isOriginDeclaration isPrimary named
          reference: <testLibrary>::@enum::E::@constructor::named
          firstFragment: #F4
          constantInitializers
            AssertInitializer
              assertKeyword: assert @39
              leftParenthesis: ( @45
              condition: BooleanLiteral
                literal: true @46
                staticType: bool
              rightParenthesis: ) @50
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F5
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F6
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
''');
  }

  test_primaryConstructorBody_noDeclaration() async {
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
            #F2 hasInitializer isOriginDeclaration v (nameOffset:11) (firstTokenOffset:11) (offset:11)
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
            #F3 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
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
          constructors
            #F4 const isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F5 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::E::@getter::v
            #F6 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F3
          type: List<E>
          constantInitializer
            fragment: #F3
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        const isOriginImplicitDefault new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F4
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F5
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F6
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
''');
  }

  test_primaryConstructorBody_notConst() async {
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
            #F2 hasInitializer isOriginDeclaration v (nameOffset:13) (firstTokenOffset:13) (offset:13)
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
            #F3 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
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
          constructors
            #F4 const isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:5) (offset:5)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
              typeNameOffset: 5
              thisKeywordOffset: 18
          getters
            #F5 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:13)
              element: <testLibrary>::@enum::E::@getter::v
            #F6 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F3
          type: List<E>
          constantInitializer
            fragment: #F3
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        const isOriginDeclaration isPrimary new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F4
          constantInitializers
            AssertInitializer
              assertKeyword: assert @25
              leftParenthesis: ( @31
              condition: BooleanLiteral
                literal: true @32
                staticType: bool
              rightParenthesis: ) @36
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F5
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F6
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
''');
  }

  test_primaryConstructorBody_primaryInitializerScope() async {
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
            #F2 hasInitializer isOriginDeclaration v (nameOffset:18) (firstTokenOffset:18) (offset:18)
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
            #F3 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
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
          constructors
            #F4 const isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:5) (offset:5)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
              typeNameOffset: 5
              thisKeywordOffset: 26
              formalParameters
                #F5 requiredPositional x (nameOffset:11) (firstTokenOffset:7) (offset:11)
                  element: <testLibrary>::@enum::E::@constructor::new::@formalParameter::x
          getters
            #F6 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:18)
              element: <testLibrary>::@enum::E::@getter::v
            #F7 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F3
          type: List<E>
          constantInitializer
            fragment: #F3
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        const isOriginDeclaration isPrimary new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional x
              firstFragment: #F5
              type: int
          constantInitializers
            AssertInitializer
              assertKeyword: assert @33
              leftParenthesis: ( @39
              condition: BinaryExpression
                leftOperand: SimpleIdentifier
                  token: x @40
                  element: <testLibrary>::@enum::E::@constructor::new::@formalParameter::x
                  staticType: int
                operator: > @42
                rightOperand: IntegerLiteral
                  literal: 0 @44
                  staticType: int
                element: dart:core::@class::num::@method::>
                staticInvokeType: bool Function(num)
                staticType: bool
              rightParenthesis: ) @45
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F6
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F7
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
''');
  }
}

abstract class EnumElementTest_augmentation extends ElementsBaseTest {
  test_add_augment() async {
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
            #F3 hasInitializer isOriginDeclaration v (nameOffset:11) (firstTokenOffset:11) (offset:11)
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
            #F4 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
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
          constructors
            #F5 const isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
          getters
            #F6 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::A::@getter::v
            #F7 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
          methods
            #F8 isOriginDeclaration foo (nameOffset:21) (firstTokenOffset:16) (offset:21)
              element: <testLibrary>::@enum::A::@method::foo
        #F2 enum A (nameOffset:46) (firstTokenOffset:33) (offset:46)
          element: <testLibrary>::@enum::A
          previousFragment: #F1
          methods
            #F9 isOriginDeclaration bar (nameOffset:58) (firstTokenOffset:53) (offset:58)
              element: <testLibrary>::@enum::A::@method::bar
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F3
          type: A
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F4
          type: List<A>
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
      constructors
        const isOriginImplicitDefault new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F5
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F6
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F7
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

  test_augmentationTarget() async {
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
enum A {
  v
}
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
        #F3 enum A (nameOffset:37) (firstTokenOffset:32) (offset:37)
          element: <testLibrary>::@enum::A
          nextFragment: #F4
          fields
            #F5 hasInitializer isOriginDeclaration v (nameOffset:43) (firstTokenOffset:43) (offset:43)
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
            #F6 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:37)
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
          constructors
            #F7 const isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:37)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
          getters
            #F8 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:43)
              element: <testLibrary>::@enum::A::@getter::v
            #F9 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:37)
              element: <testLibrary>::@enum::A::@getter::values
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
        #F4 enum A (nameOffset:68) (firstTokenOffset:55) (offset:68)
          element: <testLibrary>::@enum::A
          previousFragment: #F3
          nextFragment: #F12
    #F10 package:test/a11.dart
      element: <testLibrary>
      enclosingFragment: #F1
      previousFragment: #F1
      nextFragment: #F11
      enums
        #F12 enum A (nameOffset:32) (firstTokenOffset:19) (offset:32)
          element: <testLibrary>::@enum::A
          previousFragment: #F4
          nextFragment: #F13
    #F11 package:test/a12.dart
      element: <testLibrary>
      enclosingFragment: #F1
      previousFragment: #F10
      nextFragment: #F2
      enums
        #F13 enum A (nameOffset:32) (firstTokenOffset:19) (offset:32)
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
        #F14 enum A (nameOffset:68) (firstTokenOffset:55) (offset:68)
          element: <testLibrary>::@enum::A
          previousFragment: #F13
          nextFragment: #F17
    #F15 package:test/a21.dart
      element: <testLibrary>
      enclosingFragment: #F2
      previousFragment: #F2
      nextFragment: #F16
      enums
        #F17 enum A (nameOffset:32) (firstTokenOffset:19) (offset:32)
          element: <testLibrary>::@enum::A
          previousFragment: #F14
          nextFragment: #F18
    #F16 package:test/a22.dart
      element: <testLibrary>
      enclosingFragment: #F2
      previousFragment: #F15
      enums
        #F18 enum A (nameOffset:32) (firstTokenOffset:19) (offset:32)
          element: <testLibrary>::@enum::A
          previousFragment: #F17
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F3
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F5
          type: A
          constantInitializer
            fragment: #F5
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F6
          type: List<A>
          constantInitializer
            fragment: #F6
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
      constructors
        const isOriginImplicitDefault new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F7
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F8
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F9
          returnType: List<A>
          variable: <testLibrary>::@enum::A::@field::values
  exportedReferences
    declared <testLibrary>::@enum::A
  exportNamespace
    A: <testLibrary>::@enum::A
''');
  }

  test_augmentationTarget_augmentationThenDeclaration() async {
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
        #F1 enum A (nameOffset:13) (firstTokenOffset:0) (offset:13)
          element: <testLibrary>::@enum::A::@def::0
          fields
            #F2 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:13)
              element: <testLibrary>::@enum::A::@def::0::@field::values
              initializer: expression_0
                ListLiteral
                  leftBracket: [ @0
                  rightBracket: ] @0
                  staticType: List<A>
          constructors
            #F3 const isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:13)
              element: <testLibrary>::@enum::A::@def::0::@constructor::new
              typeName: A
          getters
            #F4 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:13)
              element: <testLibrary>::@enum::A::@def::0::@getter::values
          methods
            #F5 isOriginDeclaration foo1 (nameOffset:25) (firstTokenOffset:20) (offset:25)
              element: <testLibrary>::@enum::A::@def::0::@method::foo1
        #F6 enum A (nameOffset:43) (firstTokenOffset:38) (offset:43)
          element: <testLibrary>::@enum::A::@def::1
          nextFragment: #F7
          fields
            #F8 hasInitializer isOriginDeclaration v (nameOffset:49) (firstTokenOffset:49) (offset:49)
              element: <testLibrary>::@enum::A::@def::1::@field::v
              initializer: expression_1
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibrary>::@enum::A::@def::0
                      type: A
                    element: <testLibrary>::@enum::A::@def::0::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
            #F9 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:43)
              element: <testLibrary>::@enum::A::@def::1::@field::values
              initializer: expression_2
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::A::@def::1::@getter::v
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
          constructors
            #F10 const isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:43)
              element: <testLibrary>::@enum::A::@def::1::@constructor::new
              typeName: A
          getters
            #F11 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:49)
              element: <testLibrary>::@enum::A::@def::1::@getter::v
            #F12 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:43)
              element: <testLibrary>::@enum::A::@def::1::@getter::values
          methods
            #F13 isOriginDeclaration foo2 (nameOffset:59) (firstTokenOffset:54) (offset:59)
              element: <testLibrary>::@enum::A::@def::1::@method::foo2
        #F7 enum A (nameOffset:85) (firstTokenOffset:72) (offset:85)
          element: <testLibrary>::@enum::A::@def::1
          previousFragment: #F6
          methods
            #F14 isOriginDeclaration foo3 (nameOffset:97) (firstTokenOffset:92) (offset:97)
              element: <testLibrary>::@enum::A::@def::1::@method::foo3
  enums
    enum A
      reference: <testLibrary>::@enum::A::@def::0
      firstFragment: #F1
      supertype: Enum
      fields
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::A::@def::0::@field::values
          firstFragment: #F2
          type: List<A>
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::A::@def::0::@getter::values
      constructors
        const isOriginImplicitDefault new
          reference: <testLibrary>::@enum::A::@def::0::@constructor::new
          firstFragment: #F3
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable values
          reference: <testLibrary>::@enum::A::@def::0::@getter::values
          firstFragment: #F4
          returnType: List<A>
          variable: <testLibrary>::@enum::A::@def::0::@field::values
      methods
        isOriginDeclaration foo1
          reference: <testLibrary>::@enum::A::@def::0::@method::foo1
          firstFragment: #F5
          returnType: void
    enum A
      reference: <testLibrary>::@enum::A::@def::1
      firstFragment: #F6
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::A::@def::1::@field::v
          firstFragment: #F8
          type: A
          constantInitializer
            fragment: #F8
            expression: expression_1
          getter: <testLibrary>::@enum::A::@def::1::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::A::@def::1::@field::values
          firstFragment: #F9
          type: List<A>
          constantInitializer
            fragment: #F9
            expression: expression_2
          getter: <testLibrary>::@enum::A::@def::1::@getter::values
      constructors
        const isOriginImplicitDefault new
          reference: <testLibrary>::@enum::A::@def::1::@constructor::new
          firstFragment: #F10
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::A::@def::1::@getter::v
          firstFragment: #F11
          returnType: A
          variable: <testLibrary>::@enum::A::@def::1::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::A::@def::1::@getter::values
          firstFragment: #F12
          returnType: List<A>
          variable: <testLibrary>::@enum::A::@def::1::@field::values
      methods
        isOriginDeclaration foo2
          reference: <testLibrary>::@enum::A::@def::1::@method::foo2
          firstFragment: #F13
          returnType: void
        isOriginDeclaration foo3
          reference: <testLibrary>::@enum::A::@def::1::@method::foo3
          firstFragment: #F14
          returnType: void
''');
  }

  test_augmentationTarget_no2() async {
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
        #F1 enum A (nameOffset:13) (firstTokenOffset:0) (offset:13)
          element: <testLibrary>::@enum::A
          nextFragment: #F2
          fields
            #F3 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:13)
              element: <testLibrary>::@enum::A::@field::values
              initializer: expression_0
                ListLiteral
                  leftBracket: [ @0
                  rightBracket: ] @0
                  staticType: List<A>
          constructors
            #F4 const isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:13)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
          getters
            #F5 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:13)
              element: <testLibrary>::@enum::A::@getter::values
          methods
            #F6 isOriginDeclaration foo1 (nameOffset:25) (firstTokenOffset:20) (offset:25)
              element: <testLibrary>::@enum::A::@method::foo1
        #F2 enum A (nameOffset:51) (firstTokenOffset:38) (offset:51)
          element: <testLibrary>::@enum::A
          previousFragment: #F1
          methods
            #F7 isOriginDeclaration foo2 (nameOffset:63) (firstTokenOffset:58) (offset:63)
              element: <testLibrary>::@enum::A::@method::foo2
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      supertype: Enum
      fields
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F3
          type: List<A>
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::values
      constructors
        const isOriginImplicitDefault new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F4
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F5
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

  test_augmented_constants_add() async {
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
            #F3 hasInitializer isOriginDeclaration v1 (nameOffset:11) (firstTokenOffset:11) (offset:11)
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
            #F4 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
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
          constructors
            #F5 const isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
          getters
            #F6 isOriginVariable v1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::A::@getter::v1
            #F7 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
        #F2 enum A (nameOffset:30) (firstTokenOffset:17) (offset:30)
          element: <testLibrary>::@enum::A
          previousFragment: #F1
          fields
            #F8 hasInitializer isOriginDeclaration v2 (nameOffset:36) (firstTokenOffset:36) (offset:36)
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
          getters
            #F9 isOriginVariable v2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:36)
              element: <testLibrary>::@enum::A::@getter::v2
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v1
          reference: <testLibrary>::@enum::A::@field::v1
          firstFragment: #F3
          type: A
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v1
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F4
          type: List<A>
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v2
          reference: <testLibrary>::@enum::A::@field::v2
          firstFragment: #F8
          type: A
          constantInitializer
            fragment: #F8
            expression: expression_2
          getter: <testLibrary>::@enum::A::@getter::v2
      constructors
        const isOriginImplicitDefault new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F5
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v1
          reference: <testLibrary>::@enum::A::@getter::v1
          firstFragment: #F6
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v1
        static isOriginVariable values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F7
          returnType: List<A>
          variable: <testLibrary>::@enum::A::@field::values
        static isOriginVariable v2
          reference: <testLibrary>::@enum::A::@getter::v2
          firstFragment: #F9
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v2
''');
  }

  test_augmented_constants_add2() async {
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
            #F3 hasInitializer isOriginDeclaration v1 (nameOffset:11) (firstTokenOffset:11) (offset:11)
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
            #F4 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
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
          constructors
            #F5 const isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
          getters
            #F6 isOriginVariable v1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::A::@getter::v1
            #F7 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
        #F2 enum A (nameOffset:30) (firstTokenOffset:17) (offset:30)
          element: <testLibrary>::@enum::A
          previousFragment: #F1
          nextFragment: #F8
          fields
            #F9 hasInitializer isOriginDeclaration v2 (nameOffset:36) (firstTokenOffset:36) (offset:36)
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
          getters
            #F10 isOriginVariable v2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:36)
              element: <testLibrary>::@enum::A::@getter::v2
        #F8 enum A (nameOffset:55) (firstTokenOffset:42) (offset:55)
          element: <testLibrary>::@enum::A
          previousFragment: #F2
          fields
            #F11 hasInitializer isOriginDeclaration v3 (nameOffset:61) (firstTokenOffset:61) (offset:61)
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
          getters
            #F12 isOriginVariable v3 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:61)
              element: <testLibrary>::@enum::A::@getter::v3
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v1
          reference: <testLibrary>::@enum::A::@field::v1
          firstFragment: #F3
          type: A
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v1
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F4
          type: List<A>
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v2
          reference: <testLibrary>::@enum::A::@field::v2
          firstFragment: #F9
          type: A
          constantInitializer
            fragment: #F9
            expression: expression_2
          getter: <testLibrary>::@enum::A::@getter::v2
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v3
          reference: <testLibrary>::@enum::A::@field::v3
          firstFragment: #F11
          type: A
          constantInitializer
            fragment: #F11
            expression: expression_3
          getter: <testLibrary>::@enum::A::@getter::v3
      constructors
        const isOriginImplicitDefault new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F5
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v1
          reference: <testLibrary>::@enum::A::@getter::v1
          firstFragment: #F6
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v1
        static isOriginVariable values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F7
          returnType: List<A>
          variable: <testLibrary>::@enum::A::@field::values
        static isOriginVariable v2
          reference: <testLibrary>::@enum::A::@getter::v2
          firstFragment: #F10
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v2
        static isOriginVariable v3
          reference: <testLibrary>::@enum::A::@getter::v3
          firstFragment: #F12
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v3
''');
  }

  test_augmented_constants_add_augment() async {
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
            #F3 hasInitializer isOriginDeclaration v1 (nameOffset:11) (firstTokenOffset:11) (offset:11)
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
            #F4 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
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
          constructors
            #F5 const isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
          getters
            #F6 isOriginVariable v1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::A::@getter::v1
            #F7 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
        #F2 enum A (nameOffset:30) (firstTokenOffset:17) (offset:30)
          element: <testLibrary>::@enum::A
          previousFragment: #F1
          fields
            #F8 hasInitializer isOriginDeclaration v2 (nameOffset:36) (firstTokenOffset:36) (offset:36)
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
              nextFragment: #F9
            #F9 augment hasInitializer isOriginDeclaration v2 (nameOffset:50) (firstTokenOffset:42) (offset:50)
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
              previousFragment: #F8
          getters
            #F10 isOriginVariable v2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:36)
              element: <testLibrary>::@enum::A::@getter::v2
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v1
          reference: <testLibrary>::@enum::A::@field::v1
          firstFragment: #F3
          type: A
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v1
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F4
          type: List<A>
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v2
          reference: <testLibrary>::@enum::A::@field::v2
          firstFragment: #F8
          type: A
          constantInitializer
            fragment: #F9
            expression: expression_3
          getter: <testLibrary>::@enum::A::@getter::v2
      constructors
        const isOriginImplicitDefault new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F5
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v1
          reference: <testLibrary>::@enum::A::@getter::v1
          firstFragment: #F6
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v1
        static isOriginVariable values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F7
          returnType: List<A>
          variable: <testLibrary>::@enum::A::@field::values
        static isOriginVariable v2
          reference: <testLibrary>::@enum::A::@getter::v2
          firstFragment: #F10
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v2
''');
  }

  test_augmented_constants_augment() async {
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
            #F3 hasInitializer isOriginDeclaration v1 (nameOffset:11) (firstTokenOffset:11) (offset:11)
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
            #F4 hasInitializer isOriginDeclaration v2 (nameOffset:15) (firstTokenOffset:15) (offset:15)
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
              nextFragment: #F5
            #F6 hasInitializer isOriginDeclaration v3 (nameOffset:19) (firstTokenOffset:19) (offset:19)
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
            #F7 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
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
          constructors
            #F8 const isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
          getters
            #F9 isOriginVariable v1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::A::@getter::v1
            #F10 isOriginVariable v2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@enum::A::@getter::v2
            #F11 isOriginVariable v3 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:19)
              element: <testLibrary>::@enum::A::@getter::v3
            #F12 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
        #F2 enum A (nameOffset:38) (firstTokenOffset:25) (offset:38)
          element: <testLibrary>::@enum::A
          previousFragment: #F1
          fields
            #F5 augment hasInitializer isOriginDeclaration v2 (nameOffset:52) (firstTokenOffset:44) (offset:52)
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
              previousFragment: #F4
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v1
          reference: <testLibrary>::@enum::A::@field::v1
          firstFragment: #F3
          type: A
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v1
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v2
          reference: <testLibrary>::@enum::A::@field::v2
          firstFragment: #F4
          type: A
          constantInitializer
            fragment: #F5
            expression: expression_4
          getter: <testLibrary>::@enum::A::@getter::v2
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v3
          reference: <testLibrary>::@enum::A::@field::v3
          firstFragment: #F6
          type: A
          constantInitializer
            fragment: #F6
            expression: expression_2
          getter: <testLibrary>::@enum::A::@getter::v3
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F7
          type: List<A>
          constantInitializer
            fragment: #F7
            expression: expression_3
          getter: <testLibrary>::@enum::A::@getter::values
      constructors
        const isOriginImplicitDefault new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F8
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v1
          reference: <testLibrary>::@enum::A::@getter::v1
          firstFragment: #F9
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v1
        static isOriginVariable v2
          reference: <testLibrary>::@enum::A::@getter::v2
          firstFragment: #F10
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v2
        static isOriginVariable v3
          reference: <testLibrary>::@enum::A::@getter::v3
          firstFragment: #F11
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v3
        static isOriginVariable values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F12
          returnType: List<A>
          variable: <testLibrary>::@enum::A::@field::values
''');
  }

  test_augmented_constants_augment_withArguments() async {
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
            #F3 hasInitializer isOriginDeclaration v1 (nameOffset:11) (firstTokenOffset:11) (offset:11)
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
              nextFragment: #F4
            #F5 hasInitializer isOriginDeclaration v2 (nameOffset:18) (firstTokenOffset:18) (offset:18)
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
            #F6 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
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
          constructors
            #F7 const isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:27) (offset:33)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
              typeNameOffset: 33
              formalParameters
                #F8 requiredPositional value (nameOffset:39) (firstTokenOffset:35) (offset:39)
                  element: <testLibrary>::@enum::A::@constructor::new::@formalParameter::value
          getters
            #F9 isOriginVariable v1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::A::@getter::v1
            #F10 isOriginVariable v2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:18)
              element: <testLibrary>::@enum::A::@getter::v2
            #F11 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
        #F2 enum A (nameOffset:63) (firstTokenOffset:50) (offset:63)
          element: <testLibrary>::@enum::A
          previousFragment: #F1
          fields
            #F4 augment hasInitializer isOriginDeclaration v1 (nameOffset:77) (firstTokenOffset:69) (offset:77)
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
              previousFragment: #F3
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v1
          reference: <testLibrary>::@enum::A::@field::v1
          firstFragment: #F3
          type: A
          constantInitializer
            fragment: #F4
            expression: expression_3
          getter: <testLibrary>::@enum::A::@getter::v1
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v2
          reference: <testLibrary>::@enum::A::@field::v2
          firstFragment: #F5
          type: A
          constantInitializer
            fragment: #F5
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::v2
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F6
          type: List<A>
          constantInitializer
            fragment: #F6
            expression: expression_2
          getter: <testLibrary>::@enum::A::@getter::values
      constructors
        const isOriginDeclaration new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F7
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F8
              type: int
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v1
          reference: <testLibrary>::@enum::A::@getter::v1
          firstFragment: #F9
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v1
        static isOriginVariable v2
          reference: <testLibrary>::@enum::A::@getter::v2
          firstFragment: #F10
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v2
        static isOriginVariable values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F11
          returnType: List<A>
          variable: <testLibrary>::@enum::A::@field::values
''');
  }

  test_augmented_constants_typeParameterCountMismatch() async {
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
          fields
            #F3 hasInitializer isOriginDeclaration v (nameOffset:11) (firstTokenOffset:11) (offset:11)
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
              nextFragment: #F4
            #F5 hasInitializer isOriginDeclaration v2 (nameOffset:14) (firstTokenOffset:14) (offset:14)
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
            #F6 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
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
          getters
            #F7 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::A::@getter::v
            #F8 isOriginVariable v2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:14)
              element: <testLibrary>::@enum::A::@getter::v2
            #F9 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
        #F2 enum A (nameOffset:33) (firstTokenOffset:20) (offset:33)
          element: <testLibrary>::@enum::A
          previousFragment: #F1
          fields
            #F4 augment hasInitializer isOriginDeclaration v (nameOffset:50) (firstTokenOffset:42) (offset:50)
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
              previousFragment: #F3
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F3
          type: A
          constantInitializer
            fragment: #F4
            expression: expression_3
          getter: <testLibrary>::@enum::A::@getter::v
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v2
          reference: <testLibrary>::@enum::A::@field::v2
          firstFragment: #F5
          type: A
          constantInitializer
            fragment: #F5
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::v2
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F6
          type: List<A>
          constantInitializer
            fragment: #F6
            expression: expression_2
          getter: <testLibrary>::@enum::A::@getter::values
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F7
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v
        static isOriginVariable v2
          reference: <testLibrary>::@enum::A::@getter::v2
          firstFragment: #F8
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v2
        static isOriginVariable values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F9
          returnType: List<A>
          variable: <testLibrary>::@enum::A::@field::values
''');
  }

  test_augmented_constructors_add_named() async {
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
            #F3 hasInitializer isOriginDeclaration v (nameOffset:11) (firstTokenOffset:11) (offset:11)
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
            #F4 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
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
          getters
            #F5 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::A::@getter::v
            #F6 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
        #F2 enum A (nameOffset:38) (firstTokenOffset:25) (offset:38)
          element: <testLibrary>::@enum::A
          previousFragment: #F1
          constructors
            #F7 const isOriginDeclaration named (nameOffset:53) (firstTokenOffset:45) (offset:53)
              element: <testLibrary>::@enum::A::@constructor::named
              typeName: A
              typeNameOffset: 51
              periodOffset: 52
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F3
          type: A
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F4
          type: List<A>
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
      constructors
        const isOriginDeclaration named
          reference: <testLibrary>::@enum::A::@constructor::named
          firstFragment: #F7
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F5
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F6
          returnType: List<A>
          variable: <testLibrary>::@enum::A::@field::values
''');
  }

  test_augmented_constructors_add_named_generic() async {
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
            #F5 hasInitializer isOriginDeclaration v (nameOffset:14) (firstTokenOffset:14) (offset:14)
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
                      element: ConstructorMember
                        baseElement: <testLibrary>::@enum::A::@constructor::named
                        substitution: {T: int}
                      staticType: null
                    element: ConstructorMember
                      baseElement: <testLibrary>::@enum::A::@constructor::named
                      substitution: {T: int}
                  argumentList: ArgumentList
                    leftParenthesis: ( @26
                    rightParenthesis: ) @27
                  staticType: A<int>
            #F6 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
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
          getters
            #F7 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:14)
              element: <testLibrary>::@enum::A::@getter::v
            #F8 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
        #F2 enum A (nameOffset:45) (firstTokenOffset:32) (offset:45)
          element: <testLibrary>::@enum::A
          previousFragment: #F1
          typeParameters
            #F4 T (nameOffset:47) (firstTokenOffset:47) (offset:47)
              element: #E0 T
              previousFragment: #F3
          constructors
            #F9 const isOriginDeclaration named (nameOffset:63) (firstTokenOffset:55) (offset:63)
              element: <testLibrary>::@enum::A::@constructor::named
              typeName: A
              typeNameOffset: 61
              periodOffset: 62
              formalParameters
                #F10 requiredPositional a (nameOffset:71) (firstTokenOffset:69) (offset:71)
                  element: <testLibrary>::@enum::A::@constructor::named::@formalParameter::a
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F3
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F5
          type: A<int>
          constantInitializer
            fragment: #F5
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F6
          type: List<A<dynamic>>
          constantInitializer
            fragment: #F6
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
      constructors
        const isOriginDeclaration named
          reference: <testLibrary>::@enum::A::@constructor::named
          firstFragment: #F9
          formalParameters
            #E1 requiredPositional a
              firstFragment: #F10
              type: T
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F7
          returnType: A<int>
          variable: <testLibrary>::@enum::A::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F8
          returnType: List<A<dynamic>>
          variable: <testLibrary>::@enum::A::@field::values
''');
  }

  test_augmented_constructors_add_named_hasUnnamed() async {
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
            #F3 hasInitializer isOriginDeclaration v (nameOffset:11) (firstTokenOffset:11) (offset:11)
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
            #F4 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
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
          constructors
            #F5 const isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:16) (offset:22)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
              typeNameOffset: 22
          getters
            #F6 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::A::@getter::v
            #F7 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
        #F2 enum A (nameOffset:43) (firstTokenOffset:30) (offset:43)
          element: <testLibrary>::@enum::A
          previousFragment: #F1
          constructors
            #F8 const isOriginDeclaration named (nameOffset:58) (firstTokenOffset:50) (offset:58)
              element: <testLibrary>::@enum::A::@constructor::named
              typeName: A
              typeNameOffset: 56
              periodOffset: 57
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F3
          type: A
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F4
          type: List<A>
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
      constructors
        const isOriginDeclaration new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F5
          superConstructor: dart:core::@class::Enum::@constructor::new
        const isOriginDeclaration named
          reference: <testLibrary>::@enum::A::@constructor::named
          firstFragment: #F8
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F6
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F7
          returnType: List<A>
          variable: <testLibrary>::@enum::A::@field::values
''');
  }

  test_augmented_constructors_add_unnamed() async {
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
            #F3 hasInitializer isOriginDeclaration v (nameOffset:11) (firstTokenOffset:11) (offset:11)
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
            #F4 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
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
          getters
            #F5 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::A::@getter::v
            #F6 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
        #F2 enum A (nameOffset:30) (firstTokenOffset:17) (offset:30)
          element: <testLibrary>::@enum::A
          previousFragment: #F1
          constructors
            #F7 const isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:37) (offset:43)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
              typeNameOffset: 43
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F3
          type: A
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F4
          type: List<A>
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
      constructors
        const isOriginDeclaration new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F7
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F5
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F6
          returnType: List<A>
          variable: <testLibrary>::@enum::A::@field::values
''');
  }

  test_augmented_constructors_add_unnamed_hasNamed() async {
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
            #F3 hasInitializer isOriginDeclaration v (nameOffset:11) (firstTokenOffset:11) (offset:11)
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
            #F4 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
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
          constructors
            #F5 const isOriginDeclaration named (nameOffset:24) (firstTokenOffset:16) (offset:24)
              element: <testLibrary>::@enum::A::@constructor::named
              typeName: A
              typeNameOffset: 22
              periodOffset: 23
          getters
            #F6 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::A::@getter::v
            #F7 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
        #F2 enum A (nameOffset:49) (firstTokenOffset:36) (offset:49)
          element: <testLibrary>::@enum::A
          previousFragment: #F1
          constructors
            #F8 const isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:56) (offset:62)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
              typeNameOffset: 62
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F3
          type: A
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F4
          type: List<A>
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
      constructors
        const isOriginDeclaration named
          reference: <testLibrary>::@enum::A::@constructor::named
          firstFragment: #F5
          superConstructor: dart:core::@class::Enum::@constructor::new
        const isOriginDeclaration new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F8
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F6
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F7
          returnType: List<A>
          variable: <testLibrary>::@enum::A::@field::values
''');
  }

  test_augmented_constructors_add_useFieldFormal() async {
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
            #F3 hasInitializer isOriginDeclaration v (nameOffset:11) (firstTokenOffset:11) (offset:11)
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
            #F4 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
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
            #F5 isOriginDeclaration f (nameOffset:29) (firstTokenOffset:29) (offset:29)
              element: <testLibrary>::@enum::A::@field::f
          getters
            #F6 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::A::@getter::v
            #F7 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
            #F8 isOriginVariable f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:29)
              element: <testLibrary>::@enum::A::@getter::f
        #F2 enum A (nameOffset:48) (firstTokenOffset:35) (offset:48)
          element: <testLibrary>::@enum::A
          previousFragment: #F1
          constructors
            #F9 const isOriginDeclaration named (nameOffset:63) (firstTokenOffset:55) (offset:63)
              element: <testLibrary>::@enum::A::@constructor::named
              typeName: A
              typeNameOffset: 61
              periodOffset: 62
              formalParameters
                #F10 requiredPositional final this.f (nameOffset:74) (firstTokenOffset:69) (offset:74)
                  element: <testLibrary>::@enum::A::@constructor::named::@formalParameter::f
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F3
          type: A
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F4
          type: List<A>
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
        final isOriginDeclaration f
          reference: <testLibrary>::@enum::A::@field::f
          firstFragment: #F5
          type: int
          getter: <testLibrary>::@enum::A::@getter::f
      constructors
        const isOriginDeclaration named
          reference: <testLibrary>::@enum::A::@constructor::named
          firstFragment: #F9
          formalParameters
            #E0 requiredPositional final hasImplicitType this.f
              firstFragment: #F10
              type: int
              field: <testLibrary>::@enum::A::@field::f
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F6
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F7
          returnType: List<A>
          variable: <testLibrary>::@enum::A::@field::values
        isOriginVariable f
          reference: <testLibrary>::@enum::A::@getter::f
          firstFragment: #F8
          returnType: int
          variable: <testLibrary>::@enum::A::@field::f
''');
  }

  test_augmented_constructors_add_useFieldInitializer() async {
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
            #F3 hasInitializer isOriginDeclaration v (nameOffset:11) (firstTokenOffset:11) (offset:11)
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
            #F4 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
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
            #F5 isOriginDeclaration f (nameOffset:26) (firstTokenOffset:26) (offset:26)
              element: <testLibrary>::@enum::A::@field::f
          getters
            #F6 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::A::@getter::v
            #F7 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
            #F8 isOriginVariable f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:26)
              element: <testLibrary>::@enum::A::@getter::f
        #F2 enum A (nameOffset:45) (firstTokenOffset:32) (offset:45)
          element: <testLibrary>::@enum::A
          previousFragment: #F1
          constructors
            #F9 const isOriginDeclaration named (nameOffset:60) (firstTokenOffset:52) (offset:60)
              element: <testLibrary>::@enum::A::@constructor::named
              typeName: A
              typeNameOffset: 58
              periodOffset: 59
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F3
          type: A
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F4
          type: List<A>
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
        final isOriginDeclaration f
          reference: <testLibrary>::@enum::A::@field::f
          firstFragment: #F5
          type: int
          getter: <testLibrary>::@enum::A::@getter::f
      constructors
        const isOriginDeclaration named
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
        static isOriginVariable v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F6
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F7
          returnType: List<A>
          variable: <testLibrary>::@enum::A::@field::values
        isOriginVariable f
          reference: <testLibrary>::@enum::A::@getter::f
          firstFragment: #F8
          returnType: int
          variable: <testLibrary>::@enum::A::@field::f
''');
  }

  test_augmented_field_augment_field() async {
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
            #F3 hasInitializer isOriginDeclaration v (nameOffset:11) (firstTokenOffset:11) (offset:11)
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
            #F4 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
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
            #F5 hasInitializer isOriginDeclaration foo (nameOffset:26) (firstTokenOffset:26) (offset:26)
              element: <testLibrary>::@enum::A::@field::foo
              initializer: expression_2
                IntegerLiteral
                  literal: 0 @32
                  staticType: null
              nextFragment: #F6
          constructors
            #F7 const isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
          getters
            #F8 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::A::@getter::v
            #F9 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
            #F10 isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:26)
              element: <testLibrary>::@enum::A::@getter::foo
        #F2 enum A (nameOffset:51) (firstTokenOffset:38) (offset:51)
          element: <testLibrary>::@enum::A
          previousFragment: #F1
          fields
            #F6 augment hasInitializer isOriginDeclaration foo (nameOffset:76) (firstTokenOffset:76) (offset:76)
              element: <testLibrary>::@enum::A::@field::foo
              initializer: expression_3
                IntegerLiteral
                  literal: 1 @82
                  staticType: int
              previousFragment: #F5
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F3
          type: A
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F4
          type: List<A>
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
        final hasInitializer isOriginDeclaration foo
          reference: <testLibrary>::@enum::A::@field::foo
          firstFragment: #F5
          type: int
          constantInitializer
            fragment: #F6
            expression: expression_3
          getter: <testLibrary>::@enum::A::@getter::foo
      constructors
        const isOriginImplicitDefault new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F7
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F8
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F9
          returnType: List<A>
          variable: <testLibrary>::@enum::A::@field::values
        isOriginVariable foo
          reference: <testLibrary>::@enum::A::@getter::foo
          firstFragment: #F10
          returnType: int
          variable: <testLibrary>::@enum::A::@field::foo
''');
  }

  test_augmented_field_augment_field2() async {
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
            #F3 hasInitializer isOriginDeclaration v (nameOffset:11) (firstTokenOffset:11) (offset:11)
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
            #F4 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
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
            #F5 hasInitializer isOriginDeclaration foo (nameOffset:26) (firstTokenOffset:26) (offset:26)
              element: <testLibrary>::@enum::A::@field::foo
              initializer: expression_2
                IntegerLiteral
                  literal: 0 @32
                  staticType: null
              nextFragment: #F6
          constructors
            #F7 const isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
          getters
            #F8 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::A::@getter::v
            #F9 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
            #F10 isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:26)
              element: <testLibrary>::@enum::A::@getter::foo
        #F2 enum A (nameOffset:51) (firstTokenOffset:38) (offset:51)
          element: <testLibrary>::@enum::A
          previousFragment: #F1
          nextFragment: #F11
          fields
            #F6 augment hasInitializer isOriginDeclaration foo (nameOffset:76) (firstTokenOffset:76) (offset:76)
              element: <testLibrary>::@enum::A::@field::foo
              initializer: expression_3
                IntegerLiteral
                  literal: 1 @82
                  staticType: null
              previousFragment: #F5
              nextFragment: #F12
        #F11 enum A (nameOffset:101) (firstTokenOffset:88) (offset:101)
          element: <testLibrary>::@enum::A
          previousFragment: #F2
          fields
            #F12 augment hasInitializer isOriginDeclaration foo (nameOffset:126) (firstTokenOffset:126) (offset:126)
              element: <testLibrary>::@enum::A::@field::foo
              initializer: expression_4
                IntegerLiteral
                  literal: 2 @132
                  staticType: int
              previousFragment: #F6
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F3
          type: A
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F4
          type: List<A>
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
        final hasInitializer isOriginDeclaration foo
          reference: <testLibrary>::@enum::A::@field::foo
          firstFragment: #F5
          type: int
          constantInitializer
            fragment: #F12
            expression: expression_4
          getter: <testLibrary>::@enum::A::@getter::foo
      constructors
        const isOriginImplicitDefault new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F7
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F8
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F9
          returnType: List<A>
          variable: <testLibrary>::@enum::A::@field::values
        isOriginVariable foo
          reference: <testLibrary>::@enum::A::@getter::foo
          firstFragment: #F10
          returnType: int
          variable: <testLibrary>::@enum::A::@field::foo
''');
  }

  test_augmented_field_augment_field_afterGetter() async {
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
            #F3 hasInitializer isOriginDeclaration v (nameOffset:11) (firstTokenOffset:11) (offset:11)
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
            #F4 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
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
            #F5 hasInitializer isOriginDeclaration foo (nameOffset:26) (firstTokenOffset:26) (offset:26)
              element: <testLibrary>::@enum::A::@field::foo
              initializer: expression_2
                IntegerLiteral
                  literal: 0 @32
                  staticType: null
              nextFragment: #F6
          constructors
            #F7 const isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
          getters
            #F8 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::A::@getter::v
            #F9 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
            #F10 isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:26)
              element: <testLibrary>::@enum::A::@getter::foo
              nextFragment: #F11
        #F2 enum A (nameOffset:51) (firstTokenOffset:38) (offset:51)
          element: <testLibrary>::@enum::A
          previousFragment: #F1
          nextFragment: #F12
          getters
            #F11 augment isOriginDeclaration foo (nameOffset:74) (firstTokenOffset:58) (offset:74)
              element: <testLibrary>::@enum::A::@getter::foo
              previousFragment: #F10
        #F12 enum A (nameOffset:100) (firstTokenOffset:87) (offset:100)
          element: <testLibrary>::@enum::A
          previousFragment: #F2
          fields
            #F6 augment hasInitializer isOriginDeclaration foo (nameOffset:125) (firstTokenOffset:125) (offset:125)
              element: <testLibrary>::@enum::A::@field::foo
              initializer: expression_3
                IntegerLiteral
                  literal: 2 @131
                  staticType: int
              previousFragment: #F5
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F3
          type: A
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F4
          type: List<A>
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
        final hasInitializer isOriginDeclaration foo
          reference: <testLibrary>::@enum::A::@field::foo
          firstFragment: #F5
          type: int
          constantInitializer
            fragment: #F6
            expression: expression_3
          getter: <testLibrary>::@enum::A::@getter::foo
      constructors
        const isOriginImplicitDefault new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F7
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F8
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F9
          returnType: List<A>
          variable: <testLibrary>::@enum::A::@field::values
        isOriginVariable foo
          reference: <testLibrary>::@enum::A::@getter::foo
          firstFragment: #F10
          returnType: int
          variable: <testLibrary>::@enum::A::@field::foo
''');
  }

  test_augmented_field_augment_field_afterSetter() async {
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
            #F3 hasInitializer isOriginDeclaration v (nameOffset:11) (firstTokenOffset:11) (offset:11)
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
            #F4 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
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
            #F5 hasInitializer isOriginDeclaration foo (nameOffset:26) (firstTokenOffset:26) (offset:26)
              element: <testLibrary>::@enum::A::@field::foo
              initializer: expression_2
                IntegerLiteral
                  literal: 0 @32
                  staticType: null
              nextFragment: #F6
          constructors
            #F7 const isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
          getters
            #F8 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::A::@getter::v
            #F9 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
            #F10 isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:26)
              element: <testLibrary>::@enum::A::@getter::foo
        #F2 enum A (nameOffset:51) (firstTokenOffset:38) (offset:51)
          element: <testLibrary>::@enum::A
          previousFragment: #F1
          nextFragment: #F11
          setters
            #F12 augment isOriginDeclaration foo (nameOffset:70) (firstTokenOffset:58) (offset:70)
              element: <testLibrary>::@enum::A::@setter::foo
              formalParameters
                #F13 requiredPositional _ (nameOffset:78) (firstTokenOffset:74) (offset:78)
                  element: <testLibrary>::@enum::A::@setter::foo::@formalParameter::_
        #F11 enum A (nameOffset:100) (firstTokenOffset:87) (offset:100)
          element: <testLibrary>::@enum::A
          previousFragment: #F2
          fields
            #F6 augment hasInitializer isOriginDeclaration foo (nameOffset:125) (firstTokenOffset:125) (offset:125)
              element: <testLibrary>::@enum::A::@field::foo
              initializer: expression_3
                IntegerLiteral
                  literal: 2 @131
                  staticType: int
              previousFragment: #F5
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F3
          type: A
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F4
          type: List<A>
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
        final hasInitializer isOriginDeclaration foo
          reference: <testLibrary>::@enum::A::@field::foo
          firstFragment: #F5
          type: int
          constantInitializer
            fragment: #F6
            expression: expression_3
          getter: <testLibrary>::@enum::A::@getter::foo
          setter: <testLibrary>::@enum::A::@setter::foo
      constructors
        const isOriginImplicitDefault new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F7
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F8
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F9
          returnType: List<A>
          variable: <testLibrary>::@enum::A::@field::values
        isOriginVariable foo
          reference: <testLibrary>::@enum::A::@getter::foo
          firstFragment: #F10
          returnType: int
          variable: <testLibrary>::@enum::A::@field::foo
      setters
        isOriginDeclaration foo
          reference: <testLibrary>::@enum::A::@setter::foo
          firstFragment: #F12
          formalParameters
            #E0 requiredPositional _
              firstFragment: #F13
              type: int
          returnType: void
          variable: <testLibrary>::@enum::A::@field::foo
''');
  }

  test_augmented_field_augment_field_differentTypes() async {
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
            #F3 hasInitializer isOriginDeclaration v (nameOffset:11) (firstTokenOffset:11) (offset:11)
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
            #F4 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
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
            #F5 hasInitializer isOriginDeclaration foo (nameOffset:26) (firstTokenOffset:26) (offset:26)
              element: <testLibrary>::@enum::A::@field::foo
              initializer: expression_2
                IntegerLiteral
                  literal: 0 @32
                  staticType: null
              nextFragment: #F6
          constructors
            #F7 const isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
          getters
            #F8 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::A::@getter::v
            #F9 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
            #F10 isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:26)
              element: <testLibrary>::@enum::A::@getter::foo
        #F2 enum A (nameOffset:51) (firstTokenOffset:38) (offset:51)
          element: <testLibrary>::@enum::A
          previousFragment: #F1
          fields
            #F6 augment hasInitializer isOriginDeclaration foo (nameOffset:79) (firstTokenOffset:79) (offset:79)
              element: <testLibrary>::@enum::A::@field::foo
              initializer: expression_3
                DoubleLiteral
                  literal: 1.2 @85
                  staticType: double
              previousFragment: #F5
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F3
          type: A
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F4
          type: List<A>
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
        final hasInitializer isOriginDeclaration foo
          reference: <testLibrary>::@enum::A::@field::foo
          firstFragment: #F5
          type: int
          constantInitializer
            fragment: #F6
            expression: expression_3
          getter: <testLibrary>::@enum::A::@getter::foo
      constructors
        const isOriginImplicitDefault new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F7
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F8
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F9
          returnType: List<A>
          variable: <testLibrary>::@enum::A::@field::values
        isOriginVariable foo
          reference: <testLibrary>::@enum::A::@getter::foo
          firstFragment: #F10
          returnType: int
          variable: <testLibrary>::@enum::A::@field::foo
''');
  }

  test_augmented_field_augment_field_functionExpression() async {
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
            #F3 hasInitializer isOriginDeclaration v (nameOffset:11) (firstTokenOffset:11) (offset:11)
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
            #F4 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
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
            #F5 hasInitializer isOriginDeclaration foo (nameOffset:37) (firstTokenOffset:37) (offset:37)
              element: <testLibrary>::@enum::A::@field::foo
              initializer: expression_2
                SimpleIdentifier
                  token: _notSerializableExpression @-1
                  element: <null>
                  staticType: null
              nextFragment: #F6
          constructors
            #F7 const isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
          getters
            #F8 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::A::@getter::v
            #F9 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
            #F10 isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:37)
              element: <testLibrary>::@enum::A::@getter::foo
        #F2 enum A (nameOffset:83) (firstTokenOffset:70) (offset:83)
          element: <testLibrary>::@enum::A
          previousFragment: #F1
          fields
            #F6 augment hasInitializer isOriginDeclaration foo (nameOffset:119) (firstTokenOffset:119) (offset:119)
              element: <testLibrary>::@enum::A::@field::foo
              initializer: expression_3
                SimpleIdentifier
                  token: _notSerializableExpression @-1
                  element: <null>
                  staticType: null
              previousFragment: #F5
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F3
          type: A
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F4
          type: List<A>
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
        final hasInitializer isOriginDeclaration foo
          reference: <testLibrary>::@enum::A::@field::foo
          firstFragment: #F5
          type: int Function()
          constantInitializer
            fragment: #F6
            expression: expression_3
          getter: <testLibrary>::@enum::A::@getter::foo
      constructors
        const isOriginImplicitDefault new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F7
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F8
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F9
          returnType: List<A>
          variable: <testLibrary>::@enum::A::@field::values
        isOriginVariable foo
          reference: <testLibrary>::@enum::A::@getter::foo
          firstFragment: #F10
          returnType: int Function()
          variable: <testLibrary>::@enum::A::@field::foo
''');
  }

  /// This is not allowed by the specification, but allowed syntactically,
  /// so we need a way to handle it.
  test_augmented_field_augment_getter() async {
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
            #F3 hasInitializer isOriginDeclaration v (nameOffset:11) (firstTokenOffset:11) (offset:11)
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
            #F4 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
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
            #F5 isOriginGetterSetter foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@field::foo
              nextFragment: #F6
          constructors
            #F7 const isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
          getters
            #F8 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::A::@getter::v
            #F9 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
            #F10 isOriginDeclaration foo (nameOffset:24) (firstTokenOffset:16) (offset:24)
              element: <testLibrary>::@enum::A::@getter::foo
        #F2 enum A (nameOffset:50) (firstTokenOffset:37) (offset:50)
          element: <testLibrary>::@enum::A
          previousFragment: #F1
          fields
            #F6 augment hasInitializer isOriginDeclaration foo (nameOffset:75) (firstTokenOffset:75) (offset:75)
              element: <testLibrary>::@enum::A::@field::foo
              initializer: expression_2
                IntegerLiteral
                  literal: 1 @81
                  staticType: int
              previousFragment: #F5
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F3
          type: A
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F4
          type: List<A>
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
        hasInitializer isOriginGetterSetter foo
          reference: <testLibrary>::@enum::A::@field::foo
          firstFragment: #F5
          type: int
          constantInitializer
            fragment: #F6
            expression: expression_2
          getter: <testLibrary>::@enum::A::@getter::foo
      constructors
        const isOriginImplicitDefault new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F7
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F8
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F9
          returnType: List<A>
          variable: <testLibrary>::@enum::A::@field::values
        isOriginDeclaration foo
          reference: <testLibrary>::@enum::A::@getter::foo
          firstFragment: #F10
          returnType: int
          variable: <testLibrary>::@enum::A::@field::foo
''');
  }

  test_augmented_fields_add() async {
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
            #F3 hasInitializer isOriginDeclaration v (nameOffset:11) (firstTokenOffset:11) (offset:11)
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
            #F4 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
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
            #F5 hasInitializer isOriginDeclaration foo1 (nameOffset:26) (firstTokenOffset:26) (offset:26)
              element: <testLibrary>::@enum::A::@field::foo1
              initializer: expression_2
                IntegerLiteral
                  literal: 0 @33
                  staticType: int
          constructors
            #F6 const isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
          getters
            #F7 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::A::@getter::v
            #F8 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
            #F9 isOriginVariable foo1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:26)
              element: <testLibrary>::@enum::A::@getter::foo1
        #F2 enum A (nameOffset:52) (firstTokenOffset:39) (offset:52)
          element: <testLibrary>::@enum::A
          previousFragment: #F1
          fields
            #F10 hasInitializer isOriginDeclaration foo2 (nameOffset:69) (firstTokenOffset:69) (offset:69)
              element: <testLibrary>::@enum::A::@field::foo2
              initializer: expression_3
                IntegerLiteral
                  literal: 0 @76
                  staticType: int
          getters
            #F11 isOriginVariable foo2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:69)
              element: <testLibrary>::@enum::A::@getter::foo2
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F3
          type: A
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F4
          type: List<A>
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
        final hasInitializer isOriginDeclaration foo1
          reference: <testLibrary>::@enum::A::@field::foo1
          firstFragment: #F5
          type: int
          constantInitializer
            fragment: #F5
            expression: expression_2
          getter: <testLibrary>::@enum::A::@getter::foo1
        final hasInitializer isOriginDeclaration foo2
          reference: <testLibrary>::@enum::A::@field::foo2
          firstFragment: #F10
          type: int
          constantInitializer
            fragment: #F10
            expression: expression_3
          getter: <testLibrary>::@enum::A::@getter::foo2
      constructors
        const isOriginImplicitDefault new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F6
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F7
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F8
          returnType: List<A>
          variable: <testLibrary>::@enum::A::@field::values
        isOriginVariable foo1
          reference: <testLibrary>::@enum::A::@getter::foo1
          firstFragment: #F9
          returnType: int
          variable: <testLibrary>::@enum::A::@field::foo1
        isOriginVariable foo2
          reference: <testLibrary>::@enum::A::@getter::foo2
          firstFragment: #F11
          returnType: int
          variable: <testLibrary>::@enum::A::@field::foo2
''');
  }

  test_augmented_fields_add_generic() async {
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
            #F5 hasInitializer isOriginDeclaration v (nameOffset:14) (firstTokenOffset:14) (offset:14)
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
                    element: ConstructorMember
                      baseElement: <testLibrary>::@enum::A::@constructor::new
                      substitution: {T: int}
                  argumentList: ArgumentList
                    leftParenthesis: ( @20
                    rightParenthesis: ) @21
                  staticType: A<int>
            #F6 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
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
            #F7 isOriginDeclaration foo1 (nameOffset:34) (firstTokenOffset:34) (offset:34)
              element: <testLibrary>::@enum::A::@field::foo1
          constructors
            #F8 const isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
          getters
            #F9 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:14)
              element: <testLibrary>::@enum::A::@getter::v
            #F10 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
            #F11 isOriginVariable foo1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:34)
              element: <testLibrary>::@enum::A::@getter::foo1
        #F2 enum A (nameOffset:56) (firstTokenOffset:43) (offset:56)
          element: <testLibrary>::@enum::A
          previousFragment: #F1
          typeParameters
            #F4 T (nameOffset:58) (firstTokenOffset:58) (offset:58)
              element: #E0 T
              previousFragment: #F3
          fields
            #F12 isOriginDeclaration foo2 (nameOffset:74) (firstTokenOffset:74) (offset:74)
              element: <testLibrary>::@enum::A::@field::foo2
          getters
            #F13 isOriginVariable foo2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:74)
              element: <testLibrary>::@enum::A::@getter::foo2
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F3
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F5
          type: A<int>
          constantInitializer
            fragment: #F5
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F6
          type: List<A<dynamic>>
          constantInitializer
            fragment: #F6
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
        final isOriginDeclaration foo1
          reference: <testLibrary>::@enum::A::@field::foo1
          firstFragment: #F7
          hasEnclosingTypeParameterReference: true
          type: T
          getter: <testLibrary>::@enum::A::@getter::foo1
        final isOriginDeclaration foo2
          reference: <testLibrary>::@enum::A::@field::foo2
          firstFragment: #F12
          hasEnclosingTypeParameterReference: true
          type: T
          getter: <testLibrary>::@enum::A::@getter::foo2
      constructors
        const isOriginImplicitDefault new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F8
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F9
          returnType: A<int>
          variable: <testLibrary>::@enum::A::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F10
          returnType: List<A<dynamic>>
          variable: <testLibrary>::@enum::A::@field::values
        isOriginVariable foo1
          reference: <testLibrary>::@enum::A::@getter::foo1
          firstFragment: #F11
          hasEnclosingTypeParameterReference: true
          returnType: T
          variable: <testLibrary>::@enum::A::@field::foo1
        isOriginVariable foo2
          reference: <testLibrary>::@enum::A::@getter::foo2
          firstFragment: #F13
          hasEnclosingTypeParameterReference: true
          returnType: T
          variable: <testLibrary>::@enum::A::@field::foo2
''');
  }

  test_augmented_fields_add_useFieldFormal() async {
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
            #F3 hasInitializer isOriginDeclaration v (nameOffset:11) (firstTokenOffset:11) (offset:11)
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
            #F4 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
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
          constructors
            #F5 const isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:19) (offset:25)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
              typeNameOffset: 25
              formalParameters
                #F6 requiredPositional final this.foo (nameOffset:32) (firstTokenOffset:27) (offset:32)
                  element: <testLibrary>::@enum::A::@constructor::new::@formalParameter::foo
          getters
            #F7 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::A::@getter::v
            #F8 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
        #F2 enum A (nameOffset:54) (firstTokenOffset:41) (offset:54)
          element: <testLibrary>::@enum::A
          previousFragment: #F1
          fields
            #F9 isOriginDeclaration foo (nameOffset:71) (firstTokenOffset:71) (offset:71)
              element: <testLibrary>::@enum::A::@field::foo
          getters
            #F10 isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:71)
              element: <testLibrary>::@enum::A::@getter::foo
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F3
          type: A
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F4
          type: List<A>
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
        final isOriginDeclaration foo
          reference: <testLibrary>::@enum::A::@field::foo
          firstFragment: #F9
          type: int
          getter: <testLibrary>::@enum::A::@getter::foo
      constructors
        const isOriginDeclaration new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional final hasImplicitType this.foo
              firstFragment: #F6
              type: int
              field: <testLibrary>::@enum::A::@field::foo
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F7
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F8
          returnType: List<A>
          variable: <testLibrary>::@enum::A::@field::values
        isOriginVariable foo
          reference: <testLibrary>::@enum::A::@getter::foo
          firstFragment: #F10
          returnType: int
          variable: <testLibrary>::@enum::A::@field::foo
''');
  }

  test_augmented_fields_add_useFieldInitializer() async {
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
            #F3 hasInitializer isOriginDeclaration v (nameOffset:11) (firstTokenOffset:11) (offset:11)
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
            #F4 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
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
          constructors
            #F5 const isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:16) (offset:22)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
              typeNameOffset: 22
          getters
            #F6 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::A::@getter::v
            #F7 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
        #F2 enum A (nameOffset:53) (firstTokenOffset:40) (offset:53)
          element: <testLibrary>::@enum::A
          previousFragment: #F1
          fields
            #F8 isOriginDeclaration foo (nameOffset:70) (firstTokenOffset:70) (offset:70)
              element: <testLibrary>::@enum::A::@field::foo
          getters
            #F9 isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:70)
              element: <testLibrary>::@enum::A::@getter::foo
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F3
          type: A
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F4
          type: List<A>
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
        final isOriginDeclaration foo
          reference: <testLibrary>::@enum::A::@field::foo
          firstFragment: #F8
          type: int
          getter: <testLibrary>::@enum::A::@getter::foo
      constructors
        const isOriginDeclaration new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F5
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
        static isOriginVariable v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F6
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F7
          returnType: List<A>
          variable: <testLibrary>::@enum::A::@field::values
        isOriginVariable foo
          reference: <testLibrary>::@enum::A::@getter::foo
          firstFragment: #F9
          returnType: int
          variable: <testLibrary>::@enum::A::@field::foo
''');
  }

  test_augmented_getters_add() async {
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
            #F3 hasInitializer isOriginDeclaration v (nameOffset:11) (firstTokenOffset:11) (offset:11)
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
            #F4 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
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
            #F5 isOriginGetterSetter foo1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@field::foo1
          constructors
            #F6 const isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
          getters
            #F7 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::A::@getter::v
            #F8 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
            #F9 isOriginDeclaration foo1 (nameOffset:24) (firstTokenOffset:16) (offset:24)
              element: <testLibrary>::@enum::A::@getter::foo1
        #F2 enum A (nameOffset:51) (firstTokenOffset:38) (offset:51)
          element: <testLibrary>::@enum::A
          previousFragment: #F1
          fields
            #F10 isOriginGetterSetter foo2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:51)
              element: <testLibrary>::@enum::A::@field::foo2
          getters
            #F11 isOriginDeclaration foo2 (nameOffset:66) (firstTokenOffset:58) (offset:66)
              element: <testLibrary>::@enum::A::@getter::foo2
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F3
          type: A
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F4
          type: List<A>
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
        isOriginGetterSetter foo1
          reference: <testLibrary>::@enum::A::@field::foo1
          firstFragment: #F5
          type: int
          getter: <testLibrary>::@enum::A::@getter::foo1
        isOriginGetterSetter foo2
          reference: <testLibrary>::@enum::A::@field::foo2
          firstFragment: #F10
          type: int
          getter: <testLibrary>::@enum::A::@getter::foo2
      constructors
        const isOriginImplicitDefault new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F6
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F7
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F8
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

  test_augmented_getters_add_generic() async {
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
            #F5 hasInitializer isOriginDeclaration v (nameOffset:14) (firstTokenOffset:14) (offset:14)
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
                    element: ConstructorMember
                      baseElement: <testLibrary>::@enum::A::@constructor::new
                      substitution: {T: int}
                  argumentList: ArgumentList
                    leftParenthesis: ( @20
                    rightParenthesis: ) @21
                  staticType: A<int>
            #F6 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
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
            #F7 isOriginGetterSetter foo1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@field::foo1
          constructors
            #F8 const isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
          getters
            #F9 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:14)
              element: <testLibrary>::@enum::A::@getter::v
            #F10 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
            #F11 isOriginDeclaration foo1 (nameOffset:32) (firstTokenOffset:26) (offset:32)
              element: <testLibrary>::@enum::A::@getter::foo1
        #F2 enum A (nameOffset:54) (firstTokenOffset:41) (offset:54)
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
            #F13 isOriginDeclaration foo2 (nameOffset:70) (firstTokenOffset:64) (offset:70)
              element: <testLibrary>::@enum::A::@getter::foo2
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F3
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F5
          type: A<int>
          constantInitializer
            fragment: #F5
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F6
          type: List<A<dynamic>>
          constantInitializer
            fragment: #F6
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
        isOriginGetterSetter foo1
          reference: <testLibrary>::@enum::A::@field::foo1
          firstFragment: #F7
          hasEnclosingTypeParameterReference: true
          type: T
          getter: <testLibrary>::@enum::A::@getter::foo1
        isOriginGetterSetter foo2
          reference: <testLibrary>::@enum::A::@field::foo2
          firstFragment: #F12
          hasEnclosingTypeParameterReference: true
          type: T
          getter: <testLibrary>::@enum::A::@getter::foo2
      constructors
        const isOriginImplicitDefault new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F8
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F9
          returnType: A<int>
          variable: <testLibrary>::@enum::A::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F10
          returnType: List<A<dynamic>>
          variable: <testLibrary>::@enum::A::@field::values
        abstract isOriginDeclaration foo1
          reference: <testLibrary>::@enum::A::@getter::foo1
          firstFragment: #F11
          hasEnclosingTypeParameterReference: true
          returnType: T
          variable: <testLibrary>::@enum::A::@field::foo1
        abstract isOriginDeclaration foo2
          reference: <testLibrary>::@enum::A::@getter::foo2
          firstFragment: #F13
          hasEnclosingTypeParameterReference: true
          returnType: T
          variable: <testLibrary>::@enum::A::@field::foo2
''');
  }

  test_augmented_getters_augment_field() async {
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
            #F3 hasInitializer isOriginDeclaration v (nameOffset:11) (firstTokenOffset:11) (offset:11)
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
            #F4 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
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
            #F5 hasInitializer isOriginDeclaration foo (nameOffset:26) (firstTokenOffset:26) (offset:26)
              element: <testLibrary>::@enum::A::@field::foo
              initializer: expression_2
                IntegerLiteral
                  literal: 0 @32
                  staticType: int
          constructors
            #F6 const isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
          getters
            #F7 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::A::@getter::v
            #F8 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
            #F9 isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:26)
              element: <testLibrary>::@enum::A::@getter::foo
              nextFragment: #F10
        #F2 enum A (nameOffset:51) (firstTokenOffset:38) (offset:51)
          element: <testLibrary>::@enum::A
          previousFragment: #F1
          getters
            #F10 augment isOriginDeclaration foo (nameOffset:74) (firstTokenOffset:58) (offset:74)
              element: <testLibrary>::@enum::A::@getter::foo
              previousFragment: #F9
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F3
          type: A
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F4
          type: List<A>
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
        final hasInitializer isOriginDeclaration foo
          reference: <testLibrary>::@enum::A::@field::foo
          firstFragment: #F5
          type: int
          constantInitializer
            fragment: #F5
            expression: expression_2
          getter: <testLibrary>::@enum::A::@getter::foo
      constructors
        const isOriginImplicitDefault new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F6
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F7
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F8
          returnType: List<A>
          variable: <testLibrary>::@enum::A::@field::values
        isOriginVariable foo
          reference: <testLibrary>::@enum::A::@getter::foo
          firstFragment: #F9
          returnType: int
          variable: <testLibrary>::@enum::A::@field::foo
''');
  }

  test_augmented_getters_augment_field2() async {
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
            #F3 hasInitializer isOriginDeclaration v (nameOffset:11) (firstTokenOffset:11) (offset:11)
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
            #F4 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
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
            #F5 hasInitializer isOriginDeclaration foo (nameOffset:26) (firstTokenOffset:26) (offset:26)
              element: <testLibrary>::@enum::A::@field::foo
              initializer: expression_2
                IntegerLiteral
                  literal: 0 @32
                  staticType: int
          constructors
            #F6 const isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
          getters
            #F7 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::A::@getter::v
            #F8 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
            #F9 isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:26)
              element: <testLibrary>::@enum::A::@getter::foo
              nextFragment: #F10
        #F2 enum A (nameOffset:51) (firstTokenOffset:38) (offset:51)
          element: <testLibrary>::@enum::A
          previousFragment: #F1
          nextFragment: #F11
          getters
            #F10 augment isOriginDeclaration foo (nameOffset:74) (firstTokenOffset:58) (offset:74)
              element: <testLibrary>::@enum::A::@getter::foo
              previousFragment: #F9
              nextFragment: #F12
        #F11 enum A (nameOffset:100) (firstTokenOffset:87) (offset:100)
          element: <testLibrary>::@enum::A
          previousFragment: #F2
          getters
            #F12 augment isOriginDeclaration foo (nameOffset:123) (firstTokenOffset:107) (offset:123)
              element: <testLibrary>::@enum::A::@getter::foo
              previousFragment: #F10
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F3
          type: A
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F4
          type: List<A>
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
        final hasInitializer isOriginDeclaration foo
          reference: <testLibrary>::@enum::A::@field::foo
          firstFragment: #F5
          type: int
          constantInitializer
            fragment: #F5
            expression: expression_2
          getter: <testLibrary>::@enum::A::@getter::foo
      constructors
        const isOriginImplicitDefault new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F6
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F7
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F8
          returnType: List<A>
          variable: <testLibrary>::@enum::A::@field::values
        isOriginVariable foo
          reference: <testLibrary>::@enum::A::@getter::foo
          firstFragment: #F9
          returnType: int
          variable: <testLibrary>::@enum::A::@field::foo
''');
  }

  test_augmented_getters_augment_getter() async {
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
            #F3 hasInitializer isOriginDeclaration v (nameOffset:11) (firstTokenOffset:11) (offset:11)
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
            #F4 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
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
            #F5 isOriginGetterSetter foo1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@field::foo1
            #F6 isOriginGetterSetter foo2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@field::foo2
          constructors
            #F7 const isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
          getters
            #F8 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::A::@getter::v
            #F9 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
            #F10 isOriginDeclaration foo1 (nameOffset:24) (firstTokenOffset:16) (offset:24)
              element: <testLibrary>::@enum::A::@getter::foo1
              nextFragment: #F11
            #F12 isOriginDeclaration foo2 (nameOffset:45) (firstTokenOffset:37) (offset:45)
              element: <testLibrary>::@enum::A::@getter::foo2
        #F2 enum A (nameOffset:72) (firstTokenOffset:59) (offset:72)
          element: <testLibrary>::@enum::A
          previousFragment: #F1
          getters
            #F11 augment isOriginDeclaration foo1 (nameOffset:95) (firstTokenOffset:79) (offset:95)
              element: <testLibrary>::@enum::A::@getter::foo1
              previousFragment: #F10
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F3
          type: A
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F4
          type: List<A>
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
        isOriginGetterSetter foo1
          reference: <testLibrary>::@enum::A::@field::foo1
          firstFragment: #F5
          type: int
          getter: <testLibrary>::@enum::A::@getter::foo1
        isOriginGetterSetter foo2
          reference: <testLibrary>::@enum::A::@field::foo2
          firstFragment: #F6
          type: int
          getter: <testLibrary>::@enum::A::@getter::foo2
      constructors
        const isOriginImplicitDefault new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F7
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F8
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F9
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

  test_augmented_getters_augment_getter2_oneLib_oneTop() async {
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
            #F3 hasInitializer isOriginDeclaration v (nameOffset:11) (firstTokenOffset:11) (offset:11)
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
            #F4 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
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
            #F5 isOriginGetterSetter foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@field::foo
          constructors
            #F6 const isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
          getters
            #F7 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::A::@getter::v
            #F8 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
            #F9 isOriginDeclaration foo (nameOffset:24) (firstTokenOffset:16) (offset:24)
              element: <testLibrary>::@enum::A::@getter::foo
              nextFragment: #F10
        #F2 enum A (nameOffset:50) (firstTokenOffset:37) (offset:50)
          element: <testLibrary>::@enum::A
          previousFragment: #F1
          getters
            #F10 augment isOriginDeclaration foo (nameOffset:73) (firstTokenOffset:57) (offset:73)
              element: <testLibrary>::@enum::A::@getter::foo
              previousFragment: #F9
              nextFragment: #F11
            #F11 augment isOriginDeclaration foo (nameOffset:101) (firstTokenOffset:85) (offset:101)
              element: <testLibrary>::@enum::A::@getter::foo
              previousFragment: #F10
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F3
          type: A
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F4
          type: List<A>
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
        isOriginGetterSetter foo
          reference: <testLibrary>::@enum::A::@field::foo
          firstFragment: #F5
          type: int
          getter: <testLibrary>::@enum::A::@getter::foo
      constructors
        const isOriginImplicitDefault new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F6
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F7
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F8
          returnType: List<A>
          variable: <testLibrary>::@enum::A::@field::values
        isOriginDeclaration foo
          reference: <testLibrary>::@enum::A::@getter::foo
          firstFragment: #F9
          returnType: int
          variable: <testLibrary>::@enum::A::@field::foo
''');
  }

  test_augmented_getters_augment_getter2_twoLib() async {
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
            #F3 hasInitializer isOriginDeclaration v (nameOffset:11) (firstTokenOffset:11) (offset:11)
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
            #F4 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
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
            #F5 isOriginGetterSetter foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@field::foo
          constructors
            #F6 const isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
          getters
            #F7 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::A::@getter::v
            #F8 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
            #F9 isOriginDeclaration foo (nameOffset:24) (firstTokenOffset:16) (offset:24)
              element: <testLibrary>::@enum::A::@getter::foo
              nextFragment: #F10
        #F2 enum A (nameOffset:50) (firstTokenOffset:37) (offset:50)
          element: <testLibrary>::@enum::A
          previousFragment: #F1
          nextFragment: #F11
          getters
            #F10 augment isOriginDeclaration foo (nameOffset:73) (firstTokenOffset:57) (offset:73)
              element: <testLibrary>::@enum::A::@getter::foo
              previousFragment: #F9
              nextFragment: #F12
        #F11 enum A (nameOffset:99) (firstTokenOffset:86) (offset:99)
          element: <testLibrary>::@enum::A
          previousFragment: #F2
          getters
            #F12 augment isOriginDeclaration foo (nameOffset:122) (firstTokenOffset:106) (offset:122)
              element: <testLibrary>::@enum::A::@getter::foo
              previousFragment: #F10
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F3
          type: A
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F4
          type: List<A>
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
        isOriginGetterSetter foo
          reference: <testLibrary>::@enum::A::@field::foo
          firstFragment: #F5
          type: int
          getter: <testLibrary>::@enum::A::@getter::foo
      constructors
        const isOriginImplicitDefault new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F6
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F7
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F8
          returnType: List<A>
          variable: <testLibrary>::@enum::A::@field::values
        isOriginDeclaration foo
          reference: <testLibrary>::@enum::A::@getter::foo
          firstFragment: #F9
          returnType: int
          variable: <testLibrary>::@enum::A::@field::foo
''');
  }

  test_augmented_getters_augment_nothing() async {
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
            #F3 hasInitializer isOriginDeclaration v (nameOffset:11) (firstTokenOffset:11) (offset:11)
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
            #F4 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
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
          getters
            #F5 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::A::@getter::v
            #F6 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
        #F2 enum A (nameOffset:29) (firstTokenOffset:16) (offset:29)
          element: <testLibrary>::@enum::A
          previousFragment: #F1
          fields
            #F7 isOriginGetterSetter foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:29)
              element: <testLibrary>::@enum::A::@field::foo
          getters
            #F8 augment isOriginDeclaration foo (nameOffset:52) (firstTokenOffset:36) (offset:52)
              element: <testLibrary>::@enum::A::@getter::foo
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F3
          type: A
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F4
          type: List<A>
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
        isOriginGetterSetter foo
          reference: <testLibrary>::@enum::A::@field::foo
          firstFragment: #F7
          type: int
          getter: <testLibrary>::@enum::A::@getter::foo
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F5
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v
        static isOriginVariable values
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

  test_augmented_interfaces() async {
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
            #F7 hasInitializer isOriginDeclaration v (nameOffset:25) (firstTokenOffset:25) (offset:25)
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
            #F8 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
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
          constructors
            #F9 const isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
          getters
            #F10 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
              element: <testLibrary>::@enum::A::@getter::v
            #F11 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
        #F6 enum A (nameOffset:55) (firstTokenOffset:42) (offset:55)
          element: <testLibrary>::@enum::A
          previousFragment: #F5
  classes
    class I1
      reference: <testLibrary>::@class::I1
      firstFragment: #F1
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::I1::@constructor::new
          firstFragment: #F2
    class I2
      reference: <testLibrary>::@class::I2
      firstFragment: #F3
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::I2::@constructor::new
          firstFragment: #F4
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F5
      supertype: Enum
      interfaces
        I1
        I2
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F7
          type: A
          constantInitializer
            fragment: #F7
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F8
          type: List<A>
          constantInitializer
            fragment: #F8
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
      constructors
        const isOriginImplicitDefault new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F9
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F10
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F11
          returnType: List<A>
          variable: <testLibrary>::@enum::A::@field::values
''');
  }

  test_augmented_interfaces_chain() async {
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
            #F9 hasInitializer isOriginDeclaration v (nameOffset:25) (firstTokenOffset:25) (offset:25)
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
            #F10 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
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
          constructors
            #F11 const isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
          getters
            #F12 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
              element: <testLibrary>::@enum::A::@getter::v
            #F13 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
        #F8 enum A (nameOffset:55) (firstTokenOffset:42) (offset:55)
          element: <testLibrary>::@enum::A
          previousFragment: #F7
          nextFragment: #F14
        #F14 enum A (nameOffset:100) (firstTokenOffset:87) (offset:100)
          element: <testLibrary>::@enum::A
          previousFragment: #F8
  classes
    class I1
      reference: <testLibrary>::@class::I1
      firstFragment: #F1
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::I1::@constructor::new
          firstFragment: #F2
    class I2
      reference: <testLibrary>::@class::I2
      firstFragment: #F3
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::I2::@constructor::new
          firstFragment: #F4
    class I3
      reference: <testLibrary>::@class::I3
      firstFragment: #F5
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::I3::@constructor::new
          firstFragment: #F6
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F7
      supertype: Enum
      interfaces
        I1
        I2
        I3
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F9
          type: A
          constantInitializer
            fragment: #F9
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F10
          type: List<A>
          constantInitializer
            fragment: #F10
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
      constructors
        const isOriginImplicitDefault new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F11
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F12
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F13
          returnType: List<A>
          variable: <testLibrary>::@enum::A::@field::values
''');
  }

  test_augmented_interfaces_generic() async {
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
            #F10 hasInitializer isOriginDeclaration v (nameOffset:28) (firstTokenOffset:28) (offset:28)
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
                    element: ConstructorMember
                      baseElement: <testLibrary>::@enum::A::@constructor::new
                      substitution: {T: int}
                  argumentList: ArgumentList
                    leftParenthesis: ( @34
                    rightParenthesis: ) @35
                  staticType: A<int>
            #F11 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
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
          constructors
            #F12 const isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
          getters
            #F13 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:28)
              element: <testLibrary>::@enum::A::@getter::v
            #F14 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
        #F7 enum A (nameOffset:65) (firstTokenOffset:52) (offset:65)
          element: <testLibrary>::@enum::A
          previousFragment: #F6
          typeParameters
            #F9 T (nameOffset:67) (firstTokenOffset:67) (offset:67)
              element: #E1 T
              previousFragment: #F8
  classes
    class I1
      reference: <testLibrary>::@class::I1
      firstFragment: #F1
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::I1::@constructor::new
          firstFragment: #F2
    class I2
      reference: <testLibrary>::@class::I2
      firstFragment: #F3
      typeParameters
        #E0 E
          firstFragment: #F4
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::I2::@constructor::new
          firstFragment: #F5
  enums
    enum A
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
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F10
          type: A<int>
          constantInitializer
            fragment: #F10
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F11
          type: List<A<dynamic>>
          constantInitializer
            fragment: #F11
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
      constructors
        const isOriginImplicitDefault new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F12
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F13
          returnType: A<int>
          variable: <testLibrary>::@enum::A::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F14
          returnType: List<A<dynamic>>
          variable: <testLibrary>::@enum::A::@field::values
''');
  }

  test_augmented_interfaces_generic_mismatch() async {
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
          fields
            #F10 hasInitializer isOriginDeclaration v (nameOffset:28) (firstTokenOffset:28) (offset:28)
              element: <testLibrary>::@enum::A::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibrary>::@enum::A
                      type: A<dynamic>
                    element: ConstructorMember
                      baseElement: <testLibrary>::@enum::A::@constructor::new
                      substitution: {T: dynamic}
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A<dynamic>
            #F11 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
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
          constructors
            #F12 const isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
          getters
            #F13 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:28)
              element: <testLibrary>::@enum::A::@getter::v
            #F14 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
        #F7 enum A (nameOffset:58) (firstTokenOffset:45) (offset:58)
          element: <testLibrary>::@enum::A
          previousFragment: #F6
          typeParameters
            #F9 T (nameOffset:60) (firstTokenOffset:60) (offset:60)
              element: #E1 T
              previousFragment: #F8
  classes
    class I1
      reference: <testLibrary>::@class::I1
      firstFragment: #F1
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::I1::@constructor::new
          firstFragment: #F2
    class I2
      reference: <testLibrary>::@class::I2
      firstFragment: #F3
      typeParameters
        #E0 E
          firstFragment: #F4
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::I2::@constructor::new
          firstFragment: #F5
  enums
    enum A
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
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F10
          type: A<dynamic>
          constantInitializer
            fragment: #F10
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F11
          type: List<A<dynamic>>
          constantInitializer
            fragment: #F11
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
      constructors
        const isOriginImplicitDefault new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F12
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F13
          returnType: A<dynamic>
          variable: <testLibrary>::@enum::A::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F14
          returnType: List<A<dynamic>>
          variable: <testLibrary>::@enum::A::@field::values
''');
  }

  test_augmented_methods() async {
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
            #F3 hasInitializer isOriginDeclaration v (nameOffset:11) (firstTokenOffset:11) (offset:11)
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
            #F4 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
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
          constructors
            #F5 const isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
          getters
            #F6 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::A::@getter::v
            #F7 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
          methods
            #F8 isOriginDeclaration foo (nameOffset:21) (firstTokenOffset:16) (offset:21)
              element: <testLibrary>::@enum::A::@method::foo
        #F2 enum A (nameOffset:46) (firstTokenOffset:33) (offset:46)
          element: <testLibrary>::@enum::A
          previousFragment: #F1
          methods
            #F9 isOriginDeclaration bar (nameOffset:58) (firstTokenOffset:53) (offset:58)
              element: <testLibrary>::@enum::A::@method::bar
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F3
          type: A
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F4
          type: List<A>
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
      constructors
        const isOriginImplicitDefault new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F5
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F6
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F7
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

  test_augmented_methods_add_withDefaultValue() async {
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
            #F3 hasInitializer isOriginDeclaration v (nameOffset:11) (firstTokenOffset:11) (offset:11)
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
            #F4 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
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
          constructors
            #F5 const isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
          getters
            #F6 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::A::@getter::v
            #F7 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
        #F2 enum A (nameOffset:29) (firstTokenOffset:16) (offset:29)
          element: <testLibrary>::@enum::A
          previousFragment: #F1
          methods
            #F8 isOriginDeclaration foo (nameOffset:41) (firstTokenOffset:36) (offset:41)
              element: <testLibrary>::@enum::A::@method::foo
              formalParameters
                #F9 optionalPositional x (nameOffset:50) (firstTokenOffset:46) (offset:50)
                  element: <testLibrary>::@enum::A::@method::foo::@formalParameter::x
                  initializer: expression_2
                    IntegerLiteral
                      literal: 42 @54
                      staticType: int
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F3
          type: A
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F4
          type: List<A>
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
      constructors
        const isOriginImplicitDefault new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F5
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F6
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F7
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

  test_augmented_methods_augment() async {
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
            #F3 hasInitializer isOriginDeclaration v (nameOffset:11) (firstTokenOffset:11) (offset:11)
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
            #F4 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
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
          constructors
            #F5 const isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
          getters
            #F6 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::A::@getter::v
            #F7 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
          methods
            #F8 isOriginDeclaration foo1 (nameOffset:21) (firstTokenOffset:16) (offset:21)
              element: <testLibrary>::@enum::A::@method::foo1
              nextFragment: #F9
            #F10 isOriginDeclaration foo2 (nameOffset:38) (firstTokenOffset:33) (offset:38)
              element: <testLibrary>::@enum::A::@method::foo2
        #F2 enum A (nameOffset:64) (firstTokenOffset:51) (offset:64)
          element: <testLibrary>::@enum::A
          previousFragment: #F1
          methods
            #F9 augment isOriginDeclaration foo1 (nameOffset:84) (firstTokenOffset:71) (offset:84)
              element: <testLibrary>::@enum::A::@method::foo1
              previousFragment: #F8
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F3
          type: A
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F4
          type: List<A>
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
      constructors
        const isOriginImplicitDefault new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F5
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F6
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F7
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

  test_augmented_methods_augment2_oneLib_oneTop() async {
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
            #F3 hasInitializer isOriginDeclaration v (nameOffset:11) (firstTokenOffset:11) (offset:11)
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
            #F4 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
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
          constructors
            #F5 const isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
          getters
            #F6 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::A::@getter::v
            #F7 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
          methods
            #F8 isOriginDeclaration foo (nameOffset:21) (firstTokenOffset:16) (offset:21)
              element: <testLibrary>::@enum::A::@method::foo
              nextFragment: #F9
        #F2 enum A (nameOffset:46) (firstTokenOffset:33) (offset:46)
          element: <testLibrary>::@enum::A
          previousFragment: #F1
          methods
            #F9 augment isOriginDeclaration foo (nameOffset:66) (firstTokenOffset:53) (offset:66)
              element: <testLibrary>::@enum::A::@method::foo
              previousFragment: #F8
              nextFragment: #F10
            #F10 augment isOriginDeclaration foo (nameOffset:90) (firstTokenOffset:77) (offset:90)
              element: <testLibrary>::@enum::A::@method::foo
              previousFragment: #F9
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F3
          type: A
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F4
          type: List<A>
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
      constructors
        const isOriginImplicitDefault new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F5
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F6
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F7
          returnType: List<A>
          variable: <testLibrary>::@enum::A::@field::values
      methods
        isOriginDeclaration foo
          reference: <testLibrary>::@enum::A::@method::foo
          firstFragment: #F8
          returnType: void
''');
  }

  test_augmented_methods_augment2_oneLib_twoTop() async {
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
            #F3 hasInitializer isOriginDeclaration v (nameOffset:11) (firstTokenOffset:11) (offset:11)
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
            #F4 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
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
          constructors
            #F5 const isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
          getters
            #F6 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::A::@getter::v
            #F7 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
          methods
            #F8 isOriginDeclaration foo (nameOffset:21) (firstTokenOffset:16) (offset:21)
              element: <testLibrary>::@enum::A::@method::foo
              nextFragment: #F9
        #F2 enum A (nameOffset:46) (firstTokenOffset:33) (offset:46)
          element: <testLibrary>::@enum::A
          previousFragment: #F1
          nextFragment: #F10
          methods
            #F9 augment isOriginDeclaration foo (nameOffset:66) (firstTokenOffset:53) (offset:66)
              element: <testLibrary>::@enum::A::@method::foo
              previousFragment: #F8
              nextFragment: #F11
        #F10 enum A (nameOffset:90) (firstTokenOffset:77) (offset:90)
          element: <testLibrary>::@enum::A
          previousFragment: #F2
          methods
            #F11 augment isOriginDeclaration foo (nameOffset:110) (firstTokenOffset:97) (offset:110)
              element: <testLibrary>::@enum::A::@method::foo
              previousFragment: #F9
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F3
          type: A
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F4
          type: List<A>
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
      constructors
        const isOriginImplicitDefault new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F5
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F6
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F7
          returnType: List<A>
          variable: <testLibrary>::@enum::A::@field::values
      methods
        isOriginDeclaration foo
          reference: <testLibrary>::@enum::A::@method::foo
          firstFragment: #F8
          returnType: void
''');
  }

  test_augmented_methods_augment2_twoLib() async {
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
            #F3 hasInitializer isOriginDeclaration v (nameOffset:11) (firstTokenOffset:11) (offset:11)
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
            #F4 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
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
          constructors
            #F5 const isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
          getters
            #F6 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::A::@getter::v
            #F7 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
          methods
            #F8 isOriginDeclaration foo (nameOffset:21) (firstTokenOffset:16) (offset:21)
              element: <testLibrary>::@enum::A::@method::foo
              nextFragment: #F9
        #F2 enum A (nameOffset:46) (firstTokenOffset:33) (offset:46)
          element: <testLibrary>::@enum::A
          previousFragment: #F1
          nextFragment: #F10
          methods
            #F9 augment isOriginDeclaration foo (nameOffset:66) (firstTokenOffset:53) (offset:66)
              element: <testLibrary>::@enum::A::@method::foo
              previousFragment: #F8
              nextFragment: #F11
        #F10 enum A (nameOffset:91) (firstTokenOffset:78) (offset:91)
          element: <testLibrary>::@enum::A
          previousFragment: #F2
          methods
            #F11 augment isOriginDeclaration foo (nameOffset:111) (firstTokenOffset:98) (offset:111)
              element: <testLibrary>::@enum::A::@method::foo
              previousFragment: #F9
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F3
          type: A
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F4
          type: List<A>
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
      constructors
        const isOriginImplicitDefault new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F5
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F6
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F7
          returnType: List<A>
          variable: <testLibrary>::@enum::A::@field::values
      methods
        isOriginDeclaration foo
          reference: <testLibrary>::@enum::A::@method::foo
          firstFragment: #F8
          returnType: void
''');
  }

  test_augmented_methods_generic() async {
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
            #F5 hasInitializer isOriginDeclaration v (nameOffset:14) (firstTokenOffset:14) (offset:14)
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
                    element: ConstructorMember
                      baseElement: <testLibrary>::@enum::A::@constructor::new
                      substitution: {T: int}
                  argumentList: ArgumentList
                    leftParenthesis: ( @20
                    rightParenthesis: ) @21
                  staticType: A<int>
            #F6 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
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
          constructors
            #F7 const isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
          getters
            #F8 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:14)
              element: <testLibrary>::@enum::A::@getter::v
            #F9 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
          methods
            #F10 isOriginDeclaration foo (nameOffset:28) (firstTokenOffset:26) (offset:28)
              element: <testLibrary>::@enum::A::@method::foo
        #F2 enum A (nameOffset:62) (firstTokenOffset:49) (offset:62)
          element: <testLibrary>::@enum::A
          previousFragment: #F1
          typeParameters
            #F4 T (nameOffset:64) (firstTokenOffset:64) (offset:64)
              element: #E0 T
              previousFragment: #F3
          methods
            #F11 isOriginDeclaration bar (nameOffset:74) (firstTokenOffset:72) (offset:74)
              element: <testLibrary>::@enum::A::@method::bar
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F3
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F5
          type: A<int>
          constantInitializer
            fragment: #F5
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F6
          type: List<A<dynamic>>
          constantInitializer
            fragment: #F6
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
      constructors
        const isOriginImplicitDefault new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F7
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F8
          returnType: A<int>
          variable: <testLibrary>::@enum::A::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F9
          returnType: List<A<dynamic>>
          variable: <testLibrary>::@enum::A::@field::values
      methods
        isOriginDeclaration foo
          reference: <testLibrary>::@enum::A::@method::foo
          firstFragment: #F10
          hasEnclosingTypeParameterReference: true
          returnType: T
        isOriginDeclaration bar
          reference: <testLibrary>::@enum::A::@method::bar
          firstFragment: #F11
          hasEnclosingTypeParameterReference: true
          returnType: T
''');
  }

  test_augmented_methods_generic_augment() async {
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
            #F5 hasInitializer isOriginDeclaration v (nameOffset:14) (firstTokenOffset:14) (offset:14)
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
                    element: ConstructorMember
                      baseElement: <testLibrary>::@enum::A::@constructor::new
                      substitution: {T: int}
                  argumentList: ArgumentList
                    leftParenthesis: ( @20
                    rightParenthesis: ) @21
                  staticType: A<int>
            #F6 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
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
          constructors
            #F7 const isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
          getters
            #F8 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:14)
              element: <testLibrary>::@enum::A::@getter::v
            #F9 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
          methods
            #F10 isOriginDeclaration foo (nameOffset:28) (firstTokenOffset:26) (offset:28)
              element: <testLibrary>::@enum::A::@method::foo
              nextFragment: #F11
        #F2 enum A (nameOffset:62) (firstTokenOffset:49) (offset:62)
          element: <testLibrary>::@enum::A
          previousFragment: #F1
          typeParameters
            #F4 T (nameOffset:64) (firstTokenOffset:64) (offset:64)
              element: #E0 T
              previousFragment: #F3
          methods
            #F11 augment isOriginDeclaration foo (nameOffset:82) (firstTokenOffset:72) (offset:82)
              element: <testLibrary>::@enum::A::@method::foo
              previousFragment: #F10
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F3
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F5
          type: A<int>
          constantInitializer
            fragment: #F5
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F6
          type: List<A<dynamic>>
          constantInitializer
            fragment: #F6
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
      constructors
        const isOriginImplicitDefault new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F7
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F8
          returnType: A<int>
          variable: <testLibrary>::@enum::A::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F9
          returnType: List<A<dynamic>>
          variable: <testLibrary>::@enum::A::@field::values
      methods
        isOriginDeclaration foo
          reference: <testLibrary>::@enum::A::@method::foo
          firstFragment: #F10
          hasEnclosingTypeParameterReference: true
          returnType: T
''');
  }

  test_augmented_mixins() async {
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
            #F3 hasInitializer isOriginDeclaration v (nameOffset:19) (firstTokenOffset:19) (offset:19)
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
            #F4 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
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
          constructors
            #F5 const isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
          getters
            #F6 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:19)
              element: <testLibrary>::@enum::A::@getter::v
            #F7 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
        #F2 enum A (nameOffset:49) (firstTokenOffset:36) (offset:49)
          element: <testLibrary>::@enum::A
          previousFragment: #F1
      mixins
        #F8 mixin M1 (nameOffset:29) (firstTokenOffset:23) (offset:29)
          element: <testLibrary>::@mixin::M1
        #F9 mixin M2 (nameOffset:68) (firstTokenOffset:62) (offset:68)
          element: <testLibrary>::@mixin::M2
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      supertype: Enum
      mixins
        M1
        M2
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F3
          type: A
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F4
          type: List<A>
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
      constructors
        const isOriginImplicitDefault new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F5
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F6
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F7
          returnType: List<A>
          variable: <testLibrary>::@enum::A::@field::values
  mixins
    mixin M1
      reference: <testLibrary>::@mixin::M1
      firstFragment: #F8
      superclassConstraints
        Object
    mixin M2
      reference: <testLibrary>::@mixin::M2
      firstFragment: #F9
      superclassConstraints
        Object
''');
  }

  test_augmented_mixins_inferredTypeArguments() async {
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
            #F5 hasInitializer isOriginDeclaration v (nameOffset:25) (firstTokenOffset:25) (offset:25)
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
                    element: ConstructorMember
                      baseElement: <testLibrary>::@enum::A::@constructor::new
                      substitution: {T: int}
                  argumentList: ArgumentList
                    leftParenthesis: ( @31
                    rightParenthesis: ) @32
                  staticType: A<int>
            #F6 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
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
          constructors
            #F7 const isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
          getters
            #F8 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
              element: <testLibrary>::@enum::A::@getter::v
            #F9 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
        #F2 enum A (nameOffset:66) (firstTokenOffset:53) (offset:66)
          element: <testLibrary>::@enum::A
          previousFragment: #F1
          nextFragment: #F10
          typeParameters
            #F4 T (nameOffset:68) (firstTokenOffset:68) (offset:68)
              element: #E0 T
              previousFragment: #F3
              nextFragment: #F11
        #F10 enum A (nameOffset:122) (firstTokenOffset:109) (offset:122)
          element: <testLibrary>::@enum::A
          previousFragment: #F2
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
    enum A
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
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F5
          type: A<int>
          constantInitializer
            fragment: #F5
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F6
          type: List<A<dynamic>>
          constantInitializer
            fragment: #F6
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
      constructors
        const isOriginImplicitDefault new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F7
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F8
          returnType: A<int>
          variable: <testLibrary>::@enum::A::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F9
          returnType: List<A<dynamic>>
          variable: <testLibrary>::@enum::A::@field::values
  mixins
    mixin M1
      reference: <testLibrary>::@mixin::M1
      firstFragment: #F12
      typeParameters
        #E1 U1
          firstFragment: #F13
      superclassConstraints
        Object
    mixin M2
      reference: <testLibrary>::@mixin::M2
      firstFragment: #F14
      typeParameters
        #E2 U2
          firstFragment: #F15
      superclassConstraints
        M1<U2>
    mixin M3
      reference: <testLibrary>::@mixin::M3
      firstFragment: #F16
      typeParameters
        #E3 U3
          firstFragment: #F17
      superclassConstraints
        M2<U3>
''');
  }

  test_augmented_setters_add() async {
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
            #F3 hasInitializer isOriginDeclaration v (nameOffset:11) (firstTokenOffset:11) (offset:11)
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
            #F4 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
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
            #F5 isOriginGetterSetter foo1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@field::foo1
          constructors
            #F6 const isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
          getters
            #F7 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::A::@getter::v
            #F8 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
          setters
            #F9 isOriginDeclaration foo1 (nameOffset:20) (firstTokenOffset:16) (offset:20)
              element: <testLibrary>::@enum::A::@setter::foo1
              formalParameters
                #F10 requiredPositional _ (nameOffset:29) (firstTokenOffset:25) (offset:29)
                  element: <testLibrary>::@enum::A::@setter::foo1::@formalParameter::_
        #F2 enum A (nameOffset:51) (firstTokenOffset:38) (offset:51)
          element: <testLibrary>::@enum::A
          previousFragment: #F1
          fields
            #F11 isOriginGetterSetter foo2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:51)
              element: <testLibrary>::@enum::A::@field::foo2
          setters
            #F12 isOriginDeclaration foo2 (nameOffset:62) (firstTokenOffset:58) (offset:62)
              element: <testLibrary>::@enum::A::@setter::foo2
              formalParameters
                #F13 requiredPositional _ (nameOffset:71) (firstTokenOffset:67) (offset:71)
                  element: <testLibrary>::@enum::A::@setter::foo2::@formalParameter::_
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F3
          type: A
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F4
          type: List<A>
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
        isOriginGetterSetter foo1
          reference: <testLibrary>::@enum::A::@field::foo1
          firstFragment: #F5
          type: int
          setter: <testLibrary>::@enum::A::@setter::foo1
        isOriginGetterSetter foo2
          reference: <testLibrary>::@enum::A::@field::foo2
          firstFragment: #F11
          type: int
          setter: <testLibrary>::@enum::A::@setter::foo2
      constructors
        const isOriginImplicitDefault new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F6
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F7
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F8
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

  test_augmented_setters_augment_field() async {
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
            #F3 hasInitializer isOriginDeclaration v (nameOffset:11) (firstTokenOffset:11) (offset:11)
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
            #F4 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
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
            #F5 hasInitializer isOriginDeclaration foo (nameOffset:26) (firstTokenOffset:26) (offset:26)
              element: <testLibrary>::@enum::A::@field::foo
              initializer: expression_2
                IntegerLiteral
                  literal: 0 @32
                  staticType: int
          constructors
            #F6 const isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
          getters
            #F7 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::A::@getter::v
            #F8 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
            #F9 isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:26)
              element: <testLibrary>::@enum::A::@getter::foo
        #F2 enum A (nameOffset:51) (firstTokenOffset:38) (offset:51)
          element: <testLibrary>::@enum::A
          previousFragment: #F1
          setters
            #F10 augment isOriginDeclaration foo (nameOffset:70) (firstTokenOffset:58) (offset:70)
              element: <testLibrary>::@enum::A::@setter::foo
              formalParameters
                #F11 requiredPositional _ (nameOffset:78) (firstTokenOffset:74) (offset:78)
                  element: <testLibrary>::@enum::A::@setter::foo::@formalParameter::_
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F3
          type: A
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F4
          type: List<A>
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
        final hasInitializer isOriginDeclaration foo
          reference: <testLibrary>::@enum::A::@field::foo
          firstFragment: #F5
          type: int
          constantInitializer
            fragment: #F5
            expression: expression_2
          getter: <testLibrary>::@enum::A::@getter::foo
          setter: <testLibrary>::@enum::A::@setter::foo
      constructors
        const isOriginImplicitDefault new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F6
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F7
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F8
          returnType: List<A>
          variable: <testLibrary>::@enum::A::@field::values
        isOriginVariable foo
          reference: <testLibrary>::@enum::A::@getter::foo
          firstFragment: #F9
          returnType: int
          variable: <testLibrary>::@enum::A::@field::foo
      setters
        isOriginDeclaration foo
          reference: <testLibrary>::@enum::A::@setter::foo
          firstFragment: #F10
          formalParameters
            #E0 requiredPositional _
              firstFragment: #F11
              type: int
          returnType: void
          variable: <testLibrary>::@enum::A::@field::foo
''');
  }

  test_augmented_setters_augment_nothing() async {
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
            #F3 hasInitializer isOriginDeclaration v (nameOffset:11) (firstTokenOffset:11) (offset:11)
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
            #F4 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
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
          constructors
            #F5 const isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
          getters
            #F6 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::A::@getter::v
            #F7 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
        #F2 enum A (nameOffset:29) (firstTokenOffset:16) (offset:29)
          element: <testLibrary>::@enum::A
          previousFragment: #F1
          fields
            #F8 isOriginGetterSetter foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:29)
              element: <testLibrary>::@enum::A::@field::foo
          setters
            #F9 augment isOriginDeclaration foo (nameOffset:48) (firstTokenOffset:36) (offset:48)
              element: <testLibrary>::@enum::A::@setter::foo
              formalParameters
                #F10 requiredPositional _ (nameOffset:56) (firstTokenOffset:52) (offset:56)
                  element: <testLibrary>::@enum::A::@setter::foo::@formalParameter::_
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F3
          type: A
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F4
          type: List<A>
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
        isOriginGetterSetter foo
          reference: <testLibrary>::@enum::A::@field::foo
          firstFragment: #F8
          type: int
          setter: <testLibrary>::@enum::A::@setter::foo
      constructors
        const isOriginImplicitDefault new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F5
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F6
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F7
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

  test_augmented_setters_augment_setter() async {
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
            #F3 hasInitializer isOriginDeclaration v (nameOffset:11) (firstTokenOffset:11) (offset:11)
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
            #F4 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
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
            #F5 isOriginGetterSetter foo1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@field::foo1
            #F6 isOriginGetterSetter foo2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@field::foo2
          constructors
            #F7 const isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
          getters
            #F8 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::A::@getter::v
            #F9 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
          setters
            #F10 isOriginDeclaration foo1 (nameOffset:20) (firstTokenOffset:16) (offset:20)
              element: <testLibrary>::@enum::A::@setter::foo1
              formalParameters
                #F11 requiredPositional _ (nameOffset:29) (firstTokenOffset:25) (offset:29)
                  element: <testLibrary>::@enum::A::@setter::foo1::@formalParameter::_
              nextFragment: #F12
            #F13 isOriginDeclaration foo2 (nameOffset:41) (firstTokenOffset:37) (offset:41)
              element: <testLibrary>::@enum::A::@setter::foo2
              formalParameters
                #F14 requiredPositional _ (nameOffset:50) (firstTokenOffset:46) (offset:50)
                  element: <testLibrary>::@enum::A::@setter::foo2::@formalParameter::_
        #F2 enum A (nameOffset:72) (firstTokenOffset:59) (offset:72)
          element: <testLibrary>::@enum::A
          previousFragment: #F1
          setters
            #F12 augment isOriginDeclaration foo1 (nameOffset:91) (firstTokenOffset:79) (offset:91)
              element: <testLibrary>::@enum::A::@setter::foo1
              formalParameters
                #F15 requiredPositional _ (nameOffset:100) (firstTokenOffset:96) (offset:100)
                  element: <testLibrary>::@enum::A::@setter::foo1::@formalParameter::_
              previousFragment: #F10
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F3
          type: A
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F4
          type: List<A>
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
        isOriginGetterSetter foo1
          reference: <testLibrary>::@enum::A::@field::foo1
          firstFragment: #F5
          type: int
          setter: <testLibrary>::@enum::A::@setter::foo1
        isOriginGetterSetter foo2
          reference: <testLibrary>::@enum::A::@field::foo2
          firstFragment: #F6
          type: int
          setter: <testLibrary>::@enum::A::@setter::foo2
      constructors
        const isOriginImplicitDefault new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F7
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F8
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F9
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
          firstFragment: #F13
          formalParameters
            #E1 requiredPositional _
              firstFragment: #F14
              type: int
          returnType: void
          variable: <testLibrary>::@enum::A::@field::foo2
''');
  }

  test_augmentedBy_class2() async {
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
        #F1 class A (nameOffset:26) (firstTokenOffset:12) (offset:26)
          element: <testLibrary>::@class::A
          nextFragment: #F2
        #F2 class A (nameOffset:46) (firstTokenOffset:32) (offset:46)
          element: <testLibrary>::@class::A
          previousFragment: #F1
      enums
        #F3 enum A (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@enum::A
          fields
            #F4 hasInitializer isOriginDeclaration v (nameOffset:8) (firstTokenOffset:8) (offset:8)
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
            #F5 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
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
          getters
            #F6 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:8)
              element: <testLibrary>::@enum::A::@getter::v
            #F7 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F3
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F4
          type: A
          constantInitializer
            fragment: #F4
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F5
          type: List<A>
          constantInitializer
            fragment: #F5
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F6
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F7
          returnType: List<A>
          variable: <testLibrary>::@enum::A::@field::values
''');
  }

  test_augmentedBy_class_enum() async {
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
        #F1 class A (nameOffset:26) (firstTokenOffset:12) (offset:26)
          element: <testLibrary>::@class::A
      enums
        #F2 enum A (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@enum::A::@def::0
          fields
            #F3 hasInitializer isOriginDeclaration v (nameOffset:8) (firstTokenOffset:8) (offset:8)
              element: <testLibrary>::@enum::A::@def::0::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibrary>::@enum::A::@def::0
                      type: A
                    element: <testLibrary>::@enum::A::@def::0::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
            #F4 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@def::0::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::A::@def::0::@getter::v
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
          getters
            #F5 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:8)
              element: <testLibrary>::@enum::A::@def::0::@getter::v
            #F6 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@def::0::@getter::values
        #F7 enum A (nameOffset:44) (firstTokenOffset:31) (offset:44)
          element: <testLibrary>::@enum::A::@def::1
          fields
            #F8 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:44)
              element: <testLibrary>::@enum::A::@def::1::@field::values
              initializer: expression_2
                ListLiteral
                  leftBracket: [ @0
                  rightBracket: ] @0
                  staticType: List<A>
          getters
            #F9 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:44)
              element: <testLibrary>::@enum::A::@def::1::@getter::values
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
  enums
    enum A
      reference: <testLibrary>::@enum::A::@def::0
      firstFragment: #F2
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::A::@def::0::@field::v
          firstFragment: #F3
          type: A
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::A::@def::0::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::A::@def::0::@field::values
          firstFragment: #F4
          type: List<A>
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::A::@def::0::@getter::values
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::A::@def::0::@getter::v
          firstFragment: #F5
          returnType: A
          variable: <testLibrary>::@enum::A::@def::0::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::A::@def::0::@getter::values
          firstFragment: #F6
          returnType: List<A>
          variable: <testLibrary>::@enum::A::@def::0::@field::values
    enum A
      reference: <testLibrary>::@enum::A::@def::1
      firstFragment: #F7
      supertype: Enum
      fields
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::A::@def::1::@field::values
          firstFragment: #F8
          type: List<A>
          constantInitializer
            fragment: #F8
            expression: expression_2
          getter: <testLibrary>::@enum::A::@def::1::@getter::values
      getters
        static isOriginVariable values
          reference: <testLibrary>::@enum::A::@def::1::@getter::values
          firstFragment: #F9
          returnType: List<A>
          variable: <testLibrary>::@enum::A::@def::1::@field::values
''');
  }

  test_constructors_augment2() async {
    var library = await buildLibrary(r'''
enum A {
  v.named();
  const A.named();
}

augment enum A {;
  augment const A.named();
}

augment enum A {;
  augment const A.named();
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
            #F3 hasInitializer isOriginDeclaration v (nameOffset:11) (firstTokenOffset:11) (offset:11)
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
            #F4 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
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
          constructors
            #F5 const isOriginDeclaration named (nameOffset:32) (firstTokenOffset:24) (offset:32)
              element: <testLibrary>::@enum::A::@constructor::named
              typeName: A
              typeNameOffset: 30
              periodOffset: 31
              nextFragment: #F6
          getters
            #F7 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::A::@getter::v
            #F8 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
        #F2 enum A (nameOffset:57) (firstTokenOffset:44) (offset:57)
          element: <testLibrary>::@enum::A
          previousFragment: #F1
          nextFragment: #F9
          constructors
            #F6 augment const isOriginDeclaration named (nameOffset:80) (firstTokenOffset:64) (offset:80)
              element: <testLibrary>::@enum::A::@constructor::named
              typeName: A
              typeNameOffset: 78
              periodOffset: 79
              nextFragment: #F10
              previousFragment: #F5
        #F9 enum A (nameOffset:105) (firstTokenOffset:92) (offset:105)
          element: <testLibrary>::@enum::A
          previousFragment: #F2
          constructors
            #F10 augment const isOriginDeclaration named (nameOffset:128) (firstTokenOffset:112) (offset:128)
              element: <testLibrary>::@enum::A::@constructor::named
              typeName: A
              typeNameOffset: 126
              periodOffset: 127
              previousFragment: #F6
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F3
          type: A
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F4
          type: List<A>
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
      constructors
        const isOriginDeclaration named
          reference: <testLibrary>::@enum::A::@constructor::named
          firstFragment: #F5
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F7
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F8
          returnType: List<A>
          variable: <testLibrary>::@enum::A::@field::values
''');
  }

  test_constructors_augment_named() async {
    var library = await buildLibrary(r'''
enum A {
  v.named();
  const A.named();
}

augment enum A {;
  augment const A.named();
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
            #F3 hasInitializer isOriginDeclaration v (nameOffset:11) (firstTokenOffset:11) (offset:11)
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
            #F4 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
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
          constructors
            #F5 const isOriginDeclaration named (nameOffset:32) (firstTokenOffset:24) (offset:32)
              element: <testLibrary>::@enum::A::@constructor::named
              typeName: A
              typeNameOffset: 30
              periodOffset: 31
              nextFragment: #F6
          getters
            #F7 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::A::@getter::v
            #F8 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
        #F2 enum A (nameOffset:57) (firstTokenOffset:44) (offset:57)
          element: <testLibrary>::@enum::A
          previousFragment: #F1
          constructors
            #F6 augment const isOriginDeclaration named (nameOffset:80) (firstTokenOffset:64) (offset:80)
              element: <testLibrary>::@enum::A::@constructor::named
              typeName: A
              typeNameOffset: 78
              periodOffset: 79
              previousFragment: #F5
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F3
          type: A
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F4
          type: List<A>
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
      constructors
        const isOriginDeclaration named
          reference: <testLibrary>::@enum::A::@constructor::named
          firstFragment: #F5
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F7
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F8
          returnType: List<A>
          variable: <testLibrary>::@enum::A::@field::values
''');
  }

  test_constructors_augment_unnamed() async {
    var library = await buildLibrary(r'''
enum A {
  v;
  const A();
}

augment enum A {;
  augment const A();
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
            #F3 hasInitializer isOriginDeclaration v (nameOffset:11) (firstTokenOffset:11) (offset:11)
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
            #F4 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
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
          constructors
            #F5 const isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:16) (offset:22)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
              typeNameOffset: 22
              nextFragment: #F6
          getters
            #F7 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:11)
              element: <testLibrary>::@enum::A::@getter::v
            #F8 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
        #F2 enum A (nameOffset:43) (firstTokenOffset:30) (offset:43)
          element: <testLibrary>::@enum::A
          previousFragment: #F1
          constructors
            #F6 augment const isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:50) (offset:64)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
              typeNameOffset: 64
              previousFragment: #F5
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F3
          type: A
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F4
          type: List<A>
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
      constructors
        const isOriginDeclaration new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F5
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F7
          returnType: A
          variable: <testLibrary>::@enum::A::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F8
          returnType: List<A>
          variable: <testLibrary>::@enum::A::@field::values
''');
  }

  test_inferTypes_method_ofAugment() async {
    newFile('$testPackageLibPath/a.dart', r'''
abstract class A {
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
            #F3 hasInitializer isOriginDeclaration v (nameOffset:41) (firstTokenOffset:41) (offset:41)
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
            #F4 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
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
          constructors
            #F5 const isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
              element: <testLibrary>::@enum::B::@constructor::new
              typeName: B
          getters
            #F6 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:41)
              element: <testLibrary>::@enum::B::@getter::v
            #F7 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
              element: <testLibrary>::@enum::B::@getter::values
        #F2 enum B (nameOffset:59) (firstTokenOffset:46) (offset:59)
          element: <testLibrary>::@enum::B
          previousFragment: #F1
          methods
            #F8 isOriginDeclaration foo (nameOffset:66) (firstTokenOffset:66) (offset:66)
              element: <testLibrary>::@enum::B::@method::foo
              formalParameters
                #F9 requiredPositional a (nameOffset:70) (firstTokenOffset:70) (offset:70)
                  element: <testLibrary>::@enum::B::@method::foo::@formalParameter::a
  enums
    enum B
      reference: <testLibrary>::@enum::B
      firstFragment: #F1
      supertype: Enum
      interfaces
        A
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::B::@field::v
          firstFragment: #F3
          type: B
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::B::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::B::@field::values
          firstFragment: #F4
          type: List<B>
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::B::@getter::values
      constructors
        const isOriginImplicitDefault new
          reference: <testLibrary>::@enum::B::@constructor::new
          firstFragment: #F5
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::B::@getter::v
          firstFragment: #F6
          returnType: B
          variable: <testLibrary>::@enum::B::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::B::@getter::values
          firstFragment: #F7
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

  test_inferTypes_method_usingAugmentation_interface() async {
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
            #F3 hasInitializer isOriginDeclaration v (nameOffset:29) (firstTokenOffset:29) (offset:29)
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
            #F4 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
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
          constructors
            #F5 const isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
              element: <testLibrary>::@enum::B::@constructor::new
              typeName: B
          getters
            #F6 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:29)
              element: <testLibrary>::@enum::B::@getter::v
            #F7 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
              element: <testLibrary>::@enum::B::@getter::values
          methods
            #F8 isOriginDeclaration foo (nameOffset:34) (firstTokenOffset:34) (offset:34)
              element: <testLibrary>::@enum::B::@method::foo
              formalParameters
                #F9 requiredPositional a (nameOffset:38) (firstTokenOffset:38) (offset:38)
                  element: <testLibrary>::@enum::B::@method::foo::@formalParameter::a
        #F2 enum B (nameOffset:63) (firstTokenOffset:50) (offset:63)
          element: <testLibrary>::@enum::B
          previousFragment: #F1
  enums
    enum B
      reference: <testLibrary>::@enum::B
      firstFragment: #F1
      supertype: Enum
      interfaces
        A
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::B::@field::v
          firstFragment: #F3
          type: B
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::B::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::B::@field::values
          firstFragment: #F4
          type: List<B>
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::B::@getter::values
      constructors
        const isOriginImplicitDefault new
          reference: <testLibrary>::@enum::B::@constructor::new
          firstFragment: #F5
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::B::@getter::v
          firstFragment: #F6
          returnType: B
          variable: <testLibrary>::@enum::B::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::B::@getter::values
          firstFragment: #F7
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

  test_inferTypes_method_usingAugmentation_mixin() async {
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
            #F3 hasInitializer isOriginDeclaration v (nameOffset:29) (firstTokenOffset:29) (offset:29)
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
            #F4 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
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
          constructors
            #F5 const isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
              element: <testLibrary>::@enum::B::@constructor::new
              typeName: B
          getters
            #F6 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:29)
              element: <testLibrary>::@enum::B::@getter::v
            #F7 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
              element: <testLibrary>::@enum::B::@getter::values
          methods
            #F8 isOriginDeclaration foo (nameOffset:34) (firstTokenOffset:34) (offset:34)
              element: <testLibrary>::@enum::B::@method::foo
              formalParameters
                #F9 requiredPositional a (nameOffset:38) (firstTokenOffset:38) (offset:38)
                  element: <testLibrary>::@enum::B::@method::foo::@formalParameter::a
        #F2 enum B (nameOffset:63) (firstTokenOffset:50) (offset:63)
          element: <testLibrary>::@enum::B
          previousFragment: #F1
  enums
    enum B
      reference: <testLibrary>::@enum::B
      firstFragment: #F1
      supertype: Enum
      mixins
        A
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::B::@field::v
          firstFragment: #F3
          type: B
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::B::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::B::@field::values
          firstFragment: #F4
          type: List<B>
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::B::@getter::values
      constructors
        const isOriginImplicitDefault new
          reference: <testLibrary>::@enum::B::@constructor::new
          firstFragment: #F5
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::B::@getter::v
          firstFragment: #F6
          returnType: B
          variable: <testLibrary>::@enum::B::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::B::@getter::values
          firstFragment: #F7
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
            #F2 hasInitializer isOriginDeclaration v (nameOffset:20) (firstTokenOffset:20) (offset:20)
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
            #F3 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
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
            #F4 hasInitializer isOriginDeclaration bar (nameOffset:34) (firstTokenOffset:34) (offset:34)
              element: <testLibrary>::@enum::E::@field::bar
              initializer: expression_2
                SimpleIdentifier
                  token: foo @40
                  element: <testLibrary>::@enum::E::@constructor::new::@formalParameter::foo
                  staticType: int
          constructors
            #F5 const isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:5) (offset:5)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
              typeNameOffset: 5
              formalParameters
                #F6 requiredPositional foo (nameOffset:11) (firstTokenOffset:7) (offset:11)
                  element: <testLibrary>::@enum::E::@constructor::new::@formalParameter::foo
          getters
            #F7 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:20)
              element: <testLibrary>::@enum::E::@getter::v
            #F8 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
            #F9 isOriginVariable bar (nameOffset:<null>) (firstTokenOffset:<null>) (offset:34)
              element: <testLibrary>::@enum::E::@getter::bar
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F3
          type: List<E>
          constantInitializer
            fragment: #F3
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
        final hasImplicitType hasInitializer isOriginDeclaration bar
          reference: <testLibrary>::@enum::E::@field::bar
          firstFragment: #F4
          type: int
          constantInitializer
            fragment: #F4
            expression: expression_2
          getter: <testLibrary>::@enum::E::@getter::bar
      constructors
        const isOriginDeclaration isPrimary new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional foo
              firstFragment: #F6
              type: int
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F7
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F8
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
        isOriginVariable bar
          reference: <testLibrary>::@enum::E::@getter::bar
          firstFragment: #F9
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
            #F2 hasInitializer isOriginDeclaration v (nameOffset:26) (firstTokenOffset:26) (offset:26)
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
            #F3 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
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
            #F4 isOriginDeclaringFormalParameter foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@field::foo
            #F5 hasInitializer isOriginDeclaration bar (nameOffset:40) (firstTokenOffset:40) (offset:40)
              element: <testLibrary>::@enum::E::@field::bar
              initializer: expression_2
                SimpleIdentifier
                  token: foo @46
                  element: <testLibrary>::@enum::E::@constructor::new::@formalParameter::foo
                  staticType: int
          constructors
            #F6 const isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:5) (offset:5)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
              typeNameOffset: 5
              formalParameters
                #F7 requiredPositional final this.foo (nameOffset:17) (firstTokenOffset:7) (offset:17)
                  element: <testLibrary>::@enum::E::@constructor::new::@formalParameter::foo
          getters
            #F8 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:26)
              element: <testLibrary>::@enum::E::@getter::v
            #F9 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
            #F10 isOriginVariable foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::foo
            #F11 isOriginVariable bar (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
              element: <testLibrary>::@enum::E::@getter::bar
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F3
          type: List<E>
          constantInitializer
            fragment: #F3
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
        final isOriginDeclaringFormalParameter foo
          reference: <testLibrary>::@enum::E::@field::foo
          firstFragment: #F4
          type: int
          getter: <testLibrary>::@enum::E::@getter::foo
          declaringFormalParameter: <testLibrary>::@enum::E::@constructor::new::@formalParameter::foo
        final hasImplicitType hasInitializer isOriginDeclaration bar
          reference: <testLibrary>::@enum::E::@field::bar
          firstFragment: #F5
          type: int
          constantInitializer
            fragment: #F5
            expression: expression_2
          getter: <testLibrary>::@enum::E::@getter::bar
      constructors
        const isOriginDeclaration isPrimary new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F6
          formalParameters
            #E0 requiredPositional final declaring this.foo
              firstFragment: #F7
              type: int
              field: <testLibrary>::@enum::E::@field::foo
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F8
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F9
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
        isOriginVariable foo
          reference: <testLibrary>::@enum::E::@getter::foo
          firstFragment: #F10
          returnType: int
          variable: <testLibrary>::@enum::E::@field::foo
        isOriginVariable bar
          reference: <testLibrary>::@enum::E::@getter::bar
          firstFragment: #F11
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
            #F2 hasInitializer isOriginDeclaration v (nameOffset:20) (firstTokenOffset:20) (offset:20)
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
            #F3 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
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
            #F4 hasInitializer isOriginDeclaration bar (nameOffset:39) (firstTokenOffset:39) (offset:39)
              element: <testLibrary>::@enum::E::@field::bar
              initializer: expression_2
                SimpleIdentifier
                  token: foo @45
                  element: <null>
                  staticType: InvalidType
          constructors
            #F5 const isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:5) (offset:5)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
              typeNameOffset: 5
              formalParameters
                #F6 requiredPositional foo (nameOffset:11) (firstTokenOffset:7) (offset:11)
                  element: <testLibrary>::@enum::E::@constructor::new::@formalParameter::foo
          getters
            #F7 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:20)
              element: <testLibrary>::@enum::E::@getter::v
            #F8 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
            #F9 isOriginVariable bar (nameOffset:<null>) (firstTokenOffset:<null>) (offset:39)
              element: <testLibrary>::@enum::E::@getter::bar
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F3
          type: List<E>
          constantInitializer
            fragment: #F3
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
        late final hasImplicitType hasInitializer isOriginDeclaration bar
          reference: <testLibrary>::@enum::E::@field::bar
          firstFragment: #F4
          type: InvalidType
          constantInitializer
            fragment: #F4
            expression: expression_2
          getter: <testLibrary>::@enum::E::@getter::bar
      constructors
        const isOriginDeclaration isPrimary new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional foo
              firstFragment: #F6
              type: int
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F7
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F8
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
        isOriginVariable bar
          reference: <testLibrary>::@enum::E::@getter::bar
          firstFragment: #F9
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
            #F2 hasInitializer isOriginDeclaration v (nameOffset:21) (firstTokenOffset:21) (offset:21)
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
            #F3 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
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
            #F4 hasInitializer isOriginDeclaration bar (nameOffset:35) (firstTokenOffset:35) (offset:35)
              element: <testLibrary>::@enum::E::@field::bar
              initializer: expression_2
                ConditionalExpression
                  condition: BinaryExpression
                    leftOperand: SimpleIdentifier
                      token: foo @41
                      element: <testLibrary>::@enum::E::@constructor::new::@formalParameter::foo
                      staticType: int?
                    operator: != @45
                    rightOperand: NullLiteral
                      literal: null @48
                      staticType: Null
                    element: dart:core::@class::num::@method::==
                    staticInvokeType: bool Function(Object)
                    staticType: bool
                  question: ? @53
                  thenExpression: SimpleIdentifier
                    token: foo @55
                    element: <testLibrary>::@enum::E::@constructor::new::@formalParameter::foo
                    staticType: int
                  colon: : @59
                  elseExpression: IntegerLiteral
                    literal: 0 @61
                    staticType: int
                  staticType: int
          constructors
            #F5 const isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:5) (offset:5)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
              typeNameOffset: 5
              formalParameters
                #F6 requiredPositional foo (nameOffset:12) (firstTokenOffset:7) (offset:12)
                  element: <testLibrary>::@enum::E::@constructor::new::@formalParameter::foo
          getters
            #F7 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@enum::E::@getter::v
            #F8 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
            #F9 isOriginVariable bar (nameOffset:<null>) (firstTokenOffset:<null>) (offset:35)
              element: <testLibrary>::@enum::E::@getter::bar
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F3
          type: List<E>
          constantInitializer
            fragment: #F3
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
        final hasImplicitType hasInitializer isOriginDeclaration bar
          reference: <testLibrary>::@enum::E::@field::bar
          firstFragment: #F4
          type: int
          constantInitializer
            fragment: #F4
            expression: expression_2
          getter: <testLibrary>::@enum::E::@getter::bar
      constructors
        const isOriginDeclaration isPrimary new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional foo
              firstFragment: #F6
              type: int?
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F7
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F8
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
        isOriginVariable bar
          reference: <testLibrary>::@enum::E::@getter::bar
          firstFragment: #F9
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
            #F2 hasInitializer isOriginDeclaration v (nameOffset:20) (firstTokenOffset:20) (offset:20)
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
            #F3 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
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
            #F4 hasInitializer isOriginDeclaration bar (nameOffset:41) (firstTokenOffset:41) (offset:41)
              element: <testLibrary>::@enum::E::@field::bar
          constructors
            #F5 const isOriginDeclaration isPrimary new (nameOffset:<null>) (firstTokenOffset:5) (offset:5)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
              typeNameOffset: 5
              formalParameters
                #F6 requiredPositional foo (nameOffset:11) (firstTokenOffset:7) (offset:11)
                  element: <testLibrary>::@enum::E::@constructor::new::@formalParameter::foo
          getters
            #F7 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:20)
              element: <testLibrary>::@enum::E::@getter::v
            #F8 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
            #F9 isOriginVariable bar (nameOffset:<null>) (firstTokenOffset:<null>) (offset:41)
              element: <testLibrary>::@enum::E::@getter::bar
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F3
          type: List<E>
          constantInitializer
            fragment: #F3
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
        static final hasImplicitType hasInitializer isOriginDeclaration bar
          reference: <testLibrary>::@enum::E::@field::bar
          firstFragment: #F4
          type: InvalidType
          getter: <testLibrary>::@enum::E::@getter::bar
      constructors
        const isOriginDeclaration isPrimary new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional foo
              firstFragment: #F6
              type: int
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F7
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F8
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
        static isOriginVariable bar
          reference: <testLibrary>::@enum::E::@getter::bar
          firstFragment: #F9
          returnType: InvalidType
          variable: <testLibrary>::@enum::E::@field::bar
''');
  }

  test_typeParameters_defaultType() async {
    var library = await buildLibrary(r'''
enum A<T extends B> {
  v
}
class B {}

augment enum A<T extends B> {}
''');

    configuration.withConstantInitializers = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class B (nameOffset:34) (firstTokenOffset:28) (offset:34)
          element: <testLibrary>::@class::B
          constructors
            #F2 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:34)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
      enums
        #F3 enum A (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@enum::A
          nextFragment: #F4
          typeParameters
            #F5 T (nameOffset:7) (firstTokenOffset:7) (offset:7)
              element: #E0 T
              nextFragment: #F6
          fields
            #F7 hasInitializer isOriginDeclaration v (nameOffset:24) (firstTokenOffset:24) (offset:24)
              element: <testLibrary>::@enum::A::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibrary>::@enum::A
                      type: A<B>
                    element: ConstructorMember
                      baseElement: <testLibrary>::@enum::A::@constructor::new
                      substitution: {T: B}
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A<B>
            #F8 isOriginEnumValues values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: <testLibrary>::@enum::A::@getter::v
                      staticType: A<B>
                  rightBracket: ] @0
                  staticType: List<A<B>>
          constructors
            #F9 const isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@constructor::new
              typeName: A
          getters
            #F10 isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:24)
              element: <testLibrary>::@enum::A::@getter::v
            #F11 isOriginVariable values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::A::@getter::values
        #F4 enum A (nameOffset:53) (firstTokenOffset:40) (offset:53)
          element: <testLibrary>::@enum::A
          previousFragment: #F3
          typeParameters
            #F6 T (nameOffset:55) (firstTokenOffset:55) (offset:55)
              element: #E0 T
              previousFragment: #F5
  classes
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F1
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F2
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: #F3
      typeParameters
        #E0 T
          firstFragment: #F5
          bound: B
      supertype: Enum
      fields
        static const enumConstant hasImplicitType hasInitializer isOriginDeclaration v
          reference: <testLibrary>::@enum::A::@field::v
          firstFragment: #F7
          type: A<B>
          constantInitializer
            fragment: #F7
            expression: expression_0
          getter: <testLibrary>::@enum::A::@getter::v
        static const isOriginEnumValues values
          reference: <testLibrary>::@enum::A::@field::values
          firstFragment: #F8
          type: List<A<B>>
          constantInitializer
            fragment: #F8
            expression: expression_1
          getter: <testLibrary>::@enum::A::@getter::values
      constructors
        const isOriginImplicitDefault new
          reference: <testLibrary>::@enum::A::@constructor::new
          firstFragment: #F9
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        static isOriginVariable v
          reference: <testLibrary>::@enum::A::@getter::v
          firstFragment: #F10
          returnType: A<B>
          variable: <testLibrary>::@enum::A::@field::v
        static isOriginVariable values
          reference: <testLibrary>::@enum::A::@getter::values
          firstFragment: #F11
          returnType: List<A<B>>
          variable: <testLibrary>::@enum::A::@field::values
''');
  }
}

@reflectiveTest
class EnumElementTest_augmentation_fromBytes
    extends EnumElementTest_augmentation {
  @override
  bool get keepLinkingLibraries => false;
}

@reflectiveTest
class EnumElementTest_augmentation_keepLinking
    extends EnumElementTest_augmentation {
  @override
  bool get keepLinkingLibraries => true;
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
