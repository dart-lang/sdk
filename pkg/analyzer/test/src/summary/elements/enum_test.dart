// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../dart/resolution/node_text_expectations.dart';
import '../element_text.dart';
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          enclosingElement: <testLibraryFragment>
          codeOffset: 0
          codeLength: 26
          supertype: Enum
          fields
            static const enumConstant aaa @11
              reference: <testLibraryFragment>::@enum::E::@field::aaa
              enclosingElement: <testLibraryFragment>::@enum::E
              codeOffset: 11
              codeLength: 3
              type: E
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E
                      type: E
                    staticElement: <testLibraryFragment>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            static const enumConstant bbb @16
              reference: <testLibraryFragment>::@enum::E::@field::bbb
              enclosingElement: <testLibraryFragment>::@enum::E
              codeOffset: 16
              codeLength: 3
              type: E
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E
                      type: E
                    staticElement: <testLibraryFragment>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            static const enumConstant ccc @21
              reference: <testLibraryFragment>::@enum::E::@field::ccc
              enclosingElement: <testLibraryFragment>::@enum::E
              codeOffset: 21
              codeLength: 3
              type: E
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E
                      type: E
                    staticElement: <testLibraryFragment>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              enclosingElement: <testLibraryFragment>::@enum::E
              type: List<E>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: aaa @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::aaa
                      staticType: E
                    SimpleIdentifier
                      token: bbb @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::bbb
                      staticType: E
                    SimpleIdentifier
                      token: ccc @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::ccc
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              enclosingElement: <testLibraryFragment>::@enum::E
          accessors
            synthetic static get aaa @-1
              reference: <testLibraryFragment>::@enum::E::@getter::aaa
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: E
            synthetic static get bbb @-1
              reference: <testLibraryFragment>::@enum::E::@getter::bbb
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: E
            synthetic static get ccc @-1
              reference: <testLibraryFragment>::@enum::E::@getter::ccc
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: E
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: List<E>
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T @7
              defaultType: dynamic
          supertype: Enum
          fields
            static const enumConstant int @14
              reference: <testLibraryFragment>::@enum::E::@field::int
              enclosingElement: <testLibraryFragment>::@enum::E
              type: E<int>
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E
                      type: E<int>
                    staticElement: ConstructorMember
                      base: <testLibraryFragment>::@enum::E::@constructor::new
                      substitution: {T: int}
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    arguments
                      IntegerLiteral
                        literal: 1 @18
                        staticType: int
                    rightParenthesis: ) @0
                  staticType: E<int>
            static const enumConstant string @22
              reference: <testLibraryFragment>::@enum::E::@field::string
              enclosingElement: <testLibraryFragment>::@enum::E
              type: E<String>
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E
                      type: E<String>
                    staticElement: ConstructorMember
                      base: <testLibraryFragment>::@enum::E::@constructor::new
                      substitution: {T: String}
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    arguments
                      SimpleStringLiteral
                        literal: '2' @29
                    rightParenthesis: ) @0
                  staticType: E<String>
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              enclosingElement: <testLibraryFragment>::@enum::E
              type: List<E<dynamic>>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: int @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::int
                      staticType: E<int>
                    SimpleIdentifier
                      token: string @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::string
                      staticType: E<String>
                  rightBracket: ] @0
                  staticType: List<E<dynamic>>
          constructors
            const @43
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              enclosingElement: <testLibraryFragment>::@enum::E
              parameters
                requiredPositional a @47
                  type: T
          accessors
            synthetic static get int @-1
              reference: <testLibraryFragment>::@enum::E::@getter::int
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: E<int>
            synthetic static get string @-1
              reference: <testLibraryFragment>::@enum::E::@getter::string
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: E<String>
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: List<E<dynamic>>
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          enclosingElement: <testLibraryFragment>
          supertype: Enum
          fields
            static const enumConstant _name @11
              reference: <testLibraryFragment>::@enum::E::@field::_name
              enclosingElement: <testLibraryFragment>::@enum::E
              type: E
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E
                      type: E
                    staticElement: <testLibraryFragment>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              enclosingElement: <testLibraryFragment>::@enum::E
              type: List<E>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: _name @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::_name
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              enclosingElement: <testLibraryFragment>::@enum::E
          accessors
            synthetic static get _name @-1
              reference: <testLibraryFragment>::@enum::E::@getter::_name
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: E
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: List<E>
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T @7
              defaultType: dynamic
          supertype: Enum
          fields
            static const enumConstant v @14
              reference: <testLibraryFragment>::@enum::E::@field::v
              enclosingElement: <testLibraryFragment>::@enum::E
              type: E<double>
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      typeArguments: TypeArgumentList
                        leftBracket: < @15
                        arguments
                          NamedType
                            name: double @16
                            element: dart:core::<fragment>::@class::double
                            type: double
                        rightBracket: > @22
                      element: <testLibraryFragment>::@enum::E
                      type: E<double>
                    staticElement: ConstructorMember
                      base: <testLibraryFragment>::@enum::E::@constructor::new
                      substitution: {T: double}
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    arguments
                      IntegerLiteral
                        literal: 42 @24
                        staticType: double
                    rightParenthesis: ) @0
                  staticType: E<double>
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              enclosingElement: <testLibraryFragment>::@enum::E
              type: List<E<dynamic>>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::v
                      staticType: E<double>
                  rightBracket: ] @0
                  staticType: List<E<dynamic>>
          constructors
            const @37
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              enclosingElement: <testLibraryFragment>::@enum::E
              parameters
                requiredPositional a @41
                  type: T
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: E<double>
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: List<E<dynamic>>
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          enclosingElement: <testLibraryFragment>
          supertype: Enum
          fields
            static const enumConstant _ @11
              reference: <testLibraryFragment>::@enum::E::@field::_
              enclosingElement: <testLibraryFragment>::@enum::E
              type: E
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E
                      type: E
                    staticElement: <testLibraryFragment>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              enclosingElement: <testLibraryFragment>::@enum::E
              type: List<E>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: _ @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::_
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              enclosingElement: <testLibraryFragment>::@enum::E
          accessors
            synthetic static get _ @-1
              reference: <testLibraryFragment>::@enum::E::@getter::_
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: E
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: List<E>
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          enclosingElement: <testLibraryFragment>
          supertype: Enum
          fields
            static const enumConstant v @11
              reference: <testLibraryFragment>::@enum::E::@field::v
              enclosingElement: <testLibraryFragment>::@enum::E
              type: E
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E
                      type: E
                    staticElement: <testLibraryFragment>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              enclosingElement: <testLibraryFragment>::@enum::E
              type: List<E>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::v
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
          constructors
            factory named @26
              reference: <testLibraryFragment>::@enum::E::@constructor::named
              enclosingElement: <testLibraryFragment>::@enum::E
              periodOffset: 25
              nameEnd: 31
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              enclosingElement: <testLibraryFragment>::@enum::E
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: E
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: List<E>
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          enclosingElement: <testLibraryFragment>
          supertype: Enum
          fields
            static const enumConstant v @11
              reference: <testLibraryFragment>::@enum::E::@field::v
              enclosingElement: <testLibraryFragment>::@enum::E
              type: E
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E
                      type: E
                    staticElement: <testLibraryFragment>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              enclosingElement: <testLibraryFragment>::@enum::E
              type: List<E>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::v
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
          constructors
            factory @24
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              enclosingElement: <testLibraryFragment>::@enum::E
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: E
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: List<E>
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          enclosingElement: <testLibraryFragment>
          supertype: Enum
          fields
            static const enumConstant v @11
              reference: <testLibraryFragment>::@enum::E::@field::v
              enclosingElement: <testLibraryFragment>::@enum::E
              type: E
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E
                      type: E
                    staticElement: <testLibraryFragment>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              enclosingElement: <testLibraryFragment>::@enum::E
              type: List<E>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::v
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
            final x @22
              reference: <testLibraryFragment>::@enum::E::@field::x
              enclosingElement: <testLibraryFragment>::@enum::E
              type: dynamic
          constructors
            const @33
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              enclosingElement: <testLibraryFragment>::@enum::E
              parameters
                requiredPositional final this.x @44
                  type: int Function(double)
                  parameters
                    requiredPositional a @53
                      type: double
                  field: <testLibraryFragment>::@enum::E::@field::x
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: E
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: List<E>
            synthetic get x @-1
              reference: <testLibraryFragment>::@enum::E::@getter::x
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: dynamic
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          enclosingElement: <testLibraryFragment>
          supertype: Enum
          fields
            static const enumConstant v @11
              reference: <testLibraryFragment>::@enum::E::@field::v
              enclosingElement: <testLibraryFragment>::@enum::E
              type: E
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E
                      type: E
                    staticElement: <testLibraryFragment>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              enclosingElement: <testLibraryFragment>::@enum::E
              type: List<E>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::v
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
            final x @26
              reference: <testLibraryFragment>::@enum::E::@field::x::@def::0
              enclosingElement: <testLibraryFragment>::@enum::E
              type: int
            final x @44
              reference: <testLibraryFragment>::@enum::E::@field::x::@def::1
              enclosingElement: <testLibraryFragment>::@enum::E
              type: String
          constructors
            const @55
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              enclosingElement: <testLibraryFragment>::@enum::E
              parameters
                requiredPositional final this.x @62
                  type: int
                  field: <testLibraryFragment>::@enum::E::@field::x::@def::0
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: E
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: List<E>
            synthetic get x @-1
              reference: <testLibraryFragment>::@enum::E::@getter::x::@def::0
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: int
            synthetic get x @-1
              reference: <testLibraryFragment>::@enum::E::@getter::x::@def::1
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: String
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          enclosingElement: <testLibraryFragment>
          supertype: Enum
          fields
            static const enumConstant v @11
              reference: <testLibraryFragment>::@enum::E::@field::v
              enclosingElement: <testLibraryFragment>::@enum::E
              type: E
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E
                      type: E
                    staticElement: <testLibraryFragment>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              enclosingElement: <testLibraryFragment>::@enum::E
              type: List<E>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::v
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
          constructors
            const @22
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              enclosingElement: <testLibraryFragment>::@enum::E
              parameters
                requiredPositional final this.x @29
                  type: dynamic
                  field: <null>
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: E
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: List<E>
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          enclosingElement: <testLibraryFragment>
          supertype: Enum
          fields
            static const enumConstant v @11
              reference: <testLibraryFragment>::@enum::E::@field::v
              enclosingElement: <testLibraryFragment>::@enum::E
              type: E
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E
                      type: E
                    staticElement: <testLibraryFragment>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              enclosingElement: <testLibraryFragment>::@enum::E
              type: List<E>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::v
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
            final x @26
              reference: <testLibraryFragment>::@enum::E::@field::x
              enclosingElement: <testLibraryFragment>::@enum::E
              type: int
          constructors
            const @37
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              enclosingElement: <testLibraryFragment>::@enum::E
              parameters
                optionalNamed default final this.x @45
                  reference: <testLibraryFragment>::@enum::E::@constructor::new::@parameter::x
                  type: int
                  constantInitializer
                    BinaryExpression
                      leftOperand: IntegerLiteral
                        literal: 1 @49
                        staticType: int
                      operator: + @51
                      rightOperand: IntegerLiteral
                        literal: 2 @53
                        staticType: int
                      staticElement: dart:core::<fragment>::@class::num::@method::+
                      staticInvokeType: num Function(num)
                      staticType: int
                  field: <testLibraryFragment>::@enum::E::@field::x
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: E
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: List<E>
            synthetic get x @-1
              reference: <testLibraryFragment>::@enum::E::@getter::x
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: int
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          enclosingElement: <testLibraryFragment>
          supertype: Enum
          fields
            static const enumConstant v @11
              reference: <testLibraryFragment>::@enum::E::@field::v
              enclosingElement: <testLibraryFragment>::@enum::E
              type: E
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E
                      type: E
                    staticElement: <testLibraryFragment>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              enclosingElement: <testLibraryFragment>::@enum::E
              type: List<E>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::v
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
            final x @26
              reference: <testLibraryFragment>::@enum::E::@field::x
              enclosingElement: <testLibraryFragment>::@enum::E
              type: num
          constructors
            const @37
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              enclosingElement: <testLibraryFragment>::@enum::E
              parameters
                requiredPositional final this.x @48
                  type: int
                  field: <testLibraryFragment>::@enum::E::@field::x
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: E
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: List<E>
            synthetic get x @-1
              reference: <testLibraryFragment>::@enum::E::@getter::x
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: num
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          enclosingElement: <testLibraryFragment>
          supertype: Enum
          fields
            static const enumConstant v @11
              reference: <testLibraryFragment>::@enum::E::@field::v
              enclosingElement: <testLibraryFragment>::@enum::E
              type: E
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E
                      type: E
                    staticElement: <testLibraryFragment>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              enclosingElement: <testLibraryFragment>::@enum::E
              type: List<E>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::v
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
            final x @22
              reference: <testLibraryFragment>::@enum::E::@field::x
              enclosingElement: <testLibraryFragment>::@enum::E
              type: dynamic
          constructors
            @27
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              enclosingElement: <testLibraryFragment>::@enum::E
              parameters
                requiredPositional final this.x @38
                  type: int
                  field: <testLibraryFragment>::@enum::E::@field::x
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: E
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: List<E>
            synthetic get x @-1
              reference: <testLibraryFragment>::@enum::E::@getter::x
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: dynamic
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          enclosingElement: <testLibraryFragment>
          supertype: Enum
          fields
            static const enumConstant v @11
              reference: <testLibraryFragment>::@enum::E::@field::v
              enclosingElement: <testLibraryFragment>::@enum::E
              type: E
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E
                      type: E
                    staticElement: <testLibraryFragment>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              enclosingElement: <testLibraryFragment>::@enum::E
              type: List<E>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::v
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
            final x @22
              reference: <testLibraryFragment>::@enum::E::@field::x
              enclosingElement: <testLibraryFragment>::@enum::E
              type: dynamic
          constructors
            @27
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              enclosingElement: <testLibraryFragment>::@enum::E
              parameters
                requiredPositional final this.x @34
                  type: dynamic
                  field: <testLibraryFragment>::@enum::E::@field::x
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: E
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: List<E>
            synthetic get x @-1
              reference: <testLibraryFragment>::@enum::E::@getter::x
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: dynamic
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          enclosingElement: <testLibraryFragment>
          supertype: Enum
          fields
            static const enumConstant v @11
              reference: <testLibraryFragment>::@enum::E::@field::v
              enclosingElement: <testLibraryFragment>::@enum::E
              type: E
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E
                      type: E
                    period: . @0
                    name: SimpleIdentifier
                      token: named @-1
                      staticElement: <testLibraryFragment>::@enum::E::@constructor::named
                      staticType: null
                    staticElement: <testLibraryFragment>::@enum::E::@constructor::named
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    arguments
                      IntegerLiteral
                        literal: 42 @19
                        staticType: int
                    rightParenthesis: ) @0
                  staticType: E
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              enclosingElement: <testLibraryFragment>::@enum::E
              type: List<E>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::v
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
          constructors
            const named @34
              reference: <testLibraryFragment>::@enum::E::@constructor::named
              enclosingElement: <testLibraryFragment>::@enum::E
              periodOffset: 33
              nameEnd: 39
              parameters
                requiredPositional a @44
                  type: int
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: E
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: List<E>
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          enclosingElement: <testLibraryFragment>
          supertype: Enum
          fields
            static const enumConstant v @11
              reference: <testLibraryFragment>::@enum::E::@field::v
              enclosingElement: <testLibraryFragment>::@enum::E
              type: E
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E
                      type: E
                    staticElement: <testLibraryFragment>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    arguments
                      IntegerLiteral
                        literal: 42 @13
                        staticType: int
                    rightParenthesis: ) @0
                  staticType: E
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              enclosingElement: <testLibraryFragment>::@enum::E
              type: List<E>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::v
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
          constructors
            const @26
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              enclosingElement: <testLibraryFragment>::@enum::E
              parameters
                requiredPositional a @32
                  type: int
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: E
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: List<E>
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T @7
              defaultType: dynamic
          supertype: Enum
          fields
            static const enumConstant v @14
              reference: <testLibraryFragment>::@enum::E::@field::v
              enclosingElement: <testLibraryFragment>::@enum::E
              type: E<dynamic>
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E
                      type: E<dynamic>
                    staticElement: ConstructorMember
                      base: <testLibraryFragment>::@enum::E::@constructor::new
                      substitution: {T: dynamic}
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E<dynamic>
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              enclosingElement: <testLibraryFragment>::@enum::E
              type: List<E<dynamic>>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::v
                      staticType: E<dynamic>
                  rightBracket: ] @0
                  staticType: List<E<dynamic>>
            final x @29
              reference: <testLibraryFragment>::@enum::E::@field::x
              enclosingElement: <testLibraryFragment>::@enum::E
              type: int
          constructors
            const @40
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              enclosingElement: <testLibraryFragment>::@enum::E
              parameters
                requiredPositional a @45
                  type: T?
              constantInitializers
                AssertInitializer
                  assertKeyword: assert @50
                  leftParenthesis: ( @56
                  condition: IsExpression
                    expression: SimpleIdentifier
                      token: a @57
                      staticElement: <testLibraryFragment>::@enum::E::@constructor::new::@parameter::a
                      staticType: T?
                    isOperator: is @59
                    type: NamedType
                      name: T @62
                      element: T@7
                      type: T
                    staticType: bool
                  rightParenthesis: ) @63
                ConstructorFieldInitializer
                  fieldName: SimpleIdentifier
                    token: x @66
                    staticElement: <testLibraryFragment>::@enum::E::@field::x
                    staticType: null
                  equals: = @68
                  expression: IntegerLiteral
                    literal: 0 @70
                    staticType: int
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: E<dynamic>
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: List<E<dynamic>>
            synthetic get x @-1
              reference: <testLibraryFragment>::@enum::E::@getter::x
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: int
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      enums
        enum E @65
          reference: <testLibraryFragment>::@enum::E
          enclosingElement: <testLibraryFragment>
          documentationComment: /**\n * Docs\n */
          supertype: Enum
          fields
            static const enumConstant v @69
              reference: <testLibraryFragment>::@enum::E::@field::v
              enclosingElement: <testLibraryFragment>::@enum::E
              type: E
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E
                      type: E
                    staticElement: <testLibraryFragment>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              enclosingElement: <testLibraryFragment>::@enum::E
              type: List<E>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::v
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              enclosingElement: <testLibraryFragment>::@enum::E
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: E
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: List<E>
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          enclosingElement: <testLibraryFragment>
          supertype: Enum
          fields
            static const enumConstant v @11
              reference: <testLibraryFragment>::@enum::E::@field::v
              enclosingElement: <testLibraryFragment>::@enum::E
              type: E
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E
                      type: E
                    staticElement: <testLibraryFragment>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              enclosingElement: <testLibraryFragment>::@enum::E
              type: List<E>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::v
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
            final foo @22
              reference: <testLibraryFragment>::@enum::E::@field::foo
              enclosingElement: <testLibraryFragment>::@enum::E
              type: int
              shouldUseTypeForInitializerInference: false
              constantInitializer
                IntegerLiteral
                  literal: 42 @28
                  staticType: int
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              enclosingElement: <testLibraryFragment>::@enum::E
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: E
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: List<E>
            synthetic get foo @-1
              reference: <testLibraryFragment>::@enum::E::@getter::foo
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: int
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
    configuration.forPromotableFields(
      enumNames: {'E'},
      fieldNames: {'_foo'},
    );
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          enclosingElement: <testLibraryFragment>
          supertype: Enum
          fields
            final promotable _foo @33
              reference: <testLibraryFragment>::@enum::E::@field::_foo
              enclosingElement: <testLibraryFragment>::@enum::E
              type: int?
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          enclosingElement: <testLibraryFragment>
          supertype: Enum
          fields
            static const enumConstant v @10
              reference: <testLibraryFragment>::@enum::E::@field::v
              enclosingElement: <testLibraryFragment>::@enum::E
              type: E
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E
                      type: E
                    staticElement: <testLibraryFragment>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              enclosingElement: <testLibraryFragment>::@enum::E
              type: List<E>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::v
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
            synthetic foo @-1
              reference: <testLibraryFragment>::@enum::E::@field::foo
              enclosingElement: <testLibraryFragment>::@enum::E
              type: int
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              enclosingElement: <testLibraryFragment>::@enum::E
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: E
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: List<E>
            get foo @23
              reference: <testLibraryFragment>::@enum::E::@getter::foo
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: int
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      classes
        class I @6
          reference: <testLibraryFragment>::@class::I
          enclosingElement: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::I::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::I
      enums
        enum E @16
          reference: <testLibraryFragment>::@enum::E
          enclosingElement: <testLibraryFragment>
          supertype: Enum
          interfaces
            I
          fields
            static const enumConstant v @35
              reference: <testLibraryFragment>::@enum::E::@field::v
              enclosingElement: <testLibraryFragment>::@enum::E
              type: E
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E
                      type: E
                    staticElement: <testLibraryFragment>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              enclosingElement: <testLibraryFragment>::@enum::E
              type: List<E>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::v
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              enclosingElement: <testLibraryFragment>::@enum::E
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: E
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: List<E>
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
      enums
        enum E @55
          reference: <testLibraryFragment>::@enum::E
          enclosingElement: <testLibraryFragment>
          supertype: Enum
          interfaces
            A
            C
          fields
            static const enumConstant v @78
              reference: <testLibraryFragment>::@enum::E::@field::v
              enclosingElement: <testLibraryFragment>::@enum::E
              type: E
              shouldUseTypeForInitializerInference: false
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              enclosingElement: <testLibraryFragment>::@enum::E
              type: List<E>
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: E
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: List<E>
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      classes
        class I @6
          reference: <testLibraryFragment>::@class::I
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T @8
              defaultType: dynamic
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::I::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::I
      enums
        enum E @19
          reference: <testLibraryFragment>::@enum::E
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant U @21
              defaultType: dynamic
          supertype: Enum
          interfaces
            I<U>
          fields
            static const enumConstant v @44
              reference: <testLibraryFragment>::@enum::E::@field::v
              enclosingElement: <testLibraryFragment>::@enum::E
              type: E<dynamic>
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E
                      type: E<dynamic>
                    staticElement: ConstructorMember
                      base: <testLibraryFragment>::@enum::E::@constructor::new
                      substitution: {U: dynamic}
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E<dynamic>
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              enclosingElement: <testLibraryFragment>::@enum::E
              type: List<E<dynamic>>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::v
                      staticType: E<dynamic>
                  rightBracket: ] @0
                  staticType: List<E<dynamic>>
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              enclosingElement: <testLibraryFragment>::@enum::E
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: E<dynamic>
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: List<E<dynamic>>
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      classes
        class X @6
          reference: <testLibraryFragment>::@class::X
          enclosingElement: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::X::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::X
        class Z @17
          reference: <testLibraryFragment>::@class::Z
          enclosingElement: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::Z::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::Z
      enums
        enum E @27
          reference: <testLibraryFragment>::@enum::E
          enclosingElement: <testLibraryFragment>
          supertype: Enum
          interfaces
            X
            Z
          fields
            static const enumConstant v @52
              reference: <testLibraryFragment>::@enum::E::@field::v
              enclosingElement: <testLibraryFragment>::@enum::E
              type: E
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E
                      type: E
                    staticElement: <testLibraryFragment>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              enclosingElement: <testLibraryFragment>::@enum::E
              type: List<E>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::v
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              enclosingElement: <testLibraryFragment>::@enum::E
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: E
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: List<E>
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T @7
              defaultType: dynamic
          supertype: Enum
          fields
            static const enumConstant v @14
              reference: <testLibraryFragment>::@enum::E::@field::v
              enclosingElement: <testLibraryFragment>::@enum::E
              type: E<dynamic>
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E
                      type: E<dynamic>
                    staticElement: ConstructorMember
                      base: <testLibraryFragment>::@enum::E::@constructor::new
                      substitution: {T: dynamic}
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E<dynamic>
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              enclosingElement: <testLibraryFragment>::@enum::E
              type: List<E<dynamic>>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::v
                      staticType: E<dynamic>
                  rightBracket: ] @0
                  staticType: List<E<dynamic>>
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              enclosingElement: <testLibraryFragment>::@enum::E
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: E<dynamic>
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: List<E<dynamic>>
          methods
            foo @23
              reference: <testLibraryFragment>::@enum::E::@method::foo
              enclosingElement: <testLibraryFragment>::@enum::E
              typeParameters
                covariant U @27
                  defaultType: dynamic
              parameters
                requiredPositional t @32
                  type: T
                requiredPositional u @37
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          enclosingElement: <testLibraryFragment>
          supertype: Enum
          fields
            static const enumConstant v @11
              reference: <testLibraryFragment>::@enum::E::@field::v
              enclosingElement: <testLibraryFragment>::@enum::E
              type: E
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E
                      type: E
                    staticElement: <testLibraryFragment>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              enclosingElement: <testLibraryFragment>::@enum::E
              type: List<E>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::v
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              enclosingElement: <testLibraryFragment>::@enum::E
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: E
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: List<E>
          methods
            toString @23
              reference: <testLibraryFragment>::@enum::E::@method::toString
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: String
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      enums
        enum E @16
          reference: <testLibraryFragment>::@enum::E
          enclosingElement: <testLibraryFragment>
          supertype: Enum
          mixins
            M
          fields
            static const enumConstant v @29
              reference: <testLibraryFragment>::@enum::E::@field::v
              enclosingElement: <testLibraryFragment>::@enum::E
              type: E
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E
                      type: E
                    staticElement: <testLibraryFragment>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              enclosingElement: <testLibraryFragment>::@enum::E
              type: List<E>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::v
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              enclosingElement: <testLibraryFragment>::@enum::E
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: E
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: List<E>
      mixins
        mixin M @6
          reference: <testLibraryFragment>::@mixin::M
          enclosingElement: <testLibraryFragment>
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
      enums
        enum E @55
          reference: <testLibraryFragment>::@enum::E
          enclosingElement: <testLibraryFragment>
          supertype: Enum
          mixins
            A
            C
          fields
            static const enumConstant v @72
              reference: <testLibraryFragment>::@enum::E::@field::v
              enclosingElement: <testLibraryFragment>::@enum::E
              type: E
              shouldUseTypeForInitializerInference: false
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              enclosingElement: <testLibraryFragment>::@enum::E
              type: List<E>
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: E
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: List<E>
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      enums
        enum E @44
          reference: <testLibraryFragment>::@enum::E
          enclosingElement: <testLibraryFragment>
          supertype: Enum
          mixins
            M1<int>
            M2<int>
          fields
            static const enumConstant v @67
              reference: <testLibraryFragment>::@enum::E::@field::v
              enclosingElement: <testLibraryFragment>::@enum::E
              type: E
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E
                      type: E
                    staticElement: <testLibraryFragment>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              enclosingElement: <testLibraryFragment>::@enum::E
              type: List<E>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::v
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              enclosingElement: <testLibraryFragment>::@enum::E
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: E
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: List<E>
      mixins
        mixin M1 @6
          reference: <testLibraryFragment>::@mixin::M1
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T @9
              defaultType: dynamic
          superclassConstraints
            Object
        mixin M2 @21
          reference: <testLibraryFragment>::@mixin::M2
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T @24
              defaultType: dynamic
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          enclosingElement: <testLibraryFragment>
          supertype: Enum
          fields
            static const enumConstant v @10
              reference: <testLibraryFragment>::@enum::E::@field::v
              enclosingElement: <testLibraryFragment>::@enum::E
              type: E
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E
                      type: E
                    staticElement: <testLibraryFragment>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              enclosingElement: <testLibraryFragment>::@enum::E
              type: List<E>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::v
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
            synthetic foo @-1
              reference: <testLibraryFragment>::@enum::E::@field::foo
              enclosingElement: <testLibraryFragment>::@enum::E
              type: int
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              enclosingElement: <testLibraryFragment>::@enum::E
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: E
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: List<E>
            set foo= @19
              reference: <testLibraryFragment>::@enum::E::@setter::foo
              enclosingElement: <testLibraryFragment>::@enum::E
              parameters
                requiredPositional _ @27
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T @7
              defaultType: dynamic
          supertype: Enum
          fields
            static const enumConstant v @14
              reference: <testLibraryFragment>::@enum::E::@field::v
              enclosingElement: <testLibraryFragment>::@enum::E
              type: E<dynamic>
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E
                      type: E<dynamic>
                    staticElement: ConstructorMember
                      base: <testLibraryFragment>::@enum::E::@constructor::new
                      substitution: {T: dynamic}
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E<dynamic>
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              enclosingElement: <testLibraryFragment>::@enum::E
              type: List<E<dynamic>>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::v
                      staticType: E<dynamic>
                  rightBracket: ] @0
                  staticType: List<E<dynamic>>
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              enclosingElement: <testLibraryFragment>::@enum::E
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: E<dynamic>
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: List<E<dynamic>>
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      enums
        notSimplyBounded enum E @5
          reference: <testLibraryFragment>::@enum::E
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T @7
              bound: num
              defaultType: num
            covariant U @22
              bound: T
              defaultType: num
          supertype: Enum
          fields
            static const enumConstant v @39
              reference: <testLibraryFragment>::@enum::E::@field::v
              enclosingElement: <testLibraryFragment>::@enum::E
              type: E<num, num>
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E
                      type: E<num, num>
                    staticElement: ConstructorMember
                      base: <testLibraryFragment>::@enum::E::@constructor::new
                      substitution: {T: num, U: num}
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E<num, num>
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              enclosingElement: <testLibraryFragment>::@enum::E
              type: List<E<num, num>>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::v
                      staticType: E<num, num>
                  rightBracket: ] @0
                  staticType: List<E<num, num>>
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              enclosingElement: <testLibraryFragment>::@enum::E
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: E<num, num>
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: List<E<num, num>>
''');
  }

  test_enum_typeParameters_cycle_1of1() async {
    var library = await buildLibrary('''
