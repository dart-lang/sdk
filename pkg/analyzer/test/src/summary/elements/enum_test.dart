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
      enclosingElement3: <null>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          enclosingElement3: <testLibraryFragment>
          codeOffset: 0
          codeLength: 26
          supertype: Enum
          fields
            static const enumConstant aaa @11
              reference: <testLibraryFragment>::@enum::E::@field::aaa
              enclosingElement3: <testLibraryFragment>::@enum::E
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
                      element2: <testLibraryFragment>::@enum::E#element
                      type: E
                    staticElement: <testLibraryFragment>::@enum::E::@constructor::new
                    element: <testLibraryFragment>::@enum::E::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            static const enumConstant bbb @16
              reference: <testLibraryFragment>::@enum::E::@field::bbb
              enclosingElement3: <testLibraryFragment>::@enum::E
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
                      element2: <testLibraryFragment>::@enum::E#element
                      type: E
                    staticElement: <testLibraryFragment>::@enum::E::@constructor::new
                    element: <testLibraryFragment>::@enum::E::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            static const enumConstant ccc @21
              reference: <testLibraryFragment>::@enum::E::@field::ccc
              enclosingElement3: <testLibraryFragment>::@enum::E
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
                      element2: <testLibraryFragment>::@enum::E#element
                      type: E
                    staticElement: <testLibraryFragment>::@enum::E::@constructor::new
                    element: <testLibraryFragment>::@enum::E::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              enclosingElement3: <testLibraryFragment>::@enum::E
              type: List<E>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: aaa @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::aaa
                      element: <testLibraryFragment>::@enum::E::@getter::aaa#element
                      staticType: E
                    SimpleIdentifier
                      token: bbb @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::bbb
                      element: <testLibraryFragment>::@enum::E::@getter::bbb#element
                      staticType: E
                    SimpleIdentifier
                      token: ccc @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::ccc
                      element: <testLibraryFragment>::@enum::E::@getter::ccc#element
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              enclosingElement3: <testLibraryFragment>::@enum::E
          accessors
            synthetic static get aaa @-1
              reference: <testLibraryFragment>::@enum::E::@getter::aaa
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: E
            synthetic static get bbb @-1
              reference: <testLibraryFragment>::@enum::E::@getter::bbb
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: E
            synthetic static get ccc @-1
              reference: <testLibraryFragment>::@enum::E::@getter::ccc
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: E
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: List<E>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          element: <testLibraryFragment>::@enum::E#element
          fields
            enumConstant aaa @11
              reference: <testLibraryFragment>::@enum::E::@field::aaa
              element: <testLibraryFragment>::@enum::E::@field::aaa#element
              getter2: <testLibraryFragment>::@enum::E::@getter::aaa
            enumConstant bbb @16
              reference: <testLibraryFragment>::@enum::E::@field::bbb
              element: <testLibraryFragment>::@enum::E::@field::bbb#element
              getter2: <testLibraryFragment>::@enum::E::@getter::bbb
            enumConstant ccc @21
              reference: <testLibraryFragment>::@enum::E::@field::ccc
              element: <testLibraryFragment>::@enum::E::@field::ccc#element
              getter2: <testLibraryFragment>::@enum::E::@getter::ccc
            values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              element: <testLibraryFragment>::@enum::E::@field::values#element
              getter2: <testLibraryFragment>::@enum::E::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              element: <testLibraryFragment>::@enum::E::@constructor::new#element
          getters
            get aaa @-1
              reference: <testLibraryFragment>::@enum::E::@getter::aaa
              element: <testLibraryFragment>::@enum::E::@getter::aaa#element
            get bbb @-1
              reference: <testLibraryFragment>::@enum::E::@getter::bbb
              element: <testLibraryFragment>::@enum::E::@getter::bbb#element
            get ccc @-1
              reference: <testLibraryFragment>::@enum::E::@getter::ccc
              element: <testLibraryFragment>::@enum::E::@getter::ccc#element
            get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              element: <testLibraryFragment>::@enum::E::@getter::values#element
  enums
    enum E
      firstFragment: <testLibraryFragment>::@enum::E
      supertype: Enum
      fields
        static const aaa
          firstFragment: <testLibraryFragment>::@enum::E::@field::aaa
          type: E
          getter: <testLibraryFragment>::@enum::E::@getter::aaa#element
        static const bbb
          firstFragment: <testLibraryFragment>::@enum::E::@field::bbb
          type: E
          getter: <testLibraryFragment>::@enum::E::@getter::bbb#element
        static const ccc
          firstFragment: <testLibraryFragment>::@enum::E::@field::ccc
          type: E
          getter: <testLibraryFragment>::@enum::E::@getter::ccc#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
          type: List<E>
          getter: <testLibraryFragment>::@enum::E::@getter::values#element
      constructors
        synthetic const new
          firstFragment: <testLibraryFragment>::@enum::E::@constructor::new
      getters
        synthetic static get aaa
          firstFragment: <testLibraryFragment>::@enum::E::@getter::aaa
        synthetic static get bbb
          firstFragment: <testLibraryFragment>::@enum::E::@getter::bbb
        synthetic static get ccc
          firstFragment: <testLibraryFragment>::@enum::E::@getter::ccc
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::E::@getter::values
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
      enclosingElement3: <null>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant T @7
              defaultType: dynamic
          supertype: Enum
          fields
            static const enumConstant int @14
              reference: <testLibraryFragment>::@enum::E::@field::int
              enclosingElement3: <testLibraryFragment>::@enum::E
              type: E<int>
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E
                      element2: <testLibraryFragment>::@enum::E#element
                      type: E<int>
                    staticElement: ConstructorMember
                      base: <testLibraryFragment>::@enum::E::@constructor::new
                      substitution: {T: int}
                    element: <testLibraryFragment>::@enum::E::@constructor::new#element
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
              enclosingElement3: <testLibraryFragment>::@enum::E
              type: E<String>
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E
                      element2: <testLibraryFragment>::@enum::E#element
                      type: E<String>
                    staticElement: ConstructorMember
                      base: <testLibraryFragment>::@enum::E::@constructor::new
                      substitution: {T: String}
                    element: <testLibraryFragment>::@enum::E::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    arguments
                      SimpleStringLiteral
                        literal: '2' @29
                    rightParenthesis: ) @0
                  staticType: E<String>
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              enclosingElement3: <testLibraryFragment>::@enum::E
              type: List<E<dynamic>>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: int @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::int
                      element: <testLibraryFragment>::@enum::E::@getter::int#element
                      staticType: E<int>
                    SimpleIdentifier
                      token: string @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::string
                      element: <testLibraryFragment>::@enum::E::@getter::string#element
                      staticType: E<String>
                  rightBracket: ] @0
                  staticType: List<E<dynamic>>
          constructors
            const @43
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              enclosingElement3: <testLibraryFragment>::@enum::E
              parameters
                requiredPositional a @47
                  type: T
          accessors
            synthetic static get int @-1
              reference: <testLibraryFragment>::@enum::E::@getter::int
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: E<int>
            synthetic static get string @-1
              reference: <testLibraryFragment>::@enum::E::@getter::string
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: E<String>
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: List<E<dynamic>>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          element: <testLibraryFragment>::@enum::E#element
          typeParameters
            T @7
              element: <not-implemented>
          fields
            enumConstant int @14
              reference: <testLibraryFragment>::@enum::E::@field::int
              element: <testLibraryFragment>::@enum::E::@field::int#element
              getter2: <testLibraryFragment>::@enum::E::@getter::int
            enumConstant string @22
              reference: <testLibraryFragment>::@enum::E::@field::string
              element: <testLibraryFragment>::@enum::E::@field::string#element
              getter2: <testLibraryFragment>::@enum::E::@getter::string
            values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              element: <testLibraryFragment>::@enum::E::@field::values#element
              getter2: <testLibraryFragment>::@enum::E::@getter::values
          constructors
            const new @43
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              element: <testLibraryFragment>::@enum::E::@constructor::new#element
              formalParameters
                a @47
                  element: <testLibraryFragment>::@enum::E::@constructor::new::@parameter::a#element
          getters
            get int @-1
              reference: <testLibraryFragment>::@enum::E::@getter::int
              element: <testLibraryFragment>::@enum::E::@getter::int#element
            get string @-1
              reference: <testLibraryFragment>::@enum::E::@getter::string
              element: <testLibraryFragment>::@enum::E::@getter::string#element
            get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              element: <testLibraryFragment>::@enum::E::@getter::values#element
  enums
    enum E
      firstFragment: <testLibraryFragment>::@enum::E
      typeParameters
        T
      supertype: Enum
      fields
        static const int
          firstFragment: <testLibraryFragment>::@enum::E::@field::int
          type: E<int>
          getter: <testLibraryFragment>::@enum::E::@getter::int#element
        static const string
          firstFragment: <testLibraryFragment>::@enum::E::@field::string
          type: E<String>
          getter: <testLibraryFragment>::@enum::E::@getter::string#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
          type: List<E<dynamic>>
          getter: <testLibraryFragment>::@enum::E::@getter::values#element
      constructors
        const new
          firstFragment: <testLibraryFragment>::@enum::E::@constructor::new
          formalParameters
            requiredPositional a
              type: T
      getters
        synthetic static get int
          firstFragment: <testLibraryFragment>::@enum::E::@getter::int
        synthetic static get string
          firstFragment: <testLibraryFragment>::@enum::E::@getter::string
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::E::@getter::values
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
      enclosingElement3: <null>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          enclosingElement3: <testLibraryFragment>
          supertype: Enum
          fields
            static const enumConstant _name @11
              reference: <testLibraryFragment>::@enum::E::@field::_name
              enclosingElement3: <testLibraryFragment>::@enum::E
              type: E
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E
                      element2: <testLibraryFragment>::@enum::E#element
                      type: E
                    staticElement: <testLibraryFragment>::@enum::E::@constructor::new
                    element: <testLibraryFragment>::@enum::E::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              enclosingElement3: <testLibraryFragment>::@enum::E
              type: List<E>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: _name @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::_name
                      element: <testLibraryFragment>::@enum::E::@getter::_name#element
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              enclosingElement3: <testLibraryFragment>::@enum::E
          accessors
            synthetic static get _name @-1
              reference: <testLibraryFragment>::@enum::E::@getter::_name
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: E
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: List<E>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          element: <testLibraryFragment>::@enum::E#element
          fields
            enumConstant _name @11
              reference: <testLibraryFragment>::@enum::E::@field::_name
              element: <testLibraryFragment>::@enum::E::@field::_name#element
              getter2: <testLibraryFragment>::@enum::E::@getter::_name
            values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              element: <testLibraryFragment>::@enum::E::@field::values#element
              getter2: <testLibraryFragment>::@enum::E::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              element: <testLibraryFragment>::@enum::E::@constructor::new#element
          getters
            get _name @-1
              reference: <testLibraryFragment>::@enum::E::@getter::_name
              element: <testLibraryFragment>::@enum::E::@getter::_name#element
            get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              element: <testLibraryFragment>::@enum::E::@getter::values#element
  enums
    enum E
      firstFragment: <testLibraryFragment>::@enum::E
      supertype: Enum
      fields
        static const _name
          firstFragment: <testLibraryFragment>::@enum::E::@field::_name
          type: E
          getter: <testLibraryFragment>::@enum::E::@getter::_name#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
          type: List<E>
          getter: <testLibraryFragment>::@enum::E::@getter::values#element
      constructors
        synthetic const new
          firstFragment: <testLibraryFragment>::@enum::E::@constructor::new
      getters
        synthetic static get _name
          firstFragment: <testLibraryFragment>::@enum::E::@getter::_name
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::E::@getter::values
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
      enclosingElement3: <null>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant T @7
              defaultType: dynamic
          supertype: Enum
          fields
            static const enumConstant v @14
              reference: <testLibraryFragment>::@enum::E::@field::v
              enclosingElement3: <testLibraryFragment>::@enum::E
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
                            element2: dart:core::<fragment>::@class::double#element
                            type: double
                        rightBracket: > @22
                      element: <testLibraryFragment>::@enum::E
                      element2: <testLibraryFragment>::@enum::E#element
                      type: E<double>
                    staticElement: ConstructorMember
                      base: <testLibraryFragment>::@enum::E::@constructor::new
                      substitution: {T: double}
                    element: <testLibraryFragment>::@enum::E::@constructor::new#element
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
              enclosingElement3: <testLibraryFragment>::@enum::E
              type: List<E<dynamic>>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::v
                      element: <testLibraryFragment>::@enum::E::@getter::v#element
                      staticType: E<double>
                  rightBracket: ] @0
                  staticType: List<E<dynamic>>
          constructors
            const @37
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              enclosingElement3: <testLibraryFragment>::@enum::E
              parameters
                requiredPositional a @41
                  type: T
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: E<double>
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: List<E<dynamic>>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          element: <testLibraryFragment>::@enum::E#element
          typeParameters
            T @7
              element: <not-implemented>
          fields
            enumConstant v @14
              reference: <testLibraryFragment>::@enum::E::@field::v
              element: <testLibraryFragment>::@enum::E::@field::v#element
              getter2: <testLibraryFragment>::@enum::E::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              element: <testLibraryFragment>::@enum::E::@field::values#element
              getter2: <testLibraryFragment>::@enum::E::@getter::values
          constructors
            const new @37
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              element: <testLibraryFragment>::@enum::E::@constructor::new#element
              formalParameters
                a @41
                  element: <testLibraryFragment>::@enum::E::@constructor::new::@parameter::a#element
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              element: <testLibraryFragment>::@enum::E::@getter::v#element
            get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              element: <testLibraryFragment>::@enum::E::@getter::values#element
  enums
    enum E
      firstFragment: <testLibraryFragment>::@enum::E
      typeParameters
        T
      supertype: Enum
      fields
        static const v
          firstFragment: <testLibraryFragment>::@enum::E::@field::v
          type: E<double>
          getter: <testLibraryFragment>::@enum::E::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
          type: List<E<dynamic>>
          getter: <testLibraryFragment>::@enum::E::@getter::values#element
      constructors
        const new
          firstFragment: <testLibraryFragment>::@enum::E::@constructor::new
          formalParameters
            requiredPositional a
              type: T
      getters
        synthetic static get v
          firstFragment: <testLibraryFragment>::@enum::E::@getter::v
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::E::@getter::values
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
      enclosingElement3: <null>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          enclosingElement3: <testLibraryFragment>
          supertype: Enum
          fields
            static const enumConstant _ @11
              reference: <testLibraryFragment>::@enum::E::@field::_
              enclosingElement3: <testLibraryFragment>::@enum::E
              type: E
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E
                      element2: <testLibraryFragment>::@enum::E#element
                      type: E
                    staticElement: <testLibraryFragment>::@enum::E::@constructor::new
                    element: <testLibraryFragment>::@enum::E::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              enclosingElement3: <testLibraryFragment>::@enum::E
              type: List<E>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: _ @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::_
                      element: <testLibraryFragment>::@enum::E::@getter::_#element
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              enclosingElement3: <testLibraryFragment>::@enum::E
          accessors
            synthetic static get _ @-1
              reference: <testLibraryFragment>::@enum::E::@getter::_
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: E
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: List<E>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          element: <testLibraryFragment>::@enum::E#element
          fields
            enumConstant _ @11
              reference: <testLibraryFragment>::@enum::E::@field::_
              element: <testLibraryFragment>::@enum::E::@field::_#element
              getter2: <testLibraryFragment>::@enum::E::@getter::_
            values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              element: <testLibraryFragment>::@enum::E::@field::values#element
              getter2: <testLibraryFragment>::@enum::E::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              element: <testLibraryFragment>::@enum::E::@constructor::new#element
          getters
            get _ @-1
              reference: <testLibraryFragment>::@enum::E::@getter::_
              element: <testLibraryFragment>::@enum::E::@getter::_#element
            get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              element: <testLibraryFragment>::@enum::E::@getter::values#element
  enums
    enum E
      firstFragment: <testLibraryFragment>::@enum::E
      supertype: Enum
      fields
        static const _
          firstFragment: <testLibraryFragment>::@enum::E::@field::_
          type: E
          getter: <testLibraryFragment>::@enum::E::@getter::_#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
          type: List<E>
          getter: <testLibraryFragment>::@enum::E::@getter::values#element
      constructors
        synthetic const new
          firstFragment: <testLibraryFragment>::@enum::E::@constructor::new
      getters
        synthetic static get _
          firstFragment: <testLibraryFragment>::@enum::E::@getter::_
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::E::@getter::values
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
      enclosingElement3: <null>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          enclosingElement3: <testLibraryFragment>
          supertype: Enum
          fields
            static const enumConstant v @11
              reference: <testLibraryFragment>::@enum::E::@field::v
              enclosingElement3: <testLibraryFragment>::@enum::E
              type: E
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E
                      element2: <testLibraryFragment>::@enum::E#element
                      type: E
                    staticElement: <testLibraryFragment>::@enum::E::@constructor::new
                    element: <testLibraryFragment>::@enum::E::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              enclosingElement3: <testLibraryFragment>::@enum::E
              type: List<E>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::v
                      element: <testLibraryFragment>::@enum::E::@getter::v#element
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
          constructors
            factory named @26
              reference: <testLibraryFragment>::@enum::E::@constructor::named
              enclosingElement3: <testLibraryFragment>::@enum::E
              periodOffset: 25
              nameEnd: 31
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              enclosingElement3: <testLibraryFragment>::@enum::E
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: E
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: List<E>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          element: <testLibraryFragment>::@enum::E#element
          fields
            enumConstant v @11
              reference: <testLibraryFragment>::@enum::E::@field::v
              element: <testLibraryFragment>::@enum::E::@field::v#element
              getter2: <testLibraryFragment>::@enum::E::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              element: <testLibraryFragment>::@enum::E::@field::values#element
              getter2: <testLibraryFragment>::@enum::E::@getter::values
          constructors
            factory named @26
              reference: <testLibraryFragment>::@enum::E::@constructor::named
              element: <testLibraryFragment>::@enum::E::@constructor::named#element
              periodOffset: 25
              nameEnd: 31
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              element: <testLibraryFragment>::@enum::E::@constructor::new#element
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              element: <testLibraryFragment>::@enum::E::@getter::v#element
            get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              element: <testLibraryFragment>::@enum::E::@getter::values#element
  enums
    enum E
      firstFragment: <testLibraryFragment>::@enum::E
      supertype: Enum
      fields
        static const v
          firstFragment: <testLibraryFragment>::@enum::E::@field::v
          type: E
          getter: <testLibraryFragment>::@enum::E::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
          type: List<E>
          getter: <testLibraryFragment>::@enum::E::@getter::values#element
      constructors
        factory named
          firstFragment: <testLibraryFragment>::@enum::E::@constructor::named
        synthetic const new
          firstFragment: <testLibraryFragment>::@enum::E::@constructor::new
      getters
        synthetic static get v
          firstFragment: <testLibraryFragment>::@enum::E::@getter::v
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::E::@getter::values
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
      enclosingElement3: <null>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          enclosingElement3: <testLibraryFragment>
          supertype: Enum
          fields
            static const enumConstant v @11
              reference: <testLibraryFragment>::@enum::E::@field::v
              enclosingElement3: <testLibraryFragment>::@enum::E
              type: E
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E
                      element2: <testLibraryFragment>::@enum::E#element
                      type: E
                    staticElement: <testLibraryFragment>::@enum::E::@constructor::new
                    element: <testLibraryFragment>::@enum::E::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              enclosingElement3: <testLibraryFragment>::@enum::E
              type: List<E>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::v
                      element: <testLibraryFragment>::@enum::E::@getter::v#element
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
          constructors
            factory @24
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              enclosingElement3: <testLibraryFragment>::@enum::E
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: E
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: List<E>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          element: <testLibraryFragment>::@enum::E#element
          fields
            enumConstant v @11
              reference: <testLibraryFragment>::@enum::E::@field::v
              element: <testLibraryFragment>::@enum::E::@field::v#element
              getter2: <testLibraryFragment>::@enum::E::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              element: <testLibraryFragment>::@enum::E::@field::values#element
              getter2: <testLibraryFragment>::@enum::E::@getter::values
          constructors
            factory new @24
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              element: <testLibraryFragment>::@enum::E::@constructor::new#element
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              element: <testLibraryFragment>::@enum::E::@getter::v#element
            get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              element: <testLibraryFragment>::@enum::E::@getter::values#element
  enums
    enum E
      firstFragment: <testLibraryFragment>::@enum::E
      supertype: Enum
      fields
        static const v
          firstFragment: <testLibraryFragment>::@enum::E::@field::v
          type: E
          getter: <testLibraryFragment>::@enum::E::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
          type: List<E>
          getter: <testLibraryFragment>::@enum::E::@getter::values#element
      constructors
        factory new
          firstFragment: <testLibraryFragment>::@enum::E::@constructor::new
      getters
        synthetic static get v
          firstFragment: <testLibraryFragment>::@enum::E::@getter::v
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::E::@getter::values
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
      enclosingElement3: <null>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          enclosingElement3: <testLibraryFragment>
          supertype: Enum
          fields
            static const enumConstant v @11
              reference: <testLibraryFragment>::@enum::E::@field::v
              enclosingElement3: <testLibraryFragment>::@enum::E
              type: E
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E
                      element2: <testLibraryFragment>::@enum::E#element
                      type: E
                    staticElement: <testLibraryFragment>::@enum::E::@constructor::new
                    element: <testLibraryFragment>::@enum::E::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              enclosingElement3: <testLibraryFragment>::@enum::E
              type: List<E>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::v
                      element: <testLibraryFragment>::@enum::E::@getter::v#element
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
            final x @22
              reference: <testLibraryFragment>::@enum::E::@field::x
              enclosingElement3: <testLibraryFragment>::@enum::E
              type: dynamic
          constructors
            const @33
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              enclosingElement3: <testLibraryFragment>::@enum::E
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
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: E
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: List<E>
            synthetic get x @-1
              reference: <testLibraryFragment>::@enum::E::@getter::x
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: dynamic
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          element: <testLibraryFragment>::@enum::E#element
          fields
            enumConstant v @11
              reference: <testLibraryFragment>::@enum::E::@field::v
              element: <testLibraryFragment>::@enum::E::@field::v#element
              getter2: <testLibraryFragment>::@enum::E::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              element: <testLibraryFragment>::@enum::E::@field::values#element
              getter2: <testLibraryFragment>::@enum::E::@getter::values
            x @22
              reference: <testLibraryFragment>::@enum::E::@field::x
              element: <testLibraryFragment>::@enum::E::@field::x#element
              getter2: <testLibraryFragment>::@enum::E::@getter::x
          constructors
            const new @33
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              element: <testLibraryFragment>::@enum::E::@constructor::new#element
              formalParameters
                this.x @44
                  element: <testLibraryFragment>::@enum::E::@constructor::new::@parameter::x#element
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              element: <testLibraryFragment>::@enum::E::@getter::v#element
            get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              element: <testLibraryFragment>::@enum::E::@getter::values#element
            get x @-1
              reference: <testLibraryFragment>::@enum::E::@getter::x
              element: <testLibraryFragment>::@enum::E::@getter::x#element
  enums
    enum E
      firstFragment: <testLibraryFragment>::@enum::E
      supertype: Enum
      fields
        static const v
          firstFragment: <testLibraryFragment>::@enum::E::@field::v
          type: E
          getter: <testLibraryFragment>::@enum::E::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
          type: List<E>
          getter: <testLibraryFragment>::@enum::E::@getter::values#element
        final x
          firstFragment: <testLibraryFragment>::@enum::E::@field::x
          type: dynamic
          getter: <testLibraryFragment>::@enum::E::@getter::x#element
      constructors
        const new
          firstFragment: <testLibraryFragment>::@enum::E::@constructor::new
          formalParameters
            requiredPositional final x
              type: int Function(double)
              formalParameters
                requiredPositional a
                  type: double
      getters
        synthetic static get v
          firstFragment: <testLibraryFragment>::@enum::E::@getter::v
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::E::@getter::values
        synthetic get x
          firstFragment: <testLibraryFragment>::@enum::E::@getter::x
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
      enclosingElement3: <null>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          enclosingElement3: <testLibraryFragment>
          supertype: Enum
          fields
            static const enumConstant v @11
              reference: <testLibraryFragment>::@enum::E::@field::v
              enclosingElement3: <testLibraryFragment>::@enum::E
              type: E
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E
                      element2: <testLibraryFragment>::@enum::E#element
                      type: E
                    staticElement: <testLibraryFragment>::@enum::E::@constructor::new
                    element: <testLibraryFragment>::@enum::E::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              enclosingElement3: <testLibraryFragment>::@enum::E
              type: List<E>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::v
                      element: <testLibraryFragment>::@enum::E::@getter::v#element
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
            final x @26
              reference: <testLibraryFragment>::@enum::E::@field::x::@def::0
              enclosingElement3: <testLibraryFragment>::@enum::E
              type: int
            final x @44
              reference: <testLibraryFragment>::@enum::E::@field::x::@def::1
              enclosingElement3: <testLibraryFragment>::@enum::E
              type: String
          constructors
            const @55
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              enclosingElement3: <testLibraryFragment>::@enum::E
              parameters
                requiredPositional final this.x @62
                  type: int
                  field: <testLibraryFragment>::@enum::E::@field::x::@def::0
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: E
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: List<E>
            synthetic get x @-1
              reference: <testLibraryFragment>::@enum::E::@getter::x::@def::0
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: int
            synthetic get x @-1
              reference: <testLibraryFragment>::@enum::E::@getter::x::@def::1
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: String
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          element: <testLibraryFragment>::@enum::E#element
          fields
            enumConstant v @11
              reference: <testLibraryFragment>::@enum::E::@field::v
              element: <testLibraryFragment>::@enum::E::@field::v#element
              getter2: <testLibraryFragment>::@enum::E::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              element: <testLibraryFragment>::@enum::E::@field::values#element
              getter2: <testLibraryFragment>::@enum::E::@getter::values
            x @26
              reference: <testLibraryFragment>::@enum::E::@field::x::@def::0
              element: <testLibraryFragment>::@enum::E::@field::x::@def::0#element
              getter2: <testLibraryFragment>::@enum::E::@getter::x::@def::0
            x @44
              reference: <testLibraryFragment>::@enum::E::@field::x::@def::1
              element: <testLibraryFragment>::@enum::E::@field::x::@def::1#element
              getter2: <testLibraryFragment>::@enum::E::@getter::x::@def::1
          constructors
            const new @55
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              element: <testLibraryFragment>::@enum::E::@constructor::new#element
              formalParameters
                this.x @62
                  element: <testLibraryFragment>::@enum::E::@constructor::new::@parameter::x#element
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              element: <testLibraryFragment>::@enum::E::@getter::v#element
            get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              element: <testLibraryFragment>::@enum::E::@getter::values#element
            get x @-1
              reference: <testLibraryFragment>::@enum::E::@getter::x::@def::0
              element: <testLibraryFragment>::@enum::E::@getter::x::@def::0#element
            get x @-1
              reference: <testLibraryFragment>::@enum::E::@getter::x::@def::1
              element: <testLibraryFragment>::@enum::E::@getter::x::@def::1#element
  enums
    enum E
      firstFragment: <testLibraryFragment>::@enum::E
      supertype: Enum
      fields
        static const v
          firstFragment: <testLibraryFragment>::@enum::E::@field::v
          type: E
          getter: <testLibraryFragment>::@enum::E::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
          type: List<E>
          getter: <testLibraryFragment>::@enum::E::@getter::values#element
        final x
          firstFragment: <testLibraryFragment>::@enum::E::@field::x::@def::0
          type: int
          getter: <testLibraryFragment>::@enum::E::@getter::x::@def::0#element
        final x
          firstFragment: <testLibraryFragment>::@enum::E::@field::x::@def::1
          type: String
          getter: <testLibraryFragment>::@enum::E::@getter::x::@def::1#element
      constructors
        const new
          firstFragment: <testLibraryFragment>::@enum::E::@constructor::new
          formalParameters
            requiredPositional final x
              type: int
      getters
        synthetic static get v
          firstFragment: <testLibraryFragment>::@enum::E::@getter::v
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::E::@getter::values
        synthetic get x
          firstFragment: <testLibraryFragment>::@enum::E::@getter::x::@def::0
        synthetic get x
          firstFragment: <testLibraryFragment>::@enum::E::@getter::x::@def::1
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
      enclosingElement3: <null>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          enclosingElement3: <testLibraryFragment>
          supertype: Enum
          fields
            static const enumConstant v @11
              reference: <testLibraryFragment>::@enum::E::@field::v
              enclosingElement3: <testLibraryFragment>::@enum::E
              type: E
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E
                      element2: <testLibraryFragment>::@enum::E#element
                      type: E
                    staticElement: <testLibraryFragment>::@enum::E::@constructor::new
                    element: <testLibraryFragment>::@enum::E::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              enclosingElement3: <testLibraryFragment>::@enum::E
              type: List<E>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::v
                      element: <testLibraryFragment>::@enum::E::@getter::v#element
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
          constructors
            const @22
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              enclosingElement3: <testLibraryFragment>::@enum::E
              parameters
                requiredPositional final this.x @29
                  type: dynamic
                  field: <null>
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: E
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: List<E>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          element: <testLibraryFragment>::@enum::E#element
          fields
            enumConstant v @11
              reference: <testLibraryFragment>::@enum::E::@field::v
              element: <testLibraryFragment>::@enum::E::@field::v#element
              getter2: <testLibraryFragment>::@enum::E::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              element: <testLibraryFragment>::@enum::E::@field::values#element
              getter2: <testLibraryFragment>::@enum::E::@getter::values
          constructors
            const new @22
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              element: <testLibraryFragment>::@enum::E::@constructor::new#element
              formalParameters
                this.x @29
                  element: <testLibraryFragment>::@enum::E::@constructor::new::@parameter::x#element
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              element: <testLibraryFragment>::@enum::E::@getter::v#element
            get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              element: <testLibraryFragment>::@enum::E::@getter::values#element
  enums
    enum E
      firstFragment: <testLibraryFragment>::@enum::E
      supertype: Enum
      fields
        static const v
          firstFragment: <testLibraryFragment>::@enum::E::@field::v
          type: E
          getter: <testLibraryFragment>::@enum::E::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
          type: List<E>
          getter: <testLibraryFragment>::@enum::E::@getter::values#element
      constructors
        const new
          firstFragment: <testLibraryFragment>::@enum::E::@constructor::new
          formalParameters
            requiredPositional final x
              type: dynamic
      getters
        synthetic static get v
          firstFragment: <testLibraryFragment>::@enum::E::@getter::v
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::E::@getter::values
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
      enclosingElement3: <null>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          enclosingElement3: <testLibraryFragment>
          supertype: Enum
          fields
            static const enumConstant v @11
              reference: <testLibraryFragment>::@enum::E::@field::v
              enclosingElement3: <testLibraryFragment>::@enum::E
              type: E
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E
                      element2: <testLibraryFragment>::@enum::E#element
                      type: E
                    staticElement: <testLibraryFragment>::@enum::E::@constructor::new
                    element: <testLibraryFragment>::@enum::E::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              enclosingElement3: <testLibraryFragment>::@enum::E
              type: List<E>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::v
                      element: <testLibraryFragment>::@enum::E::@getter::v#element
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
            final x @26
              reference: <testLibraryFragment>::@enum::E::@field::x
              enclosingElement3: <testLibraryFragment>::@enum::E
              type: int
          constructors
            const @37
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              enclosingElement3: <testLibraryFragment>::@enum::E
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
                      element: dart:core::<fragment>::@class::num::@method::+#element
                      staticInvokeType: num Function(num)
                      staticType: int
                  field: <testLibraryFragment>::@enum::E::@field::x
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: E
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: List<E>
            synthetic get x @-1
              reference: <testLibraryFragment>::@enum::E::@getter::x
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          element: <testLibraryFragment>::@enum::E#element
          fields
            enumConstant v @11
              reference: <testLibraryFragment>::@enum::E::@field::v
              element: <testLibraryFragment>::@enum::E::@field::v#element
              getter2: <testLibraryFragment>::@enum::E::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              element: <testLibraryFragment>::@enum::E::@field::values#element
              getter2: <testLibraryFragment>::@enum::E::@getter::values
            x @26
              reference: <testLibraryFragment>::@enum::E::@field::x
              element: <testLibraryFragment>::@enum::E::@field::x#element
              getter2: <testLibraryFragment>::@enum::E::@getter::x
          constructors
            const new @37
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              element: <testLibraryFragment>::@enum::E::@constructor::new#element
              formalParameters
                default this.x @45
                  reference: <testLibraryFragment>::@enum::E::@constructor::new::@parameter::x
                  element: <testLibraryFragment>::@enum::E::@constructor::new::@parameter::x#element
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              element: <testLibraryFragment>::@enum::E::@getter::v#element
            get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              element: <testLibraryFragment>::@enum::E::@getter::values#element
            get x @-1
              reference: <testLibraryFragment>::@enum::E::@getter::x
              element: <testLibraryFragment>::@enum::E::@getter::x#element
  enums
    enum E
      firstFragment: <testLibraryFragment>::@enum::E
      supertype: Enum
      fields
        static const v
          firstFragment: <testLibraryFragment>::@enum::E::@field::v
          type: E
          getter: <testLibraryFragment>::@enum::E::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
          type: List<E>
          getter: <testLibraryFragment>::@enum::E::@getter::values#element
        final x
          firstFragment: <testLibraryFragment>::@enum::E::@field::x
          type: int
          getter: <testLibraryFragment>::@enum::E::@getter::x#element
      constructors
        const new
          firstFragment: <testLibraryFragment>::@enum::E::@constructor::new
          formalParameters
            optionalNamed final x
              firstFragment: <testLibraryFragment>::@enum::E::@constructor::new::@parameter::x
              type: int
      getters
        synthetic static get v
          firstFragment: <testLibraryFragment>::@enum::E::@getter::v
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::E::@getter::values
        synthetic get x
          firstFragment: <testLibraryFragment>::@enum::E::@getter::x
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
      enclosingElement3: <null>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          enclosingElement3: <testLibraryFragment>
          supertype: Enum
          fields
            static const enumConstant v @11
              reference: <testLibraryFragment>::@enum::E::@field::v
              enclosingElement3: <testLibraryFragment>::@enum::E
              type: E
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E
                      element2: <testLibraryFragment>::@enum::E#element
                      type: E
                    staticElement: <testLibraryFragment>::@enum::E::@constructor::new
                    element: <testLibraryFragment>::@enum::E::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              enclosingElement3: <testLibraryFragment>::@enum::E
              type: List<E>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::v
                      element: <testLibraryFragment>::@enum::E::@getter::v#element
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
            final x @26
              reference: <testLibraryFragment>::@enum::E::@field::x
              enclosingElement3: <testLibraryFragment>::@enum::E
              type: num
          constructors
            const @37
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              enclosingElement3: <testLibraryFragment>::@enum::E
              parameters
                requiredPositional final this.x @48
                  type: int
                  field: <testLibraryFragment>::@enum::E::@field::x
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: E
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: List<E>
            synthetic get x @-1
              reference: <testLibraryFragment>::@enum::E::@getter::x
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: num
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          element: <testLibraryFragment>::@enum::E#element
          fields
            enumConstant v @11
              reference: <testLibraryFragment>::@enum::E::@field::v
              element: <testLibraryFragment>::@enum::E::@field::v#element
              getter2: <testLibraryFragment>::@enum::E::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              element: <testLibraryFragment>::@enum::E::@field::values#element
              getter2: <testLibraryFragment>::@enum::E::@getter::values
            x @26
              reference: <testLibraryFragment>::@enum::E::@field::x
              element: <testLibraryFragment>::@enum::E::@field::x#element
              getter2: <testLibraryFragment>::@enum::E::@getter::x
          constructors
            const new @37
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              element: <testLibraryFragment>::@enum::E::@constructor::new#element
              formalParameters
                this.x @48
                  element: <testLibraryFragment>::@enum::E::@constructor::new::@parameter::x#element
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              element: <testLibraryFragment>::@enum::E::@getter::v#element
            get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              element: <testLibraryFragment>::@enum::E::@getter::values#element
            get x @-1
              reference: <testLibraryFragment>::@enum::E::@getter::x
              element: <testLibraryFragment>::@enum::E::@getter::x#element
  enums
    enum E
      firstFragment: <testLibraryFragment>::@enum::E
      supertype: Enum
      fields
        static const v
          firstFragment: <testLibraryFragment>::@enum::E::@field::v
          type: E
          getter: <testLibraryFragment>::@enum::E::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
          type: List<E>
          getter: <testLibraryFragment>::@enum::E::@getter::values#element
        final x
          firstFragment: <testLibraryFragment>::@enum::E::@field::x
          type: num
          getter: <testLibraryFragment>::@enum::E::@getter::x#element
      constructors
        const new
          firstFragment: <testLibraryFragment>::@enum::E::@constructor::new
          formalParameters
            requiredPositional final x
              type: int
      getters
        synthetic static get v
          firstFragment: <testLibraryFragment>::@enum::E::@getter::v
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::E::@getter::values
        synthetic get x
          firstFragment: <testLibraryFragment>::@enum::E::@getter::x
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
      enclosingElement3: <null>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          enclosingElement3: <testLibraryFragment>
          supertype: Enum
          fields
            static const enumConstant v @11
              reference: <testLibraryFragment>::@enum::E::@field::v
              enclosingElement3: <testLibraryFragment>::@enum::E
              type: E
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E
                      element2: <testLibraryFragment>::@enum::E#element
                      type: E
                    staticElement: <testLibraryFragment>::@enum::E::@constructor::new
                    element: <testLibraryFragment>::@enum::E::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              enclosingElement3: <testLibraryFragment>::@enum::E
              type: List<E>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::v
                      element: <testLibraryFragment>::@enum::E::@getter::v#element
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
            final x @22
              reference: <testLibraryFragment>::@enum::E::@field::x
              enclosingElement3: <testLibraryFragment>::@enum::E
              type: dynamic
          constructors
            @27
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              enclosingElement3: <testLibraryFragment>::@enum::E
              parameters
                requiredPositional final this.x @38
                  type: int
                  field: <testLibraryFragment>::@enum::E::@field::x
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: E
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: List<E>
            synthetic get x @-1
              reference: <testLibraryFragment>::@enum::E::@getter::x
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: dynamic
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          element: <testLibraryFragment>::@enum::E#element
          fields
            enumConstant v @11
              reference: <testLibraryFragment>::@enum::E::@field::v
              element: <testLibraryFragment>::@enum::E::@field::v#element
              getter2: <testLibraryFragment>::@enum::E::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              element: <testLibraryFragment>::@enum::E::@field::values#element
              getter2: <testLibraryFragment>::@enum::E::@getter::values
            x @22
              reference: <testLibraryFragment>::@enum::E::@field::x
              element: <testLibraryFragment>::@enum::E::@field::x#element
              getter2: <testLibraryFragment>::@enum::E::@getter::x
          constructors
            new @27
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              element: <testLibraryFragment>::@enum::E::@constructor::new#element
              formalParameters
                this.x @38
                  element: <testLibraryFragment>::@enum::E::@constructor::new::@parameter::x#element
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              element: <testLibraryFragment>::@enum::E::@getter::v#element
            get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              element: <testLibraryFragment>::@enum::E::@getter::values#element
            get x @-1
              reference: <testLibraryFragment>::@enum::E::@getter::x
              element: <testLibraryFragment>::@enum::E::@getter::x#element
  enums
    enum E
      firstFragment: <testLibraryFragment>::@enum::E
      supertype: Enum
      fields
        static const v
          firstFragment: <testLibraryFragment>::@enum::E::@field::v
          type: E
          getter: <testLibraryFragment>::@enum::E::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
          type: List<E>
          getter: <testLibraryFragment>::@enum::E::@getter::values#element
        final x
          firstFragment: <testLibraryFragment>::@enum::E::@field::x
          type: dynamic
          getter: <testLibraryFragment>::@enum::E::@getter::x#element
      constructors
        new
          firstFragment: <testLibraryFragment>::@enum::E::@constructor::new
          formalParameters
            requiredPositional final x
              type: int
      getters
        synthetic static get v
          firstFragment: <testLibraryFragment>::@enum::E::@getter::v
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::E::@getter::values
        synthetic get x
          firstFragment: <testLibraryFragment>::@enum::E::@getter::x
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
      enclosingElement3: <null>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          enclosingElement3: <testLibraryFragment>
          supertype: Enum
          fields
            static const enumConstant v @11
              reference: <testLibraryFragment>::@enum::E::@field::v
              enclosingElement3: <testLibraryFragment>::@enum::E
              type: E
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E
                      element2: <testLibraryFragment>::@enum::E#element
                      type: E
                    staticElement: <testLibraryFragment>::@enum::E::@constructor::new
                    element: <testLibraryFragment>::@enum::E::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              enclosingElement3: <testLibraryFragment>::@enum::E
              type: List<E>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::v
                      element: <testLibraryFragment>::@enum::E::@getter::v#element
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
            final x @22
              reference: <testLibraryFragment>::@enum::E::@field::x
              enclosingElement3: <testLibraryFragment>::@enum::E
              type: dynamic
          constructors
            @27
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              enclosingElement3: <testLibraryFragment>::@enum::E
              parameters
                requiredPositional final this.x @34
                  type: dynamic
                  field: <testLibraryFragment>::@enum::E::@field::x
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: E
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: List<E>
            synthetic get x @-1
              reference: <testLibraryFragment>::@enum::E::@getter::x
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: dynamic
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          element: <testLibraryFragment>::@enum::E#element
          fields
            enumConstant v @11
              reference: <testLibraryFragment>::@enum::E::@field::v
              element: <testLibraryFragment>::@enum::E::@field::v#element
              getter2: <testLibraryFragment>::@enum::E::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              element: <testLibraryFragment>::@enum::E::@field::values#element
              getter2: <testLibraryFragment>::@enum::E::@getter::values
            x @22
              reference: <testLibraryFragment>::@enum::E::@field::x
              element: <testLibraryFragment>::@enum::E::@field::x#element
              getter2: <testLibraryFragment>::@enum::E::@getter::x
          constructors
            new @27
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              element: <testLibraryFragment>::@enum::E::@constructor::new#element
              formalParameters
                this.x @34
                  element: <testLibraryFragment>::@enum::E::@constructor::new::@parameter::x#element
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              element: <testLibraryFragment>::@enum::E::@getter::v#element
            get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              element: <testLibraryFragment>::@enum::E::@getter::values#element
            get x @-1
              reference: <testLibraryFragment>::@enum::E::@getter::x
              element: <testLibraryFragment>::@enum::E::@getter::x#element
  enums
    enum E
      firstFragment: <testLibraryFragment>::@enum::E
      supertype: Enum
      fields
        static const v
          firstFragment: <testLibraryFragment>::@enum::E::@field::v
          type: E
          getter: <testLibraryFragment>::@enum::E::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
          type: List<E>
          getter: <testLibraryFragment>::@enum::E::@getter::values#element
        final x
          firstFragment: <testLibraryFragment>::@enum::E::@field::x
          type: dynamic
          getter: <testLibraryFragment>::@enum::E::@getter::x#element
      constructors
        new
          firstFragment: <testLibraryFragment>::@enum::E::@constructor::new
          formalParameters
            requiredPositional final x
              type: dynamic
      getters
        synthetic static get v
          firstFragment: <testLibraryFragment>::@enum::E::@getter::v
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::E::@getter::values
        synthetic get x
          firstFragment: <testLibraryFragment>::@enum::E::@getter::x
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
      enclosingElement3: <null>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          enclosingElement3: <testLibraryFragment>
          supertype: Enum
          fields
            static const enumConstant v @11
              reference: <testLibraryFragment>::@enum::E::@field::v
              enclosingElement3: <testLibraryFragment>::@enum::E
              type: E
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E
                      element2: <testLibraryFragment>::@enum::E#element
                      type: E
                    period: . @0
                    name: SimpleIdentifier
                      token: named @-1
                      staticElement: <testLibraryFragment>::@enum::E::@constructor::named
                      element: <testLibraryFragment>::@enum::E::@constructor::named#element
                      staticType: null
                    staticElement: <testLibraryFragment>::@enum::E::@constructor::named
                    element: <testLibraryFragment>::@enum::E::@constructor::named#element
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
              enclosingElement3: <testLibraryFragment>::@enum::E
              type: List<E>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::v
                      element: <testLibraryFragment>::@enum::E::@getter::v#element
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
          constructors
            const named @34
              reference: <testLibraryFragment>::@enum::E::@constructor::named
              enclosingElement3: <testLibraryFragment>::@enum::E
              periodOffset: 33
              nameEnd: 39
              parameters
                requiredPositional a @44
                  type: int
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: E
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: List<E>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          element: <testLibraryFragment>::@enum::E#element
          fields
            enumConstant v @11
              reference: <testLibraryFragment>::@enum::E::@field::v
              element: <testLibraryFragment>::@enum::E::@field::v#element
              getter2: <testLibraryFragment>::@enum::E::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              element: <testLibraryFragment>::@enum::E::@field::values#element
              getter2: <testLibraryFragment>::@enum::E::@getter::values
          constructors
            const named @34
              reference: <testLibraryFragment>::@enum::E::@constructor::named
              element: <testLibraryFragment>::@enum::E::@constructor::named#element
              periodOffset: 33
              nameEnd: 39
              formalParameters
                a @44
                  element: <testLibraryFragment>::@enum::E::@constructor::named::@parameter::a#element
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              element: <testLibraryFragment>::@enum::E::@getter::v#element
            get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              element: <testLibraryFragment>::@enum::E::@getter::values#element
  enums
    enum E
      firstFragment: <testLibraryFragment>::@enum::E
      supertype: Enum
      fields
        static const v
          firstFragment: <testLibraryFragment>::@enum::E::@field::v
          type: E
          getter: <testLibraryFragment>::@enum::E::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
          type: List<E>
          getter: <testLibraryFragment>::@enum::E::@getter::values#element
      constructors
        const named
          firstFragment: <testLibraryFragment>::@enum::E::@constructor::named
          formalParameters
            requiredPositional a
              type: int
      getters
        synthetic static get v
          firstFragment: <testLibraryFragment>::@enum::E::@getter::v
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::E::@getter::values
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
      enclosingElement3: <null>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          enclosingElement3: <testLibraryFragment>
          supertype: Enum
          fields
            static const enumConstant v @11
              reference: <testLibraryFragment>::@enum::E::@field::v
              enclosingElement3: <testLibraryFragment>::@enum::E
              type: E
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E
                      element2: <testLibraryFragment>::@enum::E#element
                      type: E
                    staticElement: <testLibraryFragment>::@enum::E::@constructor::new
                    element: <testLibraryFragment>::@enum::E::@constructor::new#element
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
              enclosingElement3: <testLibraryFragment>::@enum::E
              type: List<E>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::v
                      element: <testLibraryFragment>::@enum::E::@getter::v#element
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
          constructors
            const @26
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              enclosingElement3: <testLibraryFragment>::@enum::E
              parameters
                requiredPositional a @32
                  type: int
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: E
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: List<E>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          element: <testLibraryFragment>::@enum::E#element
          fields
            enumConstant v @11
              reference: <testLibraryFragment>::@enum::E::@field::v
              element: <testLibraryFragment>::@enum::E::@field::v#element
              getter2: <testLibraryFragment>::@enum::E::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              element: <testLibraryFragment>::@enum::E::@field::values#element
              getter2: <testLibraryFragment>::@enum::E::@getter::values
          constructors
            const new @26
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              element: <testLibraryFragment>::@enum::E::@constructor::new#element
              formalParameters
                a @32
                  element: <testLibraryFragment>::@enum::E::@constructor::new::@parameter::a#element
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              element: <testLibraryFragment>::@enum::E::@getter::v#element
            get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              element: <testLibraryFragment>::@enum::E::@getter::values#element
  enums
    enum E
      firstFragment: <testLibraryFragment>::@enum::E
      supertype: Enum
      fields
        static const v
          firstFragment: <testLibraryFragment>::@enum::E::@field::v
          type: E
          getter: <testLibraryFragment>::@enum::E::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
          type: List<E>
          getter: <testLibraryFragment>::@enum::E::@getter::values#element
      constructors
        const new
          firstFragment: <testLibraryFragment>::@enum::E::@constructor::new
          formalParameters
            requiredPositional a
              type: int
      getters
        synthetic static get v
          firstFragment: <testLibraryFragment>::@enum::E::@getter::v
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::E::@getter::values
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
      enclosingElement3: <null>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant T @7
              defaultType: dynamic
          supertype: Enum
          fields
            static const enumConstant v @14
              reference: <testLibraryFragment>::@enum::E::@field::v
              enclosingElement3: <testLibraryFragment>::@enum::E
              type: E<dynamic>
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E
                      element2: <testLibraryFragment>::@enum::E#element
                      type: E<dynamic>
                    staticElement: ConstructorMember
                      base: <testLibraryFragment>::@enum::E::@constructor::new
                      substitution: {T: dynamic}
                    element: <testLibraryFragment>::@enum::E::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E<dynamic>
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              enclosingElement3: <testLibraryFragment>::@enum::E
              type: List<E<dynamic>>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::v
                      element: <testLibraryFragment>::@enum::E::@getter::v#element
                      staticType: E<dynamic>
                  rightBracket: ] @0
                  staticType: List<E<dynamic>>
            final x @29
              reference: <testLibraryFragment>::@enum::E::@field::x
              enclosingElement3: <testLibraryFragment>::@enum::E
              type: int
          constructors
            const @40
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              enclosingElement3: <testLibraryFragment>::@enum::E
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
                      element: <testLibraryFragment>::@enum::E::@constructor::new::@parameter::a#element
                      staticType: T?
                    isOperator: is @59
                    type: NamedType
                      name: T @62
                      element: T@7
                      element2: <not-implemented>
                      type: T
                    staticType: bool
                  rightParenthesis: ) @63
                ConstructorFieldInitializer
                  fieldName: SimpleIdentifier
                    token: x @66
                    staticElement: <testLibraryFragment>::@enum::E::@field::x
                    element: <testLibraryFragment>::@enum::E::@field::x#element
                    staticType: null
                  equals: = @68
                  expression: IntegerLiteral
                    literal: 0 @70
                    staticType: int
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: E<dynamic>
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: List<E<dynamic>>
            synthetic get x @-1
              reference: <testLibraryFragment>::@enum::E::@getter::x
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          element: <testLibraryFragment>::@enum::E#element
          typeParameters
            T @7
              element: <not-implemented>
          fields
            enumConstant v @14
              reference: <testLibraryFragment>::@enum::E::@field::v
              element: <testLibraryFragment>::@enum::E::@field::v#element
              getter2: <testLibraryFragment>::@enum::E::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              element: <testLibraryFragment>::@enum::E::@field::values#element
              getter2: <testLibraryFragment>::@enum::E::@getter::values
            x @29
              reference: <testLibraryFragment>::@enum::E::@field::x
              element: <testLibraryFragment>::@enum::E::@field::x#element
              getter2: <testLibraryFragment>::@enum::E::@getter::x
          constructors
            const new @40
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              element: <testLibraryFragment>::@enum::E::@constructor::new#element
              formalParameters
                a @45
                  element: <testLibraryFragment>::@enum::E::@constructor::new::@parameter::a#element
              constantInitializers
                AssertInitializer
                  assertKeyword: assert @50
                  leftParenthesis: ( @56
                  condition: IsExpression
                    expression: SimpleIdentifier
                      token: a @57
                      staticElement: <testLibraryFragment>::@enum::E::@constructor::new::@parameter::a
                      element: <testLibraryFragment>::@enum::E::@constructor::new::@parameter::a#element
                      staticType: T?
                    isOperator: is @59
                    type: NamedType
                      name: T @62
                      element: T@7
                      element2: <not-implemented>
                      type: T
                    staticType: bool
                  rightParenthesis: ) @63
                ConstructorFieldInitializer
                  fieldName: SimpleIdentifier
                    token: x @66
                    staticElement: <testLibraryFragment>::@enum::E::@field::x
                    element: <testLibraryFragment>::@enum::E::@field::x#element
                    staticType: null
                  equals: = @68
                  expression: IntegerLiteral
                    literal: 0 @70
                    staticType: int
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              element: <testLibraryFragment>::@enum::E::@getter::v#element
            get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              element: <testLibraryFragment>::@enum::E::@getter::values#element
            get x @-1
              reference: <testLibraryFragment>::@enum::E::@getter::x
              element: <testLibraryFragment>::@enum::E::@getter::x#element
  enums
    enum E
      firstFragment: <testLibraryFragment>::@enum::E
      typeParameters
        T
      supertype: Enum
      fields
        static const v
          firstFragment: <testLibraryFragment>::@enum::E::@field::v
          type: E<dynamic>
          getter: <testLibraryFragment>::@enum::E::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
          type: List<E<dynamic>>
          getter: <testLibraryFragment>::@enum::E::@getter::values#element
        final x
          firstFragment: <testLibraryFragment>::@enum::E::@field::x
          type: int
          getter: <testLibraryFragment>::@enum::E::@getter::x#element
      constructors
        const new
          firstFragment: <testLibraryFragment>::@enum::E::@constructor::new
          formalParameters
            requiredPositional a
              type: T?
      getters
        synthetic static get v
          firstFragment: <testLibraryFragment>::@enum::E::@getter::v
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::E::@getter::values
        synthetic get x
          firstFragment: <testLibraryFragment>::@enum::E::@getter::x
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
      enclosingElement3: <null>
      enums
        enum E @65
          reference: <testLibraryFragment>::@enum::E
          enclosingElement3: <testLibraryFragment>
          documentationComment: /**\n * Docs\n */
          supertype: Enum
          fields
            static const enumConstant v @69
              reference: <testLibraryFragment>::@enum::E::@field::v
              enclosingElement3: <testLibraryFragment>::@enum::E
              type: E
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E
                      element2: <testLibraryFragment>::@enum::E#element
                      type: E
                    staticElement: <testLibraryFragment>::@enum::E::@constructor::new
                    element: <testLibraryFragment>::@enum::E::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              enclosingElement3: <testLibraryFragment>::@enum::E
              type: List<E>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::v
                      element: <testLibraryFragment>::@enum::E::@getter::v#element
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              enclosingElement3: <testLibraryFragment>::@enum::E
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: E
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: List<E>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      enums
        enum E @65
          reference: <testLibraryFragment>::@enum::E
          element: <testLibraryFragment>::@enum::E#element
          fields
            enumConstant v @69
              reference: <testLibraryFragment>::@enum::E::@field::v
              element: <testLibraryFragment>::@enum::E::@field::v#element
              getter2: <testLibraryFragment>::@enum::E::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              element: <testLibraryFragment>::@enum::E::@field::values#element
              getter2: <testLibraryFragment>::@enum::E::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              element: <testLibraryFragment>::@enum::E::@constructor::new#element
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              element: <testLibraryFragment>::@enum::E::@getter::v#element
            get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              element: <testLibraryFragment>::@enum::E::@getter::values#element
  enums
    enum E
      firstFragment: <testLibraryFragment>::@enum::E
      documentationComment: /**\n * Docs\n */
      supertype: Enum
      fields
        static const v
          firstFragment: <testLibraryFragment>::@enum::E::@field::v
          type: E
          getter: <testLibraryFragment>::@enum::E::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
          type: List<E>
          getter: <testLibraryFragment>::@enum::E::@getter::values#element
      constructors
        synthetic const new
          firstFragment: <testLibraryFragment>::@enum::E::@constructor::new
      getters
        synthetic static get v
          firstFragment: <testLibraryFragment>::@enum::E::@getter::v
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::E::@getter::values
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
      enclosingElement3: <null>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          enclosingElement3: <testLibraryFragment>
          supertype: Enum
          fields
            static const enumConstant v @11
              reference: <testLibraryFragment>::@enum::E::@field::v
              enclosingElement3: <testLibraryFragment>::@enum::E
              type: E
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E
                      element2: <testLibraryFragment>::@enum::E#element
                      type: E
                    staticElement: <testLibraryFragment>::@enum::E::@constructor::new
                    element: <testLibraryFragment>::@enum::E::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              enclosingElement3: <testLibraryFragment>::@enum::E
              type: List<E>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::v
                      element: <testLibraryFragment>::@enum::E::@getter::v#element
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
            final foo @22
              reference: <testLibraryFragment>::@enum::E::@field::foo
              enclosingElement3: <testLibraryFragment>::@enum::E
              type: int
              shouldUseTypeForInitializerInference: false
              constantInitializer
                IntegerLiteral
                  literal: 42 @28
                  staticType: int
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              enclosingElement3: <testLibraryFragment>::@enum::E
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: E
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: List<E>
            synthetic get foo @-1
              reference: <testLibraryFragment>::@enum::E::@getter::foo
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          element: <testLibraryFragment>::@enum::E#element
          fields
            enumConstant v @11
              reference: <testLibraryFragment>::@enum::E::@field::v
              element: <testLibraryFragment>::@enum::E::@field::v#element
              getter2: <testLibraryFragment>::@enum::E::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              element: <testLibraryFragment>::@enum::E::@field::values#element
              getter2: <testLibraryFragment>::@enum::E::@getter::values
            foo @22
              reference: <testLibraryFragment>::@enum::E::@field::foo
              element: <testLibraryFragment>::@enum::E::@field::foo#element
              getter2: <testLibraryFragment>::@enum::E::@getter::foo
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              element: <testLibraryFragment>::@enum::E::@constructor::new#element
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              element: <testLibraryFragment>::@enum::E::@getter::v#element
            get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              element: <testLibraryFragment>::@enum::E::@getter::values#element
            get foo @-1
              reference: <testLibraryFragment>::@enum::E::@getter::foo
              element: <testLibraryFragment>::@enum::E::@getter::foo#element
  enums
    enum E
      firstFragment: <testLibraryFragment>::@enum::E
      supertype: Enum
      fields
        static const v
          firstFragment: <testLibraryFragment>::@enum::E::@field::v
          type: E
          getter: <testLibraryFragment>::@enum::E::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
          type: List<E>
          getter: <testLibraryFragment>::@enum::E::@getter::values#element
        final foo
          firstFragment: <testLibraryFragment>::@enum::E::@field::foo
          type: int
          getter: <testLibraryFragment>::@enum::E::@getter::foo#element
      constructors
        synthetic const new
          firstFragment: <testLibraryFragment>::@enum::E::@constructor::new
      getters
        synthetic static get v
          firstFragment: <testLibraryFragment>::@enum::E::@getter::v
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::E::@getter::values
        synthetic get foo
          firstFragment: <testLibraryFragment>::@enum::E::@getter::foo
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
      enclosingElement3: <null>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          enclosingElement3: <testLibraryFragment>
          supertype: Enum
          fields
            final promotable _foo @33
              reference: <testLibraryFragment>::@enum::E::@field::_foo
              enclosingElement3: <testLibraryFragment>::@enum::E
              type: int?
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          element: <testLibraryFragment>::@enum::E#element
          fields
            promotable _foo @33
              reference: <testLibraryFragment>::@enum::E::@field::_foo
              element: <testLibraryFragment>::@enum::E::@field::_foo#element
              getter2: <testLibraryFragment>::@enum::E::@getter::_foo
  enums
    enum E
      firstFragment: <testLibraryFragment>::@enum::E
      supertype: Enum
      fields
        static const v
          firstFragment: <testLibraryFragment>::@enum::E::@field::v
          type: E
          getter: <testLibraryFragment>::@enum::E::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
          type: List<E>
          getter: <testLibraryFragment>::@enum::E::@getter::values#element
        final _foo
          firstFragment: <testLibraryFragment>::@enum::E::@field::_foo
          type: int?
          getter: <testLibraryFragment>::@enum::E::@getter::_foo#element
      constructors
        new
          firstFragment: <testLibraryFragment>::@enum::E::@constructor::new
          formalParameters
            requiredPositional final _foo
              type: int?
      getters
        synthetic static get v
          firstFragment: <testLibraryFragment>::@enum::E::@getter::v
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::E::@getter::values
        synthetic get _foo
          firstFragment: <testLibraryFragment>::@enum::E::@getter::_foo
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
      enclosingElement3: <null>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          enclosingElement3: <testLibraryFragment>
          supertype: Enum
          fields
            static const enumConstant v @10
              reference: <testLibraryFragment>::@enum::E::@field::v
              enclosingElement3: <testLibraryFragment>::@enum::E
              type: E
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E
                      element2: <testLibraryFragment>::@enum::E#element
                      type: E
                    staticElement: <testLibraryFragment>::@enum::E::@constructor::new
                    element: <testLibraryFragment>::@enum::E::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              enclosingElement3: <testLibraryFragment>::@enum::E
              type: List<E>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::v
                      element: <testLibraryFragment>::@enum::E::@getter::v#element
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
            synthetic foo @-1
              reference: <testLibraryFragment>::@enum::E::@field::foo
              enclosingElement3: <testLibraryFragment>::@enum::E
              type: int
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              enclosingElement3: <testLibraryFragment>::@enum::E
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: E
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: List<E>
            get foo @23
              reference: <testLibraryFragment>::@enum::E::@getter::foo
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          element: <testLibraryFragment>::@enum::E#element
          fields
            enumConstant v @10
              reference: <testLibraryFragment>::@enum::E::@field::v
              element: <testLibraryFragment>::@enum::E::@field::v#element
              getter2: <testLibraryFragment>::@enum::E::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              element: <testLibraryFragment>::@enum::E::@field::values#element
              getter2: <testLibraryFragment>::@enum::E::@getter::values
            foo @-1
              reference: <testLibraryFragment>::@enum::E::@field::foo
              element: <testLibraryFragment>::@enum::E::@field::foo#element
              getter2: <testLibraryFragment>::@enum::E::@getter::foo
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              element: <testLibraryFragment>::@enum::E::@constructor::new#element
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              element: <testLibraryFragment>::@enum::E::@getter::v#element
            get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              element: <testLibraryFragment>::@enum::E::@getter::values#element
            get foo @23
              reference: <testLibraryFragment>::@enum::E::@getter::foo
              element: <testLibraryFragment>::@enum::E::@getter::foo#element
  enums
    enum E
      firstFragment: <testLibraryFragment>::@enum::E
      supertype: Enum
      fields
        static const v
          firstFragment: <testLibraryFragment>::@enum::E::@field::v
          type: E
          getter: <testLibraryFragment>::@enum::E::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
          type: List<E>
          getter: <testLibraryFragment>::@enum::E::@getter::values#element
        synthetic foo
          firstFragment: <testLibraryFragment>::@enum::E::@field::foo
          type: int
          getter: <testLibraryFragment>::@enum::E::@getter::foo#element
      constructors
        synthetic const new
          firstFragment: <testLibraryFragment>::@enum::E::@constructor::new
      getters
        synthetic static get v
          firstFragment: <testLibraryFragment>::@enum::E::@getter::v
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::E::@getter::values
        get foo
          firstFragment: <testLibraryFragment>::@enum::E::@getter::foo
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
      enclosingElement3: <null>
      classes
        class I @6
          reference: <testLibraryFragment>::@class::I
          enclosingElement3: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::I::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::I
      enums
        enum E @16
          reference: <testLibraryFragment>::@enum::E
          enclosingElement3: <testLibraryFragment>
          supertype: Enum
          interfaces
            I
          fields
            static const enumConstant v @35
              reference: <testLibraryFragment>::@enum::E::@field::v
              enclosingElement3: <testLibraryFragment>::@enum::E
              type: E
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E
                      element2: <testLibraryFragment>::@enum::E#element
                      type: E
                    staticElement: <testLibraryFragment>::@enum::E::@constructor::new
                    element: <testLibraryFragment>::@enum::E::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              enclosingElement3: <testLibraryFragment>::@enum::E
              type: List<E>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::v
                      element: <testLibraryFragment>::@enum::E::@getter::v#element
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              enclosingElement3: <testLibraryFragment>::@enum::E
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: E
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: List<E>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class I @6
          reference: <testLibraryFragment>::@class::I
          element: <testLibraryFragment>::@class::I#element
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::I::@constructor::new
              element: <testLibraryFragment>::@class::I::@constructor::new#element
      enums
        enum E @16
          reference: <testLibraryFragment>::@enum::E
          element: <testLibraryFragment>::@enum::E#element
          fields
            enumConstant v @35
              reference: <testLibraryFragment>::@enum::E::@field::v
              element: <testLibraryFragment>::@enum::E::@field::v#element
              getter2: <testLibraryFragment>::@enum::E::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              element: <testLibraryFragment>::@enum::E::@field::values#element
              getter2: <testLibraryFragment>::@enum::E::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              element: <testLibraryFragment>::@enum::E::@constructor::new#element
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              element: <testLibraryFragment>::@enum::E::@getter::v#element
            get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              element: <testLibraryFragment>::@enum::E::@getter::values#element
  classes
    class I
      firstFragment: <testLibraryFragment>::@class::I
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::I::@constructor::new
  enums
    enum E
      firstFragment: <testLibraryFragment>::@enum::E
      supertype: Enum
      fields
        static const v
          firstFragment: <testLibraryFragment>::@enum::E::@field::v
          type: E
          getter: <testLibraryFragment>::@enum::E::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
          type: List<E>
          getter: <testLibraryFragment>::@enum::E::@getter::values#element
      constructors
        synthetic const new
          firstFragment: <testLibraryFragment>::@enum::E::@constructor::new
      getters
        synthetic static get v
          firstFragment: <testLibraryFragment>::@enum::E::@getter::v
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::E::@getter::values
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
      enclosingElement3: <null>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
        class C @45
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
      enums
        enum E @55
          reference: <testLibraryFragment>::@enum::E
          enclosingElement3: <testLibraryFragment>
          supertype: Enum
          interfaces
            A
            C
          fields
            static const enumConstant v @78
              reference: <testLibraryFragment>::@enum::E::@field::v
              enclosingElement3: <testLibraryFragment>::@enum::E
              type: E
              shouldUseTypeForInitializerInference: false
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              enclosingElement3: <testLibraryFragment>::@enum::E
              type: List<E>
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: E
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: List<E>
      extensionTypes
        B @26
          reference: <testLibraryFragment>::@extensionType::B
          enclosingElement3: <testLibraryFragment>
          representation: <testLibraryFragment>::@extensionType::B::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::B::@constructor::new
          typeErasure: int
          fields
            final it @32
              reference: <testLibraryFragment>::@extensionType::B::@field::it
              enclosingElement3: <testLibraryFragment>::@extensionType::B
              type: int
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::B::@getter::it
              enclosingElement3: <testLibraryFragment>::@extensionType::B
              returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A#element
        class C @45
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C#element
      enums
        enum E @55
          reference: <testLibraryFragment>::@enum::E
          element: <testLibraryFragment>::@enum::E#element
          fields
            enumConstant v @78
              reference: <testLibraryFragment>::@enum::E::@field::v
              element: <testLibraryFragment>::@enum::E::@field::v#element
              getter2: <testLibraryFragment>::@enum::E::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              element: <testLibraryFragment>::@enum::E::@field::values#element
              getter2: <testLibraryFragment>::@enum::E::@getter::values
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              element: <testLibraryFragment>::@enum::E::@getter::v#element
            get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              element: <testLibraryFragment>::@enum::E::@getter::values#element
      extensionTypes
        extension type B @26
          reference: <testLibraryFragment>::@extensionType::B
          element: <testLibraryFragment>::@extensionType::B#element
          fields
            it @32
              reference: <testLibraryFragment>::@extensionType::B::@field::it
              element: <testLibraryFragment>::@extensionType::B::@field::it#element
              getter2: <testLibraryFragment>::@extensionType::B::@getter::it
          getters
            get it @-1
              reference: <testLibraryFragment>::@extensionType::B::@getter::it
              element: <testLibraryFragment>::@extensionType::B::@getter::it#element
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
    class C
      firstFragment: <testLibraryFragment>::@class::C
  enums
    enum E
      firstFragment: <testLibraryFragment>::@enum::E
      supertype: Enum
      fields
        static const v
          firstFragment: <testLibraryFragment>::@enum::E::@field::v
          type: E
          getter: <testLibraryFragment>::@enum::E::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
          type: List<E>
          getter: <testLibraryFragment>::@enum::E::@getter::values#element
      getters
        synthetic static get v
          firstFragment: <testLibraryFragment>::@enum::E::@getter::v
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::E::@getter::values
  extensionTypes
    extension type B
      firstFragment: <testLibraryFragment>::@extensionType::B
      typeErasure: int
      fields
        final it
          firstFragment: <testLibraryFragment>::@extensionType::B::@field::it
          type: int
          getter: <testLibraryFragment>::@extensionType::B::@getter::it#element
      getters
        synthetic get it
          firstFragment: <testLibraryFragment>::@extensionType::B::@getter::it
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
      enclosingElement3: <null>
      classes
        class I @6
          reference: <testLibraryFragment>::@class::I
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant T @8
              defaultType: dynamic
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::I::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::I
      enums
        enum E @19
          reference: <testLibraryFragment>::@enum::E
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant U @21
              defaultType: dynamic
          supertype: Enum
          interfaces
            I<U>
          fields
            static const enumConstant v @44
              reference: <testLibraryFragment>::@enum::E::@field::v
              enclosingElement3: <testLibraryFragment>::@enum::E
              type: E<dynamic>
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E
                      element2: <testLibraryFragment>::@enum::E#element
                      type: E<dynamic>
                    staticElement: ConstructorMember
                      base: <testLibraryFragment>::@enum::E::@constructor::new
                      substitution: {U: dynamic}
                    element: <testLibraryFragment>::@enum::E::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E<dynamic>
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              enclosingElement3: <testLibraryFragment>::@enum::E
              type: List<E<dynamic>>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::v
                      element: <testLibraryFragment>::@enum::E::@getter::v#element
                      staticType: E<dynamic>
                  rightBracket: ] @0
                  staticType: List<E<dynamic>>
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              enclosingElement3: <testLibraryFragment>::@enum::E
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: E<dynamic>
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: List<E<dynamic>>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class I @6
          reference: <testLibraryFragment>::@class::I
          element: <testLibraryFragment>::@class::I#element
          typeParameters
            T @8
              element: <not-implemented>
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::I::@constructor::new
              element: <testLibraryFragment>::@class::I::@constructor::new#element
      enums
        enum E @19
          reference: <testLibraryFragment>::@enum::E
          element: <testLibraryFragment>::@enum::E#element
          typeParameters
            U @21
              element: <not-implemented>
          fields
            enumConstant v @44
              reference: <testLibraryFragment>::@enum::E::@field::v
              element: <testLibraryFragment>::@enum::E::@field::v#element
              getter2: <testLibraryFragment>::@enum::E::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              element: <testLibraryFragment>::@enum::E::@field::values#element
              getter2: <testLibraryFragment>::@enum::E::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              element: <testLibraryFragment>::@enum::E::@constructor::new#element
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              element: <testLibraryFragment>::@enum::E::@getter::v#element
            get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              element: <testLibraryFragment>::@enum::E::@getter::values#element
  classes
    class I
      firstFragment: <testLibraryFragment>::@class::I
      typeParameters
        T
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::I::@constructor::new
  enums
    enum E
      firstFragment: <testLibraryFragment>::@enum::E
      typeParameters
        U
      supertype: Enum
      fields
        static const v
          firstFragment: <testLibraryFragment>::@enum::E::@field::v
          type: E<dynamic>
          getter: <testLibraryFragment>::@enum::E::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
          type: List<E<dynamic>>
          getter: <testLibraryFragment>::@enum::E::@getter::values#element
      constructors
        synthetic const new
          firstFragment: <testLibraryFragment>::@enum::E::@constructor::new
      getters
        synthetic static get v
          firstFragment: <testLibraryFragment>::@enum::E::@getter::v
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::E::@getter::values
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
      enclosingElement3: <null>
      classes
        class X @6
          reference: <testLibraryFragment>::@class::X
          enclosingElement3: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::X::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::X
        class Z @17
          reference: <testLibraryFragment>::@class::Z
          enclosingElement3: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::Z::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::Z
      enums
        enum E @27
          reference: <testLibraryFragment>::@enum::E
          enclosingElement3: <testLibraryFragment>
          supertype: Enum
          interfaces
            X
            Z
          fields
            static const enumConstant v @52
              reference: <testLibraryFragment>::@enum::E::@field::v
              enclosingElement3: <testLibraryFragment>::@enum::E
              type: E
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E
                      element2: <testLibraryFragment>::@enum::E#element
                      type: E
                    staticElement: <testLibraryFragment>::@enum::E::@constructor::new
                    element: <testLibraryFragment>::@enum::E::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              enclosingElement3: <testLibraryFragment>::@enum::E
              type: List<E>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::v
                      element: <testLibraryFragment>::@enum::E::@getter::v#element
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              enclosingElement3: <testLibraryFragment>::@enum::E
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: E
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: List<E>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class X @6
          reference: <testLibraryFragment>::@class::X
          element: <testLibraryFragment>::@class::X#element
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::X::@constructor::new
              element: <testLibraryFragment>::@class::X::@constructor::new#element
        class Z @17
          reference: <testLibraryFragment>::@class::Z
          element: <testLibraryFragment>::@class::Z#element
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::Z::@constructor::new
              element: <testLibraryFragment>::@class::Z::@constructor::new#element
      enums
        enum E @27
          reference: <testLibraryFragment>::@enum::E
          element: <testLibraryFragment>::@enum::E#element
          fields
            enumConstant v @52
              reference: <testLibraryFragment>::@enum::E::@field::v
              element: <testLibraryFragment>::@enum::E::@field::v#element
              getter2: <testLibraryFragment>::@enum::E::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              element: <testLibraryFragment>::@enum::E::@field::values#element
              getter2: <testLibraryFragment>::@enum::E::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              element: <testLibraryFragment>::@enum::E::@constructor::new#element
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              element: <testLibraryFragment>::@enum::E::@getter::v#element
            get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              element: <testLibraryFragment>::@enum::E::@getter::values#element
  classes
    class X
      firstFragment: <testLibraryFragment>::@class::X
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::X::@constructor::new
    class Z
      firstFragment: <testLibraryFragment>::@class::Z
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::Z::@constructor::new
  enums
    enum E
      firstFragment: <testLibraryFragment>::@enum::E
      supertype: Enum
      fields
        static const v
          firstFragment: <testLibraryFragment>::@enum::E::@field::v
          type: E
          getter: <testLibraryFragment>::@enum::E::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
          type: List<E>
          getter: <testLibraryFragment>::@enum::E::@getter::values#element
      constructors
        synthetic const new
          firstFragment: <testLibraryFragment>::@enum::E::@constructor::new
      getters
        synthetic static get v
          firstFragment: <testLibraryFragment>::@enum::E::@getter::v
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::E::@getter::values
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
      enclosingElement3: <null>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant T @7
              defaultType: dynamic
          supertype: Enum
          fields
            static const enumConstant v @14
              reference: <testLibraryFragment>::@enum::E::@field::v
              enclosingElement3: <testLibraryFragment>::@enum::E
              type: E<dynamic>
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E
                      element2: <testLibraryFragment>::@enum::E#element
                      type: E<dynamic>
                    staticElement: ConstructorMember
                      base: <testLibraryFragment>::@enum::E::@constructor::new
                      substitution: {T: dynamic}
                    element: <testLibraryFragment>::@enum::E::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E<dynamic>
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              enclosingElement3: <testLibraryFragment>::@enum::E
              type: List<E<dynamic>>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::v
                      element: <testLibraryFragment>::@enum::E::@getter::v#element
                      staticType: E<dynamic>
                  rightBracket: ] @0
                  staticType: List<E<dynamic>>
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              enclosingElement3: <testLibraryFragment>::@enum::E
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: E<dynamic>
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: List<E<dynamic>>
          methods
            foo @23
              reference: <testLibraryFragment>::@enum::E::@method::foo
              enclosingElement3: <testLibraryFragment>::@enum::E
              typeParameters
                covariant U @27
                  defaultType: dynamic
              parameters
                requiredPositional t @32
                  type: T
                requiredPositional u @37
                  type: U
              returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          element: <testLibraryFragment>::@enum::E#element
          typeParameters
            T @7
              element: <not-implemented>
          fields
            enumConstant v @14
              reference: <testLibraryFragment>::@enum::E::@field::v
              element: <testLibraryFragment>::@enum::E::@field::v#element
              getter2: <testLibraryFragment>::@enum::E::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              element: <testLibraryFragment>::@enum::E::@field::values#element
              getter2: <testLibraryFragment>::@enum::E::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              element: <testLibraryFragment>::@enum::E::@constructor::new#element
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              element: <testLibraryFragment>::@enum::E::@getter::v#element
            get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              element: <testLibraryFragment>::@enum::E::@getter::values#element
          methods
            foo @23
              reference: <testLibraryFragment>::@enum::E::@method::foo
              element: <testLibraryFragment>::@enum::E::@method::foo#element
              typeParameters
                U @27
                  element: <not-implemented>
              formalParameters
                t @32
                  element: <testLibraryFragment>::@enum::E::@method::foo::@parameter::t#element
                u @37
                  element: <testLibraryFragment>::@enum::E::@method::foo::@parameter::u#element
  enums
    enum E
      firstFragment: <testLibraryFragment>::@enum::E
      typeParameters
        T
      supertype: Enum
      fields
        static const v
          firstFragment: <testLibraryFragment>::@enum::E::@field::v
          type: E<dynamic>
          getter: <testLibraryFragment>::@enum::E::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
          type: List<E<dynamic>>
          getter: <testLibraryFragment>::@enum::E::@getter::values#element
      constructors
        synthetic const new
          firstFragment: <testLibraryFragment>::@enum::E::@constructor::new
      getters
        synthetic static get v
          firstFragment: <testLibraryFragment>::@enum::E::@getter::v
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::E::@getter::values
      methods
        foo
          firstFragment: <testLibraryFragment>::@enum::E::@method::foo
          typeParameters
            U
          formalParameters
            requiredPositional t
              type: T
            requiredPositional u
              type: U
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
      enclosingElement3: <null>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          enclosingElement3: <testLibraryFragment>
          supertype: Enum
          fields
            static const enumConstant v @11
              reference: <testLibraryFragment>::@enum::E::@field::v
              enclosingElement3: <testLibraryFragment>::@enum::E
              type: E
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E
                      element2: <testLibraryFragment>::@enum::E#element
                      type: E
                    staticElement: <testLibraryFragment>::@enum::E::@constructor::new
                    element: <testLibraryFragment>::@enum::E::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              enclosingElement3: <testLibraryFragment>::@enum::E
              type: List<E>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::v
                      element: <testLibraryFragment>::@enum::E::@getter::v#element
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              enclosingElement3: <testLibraryFragment>::@enum::E
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: E
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: List<E>
          methods
            toString @23
              reference: <testLibraryFragment>::@enum::E::@method::toString
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: String
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          element: <testLibraryFragment>::@enum::E#element
          fields
            enumConstant v @11
              reference: <testLibraryFragment>::@enum::E::@field::v
              element: <testLibraryFragment>::@enum::E::@field::v#element
              getter2: <testLibraryFragment>::@enum::E::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              element: <testLibraryFragment>::@enum::E::@field::values#element
              getter2: <testLibraryFragment>::@enum::E::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              element: <testLibraryFragment>::@enum::E::@constructor::new#element
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              element: <testLibraryFragment>::@enum::E::@getter::v#element
            get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              element: <testLibraryFragment>::@enum::E::@getter::values#element
          methods
            toString @23
              reference: <testLibraryFragment>::@enum::E::@method::toString
              element: <testLibraryFragment>::@enum::E::@method::toString#element
  enums
    enum E
      firstFragment: <testLibraryFragment>::@enum::E
      supertype: Enum
      fields
        static const v
          firstFragment: <testLibraryFragment>::@enum::E::@field::v
          type: E
          getter: <testLibraryFragment>::@enum::E::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
          type: List<E>
          getter: <testLibraryFragment>::@enum::E::@getter::values#element
      constructors
        synthetic const new
          firstFragment: <testLibraryFragment>::@enum::E::@constructor::new
      getters
        synthetic static get v
          firstFragment: <testLibraryFragment>::@enum::E::@getter::v
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::E::@getter::values
      methods
        toString
          firstFragment: <testLibraryFragment>::@enum::E::@method::toString
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
      enclosingElement3: <null>
      enums
        enum E @16
          reference: <testLibraryFragment>::@enum::E
          enclosingElement3: <testLibraryFragment>
          supertype: Enum
          mixins
            M
          fields
            static const enumConstant v @29
              reference: <testLibraryFragment>::@enum::E::@field::v
              enclosingElement3: <testLibraryFragment>::@enum::E
              type: E
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E
                      element2: <testLibraryFragment>::@enum::E#element
                      type: E
                    staticElement: <testLibraryFragment>::@enum::E::@constructor::new
                    element: <testLibraryFragment>::@enum::E::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              enclosingElement3: <testLibraryFragment>::@enum::E
              type: List<E>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::v
                      element: <testLibraryFragment>::@enum::E::@getter::v#element
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              enclosingElement3: <testLibraryFragment>::@enum::E
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: E
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: List<E>
      mixins
        mixin M @6
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
      enums
        enum E @16
          reference: <testLibraryFragment>::@enum::E
          element: <testLibraryFragment>::@enum::E#element
          fields
            enumConstant v @29
              reference: <testLibraryFragment>::@enum::E::@field::v
              element: <testLibraryFragment>::@enum::E::@field::v#element
              getter2: <testLibraryFragment>::@enum::E::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              element: <testLibraryFragment>::@enum::E::@field::values#element
              getter2: <testLibraryFragment>::@enum::E::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              element: <testLibraryFragment>::@enum::E::@constructor::new#element
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              element: <testLibraryFragment>::@enum::E::@getter::v#element
            get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              element: <testLibraryFragment>::@enum::E::@getter::values#element
      mixins
        mixin M @6
          reference: <testLibraryFragment>::@mixin::M
          element: <testLibraryFragment>::@mixin::M#element
  enums
    enum E
      firstFragment: <testLibraryFragment>::@enum::E
      supertype: Enum
      fields
        static const v
          firstFragment: <testLibraryFragment>::@enum::E::@field::v
          type: E
          getter: <testLibraryFragment>::@enum::E::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
          type: List<E>
          getter: <testLibraryFragment>::@enum::E::@getter::values#element
      constructors
        synthetic const new
          firstFragment: <testLibraryFragment>::@enum::E::@constructor::new
      getters
        synthetic static get v
          firstFragment: <testLibraryFragment>::@enum::E::@getter::v
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::E::@getter::values
  mixins
    mixin M
      firstFragment: <testLibraryFragment>::@mixin::M
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
      enclosingElement3: <null>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
        class C @45
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
      enums
        enum E @55
          reference: <testLibraryFragment>::@enum::E
          enclosingElement3: <testLibraryFragment>
          supertype: Enum
          mixins
            A
            C
          fields
            static const enumConstant v @72
              reference: <testLibraryFragment>::@enum::E::@field::v
              enclosingElement3: <testLibraryFragment>::@enum::E
              type: E
              shouldUseTypeForInitializerInference: false
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              enclosingElement3: <testLibraryFragment>::@enum::E
              type: List<E>
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: E
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: List<E>
      extensionTypes
        B @26
          reference: <testLibraryFragment>::@extensionType::B
          enclosingElement3: <testLibraryFragment>
          representation: <testLibraryFragment>::@extensionType::B::@field::it
          primaryConstructor: <testLibraryFragment>::@extensionType::B::@constructor::new
          typeErasure: int
          fields
            final it @32
              reference: <testLibraryFragment>::@extensionType::B::@field::it
              enclosingElement3: <testLibraryFragment>::@extensionType::B
              type: int
          accessors
            synthetic get it @-1
              reference: <testLibraryFragment>::@extensionType::B::@getter::it
              enclosingElement3: <testLibraryFragment>::@extensionType::B
              returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A#element
        class C @45
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C#element
      enums
        enum E @55
          reference: <testLibraryFragment>::@enum::E
          element: <testLibraryFragment>::@enum::E#element
          fields
            enumConstant v @72
              reference: <testLibraryFragment>::@enum::E::@field::v
              element: <testLibraryFragment>::@enum::E::@field::v#element
              getter2: <testLibraryFragment>::@enum::E::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              element: <testLibraryFragment>::@enum::E::@field::values#element
              getter2: <testLibraryFragment>::@enum::E::@getter::values
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              element: <testLibraryFragment>::@enum::E::@getter::v#element
            get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              element: <testLibraryFragment>::@enum::E::@getter::values#element
      extensionTypes
        extension type B @26
          reference: <testLibraryFragment>::@extensionType::B
          element: <testLibraryFragment>::@extensionType::B#element
          fields
            it @32
              reference: <testLibraryFragment>::@extensionType::B::@field::it
              element: <testLibraryFragment>::@extensionType::B::@field::it#element
              getter2: <testLibraryFragment>::@extensionType::B::@getter::it
          getters
            get it @-1
              reference: <testLibraryFragment>::@extensionType::B::@getter::it
              element: <testLibraryFragment>::@extensionType::B::@getter::it#element
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
    class C
      firstFragment: <testLibraryFragment>::@class::C
  enums
    enum E
      firstFragment: <testLibraryFragment>::@enum::E
      supertype: Enum
      fields
        static const v
          firstFragment: <testLibraryFragment>::@enum::E::@field::v
          type: E
          getter: <testLibraryFragment>::@enum::E::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
          type: List<E>
          getter: <testLibraryFragment>::@enum::E::@getter::values#element
      getters
        synthetic static get v
          firstFragment: <testLibraryFragment>::@enum::E::@getter::v
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::E::@getter::values
  extensionTypes
    extension type B
      firstFragment: <testLibraryFragment>::@extensionType::B
      typeErasure: int
      fields
        final it
          firstFragment: <testLibraryFragment>::@extensionType::B::@field::it
          type: int
          getter: <testLibraryFragment>::@extensionType::B::@getter::it#element
      getters
        synthetic get it
          firstFragment: <testLibraryFragment>::@extensionType::B::@getter::it
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
      enclosingElement3: <null>
      enums
        enum E @44
          reference: <testLibraryFragment>::@enum::E
          enclosingElement3: <testLibraryFragment>
          supertype: Enum
          mixins
            M1<int>
            M2<int>
          fields
            static const enumConstant v @67
              reference: <testLibraryFragment>::@enum::E::@field::v
              enclosingElement3: <testLibraryFragment>::@enum::E
              type: E
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E
                      element2: <testLibraryFragment>::@enum::E#element
                      type: E
                    staticElement: <testLibraryFragment>::@enum::E::@constructor::new
                    element: <testLibraryFragment>::@enum::E::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              enclosingElement3: <testLibraryFragment>::@enum::E
              type: List<E>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::v
                      element: <testLibraryFragment>::@enum::E::@getter::v#element
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              enclosingElement3: <testLibraryFragment>::@enum::E
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: E
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: List<E>
      mixins
        mixin M1 @6
          reference: <testLibraryFragment>::@mixin::M1
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant T @9
              defaultType: dynamic
          superclassConstraints
            Object
        mixin M2 @21
          reference: <testLibraryFragment>::@mixin::M2
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant T @24
              defaultType: dynamic
          superclassConstraints
            M1<T>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      enums
        enum E @44
          reference: <testLibraryFragment>::@enum::E
          element: <testLibraryFragment>::@enum::E#element
          fields
            enumConstant v @67
              reference: <testLibraryFragment>::@enum::E::@field::v
              element: <testLibraryFragment>::@enum::E::@field::v#element
              getter2: <testLibraryFragment>::@enum::E::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              element: <testLibraryFragment>::@enum::E::@field::values#element
              getter2: <testLibraryFragment>::@enum::E::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              element: <testLibraryFragment>::@enum::E::@constructor::new#element
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              element: <testLibraryFragment>::@enum::E::@getter::v#element
            get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              element: <testLibraryFragment>::@enum::E::@getter::values#element
      mixins
        mixin M1 @6
          reference: <testLibraryFragment>::@mixin::M1
          element: <testLibraryFragment>::@mixin::M1#element
          typeParameters
            T @9
              element: <not-implemented>
        mixin M2 @21
          reference: <testLibraryFragment>::@mixin::M2
          element: <testLibraryFragment>::@mixin::M2#element
          typeParameters
            T @24
              element: <not-implemented>
  enums
    enum E
      firstFragment: <testLibraryFragment>::@enum::E
      supertype: Enum
      fields
        static const v
          firstFragment: <testLibraryFragment>::@enum::E::@field::v
          type: E
          getter: <testLibraryFragment>::@enum::E::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
          type: List<E>
          getter: <testLibraryFragment>::@enum::E::@getter::values#element
      constructors
        synthetic const new
          firstFragment: <testLibraryFragment>::@enum::E::@constructor::new
      getters
        synthetic static get v
          firstFragment: <testLibraryFragment>::@enum::E::@getter::v
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::E::@getter::values
  mixins
    mixin M1
      firstFragment: <testLibraryFragment>::@mixin::M1
      typeParameters
        T
      superclassConstraints
        Object
    mixin M2
      firstFragment: <testLibraryFragment>::@mixin::M2
      typeParameters
        T
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
      enclosingElement3: <null>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          enclosingElement3: <testLibraryFragment>
          supertype: Enum
          fields
            static const enumConstant v @10
              reference: <testLibraryFragment>::@enum::E::@field::v
              enclosingElement3: <testLibraryFragment>::@enum::E
              type: E
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E
                      element2: <testLibraryFragment>::@enum::E#element
                      type: E
                    staticElement: <testLibraryFragment>::@enum::E::@constructor::new
                    element: <testLibraryFragment>::@enum::E::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              enclosingElement3: <testLibraryFragment>::@enum::E
              type: List<E>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::v
                      element: <testLibraryFragment>::@enum::E::@getter::v#element
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
            synthetic foo @-1
              reference: <testLibraryFragment>::@enum::E::@field::foo
              enclosingElement3: <testLibraryFragment>::@enum::E
              type: int
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              enclosingElement3: <testLibraryFragment>::@enum::E
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: E
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: List<E>
            set foo= @19
              reference: <testLibraryFragment>::@enum::E::@setter::foo
              enclosingElement3: <testLibraryFragment>::@enum::E
              parameters
                requiredPositional _ @27
                  type: int
              returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          element: <testLibraryFragment>::@enum::E#element
          fields
            enumConstant v @10
              reference: <testLibraryFragment>::@enum::E::@field::v
              element: <testLibraryFragment>::@enum::E::@field::v#element
              getter2: <testLibraryFragment>::@enum::E::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              element: <testLibraryFragment>::@enum::E::@field::values#element
              getter2: <testLibraryFragment>::@enum::E::@getter::values
            foo @-1
              reference: <testLibraryFragment>::@enum::E::@field::foo
              element: <testLibraryFragment>::@enum::E::@field::foo#element
              setter2: <testLibraryFragment>::@enum::E::@setter::foo
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              element: <testLibraryFragment>::@enum::E::@constructor::new#element
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              element: <testLibraryFragment>::@enum::E::@getter::v#element
            get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              element: <testLibraryFragment>::@enum::E::@getter::values#element
          setters
            set foo= @19
              reference: <testLibraryFragment>::@enum::E::@setter::foo
              element: <testLibraryFragment>::@enum::E::@setter::foo#element
              formalParameters
                _ @27
                  element: <testLibraryFragment>::@enum::E::@setter::foo::@parameter::_#element
  enums
    enum E
      firstFragment: <testLibraryFragment>::@enum::E
      supertype: Enum
      fields
        static const v
          firstFragment: <testLibraryFragment>::@enum::E::@field::v
          type: E
          getter: <testLibraryFragment>::@enum::E::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
          type: List<E>
          getter: <testLibraryFragment>::@enum::E::@getter::values#element
        synthetic foo
          firstFragment: <testLibraryFragment>::@enum::E::@field::foo
          type: int
          setter: <testLibraryFragment>::@enum::E::@setter::foo#element
      constructors
        synthetic const new
          firstFragment: <testLibraryFragment>::@enum::E::@constructor::new
      getters
        synthetic static get v
          firstFragment: <testLibraryFragment>::@enum::E::@getter::v
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::E::@getter::values
      setters
        set foo=
          firstFragment: <testLibraryFragment>::@enum::E::@setter::foo
          formalParameters
            requiredPositional _
              type: int
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
      enclosingElement3: <null>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant T @7
              defaultType: dynamic
          supertype: Enum
          fields
            static const enumConstant v @14
              reference: <testLibraryFragment>::@enum::E::@field::v
              enclosingElement3: <testLibraryFragment>::@enum::E
              type: E<dynamic>
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E
                      element2: <testLibraryFragment>::@enum::E#element
                      type: E<dynamic>
                    staticElement: ConstructorMember
                      base: <testLibraryFragment>::@enum::E::@constructor::new
                      substitution: {T: dynamic}
                    element: <testLibraryFragment>::@enum::E::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E<dynamic>
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              enclosingElement3: <testLibraryFragment>::@enum::E
              type: List<E<dynamic>>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::v
                      element: <testLibraryFragment>::@enum::E::@getter::v#element
                      staticType: E<dynamic>
                  rightBracket: ] @0
                  staticType: List<E<dynamic>>
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              enclosingElement3: <testLibraryFragment>::@enum::E
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: E<dynamic>
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: List<E<dynamic>>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          element: <testLibraryFragment>::@enum::E#element
          typeParameters
            T @7
              element: <not-implemented>
          fields
            enumConstant v @14
              reference: <testLibraryFragment>::@enum::E::@field::v
              element: <testLibraryFragment>::@enum::E::@field::v#element
              getter2: <testLibraryFragment>::@enum::E::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              element: <testLibraryFragment>::@enum::E::@field::values#element
              getter2: <testLibraryFragment>::@enum::E::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              element: <testLibraryFragment>::@enum::E::@constructor::new#element
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              element: <testLibraryFragment>::@enum::E::@getter::v#element
            get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              element: <testLibraryFragment>::@enum::E::@getter::values#element
  enums
    enum E
      firstFragment: <testLibraryFragment>::@enum::E
      typeParameters
        T
      supertype: Enum
      fields
        static const v
          firstFragment: <testLibraryFragment>::@enum::E::@field::v
          type: E<dynamic>
          getter: <testLibraryFragment>::@enum::E::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
          type: List<E<dynamic>>
          getter: <testLibraryFragment>::@enum::E::@getter::values#element
      constructors
        synthetic const new
          firstFragment: <testLibraryFragment>::@enum::E::@constructor::new
      getters
        synthetic static get v
          firstFragment: <testLibraryFragment>::@enum::E::@getter::v
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::E::@getter::values
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
      enclosingElement3: <null>
      enums
        notSimplyBounded enum E @5
          reference: <testLibraryFragment>::@enum::E
          enclosingElement3: <testLibraryFragment>
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
              enclosingElement3: <testLibraryFragment>::@enum::E
              type: E<num, num>
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E
                      element2: <testLibraryFragment>::@enum::E#element
                      type: E<num, num>
                    staticElement: ConstructorMember
                      base: <testLibraryFragment>::@enum::E::@constructor::new
                      substitution: {T: num, U: num}
                    element: <testLibraryFragment>::@enum::E::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E<num, num>
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              enclosingElement3: <testLibraryFragment>::@enum::E
              type: List<E<num, num>>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::v
                      element: <testLibraryFragment>::@enum::E::@getter::v#element
                      staticType: E<num, num>
                  rightBracket: ] @0
                  staticType: List<E<num, num>>
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              enclosingElement3: <testLibraryFragment>::@enum::E
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: E<num, num>
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: List<E<num, num>>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          element: <testLibraryFragment>::@enum::E#element
          typeParameters
            T @7
              element: <not-implemented>
            U @22
              element: <not-implemented>
          fields
            enumConstant v @39
              reference: <testLibraryFragment>::@enum::E::@field::v
              element: <testLibraryFragment>::@enum::E::@field::v#element
              getter2: <testLibraryFragment>::@enum::E::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              element: <testLibraryFragment>::@enum::E::@field::values#element
              getter2: <testLibraryFragment>::@enum::E::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              element: <testLibraryFragment>::@enum::E::@constructor::new#element
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              element: <testLibraryFragment>::@enum::E::@getter::v#element
            get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              element: <testLibraryFragment>::@enum::E::@getter::values#element
  enums
    enum E
      firstFragment: <testLibraryFragment>::@enum::E
      typeParameters
        T
          bound: num
        U
          bound: T
      supertype: Enum
      fields
        static const v
          firstFragment: <testLibraryFragment>::@enum::E::@field::v
          type: E<num, num>
          getter: <testLibraryFragment>::@enum::E::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
          type: List<E<num, num>>
          getter: <testLibraryFragment>::@enum::E::@getter::values#element
      constructors
        synthetic const new
          firstFragment: <testLibraryFragment>::@enum::E::@constructor::new
      getters
        synthetic static get v
          firstFragment: <testLibraryFragment>::@enum::E::@getter::v
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::E::@getter::values
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
      enclosingElement3: <null>
      enums
        notSimplyBounded enum E @5
          reference: <testLibraryFragment>::@enum::E
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant T @7
              bound: dynamic
              defaultType: dynamic
          supertype: Enum
          fields
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              enclosingElement3: <testLibraryFragment>::@enum::E
              type: List<E<dynamic>>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  rightBracket: ] @0
                  staticType: List<E<dynamic>>
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              enclosingElement3: <testLibraryFragment>::@enum::E
          accessors
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: List<E<dynamic>>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          element: <testLibraryFragment>::@enum::E#element
          typeParameters
            T @7
              element: <not-implemented>
          fields
            values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              element: <testLibraryFragment>::@enum::E::@field::values#element
              getter2: <testLibraryFragment>::@enum::E::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              element: <testLibraryFragment>::@enum::E::@constructor::new#element
          getters
            get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              element: <testLibraryFragment>::@enum::E::@getter::values#element
  enums
    enum E
      firstFragment: <testLibraryFragment>::@enum::E
      typeParameters
        T
          bound: dynamic
      supertype: Enum
      fields
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
          type: List<E<dynamic>>
          getter: <testLibraryFragment>::@enum::E::@getter::values#element
      constructors
        synthetic const new
          firstFragment: <testLibraryFragment>::@enum::E::@constructor::new
      getters
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::E::@getter::values
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
      enclosingElement3: <null>
      enums
        notSimplyBounded enum E @5
          reference: <testLibraryFragment>::@enum::E
          enclosingElement3: <testLibraryFragment>
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
              enclosingElement3: <testLibraryFragment>::@enum::E
              type: List<E<dynamic, num, dynamic>>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  rightBracket: ] @0
                  staticType: List<E<dynamic, num, dynamic>>
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              enclosingElement3: <testLibraryFragment>::@enum::E
          accessors
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: List<E<dynamic, num, dynamic>>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          element: <testLibraryFragment>::@enum::E#element
          typeParameters
            T @7
              element: <not-implemented>
            U @20
              element: <not-implemented>
            V @35
              element: <not-implemented>
          fields
            values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              element: <testLibraryFragment>::@enum::E::@field::values#element
              getter2: <testLibraryFragment>::@enum::E::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              element: <testLibraryFragment>::@enum::E::@constructor::new#element
          getters
            get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              element: <testLibraryFragment>::@enum::E::@getter::values#element
  enums
    enum E
      firstFragment: <testLibraryFragment>::@enum::E
      typeParameters
        T
          bound: dynamic
        U
          bound: num
        V
          bound: dynamic
      supertype: Enum
      fields
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
          type: List<E<dynamic, num, dynamic>>
          getter: <testLibraryFragment>::@enum::E::@getter::values#element
      constructors
        synthetic const new
          firstFragment: <testLibraryFragment>::@enum::E::@constructor::new
      getters
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::E::@getter::values
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
      enclosingElement3: <null>
      enums
        notSimplyBounded enum E @5
          reference: <testLibraryFragment>::@enum::E
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant T @7
              bound: void Function(E<dynamic>)
              defaultType: dynamic
          supertype: Enum
          fields
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              enclosingElement3: <testLibraryFragment>::@enum::E
              type: List<E<dynamic>>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  rightBracket: ] @0
                  staticType: List<E<dynamic>>
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              enclosingElement3: <testLibraryFragment>::@enum::E
          accessors
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: List<E<dynamic>>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          element: <testLibraryFragment>::@enum::E#element
          typeParameters
            T @7
              element: <not-implemented>
          fields
            values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              element: <testLibraryFragment>::@enum::E::@field::values#element
              getter2: <testLibraryFragment>::@enum::E::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              element: <testLibraryFragment>::@enum::E::@constructor::new#element
          getters
            get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              element: <testLibraryFragment>::@enum::E::@getter::values#element
  enums
    enum E
      firstFragment: <testLibraryFragment>::@enum::E
      typeParameters
        T
          bound: void Function(E<dynamic>)
      supertype: Enum
      fields
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
          type: List<E<dynamic>>
          getter: <testLibraryFragment>::@enum::E::@getter::values#element
      constructors
        synthetic const new
          firstFragment: <testLibraryFragment>::@enum::E::@constructor::new
      getters
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::E::@getter::values
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
      enclosingElement3: <null>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          enclosingElement3: <testLibraryFragment>
          typeParameters
            contravariant T @10
              defaultType: dynamic
          supertype: Enum
          fields
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              enclosingElement3: <testLibraryFragment>::@enum::E
              type: List<E<dynamic>>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  rightBracket: ] @0
                  staticType: List<E<dynamic>>
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              enclosingElement3: <testLibraryFragment>::@enum::E
          accessors
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: List<E<dynamic>>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          element: <testLibraryFragment>::@enum::E#element
          typeParameters
            T @10
              element: <not-implemented>
          fields
            values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              element: <testLibraryFragment>::@enum::E::@field::values#element
              getter2: <testLibraryFragment>::@enum::E::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              element: <testLibraryFragment>::@enum::E::@constructor::new#element
          getters
            get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              element: <testLibraryFragment>::@enum::E::@getter::values#element
  enums
    enum E
      firstFragment: <testLibraryFragment>::@enum::E
      typeParameters
        T
      supertype: Enum
      fields
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
          type: List<E<dynamic>>
          getter: <testLibraryFragment>::@enum::E::@getter::values#element
      constructors
        synthetic const new
          firstFragment: <testLibraryFragment>::@enum::E::@constructor::new
      getters
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::E::@getter::values
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
      enclosingElement3: <null>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant T @11
              defaultType: dynamic
          supertype: Enum
          fields
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              enclosingElement3: <testLibraryFragment>::@enum::E
              type: List<E<dynamic>>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  rightBracket: ] @0
                  staticType: List<E<dynamic>>
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              enclosingElement3: <testLibraryFragment>::@enum::E
          accessors
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: List<E<dynamic>>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          element: <testLibraryFragment>::@enum::E#element
          typeParameters
            T @11
              element: <not-implemented>
          fields
            values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              element: <testLibraryFragment>::@enum::E::@field::values#element
              getter2: <testLibraryFragment>::@enum::E::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              element: <testLibraryFragment>::@enum::E::@constructor::new#element
          getters
            get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              element: <testLibraryFragment>::@enum::E::@getter::values#element
  enums
    enum E
      firstFragment: <testLibraryFragment>::@enum::E
      typeParameters
        T
      supertype: Enum
      fields
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
          type: List<E<dynamic>>
          getter: <testLibraryFragment>::@enum::E::@getter::values#element
      constructors
        synthetic const new
          firstFragment: <testLibraryFragment>::@enum::E::@constructor::new
      getters
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::E::@getter::values
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
      enclosingElement3: <null>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          enclosingElement3: <testLibraryFragment>
          typeParameters
            invariant T @13
              defaultType: dynamic
          supertype: Enum
          fields
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              enclosingElement3: <testLibraryFragment>::@enum::E
              type: List<E<dynamic>>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  rightBracket: ] @0
                  staticType: List<E<dynamic>>
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              enclosingElement3: <testLibraryFragment>::@enum::E
          accessors
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: List<E<dynamic>>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          element: <testLibraryFragment>::@enum::E#element
          typeParameters
            T @13
              element: <not-implemented>
          fields
            values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              element: <testLibraryFragment>::@enum::E::@field::values#element
              getter2: <testLibraryFragment>::@enum::E::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              element: <testLibraryFragment>::@enum::E::@constructor::new#element
          getters
            get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              element: <testLibraryFragment>::@enum::E::@getter::values#element
  enums
    enum E
      firstFragment: <testLibraryFragment>::@enum::E
      typeParameters
        T
      supertype: Enum
      fields
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
          type: List<E<dynamic>>
          getter: <testLibraryFragment>::@enum::E::@getter::values#element
      constructors
        synthetic const new
          firstFragment: <testLibraryFragment>::@enum::E::@constructor::new
      getters
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::E::@getter::values
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
      enclosingElement3: <null>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          enclosingElement3: <testLibraryFragment>
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
              enclosingElement3: <testLibraryFragment>::@enum::E
              type: List<E<dynamic, dynamic, dynamic>>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  rightBracket: ] @0
                  staticType: List<E<dynamic, dynamic, dynamic>>
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              enclosingElement3: <testLibraryFragment>::@enum::E
          accessors
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: List<E<dynamic, dynamic, dynamic>>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          element: <testLibraryFragment>::@enum::E#element
          typeParameters
            T @13
              element: <not-implemented>
            U @19
              element: <not-implemented>
            V @26
              element: <not-implemented>
          fields
            values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              element: <testLibraryFragment>::@enum::E::@field::values#element
              getter2: <testLibraryFragment>::@enum::E::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              element: <testLibraryFragment>::@enum::E::@constructor::new#element
          getters
            get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              element: <testLibraryFragment>::@enum::E::@getter::values#element
  enums
    enum E
      firstFragment: <testLibraryFragment>::@enum::E
      typeParameters
        T
        U
        V
      supertype: Enum
      fields
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
          type: List<E<dynamic, dynamic, dynamic>>
          getter: <testLibraryFragment>::@enum::E::@getter::values#element
      constructors
        synthetic const new
          firstFragment: <testLibraryFragment>::@enum::E::@constructor::new
      getters
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::E::@getter::values
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
      enclosingElement3: <null>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          enclosingElement3: <testLibraryFragment>
          supertype: Enum
          fields
            static const enumConstant a @32
              reference: <testLibraryFragment>::@enum::E::@field::a
              enclosingElement3: <testLibraryFragment>::@enum::E
              documentationComment: /**\n   * aaa\n   */
              type: E
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E
                      element2: <testLibraryFragment>::@enum::E#element
                      type: E
                    staticElement: <testLibraryFragment>::@enum::E::@constructor::new
                    element: <testLibraryFragment>::@enum::E::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            static const enumConstant b @47
              reference: <testLibraryFragment>::@enum::E::@field::b
              enclosingElement3: <testLibraryFragment>::@enum::E
              documentationComment: /// bbb
              type: E
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E
                      element2: <testLibraryFragment>::@enum::E#element
                      type: E
                    staticElement: <testLibraryFragment>::@enum::E::@constructor::new
                    element: <testLibraryFragment>::@enum::E::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              enclosingElement3: <testLibraryFragment>::@enum::E
              type: List<E>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: a @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::a
                      element: <testLibraryFragment>::@enum::E::@getter::a#element
                      staticType: E
                    SimpleIdentifier
                      token: b @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::b
                      element: <testLibraryFragment>::@enum::E::@getter::b#element
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              enclosingElement3: <testLibraryFragment>::@enum::E
          accessors
            synthetic static get a @-1
              reference: <testLibraryFragment>::@enum::E::@getter::a
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: E
            synthetic static get b @-1
              reference: <testLibraryFragment>::@enum::E::@getter::b
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: E
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: List<E>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          element: <testLibraryFragment>::@enum::E#element
          fields
            enumConstant a @32
              reference: <testLibraryFragment>::@enum::E::@field::a
              element: <testLibraryFragment>::@enum::E::@field::a#element
              getter2: <testLibraryFragment>::@enum::E::@getter::a
            enumConstant b @47
              reference: <testLibraryFragment>::@enum::E::@field::b
              element: <testLibraryFragment>::@enum::E::@field::b#element
              getter2: <testLibraryFragment>::@enum::E::@getter::b
            values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              element: <testLibraryFragment>::@enum::E::@field::values#element
              getter2: <testLibraryFragment>::@enum::E::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              element: <testLibraryFragment>::@enum::E::@constructor::new#element
          getters
            get a @-1
              reference: <testLibraryFragment>::@enum::E::@getter::a
              element: <testLibraryFragment>::@enum::E::@getter::a#element
            get b @-1
              reference: <testLibraryFragment>::@enum::E::@getter::b
              element: <testLibraryFragment>::@enum::E::@getter::b#element
            get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              element: <testLibraryFragment>::@enum::E::@getter::values#element
  enums
    enum E
      firstFragment: <testLibraryFragment>::@enum::E
      supertype: Enum
      fields
        static const a
          firstFragment: <testLibraryFragment>::@enum::E::@field::a
          type: E
          getter: <testLibraryFragment>::@enum::E::@getter::a#element
        static const b
          firstFragment: <testLibraryFragment>::@enum::E::@field::b
          type: E
          getter: <testLibraryFragment>::@enum::E::@getter::b#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
          type: List<E>
          getter: <testLibraryFragment>::@enum::E::@getter::values#element
      constructors
        synthetic const new
          firstFragment: <testLibraryFragment>::@enum::E::@constructor::new
      getters
        synthetic static get a
          firstFragment: <testLibraryFragment>::@enum::E::@getter::a
        synthetic static get b
          firstFragment: <testLibraryFragment>::@enum::E::@getter::b
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::E::@getter::values
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
      enclosingElement3: <null>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          enclosingElement3: <testLibraryFragment>
          supertype: Enum
          fields
            static const enumConstant a @46
              reference: <testLibraryFragment>::@enum::E::@field::a
              enclosingElement3: <testLibraryFragment>::@enum::E
              documentationComment: /**\n   * aaa\n   */
              metadata
                Annotation
                  atSign: @ @32
                  name: SimpleIdentifier
                    token: annotation @33
                    staticElement: <testLibraryFragment>::@getter::annotation
                    element: <testLibraryFragment>::@getter::annotation#element
                    staticType: null
                  element: <testLibraryFragment>::@getter::annotation
                  element2: <testLibraryFragment>::@getter::annotation#element
              type: E
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E
                      element2: <testLibraryFragment>::@enum::E#element
                      type: E
                    staticElement: <testLibraryFragment>::@enum::E::@constructor::new
                    element: <testLibraryFragment>::@enum::E::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            static const enumConstant b @75
              reference: <testLibraryFragment>::@enum::E::@field::b
              enclosingElement3: <testLibraryFragment>::@enum::E
              documentationComment: /// bbb
              metadata
                Annotation
                  atSign: @ @61
                  name: SimpleIdentifier
                    token: annotation @62
                    staticElement: <testLibraryFragment>::@getter::annotation
                    element: <testLibraryFragment>::@getter::annotation#element
                    staticType: null
                  element: <testLibraryFragment>::@getter::annotation
                  element2: <testLibraryFragment>::@getter::annotation#element
              type: E
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E
                      element2: <testLibraryFragment>::@enum::E#element
                      type: E
                    staticElement: <testLibraryFragment>::@enum::E::@constructor::new
                    element: <testLibraryFragment>::@enum::E::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              enclosingElement3: <testLibraryFragment>::@enum::E
              type: List<E>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: a @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::a
                      element: <testLibraryFragment>::@enum::E::@getter::a#element
                      staticType: E
                    SimpleIdentifier
                      token: b @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::b
                      element: <testLibraryFragment>::@enum::E::@getter::b#element
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              enclosingElement3: <testLibraryFragment>::@enum::E
          accessors
            synthetic static get a @-1
              reference: <testLibraryFragment>::@enum::E::@getter::a
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: E
            synthetic static get b @-1
              reference: <testLibraryFragment>::@enum::E::@getter::b
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: E
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: List<E>
      topLevelVariables
        static const annotation @91
          reference: <testLibraryFragment>::@topLevelVariable::annotation
          enclosingElement3: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: true
          constantInitializer
            IntegerLiteral
              literal: 0 @104
              staticType: int
      accessors
        synthetic static get annotation @-1
          reference: <testLibraryFragment>::@getter::annotation
          enclosingElement3: <testLibraryFragment>
          returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          element: <testLibraryFragment>::@enum::E#element
          fields
            enumConstant a @46
              reference: <testLibraryFragment>::@enum::E::@field::a
              element: <testLibraryFragment>::@enum::E::@field::a#element
              getter2: <testLibraryFragment>::@enum::E::@getter::a
            enumConstant b @75
              reference: <testLibraryFragment>::@enum::E::@field::b
              element: <testLibraryFragment>::@enum::E::@field::b#element
              getter2: <testLibraryFragment>::@enum::E::@getter::b
            values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              element: <testLibraryFragment>::@enum::E::@field::values#element
              getter2: <testLibraryFragment>::@enum::E::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              element: <testLibraryFragment>::@enum::E::@constructor::new#element
          getters
            get a @-1
              reference: <testLibraryFragment>::@enum::E::@getter::a
              element: <testLibraryFragment>::@enum::E::@getter::a#element
            get b @-1
              reference: <testLibraryFragment>::@enum::E::@getter::b
              element: <testLibraryFragment>::@enum::E::@getter::b#element
            get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              element: <testLibraryFragment>::@enum::E::@getter::values#element
      topLevelVariables
        const annotation @91
          reference: <testLibraryFragment>::@topLevelVariable::annotation
          element: <testLibraryFragment>::@topLevelVariable::annotation#element
          getter2: <testLibraryFragment>::@getter::annotation
      getters
        get annotation @-1
          reference: <testLibraryFragment>::@getter::annotation
          element: <testLibraryFragment>::@getter::annotation#element
  enums
    enum E
      firstFragment: <testLibraryFragment>::@enum::E
      supertype: Enum
      fields
        static const a
          firstFragment: <testLibraryFragment>::@enum::E::@field::a
          type: E
          getter: <testLibraryFragment>::@enum::E::@getter::a#element
        static const b
          firstFragment: <testLibraryFragment>::@enum::E::@field::b
          type: E
          getter: <testLibraryFragment>::@enum::E::@getter::b#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
          type: List<E>
          getter: <testLibraryFragment>::@enum::E::@getter::values#element
      constructors
        synthetic const new
          firstFragment: <testLibraryFragment>::@enum::E::@constructor::new
      getters
        synthetic static get a
          firstFragment: <testLibraryFragment>::@enum::E::@getter::a
        synthetic static get b
          firstFragment: <testLibraryFragment>::@enum::E::@getter::b
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::E::@getter::values
  topLevelVariables
    const annotation
      firstFragment: <testLibraryFragment>::@topLevelVariable::annotation
      type: int
      getter: <testLibraryFragment>::@getter::annotation#element
  getters
    synthetic static get annotation
      firstFragment: <testLibraryFragment>::@getter::annotation
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
      enclosingElement3: <null>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          enclosingElement3: <testLibraryFragment>
          supertype: Enum
          fields
            static const enumConstant v1 @9
              reference: <testLibraryFragment>::@enum::E::@field::v1
              enclosingElement3: <testLibraryFragment>::@enum::E
              type: E
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E
                      element2: <testLibraryFragment>::@enum::E#element
                      type: E
                    staticElement: <testLibraryFragment>::@enum::E::@constructor::new
                    element: <testLibraryFragment>::@enum::E::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            static const enumConstant v2 @13
              reference: <testLibraryFragment>::@enum::E::@field::v2
              enclosingElement3: <testLibraryFragment>::@enum::E
              type: E
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E
                      element2: <testLibraryFragment>::@enum::E#element
                      type: E
                    staticElement: <testLibraryFragment>::@enum::E::@constructor::new
                    element: <testLibraryFragment>::@enum::E::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              enclosingElement3: <testLibraryFragment>::@enum::E
              type: List<E>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v1 @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::v1
                      element: <testLibraryFragment>::@enum::E::@getter::v1#element
                      staticType: E
                    SimpleIdentifier
                      token: v2 @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::v2
                      element: <testLibraryFragment>::@enum::E::@getter::v2#element
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              enclosingElement3: <testLibraryFragment>::@enum::E
          accessors
            synthetic static get v1 @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v1
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: E
            synthetic static get v2 @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v2
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: E
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: List<E>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          element: <testLibraryFragment>::@enum::E#element
          fields
            enumConstant v1 @9
              reference: <testLibraryFragment>::@enum::E::@field::v1
              element: <testLibraryFragment>::@enum::E::@field::v1#element
              getter2: <testLibraryFragment>::@enum::E::@getter::v1
            enumConstant v2 @13
              reference: <testLibraryFragment>::@enum::E::@field::v2
              element: <testLibraryFragment>::@enum::E::@field::v2#element
              getter2: <testLibraryFragment>::@enum::E::@getter::v2
            values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              element: <testLibraryFragment>::@enum::E::@field::values#element
              getter2: <testLibraryFragment>::@enum::E::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              element: <testLibraryFragment>::@enum::E::@constructor::new#element
          getters
            get v1 @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v1
              element: <testLibraryFragment>::@enum::E::@getter::v1#element
            get v2 @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v2
              element: <testLibraryFragment>::@enum::E::@getter::v2#element
            get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              element: <testLibraryFragment>::@enum::E::@getter::values#element
  enums
    enum E
      firstFragment: <testLibraryFragment>::@enum::E
      supertype: Enum
      fields
        static const v1
          firstFragment: <testLibraryFragment>::@enum::E::@field::v1
          type: E
          getter: <testLibraryFragment>::@enum::E::@getter::v1#element
        static const v2
          firstFragment: <testLibraryFragment>::@enum::E::@field::v2
          type: E
          getter: <testLibraryFragment>::@enum::E::@getter::v2#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
          type: List<E>
          getter: <testLibraryFragment>::@enum::E::@getter::values#element
      constructors
        synthetic const new
          firstFragment: <testLibraryFragment>::@enum::E::@constructor::new
      getters
        synthetic static get v1
          firstFragment: <testLibraryFragment>::@enum::E::@getter::v1
        synthetic static get v2
          firstFragment: <testLibraryFragment>::@enum::E::@getter::v2
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::E::@getter::values
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
      enclosingElement3: <null>
      enums
        enum E1 @5
          reference: <testLibraryFragment>::@enum::E1
          enclosingElement3: <testLibraryFragment>
          supertype: Enum
          fields
            static const enumConstant v1 @10
              reference: <testLibraryFragment>::@enum::E1::@field::v1
              enclosingElement3: <testLibraryFragment>::@enum::E1
              type: E1
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E1 @-1
                      element: <testLibraryFragment>::@enum::E1
                      element2: <testLibraryFragment>::@enum::E1#element
                      type: E1
                    staticElement: <testLibraryFragment>::@enum::E1::@constructor::new
                    element: <testLibraryFragment>::@enum::E1::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E1
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::E1::@field::values
              enclosingElement3: <testLibraryFragment>::@enum::E1
              type: List<E1>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v1 @-1
                      staticElement: <testLibraryFragment>::@enum::E1::@getter::v1
                      element: <testLibraryFragment>::@enum::E1::@getter::v1#element
                      staticType: E1
                  rightBracket: ] @0
                  staticType: List<E1>
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::E1::@constructor::new
              enclosingElement3: <testLibraryFragment>::@enum::E1
          accessors
            synthetic static get v1 @-1
              reference: <testLibraryFragment>::@enum::E1::@getter::v1
              enclosingElement3: <testLibraryFragment>::@enum::E1
              returnType: E1
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::E1::@getter::values
              enclosingElement3: <testLibraryFragment>::@enum::E1
              returnType: List<E1>
        enum E2 @20
          reference: <testLibraryFragment>::@enum::E2
          enclosingElement3: <testLibraryFragment>
          supertype: Enum
          fields
            static const enumConstant v2 @25
              reference: <testLibraryFragment>::@enum::E2::@field::v2
              enclosingElement3: <testLibraryFragment>::@enum::E2
              type: E2
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E2 @-1
                      element: <testLibraryFragment>::@enum::E2
                      element2: <testLibraryFragment>::@enum::E2#element
                      type: E2
                    staticElement: <testLibraryFragment>::@enum::E2::@constructor::new
                    element: <testLibraryFragment>::@enum::E2::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E2
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::E2::@field::values
              enclosingElement3: <testLibraryFragment>::@enum::E2
              type: List<E2>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v2 @-1
                      staticElement: <testLibraryFragment>::@enum::E2::@getter::v2
                      element: <testLibraryFragment>::@enum::E2::@getter::v2#element
                      staticType: E2
                  rightBracket: ] @0
                  staticType: List<E2>
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::E2::@constructor::new
              enclosingElement3: <testLibraryFragment>::@enum::E2
          accessors
            synthetic static get v2 @-1
              reference: <testLibraryFragment>::@enum::E2::@getter::v2
              enclosingElement3: <testLibraryFragment>::@enum::E2
              returnType: E2
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::E2::@getter::values
              enclosingElement3: <testLibraryFragment>::@enum::E2
              returnType: List<E2>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      enums
        enum E1 @5
          reference: <testLibraryFragment>::@enum::E1
          element: <testLibraryFragment>::@enum::E1#element
          fields
            enumConstant v1 @10
              reference: <testLibraryFragment>::@enum::E1::@field::v1
              element: <testLibraryFragment>::@enum::E1::@field::v1#element
              getter2: <testLibraryFragment>::@enum::E1::@getter::v1
            values @-1
              reference: <testLibraryFragment>::@enum::E1::@field::values
              element: <testLibraryFragment>::@enum::E1::@field::values#element
              getter2: <testLibraryFragment>::@enum::E1::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::E1::@constructor::new
              element: <testLibraryFragment>::@enum::E1::@constructor::new#element
          getters
            get v1 @-1
              reference: <testLibraryFragment>::@enum::E1::@getter::v1
              element: <testLibraryFragment>::@enum::E1::@getter::v1#element
            get values @-1
              reference: <testLibraryFragment>::@enum::E1::@getter::values
              element: <testLibraryFragment>::@enum::E1::@getter::values#element
        enum E2 @20
          reference: <testLibraryFragment>::@enum::E2
          element: <testLibraryFragment>::@enum::E2#element
          fields
            enumConstant v2 @25
              reference: <testLibraryFragment>::@enum::E2::@field::v2
              element: <testLibraryFragment>::@enum::E2::@field::v2#element
              getter2: <testLibraryFragment>::@enum::E2::@getter::v2
            values @-1
              reference: <testLibraryFragment>::@enum::E2::@field::values
              element: <testLibraryFragment>::@enum::E2::@field::values#element
              getter2: <testLibraryFragment>::@enum::E2::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::E2::@constructor::new
              element: <testLibraryFragment>::@enum::E2::@constructor::new#element
          getters
            get v2 @-1
              reference: <testLibraryFragment>::@enum::E2::@getter::v2
              element: <testLibraryFragment>::@enum::E2::@getter::v2#element
            get values @-1
              reference: <testLibraryFragment>::@enum::E2::@getter::values
              element: <testLibraryFragment>::@enum::E2::@getter::values#element
  enums
    enum E1
      firstFragment: <testLibraryFragment>::@enum::E1
      supertype: Enum
      fields
        static const v1
          firstFragment: <testLibraryFragment>::@enum::E1::@field::v1
          type: E1
          getter: <testLibraryFragment>::@enum::E1::@getter::v1#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::E1::@field::values
          type: List<E1>
          getter: <testLibraryFragment>::@enum::E1::@getter::values#element
      constructors
        synthetic const new
          firstFragment: <testLibraryFragment>::@enum::E1::@constructor::new
      getters
        synthetic static get v1
          firstFragment: <testLibraryFragment>::@enum::E1::@getter::v1
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::E1::@getter::values
    enum E2
      firstFragment: <testLibraryFragment>::@enum::E2
      supertype: Enum
      fields
        static const v2
          firstFragment: <testLibraryFragment>::@enum::E2::@field::v2
          type: E2
          getter: <testLibraryFragment>::@enum::E2::@getter::v2#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::E2::@field::values
          type: List<E2>
          getter: <testLibraryFragment>::@enum::E2::@getter::values#element
      constructors
        synthetic const new
          firstFragment: <testLibraryFragment>::@enum::E2::@constructor::new
      getters
        synthetic static get v2
          firstFragment: <testLibraryFragment>::@enum::E2::@getter::v2
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::E2::@getter::values
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
      enclosingElement3: <null>
      classes
        class M @24
          reference: <testLibraryFragment>::@class::M
          enclosingElement3: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::M::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::M
        class A @36
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::A
          methods
            foo @52
              reference: <testLibraryFragment>::@class::A::@method::foo
              enclosingElement3: <testLibraryFragment>::@class::A
              returnType: dynamic
        class B @70
          reference: <testLibraryFragment>::@class::B
          enclosingElement3: <testLibraryFragment>
          interfaces
            M
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::B::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::B
          methods
            foo @92
              reference: <testLibraryFragment>::@class::B::@method::foo
              enclosingElement3: <testLibraryFragment>::@class::B
              returnType: dynamic
        class C @110
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          supertype: Object
          mixins
            M
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
          methods
            foo @141
              reference: <testLibraryFragment>::@class::C::@method::foo
              enclosingElement3: <testLibraryFragment>::@class::C
              returnType: dynamic
        class alias D @159
          reference: <testLibraryFragment>::@class::D
          enclosingElement3: <testLibraryFragment>
          supertype: Object
          mixins
            M
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@class::D::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::D
              constantInitializers
                SuperConstructorInvocation
                  superKeyword: super @0
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticElement: dart:core::<fragment>::@class::Object::@constructor::new
                  element: dart:core::<fragment>::@class::Object::@constructor::new#element
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          enclosingElement3: <testLibraryFragment>
          supertype: Enum
          fields
            static const enumConstant a @8
              reference: <testLibraryFragment>::@enum::E::@field::a
              enclosingElement3: <testLibraryFragment>::@enum::E
              type: E
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E
                      element2: <testLibraryFragment>::@enum::E#element
                      type: E
                    staticElement: <testLibraryFragment>::@enum::E::@constructor::new
                    element: <testLibraryFragment>::@enum::E::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            static const enumConstant b @11
              reference: <testLibraryFragment>::@enum::E::@field::b
              enclosingElement3: <testLibraryFragment>::@enum::E
              type: E
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E
                      element2: <testLibraryFragment>::@enum::E#element
                      type: E
                    staticElement: <testLibraryFragment>::@enum::E::@constructor::new
                    element: <testLibraryFragment>::@enum::E::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            static const enumConstant c @14
              reference: <testLibraryFragment>::@enum::E::@field::c
              enclosingElement3: <testLibraryFragment>::@enum::E
              type: E
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E
                      element2: <testLibraryFragment>::@enum::E#element
                      type: E
                    staticElement: <testLibraryFragment>::@enum::E::@constructor::new
                    element: <testLibraryFragment>::@enum::E::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              enclosingElement3: <testLibraryFragment>::@enum::E
              type: List<E>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: a @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::a
                      element: <testLibraryFragment>::@enum::E::@getter::a#element
                      staticType: E
                    SimpleIdentifier
                      token: b @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::b
                      element: <testLibraryFragment>::@enum::E::@getter::b#element
                      staticType: E
                    SimpleIdentifier
                      token: c @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::c
                      element: <testLibraryFragment>::@enum::E::@getter::c#element
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              enclosingElement3: <testLibraryFragment>::@enum::E
          accessors
            synthetic static get a @-1
              reference: <testLibraryFragment>::@enum::E::@getter::a
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: E
            synthetic static get b @-1
              reference: <testLibraryFragment>::@enum::E::@getter::b
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: E
            synthetic static get c @-1
              reference: <testLibraryFragment>::@enum::E::@getter::c
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: E
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: List<E>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class M @24
          reference: <testLibraryFragment>::@class::M
          element: <testLibraryFragment>::@class::M#element
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::M::@constructor::new
              element: <testLibraryFragment>::@class::M::@constructor::new#element
        class A @36
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A#element
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <testLibraryFragment>::@class::A::@constructor::new#element
          methods
            foo @52
              reference: <testLibraryFragment>::@class::A::@method::foo
              element: <testLibraryFragment>::@class::A::@method::foo#element
        class B @70
          reference: <testLibraryFragment>::@class::B
          element: <testLibraryFragment>::@class::B#element
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::B::@constructor::new
              element: <testLibraryFragment>::@class::B::@constructor::new#element
          methods
            foo @92
              reference: <testLibraryFragment>::@class::B::@method::foo
              element: <testLibraryFragment>::@class::B::@method::foo#element
        class C @110
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C#element
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
          methods
            foo @141
              reference: <testLibraryFragment>::@class::C::@method::foo
              element: <testLibraryFragment>::@class::C::@method::foo#element
        class D @159
          reference: <testLibraryFragment>::@class::D
          element: <testLibraryFragment>::@class::D#element
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@class::D::@constructor::new
              element: <testLibraryFragment>::@class::D::@constructor::new#element
              constantInitializers
                SuperConstructorInvocation
                  superKeyword: super @0
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticElement: dart:core::<fragment>::@class::Object::@constructor::new
                  element: dart:core::<fragment>::@class::Object::@constructor::new#element
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          element: <testLibraryFragment>::@enum::E#element
          fields
            enumConstant a @8
              reference: <testLibraryFragment>::@enum::E::@field::a
              element: <testLibraryFragment>::@enum::E::@field::a#element
              getter2: <testLibraryFragment>::@enum::E::@getter::a
            enumConstant b @11
              reference: <testLibraryFragment>::@enum::E::@field::b
              element: <testLibraryFragment>::@enum::E::@field::b#element
              getter2: <testLibraryFragment>::@enum::E::@getter::b
            enumConstant c @14
              reference: <testLibraryFragment>::@enum::E::@field::c
              element: <testLibraryFragment>::@enum::E::@field::c#element
              getter2: <testLibraryFragment>::@enum::E::@getter::c
            values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              element: <testLibraryFragment>::@enum::E::@field::values#element
              getter2: <testLibraryFragment>::@enum::E::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              element: <testLibraryFragment>::@enum::E::@constructor::new#element
          getters
            get a @-1
              reference: <testLibraryFragment>::@enum::E::@getter::a
              element: <testLibraryFragment>::@enum::E::@getter::a#element
            get b @-1
              reference: <testLibraryFragment>::@enum::E::@getter::b
              element: <testLibraryFragment>::@enum::E::@getter::b#element
            get c @-1
              reference: <testLibraryFragment>::@enum::E::@getter::c
              element: <testLibraryFragment>::@enum::E::@getter::c#element
            get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              element: <testLibraryFragment>::@enum::E::@getter::values#element
  classes
    class M
      firstFragment: <testLibraryFragment>::@class::M
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::M::@constructor::new
    class A
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
      methods
        foo
          firstFragment: <testLibraryFragment>::@class::A::@method::foo
    class B
      firstFragment: <testLibraryFragment>::@class::B
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::B::@constructor::new
      methods
        foo
          firstFragment: <testLibraryFragment>::@class::B::@method::foo
    class C
      firstFragment: <testLibraryFragment>::@class::C
      supertype: Object
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      methods
        foo
          firstFragment: <testLibraryFragment>::@class::C::@method::foo
    class alias D
      firstFragment: <testLibraryFragment>::@class::D
      supertype: Object
      constructors
        synthetic const new
          firstFragment: <testLibraryFragment>::@class::D::@constructor::new
  enums
    enum E
      firstFragment: <testLibraryFragment>::@enum::E
      supertype: Enum
      fields
        static const a
          firstFragment: <testLibraryFragment>::@enum::E::@field::a
          type: E
          getter: <testLibraryFragment>::@enum::E::@getter::a#element
        static const b
          firstFragment: <testLibraryFragment>::@enum::E::@field::b
          type: E
          getter: <testLibraryFragment>::@enum::E::@getter::b#element
        static const c
          firstFragment: <testLibraryFragment>::@enum::E::@field::c
          type: E
          getter: <testLibraryFragment>::@enum::E::@getter::c#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
          type: List<E>
          getter: <testLibraryFragment>::@enum::E::@getter::values#element
      constructors
        synthetic const new
          firstFragment: <testLibraryFragment>::@enum::E::@constructor::new
      getters
        synthetic static get a
          firstFragment: <testLibraryFragment>::@enum::E::@getter::a
        synthetic static get b
          firstFragment: <testLibraryFragment>::@enum::E::@getter::b
        synthetic static get c
          firstFragment: <testLibraryFragment>::@enum::E::@getter::c
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::E::@getter::values
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
      enclosingElement3: <null>
      enums
        enum E @19
          reference: <testLibraryFragment>::@enum::E
          enclosingElement3: <testLibraryFragment>
          supertype: Enum
          fields
            static const enumConstant v @26
              reference: <testLibraryFragment>::@enum::E::@field::v
              enclosingElement3: <testLibraryFragment>::@enum::E
              metadata
                Annotation
                  atSign: @ @23
                  name: SimpleIdentifier
                    token: a @24
                    staticElement: <testLibraryFragment>::@getter::a
                    element: <testLibraryFragment>::@getter::a#element
                    staticType: null
                  element: <testLibraryFragment>::@getter::a
                  element2: <testLibraryFragment>::@getter::a#element
              type: E
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E
                      element2: <testLibraryFragment>::@enum::E#element
                      type: E
                    staticElement: <testLibraryFragment>::@enum::E::@constructor::new
                    element: <testLibraryFragment>::@enum::E::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              enclosingElement3: <testLibraryFragment>::@enum::E
              type: List<E>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::v
                      element: <testLibraryFragment>::@enum::E::@getter::v#element
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              enclosingElement3: <testLibraryFragment>::@enum::E
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: E
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: List<E>
      topLevelVariables
        static const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement3: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            IntegerLiteral
              literal: 42 @10
              staticType: int
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement3: <testLibraryFragment>
          returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      enums
        enum E @19
          reference: <testLibraryFragment>::@enum::E
          element: <testLibraryFragment>::@enum::E#element
          fields
            enumConstant v @26
              reference: <testLibraryFragment>::@enum::E::@field::v
              element: <testLibraryFragment>::@enum::E::@field::v#element
              getter2: <testLibraryFragment>::@enum::E::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              element: <testLibraryFragment>::@enum::E::@field::values#element
              getter2: <testLibraryFragment>::@enum::E::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              element: <testLibraryFragment>::@enum::E::@constructor::new#element
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              element: <testLibraryFragment>::@enum::E::@getter::v#element
            get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              element: <testLibraryFragment>::@enum::E::@getter::values#element
      topLevelVariables
        const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <testLibraryFragment>::@topLevelVariable::a#element
          getter2: <testLibraryFragment>::@getter::a
      getters
        get a @-1
          reference: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
  enums
    enum E
      firstFragment: <testLibraryFragment>::@enum::E
      supertype: Enum
      fields
        static const v
          firstFragment: <testLibraryFragment>::@enum::E::@field::v
          type: E
          getter: <testLibraryFragment>::@enum::E::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
          type: List<E>
          getter: <testLibraryFragment>::@enum::E::@getter::values#element
      constructors
        synthetic const new
          firstFragment: <testLibraryFragment>::@enum::E::@constructor::new
      getters
        synthetic static get v
          firstFragment: <testLibraryFragment>::@enum::E::@getter::v
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::E::@getter::values
  topLevelVariables
    const a
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      type: int
      getter: <testLibraryFragment>::@getter::a#element
  getters
    synthetic static get a
      firstFragment: <testLibraryFragment>::@getter::a
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
      enclosingElement3: <null>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          fields
            final value @26
              reference: <testLibraryFragment>::@class::A::@field::value
              enclosingElement3: <testLibraryFragment>::@class::A
              type: dynamic
          constructors
            const @41
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::A
              parameters
                requiredPositional final this.value @48
                  type: dynamic
                  field: <testLibraryFragment>::@class::A::@field::value
          accessors
            synthetic get value @-1
              reference: <testLibraryFragment>::@class::A::@getter::value
              enclosingElement3: <testLibraryFragment>::@class::A
              returnType: dynamic
      enums
        enum E @64
          reference: <testLibraryFragment>::@enum::E
          enclosingElement3: <testLibraryFragment>
          supertype: Enum
          fields
            static const enumConstant a @78
              reference: <testLibraryFragment>::@enum::E::@field::a
              enclosingElement3: <testLibraryFragment>::@enum::E
              metadata
                Annotation
                  atSign: @ @70
                  name: SimpleIdentifier
                    token: A @71
                    staticElement: <testLibraryFragment>::@class::A
                    element: <testLibraryFragment>::@class::A#element
                    staticType: null
                  arguments: ArgumentList
                    leftParenthesis: ( @72
                    arguments
                      IntegerLiteral
                        literal: 100 @73
                        staticType: int
                    rightParenthesis: ) @76
                  element: <testLibraryFragment>::@class::A::@constructor::new
                  element2: <testLibraryFragment>::@class::A::@constructor::new#element
              type: E
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E
                      element2: <testLibraryFragment>::@enum::E#element
                      type: E
                    staticElement: <testLibraryFragment>::@enum::E::@constructor::new
                    element: <testLibraryFragment>::@enum::E::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            static const enumConstant b @83
              reference: <testLibraryFragment>::@enum::E::@field::b
              enclosingElement3: <testLibraryFragment>::@enum::E
              type: E
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E
                      element2: <testLibraryFragment>::@enum::E#element
                      type: E
                    staticElement: <testLibraryFragment>::@enum::E::@constructor::new
                    element: <testLibraryFragment>::@enum::E::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            static const enumConstant c @96
              reference: <testLibraryFragment>::@enum::E::@field::c
              enclosingElement3: <testLibraryFragment>::@enum::E
              metadata
                Annotation
                  atSign: @ @88
                  name: SimpleIdentifier
                    token: A @89
                    staticElement: <testLibraryFragment>::@class::A
                    element: <testLibraryFragment>::@class::A#element
                    staticType: null
                  arguments: ArgumentList
                    leftParenthesis: ( @90
                    arguments
                      IntegerLiteral
                        literal: 300 @91
                        staticType: int
                    rightParenthesis: ) @94
                  element: <testLibraryFragment>::@class::A::@constructor::new
                  element2: <testLibraryFragment>::@class::A::@constructor::new#element
              type: E
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E
                      element2: <testLibraryFragment>::@enum::E#element
                      type: E
                    staticElement: <testLibraryFragment>::@enum::E::@constructor::new
                    element: <testLibraryFragment>::@enum::E::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              enclosingElement3: <testLibraryFragment>::@enum::E
              type: List<E>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: a @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::a
                      element: <testLibraryFragment>::@enum::E::@getter::a#element
                      staticType: E
                    SimpleIdentifier
                      token: b @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::b
                      element: <testLibraryFragment>::@enum::E::@getter::b#element
                      staticType: E
                    SimpleIdentifier
                      token: c @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::c
                      element: <testLibraryFragment>::@enum::E::@getter::c#element
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              enclosingElement3: <testLibraryFragment>::@enum::E
          accessors
            synthetic static get a @-1
              reference: <testLibraryFragment>::@enum::E::@getter::a
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: E
            synthetic static get b @-1
              reference: <testLibraryFragment>::@enum::E::@getter::b
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: E
            synthetic static get c @-1
              reference: <testLibraryFragment>::@enum::E::@getter::c
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: E
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: List<E>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A#element
          fields
            value @26
              reference: <testLibraryFragment>::@class::A::@field::value
              element: <testLibraryFragment>::@class::A::@field::value#element
              getter2: <testLibraryFragment>::@class::A::@getter::value
          constructors
            const new @41
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <testLibraryFragment>::@class::A::@constructor::new#element
              formalParameters
                this.value @48
                  element: <testLibraryFragment>::@class::A::@constructor::new::@parameter::value#element
          getters
            get value @-1
              reference: <testLibraryFragment>::@class::A::@getter::value
              element: <testLibraryFragment>::@class::A::@getter::value#element
      enums
        enum E @64
          reference: <testLibraryFragment>::@enum::E
          element: <testLibraryFragment>::@enum::E#element
          fields
            enumConstant a @78
              reference: <testLibraryFragment>::@enum::E::@field::a
              element: <testLibraryFragment>::@enum::E::@field::a#element
              getter2: <testLibraryFragment>::@enum::E::@getter::a
            enumConstant b @83
              reference: <testLibraryFragment>::@enum::E::@field::b
              element: <testLibraryFragment>::@enum::E::@field::b#element
              getter2: <testLibraryFragment>::@enum::E::@getter::b
            enumConstant c @96
              reference: <testLibraryFragment>::@enum::E::@field::c
              element: <testLibraryFragment>::@enum::E::@field::c#element
              getter2: <testLibraryFragment>::@enum::E::@getter::c
            values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              element: <testLibraryFragment>::@enum::E::@field::values#element
              getter2: <testLibraryFragment>::@enum::E::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              element: <testLibraryFragment>::@enum::E::@constructor::new#element
          getters
            get a @-1
              reference: <testLibraryFragment>::@enum::E::@getter::a
              element: <testLibraryFragment>::@enum::E::@getter::a#element
            get b @-1
              reference: <testLibraryFragment>::@enum::E::@getter::b
              element: <testLibraryFragment>::@enum::E::@getter::b#element
            get c @-1
              reference: <testLibraryFragment>::@enum::E::@getter::c
              element: <testLibraryFragment>::@enum::E::@getter::c#element
            get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              element: <testLibraryFragment>::@enum::E::@getter::values#element
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
      fields
        final value
          firstFragment: <testLibraryFragment>::@class::A::@field::value
          type: dynamic
          getter: <testLibraryFragment>::@class::A::@getter::value#element
      constructors
        const new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
          formalParameters
            requiredPositional final value
              type: dynamic
      getters
        synthetic get value
          firstFragment: <testLibraryFragment>::@class::A::@getter::value
  enums
    enum E
      firstFragment: <testLibraryFragment>::@enum::E
      supertype: Enum
      fields
        static const a
          firstFragment: <testLibraryFragment>::@enum::E::@field::a
          type: E
          getter: <testLibraryFragment>::@enum::E::@getter::a#element
        static const b
          firstFragment: <testLibraryFragment>::@enum::E::@field::b
          type: E
          getter: <testLibraryFragment>::@enum::E::@getter::b#element
        static const c
          firstFragment: <testLibraryFragment>::@enum::E::@field::c
          type: E
          getter: <testLibraryFragment>::@enum::E::@getter::c#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
          type: List<E>
          getter: <testLibraryFragment>::@enum::E::@getter::values#element
      constructors
        synthetic const new
          firstFragment: <testLibraryFragment>::@enum::E::@constructor::new
      getters
        synthetic static get a
          firstFragment: <testLibraryFragment>::@enum::E::@getter::a
        synthetic static get b
          firstFragment: <testLibraryFragment>::@enum::E::@getter::b
        synthetic static get c
          firstFragment: <testLibraryFragment>::@enum::E::@getter::c
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::E::@getter::values
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
      enclosingElement3: <null>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          enclosingElement3: <testLibraryFragment>
          supertype: Enum
          fields
            static const enumConstant v @16
              reference: <testLibraryFragment>::@enum::E::@field::v
              enclosingElement3: <testLibraryFragment>::@enum::E
              metadata
                Annotation
                  atSign: @ @11
                  name: SimpleIdentifier
                    token: v @12
                    staticElement: <testLibraryFragment>::@enum::E::@getter::v
                    element: <testLibraryFragment>::@enum::E::@getter::v#element
                    staticType: null
                  element: <testLibraryFragment>::@enum::E::@getter::v
                  element2: <testLibraryFragment>::@enum::E::@getter::v#element
              type: E
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E
                      element2: <testLibraryFragment>::@enum::E#element
                      type: E
                    staticElement: <testLibraryFragment>::@enum::E::@constructor::new
                    element: <testLibraryFragment>::@enum::E::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              enclosingElement3: <testLibraryFragment>::@enum::E
              type: List<E>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::v
                      element: <testLibraryFragment>::@enum::E::@getter::v#element
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              enclosingElement3: <testLibraryFragment>::@enum::E
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: E
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: List<E>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          element: <testLibraryFragment>::@enum::E#element
          fields
            enumConstant v @16
              reference: <testLibraryFragment>::@enum::E::@field::v
              element: <testLibraryFragment>::@enum::E::@field::v#element
              getter2: <testLibraryFragment>::@enum::E::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              element: <testLibraryFragment>::@enum::E::@field::values#element
              getter2: <testLibraryFragment>::@enum::E::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              element: <testLibraryFragment>::@enum::E::@constructor::new#element
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              element: <testLibraryFragment>::@enum::E::@getter::v#element
            get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              element: <testLibraryFragment>::@enum::E::@getter::values#element
  enums
    enum E
      firstFragment: <testLibraryFragment>::@enum::E
      supertype: Enum
      fields
        static const v
          firstFragment: <testLibraryFragment>::@enum::E::@field::v
          type: E
          getter: <testLibraryFragment>::@enum::E::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
          type: List<E>
          getter: <testLibraryFragment>::@enum::E::@getter::values#element
      constructors
        synthetic const new
          firstFragment: <testLibraryFragment>::@enum::E::@constructor::new
      getters
        synthetic static get v
          firstFragment: <testLibraryFragment>::@enum::E::@getter::v
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::E::@getter::values
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
      enclosingElement3: <null>
      enums
        enum E @19
          reference: <testLibraryFragment>::@enum::E
          enclosingElement3: <testLibraryFragment>
          supertype: Enum
          fields
            static const enumConstant v @25
              reference: <testLibraryFragment>::@enum::E::@field::v
              enclosingElement3: <testLibraryFragment>::@enum::E
              type: E
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E
                      element2: <testLibraryFragment>::@enum::E#element
                      type: E
                    staticElement: <testLibraryFragment>::@enum::E::@constructor::new
                    element: <testLibraryFragment>::@enum::E::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              enclosingElement3: <testLibraryFragment>::@enum::E
              type: List<E>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::v
                      element: <testLibraryFragment>::@enum::E::@getter::v#element
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
          constructors
            const @41
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              enclosingElement3: <testLibraryFragment>::@enum::E
              metadata
                Annotation
                  atSign: @ @30
                  name: SimpleIdentifier
                    token: a @31
                    staticElement: <testLibraryFragment>::@getter::a
                    element: <testLibraryFragment>::@getter::a#element
                    staticType: null
                  element: <testLibraryFragment>::@getter::a
                  element2: <testLibraryFragment>::@getter::a#element
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: E
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: List<E>
      topLevelVariables
        static const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement3: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            IntegerLiteral
              literal: 42 @10
              staticType: int
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement3: <testLibraryFragment>
          returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      enums
        enum E @19
          reference: <testLibraryFragment>::@enum::E
          element: <testLibraryFragment>::@enum::E#element
          fields
            enumConstant v @25
              reference: <testLibraryFragment>::@enum::E::@field::v
              element: <testLibraryFragment>::@enum::E::@field::v#element
              getter2: <testLibraryFragment>::@enum::E::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              element: <testLibraryFragment>::@enum::E::@field::values#element
              getter2: <testLibraryFragment>::@enum::E::@getter::values
          constructors
            const new @41
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              element: <testLibraryFragment>::@enum::E::@constructor::new#element
              metadata
                Annotation
                  atSign: @ @30
                  name: SimpleIdentifier
                    token: a @31
                    staticElement: <testLibraryFragment>::@getter::a
                    element: <testLibraryFragment>::@getter::a#element
                    staticType: null
                  element: <testLibraryFragment>::@getter::a
                  element2: <testLibraryFragment>::@getter::a#element
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              element: <testLibraryFragment>::@enum::E::@getter::v#element
            get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              element: <testLibraryFragment>::@enum::E::@getter::values#element
      topLevelVariables
        const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <testLibraryFragment>::@topLevelVariable::a#element
          getter2: <testLibraryFragment>::@getter::a
      getters
        get a @-1
          reference: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
  enums
    enum E
      firstFragment: <testLibraryFragment>::@enum::E
      supertype: Enum
      fields
        static const v
          firstFragment: <testLibraryFragment>::@enum::E::@field::v
          type: E
          getter: <testLibraryFragment>::@enum::E::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
          type: List<E>
          getter: <testLibraryFragment>::@enum::E::@getter::values#element
      constructors
        const new
          firstFragment: <testLibraryFragment>::@enum::E::@constructor::new
          metadata
            Annotation
              atSign: @ @30
              name: SimpleIdentifier
                token: a @31
                staticElement: <testLibraryFragment>::@getter::a
                element: <testLibraryFragment>::@getter::a#element
                staticType: null
              element: <testLibraryFragment>::@getter::a
              element2: <testLibraryFragment>::@getter::a#element
      getters
        synthetic static get v
          firstFragment: <testLibraryFragment>::@enum::E::@getter::v
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::E::@getter::values
  topLevelVariables
    const a
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      type: int
      getter: <testLibraryFragment>::@getter::a#element
  getters
    synthetic static get a
      firstFragment: <testLibraryFragment>::@getter::a
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
      enclosingElement3: <null>
      enums
        enum E @19
          reference: <testLibraryFragment>::@enum::E
          enclosingElement3: <testLibraryFragment>
          supertype: Enum
          fields
            static const enumConstant v @25
              reference: <testLibraryFragment>::@enum::E::@field::v
              enclosingElement3: <testLibraryFragment>::@enum::E
              type: E
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E
                      element2: <testLibraryFragment>::@enum::E#element
                      type: E
                    staticElement: <testLibraryFragment>::@enum::E::@constructor::new
                    element: <testLibraryFragment>::@enum::E::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              enclosingElement3: <testLibraryFragment>::@enum::E
              type: List<E>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::v
                      element: <testLibraryFragment>::@enum::E::@getter::v#element
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              enclosingElement3: <testLibraryFragment>::@enum::E
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: E
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: List<E>
          methods
            foo @40
              reference: <testLibraryFragment>::@enum::E::@method::foo
              enclosingElement3: <testLibraryFragment>::@enum::E
              metadata
                Annotation
                  atSign: @ @30
                  name: SimpleIdentifier
                    token: a @31
                    staticElement: <testLibraryFragment>::@getter::a
                    element: <testLibraryFragment>::@getter::a#element
                    staticType: null
                  element: <testLibraryFragment>::@getter::a
                  element2: <testLibraryFragment>::@getter::a#element
              returnType: void
      topLevelVariables
        static const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement3: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            IntegerLiteral
              literal: 42 @10
              staticType: int
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement3: <testLibraryFragment>
          returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      enums
        enum E @19
          reference: <testLibraryFragment>::@enum::E
          element: <testLibraryFragment>::@enum::E#element
          fields
            enumConstant v @25
              reference: <testLibraryFragment>::@enum::E::@field::v
              element: <testLibraryFragment>::@enum::E::@field::v#element
              getter2: <testLibraryFragment>::@enum::E::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              element: <testLibraryFragment>::@enum::E::@field::values#element
              getter2: <testLibraryFragment>::@enum::E::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              element: <testLibraryFragment>::@enum::E::@constructor::new#element
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              element: <testLibraryFragment>::@enum::E::@getter::v#element
            get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              element: <testLibraryFragment>::@enum::E::@getter::values#element
          methods
            foo @40
              reference: <testLibraryFragment>::@enum::E::@method::foo
              element: <testLibraryFragment>::@enum::E::@method::foo#element
              metadata
                Annotation
                  atSign: @ @30
                  name: SimpleIdentifier
                    token: a @31
                    staticElement: <testLibraryFragment>::@getter::a
                    element: <testLibraryFragment>::@getter::a#element
                    staticType: null
                  element: <testLibraryFragment>::@getter::a
                  element2: <testLibraryFragment>::@getter::a#element
      topLevelVariables
        const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <testLibraryFragment>::@topLevelVariable::a#element
          getter2: <testLibraryFragment>::@getter::a
      getters
        get a @-1
          reference: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
  enums
    enum E
      firstFragment: <testLibraryFragment>::@enum::E
      supertype: Enum
      fields
        static const v
          firstFragment: <testLibraryFragment>::@enum::E::@field::v
          type: E
          getter: <testLibraryFragment>::@enum::E::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
          type: List<E>
          getter: <testLibraryFragment>::@enum::E::@getter::values#element
      constructors
        synthetic const new
          firstFragment: <testLibraryFragment>::@enum::E::@constructor::new
      getters
        synthetic static get v
          firstFragment: <testLibraryFragment>::@enum::E::@getter::v
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::E::@getter::values
      methods
        foo
          firstFragment: <testLibraryFragment>::@enum::E::@method::foo
          metadata
            Annotation
              atSign: @ @30
              name: SimpleIdentifier
                token: a @31
                staticElement: <testLibraryFragment>::@getter::a
                element: <testLibraryFragment>::@getter::a#element
                staticType: null
              element: <testLibraryFragment>::@getter::a
              element2: <testLibraryFragment>::@getter::a#element
  topLevelVariables
    const a
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      type: int
      getter: <testLibraryFragment>::@getter::a#element
  getters
    synthetic static get a
      firstFragment: <testLibraryFragment>::@getter::a
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
      enclosingElement3: <null>
      enums
        enum E @26
          reference: <testLibraryFragment>::@enum::E
          enclosingElement3: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @16
              name: SimpleIdentifier
                token: foo @17
                staticElement: <testLibraryFragment>::@getter::foo
                element: <testLibraryFragment>::@getter::foo#element
                staticType: null
              element: <testLibraryFragment>::@getter::foo
              element2: <testLibraryFragment>::@getter::foo#element
          typeParameters
            covariant T @33
              defaultType: dynamic
              metadata
                Annotation
                  atSign: @ @28
                  name: SimpleIdentifier
                    token: foo @29
                    staticElement: <testLibraryFragment>::@getter::foo
                    element: <testLibraryFragment>::@getter::foo#element
                    staticType: null
                  element: <testLibraryFragment>::@getter::foo
                  element2: <testLibraryFragment>::@getter::foo#element
          supertype: Enum
          fields
            static const enumConstant v @40
              reference: <testLibraryFragment>::@enum::E::@field::v
              enclosingElement3: <testLibraryFragment>::@enum::E
              type: E<dynamic>
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E
                      element2: <testLibraryFragment>::@enum::E#element
                      type: E<dynamic>
                    staticElement: ConstructorMember
                      base: <testLibraryFragment>::@enum::E::@constructor::new
                      substitution: {T: dynamic}
                    element: <testLibraryFragment>::@enum::E::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E<dynamic>
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              enclosingElement3: <testLibraryFragment>::@enum::E
              type: List<E<dynamic>>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::v
                      element: <testLibraryFragment>::@enum::E::@getter::v#element
                      staticType: E<dynamic>
                  rightBracket: ] @0
                  staticType: List<E<dynamic>>
            static const foo @58
              reference: <testLibraryFragment>::@enum::E::@field::foo
              enclosingElement3: <testLibraryFragment>::@enum::E
              type: int
              shouldUseTypeForInitializerInference: false
              constantInitializer
                IntegerLiteral
                  literal: 1 @64
                  staticType: int
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              enclosingElement3: <testLibraryFragment>::@enum::E
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: E<dynamic>
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: List<E<dynamic>>
            synthetic static get foo @-1
              reference: <testLibraryFragment>::@enum::E::@getter::foo
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: int
          methods
            bar @81
              reference: <testLibraryFragment>::@enum::E::@method::bar
              enclosingElement3: <testLibraryFragment>::@enum::E
              metadata
                Annotation
                  atSign: @ @69
                  name: SimpleIdentifier
                    token: foo @70
                    staticElement: <testLibraryFragment>::@enum::E::@getter::foo
                    element: <testLibraryFragment>::@enum::E::@getter::foo#element
                    staticType: null
                  element: <testLibraryFragment>::@enum::E::@getter::foo
                  element2: <testLibraryFragment>::@enum::E::@getter::foo#element
              returnType: void
      topLevelVariables
        static const foo @6
          reference: <testLibraryFragment>::@topLevelVariable::foo
          enclosingElement3: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            IntegerLiteral
              literal: 0 @12
              staticType: int
      accessors
        synthetic static get foo @-1
          reference: <testLibraryFragment>::@getter::foo
          enclosingElement3: <testLibraryFragment>
          returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      enums
        enum E @26
          reference: <testLibraryFragment>::@enum::E
          element: <testLibraryFragment>::@enum::E#element
          typeParameters
            T @33
              element: <not-implemented>
              metadata
                Annotation
                  atSign: @ @28
                  name: SimpleIdentifier
                    token: foo @29
                    staticElement: <testLibraryFragment>::@getter::foo
                    element: <testLibraryFragment>::@getter::foo#element
                    staticType: null
                  element: <testLibraryFragment>::@getter::foo
                  element2: <testLibraryFragment>::@getter::foo#element
          fields
            enumConstant v @40
              reference: <testLibraryFragment>::@enum::E::@field::v
              element: <testLibraryFragment>::@enum::E::@field::v#element
              getter2: <testLibraryFragment>::@enum::E::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              element: <testLibraryFragment>::@enum::E::@field::values#element
              getter2: <testLibraryFragment>::@enum::E::@getter::values
            foo @58
              reference: <testLibraryFragment>::@enum::E::@field::foo
              element: <testLibraryFragment>::@enum::E::@field::foo#element
              getter2: <testLibraryFragment>::@enum::E::@getter::foo
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              element: <testLibraryFragment>::@enum::E::@constructor::new#element
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              element: <testLibraryFragment>::@enum::E::@getter::v#element
            get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              element: <testLibraryFragment>::@enum::E::@getter::values#element
            get foo @-1
              reference: <testLibraryFragment>::@enum::E::@getter::foo
              element: <testLibraryFragment>::@enum::E::@getter::foo#element
          methods
            bar @81
              reference: <testLibraryFragment>::@enum::E::@method::bar
              element: <testLibraryFragment>::@enum::E::@method::bar#element
              metadata
                Annotation
                  atSign: @ @69
                  name: SimpleIdentifier
                    token: foo @70
                    staticElement: <testLibraryFragment>::@enum::E::@getter::foo
                    element: <testLibraryFragment>::@enum::E::@getter::foo#element
                    staticType: null
                  element: <testLibraryFragment>::@enum::E::@getter::foo
                  element2: <testLibraryFragment>::@enum::E::@getter::foo#element
      topLevelVariables
        const foo @6
          reference: <testLibraryFragment>::@topLevelVariable::foo
          element: <testLibraryFragment>::@topLevelVariable::foo#element
          getter2: <testLibraryFragment>::@getter::foo
      getters
        get foo @-1
          reference: <testLibraryFragment>::@getter::foo
          element: <testLibraryFragment>::@getter::foo#element
  enums
    enum E
      firstFragment: <testLibraryFragment>::@enum::E
      typeParameters
        T
          metadata
            Annotation
              atSign: @ @28
              name: SimpleIdentifier
                token: foo @29
                staticElement: <testLibraryFragment>::@getter::foo
                element: <testLibraryFragment>::@getter::foo#element
                staticType: null
              element: <testLibraryFragment>::@getter::foo
              element2: <testLibraryFragment>::@getter::foo#element
      supertype: Enum
      fields
        static const v
          firstFragment: <testLibraryFragment>::@enum::E::@field::v
          type: E<dynamic>
          getter: <testLibraryFragment>::@enum::E::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
          type: List<E<dynamic>>
          getter: <testLibraryFragment>::@enum::E::@getter::values#element
        static const foo
          firstFragment: <testLibraryFragment>::@enum::E::@field::foo
          type: int
          getter: <testLibraryFragment>::@enum::E::@getter::foo#element
      constructors
        synthetic const new
          firstFragment: <testLibraryFragment>::@enum::E::@constructor::new
      getters
        synthetic static get v
          firstFragment: <testLibraryFragment>::@enum::E::@getter::v
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::E::@getter::values
        synthetic static get foo
          firstFragment: <testLibraryFragment>::@enum::E::@getter::foo
      methods
        bar
          firstFragment: <testLibraryFragment>::@enum::E::@method::bar
          metadata
            Annotation
              atSign: @ @69
              name: SimpleIdentifier
                token: foo @70
                staticElement: <testLibraryFragment>::@enum::E::@getter::foo
                element: <testLibraryFragment>::@enum::E::@getter::foo#element
                staticType: null
              element: <testLibraryFragment>::@enum::E::@getter::foo
              element2: <testLibraryFragment>::@enum::E::@getter::foo#element
  topLevelVariables
    const foo
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo
      type: int
      getter: <testLibraryFragment>::@getter::foo#element
  getters
    synthetic static get foo
      firstFragment: <testLibraryFragment>::@getter::foo
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
      enclosingElement3: <null>
      enums
        enum E @19
          reference: <testLibraryFragment>::@enum::E
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant T @24
              defaultType: dynamic
              metadata
                Annotation
                  atSign: @ @21
                  name: SimpleIdentifier
                    token: a @22
                    staticElement: <testLibraryFragment>::@getter::a
                    element: <testLibraryFragment>::@getter::a#element
                    staticType: null
                  element: <testLibraryFragment>::@getter::a
                  element2: <testLibraryFragment>::@getter::a#element
          supertype: Enum
          fields
            static const enumConstant v @31
              reference: <testLibraryFragment>::@enum::E::@field::v
              enclosingElement3: <testLibraryFragment>::@enum::E
              type: E<dynamic>
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E
                      element2: <testLibraryFragment>::@enum::E#element
                      type: E<dynamic>
                    staticElement: ConstructorMember
                      base: <testLibraryFragment>::@enum::E::@constructor::new
                      substitution: {T: dynamic}
                    element: <testLibraryFragment>::@enum::E::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E<dynamic>
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              enclosingElement3: <testLibraryFragment>::@enum::E
              type: List<E<dynamic>>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::v
                      element: <testLibraryFragment>::@enum::E::@getter::v#element
                      staticType: E<dynamic>
                  rightBracket: ] @0
                  staticType: List<E<dynamic>>
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              enclosingElement3: <testLibraryFragment>::@enum::E
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: E<dynamic>
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: List<E<dynamic>>
      topLevelVariables
        static const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement3: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            IntegerLiteral
              literal: 42 @10
              staticType: int
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement3: <testLibraryFragment>
          returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      enums
        enum E @19
          reference: <testLibraryFragment>::@enum::E
          element: <testLibraryFragment>::@enum::E#element
          typeParameters
            T @24
              element: <not-implemented>
              metadata
                Annotation
                  atSign: @ @21
                  name: SimpleIdentifier
                    token: a @22
                    staticElement: <testLibraryFragment>::@getter::a
                    element: <testLibraryFragment>::@getter::a#element
                    staticType: null
                  element: <testLibraryFragment>::@getter::a
                  element2: <testLibraryFragment>::@getter::a#element
          fields
            enumConstant v @31
              reference: <testLibraryFragment>::@enum::E::@field::v
              element: <testLibraryFragment>::@enum::E::@field::v#element
              getter2: <testLibraryFragment>::@enum::E::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              element: <testLibraryFragment>::@enum::E::@field::values#element
              getter2: <testLibraryFragment>::@enum::E::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              element: <testLibraryFragment>::@enum::E::@constructor::new#element
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              element: <testLibraryFragment>::@enum::E::@getter::v#element
            get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              element: <testLibraryFragment>::@enum::E::@getter::values#element
      topLevelVariables
        const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <testLibraryFragment>::@topLevelVariable::a#element
          getter2: <testLibraryFragment>::@getter::a
      getters
        get a @-1
          reference: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
  enums
    enum E
      firstFragment: <testLibraryFragment>::@enum::E
      typeParameters
        T
          metadata
            Annotation
              atSign: @ @21
              name: SimpleIdentifier
                token: a @22
                staticElement: <testLibraryFragment>::@getter::a
                element: <testLibraryFragment>::@getter::a#element
                staticType: null
              element: <testLibraryFragment>::@getter::a
              element2: <testLibraryFragment>::@getter::a#element
      supertype: Enum
      fields
        static const v
          firstFragment: <testLibraryFragment>::@enum::E::@field::v
          type: E<dynamic>
          getter: <testLibraryFragment>::@enum::E::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
          type: List<E<dynamic>>
          getter: <testLibraryFragment>::@enum::E::@getter::values#element
      constructors
        synthetic const new
          firstFragment: <testLibraryFragment>::@enum::E::@constructor::new
      getters
        synthetic static get v
          firstFragment: <testLibraryFragment>::@enum::E::@getter::v
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::E::@getter::values
  topLevelVariables
    const a
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      type: int
      getter: <testLibraryFragment>::@getter::a#element
  getters
    synthetic static get a
      firstFragment: <testLibraryFragment>::@getter::a
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
      enclosingElement3: <null>
      enums
        enum E @22
          reference: <testLibraryFragment>::@enum::E
          enclosingElement3: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @14
              name: SimpleIdentifier
                token: a @15
                staticElement: <testLibraryFragment>::@getter::a
                element: <testLibraryFragment>::@getter::a#element
                staticType: null
              element: <testLibraryFragment>::@getter::a
              element2: <testLibraryFragment>::@getter::a#element
          supertype: Enum
          fields
            static const enumConstant v @26
              reference: <testLibraryFragment>::@enum::E::@field::v
              enclosingElement3: <testLibraryFragment>::@enum::E
              type: E
              shouldUseTypeForInitializerInference: false
              constantInitializer
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element: <testLibraryFragment>::@enum::E
                      element2: <testLibraryFragment>::@enum::E#element
                      type: E
                    staticElement: <testLibraryFragment>::@enum::E::@constructor::new
                    element: <testLibraryFragment>::@enum::E::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              enclosingElement3: <testLibraryFragment>::@enum::E
              type: List<E>
              constantInitializer
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      staticElement: <testLibraryFragment>::@enum::E::@getter::v
                      element: <testLibraryFragment>::@enum::E::@getter::v#element
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              enclosingElement3: <testLibraryFragment>::@enum::E
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: E
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              enclosingElement3: <testLibraryFragment>::@enum::E
              returnType: List<E>
      topLevelVariables
        static const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          enclosingElement3: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          constantInitializer
            IntegerLiteral
              literal: 42 @10
              staticType: int
      accessors
        synthetic static get a @-1
          reference: <testLibraryFragment>::@getter::a
          enclosingElement3: <testLibraryFragment>
          returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      enums
        enum E @22
          reference: <testLibraryFragment>::@enum::E
          element: <testLibraryFragment>::@enum::E#element
          fields
            enumConstant v @26
              reference: <testLibraryFragment>::@enum::E::@field::v
              element: <testLibraryFragment>::@enum::E::@field::v#element
              getter2: <testLibraryFragment>::@enum::E::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              element: <testLibraryFragment>::@enum::E::@field::values#element
              getter2: <testLibraryFragment>::@enum::E::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              element: <testLibraryFragment>::@enum::E::@constructor::new#element
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              element: <testLibraryFragment>::@enum::E::@getter::v#element
            get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              element: <testLibraryFragment>::@enum::E::@getter::values#element
      topLevelVariables
        const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <testLibraryFragment>::@topLevelVariable::a#element
          getter2: <testLibraryFragment>::@getter::a
      getters
        get a @-1
          reference: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
  enums
    enum E
      firstFragment: <testLibraryFragment>::@enum::E
      supertype: Enum
      fields
        static const v
          firstFragment: <testLibraryFragment>::@enum::E::@field::v
          type: E
          getter: <testLibraryFragment>::@enum::E::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
          type: List<E>
          getter: <testLibraryFragment>::@enum::E::@getter::values#element
      constructors
        synthetic const new
          firstFragment: <testLibraryFragment>::@enum::E::@constructor::new
      getters
        synthetic static get v
          firstFragment: <testLibraryFragment>::@enum::E::@getter::v
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::E::@getter::values
  topLevelVariables
    const a
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      type: int
      getter: <testLibraryFragment>::@getter::a#element
  getters
    synthetic static get a
      firstFragment: <testLibraryFragment>::@getter::a
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
  parts
    part_0
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
      previousFragment: <testLibraryFragment>
      enums
        enum A @27
          reference: <testLibrary>::@fragment::package:test/a.dart::@enum::A
          element: <testLibrary>::@fragment::package:test/a.dart::@enum::A#element
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            enumConstant v @33
              reference: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@field::v
              element: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@field::v#element
              getter2: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@getter::v
            values @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@field::values
              element: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@field::values#element
              getter2: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@constructor::new
              element: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@constructor::new#element
          getters
            get v @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@getter::v
              element: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@getter::v#element
            get values @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@getter::values
              element: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@getter::values#element
          methods
            foo @43
              reference: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@method::foo
              element: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@method::foo#element
        enum A @68
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibrary>::@fragment::package:test/a.dart::@enum::A#element
          previousFragment: <testLibrary>::@fragment::package:test/a.dart::@enum::A
          methods
            bar @80
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@method::bar
              element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@method::bar#element
  enums
    enum A
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enum::A
      supertype: Enum
      fields
        static const v
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@field::v
          type: A
          getter: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@getter::v#element
        synthetic static const values
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@field::values
          type: List<A>
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
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@method::foo
        bar
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
  parts
    part_0
    part_1
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
          element: <testLibraryFragment>::@enum::A#element
          nextFragment: <testLibrary>::@fragment::package:test/a1.dart::@enumAugmentation::A
          fields
            enumConstant v @43
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <testLibraryFragment>::@enum::A::@field::v#element
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <testLibraryFragment>::@enum::A::@field::values#element
              getter2: <testLibraryFragment>::@enum::A::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <testLibraryFragment>::@enum::A::@constructor::new#element
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <testLibraryFragment>::@enum::A::@getter::v#element
            get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <testLibraryFragment>::@enum::A::@getter::values#element
    <testLibrary>::@fragment::package:test/a1.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/a11.dart
      enums
        enum A @68
          reference: <testLibrary>::@fragment::package:test/a1.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A#element
          previousFragment: <testLibraryFragment>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/a11.dart::@enumAugmentation::A
    <testLibrary>::@fragment::package:test/a11.dart
      element: <testLibrary>
      previousFragment: <testLibrary>::@fragment::package:test/a1.dart
      nextFragment: <testLibrary>::@fragment::package:test/a12.dart
      enums
        enum A @32
          reference: <testLibrary>::@fragment::package:test/a11.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A#element
          previousFragment: <testLibrary>::@fragment::package:test/a1.dart::@enumAugmentation::A
          nextFragment: <testLibrary>::@fragment::package:test/a12.dart::@enumAugmentation::A
    <testLibrary>::@fragment::package:test/a12.dart
      element: <testLibrary>
      previousFragment: <testLibrary>::@fragment::package:test/a11.dart
      nextFragment: <testLibrary>::@fragment::package:test/a2.dart
      enums
        enum A @32
          reference: <testLibrary>::@fragment::package:test/a12.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A#element
          previousFragment: <testLibrary>::@fragment::package:test/a11.dart::@enumAugmentation::A
          nextFragment: <testLibrary>::@fragment::package:test/a2.dart::@enumAugmentation::A
    <testLibrary>::@fragment::package:test/a2.dart
      element: <testLibrary>
      previousFragment: <testLibrary>::@fragment::package:test/a12.dart
      nextFragment: <testLibrary>::@fragment::package:test/a21.dart
      enums
        enum A @68
          reference: <testLibrary>::@fragment::package:test/a2.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A#element
          previousFragment: <testLibrary>::@fragment::package:test/a12.dart::@enumAugmentation::A
          nextFragment: <testLibrary>::@fragment::package:test/a21.dart::@enumAugmentation::A
    <testLibrary>::@fragment::package:test/a21.dart
      element: <testLibrary>
      previousFragment: <testLibrary>::@fragment::package:test/a2.dart
      nextFragment: <testLibrary>::@fragment::package:test/a22.dart
      enums
        enum A @32
          reference: <testLibrary>::@fragment::package:test/a21.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A#element
          previousFragment: <testLibrary>::@fragment::package:test/a2.dart::@enumAugmentation::A
          nextFragment: <testLibrary>::@fragment::package:test/a22.dart::@enumAugmentation::A
    <testLibrary>::@fragment::package:test/a22.dart
      element: <testLibrary>
      previousFragment: <testLibrary>::@fragment::package:test/a21.dart
      enums
        enum A @32
          reference: <testLibrary>::@fragment::package:test/a22.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A#element
          previousFragment: <testLibrary>::@fragment::package:test/a21.dart::@enumAugmentation::A
  enums
    enum A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const v
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          type: A
          getter: <testLibraryFragment>::@enum::A::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          type: List<A>
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
  parts
    part_0
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
      previousFragment: <testLibraryFragment>
      enums
        enum A @35
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::0
          element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::0#element
          fields
            values @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::0::@field::values
              element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::0::@field::values#element
              getter2: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::0::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::0::@constructor::new
              element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::0::@constructor::new#element
          getters
            get values @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::0::@getter::values
              element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::0::@getter::values#element
          methods
            foo1 @47
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::0::@method::foo1
              element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::0::@method::foo1#element
        enum A @65
          reference: <testLibrary>::@fragment::package:test/a.dart::@enum::A
          element: <testLibrary>::@fragment::package:test/a.dart::@enum::A#element
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::1
          fields
            enumConstant v @71
              reference: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@field::v
              element: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@field::v#element
              getter2: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@getter::v
            values @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@field::values
              element: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@field::values#element
              getter2: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@constructor::new
              element: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@constructor::new#element
          getters
            get v @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@getter::v
              element: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@getter::v#element
            get values @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@getter::values
              element: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@getter::values#element
          methods
            foo2 @81
              reference: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@method::foo2
              element: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@method::foo2#element
        enum A @107
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::1
          element: <testLibrary>::@fragment::package:test/a.dart::@enum::A#element
          previousFragment: <testLibrary>::@fragment::package:test/a.dart::@enum::A
          methods
            foo3 @119
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::1::@method::foo3
              element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::1::@method::foo3#element
  enums
    enum A
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::0
      supertype: Enum
      fields
        synthetic static const values
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::0::@field::values
          type: List<A>
          getter: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::0::@getter::values#element
      constructors
        synthetic const new
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::0::@constructor::new
      getters
        synthetic static get values
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::0::@getter::values
      methods
        foo1
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::0::@method::foo1
    enum A
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enum::A
      supertype: Enum
      fields
        static const v
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@field::v
          type: A
          getter: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@getter::v#element
        synthetic static const values
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@field::values
          type: List<A>
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
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@method::foo2
        foo3
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
  parts
    part_0
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
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      enums
        enum A @49
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A#element
          nextFragment: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          fields
            values @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::values
              element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::values#element
              getter2: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructor::new
              element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructor::new#element
          getters
            get values @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::values
              element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::values#element
          methods
            foo1 @61
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@method::foo1
              element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@method::foo1#element
    <testLibrary>::@fragment::package:test/b.dart
      element: <testLibrary>
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @31
          reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A#element
          previousFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          methods
            foo2 @43
              reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@method::foo2
              element: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@method::foo2#element
  enums
    enum A
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
      supertype: Enum
      fields
        synthetic static const values
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::values
          type: List<A>
          getter: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::values#element
      constructors
        synthetic const new
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructor::new
      getters
        synthetic static get values
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::values
      methods
        foo1
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@method::foo1
        foo2
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
  parts
    part_0
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
                      element2: <testLibraryFragment>::@enum::A#element
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
                      element2: <testLibraryFragment>::@enum::A#element
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
          element: <testLibraryFragment>::@enum::A#element
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            enumConstant v1 @26
              reference: <testLibraryFragment>::@enum::A::@field::v1
              element: <testLibraryFragment>::@enum::A::@field::v1#element
              getter2: <testLibraryFragment>::@enum::A::@getter::v1
            values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <testLibraryFragment>::@enum::A::@field::values#element
              getter2: <testLibraryFragment>::@enum::A::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <testLibraryFragment>::@enum::A::@constructor::new#element
          getters
            get v1 @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v1
              element: <testLibraryFragment>::@enum::A::@getter::v1#element
            get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <testLibraryFragment>::@enum::A::@getter::values#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A#element
          previousFragment: <testLibraryFragment>::@enum::A
          fields
            enumConstant v2 @40
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::v2
              element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::v2#element
              getter2: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::v2
          getters
            get v2 @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::v2
              element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::v2#element
  enums
    enum A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const v1
          firstFragment: <testLibraryFragment>::@enum::A::@field::v1
          type: A
          getter: <testLibraryFragment>::@enum::A::@getter::v1#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          type: List<A>
          getter: <testLibraryFragment>::@enum::A::@getter::values#element
        static const v2
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::v2
          type: A
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
  parts
    part_0
    part_1
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
                      element2: <testLibraryFragment>::@enum::A#element
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
                      element2: <testLibraryFragment>::@enum::A#element
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
                      element2: <testLibraryFragment>::@enum::A#element
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
          element: <testLibraryFragment>::@enum::A#element
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            enumConstant v1 @41
              reference: <testLibraryFragment>::@enum::A::@field::v1
              element: <testLibraryFragment>::@enum::A::@field::v1#element
              getter2: <testLibraryFragment>::@enum::A::@getter::v1
            values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <testLibraryFragment>::@enum::A::@field::values#element
              getter2: <testLibraryFragment>::@enum::A::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <testLibraryFragment>::@enum::A::@constructor::new#element
          getters
            get v1 @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v1
              element: <testLibraryFragment>::@enum::A::@getter::v1#element
            get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <testLibraryFragment>::@enum::A::@getter::values#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A#element
          previousFragment: <testLibraryFragment>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          fields
            enumConstant v2 @40
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::v2
              element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::v2#element
              getter2: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::v2
          getters
            get v2 @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::v2
              element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::v2#element
    <testLibrary>::@fragment::package:test/b.dart
      element: <testLibrary>
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A#element
          previousFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            enumConstant v3 @40
              reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@field::v3
              element: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@field::v3#element
              getter2: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@getter::v3
          getters
            get v3 @-1
              reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@getter::v3
              element: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@getter::v3#element
  enums
    enum A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const v1
          firstFragment: <testLibraryFragment>::@enum::A::@field::v1
          type: A
          getter: <testLibraryFragment>::@enum::A::@getter::v1#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          type: List<A>
          getter: <testLibraryFragment>::@enum::A::@getter::values#element
        static const v2
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::v2
          type: A
          getter: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::v2#element
        static const v3
          firstFragment: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@field::v3
          type: A
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
  parts
    part_0
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
                      element2: <testLibraryFragment>::@enum::A#element
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
                      element2: <testLibraryFragment>::@enum::A#element
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
                      element2: <testLibraryFragment>::@enum::A#element
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
          element: <testLibraryFragment>::@enum::A#element
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            enumConstant v1 @26
              reference: <testLibraryFragment>::@enum::A::@field::v1
              element: <testLibraryFragment>::@enum::A::@field::v1#element
              getter2: <testLibraryFragment>::@enum::A::@getter::v1
            values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <testLibraryFragment>::@enum::A::@field::values#element
              getter2: <testLibraryFragment>::@enum::A::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <testLibraryFragment>::@enum::A::@constructor::new#element
          getters
            get v1 @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v1
              element: <testLibraryFragment>::@enum::A::@getter::v1#element
            get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <testLibraryFragment>::@enum::A::@getter::values#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A#element
          previousFragment: <testLibraryFragment>::@enum::A
          fields
            enumConstant v2 @40
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::v2
              element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::v2#element
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@fieldAugmentation::v2
              getter2: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::v2
            enumConstant v2 @54
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@fieldAugmentation::v2
              element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::v2#element
              previousFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::v2
          getters
            get v2 @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::v2
              element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::v2#element
  enums
    enum A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const v1
          firstFragment: <testLibraryFragment>::@enum::A::@field::v1
          type: A
          getter: <testLibraryFragment>::@enum::A::@getter::v1#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          type: List<A>
          getter: <testLibraryFragment>::@enum::A::@getter::values#element
        static const v2
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::v2
          type: A
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
  parts
    part_0
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
                      element2: <testLibraryFragment>::@enum::A#element
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
                      element2: <testLibraryFragment>::@enum::A#element
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
                      element2: <testLibraryFragment>::@enum::A#element
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
                      element2: <testLibraryFragment>::@enum::A#element
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
          element: <testLibraryFragment>::@enum::A#element
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            enumConstant v1 @26
              reference: <testLibraryFragment>::@enum::A::@field::v1
              element: <testLibraryFragment>::@enum::A::@field::v1#element
              getter2: <testLibraryFragment>::@enum::A::@getter::v1
            enumConstant v2 @30
              reference: <testLibraryFragment>::@enum::A::@field::v2
              element: <testLibraryFragment>::@enum::A::@field::v2#element
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@fieldAugmentation::v2
              getter2: <testLibraryFragment>::@enum::A::@getter::v2
            enumConstant v3 @34
              reference: <testLibraryFragment>::@enum::A::@field::v3
              element: <testLibraryFragment>::@enum::A::@field::v3#element
              getter2: <testLibraryFragment>::@enum::A::@getter::v3
            values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <testLibraryFragment>::@enum::A::@field::values#element
              getter2: <testLibraryFragment>::@enum::A::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <testLibraryFragment>::@enum::A::@constructor::new#element
          getters
            get v1 @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v1
              element: <testLibraryFragment>::@enum::A::@getter::v1#element
            get v2 @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v2
              element: <testLibraryFragment>::@enum::A::@getter::v2#element
            get v3 @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v3
              element: <testLibraryFragment>::@enum::A::@getter::v3#element
            get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <testLibraryFragment>::@enum::A::@getter::values#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A#element
          previousFragment: <testLibraryFragment>::@enum::A
          fields
            enumConstant v2 @48
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@fieldAugmentation::v2
              element: <testLibraryFragment>::@enum::A::@field::v2#element
              previousFragment: <testLibraryFragment>::@enum::A::@field::v2
  enums
    enum A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const v1
          firstFragment: <testLibraryFragment>::@enum::A::@field::v1
          type: A
          getter: <testLibraryFragment>::@enum::A::@getter::v1#element
        static const v3
          firstFragment: <testLibraryFragment>::@enum::A::@field::v3
          type: A
          getter: <testLibraryFragment>::@enum::A::@getter::v3#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          type: List<A>
          getter: <testLibraryFragment>::@enum::A::@getter::values#element
        static const v2
          firstFragment: <testLibraryFragment>::@enum::A::@field::v2
          type: A
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
  parts
    part_0
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
                      element2: <testLibraryFragment>::@enum::A#element
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
                      element2: <testLibraryFragment>::@enum::A#element
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
                      element2: <testLibraryFragment>::@enum::A#element
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
          element: <testLibraryFragment>::@enum::A#element
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            enumConstant v1 @26
              reference: <testLibraryFragment>::@enum::A::@field::v1
              element: <testLibraryFragment>::@enum::A::@field::v1#element
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@fieldAugmentation::v1
              getter2: <testLibraryFragment>::@enum::A::@getter::v1
            enumConstant v2 @33
              reference: <testLibraryFragment>::@enum::A::@field::v2
              element: <testLibraryFragment>::@enum::A::@field::v2#element
              getter2: <testLibraryFragment>::@enum::A::@getter::v2
            values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <testLibraryFragment>::@enum::A::@field::values#element
              getter2: <testLibraryFragment>::@enum::A::@getter::values
          constructors
            const new @48
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <testLibraryFragment>::@enum::A::@constructor::new#element
              formalParameters
                value @54
                  element: <testLibraryFragment>::@enum::A::@constructor::new::@parameter::value#element
          getters
            get v1 @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v1
              element: <testLibraryFragment>::@enum::A::@getter::v1#element
            get v2 @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v2
              element: <testLibraryFragment>::@enum::A::@getter::v2#element
            get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <testLibraryFragment>::@enum::A::@getter::values#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A#element
          previousFragment: <testLibraryFragment>::@enum::A
          fields
            enumConstant v1 @48
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@fieldAugmentation::v1
              element: <testLibraryFragment>::@enum::A::@field::v1#element
              previousFragment: <testLibraryFragment>::@enum::A::@field::v1
  enums
    enum A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const v2
          firstFragment: <testLibraryFragment>::@enum::A::@field::v2
          type: A
          getter: <testLibraryFragment>::@enum::A::@getter::v2#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          type: List<A>
          getter: <testLibraryFragment>::@enum::A::@getter::values#element
        static const v1
          firstFragment: <testLibraryFragment>::@enum::A::@field::v1
          type: A
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
  parts
    part_0
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
          element: <testLibraryFragment>::@enum::A#element
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            enumConstant v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <testLibraryFragment>::@enum::A::@field::v#element
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@fieldAugmentation::v
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            enumConstant v2 @29
              reference: <testLibraryFragment>::@enum::A::@field::v2
              element: <testLibraryFragment>::@enum::A::@field::v2#element
              getter2: <testLibraryFragment>::@enum::A::@getter::v2
            values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <testLibraryFragment>::@enum::A::@field::values#element
              getter2: <testLibraryFragment>::@enum::A::@getter::values
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <testLibraryFragment>::@enum::A::@getter::v#element
            get v2 @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v2
              element: <testLibraryFragment>::@enum::A::@getter::v2#element
            get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <testLibraryFragment>::@enum::A::@getter::values#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A#element
          previousFragment: <testLibraryFragment>::@enum::A
          typeParameters
            T @36
              element: <not-implemented>
          fields
            enumConstant v @51
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@fieldAugmentation::v
              element: <testLibraryFragment>::@enum::A::@field::v#element
              previousFragment: <testLibraryFragment>::@enum::A::@field::v
  enums
    enum A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const v2
          firstFragment: <testLibraryFragment>::@enum::A::@field::v2
          type: A
          getter: <testLibraryFragment>::@enum::A::@getter::v2#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          type: List<A>
          getter: <testLibraryFragment>::@enum::A::@getter::values#element
        static const v
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          type: A
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
  parts
    part_0
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
          element: <testLibraryFragment>::@enum::A#element
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            enumConstant v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <testLibraryFragment>::@enum::A::@field::v#element
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <testLibraryFragment>::@enum::A::@field::values#element
              getter2: <testLibraryFragment>::@enum::A::@getter::values
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <testLibraryFragment>::@enum::A::@getter::v#element
            get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <testLibraryFragment>::@enum::A::@getter::values#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A#element
          previousFragment: <testLibraryFragment>::@enum::A
          constructors
            const named @49
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructor::named
              element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructor::named#element
              periodOffset: 48
              nameEnd: 54
  enums
    enum A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const v
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          type: A
          getter: <testLibraryFragment>::@enum::A::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          type: List<A>
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
  parts
    part_0
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
          element: <testLibraryFragment>::@enum::A#element
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          typeParameters
            T1 @22
              element: <not-implemented>
          fields
            enumConstant v @30
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <testLibraryFragment>::@enum::A::@field::v#element
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <testLibraryFragment>::@enum::A::@field::values#element
              getter2: <testLibraryFragment>::@enum::A::@getter::values
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <testLibraryFragment>::@enum::A::@getter::v#element
            get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <testLibraryFragment>::@enum::A::@getter::values#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A#element
          previousFragment: <testLibraryFragment>::@enum::A
          typeParameters
            T2 @36
              element: <not-implemented>
          constructors
            const named @53
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructor::named
              element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructor::named#element
              periodOffset: 52
              nameEnd: 58
              formalParameters
                a @62
                  element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructor::named::@parameter::a#element
  enums
    enum A
      firstFragment: <testLibraryFragment>::@enum::A
      typeParameters
        T1
      supertype: Enum
      fields
        static const v
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          type: A<int>
          getter: <testLibraryFragment>::@enum::A::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          type: List<A<dynamic>>
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
  parts
    part_0
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
          element: <testLibraryFragment>::@enum::A#element
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            enumConstant v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <testLibraryFragment>::@enum::A::@field::v#element
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <testLibraryFragment>::@enum::A::@field::values#element
              getter2: <testLibraryFragment>::@enum::A::@getter::values
          constructors
            const new @37
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <testLibraryFragment>::@enum::A::@constructor::new#element
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <testLibraryFragment>::@enum::A::@getter::v#element
            get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <testLibraryFragment>::@enum::A::@getter::values#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A#element
          previousFragment: <testLibraryFragment>::@enum::A
          constructors
            const named @49
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructor::named
              element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructor::named#element
              periodOffset: 48
              nameEnd: 54
  enums
    enum A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const v
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          type: A
          getter: <testLibraryFragment>::@enum::A::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          type: List<A>
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
  parts
    part_0
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
          element: <testLibraryFragment>::@enum::A#element
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            enumConstant v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <testLibraryFragment>::@enum::A::@field::v#element
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <testLibraryFragment>::@enum::A::@field::values#element
              getter2: <testLibraryFragment>::@enum::A::@getter::values
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <testLibraryFragment>::@enum::A::@getter::v#element
            get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <testLibraryFragment>::@enum::A::@getter::values#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A#element
          previousFragment: <testLibraryFragment>::@enum::A
          constructors
            const new @47
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructor::new
              element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructor::new#element
  enums
    enum A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const v
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          type: A
          getter: <testLibraryFragment>::@enum::A::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          type: List<A>
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
  parts
    part_0
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
          element: <testLibraryFragment>::@enum::A#element
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            enumConstant v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <testLibraryFragment>::@enum::A::@field::v#element
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <testLibraryFragment>::@enum::A::@field::values#element
              getter2: <testLibraryFragment>::@enum::A::@getter::values
          constructors
            const named @39
              reference: <testLibraryFragment>::@enum::A::@constructor::named
              element: <testLibraryFragment>::@enum::A::@constructor::named#element
              periodOffset: 38
              nameEnd: 44
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <testLibraryFragment>::@enum::A::@getter::v#element
            get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <testLibraryFragment>::@enum::A::@getter::values#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A#element
          previousFragment: <testLibraryFragment>::@enum::A
          constructors
            const new @47
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructor::new
              element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructor::new#element
  enums
    enum A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const v
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          type: A
          getter: <testLibraryFragment>::@enum::A::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          type: List<A>
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
  parts
    part_0
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
                requiredPositional final this.f @60
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
          element: <testLibraryFragment>::@enum::A#element
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            enumConstant v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <testLibraryFragment>::@enum::A::@field::v#element
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <testLibraryFragment>::@enum::A::@field::values#element
              getter2: <testLibraryFragment>::@enum::A::@getter::values
            f @44
              reference: <testLibraryFragment>::@enum::A::@field::f
              element: <testLibraryFragment>::@enum::A::@field::f#element
              getter2: <testLibraryFragment>::@enum::A::@getter::f
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <testLibraryFragment>::@enum::A::@getter::v#element
            get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <testLibraryFragment>::@enum::A::@getter::values#element
            get f @-1
              reference: <testLibraryFragment>::@enum::A::@getter::f
              element: <testLibraryFragment>::@enum::A::@getter::f#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A#element
          previousFragment: <testLibraryFragment>::@enum::A
          constructors
            const named @49
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructor::named
              element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructor::named#element
              periodOffset: 48
              nameEnd: 54
              formalParameters
                this.f @60
                  element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructor::named::@parameter::f#element
  enums
    enum A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const v
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          type: A
          getter: <testLibraryFragment>::@enum::A::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          type: List<A>
          getter: <testLibraryFragment>::@enum::A::@getter::values#element
        final f
          firstFragment: <testLibraryFragment>::@enum::A::@field::f
          type: int
          getter: <testLibraryFragment>::@enum::A::@getter::f#element
      constructors
        const named
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructor::named
          formalParameters
            requiredPositional final f
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
  parts
    part_0
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
          element: <testLibraryFragment>::@enum::A#element
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            enumConstant v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <testLibraryFragment>::@enum::A::@field::v#element
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <testLibraryFragment>::@enum::A::@field::values#element
              getter2: <testLibraryFragment>::@enum::A::@getter::values
            f @41
              reference: <testLibraryFragment>::@enum::A::@field::f
              element: <testLibraryFragment>::@enum::A::@field::f#element
              getter2: <testLibraryFragment>::@enum::A::@getter::f
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <testLibraryFragment>::@enum::A::@getter::v#element
            get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <testLibraryFragment>::@enum::A::@getter::values#element
            get f @-1
              reference: <testLibraryFragment>::@enum::A::@getter::f
              element: <testLibraryFragment>::@enum::A::@getter::f#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A#element
          previousFragment: <testLibraryFragment>::@enum::A
          constructors
            const named @49
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructor::named
              element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructor::named#element
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
  enums
    enum A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const v
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          type: A
          getter: <testLibraryFragment>::@enum::A::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          type: List<A>
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
  parts
    part_0
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
          element: <testLibraryFragment>::@enum::A#element
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            enumConstant v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <testLibraryFragment>::@enum::A::@field::v#element
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <testLibraryFragment>::@enum::A::@field::values#element
              getter2: <testLibraryFragment>::@enum::A::@getter::values
            foo @41
              reference: <testLibraryFragment>::@enum::A::@field::foo
              element: <testLibraryFragment>::@enum::A::@field::foo#element
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@fieldAugmentation::foo
              getter2: <testLibraryFragment>::@enum::A::@getter::foo
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <testLibraryFragment>::@enum::A::@constructor::new#element
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <testLibraryFragment>::@enum::A::@getter::v#element
            get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <testLibraryFragment>::@enum::A::@getter::values#element
            get foo @-1
              reference: <testLibraryFragment>::@enum::A::@getter::foo
              element: <testLibraryFragment>::@enum::A::@getter::foo#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A#element
          previousFragment: <testLibraryFragment>::@enum::A
          fields
            foo @59
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@fieldAugmentation::foo
              element: <testLibraryFragment>::@enum::A::@field::foo#element
              previousFragment: <testLibraryFragment>::@enum::A::@field::foo
  enums
    enum A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const v
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          type: A
          getter: <testLibraryFragment>::@enum::A::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          type: List<A>
          getter: <testLibraryFragment>::@enum::A::@getter::values#element
        final foo
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
  parts
    part_0
    part_1
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
          element: <testLibraryFragment>::@enum::A#element
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            enumConstant v @41
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <testLibraryFragment>::@enum::A::@field::v#element
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <testLibraryFragment>::@enum::A::@field::values#element
              getter2: <testLibraryFragment>::@enum::A::@getter::values
            foo @56
              reference: <testLibraryFragment>::@enum::A::@field::foo
              element: <testLibraryFragment>::@enum::A::@field::foo#element
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@fieldAugmentation::foo
              getter2: <testLibraryFragment>::@enum::A::@getter::foo
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <testLibraryFragment>::@enum::A::@constructor::new#element
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <testLibraryFragment>::@enum::A::@getter::v#element
            get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <testLibraryFragment>::@enum::A::@getter::values#element
            get foo @-1
              reference: <testLibraryFragment>::@enum::A::@getter::foo
              element: <testLibraryFragment>::@enum::A::@getter::foo#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A#element
          previousFragment: <testLibraryFragment>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          fields
            foo @59
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@fieldAugmentation::foo
              element: <testLibraryFragment>::@enum::A::@field::foo#element
              previousFragment: <testLibraryFragment>::@enum::A::@field::foo
              nextFragment: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@fieldAugmentation::foo
    <testLibrary>::@fragment::package:test/b.dart
      element: <testLibrary>
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A#element
          previousFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            foo @59
              reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@fieldAugmentation::foo
              element: <testLibraryFragment>::@enum::A::@field::foo#element
              previousFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@fieldAugmentation::foo
  enums
    enum A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const v
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          type: A
          getter: <testLibraryFragment>::@enum::A::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          type: List<A>
          getter: <testLibraryFragment>::@enum::A::@getter::values#element
        final foo
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
  parts
    part_0
    part_1
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
              variable: field_2
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
          element: <testLibraryFragment>::@enum::A#element
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            enumConstant v @41
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <testLibraryFragment>::@enum::A::@field::v#element
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <testLibraryFragment>::@enum::A::@field::values#element
              getter2: <testLibraryFragment>::@enum::A::@getter::values
            foo @56
              reference: <testLibraryFragment>::@enum::A::@field::foo
              element: <testLibraryFragment>::@enum::A::@field::foo#element
              nextFragment: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@fieldAugmentation::foo
              getter2: <testLibraryFragment>::@enum::A::@getter::foo
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <testLibraryFragment>::@enum::A::@constructor::new#element
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <testLibraryFragment>::@enum::A::@getter::v#element
            get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <testLibraryFragment>::@enum::A::@getter::values#element
            get foo @-1
              reference: <testLibraryFragment>::@enum::A::@getter::foo
              element: <testLibraryFragment>::@enum::A::@getter::foo#element
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getterAugmentation::foo
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A#element
          previousFragment: <testLibraryFragment>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          getters
            augment get foo @57
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getterAugmentation::foo
              element: <testLibraryFragment>::@enum::A::@getter::foo#element
              previousFragment: <testLibraryFragment>::@enum::A::@getter::foo
    <testLibrary>::@fragment::package:test/b.dart
      element: <testLibrary>
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A#element
          previousFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            foo @59
              reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@fieldAugmentation::foo
              element: <testLibraryFragment>::@enum::A::@field::foo#element
              previousFragment: <testLibraryFragment>::@enum::A::@field::foo
  enums
    enum A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const v
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          type: A
          getter: <testLibraryFragment>::@enum::A::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          type: List<A>
          getter: <testLibraryFragment>::@enum::A::@getter::values#element
        final foo
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
  parts
    part_0
    part_1
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
          element: <testLibraryFragment>::@enum::A#element
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            enumConstant v @41
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <testLibraryFragment>::@enum::A::@field::v#element
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <testLibraryFragment>::@enum::A::@field::values#element
              getter2: <testLibraryFragment>::@enum::A::@getter::values
            foo @56
              reference: <testLibraryFragment>::@enum::A::@field::foo
              element: <testLibraryFragment>::@enum::A::@field::foo#element
              nextFragment: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@fieldAugmentation::foo
              getter2: <testLibraryFragment>::@enum::A::@getter::foo
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <testLibraryFragment>::@enum::A::@constructor::new#element
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <testLibraryFragment>::@enum::A::@getter::v#element
            get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <testLibraryFragment>::@enum::A::@getter::values#element
            get foo @-1
              reference: <testLibraryFragment>::@enum::A::@getter::foo
              element: <testLibraryFragment>::@enum::A::@getter::foo#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A#element
          previousFragment: <testLibraryFragment>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          setters
            augment set foo= @53
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@setterAugmentation::foo
              element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@setterAugmentation::foo#element
              formalParameters
                _ @61
                  element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@setterAugmentation::foo::@parameter::_#element
    <testLibrary>::@fragment::package:test/b.dart
      element: <testLibrary>
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A#element
          previousFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            foo @59
              reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@fieldAugmentation::foo
              element: <testLibraryFragment>::@enum::A::@field::foo#element
              previousFragment: <testLibraryFragment>::@enum::A::@field::foo
  enums
    enum A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const v
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          type: A
          getter: <testLibraryFragment>::@enum::A::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          type: List<A>
          getter: <testLibraryFragment>::@enum::A::@getter::values#element
        final foo
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
        synthetic get foo
          firstFragment: <testLibraryFragment>::@enum::A::@getter::foo
      setters
        set foo=
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
  parts
    part_0
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
          element: <testLibraryFragment>::@enum::A#element
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            enumConstant v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <testLibraryFragment>::@enum::A::@field::v#element
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <testLibraryFragment>::@enum::A::@field::values#element
              getter2: <testLibraryFragment>::@enum::A::@getter::values
            foo @41
              reference: <testLibraryFragment>::@enum::A::@field::foo
              element: <testLibraryFragment>::@enum::A::@field::foo#element
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@fieldAugmentation::foo
              getter2: <testLibraryFragment>::@enum::A::@getter::foo
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <testLibraryFragment>::@enum::A::@constructor::new#element
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <testLibraryFragment>::@enum::A::@getter::v#element
            get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <testLibraryFragment>::@enum::A::@getter::values#element
            get foo @-1
              reference: <testLibraryFragment>::@enum::A::@getter::foo
              element: <testLibraryFragment>::@enum::A::@getter::foo#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A#element
          previousFragment: <testLibraryFragment>::@enum::A
          fields
            foo @62
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@fieldAugmentation::foo
              element: <testLibraryFragment>::@enum::A::@field::foo#element
              previousFragment: <testLibraryFragment>::@enum::A::@field::foo
  enums
    enum A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const v
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          type: A
          getter: <testLibraryFragment>::@enum::A::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          type: List<A>
          getter: <testLibraryFragment>::@enum::A::@getter::values#element
        final foo
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
  parts
    part_0
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
                      element2: <testLibraryFragment>::@enum::A#element
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
          element: <testLibraryFragment>::@enum::A#element
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            enumConstant v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <testLibraryFragment>::@enum::A::@field::v#element
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <testLibraryFragment>::@enum::A::@field::values#element
              getter2: <testLibraryFragment>::@enum::A::@getter::values
            foo @52
              reference: <testLibraryFragment>::@enum::A::@field::foo
              element: <testLibraryFragment>::@enum::A::@field::foo#element
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@fieldAugmentation::foo
              getter2: <testLibraryFragment>::@enum::A::@getter::foo
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <testLibraryFragment>::@enum::A::@constructor::new#element
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <testLibraryFragment>::@enum::A::@getter::v#element
            get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <testLibraryFragment>::@enum::A::@getter::values#element
            get foo @-1
              reference: <testLibraryFragment>::@enum::A::@getter::foo
              element: <testLibraryFragment>::@enum::A::@getter::foo#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A#element
          previousFragment: <testLibraryFragment>::@enum::A
          fields
            foo @70
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@fieldAugmentation::foo
              element: <testLibraryFragment>::@enum::A::@field::foo#element
              previousFragment: <testLibraryFragment>::@enum::A::@field::foo
  enums
    enum A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const v
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          type: A
          getter: <testLibraryFragment>::@enum::A::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          type: List<A>
          getter: <testLibraryFragment>::@enum::A::@getter::values#element
        final foo
          firstFragment: <testLibraryFragment>::@enum::A::@field::foo
          type: int Function()
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
  parts
    part_0
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
          element: <testLibraryFragment>::@enum::A#element
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            enumConstant v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <testLibraryFragment>::@enum::A::@field::v#element
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <testLibraryFragment>::@enum::A::@field::values#element
              getter2: <testLibraryFragment>::@enum::A::@getter::values
            foo @-1
              reference: <testLibraryFragment>::@enum::A::@field::foo
              element: <testLibraryFragment>::@enum::A::@field::foo#element
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@fieldAugmentation::foo
              getter2: <testLibraryFragment>::@enum::A::@getter::foo
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <testLibraryFragment>::@enum::A::@constructor::new#element
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <testLibraryFragment>::@enum::A::@getter::v#element
            get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <testLibraryFragment>::@enum::A::@getter::values#element
            get foo @39
              reference: <testLibraryFragment>::@enum::A::@getter::foo
              element: <testLibraryFragment>::@enum::A::@getter::foo#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A#element
          previousFragment: <testLibraryFragment>::@enum::A
          fields
            foo @59
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@fieldAugmentation::foo
              element: <testLibraryFragment>::@enum::A::@field::foo#element
              previousFragment: <testLibraryFragment>::@enum::A::@field::foo
  enums
    enum A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const v
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          type: A
          getter: <testLibraryFragment>::@enum::A::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          type: List<A>
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
  parts
    part_0
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
          element: <testLibraryFragment>::@enum::A#element
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            enumConstant v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <testLibraryFragment>::@enum::A::@field::v#element
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <testLibraryFragment>::@enum::A::@field::values#element
              getter2: <testLibraryFragment>::@enum::A::@getter::values
            foo1 @41
              reference: <testLibraryFragment>::@enum::A::@field::foo1
              element: <testLibraryFragment>::@enum::A::@field::foo1#element
              getter2: <testLibraryFragment>::@enum::A::@getter::foo1
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <testLibraryFragment>::@enum::A::@constructor::new#element
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <testLibraryFragment>::@enum::A::@getter::v#element
            get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <testLibraryFragment>::@enum::A::@getter::values#element
            get foo1 @-1
              reference: <testLibraryFragment>::@enum::A::@getter::foo1
              element: <testLibraryFragment>::@enum::A::@getter::foo1#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A#element
          previousFragment: <testLibraryFragment>::@enum::A
          fields
            foo2 @51
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::foo2
              element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::foo2#element
              getter2: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::foo2
          getters
            get foo2 @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::foo2
              element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::foo2#element
  enums
    enum A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const v
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          type: A
          getter: <testLibraryFragment>::@enum::A::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          type: List<A>
          getter: <testLibraryFragment>::@enum::A::@getter::values#element
        final foo1
          firstFragment: <testLibraryFragment>::@enum::A::@field::foo1
          type: int
          getter: <testLibraryFragment>::@enum::A::@getter::foo1#element
        final foo2
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
  parts
    part_0
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
          element: <testLibraryFragment>::@enum::A#element
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          typeParameters
            T1 @22
              element: <not-implemented>
          fields
            enumConstant v @30
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <testLibraryFragment>::@enum::A::@field::v#element
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <testLibraryFragment>::@enum::A::@field::values#element
              getter2: <testLibraryFragment>::@enum::A::@getter::values
            foo1 @51
              reference: <testLibraryFragment>::@enum::A::@field::foo1
              element: <testLibraryFragment>::@enum::A::@field::foo1#element
              getter2: <testLibraryFragment>::@enum::A::@getter::foo1
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <testLibraryFragment>::@enum::A::@constructor::new#element
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <testLibraryFragment>::@enum::A::@getter::v#element
            get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <testLibraryFragment>::@enum::A::@getter::values#element
            get foo1 @-1
              reference: <testLibraryFragment>::@enum::A::@getter::foo1
              element: <testLibraryFragment>::@enum::A::@getter::foo1#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A#element
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
            get foo2 @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::foo2
              element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::foo2#element
  enums
    enum A
      firstFragment: <testLibraryFragment>::@enum::A
      typeParameters
        T1
      supertype: Enum
      fields
        static const v
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          type: A<int>
          getter: <testLibraryFragment>::@enum::A::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          type: List<A<dynamic>>
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
  parts
    part_0
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
                requiredPositional final this.foo @47
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
          element: <testLibraryFragment>::@enum::A#element
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            enumConstant v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <testLibraryFragment>::@enum::A::@field::v#element
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <testLibraryFragment>::@enum::A::@field::values#element
              getter2: <testLibraryFragment>::@enum::A::@getter::values
          constructors
            const new @40
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <testLibraryFragment>::@enum::A::@constructor::new#element
              formalParameters
                this.foo @47
                  element: <testLibraryFragment>::@enum::A::@constructor::new::@parameter::foo#element
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <testLibraryFragment>::@enum::A::@getter::v#element
            get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <testLibraryFragment>::@enum::A::@getter::values#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A#element
          previousFragment: <testLibraryFragment>::@enum::A
          fields
            foo @51
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::foo
              element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::foo#element
              getter2: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::foo
          getters
            get foo @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::foo
              element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::foo#element
  enums
    enum A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const v
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          type: A
          getter: <testLibraryFragment>::@enum::A::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          type: List<A>
          getter: <testLibraryFragment>::@enum::A::@getter::values#element
        final foo
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::foo
          type: int
          getter: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::foo#element
      constructors
        const new
          firstFragment: <testLibraryFragment>::@enum::A::@constructor::new
          formalParameters
            requiredPositional final foo
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
  parts
    part_0
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
          element: <testLibraryFragment>::@enum::A#element
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            enumConstant v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <testLibraryFragment>::@enum::A::@field::v#element
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <testLibraryFragment>::@enum::A::@field::values#element
              getter2: <testLibraryFragment>::@enum::A::@getter::values
          constructors
            const new @37
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <testLibraryFragment>::@enum::A::@constructor::new#element
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
            get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <testLibraryFragment>::@enum::A::@getter::v#element
            get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <testLibraryFragment>::@enum::A::@getter::values#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A#element
          previousFragment: <testLibraryFragment>::@enum::A
          fields
            foo @51
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::foo
              element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::foo#element
              getter2: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::foo
          getters
            get foo @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::foo
              element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::foo#element
  enums
    enum A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const v
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          type: A
          getter: <testLibraryFragment>::@enum::A::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          type: List<A>
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
  parts
    part_0
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
          element: <testLibraryFragment>::@enum::A#element
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            enumConstant v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <testLibraryFragment>::@enum::A::@field::v#element
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <testLibraryFragment>::@enum::A::@field::values#element
              getter2: <testLibraryFragment>::@enum::A::@getter::values
            foo1 @-1
              reference: <testLibraryFragment>::@enum::A::@field::foo1
              element: <testLibraryFragment>::@enum::A::@field::foo1#element
              getter2: <testLibraryFragment>::@enum::A::@getter::foo1
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <testLibraryFragment>::@enum::A::@constructor::new#element
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <testLibraryFragment>::@enum::A::@getter::v#element
            get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <testLibraryFragment>::@enum::A::@getter::values#element
            get foo1 @39
              reference: <testLibraryFragment>::@enum::A::@getter::foo1
              element: <testLibraryFragment>::@enum::A::@getter::foo1#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A#element
          previousFragment: <testLibraryFragment>::@enum::A
          fields
            foo2 @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::foo2
              element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::foo2#element
              getter2: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::foo2
          getters
            get foo2 @49
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::foo2
              element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::foo2#element
  enums
    enum A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const v
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          type: A
          getter: <testLibraryFragment>::@enum::A::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          type: List<A>
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
  parts
    part_0
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
          element: <testLibraryFragment>::@enum::A#element
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          typeParameters
            T1 @22
              element: <not-implemented>
          fields
            enumConstant v @30
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <testLibraryFragment>::@enum::A::@field::v#element
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <testLibraryFragment>::@enum::A::@field::values#element
              getter2: <testLibraryFragment>::@enum::A::@getter::values
            foo1 @-1
              reference: <testLibraryFragment>::@enum::A::@field::foo1
              element: <testLibraryFragment>::@enum::A::@field::foo1#element
              getter2: <testLibraryFragment>::@enum::A::@getter::foo1
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <testLibraryFragment>::@enum::A::@constructor::new#element
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <testLibraryFragment>::@enum::A::@getter::v#element
            get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <testLibraryFragment>::@enum::A::@getter::values#element
            get foo1 @49
              reference: <testLibraryFragment>::@enum::A::@getter::foo1
              element: <testLibraryFragment>::@enum::A::@getter::foo1#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A#element
          previousFragment: <testLibraryFragment>::@enum::A
          typeParameters
            T1 @36
              element: <not-implemented>
          fields
            foo2 @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::foo2
              element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::foo2#element
              getter2: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::foo2
          getters
            get foo2 @52
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::foo2
              element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::foo2#element
  enums
    enum A
      firstFragment: <testLibraryFragment>::@enum::A
      typeParameters
        T1
      supertype: Enum
      fields
        static const v
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          type: A<int>
          getter: <testLibraryFragment>::@enum::A::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          type: List<A<dynamic>>
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
  parts
    part_0
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
              variable: field_2
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
          element: <testLibraryFragment>::@enum::A#element
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            enumConstant v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <testLibraryFragment>::@enum::A::@field::v#element
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <testLibraryFragment>::@enum::A::@field::values#element
              getter2: <testLibraryFragment>::@enum::A::@getter::values
            foo @41
              reference: <testLibraryFragment>::@enum::A::@field::foo
              element: <testLibraryFragment>::@enum::A::@field::foo#element
              getter2: <testLibraryFragment>::@enum::A::@getter::foo
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <testLibraryFragment>::@enum::A::@constructor::new#element
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <testLibraryFragment>::@enum::A::@getter::v#element
            get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <testLibraryFragment>::@enum::A::@getter::values#element
            get foo @-1
              reference: <testLibraryFragment>::@enum::A::@getter::foo
              element: <testLibraryFragment>::@enum::A::@getter::foo#element
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getterAugmentation::foo
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A#element
          previousFragment: <testLibraryFragment>::@enum::A
          getters
            augment get foo @57
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getterAugmentation::foo
              element: <testLibraryFragment>::@enum::A::@getter::foo#element
              previousFragment: <testLibraryFragment>::@enum::A::@getter::foo
  enums
    enum A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const v
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          type: A
          getter: <testLibraryFragment>::@enum::A::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          type: List<A>
          getter: <testLibraryFragment>::@enum::A::@getter::values#element
        final foo
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
  parts
    part_0
    part_1
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
              variable: field_2
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
              variable: field_2
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
          element: <testLibraryFragment>::@enum::A#element
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            enumConstant v @41
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <testLibraryFragment>::@enum::A::@field::v#element
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <testLibraryFragment>::@enum::A::@field::values#element
              getter2: <testLibraryFragment>::@enum::A::@getter::values
            foo @56
              reference: <testLibraryFragment>::@enum::A::@field::foo
              element: <testLibraryFragment>::@enum::A::@field::foo#element
              getter2: <testLibraryFragment>::@enum::A::@getter::foo
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <testLibraryFragment>::@enum::A::@constructor::new#element
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <testLibraryFragment>::@enum::A::@getter::v#element
            get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <testLibraryFragment>::@enum::A::@getter::values#element
            get foo @-1
              reference: <testLibraryFragment>::@enum::A::@getter::foo
              element: <testLibraryFragment>::@enum::A::@getter::foo#element
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getterAugmentation::foo
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A#element
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
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A#element
          previousFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          getters
            augment get foo @57
              reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@getterAugmentation::foo
              element: <testLibraryFragment>::@enum::A::@getter::foo#element
              previousFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getterAugmentation::foo
  enums
    enum A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const v
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          type: A
          getter: <testLibraryFragment>::@enum::A::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          type: List<A>
          getter: <testLibraryFragment>::@enum::A::@getter::values#element
        final foo
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
  parts
    part_0
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
              variable: field_2
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
          element: <testLibraryFragment>::@enum::A#element
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            enumConstant v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <testLibraryFragment>::@enum::A::@field::v#element
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <testLibraryFragment>::@enum::A::@field::values#element
              getter2: <testLibraryFragment>::@enum::A::@getter::values
            foo1 @-1
              reference: <testLibraryFragment>::@enum::A::@field::foo1
              element: <testLibraryFragment>::@enum::A::@field::foo1#element
              getter2: <testLibraryFragment>::@enum::A::@getter::foo1
            foo2 @-1
              reference: <testLibraryFragment>::@enum::A::@field::foo2
              element: <testLibraryFragment>::@enum::A::@field::foo2#element
              getter2: <testLibraryFragment>::@enum::A::@getter::foo2
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <testLibraryFragment>::@enum::A::@constructor::new#element
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <testLibraryFragment>::@enum::A::@getter::v#element
            get values @-1
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
      previousFragment: <testLibraryFragment>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A#element
          previousFragment: <testLibraryFragment>::@enum::A
          getters
            augment get foo1 @57
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getterAugmentation::foo1
              element: <testLibraryFragment>::@enum::A::@getter::foo1#element
              previousFragment: <testLibraryFragment>::@enum::A::@getter::foo1
  enums
    enum A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const v
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          type: A
          getter: <testLibraryFragment>::@enum::A::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          type: List<A>
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
  parts
    part_0
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
              variable: field_2
              augmentationTarget: <testLibraryFragment>::@enum::A::@getter::foo
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getterAugmentation::foo::@def::1
            augment get foo @85
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getterAugmentation::foo::@def::1
              enclosingElement3: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              returnType: int
              id: getter_4
              variable: field_2
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
          element: <testLibraryFragment>::@enum::A#element
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            enumConstant v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <testLibraryFragment>::@enum::A::@field::v#element
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <testLibraryFragment>::@enum::A::@field::values#element
              getter2: <testLibraryFragment>::@enum::A::@getter::values
            foo @-1
              reference: <testLibraryFragment>::@enum::A::@field::foo
              element: <testLibraryFragment>::@enum::A::@field::foo#element
              getter2: <testLibraryFragment>::@enum::A::@getter::foo
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <testLibraryFragment>::@enum::A::@constructor::new#element
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <testLibraryFragment>::@enum::A::@getter::v#element
            get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <testLibraryFragment>::@enum::A::@getter::values#element
            get foo @39
              reference: <testLibraryFragment>::@enum::A::@getter::foo
              element: <testLibraryFragment>::@enum::A::@getter::foo#element
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getterAugmentation::foo::@def::0
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A#element
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
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const v
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          type: A
          getter: <testLibraryFragment>::@enum::A::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          type: List<A>
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
  parts
    part_0
    part_1
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
              variable: field_2
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
              variable: field_2
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
          element: <testLibraryFragment>::@enum::A#element
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            enumConstant v @41
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <testLibraryFragment>::@enum::A::@field::v#element
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <testLibraryFragment>::@enum::A::@field::values#element
              getter2: <testLibraryFragment>::@enum::A::@getter::values
            foo @-1
              reference: <testLibraryFragment>::@enum::A::@field::foo
              element: <testLibraryFragment>::@enum::A::@field::foo#element
              getter2: <testLibraryFragment>::@enum::A::@getter::foo
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <testLibraryFragment>::@enum::A::@constructor::new#element
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <testLibraryFragment>::@enum::A::@getter::v#element
            get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <testLibraryFragment>::@enum::A::@getter::values#element
            get foo @54
              reference: <testLibraryFragment>::@enum::A::@getter::foo
              element: <testLibraryFragment>::@enum::A::@getter::foo#element
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getterAugmentation::foo
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A#element
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
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A#element
          previousFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          getters
            augment get foo @57
              reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@getterAugmentation::foo
              element: <testLibraryFragment>::@enum::A::@getter::foo#element
              previousFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getterAugmentation::foo
  enums
    enum A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const v
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          type: A
          getter: <testLibraryFragment>::@enum::A::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          type: List<A>
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
  parts
    part_0
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
          element: <testLibraryFragment>::@enum::A#element
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            enumConstant v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <testLibraryFragment>::@enum::A::@field::v#element
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <testLibraryFragment>::@enum::A::@field::values#element
              getter2: <testLibraryFragment>::@enum::A::@getter::values
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <testLibraryFragment>::@enum::A::@getter::v#element
            get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <testLibraryFragment>::@enum::A::@getter::values#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A#element
          previousFragment: <testLibraryFragment>::@enum::A
          getters
            augment get foo @57
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getterAugmentation::foo
              element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getterAugmentation::foo#element
  enums
    enum A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const v
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          type: A
          getter: <testLibraryFragment>::@enum::A::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          type: List<A>
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
  parts
    part_0
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
          element: <testLibraryFragment>::@class::I1#element
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::I1::@constructor::new
              element: <testLibraryFragment>::@class::I1::@constructor::new#element
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          element: <testLibraryFragment>::@enum::A#element
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            enumConstant v @40
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <testLibraryFragment>::@enum::A::@field::v#element
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <testLibraryFragment>::@enum::A::@field::values#element
              getter2: <testLibraryFragment>::@enum::A::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <testLibraryFragment>::@enum::A::@constructor::new#element
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <testLibraryFragment>::@enum::A::@getter::v#element
            get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <testLibraryFragment>::@enum::A::@getter::values#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      classes
        class I2 @59
          reference: <testLibrary>::@fragment::package:test/a.dart::@class::I2
          element: <testLibrary>::@fragment::package:test/a.dart::@class::I2#element
          constructors
            synthetic new @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@class::I2::@constructor::new
              element: <testLibrary>::@fragment::package:test/a.dart::@class::I2::@constructor::new#element
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A#element
          previousFragment: <testLibraryFragment>::@enum::A
  classes
    class I1
      firstFragment: <testLibraryFragment>::@class::I1
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::I1::@constructor::new
    class I2
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@class::I2
      constructors
        synthetic new
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@class::I2::@constructor::new
  enums
    enum A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const v
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          type: A
          getter: <testLibraryFragment>::@enum::A::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          type: List<A>
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
  parts
    part_0
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
          element: <testLibraryFragment>::@class::I1#element
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::I1::@constructor::new
              element: <testLibraryFragment>::@class::I1::@constructor::new#element
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          element: <testLibraryFragment>::@enum::A#element
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            enumConstant v @40
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <testLibraryFragment>::@enum::A::@field::v#element
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <testLibraryFragment>::@enum::A::@field::values#element
              getter2: <testLibraryFragment>::@enum::A::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <testLibraryFragment>::@enum::A::@constructor::new#element
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <testLibraryFragment>::@enum::A::@getter::v#element
            get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <testLibraryFragment>::@enum::A::@getter::values#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      classes
        class I2 @74
          reference: <testLibrary>::@fragment::package:test/a.dart::@class::I2
          element: <testLibrary>::@fragment::package:test/a.dart::@class::I2#element
          constructors
            synthetic new @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@class::I2::@constructor::new
              element: <testLibrary>::@fragment::package:test/a.dart::@class::I2::@constructor::new#element
      enums
        enum A @49
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A#element
          previousFragment: <testLibraryFragment>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
    <testLibrary>::@fragment::package:test/b.dart
      element: <testLibrary>
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      classes
        class I3 @56
          reference: <testLibrary>::@fragment::package:test/b.dart::@class::I3
          element: <testLibrary>::@fragment::package:test/b.dart::@class::I3#element
          constructors
            synthetic new @-1
              reference: <testLibrary>::@fragment::package:test/b.dart::@class::I3::@constructor::new
              element: <testLibrary>::@fragment::package:test/b.dart::@class::I3::@constructor::new#element
      enums
        enum A @31
          reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A#element
          previousFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
  classes
    class I1
      firstFragment: <testLibraryFragment>::@class::I1
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::I1::@constructor::new
    class I2
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@class::I2
      constructors
        synthetic new
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@class::I2::@constructor::new
    class I3
      firstFragment: <testLibrary>::@fragment::package:test/b.dart::@class::I3
      constructors
        synthetic new
          firstFragment: <testLibrary>::@fragment::package:test/b.dart::@class::I3::@constructor::new
  enums
    enum A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const v
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          type: A
          getter: <testLibraryFragment>::@enum::A::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          type: List<A>
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
  parts
    part_0
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
          element: <testLibraryFragment>::@class::I1#element
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::I1::@constructor::new
              element: <testLibraryFragment>::@class::I1::@constructor::new#element
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          element: <testLibraryFragment>::@enum::A#element
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          typeParameters
            T @22
              element: <not-implemented>
          fields
            enumConstant v @43
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <testLibraryFragment>::@enum::A::@field::v#element
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <testLibraryFragment>::@enum::A::@field::values#element
              getter2: <testLibraryFragment>::@enum::A::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <testLibraryFragment>::@enum::A::@constructor::new#element
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <testLibraryFragment>::@enum::A::@getter::v#element
            get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <testLibraryFragment>::@enum::A::@getter::values#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      classes
        class I2 @67
          reference: <testLibrary>::@fragment::package:test/a.dart::@class::I2
          element: <testLibrary>::@fragment::package:test/a.dart::@class::I2#element
          typeParameters
            E @70
              element: <not-implemented>
          constructors
            synthetic new @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@class::I2::@constructor::new
              element: <testLibrary>::@fragment::package:test/a.dart::@class::I2::@constructor::new#element
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A#element
          previousFragment: <testLibraryFragment>::@enum::A
          typeParameters
            T2 @36
              element: <not-implemented>
  classes
    class I1
      firstFragment: <testLibraryFragment>::@class::I1
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::I1::@constructor::new
    class I2
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@class::I2
      typeParameters
        E
      constructors
        synthetic new
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@class::I2::@constructor::new
  enums
    enum A
      firstFragment: <testLibraryFragment>::@enum::A
      typeParameters
        T
      supertype: Enum
      fields
        static const v
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          type: A<int>
          getter: <testLibraryFragment>::@enum::A::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          type: List<A<dynamic>>
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
  parts
    part_0
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
          element: <testLibraryFragment>::@class::I1#element
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::I1::@constructor::new
              element: <testLibraryFragment>::@class::I1::@constructor::new#element
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          element: <testLibraryFragment>::@enum::A#element
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          typeParameters
            T @22
              element: <not-implemented>
          fields
            enumConstant v @43
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <testLibraryFragment>::@enum::A::@field::v#element
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <testLibraryFragment>::@enum::A::@field::values#element
              getter2: <testLibraryFragment>::@enum::A::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <testLibraryFragment>::@enum::A::@constructor::new#element
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <testLibraryFragment>::@enum::A::@getter::v#element
            get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <testLibraryFragment>::@enum::A::@getter::values#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      classes
        class I2 @71
          reference: <testLibrary>::@fragment::package:test/a.dart::@class::I2
          element: <testLibrary>::@fragment::package:test/a.dart::@class::I2#element
          typeParameters
            E @74
              element: <not-implemented>
          constructors
            synthetic new @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@class::I2::@constructor::new
              element: <testLibrary>::@fragment::package:test/a.dart::@class::I2::@constructor::new#element
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A#element
          previousFragment: <testLibraryFragment>::@enum::A
          typeParameters
            T2 @36
              element: <not-implemented>
            T3 @40
              element: <not-implemented>
  classes
    class I1
      firstFragment: <testLibraryFragment>::@class::I1
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::I1::@constructor::new
    class I2
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@class::I2
      typeParameters
        E
      constructors
        synthetic new
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@class::I2::@constructor::new
  enums
    enum A
      firstFragment: <testLibraryFragment>::@enum::A
      typeParameters
        T
      supertype: Enum
      fields
        static const v
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          type: A<dynamic>
          getter: <testLibraryFragment>::@enum::A::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          type: List<A<dynamic>>
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
  parts
    part_0
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
          element: <testLibraryFragment>::@enum::A#element
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            enumConstant v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <testLibraryFragment>::@enum::A::@field::v#element
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <testLibraryFragment>::@enum::A::@field::values#element
              getter2: <testLibraryFragment>::@enum::A::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <testLibraryFragment>::@enum::A::@constructor::new#element
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <testLibraryFragment>::@enum::A::@getter::v#element
            get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <testLibraryFragment>::@enum::A::@getter::values#element
          methods
            foo @36
              reference: <testLibraryFragment>::@enum::A::@method::foo
              element: <testLibraryFragment>::@enum::A::@method::foo#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A#element
          previousFragment: <testLibraryFragment>::@enum::A
          methods
            bar @46
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@method::bar
              element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@method::bar#element
  enums
    enum A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const v
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          type: A
          getter: <testLibraryFragment>::@enum::A::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          type: List<A>
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
          firstFragment: <testLibraryFragment>::@enum::A::@method::foo
        bar
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
  parts
    part_0
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
                      element2: <testLibraryFragment>::@enum::A#element
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
          element: <testLibraryFragment>::@enum::A#element
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            enumConstant v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <testLibraryFragment>::@enum::A::@field::v#element
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <testLibraryFragment>::@enum::A::@field::values#element
              getter2: <testLibraryFragment>::@enum::A::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <testLibraryFragment>::@enum::A::@constructor::new#element
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <testLibraryFragment>::@enum::A::@getter::v#element
            get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <testLibraryFragment>::@enum::A::@getter::values#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A#element
          previousFragment: <testLibraryFragment>::@enum::A
          methods
            foo @46
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@method::foo
              element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@method::foo#element
              formalParameters
                default x @55
                  element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@method::foo::@parameter::x#element
  enums
    enum A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const v
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          type: A
          getter: <testLibraryFragment>::@enum::A::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          type: List<A>
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
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@method::foo
          formalParameters
            optionalPositional x
              type: int
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
  parts
    part_0
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
          element: <testLibraryFragment>::@enum::A#element
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            enumConstant v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <testLibraryFragment>::@enum::A::@field::v#element
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <testLibraryFragment>::@enum::A::@field::values#element
              getter2: <testLibraryFragment>::@enum::A::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <testLibraryFragment>::@enum::A::@constructor::new#element
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <testLibraryFragment>::@enum::A::@getter::v#element
            get values @-1
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
      previousFragment: <testLibraryFragment>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A#element
          previousFragment: <testLibraryFragment>::@enum::A
          methods
            augment foo1 @54
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@methodAugmentation::foo1
              element: <testLibraryFragment>::@enum::A::@method::foo1#element
              previousFragment: <testLibraryFragment>::@enum::A::@method::foo1
  enums
    enum A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const v
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          type: A
          getter: <testLibraryFragment>::@enum::A::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          type: List<A>
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
        foo2
          firstFragment: <testLibraryFragment>::@enum::A::@method::foo2
        foo1
          firstFragment: <testLibraryFragment>::@enum::A::@method::foo1
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
  parts
    part_0
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
          element: <testLibraryFragment>::@enum::A#element
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            enumConstant v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <testLibraryFragment>::@enum::A::@field::v#element
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <testLibraryFragment>::@enum::A::@field::values#element
              getter2: <testLibraryFragment>::@enum::A::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <testLibraryFragment>::@enum::A::@constructor::new#element
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <testLibraryFragment>::@enum::A::@getter::v#element
            get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <testLibraryFragment>::@enum::A::@getter::values#element
          methods
            foo @36
              reference: <testLibraryFragment>::@enum::A::@method::foo
              element: <testLibraryFragment>::@enum::A::@method::foo#element
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@methodAugmentation::foo::@def::0
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A#element
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
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const v
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          type: A
          getter: <testLibraryFragment>::@enum::A::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          type: List<A>
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
  parts
    part_0
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
          element: <testLibraryFragment>::@enum::A#element
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::0
          fields
            enumConstant v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <testLibraryFragment>::@enum::A::@field::v#element
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <testLibraryFragment>::@enum::A::@field::values#element
              getter2: <testLibraryFragment>::@enum::A::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <testLibraryFragment>::@enum::A::@constructor::new#element
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <testLibraryFragment>::@enum::A::@getter::v#element
            get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <testLibraryFragment>::@enum::A::@getter::values#element
          methods
            foo @36
              reference: <testLibraryFragment>::@enum::A::@method::foo
              element: <testLibraryFragment>::@enum::A::@method::foo#element
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::0::@methodAugmentation::foo
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::0
          element: <testLibraryFragment>::@enum::A#element
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
          element: <testLibraryFragment>::@enum::A#element
          previousFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::0
          methods
            augment foo @98
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::1::@methodAugmentation::foo
              element: <testLibraryFragment>::@enum::A::@method::foo#element
              previousFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::0::@methodAugmentation::foo
  enums
    enum A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const v
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          type: A
          getter: <testLibraryFragment>::@enum::A::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          type: List<A>
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
  parts
    part_0
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
          element: <testLibraryFragment>::@enum::A#element
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            enumConstant v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <testLibraryFragment>::@enum::A::@field::v#element
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <testLibraryFragment>::@enum::A::@field::values#element
              getter2: <testLibraryFragment>::@enum::A::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <testLibraryFragment>::@enum::A::@constructor::new#element
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <testLibraryFragment>::@enum::A::@getter::v#element
            get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <testLibraryFragment>::@enum::A::@getter::values#element
          methods
            foo @36
              reference: <testLibraryFragment>::@enum::A::@method::foo
              element: <testLibraryFragment>::@enum::A::@method::foo#element
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@methodAugmentation::foo
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      enums
        enum A @49
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A#element
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
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @31
          reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A#element
          previousFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          methods
            augment foo @51
              reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@methodAugmentation::foo
              element: <testLibraryFragment>::@enum::A::@method::foo#element
              previousFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@methodAugmentation::foo
  enums
    enum A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const v
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          type: A
          getter: <testLibraryFragment>::@enum::A::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          type: List<A>
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
  parts
    part_0
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
          element: <testLibraryFragment>::@enum::A#element
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          typeParameters
            T @22
              element: <not-implemented>
          fields
            enumConstant v @29
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <testLibraryFragment>::@enum::A::@field::v#element
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <testLibraryFragment>::@enum::A::@field::values#element
              getter2: <testLibraryFragment>::@enum::A::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <testLibraryFragment>::@enum::A::@constructor::new#element
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <testLibraryFragment>::@enum::A::@getter::v#element
            get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <testLibraryFragment>::@enum::A::@getter::values#element
          methods
            foo @43
              reference: <testLibraryFragment>::@enum::A::@method::foo
              element: <testLibraryFragment>::@enum::A::@method::foo#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A#element
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
      firstFragment: <testLibraryFragment>::@enum::A
      typeParameters
        T
      supertype: Enum
      fields
        static const v
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          type: A<int>
          getter: <testLibraryFragment>::@enum::A::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          type: List<A<dynamic>>
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
          firstFragment: <testLibraryFragment>::@enum::A::@method::foo
        bar
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
  parts
    part_0
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
          element: <testLibraryFragment>::@enum::A#element
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          typeParameters
            T @22
              element: <not-implemented>
          fields
            enumConstant v @29
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <testLibraryFragment>::@enum::A::@field::v#element
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <testLibraryFragment>::@enum::A::@field::values#element
              getter2: <testLibraryFragment>::@enum::A::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <testLibraryFragment>::@enum::A::@constructor::new#element
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <testLibraryFragment>::@enum::A::@getter::v#element
            get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <testLibraryFragment>::@enum::A::@getter::values#element
          methods
            foo @43
              reference: <testLibraryFragment>::@enum::A::@method::foo
              element: <testLibraryFragment>::@enum::A::@method::foo#element
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@methodAugmentation::foo
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A#element
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
      firstFragment: <testLibraryFragment>::@enum::A
      typeParameters
        T
      supertype: Enum
      fields
        static const v
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          type: A<int>
          getter: <testLibraryFragment>::@enum::A::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          type: List<A<dynamic>>
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
  parts
    part_0
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
          element: <testLibraryFragment>::@enum::A#element
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            enumConstant v @34
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <testLibraryFragment>::@enum::A::@field::v#element
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <testLibraryFragment>::@enum::A::@field::values#element
              getter2: <testLibraryFragment>::@enum::A::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <testLibraryFragment>::@enum::A::@constructor::new#element
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <testLibraryFragment>::@enum::A::@getter::v#element
            get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <testLibraryFragment>::@enum::A::@getter::values#element
      mixins
        mixin M1 @44
          reference: <testLibraryFragment>::@mixin::M1
          element: <testLibraryFragment>::@mixin::M1#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A#element
          previousFragment: <testLibraryFragment>::@enum::A
      mixins
        mixin M2 @53
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixin::M2
          element: <testLibrary>::@fragment::package:test/a.dart::@mixin::M2#element
  enums
    enum A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const v
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          type: A
          getter: <testLibraryFragment>::@enum::A::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          type: List<A>
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
      firstFragment: <testLibraryFragment>::@mixin::M1
      superclassConstraints
        Object
    mixin M2
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
  parts
    part_0
    part_1
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
          element: <testLibraryFragment>::@enum::A#element
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          typeParameters
            T1 @37
              element: <not-implemented>
          fields
            enumConstant v @57
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <testLibraryFragment>::@enum::A::@field::v#element
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <testLibraryFragment>::@enum::A::@field::values#element
              getter2: <testLibraryFragment>::@enum::A::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <testLibraryFragment>::@enum::A::@constructor::new#element
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <testLibraryFragment>::@enum::A::@getter::v#element
            get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <testLibraryFragment>::@enum::A::@getter::values#element
      mixins
        mixin M1 @74
          reference: <testLibraryFragment>::@mixin::M1
          element: <testLibraryFragment>::@mixin::M1#element
          typeParameters
            U1 @77
              element: <not-implemented>
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A#element
          previousFragment: <testLibraryFragment>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          typeParameters
            T2 @36
              element: <not-implemented>
      mixins
        mixin M2 @57
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixin::M2
          element: <testLibrary>::@fragment::package:test/a.dart::@mixin::M2#element
          typeParameters
            U2 @60
              element: <not-implemented>
    <testLibrary>::@fragment::package:test/b.dart
      element: <testLibrary>
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A#element
          previousFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          typeParameters
            T3 @36
              element: <not-implemented>
      mixins
        mixin M3 @57
          reference: <testLibrary>::@fragment::package:test/b.dart::@mixin::M3
          element: <testLibrary>::@fragment::package:test/b.dart::@mixin::M3#element
          typeParameters
            U3 @60
              element: <not-implemented>
  enums
    enum A
      firstFragment: <testLibraryFragment>::@enum::A
      typeParameters
        T1
      supertype: Enum
      fields
        static const v
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          type: A<int>
          getter: <testLibraryFragment>::@enum::A::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          type: List<A<dynamic>>
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
      firstFragment: <testLibraryFragment>::@mixin::M1
      typeParameters
        U1
      superclassConstraints
        Object
    mixin M2
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@mixin::M2
      typeParameters
        U2
      superclassConstraints
        M1<U2>
    mixin M3
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
  parts
    part_0
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
          element: <testLibraryFragment>::@enum::A#element
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            enumConstant v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <testLibraryFragment>::@enum::A::@field::v#element
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <testLibraryFragment>::@enum::A::@field::values#element
              getter2: <testLibraryFragment>::@enum::A::@getter::values
            foo1 @-1
              reference: <testLibraryFragment>::@enum::A::@field::foo1
              element: <testLibraryFragment>::@enum::A::@field::foo1#element
              setter2: <testLibraryFragment>::@enum::A::@setter::foo1
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <testLibraryFragment>::@enum::A::@constructor::new#element
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <testLibraryFragment>::@enum::A::@getter::v#element
            get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <testLibraryFragment>::@enum::A::@getter::values#element
          setters
            set foo1= @35
              reference: <testLibraryFragment>::@enum::A::@setter::foo1
              element: <testLibraryFragment>::@enum::A::@setter::foo1#element
              formalParameters
                _ @44
                  element: <testLibraryFragment>::@enum::A::@setter::foo1::@parameter::_#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A#element
          previousFragment: <testLibraryFragment>::@enum::A
          fields
            foo2 @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::foo2
              element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::foo2#element
              setter2: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@setter::foo2
          setters
            set foo2= @45
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@setter::foo2
              element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@setter::foo2#element
              formalParameters
                _ @54
                  element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@setter::foo2::@parameter::_#element
  enums
    enum A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const v
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          type: A
          getter: <testLibraryFragment>::@enum::A::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          type: List<A>
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
        set foo1=
          firstFragment: <testLibraryFragment>::@enum::A::@setter::foo1
          formalParameters
            requiredPositional _
              type: int
        set foo2=
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
  parts
    part_0
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
          element: <testLibraryFragment>::@enum::A#element
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            enumConstant v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <testLibraryFragment>::@enum::A::@field::v#element
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <testLibraryFragment>::@enum::A::@field::values#element
              getter2: <testLibraryFragment>::@enum::A::@getter::values
            foo @41
              reference: <testLibraryFragment>::@enum::A::@field::foo
              element: <testLibraryFragment>::@enum::A::@field::foo#element
              getter2: <testLibraryFragment>::@enum::A::@getter::foo
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <testLibraryFragment>::@enum::A::@constructor::new#element
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <testLibraryFragment>::@enum::A::@getter::v#element
            get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <testLibraryFragment>::@enum::A::@getter::values#element
            get foo @-1
              reference: <testLibraryFragment>::@enum::A::@getter::foo
              element: <testLibraryFragment>::@enum::A::@getter::foo#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A#element
          previousFragment: <testLibraryFragment>::@enum::A
          setters
            augment set foo= @53
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@setterAugmentation::foo
              element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@setterAugmentation::foo#element
              formalParameters
                _ @61
                  element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@setterAugmentation::foo::@parameter::_#element
  enums
    enum A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const v
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          type: A
          getter: <testLibraryFragment>::@enum::A::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          type: List<A>
          getter: <testLibraryFragment>::@enum::A::@getter::values#element
        final foo
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
        synthetic get foo
          firstFragment: <testLibraryFragment>::@enum::A::@getter::foo
      setters
        set foo=
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
  parts
    part_0
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
          element: <testLibraryFragment>::@enum::A#element
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            enumConstant v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <testLibraryFragment>::@enum::A::@field::v#element
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <testLibraryFragment>::@enum::A::@field::values#element
              getter2: <testLibraryFragment>::@enum::A::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <testLibraryFragment>::@enum::A::@constructor::new#element
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <testLibraryFragment>::@enum::A::@getter::v#element
            get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <testLibraryFragment>::@enum::A::@getter::values#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A#element
          previousFragment: <testLibraryFragment>::@enum::A
          setters
            augment set foo= @53
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@setterAugmentation::foo
              element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@setterAugmentation::foo#element
              formalParameters
                _ @61
                  element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@setterAugmentation::foo::@parameter::_#element
  enums
    enum A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const v
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          type: A
          getter: <testLibraryFragment>::@enum::A::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          type: List<A>
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
        set foo=
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
  parts
    part_0
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
              variable: field_2
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
          element: <testLibraryFragment>::@enum::A#element
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            enumConstant v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <testLibraryFragment>::@enum::A::@field::v#element
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <testLibraryFragment>::@enum::A::@field::values#element
              getter2: <testLibraryFragment>::@enum::A::@getter::values
            foo1 @-1
              reference: <testLibraryFragment>::@enum::A::@field::foo1
              element: <testLibraryFragment>::@enum::A::@field::foo1#element
              setter2: <testLibraryFragment>::@enum::A::@setter::foo1
            foo2 @-1
              reference: <testLibraryFragment>::@enum::A::@field::foo2
              element: <testLibraryFragment>::@enum::A::@field::foo2#element
              setter2: <testLibraryFragment>::@enum::A::@setter::foo2
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <testLibraryFragment>::@enum::A::@constructor::new#element
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <testLibraryFragment>::@enum::A::@getter::v#element
            get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <testLibraryFragment>::@enum::A::@getter::values#element
          setters
            set foo1= @35
              reference: <testLibraryFragment>::@enum::A::@setter::foo1
              element: <testLibraryFragment>::@enum::A::@setter::foo1#element
              formalParameters
                _ @44
                  element: <testLibraryFragment>::@enum::A::@setter::foo1::@parameter::_#element
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@setterAugmentation::foo1
            set foo2= @56
              reference: <testLibraryFragment>::@enum::A::@setter::foo2
              element: <testLibraryFragment>::@enum::A::@setter::foo2#element
              formalParameters
                _ @65
                  element: <testLibraryFragment>::@enum::A::@setter::foo2::@parameter::_#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A#element
          previousFragment: <testLibraryFragment>::@enum::A
          setters
            augment set foo1= @53
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@setterAugmentation::foo1
              element: <testLibraryFragment>::@enum::A::@setter::foo1#element
              formalParameters
                _ @62
                  element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@setterAugmentation::foo1::@parameter::_#element
              previousFragment: <testLibraryFragment>::@enum::A::@setter::foo1
  enums
    enum A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const v
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          type: A
          getter: <testLibraryFragment>::@enum::A::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          type: List<A>
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
        set foo2=
          firstFragment: <testLibraryFragment>::@enum::A::@setter::foo2
          formalParameters
            requiredPositional _
              type: int
        set foo1=
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
  parts
    part_0
    part_1
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
      classes
        augment class A @36
          reference: <testLibrary>::@fragment::package:test/b.dart::@classAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/b.dart
          augmentationTargetAny: <testLibraryFragment>::@enum::A
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
          element: <testLibraryFragment>::@enum::A#element
          fields
            enumConstant v @39
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <testLibraryFragment>::@enum::A::@field::v#element
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <testLibraryFragment>::@enum::A::@field::values#element
              getter2: <testLibraryFragment>::@enum::A::@getter::values
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <testLibraryFragment>::@enum::A::@getter::v#element
            get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <testLibraryFragment>::@enum::A::@getter::values#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      classes
        class A @36
          reference: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A
          element: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A#element
    <testLibrary>::@fragment::package:test/b.dart
      element: <testLibrary>
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      classes
        class A @36
          reference: <testLibrary>::@fragment::package:test/b.dart::@classAugmentation::A
          element: <testLibrary>::@fragment::package:test/b.dart::@classAugmentation::A#element
  classes
    class A
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A
    class A
      firstFragment: <testLibrary>::@fragment::package:test/b.dart::@classAugmentation::A
  enums
    enum A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const v
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          type: A
          getter: <testLibraryFragment>::@enum::A::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          type: List<A>
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
  parts
    part_0
    part_1
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
          augmentation: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
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
          augmentationTarget: <testLibraryFragment>::@enum::A
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
          element: <testLibraryFragment>::@enum::A#element
          nextFragment: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          fields
            enumConstant v @39
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <testLibraryFragment>::@enum::A::@field::v#element
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <testLibraryFragment>::@enum::A::@field::values#element
              getter2: <testLibraryFragment>::@enum::A::@getter::values
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <testLibraryFragment>::@enum::A::@getter::v#element
            get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <testLibraryFragment>::@enum::A::@getter::values#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      classes
        class A @36
          reference: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A
          element: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A#element
    <testLibrary>::@fragment::package:test/b.dart
      element: <testLibrary>
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @35
          reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A#element
          previousFragment: <testLibraryFragment>::@enum::A
  classes
    class A
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A
  enums
    enum A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const v
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          type: A
          getter: <testLibraryFragment>::@enum::A::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          type: List<A>
          getter: <testLibraryFragment>::@enum::A::@getter::values#element
      getters
        synthetic static get v
          firstFragment: <testLibraryFragment>::@enum::A::@getter::v
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::A::@getter::values
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
  parts
    part_0
    part_1
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
          element: <testLibraryFragment>::@enum::A#element
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            enumConstant v @41
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <testLibraryFragment>::@enum::A::@field::v#element
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <testLibraryFragment>::@enum::A::@field::values#element
              getter2: <testLibraryFragment>::@enum::A::@getter::values
          constructors
            const named @62
              reference: <testLibraryFragment>::@enum::A::@constructor::named
              element: <testLibraryFragment>::@enum::A::@constructor::named#element
              periodOffset: 61
              nameEnd: 67
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructorAugmentation::named
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <testLibraryFragment>::@enum::A::@getter::v#element
            get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <testLibraryFragment>::@enum::A::@getter::values#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A#element
          previousFragment: <testLibraryFragment>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          constructors
            augment const named @57
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructorAugmentation::named
              element: <testLibraryFragment>::@enum::A::@constructor::named#element
              periodOffset: 56
              nameEnd: 62
              nextFragment: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@constructorAugmentation::named
              previousFragment: <testLibraryFragment>::@enum::A::@constructor::named
    <testLibrary>::@fragment::package:test/b.dart
      element: <testLibrary>
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A#element
          previousFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          constructors
            augment const named @57
              reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@constructorAugmentation::named
              element: <testLibraryFragment>::@enum::A::@constructor::named#element
              periodOffset: 56
              nameEnd: 62
              previousFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructorAugmentation::named
  enums
    enum A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const v
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          type: A
          getter: <testLibraryFragment>::@enum::A::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          type: List<A>
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
  parts
    part_0
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
                      element2: <testLibraryFragment>::@enum::A#element
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
          element: <testLibraryFragment>::@enum::A#element
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            enumConstant v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <testLibraryFragment>::@enum::A::@field::v#element
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <testLibraryFragment>::@enum::A::@field::values#element
              getter2: <testLibraryFragment>::@enum::A::@getter::values
          constructors
            const named @47
              reference: <testLibraryFragment>::@enum::A::@constructor::named
              element: <testLibraryFragment>::@enum::A::@constructor::named#element
              periodOffset: 46
              nameEnd: 52
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructorAugmentation::named
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <testLibraryFragment>::@enum::A::@getter::v#element
            get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <testLibraryFragment>::@enum::A::@getter::values#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A#element
          previousFragment: <testLibraryFragment>::@enum::A
          constructors
            augment const named @57
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructorAugmentation::named
              element: <testLibraryFragment>::@enum::A::@constructor::named#element
              periodOffset: 56
              nameEnd: 62
              previousFragment: <testLibraryFragment>::@enum::A::@constructor::named
  enums
    enum A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const v
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          type: A
          getter: <testLibraryFragment>::@enum::A::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          type: List<A>
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
  parts
    part_0
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
                      element2: <testLibraryFragment>::@enum::A#element
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
          element: <testLibraryFragment>::@enum::A#element
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            enumConstant v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <testLibraryFragment>::@enum::A::@field::v#element
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <testLibraryFragment>::@enum::A::@field::values#element
              getter2: <testLibraryFragment>::@enum::A::@getter::values
          constructors
            const new @37
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <testLibraryFragment>::@enum::A::@constructor::new#element
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructorAugmentation::new
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <testLibraryFragment>::@enum::A::@getter::v#element
            get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <testLibraryFragment>::@enum::A::@getter::values#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A#element
          previousFragment: <testLibraryFragment>::@enum::A
          constructors
            augment const new @55
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructorAugmentation::new
              element: <testLibraryFragment>::@enum::A::@constructor::new#element
              previousFragment: <testLibraryFragment>::@enum::A::@constructor::new
  enums
    enum A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const v
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          type: A
          getter: <testLibraryFragment>::@enum::A::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          type: List<A>
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
  libraryImports
    package:test/a.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  parts
    part_0
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
                requiredPositional a @45
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
          element: <testLibraryFragment>::@enum::B#element
          nextFragment: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::B
          fields
            enumConstant v @57
              reference: <testLibraryFragment>::@enum::B::@field::v
              element: <testLibraryFragment>::@enum::B::@field::v#element
              getter2: <testLibraryFragment>::@enum::B::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::B::@field::values
              element: <testLibraryFragment>::@enum::B::@field::values#element
              getter2: <testLibraryFragment>::@enum::B::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::B::@constructor::new
              element: <testLibraryFragment>::@enum::B::@constructor::new#element
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::B::@getter::v
              element: <testLibraryFragment>::@enum::B::@getter::v#element
            get values @-1
              reference: <testLibraryFragment>::@enum::B::@getter::values
              element: <testLibraryFragment>::@enum::B::@getter::values#element
    <testLibrary>::@fragment::package:test/b.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      enums
        enum B @34
          reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::B
          element: <testLibraryFragment>::@enum::B#element
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
      firstFragment: <testLibraryFragment>::@enum::B
      supertype: Enum
      fields
        static const v
          firstFragment: <testLibraryFragment>::@enum::B::@field::v
          type: B
          getter: <testLibraryFragment>::@enum::B::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::B::@field::values
          type: List<B>
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
          firstFragment: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::B::@method::foo
          formalParameters
            requiredPositional a
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
  parts
    part_0
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
                requiredPositional a @36
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
          element: <testLibraryFragment>::@enum::B#element
          nextFragment: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::B
          fields
            enumConstant v @27
              reference: <testLibraryFragment>::@enum::B::@field::v
              element: <testLibraryFragment>::@enum::B::@field::v#element
              getter2: <testLibraryFragment>::@enum::B::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::B::@field::values
              element: <testLibraryFragment>::@enum::B::@field::values#element
              getter2: <testLibraryFragment>::@enum::B::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::B::@constructor::new
              element: <testLibraryFragment>::@enum::B::@constructor::new#element
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::B::@getter::v
              element: <testLibraryFragment>::@enum::B::@getter::v#element
            get values @-1
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
      previousFragment: <testLibraryFragment>
      libraryImports
        package:test/a.dart
      enums
        enum B @51
          reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::B
          element: <testLibraryFragment>::@enum::B#element
          previousFragment: <testLibraryFragment>::@enum::B
  enums
    enum B
      firstFragment: <testLibraryFragment>::@enum::B
      supertype: Enum
      fields
        static const v
          firstFragment: <testLibraryFragment>::@enum::B::@field::v
          type: B
          getter: <testLibraryFragment>::@enum::B::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::B::@field::values
          type: List<B>
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
          firstFragment: <testLibraryFragment>::@enum::B::@method::foo
          formalParameters
            requiredPositional a
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
  parts
    part_0
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
                requiredPositional a @36
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
          element: <testLibraryFragment>::@enum::B#element
          nextFragment: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::B
          fields
            enumConstant v @27
              reference: <testLibraryFragment>::@enum::B::@field::v
              element: <testLibraryFragment>::@enum::B::@field::v#element
              getter2: <testLibraryFragment>::@enum::B::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::B::@field::values
              element: <testLibraryFragment>::@enum::B::@field::values#element
              getter2: <testLibraryFragment>::@enum::B::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::B::@constructor::new
              element: <testLibraryFragment>::@enum::B::@constructor::new#element
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::B::@getter::v
              element: <testLibraryFragment>::@enum::B::@getter::v#element
            get values @-1
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
      previousFragment: <testLibraryFragment>
      libraryImports
        package:test/a.dart
      enums
        enum B @51
          reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::B
          element: <testLibraryFragment>::@enum::B#element
          previousFragment: <testLibraryFragment>::@enum::B
  enums
    enum B
      firstFragment: <testLibraryFragment>::@enum::B
      supertype: Enum
      fields
        static const v
          firstFragment: <testLibraryFragment>::@enum::B::@field::v
          type: B
          getter: <testLibraryFragment>::@enum::B::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::B::@field::values
          type: List<B>
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
          firstFragment: <testLibraryFragment>::@enum::B::@method::foo
          formalParameters
            requiredPositional a
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
  parts
    part_0
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
          element: <testLibraryFragment>::@class::B#element
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::B::@constructor::new
              element: <testLibraryFragment>::@class::B::@constructor::new#element
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          element: <testLibraryFragment>::@enum::A#element
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          typeParameters
            T @22
              element: <not-implemented>
          fields
            enumConstant v @39
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <testLibraryFragment>::@enum::A::@field::v#element
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <testLibraryFragment>::@enum::A::@field::values#element
              getter2: <testLibraryFragment>::@enum::A::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <testLibraryFragment>::@enum::A::@constructor::new#element
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <testLibraryFragment>::@enum::A::@getter::v#element
            get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <testLibraryFragment>::@enum::A::@getter::values#element
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A#element
          previousFragment: <testLibraryFragment>::@enum::A
          typeParameters
            T @36
              element: <not-implemented>
  classes
    class B
      firstFragment: <testLibraryFragment>::@class::B
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::B::@constructor::new
  enums
    enum A
      firstFragment: <testLibraryFragment>::@enum::A
      typeParameters
        T
          bound: B
      supertype: Enum
      fields
        static const v
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          type: A<B>
          getter: <testLibraryFragment>::@enum::A::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          type: List<A<B>>
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
