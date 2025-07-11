// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../dart/resolution/node_text_expectations.dart';
import '../elements_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(EnumElementTest_keepLinking);
    defineReflectiveTests(EnumElementTest_fromBytes);
    // TODO(scheglov): implement augmentation
    // defineReflectiveTests(EnumElementTest_augmentation_keepLinking);
    // defineReflectiveTests(EnumElementTest_augmentation_fromBytes);
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
        #F1 enum E @5
          element: <testLibrary>::@enum::E
          fields
            #F2 hasInitializer aaa @11
              element: <testLibrary>::@enum::E::@field::aaa
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element2: <testLibrary>::@enum::E
                      type: E
                    element: <testLibrary>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            #F3 hasInitializer bbb @16
              element: <testLibrary>::@enum::E::@field::bbb
              initializer: expression_1
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element2: <testLibrary>::@enum::E
                      type: E
                    element: <testLibrary>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            #F4 hasInitializer ccc @21
              element: <testLibrary>::@enum::E::@field::ccc
              initializer: expression_2
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element2: <testLibrary>::@enum::E
                      type: E
                    element: <testLibrary>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            #F5 synthetic values
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
            #F6 synthetic const new
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F7 synthetic aaa
              element: <testLibrary>::@enum::E::@getter::aaa
              returnType: E
            #F8 synthetic bbb
              element: <testLibrary>::@enum::E::@getter::bbb
              returnType: E
            #F9 synthetic ccc
              element: <testLibrary>::@enum::E::@getter::ccc
              returnType: E
            #F10 synthetic values
              element: <testLibrary>::@enum::E::@getter::values
              returnType: List<E>
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasInitializer aaa
          reference: <testLibrary>::@enum::E::@field::aaa
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::aaa
        static const enumConstant hasInitializer bbb
          reference: <testLibrary>::@enum::E::@field::bbb
          firstFragment: #F3
          type: E
          constantInitializer
            fragment: #F3
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::bbb
        static const enumConstant hasInitializer ccc
          reference: <testLibrary>::@enum::E::@field::ccc
          firstFragment: #F4
          type: E
          constantInitializer
            fragment: #F4
            expression: expression_2
          getter: <testLibrary>::@enum::E::@getter::ccc
        synthetic static const values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F5
          type: List<E>
          constantInitializer
            fragment: #F5
            expression: expression_3
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        synthetic const new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F6
      getters
        synthetic static aaa
          reference: <testLibrary>::@enum::E::@getter::aaa
          firstFragment: #F7
          returnType: E
          variable: <testLibrary>::@enum::E::@field::aaa
        synthetic static bbb
          reference: <testLibrary>::@enum::E::@getter::bbb
          firstFragment: #F8
          returnType: E
          variable: <testLibrary>::@enum::E::@field::bbb
        synthetic static ccc
          reference: <testLibrary>::@enum::E::@getter::ccc
          firstFragment: #F9
          returnType: E
          variable: <testLibrary>::@enum::E::@field::ccc
        synthetic static values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F10
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
        #F1 enum E @5
          element: <testLibrary>::@enum::E
          typeParameters
            #F2 T @7
              element: #E0 T
          fields
            #F3 hasInitializer int @14
              element: <testLibrary>::@enum::E::@field::int
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element2: <testLibrary>::@enum::E
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
            #F4 hasInitializer string @22
              element: <testLibrary>::@enum::E::@field::string
              initializer: expression_1
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element2: <testLibrary>::@enum::E
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
            #F5 synthetic values
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
            #F6 const new
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
              typeNameOffset: 43
              formalParameters
                #F7 a @47
                  element: <testLibrary>::@enum::E::@constructor::new::@formalParameter::a
          getters
            #F8 synthetic int
              element: <testLibrary>::@enum::E::@getter::int
              returnType: E<int>
            #F9 synthetic string
              element: <testLibrary>::@enum::E::@getter::string
              returnType: E<String>
            #F10 synthetic values
              element: <testLibrary>::@enum::E::@getter::values
              returnType: List<E<dynamic>>
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      supertype: Enum
      fields
        static const enumConstant hasInitializer int
          reference: <testLibrary>::@enum::E::@field::int
          firstFragment: #F3
          type: E<int>
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::int
        static const enumConstant hasInitializer string
          reference: <testLibrary>::@enum::E::@field::string
          firstFragment: #F4
          type: E<String>
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::string
        synthetic static const values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F5
          type: List<E<dynamic>>
          constantInitializer
            fragment: #F5
            expression: expression_2
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        const new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F6
          formalParameters
            #E1 requiredPositional a
              firstFragment: #F7
              type: T
      getters
        synthetic static int
          reference: <testLibrary>::@enum::E::@getter::int
          firstFragment: #F8
          returnType: E<int>
          variable: <testLibrary>::@enum::E::@field::int
        synthetic static string
          reference: <testLibrary>::@enum::E::@getter::string
          firstFragment: #F9
          returnType: E<String>
          variable: <testLibrary>::@enum::E::@field::string
        synthetic static values
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
        #F1 enum E @5
          element: <testLibrary>::@enum::E
          fields
            #F2 hasInitializer _name @11
              element: <testLibrary>::@enum::E::@field::_name
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element2: <testLibrary>::@enum::E
                      type: E
                    element: <testLibrary>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            #F3 synthetic values
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
            #F4 synthetic const new
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F5 synthetic _name
              element: <testLibrary>::@enum::E::@getter::_name
              returnType: E
            #F6 synthetic values
              element: <testLibrary>::@enum::E::@getter::values
              returnType: List<E>
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasInitializer _name
          reference: <testLibrary>::@enum::E::@field::_name
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::_name
        synthetic static const values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F3
          type: List<E>
          constantInitializer
            fragment: #F3
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        synthetic const new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F4
      getters
        synthetic static _name
          reference: <testLibrary>::@enum::E::@getter::_name
          firstFragment: #F5
          returnType: E
          variable: <testLibrary>::@enum::E::@field::_name
        synthetic static values
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
        #F1 enum E @5
          element: <testLibrary>::@enum::E
          typeParameters
            #F2 T @7
              element: #E0 T
          fields
            #F3 hasInitializer v @14
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
                            element2: dart:core::@class::double
                            type: double
                        rightBracket: > @22
                      element2: <testLibrary>::@enum::E
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
            #F4 synthetic values
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
            #F5 const new
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
              typeNameOffset: 37
              formalParameters
                #F6 a @41
                  element: <testLibrary>::@enum::E::@constructor::new::@formalParameter::a
          getters
            #F7 synthetic v
              element: <testLibrary>::@enum::E::@getter::v
              returnType: E<double>
            #F8 synthetic values
              element: <testLibrary>::@enum::E::@getter::values
              returnType: List<E<dynamic>>
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      supertype: Enum
      fields
        static const enumConstant hasInitializer v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F3
          type: E<double>
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        synthetic static const values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F4
          type: List<E<dynamic>>
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        const new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F5
          formalParameters
            #E1 requiredPositional a
              firstFragment: #F6
              type: T
      getters
        synthetic static v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F7
          returnType: E<double>
          variable: <testLibrary>::@enum::E::@field::v
        synthetic static values
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
        #F1 enum E @5
          element: <testLibrary>::@enum::E
          fields
            #F2 hasInitializer _ @11
              element: <testLibrary>::@enum::E::@field::_
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element2: <testLibrary>::@enum::E
                      type: E
                    element: <testLibrary>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            #F3 synthetic values
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
            #F4 synthetic const new
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F5 synthetic _
              element: <testLibrary>::@enum::E::@getter::_
              returnType: E
            #F6 synthetic values
              element: <testLibrary>::@enum::E::@getter::values
              returnType: List<E>
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasInitializer _
          reference: <testLibrary>::@enum::E::@field::_
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::_
        synthetic static const values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F3
          type: List<E>
          constantInitializer
            fragment: #F3
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        synthetic const new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F4
      getters
        synthetic static _
          reference: <testLibrary>::@enum::E::@getter::_
          firstFragment: #F5
          returnType: E
          variable: <testLibrary>::@enum::E::@field::_
        synthetic static values
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
        #F1 enum E @5
          element: <testLibrary>::@enum::E
          fields
            #F2 hasInitializer v @11
              element: <testLibrary>::@enum::E::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element2: <testLibrary>::@enum::E
                      type: E
                    element: <testLibrary>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            #F3 synthetic values
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
            #F4 factory named @26
              element: <testLibrary>::@enum::E::@constructor::named
              typeName: E
              typeNameOffset: 24
              periodOffset: 25
            #F5 synthetic const new
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F6 synthetic v
              element: <testLibrary>::@enum::E::@getter::v
              returnType: E
            #F7 synthetic values
              element: <testLibrary>::@enum::E::@getter::values
              returnType: List<E>
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasInitializer v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        synthetic static const values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F3
          type: List<E>
          constantInitializer
            fragment: #F3
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        factory named
          reference: <testLibrary>::@enum::E::@constructor::named
          firstFragment: #F4
        synthetic const new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F5
      getters
        synthetic static v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F6
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        synthetic static values
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
        #F1 enum E @5
          element: <testLibrary>::@enum::E
          fields
            #F2 hasInitializer v @11
              element: <testLibrary>::@enum::E::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element2: <testLibrary>::@enum::E
                      type: E
                    element: <testLibrary>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            #F3 synthetic values
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
            #F4 factory new
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
              typeNameOffset: 24
          getters
            #F5 synthetic v
              element: <testLibrary>::@enum::E::@getter::v
              returnType: E
            #F6 synthetic values
              element: <testLibrary>::@enum::E::@getter::values
              returnType: List<E>
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasInitializer v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        synthetic static const values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F3
          type: List<E>
          constantInitializer
            fragment: #F3
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        factory new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F4
      getters
        synthetic static v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F5
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        synthetic static values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F6
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
        #F1 enum E @5
          element: <testLibrary>::@enum::E
          fields
            #F2 hasInitializer v @11
              element: <testLibrary>::@enum::E::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element2: <testLibrary>::@enum::E
                      type: E
                    element: <testLibrary>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            #F3 synthetic values
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
            #F4 x @22
              element: <testLibrary>::@enum::E::@field::x
          constructors
            #F5 const new
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
              typeNameOffset: 33
              formalParameters
                #F6 this.x @44
                  element: <testLibrary>::@enum::E::@constructor::new::@formalParameter::x
                  parameters
                    #F7 a @53
                      element: a@53
          getters
            #F8 synthetic v
              element: <testLibrary>::@enum::E::@getter::v
              returnType: E
            #F9 synthetic values
              element: <testLibrary>::@enum::E::@getter::values
              returnType: List<E>
            #F10 synthetic x
              element: <testLibrary>::@enum::E::@getter::x
              returnType: dynamic
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasInitializer v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        synthetic static const values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F3
          type: List<E>
          constantInitializer
            fragment: #F3
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
        final x
          reference: <testLibrary>::@enum::E::@field::x
          firstFragment: #F4
          type: dynamic
          getter: <testLibrary>::@enum::E::@getter::x
      constructors
        const new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional final x
              firstFragment: #F6
              type: int Function(double)
              formalParameters
                #E1 requiredPositional a
                  firstFragment: #F7
                  type: double
      getters
        synthetic static v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F8
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        synthetic static values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F9
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
        synthetic x
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
        #F1 enum E @5
          element: <testLibrary>::@enum::E
          fields
            #F2 hasInitializer v @11
              element: <testLibrary>::@enum::E::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element2: <testLibrary>::@enum::E
                      type: E
                    element: <testLibrary>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            #F3 synthetic values
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
            #F4 x @26
              element: <testLibrary>::@enum::E::@field::x::@def::0
            #F5 x @44
              element: <testLibrary>::@enum::E::@field::x::@def::1
          constructors
            #F6 const new
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
              typeNameOffset: 55
              formalParameters
                #F7 this.x @62
                  element: <testLibrary>::@enum::E::@constructor::new::@formalParameter::x
          getters
            #F8 synthetic v
              element: <testLibrary>::@enum::E::@getter::v
              returnType: E
            #F9 synthetic values
              element: <testLibrary>::@enum::E::@getter::values
              returnType: List<E>
            #F10 synthetic x
              element: <testLibrary>::@enum::E::@getter::x::@def::0
              returnType: int
            #F11 synthetic x
              element: <testLibrary>::@enum::E::@getter::x::@def::1
              returnType: String
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasInitializer v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        synthetic static const values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F3
          type: List<E>
          constantInitializer
            fragment: #F3
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
        final x
          reference: <testLibrary>::@enum::E::@field::x::@def::0
          firstFragment: #F4
          type: int
          getter: <testLibrary>::@enum::E::@getter::x::@def::0
        final x
          reference: <testLibrary>::@enum::E::@field::x::@def::1
          firstFragment: #F5
          type: String
          getter: <testLibrary>::@enum::E::@getter::x::@def::1
      constructors
        const new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F6
          formalParameters
            #E0 requiredPositional final hasImplicitType x
              firstFragment: #F7
              type: int
      getters
        synthetic static v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F8
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        synthetic static values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F9
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
        synthetic x
          reference: <testLibrary>::@enum::E::@getter::x::@def::0
          firstFragment: #F10
          returnType: int
          variable: <testLibrary>::@enum::E::@field::x::@def::0
        synthetic x
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
        #F1 enum E @5
          element: <testLibrary>::@enum::E
          fields
            #F2 hasInitializer v @11
              element: <testLibrary>::@enum::E::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element2: <testLibrary>::@enum::E
                      type: E
                    element: <testLibrary>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            #F3 synthetic values
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
            #F4 const new
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
              typeNameOffset: 22
              formalParameters
                #F5 this.x @29
                  element: <testLibrary>::@enum::E::@constructor::new::@formalParameter::x
          getters
            #F6 synthetic v
              element: <testLibrary>::@enum::E::@getter::v
              returnType: E
            #F7 synthetic values
              element: <testLibrary>::@enum::E::@getter::values
              returnType: List<E>
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasInitializer v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        synthetic static const values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F3
          type: List<E>
          constantInitializer
            fragment: #F3
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        const new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional final hasImplicitType x
              firstFragment: #F5
              type: dynamic
      getters
        synthetic static v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F6
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        synthetic static values
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
        #F1 enum E @5
          element: <testLibrary>::@enum::E
          fields
            #F2 hasInitializer v @11
              element: <testLibrary>::@enum::E::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element2: <testLibrary>::@enum::E
                      type: E
                    element: <testLibrary>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            #F3 synthetic values
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
            #F4 x @26
              element: <testLibrary>::@enum::E::@field::x
          constructors
            #F5 const new
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
              typeNameOffset: 37
              formalParameters
                #F6 this.x @45
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
            #F7 synthetic v
              element: <testLibrary>::@enum::E::@getter::v
              returnType: E
            #F8 synthetic values
              element: <testLibrary>::@enum::E::@getter::values
              returnType: List<E>
            #F9 synthetic x
              element: <testLibrary>::@enum::E::@getter::x
              returnType: int
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasInitializer v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        synthetic static const values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F3
          type: List<E>
          constantInitializer
            fragment: #F3
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
        final x
          reference: <testLibrary>::@enum::E::@field::x
          firstFragment: #F4
          type: int
          getter: <testLibrary>::@enum::E::@getter::x
      constructors
        const new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F5
          formalParameters
            #E0 optionalNamed final hasImplicitType x
              firstFragment: #F6
              type: int
              constantInitializer
                fragment: #F6
                expression: expression_2
      getters
        synthetic static v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F7
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        synthetic static values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F8
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
        synthetic x
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
        #F1 enum E @5
          element: <testLibrary>::@enum::E
          fields
            #F2 hasInitializer v @11
              element: <testLibrary>::@enum::E::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element2: <testLibrary>::@enum::E
                      type: E
                    element: <testLibrary>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            #F3 synthetic values
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
            #F4 x @26
              element: <testLibrary>::@enum::E::@field::x
          constructors
            #F5 const new
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
              typeNameOffset: 37
              formalParameters
                #F6 this.x @48
                  element: <testLibrary>::@enum::E::@constructor::new::@formalParameter::x
          getters
            #F7 synthetic v
              element: <testLibrary>::@enum::E::@getter::v
              returnType: E
            #F8 synthetic values
              element: <testLibrary>::@enum::E::@getter::values
              returnType: List<E>
            #F9 synthetic x
              element: <testLibrary>::@enum::E::@getter::x
              returnType: num
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasInitializer v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        synthetic static const values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F3
          type: List<E>
          constantInitializer
            fragment: #F3
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
        final x
          reference: <testLibrary>::@enum::E::@field::x
          firstFragment: #F4
          type: num
          getter: <testLibrary>::@enum::E::@getter::x
      constructors
        const new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional final x
              firstFragment: #F6
              type: int
      getters
        synthetic static v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F7
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        synthetic static values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F8
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
        synthetic x
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
        #F1 enum E @5
          element: <testLibrary>::@enum::E
          fields
            #F2 hasInitializer v @11
              element: <testLibrary>::@enum::E::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element2: <testLibrary>::@enum::E
                      type: E
                    element: <testLibrary>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            #F3 synthetic values
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
            #F4 x @22
              element: <testLibrary>::@enum::E::@field::x
          constructors
            #F5 new
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
              typeNameOffset: 27
              formalParameters
                #F6 this.x @38
                  element: <testLibrary>::@enum::E::@constructor::new::@formalParameter::x
          getters
            #F7 synthetic v
              element: <testLibrary>::@enum::E::@getter::v
              returnType: E
            #F8 synthetic values
              element: <testLibrary>::@enum::E::@getter::values
              returnType: List<E>
            #F9 synthetic x
              element: <testLibrary>::@enum::E::@getter::x
              returnType: dynamic
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasInitializer v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        synthetic static const values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F3
          type: List<E>
          constantInitializer
            fragment: #F3
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
        final x
          reference: <testLibrary>::@enum::E::@field::x
          firstFragment: #F4
          type: dynamic
          getter: <testLibrary>::@enum::E::@getter::x
      constructors
        new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional final x
              firstFragment: #F6
              type: int
      getters
        synthetic static v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F7
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        synthetic static values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F8
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
        synthetic x
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
        #F1 enum E @5
          element: <testLibrary>::@enum::E
          fields
            #F2 hasInitializer v @11
              element: <testLibrary>::@enum::E::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element2: <testLibrary>::@enum::E
                      type: E
                    element: <testLibrary>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            #F3 synthetic values
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
            #F4 x @22
              element: <testLibrary>::@enum::E::@field::x
          constructors
            #F5 new
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
              typeNameOffset: 27
              formalParameters
                #F6 this.x @34
                  element: <testLibrary>::@enum::E::@constructor::new::@formalParameter::x
          getters
            #F7 synthetic v
              element: <testLibrary>::@enum::E::@getter::v
              returnType: E
            #F8 synthetic values
              element: <testLibrary>::@enum::E::@getter::values
              returnType: List<E>
            #F9 synthetic x
              element: <testLibrary>::@enum::E::@getter::x
              returnType: dynamic
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasInitializer v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        synthetic static const values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F3
          type: List<E>
          constantInitializer
            fragment: #F3
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
        final x
          reference: <testLibrary>::@enum::E::@field::x
          firstFragment: #F4
          type: dynamic
          getter: <testLibrary>::@enum::E::@getter::x
      constructors
        new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional final hasImplicitType x
              firstFragment: #F6
              type: dynamic
      getters
        synthetic static v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F7
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        synthetic static values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F8
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
        synthetic x
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
        #F1 enum E @5
          element: <testLibrary>::@enum::E
          fields
            #F2 hasInitializer v @11
              element: <testLibrary>::@enum::E::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element2: <testLibrary>::@enum::E
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
            #F3 synthetic values
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
            #F4 const named @34
              element: <testLibrary>::@enum::E::@constructor::named
              typeName: E
              typeNameOffset: 32
              periodOffset: 33
              formalParameters
                #F5 a @44
                  element: <testLibrary>::@enum::E::@constructor::named::@formalParameter::a
          getters
            #F6 synthetic v
              element: <testLibrary>::@enum::E::@getter::v
              returnType: E
            #F7 synthetic values
              element: <testLibrary>::@enum::E::@getter::values
              returnType: List<E>
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasInitializer v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        synthetic static const values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F3
          type: List<E>
          constantInitializer
            fragment: #F3
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        const named
          reference: <testLibrary>::@enum::E::@constructor::named
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional a
              firstFragment: #F5
              type: int
      getters
        synthetic static v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F6
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        synthetic static values
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
        #F1 enum E @5
          element: <testLibrary>::@enum::E
          fields
            #F2 hasInitializer v @11
              element: <testLibrary>::@enum::E::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element2: <testLibrary>::@enum::E
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
            #F3 synthetic values
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
            #F4 const new
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
              typeNameOffset: 26
              formalParameters
                #F5 a @32
                  element: <testLibrary>::@enum::E::@constructor::new::@formalParameter::a
          getters
            #F6 synthetic v
              element: <testLibrary>::@enum::E::@getter::v
              returnType: E
            #F7 synthetic values
              element: <testLibrary>::@enum::E::@getter::values
              returnType: List<E>
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasInitializer v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        synthetic static const values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F3
          type: List<E>
          constantInitializer
            fragment: #F3
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        const new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional a
              firstFragment: #F5
              type: int
      getters
        synthetic static v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F6
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        synthetic static values
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
        #F1 enum E @5
          element: <testLibrary>::@enum::E
          typeParameters
            #F2 T @7
              element: #E0 T
          fields
            #F3 hasInitializer v @14
              element: <testLibrary>::@enum::E::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element2: <testLibrary>::@enum::E
                      type: E<dynamic>
                    element: ConstructorMember
                      baseElement: <testLibrary>::@enum::E::@constructor::new
                      substitution: {T: dynamic}
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E<dynamic>
            #F4 synthetic values
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
            #F5 x @29
              element: <testLibrary>::@enum::E::@field::x
          constructors
            #F6 const new
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
              typeNameOffset: 40
              formalParameters
                #F7 a @45
                  element: <testLibrary>::@enum::E::@constructor::new::@formalParameter::a
          getters
            #F8 synthetic v
              element: <testLibrary>::@enum::E::@getter::v
              returnType: E<dynamic>
            #F9 synthetic values
              element: <testLibrary>::@enum::E::@getter::values
              returnType: List<E<dynamic>>
            #F10 synthetic x
              element: <testLibrary>::@enum::E::@getter::x
              returnType: int
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      supertype: Enum
      fields
        static const enumConstant hasInitializer v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F3
          type: E<dynamic>
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        synthetic static const values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F4
          type: List<E<dynamic>>
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
        final x
          reference: <testLibrary>::@enum::E::@field::x
          firstFragment: #F5
          type: int
          getter: <testLibrary>::@enum::E::@getter::x
      constructors
        const new
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
                  element2: #E0 T
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
      getters
        synthetic static v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F8
          returnType: E<dynamic>
          variable: <testLibrary>::@enum::E::@field::v
        synthetic static values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F9
          returnType: List<E<dynamic>>
          variable: <testLibrary>::@enum::E::@field::values
        synthetic x
          reference: <testLibrary>::@enum::E::@getter::x
          firstFragment: #F10
          returnType: int
          variable: <testLibrary>::@enum::E::@field::x
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
        #F1 enum E @65
          element: <testLibrary>::@enum::E
          fields
            #F2 hasInitializer v @69
              element: <testLibrary>::@enum::E::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element2: <testLibrary>::@enum::E
                      type: E
                    element: <testLibrary>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            #F3 synthetic values
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
            #F4 synthetic const new
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F5 synthetic v
              element: <testLibrary>::@enum::E::@getter::v
              returnType: E
            #F6 synthetic values
              element: <testLibrary>::@enum::E::@getter::values
              returnType: List<E>
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      documentationComment: /**\n * Docs\n */
      supertype: Enum
      fields
        static const enumConstant hasInitializer v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        synthetic static const values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F3
          type: List<E>
          constantInitializer
            fragment: #F3
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        synthetic const new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F4
      getters
        synthetic static v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F5
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        synthetic static values
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
        #F1 enum E @5
          element: <testLibrary>::@enum::E
          fields
            #F2 hasInitializer v @11
              element: <testLibrary>::@enum::E::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element2: <testLibrary>::@enum::E
                      type: E
                    element: <testLibrary>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            #F3 synthetic values
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
            #F4 hasInitializer foo @22
              element: <testLibrary>::@enum::E::@field::foo
              initializer: expression_2
                IntegerLiteral
                  literal: 42 @28
                  staticType: int
          constructors
            #F5 synthetic const new
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F6 synthetic v
              element: <testLibrary>::@enum::E::@getter::v
              returnType: E
            #F7 synthetic values
              element: <testLibrary>::@enum::E::@getter::values
              returnType: List<E>
            #F8 synthetic foo
              element: <testLibrary>::@enum::E::@getter::foo
              returnType: int
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasInitializer v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        synthetic static const values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F3
          type: List<E>
          constantInitializer
            fragment: #F3
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
        final hasInitializer foo
          reference: <testLibrary>::@enum::E::@field::foo
          firstFragment: #F4
          type: int
          constantInitializer
            fragment: #F4
            expression: expression_2
          getter: <testLibrary>::@enum::E::@getter::foo
      constructors
        synthetic const new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F5
      getters
        synthetic static v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F6
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        synthetic static values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F7
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
        synthetic foo
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
        final promotable _foo
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
        #F1 enum E @5
          element: <testLibrary>::@enum::E
          fields
            #F2 hasInitializer v @10
              element: <testLibrary>::@enum::E::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element2: <testLibrary>::@enum::E
                      type: E
                    element: <testLibrary>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            #F3 synthetic values
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
            #F4 synthetic foo
              element: <testLibrary>::@enum::E::@field::foo
          constructors
            #F5 synthetic const new
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F6 synthetic v
              element: <testLibrary>::@enum::E::@getter::v
              returnType: E
            #F7 synthetic values
              element: <testLibrary>::@enum::E::@getter::values
              returnType: List<E>
            #F8 foo @23
              element: <testLibrary>::@enum::E::@getter::foo
              returnType: int
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasInitializer v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        synthetic static const values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F3
          type: List<E>
          constantInitializer
            fragment: #F3
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
        synthetic foo
          reference: <testLibrary>::@enum::E::@field::foo
          firstFragment: #F4
          type: int
          getter: <testLibrary>::@enum::E::@getter::foo
      constructors
        synthetic const new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F5
      getters
        synthetic static v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F6
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        synthetic static values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F7
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
        foo
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
        #F1 class I @6
          element: <testLibrary>::@class::I
          constructors
            #F2 synthetic new
              element: <testLibrary>::@class::I::@constructor::new
              typeName: I
      enums
        #F3 enum E @16
          element: <testLibrary>::@enum::E
          fields
            #F4 hasInitializer v @35
              element: <testLibrary>::@enum::E::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element2: <testLibrary>::@enum::E
                      type: E
                    element: <testLibrary>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            #F5 synthetic values
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
            #F6 synthetic const new
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F7 synthetic v
              element: <testLibrary>::@enum::E::@getter::v
              returnType: E
            #F8 synthetic values
              element: <testLibrary>::@enum::E::@getter::values
              returnType: List<E>
  classes
    class I
      reference: <testLibrary>::@class::I
      firstFragment: #F1
      constructors
        synthetic new
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
        static const enumConstant hasInitializer v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F4
          type: E
          constantInitializer
            fragment: #F4
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        synthetic static const values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F5
          type: List<E>
          constantInitializer
            fragment: #F5
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        synthetic const new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F6
      getters
        synthetic static v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F7
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        synthetic static values
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
        #F1 class A @6
          element: <testLibrary>::@class::A
        #F2 class C @45
          element: <testLibrary>::@class::C
      enums
        #F3 enum E @55
          element: <testLibrary>::@enum::E
          fields
            #F4 hasInitializer v @78
              element: <testLibrary>::@enum::E::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element2: <testLibrary>::@enum::E
                      type: E
                    element: <testLibrary>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            #F5 synthetic values
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
            #F6 synthetic v
              element: <testLibrary>::@enum::E::@getter::v
              returnType: E
            #F7 synthetic values
              element: <testLibrary>::@enum::E::@getter::values
              returnType: List<E>
      extensionTypes
        #F8 extension type B @26
          element: <testLibrary>::@extensionType::B
          fields
            #F9 it @32
              element: <testLibrary>::@extensionType::B::@field::it
          getters
            #F10 synthetic it
              element: <testLibrary>::@extensionType::B::@getter::it
              returnType: int
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
        static const enumConstant hasInitializer v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F4
          type: E
          constantInitializer
            fragment: #F4
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        synthetic static const values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F5
          type: List<E>
          constantInitializer
            fragment: #F5
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      getters
        synthetic static v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F6
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        synthetic static values
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
        final it
          reference: <testLibrary>::@extensionType::B::@field::it
          firstFragment: #F9
          type: int
          getter: <testLibrary>::@extensionType::B::@getter::it
      getters
        synthetic it
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
        #F1 class I @6
          element: <testLibrary>::@class::I
          typeParameters
            #F2 T @8
              element: #E0 T
          constructors
            #F3 synthetic new
              element: <testLibrary>::@class::I::@constructor::new
              typeName: I
      enums
        #F4 enum E @19
          element: <testLibrary>::@enum::E
          typeParameters
            #F5 U @21
              element: #E1 U
          fields
            #F6 hasInitializer v @44
              element: <testLibrary>::@enum::E::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element2: <testLibrary>::@enum::E
                      type: E<dynamic>
                    element: ConstructorMember
                      baseElement: <testLibrary>::@enum::E::@constructor::new
                      substitution: {U: dynamic}
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E<dynamic>
            #F7 synthetic values
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
            #F8 synthetic const new
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F9 synthetic v
              element: <testLibrary>::@enum::E::@getter::v
              returnType: E<dynamic>
            #F10 synthetic values
              element: <testLibrary>::@enum::E::@getter::values
              returnType: List<E<dynamic>>
  classes
    class I
      reference: <testLibrary>::@class::I
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      constructors
        synthetic new
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
        static const enumConstant hasInitializer v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F6
          type: E<dynamic>
          constantInitializer
            fragment: #F6
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        synthetic static const values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F7
          type: List<E<dynamic>>
          constantInitializer
            fragment: #F7
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        synthetic const new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F8
      getters
        synthetic static v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F9
          returnType: E<dynamic>
          variable: <testLibrary>::@enum::E::@field::v
        synthetic static values
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
        #F1 class X @6
          element: <testLibrary>::@class::X
          constructors
            #F2 synthetic new
              element: <testLibrary>::@class::X::@constructor::new
              typeName: X
        #F3 class Z @17
          element: <testLibrary>::@class::Z
          constructors
            #F4 synthetic new
              element: <testLibrary>::@class::Z::@constructor::new
              typeName: Z
      enums
        #F5 enum E @27
          element: <testLibrary>::@enum::E
          fields
            #F6 hasInitializer v @52
              element: <testLibrary>::@enum::E::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element2: <testLibrary>::@enum::E
                      type: E
                    element: <testLibrary>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            #F7 synthetic values
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
            #F8 synthetic const new
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F9 synthetic v
              element: <testLibrary>::@enum::E::@getter::v
              returnType: E
            #F10 synthetic values
              element: <testLibrary>::@enum::E::@getter::values
              returnType: List<E>
  classes
    class X
      reference: <testLibrary>::@class::X
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::X::@constructor::new
          firstFragment: #F2
    class Z
      reference: <testLibrary>::@class::Z
      firstFragment: #F3
      constructors
        synthetic new
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
        static const enumConstant hasInitializer v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F6
          type: E
          constantInitializer
            fragment: #F6
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        synthetic static const values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F7
          type: List<E>
          constantInitializer
            fragment: #F7
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        synthetic const new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F8
      getters
        synthetic static v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F9
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        synthetic static values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F10
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
''');
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
        #F1 enum E @5
          element: <testLibrary>::@enum::E
          typeParameters
            #F2 T @7
              element: #E0 T
          fields
            #F3 hasInitializer v @14
              element: <testLibrary>::@enum::E::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element2: <testLibrary>::@enum::E
                      type: E<dynamic>
                    element: ConstructorMember
                      baseElement: <testLibrary>::@enum::E::@constructor::new
                      substitution: {T: dynamic}
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E<dynamic>
            #F4 synthetic values
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
            #F5 synthetic const new
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F6 synthetic v
              element: <testLibrary>::@enum::E::@getter::v
              returnType: E<dynamic>
            #F7 synthetic values
              element: <testLibrary>::@enum::E::@getter::values
              returnType: List<E<dynamic>>
          methods
            #F8 foo @23
              element: <testLibrary>::@enum::E::@method::foo
              typeParameters
                #F9 U @27
                  element: #E1 U
              formalParameters
                #F10 t @32
                  element: <testLibrary>::@enum::E::@method::foo::@formalParameter::t
                #F11 u @37
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
        static const enumConstant hasInitializer v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F3
          type: E<dynamic>
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        synthetic static const values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F4
          type: List<E<dynamic>>
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        synthetic const new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F5
      getters
        synthetic static v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F6
          returnType: E<dynamic>
          variable: <testLibrary>::@enum::E::@field::v
        synthetic static values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F7
          returnType: List<E<dynamic>>
          variable: <testLibrary>::@enum::E::@field::values
      methods
        foo
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
        #F1 enum E @5
          element: <testLibrary>::@enum::E
          fields
            #F2 hasInitializer v @11
              element: <testLibrary>::@enum::E::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element2: <testLibrary>::@enum::E
                      type: E
                    element: <testLibrary>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            #F3 synthetic values
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
            #F4 synthetic const new
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F5 synthetic v
              element: <testLibrary>::@enum::E::@getter::v
              returnType: E
            #F6 synthetic values
              element: <testLibrary>::@enum::E::@getter::values
              returnType: List<E>
          methods
            #F7 toString @23
              element: <testLibrary>::@enum::E::@method::toString
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasInitializer v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        synthetic static const values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F3
          type: List<E>
          constantInitializer
            fragment: #F3
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        synthetic const new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F4
      getters
        synthetic static v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F5
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        synthetic static values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F6
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
      methods
        toString
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
        #F1 enum <null-name> (offset=0)
          element: <testLibrary>::@enum::0
          fields
            #F2 hasInitializer v @6
              element: <testLibrary>::@enum::0::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: <empty> @-1 <synthetic>
                      element2: <null>
                      type: InvalidType
                    element: <null>
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: InvalidType
            #F3 synthetic values
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
            #F4 synthetic const new
              element: <testLibrary>::@enum::0::@constructor::new
              typeName: null
          getters
            #F5 synthetic v
              element: <testLibrary>::@enum::0::@getter::v
              returnType: InvalidType
            #F6 synthetic values
              element: <testLibrary>::@enum::0::@getter::values
              returnType: List<<null>>
  enums
    enum <null-name>
      reference: <testLibrary>::@enum::0
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasInitializer v
          reference: <testLibrary>::@enum::0::@field::v
          firstFragment: #F2
          type: InvalidType
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::0::@getter::v
        synthetic static const values
          reference: <testLibrary>::@enum::0::@field::values
          firstFragment: #F3
          type: List<<null>>
          constantInitializer
            fragment: #F3
            expression: expression_1
          getter: <testLibrary>::@enum::0::@getter::values
      constructors
        synthetic const new
          reference: <testLibrary>::@enum::0::@constructor::new
          firstFragment: #F4
      getters
        synthetic static v
          reference: <testLibrary>::@enum::0::@getter::v
          firstFragment: #F5
          returnType: InvalidType
          variable: <testLibrary>::@enum::0::@field::v
        synthetic static values
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
        #F1 enum E @16
          element: <testLibrary>::@enum::E
          fields
            #F2 hasInitializer v @29
              element: <testLibrary>::@enum::E::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element2: <testLibrary>::@enum::E
                      type: E
                    element: <testLibrary>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            #F3 synthetic values
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
            #F4 synthetic const new
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F5 synthetic v
              element: <testLibrary>::@enum::E::@getter::v
              returnType: E
            #F6 synthetic values
              element: <testLibrary>::@enum::E::@getter::values
              returnType: List<E>
      mixins
        #F7 mixin M @6
          element: <testLibrary>::@mixin::M
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      mixins
        M
      fields
        static const enumConstant hasInitializer v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        synthetic static const values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F3
          type: List<E>
          constantInitializer
            fragment: #F3
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        synthetic const new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F4
      getters
        synthetic static v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F5
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        synthetic static values
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
        #F1 class A @6
          element: <testLibrary>::@class::A
        #F2 class C @45
          element: <testLibrary>::@class::C
      enums
        #F3 enum E @55
          element: <testLibrary>::@enum::E
          fields
            #F4 hasInitializer v @72
              element: <testLibrary>::@enum::E::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element2: <testLibrary>::@enum::E
                      type: E
                    element: <testLibrary>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            #F5 synthetic values
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
            #F6 synthetic v
              element: <testLibrary>::@enum::E::@getter::v
              returnType: E
            #F7 synthetic values
              element: <testLibrary>::@enum::E::@getter::values
              returnType: List<E>
      extensionTypes
        #F8 extension type B @26
          element: <testLibrary>::@extensionType::B
          fields
            #F9 it @32
              element: <testLibrary>::@extensionType::B::@field::it
          getters
            #F10 synthetic it
              element: <testLibrary>::@extensionType::B::@getter::it
              returnType: int
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
        static const enumConstant hasInitializer v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F4
          type: E
          constantInitializer
            fragment: #F4
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        synthetic static const values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F5
          type: List<E>
          constantInitializer
            fragment: #F5
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      getters
        synthetic static v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F6
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        synthetic static values
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
        final it
          reference: <testLibrary>::@extensionType::B::@field::it
          firstFragment: #F9
          type: int
          getter: <testLibrary>::@extensionType::B::@getter::it
      getters
        synthetic it
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
        #F1 enum E @44
          element: <testLibrary>::@enum::E
          fields
            #F2 hasInitializer v @67
              element: <testLibrary>::@enum::E::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element2: <testLibrary>::@enum::E
                      type: E
                    element: <testLibrary>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            #F3 synthetic values
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
            #F4 synthetic const new
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F5 synthetic v
              element: <testLibrary>::@enum::E::@getter::v
              returnType: E
            #F6 synthetic values
              element: <testLibrary>::@enum::E::@getter::values
              returnType: List<E>
      mixins
        #F7 mixin M1 @6
          element: <testLibrary>::@mixin::M1
          typeParameters
            #F8 T @9
              element: #E0 T
        #F9 mixin M2 @21
          element: <testLibrary>::@mixin::M2
          typeParameters
            #F10 T @24
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
        static const enumConstant hasInitializer v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        synthetic static const values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F3
          type: List<E>
          constantInitializer
            fragment: #F3
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        synthetic const new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F4
      getters
        synthetic static v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F5
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        synthetic static values
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
        #F1 enum E @5
          element: <testLibrary>::@enum::E
          fields
            #F2 hasInitializer v @10
              element: <testLibrary>::@enum::E::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element2: <testLibrary>::@enum::E
                      type: E
                    element: <testLibrary>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            #F3 synthetic values
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
            #F4 synthetic foo
              element: <testLibrary>::@enum::E::@field::foo
          constructors
            #F5 synthetic const new
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F6 synthetic v
              element: <testLibrary>::@enum::E::@getter::v
              returnType: E
            #F7 synthetic values
              element: <testLibrary>::@enum::E::@getter::values
              returnType: List<E>
          setters
            #F8 foo @19
              element: <testLibrary>::@enum::E::@setter::foo
              formalParameters
                #F9 _ @27
                  element: <testLibrary>::@enum::E::@setter::foo::@formalParameter::_
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasInitializer v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        synthetic static const values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F3
          type: List<E>
          constantInitializer
            fragment: #F3
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
        synthetic foo
          reference: <testLibrary>::@enum::E::@field::foo
          firstFragment: #F4
          type: int
          setter: <testLibrary>::@enum::E::@setter::foo
      constructors
        synthetic const new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F5
      getters
        synthetic static v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F6
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        synthetic static values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F7
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
      setters
        foo
          reference: <testLibrary>::@enum::E::@setter::foo
          firstFragment: #F8
          formalParameters
            #E0 requiredPositional _
              firstFragment: #F9
              type: int
          returnType: void
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
        #F1 enum E @5
          element: <testLibrary>::@enum::E
          typeParameters
            #F2 T @7
              element: #E0 T
          fields
            #F3 hasInitializer v @14
              element: <testLibrary>::@enum::E::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element2: <testLibrary>::@enum::E
                      type: E<dynamic>
                    element: ConstructorMember
                      baseElement: <testLibrary>::@enum::E::@constructor::new
                      substitution: {T: dynamic}
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E<dynamic>
            #F4 synthetic values
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
            #F5 synthetic const new
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F6 synthetic v
              element: <testLibrary>::@enum::E::@getter::v
              returnType: E<dynamic>
            #F7 synthetic values
              element: <testLibrary>::@enum::E::@getter::values
              returnType: List<E<dynamic>>
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      supertype: Enum
      fields
        static const enumConstant hasInitializer v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F3
          type: E<dynamic>
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        synthetic static const values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F4
          type: List<E<dynamic>>
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        synthetic const new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F5
      getters
        synthetic static v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F6
          returnType: E<dynamic>
          variable: <testLibrary>::@enum::E::@field::v
        synthetic static values
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
        #F1 enum E @5
          element: <testLibrary>::@enum::E
          typeParameters
            #F2 T @7
              element: #E0 T
            #F3 U @22
              element: #E1 U
          fields
            #F4 hasInitializer v @39
              element: <testLibrary>::@enum::E::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element2: <testLibrary>::@enum::E
                      type: E<num, num>
                    element: ConstructorMember
                      baseElement: <testLibrary>::@enum::E::@constructor::new
                      substitution: {T: num, U: num}
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E<num, num>
            #F5 synthetic values
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
            #F6 synthetic const new
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F7 synthetic v
              element: <testLibrary>::@enum::E::@getter::v
              returnType: E<num, num>
            #F8 synthetic values
              element: <testLibrary>::@enum::E::@getter::values
              returnType: List<E<num, num>>
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
        static const enumConstant hasInitializer v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F4
          type: E<num, num>
          constantInitializer
            fragment: #F4
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        synthetic static const values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F5
          type: List<E<num, num>>
          constantInitializer
            fragment: #F5
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        synthetic const new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F6
      getters
        synthetic static v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F7
          returnType: E<num, num>
          variable: <testLibrary>::@enum::E::@field::v
        synthetic static values
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
        #F1 enum E @5
          element: <testLibrary>::@enum::E
          typeParameters
            #F2 T @7
              element: #E0 T
          fields
            #F3 synthetic values
              element: <testLibrary>::@enum::E::@field::values
              initializer: expression_0
                ListLiteral
                  leftBracket: [ @0
                  rightBracket: ] @0
                  staticType: List<E<dynamic>>
          constructors
            #F4 synthetic const new
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F5 synthetic values
              element: <testLibrary>::@enum::E::@getter::values
              returnType: List<E<dynamic>>
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
        synthetic static const values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F3
          type: List<E<dynamic>>
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        synthetic const new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F4
      getters
        synthetic static values
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
        #F1 enum E @5
          element: <testLibrary>::@enum::E
          typeParameters
            #F2 T @7
              element: #E0 T
            #F3 U @20
              element: #E1 U
            #F4 V @35
              element: #E2 V
          fields
            #F5 synthetic values
              element: <testLibrary>::@enum::E::@field::values
              initializer: expression_0
                ListLiteral
                  leftBracket: [ @0
                  rightBracket: ] @0
                  staticType: List<E<dynamic, num, dynamic>>
          constructors
            #F6 synthetic const new
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F7 synthetic values
              element: <testLibrary>::@enum::E::@getter::values
              returnType: List<E<dynamic, num, dynamic>>
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
        synthetic static const values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F5
          type: List<E<dynamic, num, dynamic>>
          constantInitializer
            fragment: #F5
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        synthetic const new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F6
      getters
        synthetic static values
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
        #F1 enum E @5
          element: <testLibrary>::@enum::E
          typeParameters
            #F2 T @7
              element: #E0 T
          fields
            #F3 synthetic values
              element: <testLibrary>::@enum::E::@field::values
              initializer: expression_0
                ListLiteral
                  leftBracket: [ @0
                  rightBracket: ] @0
                  staticType: List<E<dynamic>>
          constructors
            #F4 synthetic const new
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F5 synthetic values
              element: <testLibrary>::@enum::E::@getter::values
              returnType: List<E<dynamic>>
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
        synthetic static const values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F3
          type: List<E<dynamic>>
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        synthetic const new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F4
      getters
        synthetic static values
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
        #F1 enum E @5
          element: <testLibrary>::@enum::E
          typeParameters
            #F2 T @10
              element: #E0 T
          fields
            #F3 synthetic values
              element: <testLibrary>::@enum::E::@field::values
              initializer: expression_0
                ListLiteral
                  leftBracket: [ @0
                  rightBracket: ] @0
                  staticType: List<E<dynamic>>
          constructors
            #F4 synthetic const new
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F5 synthetic values
              element: <testLibrary>::@enum::E::@getter::values
              returnType: List<E<dynamic>>
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      supertype: Enum
      fields
        synthetic static const values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F3
          type: List<E<dynamic>>
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        synthetic const new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F4
      getters
        synthetic static values
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
        #F1 enum E @5
          element: <testLibrary>::@enum::E
          typeParameters
            #F2 T @11
              element: #E0 T
          fields
            #F3 synthetic values
              element: <testLibrary>::@enum::E::@field::values
              initializer: expression_0
                ListLiteral
                  leftBracket: [ @0
                  rightBracket: ] @0
                  staticType: List<E<dynamic>>
          constructors
            #F4 synthetic const new
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F5 synthetic values
              element: <testLibrary>::@enum::E::@getter::values
              returnType: List<E<dynamic>>
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      supertype: Enum
      fields
        synthetic static const values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F3
          type: List<E<dynamic>>
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        synthetic const new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F4
      getters
        synthetic static values
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
        #F1 enum E @5
          element: <testLibrary>::@enum::E
          typeParameters
            #F2 T @13
              element: #E0 T
          fields
            #F3 synthetic values
              element: <testLibrary>::@enum::E::@field::values
              initializer: expression_0
                ListLiteral
                  leftBracket: [ @0
                  rightBracket: ] @0
                  staticType: List<E<dynamic>>
          constructors
            #F4 synthetic const new
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F5 synthetic values
              element: <testLibrary>::@enum::E::@getter::values
              returnType: List<E<dynamic>>
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      supertype: Enum
      fields
        synthetic static const values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F3
          type: List<E<dynamic>>
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        synthetic const new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F4
      getters
        synthetic static values
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
        #F1 enum E @5
          element: <testLibrary>::@enum::E
          typeParameters
            #F2 T @13
              element: #E0 T
            #F3 U @19
              element: #E1 U
            #F4 V @26
              element: #E2 V
          fields
            #F5 synthetic values
              element: <testLibrary>::@enum::E::@field::values
              initializer: expression_0
                ListLiteral
                  leftBracket: [ @0
                  rightBracket: ] @0
                  staticType: List<E<dynamic, dynamic, dynamic>>
          constructors
            #F6 synthetic const new
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F7 synthetic values
              element: <testLibrary>::@enum::E::@getter::values
              returnType: List<E<dynamic, dynamic, dynamic>>
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
        synthetic static const values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F5
          type: List<E<dynamic, dynamic, dynamic>>
          constantInitializer
            fragment: #F5
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        synthetic const new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F6
      getters
        synthetic static values
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
        #F1 enum E @5
          element: <testLibrary>::@enum::E
          fields
            #F2 hasInitializer a @32
              element: <testLibrary>::@enum::E::@field::a
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element2: <testLibrary>::@enum::E
                      type: E
                    element: <testLibrary>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            #F3 hasInitializer b @47
              element: <testLibrary>::@enum::E::@field::b
              initializer: expression_1
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element2: <testLibrary>::@enum::E
                      type: E
                    element: <testLibrary>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            #F4 synthetic values
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
            #F5 synthetic const new
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F6 synthetic a
              element: <testLibrary>::@enum::E::@getter::a
              returnType: E
            #F7 synthetic b
              element: <testLibrary>::@enum::E::@getter::b
              returnType: E
            #F8 synthetic values
              element: <testLibrary>::@enum::E::@getter::values
              returnType: List<E>
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasInitializer a
          reference: <testLibrary>::@enum::E::@field::a
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::a
        static const enumConstant hasInitializer b
          reference: <testLibrary>::@enum::E::@field::b
          firstFragment: #F3
          type: E
          constantInitializer
            fragment: #F3
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::b
        synthetic static const values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F4
          type: List<E>
          constantInitializer
            fragment: #F4
            expression: expression_2
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        synthetic const new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F5
      getters
        synthetic static a
          reference: <testLibrary>::@enum::E::@getter::a
          firstFragment: #F6
          returnType: E
          variable: <testLibrary>::@enum::E::@field::a
        synthetic static b
          reference: <testLibrary>::@enum::E::@getter::b
          firstFragment: #F7
          returnType: E
          variable: <testLibrary>::@enum::E::@field::b
        synthetic static values
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
        #F1 enum E @5
          element: <testLibrary>::@enum::E
          fields
            #F2 hasInitializer a @46
              element: <testLibrary>::@enum::E::@field::a
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element2: <testLibrary>::@enum::E
                      type: E
                    element: <testLibrary>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            #F3 hasInitializer b @75
              element: <testLibrary>::@enum::E::@field::b
              initializer: expression_1
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element2: <testLibrary>::@enum::E
                      type: E
                    element: <testLibrary>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            #F4 synthetic values
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
            #F5 synthetic const new
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F6 synthetic a
              element: <testLibrary>::@enum::E::@getter::a
              returnType: E
            #F7 synthetic b
              element: <testLibrary>::@enum::E::@getter::b
              returnType: E
            #F8 synthetic values
              element: <testLibrary>::@enum::E::@getter::values
              returnType: List<E>
      topLevelVariables
        #F9 hasInitializer annotation @91
          element: <testLibrary>::@topLevelVariable::annotation
          initializer: expression_3
            IntegerLiteral
              literal: 0 @104
              staticType: int
      getters
        #F10 synthetic annotation
          element: <testLibrary>::@getter::annotation
          returnType: int
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasInitializer a
          reference: <testLibrary>::@enum::E::@field::a
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::a
        static const enumConstant hasInitializer b
          reference: <testLibrary>::@enum::E::@field::b
          firstFragment: #F3
          type: E
          constantInitializer
            fragment: #F3
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::b
        synthetic static const values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F4
          type: List<E>
          constantInitializer
            fragment: #F4
            expression: expression_2
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        synthetic const new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F5
      getters
        synthetic static a
          reference: <testLibrary>::@enum::E::@getter::a
          firstFragment: #F6
          returnType: E
          variable: <testLibrary>::@enum::E::@field::a
        synthetic static b
          reference: <testLibrary>::@enum::E::@getter::b
          firstFragment: #F7
          returnType: E
          variable: <testLibrary>::@enum::E::@field::b
        synthetic static values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F8
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
  topLevelVariables
    const hasInitializer annotation
      reference: <testLibrary>::@topLevelVariable::annotation
      firstFragment: #F9
      type: int
      constantInitializer
        fragment: #F9
        expression: expression_3
      getter: <testLibrary>::@getter::annotation
  getters
    synthetic static annotation
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
        #F1 enum E @5
          element: <testLibrary>::@enum::E
          fields
            #F2 hasInitializer v @8
              element: <testLibrary>::@enum::E::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element2: <testLibrary>::@enum::E
                      type: E
                    element: <testLibrary>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            #F3 hasInitializer <null-name> (offset=10)
              element: <testLibrary>::@enum::E::@field::0
              initializer: expression_1
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element2: <testLibrary>::@enum::E
                      type: E
                    element: <testLibrary>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            #F4 synthetic values
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
            #F5 synthetic const new
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F6 synthetic v
              element: <testLibrary>::@enum::E::@getter::v
              returnType: E
            #F7 synthetic <null-name>
              element: <testLibrary>::@enum::E::@getter::1
              returnType: E
            #F8 synthetic values
              element: <testLibrary>::@enum::E::@getter::values
              returnType: List<E>
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasInitializer v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        static const enumConstant hasInitializer <null-name>
          reference: <testLibrary>::@enum::E::@field::0
          firstFragment: #F3
          type: E
          constantInitializer
            fragment: #F3
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::1
        synthetic static const values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F4
          type: List<E>
          constantInitializer
            fragment: #F4
            expression: expression_2
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        synthetic const new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F5
      getters
        synthetic static v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F6
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        synthetic static <null-name>
          reference: <testLibrary>::@enum::E::@getter::1
          firstFragment: #F7
          returnType: E
          variable: <testLibrary>::@enum::E::@field::0
        synthetic static values
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
        #F1 enum E @5
          element: <testLibrary>::@enum::E
          fields
            #F2 hasInitializer v1 @9
              element: <testLibrary>::@enum::E::@field::v1
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element2: <testLibrary>::@enum::E
                      type: E
                    element: <testLibrary>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            #F3 hasInitializer v2 @13
              element: <testLibrary>::@enum::E::@field::v2
              initializer: expression_1
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element2: <testLibrary>::@enum::E
                      type: E
                    element: <testLibrary>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            #F4 synthetic values
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
            #F5 synthetic const new
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F6 synthetic v1
              element: <testLibrary>::@enum::E::@getter::v1
              returnType: E
            #F7 synthetic v2
              element: <testLibrary>::@enum::E::@getter::v2
              returnType: E
            #F8 synthetic values
              element: <testLibrary>::@enum::E::@getter::values
              returnType: List<E>
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasInitializer v1
          reference: <testLibrary>::@enum::E::@field::v1
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v1
        static const enumConstant hasInitializer v2
          reference: <testLibrary>::@enum::E::@field::v2
          firstFragment: #F3
          type: E
          constantInitializer
            fragment: #F3
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::v2
        synthetic static const values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F4
          type: List<E>
          constantInitializer
            fragment: #F4
            expression: expression_2
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        synthetic const new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F5
      getters
        synthetic static v1
          reference: <testLibrary>::@enum::E::@getter::v1
          firstFragment: #F6
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v1
        synthetic static v2
          reference: <testLibrary>::@enum::E::@getter::v2
          firstFragment: #F7
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v2
        synthetic static values
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
        #F1 enum E1 @5
          element: <testLibrary>::@enum::E1
          fields
            #F2 hasInitializer v1 @10
              element: <testLibrary>::@enum::E1::@field::v1
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E1 @-1
                      element2: <testLibrary>::@enum::E1
                      type: E1
                    element: <testLibrary>::@enum::E1::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E1
            #F3 synthetic values
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
            #F4 synthetic const new
              element: <testLibrary>::@enum::E1::@constructor::new
              typeName: E1
          getters
            #F5 synthetic v1
              element: <testLibrary>::@enum::E1::@getter::v1
              returnType: E1
            #F6 synthetic values
              element: <testLibrary>::@enum::E1::@getter::values
              returnType: List<E1>
        #F7 enum E2 @20
          element: <testLibrary>::@enum::E2
          fields
            #F8 hasInitializer v2 @25
              element: <testLibrary>::@enum::E2::@field::v2
              initializer: expression_2
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E2 @-1
                      element2: <testLibrary>::@enum::E2
                      type: E2
                    element: <testLibrary>::@enum::E2::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E2
            #F9 synthetic values
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
            #F10 synthetic const new
              element: <testLibrary>::@enum::E2::@constructor::new
              typeName: E2
          getters
            #F11 synthetic v2
              element: <testLibrary>::@enum::E2::@getter::v2
              returnType: E2
            #F12 synthetic values
              element: <testLibrary>::@enum::E2::@getter::values
              returnType: List<E2>
  enums
    enum E1
      reference: <testLibrary>::@enum::E1
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasInitializer v1
          reference: <testLibrary>::@enum::E1::@field::v1
          firstFragment: #F2
          type: E1
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E1::@getter::v1
        synthetic static const values
          reference: <testLibrary>::@enum::E1::@field::values
          firstFragment: #F3
          type: List<E1>
          constantInitializer
            fragment: #F3
            expression: expression_1
          getter: <testLibrary>::@enum::E1::@getter::values
      constructors
        synthetic const new
          reference: <testLibrary>::@enum::E1::@constructor::new
          firstFragment: #F4
      getters
        synthetic static v1
          reference: <testLibrary>::@enum::E1::@getter::v1
          firstFragment: #F5
          returnType: E1
          variable: <testLibrary>::@enum::E1::@field::v1
        synthetic static values
          reference: <testLibrary>::@enum::E1::@getter::values
          firstFragment: #F6
          returnType: List<E1>
          variable: <testLibrary>::@enum::E1::@field::values
    enum E2
      reference: <testLibrary>::@enum::E2
      firstFragment: #F7
      supertype: Enum
      fields
        static const enumConstant hasInitializer v2
          reference: <testLibrary>::@enum::E2::@field::v2
          firstFragment: #F8
          type: E2
          constantInitializer
            fragment: #F8
            expression: expression_2
          getter: <testLibrary>::@enum::E2::@getter::v2
        synthetic static const values
          reference: <testLibrary>::@enum::E2::@field::values
          firstFragment: #F9
          type: List<E2>
          constantInitializer
            fragment: #F9
            expression: expression_3
          getter: <testLibrary>::@enum::E2::@getter::values
      constructors
        synthetic const new
          reference: <testLibrary>::@enum::E2::@constructor::new
          firstFragment: #F10
      getters
        synthetic static v2
          reference: <testLibrary>::@enum::E2::@getter::v2
          firstFragment: #F11
          returnType: E2
          variable: <testLibrary>::@enum::E2::@field::v2
        synthetic static values
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
        #F1 class M @24
          element: <testLibrary>::@class::M
          constructors
            #F2 synthetic new
              element: <testLibrary>::@class::M::@constructor::new
              typeName: M
        #F3 class A @36
          element: <testLibrary>::@class::A
          constructors
            #F4 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          methods
            #F5 foo @52
              element: <testLibrary>::@class::A::@method::foo
        #F6 class B @70
          element: <testLibrary>::@class::B
          constructors
            #F7 synthetic new
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          methods
            #F8 foo @92
              element: <testLibrary>::@class::B::@method::foo
        #F9 class C @110
          element: <testLibrary>::@class::C
          constructors
            #F10 synthetic new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          methods
            #F11 foo @141
              element: <testLibrary>::@class::C::@method::foo
        #F12 class D @159
          element: <testLibrary>::@class::D
          constructors
            #F13 synthetic const new
              element: <testLibrary>::@class::D::@constructor::new
              typeName: D
      enums
        #F14 enum E @5
          element: <testLibrary>::@enum::E
          fields
            #F15 hasInitializer a @8
              element: <testLibrary>::@enum::E::@field::a
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element2: <testLibrary>::@enum::E
                      type: E
                    element: <testLibrary>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            #F16 hasInitializer b @11
              element: <testLibrary>::@enum::E::@field::b
              initializer: expression_1
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element2: <testLibrary>::@enum::E
                      type: E
                    element: <testLibrary>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            #F17 hasInitializer c @14
              element: <testLibrary>::@enum::E::@field::c
              initializer: expression_2
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element2: <testLibrary>::@enum::E
                      type: E
                    element: <testLibrary>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            #F18 synthetic values
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
            #F19 synthetic const new
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F20 synthetic a
              element: <testLibrary>::@enum::E::@getter::a
              returnType: E
            #F21 synthetic b
              element: <testLibrary>::@enum::E::@getter::b
              returnType: E
            #F22 synthetic c
              element: <testLibrary>::@enum::E::@getter::c
              returnType: E
            #F23 synthetic values
              element: <testLibrary>::@enum::E::@getter::values
              returnType: List<E>
  classes
    class M
      reference: <testLibrary>::@class::M
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::M::@constructor::new
          firstFragment: #F2
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F3
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F4
      methods
        foo
          reference: <testLibrary>::@class::A::@method::foo
          firstFragment: #F5
          returnType: dynamic
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F6
      interfaces
        M
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F7
      methods
        foo
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
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F10
      methods
        foo
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
        synthetic const new
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
        static const enumConstant hasInitializer a
          reference: <testLibrary>::@enum::E::@field::a
          firstFragment: #F15
          type: E
          constantInitializer
            fragment: #F15
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::a
        static const enumConstant hasInitializer b
          reference: <testLibrary>::@enum::E::@field::b
          firstFragment: #F16
          type: E
          constantInitializer
            fragment: #F16
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::b
        static const enumConstant hasInitializer c
          reference: <testLibrary>::@enum::E::@field::c
          firstFragment: #F17
          type: E
          constantInitializer
            fragment: #F17
            expression: expression_2
          getter: <testLibrary>::@enum::E::@getter::c
        synthetic static const values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F18
          type: List<E>
          constantInitializer
            fragment: #F18
            expression: expression_3
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        synthetic const new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F19
      getters
        synthetic static a
          reference: <testLibrary>::@enum::E::@getter::a
          firstFragment: #F20
          returnType: E
          variable: <testLibrary>::@enum::E::@field::a
        synthetic static b
          reference: <testLibrary>::@enum::E::@getter::b
          firstFragment: #F21
          returnType: E
          variable: <testLibrary>::@enum::E::@field::b
        synthetic static c
          reference: <testLibrary>::@enum::E::@getter::c
          firstFragment: #F22
          returnType: E
          variable: <testLibrary>::@enum::E::@field::c
        synthetic static values
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
        #F1 enum E @19
          element: <testLibrary>::@enum::E
          fields
            #F2 hasInitializer v @26
              element: <testLibrary>::@enum::E::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element2: <testLibrary>::@enum::E
                      type: E
                    element: <testLibrary>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            #F3 synthetic values
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
            #F4 synthetic const new
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F5 synthetic v
              element: <testLibrary>::@enum::E::@getter::v
              returnType: E
            #F6 synthetic values
              element: <testLibrary>::@enum::E::@getter::values
              returnType: List<E>
      topLevelVariables
        #F7 hasInitializer a @6
          element: <testLibrary>::@topLevelVariable::a
          initializer: expression_2
            IntegerLiteral
              literal: 42 @10
              staticType: int
      getters
        #F8 synthetic a
          element: <testLibrary>::@getter::a
          returnType: int
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasInitializer v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        synthetic static const values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F3
          type: List<E>
          constantInitializer
            fragment: #F3
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        synthetic const new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F4
      getters
        synthetic static v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F5
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        synthetic static values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F6
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
  topLevelVariables
    const hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F7
      type: int
      constantInitializer
        fragment: #F7
        expression: expression_2
      getter: <testLibrary>::@getter::a
  getters
    synthetic static a
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
        #F1 class A @6
          element: <testLibrary>::@class::A
          fields
            #F2 value @26
              element: <testLibrary>::@class::A::@field::value
          constructors
            #F3 const new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
              typeNameOffset: 41
              formalParameters
                #F4 this.value @48
                  element: <testLibrary>::@class::A::@constructor::new::@formalParameter::value
          getters
            #F5 synthetic value
              element: <testLibrary>::@class::A::@getter::value
              returnType: dynamic
      enums
        #F6 enum E @64
          element: <testLibrary>::@enum::E
          fields
            #F7 hasInitializer a @78
              element: <testLibrary>::@enum::E::@field::a
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element2: <testLibrary>::@enum::E
                      type: E
                    element: <testLibrary>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            #F8 hasInitializer b @83
              element: <testLibrary>::@enum::E::@field::b
              initializer: expression_1
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element2: <testLibrary>::@enum::E
                      type: E
                    element: <testLibrary>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            #F9 hasInitializer c @96
              element: <testLibrary>::@enum::E::@field::c
              initializer: expression_2
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element2: <testLibrary>::@enum::E
                      type: E
                    element: <testLibrary>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            #F10 synthetic values
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
            #F11 synthetic const new
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F12 synthetic a
              element: <testLibrary>::@enum::E::@getter::a
              returnType: E
            #F13 synthetic b
              element: <testLibrary>::@enum::E::@getter::b
              returnType: E
            #F14 synthetic c
              element: <testLibrary>::@enum::E::@getter::c
              returnType: E
            #F15 synthetic values
              element: <testLibrary>::@enum::E::@getter::values
              returnType: List<E>
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        final value
          reference: <testLibrary>::@class::A::@field::value
          firstFragment: #F2
          type: dynamic
          getter: <testLibrary>::@class::A::@getter::value
      constructors
        const new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional final hasImplicitType value
              firstFragment: #F4
              type: dynamic
      getters
        synthetic value
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
        static const enumConstant hasInitializer a
          reference: <testLibrary>::@enum::E::@field::a
          firstFragment: #F7
          type: E
          constantInitializer
            fragment: #F7
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::a
        static const enumConstant hasInitializer b
          reference: <testLibrary>::@enum::E::@field::b
          firstFragment: #F8
          type: E
          constantInitializer
            fragment: #F8
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::b
        static const enumConstant hasInitializer c
          reference: <testLibrary>::@enum::E::@field::c
          firstFragment: #F9
          type: E
          constantInitializer
            fragment: #F9
            expression: expression_2
          getter: <testLibrary>::@enum::E::@getter::c
        synthetic static const values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F10
          type: List<E>
          constantInitializer
            fragment: #F10
            expression: expression_3
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        synthetic const new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F11
      getters
        synthetic static a
          reference: <testLibrary>::@enum::E::@getter::a
          firstFragment: #F12
          returnType: E
          variable: <testLibrary>::@enum::E::@field::a
        synthetic static b
          reference: <testLibrary>::@enum::E::@getter::b
          firstFragment: #F13
          returnType: E
          variable: <testLibrary>::@enum::E::@field::b
        synthetic static c
          reference: <testLibrary>::@enum::E::@getter::c
          firstFragment: #F14
          returnType: E
          variable: <testLibrary>::@enum::E::@field::c
        synthetic static values
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
        #F1 enum E @5
          element: <testLibrary>::@enum::E
          fields
            #F2 hasInitializer v @16
              element: <testLibrary>::@enum::E::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element2: <testLibrary>::@enum::E
                      type: E
                    element: <testLibrary>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            #F3 synthetic values
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
            #F4 synthetic const new
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F5 synthetic v
              element: <testLibrary>::@enum::E::@getter::v
              returnType: E
            #F6 synthetic values
              element: <testLibrary>::@enum::E::@getter::values
              returnType: List<E>
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasInitializer v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        synthetic static const values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F3
          type: List<E>
          constantInitializer
            fragment: #F3
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        synthetic const new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F4
      getters
        synthetic static v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F5
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        synthetic static values
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
        #F1 enum E @19
          element: <testLibrary>::@enum::E
          fields
            #F2 hasInitializer v @25
              element: <testLibrary>::@enum::E::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element2: <testLibrary>::@enum::E
                      type: E
                    element: <testLibrary>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            #F3 synthetic values
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
            #F4 const new
              element: <testLibrary>::@enum::E::@constructor::new
              metadata
                Annotation
                  atSign: @ @30
                  name: SimpleIdentifier
                    token: a @31
                    element: <testLibrary>::@getter::a
                    staticType: null
                  element2: <testLibrary>::@getter::a
              typeName: E
              typeNameOffset: 41
          getters
            #F5 synthetic v
              element: <testLibrary>::@enum::E::@getter::v
              returnType: E
            #F6 synthetic values
              element: <testLibrary>::@enum::E::@getter::values
              returnType: List<E>
      topLevelVariables
        #F7 hasInitializer a @6
          element: <testLibrary>::@topLevelVariable::a
          initializer: expression_2
            IntegerLiteral
              literal: 42 @10
              staticType: int
      getters
        #F8 synthetic a
          element: <testLibrary>::@getter::a
          returnType: int
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasInitializer v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        synthetic static const values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F3
          type: List<E>
          constantInitializer
            fragment: #F3
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        const new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F4
          metadata
            Annotation
              atSign: @ @30
              name: SimpleIdentifier
                token: a @31
                element: <testLibrary>::@getter::a
                staticType: null
              element2: <testLibrary>::@getter::a
      getters
        synthetic static v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F5
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        synthetic static values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F6
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
  topLevelVariables
    const hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F7
      type: int
      constantInitializer
        fragment: #F7
        expression: expression_2
      getter: <testLibrary>::@getter::a
  getters
    synthetic static a
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
        #F1 enum E @19
          element: <testLibrary>::@enum::E
          fields
            #F2 hasInitializer v @25
              element: <testLibrary>::@enum::E::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element2: <testLibrary>::@enum::E
                      type: E
                    element: <testLibrary>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            #F3 synthetic values
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
            #F4 synthetic const new
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F5 synthetic v
              element: <testLibrary>::@enum::E::@getter::v
              returnType: E
            #F6 synthetic values
              element: <testLibrary>::@enum::E::@getter::values
              returnType: List<E>
          methods
            #F7 foo @40
              element: <testLibrary>::@enum::E::@method::foo
              metadata
                Annotation
                  atSign: @ @30
                  name: SimpleIdentifier
                    token: a @31
                    element: <testLibrary>::@getter::a
                    staticType: null
                  element2: <testLibrary>::@getter::a
      topLevelVariables
        #F8 hasInitializer a @6
          element: <testLibrary>::@topLevelVariable::a
          initializer: expression_2
            IntegerLiteral
              literal: 42 @10
              staticType: int
      getters
        #F9 synthetic a
          element: <testLibrary>::@getter::a
          returnType: int
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasInitializer v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        synthetic static const values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F3
          type: List<E>
          constantInitializer
            fragment: #F3
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        synthetic const new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F4
      getters
        synthetic static v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F5
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        synthetic static values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F6
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
      methods
        foo
          reference: <testLibrary>::@enum::E::@method::foo
          firstFragment: #F7
          metadata
            Annotation
              atSign: @ @30
              name: SimpleIdentifier
                token: a @31
                element: <testLibrary>::@getter::a
                staticType: null
              element2: <testLibrary>::@getter::a
          returnType: void
  topLevelVariables
    const hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F8
      type: int
      constantInitializer
        fragment: #F8
        expression: expression_2
      getter: <testLibrary>::@getter::a
  getters
    synthetic static a
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
        #F1 enum E @26
          element: <testLibrary>::@enum::E
          typeParameters
            #F2 T @33
              element: #E0 T
              metadata
                Annotation
                  atSign: @ @28
                  name: SimpleIdentifier
                    token: foo @29
                    element: <testLibrary>::@getter::foo
                    staticType: null
                  element2: <testLibrary>::@getter::foo
          fields
            #F3 hasInitializer v @40
              element: <testLibrary>::@enum::E::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element2: <testLibrary>::@enum::E
                      type: E<dynamic>
                    element: ConstructorMember
                      baseElement: <testLibrary>::@enum::E::@constructor::new
                      substitution: {T: dynamic}
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E<dynamic>
            #F4 synthetic values
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
            #F5 hasInitializer foo @58
              element: <testLibrary>::@enum::E::@field::foo
              initializer: expression_2
                IntegerLiteral
                  literal: 1 @64
                  staticType: int
          constructors
            #F6 synthetic const new
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F7 synthetic v
              element: <testLibrary>::@enum::E::@getter::v
              returnType: E<dynamic>
            #F8 synthetic values
              element: <testLibrary>::@enum::E::@getter::values
              returnType: List<E<dynamic>>
            #F9 synthetic foo
              element: <testLibrary>::@enum::E::@getter::foo
              returnType: int
          methods
            #F10 bar @81
              element: <testLibrary>::@enum::E::@method::bar
              metadata
                Annotation
                  atSign: @ @69
                  name: SimpleIdentifier
                    token: foo @70
                    element: <testLibrary>::@enum::E::@getter::foo
                    staticType: null
                  element2: <testLibrary>::@enum::E::@getter::foo
      topLevelVariables
        #F11 hasInitializer foo @6
          element: <testLibrary>::@topLevelVariable::foo
          initializer: expression_3
            IntegerLiteral
              literal: 0 @12
              staticType: int
      getters
        #F12 synthetic foo
          element: <testLibrary>::@getter::foo
          returnType: int
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
              element2: <testLibrary>::@getter::foo
      supertype: Enum
      fields
        static const enumConstant hasInitializer v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F3
          type: E<dynamic>
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        synthetic static const values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F4
          type: List<E<dynamic>>
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
        static const hasInitializer foo
          reference: <testLibrary>::@enum::E::@field::foo
          firstFragment: #F5
          type: int
          constantInitializer
            fragment: #F5
            expression: expression_2
          getter: <testLibrary>::@enum::E::@getter::foo
      constructors
        synthetic const new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F6
      getters
        synthetic static v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F7
          returnType: E<dynamic>
          variable: <testLibrary>::@enum::E::@field::v
        synthetic static values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F8
          returnType: List<E<dynamic>>
          variable: <testLibrary>::@enum::E::@field::values
        synthetic static foo
          reference: <testLibrary>::@enum::E::@getter::foo
          firstFragment: #F9
          returnType: int
          variable: <testLibrary>::@enum::E::@field::foo
      methods
        bar
          reference: <testLibrary>::@enum::E::@method::bar
          firstFragment: #F10
          metadata
            Annotation
              atSign: @ @69
              name: SimpleIdentifier
                token: foo @70
                element: <testLibrary>::@enum::E::@getter::foo
                staticType: null
              element2: <testLibrary>::@enum::E::@getter::foo
          returnType: void
  topLevelVariables
    const hasInitializer foo
      reference: <testLibrary>::@topLevelVariable::foo
      firstFragment: #F11
      type: int
      constantInitializer
        fragment: #F11
        expression: expression_3
      getter: <testLibrary>::@getter::foo
  getters
    synthetic static foo
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
        #F1 enum E @19
          element: <testLibrary>::@enum::E
          typeParameters
            #F2 T @24
              element: #E0 T
              metadata
                Annotation
                  atSign: @ @21
                  name: SimpleIdentifier
                    token: a @22
                    element: <testLibrary>::@getter::a
                    staticType: null
                  element2: <testLibrary>::@getter::a
          fields
            #F3 hasInitializer v @31
              element: <testLibrary>::@enum::E::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element2: <testLibrary>::@enum::E
                      type: E<dynamic>
                    element: ConstructorMember
                      baseElement: <testLibrary>::@enum::E::@constructor::new
                      substitution: {T: dynamic}
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E<dynamic>
            #F4 synthetic values
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
            #F5 synthetic const new
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F6 synthetic v
              element: <testLibrary>::@enum::E::@getter::v
              returnType: E<dynamic>
            #F7 synthetic values
              element: <testLibrary>::@enum::E::@getter::values
              returnType: List<E<dynamic>>
      topLevelVariables
        #F8 hasInitializer a @6
          element: <testLibrary>::@topLevelVariable::a
          initializer: expression_2
            IntegerLiteral
              literal: 42 @10
              staticType: int
      getters
        #F9 synthetic a
          element: <testLibrary>::@getter::a
          returnType: int
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
              element2: <testLibrary>::@getter::a
      supertype: Enum
      fields
        static const enumConstant hasInitializer v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F3
          type: E<dynamic>
          constantInitializer
            fragment: #F3
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        synthetic static const values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F4
          type: List<E<dynamic>>
          constantInitializer
            fragment: #F4
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        synthetic const new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F5
      getters
        synthetic static v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F6
          returnType: E<dynamic>
          variable: <testLibrary>::@enum::E::@field::v
        synthetic static values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F7
          returnType: List<E<dynamic>>
          variable: <testLibrary>::@enum::E::@field::values
  topLevelVariables
    const hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F8
      type: int
      constantInitializer
        fragment: #F8
        expression: expression_2
      getter: <testLibrary>::@getter::a
  getters
    synthetic static a
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
        #F1 enum E @22
          element: <testLibrary>::@enum::E
          fields
            #F2 hasInitializer v @26
              element: <testLibrary>::@enum::E::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element2: <testLibrary>::@enum::E
                      type: E
                    element: <testLibrary>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            #F3 synthetic values
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
            #F4 synthetic const new
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F5 synthetic v
              element: <testLibrary>::@enum::E::@getter::v
              returnType: E
            #F6 synthetic values
              element: <testLibrary>::@enum::E::@getter::values
              returnType: List<E>
      topLevelVariables
        #F7 hasInitializer a @6
          element: <testLibrary>::@topLevelVariable::a
          initializer: expression_2
            IntegerLiteral
              literal: 42 @10
              staticType: int
      getters
        #F8 synthetic a
          element: <testLibrary>::@getter::a
          returnType: int
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasInitializer v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        synthetic static const values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F3
          type: List<E>
          constantInitializer
            fragment: #F3
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        synthetic const new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F4
      getters
        synthetic static v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F5
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        synthetic static values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F6
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
  topLevelVariables
    const hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F7
      type: int
      constantInitializer
        fragment: #F7
        expression: expression_2
      getter: <testLibrary>::@getter::a
  getters
    synthetic static a
      reference: <testLibrary>::@getter::a
      firstFragment: #F8
      returnType: int
      variable: <testLibrary>::@topLevelVariable::a
''');
  }
}

abstract class EnumElementTest_augmentation extends ElementsBaseTest {
  test_add_augment() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';

enum A {
  v;
  void foo() {}
}

augment enum A {;
  void bar() {}
}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
''');

    configuration.withConstantInitializers = false;
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
      enums
        enum A @27
          reference: <testLibrary>::@fragment::package:test/a.dart::@enum::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @33
              reference: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@field::v
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@enum::A
              type: A
              shouldUseTypeForInitializerInference: false
            synthetic static const values @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@field::values
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@enum::A
              type: List<A>
          constructors
            synthetic const @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@constructor::new
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@enum::A
          accessors
            synthetic static get v @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@getter::v
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@enum::A
              returnType: A
            synthetic static get values @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@getter::values
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@enum::A
              returnType: List<A>
          methods
            foo @43
              reference: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@method::foo
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@enum::A
              returnType: void
          augmented
            fields
              <testLibrary>::@fragment::package:test/a.dart::@enum::A::@field::v
              <testLibrary>::@fragment::package:test/a.dart::@enum::A::@field::values
            constants
              <testLibrary>::@fragment::package:test/a.dart::@enum::A::@field::v
            constructors
              <testLibrary>::@fragment::package:test/a.dart::@enum::A::@constructor::new
            accessors
              <testLibrary>::@fragment::package:test/a.dart::@enum::A::@getter::v
              <testLibrary>::@fragment::package:test/a.dart::@enum::A::@getter::values
            methods
              <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@method::bar
              <testLibrary>::@fragment::package:test/a.dart::@enum::A::@method::foo
        augment enum A @68
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@enum::A
          methods
            bar @80
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@method::bar
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
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
      enums
        enum A @27
          reference: <testLibrary>::@fragment::package:test/a.dart::@enum::A
          element: <testLibrary>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            hasInitializer v @33
              reference: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@field::v
              element: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@field::v#element
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibrary>::@fragment::package:test/a.dart::@enum::A
                      element2: <testLibrary>::@enum::A
                      type: A
                    staticElement: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@constructor::new
                    element: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              getter2: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@getter::v
            synthetic values
              reference: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@field::values
              element: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@field::values#element
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@getter::v
                      element: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@getter::v#element
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
              getter2: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@getter::values
          constructors
            synthetic const new
              reference: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@constructor::new
              element: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@constructor::new#element
              typeName: A
          getters
            synthetic get v
              reference: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@getter::v
              element: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@getter::v#element
            synthetic get values
              reference: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@getter::values
              element: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@getter::values#element
          methods
            foo @43
              reference: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@method::foo
              element: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@method::foo#element
        enum A @68
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibrary>::@enum::A
          previousFragment: <testLibrary>::@fragment::package:test/a.dart::@enum::A
          methods
            bar @80
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@method::bar
              element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@method::bar#element
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enum::A
      supertype: Enum
      fields
        static const enumConstant hasInitializer v
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@field::v
          type: A
          constantInitializer
            fragment: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@field::v
            expression: expression_0
          getter: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@getter::v#element
        synthetic static const values
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@field::values
          type: List<A>
          constantInitializer
            fragment: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@field::values
            expression: expression_1
          getter: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@getter::values#element
      constructors
        synthetic const new
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@constructor::new
      getters
        synthetic static get v
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@getter::v
        synthetic static get values
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@getter::values
      methods
        foo
          reference: <testLibrary>::@enum::A::@method::foo
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@method::foo
        bar
          reference: <testLibrary>::@enum::A::@method::bar
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@method::bar
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      parts
        part_0
          uri: package:test/a1.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a1.dart
        part_1
          uri: package:test/a2.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a2.dart
      enums
        enum A @37
          reference: <testLibraryFragment>::@enum::A
          enclosingElement3: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a1.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @43
              reference: <testLibraryFragment>::@enum::A::@field::v
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: A
              shouldUseTypeForInitializerInference: false
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: List<A>
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@enum::A
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: A
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: List<A>
          augmented
            fields
              <testLibraryFragment>::@enum::A::@field::v
              <testLibraryFragment>::@enum::A::@field::values
            constants
              <testLibraryFragment>::@enum::A::@field::v
            constructors
              <testLibraryFragment>::@enum::A::@constructor::new
            accessors
              <testLibraryFragment>::@enum::A::@getter::v
              <testLibraryFragment>::@enum::A::@getter::values
    <testLibrary>::@fragment::package:test/a1.dart
      enclosingElement3: <testLibraryFragment>
      parts
        part_2
          uri: package:test/a11.dart
          enclosingElement3: <testLibrary>::@fragment::package:test/a1.dart
          unit: <testLibrary>::@fragment::package:test/a11.dart
        part_3
          uri: package:test/a12.dart
          enclosingElement3: <testLibrary>::@fragment::package:test/a1.dart
          unit: <testLibrary>::@fragment::package:test/a12.dart
      enums
        augment enum A @68
          reference: <testLibrary>::@fragment::package:test/a1.dart::@enumAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a1.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          augmentation: <testLibrary>::@fragment::package:test/a11.dart::@enumAugmentation::A
    <testLibrary>::@fragment::package:test/a11.dart
      enclosingElement3: <testLibrary>::@fragment::package:test/a1.dart
      enums
        augment enum A @32
          reference: <testLibrary>::@fragment::package:test/a11.dart::@enumAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a11.dart
          augmentationTarget: <testLibrary>::@fragment::package:test/a1.dart::@enumAugmentation::A
          augmentation: <testLibrary>::@fragment::package:test/a12.dart::@enumAugmentation::A
    <testLibrary>::@fragment::package:test/a12.dart
      enclosingElement3: <testLibrary>::@fragment::package:test/a1.dart
      enums
        augment enum A @32
          reference: <testLibrary>::@fragment::package:test/a12.dart::@enumAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a12.dart
          augmentationTarget: <testLibrary>::@fragment::package:test/a11.dart::@enumAugmentation::A
          augmentation: <testLibrary>::@fragment::package:test/a2.dart::@enumAugmentation::A
    <testLibrary>::@fragment::package:test/a2.dart
      enclosingElement3: <testLibraryFragment>
      parts
        part_4
          uri: package:test/a21.dart
          enclosingElement3: <testLibrary>::@fragment::package:test/a2.dart
          unit: <testLibrary>::@fragment::package:test/a21.dart
        part_5
          uri: package:test/a22.dart
          enclosingElement3: <testLibrary>::@fragment::package:test/a2.dart
          unit: <testLibrary>::@fragment::package:test/a22.dart
      enums
        augment enum A @68
          reference: <testLibrary>::@fragment::package:test/a2.dart::@enumAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a2.dart
          augmentationTarget: <testLibrary>::@fragment::package:test/a12.dart::@enumAugmentation::A
          augmentation: <testLibrary>::@fragment::package:test/a21.dart::@enumAugmentation::A
    <testLibrary>::@fragment::package:test/a21.dart
      enclosingElement3: <testLibrary>::@fragment::package:test/a2.dart
      enums
        augment enum A @32
          reference: <testLibrary>::@fragment::package:test/a21.dart::@enumAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a21.dart
          augmentationTarget: <testLibrary>::@fragment::package:test/a2.dart::@enumAugmentation::A
          augmentation: <testLibrary>::@fragment::package:test/a22.dart::@enumAugmentation::A
    <testLibrary>::@fragment::package:test/a22.dart
      enclosingElement3: <testLibrary>::@fragment::package:test/a2.dart
      enums
        augment enum A @32
          reference: <testLibrary>::@fragment::package:test/a22.dart::@enumAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a22.dart
          augmentationTarget: <testLibrary>::@fragment::package:test/a21.dart::@enumAugmentation::A
  exportedReferences
    declared <testLibraryFragment>::@enum::A
  exportNamespace
    A: <testLibraryFragment>::@enum::A
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a1.dart
      enums
        enum A @37
          reference: <testLibraryFragment>::@enum::A
          element: <testLibrary>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/a1.dart::@enumAugmentation::A
          fields
            hasInitializer v @43
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <testLibraryFragment>::@enum::A::@field::v#element
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibraryFragment>::@enum::A
                      element2: <testLibrary>::@enum::A
                      type: A
                    staticElement: <testLibraryFragment>::@enum::A::@constructor::new
                    element: <testLibraryFragment>::@enum::A::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            synthetic values
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <testLibraryFragment>::@enum::A::@field::values#element
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::A::@getter::v
                      element: <testLibraryFragment>::@enum::A::@getter::v#element
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
              getter2: <testLibraryFragment>::@enum::A::@getter::values
          constructors
            synthetic const new
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <testLibraryFragment>::@enum::A::@constructor::new#element
              typeName: A
          getters
            synthetic get v
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <testLibraryFragment>::@enum::A::@getter::v#element
            synthetic get values
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <testLibraryFragment>::@enum::A::@getter::values#element
    <testLibrary>::@fragment::package:test/a1.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/a11.dart
      enums
        enum A @68
          reference: <testLibrary>::@fragment::package:test/a1.dart::@enumAugmentation::A
          element: <testLibrary>::@enum::A
          previousFragment: <testLibraryFragment>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/a11.dart::@enumAugmentation::A
    <testLibrary>::@fragment::package:test/a11.dart
      element: <testLibrary>
      enclosingFragment: <testLibrary>::@fragment::package:test/a1.dart
      previousFragment: <testLibrary>::@fragment::package:test/a1.dart
      nextFragment: <testLibrary>::@fragment::package:test/a12.dart
      enums
        enum A @32
          reference: <testLibrary>::@fragment::package:test/a11.dart::@enumAugmentation::A
          element: <testLibrary>::@enum::A
          previousFragment: <testLibrary>::@fragment::package:test/a1.dart::@enumAugmentation::A
          nextFragment: <testLibrary>::@fragment::package:test/a12.dart::@enumAugmentation::A
    <testLibrary>::@fragment::package:test/a12.dart
      element: <testLibrary>
      enclosingFragment: <testLibrary>::@fragment::package:test/a1.dart
      previousFragment: <testLibrary>::@fragment::package:test/a11.dart
      nextFragment: <testLibrary>::@fragment::package:test/a2.dart
      enums
        enum A @32
          reference: <testLibrary>::@fragment::package:test/a12.dart::@enumAugmentation::A
          element: <testLibrary>::@enum::A
          previousFragment: <testLibrary>::@fragment::package:test/a11.dart::@enumAugmentation::A
          nextFragment: <testLibrary>::@fragment::package:test/a2.dart::@enumAugmentation::A
    <testLibrary>::@fragment::package:test/a2.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibrary>::@fragment::package:test/a12.dart
      nextFragment: <testLibrary>::@fragment::package:test/a21.dart
      enums
        enum A @68
          reference: <testLibrary>::@fragment::package:test/a2.dart::@enumAugmentation::A
          element: <testLibrary>::@enum::A
          previousFragment: <testLibrary>::@fragment::package:test/a12.dart::@enumAugmentation::A
          nextFragment: <testLibrary>::@fragment::package:test/a21.dart::@enumAugmentation::A
    <testLibrary>::@fragment::package:test/a21.dart
      element: <testLibrary>
      enclosingFragment: <testLibrary>::@fragment::package:test/a2.dart
      previousFragment: <testLibrary>::@fragment::package:test/a2.dart
      nextFragment: <testLibrary>::@fragment::package:test/a22.dart
      enums
        enum A @32
          reference: <testLibrary>::@fragment::package:test/a21.dart::@enumAugmentation::A
          element: <testLibrary>::@enum::A
          previousFragment: <testLibrary>::@fragment::package:test/a2.dart::@enumAugmentation::A
          nextFragment: <testLibrary>::@fragment::package:test/a22.dart::@enumAugmentation::A
    <testLibrary>::@fragment::package:test/a22.dart
      element: <testLibrary>
      enclosingFragment: <testLibrary>::@fragment::package:test/a2.dart
      previousFragment: <testLibrary>::@fragment::package:test/a21.dart
      enums
        enum A @32
          reference: <testLibrary>::@fragment::package:test/a22.dart::@enumAugmentation::A
          element: <testLibrary>::@enum::A
          previousFragment: <testLibrary>::@fragment::package:test/a21.dart::@enumAugmentation::A
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const enumConstant hasInitializer v
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          type: A
          constantInitializer
            fragment: <testLibraryFragment>::@enum::A::@field::v
            expression: expression_0
          getter: <testLibraryFragment>::@enum::A::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          type: List<A>
          constantInitializer
            fragment: <testLibraryFragment>::@enum::A::@field::values
            expression: expression_1
          getter: <testLibraryFragment>::@enum::A::@getter::values#element
      constructors
        synthetic const new
          firstFragment: <testLibraryFragment>::@enum::A::@constructor::new
      getters
        synthetic static get v
          firstFragment: <testLibraryFragment>::@enum::A::@getter::v
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::A::@getter::values
  exportedReferences
    declared <testLibraryFragment>::@enum::A
  exportNamespace
    A: <testLibraryFragment>::@enum::A
''');
  }

  test_augmentationTarget_augmentationThenDeclaration() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';

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

    var library = await buildLibrary(r'''
part 'a.dart';
''');

    configuration.withConstantInitializers = false;
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
      enums
        augment enum A @35
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::0
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          fields
            synthetic static const values @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::0::@field::values
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::0
              type: List<A>
          constructors
            synthetic const @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::0::@constructor::new
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::0
          accessors
            synthetic static get values @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::0::@getter::values
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::0
              returnType: List<A>
          methods
            foo1 @47
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::0::@method::foo1
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::0
              returnType: void
        enum A @65
          reference: <testLibrary>::@fragment::package:test/a.dart::@enum::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::1
          supertype: Enum
          fields
            static const enumConstant v @71
              reference: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@field::v
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@enum::A
              type: A
              shouldUseTypeForInitializerInference: false
            synthetic static const values @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@field::values
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@enum::A
              type: List<A>
          constructors
            synthetic const @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@constructor::new
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@enum::A
          accessors
            synthetic static get v @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@getter::v
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@enum::A
              returnType: A
            synthetic static get values @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@getter::values
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@enum::A
              returnType: List<A>
          methods
            foo2 @81
              reference: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@method::foo2
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@enum::A
              returnType: void
          augmented
            fields
              <testLibrary>::@fragment::package:test/a.dart::@enum::A::@field::v
              <testLibrary>::@fragment::package:test/a.dart::@enum::A::@field::values
            constants
              <testLibrary>::@fragment::package:test/a.dart::@enum::A::@field::v
            constructors
              <testLibrary>::@fragment::package:test/a.dart::@enum::A::@constructor::new
            accessors
              <testLibrary>::@fragment::package:test/a.dart::@enum::A::@getter::v
              <testLibrary>::@fragment::package:test/a.dart::@enum::A::@getter::values
            methods
              <testLibrary>::@fragment::package:test/a.dart::@enum::A::@method::foo2
              <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::1::@method::foo3
        augment enum A @107
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::1
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@enum::A
          methods
            foo3 @119
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::1::@method::foo3
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::1
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
      enums
        enum A @35
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::0
          element: <testLibrary>::@enum::A::@def::0
          fields
            synthetic values
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::0::@field::values
              element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::0::@field::values#element
              initializer: expression_0
                ListLiteral
                  leftBracket: [ @0
                  rightBracket: ] @0
                  staticType: List<A>
              getter2: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::0::@getter::values
          constructors
            synthetic const new
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::0::@constructor::new
              element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::0::@constructor::new#element
              typeName: A
          getters
            synthetic get values
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::0::@getter::values
              element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::0::@getter::values#element
          methods
            foo1 @47
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::0::@method::foo1
              element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::0::@method::foo1#element
        enum A @65
          reference: <testLibrary>::@fragment::package:test/a.dart::@enum::A
          element: <testLibrary>::@enum::A::@def::1
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::1
          fields
            hasInitializer v @71
              reference: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@field::v
              element: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@field::v#element
              initializer: expression_1
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::0
                      element2: <testLibrary>::@enum::A::@def::0
                      type: A
                    staticElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::0::@constructor::new
                    element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::0::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              getter2: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@getter::v
            synthetic values
              reference: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@field::values
              element: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@field::values#element
              initializer: expression_2
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@getter::v
                      element: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@getter::v#element
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
              getter2: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@getter::values
          constructors
            synthetic const new
              reference: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@constructor::new
              element: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@constructor::new#element
              typeName: A
          getters
            synthetic get v
              reference: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@getter::v
              element: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@getter::v#element
            synthetic get values
              reference: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@getter::values
              element: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@getter::values#element
          methods
            foo2 @81
              reference: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@method::foo2
              element: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@method::foo2#element
        enum A @107
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::1
          element: <testLibrary>::@enum::A::@def::1
          previousFragment: <testLibrary>::@fragment::package:test/a.dart::@enum::A
          methods
            foo3 @119
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::1::@method::foo3
              element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::1::@method::foo3#element
  enums
    enum A
      reference: <testLibrary>::@enum::A::@def::0
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::0
      supertype: Enum
      fields
        synthetic static const values
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::0::@field::values
          type: List<A>
          constantInitializer
            fragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::0::@field::values
            expression: expression_0
          getter: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::0::@getter::values#element
      constructors
        synthetic const new
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::0::@constructor::new
      getters
        synthetic static get values
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::0::@getter::values
      methods
        foo1
          reference: <testLibrary>::@enum::A::@def::0::@method::foo1
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::0::@method::foo1
    enum A
      reference: <testLibrary>::@enum::A::@def::1
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enum::A
      supertype: Enum
      fields
        static const enumConstant hasInitializer v
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@field::v
          type: A
          constantInitializer
            fragment: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@field::v
            expression: expression_1
          getter: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@getter::v#element
        synthetic static const values
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@field::values
          type: List<A>
          constantInitializer
            fragment: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@field::values
            expression: expression_2
          getter: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@getter::values#element
      constructors
        synthetic const new
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@constructor::new
      getters
        synthetic static get v
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@getter::v
        synthetic static get values
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@getter::values
      methods
        foo2
          reference: <testLibrary>::@enum::A::@def::1::@method::foo2
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@method::foo2
        foo3
          reference: <testLibrary>::@enum::A::@def::1::@method::foo3
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::1::@method::foo3
''');
  }

  test_augmentationTarget_no2() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
part 'b.dart';
augment enum A {;
  void foo1() {}
}
''');

    newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';
augment enum A {;
  void foo2() {}
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
      parts
        part_1
          uri: package:test/b.dart
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          unit: <testLibrary>::@fragment::package:test/b.dart
      enums
        augment enum A @49
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          augmentation: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          fields
            synthetic static const values @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::values
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              type: List<A>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  rightBracket: ] @0
                  staticType: List<A>
          constructors
            synthetic const @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructor::new
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          accessors
            synthetic static get values @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::values
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              returnType: List<A>
          methods
            foo1 @61
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@method::foo1
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              returnType: void
          augmented
            fields
              <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::values
            constructors
              <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructor::new
            accessors
              <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::values
            methods
              <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@method::foo1
              <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@method::foo2
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
      enums
        augment enum A @31
          reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/b.dart
          augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          methods
            foo2 @43
              reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@method::foo2
              enclosingElement3: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
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
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      enums
        enum A @49
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibrary>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          fields
            synthetic values
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::values
              element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::values#element
              initializer: expression_0
                ListLiteral
                  leftBracket: [ @0
                  rightBracket: ] @0
                  staticType: List<A>
              getter2: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::values
          constructors
            synthetic const new
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructor::new
              element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructor::new#element
              typeName: A
          getters
            synthetic get values
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::values
              element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::values#element
          methods
            foo1 @61
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@method::foo1
              element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@method::foo1#element
    <testLibrary>::@fragment::package:test/b.dart
      element: <testLibrary>
      enclosingFragment: <testLibrary>::@fragment::package:test/a.dart
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @31
          reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          element: <testLibrary>::@enum::A
          previousFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          methods
            foo2 @43
              reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@method::foo2
              element: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@method::foo2#element
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
      supertype: Enum
      fields
        synthetic static const values
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::values
          type: List<A>
          constantInitializer
            fragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::values
            expression: expression_0
          getter: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::values#element
      constructors
        synthetic const new
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructor::new
      getters
        synthetic static get values
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::values
      methods
        foo1
          reference: <testLibrary>::@enum::A::@method::foo1
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@method::foo1
        foo2
          reference: <testLibrary>::@enum::A::@method::foo2
          firstFragment: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@method::foo2
''');
  }

  test_augmented_constants_add() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment enum A {
  v2
}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
enum A {
  v1
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
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          enclosingElement3: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v1 @26
              reference: <testLibraryFragment>::@enum::A::@field::v1
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: A
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibraryFragment>::@enum::A
                      element2: <testLibrary>::@enum::A
                      type: A
                    staticElement: <testLibraryFragment>::@enum::A::@constructor::new
                    element: <testLibraryFragment>::@enum::A::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              id: field_0
              getter: getter_0
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: List<A>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v1 @-1
                      staticElement: <testLibraryFragment>::@enum::A::@getter::v1
                      element: <testLibraryFragment>::@enum::A::@getter::v1#element
                      staticType: A
                    SimpleIdentifier
                      token: v2 @-1
                      staticElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::v2
                      element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::v2#element
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
              id: field_1
              getter: getter_1
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@enum::A
          accessors
            synthetic static get v1 @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v1
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: A
              id: getter_0
              variable: field_0
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: List<A>
              id: getter_1
              variable: field_1
          augmented
            fields
              <testLibraryFragment>::@enum::A::@field::v1
              <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::v2
              <testLibraryFragment>::@enum::A::@field::values
            constants
              <testLibraryFragment>::@enum::A::@field::v1
              <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::v2
            constructors
              <testLibraryFragment>::@enum::A::@constructor::new
            accessors
              <testLibraryFragment>::@enum::A::@getter::v1
              <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::v2
              <testLibraryFragment>::@enum::A::@getter::values
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          fields
            static const enumConstant v2 @40
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::v2
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              type: A
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibraryFragment>::@enum::A
                      element2: <testLibrary>::@enum::A
                      type: A
                    staticElement: <testLibraryFragment>::@enum::A::@constructor::new
                    element: <testLibraryFragment>::@enum::A::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              id: field_2
              getter: getter_2
          accessors
            synthetic static get v2 @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::v2
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              returnType: A
              id: getter_2
              variable: field_2
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          element: <testLibrary>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            hasInitializer v1 @26
              reference: <testLibraryFragment>::@enum::A::@field::v1
              element: <testLibraryFragment>::@enum::A::@field::v1#element
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibraryFragment>::@enum::A
                      element2: <testLibrary>::@enum::A
                      type: A
                    staticElement: <testLibraryFragment>::@enum::A::@constructor::new
                    element: <testLibraryFragment>::@enum::A::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              getter2: <testLibraryFragment>::@enum::A::@getter::v1
            synthetic values
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <testLibraryFragment>::@enum::A::@field::values#element
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v1 @-1
                      staticElement: <testLibraryFragment>::@enum::A::@getter::v1
                      element: <testLibraryFragment>::@enum::A::@getter::v1#element
                      staticType: A
                    SimpleIdentifier
                      token: v2 @-1
                      staticElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::v2
                      element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::v2#element
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
              getter2: <testLibraryFragment>::@enum::A::@getter::values
          constructors
            synthetic const new
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <testLibraryFragment>::@enum::A::@constructor::new#element
              typeName: A
          getters
            synthetic get v1
              reference: <testLibraryFragment>::@enum::A::@getter::v1
              element: <testLibraryFragment>::@enum::A::@getter::v1#element
            synthetic get values
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <testLibraryFragment>::@enum::A::@getter::values#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibrary>::@enum::A
          previousFragment: <testLibraryFragment>::@enum::A
          fields
            hasInitializer v2 @40
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::v2
              element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::v2#element
              initializer: expression_2
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibraryFragment>::@enum::A
                      element2: <testLibrary>::@enum::A
                      type: A
                    staticElement: <testLibraryFragment>::@enum::A::@constructor::new
                    element: <testLibraryFragment>::@enum::A::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              getter2: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::v2
          getters
            synthetic get v2
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::v2
              element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::v2#element
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const enumConstant hasInitializer v1
          firstFragment: <testLibraryFragment>::@enum::A::@field::v1
          type: A
          constantInitializer
            fragment: <testLibraryFragment>::@enum::A::@field::v1
            expression: expression_0
          getter: <testLibraryFragment>::@enum::A::@getter::v1#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          type: List<A>
          constantInitializer
            fragment: <testLibraryFragment>::@enum::A::@field::values
            expression: expression_1
          getter: <testLibraryFragment>::@enum::A::@getter::values#element
        static const enumConstant hasInitializer v2
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::v2
          type: A
          constantInitializer
            fragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::v2
            expression: expression_2
          getter: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::v2#element
      constructors
        synthetic const new
          firstFragment: <testLibraryFragment>::@enum::A::@constructor::new
      getters
        synthetic static get v1
          firstFragment: <testLibraryFragment>::@enum::A::@getter::v1
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::A::@getter::values
        synthetic static get v2
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::v2
''');
  }

  test_augmented_constants_add2() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment enum A {
  v2
}
''');

    newFile('$testPackageLibPath/b.dart', r'''
part of 'test.dart';
augment enum A {
  v3
}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
part 'b.dart';
enum A {
  v1
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
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
        part_1
          uri: package:test/b.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/b.dart
      enums
        enum A @35
          reference: <testLibraryFragment>::@enum::A
          enclosingElement3: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v1 @41
              reference: <testLibraryFragment>::@enum::A::@field::v1
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: A
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibraryFragment>::@enum::A
                      element2: <testLibrary>::@enum::A
                      type: A
                    staticElement: <testLibraryFragment>::@enum::A::@constructor::new
                    element: <testLibraryFragment>::@enum::A::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              id: field_0
              getter: getter_0
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: List<A>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v1 @-1
                      staticElement: <testLibraryFragment>::@enum::A::@getter::v1
                      element: <testLibraryFragment>::@enum::A::@getter::v1#element
                      staticType: A
                    SimpleIdentifier
                      token: v2 @-1
                      staticElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::v2
                      element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::v2#element
                      staticType: A
                    SimpleIdentifier
                      token: v3 @-1
                      staticElement: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@getter::v3
                      element: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@getter::v3#element
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
              id: field_1
              getter: getter_1
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@enum::A
          accessors
            synthetic static get v1 @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v1
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: A
              id: getter_0
              variable: field_0
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: List<A>
              id: getter_1
              variable: field_1
          augmented
            fields
              <testLibraryFragment>::@enum::A::@field::v1
              <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::v2
              <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@field::v3
              <testLibraryFragment>::@enum::A::@field::values
            constants
              <testLibraryFragment>::@enum::A::@field::v1
              <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::v2
              <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@field::v3
            constructors
              <testLibraryFragment>::@enum::A::@constructor::new
            accessors
              <testLibraryFragment>::@enum::A::@getter::v1
              <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::v2
              <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@getter::v3
              <testLibraryFragment>::@enum::A::@getter::values
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          augmentation: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          fields
            static const enumConstant v2 @40
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::v2
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              type: A
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibraryFragment>::@enum::A
                      element2: <testLibrary>::@enum::A
                      type: A
                    staticElement: <testLibraryFragment>::@enum::A::@constructor::new
                    element: <testLibraryFragment>::@enum::A::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              id: field_2
              getter: getter_2
          accessors
            synthetic static get v2 @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::v2
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              returnType: A
              id: getter_2
              variable: field_2
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @34
          reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/b.dart
          augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            static const enumConstant v3 @40
              reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@field::v3
              enclosingElement3: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
              type: A
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibraryFragment>::@enum::A
                      element2: <testLibrary>::@enum::A
                      type: A
                    staticElement: <testLibraryFragment>::@enum::A::@constructor::new
                    element: <testLibraryFragment>::@enum::A::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              id: field_3
              getter: getter_3
          accessors
            synthetic static get v3 @-1
              reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@getter::v3
              enclosingElement3: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
              returnType: A
              id: getter_3
              variable: field_3
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @35
          reference: <testLibraryFragment>::@enum::A
          element: <testLibrary>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            hasInitializer v1 @41
              reference: <testLibraryFragment>::@enum::A::@field::v1
              element: <testLibraryFragment>::@enum::A::@field::v1#element
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibraryFragment>::@enum::A
                      element2: <testLibrary>::@enum::A
                      type: A
                    staticElement: <testLibraryFragment>::@enum::A::@constructor::new
                    element: <testLibraryFragment>::@enum::A::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              getter2: <testLibraryFragment>::@enum::A::@getter::v1
            synthetic values
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <testLibraryFragment>::@enum::A::@field::values#element
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v1 @-1
                      staticElement: <testLibraryFragment>::@enum::A::@getter::v1
                      element: <testLibraryFragment>::@enum::A::@getter::v1#element
                      staticType: A
                    SimpleIdentifier
                      token: v2 @-1
                      staticElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::v2
                      element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::v2#element
                      staticType: A
                    SimpleIdentifier
                      token: v3 @-1
                      staticElement: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@getter::v3
                      element: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@getter::v3#element
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
              getter2: <testLibraryFragment>::@enum::A::@getter::values
          constructors
            synthetic const new
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <testLibraryFragment>::@enum::A::@constructor::new#element
              typeName: A
          getters
            synthetic get v1
              reference: <testLibraryFragment>::@enum::A::@getter::v1
              element: <testLibraryFragment>::@enum::A::@getter::v1#element
            synthetic get values
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <testLibraryFragment>::@enum::A::@getter::values#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibrary>::@enum::A
          previousFragment: <testLibraryFragment>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          fields
            hasInitializer v2 @40
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::v2
              element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::v2#element
              initializer: expression_2
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibraryFragment>::@enum::A
                      element2: <testLibrary>::@enum::A
                      type: A
                    staticElement: <testLibraryFragment>::@enum::A::@constructor::new
                    element: <testLibraryFragment>::@enum::A::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              getter2: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::v2
          getters
            synthetic get v2
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::v2
              element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::v2#element
    <testLibrary>::@fragment::package:test/b.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          element: <testLibrary>::@enum::A
          previousFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            hasInitializer v3 @40
              reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@field::v3
              element: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@field::v3#element
              initializer: expression_3
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibraryFragment>::@enum::A
                      element2: <testLibrary>::@enum::A
                      type: A
                    staticElement: <testLibraryFragment>::@enum::A::@constructor::new
                    element: <testLibraryFragment>::@enum::A::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              getter2: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@getter::v3
          getters
            synthetic get v3
              reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@getter::v3
              element: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@getter::v3#element
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const enumConstant hasInitializer v1
          firstFragment: <testLibraryFragment>::@enum::A::@field::v1
          type: A
          constantInitializer
            fragment: <testLibraryFragment>::@enum::A::@field::v1
            expression: expression_0
          getter: <testLibraryFragment>::@enum::A::@getter::v1#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          type: List<A>
          constantInitializer
            fragment: <testLibraryFragment>::@enum::A::@field::values
            expression: expression_1
          getter: <testLibraryFragment>::@enum::A::@getter::values#element
        static const enumConstant hasInitializer v2
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::v2
          type: A
          constantInitializer
            fragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::v2
            expression: expression_2
          getter: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::v2#element
        static const enumConstant hasInitializer v3
          firstFragment: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@field::v3
          type: A
          constantInitializer
            fragment: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@field::v3
            expression: expression_3
          getter: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@getter::v3#element
      constructors
        synthetic const new
          firstFragment: <testLibraryFragment>::@enum::A::@constructor::new
      getters
        synthetic static get v1
          firstFragment: <testLibraryFragment>::@enum::A::@getter::v1
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::A::@getter::values
        synthetic static get v2
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::v2
        synthetic static get v3
          firstFragment: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@getter::v3
''');
  }

  test_augmented_constants_add_augment() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment enum A {
  v2,
  augment v2
}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
enum A {
  v1
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
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          enclosingElement3: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v1 @26
              reference: <testLibraryFragment>::@enum::A::@field::v1
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: A
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibraryFragment>::@enum::A
                      element2: <testLibrary>::@enum::A
                      type: A
                    staticElement: <testLibraryFragment>::@enum::A::@constructor::new
                    element: <testLibraryFragment>::@enum::A::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              id: field_0
              getter: getter_0
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: List<A>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v1 @-1
                      staticElement: <testLibraryFragment>::@enum::A::@getter::v1
                      element: <testLibraryFragment>::@enum::A::@getter::v1#element
                      staticType: A
                    SimpleIdentifier
                      token: v2 @-1
                      staticElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::v2
                      element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::v2#element
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
              id: field_1
              getter: getter_1
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@enum::A
          accessors
            synthetic static get v1 @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v1
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: A
              id: getter_0
              variable: field_0
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: List<A>
              id: getter_1
              variable: field_1
          augmented
            fields
              <testLibraryFragment>::@enum::A::@field::v1
              <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@fieldAugmentation::v2
              <testLibraryFragment>::@enum::A::@field::values
            constants
              <testLibraryFragment>::@enum::A::@field::v1
              <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@fieldAugmentation::v2
            constructors
              <testLibraryFragment>::@enum::A::@constructor::new
            accessors
              <testLibraryFragment>::@enum::A::@getter::v1
              <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::v2
              <testLibraryFragment>::@enum::A::@getter::values
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          fields
            static const enumConstant v2 @40
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::v2
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              type: A
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibraryFragment>::@enum::A
                      element2: <testLibrary>::@enum::A
                      type: A
                    staticElement: <testLibraryFragment>::@enum::A::@constructor::new
                    element: <testLibraryFragment>::@enum::A::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              id: field_2
              getter: getter_2
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@fieldAugmentation::v2
            augment static const enumConstant v2 @54
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@fieldAugmentation::v2
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              type: A
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibraryFragment>::@enum::A
                      element2: <testLibrary>::@enum::A
                      type: A
                    staticElement: <testLibraryFragment>::@enum::A::@constructor::new
                    element: <testLibraryFragment>::@enum::A::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              id: field_3
              augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::v2
          accessors
            synthetic static get v2 @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::v2
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              returnType: A
              id: getter_2
              variable: field_2
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          element: <testLibrary>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            hasInitializer v1 @26
              reference: <testLibraryFragment>::@enum::A::@field::v1
              element: <testLibraryFragment>::@enum::A::@field::v1#element
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibraryFragment>::@enum::A
                      element2: <testLibrary>::@enum::A
                      type: A
                    staticElement: <testLibraryFragment>::@enum::A::@constructor::new
                    element: <testLibraryFragment>::@enum::A::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              getter2: <testLibraryFragment>::@enum::A::@getter::v1
            synthetic values
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <testLibraryFragment>::@enum::A::@field::values#element
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v1 @-1
                      staticElement: <testLibraryFragment>::@enum::A::@getter::v1
                      element: <testLibraryFragment>::@enum::A::@getter::v1#element
                      staticType: A
                    SimpleIdentifier
                      token: v2 @-1
                      staticElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::v2
                      element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::v2#element
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
              getter2: <testLibraryFragment>::@enum::A::@getter::values
          constructors
            synthetic const new
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <testLibraryFragment>::@enum::A::@constructor::new#element
              typeName: A
          getters
            synthetic get v1
              reference: <testLibraryFragment>::@enum::A::@getter::v1
              element: <testLibraryFragment>::@enum::A::@getter::v1#element
            synthetic get values
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <testLibraryFragment>::@enum::A::@getter::values#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibrary>::@enum::A
          previousFragment: <testLibraryFragment>::@enum::A
          fields
            hasInitializer v2 @40
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::v2
              element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::v2#element
              initializer: expression_2
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibraryFragment>::@enum::A
                      element2: <testLibrary>::@enum::A
                      type: A
                    staticElement: <testLibraryFragment>::@enum::A::@constructor::new
                    element: <testLibraryFragment>::@enum::A::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@fieldAugmentation::v2
              getter2: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::v2
            augment hasInitializer v2 @54
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@fieldAugmentation::v2
              element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::v2#element
              initializer: expression_3
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibraryFragment>::@enum::A
                      element2: <testLibrary>::@enum::A
                      type: A
                    staticElement: <testLibraryFragment>::@enum::A::@constructor::new
                    element: <testLibraryFragment>::@enum::A::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              previousFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::v2
          getters
            synthetic get v2
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::v2
              element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::v2#element
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const enumConstant hasInitializer v1
          firstFragment: <testLibraryFragment>::@enum::A::@field::v1
          type: A
          constantInitializer
            fragment: <testLibraryFragment>::@enum::A::@field::v1
            expression: expression_0
          getter: <testLibraryFragment>::@enum::A::@getter::v1#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          type: List<A>
          constantInitializer
            fragment: <testLibraryFragment>::@enum::A::@field::values
            expression: expression_1
          getter: <testLibraryFragment>::@enum::A::@getter::values#element
        static const enumConstant hasInitializer v2
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::v2
          type: A
          constantInitializer
            fragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@fieldAugmentation::v2
            expression: expression_3
          getter: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::v2#element
      constructors
        synthetic const new
          firstFragment: <testLibraryFragment>::@enum::A::@constructor::new
      getters
        synthetic static get v1
          firstFragment: <testLibraryFragment>::@enum::A::@getter::v1
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::A::@getter::values
        synthetic static get v2
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::v2
''');
  }

  test_augmented_constants_augment() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment enum A {
  augment v2
}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
enum A {
  v1, v2, v3
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
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          enclosingElement3: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v1 @26
              reference: <testLibraryFragment>::@enum::A::@field::v1
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: A
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibraryFragment>::@enum::A
                      element2: <testLibrary>::@enum::A
                      type: A
                    staticElement: <testLibraryFragment>::@enum::A::@constructor::new
                    element: <testLibraryFragment>::@enum::A::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              id: field_0
              getter: getter_0
            static const enumConstant v2 @30
              reference: <testLibraryFragment>::@enum::A::@field::v2
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: A
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibraryFragment>::@enum::A
                      element2: <testLibrary>::@enum::A
                      type: A
                    staticElement: <testLibraryFragment>::@enum::A::@constructor::new
                    element: <testLibraryFragment>::@enum::A::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              id: field_1
              getter: getter_1
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@fieldAugmentation::v2
            static const enumConstant v3 @34
              reference: <testLibraryFragment>::@enum::A::@field::v3
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: A
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibraryFragment>::@enum::A
                      element2: <testLibrary>::@enum::A
                      type: A
                    staticElement: <testLibraryFragment>::@enum::A::@constructor::new
                    element: <testLibraryFragment>::@enum::A::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              id: field_2
              getter: getter_2
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: List<A>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v1 @-1
                      staticElement: <testLibraryFragment>::@enum::A::@getter::v1
                      element: <testLibraryFragment>::@enum::A::@getter::v1#element
                      staticType: A
                    SimpleIdentifier
                      token: v2 @-1
                      staticElement: <testLibraryFragment>::@enum::A::@getter::v2
                      element: <testLibraryFragment>::@enum::A::@getter::v2#element
                      staticType: A
                    SimpleIdentifier
                      token: v3 @-1
                      staticElement: <testLibraryFragment>::@enum::A::@getter::v3
                      element: <testLibraryFragment>::@enum::A::@getter::v3#element
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
              id: field_3
              getter: getter_3
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@enum::A
          accessors
            synthetic static get v1 @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v1
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: A
              id: getter_0
              variable: field_0
            synthetic static get v2 @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v2
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: A
              id: getter_1
              variable: field_1
            synthetic static get v3 @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v3
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: A
              id: getter_2
              variable: field_2
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: List<A>
              id: getter_3
              variable: field_3
          augmented
            fields
              <testLibraryFragment>::@enum::A::@field::v1
              <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@fieldAugmentation::v2
              <testLibraryFragment>::@enum::A::@field::v3
              <testLibraryFragment>::@enum::A::@field::values
            constants
              <testLibraryFragment>::@enum::A::@field::v1
              <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@fieldAugmentation::v2
              <testLibraryFragment>::@enum::A::@field::v3
            constructors
              <testLibraryFragment>::@enum::A::@constructor::new
            accessors
              <testLibraryFragment>::@enum::A::@getter::v1
              <testLibraryFragment>::@enum::A::@getter::v2
              <testLibraryFragment>::@enum::A::@getter::v3
              <testLibraryFragment>::@enum::A::@getter::values
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          fields
            augment static const enumConstant v2 @48
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@fieldAugmentation::v2
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              type: A
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibraryFragment>::@enum::A
                      element2: <testLibrary>::@enum::A
                      type: A
                    staticElement: <testLibraryFragment>::@enum::A::@constructor::new
                    element: <testLibraryFragment>::@enum::A::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              id: field_4
              augmentationTarget: <testLibraryFragment>::@enum::A::@field::v2
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          element: <testLibrary>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            hasInitializer v1 @26
              reference: <testLibraryFragment>::@enum::A::@field::v1
              element: <testLibraryFragment>::@enum::A::@field::v1#element
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibraryFragment>::@enum::A
                      element2: <testLibrary>::@enum::A
                      type: A
                    staticElement: <testLibraryFragment>::@enum::A::@constructor::new
                    element: <testLibraryFragment>::@enum::A::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              getter2: <testLibraryFragment>::@enum::A::@getter::v1
            hasInitializer v2 @30
              reference: <testLibraryFragment>::@enum::A::@field::v2
              element: <testLibraryFragment>::@enum::A::@field::v2#element
              initializer: expression_1
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibraryFragment>::@enum::A
                      element2: <testLibrary>::@enum::A
                      type: A
                    staticElement: <testLibraryFragment>::@enum::A::@constructor::new
                    element: <testLibraryFragment>::@enum::A::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@fieldAugmentation::v2
              getter2: <testLibraryFragment>::@enum::A::@getter::v2
            hasInitializer v3 @34
              reference: <testLibraryFragment>::@enum::A::@field::v3
              element: <testLibraryFragment>::@enum::A::@field::v3#element
              initializer: expression_2
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibraryFragment>::@enum::A
                      element2: <testLibrary>::@enum::A
                      type: A
                    staticElement: <testLibraryFragment>::@enum::A::@constructor::new
                    element: <testLibraryFragment>::@enum::A::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              getter2: <testLibraryFragment>::@enum::A::@getter::v3
            synthetic values
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <testLibraryFragment>::@enum::A::@field::values#element
              initializer: expression_3
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v1 @-1
                      staticElement: <testLibraryFragment>::@enum::A::@getter::v1
                      element: <testLibraryFragment>::@enum::A::@getter::v1#element
                      staticType: A
                    SimpleIdentifier
                      token: v2 @-1
                      staticElement: <testLibraryFragment>::@enum::A::@getter::v2
                      element: <testLibraryFragment>::@enum::A::@getter::v2#element
                      staticType: A
                    SimpleIdentifier
                      token: v3 @-1
                      staticElement: <testLibraryFragment>::@enum::A::@getter::v3
                      element: <testLibraryFragment>::@enum::A::@getter::v3#element
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
              getter2: <testLibraryFragment>::@enum::A::@getter::values
          constructors
            synthetic const new
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <testLibraryFragment>::@enum::A::@constructor::new#element
              typeName: A
          getters
            synthetic get v1
              reference: <testLibraryFragment>::@enum::A::@getter::v1
              element: <testLibraryFragment>::@enum::A::@getter::v1#element
            synthetic get v2
              reference: <testLibraryFragment>::@enum::A::@getter::v2
              element: <testLibraryFragment>::@enum::A::@getter::v2#element
            synthetic get v3
              reference: <testLibraryFragment>::@enum::A::@getter::v3
              element: <testLibraryFragment>::@enum::A::@getter::v3#element
            synthetic get values
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <testLibraryFragment>::@enum::A::@getter::values#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibrary>::@enum::A
          previousFragment: <testLibraryFragment>::@enum::A
          fields
            augment hasInitializer v2 @48
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@fieldAugmentation::v2
              element: <testLibraryFragment>::@enum::A::@field::v2#element
              initializer: expression_4
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibraryFragment>::@enum::A
                      element2: <testLibrary>::@enum::A
                      type: A
                    staticElement: <testLibraryFragment>::@enum::A::@constructor::new
                    element: <testLibraryFragment>::@enum::A::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              previousFragment: <testLibraryFragment>::@enum::A::@field::v2
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const enumConstant hasInitializer v1
          firstFragment: <testLibraryFragment>::@enum::A::@field::v1
          type: A
          constantInitializer
            fragment: <testLibraryFragment>::@enum::A::@field::v1
            expression: expression_0
          getter: <testLibraryFragment>::@enum::A::@getter::v1#element
        static const enumConstant hasInitializer v3
          firstFragment: <testLibraryFragment>::@enum::A::@field::v3
          type: A
          constantInitializer
            fragment: <testLibraryFragment>::@enum::A::@field::v3
            expression: expression_2
          getter: <testLibraryFragment>::@enum::A::@getter::v3#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          type: List<A>
          constantInitializer
            fragment: <testLibraryFragment>::@enum::A::@field::values
            expression: expression_3
          getter: <testLibraryFragment>::@enum::A::@getter::values#element
        static const enumConstant hasInitializer v2
          firstFragment: <testLibraryFragment>::@enum::A::@field::v2
          type: A
          constantInitializer
            fragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@fieldAugmentation::v2
            expression: expression_4
          getter: <testLibraryFragment>::@enum::A::@getter::v2#element
      constructors
        synthetic const new
          firstFragment: <testLibraryFragment>::@enum::A::@constructor::new
      getters
        synthetic static get v1
          firstFragment: <testLibraryFragment>::@enum::A::@getter::v1
        synthetic static get v2
          firstFragment: <testLibraryFragment>::@enum::A::@getter::v2
        synthetic static get v3
          firstFragment: <testLibraryFragment>::@enum::A::@getter::v3
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::A::@getter::values
''');
  }

  test_augmented_constants_augment_withArguments() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment enum A {
  augment v1(3)
}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
enum A {
  v1(1), v2(2);
  const A(int value);
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
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          enclosingElement3: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v1 @26
              reference: <testLibraryFragment>::@enum::A::@field::v1
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: A
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibraryFragment>::@enum::A
                      element2: <testLibrary>::@enum::A
                      type: A
                    staticElement: <testLibraryFragment>::@enum::A::@constructor::new
                    element: <testLibraryFragment>::@enum::A::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    arguments
                      IntegerLiteral
                        literal: 1 @29
                        staticType: int
                    rightParenthesis: ) @0
                  staticType: A
              id: field_0
              getter: getter_0
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@fieldAugmentation::v1
            static const enumConstant v2 @33
              reference: <testLibraryFragment>::@enum::A::@field::v2
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: A
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibraryFragment>::@enum::A
                      element2: <testLibrary>::@enum::A
                      type: A
                    staticElement: <testLibraryFragment>::@enum::A::@constructor::new
                    element: <testLibraryFragment>::@enum::A::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    arguments
                      IntegerLiteral
                        literal: 2 @36
                        staticType: int
                    rightParenthesis: ) @0
                  staticType: A
              id: field_1
              getter: getter_1
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: List<A>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v1 @-1
                      staticElement: <testLibraryFragment>::@enum::A::@getter::v1
                      element: <testLibraryFragment>::@enum::A::@getter::v1#element
                      staticType: A
                    SimpleIdentifier
                      token: v2 @-1
                      staticElement: <testLibraryFragment>::@enum::A::@getter::v2
                      element: <testLibraryFragment>::@enum::A::@getter::v2#element
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
              id: field_2
              getter: getter_2
          constructors
            const @48
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@enum::A
              parameters
                requiredPositional value @54
                  type: int
          accessors
            synthetic static get v1 @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v1
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: A
              id: getter_0
              variable: field_0
            synthetic static get v2 @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v2
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: A
              id: getter_1
              variable: field_1
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: List<A>
              id: getter_2
              variable: field_2
          augmented
            fields
              <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@fieldAugmentation::v1
              <testLibraryFragment>::@enum::A::@field::v2
              <testLibraryFragment>::@enum::A::@field::values
            constants
              <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@fieldAugmentation::v1
              <testLibraryFragment>::@enum::A::@field::v2
            constructors
              <testLibraryFragment>::@enum::A::@constructor::new
            accessors
              <testLibraryFragment>::@enum::A::@getter::v1
              <testLibraryFragment>::@enum::A::@getter::v2
              <testLibraryFragment>::@enum::A::@getter::values
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          fields
            augment static const enumConstant v1 @48
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@fieldAugmentation::v1
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              type: A
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibraryFragment>::@enum::A
                      element2: <testLibrary>::@enum::A
                      type: A
                    staticElement: <testLibraryFragment>::@enum::A::@constructor::new
                    element: <testLibraryFragment>::@enum::A::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    arguments
                      IntegerLiteral
                        literal: 3 @51
                        staticType: int
                    rightParenthesis: ) @0
                  staticType: A
              id: field_3
              augmentationTarget: <testLibraryFragment>::@enum::A::@field::v1
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          element: <testLibrary>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            hasInitializer v1 @26
              reference: <testLibraryFragment>::@enum::A::@field::v1
              element: <testLibraryFragment>::@enum::A::@field::v1#element
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibraryFragment>::@enum::A
                      element2: <testLibrary>::@enum::A
                      type: A
                    staticElement: <testLibraryFragment>::@enum::A::@constructor::new
                    element: <testLibraryFragment>::@enum::A::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    arguments
                      IntegerLiteral
                        literal: 1 @29
                        staticType: int
                    rightParenthesis: ) @0
                  staticType: A
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@fieldAugmentation::v1
              getter2: <testLibraryFragment>::@enum::A::@getter::v1
            hasInitializer v2 @33
              reference: <testLibraryFragment>::@enum::A::@field::v2
              element: <testLibraryFragment>::@enum::A::@field::v2#element
              initializer: expression_1
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibraryFragment>::@enum::A
                      element2: <testLibrary>::@enum::A
                      type: A
                    staticElement: <testLibraryFragment>::@enum::A::@constructor::new
                    element: <testLibraryFragment>::@enum::A::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    arguments
                      IntegerLiteral
                        literal: 2 @36
                        staticType: int
                    rightParenthesis: ) @0
                  staticType: A
              getter2: <testLibraryFragment>::@enum::A::@getter::v2
            synthetic values
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <testLibraryFragment>::@enum::A::@field::values#element
              initializer: expression_2
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v1 @-1
                      staticElement: <testLibraryFragment>::@enum::A::@getter::v1
                      element: <testLibraryFragment>::@enum::A::@getter::v1#element
                      staticType: A
                    SimpleIdentifier
                      token: v2 @-1
                      staticElement: <testLibraryFragment>::@enum::A::@getter::v2
                      element: <testLibraryFragment>::@enum::A::@getter::v2#element
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
              getter2: <testLibraryFragment>::@enum::A::@getter::values
          constructors
            const new
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <testLibraryFragment>::@enum::A::@constructor::new#element
              typeName: A
              typeNameOffset: 48
              formalParameters
                value @54
                  element: <testLibraryFragment>::@enum::A::@constructor::new::@parameter::value#element
          getters
            synthetic get v1
              reference: <testLibraryFragment>::@enum::A::@getter::v1
              element: <testLibraryFragment>::@enum::A::@getter::v1#element
            synthetic get v2
              reference: <testLibraryFragment>::@enum::A::@getter::v2
              element: <testLibraryFragment>::@enum::A::@getter::v2#element
            synthetic get values
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <testLibraryFragment>::@enum::A::@getter::values#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibrary>::@enum::A
          previousFragment: <testLibraryFragment>::@enum::A
          fields
            augment hasInitializer v1 @48
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@fieldAugmentation::v1
              element: <testLibraryFragment>::@enum::A::@field::v1#element
              initializer: expression_3
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibraryFragment>::@enum::A
                      element2: <testLibrary>::@enum::A
                      type: A
                    staticElement: <testLibraryFragment>::@enum::A::@constructor::new
                    element: <testLibraryFragment>::@enum::A::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    arguments
                      IntegerLiteral
                        literal: 3 @51
                        staticType: int
                    rightParenthesis: ) @0
                  staticType: A
              previousFragment: <testLibraryFragment>::@enum::A::@field::v1
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const enumConstant hasInitializer v2
          firstFragment: <testLibraryFragment>::@enum::A::@field::v2
          type: A
          constantInitializer
            fragment: <testLibraryFragment>::@enum::A::@field::v2
            expression: expression_1
          getter: <testLibraryFragment>::@enum::A::@getter::v2#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          type: List<A>
          constantInitializer
            fragment: <testLibraryFragment>::@enum::A::@field::values
            expression: expression_2
          getter: <testLibraryFragment>::@enum::A::@getter::values#element
        static const enumConstant hasInitializer v1
          firstFragment: <testLibraryFragment>::@enum::A::@field::v1
          type: A
          constantInitializer
            fragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@fieldAugmentation::v1
            expression: expression_3
          getter: <testLibraryFragment>::@enum::A::@getter::v1#element
      constructors
        const new
          firstFragment: <testLibraryFragment>::@enum::A::@constructor::new
          formalParameters
            requiredPositional value
              type: int
      getters
        synthetic static get v1
          firstFragment: <testLibraryFragment>::@enum::A::@getter::v1
        synthetic static get v2
          firstFragment: <testLibraryFragment>::@enum::A::@getter::v2
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::A::@getter::values
''');
  }

  test_augmented_constants_typeParameterCountMismatch() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment enum A<T> {
  augment v
}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
enum A {
  v, v2
}
''');

    configuration
      ..withConstructors = false
      ..withConstantInitializers = false;
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
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          enclosingElement3: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: A
              shouldUseTypeForInitializerInference: false
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@fieldAugmentation::v
            static const enumConstant v2 @29
              reference: <testLibraryFragment>::@enum::A::@field::v2
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: A
              shouldUseTypeForInitializerInference: false
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: List<A>
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: A
            synthetic static get v2 @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v2
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: A
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: List<A>
          augmented
            fields
              FieldMember
                base: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@fieldAugmentation::v
                augmentationSubstitution: {T: InvalidType}
              <testLibraryFragment>::@enum::A::@field::v2
              <testLibraryFragment>::@enum::A::@field::values
            constants
              FieldMember
                base: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@fieldAugmentation::v
                augmentationSubstitution: {T: InvalidType}
              <testLibraryFragment>::@enum::A::@field::v2
            accessors
              <testLibraryFragment>::@enum::A::@getter::v
              <testLibraryFragment>::@enum::A::@getter::v2
              <testLibraryFragment>::@enum::A::@getter::values
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          typeParameters
            covariant T @36
              defaultType: dynamic
          augmentationTarget: <testLibraryFragment>::@enum::A
          fields
            augment static const enumConstant v @51
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@fieldAugmentation::v
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              type: A
              shouldUseTypeForInitializerInference: false
              augmentationTarget: <testLibraryFragment>::@enum::A::@field::v
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          element: <testLibrary>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            hasInitializer v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <testLibraryFragment>::@enum::A::@field::v#element
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibraryFragment>::@enum::A
                      element2: <testLibrary>::@enum::A
                      type: A
                    staticElement: <testLibraryFragment>::@enum::A::@constructor::new
                    element: <testLibraryFragment>::@enum::A::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@fieldAugmentation::v
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            hasInitializer v2 @29
              reference: <testLibraryFragment>::@enum::A::@field::v2
              element: <testLibraryFragment>::@enum::A::@field::v2#element
              initializer: expression_1
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibraryFragment>::@enum::A
                      element2: <testLibrary>::@enum::A
                      type: A
                    staticElement: <testLibraryFragment>::@enum::A::@constructor::new
                    element: <testLibraryFragment>::@enum::A::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              getter2: <testLibraryFragment>::@enum::A::@getter::v2
            synthetic values
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <testLibraryFragment>::@enum::A::@field::values#element
              initializer: expression_2
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::A::@getter::v
                      element: <testLibraryFragment>::@enum::A::@getter::v#element
                      staticType: A
                    SimpleIdentifier
                      token: v2 @-1
                      staticElement: <testLibraryFragment>::@enum::A::@getter::v2
                      element: <testLibraryFragment>::@enum::A::@getter::v2#element
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
              getter2: <testLibraryFragment>::@enum::A::@getter::values
          getters
            synthetic get v
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <testLibraryFragment>::@enum::A::@getter::v#element
            synthetic get v2
              reference: <testLibraryFragment>::@enum::A::@getter::v2
              element: <testLibraryFragment>::@enum::A::@getter::v2#element
            synthetic get values
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <testLibraryFragment>::@enum::A::@getter::values#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibrary>::@enum::A
          previousFragment: <testLibraryFragment>::@enum::A
          typeParameters
            T @36
              element: <not-implemented>
          fields
            augment hasInitializer v @51
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@fieldAugmentation::v
              element: <testLibraryFragment>::@enum::A::@field::v#element
              initializer: expression_3
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibraryFragment>::@enum::A
                      element2: <testLibrary>::@enum::A
                      type: A
                    staticElement: <testLibraryFragment>::@enum::A::@constructor::new
                    element: <testLibraryFragment>::@enum::A::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              previousFragment: <testLibraryFragment>::@enum::A::@field::v
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const enumConstant hasInitializer v2
          firstFragment: <testLibraryFragment>::@enum::A::@field::v2
          type: A
          constantInitializer
            fragment: <testLibraryFragment>::@enum::A::@field::v2
            expression: expression_1
          getter: <testLibraryFragment>::@enum::A::@getter::v2#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          type: List<A>
          constantInitializer
            fragment: <testLibraryFragment>::@enum::A::@field::values
            expression: expression_2
          getter: <testLibraryFragment>::@enum::A::@getter::values#element
        static const enumConstant hasInitializer v
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          type: A
          constantInitializer
            fragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@fieldAugmentation::v
            expression: expression_3
      getters
        synthetic static get v
          firstFragment: <testLibraryFragment>::@enum::A::@getter::v
        synthetic static get v2
          firstFragment: <testLibraryFragment>::@enum::A::@getter::v2
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::A::@getter::values
''');
  }

  test_augmented_constructors_add_named() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment enum A {;
  const A.named();
}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
enum A {
  v.named();
}
''');

    configuration.withConstantInitializers = false;
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
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          enclosingElement3: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: A
              shouldUseTypeForInitializerInference: false
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: List<A>
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: A
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: List<A>
          augmented
            fields
              <testLibraryFragment>::@enum::A::@field::v
              <testLibraryFragment>::@enum::A::@field::values
            constants
              <testLibraryFragment>::@enum::A::@field::v
            constructors
              <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructor::named
            accessors
              <testLibraryFragment>::@enum::A::@getter::v
              <testLibraryFragment>::@enum::A::@getter::values
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          constructors
            const named @49
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructor::named
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              periodOffset: 48
              nameEnd: 54
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          element: <testLibrary>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            hasInitializer v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <testLibraryFragment>::@enum::A::@field::v#element
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibraryFragment>::@enum::A
                      element2: <testLibrary>::@enum::A
                      type: A
                    period: . @0
                    name: SimpleIdentifier
                      token: named @-1
                      staticElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructor::named
                      element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructor::named#element
                      staticType: null
                    staticElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructor::named
                    element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructor::named#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            synthetic values
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <testLibraryFragment>::@enum::A::@field::values#element
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::A::@getter::v
                      element: <testLibraryFragment>::@enum::A::@getter::v#element
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
              getter2: <testLibraryFragment>::@enum::A::@getter::values
          getters
            synthetic get v
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <testLibraryFragment>::@enum::A::@getter::v#element
            synthetic get values
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <testLibraryFragment>::@enum::A::@getter::values#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibrary>::@enum::A
          previousFragment: <testLibraryFragment>::@enum::A
          constructors
            const named @49
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructor::named
              element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructor::named#element
              typeName: A
              typeNameOffset: 47
              periodOffset: 48
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const enumConstant hasInitializer v
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          type: A
          constantInitializer
            fragment: <testLibraryFragment>::@enum::A::@field::v
            expression: expression_0
          getter: <testLibraryFragment>::@enum::A::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          type: List<A>
          constantInitializer
            fragment: <testLibraryFragment>::@enum::A::@field::values
            expression: expression_1
          getter: <testLibraryFragment>::@enum::A::@getter::values#element
      constructors
        const named
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructor::named
      getters
        synthetic static get v
          firstFragment: <testLibraryFragment>::@enum::A::@getter::v
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::A::@getter::values
''');
  }

  test_augmented_constructors_add_named_generic() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment enum A<T2> {;
  const A.named(T2 a);
}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
enum A<T1> {
  v<int>.named()
}
''');

    configuration.withConstantInitializers = false;
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
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant T1 @22
              defaultType: dynamic
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @30
              reference: <testLibraryFragment>::@enum::A::@field::v
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: A<int>
              shouldUseTypeForInitializerInference: false
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: List<A<dynamic>>
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: A<int>
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: List<A<dynamic>>
          augmented
            fields
              <testLibraryFragment>::@enum::A::@field::v
              <testLibraryFragment>::@enum::A::@field::values
            constants
              <testLibraryFragment>::@enum::A::@field::v
            constructors
              ConstructorMember
                base: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructor::named
                augmentationSubstitution: {T2: T1}
            accessors
              <testLibraryFragment>::@enum::A::@getter::v
              <testLibraryFragment>::@enum::A::@getter::values
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          typeParameters
            covariant T2 @36
              defaultType: dynamic
          augmentationTarget: <testLibraryFragment>::@enum::A
          constructors
            const named @53
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructor::named
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              periodOffset: 52
              nameEnd: 58
              parameters
                requiredPositional a @62
                  type: T2
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          element: <testLibrary>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          typeParameters
            T1 @22
              element: <not-implemented>
          fields
            hasInitializer v @30
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <testLibraryFragment>::@enum::A::@field::v#element
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      typeArguments: TypeArgumentList
                        leftBracket: < @31
                        arguments
                          NamedType
                            name: int @32
                            element: dart:core::<fragment>::@class::int
                            element2: dart:core::@class::int
                            type: int
                        rightBracket: > @35
                      element: <testLibraryFragment>::@enum::A
                      element2: <testLibrary>::@enum::A
                      type: A<int>
                    period: . @0
                    name: SimpleIdentifier
                      token: named @-1
                      staticElement: ConstructorMember
                        base: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructor::named
                        augmentationSubstitution: {T2: T1}
                        substitution: {T1: int}
                      element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructor::named#element
                      staticType: null
                    staticElement: ConstructorMember
                      base: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructor::named
                      augmentationSubstitution: {T2: T1}
                      substitution: {T1: int}
                    element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructor::named#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A<int>
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            synthetic values
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <testLibraryFragment>::@enum::A::@field::values#element
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::A::@getter::v
                      element: <testLibraryFragment>::@enum::A::@getter::v#element
                      staticType: A<int>
                  rightBracket: ] @0
                  staticType: List<A<dynamic>>
              getter2: <testLibraryFragment>::@enum::A::@getter::values
          getters
            synthetic get v
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <testLibraryFragment>::@enum::A::@getter::v#element
            synthetic get values
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <testLibraryFragment>::@enum::A::@getter::values#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibrary>::@enum::A
          previousFragment: <testLibraryFragment>::@enum::A
          typeParameters
            T2 @36
              element: <not-implemented>
          constructors
            const named @53
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructor::named
              element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructor::named#element
              typeName: A
              typeNameOffset: 51
              periodOffset: 52
              formalParameters
                a @62
                  element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructor::named::@parameter::a#element
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: <testLibraryFragment>::@enum::A
      typeParameters
        T1
      supertype: Enum
      fields
        static const enumConstant hasInitializer v
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          type: A<int>
          constantInitializer
            fragment: <testLibraryFragment>::@enum::A::@field::v
            expression: expression_0
          getter: <testLibraryFragment>::@enum::A::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          type: List<A<dynamic>>
          constantInitializer
            fragment: <testLibraryFragment>::@enum::A::@field::values
            expression: expression_1
          getter: <testLibraryFragment>::@enum::A::@getter::values#element
      constructors
        const named
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructor::named
          formalParameters
            requiredPositional a
              type: T2
      getters
        synthetic static get v
          firstFragment: <testLibraryFragment>::@enum::A::@getter::v
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::A::@getter::values
''');
  }

  test_augmented_constructors_add_named_hasUnnamed() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment enum A {;
  const A.named();
}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
enum A {
  v;
  const A();
}
''');

    configuration.withConstantInitializers = false;
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
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          enclosingElement3: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: A
              shouldUseTypeForInitializerInference: false
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: List<A>
          constructors
            const @37
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@enum::A
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: A
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: List<A>
          augmented
            fields
              <testLibraryFragment>::@enum::A::@field::v
              <testLibraryFragment>::@enum::A::@field::values
            constants
              <testLibraryFragment>::@enum::A::@field::v
            constructors
              <testLibraryFragment>::@enum::A::@constructor::new
              <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructor::named
            accessors
              <testLibraryFragment>::@enum::A::@getter::v
              <testLibraryFragment>::@enum::A::@getter::values
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          constructors
            const named @49
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructor::named
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              periodOffset: 48
              nameEnd: 54
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          element: <testLibrary>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            hasInitializer v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <testLibraryFragment>::@enum::A::@field::v#element
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibraryFragment>::@enum::A
                      element2: <testLibrary>::@enum::A
                      type: A
                    staticElement: <testLibraryFragment>::@enum::A::@constructor::new
                    element: <testLibraryFragment>::@enum::A::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            synthetic values
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <testLibraryFragment>::@enum::A::@field::values#element
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::A::@getter::v
                      element: <testLibraryFragment>::@enum::A::@getter::v#element
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
              getter2: <testLibraryFragment>::@enum::A::@getter::values
          constructors
            const new
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <testLibraryFragment>::@enum::A::@constructor::new#element
              typeName: A
              typeNameOffset: 37
          getters
            synthetic get v
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <testLibraryFragment>::@enum::A::@getter::v#element
            synthetic get values
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <testLibraryFragment>::@enum::A::@getter::values#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibrary>::@enum::A
          previousFragment: <testLibraryFragment>::@enum::A
          constructors
            const named @49
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructor::named
              element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructor::named#element
              typeName: A
              typeNameOffset: 47
              periodOffset: 48
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const enumConstant hasInitializer v
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          type: A
          constantInitializer
            fragment: <testLibraryFragment>::@enum::A::@field::v
            expression: expression_0
          getter: <testLibraryFragment>::@enum::A::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          type: List<A>
          constantInitializer
            fragment: <testLibraryFragment>::@enum::A::@field::values
            expression: expression_1
          getter: <testLibraryFragment>::@enum::A::@getter::values#element
      constructors
        const new
          firstFragment: <testLibraryFragment>::@enum::A::@constructor::new
        const named
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructor::named
      getters
        synthetic static get v
          firstFragment: <testLibraryFragment>::@enum::A::@getter::v
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::A::@getter::values
''');
  }

  test_augmented_constructors_add_unnamed() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment enum A {;
  const A();
}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
enum A {
  v;
}
''');

    configuration.withConstantInitializers = false;
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
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          enclosingElement3: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: A
              shouldUseTypeForInitializerInference: false
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: List<A>
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: A
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: List<A>
          augmented
            fields
              <testLibraryFragment>::@enum::A::@field::v
              <testLibraryFragment>::@enum::A::@field::values
            constants
              <testLibraryFragment>::@enum::A::@field::v
            constructors
              <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructor::new
            accessors
              <testLibraryFragment>::@enum::A::@getter::v
              <testLibraryFragment>::@enum::A::@getter::values
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          constructors
            const @47
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructor::new
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          element: <testLibrary>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            hasInitializer v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <testLibraryFragment>::@enum::A::@field::v#element
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibraryFragment>::@enum::A
                      element2: <testLibrary>::@enum::A
                      type: A
                    staticElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructor::new
                    element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            synthetic values
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <testLibraryFragment>::@enum::A::@field::values#element
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::A::@getter::v
                      element: <testLibraryFragment>::@enum::A::@getter::v#element
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
              getter2: <testLibraryFragment>::@enum::A::@getter::values
          getters
            synthetic get v
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <testLibraryFragment>::@enum::A::@getter::v#element
            synthetic get values
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <testLibraryFragment>::@enum::A::@getter::values#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibrary>::@enum::A
          previousFragment: <testLibraryFragment>::@enum::A
          constructors
            const new
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructor::new
              element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructor::new#element
              typeName: A
              typeNameOffset: 47
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const enumConstant hasInitializer v
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          type: A
          constantInitializer
            fragment: <testLibraryFragment>::@enum::A::@field::v
            expression: expression_0
          getter: <testLibraryFragment>::@enum::A::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          type: List<A>
          constantInitializer
            fragment: <testLibraryFragment>::@enum::A::@field::values
            expression: expression_1
          getter: <testLibraryFragment>::@enum::A::@getter::values#element
      constructors
        const new
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructor::new
      getters
        synthetic static get v
          firstFragment: <testLibraryFragment>::@enum::A::@getter::v
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::A::@getter::values
''');
  }

  test_augmented_constructors_add_unnamed_hasNamed() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment enum A {;
  const A();
}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
enum A {
  v;
  const A.named();
}
''');

    configuration.withConstantInitializers = false;
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
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          enclosingElement3: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: A
              shouldUseTypeForInitializerInference: false
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: List<A>
          constructors
            const named @39
              reference: <testLibraryFragment>::@enum::A::@constructor::named
              enclosingElement3: <testLibraryFragment>::@enum::A
              periodOffset: 38
              nameEnd: 44
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: A
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: List<A>
          augmented
            fields
              <testLibraryFragment>::@enum::A::@field::v
              <testLibraryFragment>::@enum::A::@field::values
            constants
              <testLibraryFragment>::@enum::A::@field::v
            constructors
              <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructor::new
              <testLibraryFragment>::@enum::A::@constructor::named
            accessors
              <testLibraryFragment>::@enum::A::@getter::v
              <testLibraryFragment>::@enum::A::@getter::values
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          constructors
            const @47
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructor::new
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          element: <testLibrary>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            hasInitializer v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <testLibraryFragment>::@enum::A::@field::v#element
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibraryFragment>::@enum::A
                      element2: <testLibrary>::@enum::A
                      type: A
                    staticElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructor::new
                    element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            synthetic values
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <testLibraryFragment>::@enum::A::@field::values#element
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::A::@getter::v
                      element: <testLibraryFragment>::@enum::A::@getter::v#element
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
              getter2: <testLibraryFragment>::@enum::A::@getter::values
          constructors
            const named @39
              reference: <testLibraryFragment>::@enum::A::@constructor::named
              element: <testLibraryFragment>::@enum::A::@constructor::named#element
              typeName: A
              typeNameOffset: 37
              periodOffset: 38
          getters
            synthetic get v
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <testLibraryFragment>::@enum::A::@getter::v#element
            synthetic get values
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <testLibraryFragment>::@enum::A::@getter::values#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibrary>::@enum::A
          previousFragment: <testLibraryFragment>::@enum::A
          constructors
            const new
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructor::new
              element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructor::new#element
              typeName: A
              typeNameOffset: 47
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const enumConstant hasInitializer v
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          type: A
          constantInitializer
            fragment: <testLibraryFragment>::@enum::A::@field::v
            expression: expression_0
          getter: <testLibraryFragment>::@enum::A::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          type: List<A>
          constantInitializer
            fragment: <testLibraryFragment>::@enum::A::@field::values
            expression: expression_1
          getter: <testLibraryFragment>::@enum::A::@getter::values#element
      constructors
        const named
          firstFragment: <testLibraryFragment>::@enum::A::@constructor::named
        const new
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructor::new
      getters
        synthetic static get v
          firstFragment: <testLibraryFragment>::@enum::A::@getter::v
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::A::@getter::values
''');
  }

  test_augmented_constructors_add_useFieldFormal() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment enum A {;
  const A.named(this.f);
}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
enum A {
  v(0);
  final int f;
}
''');

    configuration.withConstantInitializers = false;
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
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          enclosingElement3: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: A
              shouldUseTypeForInitializerInference: false
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: List<A>
            final f @44
              reference: <testLibraryFragment>::@enum::A::@field::f
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: int
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: A
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: List<A>
            synthetic get f @-1
              reference: <testLibraryFragment>::@enum::A::@getter::f
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: int
          augmented
            fields
              <testLibraryFragment>::@enum::A::@field::f
              <testLibraryFragment>::@enum::A::@field::v
              <testLibraryFragment>::@enum::A::@field::values
            constants
              <testLibraryFragment>::@enum::A::@field::v
            constructors
              <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructor::named
            accessors
              <testLibraryFragment>::@enum::A::@getter::f
              <testLibraryFragment>::@enum::A::@getter::v
              <testLibraryFragment>::@enum::A::@getter::values
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          constructors
            const named @49
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructor::named
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              periodOffset: 48
              nameEnd: 54
              parameters
                requiredPositional final hasImplicitType this.f @60
                  type: int
                  field: <testLibraryFragment>::@enum::A::@field::f
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          element: <testLibrary>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            hasInitializer v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <testLibraryFragment>::@enum::A::@field::v#element
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibraryFragment>::@enum::A
                      element2: <testLibrary>::@enum::A
                      type: A
                    staticElement: <null>
                    element: <null>
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    arguments
                      IntegerLiteral
                        literal: 0 @28
                        staticType: int
                    rightParenthesis: ) @0
                  staticType: A
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            synthetic values
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <testLibraryFragment>::@enum::A::@field::values#element
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::A::@getter::v
                      element: <testLibraryFragment>::@enum::A::@getter::v#element
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
              getter2: <testLibraryFragment>::@enum::A::@getter::values
            f @44
              reference: <testLibraryFragment>::@enum::A::@field::f
              element: <testLibraryFragment>::@enum::A::@field::f#element
              getter2: <testLibraryFragment>::@enum::A::@getter::f
          getters
            synthetic get v
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <testLibraryFragment>::@enum::A::@getter::v#element
            synthetic get values
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <testLibraryFragment>::@enum::A::@getter::values#element
            synthetic get f
              reference: <testLibraryFragment>::@enum::A::@getter::f
              element: <testLibraryFragment>::@enum::A::@getter::f#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibrary>::@enum::A
          previousFragment: <testLibraryFragment>::@enum::A
          constructors
            const named @49
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructor::named
              element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructor::named#element
              typeName: A
              typeNameOffset: 47
              periodOffset: 48
              formalParameters
                this.f @60
                  element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructor::named::@parameter::f#element
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const enumConstant hasInitializer v
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          type: A
          constantInitializer
            fragment: <testLibraryFragment>::@enum::A::@field::v
            expression: expression_0
          getter: <testLibraryFragment>::@enum::A::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          type: List<A>
          constantInitializer
            fragment: <testLibraryFragment>::@enum::A::@field::values
            expression: expression_1
          getter: <testLibraryFragment>::@enum::A::@getter::values#element
        final f
          firstFragment: <testLibraryFragment>::@enum::A::@field::f
          type: int
          getter: <testLibraryFragment>::@enum::A::@getter::f#element
      constructors
        const named
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructor::named
          formalParameters
            requiredPositional final hasImplicitType f
              type: int
      getters
        synthetic static get v
          firstFragment: <testLibraryFragment>::@enum::A::@getter::v
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::A::@getter::values
        synthetic get f
          firstFragment: <testLibraryFragment>::@enum::A::@getter::f
''');
  }

  test_augmented_constructors_add_useFieldInitializer() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment enum A {;
  const A.named() : f = 0;
}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
enum A {
  v;
  final int f;
}
''');

    configuration.withConstantInitializers = false;
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
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          enclosingElement3: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: A
              shouldUseTypeForInitializerInference: false
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: List<A>
            final f @41
              reference: <testLibraryFragment>::@enum::A::@field::f
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: int
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: A
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: List<A>
            synthetic get f @-1
              reference: <testLibraryFragment>::@enum::A::@getter::f
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: int
          augmented
            fields
              <testLibraryFragment>::@enum::A::@field::f
              <testLibraryFragment>::@enum::A::@field::v
              <testLibraryFragment>::@enum::A::@field::values
            constants
              <testLibraryFragment>::@enum::A::@field::v
            constructors
              <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructor::named
            accessors
              <testLibraryFragment>::@enum::A::@getter::f
              <testLibraryFragment>::@enum::A::@getter::v
              <testLibraryFragment>::@enum::A::@getter::values
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          constructors
            const named @49
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructor::named
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              periodOffset: 48
              nameEnd: 54
              constantInitializers
                ConstructorFieldInitializer
                  fieldName: SimpleIdentifier
                    token: f @59
                    staticElement: <testLibraryFragment>::@enum::A::@field::f
                    element: <testLibraryFragment>::@enum::A::@field::f#element
                    staticType: null
                  equals: = @61
                  expression: IntegerLiteral
                    literal: 0 @63
                    staticType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          element: <testLibrary>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            hasInitializer v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <testLibraryFragment>::@enum::A::@field::v#element
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibraryFragment>::@enum::A
                      element2: <testLibrary>::@enum::A
                      type: A
                    staticElement: <null>
                    element: <null>
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            synthetic values
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <testLibraryFragment>::@enum::A::@field::values#element
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::A::@getter::v
                      element: <testLibraryFragment>::@enum::A::@getter::v#element
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
              getter2: <testLibraryFragment>::@enum::A::@getter::values
            f @41
              reference: <testLibraryFragment>::@enum::A::@field::f
              element: <testLibraryFragment>::@enum::A::@field::f#element
              getter2: <testLibraryFragment>::@enum::A::@getter::f
          getters
            synthetic get v
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <testLibraryFragment>::@enum::A::@getter::v#element
            synthetic get values
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <testLibraryFragment>::@enum::A::@getter::values#element
            synthetic get f
              reference: <testLibraryFragment>::@enum::A::@getter::f
              element: <testLibraryFragment>::@enum::A::@getter::f#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibrary>::@enum::A
          previousFragment: <testLibraryFragment>::@enum::A
          constructors
            const named @49
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructor::named
              element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructor::named#element
              typeName: A
              typeNameOffset: 47
              periodOffset: 48
              constantInitializers
                ConstructorFieldInitializer
                  fieldName: SimpleIdentifier
                    token: f @59
                    staticElement: <testLibraryFragment>::@enum::A::@field::f
                    element: <testLibraryFragment>::@enum::A::@field::f#element
                    staticType: null
                  equals: = @61
                  expression: IntegerLiteral
                    literal: 0 @63
                    staticType: int
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const enumConstant hasInitializer v
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          type: A
          constantInitializer
            fragment: <testLibraryFragment>::@enum::A::@field::v
            expression: expression_0
          getter: <testLibraryFragment>::@enum::A::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          type: List<A>
          constantInitializer
            fragment: <testLibraryFragment>::@enum::A::@field::values
            expression: expression_1
          getter: <testLibraryFragment>::@enum::A::@getter::values#element
        final f
          firstFragment: <testLibraryFragment>::@enum::A::@field::f
          type: int
          getter: <testLibraryFragment>::@enum::A::@getter::f#element
      constructors
        const named
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructor::named
      getters
        synthetic static get v
          firstFragment: <testLibraryFragment>::@enum::A::@getter::v
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::A::@getter::values
        synthetic get f
          firstFragment: <testLibraryFragment>::@enum::A::@getter::f
''');
  }

  test_augmented_field_augment_field() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment enum A {;
  augment final int foo = 1;
}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
enum A {
  v;
  final int foo = 0;
}
''');

    configuration
      ..withConstantInitializers = false
      ..withPropertyLinking = true;
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
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          enclosingElement3: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: A
              shouldUseTypeForInitializerInference: false
              id: field_0
              getter: getter_0
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: List<A>
              id: field_1
              getter: getter_1
            final foo @41
              reference: <testLibraryFragment>::@enum::A::@field::foo
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: int
              shouldUseTypeForInitializerInference: true
              id: field_2
              getter: getter_2
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@fieldAugmentation::foo
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@enum::A
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: A
              id: getter_0
              variable: field_0
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: List<A>
              id: getter_1
              variable: field_1
            synthetic get foo @-1
              reference: <testLibraryFragment>::@enum::A::@getter::foo
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: int
              id: getter_2
              variable: field_2
          augmented
            fields
              <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@fieldAugmentation::foo
              <testLibraryFragment>::@enum::A::@field::v
              <testLibraryFragment>::@enum::A::@field::values
            constants
              <testLibraryFragment>::@enum::A::@field::v
            constructors
              <testLibraryFragment>::@enum::A::@constructor::new
            accessors
              <testLibraryFragment>::@enum::A::@getter::foo
              <testLibraryFragment>::@enum::A::@getter::v
              <testLibraryFragment>::@enum::A::@getter::values
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          fields
            augment final foo @59
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@fieldAugmentation::foo
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              type: int
              shouldUseTypeForInitializerInference: true
              id: field_3
              augmentationTarget: <testLibraryFragment>::@enum::A::@field::foo
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          element: <testLibrary>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            hasInitializer v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <testLibraryFragment>::@enum::A::@field::v#element
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibraryFragment>::@enum::A
                      element2: <testLibrary>::@enum::A
                      type: A
                    staticElement: <testLibraryFragment>::@enum::A::@constructor::new
                    element: <testLibraryFragment>::@enum::A::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            synthetic values
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <testLibraryFragment>::@enum::A::@field::values#element
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::A::@getter::v
                      element: <testLibraryFragment>::@enum::A::@getter::v#element
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
              getter2: <testLibraryFragment>::@enum::A::@getter::values
            hasInitializer foo @41
              reference: <testLibraryFragment>::@enum::A::@field::foo
              element: <testLibraryFragment>::@enum::A::@field::foo#element
              initializer: expression_2
                IntegerLiteral
                  literal: 0 @47
                  staticType: int
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@fieldAugmentation::foo
              getter2: <testLibraryFragment>::@enum::A::@getter::foo
          constructors
            synthetic const new
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <testLibraryFragment>::@enum::A::@constructor::new#element
              typeName: A
          getters
            synthetic get v
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <testLibraryFragment>::@enum::A::@getter::v#element
            synthetic get values
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <testLibraryFragment>::@enum::A::@getter::values#element
            synthetic get foo
              reference: <testLibraryFragment>::@enum::A::@getter::foo
              element: <testLibraryFragment>::@enum::A::@getter::foo#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibrary>::@enum::A
          previousFragment: <testLibraryFragment>::@enum::A
          fields
            augment hasInitializer foo @59
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@fieldAugmentation::foo
              element: <testLibraryFragment>::@enum::A::@field::foo#element
              initializer: expression_3
                IntegerLiteral
                  literal: 1 @65
                  staticType: int
              previousFragment: <testLibraryFragment>::@enum::A::@field::foo
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const enumConstant hasInitializer v
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          type: A
          constantInitializer
            fragment: <testLibraryFragment>::@enum::A::@field::v
            expression: expression_0
          getter: <testLibraryFragment>::@enum::A::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          type: List<A>
          constantInitializer
            fragment: <testLibraryFragment>::@enum::A::@field::values
            expression: expression_1
          getter: <testLibraryFragment>::@enum::A::@getter::values#element
        final hasInitializer foo
          firstFragment: <testLibraryFragment>::@enum::A::@field::foo
          type: int
          constantInitializer
            fragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@fieldAugmentation::foo
            expression: expression_3
          getter: <testLibraryFragment>::@enum::A::@getter::foo#element
      constructors
        synthetic const new
          firstFragment: <testLibraryFragment>::@enum::A::@constructor::new
      getters
        synthetic static get v
          firstFragment: <testLibraryFragment>::@enum::A::@getter::v
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::A::@getter::values
        synthetic get foo
          firstFragment: <testLibraryFragment>::@enum::A::@getter::foo
''');
  }

  test_augmented_field_augment_field2() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment enum A {;
  augment final int foo = 1;
}
''');

    newFile('$testPackageLibPath/b.dart', r'''
part of 'test.dart';
augment enum A {;
  augment final int foo = 2;
}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
part 'b.dart';
enum A {
  v;
  final int foo = 0;
}
''');

    configuration
      ..withConstantInitializers = false
      ..withPropertyLinking = true;
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
      enums
        enum A @35
          reference: <testLibraryFragment>::@enum::A
          enclosingElement3: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @41
              reference: <testLibraryFragment>::@enum::A::@field::v
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: A
              shouldUseTypeForInitializerInference: false
              id: field_0
              getter: getter_0
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: List<A>
              id: field_1
              getter: getter_1
            final foo @56
              reference: <testLibraryFragment>::@enum::A::@field::foo
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: int
              shouldUseTypeForInitializerInference: true
              id: field_2
              getter: getter_2
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@fieldAugmentation::foo
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@enum::A
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: A
              id: getter_0
              variable: field_0
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: List<A>
              id: getter_1
              variable: field_1
            synthetic get foo @-1
              reference: <testLibraryFragment>::@enum::A::@getter::foo
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: int
              id: getter_2
              variable: field_2
          augmented
            fields
              <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@fieldAugmentation::foo
              <testLibraryFragment>::@enum::A::@field::v
              <testLibraryFragment>::@enum::A::@field::values
            constants
              <testLibraryFragment>::@enum::A::@field::v
            constructors
              <testLibraryFragment>::@enum::A::@constructor::new
            accessors
              <testLibraryFragment>::@enum::A::@getter::foo
              <testLibraryFragment>::@enum::A::@getter::v
              <testLibraryFragment>::@enum::A::@getter::values
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          augmentation: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          fields
            augment final foo @59
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@fieldAugmentation::foo
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              type: int
              shouldUseTypeForInitializerInference: true
              id: field_3
              augmentationTarget: <testLibraryFragment>::@enum::A::@field::foo
              augmentation: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@fieldAugmentation::foo
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @34
          reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/b.dart
          augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            augment final foo @59
              reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@fieldAugmentation::foo
              enclosingElement3: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
              type: int
              shouldUseTypeForInitializerInference: true
              id: field_4
              augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@fieldAugmentation::foo
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @35
          reference: <testLibraryFragment>::@enum::A
          element: <testLibrary>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            hasInitializer v @41
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <testLibraryFragment>::@enum::A::@field::v#element
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibraryFragment>::@enum::A
                      element2: <testLibrary>::@enum::A
                      type: A
                    staticElement: <testLibraryFragment>::@enum::A::@constructor::new
                    element: <testLibraryFragment>::@enum::A::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            synthetic values
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <testLibraryFragment>::@enum::A::@field::values#element
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::A::@getter::v
                      element: <testLibraryFragment>::@enum::A::@getter::v#element
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
              getter2: <testLibraryFragment>::@enum::A::@getter::values
            hasInitializer foo @56
              reference: <testLibraryFragment>::@enum::A::@field::foo
              element: <testLibraryFragment>::@enum::A::@field::foo#element
              initializer: expression_2
                IntegerLiteral
                  literal: 0 @62
                  staticType: int
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@fieldAugmentation::foo
              getter2: <testLibraryFragment>::@enum::A::@getter::foo
          constructors
            synthetic const new
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <testLibraryFragment>::@enum::A::@constructor::new#element
              typeName: A
          getters
            synthetic get v
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <testLibraryFragment>::@enum::A::@getter::v#element
            synthetic get values
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <testLibraryFragment>::@enum::A::@getter::values#element
            synthetic get foo
              reference: <testLibraryFragment>::@enum::A::@getter::foo
              element: <testLibraryFragment>::@enum::A::@getter::foo#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibrary>::@enum::A
          previousFragment: <testLibraryFragment>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          fields
            augment hasInitializer foo @59
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@fieldAugmentation::foo
              element: <testLibraryFragment>::@enum::A::@field::foo#element
              initializer: expression_3
                IntegerLiteral
                  literal: 1 @65
                  staticType: int
              previousFragment: <testLibraryFragment>::@enum::A::@field::foo
              nextFragment: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@fieldAugmentation::foo
    <testLibrary>::@fragment::package:test/b.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          element: <testLibrary>::@enum::A
          previousFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            augment hasInitializer foo @59
              reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@fieldAugmentation::foo
              element: <testLibraryFragment>::@enum::A::@field::foo#element
              initializer: expression_4
                IntegerLiteral
                  literal: 2 @65
                  staticType: int
              previousFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@fieldAugmentation::foo
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const enumConstant hasInitializer v
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          type: A
          constantInitializer
            fragment: <testLibraryFragment>::@enum::A::@field::v
            expression: expression_0
          getter: <testLibraryFragment>::@enum::A::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          type: List<A>
          constantInitializer
            fragment: <testLibraryFragment>::@enum::A::@field::values
            expression: expression_1
          getter: <testLibraryFragment>::@enum::A::@getter::values#element
        final hasInitializer foo
          firstFragment: <testLibraryFragment>::@enum::A::@field::foo
          type: int
          constantInitializer
            fragment: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@fieldAugmentation::foo
            expression: expression_4
          getter: <testLibraryFragment>::@enum::A::@getter::foo#element
      constructors
        synthetic const new
          firstFragment: <testLibraryFragment>::@enum::A::@constructor::new
      getters
        synthetic static get v
          firstFragment: <testLibraryFragment>::@enum::A::@getter::v
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::A::@getter::values
        synthetic get foo
          firstFragment: <testLibraryFragment>::@enum::A::@getter::foo
''');
  }

  test_augmented_field_augment_field_afterGetter() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment enum A {;
  augment int get foo => 1;
}
''');

    newFile('$testPackageLibPath/b.dart', r'''
part of 'test.dart';
augment enum A {;
  augment final int foo = 2;
}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
part 'b.dart';
enum A {
  v;
  final int foo = 0;
}
''');

    configuration
      ..withConstantInitializers = false
      ..withPropertyLinking = true;
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
      enums
        enum A @35
          reference: <testLibraryFragment>::@enum::A
          enclosingElement3: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @41
              reference: <testLibraryFragment>::@enum::A::@field::v
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: A
              shouldUseTypeForInitializerInference: false
              id: field_0
              getter: getter_0
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: List<A>
              id: field_1
              getter: getter_1
            final foo @56
              reference: <testLibraryFragment>::@enum::A::@field::foo
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: int
              shouldUseTypeForInitializerInference: true
              id: field_2
              getter: getter_2
              augmentation: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@fieldAugmentation::foo
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@enum::A
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: A
              id: getter_0
              variable: field_0
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: List<A>
              id: getter_1
              variable: field_1
            synthetic get foo @-1
              reference: <testLibraryFragment>::@enum::A::@getter::foo
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: int
              id: getter_2
              variable: field_2
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getterAugmentation::foo
          augmented
            fields
              <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@fieldAugmentation::foo
              <testLibraryFragment>::@enum::A::@field::v
              <testLibraryFragment>::@enum::A::@field::values
            constants
              <testLibraryFragment>::@enum::A::@field::v
            constructors
              <testLibraryFragment>::@enum::A::@constructor::new
            accessors
              <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getterAugmentation::foo
              <testLibraryFragment>::@enum::A::@getter::v
              <testLibraryFragment>::@enum::A::@getter::values
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          augmentation: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          accessors
            augment get foo @57
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getterAugmentation::foo
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              returnType: int
              id: getter_3
              variable: <null>
              augmentationTarget: <testLibraryFragment>::@enum::A::@getter::foo
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @34
          reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/b.dart
          augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            augment final foo @59
              reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@fieldAugmentation::foo
              enclosingElement3: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
              type: int
              shouldUseTypeForInitializerInference: true
              id: field_3
              augmentationTarget: <testLibraryFragment>::@enum::A::@field::foo
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @35
          reference: <testLibraryFragment>::@enum::A
          element: <testLibrary>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            hasInitializer v @41
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <testLibraryFragment>::@enum::A::@field::v#element
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibraryFragment>::@enum::A
                      element2: <testLibrary>::@enum::A
                      type: A
                    staticElement: <testLibraryFragment>::@enum::A::@constructor::new
                    element: <testLibraryFragment>::@enum::A::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            synthetic values
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <testLibraryFragment>::@enum::A::@field::values#element
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::A::@getter::v
                      element: <testLibraryFragment>::@enum::A::@getter::v#element
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
              getter2: <testLibraryFragment>::@enum::A::@getter::values
            hasInitializer foo @56
              reference: <testLibraryFragment>::@enum::A::@field::foo
              element: <testLibraryFragment>::@enum::A::@field::foo#element
              initializer: expression_2
                IntegerLiteral
                  literal: 0 @62
                  staticType: int
              nextFragment: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@fieldAugmentation::foo
              getter2: <testLibraryFragment>::@enum::A::@getter::foo
          constructors
            synthetic const new
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <testLibraryFragment>::@enum::A::@constructor::new#element
              typeName: A
          getters
            synthetic get v
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <testLibraryFragment>::@enum::A::@getter::v#element
            synthetic get values
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <testLibraryFragment>::@enum::A::@getter::values#element
            synthetic get foo
              reference: <testLibraryFragment>::@enum::A::@getter::foo
              element: <testLibraryFragment>::@enum::A::@getter::foo#element
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getterAugmentation::foo
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibrary>::@enum::A
          previousFragment: <testLibraryFragment>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          getters
            augment get foo @57
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getterAugmentation::foo
              element: <testLibraryFragment>::@enum::A::@getter::foo#element
              previousFragment: <testLibraryFragment>::@enum::A::@getter::foo
    <testLibrary>::@fragment::package:test/b.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          element: <testLibrary>::@enum::A
          previousFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            augment hasInitializer foo @59
              reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@fieldAugmentation::foo
              element: <testLibraryFragment>::@enum::A::@field::foo#element
              initializer: expression_3
                IntegerLiteral
                  literal: 2 @65
                  staticType: int
              previousFragment: <testLibraryFragment>::@enum::A::@field::foo
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const enumConstant hasInitializer v
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          type: A
          constantInitializer
            fragment: <testLibraryFragment>::@enum::A::@field::v
            expression: expression_0
          getter: <testLibraryFragment>::@enum::A::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          type: List<A>
          constantInitializer
            fragment: <testLibraryFragment>::@enum::A::@field::values
            expression: expression_1
          getter: <testLibraryFragment>::@enum::A::@getter::values#element
        final hasInitializer foo
          firstFragment: <testLibraryFragment>::@enum::A::@field::foo
          type: int
          constantInitializer
            fragment: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@fieldAugmentation::foo
            expression: expression_3
          getter: <testLibraryFragment>::@enum::A::@getter::foo#element
      constructors
        synthetic const new
          firstFragment: <testLibraryFragment>::@enum::A::@constructor::new
      getters
        synthetic static get v
          firstFragment: <testLibraryFragment>::@enum::A::@getter::v
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::A::@getter::values
        synthetic get foo
          firstFragment: <testLibraryFragment>::@enum::A::@getter::foo
''');
  }

  test_augmented_field_augment_field_afterSetter() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment enum A {;
  augment set foo(int _) {}
}
''');

    newFile('$testPackageLibPath/b.dart', r'''
part of 'test.dart';
augment enum A {;
  augment final int foo = 2;
}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
part 'b.dart';
enum A {
  v;
  final int foo = 0;
}
''');

    configuration
      ..withConstantInitializers = false
      ..withPropertyLinking = true;
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
      enums
        enum A @35
          reference: <testLibraryFragment>::@enum::A
          enclosingElement3: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @41
              reference: <testLibraryFragment>::@enum::A::@field::v
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: A
              shouldUseTypeForInitializerInference: false
              id: field_0
              getter: getter_0
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: List<A>
              id: field_1
              getter: getter_1
            final foo @56
              reference: <testLibraryFragment>::@enum::A::@field::foo
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: int
              shouldUseTypeForInitializerInference: true
              id: field_2
              getter: getter_2
              augmentation: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@fieldAugmentation::foo
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@enum::A
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: A
              id: getter_0
              variable: field_0
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: List<A>
              id: getter_1
              variable: field_1
            synthetic get foo @-1
              reference: <testLibraryFragment>::@enum::A::@getter::foo
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: int
              id: getter_2
              variable: field_2
          augmented
            fields
              <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@fieldAugmentation::foo
              <testLibraryFragment>::@enum::A::@field::v
              <testLibraryFragment>::@enum::A::@field::values
            constants
              <testLibraryFragment>::@enum::A::@field::v
            constructors
              <testLibraryFragment>::@enum::A::@constructor::new
            accessors
              <testLibraryFragment>::@enum::A::@getter::foo
              <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@setterAugmentation::foo
              <testLibraryFragment>::@enum::A::@getter::v
              <testLibraryFragment>::@enum::A::@getter::values
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          augmentation: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          accessors
            augment set foo= @53
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@setterAugmentation::foo
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              parameters
                requiredPositional _ @61
                  type: int
              returnType: void
              id: setter_0
              variable: <null>
              augmentationTargetAny: <testLibraryFragment>::@enum::A::@getter::foo
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @34
          reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/b.dart
          augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            augment final foo @59
              reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@fieldAugmentation::foo
              enclosingElement3: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
              type: int
              shouldUseTypeForInitializerInference: true
              id: field_3
              augmentationTarget: <testLibraryFragment>::@enum::A::@field::foo
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @35
          reference: <testLibraryFragment>::@enum::A
          element: <testLibrary>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            hasInitializer v @41
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <testLibraryFragment>::@enum::A::@field::v#element
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibraryFragment>::@enum::A
                      element2: <testLibrary>::@enum::A
                      type: A
                    staticElement: <testLibraryFragment>::@enum::A::@constructor::new
                    element: <testLibraryFragment>::@enum::A::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            synthetic values
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <testLibraryFragment>::@enum::A::@field::values#element
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::A::@getter::v
                      element: <testLibraryFragment>::@enum::A::@getter::v#element
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
              getter2: <testLibraryFragment>::@enum::A::@getter::values
            hasInitializer foo @56
              reference: <testLibraryFragment>::@enum::A::@field::foo
              element: <testLibraryFragment>::@enum::A::@field::foo#element
              initializer: expression_2
                IntegerLiteral
                  literal: 0 @62
                  staticType: int
              nextFragment: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@fieldAugmentation::foo
              getter2: <testLibraryFragment>::@enum::A::@getter::foo
          constructors
            synthetic const new
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <testLibraryFragment>::@enum::A::@constructor::new#element
              typeName: A
          getters
            synthetic get v
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <testLibraryFragment>::@enum::A::@getter::v#element
            synthetic get values
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <testLibraryFragment>::@enum::A::@getter::values#element
            synthetic get foo
              reference: <testLibraryFragment>::@enum::A::@getter::foo
              element: <testLibraryFragment>::@enum::A::@getter::foo#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibrary>::@enum::A
          previousFragment: <testLibraryFragment>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          setters
            augment set foo @53
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@setterAugmentation::foo
              element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@setterAugmentation::foo#element
              formalParameters
                _ @61
                  element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@setterAugmentation::foo::@parameter::_#element
    <testLibrary>::@fragment::package:test/b.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          element: <testLibrary>::@enum::A
          previousFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            augment hasInitializer foo @59
              reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@fieldAugmentation::foo
              element: <testLibraryFragment>::@enum::A::@field::foo#element
              initializer: expression_3
                IntegerLiteral
                  literal: 2 @65
                  staticType: int
              previousFragment: <testLibraryFragment>::@enum::A::@field::foo
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const enumConstant hasInitializer v
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          type: A
          constantInitializer
            fragment: <testLibraryFragment>::@enum::A::@field::v
            expression: expression_0
          getter: <testLibraryFragment>::@enum::A::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          type: List<A>
          constantInitializer
            fragment: <testLibraryFragment>::@enum::A::@field::values
            expression: expression_1
          getter: <testLibraryFragment>::@enum::A::@getter::values#element
        final hasInitializer foo
          firstFragment: <testLibraryFragment>::@enum::A::@field::foo
          type: int
          constantInitializer
            fragment: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@fieldAugmentation::foo
            expression: expression_3
          getter: <testLibraryFragment>::@enum::A::@getter::foo#element
      constructors
        synthetic const new
          firstFragment: <testLibraryFragment>::@enum::A::@constructor::new
      getters
        synthetic static get v
          firstFragment: <testLibraryFragment>::@enum::A::@getter::v
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::A::@getter::values
        synthetic get foo
          firstFragment: <testLibraryFragment>::@enum::A::@getter::foo
      setters
        set foo
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@setterAugmentation::foo
          formalParameters
            requiredPositional _
              type: int
''');
  }

  test_augmented_field_augment_field_differentTypes() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment enum A {;
  augment final double foo = 1.2;
}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
enum A {
  v;
  final int foo = 0;
}
''');

    configuration
      ..withConstantInitializers = false
      ..withPropertyLinking = true;
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
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          enclosingElement3: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: A
              shouldUseTypeForInitializerInference: false
              id: field_0
              getter: getter_0
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: List<A>
              id: field_1
              getter: getter_1
            final foo @41
              reference: <testLibraryFragment>::@enum::A::@field::foo
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: int
              shouldUseTypeForInitializerInference: true
              id: field_2
              getter: getter_2
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@fieldAugmentation::foo
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@enum::A
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: A
              id: getter_0
              variable: field_0
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: List<A>
              id: getter_1
              variable: field_1
            synthetic get foo @-1
              reference: <testLibraryFragment>::@enum::A::@getter::foo
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: int
              id: getter_2
              variable: field_2
          augmented
            fields
              <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@fieldAugmentation::foo
              <testLibraryFragment>::@enum::A::@field::v
              <testLibraryFragment>::@enum::A::@field::values
            constants
              <testLibraryFragment>::@enum::A::@field::v
            constructors
              <testLibraryFragment>::@enum::A::@constructor::new
            accessors
              <testLibraryFragment>::@enum::A::@getter::foo
              <testLibraryFragment>::@enum::A::@getter::v
              <testLibraryFragment>::@enum::A::@getter::values
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          fields
            augment final foo @62
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@fieldAugmentation::foo
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              type: double
              shouldUseTypeForInitializerInference: true
              id: field_3
              augmentationTarget: <testLibraryFragment>::@enum::A::@field::foo
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          element: <testLibrary>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            hasInitializer v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <testLibraryFragment>::@enum::A::@field::v#element
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibraryFragment>::@enum::A
                      element2: <testLibrary>::@enum::A
                      type: A
                    staticElement: <testLibraryFragment>::@enum::A::@constructor::new
                    element: <testLibraryFragment>::@enum::A::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            synthetic values
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <testLibraryFragment>::@enum::A::@field::values#element
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::A::@getter::v
                      element: <testLibraryFragment>::@enum::A::@getter::v#element
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
              getter2: <testLibraryFragment>::@enum::A::@getter::values
            hasInitializer foo @41
              reference: <testLibraryFragment>::@enum::A::@field::foo
              element: <testLibraryFragment>::@enum::A::@field::foo#element
              initializer: expression_2
                IntegerLiteral
                  literal: 0 @47
                  staticType: int
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@fieldAugmentation::foo
              getter2: <testLibraryFragment>::@enum::A::@getter::foo
          constructors
            synthetic const new
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <testLibraryFragment>::@enum::A::@constructor::new#element
              typeName: A
          getters
            synthetic get v
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <testLibraryFragment>::@enum::A::@getter::v#element
            synthetic get values
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <testLibraryFragment>::@enum::A::@getter::values#element
            synthetic get foo
              reference: <testLibraryFragment>::@enum::A::@getter::foo
              element: <testLibraryFragment>::@enum::A::@getter::foo#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibrary>::@enum::A
          previousFragment: <testLibraryFragment>::@enum::A
          fields
            augment hasInitializer foo @62
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@fieldAugmentation::foo
              element: <testLibraryFragment>::@enum::A::@field::foo#element
              initializer: expression_3
                DoubleLiteral
                  literal: 1.2 @68
                  staticType: double
              previousFragment: <testLibraryFragment>::@enum::A::@field::foo
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const enumConstant hasInitializer v
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          type: A
          constantInitializer
            fragment: <testLibraryFragment>::@enum::A::@field::v
            expression: expression_0
          getter: <testLibraryFragment>::@enum::A::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          type: List<A>
          constantInitializer
            fragment: <testLibraryFragment>::@enum::A::@field::values
            expression: expression_1
          getter: <testLibraryFragment>::@enum::A::@getter::values#element
        final hasInitializer foo
          firstFragment: <testLibraryFragment>::@enum::A::@field::foo
          type: int
          constantInitializer
            fragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@fieldAugmentation::foo
            expression: expression_3
          getter: <testLibraryFragment>::@enum::A::@getter::foo#element
      constructors
        synthetic const new
          firstFragment: <testLibraryFragment>::@enum::A::@constructor::new
      getters
        synthetic static get v
          firstFragment: <testLibraryFragment>::@enum::A::@getter::v
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::A::@getter::values
        synthetic get foo
          firstFragment: <testLibraryFragment>::@enum::A::@getter::foo
''');
  }

  test_augmented_field_augment_field_functionExpression() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment enum A {;
  augment final int Function() foo = () {
    return augmented() + 1;
  };
}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
enum A {
  v;
  final int Function() foo = () {
    return 0;
  };
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
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          enclosingElement3: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: A
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibraryFragment>::@enum::A
                      element2: <testLibrary>::@enum::A
                      type: A
                    staticElement: <testLibraryFragment>::@enum::A::@constructor::new
                    element: <testLibraryFragment>::@enum::A::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: List<A>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::A::@getter::v
                      element: <testLibraryFragment>::@enum::A::@getter::v#element
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
            final foo @52
              reference: <testLibraryFragment>::@enum::A::@field::foo
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: int Function()
              shouldUseTypeForInitializerInference: true
              constantInitializer
                SimpleIdentifier
                  token: _notSerializableExpression @-1
                  staticElement: <null>
                  element: <null>
                  staticType: null
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@fieldAugmentation::foo
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@enum::A
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: A
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: List<A>
            synthetic get foo @-1
              reference: <testLibraryFragment>::@enum::A::@getter::foo
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: int Function()
          augmented
            fields
              <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@fieldAugmentation::foo
              <testLibraryFragment>::@enum::A::@field::v
              <testLibraryFragment>::@enum::A::@field::values
            constants
              <testLibraryFragment>::@enum::A::@field::v
            constructors
              <testLibraryFragment>::@enum::A::@constructor::new
            accessors
              <testLibraryFragment>::@enum::A::@getter::foo
              <testLibraryFragment>::@enum::A::@getter::v
              <testLibraryFragment>::@enum::A::@getter::values
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          fields
            augment final foo @70
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@fieldAugmentation::foo
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              type: int Function()
              shouldUseTypeForInitializerInference: true
              constantInitializer
                SimpleIdentifier
                  token: _notSerializableExpression @-1
                  staticElement: <null>
                  element: <null>
                  staticType: null
              augmentationTarget: <testLibraryFragment>::@enum::A::@field::foo
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          element: <testLibrary>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            hasInitializer v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <testLibraryFragment>::@enum::A::@field::v#element
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibraryFragment>::@enum::A
                      element2: <testLibrary>::@enum::A
                      type: A
                    staticElement: <testLibraryFragment>::@enum::A::@constructor::new
                    element: <testLibraryFragment>::@enum::A::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            synthetic values
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <testLibraryFragment>::@enum::A::@field::values#element
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::A::@getter::v
                      element: <testLibraryFragment>::@enum::A::@getter::v#element
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
              getter2: <testLibraryFragment>::@enum::A::@getter::values
            hasInitializer foo @52
              reference: <testLibraryFragment>::@enum::A::@field::foo
              element: <testLibraryFragment>::@enum::A::@field::foo#element
              initializer: expression_2
                SimpleIdentifier
                  token: _notSerializableExpression @-1
                  staticElement: <null>
                  element: <null>
                  staticType: null
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@fieldAugmentation::foo
              getter2: <testLibraryFragment>::@enum::A::@getter::foo
          constructors
            synthetic const new
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <testLibraryFragment>::@enum::A::@constructor::new#element
              typeName: A
          getters
            synthetic get v
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <testLibraryFragment>::@enum::A::@getter::v#element
            synthetic get values
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <testLibraryFragment>::@enum::A::@getter::values#element
            synthetic get foo
              reference: <testLibraryFragment>::@enum::A::@getter::foo
              element: <testLibraryFragment>::@enum::A::@getter::foo#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibrary>::@enum::A
          previousFragment: <testLibraryFragment>::@enum::A
          fields
            augment hasInitializer foo @70
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@fieldAugmentation::foo
              element: <testLibraryFragment>::@enum::A::@field::foo#element
              initializer: expression_3
                SimpleIdentifier
                  token: _notSerializableExpression @-1
                  staticElement: <null>
                  element: <null>
                  staticType: null
              previousFragment: <testLibraryFragment>::@enum::A::@field::foo
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const enumConstant hasInitializer v
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          type: A
          constantInitializer
            fragment: <testLibraryFragment>::@enum::A::@field::v
            expression: expression_0
          getter: <testLibraryFragment>::@enum::A::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          type: List<A>
          constantInitializer
            fragment: <testLibraryFragment>::@enum::A::@field::values
            expression: expression_1
          getter: <testLibraryFragment>::@enum::A::@getter::values#element
        final hasInitializer foo
          firstFragment: <testLibraryFragment>::@enum::A::@field::foo
          type: int Function()
          constantInitializer
            fragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@fieldAugmentation::foo
            expression: expression_3
          getter: <testLibraryFragment>::@enum::A::@getter::foo#element
      constructors
        synthetic const new
          firstFragment: <testLibraryFragment>::@enum::A::@constructor::new
      getters
        synthetic static get v
          firstFragment: <testLibraryFragment>::@enum::A::@getter::v
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::A::@getter::values
        synthetic get foo
          firstFragment: <testLibraryFragment>::@enum::A::@getter::foo
''');
  }

  /// This is not allowed by the specification, but allowed syntactically,
  /// so we need a way to handle it.
  test_augmented_field_augment_getter() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment enum A {;
  augment final int foo = 1;
}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
enum A {
  v;
  int get foo => 0;
}
''');

    configuration
      ..withConstantInitializers = false
      ..withPropertyLinking = true;
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
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          enclosingElement3: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: A
              shouldUseTypeForInitializerInference: false
              id: field_0
              getter: getter_0
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: List<A>
              id: field_1
              getter: getter_1
            synthetic foo @-1
              reference: <testLibraryFragment>::@enum::A::@field::foo
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: int
              id: field_2
              getter: getter_2
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@fieldAugmentation::foo
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@enum::A
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: A
              id: getter_0
              variable: field_0
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: List<A>
              id: getter_1
              variable: field_1
            get foo @39
              reference: <testLibraryFragment>::@enum::A::@getter::foo
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: int
              id: getter_2
              variable: field_2
          augmented
            fields
              <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@fieldAugmentation::foo
              <testLibraryFragment>::@enum::A::@field::v
              <testLibraryFragment>::@enum::A::@field::values
            constants
              <testLibraryFragment>::@enum::A::@field::v
            constructors
              <testLibraryFragment>::@enum::A::@constructor::new
            accessors
              <testLibraryFragment>::@enum::A::@getter::foo
              <testLibraryFragment>::@enum::A::@getter::v
              <testLibraryFragment>::@enum::A::@getter::values
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          fields
            augment final foo @59
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@fieldAugmentation::foo
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              type: int
              shouldUseTypeForInitializerInference: true
              id: field_3
              augmentationTarget: <testLibraryFragment>::@enum::A::@field::foo
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          element: <testLibrary>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            hasInitializer v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <testLibraryFragment>::@enum::A::@field::v#element
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibraryFragment>::@enum::A
                      element2: <testLibrary>::@enum::A
                      type: A
                    staticElement: <testLibraryFragment>::@enum::A::@constructor::new
                    element: <testLibraryFragment>::@enum::A::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            synthetic values
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <testLibraryFragment>::@enum::A::@field::values#element
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::A::@getter::v
                      element: <testLibraryFragment>::@enum::A::@getter::v#element
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
              getter2: <testLibraryFragment>::@enum::A::@getter::values
            synthetic foo
              reference: <testLibraryFragment>::@enum::A::@field::foo
              element: <testLibraryFragment>::@enum::A::@field::foo#element
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@fieldAugmentation::foo
              getter2: <testLibraryFragment>::@enum::A::@getter::foo
          constructors
            synthetic const new
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <testLibraryFragment>::@enum::A::@constructor::new#element
              typeName: A
          getters
            synthetic get v
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <testLibraryFragment>::@enum::A::@getter::v#element
            synthetic get values
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <testLibraryFragment>::@enum::A::@getter::values#element
            get foo @39
              reference: <testLibraryFragment>::@enum::A::@getter::foo
              element: <testLibraryFragment>::@enum::A::@getter::foo#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibrary>::@enum::A
          previousFragment: <testLibraryFragment>::@enum::A
          fields
            augment hasInitializer foo @59
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@fieldAugmentation::foo
              element: <testLibraryFragment>::@enum::A::@field::foo#element
              initializer: expression_2
                IntegerLiteral
                  literal: 1 @65
                  staticType: int
              previousFragment: <testLibraryFragment>::@enum::A::@field::foo
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const enumConstant hasInitializer v
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          type: A
          constantInitializer
            fragment: <testLibraryFragment>::@enum::A::@field::v
            expression: expression_0
          getter: <testLibraryFragment>::@enum::A::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          type: List<A>
          constantInitializer
            fragment: <testLibraryFragment>::@enum::A::@field::values
            expression: expression_1
          getter: <testLibraryFragment>::@enum::A::@getter::values#element
        synthetic hasInitializer foo
          firstFragment: <testLibraryFragment>::@enum::A::@field::foo
          type: int
          constantInitializer
            fragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@fieldAugmentation::foo
            expression: expression_2
          getter: <testLibraryFragment>::@enum::A::@getter::foo#element
      constructors
        synthetic const new
          firstFragment: <testLibraryFragment>::@enum::A::@constructor::new
      getters
        synthetic static get v
          firstFragment: <testLibraryFragment>::@enum::A::@getter::v
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::A::@getter::values
        get foo
          firstFragment: <testLibraryFragment>::@enum::A::@getter::foo
''');
  }

  test_augmented_fields_add() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment enum A {;
  final int foo2 = 0;
}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
enum A {
  v;
  final int foo1 = 0;
}
''');

    configuration
      ..withConstantInitializers = false
      ..withPropertyLinking = true;
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
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          enclosingElement3: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: A
              shouldUseTypeForInitializerInference: false
              id: field_0
              getter: getter_0
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: List<A>
              id: field_1
              getter: getter_1
            final foo1 @41
              reference: <testLibraryFragment>::@enum::A::@field::foo1
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: int
              shouldUseTypeForInitializerInference: true
              id: field_2
              getter: getter_2
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@enum::A
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: A
              id: getter_0
              variable: field_0
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: List<A>
              id: getter_1
              variable: field_1
            synthetic get foo1 @-1
              reference: <testLibraryFragment>::@enum::A::@getter::foo1
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: int
              id: getter_2
              variable: field_2
          augmented
            fields
              <testLibraryFragment>::@enum::A::@field::foo1
              <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::foo2
              <testLibraryFragment>::@enum::A::@field::v
              <testLibraryFragment>::@enum::A::@field::values
            constants
              <testLibraryFragment>::@enum::A::@field::v
            constructors
              <testLibraryFragment>::@enum::A::@constructor::new
            accessors
              <testLibraryFragment>::@enum::A::@getter::foo1
              <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::foo2
              <testLibraryFragment>::@enum::A::@getter::v
              <testLibraryFragment>::@enum::A::@getter::values
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          fields
            final foo2 @51
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::foo2
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              type: int
              shouldUseTypeForInitializerInference: true
              id: field_3
              getter: getter_3
          accessors
            synthetic get foo2 @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::foo2
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              returnType: int
              id: getter_3
              variable: field_3
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          element: <testLibrary>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            hasInitializer v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <testLibraryFragment>::@enum::A::@field::v#element
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibraryFragment>::@enum::A
                      element2: <testLibrary>::@enum::A
                      type: A
                    staticElement: <testLibraryFragment>::@enum::A::@constructor::new
                    element: <testLibraryFragment>::@enum::A::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            synthetic values
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <testLibraryFragment>::@enum::A::@field::values#element
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::A::@getter::v
                      element: <testLibraryFragment>::@enum::A::@getter::v#element
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
              getter2: <testLibraryFragment>::@enum::A::@getter::values
            hasInitializer foo1 @41
              reference: <testLibraryFragment>::@enum::A::@field::foo1
              element: <testLibraryFragment>::@enum::A::@field::foo1#element
              initializer: expression_2
                IntegerLiteral
                  literal: 0 @48
                  staticType: int
              getter2: <testLibraryFragment>::@enum::A::@getter::foo1
          constructors
            synthetic const new
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <testLibraryFragment>::@enum::A::@constructor::new#element
              typeName: A
          getters
            synthetic get v
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <testLibraryFragment>::@enum::A::@getter::v#element
            synthetic get values
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <testLibraryFragment>::@enum::A::@getter::values#element
            synthetic get foo1
              reference: <testLibraryFragment>::@enum::A::@getter::foo1
              element: <testLibraryFragment>::@enum::A::@getter::foo1#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibrary>::@enum::A
          previousFragment: <testLibraryFragment>::@enum::A
          fields
            hasInitializer foo2 @51
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::foo2
              element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::foo2#element
              initializer: expression_3
                IntegerLiteral
                  literal: 0 @58
                  staticType: int
              getter2: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::foo2
          getters
            synthetic get foo2
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::foo2
              element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::foo2#element
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const enumConstant hasInitializer v
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          type: A
          constantInitializer
            fragment: <testLibraryFragment>::@enum::A::@field::v
            expression: expression_0
          getter: <testLibraryFragment>::@enum::A::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          type: List<A>
          constantInitializer
            fragment: <testLibraryFragment>::@enum::A::@field::values
            expression: expression_1
          getter: <testLibraryFragment>::@enum::A::@getter::values#element
        final hasInitializer foo1
          firstFragment: <testLibraryFragment>::@enum::A::@field::foo1
          type: int
          constantInitializer
            fragment: <testLibraryFragment>::@enum::A::@field::foo1
            expression: expression_2
          getter: <testLibraryFragment>::@enum::A::@getter::foo1#element
        final hasInitializer foo2
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::foo2
          type: int
          constantInitializer
            fragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::foo2
            expression: expression_3
          getter: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::foo2#element
      constructors
        synthetic const new
          firstFragment: <testLibraryFragment>::@enum::A::@constructor::new
      getters
        synthetic static get v
          firstFragment: <testLibraryFragment>::@enum::A::@getter::v
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::A::@getter::values
        synthetic get foo1
          firstFragment: <testLibraryFragment>::@enum::A::@getter::foo1
        synthetic get foo2
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::foo2
''');
  }

  test_augmented_fields_add_generic() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment enum A<T1> {;
  final T1 foo2;
}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
enum A<T1> {
  v<int>();
  final T1 foo1;
}
''');

    configuration
      ..withConstantInitializers = false
      ..withPropertyLinking = true;
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
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant T1 @22
              defaultType: dynamic
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @30
              reference: <testLibraryFragment>::@enum::A::@field::v
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: A<int>
              shouldUseTypeForInitializerInference: false
              id: field_0
              getter: getter_0
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: List<A<dynamic>>
              id: field_1
              getter: getter_1
            final foo1 @51
              reference: <testLibraryFragment>::@enum::A::@field::foo1
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: T1
              id: field_2
              getter: getter_2
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@enum::A
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: A<int>
              id: getter_0
              variable: field_0
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: List<A<dynamic>>
              id: getter_1
              variable: field_1
            synthetic get foo1 @-1
              reference: <testLibraryFragment>::@enum::A::@getter::foo1
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: T1
              id: getter_2
              variable: field_2
          augmented
            fields
              <testLibraryFragment>::@enum::A::@field::foo1
              FieldMember
                base: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::foo2
                augmentationSubstitution: {T1: T1}
              <testLibraryFragment>::@enum::A::@field::v
              <testLibraryFragment>::@enum::A::@field::values
            constants
              <testLibraryFragment>::@enum::A::@field::v
            constructors
              <testLibraryFragment>::@enum::A::@constructor::new
            accessors
              <testLibraryFragment>::@enum::A::@getter::foo1
              GetterMember
                base: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::foo2
                augmentationSubstitution: {T1: T1}
              <testLibraryFragment>::@enum::A::@getter::v
              <testLibraryFragment>::@enum::A::@getter::values
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          typeParameters
            covariant T1 @36
              defaultType: dynamic
          augmentationTarget: <testLibraryFragment>::@enum::A
          fields
            final foo2 @54
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::foo2
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              type: T1
              id: field_3
              getter: getter_3
          accessors
            synthetic get foo2 @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::foo2
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              returnType: T1
              id: getter_3
              variable: field_3
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          element: <testLibrary>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          typeParameters
            T1 @22
              element: <not-implemented>
          fields
            hasInitializer v @30
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <testLibraryFragment>::@enum::A::@field::v#element
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      typeArguments: TypeArgumentList
                        leftBracket: < @31
                        arguments
                          NamedType
                            name: int @32
                            element: dart:core::<fragment>::@class::int
                            element2: dart:core::@class::int
                            type: int
                        rightBracket: > @35
                      element: <testLibraryFragment>::@enum::A
                      element2: <testLibrary>::@enum::A
                      type: A<int>
                    staticElement: ConstructorMember
                      base: <testLibraryFragment>::@enum::A::@constructor::new
                      substitution: {T1: int}
                    element: <testLibraryFragment>::@enum::A::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A<int>
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            synthetic values
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <testLibraryFragment>::@enum::A::@field::values#element
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::A::@getter::v
                      element: <testLibraryFragment>::@enum::A::@getter::v#element
                      staticType: A<int>
                  rightBracket: ] @0
                  staticType: List<A<dynamic>>
              getter2: <testLibraryFragment>::@enum::A::@getter::values
            foo1 @51
              reference: <testLibraryFragment>::@enum::A::@field::foo1
              element: <testLibraryFragment>::@enum::A::@field::foo1#element
              getter2: <testLibraryFragment>::@enum::A::@getter::foo1
          constructors
            synthetic const new
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <testLibraryFragment>::@enum::A::@constructor::new#element
              typeName: A
          getters
            synthetic get v
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <testLibraryFragment>::@enum::A::@getter::v#element
            synthetic get values
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <testLibraryFragment>::@enum::A::@getter::values#element
            synthetic get foo1
              reference: <testLibraryFragment>::@enum::A::@getter::foo1
              element: <testLibraryFragment>::@enum::A::@getter::foo1#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibrary>::@enum::A
          previousFragment: <testLibraryFragment>::@enum::A
          typeParameters
            T1 @36
              element: <not-implemented>
          fields
            foo2 @54
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::foo2
              element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::foo2#element
              getter2: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::foo2
          getters
            synthetic get foo2
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::foo2
              element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::foo2#element
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: <testLibraryFragment>::@enum::A
      typeParameters
        T1
      supertype: Enum
      fields
        static const enumConstant hasInitializer v
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          type: A<int>
          constantInitializer
            fragment: <testLibraryFragment>::@enum::A::@field::v
            expression: expression_0
          getter: <testLibraryFragment>::@enum::A::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          type: List<A<dynamic>>
          constantInitializer
            fragment: <testLibraryFragment>::@enum::A::@field::values
            expression: expression_1
          getter: <testLibraryFragment>::@enum::A::@getter::values#element
        final foo1
          firstFragment: <testLibraryFragment>::@enum::A::@field::foo1
          type: T1
          getter: <testLibraryFragment>::@enum::A::@getter::foo1#element
        final foo2
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::foo2
          type: T1
          getter: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::foo2#element
      constructors
        synthetic const new
          firstFragment: <testLibraryFragment>::@enum::A::@constructor::new
      getters
        synthetic static get v
          firstFragment: <testLibraryFragment>::@enum::A::@getter::v
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::A::@getter::values
        synthetic get foo1
          firstFragment: <testLibraryFragment>::@enum::A::@getter::foo1
        synthetic get foo2
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::foo2
''');
  }

  test_augmented_fields_add_useFieldFormal() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment enum A {;
  final int foo;
}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
enum A {
  v(0);
  const A(this.foo);
}
''');

    configuration.withConstantInitializers = false;
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
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          enclosingElement3: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: A
              shouldUseTypeForInitializerInference: false
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: List<A>
          constructors
            const @40
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@enum::A
              parameters
                requiredPositional final hasImplicitType this.foo @47
                  type: int
                  field: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::foo
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: A
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: List<A>
          augmented
            fields
              <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::foo
              <testLibraryFragment>::@enum::A::@field::v
              <testLibraryFragment>::@enum::A::@field::values
            constants
              <testLibraryFragment>::@enum::A::@field::v
            constructors
              <testLibraryFragment>::@enum::A::@constructor::new
            accessors
              <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::foo
              <testLibraryFragment>::@enum::A::@getter::v
              <testLibraryFragment>::@enum::A::@getter::values
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          fields
            final foo @51
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::foo
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              type: int
          accessors
            synthetic get foo @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::foo
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          element: <testLibrary>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            hasInitializer v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <testLibraryFragment>::@enum::A::@field::v#element
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibraryFragment>::@enum::A
                      element2: <testLibrary>::@enum::A
                      type: A
                    staticElement: <testLibraryFragment>::@enum::A::@constructor::new
                    element: <testLibraryFragment>::@enum::A::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    arguments
                      IntegerLiteral
                        literal: 0 @28
                        staticType: int
                    rightParenthesis: ) @0
                  staticType: A
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            synthetic values
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <testLibraryFragment>::@enum::A::@field::values#element
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::A::@getter::v
                      element: <testLibraryFragment>::@enum::A::@getter::v#element
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
              getter2: <testLibraryFragment>::@enum::A::@getter::values
          constructors
            const new
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <testLibraryFragment>::@enum::A::@constructor::new#element
              typeName: A
              typeNameOffset: 40
              formalParameters
                this.foo @47
                  element: <testLibraryFragment>::@enum::A::@constructor::new::@parameter::foo#element
          getters
            synthetic get v
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <testLibraryFragment>::@enum::A::@getter::v#element
            synthetic get values
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <testLibraryFragment>::@enum::A::@getter::values#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibrary>::@enum::A
          previousFragment: <testLibraryFragment>::@enum::A
          fields
            foo @51
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::foo
              element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::foo#element
              getter2: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::foo
          getters
            synthetic get foo
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::foo
              element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::foo#element
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const enumConstant hasInitializer v
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          type: A
          constantInitializer
            fragment: <testLibraryFragment>::@enum::A::@field::v
            expression: expression_0
          getter: <testLibraryFragment>::@enum::A::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          type: List<A>
          constantInitializer
            fragment: <testLibraryFragment>::@enum::A::@field::values
            expression: expression_1
          getter: <testLibraryFragment>::@enum::A::@getter::values#element
        final foo
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::foo
          type: int
          getter: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::foo#element
      constructors
        const new
          firstFragment: <testLibraryFragment>::@enum::A::@constructor::new
          formalParameters
            requiredPositional final hasImplicitType foo
              type: int
      getters
        synthetic static get v
          firstFragment: <testLibraryFragment>::@enum::A::@getter::v
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::A::@getter::values
        synthetic get foo
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::foo
''');
  }

  test_augmented_fields_add_useFieldInitializer() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment enum A {;
  final int foo;
}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
enum A {
  v;
  const A() : foo = 0;
}
''');

    configuration.withConstantInitializers = false;
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
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          enclosingElement3: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: A
              shouldUseTypeForInitializerInference: false
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: List<A>
          constructors
            const @37
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@enum::A
              constantInitializers
                ConstructorFieldInitializer
                  fieldName: SimpleIdentifier
                    token: foo @43
                    staticElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::foo
                    element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::foo#element
                    staticType: null
                  equals: = @47
                  expression: IntegerLiteral
                    literal: 0 @49
                    staticType: int
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: A
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: List<A>
          augmented
            fields
              <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::foo
              <testLibraryFragment>::@enum::A::@field::v
              <testLibraryFragment>::@enum::A::@field::values
            constants
              <testLibraryFragment>::@enum::A::@field::v
            constructors
              <testLibraryFragment>::@enum::A::@constructor::new
            accessors
              <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::foo
              <testLibraryFragment>::@enum::A::@getter::v
              <testLibraryFragment>::@enum::A::@getter::values
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          fields
            final foo @51
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::foo
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              type: int
          accessors
            synthetic get foo @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::foo
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          element: <testLibrary>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            hasInitializer v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <testLibraryFragment>::@enum::A::@field::v#element
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibraryFragment>::@enum::A
                      element2: <testLibrary>::@enum::A
                      type: A
                    staticElement: <testLibraryFragment>::@enum::A::@constructor::new
                    element: <testLibraryFragment>::@enum::A::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            synthetic values
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <testLibraryFragment>::@enum::A::@field::values#element
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::A::@getter::v
                      element: <testLibraryFragment>::@enum::A::@getter::v#element
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
              getter2: <testLibraryFragment>::@enum::A::@getter::values
          constructors
            const new
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <testLibraryFragment>::@enum::A::@constructor::new#element
              typeName: A
              typeNameOffset: 37
              constantInitializers
                ConstructorFieldInitializer
                  fieldName: SimpleIdentifier
                    token: foo @43
                    staticElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::foo
                    element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::foo#element
                    staticType: null
                  equals: = @47
                  expression: IntegerLiteral
                    literal: 0 @49
                    staticType: int
          getters
            synthetic get v
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <testLibraryFragment>::@enum::A::@getter::v#element
            synthetic get values
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <testLibraryFragment>::@enum::A::@getter::values#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibrary>::@enum::A
          previousFragment: <testLibraryFragment>::@enum::A
          fields
            foo @51
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::foo
              element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::foo#element
              getter2: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::foo
          getters
            synthetic get foo
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::foo
              element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::foo#element
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const enumConstant hasInitializer v
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          type: A
          constantInitializer
            fragment: <testLibraryFragment>::@enum::A::@field::v
            expression: expression_0
          getter: <testLibraryFragment>::@enum::A::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          type: List<A>
          constantInitializer
            fragment: <testLibraryFragment>::@enum::A::@field::values
            expression: expression_1
          getter: <testLibraryFragment>::@enum::A::@getter::values#element
        final foo
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::foo
          type: int
          getter: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::foo#element
      constructors
        const new
          firstFragment: <testLibraryFragment>::@enum::A::@constructor::new
      getters
        synthetic static get v
          firstFragment: <testLibraryFragment>::@enum::A::@getter::v
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::A::@getter::values
        synthetic get foo
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::foo
''');
  }

  test_augmented_getters_add() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment enum A {;
  int get foo2 => 0;
}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
enum A {
  v;
  int get foo1 => 0;
}
''');

    configuration
      ..withConstantInitializers = false
      ..withPropertyLinking = true;
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
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          enclosingElement3: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: A
              shouldUseTypeForInitializerInference: false
              id: field_0
              getter: getter_0
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: List<A>
              id: field_1
              getter: getter_1
            synthetic foo1 @-1
              reference: <testLibraryFragment>::@enum::A::@field::foo1
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: int
              id: field_2
              getter: getter_2
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@enum::A
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: A
              id: getter_0
              variable: field_0
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: List<A>
              id: getter_1
              variable: field_1
            get foo1 @39
              reference: <testLibraryFragment>::@enum::A::@getter::foo1
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: int
              id: getter_2
              variable: field_2
          augmented
            fields
              <testLibraryFragment>::@enum::A::@field::foo1
              <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::foo2
              <testLibraryFragment>::@enum::A::@field::v
              <testLibraryFragment>::@enum::A::@field::values
            constants
              <testLibraryFragment>::@enum::A::@field::v
            constructors
              <testLibraryFragment>::@enum::A::@constructor::new
            accessors
              <testLibraryFragment>::@enum::A::@getter::foo1
              <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::foo2
              <testLibraryFragment>::@enum::A::@getter::v
              <testLibraryFragment>::@enum::A::@getter::values
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          fields
            synthetic foo2 @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::foo2
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              type: int
              id: field_3
              getter: getter_3
          accessors
            get foo2 @49
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::foo2
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              returnType: int
              id: getter_3
              variable: field_3
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          element: <testLibrary>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            hasInitializer v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <testLibraryFragment>::@enum::A::@field::v#element
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibraryFragment>::@enum::A
                      element2: <testLibrary>::@enum::A
                      type: A
                    staticElement: <testLibraryFragment>::@enum::A::@constructor::new
                    element: <testLibraryFragment>::@enum::A::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            synthetic values
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <testLibraryFragment>::@enum::A::@field::values#element
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::A::@getter::v
                      element: <testLibraryFragment>::@enum::A::@getter::v#element
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
              getter2: <testLibraryFragment>::@enum::A::@getter::values
            synthetic foo1
              reference: <testLibraryFragment>::@enum::A::@field::foo1
              element: <testLibraryFragment>::@enum::A::@field::foo1#element
              getter2: <testLibraryFragment>::@enum::A::@getter::foo1
          constructors
            synthetic const new
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <testLibraryFragment>::@enum::A::@constructor::new#element
              typeName: A
          getters
            synthetic get v
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <testLibraryFragment>::@enum::A::@getter::v#element
            synthetic get values
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <testLibraryFragment>::@enum::A::@getter::values#element
            get foo1 @39
              reference: <testLibraryFragment>::@enum::A::@getter::foo1
              element: <testLibraryFragment>::@enum::A::@getter::foo1#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibrary>::@enum::A
          previousFragment: <testLibraryFragment>::@enum::A
          fields
            synthetic foo2
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::foo2
              element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::foo2#element
              getter2: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::foo2
          getters
            get foo2 @49
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::foo2
              element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::foo2#element
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const enumConstant hasInitializer v
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          type: A
          constantInitializer
            fragment: <testLibraryFragment>::@enum::A::@field::v
            expression: expression_0
          getter: <testLibraryFragment>::@enum::A::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          type: List<A>
          constantInitializer
            fragment: <testLibraryFragment>::@enum::A::@field::values
            expression: expression_1
          getter: <testLibraryFragment>::@enum::A::@getter::values#element
        synthetic foo1
          firstFragment: <testLibraryFragment>::@enum::A::@field::foo1
          type: int
          getter: <testLibraryFragment>::@enum::A::@getter::foo1#element
        synthetic foo2
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::foo2
          type: int
          getter: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::foo2#element
      constructors
        synthetic const new
          firstFragment: <testLibraryFragment>::@enum::A::@constructor::new
      getters
        synthetic static get v
          firstFragment: <testLibraryFragment>::@enum::A::@getter::v
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::A::@getter::values
        get foo1
          firstFragment: <testLibraryFragment>::@enum::A::@getter::foo1
        get foo2
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::foo2
''');
  }

  test_augmented_getters_add_generic() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment enum A<T1> {;
  T1 get foo2;
}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
enum A<T1> {
  v<int>();
  T1 get foo1;
}
''');

    configuration
      ..withConstantInitializers = false
      ..withPropertyLinking = true;
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
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant T1 @22
              defaultType: dynamic
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @30
              reference: <testLibraryFragment>::@enum::A::@field::v
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: A<int>
              shouldUseTypeForInitializerInference: false
              id: field_0
              getter: getter_0
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: List<A<dynamic>>
              id: field_1
              getter: getter_1
            synthetic foo1 @-1
              reference: <testLibraryFragment>::@enum::A::@field::foo1
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: T1
              id: field_2
              getter: getter_2
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@enum::A
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: A<int>
              id: getter_0
              variable: field_0
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: List<A<dynamic>>
              id: getter_1
              variable: field_1
            abstract get foo1 @49
              reference: <testLibraryFragment>::@enum::A::@getter::foo1
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: T1
              id: getter_2
              variable: field_2
          augmented
            fields
              <testLibraryFragment>::@enum::A::@field::foo1
              FieldMember
                base: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::foo2
                augmentationSubstitution: {T1: T1}
              <testLibraryFragment>::@enum::A::@field::v
              <testLibraryFragment>::@enum::A::@field::values
            constants
              <testLibraryFragment>::@enum::A::@field::v
            constructors
              <testLibraryFragment>::@enum::A::@constructor::new
            accessors
              <testLibraryFragment>::@enum::A::@getter::foo1
              GetterMember
                base: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::foo2
                augmentationSubstitution: {T1: T1}
              <testLibraryFragment>::@enum::A::@getter::v
              <testLibraryFragment>::@enum::A::@getter::values
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          typeParameters
            covariant T1 @36
              defaultType: dynamic
          augmentationTarget: <testLibraryFragment>::@enum::A
          fields
            synthetic foo2 @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::foo2
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              type: T1
              id: field_3
              getter: getter_3
          accessors
            abstract get foo2 @52
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::foo2
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              returnType: T1
              id: getter_3
              variable: field_3
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          element: <testLibrary>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          typeParameters
            T1 @22
              element: <not-implemented>
          fields
            hasInitializer v @30
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <testLibraryFragment>::@enum::A::@field::v#element
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      typeArguments: TypeArgumentList
                        leftBracket: < @31
                        arguments
                          NamedType
                            name: int @32
                            element: dart:core::<fragment>::@class::int
                            element2: dart:core::@class::int
                            type: int
                        rightBracket: > @35
                      element: <testLibraryFragment>::@enum::A
                      element2: <testLibrary>::@enum::A
                      type: A<int>
                    staticElement: ConstructorMember
                      base: <testLibraryFragment>::@enum::A::@constructor::new
                      substitution: {T1: int}
                    element: <testLibraryFragment>::@enum::A::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A<int>
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            synthetic values
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <testLibraryFragment>::@enum::A::@field::values#element
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::A::@getter::v
                      element: <testLibraryFragment>::@enum::A::@getter::v#element
                      staticType: A<int>
                  rightBracket: ] @0
                  staticType: List<A<dynamic>>
              getter2: <testLibraryFragment>::@enum::A::@getter::values
            synthetic foo1
              reference: <testLibraryFragment>::@enum::A::@field::foo1
              element: <testLibraryFragment>::@enum::A::@field::foo1#element
              getter2: <testLibraryFragment>::@enum::A::@getter::foo1
          constructors
            synthetic const new
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <testLibraryFragment>::@enum::A::@constructor::new#element
              typeName: A
          getters
            synthetic get v
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <testLibraryFragment>::@enum::A::@getter::v#element
            synthetic get values
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <testLibraryFragment>::@enum::A::@getter::values#element
            get foo1 @49
              reference: <testLibraryFragment>::@enum::A::@getter::foo1
              element: <testLibraryFragment>::@enum::A::@getter::foo1#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibrary>::@enum::A
          previousFragment: <testLibraryFragment>::@enum::A
          typeParameters
            T1 @36
              element: <not-implemented>
          fields
            synthetic foo2
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::foo2
              element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::foo2#element
              getter2: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::foo2
          getters
            get foo2 @52
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::foo2
              element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::foo2#element
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: <testLibraryFragment>::@enum::A
      typeParameters
        T1
      supertype: Enum
      fields
        static const enumConstant hasInitializer v
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          type: A<int>
          constantInitializer
            fragment: <testLibraryFragment>::@enum::A::@field::v
            expression: expression_0
          getter: <testLibraryFragment>::@enum::A::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          type: List<A<dynamic>>
          constantInitializer
            fragment: <testLibraryFragment>::@enum::A::@field::values
            expression: expression_1
          getter: <testLibraryFragment>::@enum::A::@getter::values#element
        synthetic foo1
          firstFragment: <testLibraryFragment>::@enum::A::@field::foo1
          type: T1
          getter: <testLibraryFragment>::@enum::A::@getter::foo1#element
        synthetic foo2
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::foo2
          type: T1
          getter: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::foo2#element
      constructors
        synthetic const new
          firstFragment: <testLibraryFragment>::@enum::A::@constructor::new
      getters
        synthetic static get v
          firstFragment: <testLibraryFragment>::@enum::A::@getter::v
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::A::@getter::values
        abstract get foo1
          firstFragment: <testLibraryFragment>::@enum::A::@getter::foo1
        abstract get foo2
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::foo2
''');
  }

  test_augmented_getters_augment_field() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment enum A {;
  augment int get foo => 0;
}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
enum A {
  v;
  final int foo = 0;
}
''');

    configuration
      ..withConstantInitializers = false
      ..withPropertyLinking = true;
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
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          enclosingElement3: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: A
              shouldUseTypeForInitializerInference: false
              id: field_0
              getter: getter_0
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: List<A>
              id: field_1
              getter: getter_1
            final foo @41
              reference: <testLibraryFragment>::@enum::A::@field::foo
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: int
              shouldUseTypeForInitializerInference: true
              id: field_2
              getter: getter_2
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@enum::A
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: A
              id: getter_0
              variable: field_0
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: List<A>
              id: getter_1
              variable: field_1
            synthetic get foo @-1
              reference: <testLibraryFragment>::@enum::A::@getter::foo
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: int
              id: getter_2
              variable: field_2
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getterAugmentation::foo
          augmented
            fields
              <testLibraryFragment>::@enum::A::@field::foo
              <testLibraryFragment>::@enum::A::@field::v
              <testLibraryFragment>::@enum::A::@field::values
            constants
              <testLibraryFragment>::@enum::A::@field::v
            constructors
              <testLibraryFragment>::@enum::A::@constructor::new
            accessors
              <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getterAugmentation::foo
              <testLibraryFragment>::@enum::A::@getter::v
              <testLibraryFragment>::@enum::A::@getter::values
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          accessors
            augment get foo @57
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getterAugmentation::foo
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              returnType: int
              id: getter_3
              variable: <null>
              augmentationTarget: <testLibraryFragment>::@enum::A::@getter::foo
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          element: <testLibrary>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            hasInitializer v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <testLibraryFragment>::@enum::A::@field::v#element
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibraryFragment>::@enum::A
                      element2: <testLibrary>::@enum::A
                      type: A
                    staticElement: <testLibraryFragment>::@enum::A::@constructor::new
                    element: <testLibraryFragment>::@enum::A::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            synthetic values
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <testLibraryFragment>::@enum::A::@field::values#element
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::A::@getter::v
                      element: <testLibraryFragment>::@enum::A::@getter::v#element
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
              getter2: <testLibraryFragment>::@enum::A::@getter::values
            hasInitializer foo @41
              reference: <testLibraryFragment>::@enum::A::@field::foo
              element: <testLibraryFragment>::@enum::A::@field::foo#element
              initializer: expression_2
                IntegerLiteral
                  literal: 0 @47
                  staticType: int
              getter2: <testLibraryFragment>::@enum::A::@getter::foo
          constructors
            synthetic const new
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <testLibraryFragment>::@enum::A::@constructor::new#element
              typeName: A
          getters
            synthetic get v
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <testLibraryFragment>::@enum::A::@getter::v#element
            synthetic get values
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <testLibraryFragment>::@enum::A::@getter::values#element
            synthetic get foo
              reference: <testLibraryFragment>::@enum::A::@getter::foo
              element: <testLibraryFragment>::@enum::A::@getter::foo#element
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getterAugmentation::foo
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibrary>::@enum::A
          previousFragment: <testLibraryFragment>::@enum::A
          getters
            augment get foo @57
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getterAugmentation::foo
              element: <testLibraryFragment>::@enum::A::@getter::foo#element
              previousFragment: <testLibraryFragment>::@enum::A::@getter::foo
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const enumConstant hasInitializer v
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          type: A
          constantInitializer
            fragment: <testLibraryFragment>::@enum::A::@field::v
            expression: expression_0
          getter: <testLibraryFragment>::@enum::A::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          type: List<A>
          constantInitializer
            fragment: <testLibraryFragment>::@enum::A::@field::values
            expression: expression_1
          getter: <testLibraryFragment>::@enum::A::@getter::values#element
        final hasInitializer foo
          firstFragment: <testLibraryFragment>::@enum::A::@field::foo
          type: int
          constantInitializer
            fragment: <testLibraryFragment>::@enum::A::@field::foo
            expression: expression_2
          getter: <testLibraryFragment>::@enum::A::@getter::foo#element
      constructors
        synthetic const new
          firstFragment: <testLibraryFragment>::@enum::A::@constructor::new
      getters
        synthetic static get v
          firstFragment: <testLibraryFragment>::@enum::A::@getter::v
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::A::@getter::values
        synthetic get foo
          firstFragment: <testLibraryFragment>::@enum::A::@getter::foo
''');
  }

  test_augmented_getters_augment_field2() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment enum A {;
  augment int get foo => 0;
}
''');

    newFile('$testPackageLibPath/b.dart', r'''
part of 'test.dart';
augment enum A {;
  augment int get foo => 0;
}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
part 'b.dart';
enum A {
  v;
  final int foo = 0;
}
''');

    configuration
      ..withConstantInitializers = false
      ..withPropertyLinking = true;
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
      enums
        enum A @35
          reference: <testLibraryFragment>::@enum::A
          enclosingElement3: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @41
              reference: <testLibraryFragment>::@enum::A::@field::v
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: A
              shouldUseTypeForInitializerInference: false
              id: field_0
              getter: getter_0
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: List<A>
              id: field_1
              getter: getter_1
            final foo @56
              reference: <testLibraryFragment>::@enum::A::@field::foo
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: int
              shouldUseTypeForInitializerInference: true
              id: field_2
              getter: getter_2
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@enum::A
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: A
              id: getter_0
              variable: field_0
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: List<A>
              id: getter_1
              variable: field_1
            synthetic get foo @-1
              reference: <testLibraryFragment>::@enum::A::@getter::foo
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: int
              id: getter_2
              variable: field_2
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getterAugmentation::foo
          augmented
            fields
              <testLibraryFragment>::@enum::A::@field::foo
              <testLibraryFragment>::@enum::A::@field::v
              <testLibraryFragment>::@enum::A::@field::values
            constants
              <testLibraryFragment>::@enum::A::@field::v
            constructors
              <testLibraryFragment>::@enum::A::@constructor::new
            accessors
              <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@getterAugmentation::foo
              <testLibraryFragment>::@enum::A::@getter::v
              <testLibraryFragment>::@enum::A::@getter::values
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          augmentation: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          accessors
            augment get foo @57
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getterAugmentation::foo
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              returnType: int
              id: getter_3
              variable: <null>
              augmentationTarget: <testLibraryFragment>::@enum::A::@getter::foo
              augmentation: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@getterAugmentation::foo
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @34
          reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/b.dart
          augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          accessors
            augment get foo @57
              reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@getterAugmentation::foo
              enclosingElement3: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
              returnType: int
              id: getter_4
              variable: <null>
              augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getterAugmentation::foo
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @35
          reference: <testLibraryFragment>::@enum::A
          element: <testLibrary>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            hasInitializer v @41
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <testLibraryFragment>::@enum::A::@field::v#element
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibraryFragment>::@enum::A
                      element2: <testLibrary>::@enum::A
                      type: A
                    staticElement: <testLibraryFragment>::@enum::A::@constructor::new
                    element: <testLibraryFragment>::@enum::A::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            synthetic values
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <testLibraryFragment>::@enum::A::@field::values#element
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::A::@getter::v
                      element: <testLibraryFragment>::@enum::A::@getter::v#element
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
              getter2: <testLibraryFragment>::@enum::A::@getter::values
            hasInitializer foo @56
              reference: <testLibraryFragment>::@enum::A::@field::foo
              element: <testLibraryFragment>::@enum::A::@field::foo#element
              initializer: expression_2
                IntegerLiteral
                  literal: 0 @62
                  staticType: int
              getter2: <testLibraryFragment>::@enum::A::@getter::foo
          constructors
            synthetic const new
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <testLibraryFragment>::@enum::A::@constructor::new#element
              typeName: A
          getters
            synthetic get v
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <testLibraryFragment>::@enum::A::@getter::v#element
            synthetic get values
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <testLibraryFragment>::@enum::A::@getter::values#element
            synthetic get foo
              reference: <testLibraryFragment>::@enum::A::@getter::foo
              element: <testLibraryFragment>::@enum::A::@getter::foo#element
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getterAugmentation::foo
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibrary>::@enum::A
          previousFragment: <testLibraryFragment>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          getters
            augment get foo @57
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getterAugmentation::foo
              element: <testLibraryFragment>::@enum::A::@getter::foo#element
              previousFragment: <testLibraryFragment>::@enum::A::@getter::foo
              nextFragment: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@getterAugmentation::foo
    <testLibrary>::@fragment::package:test/b.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          element: <testLibrary>::@enum::A
          previousFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          getters
            augment get foo @57
              reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@getterAugmentation::foo
              element: <testLibraryFragment>::@enum::A::@getter::foo#element
              previousFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getterAugmentation::foo
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const enumConstant hasInitializer v
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          type: A
          constantInitializer
            fragment: <testLibraryFragment>::@enum::A::@field::v
            expression: expression_0
          getter: <testLibraryFragment>::@enum::A::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          type: List<A>
          constantInitializer
            fragment: <testLibraryFragment>::@enum::A::@field::values
            expression: expression_1
          getter: <testLibraryFragment>::@enum::A::@getter::values#element
        final hasInitializer foo
          firstFragment: <testLibraryFragment>::@enum::A::@field::foo
          type: int
          constantInitializer
            fragment: <testLibraryFragment>::@enum::A::@field::foo
            expression: expression_2
          getter: <testLibraryFragment>::@enum::A::@getter::foo#element
      constructors
        synthetic const new
          firstFragment: <testLibraryFragment>::@enum::A::@constructor::new
      getters
        synthetic static get v
          firstFragment: <testLibraryFragment>::@enum::A::@getter::v
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::A::@getter::values
        synthetic get foo
          firstFragment: <testLibraryFragment>::@enum::A::@getter::foo
''');
  }

  test_augmented_getters_augment_getter() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment enum A {;
  augment int get foo1 => 0;
}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
enum A {
  v;
  int get foo1 => 0;
  int get foo2 => 0;
}
''');

    configuration
      ..withConstantInitializers = false
      ..withPropertyLinking = true;
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
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          enclosingElement3: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: A
              shouldUseTypeForInitializerInference: false
              id: field_0
              getter: getter_0
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: List<A>
              id: field_1
              getter: getter_1
            synthetic foo1 @-1
              reference: <testLibraryFragment>::@enum::A::@field::foo1
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: int
              id: field_2
              getter: getter_2
            synthetic foo2 @-1
              reference: <testLibraryFragment>::@enum::A::@field::foo2
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: int
              id: field_3
              getter: getter_3
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@enum::A
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: A
              id: getter_0
              variable: field_0
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: List<A>
              id: getter_1
              variable: field_1
            get foo1 @39
              reference: <testLibraryFragment>::@enum::A::@getter::foo1
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: int
              id: getter_2
              variable: field_2
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getterAugmentation::foo1
            get foo2 @60
              reference: <testLibraryFragment>::@enum::A::@getter::foo2
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: int
              id: getter_3
              variable: field_3
          augmented
            fields
              <testLibraryFragment>::@enum::A::@field::foo1
              <testLibraryFragment>::@enum::A::@field::foo2
              <testLibraryFragment>::@enum::A::@field::v
              <testLibraryFragment>::@enum::A::@field::values
            constants
              <testLibraryFragment>::@enum::A::@field::v
            constructors
              <testLibraryFragment>::@enum::A::@constructor::new
            accessors
              <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getterAugmentation::foo1
              <testLibraryFragment>::@enum::A::@getter::foo2
              <testLibraryFragment>::@enum::A::@getter::v
              <testLibraryFragment>::@enum::A::@getter::values
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          accessors
            augment get foo1 @57
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getterAugmentation::foo1
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              returnType: int
              id: getter_4
              variable: <null>
              augmentationTarget: <testLibraryFragment>::@enum::A::@getter::foo1
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          element: <testLibrary>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            hasInitializer v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <testLibraryFragment>::@enum::A::@field::v#element
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibraryFragment>::@enum::A
                      element2: <testLibrary>::@enum::A
                      type: A
                    staticElement: <testLibraryFragment>::@enum::A::@constructor::new
                    element: <testLibraryFragment>::@enum::A::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            synthetic values
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <testLibraryFragment>::@enum::A::@field::values#element
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::A::@getter::v
                      element: <testLibraryFragment>::@enum::A::@getter::v#element
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
              getter2: <testLibraryFragment>::@enum::A::@getter::values
            synthetic foo1
              reference: <testLibraryFragment>::@enum::A::@field::foo1
              element: <testLibraryFragment>::@enum::A::@field::foo1#element
              getter2: <testLibraryFragment>::@enum::A::@getter::foo1
            synthetic foo2
              reference: <testLibraryFragment>::@enum::A::@field::foo2
              element: <testLibraryFragment>::@enum::A::@field::foo2#element
              getter2: <testLibraryFragment>::@enum::A::@getter::foo2
          constructors
            synthetic const new
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <testLibraryFragment>::@enum::A::@constructor::new#element
              typeName: A
          getters
            synthetic get v
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <testLibraryFragment>::@enum::A::@getter::v#element
            synthetic get values
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <testLibraryFragment>::@enum::A::@getter::values#element
            get foo1 @39
              reference: <testLibraryFragment>::@enum::A::@getter::foo1
              element: <testLibraryFragment>::@enum::A::@getter::foo1#element
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getterAugmentation::foo1
            get foo2 @60
              reference: <testLibraryFragment>::@enum::A::@getter::foo2
              element: <testLibraryFragment>::@enum::A::@getter::foo2#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibrary>::@enum::A
          previousFragment: <testLibraryFragment>::@enum::A
          getters
            augment get foo1 @57
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getterAugmentation::foo1
              element: <testLibraryFragment>::@enum::A::@getter::foo1#element
              previousFragment: <testLibraryFragment>::@enum::A::@getter::foo1
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const enumConstant hasInitializer v
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          type: A
          constantInitializer
            fragment: <testLibraryFragment>::@enum::A::@field::v
            expression: expression_0
          getter: <testLibraryFragment>::@enum::A::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          type: List<A>
          constantInitializer
            fragment: <testLibraryFragment>::@enum::A::@field::values
            expression: expression_1
          getter: <testLibraryFragment>::@enum::A::@getter::values#element
        synthetic foo1
          firstFragment: <testLibraryFragment>::@enum::A::@field::foo1
          type: int
          getter: <testLibraryFragment>::@enum::A::@getter::foo1#element
        synthetic foo2
          firstFragment: <testLibraryFragment>::@enum::A::@field::foo2
          type: int
          getter: <testLibraryFragment>::@enum::A::@getter::foo2#element
      constructors
        synthetic const new
          firstFragment: <testLibraryFragment>::@enum::A::@constructor::new
      getters
        synthetic static get v
          firstFragment: <testLibraryFragment>::@enum::A::@getter::v
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::A::@getter::values
        get foo2
          firstFragment: <testLibraryFragment>::@enum::A::@getter::foo2
        get foo1
          firstFragment: <testLibraryFragment>::@enum::A::@getter::foo1
''');
  }

  test_augmented_getters_augment_getter2_oneLib_oneTop() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment enum A {;
  augment int get foo => 0;
  augment int get foo => 0;
}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
enum A {
  v;
  int get foo => 0;
}
''');

    configuration
      ..withConstantInitializers = false
      ..withPropertyLinking = true;
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
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          enclosingElement3: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: A
              shouldUseTypeForInitializerInference: false
              id: field_0
              getter: getter_0
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: List<A>
              id: field_1
              getter: getter_1
            synthetic foo @-1
              reference: <testLibraryFragment>::@enum::A::@field::foo
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: int
              id: field_2
              getter: getter_2
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@enum::A
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: A
              id: getter_0
              variable: field_0
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: List<A>
              id: getter_1
              variable: field_1
            get foo @39
              reference: <testLibraryFragment>::@enum::A::@getter::foo
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: int
              id: getter_2
              variable: field_2
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getterAugmentation::foo::@def::0
          augmented
            fields
              <testLibraryFragment>::@enum::A::@field::foo
              <testLibraryFragment>::@enum::A::@field::v
              <testLibraryFragment>::@enum::A::@field::values
            constants
              <testLibraryFragment>::@enum::A::@field::v
            constructors
              <testLibraryFragment>::@enum::A::@constructor::new
            accessors
              <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getterAugmentation::foo::@def::1
              <testLibraryFragment>::@enum::A::@getter::v
              <testLibraryFragment>::@enum::A::@getter::values
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          accessors
            augment get foo @57
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getterAugmentation::foo::@def::0
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              returnType: int
              id: getter_3
              variable: <null>
              augmentationTarget: <testLibraryFragment>::@enum::A::@getter::foo
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getterAugmentation::foo::@def::1
            augment get foo @85
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getterAugmentation::foo::@def::1
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              returnType: int
              id: getter_4
              variable: <null>
              augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getterAugmentation::foo::@def::0
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          element: <testLibrary>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            hasInitializer v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <testLibraryFragment>::@enum::A::@field::v#element
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibraryFragment>::@enum::A
                      element2: <testLibrary>::@enum::A
                      type: A
                    staticElement: <testLibraryFragment>::@enum::A::@constructor::new
                    element: <testLibraryFragment>::@enum::A::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            synthetic values
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <testLibraryFragment>::@enum::A::@field::values#element
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::A::@getter::v
                      element: <testLibraryFragment>::@enum::A::@getter::v#element
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
              getter2: <testLibraryFragment>::@enum::A::@getter::values
            synthetic foo
              reference: <testLibraryFragment>::@enum::A::@field::foo
              element: <testLibraryFragment>::@enum::A::@field::foo#element
              getter2: <testLibraryFragment>::@enum::A::@getter::foo
          constructors
            synthetic const new
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <testLibraryFragment>::@enum::A::@constructor::new#element
              typeName: A
          getters
            synthetic get v
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <testLibraryFragment>::@enum::A::@getter::v#element
            synthetic get values
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <testLibraryFragment>::@enum::A::@getter::values#element
            get foo @39
              reference: <testLibraryFragment>::@enum::A::@getter::foo
              element: <testLibraryFragment>::@enum::A::@getter::foo#element
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getterAugmentation::foo::@def::0
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibrary>::@enum::A
          previousFragment: <testLibraryFragment>::@enum::A
          getters
            augment get foo @57
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getterAugmentation::foo::@def::0
              element: <testLibraryFragment>::@enum::A::@getter::foo#element
              previousFragment: <testLibraryFragment>::@enum::A::@getter::foo
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getterAugmentation::foo::@def::1
            augment get foo @85
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getterAugmentation::foo::@def::1
              element: <testLibraryFragment>::@enum::A::@getter::foo#element
              previousFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getterAugmentation::foo::@def::0
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const enumConstant hasInitializer v
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          type: A
          constantInitializer
            fragment: <testLibraryFragment>::@enum::A::@field::v
            expression: expression_0
          getter: <testLibraryFragment>::@enum::A::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          type: List<A>
          constantInitializer
            fragment: <testLibraryFragment>::@enum::A::@field::values
            expression: expression_1
          getter: <testLibraryFragment>::@enum::A::@getter::values#element
        synthetic foo
          firstFragment: <testLibraryFragment>::@enum::A::@field::foo
          type: int
          getter: <testLibraryFragment>::@enum::A::@getter::foo#element
      constructors
        synthetic const new
          firstFragment: <testLibraryFragment>::@enum::A::@constructor::new
      getters
        synthetic static get v
          firstFragment: <testLibraryFragment>::@enum::A::@getter::v
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::A::@getter::values
        get foo
          firstFragment: <testLibraryFragment>::@enum::A::@getter::foo
''');
  }

  test_augmented_getters_augment_getter2_twoLib() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment enum A {;
  augment int get foo => 0;
}
''');

    newFile('$testPackageLibPath/b.dart', r'''
part of 'test.dart';
augment enum A {;
  augment int get foo => 0;
}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
part 'b.dart';
enum A {
  v;
  int get foo => 0;
}
''');

    configuration
      ..withConstantInitializers = false
      ..withPropertyLinking = true;
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
      enums
        enum A @35
          reference: <testLibraryFragment>::@enum::A
          enclosingElement3: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @41
              reference: <testLibraryFragment>::@enum::A::@field::v
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: A
              shouldUseTypeForInitializerInference: false
              id: field_0
              getter: getter_0
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: List<A>
              id: field_1
              getter: getter_1
            synthetic foo @-1
              reference: <testLibraryFragment>::@enum::A::@field::foo
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: int
              id: field_2
              getter: getter_2
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@enum::A
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: A
              id: getter_0
              variable: field_0
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: List<A>
              id: getter_1
              variable: field_1
            get foo @54
              reference: <testLibraryFragment>::@enum::A::@getter::foo
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: int
              id: getter_2
              variable: field_2
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getterAugmentation::foo
          augmented
            fields
              <testLibraryFragment>::@enum::A::@field::foo
              <testLibraryFragment>::@enum::A::@field::v
              <testLibraryFragment>::@enum::A::@field::values
            constants
              <testLibraryFragment>::@enum::A::@field::v
            constructors
              <testLibraryFragment>::@enum::A::@constructor::new
            accessors
              <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@getterAugmentation::foo
              <testLibraryFragment>::@enum::A::@getter::v
              <testLibraryFragment>::@enum::A::@getter::values
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          augmentation: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          accessors
            augment get foo @57
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getterAugmentation::foo
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              returnType: int
              id: getter_3
              variable: <null>
              augmentationTarget: <testLibraryFragment>::@enum::A::@getter::foo
              augmentation: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@getterAugmentation::foo
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @34
          reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/b.dart
          augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          accessors
            augment get foo @57
              reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@getterAugmentation::foo
              enclosingElement3: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
              returnType: int
              id: getter_4
              variable: <null>
              augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getterAugmentation::foo
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @35
          reference: <testLibraryFragment>::@enum::A
          element: <testLibrary>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            hasInitializer v @41
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <testLibraryFragment>::@enum::A::@field::v#element
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibraryFragment>::@enum::A
                      element2: <testLibrary>::@enum::A
                      type: A
                    staticElement: <testLibraryFragment>::@enum::A::@constructor::new
                    element: <testLibraryFragment>::@enum::A::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            synthetic values
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <testLibraryFragment>::@enum::A::@field::values#element
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::A::@getter::v
                      element: <testLibraryFragment>::@enum::A::@getter::v#element
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
              getter2: <testLibraryFragment>::@enum::A::@getter::values
            synthetic foo
              reference: <testLibraryFragment>::@enum::A::@field::foo
              element: <testLibraryFragment>::@enum::A::@field::foo#element
              getter2: <testLibraryFragment>::@enum::A::@getter::foo
          constructors
            synthetic const new
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <testLibraryFragment>::@enum::A::@constructor::new#element
              typeName: A
          getters
            synthetic get v
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <testLibraryFragment>::@enum::A::@getter::v#element
            synthetic get values
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <testLibraryFragment>::@enum::A::@getter::values#element
            get foo @54
              reference: <testLibraryFragment>::@enum::A::@getter::foo
              element: <testLibraryFragment>::@enum::A::@getter::foo#element
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getterAugmentation::foo
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibrary>::@enum::A
          previousFragment: <testLibraryFragment>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          getters
            augment get foo @57
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getterAugmentation::foo
              element: <testLibraryFragment>::@enum::A::@getter::foo#element
              previousFragment: <testLibraryFragment>::@enum::A::@getter::foo
              nextFragment: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@getterAugmentation::foo
    <testLibrary>::@fragment::package:test/b.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          element: <testLibrary>::@enum::A
          previousFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          getters
            augment get foo @57
              reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@getterAugmentation::foo
              element: <testLibraryFragment>::@enum::A::@getter::foo#element
              previousFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getterAugmentation::foo
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const enumConstant hasInitializer v
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          type: A
          constantInitializer
            fragment: <testLibraryFragment>::@enum::A::@field::v
            expression: expression_0
          getter: <testLibraryFragment>::@enum::A::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          type: List<A>
          constantInitializer
            fragment: <testLibraryFragment>::@enum::A::@field::values
            expression: expression_1
          getter: <testLibraryFragment>::@enum::A::@getter::values#element
        synthetic foo
          firstFragment: <testLibraryFragment>::@enum::A::@field::foo
          type: int
          getter: <testLibraryFragment>::@enum::A::@getter::foo#element
      constructors
        synthetic const new
          firstFragment: <testLibraryFragment>::@enum::A::@constructor::new
      getters
        synthetic static get v
          firstFragment: <testLibraryFragment>::@enum::A::@getter::v
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::A::@getter::values
        get foo
          firstFragment: <testLibraryFragment>::@enum::A::@getter::foo
''');
  }

  test_augmented_getters_augment_nothing() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment enum A {;
  augment int get foo => 0;
}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
enum A {
  v
}
''');

    configuration
      ..withConstantInitializers = false
      ..withConstructors = false
      ..withPropertyLinking = true;
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
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          enclosingElement3: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: A
              shouldUseTypeForInitializerInference: false
              id: field_0
              getter: getter_0
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: List<A>
              id: field_1
              getter: getter_1
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: A
              id: getter_0
              variable: field_0
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: List<A>
              id: getter_1
              variable: field_1
          augmented
            fields
              <testLibraryFragment>::@enum::A::@field::v
              <testLibraryFragment>::@enum::A::@field::values
            constants
              <testLibraryFragment>::@enum::A::@field::v
            accessors
              <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getterAugmentation::foo
              <testLibraryFragment>::@enum::A::@getter::v
              <testLibraryFragment>::@enum::A::@getter::values
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          accessors
            augment get foo @57
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getterAugmentation::foo
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              returnType: int
              id: getter_2
              variable: <null>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          element: <testLibrary>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            hasInitializer v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <testLibraryFragment>::@enum::A::@field::v#element
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibraryFragment>::@enum::A
                      element2: <testLibrary>::@enum::A
                      type: A
                    staticElement: <testLibraryFragment>::@enum::A::@constructor::new
                    element: <testLibraryFragment>::@enum::A::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            synthetic values
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <testLibraryFragment>::@enum::A::@field::values#element
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::A::@getter::v
                      element: <testLibraryFragment>::@enum::A::@getter::v#element
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
              getter2: <testLibraryFragment>::@enum::A::@getter::values
          getters
            synthetic get v
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <testLibraryFragment>::@enum::A::@getter::v#element
            synthetic get values
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <testLibraryFragment>::@enum::A::@getter::values#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibrary>::@enum::A
          previousFragment: <testLibraryFragment>::@enum::A
          getters
            augment get foo @57
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getterAugmentation::foo
              element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getterAugmentation::foo#element
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const enumConstant hasInitializer v
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          type: A
          constantInitializer
            fragment: <testLibraryFragment>::@enum::A::@field::v
            expression: expression_0
          getter: <testLibraryFragment>::@enum::A::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          type: List<A>
          constantInitializer
            fragment: <testLibraryFragment>::@enum::A::@field::values
            expression: expression_1
          getter: <testLibraryFragment>::@enum::A::@getter::values#element
      getters
        synthetic static get v
          firstFragment: <testLibraryFragment>::@enum::A::@getter::v
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::A::@getter::values
        get foo
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getterAugmentation::foo
''');
  }

  test_augmented_interfaces() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment enum A implements I2 {}
class I2 {}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
enum A implements I1 {
  v
}
class I1 {}
''');

    configuration.withConstantInitializers = false;
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
        class I1 @50
          reference: <testLibraryFragment>::@class::I1
          enclosingElement3: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::I1::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::I1
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          enclosingElement3: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          interfaces
            I1
          fields
            static const enumConstant v @40
              reference: <testLibraryFragment>::@enum::A::@field::v
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: A
              shouldUseTypeForInitializerInference: false
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: List<A>
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@enum::A
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: A
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: List<A>
          augmented
            interfaces
              I1
              I2
            fields
              <testLibraryFragment>::@enum::A::@field::v
              <testLibraryFragment>::@enum::A::@field::values
            constants
              <testLibraryFragment>::@enum::A::@field::v
            constructors
              <testLibraryFragment>::@enum::A::@constructor::new
            accessors
              <testLibraryFragment>::@enum::A::@getter::v
              <testLibraryFragment>::@enum::A::@getter::values
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      classes
        class I2 @59
          reference: <testLibrary>::@fragment::package:test/a.dart::@class::I2
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          constructors
            synthetic @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@class::I2::@constructor::new
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@class::I2
      enums
        augment enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
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
        class I1 @50
          reference: <testLibraryFragment>::@class::I1
          element: <testLibrary>::@class::I1
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::I1::@constructor::new
              element: <testLibraryFragment>::@class::I1::@constructor::new#element
              typeName: I1
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          element: <testLibrary>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            hasInitializer v @40
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <testLibraryFragment>::@enum::A::@field::v#element
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibraryFragment>::@enum::A
                      element2: <testLibrary>::@enum::A
                      type: A
                    staticElement: <testLibraryFragment>::@enum::A::@constructor::new
                    element: <testLibraryFragment>::@enum::A::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            synthetic values
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <testLibraryFragment>::@enum::A::@field::values#element
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::A::@getter::v
                      element: <testLibraryFragment>::@enum::A::@getter::v#element
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
              getter2: <testLibraryFragment>::@enum::A::@getter::values
          constructors
            synthetic const new
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <testLibraryFragment>::@enum::A::@constructor::new#element
              typeName: A
          getters
            synthetic get v
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <testLibraryFragment>::@enum::A::@getter::v#element
            synthetic get values
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <testLibraryFragment>::@enum::A::@getter::values#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      classes
        class I2 @59
          reference: <testLibrary>::@fragment::package:test/a.dart::@class::I2
          element: <testLibrary>::@class::I2
          constructors
            synthetic new
              reference: <testLibrary>::@fragment::package:test/a.dart::@class::I2::@constructor::new
              element: <testLibrary>::@fragment::package:test/a.dart::@class::I2::@constructor::new#element
              typeName: I2
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibrary>::@enum::A
          previousFragment: <testLibraryFragment>::@enum::A
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
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      interfaces
        I1
        I2
      fields
        static const enumConstant hasInitializer v
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          type: A
          constantInitializer
            fragment: <testLibraryFragment>::@enum::A::@field::v
            expression: expression_0
          getter: <testLibraryFragment>::@enum::A::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          type: List<A>
          constantInitializer
            fragment: <testLibraryFragment>::@enum::A::@field::values
            expression: expression_1
          getter: <testLibraryFragment>::@enum::A::@getter::values#element
      constructors
        synthetic const new
          firstFragment: <testLibraryFragment>::@enum::A::@constructor::new
      getters
        synthetic static get v
          firstFragment: <testLibraryFragment>::@enum::A::@getter::v
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::A::@getter::values
''');
  }

  test_augmented_interfaces_chain() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
part 'b.dart';
augment enum A implements I2 {}
class I2 {}
''');

    newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';
augment enum A implements I3 {}
class I3 {}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
enum A implements I1 {
  v
}
class I1 {}
''');

    configuration.withConstantInitializers = false;
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
        class I1 @50
          reference: <testLibraryFragment>::@class::I1
          enclosingElement3: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::I1::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::I1
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          enclosingElement3: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          interfaces
            I1
          fields
            static const enumConstant v @40
              reference: <testLibraryFragment>::@enum::A::@field::v
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: A
              shouldUseTypeForInitializerInference: false
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: List<A>
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@enum::A
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: A
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: List<A>
          augmented
            interfaces
              I1
              I2
              I3
            fields
              <testLibraryFragment>::@enum::A::@field::v
              <testLibraryFragment>::@enum::A::@field::values
            constants
              <testLibraryFragment>::@enum::A::@field::v
            constructors
              <testLibraryFragment>::@enum::A::@constructor::new
            accessors
              <testLibraryFragment>::@enum::A::@getter::v
              <testLibraryFragment>::@enum::A::@getter::values
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      parts
        part_1
          uri: package:test/b.dart
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          unit: <testLibrary>::@fragment::package:test/b.dart
      classes
        class I2 @74
          reference: <testLibrary>::@fragment::package:test/a.dart::@class::I2
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          constructors
            synthetic @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@class::I2::@constructor::new
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@class::I2
      enums
        augment enum A @49
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          augmentation: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          interfaces
            I2
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
      classes
        class I3 @56
          reference: <testLibrary>::@fragment::package:test/b.dart::@class::I3
          enclosingElement3: <testLibrary>::@fragment::package:test/b.dart
          constructors
            synthetic @-1
              reference: <testLibrary>::@fragment::package:test/b.dart::@class::I3::@constructor::new
              enclosingElement3: <testLibrary>::@fragment::package:test/b.dart::@class::I3
      enums
        augment enum A @31
          reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/b.dart
          augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
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
        class I1 @50
          reference: <testLibraryFragment>::@class::I1
          element: <testLibrary>::@class::I1
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::I1::@constructor::new
              element: <testLibraryFragment>::@class::I1::@constructor::new#element
              typeName: I1
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          element: <testLibrary>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            hasInitializer v @40
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <testLibraryFragment>::@enum::A::@field::v#element
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibraryFragment>::@enum::A
                      element2: <testLibrary>::@enum::A
                      type: A
                    staticElement: <testLibraryFragment>::@enum::A::@constructor::new
                    element: <testLibraryFragment>::@enum::A::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            synthetic values
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <testLibraryFragment>::@enum::A::@field::values#element
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::A::@getter::v
                      element: <testLibraryFragment>::@enum::A::@getter::v#element
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
              getter2: <testLibraryFragment>::@enum::A::@getter::values
          constructors
            synthetic const new
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <testLibraryFragment>::@enum::A::@constructor::new#element
              typeName: A
          getters
            synthetic get v
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <testLibraryFragment>::@enum::A::@getter::v#element
            synthetic get values
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <testLibraryFragment>::@enum::A::@getter::values#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      classes
        class I2 @74
          reference: <testLibrary>::@fragment::package:test/a.dart::@class::I2
          element: <testLibrary>::@class::I2
          constructors
            synthetic new
              reference: <testLibrary>::@fragment::package:test/a.dart::@class::I2::@constructor::new
              element: <testLibrary>::@fragment::package:test/a.dart::@class::I2::@constructor::new#element
              typeName: I2
      enums
        enum A @49
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibrary>::@enum::A
          previousFragment: <testLibraryFragment>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
    <testLibrary>::@fragment::package:test/b.dart
      element: <testLibrary>
      enclosingFragment: <testLibrary>::@fragment::package:test/a.dart
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      classes
        class I3 @56
          reference: <testLibrary>::@fragment::package:test/b.dart::@class::I3
          element: <testLibrary>::@class::I3
          constructors
            synthetic new
              reference: <testLibrary>::@fragment::package:test/b.dart::@class::I3::@constructor::new
              element: <testLibrary>::@fragment::package:test/b.dart::@class::I3::@constructor::new#element
              typeName: I3
      enums
        enum A @31
          reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          element: <testLibrary>::@enum::A
          previousFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
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
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      interfaces
        I1
        I2
        I3
      fields
        static const enumConstant hasInitializer v
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          type: A
          constantInitializer
            fragment: <testLibraryFragment>::@enum::A::@field::v
            expression: expression_0
          getter: <testLibraryFragment>::@enum::A::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          type: List<A>
          constantInitializer
            fragment: <testLibraryFragment>::@enum::A::@field::values
            expression: expression_1
          getter: <testLibraryFragment>::@enum::A::@getter::values#element
      constructors
        synthetic const new
          firstFragment: <testLibraryFragment>::@enum::A::@constructor::new
      getters
        synthetic static get v
          firstFragment: <testLibraryFragment>::@enum::A::@getter::v
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::A::@getter::values
''');
  }

  test_augmented_interfaces_generic() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment enum A<T2> implements I2<T2> {}
class I2<E> {}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
enum A<T> implements I1 {
  v<int>()
}
class I1 {}
''');

    configuration.withConstantInitializers = false;
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
        class I1 @60
          reference: <testLibraryFragment>::@class::I1
          enclosingElement3: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::I1::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::I1
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant T @22
              defaultType: dynamic
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          interfaces
            I1
          fields
            static const enumConstant v @43
              reference: <testLibraryFragment>::@enum::A::@field::v
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: A<int>
              shouldUseTypeForInitializerInference: false
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: List<A<dynamic>>
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@enum::A
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: A<int>
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: List<A<dynamic>>
          augmented
            interfaces
              I1
              I2<T>
            fields
              <testLibraryFragment>::@enum::A::@field::v
              <testLibraryFragment>::@enum::A::@field::values
            constants
              <testLibraryFragment>::@enum::A::@field::v
            constructors
              <testLibraryFragment>::@enum::A::@constructor::new
            accessors
              <testLibraryFragment>::@enum::A::@getter::v
              <testLibraryFragment>::@enum::A::@getter::values
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      classes
        class I2 @67
          reference: <testLibrary>::@fragment::package:test/a.dart::@class::I2
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          typeParameters
            covariant E @70
              defaultType: dynamic
          constructors
            synthetic @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@class::I2::@constructor::new
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@class::I2
      enums
        augment enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          typeParameters
            covariant T2 @36
              defaultType: dynamic
          augmentationTarget: <testLibraryFragment>::@enum::A
          interfaces
            I2<T2>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      classes
        class I1 @60
          reference: <testLibraryFragment>::@class::I1
          element: <testLibrary>::@class::I1
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::I1::@constructor::new
              element: <testLibraryFragment>::@class::I1::@constructor::new#element
              typeName: I1
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          element: <testLibrary>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          typeParameters
            T @22
              element: <not-implemented>
          fields
            hasInitializer v @43
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <testLibraryFragment>::@enum::A::@field::v#element
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      typeArguments: TypeArgumentList
                        leftBracket: < @44
                        arguments
                          NamedType
                            name: int @45
                            element: dart:core::<fragment>::@class::int
                            element2: dart:core::@class::int
                            type: int
                        rightBracket: > @48
                      element: <testLibraryFragment>::@enum::A
                      element2: <testLibrary>::@enum::A
                      type: A<int>
                    staticElement: ConstructorMember
                      base: <testLibraryFragment>::@enum::A::@constructor::new
                      substitution: {T: int}
                    element: <testLibraryFragment>::@enum::A::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A<int>
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            synthetic values
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <testLibraryFragment>::@enum::A::@field::values#element
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::A::@getter::v
                      element: <testLibraryFragment>::@enum::A::@getter::v#element
                      staticType: A<int>
                  rightBracket: ] @0
                  staticType: List<A<dynamic>>
              getter2: <testLibraryFragment>::@enum::A::@getter::values
          constructors
            synthetic const new
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <testLibraryFragment>::@enum::A::@constructor::new#element
              typeName: A
          getters
            synthetic get v
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <testLibraryFragment>::@enum::A::@getter::v#element
            synthetic get values
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <testLibraryFragment>::@enum::A::@getter::values#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      classes
        class I2 @67
          reference: <testLibrary>::@fragment::package:test/a.dart::@class::I2
          element: <testLibrary>::@class::I2
          typeParameters
            E @70
              element: <not-implemented>
          constructors
            synthetic new
              reference: <testLibrary>::@fragment::package:test/a.dart::@class::I2::@constructor::new
              element: <testLibrary>::@fragment::package:test/a.dart::@class::I2::@constructor::new#element
              typeName: I2
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibrary>::@enum::A
          previousFragment: <testLibraryFragment>::@enum::A
          typeParameters
            T2 @36
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
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: <testLibraryFragment>::@enum::A
      typeParameters
        T
      supertype: Enum
      interfaces
        I1
        I2<T>
      fields
        static const enumConstant hasInitializer v
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          type: A<int>
          constantInitializer
            fragment: <testLibraryFragment>::@enum::A::@field::v
            expression: expression_0
          getter: <testLibraryFragment>::@enum::A::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          type: List<A<dynamic>>
          constantInitializer
            fragment: <testLibraryFragment>::@enum::A::@field::values
            expression: expression_1
          getter: <testLibraryFragment>::@enum::A::@getter::values#element
      constructors
        synthetic const new
          firstFragment: <testLibraryFragment>::@enum::A::@constructor::new
      getters
        synthetic static get v
          firstFragment: <testLibraryFragment>::@enum::A::@getter::v
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::A::@getter::values
''');
  }

  test_augmented_interfaces_generic_mismatch() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment enum A<T2, T3> implements I2<T2> {}
class I2<E> {}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
enum A<T> implements I1 {
  v
}
class I1 {}
''');

    configuration.withConstantInitializers = false;
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
        class I1 @53
          reference: <testLibraryFragment>::@class::I1
          enclosingElement3: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::I1::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::I1
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant T @22
              defaultType: dynamic
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          interfaces
            I1
          fields
            static const enumConstant v @43
              reference: <testLibraryFragment>::@enum::A::@field::v
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: A<dynamic>
              shouldUseTypeForInitializerInference: false
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: List<A<dynamic>>
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@enum::A
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: A<dynamic>
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: List<A<dynamic>>
          augmented
            interfaces
              I1
            fields
              <testLibraryFragment>::@enum::A::@field::v
              <testLibraryFragment>::@enum::A::@field::values
            constants
              <testLibraryFragment>::@enum::A::@field::v
            constructors
              <testLibraryFragment>::@enum::A::@constructor::new
            accessors
              <testLibraryFragment>::@enum::A::@getter::v
              <testLibraryFragment>::@enum::A::@getter::values
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      classes
        class I2 @71
          reference: <testLibrary>::@fragment::package:test/a.dart::@class::I2
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          typeParameters
            covariant E @74
              defaultType: dynamic
          constructors
            synthetic @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@class::I2::@constructor::new
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@class::I2
      enums
        augment enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          typeParameters
            covariant T2 @36
              defaultType: dynamic
            covariant T3 @40
              defaultType: dynamic
          augmentationTarget: <testLibraryFragment>::@enum::A
          interfaces
            I2<T2>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      classes
        class I1 @53
          reference: <testLibraryFragment>::@class::I1
          element: <testLibrary>::@class::I1
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::I1::@constructor::new
              element: <testLibraryFragment>::@class::I1::@constructor::new#element
              typeName: I1
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          element: <testLibrary>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          typeParameters
            T @22
              element: <not-implemented>
          fields
            hasInitializer v @43
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <testLibraryFragment>::@enum::A::@field::v#element
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibraryFragment>::@enum::A
                      element2: <testLibrary>::@enum::A
                      type: A<dynamic>
                    staticElement: ConstructorMember
                      base: <testLibraryFragment>::@enum::A::@constructor::new
                      substitution: {T: dynamic}
                    element: <testLibraryFragment>::@enum::A::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A<dynamic>
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            synthetic values
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <testLibraryFragment>::@enum::A::@field::values#element
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::A::@getter::v
                      element: <testLibraryFragment>::@enum::A::@getter::v#element
                      staticType: A<dynamic>
                  rightBracket: ] @0
                  staticType: List<A<dynamic>>
              getter2: <testLibraryFragment>::@enum::A::@getter::values
          constructors
            synthetic const new
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <testLibraryFragment>::@enum::A::@constructor::new#element
              typeName: A
          getters
            synthetic get v
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <testLibraryFragment>::@enum::A::@getter::v#element
            synthetic get values
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <testLibraryFragment>::@enum::A::@getter::values#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      classes
        class I2 @71
          reference: <testLibrary>::@fragment::package:test/a.dart::@class::I2
          element: <testLibrary>::@class::I2
          typeParameters
            E @74
              element: <not-implemented>
          constructors
            synthetic new
              reference: <testLibrary>::@fragment::package:test/a.dart::@class::I2::@constructor::new
              element: <testLibrary>::@fragment::package:test/a.dart::@class::I2::@constructor::new#element
              typeName: I2
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibrary>::@enum::A
          previousFragment: <testLibraryFragment>::@enum::A
          typeParameters
            T2 @36
              element: <not-implemented>
            T3 @40
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
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: <testLibraryFragment>::@enum::A
      typeParameters
        T
      supertype: Enum
      interfaces
        I1
      fields
        static const enumConstant hasInitializer v
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          type: A<dynamic>
          constantInitializer
            fragment: <testLibraryFragment>::@enum::A::@field::v
            expression: expression_0
          getter: <testLibraryFragment>::@enum::A::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          type: List<A<dynamic>>
          constantInitializer
            fragment: <testLibraryFragment>::@enum::A::@field::values
            expression: expression_1
          getter: <testLibraryFragment>::@enum::A::@getter::values#element
      constructors
        synthetic const new
          firstFragment: <testLibraryFragment>::@enum::A::@constructor::new
      getters
        synthetic static get v
          firstFragment: <testLibraryFragment>::@enum::A::@getter::v
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::A::@getter::values
''');
  }

  test_augmented_methods() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment enum A {;
  void bar() {}
}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
enum A {
  v;
  void foo() {}
}
''');

    configuration.withConstantInitializers = false;
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
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          enclosingElement3: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: A
              shouldUseTypeForInitializerInference: false
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: List<A>
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@enum::A
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: A
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: List<A>
          methods
            foo @36
              reference: <testLibraryFragment>::@enum::A::@method::foo
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: void
          augmented
            fields
              <testLibraryFragment>::@enum::A::@field::v
              <testLibraryFragment>::@enum::A::@field::values
            constants
              <testLibraryFragment>::@enum::A::@field::v
            constructors
              <testLibraryFragment>::@enum::A::@constructor::new
            accessors
              <testLibraryFragment>::@enum::A::@getter::v
              <testLibraryFragment>::@enum::A::@getter::values
            methods
              <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@method::bar
              <testLibraryFragment>::@enum::A::@method::foo
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          methods
            bar @46
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@method::bar
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          element: <testLibrary>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            hasInitializer v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <testLibraryFragment>::@enum::A::@field::v#element
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibraryFragment>::@enum::A
                      element2: <testLibrary>::@enum::A
                      type: A
                    staticElement: <testLibraryFragment>::@enum::A::@constructor::new
                    element: <testLibraryFragment>::@enum::A::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            synthetic values
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <testLibraryFragment>::@enum::A::@field::values#element
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::A::@getter::v
                      element: <testLibraryFragment>::@enum::A::@getter::v#element
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
              getter2: <testLibraryFragment>::@enum::A::@getter::values
          constructors
            synthetic const new
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <testLibraryFragment>::@enum::A::@constructor::new#element
              typeName: A
          getters
            synthetic get v
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <testLibraryFragment>::@enum::A::@getter::v#element
            synthetic get values
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <testLibraryFragment>::@enum::A::@getter::values#element
          methods
            foo @36
              reference: <testLibraryFragment>::@enum::A::@method::foo
              element: <testLibraryFragment>::@enum::A::@method::foo#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibrary>::@enum::A
          previousFragment: <testLibraryFragment>::@enum::A
          methods
            bar @46
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@method::bar
              element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@method::bar#element
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const enumConstant hasInitializer v
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          type: A
          constantInitializer
            fragment: <testLibraryFragment>::@enum::A::@field::v
            expression: expression_0
          getter: <testLibraryFragment>::@enum::A::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          type: List<A>
          constantInitializer
            fragment: <testLibraryFragment>::@enum::A::@field::values
            expression: expression_1
          getter: <testLibraryFragment>::@enum::A::@getter::values#element
      constructors
        synthetic const new
          firstFragment: <testLibraryFragment>::@enum::A::@constructor::new
      getters
        synthetic static get v
          firstFragment: <testLibraryFragment>::@enum::A::@getter::v
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::A::@getter::values
      methods
        foo
          reference: <testLibrary>::@enum::A::@method::foo
          firstFragment: <testLibraryFragment>::@enum::A::@method::foo
        bar
          reference: <testLibrary>::@enum::A::@method::bar
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@method::bar
''');
  }

  test_augmented_methods_add_withDefaultValue() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment enum A {;
  void foo([int x = 42]) {}
}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
enum A {
  v
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
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          enclosingElement3: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: A
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibraryFragment>::@enum::A
                      element2: <testLibrary>::@enum::A
                      type: A
                    staticElement: <testLibraryFragment>::@enum::A::@constructor::new
                    element: <testLibraryFragment>::@enum::A::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: List<A>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::A::@getter::v
                      element: <testLibraryFragment>::@enum::A::@getter::v#element
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@enum::A
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: A
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: List<A>
          augmented
            fields
              <testLibraryFragment>::@enum::A::@field::v
              <testLibraryFragment>::@enum::A::@field::values
            constants
              <testLibraryFragment>::@enum::A::@field::v
            constructors
              <testLibraryFragment>::@enum::A::@constructor::new
            accessors
              <testLibraryFragment>::@enum::A::@getter::v
              <testLibraryFragment>::@enum::A::@getter::values
            methods
              <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@method::foo
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          methods
            foo @46
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@method::foo
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              parameters
                optionalPositional default x @55
                  type: int
                  constantInitializer
                    IntegerLiteral
                      literal: 42 @59
                      staticType: int
              returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          element: <testLibrary>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            hasInitializer v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <testLibraryFragment>::@enum::A::@field::v#element
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibraryFragment>::@enum::A
                      element2: <testLibrary>::@enum::A
                      type: A
                    staticElement: <testLibraryFragment>::@enum::A::@constructor::new
                    element: <testLibraryFragment>::@enum::A::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            synthetic values
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <testLibraryFragment>::@enum::A::@field::values#element
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::A::@getter::v
                      element: <testLibraryFragment>::@enum::A::@getter::v#element
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
              getter2: <testLibraryFragment>::@enum::A::@getter::values
          constructors
            synthetic const new
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <testLibraryFragment>::@enum::A::@constructor::new#element
              typeName: A
          getters
            synthetic get v
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <testLibraryFragment>::@enum::A::@getter::v#element
            synthetic get values
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <testLibraryFragment>::@enum::A::@getter::values#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibrary>::@enum::A
          previousFragment: <testLibraryFragment>::@enum::A
          methods
            foo @46
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@method::foo
              element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@method::foo#element
              formalParameters
                default x @55
                  element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@method::foo::@parameter::x#element
                  initializer: expression_2
                    IntegerLiteral
                      literal: 42 @59
                      staticType: int
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const enumConstant hasInitializer v
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          type: A
          constantInitializer
            fragment: <testLibraryFragment>::@enum::A::@field::v
            expression: expression_0
          getter: <testLibraryFragment>::@enum::A::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          type: List<A>
          constantInitializer
            fragment: <testLibraryFragment>::@enum::A::@field::values
            expression: expression_1
          getter: <testLibraryFragment>::@enum::A::@getter::values#element
      constructors
        synthetic const new
          firstFragment: <testLibraryFragment>::@enum::A::@constructor::new
      getters
        synthetic static get v
          firstFragment: <testLibraryFragment>::@enum::A::@getter::v
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::A::@getter::values
      methods
        foo
          reference: <testLibrary>::@enum::A::@method::foo
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@method::foo
          formalParameters
            optionalPositional x
              type: int
              constantInitializer
                expression: expression_2
''');
  }

  test_augmented_methods_augment() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment enum A {;
  augment void foo1() {}
}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
enum A {
  v;
  void foo1() {}
  void foo2() {}
}
''');

    configuration.withConstantInitializers = false;
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
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          enclosingElement3: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: A
              shouldUseTypeForInitializerInference: false
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: List<A>
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@enum::A
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: A
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: List<A>
          methods
            foo1 @36
              reference: <testLibraryFragment>::@enum::A::@method::foo1
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: void
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@methodAugmentation::foo1
            foo2 @53
              reference: <testLibraryFragment>::@enum::A::@method::foo2
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: void
          augmented
            fields
              <testLibraryFragment>::@enum::A::@field::v
              <testLibraryFragment>::@enum::A::@field::values
            constants
              <testLibraryFragment>::@enum::A::@field::v
            constructors
              <testLibraryFragment>::@enum::A::@constructor::new
            accessors
              <testLibraryFragment>::@enum::A::@getter::v
              <testLibraryFragment>::@enum::A::@getter::values
            methods
              <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@methodAugmentation::foo1
              <testLibraryFragment>::@enum::A::@method::foo2
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          methods
            augment foo1 @54
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@methodAugmentation::foo1
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              returnType: void
              augmentationTarget: <testLibraryFragment>::@enum::A::@method::foo1
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          element: <testLibrary>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            hasInitializer v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <testLibraryFragment>::@enum::A::@field::v#element
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibraryFragment>::@enum::A
                      element2: <testLibrary>::@enum::A
                      type: A
                    staticElement: <testLibraryFragment>::@enum::A::@constructor::new
                    element: <testLibraryFragment>::@enum::A::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            synthetic values
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <testLibraryFragment>::@enum::A::@field::values#element
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::A::@getter::v
                      element: <testLibraryFragment>::@enum::A::@getter::v#element
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
              getter2: <testLibraryFragment>::@enum::A::@getter::values
          constructors
            synthetic const new
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <testLibraryFragment>::@enum::A::@constructor::new#element
              typeName: A
          getters
            synthetic get v
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <testLibraryFragment>::@enum::A::@getter::v#element
            synthetic get values
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <testLibraryFragment>::@enum::A::@getter::values#element
          methods
            foo1 @36
              reference: <testLibraryFragment>::@enum::A::@method::foo1
              element: <testLibraryFragment>::@enum::A::@method::foo1#element
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@methodAugmentation::foo1
            foo2 @53
              reference: <testLibraryFragment>::@enum::A::@method::foo2
              element: <testLibraryFragment>::@enum::A::@method::foo2#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibrary>::@enum::A
          previousFragment: <testLibraryFragment>::@enum::A
          methods
            augment foo1 @54
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@methodAugmentation::foo1
              element: <testLibraryFragment>::@enum::A::@method::foo1#element
              previousFragment: <testLibraryFragment>::@enum::A::@method::foo1
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const enumConstant hasInitializer v
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          type: A
          constantInitializer
            fragment: <testLibraryFragment>::@enum::A::@field::v
            expression: expression_0
          getter: <testLibraryFragment>::@enum::A::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          type: List<A>
          constantInitializer
            fragment: <testLibraryFragment>::@enum::A::@field::values
            expression: expression_1
          getter: <testLibraryFragment>::@enum::A::@getter::values#element
      constructors
        synthetic const new
          firstFragment: <testLibraryFragment>::@enum::A::@constructor::new
      getters
        synthetic static get v
          firstFragment: <testLibraryFragment>::@enum::A::@getter::v
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::A::@getter::values
      methods
        foo1
          reference: <testLibrary>::@enum::A::@method::foo1
          firstFragment: <testLibraryFragment>::@enum::A::@method::foo1
        foo2
          reference: <testLibrary>::@enum::A::@method::foo2
          firstFragment: <testLibraryFragment>::@enum::A::@method::foo2
''');
  }

  test_augmented_methods_augment2_oneLib_oneTop() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment enum A {;
  augment void foo() {}
  augment void foo() {}
}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
enum A {
  v;
  void foo() {}
}
''');

    configuration.withConstantInitializers = false;
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
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          enclosingElement3: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: A
              shouldUseTypeForInitializerInference: false
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: List<A>
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@enum::A
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: A
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: List<A>
          methods
            foo @36
              reference: <testLibraryFragment>::@enum::A::@method::foo
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: void
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@methodAugmentation::foo::@def::0
          augmented
            fields
              <testLibraryFragment>::@enum::A::@field::v
              <testLibraryFragment>::@enum::A::@field::values
            constants
              <testLibraryFragment>::@enum::A::@field::v
            constructors
              <testLibraryFragment>::@enum::A::@constructor::new
            accessors
              <testLibraryFragment>::@enum::A::@getter::v
              <testLibraryFragment>::@enum::A::@getter::values
            methods
              <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@methodAugmentation::foo::@def::1
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          methods
            augment foo @54
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@methodAugmentation::foo::@def::0
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              returnType: void
              augmentationTarget: <testLibraryFragment>::@enum::A::@method::foo
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@methodAugmentation::foo::@def::1
            augment foo @78
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@methodAugmentation::foo::@def::1
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              returnType: void
              augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@methodAugmentation::foo::@def::0
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          element: <testLibrary>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            hasInitializer v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <testLibraryFragment>::@enum::A::@field::v#element
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibraryFragment>::@enum::A
                      element2: <testLibrary>::@enum::A
                      type: A
                    staticElement: <testLibraryFragment>::@enum::A::@constructor::new
                    element: <testLibraryFragment>::@enum::A::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            synthetic values
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <testLibraryFragment>::@enum::A::@field::values#element
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::A::@getter::v
                      element: <testLibraryFragment>::@enum::A::@getter::v#element
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
              getter2: <testLibraryFragment>::@enum::A::@getter::values
          constructors
            synthetic const new
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <testLibraryFragment>::@enum::A::@constructor::new#element
              typeName: A
          getters
            synthetic get v
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <testLibraryFragment>::@enum::A::@getter::v#element
            synthetic get values
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <testLibraryFragment>::@enum::A::@getter::values#element
          methods
            foo @36
              reference: <testLibraryFragment>::@enum::A::@method::foo
              element: <testLibraryFragment>::@enum::A::@method::foo#element
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@methodAugmentation::foo::@def::0
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibrary>::@enum::A
          previousFragment: <testLibraryFragment>::@enum::A
          methods
            augment foo @54
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@methodAugmentation::foo::@def::0
              element: <testLibraryFragment>::@enum::A::@method::foo#element
              previousFragment: <testLibraryFragment>::@enum::A::@method::foo
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@methodAugmentation::foo::@def::1
            augment foo @78
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@methodAugmentation::foo::@def::1
              element: <testLibraryFragment>::@enum::A::@method::foo#element
              previousFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@methodAugmentation::foo::@def::0
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const enumConstant hasInitializer v
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          type: A
          constantInitializer
            fragment: <testLibraryFragment>::@enum::A::@field::v
            expression: expression_0
          getter: <testLibraryFragment>::@enum::A::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          type: List<A>
          constantInitializer
            fragment: <testLibraryFragment>::@enum::A::@field::values
            expression: expression_1
          getter: <testLibraryFragment>::@enum::A::@getter::values#element
      constructors
        synthetic const new
          firstFragment: <testLibraryFragment>::@enum::A::@constructor::new
      getters
        synthetic static get v
          firstFragment: <testLibraryFragment>::@enum::A::@getter::v
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::A::@getter::values
      methods
        foo
          reference: <testLibrary>::@enum::A::@method::foo
          firstFragment: <testLibraryFragment>::@enum::A::@method::foo
''');
  }

  test_augmented_methods_augment2_oneLib_twoTop() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment enum A {;
  augment void foo() {}
}
augment enum A {;
  augment void foo() {}
}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
enum A {
  v;
  void foo() {}
}
''');

    configuration.withConstantInitializers = false;
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
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          enclosingElement3: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::0
          supertype: Enum
          fields
            static const enumConstant v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: A
              shouldUseTypeForInitializerInference: false
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: List<A>
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@enum::A
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: A
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: List<A>
          methods
            foo @36
              reference: <testLibraryFragment>::@enum::A::@method::foo
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: void
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::0::@methodAugmentation::foo
          augmented
            fields
              <testLibraryFragment>::@enum::A::@field::v
              <testLibraryFragment>::@enum::A::@field::values
            constants
              <testLibraryFragment>::@enum::A::@field::v
            constructors
              <testLibraryFragment>::@enum::A::@constructor::new
            accessors
              <testLibraryFragment>::@enum::A::@getter::v
              <testLibraryFragment>::@enum::A::@getter::values
            methods
              <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::1::@methodAugmentation::foo
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::0
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::1
          methods
            augment foo @54
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::0::@methodAugmentation::foo
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::0
              returnType: void
              augmentationTarget: <testLibraryFragment>::@enum::A::@method::foo
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::1::@methodAugmentation::foo
        augment enum A @78
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::1
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::0
          methods
            augment foo @98
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::1::@methodAugmentation::foo
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::1
              returnType: void
              augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::0::@methodAugmentation::foo
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          element: <testLibrary>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::0
          fields
            hasInitializer v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <testLibraryFragment>::@enum::A::@field::v#element
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibraryFragment>::@enum::A
                      element2: <testLibrary>::@enum::A
                      type: A
                    staticElement: <testLibraryFragment>::@enum::A::@constructor::new
                    element: <testLibraryFragment>::@enum::A::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            synthetic values
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <testLibraryFragment>::@enum::A::@field::values#element
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::A::@getter::v
                      element: <testLibraryFragment>::@enum::A::@getter::v#element
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
              getter2: <testLibraryFragment>::@enum::A::@getter::values
          constructors
            synthetic const new
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <testLibraryFragment>::@enum::A::@constructor::new#element
              typeName: A
          getters
            synthetic get v
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <testLibraryFragment>::@enum::A::@getter::v#element
            synthetic get values
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <testLibraryFragment>::@enum::A::@getter::values#element
          methods
            foo @36
              reference: <testLibraryFragment>::@enum::A::@method::foo
              element: <testLibraryFragment>::@enum::A::@method::foo#element
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::0::@methodAugmentation::foo
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::0
          element: <testLibrary>::@enum::A
          previousFragment: <testLibraryFragment>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::1
          methods
            augment foo @54
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::0::@methodAugmentation::foo
              element: <testLibraryFragment>::@enum::A::@method::foo#element
              previousFragment: <testLibraryFragment>::@enum::A::@method::foo
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::1::@methodAugmentation::foo
        enum A @78
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::1
          element: <testLibrary>::@enum::A
          previousFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::0
          methods
            augment foo @98
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::1::@methodAugmentation::foo
              element: <testLibraryFragment>::@enum::A::@method::foo#element
              previousFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::0::@methodAugmentation::foo
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const enumConstant hasInitializer v
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          type: A
          constantInitializer
            fragment: <testLibraryFragment>::@enum::A::@field::v
            expression: expression_0
          getter: <testLibraryFragment>::@enum::A::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          type: List<A>
          constantInitializer
            fragment: <testLibraryFragment>::@enum::A::@field::values
            expression: expression_1
          getter: <testLibraryFragment>::@enum::A::@getter::values#element
      constructors
        synthetic const new
          firstFragment: <testLibraryFragment>::@enum::A::@constructor::new
      getters
        synthetic static get v
          firstFragment: <testLibraryFragment>::@enum::A::@getter::v
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::A::@getter::values
      methods
        foo
          reference: <testLibrary>::@enum::A::@method::foo
          firstFragment: <testLibraryFragment>::@enum::A::@method::foo
''');
  }

  test_augmented_methods_augment2_twoLib() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
part 'b.dart';
augment enum A {;
  augment void foo() {}
}
''');

    newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';
augment enum A {;
  augment void foo() {}
}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
enum A {
  v;
  void foo() {}
}
''');

    configuration.withConstantInitializers = false;
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
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          enclosingElement3: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: A
              shouldUseTypeForInitializerInference: false
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: List<A>
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@enum::A
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: A
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: List<A>
          methods
            foo @36
              reference: <testLibraryFragment>::@enum::A::@method::foo
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: void
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@methodAugmentation::foo
          augmented
            fields
              <testLibraryFragment>::@enum::A::@field::v
              <testLibraryFragment>::@enum::A::@field::values
            constants
              <testLibraryFragment>::@enum::A::@field::v
            constructors
              <testLibraryFragment>::@enum::A::@constructor::new
            accessors
              <testLibraryFragment>::@enum::A::@getter::v
              <testLibraryFragment>::@enum::A::@getter::values
            methods
              <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@methodAugmentation::foo
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      parts
        part_1
          uri: package:test/b.dart
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          unit: <testLibrary>::@fragment::package:test/b.dart
      enums
        augment enum A @49
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          augmentation: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          methods
            augment foo @69
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@methodAugmentation::foo
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              returnType: void
              augmentationTarget: <testLibraryFragment>::@enum::A::@method::foo
              augmentation: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@methodAugmentation::foo
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
      enums
        augment enum A @31
          reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/b.dart
          augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          methods
            augment foo @51
              reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@methodAugmentation::foo
              enclosingElement3: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
              returnType: void
              augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@methodAugmentation::foo
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          element: <testLibrary>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            hasInitializer v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <testLibraryFragment>::@enum::A::@field::v#element
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibraryFragment>::@enum::A
                      element2: <testLibrary>::@enum::A
                      type: A
                    staticElement: <testLibraryFragment>::@enum::A::@constructor::new
                    element: <testLibraryFragment>::@enum::A::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            synthetic values
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <testLibraryFragment>::@enum::A::@field::values#element
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::A::@getter::v
                      element: <testLibraryFragment>::@enum::A::@getter::v#element
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
              getter2: <testLibraryFragment>::@enum::A::@getter::values
          constructors
            synthetic const new
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <testLibraryFragment>::@enum::A::@constructor::new#element
              typeName: A
          getters
            synthetic get v
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <testLibraryFragment>::@enum::A::@getter::v#element
            synthetic get values
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <testLibraryFragment>::@enum::A::@getter::values#element
          methods
            foo @36
              reference: <testLibraryFragment>::@enum::A::@method::foo
              element: <testLibraryFragment>::@enum::A::@method::foo#element
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@methodAugmentation::foo
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      enums
        enum A @49
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibrary>::@enum::A
          previousFragment: <testLibraryFragment>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          methods
            augment foo @69
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@methodAugmentation::foo
              element: <testLibraryFragment>::@enum::A::@method::foo#element
              previousFragment: <testLibraryFragment>::@enum::A::@method::foo
              nextFragment: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@methodAugmentation::foo
    <testLibrary>::@fragment::package:test/b.dart
      element: <testLibrary>
      enclosingFragment: <testLibrary>::@fragment::package:test/a.dart
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @31
          reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          element: <testLibrary>::@enum::A
          previousFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          methods
            augment foo @51
              reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@methodAugmentation::foo
              element: <testLibraryFragment>::@enum::A::@method::foo#element
              previousFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@methodAugmentation::foo
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const enumConstant hasInitializer v
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          type: A
          constantInitializer
            fragment: <testLibraryFragment>::@enum::A::@field::v
            expression: expression_0
          getter: <testLibraryFragment>::@enum::A::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          type: List<A>
          constantInitializer
            fragment: <testLibraryFragment>::@enum::A::@field::values
            expression: expression_1
          getter: <testLibraryFragment>::@enum::A::@getter::values#element
      constructors
        synthetic const new
          firstFragment: <testLibraryFragment>::@enum::A::@constructor::new
      getters
        synthetic static get v
          firstFragment: <testLibraryFragment>::@enum::A::@getter::v
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::A::@getter::values
      methods
        foo
          reference: <testLibrary>::@enum::A::@method::foo
          firstFragment: <testLibraryFragment>::@enum::A::@method::foo
''');
  }

  test_augmented_methods_generic() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment enum A<T2> {;
  T2 bar() => throw 0;
}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
enum A<T> {
  v<int>();
  T foo() => throw 0;
}
''');

    configuration.withConstantInitializers = false;
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
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant T @22
              defaultType: dynamic
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @29
              reference: <testLibraryFragment>::@enum::A::@field::v
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: A<int>
              shouldUseTypeForInitializerInference: false
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: List<A<dynamic>>
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@enum::A
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: A<int>
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: List<A<dynamic>>
          methods
            foo @43
              reference: <testLibraryFragment>::@enum::A::@method::foo
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: T
          augmented
            fields
              <testLibraryFragment>::@enum::A::@field::v
              <testLibraryFragment>::@enum::A::@field::values
            constants
              <testLibraryFragment>::@enum::A::@field::v
            constructors
              <testLibraryFragment>::@enum::A::@constructor::new
            accessors
              <testLibraryFragment>::@enum::A::@getter::v
              <testLibraryFragment>::@enum::A::@getter::values
            methods
              MethodMember
                base: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@method::bar
                augmentationSubstitution: {T2: T}
              <testLibraryFragment>::@enum::A::@method::foo
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          typeParameters
            covariant T2 @36
              defaultType: dynamic
          augmentationTarget: <testLibraryFragment>::@enum::A
          methods
            bar @48
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@method::bar
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              returnType: T2
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          element: <testLibrary>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          typeParameters
            T @22
              element: <not-implemented>
          fields
            hasInitializer v @29
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <testLibraryFragment>::@enum::A::@field::v#element
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      typeArguments: TypeArgumentList
                        leftBracket: < @30
                        arguments
                          NamedType
                            name: int @31
                            element: dart:core::<fragment>::@class::int
                            element2: dart:core::@class::int
                            type: int
                        rightBracket: > @34
                      element: <testLibraryFragment>::@enum::A
                      element2: <testLibrary>::@enum::A
                      type: A<int>
                    staticElement: ConstructorMember
                      base: <testLibraryFragment>::@enum::A::@constructor::new
                      substitution: {T: int}
                    element: <testLibraryFragment>::@enum::A::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A<int>
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            synthetic values
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <testLibraryFragment>::@enum::A::@field::values#element
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::A::@getter::v
                      element: <testLibraryFragment>::@enum::A::@getter::v#element
                      staticType: A<int>
                  rightBracket: ] @0
                  staticType: List<A<dynamic>>
              getter2: <testLibraryFragment>::@enum::A::@getter::values
          constructors
            synthetic const new
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <testLibraryFragment>::@enum::A::@constructor::new#element
              typeName: A
          getters
            synthetic get v
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <testLibraryFragment>::@enum::A::@getter::v#element
            synthetic get values
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <testLibraryFragment>::@enum::A::@getter::values#element
          methods
            foo @43
              reference: <testLibraryFragment>::@enum::A::@method::foo
              element: <testLibraryFragment>::@enum::A::@method::foo#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibrary>::@enum::A
          previousFragment: <testLibraryFragment>::@enum::A
          typeParameters
            T2 @36
              element: <not-implemented>
          methods
            bar @48
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@method::bar
              element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@method::bar#element
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: <testLibraryFragment>::@enum::A
      typeParameters
        T
      supertype: Enum
      fields
        static const enumConstant hasInitializer v
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          type: A<int>
          constantInitializer
            fragment: <testLibraryFragment>::@enum::A::@field::v
            expression: expression_0
          getter: <testLibraryFragment>::@enum::A::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          type: List<A<dynamic>>
          constantInitializer
            fragment: <testLibraryFragment>::@enum::A::@field::values
            expression: expression_1
          getter: <testLibraryFragment>::@enum::A::@getter::values#element
      constructors
        synthetic const new
          firstFragment: <testLibraryFragment>::@enum::A::@constructor::new
      getters
        synthetic static get v
          firstFragment: <testLibraryFragment>::@enum::A::@getter::v
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::A::@getter::values
      methods
        foo
          reference: <testLibrary>::@enum::A::@method::foo
          firstFragment: <testLibraryFragment>::@enum::A::@method::foo
        bar
          reference: <testLibrary>::@enum::A::@method::bar
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@method::bar
''');
  }

  test_augmented_methods_generic_augment() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment enum A<T2> {;
  augment T2 foo() => throw 0;
}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
enum A<T> {
  v<int>();
  T foo() => throw 0;
}
''');

    configuration.withConstantInitializers = false;
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
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant T @22
              defaultType: dynamic
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @29
              reference: <testLibraryFragment>::@enum::A::@field::v
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: A<int>
              shouldUseTypeForInitializerInference: false
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: List<A<dynamic>>
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@enum::A
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: A<int>
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: List<A<dynamic>>
          methods
            foo @43
              reference: <testLibraryFragment>::@enum::A::@method::foo
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: T
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@methodAugmentation::foo
          augmented
            fields
              <testLibraryFragment>::@enum::A::@field::v
              <testLibraryFragment>::@enum::A::@field::values
            constants
              <testLibraryFragment>::@enum::A::@field::v
            constructors
              <testLibraryFragment>::@enum::A::@constructor::new
            accessors
              <testLibraryFragment>::@enum::A::@getter::v
              <testLibraryFragment>::@enum::A::@getter::values
            methods
              MethodMember
                base: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@methodAugmentation::foo
                augmentationSubstitution: {T2: T}
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          typeParameters
            covariant T2 @36
              defaultType: dynamic
          augmentationTarget: <testLibraryFragment>::@enum::A
          methods
            augment foo @56
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@methodAugmentation::foo
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              returnType: T2
              augmentationTarget: <testLibraryFragment>::@enum::A::@method::foo
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          element: <testLibrary>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          typeParameters
            T @22
              element: <not-implemented>
          fields
            hasInitializer v @29
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <testLibraryFragment>::@enum::A::@field::v#element
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      typeArguments: TypeArgumentList
                        leftBracket: < @30
                        arguments
                          NamedType
                            name: int @31
                            element: dart:core::<fragment>::@class::int
                            element2: dart:core::@class::int
                            type: int
                        rightBracket: > @34
                      element: <testLibraryFragment>::@enum::A
                      element2: <testLibrary>::@enum::A
                      type: A<int>
                    staticElement: ConstructorMember
                      base: <testLibraryFragment>::@enum::A::@constructor::new
                      substitution: {T: int}
                    element: <testLibraryFragment>::@enum::A::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A<int>
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            synthetic values
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <testLibraryFragment>::@enum::A::@field::values#element
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::A::@getter::v
                      element: <testLibraryFragment>::@enum::A::@getter::v#element
                      staticType: A<int>
                  rightBracket: ] @0
                  staticType: List<A<dynamic>>
              getter2: <testLibraryFragment>::@enum::A::@getter::values
          constructors
            synthetic const new
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <testLibraryFragment>::@enum::A::@constructor::new#element
              typeName: A
          getters
            synthetic get v
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <testLibraryFragment>::@enum::A::@getter::v#element
            synthetic get values
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <testLibraryFragment>::@enum::A::@getter::values#element
          methods
            foo @43
              reference: <testLibraryFragment>::@enum::A::@method::foo
              element: <testLibraryFragment>::@enum::A::@method::foo#element
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@methodAugmentation::foo
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibrary>::@enum::A
          previousFragment: <testLibraryFragment>::@enum::A
          typeParameters
            T2 @36
              element: <not-implemented>
          methods
            augment foo @56
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@methodAugmentation::foo
              element: <testLibraryFragment>::@enum::A::@method::foo#element
              previousFragment: <testLibraryFragment>::@enum::A::@method::foo
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: <testLibraryFragment>::@enum::A
      typeParameters
        T
      supertype: Enum
      fields
        static const enumConstant hasInitializer v
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          type: A<int>
          constantInitializer
            fragment: <testLibraryFragment>::@enum::A::@field::v
            expression: expression_0
          getter: <testLibraryFragment>::@enum::A::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          type: List<A<dynamic>>
          constantInitializer
            fragment: <testLibraryFragment>::@enum::A::@field::values
            expression: expression_1
          getter: <testLibraryFragment>::@enum::A::@getter::values#element
      constructors
        synthetic const new
          firstFragment: <testLibraryFragment>::@enum::A::@constructor::new
      getters
        synthetic static get v
          firstFragment: <testLibraryFragment>::@enum::A::@getter::v
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::A::@getter::values
      methods
        foo
          reference: <testLibrary>::@enum::A::@method::foo
          firstFragment: <testLibraryFragment>::@enum::A::@method::foo
''');
  }

  test_augmented_mixins() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment enum A with M2 {}
mixin M2 {}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
enum A with M1 {
  v
}
mixin M1 {}
''');

    configuration.withConstantInitializers = false;
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
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          enclosingElement3: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          mixins
            M1
          fields
            static const enumConstant v @34
              reference: <testLibraryFragment>::@enum::A::@field::v
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: A
              shouldUseTypeForInitializerInference: false
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: List<A>
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@enum::A
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: A
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: List<A>
          augmented
            mixins
              M1
              M2
            fields
              <testLibraryFragment>::@enum::A::@field::v
              <testLibraryFragment>::@enum::A::@field::values
            constants
              <testLibraryFragment>::@enum::A::@field::v
            constructors
              <testLibraryFragment>::@enum::A::@constructor::new
            accessors
              <testLibraryFragment>::@enum::A::@getter::v
              <testLibraryFragment>::@enum::A::@getter::values
      mixins
        mixin M1 @44
          reference: <testLibraryFragment>::@mixin::M1
          enclosingElement3: <testLibraryFragment>
          superclassConstraints
            Object
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          mixins
            M2
      mixins
        mixin M2 @53
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixin::M2
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          superclassConstraints
            Object
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          element: <testLibrary>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            hasInitializer v @34
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <testLibraryFragment>::@enum::A::@field::v#element
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibraryFragment>::@enum::A
                      element2: <testLibrary>::@enum::A
                      type: A
                    staticElement: <testLibraryFragment>::@enum::A::@constructor::new
                    element: <testLibraryFragment>::@enum::A::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            synthetic values
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <testLibraryFragment>::@enum::A::@field::values#element
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::A::@getter::v
                      element: <testLibraryFragment>::@enum::A::@getter::v#element
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
              getter2: <testLibraryFragment>::@enum::A::@getter::values
          constructors
            synthetic const new
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <testLibraryFragment>::@enum::A::@constructor::new#element
              typeName: A
          getters
            synthetic get v
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <testLibraryFragment>::@enum::A::@getter::v#element
            synthetic get values
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <testLibraryFragment>::@enum::A::@getter::values#element
      mixins
        mixin M1 @44
          reference: <testLibraryFragment>::@mixin::M1
          element: <testLibrary>::@mixin::M1
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibrary>::@enum::A
          previousFragment: <testLibraryFragment>::@enum::A
      mixins
        mixin M2 @53
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixin::M2
          element: <testLibrary>::@mixin::M2
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      mixins
        M1
        M2
      fields
        static const enumConstant hasInitializer v
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          type: A
          constantInitializer
            fragment: <testLibraryFragment>::@enum::A::@field::v
            expression: expression_0
          getter: <testLibraryFragment>::@enum::A::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          type: List<A>
          constantInitializer
            fragment: <testLibraryFragment>::@enum::A::@field::values
            expression: expression_1
          getter: <testLibraryFragment>::@enum::A::@getter::values#element
      constructors
        synthetic const new
          firstFragment: <testLibraryFragment>::@enum::A::@constructor::new
      getters
        synthetic static get v
          firstFragment: <testLibraryFragment>::@enum::A::@getter::v
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::A::@getter::values
  mixins
    mixin M1
      reference: <testLibrary>::@mixin::M1
      firstFragment: <testLibraryFragment>::@mixin::M1
      superclassConstraints
        Object
    mixin M2
      reference: <testLibrary>::@mixin::M2
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@mixin::M2
      superclassConstraints
        Object
''');
  }

  test_augmented_mixins_inferredTypeArguments() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment enum A<T2> with M2 {}
mixin M2<U2> on M1<U2> {}
''');

    newFile('$testPackageLibPath/b.dart', r'''
part of 'test.dart';
augment enum A<T3> with M3 {}
mixin M3<U3> on M2<U3> {}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
part 'b.dart';
enum A<T1> with M1<T1> {
  v<int>()
}
mixin M1<U1> {}
''');

    configuration.withConstantInitializers = false;
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
      enums
        enum A @35
          reference: <testLibraryFragment>::@enum::A
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant T1 @37
              defaultType: dynamic
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          mixins
            M1<T1>
          fields
            static const enumConstant v @57
              reference: <testLibraryFragment>::@enum::A::@field::v
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: A<int>
              shouldUseTypeForInitializerInference: false
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: List<A<dynamic>>
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@enum::A
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: A<int>
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: List<A<dynamic>>
          augmented
            mixins
              M1<T1>
              M2<T1>
              M3<T1>
            fields
              <testLibraryFragment>::@enum::A::@field::v
              <testLibraryFragment>::@enum::A::@field::values
            constants
              <testLibraryFragment>::@enum::A::@field::v
            constructors
              <testLibraryFragment>::@enum::A::@constructor::new
            accessors
              <testLibraryFragment>::@enum::A::@getter::v
              <testLibraryFragment>::@enum::A::@getter::values
      mixins
        mixin M1 @74
          reference: <testLibraryFragment>::@mixin::M1
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant U1 @77
              defaultType: dynamic
          superclassConstraints
            Object
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          typeParameters
            covariant T2 @36
              defaultType: dynamic
          augmentationTarget: <testLibraryFragment>::@enum::A
          augmentation: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          mixins
            M2<T2>
      mixins
        mixin M2 @57
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixin::M2
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          typeParameters
            covariant U2 @60
              defaultType: dynamic
          superclassConstraints
            M1<U2>
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @34
          reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/b.dart
          typeParameters
            covariant T3 @36
              defaultType: dynamic
          augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          mixins
            M3<T3>
      mixins
        mixin M3 @57
          reference: <testLibrary>::@fragment::package:test/b.dart::@mixin::M3
          enclosingElement3: <testLibrary>::@fragment::package:test/b.dart
          typeParameters
            covariant U3 @60
              defaultType: dynamic
          superclassConstraints
            M2<U3>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @35
          reference: <testLibraryFragment>::@enum::A
          element: <testLibrary>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          typeParameters
            T1 @37
              element: <not-implemented>
          fields
            hasInitializer v @57
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <testLibraryFragment>::@enum::A::@field::v#element
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      typeArguments: TypeArgumentList
                        leftBracket: < @58
                        arguments
                          NamedType
                            name: int @59
                            element: dart:core::<fragment>::@class::int
                            element2: dart:core::@class::int
                            type: int
                        rightBracket: > @62
                      element: <testLibraryFragment>::@enum::A
                      element2: <testLibrary>::@enum::A
                      type: A<int>
                    staticElement: ConstructorMember
                      base: <testLibraryFragment>::@enum::A::@constructor::new
                      substitution: {T1: int}
                    element: <testLibraryFragment>::@enum::A::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A<int>
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            synthetic values
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <testLibraryFragment>::@enum::A::@field::values#element
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::A::@getter::v
                      element: <testLibraryFragment>::@enum::A::@getter::v#element
                      staticType: A<int>
                  rightBracket: ] @0
                  staticType: List<A<dynamic>>
              getter2: <testLibraryFragment>::@enum::A::@getter::values
          constructors
            synthetic const new
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <testLibraryFragment>::@enum::A::@constructor::new#element
              typeName: A
          getters
            synthetic get v
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <testLibraryFragment>::@enum::A::@getter::v#element
            synthetic get values
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <testLibraryFragment>::@enum::A::@getter::values#element
      mixins
        mixin M1 @74
          reference: <testLibraryFragment>::@mixin::M1
          element: <testLibrary>::@mixin::M1
          typeParameters
            U1 @77
              element: <not-implemented>
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibrary>::@enum::A
          previousFragment: <testLibraryFragment>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          typeParameters
            T2 @36
              element: <not-implemented>
      mixins
        mixin M2 @57
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixin::M2
          element: <testLibrary>::@mixin::M2
          typeParameters
            U2 @60
              element: <not-implemented>
    <testLibrary>::@fragment::package:test/b.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          element: <testLibrary>::@enum::A
          previousFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          typeParameters
            T3 @36
              element: <not-implemented>
      mixins
        mixin M3 @57
          reference: <testLibrary>::@fragment::package:test/b.dart::@mixin::M3
          element: <testLibrary>::@mixin::M3
          typeParameters
            U3 @60
              element: <not-implemented>
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: <testLibraryFragment>::@enum::A
      typeParameters
        T1
      supertype: Enum
      mixins
        M1<T1>
        M2<T1>
        M3<T1>
      fields
        static const enumConstant hasInitializer v
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          type: A<int>
          constantInitializer
            fragment: <testLibraryFragment>::@enum::A::@field::v
            expression: expression_0
          getter: <testLibraryFragment>::@enum::A::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          type: List<A<dynamic>>
          constantInitializer
            fragment: <testLibraryFragment>::@enum::A::@field::values
            expression: expression_1
          getter: <testLibraryFragment>::@enum::A::@getter::values#element
      constructors
        synthetic const new
          firstFragment: <testLibraryFragment>::@enum::A::@constructor::new
      getters
        synthetic static get v
          firstFragment: <testLibraryFragment>::@enum::A::@getter::v
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::A::@getter::values
  mixins
    mixin M1
      reference: <testLibrary>::@mixin::M1
      firstFragment: <testLibraryFragment>::@mixin::M1
      typeParameters
        U1
      superclassConstraints
        Object
    mixin M2
      reference: <testLibrary>::@mixin::M2
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@mixin::M2
      typeParameters
        U2
      superclassConstraints
        M1<U2>
    mixin M3
      reference: <testLibrary>::@mixin::M3
      firstFragment: <testLibrary>::@fragment::package:test/b.dart::@mixin::M3
      typeParameters
        U3
      superclassConstraints
        M2<U3>
''');
  }

  test_augmented_setters_add() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment enum A {;
  set foo2(int _) {}
}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
enum A {
  v;
  set foo1(int _) {}
}
''');

    configuration
      ..withConstantInitializers = false
      ..withPropertyLinking = true;
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
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          enclosingElement3: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: A
              shouldUseTypeForInitializerInference: false
              id: field_0
              getter: getter_0
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: List<A>
              id: field_1
              getter: getter_1
            synthetic foo1 @-1
              reference: <testLibraryFragment>::@enum::A::@field::foo1
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: int
              id: field_2
              setter: setter_0
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@enum::A
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: A
              id: getter_0
              variable: field_0
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: List<A>
              id: getter_1
              variable: field_1
            set foo1= @35
              reference: <testLibraryFragment>::@enum::A::@setter::foo1
              enclosingElement3: <testLibraryFragment>::@enum::A
              parameters
                requiredPositional _ @44
                  type: int
              returnType: void
              id: setter_0
              variable: field_2
          augmented
            fields
              <testLibraryFragment>::@enum::A::@field::foo1
              <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::foo2
              <testLibraryFragment>::@enum::A::@field::v
              <testLibraryFragment>::@enum::A::@field::values
            constants
              <testLibraryFragment>::@enum::A::@field::v
            constructors
              <testLibraryFragment>::@enum::A::@constructor::new
            accessors
              <testLibraryFragment>::@enum::A::@setter::foo1
              <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@setter::foo2
              <testLibraryFragment>::@enum::A::@getter::v
              <testLibraryFragment>::@enum::A::@getter::values
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          fields
            synthetic foo2 @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::foo2
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              type: int
              id: field_3
              setter: setter_1
          accessors
            set foo2= @45
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@setter::foo2
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              parameters
                requiredPositional _ @54
                  type: int
              returnType: void
              id: setter_1
              variable: field_3
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          element: <testLibrary>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            hasInitializer v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <testLibraryFragment>::@enum::A::@field::v#element
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibraryFragment>::@enum::A
                      element2: <testLibrary>::@enum::A
                      type: A
                    staticElement: <testLibraryFragment>::@enum::A::@constructor::new
                    element: <testLibraryFragment>::@enum::A::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            synthetic values
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <testLibraryFragment>::@enum::A::@field::values#element
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::A::@getter::v
                      element: <testLibraryFragment>::@enum::A::@getter::v#element
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
              getter2: <testLibraryFragment>::@enum::A::@getter::values
            synthetic foo1
              reference: <testLibraryFragment>::@enum::A::@field::foo1
              element: <testLibraryFragment>::@enum::A::@field::foo1#element
              setter2: <testLibraryFragment>::@enum::A::@setter::foo1
          constructors
            synthetic const new
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <testLibraryFragment>::@enum::A::@constructor::new#element
              typeName: A
          getters
            synthetic get v
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <testLibraryFragment>::@enum::A::@getter::v#element
            synthetic get values
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <testLibraryFragment>::@enum::A::@getter::values#element
          setters
            set foo1 @35
              reference: <testLibraryFragment>::@enum::A::@setter::foo1
              element: <testLibraryFragment>::@enum::A::@setter::foo1#element
              formalParameters
                _ @44
                  element: <testLibraryFragment>::@enum::A::@setter::foo1::@parameter::_#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibrary>::@enum::A
          previousFragment: <testLibraryFragment>::@enum::A
          fields
            synthetic foo2
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::foo2
              element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::foo2#element
              setter2: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@setter::foo2
          setters
            set foo2 @45
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@setter::foo2
              element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@setter::foo2#element
              formalParameters
                _ @54
                  element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@setter::foo2::@parameter::_#element
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const enumConstant hasInitializer v
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          type: A
          constantInitializer
            fragment: <testLibraryFragment>::@enum::A::@field::v
            expression: expression_0
          getter: <testLibraryFragment>::@enum::A::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          type: List<A>
          constantInitializer
            fragment: <testLibraryFragment>::@enum::A::@field::values
            expression: expression_1
          getter: <testLibraryFragment>::@enum::A::@getter::values#element
        synthetic foo1
          firstFragment: <testLibraryFragment>::@enum::A::@field::foo1
          type: int
          setter: <testLibraryFragment>::@enum::A::@setter::foo1#element
        synthetic foo2
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::foo2
          type: int
          setter: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@setter::foo2#element
      constructors
        synthetic const new
          firstFragment: <testLibraryFragment>::@enum::A::@constructor::new
      getters
        synthetic static get v
          firstFragment: <testLibraryFragment>::@enum::A::@getter::v
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::A::@getter::values
      setters
        set foo1
          firstFragment: <testLibraryFragment>::@enum::A::@setter::foo1
          formalParameters
            requiredPositional _
              type: int
        set foo2
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@setter::foo2
          formalParameters
            requiredPositional _
              type: int
''');
  }

  test_augmented_setters_augment_field() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment enum A {;
  augment set foo(int _) {}
}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
enum A {
  v;
  final int foo = 0;
}
''');

    configuration
      ..withConstantInitializers = false
      ..withPropertyLinking = true;
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
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          enclosingElement3: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: A
              shouldUseTypeForInitializerInference: false
              id: field_0
              getter: getter_0
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: List<A>
              id: field_1
              getter: getter_1
            final foo @41
              reference: <testLibraryFragment>::@enum::A::@field::foo
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: int
              shouldUseTypeForInitializerInference: true
              id: field_2
              getter: getter_2
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@enum::A
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: A
              id: getter_0
              variable: field_0
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: List<A>
              id: getter_1
              variable: field_1
            synthetic get foo @-1
              reference: <testLibraryFragment>::@enum::A::@getter::foo
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: int
              id: getter_2
              variable: field_2
          augmented
            fields
              <testLibraryFragment>::@enum::A::@field::foo
              <testLibraryFragment>::@enum::A::@field::v
              <testLibraryFragment>::@enum::A::@field::values
            constants
              <testLibraryFragment>::@enum::A::@field::v
            constructors
              <testLibraryFragment>::@enum::A::@constructor::new
            accessors
              <testLibraryFragment>::@enum::A::@getter::foo
              <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@setterAugmentation::foo
              <testLibraryFragment>::@enum::A::@getter::v
              <testLibraryFragment>::@enum::A::@getter::values
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          accessors
            augment set foo= @53
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@setterAugmentation::foo
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              parameters
                requiredPositional _ @61
                  type: int
              returnType: void
              id: setter_0
              variable: <null>
              augmentationTargetAny: <testLibraryFragment>::@enum::A::@getter::foo
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          element: <testLibrary>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            hasInitializer v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <testLibraryFragment>::@enum::A::@field::v#element
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibraryFragment>::@enum::A
                      element2: <testLibrary>::@enum::A
                      type: A
                    staticElement: <testLibraryFragment>::@enum::A::@constructor::new
                    element: <testLibraryFragment>::@enum::A::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            synthetic values
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <testLibraryFragment>::@enum::A::@field::values#element
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::A::@getter::v
                      element: <testLibraryFragment>::@enum::A::@getter::v#element
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
              getter2: <testLibraryFragment>::@enum::A::@getter::values
            hasInitializer foo @41
              reference: <testLibraryFragment>::@enum::A::@field::foo
              element: <testLibraryFragment>::@enum::A::@field::foo#element
              initializer: expression_2
                IntegerLiteral
                  literal: 0 @47
                  staticType: int
              getter2: <testLibraryFragment>::@enum::A::@getter::foo
          constructors
            synthetic const new
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <testLibraryFragment>::@enum::A::@constructor::new#element
              typeName: A
          getters
            synthetic get v
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <testLibraryFragment>::@enum::A::@getter::v#element
            synthetic get values
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <testLibraryFragment>::@enum::A::@getter::values#element
            synthetic get foo
              reference: <testLibraryFragment>::@enum::A::@getter::foo
              element: <testLibraryFragment>::@enum::A::@getter::foo#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibrary>::@enum::A
          previousFragment: <testLibraryFragment>::@enum::A
          setters
            augment set foo @53
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@setterAugmentation::foo
              element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@setterAugmentation::foo#element
              formalParameters
                _ @61
                  element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@setterAugmentation::foo::@parameter::_#element
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const enumConstant hasInitializer v
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          type: A
          constantInitializer
            fragment: <testLibraryFragment>::@enum::A::@field::v
            expression: expression_0
          getter: <testLibraryFragment>::@enum::A::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          type: List<A>
          constantInitializer
            fragment: <testLibraryFragment>::@enum::A::@field::values
            expression: expression_1
          getter: <testLibraryFragment>::@enum::A::@getter::values#element
        final hasInitializer foo
          firstFragment: <testLibraryFragment>::@enum::A::@field::foo
          type: int
          constantInitializer
            fragment: <testLibraryFragment>::@enum::A::@field::foo
            expression: expression_2
          getter: <testLibraryFragment>::@enum::A::@getter::foo#element
      constructors
        synthetic const new
          firstFragment: <testLibraryFragment>::@enum::A::@constructor::new
      getters
        synthetic static get v
          firstFragment: <testLibraryFragment>::@enum::A::@getter::v
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::A::@getter::values
        synthetic get foo
          firstFragment: <testLibraryFragment>::@enum::A::@getter::foo
      setters
        set foo
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@setterAugmentation::foo
          formalParameters
            requiredPositional _
              type: int
''');
  }

  test_augmented_setters_augment_nothing() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment enum A {;
  augment set foo(int _) {}
}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
enum A {
  v
}
''');

    configuration
      ..withConstantInitializers = false
      ..withPropertyLinking = true;
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
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          enclosingElement3: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: A
              shouldUseTypeForInitializerInference: false
              id: field_0
              getter: getter_0
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: List<A>
              id: field_1
              getter: getter_1
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@enum::A
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: A
              id: getter_0
              variable: field_0
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: List<A>
              id: getter_1
              variable: field_1
          augmented
            fields
              <testLibraryFragment>::@enum::A::@field::v
              <testLibraryFragment>::@enum::A::@field::values
            constants
              <testLibraryFragment>::@enum::A::@field::v
            constructors
              <testLibraryFragment>::@enum::A::@constructor::new
            accessors
              <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@setterAugmentation::foo
              <testLibraryFragment>::@enum::A::@getter::v
              <testLibraryFragment>::@enum::A::@getter::values
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          accessors
            augment set foo= @53
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@setterAugmentation::foo
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              parameters
                requiredPositional _ @61
                  type: int
              returnType: void
              id: setter_0
              variable: <null>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          element: <testLibrary>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            hasInitializer v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <testLibraryFragment>::@enum::A::@field::v#element
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibraryFragment>::@enum::A
                      element2: <testLibrary>::@enum::A
                      type: A
                    staticElement: <testLibraryFragment>::@enum::A::@constructor::new
                    element: <testLibraryFragment>::@enum::A::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            synthetic values
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <testLibraryFragment>::@enum::A::@field::values#element
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::A::@getter::v
                      element: <testLibraryFragment>::@enum::A::@getter::v#element
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
              getter2: <testLibraryFragment>::@enum::A::@getter::values
          constructors
            synthetic const new
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <testLibraryFragment>::@enum::A::@constructor::new#element
              typeName: A
          getters
            synthetic get v
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <testLibraryFragment>::@enum::A::@getter::v#element
            synthetic get values
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <testLibraryFragment>::@enum::A::@getter::values#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibrary>::@enum::A
          previousFragment: <testLibraryFragment>::@enum::A
          setters
            augment set foo @53
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@setterAugmentation::foo
              element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@setterAugmentation::foo#element
              formalParameters
                _ @61
                  element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@setterAugmentation::foo::@parameter::_#element
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const enumConstant hasInitializer v
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          type: A
          constantInitializer
            fragment: <testLibraryFragment>::@enum::A::@field::v
            expression: expression_0
          getter: <testLibraryFragment>::@enum::A::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          type: List<A>
          constantInitializer
            fragment: <testLibraryFragment>::@enum::A::@field::values
            expression: expression_1
          getter: <testLibraryFragment>::@enum::A::@getter::values#element
      constructors
        synthetic const new
          firstFragment: <testLibraryFragment>::@enum::A::@constructor::new
      getters
        synthetic static get v
          firstFragment: <testLibraryFragment>::@enum::A::@getter::v
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::A::@getter::values
      setters
        set foo
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@setterAugmentation::foo
          formalParameters
            requiredPositional _
              type: int
''');
  }

  test_augmented_setters_augment_setter() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment enum A {;
  augment set foo1(int _) {}
}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
enum A {
  v;
  set foo1(int _) {}
  set foo2(int _) {}
}
''');

    configuration
      ..withConstantInitializers = false
      ..withPropertyLinking = true;
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
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          enclosingElement3: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: A
              shouldUseTypeForInitializerInference: false
              id: field_0
              getter: getter_0
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: List<A>
              id: field_1
              getter: getter_1
            synthetic foo1 @-1
              reference: <testLibraryFragment>::@enum::A::@field::foo1
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: int
              id: field_2
              setter: setter_0
            synthetic foo2 @-1
              reference: <testLibraryFragment>::@enum::A::@field::foo2
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: int
              id: field_3
              setter: setter_1
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@enum::A
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: A
              id: getter_0
              variable: field_0
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: List<A>
              id: getter_1
              variable: field_1
            set foo1= @35
              reference: <testLibraryFragment>::@enum::A::@setter::foo1
              enclosingElement3: <testLibraryFragment>::@enum::A
              parameters
                requiredPositional _ @44
                  type: int
              returnType: void
              id: setter_0
              variable: field_2
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@setterAugmentation::foo1
            set foo2= @56
              reference: <testLibraryFragment>::@enum::A::@setter::foo2
              enclosingElement3: <testLibraryFragment>::@enum::A
              parameters
                requiredPositional _ @65
                  type: int
              returnType: void
              id: setter_1
              variable: field_3
          augmented
            fields
              <testLibraryFragment>::@enum::A::@field::foo1
              <testLibraryFragment>::@enum::A::@field::foo2
              <testLibraryFragment>::@enum::A::@field::v
              <testLibraryFragment>::@enum::A::@field::values
            constants
              <testLibraryFragment>::@enum::A::@field::v
            constructors
              <testLibraryFragment>::@enum::A::@constructor::new
            accessors
              <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@setterAugmentation::foo1
              <testLibraryFragment>::@enum::A::@setter::foo2
              <testLibraryFragment>::@enum::A::@getter::v
              <testLibraryFragment>::@enum::A::@getter::values
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          accessors
            augment set foo1= @53
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@setterAugmentation::foo1
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              parameters
                requiredPositional _ @62
                  type: int
              returnType: void
              id: setter_2
              variable: <null>
              augmentationTarget: <testLibraryFragment>::@enum::A::@setter::foo1
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          element: <testLibrary>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            hasInitializer v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <testLibraryFragment>::@enum::A::@field::v#element
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibraryFragment>::@enum::A
                      element2: <testLibrary>::@enum::A
                      type: A
                    staticElement: <testLibraryFragment>::@enum::A::@constructor::new
                    element: <testLibraryFragment>::@enum::A::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            synthetic values
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <testLibraryFragment>::@enum::A::@field::values#element
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::A::@getter::v
                      element: <testLibraryFragment>::@enum::A::@getter::v#element
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
              getter2: <testLibraryFragment>::@enum::A::@getter::values
            synthetic foo1
              reference: <testLibraryFragment>::@enum::A::@field::foo1
              element: <testLibraryFragment>::@enum::A::@field::foo1#element
              setter2: <testLibraryFragment>::@enum::A::@setter::foo1
            synthetic foo2
              reference: <testLibraryFragment>::@enum::A::@field::foo2
              element: <testLibraryFragment>::@enum::A::@field::foo2#element
              setter2: <testLibraryFragment>::@enum::A::@setter::foo2
          constructors
            synthetic const new
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <testLibraryFragment>::@enum::A::@constructor::new#element
              typeName: A
          getters
            synthetic get v
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <testLibraryFragment>::@enum::A::@getter::v#element
            synthetic get values
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <testLibraryFragment>::@enum::A::@getter::values#element
          setters
            set foo1 @35
              reference: <testLibraryFragment>::@enum::A::@setter::foo1
              element: <testLibraryFragment>::@enum::A::@setter::foo1#element
              formalParameters
                _ @44
                  element: <testLibraryFragment>::@enum::A::@setter::foo1::@parameter::_#element
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@setterAugmentation::foo1
            set foo2 @56
              reference: <testLibraryFragment>::@enum::A::@setter::foo2
              element: <testLibraryFragment>::@enum::A::@setter::foo2#element
              formalParameters
                _ @65
                  element: <testLibraryFragment>::@enum::A::@setter::foo2::@parameter::_#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibrary>::@enum::A
          previousFragment: <testLibraryFragment>::@enum::A
          setters
            augment set foo1 @53
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@setterAugmentation::foo1
              element: <testLibraryFragment>::@enum::A::@setter::foo1#element
              formalParameters
                _ @62
                  element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@setterAugmentation::foo1::@parameter::_#element
              previousFragment: <testLibraryFragment>::@enum::A::@setter::foo1
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const enumConstant hasInitializer v
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          type: A
          constantInitializer
            fragment: <testLibraryFragment>::@enum::A::@field::v
            expression: expression_0
          getter: <testLibraryFragment>::@enum::A::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          type: List<A>
          constantInitializer
            fragment: <testLibraryFragment>::@enum::A::@field::values
            expression: expression_1
          getter: <testLibraryFragment>::@enum::A::@getter::values#element
        synthetic foo1
          firstFragment: <testLibraryFragment>::@enum::A::@field::foo1
          type: int
          setter: <testLibraryFragment>::@enum::A::@setter::foo1#element
        synthetic foo2
          firstFragment: <testLibraryFragment>::@enum::A::@field::foo2
          type: int
          setter: <testLibraryFragment>::@enum::A::@setter::foo2#element
      constructors
        synthetic const new
          firstFragment: <testLibraryFragment>::@enum::A::@constructor::new
      getters
        synthetic static get v
          firstFragment: <testLibraryFragment>::@enum::A::@getter::v
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::A::@getter::values
      setters
        set foo2
          firstFragment: <testLibraryFragment>::@enum::A::@setter::foo2
          formalParameters
            requiredPositional _
              type: int
        set foo1
          firstFragment: <testLibraryFragment>::@enum::A::@setter::foo1
          formalParameters
            requiredPositional _
              type: int
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

enum A {v}
''');

    configuration
      ..withConstantInitializers = false
      ..withConstructors = false;
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
      enums
        enum A @36
          reference: <testLibraryFragment>::@enum::A
          enclosingElement3: <testLibraryFragment>
          supertype: Enum
          fields
            static const enumConstant v @39
              reference: <testLibraryFragment>::@enum::A::@field::v
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: A
              shouldUseTypeForInitializerInference: false
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: List<A>
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: A
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: List<A>
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      classes
        augment class A @36
          reference: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          augmentationTargetAny: <testLibraryFragment>::@enum::A
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
      enums
        enum A @36
          reference: <testLibraryFragment>::@enum::A
          element: <testLibrary>::@enum::A
          fields
            hasInitializer v @39
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <testLibraryFragment>::@enum::A::@field::v#element
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibraryFragment>::@enum::A
                      element2: <testLibrary>::@enum::A
                      type: A
                    staticElement: <testLibraryFragment>::@enum::A::@constructor::new
                    element: <testLibraryFragment>::@enum::A::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            synthetic values
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <testLibraryFragment>::@enum::A::@field::values#element
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::A::@getter::v
                      element: <testLibraryFragment>::@enum::A::@getter::v#element
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
              getter2: <testLibraryFragment>::@enum::A::@getter::values
          getters
            synthetic get v
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <testLibraryFragment>::@enum::A::@getter::v#element
            synthetic get values
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <testLibraryFragment>::@enum::A::@getter::values#element
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
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const enumConstant hasInitializer v
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          type: A
          constantInitializer
            fragment: <testLibraryFragment>::@enum::A::@field::v
            expression: expression_0
          getter: <testLibraryFragment>::@enum::A::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          type: List<A>
          constantInitializer
            fragment: <testLibraryFragment>::@enum::A::@field::values
            expression: expression_1
          getter: <testLibraryFragment>::@enum::A::@getter::values#element
      getters
        synthetic static get v
          firstFragment: <testLibraryFragment>::@enum::A::@getter::v
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::A::@getter::values
''');
  }

  test_augmentedBy_class_enum() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';

augment class A {}
''');

    newFile('$testPackageLibPath/b.dart', r'''
part of 'test.dart';

augment enum A {}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
part 'b.dart';

enum A {v}
''');

    configuration
      ..withConstantInitializers = false
      ..withConstructors = false;
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
      enums
        enum A @36
          reference: <testLibraryFragment>::@enum::A
          enclosingElement3: <testLibraryFragment>
          supertype: Enum
          fields
            static const enumConstant v @39
              reference: <testLibraryFragment>::@enum::A::@field::v
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: A
              shouldUseTypeForInitializerInference: false
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: List<A>
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: A
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: List<A>
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      classes
        augment class A @36
          reference: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          augmentationTargetAny: <testLibraryFragment>::@enum::A
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @35
          reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/b.dart
          augmentationTargetAny: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A
          fields
            synthetic static const values @-1
              reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@field::values
              enclosingElement3: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
              type: List<A>
          accessors
            synthetic static get values @-1
              reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@getter::values
              enclosingElement3: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
              returnType: List<A>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @36
          reference: <testLibraryFragment>::@enum::A
          element: <testLibrary>::@enum::A::@def::0
          fields
            hasInitializer v @39
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <testLibraryFragment>::@enum::A::@field::v#element
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibraryFragment>::@enum::A
                      element2: <testLibrary>::@enum::A::@def::0
                      type: A
                    staticElement: <testLibraryFragment>::@enum::A::@constructor::new
                    element: <testLibraryFragment>::@enum::A::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            synthetic values
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <testLibraryFragment>::@enum::A::@field::values#element
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::A::@getter::v
                      element: <testLibraryFragment>::@enum::A::@getter::v#element
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
              getter2: <testLibraryFragment>::@enum::A::@getter::values
          getters
            synthetic get v
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <testLibraryFragment>::@enum::A::@getter::v#element
            synthetic get values
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <testLibraryFragment>::@enum::A::@getter::values#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      classes
        class A @36
          reference: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A
          element: <testLibrary>::@class::A
    <testLibrary>::@fragment::package:test/b.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @35
          reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          element: <testLibrary>::@enum::A::@def::1
          fields
            synthetic values
              reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@field::values
              element: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@field::values#element
              initializer: expression_2
                ListLiteral
                  leftBracket: [ @0
                  rightBracket: ] @0
                  staticType: List<A>
              getter2: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@getter::values
          getters
            synthetic get values
              reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@getter::values
              element: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@getter::values#element
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A
  enums
    enum A
      reference: <testLibrary>::@enum::A::@def::0
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const enumConstant hasInitializer v
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          type: A
          constantInitializer
            fragment: <testLibraryFragment>::@enum::A::@field::v
            expression: expression_0
          getter: <testLibraryFragment>::@enum::A::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          type: List<A>
          constantInitializer
            fragment: <testLibraryFragment>::@enum::A::@field::values
            expression: expression_1
          getter: <testLibraryFragment>::@enum::A::@getter::values#element
      getters
        synthetic static get v
          firstFragment: <testLibraryFragment>::@enum::A::@getter::v
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::A::@getter::values
    enum A
      reference: <testLibrary>::@enum::A::@def::1
      firstFragment: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
      supertype: Enum
      fields
        synthetic static const values
          firstFragment: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@field::values
          type: List<A>
          constantInitializer
            fragment: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@field::values
            expression: expression_2
          getter: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@getter::values#element
      getters
        synthetic static get values
          firstFragment: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@getter::values
''');
  }

  test_constructors_augment2() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment enum A {;
  augment const A.named();
}
''');

    newFile('$testPackageLibPath/b.dart', r'''
part of 'test.dart';
augment enum A {;
  augment const A.named();
}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
part 'b.dart';
enum A {
  v.named();
  const A.named();
}
''');

    configuration.withConstantInitializers = false;
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
      enums
        enum A @35
          reference: <testLibraryFragment>::@enum::A
          enclosingElement3: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @41
              reference: <testLibraryFragment>::@enum::A::@field::v
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: A
              shouldUseTypeForInitializerInference: false
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: List<A>
          constructors
            const named @62
              reference: <testLibraryFragment>::@enum::A::@constructor::named
              enclosingElement3: <testLibraryFragment>::@enum::A
              periodOffset: 61
              nameEnd: 67
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructorAugmentation::named
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: A
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: List<A>
          augmented
            fields
              <testLibraryFragment>::@enum::A::@field::v
              <testLibraryFragment>::@enum::A::@field::values
            constants
              <testLibraryFragment>::@enum::A::@field::v
            constructors
              <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@constructorAugmentation::named
            accessors
              <testLibraryFragment>::@enum::A::@getter::v
              <testLibraryFragment>::@enum::A::@getter::values
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          augmentation: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          constructors
            augment const named @57
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructorAugmentation::named
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              periodOffset: 56
              nameEnd: 62
              augmentationTarget: <testLibraryFragment>::@enum::A::@constructor::named
              augmentation: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@constructorAugmentation::named
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @34
          reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/b.dart
          augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          constructors
            augment const named @57
              reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@constructorAugmentation::named
              enclosingElement3: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
              periodOffset: 56
              nameEnd: 62
              augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructorAugmentation::named
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @35
          reference: <testLibraryFragment>::@enum::A
          element: <testLibrary>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            hasInitializer v @41
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <testLibraryFragment>::@enum::A::@field::v#element
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibraryFragment>::@enum::A
                      element2: <testLibrary>::@enum::A
                      type: A
                    period: . @0
                    name: SimpleIdentifier
                      token: named @-1
                      staticElement: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@constructorAugmentation::named
                      element: <testLibraryFragment>::@enum::A::@constructor::named#element
                      staticType: null
                    staticElement: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@constructorAugmentation::named
                    element: <testLibraryFragment>::@enum::A::@constructor::named#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            synthetic values
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <testLibraryFragment>::@enum::A::@field::values#element
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::A::@getter::v
                      element: <testLibraryFragment>::@enum::A::@getter::v#element
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
              getter2: <testLibraryFragment>::@enum::A::@getter::values
          constructors
            const named @62
              reference: <testLibraryFragment>::@enum::A::@constructor::named
              element: <testLibraryFragment>::@enum::A::@constructor::named#element
              typeName: A
              typeNameOffset: 60
              periodOffset: 61
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructorAugmentation::named
          getters
            synthetic get v
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <testLibraryFragment>::@enum::A::@getter::v#element
            synthetic get values
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <testLibraryFragment>::@enum::A::@getter::values#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibrary>::@enum::A
          previousFragment: <testLibraryFragment>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          constructors
            augment const named @57
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructorAugmentation::named
              element: <testLibraryFragment>::@enum::A::@constructor::named#element
              typeName: A
              typeNameOffset: 55
              periodOffset: 56
              nextFragment: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@constructorAugmentation::named
              previousFragment: <testLibraryFragment>::@enum::A::@constructor::named
    <testLibrary>::@fragment::package:test/b.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          element: <testLibrary>::@enum::A
          previousFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          constructors
            augment const named @57
              reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@constructorAugmentation::named
              element: <testLibraryFragment>::@enum::A::@constructor::named#element
              typeName: A
              typeNameOffset: 55
              periodOffset: 56
              previousFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructorAugmentation::named
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const enumConstant hasInitializer v
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          type: A
          constantInitializer
            fragment: <testLibraryFragment>::@enum::A::@field::v
            expression: expression_0
          getter: <testLibraryFragment>::@enum::A::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          type: List<A>
          constantInitializer
            fragment: <testLibraryFragment>::@enum::A::@field::values
            expression: expression_1
          getter: <testLibraryFragment>::@enum::A::@getter::values#element
      constructors
        const named
          firstFragment: <testLibraryFragment>::@enum::A::@constructor::named
      getters
        synthetic static get v
          firstFragment: <testLibraryFragment>::@enum::A::@getter::v
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::A::@getter::values
''');
  }

  test_constructors_augment_named() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment enum A {;
  augment const A.named();
}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
enum A {
  v.named();
  const A.named();
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
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          enclosingElement3: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: A
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibraryFragment>::@enum::A
                      element2: <testLibrary>::@enum::A
                      type: A
                    period: . @0
                    name: SimpleIdentifier
                      token: named @-1
                      staticElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructorAugmentation::named
                      element: <testLibraryFragment>::@enum::A::@constructor::named#element
                      staticType: null
                    staticElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructorAugmentation::named
                    element: <testLibraryFragment>::@enum::A::@constructor::named#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: List<A>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::A::@getter::v
                      element: <testLibraryFragment>::@enum::A::@getter::v#element
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
          constructors
            const named @47
              reference: <testLibraryFragment>::@enum::A::@constructor::named
              enclosingElement3: <testLibraryFragment>::@enum::A
              periodOffset: 46
              nameEnd: 52
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructorAugmentation::named
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: A
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: List<A>
          augmented
            fields
              <testLibraryFragment>::@enum::A::@field::v
              <testLibraryFragment>::@enum::A::@field::values
            constants
              <testLibraryFragment>::@enum::A::@field::v
            constructors
              <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructorAugmentation::named
            accessors
              <testLibraryFragment>::@enum::A::@getter::v
              <testLibraryFragment>::@enum::A::@getter::values
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          constructors
            augment const named @57
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructorAugmentation::named
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              periodOffset: 56
              nameEnd: 62
              augmentationTarget: <testLibraryFragment>::@enum::A::@constructor::named
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          element: <testLibrary>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            hasInitializer v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <testLibraryFragment>::@enum::A::@field::v#element
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibraryFragment>::@enum::A
                      element2: <testLibrary>::@enum::A
                      type: A
                    period: . @0
                    name: SimpleIdentifier
                      token: named @-1
                      staticElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructorAugmentation::named
                      element: <testLibraryFragment>::@enum::A::@constructor::named#element
                      staticType: null
                    staticElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructorAugmentation::named
                    element: <testLibraryFragment>::@enum::A::@constructor::named#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            synthetic values
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <testLibraryFragment>::@enum::A::@field::values#element
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::A::@getter::v
                      element: <testLibraryFragment>::@enum::A::@getter::v#element
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
              getter2: <testLibraryFragment>::@enum::A::@getter::values
          constructors
            const named @47
              reference: <testLibraryFragment>::@enum::A::@constructor::named
              element: <testLibraryFragment>::@enum::A::@constructor::named#element
              typeName: A
              typeNameOffset: 45
              periodOffset: 46
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructorAugmentation::named
          getters
            synthetic get v
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <testLibraryFragment>::@enum::A::@getter::v#element
            synthetic get values
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <testLibraryFragment>::@enum::A::@getter::values#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibrary>::@enum::A
          previousFragment: <testLibraryFragment>::@enum::A
          constructors
            augment const named @57
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructorAugmentation::named
              element: <testLibraryFragment>::@enum::A::@constructor::named#element
              typeName: A
              typeNameOffset: 55
              periodOffset: 56
              previousFragment: <testLibraryFragment>::@enum::A::@constructor::named
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const enumConstant hasInitializer v
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          type: A
          constantInitializer
            fragment: <testLibraryFragment>::@enum::A::@field::v
            expression: expression_0
          getter: <testLibraryFragment>::@enum::A::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          type: List<A>
          constantInitializer
            fragment: <testLibraryFragment>::@enum::A::@field::values
            expression: expression_1
          getter: <testLibraryFragment>::@enum::A::@getter::values#element
      constructors
        const named
          firstFragment: <testLibraryFragment>::@enum::A::@constructor::named
      getters
        synthetic static get v
          firstFragment: <testLibraryFragment>::@enum::A::@getter::v
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::A::@getter::values
''');
  }

  test_constructors_augment_unnamed() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment enum A {;
  augment const A();
}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
enum A {
  v;
  const A();
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
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          enclosingElement3: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: A
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibraryFragment>::@enum::A
                      element2: <testLibrary>::@enum::A
                      type: A
                    staticElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructorAugmentation::new
                    element: <testLibraryFragment>::@enum::A::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: List<A>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::A::@getter::v
                      element: <testLibraryFragment>::@enum::A::@getter::v#element
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
          constructors
            const @37
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@enum::A
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructorAugmentation::new
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: A
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: List<A>
          augmented
            fields
              <testLibraryFragment>::@enum::A::@field::v
              <testLibraryFragment>::@enum::A::@field::values
            constants
              <testLibraryFragment>::@enum::A::@field::v
            constructors
              <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructorAugmentation::new
            accessors
              <testLibraryFragment>::@enum::A::@getter::v
              <testLibraryFragment>::@enum::A::@getter::values
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          constructors
            augment const @55
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructorAugmentation::new
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              augmentationTarget: <testLibraryFragment>::@enum::A::@constructor::new
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          element: <testLibrary>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            hasInitializer v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <testLibraryFragment>::@enum::A::@field::v#element
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibraryFragment>::@enum::A
                      element2: <testLibrary>::@enum::A
                      type: A
                    staticElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructorAugmentation::new
                    element: <testLibraryFragment>::@enum::A::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            synthetic values
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <testLibraryFragment>::@enum::A::@field::values#element
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::A::@getter::v
                      element: <testLibraryFragment>::@enum::A::@getter::v#element
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
              getter2: <testLibraryFragment>::@enum::A::@getter::values
          constructors
            const new
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <testLibraryFragment>::@enum::A::@constructor::new#element
              typeName: A
              typeNameOffset: 37
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructorAugmentation::new
          getters
            synthetic get v
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <testLibraryFragment>::@enum::A::@getter::v#element
            synthetic get values
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <testLibraryFragment>::@enum::A::@getter::values#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibrary>::@enum::A
          previousFragment: <testLibraryFragment>::@enum::A
          constructors
            augment const new
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructorAugmentation::new
              element: <testLibraryFragment>::@enum::A::@constructor::new#element
              typeName: A
              typeNameOffset: 55
              previousFragment: <testLibraryFragment>::@enum::A::@constructor::new
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const enumConstant hasInitializer v
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          type: A
          constantInitializer
            fragment: <testLibraryFragment>::@enum::A::@field::v
            expression: expression_0
          getter: <testLibraryFragment>::@enum::A::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          type: List<A>
          constantInitializer
            fragment: <testLibraryFragment>::@enum::A::@field::values
            expression: expression_1
          getter: <testLibraryFragment>::@enum::A::@getter::values#element
      constructors
        const new
          firstFragment: <testLibraryFragment>::@enum::A::@constructor::new
      getters
        synthetic static get v
          firstFragment: <testLibraryFragment>::@enum::A::@getter::v
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::A::@getter::values
''');
  }

  test_inferTypes_method_ofAugment() async {
    newFile('$testPackageLibPath/a.dart', r'''
abstract class A {
  int foo(String a);
}
''');

    newFile('$testPackageLibPath/b.dart', r'''
part of 'test.dart';
augment enum B {;
  foo(a) => 0;
}
''');

    var library = await buildLibrary(r'''
import 'a.dart';
part 'b.dart';

enum B implements A {
  v
}
''');

    configuration.withConstantInitializers = false;
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
      enums
        enum B @38
          reference: <testLibraryFragment>::@enum::B
          enclosingElement3: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::B
          supertype: Enum
          interfaces
            A
          fields
            static const enumConstant v @57
              reference: <testLibraryFragment>::@enum::B::@field::v
              enclosingElement3: <testLibraryFragment>::@enum::B
              type: B
              shouldUseTypeForInitializerInference: false
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::B::@field::values
              enclosingElement3: <testLibraryFragment>::@enum::B
              type: List<B>
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::B::@constructor::new
              enclosingElement3: <testLibraryFragment>::@enum::B
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::B::@getter::v
              enclosingElement3: <testLibraryFragment>::@enum::B
              returnType: B
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::B::@getter::values
              enclosingElement3: <testLibraryFragment>::@enum::B
              returnType: List<B>
          augmented
            interfaces
              A
            fields
              <testLibraryFragment>::@enum::B::@field::v
              <testLibraryFragment>::@enum::B::@field::values
            constants
              <testLibraryFragment>::@enum::B::@field::v
            constructors
              <testLibraryFragment>::@enum::B::@constructor::new
            accessors
              <testLibraryFragment>::@enum::B::@getter::v
              <testLibraryFragment>::@enum::B::@getter::values
            methods
              <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::B::@method::foo
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum B @34
          reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::B
          enclosingElement3: <testLibrary>::@fragment::package:test/b.dart
          augmentationTarget: <testLibraryFragment>::@enum::B
          methods
            foo @41
              reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::B::@method::foo
              enclosingElement3: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::B
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
      enums
        enum B @38
          reference: <testLibraryFragment>::@enum::B
          element: <testLibrary>::@enum::B
          nextFragment: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::B
          fields
            hasInitializer v @57
              reference: <testLibraryFragment>::@enum::B::@field::v
              element: <testLibraryFragment>::@enum::B::@field::v#element
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: B @-1
                      element: <testLibraryFragment>::@enum::B
                      element2: <testLibrary>::@enum::B
                      type: B
                    staticElement: <testLibraryFragment>::@enum::B::@constructor::new
                    element: <testLibraryFragment>::@enum::B::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: B
              getter2: <testLibraryFragment>::@enum::B::@getter::v
            synthetic values
              reference: <testLibraryFragment>::@enum::B::@field::values
              element: <testLibraryFragment>::@enum::B::@field::values#element
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::B::@getter::v
                      element: <testLibraryFragment>::@enum::B::@getter::v#element
                      staticType: B
                  rightBracket: ] @0
                  staticType: List<B>
              getter2: <testLibraryFragment>::@enum::B::@getter::values
          constructors
            synthetic const new
              reference: <testLibraryFragment>::@enum::B::@constructor::new
              element: <testLibraryFragment>::@enum::B::@constructor::new#element
              typeName: B
          getters
            synthetic get v
              reference: <testLibraryFragment>::@enum::B::@getter::v
              element: <testLibraryFragment>::@enum::B::@getter::v#element
            synthetic get values
              reference: <testLibraryFragment>::@enum::B::@getter::values
              element: <testLibraryFragment>::@enum::B::@getter::values#element
    <testLibrary>::@fragment::package:test/b.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      enums
        enum B @34
          reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::B
          element: <testLibrary>::@enum::B
          previousFragment: <testLibraryFragment>::@enum::B
          methods
            foo @41
              reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::B::@method::foo
              element: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::B::@method::foo#element
              formalParameters
                a @45
                  element: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::B::@method::foo::@parameter::a#element
  enums
    enum B
      reference: <testLibrary>::@enum::B
      firstFragment: <testLibraryFragment>::@enum::B
      supertype: Enum
      interfaces
        A
      fields
        static const enumConstant hasInitializer v
          firstFragment: <testLibraryFragment>::@enum::B::@field::v
          type: B
          constantInitializer
            fragment: <testLibraryFragment>::@enum::B::@field::v
            expression: expression_0
          getter: <testLibraryFragment>::@enum::B::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::B::@field::values
          type: List<B>
          constantInitializer
            fragment: <testLibraryFragment>::@enum::B::@field::values
            expression: expression_1
          getter: <testLibraryFragment>::@enum::B::@getter::values#element
      constructors
        synthetic const new
          firstFragment: <testLibraryFragment>::@enum::B::@constructor::new
      getters
        synthetic static get v
          firstFragment: <testLibraryFragment>::@enum::B::@getter::v
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::B::@getter::values
      methods
        foo
          reference: <testLibrary>::@enum::B::@method::foo
          firstFragment: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::B::@method::foo
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
augment enum B implements A {}
''');

    var library = await buildLibrary(r'''
part 'b.dart';

enum B {
  v;
  foo(a) => 0;
}
''');

    configuration.withConstantInitializers = false;
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
      enums
        enum B @21
          reference: <testLibraryFragment>::@enum::B
          enclosingElement3: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::B
          supertype: Enum
          fields
            static const enumConstant v @27
              reference: <testLibraryFragment>::@enum::B::@field::v
              enclosingElement3: <testLibraryFragment>::@enum::B
              type: B
              shouldUseTypeForInitializerInference: false
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::B::@field::values
              enclosingElement3: <testLibraryFragment>::@enum::B
              type: List<B>
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::B::@constructor::new
              enclosingElement3: <testLibraryFragment>::@enum::B
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::B::@getter::v
              enclosingElement3: <testLibraryFragment>::@enum::B
              returnType: B
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::B::@getter::values
              enclosingElement3: <testLibraryFragment>::@enum::B
              returnType: List<B>
          methods
            foo @32
              reference: <testLibraryFragment>::@enum::B::@method::foo
              enclosingElement3: <testLibraryFragment>::@enum::B
              parameters
                requiredPositional hasImplicitType a @36
                  type: String
              returnType: int
          augmented
            interfaces
              A
            fields
              <testLibraryFragment>::@enum::B::@field::v
              <testLibraryFragment>::@enum::B::@field::values
            constants
              <testLibraryFragment>::@enum::B::@field::v
            constructors
              <testLibraryFragment>::@enum::B::@constructor::new
            accessors
              <testLibraryFragment>::@enum::B::@getter::v
              <testLibraryFragment>::@enum::B::@getter::values
            methods
              <testLibraryFragment>::@enum::B::@method::foo
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement3: <testLibraryFragment>
      libraryImports
        package:test/a.dart
          enclosingElement3: <testLibrary>::@fragment::package:test/b.dart
      enums
        augment enum B @51
          reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::B
          enclosingElement3: <testLibrary>::@fragment::package:test/b.dart
          augmentationTarget: <testLibraryFragment>::@enum::B
          interfaces
            A
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      enums
        enum B @21
          reference: <testLibraryFragment>::@enum::B
          element: <testLibrary>::@enum::B
          nextFragment: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::B
          fields
            hasInitializer v @27
              reference: <testLibraryFragment>::@enum::B::@field::v
              element: <testLibraryFragment>::@enum::B::@field::v#element
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: B @-1
                      element: <testLibraryFragment>::@enum::B
                      element2: <testLibrary>::@enum::B
                      type: B
                    staticElement: <testLibraryFragment>::@enum::B::@constructor::new
                    element: <testLibraryFragment>::@enum::B::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: B
              getter2: <testLibraryFragment>::@enum::B::@getter::v
            synthetic values
              reference: <testLibraryFragment>::@enum::B::@field::values
              element: <testLibraryFragment>::@enum::B::@field::values#element
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::B::@getter::v
                      element: <testLibraryFragment>::@enum::B::@getter::v#element
                      staticType: B
                  rightBracket: ] @0
                  staticType: List<B>
              getter2: <testLibraryFragment>::@enum::B::@getter::values
          constructors
            synthetic const new
              reference: <testLibraryFragment>::@enum::B::@constructor::new
              element: <testLibraryFragment>::@enum::B::@constructor::new#element
              typeName: B
          getters
            synthetic get v
              reference: <testLibraryFragment>::@enum::B::@getter::v
              element: <testLibraryFragment>::@enum::B::@getter::v#element
            synthetic get values
              reference: <testLibraryFragment>::@enum::B::@getter::values
              element: <testLibraryFragment>::@enum::B::@getter::values#element
          methods
            foo @32
              reference: <testLibraryFragment>::@enum::B::@method::foo
              element: <testLibraryFragment>::@enum::B::@method::foo#element
              formalParameters
                a @36
                  element: <testLibraryFragment>::@enum::B::@method::foo::@parameter::a#element
    <testLibrary>::@fragment::package:test/b.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      libraryImports
        package:test/a.dart
      enums
        enum B @51
          reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::B
          element: <testLibrary>::@enum::B
          previousFragment: <testLibraryFragment>::@enum::B
  enums
    enum B
      reference: <testLibrary>::@enum::B
      firstFragment: <testLibraryFragment>::@enum::B
      supertype: Enum
      interfaces
        A
      fields
        static const enumConstant hasInitializer v
          firstFragment: <testLibraryFragment>::@enum::B::@field::v
          type: B
          constantInitializer
            fragment: <testLibraryFragment>::@enum::B::@field::v
            expression: expression_0
          getter: <testLibraryFragment>::@enum::B::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::B::@field::values
          type: List<B>
          constantInitializer
            fragment: <testLibraryFragment>::@enum::B::@field::values
            expression: expression_1
          getter: <testLibraryFragment>::@enum::B::@getter::values#element
      constructors
        synthetic const new
          firstFragment: <testLibraryFragment>::@enum::B::@constructor::new
      getters
        synthetic static get v
          firstFragment: <testLibraryFragment>::@enum::B::@getter::v
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::B::@getter::values
      methods
        foo
          reference: <testLibrary>::@enum::B::@method::foo
          firstFragment: <testLibraryFragment>::@enum::B::@method::foo
          formalParameters
            requiredPositional hasImplicitType a
              type: String
''');
  }

  test_inferTypes_method_usingAugmentation_mixin() async {
    newFile('$testPackageLibPath/a.dart', r'''
mixin A {
  int foo(String a) => 0;
}
''');

    newFile('$testPackageLibPath/b.dart', r'''
part of 'test.dart';
import 'a.dart';
augment enum B with A {}
''');

    var library = await buildLibrary(r'''
part 'b.dart';

enum B {
  v;
  foo(a) => 0;
}
''');

    configuration.withConstantInitializers = false;
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
      enums
        enum B @21
          reference: <testLibraryFragment>::@enum::B
          enclosingElement3: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::B
          supertype: Enum
          fields
            static const enumConstant v @27
              reference: <testLibraryFragment>::@enum::B::@field::v
              enclosingElement3: <testLibraryFragment>::@enum::B
              type: B
              shouldUseTypeForInitializerInference: false
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::B::@field::values
              enclosingElement3: <testLibraryFragment>::@enum::B
              type: List<B>
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::B::@constructor::new
              enclosingElement3: <testLibraryFragment>::@enum::B
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::B::@getter::v
              enclosingElement3: <testLibraryFragment>::@enum::B
              returnType: B
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::B::@getter::values
              enclosingElement3: <testLibraryFragment>::@enum::B
              returnType: List<B>
          methods
            foo @32
              reference: <testLibraryFragment>::@enum::B::@method::foo
              enclosingElement3: <testLibraryFragment>::@enum::B
              parameters
                requiredPositional hasImplicitType a @36
                  type: String
              returnType: int
          augmented
            mixins
              A
            fields
              <testLibraryFragment>::@enum::B::@field::v
              <testLibraryFragment>::@enum::B::@field::values
            constants
              <testLibraryFragment>::@enum::B::@field::v
            constructors
              <testLibraryFragment>::@enum::B::@constructor::new
            accessors
              <testLibraryFragment>::@enum::B::@getter::v
              <testLibraryFragment>::@enum::B::@getter::values
            methods
              <testLibraryFragment>::@enum::B::@method::foo
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement3: <testLibraryFragment>
      libraryImports
        package:test/a.dart
          enclosingElement3: <testLibrary>::@fragment::package:test/b.dart
      enums
        augment enum B @51
          reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::B
          enclosingElement3: <testLibrary>::@fragment::package:test/b.dart
          augmentationTarget: <testLibraryFragment>::@enum::B
          mixins
            A
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      enums
        enum B @21
          reference: <testLibraryFragment>::@enum::B
          element: <testLibrary>::@enum::B
          nextFragment: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::B
          fields
            hasInitializer v @27
              reference: <testLibraryFragment>::@enum::B::@field::v
              element: <testLibraryFragment>::@enum::B::@field::v#element
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: B @-1
                      element: <testLibraryFragment>::@enum::B
                      element2: <testLibrary>::@enum::B
                      type: B
                    staticElement: <testLibraryFragment>::@enum::B::@constructor::new
                    element: <testLibraryFragment>::@enum::B::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: B
              getter2: <testLibraryFragment>::@enum::B::@getter::v
            synthetic values
              reference: <testLibraryFragment>::@enum::B::@field::values
              element: <testLibraryFragment>::@enum::B::@field::values#element
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::B::@getter::v
                      element: <testLibraryFragment>::@enum::B::@getter::v#element
                      staticType: B
                  rightBracket: ] @0
                  staticType: List<B>
              getter2: <testLibraryFragment>::@enum::B::@getter::values
          constructors
            synthetic const new
              reference: <testLibraryFragment>::@enum::B::@constructor::new
              element: <testLibraryFragment>::@enum::B::@constructor::new#element
              typeName: B
          getters
            synthetic get v
              reference: <testLibraryFragment>::@enum::B::@getter::v
              element: <testLibraryFragment>::@enum::B::@getter::v#element
            synthetic get values
              reference: <testLibraryFragment>::@enum::B::@getter::values
              element: <testLibraryFragment>::@enum::B::@getter::values#element
          methods
            foo @32
              reference: <testLibraryFragment>::@enum::B::@method::foo
              element: <testLibraryFragment>::@enum::B::@method::foo#element
              formalParameters
                a @36
                  element: <testLibraryFragment>::@enum::B::@method::foo::@parameter::a#element
    <testLibrary>::@fragment::package:test/b.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      libraryImports
        package:test/a.dart
      enums
        enum B @51
          reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::B
          element: <testLibrary>::@enum::B
          previousFragment: <testLibraryFragment>::@enum::B
  enums
    enum B
      reference: <testLibrary>::@enum::B
      firstFragment: <testLibraryFragment>::@enum::B
      supertype: Enum
      mixins
        A
      fields
        static const enumConstant hasInitializer v
          firstFragment: <testLibraryFragment>::@enum::B::@field::v
          type: B
          constantInitializer
            fragment: <testLibraryFragment>::@enum::B::@field::v
            expression: expression_0
          getter: <testLibraryFragment>::@enum::B::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::B::@field::values
          type: List<B>
          constantInitializer
            fragment: <testLibraryFragment>::@enum::B::@field::values
            expression: expression_1
          getter: <testLibraryFragment>::@enum::B::@getter::values#element
      constructors
        synthetic const new
          firstFragment: <testLibraryFragment>::@enum::B::@constructor::new
      getters
        synthetic static get v
          firstFragment: <testLibraryFragment>::@enum::B::@getter::v
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::B::@getter::values
      methods
        foo
          reference: <testLibrary>::@enum::B::@method::foo
          firstFragment: <testLibraryFragment>::@enum::B::@method::foo
          formalParameters
            requiredPositional hasImplicitType a
              type: String
''');
  }

  test_typeParameters_defaultType() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment enum A<T extends B> {}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
enum A<T extends B> {
  v
}
class B {}
''');

    configuration.withConstantInitializers = false;
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
        class B @49
          reference: <testLibraryFragment>::@class::B
          enclosingElement3: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::B::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::B
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant T @22
              bound: B
              defaultType: B
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @39
              reference: <testLibraryFragment>::@enum::A::@field::v
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: A<B>
              shouldUseTypeForInitializerInference: false
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              enclosingElement3: <testLibraryFragment>::@enum::A
              type: List<A<B>>
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@enum::A
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: A<B>
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              enclosingElement3: <testLibraryFragment>::@enum::A
              returnType: List<A<B>>
          augmented
            fields
              <testLibraryFragment>::@enum::A::@field::v
              <testLibraryFragment>::@enum::A::@field::values
            constants
              <testLibraryFragment>::@enum::A::@field::v
            constructors
              <testLibraryFragment>::@enum::A::@constructor::new
            accessors
              <testLibraryFragment>::@enum::A::@getter::v
              <testLibraryFragment>::@enum::A::@getter::values
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          typeParameters
            covariant T @36
              bound: B
              defaultType: B
          augmentationTarget: <testLibraryFragment>::@enum::A
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/a.dart
      classes
        class B @49
          reference: <testLibraryFragment>::@class::B
          element: <testLibrary>::@class::B
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::B::@constructor::new
              element: <testLibraryFragment>::@class::B::@constructor::new#element
              typeName: B
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          element: <testLibrary>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          typeParameters
            T @22
              element: <not-implemented>
          fields
            hasInitializer v @39
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <testLibraryFragment>::@enum::A::@field::v#element
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibraryFragment>::@enum::A
                      element2: <testLibrary>::@enum::A
                      type: A<B>
                    staticElement: ConstructorMember
                      base: <testLibraryFragment>::@enum::A::@constructor::new
                      substitution: {T: B}
                    element: <testLibraryFragment>::@enum::A::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A<B>
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            synthetic values
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <testLibraryFragment>::@enum::A::@field::values#element
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::A::@getter::v
                      element: <testLibraryFragment>::@enum::A::@getter::v#element
                      staticType: A<B>
                  rightBracket: ] @0
                  staticType: List<A<B>>
              getter2: <testLibraryFragment>::@enum::A::@getter::values
          constructors
            synthetic const new
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <testLibraryFragment>::@enum::A::@constructor::new#element
              typeName: A
          getters
            synthetic get v
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <testLibraryFragment>::@enum::A::@getter::v#element
            synthetic get values
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <testLibraryFragment>::@enum::A::@getter::values#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      enclosingFragment: <testLibraryFragment>
      previousFragment: <testLibraryFragment>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibrary>::@enum::A
          previousFragment: <testLibraryFragment>::@enum::A
          typeParameters
            T @36
              element: <not-implemented>
  classes
    class B
      reference: <testLibrary>::@class::B
      firstFragment: <testLibraryFragment>::@class::B
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::B::@constructor::new
  enums
    enum A
      reference: <testLibrary>::@enum::A
      firstFragment: <testLibraryFragment>::@enum::A
      typeParameters
        T
          bound: B
      supertype: Enum
      fields
        static const enumConstant hasInitializer v
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          type: A<B>
          constantInitializer
            fragment: <testLibraryFragment>::@enum::A::@field::v
            expression: expression_0
          getter: <testLibraryFragment>::@enum::A::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          type: List<A<B>>
          constantInitializer
            fragment: <testLibraryFragment>::@enum::A::@field::values
            expression: expression_1
          getter: <testLibraryFragment>::@enum::A::@getter::values#element
      constructors
        synthetic const new
          firstFragment: <testLibraryFragment>::@enum::A::@constructor::new
      getters
        synthetic static get v
          firstFragment: <testLibraryFragment>::@enum::A::@getter::v
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::A::@getter::values
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