enum E<T extends T> {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      enums
        notSimplyBounded enum E @5
          reference: <testLibraryFragment>::@enum::E
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T @7
              bound: dynamic
              defaultType: dynamic
          supertype: Enum
          fields
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              enclosingElement: <testLibraryFragment>::@enum::E
              type: List<E<dynamic>>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  rightBracket: ] @0
                  staticType: List<E<dynamic>>
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              enclosingElement: <testLibraryFragment>::@enum::E
          accessors
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: List<E<dynamic>>
''');
  }

  test_enum_typeParameters_cycle_2of3() async {
    var library = await buildLibrary(r'''
enum E<T extends V, U extends num, V extends T> {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      enums
        notSimplyBounded enum E @5
          reference: <testLibraryFragment>::@enum::E
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T @7
              bound: dynamic
              defaultType: dynamic
            covariant U @20
              bound: num
              defaultType: num
            covariant V @35
              bound: dynamic
              defaultType: dynamic
          supertype: Enum
          fields
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              enclosingElement: <testLibraryFragment>::@enum::E
              type: List<E<dynamic, num, dynamic>>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  rightBracket: ] @0
                  staticType: List<E<dynamic, num, dynamic>>
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              enclosingElement: <testLibraryFragment>::@enum::E
          accessors
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: List<E<dynamic, num, dynamic>>
''');
  }

  test_enum_typeParameters_defaultType_cycle_genericFunctionType() async {
    var library = await buildLibrary(r'''
enum E<T extends void Function(E)> {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      enums
        notSimplyBounded enum E @5
          reference: <testLibraryFragment>::@enum::E
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T @7
              bound: void Function(E<dynamic>)
              defaultType: dynamic
          supertype: Enum
          fields
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              enclosingElement: <testLibraryFragment>::@enum::E
              type: List<E<dynamic>>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  rightBracket: ] @0
                  staticType: List<E<dynamic>>
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              enclosingElement: <testLibraryFragment>::@enum::E
          accessors
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: List<E<dynamic>>
''');
  }

  test_enum_typeParameters_variance_contravariant() async {
    var library = await buildLibrary('''
enum E<in T> {}
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
          reference: <testLibraryFragment>::@enum::E
          enclosingElement: <testLibraryFragment>
          typeParameters
            contravariant T @10
              defaultType: dynamic
          supertype: Enum
          fields
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              enclosingElement: <testLibraryFragment>::@enum::E
              type: List<E<dynamic>>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  rightBracket: ] @0
                  staticType: List<E<dynamic>>
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              enclosingElement: <testLibraryFragment>::@enum::E
          accessors
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: List<E<dynamic>>
''');
  }

  test_enum_typeParameters_variance_covariant() async {
    var library = await buildLibrary('''
enum E<out T> {}
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
          reference: <testLibraryFragment>::@enum::E
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T @11
              defaultType: dynamic
          supertype: Enum
          fields
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              enclosingElement: <testLibraryFragment>::@enum::E
              type: List<E<dynamic>>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  rightBracket: ] @0
                  staticType: List<E<dynamic>>
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              enclosingElement: <testLibraryFragment>::@enum::E
          accessors
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: List<E<dynamic>>
''');
  }

  test_enum_typeParameters_variance_invariant() async {
    var library = await buildLibrary('''
enum E<inout T> {}
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
          reference: <testLibraryFragment>::@enum::E
          enclosingElement: <testLibraryFragment>
          typeParameters
            invariant T @13
              defaultType: dynamic
          supertype: Enum
          fields
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              enclosingElement: <testLibraryFragment>::@enum::E
              type: List<E<dynamic>>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  rightBracket: ] @0
                  staticType: List<E<dynamic>>
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              enclosingElement: <testLibraryFragment>::@enum::E
          accessors
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: List<E<dynamic>>
''');
  }

  test_enum_typeParameters_variance_multiple() async {
    var library = await buildLibrary('''
enum E<inout T, in U, out V> {}
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
          reference: <testLibraryFragment>::@enum::E
          enclosingElement: <testLibraryFragment>
          typeParameters
            invariant T @13
              defaultType: dynamic
            contravariant U @19
              defaultType: dynamic
            covariant V @26
              defaultType: dynamic
          supertype: Enum
          fields
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              enclosingElement: <testLibraryFragment>::@enum::E
              type: List<E<dynamic, dynamic, dynamic>>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  rightBracket: ] @0
                  staticType: List<E<dynamic, dynamic, dynamic>>
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              enclosingElement: <testLibraryFragment>::@enum::E
          accessors
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: List<E<dynamic, dynamic, dynamic>>
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          enclosingElement: <testLibraryFragment>
          supertype: Enum
          fields
            static const enumConstant a @32
              reference: <testLibraryFragment>::@enum::E::@field::a
              enclosingElement: <testLibraryFragment>::@enum::E
              documentationComment: /**\n   * aaa\n   */
              type: E
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E
                      type: E
                    staticElement: <testLibraryFragment>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            static const enumConstant b @47
              reference: <testLibraryFragment>::@enum::E::@field::b
              enclosingElement: <testLibraryFragment>::@enum::E
              documentationComment: /// bbb
              type: E
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E
                      type: E
                    staticElement: <testLibraryFragment>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              enclosingElement: <testLibraryFragment>::@enum::E
              type: List<E>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: a @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::a
                      staticType: E
                    SimpleIdentifier
                      token: b @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::b
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              enclosingElement: <testLibraryFragment>::@enum::E
          accessors
            synthetic static get a @-1
              reference: <testLibraryFragment>::@enum::E::@getter::a
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: E
            synthetic static get b @-1
              reference: <testLibraryFragment>::@enum::E::@getter::b
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: E
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: List<E>
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          enclosingElement: <testLibraryFragment>
          supertype: Enum
          fields
            static const enumConstant a @46
              reference: <testLibraryFragment>::@enum::E::@field::a
              enclosingElement: <testLibraryFragment>::@enum::E
              documentationComment: /**\n   * aaa\n   */
              metadata
                Annotation
                  atSign: @ @32
                  name: SimpleIdentifier
                    token: annotation @33
                    staticElement: <testLibraryFragment>::@getter::annotation
                    staticType: null
                  element: <testLibraryFragment>::@getter::annotation
              type: E
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E
                      type: E
                    staticElement: <testLibraryFragment>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            static const enumConstant b @75
              reference: <testLibraryFragment>::@enum::E::@field::b
              enclosingElement: <testLibraryFragment>::@enum::E
              documentationComment: /// bbb
              metadata
                Annotation
                  atSign: @ @61
                  name: SimpleIdentifier
                    token: annotation @62
                    staticElement: <testLibraryFragment>::@getter::annotation
                    staticType: null
                  element: <testLibraryFragment>::@getter::annotation
              type: E
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E
                      type: E
                    staticElement: <testLibraryFragment>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              enclosingElement: <testLibraryFragment>::@enum::E
              type: List<E>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: a @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::a
                      staticType: E
                    SimpleIdentifier
                      token: b @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::b
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              enclosingElement: <testLibraryFragment>::@enum::E
          accessors
            synthetic static get a @-1
              reference: <testLibraryFragment>::@enum::E::@getter::a
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: E
            synthetic static get b @-1
              reference: <testLibraryFragment>::@enum::E::@getter::b
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: E
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: List<E>
      topLevelVariables
        static const annotation @91
          reference: <testLibraryFragment>::@topLevelVariable::annotation
          enclosingElement: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: true
          constantInitializer
            IntegerLiteral
              literal: 0 @104
              staticType: int
      accessors
        synthetic static get annotation @-1
          reference: <testLibraryFragment>::@getter::annotation
          enclosingElement: <testLibraryFragment>
          returnType: int
''');
  }

  test_enum_values() async {
    var library = await buildLibrary('enum E { v1, v2 }');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          enclosingElement: <testLibraryFragment>
          supertype: Enum
          fields
            static const enumConstant v1 @9
              reference: <testLibraryFragment>::@enum::E::@field::v1
              enclosingElement: <testLibraryFragment>::@enum::E
              type: E
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E
                      type: E
                    staticElement: <testLibraryFragment>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            static const enumConstant v2 @13
              reference: <testLibraryFragment>::@enum::E::@field::v2
              enclosingElement: <testLibraryFragment>::@enum::E
              type: E
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E
                      type: E
                    staticElement: <testLibraryFragment>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              enclosingElement: <testLibraryFragment>::@enum::E
              type: List<E>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v1 @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::v1
                      staticType: E
                    SimpleIdentifier
                      token: v2 @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::v2
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              enclosingElement: <testLibraryFragment>::@enum::E
          accessors
            synthetic static get v1 @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v1
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: E
            synthetic static get v2 @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v2
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: E
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: List<E>
''');
  }

  test_enums() async {
    var library = await buildLibrary('enum E1 { v1 } enum E2 { v2 }');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      enums
        enum E1 @5
          reference: <testLibraryFragment>::@enum::E1
          enclosingElement: <testLibraryFragment>
          supertype: Enum
          fields
            static const enumConstant v1 @10
              reference: <testLibraryFragment>::@enum::E1::@field::v1
              enclosingElement: <testLibraryFragment>::@enum::E1
              type: E1
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E1 @-1
                      element: <testLibraryFragment>::@enum::E1
                      type: E1
                    staticElement: <testLibraryFragment>::@enum::E1::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E1
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::E1::@field::values
              enclosingElement: <testLibraryFragment>::@enum::E1
              type: List<E1>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v1 @-1
                      staticElement: <testLibraryFragment>::@enum::E1::@getter::v1
                      staticType: E1
                  rightBracket: ] @0
                  staticType: List<E1>
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::E1::@constructor::new
              enclosingElement: <testLibraryFragment>::@enum::E1
          accessors
            synthetic static get v1 @-1
              reference: <testLibraryFragment>::@enum::E1::@getter::v1
              enclosingElement: <testLibraryFragment>::@enum::E1
              returnType: E1
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::E1::@getter::values
              enclosingElement: <testLibraryFragment>::@enum::E1
              returnType: List<E1>
        enum E2 @20
          reference: <testLibraryFragment>::@enum::E2
          enclosingElement: <testLibraryFragment>
          supertype: Enum
          fields
            static const enumConstant v2 @25
              reference: <testLibraryFragment>::@enum::E2::@field::v2
              enclosingElement: <testLibraryFragment>::@enum::E2
              type: E2
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E2 @-1
                      element: <testLibraryFragment>::@enum::E2
                      type: E2
                    staticElement: <testLibraryFragment>::@enum::E2::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E2
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::E2::@field::values
              enclosingElement: <testLibraryFragment>::@enum::E2
              type: List<E2>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v2 @-1
                      staticElement: <testLibraryFragment>::@enum::E2::@getter::v2
                      staticType: E2
                  rightBracket: ] @0
                  staticType: List<E2>
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::E2::@constructor::new
              enclosingElement: <testLibraryFragment>::@enum::E2
          accessors
            synthetic static get v2 @-1
              reference: <testLibraryFragment>::@enum::E2::@getter::v2
              enclosingElement: <testLibraryFragment>::@enum::E2
              returnType: E2
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::E2::@getter::values
              enclosingElement: <testLibraryFragment>::@enum::E2
              returnType: List<E2>
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      classes
        class M @24
          reference: <testLibraryFragment>::@class::M
          enclosingElement: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::M::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::M
        class A @36
          reference: <testLibraryFragment>::@class::A
          enclosingElement: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::A
          methods
            foo @52
              reference: <testLibraryFragment>::@class::A::@method::foo
              enclosingElement: <testLibraryFragment>::@class::A
              returnType: dynamic
        class B @70
          reference: <testLibraryFragment>::@class::B
          enclosingElement: <testLibraryFragment>
          interfaces
            M
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::B::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::B
          methods
            foo @92
              reference: <testLibraryFragment>::@class::B::@method::foo
              enclosingElement: <testLibraryFragment>::@class::B
              returnType: dynamic
        class C @110
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          supertype: Object
          mixins
            M
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
          methods
            foo @141
              reference: <testLibraryFragment>::@class::C::@method::foo
              enclosingElement: <testLibraryFragment>::@class::C
              returnType: dynamic
        class alias D @159
          reference: <testLibraryFragment>::@class::D
          enclosingElement: <testLibraryFragment>
          supertype: Object
          mixins
            M
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@class::D::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::D
              constantInitializers
                SuperConstructorInvocation
                  superKeyword: super @0
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticElement: dart:core::<fragment>::@class::Object::@constructor::new
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          enclosingElement: <testLibraryFragment>
          supertype: Enum
          fields
            static const enumConstant a @8
              reference: <testLibraryFragment>::@enum::E::@field::a
              enclosingElement: <testLibraryFragment>::@enum::E
              type: E
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E
                      type: E
                    staticElement: <testLibraryFragment>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            static const enumConstant b @11
              reference: <testLibraryFragment>::@enum::E::@field::b
              enclosingElement: <testLibraryFragment>::@enum::E
              type: E
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E
                      type: E
                    staticElement: <testLibraryFragment>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            static const enumConstant c @14
              reference: <testLibraryFragment>::@enum::E::@field::c
              enclosingElement: <testLibraryFragment>::@enum::E
              type: E
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E
                      type: E
                    staticElement: <testLibraryFragment>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              enclosingElement: <testLibraryFragment>::@enum::E
              type: List<E>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: a @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::a
                      staticType: E
                    SimpleIdentifier
                      token: b @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::b
                      staticType: E
                    SimpleIdentifier
                      token: c @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::c
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              enclosingElement: <testLibraryFragment>::@enum::E
          accessors
            synthetic static get a @-1
              reference: <testLibraryFragment>::@enum::E::@getter::a
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: E
            synthetic static get b @-1
              reference: <testLibraryFragment>::@enum::E::@getter::b
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: E
            synthetic static get c @-1
              reference: <testLibraryFragment>::@enum::E::@getter::c
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: E
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: List<E>
''');
  }

  test_metadata_enum_constant() async {
    var library = await buildLibrary('const a = 42; enum E { @a v }');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      enums
        enum E @19
          reference: <testLibraryFragment>::@enum::E
          enclosingElement: <testLibraryFragment>
          supertype: Enum
          fields
            static const enumConstant v @26
              reference: <testLibraryFragment>::@enum::E::@field::v
              enclosingElement: <testLibraryFragment>::@enum::E
              metadata
                Annotation
                  atSign: @ @23
                  name: SimpleIdentifier
                    token: a @24
                    staticElement: <testLibraryFragment>::@getter::a
                    staticType: null
                  element: <testLibraryFragment>::@getter::a
              type: E
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E
                      type: E
                    staticElement: <testLibraryFragment>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              enclosingElement: <testLibraryFragment>::@enum::E
              type: List<E>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::v
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              enclosingElement: <testLibraryFragment>::@enum::E
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: E
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: List<E>
      topLevelVariables
        static const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            IntegerLiteral
              literal: 42 @10
              staticType: int
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement: <testLibraryFragment>
          returnType: int
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          enclosingElement: <testLibraryFragment>
          fields
            final value @26
              reference: <testLibraryFragment>::@class::A::@field::value
              enclosingElement: <testLibraryFragment>::@class::A
              type: dynamic
          constructors
            const @41
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::A
              parameters
                requiredPositional final this.value @48
                  type: dynamic
                  field: <testLibraryFragment>::@class::A::@field::value
          accessors
            synthetic get value @-1
              reference: <testLibraryFragment>::@class::A::@getter::value
              enclosingElement: <testLibraryFragment>::@class::A
              returnType: dynamic
      enums
        enum E @64
          reference: <testLibraryFragment>::@enum::E
          enclosingElement: <testLibraryFragment>
          supertype: Enum
          fields
            static const enumConstant a @78
              reference: <testLibraryFragment>::@enum::E::@field::a
              enclosingElement: <testLibraryFragment>::@enum::E
              metadata
                Annotation
                  atSign: @ @70
                  name: SimpleIdentifier
                    token: A @71
                    staticElement: <testLibraryFragment>::@class::A
                    staticType: null
                  arguments: ArgumentList
                    leftParenthesis: ( @72
                    arguments
                      IntegerLiteral
                        literal: 100 @73
                        staticType: int
                    rightParenthesis: ) @76
                  element: <testLibraryFragment>::@class::A::@constructor::new
              type: E
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E
                      type: E
                    staticElement: <testLibraryFragment>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            static const enumConstant b @83
              reference: <testLibraryFragment>::@enum::E::@field::b
              enclosingElement: <testLibraryFragment>::@enum::E
              type: E
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E
                      type: E
                    staticElement: <testLibraryFragment>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            static const enumConstant c @96
              reference: <testLibraryFragment>::@enum::E::@field::c
              enclosingElement: <testLibraryFragment>::@enum::E
              metadata
                Annotation
                  atSign: @ @88
                  name: SimpleIdentifier
                    token: A @89
                    staticElement: <testLibraryFragment>::@class::A
                    staticType: null
                  arguments: ArgumentList
                    leftParenthesis: ( @90
                    arguments
                      IntegerLiteral
                        literal: 300 @91
                        staticType: int
                    rightParenthesis: ) @94
                  element: <testLibraryFragment>::@class::A::@constructor::new
              type: E
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E
                      type: E
                    staticElement: <testLibraryFragment>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              enclosingElement: <testLibraryFragment>::@enum::E
              type: List<E>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: a @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::a
                      staticType: E
                    SimpleIdentifier
                      token: b @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::b
                      staticType: E
                    SimpleIdentifier
                      token: c @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::c
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              enclosingElement: <testLibraryFragment>::@enum::E
          accessors
            synthetic static get a @-1
              reference: <testLibraryFragment>::@enum::E::@getter::a
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: E
            synthetic static get b @-1
              reference: <testLibraryFragment>::@enum::E::@getter::b
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: E
            synthetic static get c @-1
              reference: <testLibraryFragment>::@enum::E::@getter::c
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: E
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: List<E>
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          enclosingElement: <testLibraryFragment>
          supertype: Enum
          fields
            static const enumConstant v @16
              reference: <testLibraryFragment>::@enum::E::@field::v
              enclosingElement: <testLibraryFragment>::@enum::E
              metadata
                Annotation
                  atSign: @ @11
                  name: SimpleIdentifier
                    token: v @12
                    staticElement: <testLibraryFragment>::@enum::E::@getter::v
                    staticType: null
                  element: <testLibraryFragment>::@enum::E::@getter::v
              type: E
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E
                      type: E
                    staticElement: <testLibraryFragment>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              enclosingElement: <testLibraryFragment>::@enum::E
              type: List<E>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::v
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              enclosingElement: <testLibraryFragment>::@enum::E
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: E
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: List<E>
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      enums
        enum E @19
          reference: <testLibraryFragment>::@enum::E
          enclosingElement: <testLibraryFragment>
          supertype: Enum
          fields
            static const enumConstant v @25
              reference: <testLibraryFragment>::@enum::E::@field::v
              enclosingElement: <testLibraryFragment>::@enum::E
              type: E
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E
                      type: E
                    staticElement: <testLibraryFragment>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              enclosingElement: <testLibraryFragment>::@enum::E
              type: List<E>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::v
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
          constructors
            const @41
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              enclosingElement: <testLibraryFragment>::@enum::E
              metadata
                Annotation
                  atSign: @ @30
                  name: SimpleIdentifier
                    token: a @31
                    staticElement: <testLibraryFragment>::@getter::a
                    staticType: null
                  element: <testLibraryFragment>::@getter::a
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: E
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: List<E>
      topLevelVariables
        static const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            IntegerLiteral
              literal: 42 @10
              staticType: int
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement: <testLibraryFragment>
          returnType: int
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      enums
        enum E @19
          reference: <testLibraryFragment>::@enum::E
          enclosingElement: <testLibraryFragment>
          supertype: Enum
          fields
            static const enumConstant v @25
              reference: <testLibraryFragment>::@enum::E::@field::v
              enclosingElement: <testLibraryFragment>::@enum::E
              type: E
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E
                      type: E
                    staticElement: <testLibraryFragment>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              enclosingElement: <testLibraryFragment>::@enum::E
              type: List<E>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::v
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              enclosingElement: <testLibraryFragment>::@enum::E
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: E
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: List<E>
          methods
            foo @40
              reference: <testLibraryFragment>::@enum::E::@method::foo
              enclosingElement: <testLibraryFragment>::@enum::E
              metadata
                Annotation
                  atSign: @ @30
                  name: SimpleIdentifier
                    token: a @31
                    staticElement: <testLibraryFragment>::@getter::a
                    staticType: null
                  element: <testLibraryFragment>::@getter::a
              returnType: void
      topLevelVariables
        static const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            IntegerLiteral
              literal: 42 @10
              staticType: int
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement: <testLibraryFragment>
          returnType: int
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      enums
        enum E @26
          reference: <testLibraryFragment>::@enum::E
          enclosingElement: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @16
              name: SimpleIdentifier
                token: foo @17
                staticElement: <testLibraryFragment>::@getter::foo
                staticType: null
              element: <testLibraryFragment>::@getter::foo
          typeParameters
            covariant T @33
              defaultType: dynamic
              metadata
                Annotation
                  atSign: @ @28
                  name: SimpleIdentifier
                    token: foo @29
                    staticElement: <testLibraryFragment>::@getter::foo
                    staticType: null
                  element: <testLibraryFragment>::@getter::foo
          supertype: Enum
          fields
            static const enumConstant v @40
              reference: <testLibraryFragment>::@enum::E::@field::v
              enclosingElement: <testLibraryFragment>::@enum::E
              type: E<dynamic>
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E
                      type: E<dynamic>
                    staticElement: ConstructorMember
                      base: <testLibraryFragment>::@enum::E::@constructor::new
                      substitution: {T: dynamic}
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E<dynamic>
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              enclosingElement: <testLibraryFragment>::@enum::E
              type: List<E<dynamic>>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::v
                      staticType: E<dynamic>
                  rightBracket: ] @0
                  staticType: List<E<dynamic>>
            static const foo @58
              reference: <testLibraryFragment>::@enum::E::@field::foo
              enclosingElement: <testLibraryFragment>::@enum::E
              type: int
              shouldUseTypeForInitializerInference: false
              constantInitializer
                IntegerLiteral
                  literal: 1 @64
                  staticType: int
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              enclosingElement: <testLibraryFragment>::@enum::E
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: E<dynamic>
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: List<E<dynamic>>
            synthetic static get foo @-1
              reference: <testLibraryFragment>::@enum::E::@getter::foo
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: int
          methods
            bar @81
              reference: <testLibraryFragment>::@enum::E::@method::bar
              enclosingElement: <testLibraryFragment>::@enum::E
              metadata
                Annotation
                  atSign: @ @69
                  name: SimpleIdentifier
                    token: foo @70
                    staticElement: <testLibraryFragment>::@enum::E::@getter::foo
                    staticType: null
                  element: <testLibraryFragment>::@enum::E::@getter::foo
              returnType: void
      topLevelVariables
        static const foo @6
          reference: <testLibraryFragment>::@topLevelVariable::foo
          enclosingElement: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            IntegerLiteral
              literal: 0 @12
              staticType: int
      accessors
        synthetic static get foo @-1
          reference: <testLibraryFragment>::@getter::foo
          enclosingElement: <testLibraryFragment>
          returnType: int
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      enums
        enum E @19
          reference: <testLibraryFragment>::@enum::E
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T @24
              defaultType: dynamic
              metadata
                Annotation
                  atSign: @ @21
                  name: SimpleIdentifier
                    token: a @22
                    staticElement: <testLibraryFragment>::@getter::a
                    staticType: null
                  element: <testLibraryFragment>::@getter::a
          supertype: Enum
          fields
            static const enumConstant v @31
              reference: <testLibraryFragment>::@enum::E::@field::v
              enclosingElement: <testLibraryFragment>::@enum::E
              type: E<dynamic>
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E
                      type: E<dynamic>
                    staticElement: ConstructorMember
                      base: <testLibraryFragment>::@enum::E::@constructor::new
                      substitution: {T: dynamic}
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E<dynamic>
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              enclosingElement: <testLibraryFragment>::@enum::E
              type: List<E<dynamic>>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::v
                      staticType: E<dynamic>
                  rightBracket: ] @0
                  staticType: List<E<dynamic>>
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              enclosingElement: <testLibraryFragment>::@enum::E
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: E<dynamic>
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: List<E<dynamic>>
      topLevelVariables
        static const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            IntegerLiteral
              literal: 42 @10
              staticType: int
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement: <testLibraryFragment>
          returnType: int
''');
  }

  test_metadata_enumDeclaration() async {
    var library = await buildLibrary('const a = 42; @a enum E { v }');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      enums
        enum E @22
          reference: <testLibraryFragment>::@enum::E
          enclosingElement: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @14
              name: SimpleIdentifier
                token: a @15
                staticElement: <testLibraryFragment>::@getter::a
                staticType: null
              element: <testLibraryFragment>::@getter::a
          supertype: Enum
          fields
            static const enumConstant v @26
              reference: <testLibraryFragment>::@enum::E::@field::v
              enclosingElement: <testLibraryFragment>::@enum::E
              type: E
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E
                      type: E
                    staticElement: <testLibraryFragment>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              enclosingElement: <testLibraryFragment>::@enum::E
              type: List<E>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::v
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              enclosingElement: <testLibraryFragment>::@enum::E
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: E
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              enclosingElement: <testLibraryFragment>::@enum::E
              returnType: List<E>
      topLevelVariables
        static const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            IntegerLiteral
              literal: 42 @10
              staticType: int
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement: <testLibraryFragment>
          returnType: int
''');
  }
}

abstract class EnumElementTest_augmentation extends ElementsBaseTest {
  test_add_augment() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';

enum A {
  v;
  void foo() {}
}

augment enum A {;
  void bar() {}
}
''');

    var library = await buildLibrary(r'''
import augment 'a.dart';
''');

    configuration.withConstantInitializers = false;
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
      enums
        enum A @35
          reference: <testLibrary>::@fragment::package:test/a.dart::@enum::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @41
              reference: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@field::v
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enum::A
              type: A
              shouldUseTypeForInitializerInference: false
            synthetic static const values @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@field::values
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enum::A
              type: List<A>
          constructors
            synthetic const @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@constructor::new
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enum::A
          accessors
            synthetic static get v @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@getter::v
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enum::A
              returnType: A
            synthetic static get values @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@getter::values
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enum::A
              returnType: List<A>
          methods
            foo @51
              reference: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@method::foo
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enum::A
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
        augment enum A @76
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@enum::A
          methods
            bar @88
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@method::bar
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              returnType: void
''');
  }

  test_augmentationTarget() async {
    newFile('$testPackageLibPath/a1.dart', r'''
augment library 'test.dart';
import augment 'a11.dart';
import augment 'a12.dart';
augment enum A {}
''');

    newFile('$testPackageLibPath/a11.dart', r'''
augment library 'a1.dart';
augment enum A {}
''');

    newFile('$testPackageLibPath/a12.dart', r'''
augment library 'a1.dart';
augment enum A {}
''');

    newFile('$testPackageLibPath/a2.dart', r'''
augment library 'test.dart';
import augment 'a21.dart';
import augment 'a22.dart';
augment enum A {}
''');

    newFile('$testPackageLibPath/a21.dart', r'''
augment library 'a2.dart';
augment enum A {}
''');

    newFile('$testPackageLibPath/a22.dart', r'''
augment library 'a2.dart';
augment enum A {}
''');

    var library = await buildLibrary(r'''
import augment 'a1.dart';
import augment 'a2.dart';
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
  augmentationImports
    package:test/a1.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/a1.dart
      definingUnit: <testLibrary>::@fragment::package:test/a1.dart
      augmentationImports
        package:test/a11.dart
          enclosingElement: <testLibrary>::@augmentation::package:test/a1.dart
          reference: <testLibrary>::@augmentation::package:test/a11.dart
          definingUnit: <testLibrary>::@fragment::package:test/a11.dart
        package:test/a12.dart
          enclosingElement: <testLibrary>::@augmentation::package:test/a1.dart
          reference: <testLibrary>::@augmentation::package:test/a12.dart
          definingUnit: <testLibrary>::@fragment::package:test/a12.dart
    package:test/a2.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/a2.dart
      definingUnit: <testLibrary>::@fragment::package:test/a2.dart
      augmentationImports
        package:test/a21.dart
          enclosingElement: <testLibrary>::@augmentation::package:test/a2.dart
          reference: <testLibrary>::@augmentation::package:test/a21.dart
          definingUnit: <testLibrary>::@fragment::package:test/a21.dart
        package:test/a22.dart
          enclosingElement: <testLibrary>::@augmentation::package:test/a2.dart
          reference: <testLibrary>::@augmentation::package:test/a22.dart
          definingUnit: <testLibrary>::@fragment::package:test/a22.dart
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      enums
        enum A @57
          reference: <testLibraryFragment>::@enum::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a1.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @63
              reference: <testLibraryFragment>::@enum::A::@field::v
              enclosingElement: <testLibraryFragment>::@enum::A
              type: A
              shouldUseTypeForInitializerInference: false
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              enclosingElement: <testLibraryFragment>::@enum::A
              type: List<A>
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@enum::A
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              enclosingElement: <testLibraryFragment>::@enum::A
              returnType: A
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              enclosingElement: <testLibraryFragment>::@enum::A
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
      enclosingElement: <testLibrary>::@augmentation::package:test/a1.dart
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @96
          reference: <testLibrary>::@fragment::package:test/a1.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a1.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          augmentation: <testLibrary>::@fragment::package:test/a11.dart::@enumAugmentation::A
    <testLibrary>::@fragment::package:test/a11.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/a11.dart
      enclosingElement3: <testLibrary>::@fragment::package:test/a1.dart
      enums
        augment enum A @40
          reference: <testLibrary>::@fragment::package:test/a11.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a11.dart
          augmentationTarget: <testLibrary>::@fragment::package:test/a1.dart::@enumAugmentation::A
          augmentation: <testLibrary>::@fragment::package:test/a12.dart::@enumAugmentation::A
    <testLibrary>::@fragment::package:test/a12.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/a12.dart
      enclosingElement3: <testLibrary>::@fragment::package:test/a1.dart
      enums
        augment enum A @40
          reference: <testLibrary>::@fragment::package:test/a12.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a12.dart
          augmentationTarget: <testLibrary>::@fragment::package:test/a11.dart::@enumAugmentation::A
          augmentation: <testLibrary>::@fragment::package:test/a2.dart::@enumAugmentation::A
    <testLibrary>::@fragment::package:test/a2.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/a2.dart
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @96
          reference: <testLibrary>::@fragment::package:test/a2.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a2.dart
          augmentationTarget: <testLibrary>::@fragment::package:test/a12.dart::@enumAugmentation::A
          augmentation: <testLibrary>::@fragment::package:test/a21.dart::@enumAugmentation::A
    <testLibrary>::@fragment::package:test/a21.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/a21.dart
      enclosingElement3: <testLibrary>::@fragment::package:test/a2.dart
      enums
        augment enum A @40
          reference: <testLibrary>::@fragment::package:test/a21.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a21.dart
          augmentationTarget: <testLibrary>::@fragment::package:test/a2.dart::@enumAugmentation::A
          augmentation: <testLibrary>::@fragment::package:test/a22.dart::@enumAugmentation::A
    <testLibrary>::@fragment::package:test/a22.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/a22.dart
      enclosingElement3: <testLibrary>::@fragment::package:test/a2.dart
      enums
        augment enum A @40
          reference: <testLibrary>::@fragment::package:test/a22.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a22.dart
          augmentationTarget: <testLibrary>::@fragment::package:test/a21.dart::@enumAugmentation::A
  exportedReferences
    declared <testLibraryFragment>::@enum::A
  exportNamespace
    A: <testLibraryFragment>::@enum::A
''');
  }

  test_augmentationTarget_augmentationThenDeclaration() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';

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
import augment 'a.dart';
''');

    configuration.withConstantInitializers = false;
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
      enums
        augment enum A @43
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::0
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          fields
            synthetic static const values @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::0::@field::values
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::0
              type: List<A>
          constructors
            synthetic const @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::0::@constructor::new
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::0
          accessors
            synthetic static get values @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::0::@getter::values
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::0
              returnType: List<A>
          methods
            foo1 @55
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::0::@method::foo1
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::0
              returnType: void
        enum A @73
          reference: <testLibrary>::@fragment::package:test/a.dart::@enum::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::1
          supertype: Enum
          fields
            static const enumConstant v @79
              reference: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@field::v
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enum::A
              type: A
              shouldUseTypeForInitializerInference: false
            synthetic static const values @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@field::values
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enum::A
              type: List<A>
          constructors
            synthetic const @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@constructor::new
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enum::A
          accessors
            synthetic static get v @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@getter::v
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enum::A
              returnType: A
            synthetic static get values @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@getter::values
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enum::A
              returnType: List<A>
          methods
            foo2 @89
              reference: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@method::foo2
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enum::A
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
        augment enum A @115
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::1
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@enum::A
          methods
            foo3 @127
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::1::@method::foo3
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::1
              returnType: void
''');
  }

  test_augmentationTarget_no2() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
import augment 'b.dart';
augment enum A {;
  void foo1() {}
}
''');

    newFile('$testPackageLibPath/b.dart', r'''
augment library 'a.dart';
augment enum A {;
  void foo2() {}
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
      augmentationImports
        package:test/b.dart
          enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
          reference: <testLibrary>::@augmentation::package:test/b.dart
          definingUnit: <testLibrary>::@fragment::package:test/b.dart
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @67
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentation: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          fields
            synthetic static const values @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::values
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              type: List<A>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  rightBracket: ] @0
                  staticType: List<A>
          constructors
            synthetic const @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructor::new
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          accessors
            synthetic static get values @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::values
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              returnType: List<A>
          methods
            foo1 @79
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@method::foo1
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
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
      enclosingElement: <testLibrary>::@augmentation::package:test/b.dart
      enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
      enums
        augment enum A @39
          reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/b.dart
          augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          methods
            foo2 @51
              reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@method::foo2
              enclosingElement: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
              returnType: void
''');
  }

  test_augmented_constants_add() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
augment enum A {
  v2
}
''');

    var library = await buildLibrary(r'''
import augment 'a.dart';
enum A {
  v1
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
      enums
        enum A @30
          reference: <testLibraryFragment>::@enum::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v1 @36
              reference: <testLibraryFragment>::@enum::A::@field::v1
              enclosingElement: <testLibraryFragment>::@enum::A
              type: A
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibraryFragment>::@enum::A
                      type: A
                    staticElement: <testLibraryFragment>::@enum::A::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              id: field_0
              getter: getter_0
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              enclosingElement: <testLibraryFragment>::@enum::A
              type: List<A>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v1 @-1
                      staticElement: <testLibraryFragment>::@enum::A::@getter::v1
                      staticType: A
                    SimpleIdentifier
                      token: v2 @-1
                      staticElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::v2
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
              id: field_1
              getter: getter_1
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@enum::A
          accessors
            synthetic static get v1 @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v1
              enclosingElement: <testLibraryFragment>::@enum::A
              returnType: A
              id: getter_0
              variable: field_0
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              enclosingElement: <testLibraryFragment>::@enum::A
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
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @42
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          fields
            static const enumConstant v2 @48
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::v2
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              type: A
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibraryFragment>::@enum::A
                      type: A
                    staticElement: <testLibraryFragment>::@enum::A::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              id: field_2
              getter: getter_2
          accessors
            synthetic static get v2 @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::v2
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              returnType: A
              id: getter_2
              variable: field_2
''');
  }

  test_augmented_constants_add2() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
augment enum A {
  v2
}
''');

    newFile('$testPackageLibPath/b.dart', r'''
augment library 'test.dart';
augment enum A {
  v3
}
''');

    var library = await buildLibrary(r'''
import augment 'a.dart';
import augment 'b.dart';
enum A {
  v1
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
      enums
        enum A @55
          reference: <testLibraryFragment>::@enum::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v1 @61
              reference: <testLibraryFragment>::@enum::A::@field::v1
              enclosingElement: <testLibraryFragment>::@enum::A
              type: A
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibraryFragment>::@enum::A
                      type: A
                    staticElement: <testLibraryFragment>::@enum::A::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              id: field_0
              getter: getter_0
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              enclosingElement: <testLibraryFragment>::@enum::A
              type: List<A>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v1 @-1
                      staticElement: <testLibraryFragment>::@enum::A::@getter::v1
                      staticType: A
                    SimpleIdentifier
                      token: v2 @-1
                      staticElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::v2
                      staticType: A
                    SimpleIdentifier
                      token: v3 @-1
                      staticElement: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@getter::v3
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
              id: field_1
              getter: getter_1
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@enum::A
          accessors
            synthetic static get v1 @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v1
              enclosingElement: <testLibraryFragment>::@enum::A
              returnType: A
              id: getter_0
              variable: field_0
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              enclosingElement: <testLibraryFragment>::@enum::A
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
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @42
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          augmentation: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          fields
            static const enumConstant v2 @48
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::v2
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              type: A
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibraryFragment>::@enum::A
                      type: A
                    staticElement: <testLibraryFragment>::@enum::A::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              id: field_2
              getter: getter_2
          accessors
            synthetic static get v2 @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::v2
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              returnType: A
              id: getter_2
              variable: field_2
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/b.dart
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @42
          reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/b.dart
          augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            static const enumConstant v3 @48
              reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@field::v3
              enclosingElement: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
              type: A
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibraryFragment>::@enum::A
                      type: A
                    staticElement: <testLibraryFragment>::@enum::A::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              id: field_3
              getter: getter_3
          accessors
            synthetic static get v3 @-1
              reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@getter::v3
              enclosingElement: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
              returnType: A
              id: getter_3
              variable: field_3
''');
  }

  test_augmented_constants_add_augment() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
augment enum A {
  v2,
  augment v2
}
''');

    var library = await buildLibrary(r'''
import augment 'a.dart';
enum A {
  v1
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
      enums
        enum A @30
          reference: <testLibraryFragment>::@enum::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v1 @36
              reference: <testLibraryFragment>::@enum::A::@field::v1
              enclosingElement: <testLibraryFragment>::@enum::A
              type: A
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibraryFragment>::@enum::A
                      type: A
                    staticElement: <testLibraryFragment>::@enum::A::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              id: field_0
              getter: getter_0
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              enclosingElement: <testLibraryFragment>::@enum::A
              type: List<A>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v1 @-1
                      staticElement: <testLibraryFragment>::@enum::A::@getter::v1
                      staticType: A
                    SimpleIdentifier
                      token: v2 @-1
                      staticElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::v2
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
              id: field_1
              getter: getter_1
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@enum::A
          accessors
            synthetic static get v1 @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v1
              enclosingElement: <testLibraryFragment>::@enum::A
              returnType: A
              id: getter_0
              variable: field_0
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              enclosingElement: <testLibraryFragment>::@enum::A
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
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @42
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          fields
            static const enumConstant v2 @48
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::v2
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              type: A
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibraryFragment>::@enum::A
                      type: A
                    staticElement: <testLibraryFragment>::@enum::A::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              id: field_2
              getter: getter_2
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@fieldAugmentation::v2
            augment static const enumConstant v2 @62
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@fieldAugmentation::v2
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              type: A
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibraryFragment>::@enum::A
                      type: A
                    staticElement: <testLibraryFragment>::@enum::A::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              id: field_3
              augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::v2
          accessors
            synthetic static get v2 @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::v2
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              returnType: A
              id: getter_2
              variable: field_2
''');
  }

  test_augmented_constants_augment() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
augment enum A {
  augment v2
}
''');

    var library = await buildLibrary(r'''
import augment 'a.dart';
enum A {
  v1, v2, v3
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
      enums
        enum A @30
          reference: <testLibraryFragment>::@enum::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v1 @36
              reference: <testLibraryFragment>::@enum::A::@field::v1
              enclosingElement: <testLibraryFragment>::@enum::A
              type: A
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibraryFragment>::@enum::A
                      type: A
                    staticElement: <testLibraryFragment>::@enum::A::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              id: field_0
              getter: getter_0
            static const enumConstant v2 @40
              reference: <testLibraryFragment>::@enum::A::@field::v2
              enclosingElement: <testLibraryFragment>::@enum::A
              type: A
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibraryFragment>::@enum::A
                      type: A
                    staticElement: <testLibraryFragment>::@enum::A::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              id: field_1
              getter: getter_1
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@fieldAugmentation::v2
            static const enumConstant v3 @44
              reference: <testLibraryFragment>::@enum::A::@field::v3
              enclosingElement: <testLibraryFragment>::@enum::A
              type: A
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibraryFragment>::@enum::A
                      type: A
                    staticElement: <testLibraryFragment>::@enum::A::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              id: field_2
              getter: getter_2
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              enclosingElement: <testLibraryFragment>::@enum::A
              type: List<A>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v1 @-1
                      staticElement: <testLibraryFragment>::@enum::A::@getter::v1
                      staticType: A
                    SimpleIdentifier
                      token: v2 @-1
                      staticElement: <testLibraryFragment>::@enum::A::@getter::v2
                      staticType: A
                    SimpleIdentifier
                      token: v3 @-1
                      staticElement: <testLibraryFragment>::@enum::A::@getter::v3
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
              id: field_3
              getter: getter_3
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@enum::A
          accessors
            synthetic static get v1 @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v1
              enclosingElement: <testLibraryFragment>::@enum::A
              returnType: A
              id: getter_0
              variable: field_0
            synthetic static get v2 @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v2
              enclosingElement: <testLibraryFragment>::@enum::A
              returnType: A
              id: getter_1
              variable: field_1
            synthetic static get v3 @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v3
              enclosingElement: <testLibraryFragment>::@enum::A
              returnType: A
              id: getter_2
              variable: field_2
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              enclosingElement: <testLibraryFragment>::@enum::A
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
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @42
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          fields
            augment static const enumConstant v2 @56
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@fieldAugmentation::v2
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              type: A
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibraryFragment>::@enum::A
                      type: A
                    staticElement: <testLibraryFragment>::@enum::A::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
              id: field_4
              augmentationTarget: <testLibraryFragment>::@enum::A::@field::v2
''');
  }

  test_augmented_constants_augment_withArguments() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
augment enum A {
  augment v1(3)
}
''');

    var library = await buildLibrary(r'''
import augment 'a.dart';
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
  augmentationImports
    package:test/a.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/a.dart
      definingUnit: <testLibrary>::@fragment::package:test/a.dart
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      enums
        enum A @30
          reference: <testLibraryFragment>::@enum::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v1 @36
              reference: <testLibraryFragment>::@enum::A::@field::v1
              enclosingElement: <testLibraryFragment>::@enum::A
              type: A
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibraryFragment>::@enum::A
                      type: A
                    staticElement: <testLibraryFragment>::@enum::A::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    arguments
                      IntegerLiteral
                        literal: 1 @39
                        staticType: int
                    rightParenthesis: ) @0
                  staticType: A
              id: field_0
              getter: getter_0
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@fieldAugmentation::v1
            static const enumConstant v2 @43
              reference: <testLibraryFragment>::@enum::A::@field::v2
              enclosingElement: <testLibraryFragment>::@enum::A
              type: A
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibraryFragment>::@enum::A
                      type: A
                    staticElement: <testLibraryFragment>::@enum::A::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    arguments
                      IntegerLiteral
                        literal: 2 @46
                        staticType: int
                    rightParenthesis: ) @0
                  staticType: A
              id: field_1
              getter: getter_1
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              enclosingElement: <testLibraryFragment>::@enum::A
              type: List<A>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v1 @-1
                      staticElement: <testLibraryFragment>::@enum::A::@getter::v1
                      staticType: A
                    SimpleIdentifier
                      token: v2 @-1
                      staticElement: <testLibraryFragment>::@enum::A::@getter::v2
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
              id: field_2
              getter: getter_2
          constructors
            const @58
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@enum::A
              parameters
                requiredPositional value @64
                  type: int
          accessors
            synthetic static get v1 @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v1
              enclosingElement: <testLibraryFragment>::@enum::A
              returnType: A
              id: getter_0
              variable: field_0
            synthetic static get v2 @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v2
              enclosingElement: <testLibraryFragment>::@enum::A
              returnType: A
              id: getter_1
              variable: field_1
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              enclosingElement: <testLibraryFragment>::@enum::A
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
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @42
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          fields
            augment static const enumConstant v1 @56
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@fieldAugmentation::v1
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              type: A
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibraryFragment>::@enum::A
                      type: A
                    staticElement: <testLibraryFragment>::@enum::A::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    arguments
                      IntegerLiteral
                        literal: 3 @59
                        staticType: int
                    rightParenthesis: ) @0
                  staticType: A
              id: field_3
              augmentationTarget: <testLibraryFragment>::@enum::A::@field::v1
''');
  }

  test_augmented_constants_typeParameterCountMismatch() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
augment enum A<T> {
  augment v
}
''');

    var library = await buildLibrary(r'''
import augment 'a.dart';
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
  augmentationImports
    package:test/a.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/a.dart
      definingUnit: <testLibrary>::@fragment::package:test/a.dart
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      enums
        enum A @30
          reference: <testLibraryFragment>::@enum::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @36
              reference: <testLibraryFragment>::@enum::A::@field::v
              enclosingElement: <testLibraryFragment>::@enum::A
              type: A
              shouldUseTypeForInitializerInference: false
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@fieldAugmentation::v
            static const enumConstant v2 @39
              reference: <testLibraryFragment>::@enum::A::@field::v2
              enclosingElement: <testLibraryFragment>::@enum::A
              type: A
              shouldUseTypeForInitializerInference: false
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              enclosingElement: <testLibraryFragment>::@enum::A
              type: List<A>
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              enclosingElement: <testLibraryFragment>::@enum::A
              returnType: A
            synthetic static get v2 @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v2
              enclosingElement: <testLibraryFragment>::@enum::A
              returnType: A
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              enclosingElement: <testLibraryFragment>::@enum::A
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
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @42
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          typeParameters
            covariant T @44
              defaultType: dynamic
          augmentationTarget: <testLibraryFragment>::@enum::A
          fields
            augment static const enumConstant v @59
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@fieldAugmentation::v
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              type: A
              shouldUseTypeForInitializerInference: false
              augmentationTarget: <testLibraryFragment>::@enum::A::@field::v
''');
  }

  test_augmented_constructors_add_named() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
augment enum A {;
  const A.named();
}
''');

    var library = await buildLibrary(r'''
import augment 'a.dart';
enum A {
  v.named();
}
''');

    configuration.withConstantInitializers = false;
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
      enums
        enum A @30
          reference: <testLibraryFragment>::@enum::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @36
              reference: <testLibraryFragment>::@enum::A::@field::v
              enclosingElement: <testLibraryFragment>::@enum::A
              type: A
              shouldUseTypeForInitializerInference: false
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              enclosingElement: <testLibraryFragment>::@enum::A
              type: List<A>
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              enclosingElement: <testLibraryFragment>::@enum::A
              returnType: A
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              enclosingElement: <testLibraryFragment>::@enum::A
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
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @42
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          constructors
            const named @57
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructor::named
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              periodOffset: 56
              nameEnd: 62
''');
  }

  test_augmented_constructors_add_named_generic() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
augment enum A<T2> {;
  const A.named(T2 a);
}
''');

    var library = await buildLibrary(r'''
import augment 'a.dart';
enum A<T1> {
  v<int>.named()
}
''');

    configuration.withConstantInitializers = false;
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
      enums
        enum A @30
          reference: <testLibraryFragment>::@enum::A
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T1 @32
              defaultType: dynamic
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @40
              reference: <testLibraryFragment>::@enum::A::@field::v
              enclosingElement: <testLibraryFragment>::@enum::A
              type: A<int>
              shouldUseTypeForInitializerInference: false
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              enclosingElement: <testLibraryFragment>::@enum::A
              type: List<A<dynamic>>
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              enclosingElement: <testLibraryFragment>::@enum::A
              returnType: A<int>
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              enclosingElement: <testLibraryFragment>::@enum::A
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
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @42
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          typeParameters
            covariant T2 @44
              defaultType: dynamic
          augmentationTarget: <testLibraryFragment>::@enum::A
          constructors
            const named @61
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructor::named
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              periodOffset: 60
              nameEnd: 66
              parameters
                requiredPositional a @70
                  type: T2
''');
  }

  test_augmented_constructors_add_named_hasUnnamed() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
augment enum A {;
  const A.named();
}
''');

    var library = await buildLibrary(r'''
import augment 'a.dart';
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
  augmentationImports
    package:test/a.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/a.dart
      definingUnit: <testLibrary>::@fragment::package:test/a.dart
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      enums
        enum A @30
          reference: <testLibraryFragment>::@enum::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @36
              reference: <testLibraryFragment>::@enum::A::@field::v
              enclosingElement: <testLibraryFragment>::@enum::A
              type: A
              shouldUseTypeForInitializerInference: false
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              enclosingElement: <testLibraryFragment>::@enum::A
              type: List<A>
          constructors
            const @47
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@enum::A
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              enclosingElement: <testLibraryFragment>::@enum::A
              returnType: A
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              enclosingElement: <testLibraryFragment>::@enum::A
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
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @42
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          constructors
            const named @57
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructor::named
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              periodOffset: 56
              nameEnd: 62
''');
  }

  test_augmented_constructors_add_unnamed() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
augment enum A {;
  const A();
}
''');

    var library = await buildLibrary(r'''
import augment 'a.dart';
enum A {
  v;
}
''');

    configuration.withConstantInitializers = false;
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
      enums
        enum A @30
          reference: <testLibraryFragment>::@enum::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @36
              reference: <testLibraryFragment>::@enum::A::@field::v
              enclosingElement: <testLibraryFragment>::@enum::A
              type: A
              shouldUseTypeForInitializerInference: false
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              enclosingElement: <testLibraryFragment>::@enum::A
              type: List<A>
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              enclosingElement: <testLibraryFragment>::@enum::A
              returnType: A
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              enclosingElement: <testLibraryFragment>::@enum::A
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
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @42
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          constructors
            const @55
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructor::new
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
''');
  }

  test_augmented_constructors_add_unnamed_hasNamed() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
augment enum A {;
  const A();
}
''');

    var library = await buildLibrary(r'''
import augment 'a.dart';
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
  augmentationImports
    package:test/a.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/a.dart
      definingUnit: <testLibrary>::@fragment::package:test/a.dart
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      enums
        enum A @30
          reference: <testLibraryFragment>::@enum::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @36
              reference: <testLibraryFragment>::@enum::A::@field::v
              enclosingElement: <testLibraryFragment>::@enum::A
              type: A
              shouldUseTypeForInitializerInference: false
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              enclosingElement: <testLibraryFragment>::@enum::A
              type: List<A>
          constructors
            const named @49
              reference: <testLibraryFragment>::@enum::A::@constructor::named
              enclosingElement: <testLibraryFragment>::@enum::A
              periodOffset: 48
              nameEnd: 54
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              enclosingElement: <testLibraryFragment>::@enum::A
              returnType: A
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              enclosingElement: <testLibraryFragment>::@enum::A
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
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @42
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          constructors
            const @55
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructor::new
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
''');
  }

  test_augmented_constructors_add_useFieldFormal() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
augment enum A {;
  const A.named(this.f);
}
''');

    var library = await buildLibrary(r'''
import augment 'a.dart';
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
  augmentationImports
    package:test/a.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/a.dart
      definingUnit: <testLibrary>::@fragment::package:test/a.dart
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      enums
        enum A @30
          reference: <testLibraryFragment>::@enum::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @36
              reference: <testLibraryFragment>::@enum::A::@field::v
              enclosingElement: <testLibraryFragment>::@enum::A
              type: A
              shouldUseTypeForInitializerInference: false
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              enclosingElement: <testLibraryFragment>::@enum::A
              type: List<A>
            final f @54
              reference: <testLibraryFragment>::@enum::A::@field::f
              enclosingElement: <testLibraryFragment>::@enum::A
              type: int
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              enclosingElement: <testLibraryFragment>::@enum::A
              returnType: A
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              enclosingElement: <testLibraryFragment>::@enum::A
              returnType: List<A>
            synthetic get f @-1
              reference: <testLibraryFragment>::@enum::A::@getter::f
              enclosingElement: <testLibraryFragment>::@enum::A
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
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @42
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          constructors
            const named @57
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructor::named
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              periodOffset: 56
              nameEnd: 62
              parameters
                requiredPositional final this.f @68
                  type: int
                  field: <testLibraryFragment>::@enum::A::@field::f
''');
  }

  test_augmented_constructors_add_useFieldInitializer() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
augment enum A {;
  const A.named() : f = 0;
}
''');

    var library = await buildLibrary(r'''
import augment 'a.dart';
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
  augmentationImports
    package:test/a.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/a.dart
      definingUnit: <testLibrary>::@fragment::package:test/a.dart
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      enums
        enum A @30
          reference: <testLibraryFragment>::@enum::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @36
              reference: <testLibraryFragment>::@enum::A::@field::v
              enclosingElement: <testLibraryFragment>::@enum::A
              type: A
              shouldUseTypeForInitializerInference: false
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              enclosingElement: <testLibraryFragment>::@enum::A
              type: List<A>
            final f @51
              reference: <testLibraryFragment>::@enum::A::@field::f
              enclosingElement: <testLibraryFragment>::@enum::A
              type: int
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              enclosingElement: <testLibraryFragment>::@enum::A
              returnType: A
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              enclosingElement: <testLibraryFragment>::@enum::A
              returnType: List<A>
            synthetic get f @-1
              reference: <testLibraryFragment>::@enum::A::@getter::f
              enclosingElement: <testLibraryFragment>::@enum::A
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
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @42
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          constructors
            const named @57
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructor::named
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              periodOffset: 56
              nameEnd: 62
              constantInitializers
                ConstructorFieldInitializer
                  fieldName: SimpleIdentifier
                    token: f @67
                    staticElement: <testLibraryFragment>::@enum::A::@field::f
                    staticType: null
                  equals: = @69
                  expression: IntegerLiteral
                    literal: 0 @71
                    staticType: int
''');
  }

  test_augmented_field_augment_field() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
augment enum A {;
  augment final int foo = 1;
}
''');

    var library = await buildLibrary(r'''
import augment 'a.dart';
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
  augmentationImports
    package:test/a.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/a.dart
      definingUnit: <testLibrary>::@fragment::package:test/a.dart
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      enums
        enum A @30
          reference: <testLibraryFragment>::@enum::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @36
              reference: <testLibraryFragment>::@enum::A::@field::v
              enclosingElement: <testLibraryFragment>::@enum::A
              type: A
              shouldUseTypeForInitializerInference: false
              id: field_0
              getter: getter_0
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              enclosingElement: <testLibraryFragment>::@enum::A
              type: List<A>
              id: field_1
              getter: getter_1
            final foo @51
              reference: <testLibraryFragment>::@enum::A::@field::foo
              enclosingElement: <testLibraryFragment>::@enum::A
              type: int
              shouldUseTypeForInitializerInference: true
              id: field_2
              getter: getter_2
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@fieldAugmentation::foo
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@enum::A
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              enclosingElement: <testLibraryFragment>::@enum::A
              returnType: A
              id: getter_0
              variable: field_0
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              enclosingElement: <testLibraryFragment>::@enum::A
              returnType: List<A>
              id: getter_1
              variable: field_1
            synthetic get foo @-1
              reference: <testLibraryFragment>::@enum::A::@getter::foo
              enclosingElement: <testLibraryFragment>::@enum::A
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
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @42
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          fields
            augment final foo @67
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@fieldAugmentation::foo
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              type: int
              shouldUseTypeForInitializerInference: true
              id: field_3
              augmentationTarget: <testLibraryFragment>::@enum::A::@field::foo
''');
  }

  test_augmented_field_augment_field2() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
augment enum A {;
  augment final int foo = 1;
}
''');

    newFile('$testPackageLibPath/b.dart', r'''
augment library 'test.dart';
augment enum A {;
  augment final int foo = 2;
}
''');

    var library = await buildLibrary(r'''
import augment 'a.dart';
import augment 'b.dart';
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
      enums
        enum A @55
          reference: <testLibraryFragment>::@enum::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @61
              reference: <testLibraryFragment>::@enum::A::@field::v
              enclosingElement: <testLibraryFragment>::@enum::A
              type: A
              shouldUseTypeForInitializerInference: false
              id: field_0
              getter: getter_0
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              enclosingElement: <testLibraryFragment>::@enum::A
              type: List<A>
              id: field_1
              getter: getter_1
            final foo @76
              reference: <testLibraryFragment>::@enum::A::@field::foo
              enclosingElement: <testLibraryFragment>::@enum::A
              type: int
              shouldUseTypeForInitializerInference: true
              id: field_2
              getter: getter_2
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@fieldAugmentation::foo
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@enum::A
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              enclosingElement: <testLibraryFragment>::@enum::A
              returnType: A
              id: getter_0
              variable: field_0
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              enclosingElement: <testLibraryFragment>::@enum::A
              returnType: List<A>
              id: getter_1
              variable: field_1
            synthetic get foo @-1
              reference: <testLibraryFragment>::@enum::A::@getter::foo
              enclosingElement: <testLibraryFragment>::@enum::A
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
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @42
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          augmentation: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          fields
            augment final foo @67
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@fieldAugmentation::foo
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              type: int
              shouldUseTypeForInitializerInference: true
              id: field_3
              augmentationTarget: <testLibraryFragment>::@enum::A::@field::foo
              augmentation: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@fieldAugmentation::foo
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/b.dart
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @42
          reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/b.dart
          augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            augment final foo @67
              reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@fieldAugmentation::foo
              enclosingElement: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
              type: int
              shouldUseTypeForInitializerInference: true
              id: field_4
              augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@fieldAugmentation::foo
''');
  }

  test_augmented_field_augment_field_afterGetter() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
augment enum A {;
  augment int get foo => 1;
}
''');

    newFile('$testPackageLibPath/b.dart', r'''
augment library 'test.dart';
augment enum A {;
  augment final int foo = 2;
}
''');

    var library = await buildLibrary(r'''
import augment 'a.dart';
import augment 'b.dart';
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
      enums
        enum A @55
          reference: <testLibraryFragment>::@enum::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @61
              reference: <testLibraryFragment>::@enum::A::@field::v
              enclosingElement: <testLibraryFragment>::@enum::A
              type: A
              shouldUseTypeForInitializerInference: false
              id: field_0
              getter: getter_0
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              enclosingElement: <testLibraryFragment>::@enum::A
              type: List<A>
              id: field_1
              getter: getter_1
            final foo @76
              reference: <testLibraryFragment>::@enum::A::@field::foo
              enclosingElement: <testLibraryFragment>::@enum::A
              type: int
              shouldUseTypeForInitializerInference: true
              id: field_2
              getter: getter_2
              augmentation: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@fieldAugmentation::foo
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@enum::A
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              enclosingElement: <testLibraryFragment>::@enum::A
              returnType: A
              id: getter_0
              variable: field_0
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              enclosingElement: <testLibraryFragment>::@enum::A
              returnType: List<A>
              id: getter_1
              variable: field_1
            synthetic get foo @-1
              reference: <testLibraryFragment>::@enum::A::@getter::foo
              enclosingElement: <testLibraryFragment>::@enum::A
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
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @42
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          augmentation: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          accessors
            augment get foo @65
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getterAugmentation::foo
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              returnType: int
              id: getter_3
              variable: field_2
              augmentationTarget: <testLibraryFragment>::@enum::A::@getter::foo
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/b.dart
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @42
          reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/b.dart
          augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            augment final foo @67
              reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@fieldAugmentation::foo
              enclosingElement: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
              type: int
              shouldUseTypeForInitializerInference: true
              id: field_3
              augmentationTarget: <testLibraryFragment>::@enum::A::@field::foo
''');
  }

  test_augmented_field_augment_field_afterSetter() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
augment enum A {;
  augment set foo(int _) {}
}
''');

    newFile('$testPackageLibPath/b.dart', r'''
augment library 'test.dart';
augment enum A {;
  augment final int foo = 2;
}
''');

    var library = await buildLibrary(r'''
import augment 'a.dart';
import augment 'b.dart';
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
      enums
        enum A @55
          reference: <testLibraryFragment>::@enum::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @61
              reference: <testLibraryFragment>::@enum::A::@field::v
              enclosingElement: <testLibraryFragment>::@enum::A
              type: A
              shouldUseTypeForInitializerInference: false
              id: field_0
              getter: getter_0
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              enclosingElement: <testLibraryFragment>::@enum::A
              type: List<A>
              id: field_1
              getter: getter_1
            final foo @76
              reference: <testLibraryFragment>::@enum::A::@field::foo
              enclosingElement: <testLibraryFragment>::@enum::A
              type: int
              shouldUseTypeForInitializerInference: true
              id: field_2
              getter: getter_2
              augmentation: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@fieldAugmentation::foo
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@enum::A
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              enclosingElement: <testLibraryFragment>::@enum::A
              returnType: A
              id: getter_0
              variable: field_0
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              enclosingElement: <testLibraryFragment>::@enum::A
              returnType: List<A>
              id: getter_1
              variable: field_1
            synthetic get foo @-1
              reference: <testLibraryFragment>::@enum::A::@getter::foo
              enclosingElement: <testLibraryFragment>::@enum::A
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
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @42
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          augmentation: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          accessors
            augment set foo= @61
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@setterAugmentation::foo
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              parameters
                requiredPositional _ @69
                  type: int
              returnType: void
              id: setter_0
              variable: <null>
              augmentationTargetAny: <testLibraryFragment>::@enum::A::@getter::foo
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/b.dart
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @42
          reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/b.dart
          augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            augment final foo @67
              reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@fieldAugmentation::foo
              enclosingElement: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
              type: int
              shouldUseTypeForInitializerInference: true
              id: field_3
              augmentationTarget: <testLibraryFragment>::@enum::A::@field::foo
''');
  }

  test_augmented_field_augment_field_differentTypes() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
augment enum A {;
  augment final double foo = 1.2;
}
''');

    var library = await buildLibrary(r'''
import augment 'a.dart';
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
  augmentationImports
    package:test/a.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/a.dart
      definingUnit: <testLibrary>::@fragment::package:test/a.dart
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      enums
        enum A @30
          reference: <testLibraryFragment>::@enum::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @36
              reference: <testLibraryFragment>::@enum::A::@field::v
              enclosingElement: <testLibraryFragment>::@enum::A
              type: A
              shouldUseTypeForInitializerInference: false
              id: field_0
              getter: getter_0
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              enclosingElement: <testLibraryFragment>::@enum::A
              type: List<A>
              id: field_1
              getter: getter_1
            final foo @51
              reference: <testLibraryFragment>::@enum::A::@field::foo
              enclosingElement: <testLibraryFragment>::@enum::A
              type: int
              shouldUseTypeForInitializerInference: true
              id: field_2
              getter: getter_2
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@fieldAugmentation::foo
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@enum::A
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              enclosingElement: <testLibraryFragment>::@enum::A
              returnType: A
              id: getter_0
              variable: field_0
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              enclosingElement: <testLibraryFragment>::@enum::A
              returnType: List<A>
              id: getter_1
              variable: field_1
            synthetic get foo @-1
              reference: <testLibraryFragment>::@enum::A::@getter::foo
              enclosingElement: <testLibraryFragment>::@enum::A
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
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @42
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          fields
            augment final foo @70
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@fieldAugmentation::foo
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              type: double
              shouldUseTypeForInitializerInference: true
              id: field_3
              augmentationTarget: <testLibraryFragment>::@enum::A::@field::foo
''');
  }

  test_augmented_field_augment_field_functionExpression() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
augment enum A {;
  augment final int Function() foo = () {
    return augmented() + 1;
  };
}
''');

    var library = await buildLibrary(r'''
import augment 'a.dart';
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
  augmentationImports
    package:test/a.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/a.dart
      definingUnit: <testLibrary>::@fragment::package:test/a.dart
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      enums
        enum A @30
          reference: <testLibraryFragment>::@enum::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @36
              reference: <testLibraryFragment>::@enum::A::@field::v
              enclosingElement: <testLibraryFragment>::@enum::A
              type: A
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibraryFragment>::@enum::A
                      type: A
                    staticElement: <testLibraryFragment>::@enum::A::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              enclosingElement: <testLibraryFragment>::@enum::A
              type: List<A>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::A::@getter::v
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
            final foo @62
              reference: <testLibraryFragment>::@enum::A::@field::foo
              enclosingElement: <testLibraryFragment>::@enum::A
              type: int Function()
              shouldUseTypeForInitializerInference: true
              constantInitializer
                SimpleIdentifier
                  token: _notSerializableExpression @-1
                  staticElement: <null>
                  staticType: null
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@fieldAugmentation::foo
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@enum::A
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              enclosingElement: <testLibraryFragment>::@enum::A
              returnType: A
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              enclosingElement: <testLibraryFragment>::@enum::A
              returnType: List<A>
            synthetic get foo @-1
              reference: <testLibraryFragment>::@enum::A::@getter::foo
              enclosingElement: <testLibraryFragment>::@enum::A
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
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @42
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          fields
            augment final foo @78
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@fieldAugmentation::foo
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              type: int Function()
              shouldUseTypeForInitializerInference: true
              constantInitializer
                SimpleIdentifier
                  token: _notSerializableExpression @-1
                  staticElement: <null>
                  staticType: null
              augmentationTarget: <testLibraryFragment>::@enum::A::@field::foo
''');
  }

  /// This is not allowed by the specification, but allowed syntactically,
  /// so we need a way to handle it.
  test_augmented_field_augment_getter() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
augment enum A {;
  augment final int foo = 1;
}
''');

    var library = await buildLibrary(r'''
import augment 'a.dart';
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
  augmentationImports
    package:test/a.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/a.dart
      definingUnit: <testLibrary>::@fragment::package:test/a.dart
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      enums
        enum A @30
          reference: <testLibraryFragment>::@enum::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @36
              reference: <testLibraryFragment>::@enum::A::@field::v
              enclosingElement: <testLibraryFragment>::@enum::A
              type: A
              shouldUseTypeForInitializerInference: false
              id: field_0
              getter: getter_0
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              enclosingElement: <testLibraryFragment>::@enum::A
              type: List<A>
              id: field_1
              getter: getter_1
            synthetic foo @-1
              reference: <testLibraryFragment>::@enum::A::@field::foo
              enclosingElement: <testLibraryFragment>::@enum::A
              type: int
              id: field_2
              getter: getter_2
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@fieldAugmentation::foo
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@enum::A
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              enclosingElement: <testLibraryFragment>::@enum::A
              returnType: A
              id: getter_0
              variable: field_0
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              enclosingElement: <testLibraryFragment>::@enum::A
              returnType: List<A>
              id: getter_1
              variable: field_1
            get foo @49
              reference: <testLibraryFragment>::@enum::A::@getter::foo
              enclosingElement: <testLibraryFragment>::@enum::A
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
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @42
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          fields
            augment final foo @67
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@fieldAugmentation::foo
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              type: int
              shouldUseTypeForInitializerInference: true
              id: field_3
              augmentationTarget: <testLibraryFragment>::@enum::A::@field::foo
''');
  }

  test_augmented_fields_add() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
augment enum A {;
  final int foo2 = 0;
}
''');

    var library = await buildLibrary(r'''
import augment 'a.dart';
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
  augmentationImports
    package:test/a.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/a.dart
      definingUnit: <testLibrary>::@fragment::package:test/a.dart
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      enums
        enum A @30
          reference: <testLibraryFragment>::@enum::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @36
              reference: <testLibraryFragment>::@enum::A::@field::v
              enclosingElement: <testLibraryFragment>::@enum::A
              type: A
              shouldUseTypeForInitializerInference: false
              id: field_0
              getter: getter_0
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              enclosingElement: <testLibraryFragment>::@enum::A
              type: List<A>
              id: field_1
              getter: getter_1
            final foo1 @51
              reference: <testLibraryFragment>::@enum::A::@field::foo1
              enclosingElement: <testLibraryFragment>::@enum::A
              type: int
              shouldUseTypeForInitializerInference: true
              id: field_2
              getter: getter_2
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@enum::A
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              enclosingElement: <testLibraryFragment>::@enum::A
              returnType: A
              id: getter_0
              variable: field_0
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              enclosingElement: <testLibraryFragment>::@enum::A
              returnType: List<A>
              id: getter_1
              variable: field_1
            synthetic get foo1 @-1
              reference: <testLibraryFragment>::@enum::A::@getter::foo1
              enclosingElement: <testLibraryFragment>::@enum::A
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
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @42
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          fields
            final foo2 @59
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::foo2
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              type: int
              shouldUseTypeForInitializerInference: true
              id: field_3
              getter: getter_3
          accessors
            synthetic get foo2 @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::foo2
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              returnType: int
              id: getter_3
              variable: field_3
''');
  }

  test_augmented_fields_add_generic() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
augment enum A<T2> {;
  final T2 foo2;
}
''');

    var library = await buildLibrary(r'''
import augment 'a.dart';
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
  augmentationImports
    package:test/a.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/a.dart
      definingUnit: <testLibrary>::@fragment::package:test/a.dart
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      enums
        enum A @30
          reference: <testLibraryFragment>::@enum::A
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T1 @32
              defaultType: dynamic
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @40
              reference: <testLibraryFragment>::@enum::A::@field::v
              enclosingElement: <testLibraryFragment>::@enum::A
              type: A<int>
              shouldUseTypeForInitializerInference: false
              id: field_0
              getter: getter_0
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              enclosingElement: <testLibraryFragment>::@enum::A
              type: List<A<dynamic>>
              id: field_1
              getter: getter_1
            final foo1 @61
              reference: <testLibraryFragment>::@enum::A::@field::foo1
              enclosingElement: <testLibraryFragment>::@enum::A
              type: T1
              id: field_2
              getter: getter_2
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@enum::A
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              enclosingElement: <testLibraryFragment>::@enum::A
              returnType: A<int>
              id: getter_0
              variable: field_0
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              enclosingElement: <testLibraryFragment>::@enum::A
              returnType: List<A<dynamic>>
              id: getter_1
              variable: field_1
            synthetic get foo1 @-1
              reference: <testLibraryFragment>::@enum::A::@getter::foo1
              enclosingElement: <testLibraryFragment>::@enum::A
              returnType: T1
              id: getter_2
              variable: field_2
          augmented
            fields
              <testLibraryFragment>::@enum::A::@field::foo1
              FieldMember
                base: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::foo2
                augmentationSubstitution: {T2: T1}
              <testLibraryFragment>::@enum::A::@field::v
              <testLibraryFragment>::@enum::A::@field::values
            constants
              <testLibraryFragment>::@enum::A::@field::v
            constructors
              <testLibraryFragment>::@enum::A::@constructor::new
            accessors
              <testLibraryFragment>::@enum::A::@getter::foo1
              PropertyAccessorMember
                base: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::foo2
                augmentationSubstitution: {T2: T1}
              <testLibraryFragment>::@enum::A::@getter::v
              <testLibraryFragment>::@enum::A::@getter::values
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @42
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          typeParameters
            covariant T2 @44
              defaultType: dynamic
          augmentationTarget: <testLibraryFragment>::@enum::A
          fields
            final foo2 @62
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::foo2
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              type: T2
              id: field_3
              getter: getter_3
          accessors
            synthetic get foo2 @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::foo2
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              returnType: T2
              id: getter_3
              variable: field_3
''');
  }

  test_augmented_fields_add_useFieldFormal() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
augment enum A {;
  final int foo;
}
''');

    var library = await buildLibrary(r'''
import augment 'a.dart';
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
  augmentationImports
    package:test/a.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/a.dart
      definingUnit: <testLibrary>::@fragment::package:test/a.dart
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      enums
        enum A @30
          reference: <testLibraryFragment>::@enum::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @36
              reference: <testLibraryFragment>::@enum::A::@field::v
              enclosingElement: <testLibraryFragment>::@enum::A
              type: A
              shouldUseTypeForInitializerInference: false
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              enclosingElement: <testLibraryFragment>::@enum::A
              type: List<A>
          constructors
            const @50
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@enum::A
              parameters
                requiredPositional final this.foo @57
                  type: int
                  field: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::foo
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              enclosingElement: <testLibraryFragment>::@enum::A
              returnType: A
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              enclosingElement: <testLibraryFragment>::@enum::A
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
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @42
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          fields
            final foo @59
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::foo
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              type: int
          accessors
            synthetic get foo @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::foo
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              returnType: int
''');
  }

  test_augmented_fields_add_useFieldInitializer() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
augment enum A {;
  final int foo;
}
''');

    var library = await buildLibrary(r'''
import augment 'a.dart';
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
  augmentationImports
    package:test/a.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/a.dart
      definingUnit: <testLibrary>::@fragment::package:test/a.dart
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      enums
        enum A @30
          reference: <testLibraryFragment>::@enum::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @36
              reference: <testLibraryFragment>::@enum::A::@field::v
              enclosingElement: <testLibraryFragment>::@enum::A
              type: A
              shouldUseTypeForInitializerInference: false
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              enclosingElement: <testLibraryFragment>::@enum::A
              type: List<A>
          constructors
            const @47
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@enum::A
              constantInitializers
                ConstructorFieldInitializer
                  fieldName: SimpleIdentifier
                    token: foo @53
                    staticElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::foo
                    staticType: null
                  equals: = @57
                  expression: IntegerLiteral
                    literal: 0 @59
                    staticType: int
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              enclosingElement: <testLibraryFragment>::@enum::A
              returnType: A
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              enclosingElement: <testLibraryFragment>::@enum::A
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
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @42
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          fields
            final foo @59
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::foo
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              type: int
          accessors
            synthetic get foo @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::foo
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              returnType: int
''');
  }

  test_augmented_getters_add() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
augment enum A {;
  int get foo2 => 0;
}
''');

    var library = await buildLibrary(r'''
import augment 'a.dart';
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
  augmentationImports
    package:test/a.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/a.dart
      definingUnit: <testLibrary>::@fragment::package:test/a.dart
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      enums
        enum A @30
          reference: <testLibraryFragment>::@enum::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @36
              reference: <testLibraryFragment>::@enum::A::@field::v
              enclosingElement: <testLibraryFragment>::@enum::A
              type: A
              shouldUseTypeForInitializerInference: false
              id: field_0
              getter: getter_0
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              enclosingElement: <testLibraryFragment>::@enum::A
              type: List<A>
              id: field_1
              getter: getter_1
            synthetic foo1 @-1
              reference: <testLibraryFragment>::@enum::A::@field::foo1
              enclosingElement: <testLibraryFragment>::@enum::A
              type: int
              id: field_2
              getter: getter_2
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@enum::A
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              enclosingElement: <testLibraryFragment>::@enum::A
              returnType: A
              id: getter_0
              variable: field_0
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              enclosingElement: <testLibraryFragment>::@enum::A
              returnType: List<A>
              id: getter_1
              variable: field_1
            get foo1 @49
              reference: <testLibraryFragment>::@enum::A::@getter::foo1
              enclosingElement: <testLibraryFragment>::@enum::A
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
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @42
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          fields
            synthetic foo2 @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::foo2
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              type: int
              id: field_3
              getter: getter_3
          accessors
            get foo2 @57
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::foo2
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              returnType: int
              id: getter_3
              variable: field_3
''');
  }

  test_augmented_getters_add_generic() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
augment enum A<T2> {;
  T2 get foo2;
}
''');

    var library = await buildLibrary(r'''
import augment 'a.dart';
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
  augmentationImports
    package:test/a.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/a.dart
      definingUnit: <testLibrary>::@fragment::package:test/a.dart
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      enums
        enum A @30
          reference: <testLibraryFragment>::@enum::A
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T1 @32
              defaultType: dynamic
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @40
              reference: <testLibraryFragment>::@enum::A::@field::v
              enclosingElement: <testLibraryFragment>::@enum::A
              type: A<int>
              shouldUseTypeForInitializerInference: false
              id: field_0
              getter: getter_0
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              enclosingElement: <testLibraryFragment>::@enum::A
              type: List<A<dynamic>>
              id: field_1
              getter: getter_1
            synthetic foo1 @-1
              reference: <testLibraryFragment>::@enum::A::@field::foo1
              enclosingElement: <testLibraryFragment>::@enum::A
              type: T1
              id: field_2
              getter: getter_2
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@enum::A
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              enclosingElement: <testLibraryFragment>::@enum::A
              returnType: A<int>
              id: getter_0
              variable: field_0
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              enclosingElement: <testLibraryFragment>::@enum::A
              returnType: List<A<dynamic>>
              id: getter_1
              variable: field_1
            abstract get foo1 @59
              reference: <testLibraryFragment>::@enum::A::@getter::foo1
              enclosingElement: <testLibraryFragment>::@enum::A
              returnType: T1
              id: getter_2
              variable: field_2
          augmented
            fields
              <testLibraryFragment>::@enum::A::@field::foo1
              FieldMember
                base: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::foo2
                augmentationSubstitution: {T2: T1}
              <testLibraryFragment>::@enum::A::@field::v
              <testLibraryFragment>::@enum::A::@field::values
            constants
              <testLibraryFragment>::@enum::A::@field::v
            constructors
              <testLibraryFragment>::@enum::A::@constructor::new
            accessors
              <testLibraryFragment>::@enum::A::@getter::foo1
              PropertyAccessorMember
                base: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::foo2
                augmentationSubstitution: {T2: T1}
              <testLibraryFragment>::@enum::A::@getter::v
              <testLibraryFragment>::@enum::A::@getter::values
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @42
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          typeParameters
            covariant T2 @44
              defaultType: dynamic
          augmentationTarget: <testLibraryFragment>::@enum::A
          fields
            synthetic foo2 @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::foo2
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              type: T2
              id: field_3
              getter: getter_3
          accessors
            abstract get foo2 @60
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::foo2
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              returnType: T2
              id: getter_3
              variable: field_3
''');
  }

  test_augmented_getters_augment_field() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
augment enum A {;
  augment int get foo => 0;
}
''');

    var library = await buildLibrary(r'''
import augment 'a.dart';
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
  augmentationImports
    package:test/a.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/a.dart
      definingUnit: <testLibrary>::@fragment::package:test/a.dart
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      enums
        enum A @30
          reference: <testLibraryFragment>::@enum::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @36
              reference: <testLibraryFragment>::@enum::A::@field::v
              enclosingElement: <testLibraryFragment>::@enum::A
              type: A
              shouldUseTypeForInitializerInference: false
              id: field_0
              getter: getter_0
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              enclosingElement: <testLibraryFragment>::@enum::A
              type: List<A>
              id: field_1
              getter: getter_1
            final foo @51
              reference: <testLibraryFragment>::@enum::A::@field::foo
              enclosingElement: <testLibraryFragment>::@enum::A
              type: int
              shouldUseTypeForInitializerInference: true
              id: field_2
              getter: getter_2
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@enum::A
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              enclosingElement: <testLibraryFragment>::@enum::A
              returnType: A
              id: getter_0
              variable: field_0
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              enclosingElement: <testLibraryFragment>::@enum::A
              returnType: List<A>
              id: getter_1
              variable: field_1
            synthetic get foo @-1
              reference: <testLibraryFragment>::@enum::A::@getter::foo
              enclosingElement: <testLibraryFragment>::@enum::A
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
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @42
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          accessors
            augment get foo @65
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getterAugmentation::foo
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              returnType: int
              id: getter_3
              variable: field_2
              augmentationTarget: <testLibraryFragment>::@enum::A::@getter::foo
''');
  }

  test_augmented_getters_augment_field2() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
augment enum A {;
  augment int get foo => 0;
}
''');

    newFile('$testPackageLibPath/b.dart', r'''
augment library 'test.dart';
augment enum A {;
  augment int get foo => 0;
}
''');

    var library = await buildLibrary(r'''
import augment 'a.dart';
import augment 'b.dart';
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
      enums
        enum A @55
          reference: <testLibraryFragment>::@enum::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @61
              reference: <testLibraryFragment>::@enum::A::@field::v
              enclosingElement: <testLibraryFragment>::@enum::A
              type: A
              shouldUseTypeForInitializerInference: false
              id: field_0
              getter: getter_0
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              enclosingElement: <testLibraryFragment>::@enum::A
              type: List<A>
              id: field_1
              getter: getter_1
            final foo @76
              reference: <testLibraryFragment>::@enum::A::@field::foo
              enclosingElement: <testLibraryFragment>::@enum::A
              type: int
              shouldUseTypeForInitializerInference: true
              id: field_2
              getter: getter_2
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@enum::A
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              enclosingElement: <testLibraryFragment>::@enum::A
              returnType: A
              id: getter_0
              variable: field_0
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              enclosingElement: <testLibraryFragment>::@enum::A
              returnType: List<A>
              id: getter_1
              variable: field_1
            synthetic get foo @-1
              reference: <testLibraryFragment>::@enum::A::@getter::foo
              enclosingElement: <testLibraryFragment>::@enum::A
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
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @42
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          augmentation: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          accessors
            augment get foo @65
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getterAugmentation::foo
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              returnType: int
              id: getter_3
              variable: field_2
              augmentationTarget: <testLibraryFragment>::@enum::A::@getter::foo
              augmentation: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@getterAugmentation::foo
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/b.dart
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @42
          reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/b.dart
          augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          accessors
            augment get foo @65
              reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@getterAugmentation::foo
              enclosingElement: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
              returnType: int
              id: getter_4
              variable: field_2
              augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getterAugmentation::foo
''');
  }

  test_augmented_getters_augment_getter() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
augment enum A {;
  augment int get foo1 => 0;
}
''');

    var library = await buildLibrary(r'''
import augment 'a.dart';
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
  augmentationImports
    package:test/a.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/a.dart
      definingUnit: <testLibrary>::@fragment::package:test/a.dart
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      enums
        enum A @30
          reference: <testLibraryFragment>::@enum::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @36
              reference: <testLibraryFragment>::@enum::A::@field::v
              enclosingElement: <testLibraryFragment>::@enum::A
              type: A
              shouldUseTypeForInitializerInference: false
              id: field_0
              getter: getter_0
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              enclosingElement: <testLibraryFragment>::@enum::A
              type: List<A>
              id: field_1
              getter: getter_1
            synthetic foo1 @-1
              reference: <testLibraryFragment>::@enum::A::@field::foo1
              enclosingElement: <testLibraryFragment>::@enum::A
              type: int
              id: field_2
              getter: getter_2
            synthetic foo2 @-1
              reference: <testLibraryFragment>::@enum::A::@field::foo2
              enclosingElement: <testLibraryFragment>::@enum::A
              type: int
              id: field_3
              getter: getter_3
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@enum::A
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              enclosingElement: <testLibraryFragment>::@enum::A
              returnType: A
              id: getter_0
              variable: field_0
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              enclosingElement: <testLibraryFragment>::@enum::A
              returnType: List<A>
              id: getter_1
              variable: field_1
            get foo1 @49
              reference: <testLibraryFragment>::@enum::A::@getter::foo1
              enclosingElement: <testLibraryFragment>::@enum::A
              returnType: int
              id: getter_2
              variable: field_2
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getterAugmentation::foo1
            get foo2 @70
              reference: <testLibraryFragment>::@enum::A::@getter::foo2
              enclosingElement: <testLibraryFragment>::@enum::A
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
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @42
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          accessors
            augment get foo1 @65
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getterAugmentation::foo1
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              returnType: int
              id: getter_4
              variable: field_2
              augmentationTarget: <testLibraryFragment>::@enum::A::@getter::foo1
''');
  }

  test_augmented_getters_augment_getter2_oneLib_oneTop() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
augment enum A {;
  augment int get foo => 0;
  augment int get foo => 0;
}
''');

    var library = await buildLibrary(r'''
import augment 'a.dart';
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
  augmentationImports
    package:test/a.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/a.dart
      definingUnit: <testLibrary>::@fragment::package:test/a.dart
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      enums
        enum A @30
          reference: <testLibraryFragment>::@enum::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @36
              reference: <testLibraryFragment>::@enum::A::@field::v
              enclosingElement: <testLibraryFragment>::@enum::A
              type: A
              shouldUseTypeForInitializerInference: false
              id: field_0
              getter: getter_0
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              enclosingElement: <testLibraryFragment>::@enum::A
              type: List<A>
              id: field_1
              getter: getter_1
            synthetic foo @-1
              reference: <testLibraryFragment>::@enum::A::@field::foo
              enclosingElement: <testLibraryFragment>::@enum::A
              type: int
              id: field_2
              getter: getter_2
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@enum::A
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              enclosingElement: <testLibraryFragment>::@enum::A
              returnType: A
              id: getter_0
              variable: field_0
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              enclosingElement: <testLibraryFragment>::@enum::A
              returnType: List<A>
              id: getter_1
              variable: field_1
            get foo @49
              reference: <testLibraryFragment>::@enum::A::@getter::foo
              enclosingElement: <testLibraryFragment>::@enum::A
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
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @42
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          accessors
            augment get foo @65
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getterAugmentation::foo::@def::0
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              returnType: int
              id: getter_3
              variable: field_2
              augmentationTarget: <testLibraryFragment>::@enum::A::@getter::foo
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getterAugmentation::foo::@def::1
            augment get foo @93
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getterAugmentation::foo::@def::1
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              returnType: int
              id: getter_4
              variable: field_2
              augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getterAugmentation::foo::@def::0
''');
  }

  test_augmented_getters_augment_getter2_twoLib() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
augment enum A {;
  augment int get foo => 0;
}
''');

    newFile('$testPackageLibPath/b.dart', r'''
augment library 'test.dart';
augment enum A {;
  augment int get foo => 0;
}
''');

    var library = await buildLibrary(r'''
import augment 'a.dart';
import augment 'b.dart';
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
      enums
        enum A @55
          reference: <testLibraryFragment>::@enum::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @61
              reference: <testLibraryFragment>::@enum::A::@field::v
              enclosingElement: <testLibraryFragment>::@enum::A
              type: A
              shouldUseTypeForInitializerInference: false
              id: field_0
              getter: getter_0
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              enclosingElement: <testLibraryFragment>::@enum::A
              type: List<A>
              id: field_1
              getter: getter_1
            synthetic foo @-1
              reference: <testLibraryFragment>::@enum::A::@field::foo
              enclosingElement: <testLibraryFragment>::@enum::A
              type: int
              id: field_2
              getter: getter_2
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@enum::A
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              enclosingElement: <testLibraryFragment>::@enum::A
              returnType: A
              id: getter_0
              variable: field_0
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              enclosingElement: <testLibraryFragment>::@enum::A
              returnType: List<A>
              id: getter_1
              variable: field_1
            get foo @74
              reference: <testLibraryFragment>::@enum::A::@getter::foo
              enclosingElement: <testLibraryFragment>::@enum::A
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
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @42
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          augmentation: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          accessors
            augment get foo @65
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getterAugmentation::foo
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              returnType: int
              id: getter_3
              variable: field_2
              augmentationTarget: <testLibraryFragment>::@enum::A::@getter::foo
              augmentation: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@getterAugmentation::foo
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/b.dart
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @42
          reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/b.dart
          augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          accessors
            augment get foo @65
              reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@getterAugmentation::foo
              enclosingElement: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
              returnType: int
              id: getter_4
              variable: field_2
              augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getterAugmentation::foo
''');
  }

  test_augmented_getters_augment_nothing() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
augment enum A {;
  augment int get foo => 0;
}
''');

    var library = await buildLibrary(r'''
import augment 'a.dart';
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
  augmentationImports
    package:test/a.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/a.dart
      definingUnit: <testLibrary>::@fragment::package:test/a.dart
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      enums
        enum A @30
          reference: <testLibraryFragment>::@enum::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @36
              reference: <testLibraryFragment>::@enum::A::@field::v
              enclosingElement: <testLibraryFragment>::@enum::A
              type: A
              shouldUseTypeForInitializerInference: false
              id: field_0
              getter: getter_0
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              enclosingElement: <testLibraryFragment>::@enum::A
              type: List<A>
              id: field_1
              getter: getter_1
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              enclosingElement: <testLibraryFragment>::@enum::A
              returnType: A
              id: getter_0
              variable: field_0
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              enclosingElement: <testLibraryFragment>::@enum::A
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
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @42
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          accessors
            augment get foo @65
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getterAugmentation::foo
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              returnType: int
              id: getter_2
              variable: <null>
''');
  }

  test_augmented_interfaces() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
augment enum A implements I2 {}
class I2 {}
''');

    var library = await buildLibrary(r'''
import augment 'a.dart';
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
  augmentationImports
    package:test/a.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/a.dart
      definingUnit: <testLibrary>::@fragment::package:test/a.dart
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      classes
        class I1 @60
          reference: <testLibraryFragment>::@class::I1
          enclosingElement: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::I1::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::I1
      enums
        enum A @30
          reference: <testLibraryFragment>::@enum::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          interfaces
            I1
          fields
            static const enumConstant v @50
              reference: <testLibraryFragment>::@enum::A::@field::v
              enclosingElement: <testLibraryFragment>::@enum::A
              type: A
              shouldUseTypeForInitializerInference: false
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              enclosingElement: <testLibraryFragment>::@enum::A
              type: List<A>
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@enum::A
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              enclosingElement: <testLibraryFragment>::@enum::A
              returnType: A
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              enclosingElement: <testLibraryFragment>::@enum::A
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
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      classes
        class I2 @67
          reference: <testLibrary>::@fragment::package:test/a.dart::@class::I2
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          constructors
            synthetic @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@class::I2::@constructor::new
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@class::I2
      enums
        augment enum A @42
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          interfaces
            I2
''');
  }

  test_augmented_interfaces_chain() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
import augment 'b.dart';
augment enum A implements I2 {}
class I2 {}
''');

    newFile('$testPackageLibPath/b.dart', r'''
augment library 'a.dart';
augment enum A implements I3 {}
class I3 {}
''');

    var library = await buildLibrary(r'''
import augment 'a.dart';
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
        class I1 @60
          reference: <testLibraryFragment>::@class::I1
          enclosingElement: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::I1::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::I1
      enums
        enum A @30
          reference: <testLibraryFragment>::@enum::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          interfaces
            I1
          fields
            static const enumConstant v @50
              reference: <testLibraryFragment>::@enum::A::@field::v
              enclosingElement: <testLibraryFragment>::@enum::A
              type: A
              shouldUseTypeForInitializerInference: false
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              enclosingElement: <testLibraryFragment>::@enum::A
              type: List<A>
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@enum::A
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              enclosingElement: <testLibraryFragment>::@enum::A
              returnType: A
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              enclosingElement: <testLibraryFragment>::@enum::A
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
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      classes
        class I2 @92
          reference: <testLibrary>::@fragment::package:test/a.dart::@class::I2
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          constructors
            synthetic @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@class::I2::@constructor::new
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@class::I2
      enums
        augment enum A @67
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          augmentation: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          interfaces
            I2
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/b.dart
      enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
      classes
        class I3 @64
          reference: <testLibrary>::@fragment::package:test/b.dart::@class::I3
          enclosingElement: <testLibrary>::@fragment::package:test/b.dart
          constructors
            synthetic @-1
              reference: <testLibrary>::@fragment::package:test/b.dart::@class::I3::@constructor::new
              enclosingElement: <testLibrary>::@fragment::package:test/b.dart::@class::I3
      enums
        augment enum A @39
          reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/b.dart
          augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          interfaces
            I3
''');
  }

  test_augmented_interfaces_generic() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
augment enum A<T2> implements I2<T2> {}
class I2<E> {}
''');

    var library = await buildLibrary(r'''
import augment 'a.dart';
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
  augmentationImports
    package:test/a.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/a.dart
      definingUnit: <testLibrary>::@fragment::package:test/a.dart
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      classes
        class I1 @70
          reference: <testLibraryFragment>::@class::I1
          enclosingElement: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::I1::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::I1
      enums
        enum A @30
          reference: <testLibraryFragment>::@enum::A
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T @32
              defaultType: dynamic
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          interfaces
            I1
          fields
            static const enumConstant v @53
              reference: <testLibraryFragment>::@enum::A::@field::v
              enclosingElement: <testLibraryFragment>::@enum::A
              type: A<int>
              shouldUseTypeForInitializerInference: false
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              enclosingElement: <testLibraryFragment>::@enum::A
              type: List<A<dynamic>>
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@enum::A
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              enclosingElement: <testLibraryFragment>::@enum::A
              returnType: A<int>
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              enclosingElement: <testLibraryFragment>::@enum::A
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
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      classes
        class I2 @75
          reference: <testLibrary>::@fragment::package:test/a.dart::@class::I2
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          typeParameters
            covariant E @78
              defaultType: dynamic
          constructors
            synthetic @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@class::I2::@constructor::new
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@class::I2
      enums
        augment enum A @42
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          typeParameters
            covariant T2 @44
              defaultType: dynamic
          augmentationTarget: <testLibraryFragment>::@enum::A
          interfaces
            I2<T2>
''');
  }

  test_augmented_interfaces_generic_mismatch() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
augment enum A<T2, T3> implements I2<T2> {}
class I2<E> {}
''');

    var library = await buildLibrary(r'''
import augment 'a.dart';
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
  augmentationImports
    package:test/a.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/a.dart
      definingUnit: <testLibrary>::@fragment::package:test/a.dart
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      classes
        class I1 @63
          reference: <testLibraryFragment>::@class::I1
          enclosingElement: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::I1::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::I1
      enums
        enum A @30
          reference: <testLibraryFragment>::@enum::A
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T @32
              defaultType: dynamic
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          interfaces
            I1
          fields
            static const enumConstant v @53
              reference: <testLibraryFragment>::@enum::A::@field::v
              enclosingElement: <testLibraryFragment>::@enum::A
              type: A<dynamic>
              shouldUseTypeForInitializerInference: false
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              enclosingElement: <testLibraryFragment>::@enum::A
              type: List<A<dynamic>>
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@enum::A
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              enclosingElement: <testLibraryFragment>::@enum::A
              returnType: A<dynamic>
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              enclosingElement: <testLibraryFragment>::@enum::A
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
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      classes
        class I2 @79
          reference: <testLibrary>::@fragment::package:test/a.dart::@class::I2
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          typeParameters
            covariant E @82
              defaultType: dynamic
          constructors
            synthetic @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@class::I2::@constructor::new
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@class::I2
      enums
        augment enum A @42
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          typeParameters
            covariant T2 @44
              defaultType: dynamic
            covariant T3 @48
              defaultType: dynamic
          augmentationTarget: <testLibraryFragment>::@enum::A
          interfaces
            I2<T2>
''');
  }

  test_augmented_methods() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
augment enum A {;
  void bar() {}
}
''');

    var library = await buildLibrary(r'''
import augment 'a.dart';
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
  augmentationImports
    package:test/a.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/a.dart
      definingUnit: <testLibrary>::@fragment::package:test/a.dart
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      enums
        enum A @30
          reference: <testLibraryFragment>::@enum::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @36
              reference: <testLibraryFragment>::@enum::A::@field::v
              enclosingElement: <testLibraryFragment>::@enum::A
              type: A
              shouldUseTypeForInitializerInference: false
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              enclosingElement: <testLibraryFragment>::@enum::A
              type: List<A>
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@enum::A
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              enclosingElement: <testLibraryFragment>::@enum::A
              returnType: A
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              enclosingElement: <testLibraryFragment>::@enum::A
              returnType: List<A>
          methods
            foo @46
              reference: <testLibraryFragment>::@enum::A::@method::foo
              enclosingElement: <testLibraryFragment>::@enum::A
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
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @42
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          methods
            bar @54
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@method::bar
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              returnType: void
''');
  }

  test_augmented_methods_add_withDefaultValue() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
augment enum A {;
  void foo([int x = 42]) {}
}
''');

    var library = await buildLibrary(r'''
import augment 'a.dart';
enum A {
  v
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
      enums
        enum A @30
          reference: <testLibraryFragment>::@enum::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @36
              reference: <testLibraryFragment>::@enum::A::@field::v
              enclosingElement: <testLibraryFragment>::@enum::A
              type: A
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibraryFragment>::@enum::A
                      type: A
                    staticElement: <testLibraryFragment>::@enum::A::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              enclosingElement: <testLibraryFragment>::@enum::A
              type: List<A>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::A::@getter::v
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@enum::A
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              enclosingElement: <testLibraryFragment>::@enum::A
              returnType: A
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              enclosingElement: <testLibraryFragment>::@enum::A
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
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @42
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          methods
            foo @54
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@method::foo
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              parameters
                optionalPositional default x @63
                  type: int
                  constantInitializer
                    IntegerLiteral
                      literal: 42 @67
                      staticType: int
              returnType: void
''');
  }

  test_augmented_methods_augment() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
augment enum A {;
  augment void foo1() {}
}
''');

    var library = await buildLibrary(r'''
import augment 'a.dart';
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
  augmentationImports
    package:test/a.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/a.dart
      definingUnit: <testLibrary>::@fragment::package:test/a.dart
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      enums
        enum A @30
          reference: <testLibraryFragment>::@enum::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @36
              reference: <testLibraryFragment>::@enum::A::@field::v
              enclosingElement: <testLibraryFragment>::@enum::A
              type: A
              shouldUseTypeForInitializerInference: false
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              enclosingElement: <testLibraryFragment>::@enum::A
              type: List<A>
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@enum::A
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              enclosingElement: <testLibraryFragment>::@enum::A
              returnType: A
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              enclosingElement: <testLibraryFragment>::@enum::A
              returnType: List<A>
          methods
            foo1 @46
              reference: <testLibraryFragment>::@enum::A::@method::foo1
              enclosingElement: <testLibraryFragment>::@enum::A
              returnType: void
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@methodAugmentation::foo1
            foo2 @63
              reference: <testLibraryFragment>::@enum::A::@method::foo2
              enclosingElement: <testLibraryFragment>::@enum::A
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
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @42
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          methods
            augment foo1 @62
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@methodAugmentation::foo1
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              returnType: void
              augmentationTarget: <testLibraryFragment>::@enum::A::@method::foo1
''');
  }

  test_augmented_methods_augment2_oneLib_oneTop() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
augment enum A {;
  augment void foo() {}
  augment void foo() {}
}
''');

    var library = await buildLibrary(r'''
import augment 'a.dart';
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
  augmentationImports
    package:test/a.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/a.dart
      definingUnit: <testLibrary>::@fragment::package:test/a.dart
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      enums
        enum A @30
          reference: <testLibraryFragment>::@enum::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @36
              reference: <testLibraryFragment>::@enum::A::@field::v
              enclosingElement: <testLibraryFragment>::@enum::A
              type: A
              shouldUseTypeForInitializerInference: false
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              enclosingElement: <testLibraryFragment>::@enum::A
              type: List<A>
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@enum::A
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              enclosingElement: <testLibraryFragment>::@enum::A
              returnType: A
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              enclosingElement: <testLibraryFragment>::@enum::A
              returnType: List<A>
          methods
            foo @46
              reference: <testLibraryFragment>::@enum::A::@method::foo
              enclosingElement: <testLibraryFragment>::@enum::A
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
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @42
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          methods
            augment foo @62
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@methodAugmentation::foo::@def::0
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              returnType: void
              augmentationTarget: <testLibraryFragment>::@enum::A::@method::foo
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@methodAugmentation::foo::@def::1
            augment foo @86
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@methodAugmentation::foo::@def::1
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              returnType: void
              augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@methodAugmentation::foo::@def::0
''');
  }

  test_augmented_methods_augment2_oneLib_twoTop() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
augment enum A {;
  augment void foo() {}
}
augment enum A {;
  augment void foo() {}
}
''');

    var library = await buildLibrary(r'''
import augment 'a.dart';
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
  augmentationImports
    package:test/a.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/a.dart
      definingUnit: <testLibrary>::@fragment::package:test/a.dart
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      enums
        enum A @30
          reference: <testLibraryFragment>::@enum::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::0
          supertype: Enum
          fields
            static const enumConstant v @36
              reference: <testLibraryFragment>::@enum::A::@field::v
              enclosingElement: <testLibraryFragment>::@enum::A
              type: A
              shouldUseTypeForInitializerInference: false
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              enclosingElement: <testLibraryFragment>::@enum::A
              type: List<A>
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@enum::A
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              enclosingElement: <testLibraryFragment>::@enum::A
              returnType: A
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              enclosingElement: <testLibraryFragment>::@enum::A
              returnType: List<A>
          methods
            foo @46
              reference: <testLibraryFragment>::@enum::A::@method::foo
              enclosingElement: <testLibraryFragment>::@enum::A
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
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @42
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::0
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::1
          methods
            augment foo @62
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::0::@methodAugmentation::foo
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::0
              returnType: void
              augmentationTarget: <testLibraryFragment>::@enum::A::@method::foo
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::1::@methodAugmentation::foo
        augment enum A @86
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::1
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::0
          methods
            augment foo @106
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::1::@methodAugmentation::foo
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::1
              returnType: void
              augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::0::@methodAugmentation::foo
''');
  }

  test_augmented_methods_augment2_twoLib() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
import augment 'b.dart';
augment enum A {;
  augment void foo() {}
}
''');

    newFile('$testPackageLibPath/b.dart', r'''
augment library 'a.dart';
augment enum A {;
  augment void foo() {}
}
''');

    var library = await buildLibrary(r'''
import augment 'a.dart';
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
      enums
        enum A @30
          reference: <testLibraryFragment>::@enum::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @36
              reference: <testLibraryFragment>::@enum::A::@field::v
              enclosingElement: <testLibraryFragment>::@enum::A
              type: A
              shouldUseTypeForInitializerInference: false
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              enclosingElement: <testLibraryFragment>::@enum::A
              type: List<A>
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@enum::A
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              enclosingElement: <testLibraryFragment>::@enum::A
              returnType: A
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              enclosingElement: <testLibraryFragment>::@enum::A
              returnType: List<A>
          methods
            foo @46
              reference: <testLibraryFragment>::@enum::A::@method::foo
              enclosingElement: <testLibraryFragment>::@enum::A
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
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @67
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          augmentation: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          methods
            augment foo @87
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@methodAugmentation::foo
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              returnType: void
              augmentationTarget: <testLibraryFragment>::@enum::A::@method::foo
              augmentation: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@methodAugmentation::foo
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/b.dart
      enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
      enums
        augment enum A @39
          reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/b.dart
          augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          methods
            augment foo @59
              reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@methodAugmentation::foo
              enclosingElement: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
              returnType: void
              augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@methodAugmentation::foo
''');
  }

  test_augmented_methods_generic() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
augment enum A<T2> {;
  T2 bar() => throw 0;
}
''');

    var library = await buildLibrary(r'''
import augment 'a.dart';
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
  augmentationImports
    package:test/a.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/a.dart
      definingUnit: <testLibrary>::@fragment::package:test/a.dart
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      enums
        enum A @30
          reference: <testLibraryFragment>::@enum::A
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T @32
              defaultType: dynamic
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @39
              reference: <testLibraryFragment>::@enum::A::@field::v
              enclosingElement: <testLibraryFragment>::@enum::A
              type: A<int>
              shouldUseTypeForInitializerInference: false
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              enclosingElement: <testLibraryFragment>::@enum::A
              type: List<A<dynamic>>
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@enum::A
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              enclosingElement: <testLibraryFragment>::@enum::A
              returnType: A<int>
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              enclosingElement: <testLibraryFragment>::@enum::A
              returnType: List<A<dynamic>>
          methods
            foo @53
              reference: <testLibraryFragment>::@enum::A::@method::foo
              enclosingElement: <testLibraryFragment>::@enum::A
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
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @42
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          typeParameters
            covariant T2 @44
              defaultType: dynamic
          augmentationTarget: <testLibraryFragment>::@enum::A
          methods
            bar @56
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@method::bar
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              returnType: T2
''');
  }

  test_augmented_methods_generic_augment() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
augment enum A<T2> {;
  augment T2 foo() => throw 0;
}
''');

    var library = await buildLibrary(r'''
import augment 'a.dart';
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
  augmentationImports
    package:test/a.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/a.dart
      definingUnit: <testLibrary>::@fragment::package:test/a.dart
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      enums
        enum A @30
          reference: <testLibraryFragment>::@enum::A
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T @32
              defaultType: dynamic
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @39
              reference: <testLibraryFragment>::@enum::A::@field::v
              enclosingElement: <testLibraryFragment>::@enum::A
              type: A<int>
              shouldUseTypeForInitializerInference: false
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              enclosingElement: <testLibraryFragment>::@enum::A
              type: List<A<dynamic>>
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@enum::A
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              enclosingElement: <testLibraryFragment>::@enum::A
              returnType: A<int>
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              enclosingElement: <testLibraryFragment>::@enum::A
              returnType: List<A<dynamic>>
          methods
            foo @53
              reference: <testLibraryFragment>::@enum::A::@method::foo
              enclosingElement: <testLibraryFragment>::@enum::A
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
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @42
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          typeParameters
            covariant T2 @44
              defaultType: dynamic
          augmentationTarget: <testLibraryFragment>::@enum::A
          methods
            augment foo @64
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@methodAugmentation::foo
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              returnType: T2
              augmentationTarget: <testLibraryFragment>::@enum::A::@method::foo
''');
  }

  test_augmented_mixins() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
augment enum A with M2 {}
mixin M2 {}
''');

    var library = await buildLibrary(r'''
import augment 'a.dart';
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
  augmentationImports
    package:test/a.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/a.dart
      definingUnit: <testLibrary>::@fragment::package:test/a.dart
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      enums
        enum A @30
          reference: <testLibraryFragment>::@enum::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          mixins
            M1
          fields
            static const enumConstant v @44
              reference: <testLibraryFragment>::@enum::A::@field::v
              enclosingElement: <testLibraryFragment>::@enum::A
              type: A
              shouldUseTypeForInitializerInference: false
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              enclosingElement: <testLibraryFragment>::@enum::A
              type: List<A>
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@enum::A
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              enclosingElement: <testLibraryFragment>::@enum::A
              returnType: A
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              enclosingElement: <testLibraryFragment>::@enum::A
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
        mixin M1 @54
          reference: <testLibraryFragment>::@mixin::M1
          enclosingElement: <testLibraryFragment>
          superclassConstraints
            Object
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @42
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          mixins
            M2
      mixins
        mixin M2 @61
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixin::M2
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          superclassConstraints
            Object
''');
  }

  test_augmented_mixins_inferredTypeArguments() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
augment enum A<T2> with M2 {}
mixin M2<U2> on M1<U2> {}
''');

    newFile('$testPackageLibPath/b.dart', r'''
augment library 'test.dart';
augment enum A<T3> with M3 {}
mixin M3<U3> on M2<U3> {}
''');

    var library = await buildLibrary(r'''
import augment 'a.dart';
import augment 'b.dart';
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
      enums
        enum A @55
          reference: <testLibraryFragment>::@enum::A
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T1 @57
              defaultType: dynamic
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          mixins
            M1<T1>
          fields
            static const enumConstant v @77
              reference: <testLibraryFragment>::@enum::A::@field::v
              enclosingElement: <testLibraryFragment>::@enum::A
              type: A<int>
              shouldUseTypeForInitializerInference: false
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              enclosingElement: <testLibraryFragment>::@enum::A
              type: List<A<dynamic>>
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@enum::A
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              enclosingElement: <testLibraryFragment>::@enum::A
              returnType: A<int>
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              enclosingElement: <testLibraryFragment>::@enum::A
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
        mixin M1 @94
          reference: <testLibraryFragment>::@mixin::M1
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant U1 @97
              defaultType: dynamic
          superclassConstraints
            Object
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @42
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          typeParameters
            covariant T2 @44
              defaultType: dynamic
          augmentationTarget: <testLibraryFragment>::@enum::A
          augmentation: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          mixins
            M2<T2>
      mixins
        mixin M2 @65
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixin::M2
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          typeParameters
            covariant U2 @68
              defaultType: dynamic
          superclassConstraints
            M1<U2>
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/b.dart
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @42
          reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/b.dart
          typeParameters
            covariant T3 @44
              defaultType: dynamic
          augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          mixins
            M3<T3>
      mixins
        mixin M3 @65
          reference: <testLibrary>::@fragment::package:test/b.dart::@mixin::M3
          enclosingElement: <testLibrary>::@fragment::package:test/b.dart
          typeParameters
            covariant U3 @68
              defaultType: dynamic
          superclassConstraints
            M2<U3>
''');
  }

  test_augmented_setters_add() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
augment enum A {;
  set foo2(int _) {}
}
''');

    var library = await buildLibrary(r'''
import augment 'a.dart';
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
  augmentationImports
    package:test/a.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/a.dart
      definingUnit: <testLibrary>::@fragment::package:test/a.dart
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      enums
        enum A @30
          reference: <testLibraryFragment>::@enum::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @36
              reference: <testLibraryFragment>::@enum::A::@field::v
              enclosingElement: <testLibraryFragment>::@enum::A
              type: A
              shouldUseTypeForInitializerInference: false
              id: field_0
              getter: getter_0
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              enclosingElement: <testLibraryFragment>::@enum::A
              type: List<A>
              id: field_1
              getter: getter_1
            synthetic foo1 @-1
              reference: <testLibraryFragment>::@enum::A::@field::foo1
              enclosingElement: <testLibraryFragment>::@enum::A
              type: int
              id: field_2
              setter: setter_0
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@enum::A
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              enclosingElement: <testLibraryFragment>::@enum::A
              returnType: A
              id: getter_0
              variable: field_0
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              enclosingElement: <testLibraryFragment>::@enum::A
              returnType: List<A>
              id: getter_1
              variable: field_1
            set foo1= @45
              reference: <testLibraryFragment>::@enum::A::@setter::foo1
              enclosingElement: <testLibraryFragment>::@enum::A
              parameters
                requiredPositional _ @54
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
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @42
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          fields
            synthetic foo2 @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::foo2
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              type: int
              id: field_3
              setter: setter_1
          accessors
            set foo2= @53
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@setter::foo2
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              parameters
                requiredPositional _ @62
                  type: int
              returnType: void
              id: setter_1
              variable: field_3
''');
  }

  test_augmented_setters_augment_field() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
augment enum A {;
  augment set foo(int _) {}
}
''');

    var library = await buildLibrary(r'''
import augment 'a.dart';
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
  augmentationImports
    package:test/a.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/a.dart
      definingUnit: <testLibrary>::@fragment::package:test/a.dart
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      enums
        enum A @30
          reference: <testLibraryFragment>::@enum::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @36
              reference: <testLibraryFragment>::@enum::A::@field::v
              enclosingElement: <testLibraryFragment>::@enum::A
              type: A
              shouldUseTypeForInitializerInference: false
              id: field_0
              getter: getter_0
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              enclosingElement: <testLibraryFragment>::@enum::A
              type: List<A>
              id: field_1
              getter: getter_1
            final foo @51
              reference: <testLibraryFragment>::@enum::A::@field::foo
              enclosingElement: <testLibraryFragment>::@enum::A
              type: int
              shouldUseTypeForInitializerInference: true
              id: field_2
              getter: getter_2
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@enum::A
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              enclosingElement: <testLibraryFragment>::@enum::A
              returnType: A
              id: getter_0
              variable: field_0
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              enclosingElement: <testLibraryFragment>::@enum::A
              returnType: List<A>
              id: getter_1
              variable: field_1
            synthetic get foo @-1
              reference: <testLibraryFragment>::@enum::A::@getter::foo
              enclosingElement: <testLibraryFragment>::@enum::A
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
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @42
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          accessors
            augment set foo= @61
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@setterAugmentation::foo
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              parameters
                requiredPositional _ @69
                  type: int
              returnType: void
              id: setter_0
              variable: <null>
              augmentationTargetAny: <testLibraryFragment>::@enum::A::@getter::foo
''');
  }

  test_augmented_setters_augment_nothing() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
augment enum A {;
  augment set foo(int _) {}
}
''');

    var library = await buildLibrary(r'''
import augment 'a.dart';
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
  augmentationImports
    package:test/a.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/a.dart
      definingUnit: <testLibrary>::@fragment::package:test/a.dart
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      enums
        enum A @30
          reference: <testLibraryFragment>::@enum::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @36
              reference: <testLibraryFragment>::@enum::A::@field::v
              enclosingElement: <testLibraryFragment>::@enum::A
              type: A
              shouldUseTypeForInitializerInference: false
              id: field_0
              getter: getter_0
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              enclosingElement: <testLibraryFragment>::@enum::A
              type: List<A>
              id: field_1
              getter: getter_1
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@enum::A
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              enclosingElement: <testLibraryFragment>::@enum::A
              returnType: A
              id: getter_0
              variable: field_0
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              enclosingElement: <testLibraryFragment>::@enum::A
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
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @42
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          accessors
            augment set foo= @61
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@setterAugmentation::foo
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              parameters
                requiredPositional _ @69
                  type: int
              returnType: void
              id: setter_0
              variable: <null>
''');
  }

  test_augmented_setters_augment_setter() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
augment enum A {;
  augment set foo1(int _) {}
}
''');

    var library = await buildLibrary(r'''
import augment 'a.dart';
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
  augmentationImports
    package:test/a.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/a.dart
      definingUnit: <testLibrary>::@fragment::package:test/a.dart
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      enums
        enum A @30
          reference: <testLibraryFragment>::@enum::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @36
              reference: <testLibraryFragment>::@enum::A::@field::v
              enclosingElement: <testLibraryFragment>::@enum::A
              type: A
              shouldUseTypeForInitializerInference: false
              id: field_0
              getter: getter_0
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              enclosingElement: <testLibraryFragment>::@enum::A
              type: List<A>
              id: field_1
              getter: getter_1
            synthetic foo1 @-1
              reference: <testLibraryFragment>::@enum::A::@field::foo1
              enclosingElement: <testLibraryFragment>::@enum::A
              type: int
              id: field_2
              setter: setter_0
            synthetic foo2 @-1
              reference: <testLibraryFragment>::@enum::A::@field::foo2
              enclosingElement: <testLibraryFragment>::@enum::A
              type: int
              id: field_3
              setter: setter_1
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@enum::A
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              enclosingElement: <testLibraryFragment>::@enum::A
              returnType: A
              id: getter_0
              variable: field_0
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              enclosingElement: <testLibraryFragment>::@enum::A
              returnType: List<A>
              id: getter_1
              variable: field_1
            set foo1= @45
              reference: <testLibraryFragment>::@enum::A::@setter::foo1
              enclosingElement: <testLibraryFragment>::@enum::A
              parameters
                requiredPositional _ @54
                  type: int
              returnType: void
              id: setter_0
              variable: field_2
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@setterAugmentation::foo1
            set foo2= @66
              reference: <testLibraryFragment>::@enum::A::@setter::foo2
              enclosingElement: <testLibraryFragment>::@enum::A
              parameters
                requiredPositional _ @75
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
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @42
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          accessors
            augment set foo1= @61
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@setterAugmentation::foo1
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              parameters
                requiredPositional _ @70
                  type: int
              returnType: void
              id: setter_2
              variable: field_2
              augmentationTarget: <testLibraryFragment>::@enum::A::@setter::foo1
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

enum A {v}
''');

    configuration
      ..withConstantInitializers = false
      ..withConstructors = false;
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
      enums
        enum A @56
          reference: <testLibraryFragment>::@enum::A
          enclosingElement: <testLibraryFragment>
          supertype: Enum
          fields
            static const enumConstant v @59
              reference: <testLibraryFragment>::@enum::A::@field::v
              enclosingElement: <testLibraryFragment>::@enum::A
              type: A
              shouldUseTypeForInitializerInference: false
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              enclosingElement: <testLibraryFragment>::@enum::A
              type: List<A>
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              enclosingElement: <testLibraryFragment>::@enum::A
              returnType: A
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              enclosingElement: <testLibraryFragment>::@enum::A
              returnType: List<A>
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      classes
        augment class A @44
          reference: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTargetAny: <testLibraryFragment>::@enum::A
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/b.dart
      enclosingElement3: <testLibraryFragment>
      classes
        augment class A @44
          reference: <testLibrary>::@fragment::package:test/b.dart::@classAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/b.dart
          augmentationTargetAny: <testLibraryFragment>::@enum::A
''');
  }

  test_augmentedBy_class_enum() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';

augment class A {}
''');

    newFile('$testPackageLibPath/b.dart', r'''
augment library 'test.dart';

augment enum A {}
''');

    var library = await buildLibrary(r'''
import augment 'a.dart';
import augment 'b.dart';

enum A {v}
''');

    configuration
      ..withConstantInitializers = false
      ..withConstructors = false;
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
      enums
        enum A @56
          reference: <testLibraryFragment>::@enum::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @59
              reference: <testLibraryFragment>::@enum::A::@field::v
              enclosingElement: <testLibraryFragment>::@enum::A
              type: A
              shouldUseTypeForInitializerInference: false
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              enclosingElement: <testLibraryFragment>::@enum::A
              type: List<A>
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              enclosingElement: <testLibraryFragment>::@enum::A
              returnType: A
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              enclosingElement: <testLibraryFragment>::@enum::A
              returnType: List<A>
          augmented
            fields
              <testLibraryFragment>::@enum::A::@field::v
              <testLibraryFragment>::@enum::A::@field::values
            constants
              <testLibraryFragment>::@enum::A::@field::v
            accessors
              <testLibraryFragment>::@enum::A::@getter::v
              <testLibraryFragment>::@enum::A::@getter::values
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      classes
        augment class A @44
          reference: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTargetAny: <testLibraryFragment>::@enum::A
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/b.dart
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @43
          reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/b.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
''');
  }

  test_constructors_augment2() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
augment enum A {;
  augment const A.named();
}
''');

    newFile('$testPackageLibPath/b.dart', r'''
augment library 'test.dart';
augment enum A {;
  augment const A.named();
}
''');

    var library = await buildLibrary(r'''
import augment 'a.dart';
import augment 'b.dart';
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
      enums
        enum A @55
          reference: <testLibraryFragment>::@enum::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @61
              reference: <testLibraryFragment>::@enum::A::@field::v
              enclosingElement: <testLibraryFragment>::@enum::A
              type: A
              shouldUseTypeForInitializerInference: false
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              enclosingElement: <testLibraryFragment>::@enum::A
              type: List<A>
          constructors
            const named @82
              reference: <testLibraryFragment>::@enum::A::@constructor::named
              enclosingElement: <testLibraryFragment>::@enum::A
              periodOffset: 81
              nameEnd: 87
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructorAugmentation::named
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              enclosingElement: <testLibraryFragment>::@enum::A
              returnType: A
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              enclosingElement: <testLibraryFragment>::@enum::A
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
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @42
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          augmentation: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          constructors
            augment const named @65
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructorAugmentation::named
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              periodOffset: 64
              nameEnd: 70
              augmentationTarget: <testLibraryFragment>::@enum::A::@constructor::named
              augmentation: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@constructorAugmentation::named
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement: <testLibrary>::@augmentation::package:test/b.dart
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @42
          reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/b.dart
          augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          constructors
            augment const named @65
              reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@constructorAugmentation::named
              enclosingElement: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
              periodOffset: 64
              nameEnd: 70
              augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructorAugmentation::named
''');
  }

  test_constructors_augment_named() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
augment enum A {;
  augment const A.named();
}
''');

    var library = await buildLibrary(r'''
import augment 'a.dart';
enum A {
  v.named();
  const A.named();
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
      enums
        enum A @30
          reference: <testLibraryFragment>::@enum::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @36
              reference: <testLibraryFragment>::@enum::A::@field::v
              enclosingElement: <testLibraryFragment>::@enum::A
              type: A
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibraryFragment>::@enum::A
                      type: A
                    period: . @0
                    name: SimpleIdentifier
                      token: named @-1
                      staticElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructorAugmentation::named
                      staticType: null
                    staticElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructorAugmentation::named
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              enclosingElement: <testLibraryFragment>::@enum::A
              type: List<A>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::A::@getter::v
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
          constructors
            const named @57
              reference: <testLibraryFragment>::@enum::A::@constructor::named
              enclosingElement: <testLibraryFragment>::@enum::A
              periodOffset: 56
              nameEnd: 62
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructorAugmentation::named
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              enclosingElement: <testLibraryFragment>::@enum::A
              returnType: A
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              enclosingElement: <testLibraryFragment>::@enum::A
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
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @42
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          constructors
            augment const named @65
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructorAugmentation::named
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              periodOffset: 64
              nameEnd: 70
              augmentationTarget: <testLibraryFragment>::@enum::A::@constructor::named
''');
  }

  test_constructors_augment_unnamed() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
augment enum A {;
  augment const A();
}
''');

    var library = await buildLibrary(r'''
import augment 'a.dart';
enum A {
  v;
  const A();
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
      enums
        enum A @30
          reference: <testLibraryFragment>::@enum::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @36
              reference: <testLibraryFragment>::@enum::A::@field::v
              enclosingElement: <testLibraryFragment>::@enum::A
              type: A
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: A @-1
                      element: <testLibraryFragment>::@enum::A
                      type: A
                    staticElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructorAugmentation::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: A
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              enclosingElement: <testLibraryFragment>::@enum::A
              type: List<A>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::A::@getter::v
                      staticType: A
                  rightBracket: ] @0
                  staticType: List<A>
          constructors
            const @47
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@enum::A
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructorAugmentation::new
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              enclosingElement: <testLibraryFragment>::@enum::A
              returnType: A
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              enclosingElement: <testLibraryFragment>::@enum::A
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
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @42
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          constructors
            augment const @63
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructorAugmentation::new
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              augmentationTarget: <testLibraryFragment>::@enum::A::@constructor::new
''');
  }

  test_inferTypes_method_ofAugment() async {
    newFile('$testPackageLibPath/a.dart', r'''
abstract class A {
  int foo(String a);
}
''');

    newFile('$testPackageLibPath/b.dart', r'''
augment library 'test.dart';
augment enum B {;
  foo(a) => 0;
}
''');

    var library = await buildLibrary(r'''
import 'a.dart';
import augment 'b.dart';

enum B implements A {
  v
}
''');

    configuration.withConstantInitializers = false;
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
      enums
        enum B @48
          reference: <testLibraryFragment>::@enum::B
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::B
          supertype: Enum
          interfaces
            A
          fields
            static const enumConstant v @67
              reference: <testLibraryFragment>::@enum::B::@field::v
              enclosingElement: <testLibraryFragment>::@enum::B
              type: B
              shouldUseTypeForInitializerInference: false
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::B::@field::values
              enclosingElement: <testLibraryFragment>::@enum::B
              type: List<B>
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::B::@constructor::new
              enclosingElement: <testLibraryFragment>::@enum::B
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::B::@getter::v
              enclosingElement: <testLibraryFragment>::@enum::B
              returnType: B
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::B::@getter::values
              enclosingElement: <testLibraryFragment>::@enum::B
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
      enclosingElement: <testLibrary>::@augmentation::package:test/b.dart
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum B @42
          reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::B
          enclosingElement: <testLibrary>::@fragment::package:test/b.dart
          augmentationTarget: <testLibraryFragment>::@enum::B
          methods
            foo @49
              reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::B::@method::foo
              enclosingElement: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::B
              parameters
                requiredPositional a @53
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

    newFile('$testPackageLibPath/b.dart', r'''
augment library 'test.dart';
import 'a.dart';
augment enum B implements A {}
''');

    var library = await buildLibrary(r'''
import augment 'b.dart';

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
      enums
        enum B @31
          reference: <testLibraryFragment>::@enum::B
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::B
          supertype: Enum
          fields
            static const enumConstant v @37
              reference: <testLibraryFragment>::@enum::B::@field::v
              enclosingElement: <testLibraryFragment>::@enum::B
              type: B
              shouldUseTypeForInitializerInference: false
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::B::@field::values
              enclosingElement: <testLibraryFragment>::@enum::B
              type: List<B>
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::B::@constructor::new
              enclosingElement: <testLibraryFragment>::@enum::B
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::B::@getter::v
              enclosingElement: <testLibraryFragment>::@enum::B
              returnType: B
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::B::@getter::values
              enclosingElement: <testLibraryFragment>::@enum::B
              returnType: List<B>
          methods
            foo @42
              reference: <testLibraryFragment>::@enum::B::@method::foo
              enclosingElement: <testLibraryFragment>::@enum::B
              parameters
                requiredPositional a @46
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
      enclosingElement: <testLibrary>::@augmentation::package:test/b.dart
      enclosingElement3: <testLibraryFragment>
      libraryImports
        package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibrary>::@fragment::package:test/b.dart
      enums
        augment enum B @59
          reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::B
          enclosingElement: <testLibrary>::@fragment::package:test/b.dart
          augmentationTarget: <testLibraryFragment>::@enum::B
          interfaces
            A
''');
  }

  test_inferTypes_method_usingAugmentation_mixin() async {
    newFile('$testPackageLibPath/a.dart', r'''
mixin A {
  int foo(String a) => 0;
}
''');

    newFile('$testPackageLibPath/b.dart', r'''
augment library 'test.dart';
import 'a.dart';
augment enum B with A {}
''');

    var library = await buildLibrary(r'''
import augment 'b.dart';

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
      enums
        enum B @31
          reference: <testLibraryFragment>::@enum::B
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::B
          supertype: Enum
          fields
            static const enumConstant v @37
              reference: <testLibraryFragment>::@enum::B::@field::v
              enclosingElement: <testLibraryFragment>::@enum::B
              type: B
              shouldUseTypeForInitializerInference: false
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::B::@field::values
              enclosingElement: <testLibraryFragment>::@enum::B
              type: List<B>
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::B::@constructor::new
              enclosingElement: <testLibraryFragment>::@enum::B
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::B::@getter::v
              enclosingElement: <testLibraryFragment>::@enum::B
              returnType: B
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::B::@getter::values
              enclosingElement: <testLibraryFragment>::@enum::B
              returnType: List<B>
          methods
            foo @42
              reference: <testLibraryFragment>::@enum::B::@method::foo
              enclosingElement: <testLibraryFragment>::@enum::B
              parameters
                requiredPositional a @46
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
      enclosingElement: <testLibrary>::@augmentation::package:test/b.dart
      enclosingElement3: <testLibraryFragment>
      libraryImports
        package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibrary>::@fragment::package:test/b.dart
      enums
        augment enum B @59
          reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::B
          enclosingElement: <testLibrary>::@fragment::package:test/b.dart
          augmentationTarget: <testLibraryFragment>::@enum::B
          mixins
            A
''');
  }

  test_typeParameters_defaultType() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';
augment enum A<T extends B> {}
''');

    var library = await buildLibrary(r'''
import augment 'a.dart';
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
  augmentationImports
    package:test/a.dart
      enclosingElement: <testLibrary>
      reference: <testLibrary>::@augmentation::package:test/a.dart
      definingUnit: <testLibrary>::@fragment::package:test/a.dart
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      classes
        class B @59
          reference: <testLibraryFragment>::@class::B
          enclosingElement: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::B::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::B
      enums
        enum A @30
          reference: <testLibraryFragment>::@enum::A
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T @32
              bound: B
              defaultType: B
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @49
              reference: <testLibraryFragment>::@enum::A::@field::v
              enclosingElement: <testLibraryFragment>::@enum::A
              type: A<B>
              shouldUseTypeForInitializerInference: false
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              enclosingElement: <testLibraryFragment>::@enum::A
              type: List<A<B>>
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@enum::A
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              enclosingElement: <testLibraryFragment>::@enum::A
              returnType: A<B>
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              enclosingElement: <testLibraryFragment>::@enum::A
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
      enclosingElement: <testLibrary>::@augmentation::package:test/a.dart
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @42
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          typeParameters
            covariant T @44
              bound: B
              defaultType: B
          augmentationTarget: <testLibraryFragment>::@enum::A
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

// TODO(scheglov): This is duplicate.
extension on ElementTextConfiguration {
  void forPromotableFields({
    Set<String> classNames = const {},
    Set<String> enumNames = const {},
    Set<String> extensionTypeNames = const {},
    Set<String> mixinNames = const {},
    Set<String> fieldNames = const {},
  }) {
    filter = (e) {
      if (e is ClassElement) {
        return classNames.contains(e.name);
      } else if (e is ConstructorElement) {
        return false;
      } else if (e is EnumElement) {
        return enumNames.contains(e.name);
      } else if (e is ExtensionTypeElement) {
        return extensionTypeNames.contains(e.name);
      } else if (e is FieldElement) {
        return fieldNames.isEmpty || fieldNames.contains(e.name);
      } else if (e is MixinElement) {
        return mixinNames.contains(e.name);
      } else if (e is PartElement) {
        return false;
      } else if (e is PropertyAccessorElement) {
        return false;
      }
      return true;
    };
  }
}
