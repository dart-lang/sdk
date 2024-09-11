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
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          element: <testLibraryFragment>::@enum::E
          fields
            enumConstant aaa @11
              reference: <testLibraryFragment>::@enum::E::@field::aaa
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::aaa
            enumConstant bbb @16
              reference: <testLibraryFragment>::@enum::E::@field::bbb
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::bbb
            enumConstant ccc @21
              reference: <testLibraryFragment>::@enum::E::@field::ccc
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::ccc
            values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              element: <none>
          getters
            get aaa @-1
              reference: <testLibraryFragment>::@enum::E::@getter::aaa
              element: <none>
            get bbb @-1
              reference: <testLibraryFragment>::@enum::E::@getter::bbb
              element: <none>
            get ccc @-1
              reference: <testLibraryFragment>::@enum::E::@getter::ccc
              element: <none>
            get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              element: <none>
  enums
    enum E
      reference: <testLibraryFragment>::@enum::E
      codeOffset: 0
      codeLength: 26
      firstFragment: <testLibraryFragment>::@enum::E
      supertype: Enum
      fields
        static const aaa
          reference: <none>
          type: E
          firstFragment: <testLibraryFragment>::@enum::E::@field::aaa
          getter: <none>
        static const bbb
          reference: <none>
          type: E
          firstFragment: <testLibraryFragment>::@enum::E::@field::bbb
          getter: <none>
        static const ccc
          reference: <none>
          type: E
          firstFragment: <testLibraryFragment>::@enum::E::@field::ccc
          getter: <none>
        synthetic static const values
          reference: <none>
          type: List<E>
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
          getter: <none>
      constructors
        synthetic const new
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@constructor::new
      getters
        synthetic static get aaa
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@getter::aaa
        synthetic static get bbb
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@getter::bbb
        synthetic static get ccc
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@getter::ccc
        synthetic static get values
          reference: <none>
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
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          element: <testLibraryFragment>::@enum::E
          typeParameters
            T @7
              element: <none>
          fields
            enumConstant int @14
              reference: <testLibraryFragment>::@enum::E::@field::int
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::int
            enumConstant string @22
              reference: <testLibraryFragment>::@enum::E::@field::string
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::string
            values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::values
          constructors
            const new @43
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              element: <none>
              parameters
                a @47
                  element: <none>
          getters
            get int @-1
              reference: <testLibraryFragment>::@enum::E::@getter::int
              element: <none>
            get string @-1
              reference: <testLibraryFragment>::@enum::E::@getter::string
              element: <none>
            get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              element: <none>
  enums
    enum E
      reference: <testLibraryFragment>::@enum::E
      typeParameters
        T
      firstFragment: <testLibraryFragment>::@enum::E
      supertype: Enum
      fields
        static const int
          reference: <none>
          type: E<int>
          firstFragment: <testLibraryFragment>::@enum::E::@field::int
          getter: <none>
        static const string
          reference: <none>
          type: E<String>
          firstFragment: <testLibraryFragment>::@enum::E::@field::string
          getter: <none>
        synthetic static const values
          reference: <none>
          type: List<E<dynamic>>
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
          getter: <none>
      constructors
        const new
          reference: <none>
          parameters
            requiredPositional a
              reference: <none>
              type: T
          firstFragment: <testLibraryFragment>::@enum::E::@constructor::new
      getters
        synthetic static get int
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@getter::int
        synthetic static get string
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@getter::string
        synthetic static get values
          reference: <none>
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
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          element: <testLibraryFragment>::@enum::E
          fields
            enumConstant _name @11
              reference: <testLibraryFragment>::@enum::E::@field::_name
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::_name
            values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              element: <none>
          getters
            get _name @-1
              reference: <testLibraryFragment>::@enum::E::@getter::_name
              element: <none>
            get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              element: <none>
  enums
    enum E
      reference: <testLibraryFragment>::@enum::E
      firstFragment: <testLibraryFragment>::@enum::E
      supertype: Enum
      fields
        static const _name
          reference: <none>
          type: E
          firstFragment: <testLibraryFragment>::@enum::E::@field::_name
          getter: <none>
        synthetic static const values
          reference: <none>
          type: List<E>
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
          getter: <none>
      constructors
        synthetic const new
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@constructor::new
      getters
        synthetic static get _name
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@getter::_name
        synthetic static get values
          reference: <none>
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
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          element: <testLibraryFragment>::@enum::E
          typeParameters
            T @7
              element: <none>
          fields
            enumConstant v @14
              reference: <testLibraryFragment>::@enum::E::@field::v
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::values
          constructors
            const new @37
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              element: <none>
              parameters
                a @41
                  element: <none>
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              element: <none>
            get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              element: <none>
  enums
    enum E
      reference: <testLibraryFragment>::@enum::E
      typeParameters
        T
      firstFragment: <testLibraryFragment>::@enum::E
      supertype: Enum
      fields
        static const v
          reference: <none>
          type: E<double>
          firstFragment: <testLibraryFragment>::@enum::E::@field::v
          getter: <none>
        synthetic static const values
          reference: <none>
          type: List<E<dynamic>>
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
          getter: <none>
      constructors
        const new
          reference: <none>
          parameters
            requiredPositional a
              reference: <none>
              type: T
          firstFragment: <testLibraryFragment>::@enum::E::@constructor::new
      getters
        synthetic static get v
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@getter::v
        synthetic static get values
          reference: <none>
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
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          element: <testLibraryFragment>::@enum::E
          fields
            enumConstant _ @11
              reference: <testLibraryFragment>::@enum::E::@field::_
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::_
            values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              element: <none>
          getters
            get _ @-1
              reference: <testLibraryFragment>::@enum::E::@getter::_
              element: <none>
            get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              element: <none>
  enums
    enum E
      reference: <testLibraryFragment>::@enum::E
      firstFragment: <testLibraryFragment>::@enum::E
      supertype: Enum
      fields
        static const _
          reference: <none>
          type: E
          firstFragment: <testLibraryFragment>::@enum::E::@field::_
          getter: <none>
        synthetic static const values
          reference: <none>
          type: List<E>
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
          getter: <none>
      constructors
        synthetic const new
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@constructor::new
      getters
        synthetic static get _
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@getter::_
        synthetic static get values
          reference: <none>
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
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          element: <testLibraryFragment>::@enum::E
          fields
            enumConstant v @11
              reference: <testLibraryFragment>::@enum::E::@field::v
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::values
          constructors
            factory named @26
              reference: <testLibraryFragment>::@enum::E::@constructor::named
              element: <none>
              periodOffset: 25
              nameEnd: 31
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              element: <none>
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              element: <none>
            get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              element: <none>
  enums
    enum E
      reference: <testLibraryFragment>::@enum::E
      firstFragment: <testLibraryFragment>::@enum::E
      supertype: Enum
      fields
        static const v
          reference: <none>
          type: E
          firstFragment: <testLibraryFragment>::@enum::E::@field::v
          getter: <none>
        synthetic static const values
          reference: <none>
          type: List<E>
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
          getter: <none>
      constructors
        factory named
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@constructor::named
        synthetic const new
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@constructor::new
      getters
        synthetic static get v
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@getter::v
        synthetic static get values
          reference: <none>
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
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          element: <testLibraryFragment>::@enum::E
          fields
            enumConstant v @11
              reference: <testLibraryFragment>::@enum::E::@field::v
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::values
          constructors
            factory new @24
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              element: <none>
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              element: <none>
            get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              element: <none>
  enums
    enum E
      reference: <testLibraryFragment>::@enum::E
      firstFragment: <testLibraryFragment>::@enum::E
      supertype: Enum
      fields
        static const v
          reference: <none>
          type: E
          firstFragment: <testLibraryFragment>::@enum::E::@field::v
          getter: <none>
        synthetic static const values
          reference: <none>
          type: List<E>
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
          getter: <none>
      constructors
        factory new
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@constructor::new
      getters
        synthetic static get v
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@getter::v
        synthetic static get values
          reference: <none>
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
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          element: <testLibraryFragment>::@enum::E
          fields
            enumConstant v @11
              reference: <testLibraryFragment>::@enum::E::@field::v
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::values
            x @22
              reference: <testLibraryFragment>::@enum::E::@field::x
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::x
          constructors
            const new @33
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              element: <none>
              parameters
                this.x @44
                  element: <none>
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              element: <none>
            get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              element: <none>
            get x @-1
              reference: <testLibraryFragment>::@enum::E::@getter::x
              element: <none>
  enums
    enum E
      reference: <testLibraryFragment>::@enum::E
      firstFragment: <testLibraryFragment>::@enum::E
      supertype: Enum
      fields
        static const v
          reference: <none>
          type: E
          firstFragment: <testLibraryFragment>::@enum::E::@field::v
          getter: <none>
        synthetic static const values
          reference: <none>
          type: List<E>
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
          getter: <none>
        final x
          reference: <none>
          type: dynamic
          firstFragment: <testLibraryFragment>::@enum::E::@field::x
          getter: <none>
      constructors
        const new
          reference: <none>
          parameters
            requiredPositional final x
              reference: <none>
              type: int Function(double)
              parameters
                requiredPositional a
                  reference: <none>
                  type: double
          firstFragment: <testLibraryFragment>::@enum::E::@constructor::new
      getters
        synthetic static get v
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@getter::v
        synthetic static get values
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@getter::values
        synthetic get x
          reference: <none>
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
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          element: <testLibraryFragment>::@enum::E
          fields
            enumConstant v @11
              reference: <testLibraryFragment>::@enum::E::@field::v
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::values
            x @26
              reference: <testLibraryFragment>::@enum::E::@field::x::@def::0
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::x::@def::0
            x @44
              reference: <testLibraryFragment>::@enum::E::@field::x::@def::1
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::x::@def::1
          constructors
            const new @55
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              element: <none>
              parameters
                this.x @62
                  element: <none>
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              element: <none>
            get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              element: <none>
            get x @-1
              reference: <testLibraryFragment>::@enum::E::@getter::x::@def::0
              element: <none>
            get x @-1
              reference: <testLibraryFragment>::@enum::E::@getter::x::@def::1
              element: <none>
  enums
    enum E
      reference: <testLibraryFragment>::@enum::E
      firstFragment: <testLibraryFragment>::@enum::E
      supertype: Enum
      fields
        static const v
          reference: <none>
          type: E
          firstFragment: <testLibraryFragment>::@enum::E::@field::v
          getter: <none>
        synthetic static const values
          reference: <none>
          type: List<E>
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
          getter: <none>
        final x
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@enum::E::@field::x::@def::0
          getter: <none>
        final x
          reference: <none>
          type: String
          firstFragment: <testLibraryFragment>::@enum::E::@field::x::@def::1
          getter: <none>
      constructors
        const new
          reference: <none>
          parameters
            requiredPositional final x
              reference: <none>
              type: int
          firstFragment: <testLibraryFragment>::@enum::E::@constructor::new
      getters
        synthetic static get v
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@getter::v
        synthetic static get values
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@getter::values
        synthetic get x
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@getter::x::@def::0
        synthetic get x
          reference: <none>
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
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          element: <testLibraryFragment>::@enum::E
          fields
            enumConstant v @11
              reference: <testLibraryFragment>::@enum::E::@field::v
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::values
          constructors
            const new @22
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              element: <none>
              parameters
                this.x @29
                  element: <none>
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              element: <none>
            get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              element: <none>
  enums
    enum E
      reference: <testLibraryFragment>::@enum::E
      firstFragment: <testLibraryFragment>::@enum::E
      supertype: Enum
      fields
        static const v
          reference: <none>
          type: E
          firstFragment: <testLibraryFragment>::@enum::E::@field::v
          getter: <none>
        synthetic static const values
          reference: <none>
          type: List<E>
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
          getter: <none>
      constructors
        const new
          reference: <none>
          parameters
            requiredPositional final x
              reference: <none>
              type: dynamic
          firstFragment: <testLibraryFragment>::@enum::E::@constructor::new
      getters
        synthetic static get v
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@getter::v
        synthetic static get values
          reference: <none>
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
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          element: <testLibraryFragment>::@enum::E
          fields
            enumConstant v @11
              reference: <testLibraryFragment>::@enum::E::@field::v
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::values
            x @26
              reference: <testLibraryFragment>::@enum::E::@field::x
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::x
          constructors
            const new @37
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              element: <none>
              parameters
                default this.x @45
                  reference: <testLibraryFragment>::@enum::E::@constructor::new::@parameter::x
                  element: <none>
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              element: <none>
            get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              element: <none>
            get x @-1
              reference: <testLibraryFragment>::@enum::E::@getter::x
              element: <none>
  enums
    enum E
      reference: <testLibraryFragment>::@enum::E
      firstFragment: <testLibraryFragment>::@enum::E
      supertype: Enum
      fields
        static const v
          reference: <none>
          type: E
          firstFragment: <testLibraryFragment>::@enum::E::@field::v
          getter: <none>
        synthetic static const values
          reference: <none>
          type: List<E>
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
          getter: <none>
        final x
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@enum::E::@field::x
          getter: <none>
      constructors
        const new
          reference: <none>
          parameters
            optionalNamed final x
              reference: <none>
              type: int
          firstFragment: <testLibraryFragment>::@enum::E::@constructor::new
      getters
        synthetic static get v
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@getter::v
        synthetic static get values
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@getter::values
        synthetic get x
          reference: <none>
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
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          element: <testLibraryFragment>::@enum::E
          fields
            enumConstant v @11
              reference: <testLibraryFragment>::@enum::E::@field::v
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::values
            x @26
              reference: <testLibraryFragment>::@enum::E::@field::x
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::x
          constructors
            const new @37
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              element: <none>
              parameters
                this.x @48
                  element: <none>
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              element: <none>
            get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              element: <none>
            get x @-1
              reference: <testLibraryFragment>::@enum::E::@getter::x
              element: <none>
  enums
    enum E
      reference: <testLibraryFragment>::@enum::E
      firstFragment: <testLibraryFragment>::@enum::E
      supertype: Enum
      fields
        static const v
          reference: <none>
          type: E
          firstFragment: <testLibraryFragment>::@enum::E::@field::v
          getter: <none>
        synthetic static const values
          reference: <none>
          type: List<E>
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
          getter: <none>
        final x
          reference: <none>
          type: num
          firstFragment: <testLibraryFragment>::@enum::E::@field::x
          getter: <none>
      constructors
        const new
          reference: <none>
          parameters
            requiredPositional final x
              reference: <none>
              type: int
          firstFragment: <testLibraryFragment>::@enum::E::@constructor::new
      getters
        synthetic static get v
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@getter::v
        synthetic static get values
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@getter::values
        synthetic get x
          reference: <none>
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
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          element: <testLibraryFragment>::@enum::E
          fields
            enumConstant v @11
              reference: <testLibraryFragment>::@enum::E::@field::v
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::values
            x @22
              reference: <testLibraryFragment>::@enum::E::@field::x
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::x
          constructors
            new @27
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              element: <none>
              parameters
                this.x @38
                  element: <none>
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              element: <none>
            get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              element: <none>
            get x @-1
              reference: <testLibraryFragment>::@enum::E::@getter::x
              element: <none>
  enums
    enum E
      reference: <testLibraryFragment>::@enum::E
      firstFragment: <testLibraryFragment>::@enum::E
      supertype: Enum
      fields
        static const v
          reference: <none>
          type: E
          firstFragment: <testLibraryFragment>::@enum::E::@field::v
          getter: <none>
        synthetic static const values
          reference: <none>
          type: List<E>
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
          getter: <none>
        final x
          reference: <none>
          type: dynamic
          firstFragment: <testLibraryFragment>::@enum::E::@field::x
          getter: <none>
      constructors
        new
          reference: <none>
          parameters
            requiredPositional final x
              reference: <none>
              type: int
          firstFragment: <testLibraryFragment>::@enum::E::@constructor::new
      getters
        synthetic static get v
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@getter::v
        synthetic static get values
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@getter::values
        synthetic get x
          reference: <none>
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
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          element: <testLibraryFragment>::@enum::E
          fields
            enumConstant v @11
              reference: <testLibraryFragment>::@enum::E::@field::v
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::values
            x @22
              reference: <testLibraryFragment>::@enum::E::@field::x
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::x
          constructors
            new @27
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              element: <none>
              parameters
                this.x @34
                  element: <none>
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              element: <none>
            get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              element: <none>
            get x @-1
              reference: <testLibraryFragment>::@enum::E::@getter::x
              element: <none>
  enums
    enum E
      reference: <testLibraryFragment>::@enum::E
      firstFragment: <testLibraryFragment>::@enum::E
      supertype: Enum
      fields
        static const v
          reference: <none>
          type: E
          firstFragment: <testLibraryFragment>::@enum::E::@field::v
          getter: <none>
        synthetic static const values
          reference: <none>
          type: List<E>
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
          getter: <none>
        final x
          reference: <none>
          type: dynamic
          firstFragment: <testLibraryFragment>::@enum::E::@field::x
          getter: <none>
      constructors
        new
          reference: <none>
          parameters
            requiredPositional final x
              reference: <none>
              type: dynamic
          firstFragment: <testLibraryFragment>::@enum::E::@constructor::new
      getters
        synthetic static get v
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@getter::v
        synthetic static get values
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@getter::values
        synthetic get x
          reference: <none>
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
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          element: <testLibraryFragment>::@enum::E
          fields
            enumConstant v @11
              reference: <testLibraryFragment>::@enum::E::@field::v
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::values
          constructors
            const named @34
              reference: <testLibraryFragment>::@enum::E::@constructor::named
              element: <none>
              periodOffset: 33
              nameEnd: 39
              parameters
                a @44
                  element: <none>
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              element: <none>
            get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              element: <none>
  enums
    enum E
      reference: <testLibraryFragment>::@enum::E
      firstFragment: <testLibraryFragment>::@enum::E
      supertype: Enum
      fields
        static const v
          reference: <none>
          type: E
          firstFragment: <testLibraryFragment>::@enum::E::@field::v
          getter: <none>
        synthetic static const values
          reference: <none>
          type: List<E>
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
          getter: <none>
      constructors
        const named
          reference: <none>
          parameters
            requiredPositional a
              reference: <none>
              type: int
          firstFragment: <testLibraryFragment>::@enum::E::@constructor::named
      getters
        synthetic static get v
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@getter::v
        synthetic static get values
          reference: <none>
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
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          element: <testLibraryFragment>::@enum::E
          fields
            enumConstant v @11
              reference: <testLibraryFragment>::@enum::E::@field::v
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::values
          constructors
            const new @26
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              element: <none>
              parameters
                a @32
                  element: <none>
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              element: <none>
            get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              element: <none>
  enums
    enum E
      reference: <testLibraryFragment>::@enum::E
      firstFragment: <testLibraryFragment>::@enum::E
      supertype: Enum
      fields
        static const v
          reference: <none>
          type: E
          firstFragment: <testLibraryFragment>::@enum::E::@field::v
          getter: <none>
        synthetic static const values
          reference: <none>
          type: List<E>
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
          getter: <none>
      constructors
        const new
          reference: <none>
          parameters
            requiredPositional a
              reference: <none>
              type: int
          firstFragment: <testLibraryFragment>::@enum::E::@constructor::new
      getters
        synthetic static get v
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@getter::v
        synthetic static get values
          reference: <none>
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
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          element: <testLibraryFragment>::@enum::E
          typeParameters
            T @7
              element: <none>
          fields
            enumConstant v @14
              reference: <testLibraryFragment>::@enum::E::@field::v
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::values
            x @29
              reference: <testLibraryFragment>::@enum::E::@field::x
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::x
          constructors
            const new @40
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              element: <none>
              parameters
                a @45
                  element: <none>
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
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              element: <none>
            get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              element: <none>
            get x @-1
              reference: <testLibraryFragment>::@enum::E::@getter::x
              element: <none>
  enums
    enum E
      reference: <testLibraryFragment>::@enum::E
      typeParameters
        T
      firstFragment: <testLibraryFragment>::@enum::E
      supertype: Enum
      fields
        static const v
          reference: <none>
          type: E<dynamic>
          firstFragment: <testLibraryFragment>::@enum::E::@field::v
          getter: <none>
        synthetic static const values
          reference: <none>
          type: List<E<dynamic>>
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
          getter: <none>
        final x
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@enum::E::@field::x
          getter: <none>
      constructors
        const new
          reference: <none>
          parameters
            requiredPositional a
              reference: <none>
              type: T?
          firstFragment: <testLibraryFragment>::@enum::E::@constructor::new
      getters
        synthetic static get v
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@getter::v
        synthetic static get values
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@getter::values
        synthetic get x
          reference: <none>
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
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      enums
        enum E @65
          reference: <testLibraryFragment>::@enum::E
          element: <testLibraryFragment>::@enum::E
          fields
            enumConstant v @69
              reference: <testLibraryFragment>::@enum::E::@field::v
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              element: <none>
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              element: <none>
            get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              element: <none>
  enums
    enum E
      reference: <testLibraryFragment>::@enum::E
      documentationComment: /**\n * Docs\n */
      firstFragment: <testLibraryFragment>::@enum::E
      supertype: Enum
      fields
        static const v
          reference: <none>
          type: E
          firstFragment: <testLibraryFragment>::@enum::E::@field::v
          getter: <none>
        synthetic static const values
          reference: <none>
          type: List<E>
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
          getter: <none>
      constructors
        synthetic const new
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@constructor::new
      getters
        synthetic static get v
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@getter::v
        synthetic static get values
          reference: <none>
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
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          element: <testLibraryFragment>::@enum::E
          fields
            enumConstant v @11
              reference: <testLibraryFragment>::@enum::E::@field::v
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::values
            foo @22
              reference: <testLibraryFragment>::@enum::E::@field::foo
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::foo
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              element: <none>
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              element: <none>
            get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              element: <none>
            get foo @-1
              reference: <testLibraryFragment>::@enum::E::@getter::foo
              element: <none>
  enums
    enum E
      reference: <testLibraryFragment>::@enum::E
      firstFragment: <testLibraryFragment>::@enum::E
      supertype: Enum
      fields
        static const v
          reference: <none>
          type: E
          firstFragment: <testLibraryFragment>::@enum::E::@field::v
          getter: <none>
        synthetic static const values
          reference: <none>
          type: List<E>
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
          getter: <none>
        final foo
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@enum::E::@field::foo
          getter: <none>
      constructors
        synthetic const new
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@constructor::new
      getters
        synthetic static get v
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@getter::v
        synthetic static get values
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@getter::values
        synthetic get foo
          reference: <none>
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
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          element: <testLibraryFragment>::@enum::E
          fields
            promotable _foo @33
              reference: <testLibraryFragment>::@enum::E::@field::_foo
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::_foo
  enums
    enum E
      reference: <testLibraryFragment>::@enum::E
      firstFragment: <testLibraryFragment>::@enum::E
      supertype: Enum
      fields
        static const v
          reference: <none>
          type: E
          firstFragment: <testLibraryFragment>::@enum::E::@field::v
          getter: <none>
        synthetic static const values
          reference: <none>
          type: List<E>
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
          getter: <none>
        final _foo
          reference: <none>
          type: int?
          firstFragment: <testLibraryFragment>::@enum::E::@field::_foo
          getter: <none>
      constructors
        new
          reference: <none>
          parameters
            requiredPositional final _foo
              reference: <none>
              type: int?
          firstFragment: <testLibraryFragment>::@enum::E::@constructor::new
      getters
        synthetic static get v
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@getter::v
        synthetic static get values
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@getter::values
        synthetic get _foo
          reference: <none>
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
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          element: <testLibraryFragment>::@enum::E
          fields
            enumConstant v @10
              reference: <testLibraryFragment>::@enum::E::@field::v
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::values
            foo @-1
              reference: <testLibraryFragment>::@enum::E::@field::foo
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::foo
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              element: <none>
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              element: <none>
            get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              element: <none>
            get foo @23
              reference: <testLibraryFragment>::@enum::E::@getter::foo
              element: <none>
  enums
    enum E
      reference: <testLibraryFragment>::@enum::E
      firstFragment: <testLibraryFragment>::@enum::E
      supertype: Enum
      fields
        static const v
          reference: <none>
          type: E
          firstFragment: <testLibraryFragment>::@enum::E::@field::v
          getter: <none>
        synthetic static const values
          reference: <none>
          type: List<E>
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
          getter: <none>
        synthetic foo
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@enum::E::@field::foo
          getter: <none>
      constructors
        synthetic const new
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@constructor::new
      getters
        synthetic static get v
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@getter::v
        synthetic static get values
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@getter::values
        get foo
          reference: <none>
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
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class I @6
          reference: <testLibraryFragment>::@class::I
          element: <testLibraryFragment>::@class::I
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::I::@constructor::new
              element: <none>
      enums
        enum E @16
          reference: <testLibraryFragment>::@enum::E
          element: <testLibraryFragment>::@enum::E
          fields
            enumConstant v @35
              reference: <testLibraryFragment>::@enum::E::@field::v
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              element: <none>
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              element: <none>
            get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              element: <none>
  classes
    class I
      reference: <testLibraryFragment>::@class::I
      firstFragment: <testLibraryFragment>::@class::I
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::I::@constructor::new
  enums
    enum E
      reference: <testLibraryFragment>::@enum::E
      firstFragment: <testLibraryFragment>::@enum::E
      supertype: Enum
      fields
        static const v
          reference: <none>
          type: E
          firstFragment: <testLibraryFragment>::@enum::E::@field::v
          getter: <none>
        synthetic static const values
          reference: <none>
          type: List<E>
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
          getter: <none>
      constructors
        synthetic const new
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@constructor::new
      getters
        synthetic static get v
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@getter::v
        synthetic static get values
          reference: <none>
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
        class C @45
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C
      enums
        enum E @55
          reference: <testLibraryFragment>::@enum::E
          element: <testLibraryFragment>::@enum::E
          fields
            enumConstant v @78
              reference: <testLibraryFragment>::@enum::E::@field::v
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::values
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              element: <none>
            get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              element: <none>
      extensionTypes
        extension type B @26
          reference: <testLibraryFragment>::@extensionType::B
          element: <testLibraryFragment>::@extensionType::B
          fields
            it @32
              reference: <testLibraryFragment>::@extensionType::B::@field::it
              element: <none>
              getter2: <testLibraryFragment>::@extensionType::B::@getter::it
          getters
            get it @-1
              reference: <testLibraryFragment>::@extensionType::B::@getter::it
              element: <none>
  classes
    class A
      reference: <testLibraryFragment>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
    class C
      reference: <testLibraryFragment>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
  enums
    enum E
      reference: <testLibraryFragment>::@enum::E
      firstFragment: <testLibraryFragment>::@enum::E
      supertype: Enum
      fields
        static const v
          reference: <none>
          type: E
          firstFragment: <testLibraryFragment>::@enum::E::@field::v
          getter: <none>
        synthetic static const values
          reference: <none>
          type: List<E>
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
          getter: <none>
      getters
        synthetic static get v
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@getter::v
        synthetic static get values
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@getter::values
  extensionTypes
    extension type B
      reference: <testLibraryFragment>::@extensionType::B
      firstFragment: <testLibraryFragment>::@extensionType::B
      typeErasure: int
      fields
        final it
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@extensionType::B::@field::it
          getter: <none>
      getters
        synthetic get it
          reference: <none>
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
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class I @6
          reference: <testLibraryFragment>::@class::I
          element: <testLibraryFragment>::@class::I
          typeParameters
            T @8
              element: <none>
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::I::@constructor::new
              element: <none>
      enums
        enum E @19
          reference: <testLibraryFragment>::@enum::E
          element: <testLibraryFragment>::@enum::E
          typeParameters
            U @21
              element: <none>
          fields
            enumConstant v @44
              reference: <testLibraryFragment>::@enum::E::@field::v
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              element: <none>
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              element: <none>
            get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              element: <none>
  classes
    class I
      reference: <testLibraryFragment>::@class::I
      typeParameters
        T
      firstFragment: <testLibraryFragment>::@class::I
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::I::@constructor::new
  enums
    enum E
      reference: <testLibraryFragment>::@enum::E
      typeParameters
        U
      firstFragment: <testLibraryFragment>::@enum::E
      supertype: Enum
      fields
        static const v
          reference: <none>
          type: E<dynamic>
          firstFragment: <testLibraryFragment>::@enum::E::@field::v
          getter: <none>
        synthetic static const values
          reference: <none>
          type: List<E<dynamic>>
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
          getter: <none>
      constructors
        synthetic const new
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@constructor::new
      getters
        synthetic static get v
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@getter::v
        synthetic static get values
          reference: <none>
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
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class X @6
          reference: <testLibraryFragment>::@class::X
          element: <testLibraryFragment>::@class::X
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::X::@constructor::new
              element: <none>
        class Z @17
          reference: <testLibraryFragment>::@class::Z
          element: <testLibraryFragment>::@class::Z
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::Z::@constructor::new
              element: <none>
      enums
        enum E @27
          reference: <testLibraryFragment>::@enum::E
          element: <testLibraryFragment>::@enum::E
          fields
            enumConstant v @52
              reference: <testLibraryFragment>::@enum::E::@field::v
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              element: <none>
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              element: <none>
            get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              element: <none>
  classes
    class X
      reference: <testLibraryFragment>::@class::X
      firstFragment: <testLibraryFragment>::@class::X
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::X::@constructor::new
    class Z
      reference: <testLibraryFragment>::@class::Z
      firstFragment: <testLibraryFragment>::@class::Z
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::Z::@constructor::new
  enums
    enum E
      reference: <testLibraryFragment>::@enum::E
      firstFragment: <testLibraryFragment>::@enum::E
      supertype: Enum
      fields
        static const v
          reference: <none>
          type: E
          firstFragment: <testLibraryFragment>::@enum::E::@field::v
          getter: <none>
        synthetic static const values
          reference: <none>
          type: List<E>
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
          getter: <none>
      constructors
        synthetic const new
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@constructor::new
      getters
        synthetic static get v
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@getter::v
        synthetic static get values
          reference: <none>
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
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          element: <testLibraryFragment>::@enum::E
          typeParameters
            T @7
              element: <none>
          fields
            enumConstant v @14
              reference: <testLibraryFragment>::@enum::E::@field::v
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              element: <none>
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              element: <none>
            get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              element: <none>
          methods
            foo @23
              reference: <testLibraryFragment>::@enum::E::@method::foo
              element: <none>
              typeParameters
                U @27
                  element: <none>
              parameters
                t @32
                  element: <none>
                u @37
                  element: <none>
  enums
    enum E
      reference: <testLibraryFragment>::@enum::E
      typeParameters
        T
      firstFragment: <testLibraryFragment>::@enum::E
      supertype: Enum
      fields
        static const v
          reference: <none>
          type: E<dynamic>
          firstFragment: <testLibraryFragment>::@enum::E::@field::v
          getter: <none>
        synthetic static const values
          reference: <none>
          type: List<E<dynamic>>
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
          getter: <none>
      constructors
        synthetic const new
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@constructor::new
      getters
        synthetic static get v
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@getter::v
        synthetic static get values
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@getter::values
      methods
        foo
          reference: <none>
          typeParameters
            U
          parameters
            requiredPositional t
              reference: <none>
              type: T
            requiredPositional u
              reference: <none>
              type: U
          firstFragment: <testLibraryFragment>::@enum::E::@method::foo
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
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          element: <testLibraryFragment>::@enum::E
          fields
            enumConstant v @11
              reference: <testLibraryFragment>::@enum::E::@field::v
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              element: <none>
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              element: <none>
            get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              element: <none>
          methods
            toString @23
              reference: <testLibraryFragment>::@enum::E::@method::toString
              element: <none>
  enums
    enum E
      reference: <testLibraryFragment>::@enum::E
      firstFragment: <testLibraryFragment>::@enum::E
      supertype: Enum
      fields
        static const v
          reference: <none>
          type: E
          firstFragment: <testLibraryFragment>::@enum::E::@field::v
          getter: <none>
        synthetic static const values
          reference: <none>
          type: List<E>
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
          getter: <none>
      constructors
        synthetic const new
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@constructor::new
      getters
        synthetic static get v
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@getter::v
        synthetic static get values
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@getter::values
      methods
        toString
          reference: <none>
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
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      enums
        enum E @16
          reference: <testLibraryFragment>::@enum::E
          element: <testLibraryFragment>::@enum::E
          fields
            enumConstant v @29
              reference: <testLibraryFragment>::@enum::E::@field::v
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              element: <none>
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              element: <none>
            get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              element: <none>
      mixins
        mixin M @6
          reference: <testLibraryFragment>::@mixin::M
          element: <testLibraryFragment>::@mixin::M
  enums
    enum E
      reference: <testLibraryFragment>::@enum::E
      firstFragment: <testLibraryFragment>::@enum::E
      supertype: Enum
      fields
        static const v
          reference: <none>
          type: E
          firstFragment: <testLibraryFragment>::@enum::E::@field::v
          getter: <none>
        synthetic static const values
          reference: <none>
          type: List<E>
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
          getter: <none>
      constructors
        synthetic const new
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@constructor::new
      getters
        synthetic static get v
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@getter::v
        synthetic static get values
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@getter::values
  mixins
    mixin M
      reference: <testLibraryFragment>::@mixin::M
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
        class C @45
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C
      enums
        enum E @55
          reference: <testLibraryFragment>::@enum::E
          element: <testLibraryFragment>::@enum::E
          fields
            enumConstant v @72
              reference: <testLibraryFragment>::@enum::E::@field::v
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::values
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              element: <none>
            get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              element: <none>
      extensionTypes
        extension type B @26
          reference: <testLibraryFragment>::@extensionType::B
          element: <testLibraryFragment>::@extensionType::B
          fields
            it @32
              reference: <testLibraryFragment>::@extensionType::B::@field::it
              element: <none>
              getter2: <testLibraryFragment>::@extensionType::B::@getter::it
          getters
            get it @-1
              reference: <testLibraryFragment>::@extensionType::B::@getter::it
              element: <none>
  classes
    class A
      reference: <testLibraryFragment>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
    class C
      reference: <testLibraryFragment>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
  enums
    enum E
      reference: <testLibraryFragment>::@enum::E
      firstFragment: <testLibraryFragment>::@enum::E
      supertype: Enum
      fields
        static const v
          reference: <none>
          type: E
          firstFragment: <testLibraryFragment>::@enum::E::@field::v
          getter: <none>
        synthetic static const values
          reference: <none>
          type: List<E>
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
          getter: <none>
      getters
        synthetic static get v
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@getter::v
        synthetic static get values
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@getter::values
  extensionTypes
    extension type B
      reference: <testLibraryFragment>::@extensionType::B
      firstFragment: <testLibraryFragment>::@extensionType::B
      typeErasure: int
      fields
        final it
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@extensionType::B::@field::it
          getter: <none>
      getters
        synthetic get it
          reference: <none>
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
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      enums
        enum E @44
          reference: <testLibraryFragment>::@enum::E
          element: <testLibraryFragment>::@enum::E
          fields
            enumConstant v @67
              reference: <testLibraryFragment>::@enum::E::@field::v
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              element: <none>
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              element: <none>
            get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              element: <none>
      mixins
        mixin M1 @6
          reference: <testLibraryFragment>::@mixin::M1
          element: <testLibraryFragment>::@mixin::M1
          typeParameters
            T @9
              element: <none>
        mixin M2 @21
          reference: <testLibraryFragment>::@mixin::M2
          element: <testLibraryFragment>::@mixin::M2
          typeParameters
            T @24
              element: <none>
  enums
    enum E
      reference: <testLibraryFragment>::@enum::E
      firstFragment: <testLibraryFragment>::@enum::E
      supertype: Enum
      fields
        static const v
          reference: <none>
          type: E
          firstFragment: <testLibraryFragment>::@enum::E::@field::v
          getter: <none>
        synthetic static const values
          reference: <none>
          type: List<E>
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
          getter: <none>
      constructors
        synthetic const new
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@constructor::new
      getters
        synthetic static get v
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@getter::v
        synthetic static get values
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@getter::values
  mixins
    mixin M1
      reference: <testLibraryFragment>::@mixin::M1
      typeParameters
        T
      firstFragment: <testLibraryFragment>::@mixin::M1
      superclassConstraints
        Object
    mixin M2
      reference: <testLibraryFragment>::@mixin::M2
      typeParameters
        T
      firstFragment: <testLibraryFragment>::@mixin::M2
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
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          element: <testLibraryFragment>::@enum::E
          fields
            enumConstant v @10
              reference: <testLibraryFragment>::@enum::E::@field::v
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::values
            foo @-1
              reference: <testLibraryFragment>::@enum::E::@field::foo
              element: <none>
              setter2: <testLibraryFragment>::@enum::E::@setter::foo
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              element: <none>
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              element: <none>
            get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              element: <none>
          setters
            set foo= @19
              reference: <testLibraryFragment>::@enum::E::@setter::foo
              element: <none>
              parameters
                _ @27
                  element: <none>
  enums
    enum E
      reference: <testLibraryFragment>::@enum::E
      firstFragment: <testLibraryFragment>::@enum::E
      supertype: Enum
      fields
        static const v
          reference: <none>
          type: E
          firstFragment: <testLibraryFragment>::@enum::E::@field::v
          getter: <none>
        synthetic static const values
          reference: <none>
          type: List<E>
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
          getter: <none>
        synthetic foo
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@enum::E::@field::foo
          setter: <none>
      constructors
        synthetic const new
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@constructor::new
      getters
        synthetic static get v
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@getter::v
        synthetic static get values
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@getter::values
      setters
        set foo=
          reference: <none>
          parameters
            requiredPositional _
              reference: <none>
              type: int
          firstFragment: <testLibraryFragment>::@enum::E::@setter::foo
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
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          element: <testLibraryFragment>::@enum::E
          typeParameters
            T @7
              element: <none>
          fields
            enumConstant v @14
              reference: <testLibraryFragment>::@enum::E::@field::v
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              element: <none>
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              element: <none>
            get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              element: <none>
  enums
    enum E
      reference: <testLibraryFragment>::@enum::E
      typeParameters
        T
      firstFragment: <testLibraryFragment>::@enum::E
      supertype: Enum
      fields
        static const v
          reference: <none>
          type: E<dynamic>
          firstFragment: <testLibraryFragment>::@enum::E::@field::v
          getter: <none>
        synthetic static const values
          reference: <none>
          type: List<E<dynamic>>
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
          getter: <none>
      constructors
        synthetic const new
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@constructor::new
      getters
        synthetic static get v
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@getter::v
        synthetic static get values
          reference: <none>
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
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          element: <testLibraryFragment>::@enum::E
          typeParameters
            T @7
              element: <none>
            U @22
              element: <none>
          fields
            enumConstant v @39
              reference: <testLibraryFragment>::@enum::E::@field::v
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              element: <none>
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              element: <none>
            get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              element: <none>
  enums
    enum E
      reference: <testLibraryFragment>::@enum::E
      typeParameters
        T
          bound: num
        U
          bound: T
      firstFragment: <testLibraryFragment>::@enum::E
      supertype: Enum
      fields
        static const v
          reference: <none>
          type: E<num, num>
          firstFragment: <testLibraryFragment>::@enum::E::@field::v
          getter: <none>
        synthetic static const values
          reference: <none>
          type: List<E<num, num>>
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
          getter: <none>
      constructors
        synthetic const new
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@constructor::new
      getters
        synthetic static get v
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@getter::v
        synthetic static get values
          reference: <none>
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
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          element: <testLibraryFragment>::@enum::E
          typeParameters
            T @7
              element: <none>
          fields
            values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              element: <none>
          getters
            get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              element: <none>
  enums
    enum E
      reference: <testLibraryFragment>::@enum::E
      typeParameters
        T
          bound: dynamic
      firstFragment: <testLibraryFragment>::@enum::E
      supertype: Enum
      fields
        synthetic static const values
          reference: <none>
          type: List<E<dynamic>>
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
          getter: <none>
      constructors
        synthetic const new
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@constructor::new
      getters
        synthetic static get values
          reference: <none>
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
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          element: <testLibraryFragment>::@enum::E
          typeParameters
            T @7
              element: <none>
            U @20
              element: <none>
            V @35
              element: <none>
          fields
            values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              element: <none>
          getters
            get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              element: <none>
  enums
    enum E
      reference: <testLibraryFragment>::@enum::E
      typeParameters
        T
          bound: dynamic
        U
          bound: num
        V
          bound: dynamic
      firstFragment: <testLibraryFragment>::@enum::E
      supertype: Enum
      fields
        synthetic static const values
          reference: <none>
          type: List<E<dynamic, num, dynamic>>
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
          getter: <none>
      constructors
        synthetic const new
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@constructor::new
      getters
        synthetic static get values
          reference: <none>
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
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          element: <testLibraryFragment>::@enum::E
          typeParameters
            T @7
              element: <none>
          fields
            values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              element: <none>
          getters
            get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              element: <none>
  enums
    enum E
      reference: <testLibraryFragment>::@enum::E
      typeParameters
        T
          bound: void Function(E<dynamic>)
      firstFragment: <testLibraryFragment>::@enum::E
      supertype: Enum
      fields
        synthetic static const values
          reference: <none>
          type: List<E<dynamic>>
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
          getter: <none>
      constructors
        synthetic const new
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@constructor::new
      getters
        synthetic static get values
          reference: <none>
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
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          element: <testLibraryFragment>::@enum::E
          typeParameters
            T @10
              element: <none>
          fields
            values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              element: <none>
          getters
            get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              element: <none>
  enums
    enum E
      reference: <testLibraryFragment>::@enum::E
      typeParameters
        T
      firstFragment: <testLibraryFragment>::@enum::E
      supertype: Enum
      fields
        synthetic static const values
          reference: <none>
          type: List<E<dynamic>>
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
          getter: <none>
      constructors
        synthetic const new
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@constructor::new
      getters
        synthetic static get values
          reference: <none>
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
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          element: <testLibraryFragment>::@enum::E
          typeParameters
            T @11
              element: <none>
          fields
            values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              element: <none>
          getters
            get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              element: <none>
  enums
    enum E
      reference: <testLibraryFragment>::@enum::E
      typeParameters
        T
      firstFragment: <testLibraryFragment>::@enum::E
      supertype: Enum
      fields
        synthetic static const values
          reference: <none>
          type: List<E<dynamic>>
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
          getter: <none>
      constructors
        synthetic const new
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@constructor::new
      getters
        synthetic static get values
          reference: <none>
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
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          element: <testLibraryFragment>::@enum::E
          typeParameters
            T @13
              element: <none>
          fields
            values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              element: <none>
          getters
            get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              element: <none>
  enums
    enum E
      reference: <testLibraryFragment>::@enum::E
      typeParameters
        T
      firstFragment: <testLibraryFragment>::@enum::E
      supertype: Enum
      fields
        synthetic static const values
          reference: <none>
          type: List<E<dynamic>>
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
          getter: <none>
      constructors
        synthetic const new
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@constructor::new
      getters
        synthetic static get values
          reference: <none>
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
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          element: <testLibraryFragment>::@enum::E
          typeParameters
            T @13
              element: <none>
            U @19
              element: <none>
            V @26
              element: <none>
          fields
            values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              element: <none>
          getters
            get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              element: <none>
  enums
    enum E
      reference: <testLibraryFragment>::@enum::E
      typeParameters
        T
        U
        V
      firstFragment: <testLibraryFragment>::@enum::E
      supertype: Enum
      fields
        synthetic static const values
          reference: <none>
          type: List<E<dynamic, dynamic, dynamic>>
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
          getter: <none>
      constructors
        synthetic const new
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@constructor::new
      getters
        synthetic static get values
          reference: <none>
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
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          element: <testLibraryFragment>::@enum::E
          fields
            enumConstant a @32
              reference: <testLibraryFragment>::@enum::E::@field::a
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::a
            enumConstant b @47
              reference: <testLibraryFragment>::@enum::E::@field::b
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::b
            values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              element: <none>
          getters
            get a @-1
              reference: <testLibraryFragment>::@enum::E::@getter::a
              element: <none>
            get b @-1
              reference: <testLibraryFragment>::@enum::E::@getter::b
              element: <none>
            get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              element: <none>
  enums
    enum E
      reference: <testLibraryFragment>::@enum::E
      firstFragment: <testLibraryFragment>::@enum::E
      supertype: Enum
      fields
        static const a
          reference: <none>
          type: E
          firstFragment: <testLibraryFragment>::@enum::E::@field::a
          getter: <none>
        static const b
          reference: <none>
          type: E
          firstFragment: <testLibraryFragment>::@enum::E::@field::b
          getter: <none>
        synthetic static const values
          reference: <none>
          type: List<E>
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
          getter: <none>
      constructors
        synthetic const new
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@constructor::new
      getters
        synthetic static get a
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@getter::a
        synthetic static get b
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@getter::b
        synthetic static get values
          reference: <none>
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
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          element: <testLibraryFragment>::@enum::E
          fields
            enumConstant a @46
              reference: <testLibraryFragment>::@enum::E::@field::a
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::a
            enumConstant b @75
              reference: <testLibraryFragment>::@enum::E::@field::b
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::b
            values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              element: <none>
          getters
            get a @-1
              reference: <testLibraryFragment>::@enum::E::@getter::a
              element: <none>
            get b @-1
              reference: <testLibraryFragment>::@enum::E::@getter::b
              element: <none>
            get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              element: <none>
      topLevelVariables
        const annotation @91
          reference: <testLibraryFragment>::@topLevelVariable::annotation
          element: <none>
          getter2: <testLibraryFragment>::@getter::annotation
      getters
        get annotation @-1
          reference: <testLibraryFragment>::@getter::annotation
          element: <none>
  enums
    enum E
      reference: <testLibraryFragment>::@enum::E
      firstFragment: <testLibraryFragment>::@enum::E
      supertype: Enum
      fields
        static const a
          reference: <none>
          type: E
          firstFragment: <testLibraryFragment>::@enum::E::@field::a
          getter: <none>
        static const b
          reference: <none>
          type: E
          firstFragment: <testLibraryFragment>::@enum::E::@field::b
          getter: <none>
        synthetic static const values
          reference: <none>
          type: List<E>
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
          getter: <none>
      constructors
        synthetic const new
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@constructor::new
      getters
        synthetic static get a
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@getter::a
        synthetic static get b
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@getter::b
        synthetic static get values
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@getter::values
  topLevelVariables
    const annotation
      reference: <none>
      type: int
      firstFragment: <testLibraryFragment>::@topLevelVariable::annotation
      getter: <none>
  getters
    synthetic static get annotation
      reference: <none>
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
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          element: <testLibraryFragment>::@enum::E
          fields
            enumConstant v1 @9
              reference: <testLibraryFragment>::@enum::E::@field::v1
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::v1
            enumConstant v2 @13
              reference: <testLibraryFragment>::@enum::E::@field::v2
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::v2
            values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              element: <none>
          getters
            get v1 @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v1
              element: <none>
            get v2 @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v2
              element: <none>
            get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              element: <none>
  enums
    enum E
      reference: <testLibraryFragment>::@enum::E
      firstFragment: <testLibraryFragment>::@enum::E
      supertype: Enum
      fields
        static const v1
          reference: <none>
          type: E
          firstFragment: <testLibraryFragment>::@enum::E::@field::v1
          getter: <none>
        static const v2
          reference: <none>
          type: E
          firstFragment: <testLibraryFragment>::@enum::E::@field::v2
          getter: <none>
        synthetic static const values
          reference: <none>
          type: List<E>
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
          getter: <none>
      constructors
        synthetic const new
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@constructor::new
      getters
        synthetic static get v1
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@getter::v1
        synthetic static get v2
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@getter::v2
        synthetic static get values
          reference: <none>
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
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      enums
        enum E1 @5
          reference: <testLibraryFragment>::@enum::E1
          element: <testLibraryFragment>::@enum::E1
          fields
            enumConstant v1 @10
              reference: <testLibraryFragment>::@enum::E1::@field::v1
              element: <none>
              getter2: <testLibraryFragment>::@enum::E1::@getter::v1
            values @-1
              reference: <testLibraryFragment>::@enum::E1::@field::values
              element: <none>
              getter2: <testLibraryFragment>::@enum::E1::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::E1::@constructor::new
              element: <none>
          getters
            get v1 @-1
              reference: <testLibraryFragment>::@enum::E1::@getter::v1
              element: <none>
            get values @-1
              reference: <testLibraryFragment>::@enum::E1::@getter::values
              element: <none>
        enum E2 @20
          reference: <testLibraryFragment>::@enum::E2
          element: <testLibraryFragment>::@enum::E2
          fields
            enumConstant v2 @25
              reference: <testLibraryFragment>::@enum::E2::@field::v2
              element: <none>
              getter2: <testLibraryFragment>::@enum::E2::@getter::v2
            values @-1
              reference: <testLibraryFragment>::@enum::E2::@field::values
              element: <none>
              getter2: <testLibraryFragment>::@enum::E2::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::E2::@constructor::new
              element: <none>
          getters
            get v2 @-1
              reference: <testLibraryFragment>::@enum::E2::@getter::v2
              element: <none>
            get values @-1
              reference: <testLibraryFragment>::@enum::E2::@getter::values
              element: <none>
  enums
    enum E1
      reference: <testLibraryFragment>::@enum::E1
      firstFragment: <testLibraryFragment>::@enum::E1
      supertype: Enum
      fields
        static const v1
          reference: <none>
          type: E1
          firstFragment: <testLibraryFragment>::@enum::E1::@field::v1
          getter: <none>
        synthetic static const values
          reference: <none>
          type: List<E1>
          firstFragment: <testLibraryFragment>::@enum::E1::@field::values
          getter: <none>
      constructors
        synthetic const new
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E1::@constructor::new
      getters
        synthetic static get v1
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E1::@getter::v1
        synthetic static get values
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E1::@getter::values
    enum E2
      reference: <testLibraryFragment>::@enum::E2
      firstFragment: <testLibraryFragment>::@enum::E2
      supertype: Enum
      fields
        static const v2
          reference: <none>
          type: E2
          firstFragment: <testLibraryFragment>::@enum::E2::@field::v2
          getter: <none>
        synthetic static const values
          reference: <none>
          type: List<E2>
          firstFragment: <testLibraryFragment>::@enum::E2::@field::values
          getter: <none>
      constructors
        synthetic const new
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E2::@constructor::new
      getters
        synthetic static get v2
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E2::@getter::v2
        synthetic static get values
          reference: <none>
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
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class M @24
          reference: <testLibraryFragment>::@class::M
          element: <testLibraryFragment>::@class::M
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::M::@constructor::new
              element: <none>
        class A @36
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <none>
          methods
            foo @52
              reference: <testLibraryFragment>::@class::A::@method::foo
              element: <none>
        class B @70
          reference: <testLibraryFragment>::@class::B
          element: <testLibraryFragment>::@class::B
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::B::@constructor::new
              element: <none>
          methods
            foo @92
              reference: <testLibraryFragment>::@class::B::@method::foo
              element: <none>
        class C @110
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <none>
          methods
            foo @141
              reference: <testLibraryFragment>::@class::C::@method::foo
              element: <none>
        class D @159
          reference: <testLibraryFragment>::@class::D
          element: <testLibraryFragment>::@class::D
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@class::D::@constructor::new
              element: <none>
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
          element: <testLibraryFragment>::@enum::E
          fields
            enumConstant a @8
              reference: <testLibraryFragment>::@enum::E::@field::a
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::a
            enumConstant b @11
              reference: <testLibraryFragment>::@enum::E::@field::b
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::b
            enumConstant c @14
              reference: <testLibraryFragment>::@enum::E::@field::c
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::c
            values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              element: <none>
          getters
            get a @-1
              reference: <testLibraryFragment>::@enum::E::@getter::a
              element: <none>
            get b @-1
              reference: <testLibraryFragment>::@enum::E::@getter::b
              element: <none>
            get c @-1
              reference: <testLibraryFragment>::@enum::E::@getter::c
              element: <none>
            get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              element: <none>
  classes
    class M
      reference: <testLibraryFragment>::@class::M
      firstFragment: <testLibraryFragment>::@class::M
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::M::@constructor::new
    class A
      reference: <testLibraryFragment>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
      methods
        foo
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::A::@method::foo
    class B
      reference: <testLibraryFragment>::@class::B
      firstFragment: <testLibraryFragment>::@class::B
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::B::@constructor::new
      methods
        foo
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::B::@method::foo
    class C
      reference: <testLibraryFragment>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      supertype: Object
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      methods
        foo
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@method::foo
    class alias D
      reference: <testLibraryFragment>::@class::D
      firstFragment: <testLibraryFragment>::@class::D
      supertype: Object
      constructors
        synthetic const new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::D::@constructor::new
  enums
    enum E
      reference: <testLibraryFragment>::@enum::E
      firstFragment: <testLibraryFragment>::@enum::E
      supertype: Enum
      fields
        static const a
          reference: <none>
          type: E
          firstFragment: <testLibraryFragment>::@enum::E::@field::a
          getter: <none>
        static const b
          reference: <none>
          type: E
          firstFragment: <testLibraryFragment>::@enum::E::@field::b
          getter: <none>
        static const c
          reference: <none>
          type: E
          firstFragment: <testLibraryFragment>::@enum::E::@field::c
          getter: <none>
        synthetic static const values
          reference: <none>
          type: List<E>
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
          getter: <none>
      constructors
        synthetic const new
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@constructor::new
      getters
        synthetic static get a
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@getter::a
        synthetic static get b
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@getter::b
        synthetic static get c
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@getter::c
        synthetic static get values
          reference: <none>
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
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      enums
        enum E @19
          reference: <testLibraryFragment>::@enum::E
          element: <testLibraryFragment>::@enum::E
          fields
            enumConstant v @26
              reference: <testLibraryFragment>::@enum::E::@field::v
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              element: <none>
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              element: <none>
            get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              element: <none>
      topLevelVariables
        const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <none>
          getter2: <testLibraryFragment>::@getter::a
      getters
        get a @-1
          reference: <testLibraryFragment>::@getter::a
          element: <none>
  enums
    enum E
      reference: <testLibraryFragment>::@enum::E
      firstFragment: <testLibraryFragment>::@enum::E
      supertype: Enum
      fields
        static const v
          reference: <none>
          type: E
          firstFragment: <testLibraryFragment>::@enum::E::@field::v
          getter: <none>
        synthetic static const values
          reference: <none>
          type: List<E>
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
          getter: <none>
      constructors
        synthetic const new
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@constructor::new
      getters
        synthetic static get v
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@getter::v
        synthetic static get values
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@getter::values
  topLevelVariables
    const a
      reference: <none>
      type: int
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      getter: <none>
  getters
    synthetic static get a
      reference: <none>
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
            value @26
              reference: <testLibraryFragment>::@class::A::@field::value
              element: <none>
              getter2: <testLibraryFragment>::@class::A::@getter::value
          constructors
            const new @41
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <none>
              parameters
                this.value @48
                  element: <none>
          getters
            get value @-1
              reference: <testLibraryFragment>::@class::A::@getter::value
              element: <none>
      enums
        enum E @64
          reference: <testLibraryFragment>::@enum::E
          element: <testLibraryFragment>::@enum::E
          fields
            enumConstant a @78
              reference: <testLibraryFragment>::@enum::E::@field::a
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::a
            enumConstant b @83
              reference: <testLibraryFragment>::@enum::E::@field::b
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::b
            enumConstant c @96
              reference: <testLibraryFragment>::@enum::E::@field::c
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::c
            values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              element: <none>
          getters
            get a @-1
              reference: <testLibraryFragment>::@enum::E::@getter::a
              element: <none>
            get b @-1
              reference: <testLibraryFragment>::@enum::E::@getter::b
              element: <none>
            get c @-1
              reference: <testLibraryFragment>::@enum::E::@getter::c
              element: <none>
            get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              element: <none>
  classes
    class A
      reference: <testLibraryFragment>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
      fields
        final value
          reference: <none>
          type: dynamic
          firstFragment: <testLibraryFragment>::@class::A::@field::value
          getter: <none>
      constructors
        const new
          reference: <none>
          parameters
            requiredPositional final value
              reference: <none>
              type: dynamic
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
      getters
        synthetic get value
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::A::@getter::value
  enums
    enum E
      reference: <testLibraryFragment>::@enum::E
      firstFragment: <testLibraryFragment>::@enum::E
      supertype: Enum
      fields
        static const a
          reference: <none>
          type: E
          firstFragment: <testLibraryFragment>::@enum::E::@field::a
          getter: <none>
        static const b
          reference: <none>
          type: E
          firstFragment: <testLibraryFragment>::@enum::E::@field::b
          getter: <none>
        static const c
          reference: <none>
          type: E
          firstFragment: <testLibraryFragment>::@enum::E::@field::c
          getter: <none>
        synthetic static const values
          reference: <none>
          type: List<E>
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
          getter: <none>
      constructors
        synthetic const new
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@constructor::new
      getters
        synthetic static get a
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@getter::a
        synthetic static get b
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@getter::b
        synthetic static get c
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@getter::c
        synthetic static get values
          reference: <none>
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
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      enums
        enum E @5
          reference: <testLibraryFragment>::@enum::E
          element: <testLibraryFragment>::@enum::E
          fields
            enumConstant v @16
              reference: <testLibraryFragment>::@enum::E::@field::v
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              element: <none>
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              element: <none>
            get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              element: <none>
  enums
    enum E
      reference: <testLibraryFragment>::@enum::E
      firstFragment: <testLibraryFragment>::@enum::E
      supertype: Enum
      fields
        static const v
          reference: <none>
          type: E
          firstFragment: <testLibraryFragment>::@enum::E::@field::v
          getter: <none>
        synthetic static const values
          reference: <none>
          type: List<E>
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
          getter: <none>
      constructors
        synthetic const new
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@constructor::new
      getters
        synthetic static get v
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@getter::v
        synthetic static get values
          reference: <none>
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
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      enums
        enum E @19
          reference: <testLibraryFragment>::@enum::E
          element: <testLibraryFragment>::@enum::E
          fields
            enumConstant v @25
              reference: <testLibraryFragment>::@enum::E::@field::v
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::values
          constructors
            const new @41
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              element: <none>
              metadata
                Annotation
                  atSign: @ @30
                  name: SimpleIdentifier
                    token: a @31
                    staticElement: <testLibraryFragment>::@getter::a
                    staticType: null
                  element: <testLibraryFragment>::@getter::a
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              element: <none>
            get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              element: <none>
      topLevelVariables
        const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <none>
          getter2: <testLibraryFragment>::@getter::a
      getters
        get a @-1
          reference: <testLibraryFragment>::@getter::a
          element: <none>
  enums
    enum E
      reference: <testLibraryFragment>::@enum::E
      firstFragment: <testLibraryFragment>::@enum::E
      supertype: Enum
      fields
        static const v
          reference: <none>
          type: E
          firstFragment: <testLibraryFragment>::@enum::E::@field::v
          getter: <none>
        synthetic static const values
          reference: <none>
          type: List<E>
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
          getter: <none>
      constructors
        const new
          reference: <none>
          metadata
            Annotation
              atSign: @ @30
              name: SimpleIdentifier
                token: a @31
                staticElement: <testLibraryFragment>::@getter::a
                staticType: null
              element: <testLibraryFragment>::@getter::a
          firstFragment: <testLibraryFragment>::@enum::E::@constructor::new
      getters
        synthetic static get v
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@getter::v
        synthetic static get values
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@getter::values
  topLevelVariables
    const a
      reference: <none>
      type: int
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      getter: <none>
  getters
    synthetic static get a
      reference: <none>
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
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      enums
        enum E @19
          reference: <testLibraryFragment>::@enum::E
          element: <testLibraryFragment>::@enum::E
          fields
            enumConstant v @25
              reference: <testLibraryFragment>::@enum::E::@field::v
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              element: <none>
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              element: <none>
            get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              element: <none>
          methods
            foo @40
              reference: <testLibraryFragment>::@enum::E::@method::foo
              element: <none>
              metadata
                Annotation
                  atSign: @ @30
                  name: SimpleIdentifier
                    token: a @31
                    staticElement: <testLibraryFragment>::@getter::a
                    staticType: null
                  element: <testLibraryFragment>::@getter::a
      topLevelVariables
        const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <none>
          getter2: <testLibraryFragment>::@getter::a
      getters
        get a @-1
          reference: <testLibraryFragment>::@getter::a
          element: <none>
  enums
    enum E
      reference: <testLibraryFragment>::@enum::E
      firstFragment: <testLibraryFragment>::@enum::E
      supertype: Enum
      fields
        static const v
          reference: <none>
          type: E
          firstFragment: <testLibraryFragment>::@enum::E::@field::v
          getter: <none>
        synthetic static const values
          reference: <none>
          type: List<E>
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
          getter: <none>
      constructors
        synthetic const new
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@constructor::new
      getters
        synthetic static get v
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@getter::v
        synthetic static get values
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@getter::values
      methods
        foo
          reference: <none>
          metadata
            Annotation
              atSign: @ @30
              name: SimpleIdentifier
                token: a @31
                staticElement: <testLibraryFragment>::@getter::a
                staticType: null
              element: <testLibraryFragment>::@getter::a
          firstFragment: <testLibraryFragment>::@enum::E::@method::foo
  topLevelVariables
    const a
      reference: <none>
      type: int
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      getter: <none>
  getters
    synthetic static get a
      reference: <none>
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
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      enums
        enum E @26
          reference: <testLibraryFragment>::@enum::E
          element: <testLibraryFragment>::@enum::E
          typeParameters
            T @33
              element: <none>
              metadata
                Annotation
                  atSign: @ @28
                  name: SimpleIdentifier
                    token: foo @29
                    staticElement: <testLibraryFragment>::@getter::foo
                    staticType: null
                  element: <testLibraryFragment>::@getter::foo
          fields
            enumConstant v @40
              reference: <testLibraryFragment>::@enum::E::@field::v
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::values
            foo @58
              reference: <testLibraryFragment>::@enum::E::@field::foo
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::foo
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              element: <none>
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              element: <none>
            get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              element: <none>
            get foo @-1
              reference: <testLibraryFragment>::@enum::E::@getter::foo
              element: <none>
          methods
            bar @81
              reference: <testLibraryFragment>::@enum::E::@method::bar
              element: <none>
              metadata
                Annotation
                  atSign: @ @69
                  name: SimpleIdentifier
                    token: foo @70
                    staticElement: <testLibraryFragment>::@enum::E::@getter::foo
                    staticType: null
                  element: <testLibraryFragment>::@enum::E::@getter::foo
      topLevelVariables
        const foo @6
          reference: <testLibraryFragment>::@topLevelVariable::foo
          element: <none>
          getter2: <testLibraryFragment>::@getter::foo
      getters
        get foo @-1
          reference: <testLibraryFragment>::@getter::foo
          element: <none>
  enums
    enum E
      reference: <testLibraryFragment>::@enum::E
      typeParameters
        T
          metadata
            Annotation
              atSign: @ @28
              name: SimpleIdentifier
                token: foo @29
                staticElement: <testLibraryFragment>::@getter::foo
                staticType: null
              element: <testLibraryFragment>::@getter::foo
      firstFragment: <testLibraryFragment>::@enum::E
      supertype: Enum
      fields
        static const v
          reference: <none>
          type: E<dynamic>
          firstFragment: <testLibraryFragment>::@enum::E::@field::v
          getter: <none>
        synthetic static const values
          reference: <none>
          type: List<E<dynamic>>
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
          getter: <none>
        static const foo
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@enum::E::@field::foo
          getter: <none>
      constructors
        synthetic const new
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@constructor::new
      getters
        synthetic static get v
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@getter::v
        synthetic static get values
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@getter::values
        synthetic static get foo
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@getter::foo
      methods
        bar
          reference: <none>
          metadata
            Annotation
              atSign: @ @69
              name: SimpleIdentifier
                token: foo @70
                staticElement: <testLibraryFragment>::@enum::E::@getter::foo
                staticType: null
              element: <testLibraryFragment>::@enum::E::@getter::foo
          firstFragment: <testLibraryFragment>::@enum::E::@method::bar
  topLevelVariables
    const foo
      reference: <none>
      type: int
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo
      getter: <none>
  getters
    synthetic static get foo
      reference: <none>
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
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      enums
        enum E @19
          reference: <testLibraryFragment>::@enum::E
          element: <testLibraryFragment>::@enum::E
          typeParameters
            T @24
              element: <none>
              metadata
                Annotation
                  atSign: @ @21
                  name: SimpleIdentifier
                    token: a @22
                    staticElement: <testLibraryFragment>::@getter::a
                    staticType: null
                  element: <testLibraryFragment>::@getter::a
          fields
            enumConstant v @31
              reference: <testLibraryFragment>::@enum::E::@field::v
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              element: <none>
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              element: <none>
            get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              element: <none>
      topLevelVariables
        const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <none>
          getter2: <testLibraryFragment>::@getter::a
      getters
        get a @-1
          reference: <testLibraryFragment>::@getter::a
          element: <none>
  enums
    enum E
      reference: <testLibraryFragment>::@enum::E
      typeParameters
        T
          metadata
            Annotation
              atSign: @ @21
              name: SimpleIdentifier
                token: a @22
                staticElement: <testLibraryFragment>::@getter::a
                staticType: null
              element: <testLibraryFragment>::@getter::a
      firstFragment: <testLibraryFragment>::@enum::E
      supertype: Enum
      fields
        static const v
          reference: <none>
          type: E<dynamic>
          firstFragment: <testLibraryFragment>::@enum::E::@field::v
          getter: <none>
        synthetic static const values
          reference: <none>
          type: List<E<dynamic>>
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
          getter: <none>
      constructors
        synthetic const new
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@constructor::new
      getters
        synthetic static get v
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@getter::v
        synthetic static get values
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@getter::values
  topLevelVariables
    const a
      reference: <none>
      type: int
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      getter: <none>
  getters
    synthetic static get a
      reference: <none>
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
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      enums
        enum E @22
          reference: <testLibraryFragment>::@enum::E
          element: <testLibraryFragment>::@enum::E
          fields
            enumConstant v @26
              reference: <testLibraryFragment>::@enum::E::@field::v
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::E::@field::values
              element: <none>
              getter2: <testLibraryFragment>::@enum::E::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::E::@constructor::new
              element: <none>
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::E::@getter::v
              element: <none>
            get values @-1
              reference: <testLibraryFragment>::@enum::E::@getter::values
              element: <none>
      topLevelVariables
        const a @6
          reference: <testLibraryFragment>::@topLevelVariable::a
          element: <none>
          getter2: <testLibraryFragment>::@getter::a
      getters
        get a @-1
          reference: <testLibraryFragment>::@getter::a
          element: <none>
  enums
    enum E
      reference: <testLibraryFragment>::@enum::E
      firstFragment: <testLibraryFragment>::@enum::E
      supertype: Enum
      fields
        static const v
          reference: <none>
          type: E
          firstFragment: <testLibraryFragment>::@enum::E::@field::v
          getter: <none>
        synthetic static const values
          reference: <none>
          type: List<E>
          firstFragment: <testLibraryFragment>::@enum::E::@field::values
          getter: <none>
      constructors
        synthetic const new
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@constructor::new
      getters
        synthetic static get v
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@getter::v
        synthetic static get values
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::E::@getter::values
  topLevelVariables
    const a
      reference: <none>
      type: int
      firstFragment: <testLibraryFragment>::@topLevelVariable::a
      getter: <none>
  getters
    synthetic static get a
      reference: <none>
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
      enclosingElement: <testLibrary>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      enums
        enum A @27
          reference: <testLibrary>::@fragment::package:test/a.dart::@enum::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @33
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
            foo @43
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
        augment enum A @68
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@enum::A
          methods
            bar @80
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@method::bar
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
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
          element: <testLibrary>::@fragment::package:test/a.dart::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            enumConstant v @33
              reference: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@field::v
              element: <none>
              getter2: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@getter::v
            values @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@field::values
              element: <none>
              getter2: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@constructor::new
              element: <none>
          getters
            get v @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@getter::v
              element: <none>
            get values @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@getter::values
              element: <none>
          methods
            foo @43
              reference: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@method::foo
              element: <none>
        enum A @68
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibrary>::@fragment::package:test/a.dart::@enum::A
          previousFragment: <testLibrary>::@fragment::package:test/a.dart::@enum::A
          methods
            bar @80
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@method::bar
              element: <none>
  enums
    enum A
      reference: <testLibrary>::@fragment::package:test/a.dart::@enum::A
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enum::A
      supertype: Enum
      fields
        static const v
          reference: <none>
          type: A
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@field::v
          getter: <none>
        synthetic static const values
          reference: <none>
          type: List<A>
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@field::values
          getter: <none>
      constructors
        synthetic const new
          reference: <none>
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@constructor::new
      getters
        synthetic static get v
          reference: <none>
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@getter::v
        synthetic static get values
          reference: <none>
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@getter::values
      methods
        foo
          reference: <none>
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@method::foo
        bar
          reference: <none>
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
      enclosingElement: <testLibrary>
      parts
        part_0
          uri: package:test/a1.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a1.dart
        part_1
          uri: package:test/a2.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a2.dart
      enums
        enum A @37
          reference: <testLibraryFragment>::@enum::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a1.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @43
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
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      parts
        part_2
          uri: package:test/a11.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibrary>::@fragment::package:test/a1.dart
          unit: <testLibrary>::@fragment::package:test/a11.dart
        part_3
          uri: package:test/a12.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibrary>::@fragment::package:test/a1.dart
          unit: <testLibrary>::@fragment::package:test/a12.dart
      enums
        augment enum A @68
          reference: <testLibrary>::@fragment::package:test/a1.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a1.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          augmentation: <testLibrary>::@fragment::package:test/a11.dart::@enumAugmentation::A
    <testLibrary>::@fragment::package:test/a11.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibrary>::@fragment::package:test/a1.dart
      enums
        augment enum A @32
          reference: <testLibrary>::@fragment::package:test/a11.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a11.dart
          augmentationTarget: <testLibrary>::@fragment::package:test/a1.dart::@enumAugmentation::A
          augmentation: <testLibrary>::@fragment::package:test/a12.dart::@enumAugmentation::A
    <testLibrary>::@fragment::package:test/a12.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibrary>::@fragment::package:test/a1.dart
      enums
        augment enum A @32
          reference: <testLibrary>::@fragment::package:test/a12.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a12.dart
          augmentationTarget: <testLibrary>::@fragment::package:test/a11.dart::@enumAugmentation::A
          augmentation: <testLibrary>::@fragment::package:test/a2.dart::@enumAugmentation::A
    <testLibrary>::@fragment::package:test/a2.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      parts
        part_4
          uri: package:test/a21.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibrary>::@fragment::package:test/a2.dart
          unit: <testLibrary>::@fragment::package:test/a21.dart
        part_5
          uri: package:test/a22.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibrary>::@fragment::package:test/a2.dart
          unit: <testLibrary>::@fragment::package:test/a22.dart
      enums
        augment enum A @68
          reference: <testLibrary>::@fragment::package:test/a2.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a2.dart
          augmentationTarget: <testLibrary>::@fragment::package:test/a12.dart::@enumAugmentation::A
          augmentation: <testLibrary>::@fragment::package:test/a21.dart::@enumAugmentation::A
    <testLibrary>::@fragment::package:test/a21.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibrary>::@fragment::package:test/a2.dart
      enums
        augment enum A @32
          reference: <testLibrary>::@fragment::package:test/a21.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a21.dart
          augmentationTarget: <testLibrary>::@fragment::package:test/a2.dart::@enumAugmentation::A
          augmentation: <testLibrary>::@fragment::package:test/a22.dart::@enumAugmentation::A
    <testLibrary>::@fragment::package:test/a22.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibrary>::@fragment::package:test/a2.dart
      enums
        augment enum A @32
          reference: <testLibrary>::@fragment::package:test/a22.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a22.dart
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
          element: <testLibraryFragment>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/a1.dart::@enumAugmentation::A
          fields
            enumConstant v @43
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <none>
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <none>
            get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <none>
    <testLibrary>::@fragment::package:test/a1.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/a11.dart
      enums
        enum A @68
          reference: <testLibrary>::@fragment::package:test/a1.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A
          previousFragment: <testLibraryFragment>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/a11.dart::@enumAugmentation::A
    <testLibrary>::@fragment::package:test/a11.dart
      element: <testLibrary>
      previousFragment: <testLibrary>::@fragment::package:test/a1.dart
      nextFragment: <testLibrary>::@fragment::package:test/a12.dart
      enums
        enum A @32
          reference: <testLibrary>::@fragment::package:test/a11.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A
          previousFragment: <testLibrary>::@fragment::package:test/a1.dart::@enumAugmentation::A
          nextFragment: <testLibrary>::@fragment::package:test/a12.dart::@enumAugmentation::A
    <testLibrary>::@fragment::package:test/a12.dart
      element: <testLibrary>
      previousFragment: <testLibrary>::@fragment::package:test/a11.dart
      nextFragment: <testLibrary>::@fragment::package:test/a2.dart
      enums
        enum A @32
          reference: <testLibrary>::@fragment::package:test/a12.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A
          previousFragment: <testLibrary>::@fragment::package:test/a11.dart::@enumAugmentation::A
          nextFragment: <testLibrary>::@fragment::package:test/a2.dart::@enumAugmentation::A
    <testLibrary>::@fragment::package:test/a2.dart
      element: <testLibrary>
      previousFragment: <testLibrary>::@fragment::package:test/a12.dart
      nextFragment: <testLibrary>::@fragment::package:test/a21.dart
      enums
        enum A @68
          reference: <testLibrary>::@fragment::package:test/a2.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A
          previousFragment: <testLibrary>::@fragment::package:test/a12.dart::@enumAugmentation::A
          nextFragment: <testLibrary>::@fragment::package:test/a21.dart::@enumAugmentation::A
    <testLibrary>::@fragment::package:test/a21.dart
      element: <testLibrary>
      previousFragment: <testLibrary>::@fragment::package:test/a2.dart
      nextFragment: <testLibrary>::@fragment::package:test/a22.dart
      enums
        enum A @32
          reference: <testLibrary>::@fragment::package:test/a21.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A
          previousFragment: <testLibrary>::@fragment::package:test/a2.dart::@enumAugmentation::A
          nextFragment: <testLibrary>::@fragment::package:test/a22.dart::@enumAugmentation::A
    <testLibrary>::@fragment::package:test/a22.dart
      element: <testLibrary>
      previousFragment: <testLibrary>::@fragment::package:test/a21.dart
      enums
        enum A @32
          reference: <testLibrary>::@fragment::package:test/a22.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A
          previousFragment: <testLibrary>::@fragment::package:test/a21.dart::@enumAugmentation::A
  enums
    enum A
      reference: <testLibraryFragment>::@enum::A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const v
          reference: <none>
          type: A
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          getter: <none>
        synthetic static const values
          reference: <none>
          type: List<A>
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          getter: <none>
      constructors
        synthetic const new
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@constructor::new
      getters
        synthetic static get v
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@getter::v
        synthetic static get values
          reference: <none>
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
      enclosingElement: <testLibrary>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @35
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
            foo1 @47
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::0::@method::foo1
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::0
              returnType: void
        enum A @65
          reference: <testLibrary>::@fragment::package:test/a.dart::@enum::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::1
          supertype: Enum
          fields
            static const enumConstant v @71
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
            foo2 @81
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
        augment enum A @107
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::1
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@enum::A
          methods
            foo3 @119
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::1::@method::foo3
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::1
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
          element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::0
          fields
            values @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::0::@field::values
              element: <none>
              getter2: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::0::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::0::@constructor::new
              element: <none>
          getters
            get values @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::0::@getter::values
              element: <none>
          methods
            foo1 @47
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::0::@method::foo1
              element: <none>
        enum A @65
          reference: <testLibrary>::@fragment::package:test/a.dart::@enum::A
          element: <testLibrary>::@fragment::package:test/a.dart::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::1
          fields
            enumConstant v @71
              reference: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@field::v
              element: <none>
              getter2: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@getter::v
            values @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@field::values
              element: <none>
              getter2: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@constructor::new
              element: <none>
          getters
            get v @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@getter::v
              element: <none>
            get values @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@getter::values
              element: <none>
          methods
            foo2 @81
              reference: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@method::foo2
              element: <none>
        enum A @107
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::1
          element: <testLibrary>::@fragment::package:test/a.dart::@enum::A
          previousFragment: <testLibrary>::@fragment::package:test/a.dart::@enum::A
          methods
            foo3 @119
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::1::@method::foo3
              element: <none>
  enums
    enum A
      reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::0
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::0
      supertype: Enum
      fields
        synthetic static const values
          reference: <none>
          type: List<A>
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::0::@field::values
          getter: <none>
      constructors
        synthetic const new
          reference: <none>
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::0::@constructor::new
      getters
        synthetic static get values
          reference: <none>
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::0::@getter::values
      methods
        foo1
          reference: <none>
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::0::@method::foo1
    enum A
      reference: <testLibrary>::@fragment::package:test/a.dart::@enum::A
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enum::A
      supertype: Enum
      fields
        static const v
          reference: <none>
          type: A
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@field::v
          getter: <none>
        synthetic static const values
          reference: <none>
          type: List<A>
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@field::values
          getter: <none>
      constructors
        synthetic const new
          reference: <none>
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@constructor::new
      getters
        synthetic static get v
          reference: <none>
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@getter::v
        synthetic static get values
          reference: <none>
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@getter::values
      methods
        foo2
          reference: <none>
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enum::A::@method::foo2
        foo3
          reference: <none>
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
      enclosingElement: <testLibrary>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      parts
        part_1
          uri: package:test/b.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          unit: <testLibrary>::@fragment::package:test/b.dart
      enums
        augment enum A @49
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
            foo1 @61
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
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
      enums
        augment enum A @31
          reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/b.dart
          augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          methods
            foo2 @43
              reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@method::foo2
              enclosingElement: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
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
          element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          nextFragment: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          fields
            values @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::values
              element: <none>
              getter2: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructor::new
              element: <none>
          getters
            get values @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::values
              element: <none>
          methods
            foo1 @61
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@method::foo1
              element: <none>
    <testLibrary>::@fragment::package:test/b.dart
      element: <testLibrary>
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @31
          reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          element: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          previousFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          methods
            foo2 @43
              reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@method::foo2
              element: <none>
  enums
    enum A
      reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
      supertype: Enum
      fields
        synthetic static const values
          reference: <none>
          type: List<A>
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::values
          getter: <none>
      constructors
        synthetic const new
          reference: <none>
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructor::new
      getters
        synthetic static get values
          reference: <none>
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::values
      methods
        foo1
          reference: <none>
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@method::foo1
        foo2
          reference: <none>
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
      enclosingElement: <testLibrary>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v1 @26
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
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          fields
            static const enumConstant v2 @40
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
          element: <testLibraryFragment>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            enumConstant v1 @26
              reference: <testLibraryFragment>::@enum::A::@field::v1
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::v1
            values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <none>
          getters
            get v1 @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v1
              element: <none>
            get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <none>
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A
          previousFragment: <testLibraryFragment>::@enum::A
          fields
            enumConstant v2 @40
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::v2
              element: <none>
              getter2: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::v2
          getters
            get v2 @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::v2
              element: <none>
  enums
    enum A
      reference: <testLibraryFragment>::@enum::A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const v1
          reference: <none>
          type: A
          firstFragment: <testLibraryFragment>::@enum::A::@field::v1
          getter: <none>
        synthetic static const values
          reference: <none>
          type: List<A>
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          getter: <none>
        static const v2
          reference: <none>
          type: A
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::v2
          getter: <none>
      constructors
        synthetic const new
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@constructor::new
      getters
        synthetic static get v1
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@getter::v1
        synthetic static get values
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@getter::values
        synthetic static get v2
          reference: <none>
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
      enclosingElement: <testLibrary>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
        part_1
          uri: package:test/b.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/b.dart
      enums
        enum A @35
          reference: <testLibraryFragment>::@enum::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v1 @41
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
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          augmentation: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          fields
            static const enumConstant v2 @40
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
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @34
          reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/b.dart
          augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            static const enumConstant v3 @40
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
          element: <testLibraryFragment>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            enumConstant v1 @41
              reference: <testLibraryFragment>::@enum::A::@field::v1
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::v1
            values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <none>
          getters
            get v1 @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v1
              element: <none>
            get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <none>
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A
          previousFragment: <testLibraryFragment>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          fields
            enumConstant v2 @40
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::v2
              element: <none>
              getter2: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::v2
          getters
            get v2 @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::v2
              element: <none>
    <testLibrary>::@fragment::package:test/b.dart
      element: <testLibrary>
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A
          previousFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            enumConstant v3 @40
              reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@field::v3
              element: <none>
              getter2: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@getter::v3
          getters
            get v3 @-1
              reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@getter::v3
              element: <none>
  enums
    enum A
      reference: <testLibraryFragment>::@enum::A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const v1
          reference: <none>
          type: A
          firstFragment: <testLibraryFragment>::@enum::A::@field::v1
          getter: <none>
        synthetic static const values
          reference: <none>
          type: List<A>
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          getter: <none>
        static const v2
          reference: <none>
          type: A
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::v2
          getter: <none>
        static const v3
          reference: <none>
          type: A
          firstFragment: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@field::v3
          getter: <none>
      constructors
        synthetic const new
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@constructor::new
      getters
        synthetic static get v1
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@getter::v1
        synthetic static get values
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@getter::values
        synthetic static get v2
          reference: <none>
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::v2
        synthetic static get v3
          reference: <none>
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
      enclosingElement: <testLibrary>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v1 @26
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
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          fields
            static const enumConstant v2 @40
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
            augment static const enumConstant v2 @54
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
          element: <testLibraryFragment>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            enumConstant v1 @26
              reference: <testLibraryFragment>::@enum::A::@field::v1
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::v1
            values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <none>
          getters
            get v1 @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v1
              element: <none>
            get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <none>
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A
          previousFragment: <testLibraryFragment>::@enum::A
          fields
            enumConstant v2 @40
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::v2
              element: <none>
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@fieldAugmentation::v2
              getter2: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::v2
            enumConstant v2 @54
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@fieldAugmentation::v2
              element: <none>
              previousFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::v2
          getters
            get v2 @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::v2
              element: <none>
  enums
    enum A
      reference: <testLibraryFragment>::@enum::A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const v1
          reference: <none>
          type: A
          firstFragment: <testLibraryFragment>::@enum::A::@field::v1
          getter: <none>
        synthetic static const values
          reference: <none>
          type: List<A>
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          getter: <none>
        static const v2
          reference: <none>
          type: A
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::v2
          getter: <none>
      constructors
        synthetic const new
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@constructor::new
      getters
        synthetic static get v1
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@getter::v1
        synthetic static get values
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@getter::values
        synthetic static get v2
          reference: <none>
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
      enclosingElement: <testLibrary>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v1 @26
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
            static const enumConstant v2 @30
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
            static const enumConstant v3 @34
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
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          fields
            augment static const enumConstant v2 @48
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
          element: <testLibraryFragment>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            enumConstant v1 @26
              reference: <testLibraryFragment>::@enum::A::@field::v1
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::v1
            enumConstant v2 @30
              reference: <testLibraryFragment>::@enum::A::@field::v2
              element: <none>
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@fieldAugmentation::v2
              getter2: <testLibraryFragment>::@enum::A::@getter::v2
            enumConstant v3 @34
              reference: <testLibraryFragment>::@enum::A::@field::v3
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::v3
            values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <none>
          getters
            get v1 @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v1
              element: <none>
            get v2 @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v2
              element: <none>
            get v3 @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v3
              element: <none>
            get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <none>
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A
          previousFragment: <testLibraryFragment>::@enum::A
          fields
            enumConstant v2 @48
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@fieldAugmentation::v2
              element: <none>
              previousFragment: <testLibraryFragment>::@enum::A::@field::v2
  enums
    enum A
      reference: <testLibraryFragment>::@enum::A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const v1
          reference: <none>
          type: A
          firstFragment: <testLibraryFragment>::@enum::A::@field::v1
          getter: <none>
        static const v3
          reference: <none>
          type: A
          firstFragment: <testLibraryFragment>::@enum::A::@field::v3
          getter: <none>
        synthetic static const values
          reference: <none>
          type: List<A>
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          getter: <none>
        static const v2
          reference: <none>
          type: A
          firstFragment: <testLibraryFragment>::@enum::A::@field::v2
          getter: <none>
      constructors
        synthetic const new
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@constructor::new
      getters
        synthetic static get v1
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@getter::v1
        synthetic static get v2
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@getter::v2
        synthetic static get v3
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@getter::v3
        synthetic static get values
          reference: <none>
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
      enclosingElement: <testLibrary>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v1 @26
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
                        literal: 1 @29
                        staticType: int
                    rightParenthesis: ) @0
                  staticType: A
              id: field_0
              getter: getter_0
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@fieldAugmentation::v1
            static const enumConstant v2 @33
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
                        literal: 2 @36
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
            const @48
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@enum::A
              parameters
                requiredPositional value @54
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
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          fields
            augment static const enumConstant v1 @48
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
          element: <testLibraryFragment>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            enumConstant v1 @26
              reference: <testLibraryFragment>::@enum::A::@field::v1
              element: <none>
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@fieldAugmentation::v1
              getter2: <testLibraryFragment>::@enum::A::@getter::v1
            enumConstant v2 @33
              reference: <testLibraryFragment>::@enum::A::@field::v2
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::v2
            values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::values
          constructors
            const new @48
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <none>
              parameters
                value @54
                  element: <none>
          getters
            get v1 @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v1
              element: <none>
            get v2 @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v2
              element: <none>
            get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <none>
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A
          previousFragment: <testLibraryFragment>::@enum::A
          fields
            enumConstant v1 @48
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@fieldAugmentation::v1
              element: <none>
              previousFragment: <testLibraryFragment>::@enum::A::@field::v1
  enums
    enum A
      reference: <testLibraryFragment>::@enum::A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const v2
          reference: <none>
          type: A
          firstFragment: <testLibraryFragment>::@enum::A::@field::v2
          getter: <none>
        synthetic static const values
          reference: <none>
          type: List<A>
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          getter: <none>
        static const v1
          reference: <none>
          type: A
          firstFragment: <testLibraryFragment>::@enum::A::@field::v1
          getter: <none>
      constructors
        const new
          reference: <none>
          parameters
            requiredPositional value
              reference: <none>
              type: int
          firstFragment: <testLibraryFragment>::@enum::A::@constructor::new
      getters
        synthetic static get v1
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@getter::v1
        synthetic static get v2
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@getter::v2
        synthetic static get values
          reference: <none>
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
      enclosingElement: <testLibrary>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              enclosingElement: <testLibraryFragment>::@enum::A
              type: A
              shouldUseTypeForInitializerInference: false
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@fieldAugmentation::v
            static const enumConstant v2 @29
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
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          typeParameters
            covariant T @36
              defaultType: dynamic
          augmentationTarget: <testLibraryFragment>::@enum::A
          fields
            augment static const enumConstant v @51
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@fieldAugmentation::v
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
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
          element: <testLibraryFragment>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            enumConstant v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <none>
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@fieldAugmentation::v
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            enumConstant v2 @29
              reference: <testLibraryFragment>::@enum::A::@field::v2
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::v2
            values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::values
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <none>
            get v2 @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v2
              element: <none>
            get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <none>
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A
          previousFragment: <testLibraryFragment>::@enum::A
          typeParameters
            T @36
              element: <none>
          fields
            enumConstant v @51
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@fieldAugmentation::v
              element: <none>
              previousFragment: <testLibraryFragment>::@enum::A::@field::v
  enums
    enum A
      reference: <testLibraryFragment>::@enum::A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const v2
          reference: <none>
          type: A
          firstFragment: <testLibraryFragment>::@enum::A::@field::v2
          getter: <none>
        synthetic static const values
          reference: <none>
          type: List<A>
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          getter: <none>
        static const v
          reference: <none>
          type: A
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          getter: <none>
      getters
        synthetic static get v
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@getter::v
        synthetic static get v2
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@getter::v2
        synthetic static get values
          reference: <none>
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
      enclosingElement: <testLibrary>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @26
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
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          constructors
            const named @49
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructor::named
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
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
          element: <testLibraryFragment>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            enumConstant v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::values
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <none>
            get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <none>
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A
          previousFragment: <testLibraryFragment>::@enum::A
          constructors
            const named @49
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructor::named
              element: <none>
              periodOffset: 48
              nameEnd: 54
  enums
    enum A
      reference: <testLibraryFragment>::@enum::A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const v
          reference: <none>
          type: A
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          getter: <none>
        synthetic static const values
          reference: <none>
          type: List<A>
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          getter: <none>
      constructors
        const named
          reference: <none>
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructor::named
      getters
        synthetic static get v
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@getter::v
        synthetic static get values
          reference: <none>
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
      enclosingElement: <testLibrary>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T1 @22
              defaultType: dynamic
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @30
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
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          typeParameters
            covariant T2 @36
              defaultType: dynamic
          augmentationTarget: <testLibraryFragment>::@enum::A
          constructors
            const named @53
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructor::named
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
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
          element: <testLibraryFragment>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          typeParameters
            T1 @22
              element: <none>
          fields
            enumConstant v @30
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::values
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <none>
            get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <none>
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A
          previousFragment: <testLibraryFragment>::@enum::A
          typeParameters
            T2 @36
              element: <none>
          constructors
            const named @53
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructor::named
              element: <none>
              periodOffset: 52
              nameEnd: 58
              parameters
                a @62
                  element: <none>
  enums
    enum A
      reference: <testLibraryFragment>::@enum::A
      typeParameters
        T1
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const v
          reference: <none>
          type: A<int>
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          getter: <none>
        synthetic static const values
          reference: <none>
          type: List<A<dynamic>>
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          getter: <none>
      constructors
        const named
          reference: <none>
          parameters
            requiredPositional a
              reference: <none>
              type: T2
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructor::named
      getters
        synthetic static get v
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@getter::v
        synthetic static get values
          reference: <none>
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
      enclosingElement: <testLibrary>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              enclosingElement: <testLibraryFragment>::@enum::A
              type: A
              shouldUseTypeForInitializerInference: false
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              enclosingElement: <testLibraryFragment>::@enum::A
              type: List<A>
          constructors
            const @37
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
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          constructors
            const named @49
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructor::named
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
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
          element: <testLibraryFragment>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            enumConstant v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::values
          constructors
            const new @37
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <none>
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <none>
            get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <none>
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A
          previousFragment: <testLibraryFragment>::@enum::A
          constructors
            const named @49
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructor::named
              element: <none>
              periodOffset: 48
              nameEnd: 54
  enums
    enum A
      reference: <testLibraryFragment>::@enum::A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const v
          reference: <none>
          type: A
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          getter: <none>
        synthetic static const values
          reference: <none>
          type: List<A>
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          getter: <none>
      constructors
        const new
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@constructor::new
        const named
          reference: <none>
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructor::named
      getters
        synthetic static get v
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@getter::v
        synthetic static get values
          reference: <none>
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
      enclosingElement: <testLibrary>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @26
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
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          constructors
            const @47
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructor::new
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
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
          element: <testLibraryFragment>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            enumConstant v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::values
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <none>
            get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <none>
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A
          previousFragment: <testLibraryFragment>::@enum::A
          constructors
            const new @47
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructor::new
              element: <none>
  enums
    enum A
      reference: <testLibraryFragment>::@enum::A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const v
          reference: <none>
          type: A
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          getter: <none>
        synthetic static const values
          reference: <none>
          type: List<A>
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          getter: <none>
      constructors
        const new
          reference: <none>
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructor::new
      getters
        synthetic static get v
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@getter::v
        synthetic static get values
          reference: <none>
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
      enclosingElement: <testLibrary>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              enclosingElement: <testLibraryFragment>::@enum::A
              type: A
              shouldUseTypeForInitializerInference: false
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              enclosingElement: <testLibraryFragment>::@enum::A
              type: List<A>
          constructors
            const named @39
              reference: <testLibraryFragment>::@enum::A::@constructor::named
              enclosingElement: <testLibraryFragment>::@enum::A
              periodOffset: 38
              nameEnd: 44
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
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          constructors
            const @47
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructor::new
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
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
          element: <testLibraryFragment>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            enumConstant v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::values
          constructors
            const named @39
              reference: <testLibraryFragment>::@enum::A::@constructor::named
              element: <none>
              periodOffset: 38
              nameEnd: 44
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <none>
            get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <none>
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A
          previousFragment: <testLibraryFragment>::@enum::A
          constructors
            const new @47
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructor::new
              element: <none>
  enums
    enum A
      reference: <testLibraryFragment>::@enum::A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const v
          reference: <none>
          type: A
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          getter: <none>
        synthetic static const values
          reference: <none>
          type: List<A>
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          getter: <none>
      constructors
        const named
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@constructor::named
        const new
          reference: <none>
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructor::new
      getters
        synthetic static get v
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@getter::v
        synthetic static get values
          reference: <none>
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
      enclosingElement: <testLibrary>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              enclosingElement: <testLibraryFragment>::@enum::A
              type: A
              shouldUseTypeForInitializerInference: false
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              enclosingElement: <testLibraryFragment>::@enum::A
              type: List<A>
            final f @44
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
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          constructors
            const named @49
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructor::named
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
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
          element: <testLibraryFragment>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            enumConstant v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::values
            f @44
              reference: <testLibraryFragment>::@enum::A::@field::f
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::f
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <none>
            get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <none>
            get f @-1
              reference: <testLibraryFragment>::@enum::A::@getter::f
              element: <none>
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A
          previousFragment: <testLibraryFragment>::@enum::A
          constructors
            const named @49
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructor::named
              element: <none>
              periodOffset: 48
              nameEnd: 54
              parameters
                this.f @60
                  element: <none>
  enums
    enum A
      reference: <testLibraryFragment>::@enum::A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const v
          reference: <none>
          type: A
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          getter: <none>
        synthetic static const values
          reference: <none>
          type: List<A>
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          getter: <none>
        final f
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@enum::A::@field::f
          getter: <none>
      constructors
        const named
          reference: <none>
          parameters
            requiredPositional final f
              reference: <none>
              type: int
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructor::named
      getters
        synthetic static get v
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@getter::v
        synthetic static get values
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@getter::values
        synthetic get f
          reference: <none>
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
      enclosingElement: <testLibrary>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              enclosingElement: <testLibraryFragment>::@enum::A
              type: A
              shouldUseTypeForInitializerInference: false
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              enclosingElement: <testLibraryFragment>::@enum::A
              type: List<A>
            final f @41
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
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          constructors
            const named @49
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructor::named
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              periodOffset: 48
              nameEnd: 54
              constantInitializers
                ConstructorFieldInitializer
                  fieldName: SimpleIdentifier
                    token: f @59
                    staticElement: <testLibraryFragment>::@enum::A::@field::f
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
          element: <testLibraryFragment>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            enumConstant v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::values
            f @41
              reference: <testLibraryFragment>::@enum::A::@field::f
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::f
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <none>
            get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <none>
            get f @-1
              reference: <testLibraryFragment>::@enum::A::@getter::f
              element: <none>
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A
          previousFragment: <testLibraryFragment>::@enum::A
          constructors
            const named @49
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructor::named
              element: <none>
              periodOffset: 48
              nameEnd: 54
              constantInitializers
                ConstructorFieldInitializer
                  fieldName: SimpleIdentifier
                    token: f @59
                    staticElement: <testLibraryFragment>::@enum::A::@field::f
                    staticType: null
                  equals: = @61
                  expression: IntegerLiteral
                    literal: 0 @63
                    staticType: int
  enums
    enum A
      reference: <testLibraryFragment>::@enum::A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const v
          reference: <none>
          type: A
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          getter: <none>
        synthetic static const values
          reference: <none>
          type: List<A>
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          getter: <none>
        final f
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@enum::A::@field::f
          getter: <none>
      constructors
        const named
          reference: <none>
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructor::named
      getters
        synthetic static get v
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@getter::v
        synthetic static get values
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@getter::values
        synthetic get f
          reference: <none>
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
      enclosingElement: <testLibrary>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @26
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
            final foo @41
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
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          fields
            augment final foo @59
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@fieldAugmentation::foo
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
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
          element: <testLibraryFragment>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            enumConstant v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::values
            foo @41
              reference: <testLibraryFragment>::@enum::A::@field::foo
              element: <none>
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@fieldAugmentation::foo
              getter2: <testLibraryFragment>::@enum::A::@getter::foo
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <none>
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <none>
            get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <none>
            get foo @-1
              reference: <testLibraryFragment>::@enum::A::@getter::foo
              element: <none>
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A
          previousFragment: <testLibraryFragment>::@enum::A
          fields
            foo @59
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@fieldAugmentation::foo
              element: <none>
              previousFragment: <testLibraryFragment>::@enum::A::@field::foo
  enums
    enum A
      reference: <testLibraryFragment>::@enum::A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const v
          reference: <none>
          type: A
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          getter: <none>
        synthetic static const values
          reference: <none>
          type: List<A>
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          getter: <none>
        final foo
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@enum::A::@field::foo
          getter: <none>
      constructors
        synthetic const new
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@constructor::new
      getters
        synthetic static get v
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@getter::v
        synthetic static get values
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@getter::values
        synthetic get foo
          reference: <none>
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
      enclosingElement: <testLibrary>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
        part_1
          uri: package:test/b.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/b.dart
      enums
        enum A @35
          reference: <testLibraryFragment>::@enum::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @41
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
            final foo @56
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
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          augmentation: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          fields
            augment final foo @59
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@fieldAugmentation::foo
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              type: int
              shouldUseTypeForInitializerInference: true
              id: field_3
              augmentationTarget: <testLibraryFragment>::@enum::A::@field::foo
              augmentation: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@fieldAugmentation::foo
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @34
          reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/b.dart
          augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            augment final foo @59
              reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@fieldAugmentation::foo
              enclosingElement: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
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
          element: <testLibraryFragment>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            enumConstant v @41
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::values
            foo @56
              reference: <testLibraryFragment>::@enum::A::@field::foo
              element: <none>
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@fieldAugmentation::foo
              getter2: <testLibraryFragment>::@enum::A::@getter::foo
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <none>
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <none>
            get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <none>
            get foo @-1
              reference: <testLibraryFragment>::@enum::A::@getter::foo
              element: <none>
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A
          previousFragment: <testLibraryFragment>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          fields
            foo @59
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@fieldAugmentation::foo
              element: <none>
              previousFragment: <testLibraryFragment>::@enum::A::@field::foo
              nextFragment: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@fieldAugmentation::foo
    <testLibrary>::@fragment::package:test/b.dart
      element: <testLibrary>
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A
          previousFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            foo @59
              reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@fieldAugmentation::foo
              element: <none>
              previousFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@fieldAugmentation::foo
  enums
    enum A
      reference: <testLibraryFragment>::@enum::A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const v
          reference: <none>
          type: A
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          getter: <none>
        synthetic static const values
          reference: <none>
          type: List<A>
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          getter: <none>
        final foo
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@enum::A::@field::foo
          getter: <none>
      constructors
        synthetic const new
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@constructor::new
      getters
        synthetic static get v
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@getter::v
        synthetic static get values
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@getter::values
        synthetic get foo
          reference: <none>
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
      enclosingElement: <testLibrary>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
        part_1
          uri: package:test/b.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/b.dart
      enums
        enum A @35
          reference: <testLibraryFragment>::@enum::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @41
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
            final foo @56
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
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          augmentation: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          accessors
            augment get foo @57
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getterAugmentation::foo
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              returnType: int
              id: getter_3
              variable: field_2
              augmentationTarget: <testLibraryFragment>::@enum::A::@getter::foo
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @34
          reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/b.dart
          augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            augment final foo @59
              reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@fieldAugmentation::foo
              enclosingElement: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
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
          element: <testLibraryFragment>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            enumConstant v @41
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::values
            foo @56
              reference: <testLibraryFragment>::@enum::A::@field::foo
              element: <none>
              nextFragment: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@fieldAugmentation::foo
              getter2: <testLibraryFragment>::@enum::A::@getter::foo
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <none>
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <none>
            get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <none>
            get foo @-1
              reference: <testLibraryFragment>::@enum::A::@getter::foo
              element: <none>
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getterAugmentation::foo
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A
          previousFragment: <testLibraryFragment>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          getters
            augment get foo @57
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getterAugmentation::foo
              element: <none>
              previousFragment: <testLibraryFragment>::@enum::A::@getter::foo
    <testLibrary>::@fragment::package:test/b.dart
      element: <testLibrary>
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A
          previousFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            foo @59
              reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@fieldAugmentation::foo
              element: <none>
              previousFragment: <testLibraryFragment>::@enum::A::@field::foo
  enums
    enum A
      reference: <testLibraryFragment>::@enum::A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const v
          reference: <none>
          type: A
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          getter: <none>
        synthetic static const values
          reference: <none>
          type: List<A>
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          getter: <none>
        final foo
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@enum::A::@field::foo
          getter: <none>
      constructors
        synthetic const new
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@constructor::new
      getters
        synthetic static get v
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@getter::v
        synthetic static get values
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@getter::values
        synthetic get foo
          reference: <none>
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
      enclosingElement: <testLibrary>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
        part_1
          uri: package:test/b.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/b.dart
      enums
        enum A @35
          reference: <testLibraryFragment>::@enum::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @41
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
            final foo @56
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
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          augmentation: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          accessors
            augment set foo= @53
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@setterAugmentation::foo
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              parameters
                requiredPositional _ @61
                  type: int
              returnType: void
              id: setter_0
              variable: <null>
              augmentationTargetAny: <testLibraryFragment>::@enum::A::@getter::foo
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @34
          reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/b.dart
          augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            augment final foo @59
              reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@fieldAugmentation::foo
              enclosingElement: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
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
          element: <testLibraryFragment>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            enumConstant v @41
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::values
            foo @56
              reference: <testLibraryFragment>::@enum::A::@field::foo
              element: <none>
              nextFragment: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@fieldAugmentation::foo
              getter2: <testLibraryFragment>::@enum::A::@getter::foo
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <none>
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <none>
            get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <none>
            get foo @-1
              reference: <testLibraryFragment>::@enum::A::@getter::foo
              element: <none>
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A
          previousFragment: <testLibraryFragment>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          setters
            augment set foo= @53
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@setterAugmentation::foo
              element: <none>
              parameters
                _ @61
                  element: <none>
    <testLibrary>::@fragment::package:test/b.dart
      element: <testLibrary>
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A
          previousFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            foo @59
              reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@fieldAugmentation::foo
              element: <none>
              previousFragment: <testLibraryFragment>::@enum::A::@field::foo
  enums
    enum A
      reference: <testLibraryFragment>::@enum::A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const v
          reference: <none>
          type: A
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          getter: <none>
        synthetic static const values
          reference: <none>
          type: List<A>
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          getter: <none>
        final foo
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@enum::A::@field::foo
          getter: <none>
      constructors
        synthetic const new
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@constructor::new
      getters
        synthetic static get v
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@getter::v
        synthetic static get values
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@getter::values
        synthetic get foo
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@getter::foo
      setters
        set foo=
          reference: <none>
          parameters
            requiredPositional _
              reference: <none>
              type: int
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@setterAugmentation::foo
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
      enclosingElement: <testLibrary>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @26
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
            final foo @41
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
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          fields
            augment final foo @62
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@fieldAugmentation::foo
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
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
          element: <testLibraryFragment>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            enumConstant v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::values
            foo @41
              reference: <testLibraryFragment>::@enum::A::@field::foo
              element: <none>
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@fieldAugmentation::foo
              getter2: <testLibraryFragment>::@enum::A::@getter::foo
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <none>
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <none>
            get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <none>
            get foo @-1
              reference: <testLibraryFragment>::@enum::A::@getter::foo
              element: <none>
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A
          previousFragment: <testLibraryFragment>::@enum::A
          fields
            foo @62
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@fieldAugmentation::foo
              element: <none>
              previousFragment: <testLibraryFragment>::@enum::A::@field::foo
  enums
    enum A
      reference: <testLibraryFragment>::@enum::A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const v
          reference: <none>
          type: A
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          getter: <none>
        synthetic static const values
          reference: <none>
          type: List<A>
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          getter: <none>
        final foo
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@enum::A::@field::foo
          getter: <none>
      constructors
        synthetic const new
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@constructor::new
      getters
        synthetic static get v
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@getter::v
        synthetic static get values
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@getter::values
        synthetic get foo
          reference: <none>
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
      enclosingElement: <testLibrary>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @26
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
            final foo @52
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
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          fields
            augment final foo @70
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
          element: <testLibraryFragment>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            enumConstant v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::values
            foo @52
              reference: <testLibraryFragment>::@enum::A::@field::foo
              element: <none>
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@fieldAugmentation::foo
              getter2: <testLibraryFragment>::@enum::A::@getter::foo
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <none>
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <none>
            get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <none>
            get foo @-1
              reference: <testLibraryFragment>::@enum::A::@getter::foo
              element: <none>
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A
          previousFragment: <testLibraryFragment>::@enum::A
          fields
            foo @70
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@fieldAugmentation::foo
              element: <none>
              previousFragment: <testLibraryFragment>::@enum::A::@field::foo
  enums
    enum A
      reference: <testLibraryFragment>::@enum::A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const v
          reference: <none>
          type: A
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          getter: <none>
        synthetic static const values
          reference: <none>
          type: List<A>
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          getter: <none>
        final foo
          reference: <none>
          type: int Function()
          firstFragment: <testLibraryFragment>::@enum::A::@field::foo
          getter: <none>
      constructors
        synthetic const new
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@constructor::new
      getters
        synthetic static get v
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@getter::v
        synthetic static get values
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@getter::values
        synthetic get foo
          reference: <none>
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
      enclosingElement: <testLibrary>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @26
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
            get foo @39
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
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          fields
            augment final foo @59
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@fieldAugmentation::foo
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
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
          element: <testLibraryFragment>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            enumConstant v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::values
            foo @-1
              reference: <testLibraryFragment>::@enum::A::@field::foo
              element: <none>
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@fieldAugmentation::foo
              getter2: <testLibraryFragment>::@enum::A::@getter::foo
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <none>
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <none>
            get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <none>
            get foo @39
              reference: <testLibraryFragment>::@enum::A::@getter::foo
              element: <none>
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A
          previousFragment: <testLibraryFragment>::@enum::A
          fields
            foo @59
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@fieldAugmentation::foo
              element: <none>
              previousFragment: <testLibraryFragment>::@enum::A::@field::foo
  enums
    enum A
      reference: <testLibraryFragment>::@enum::A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const v
          reference: <none>
          type: A
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          getter: <none>
        synthetic static const values
          reference: <none>
          type: List<A>
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          getter: <none>
        synthetic foo
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@enum::A::@field::foo
          getter: <none>
      constructors
        synthetic const new
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@constructor::new
      getters
        synthetic static get v
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@getter::v
        synthetic static get values
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@getter::values
        get foo
          reference: <none>
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
      enclosingElement: <testLibrary>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @26
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
            final foo1 @41
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
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          fields
            final foo2 @51
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
          element: <testLibraryFragment>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            enumConstant v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::values
            foo1 @41
              reference: <testLibraryFragment>::@enum::A::@field::foo1
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::foo1
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <none>
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <none>
            get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <none>
            get foo1 @-1
              reference: <testLibraryFragment>::@enum::A::@getter::foo1
              element: <none>
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A
          previousFragment: <testLibraryFragment>::@enum::A
          fields
            foo2 @51
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::foo2
              element: <none>
              getter2: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::foo2
          getters
            get foo2 @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::foo2
              element: <none>
  enums
    enum A
      reference: <testLibraryFragment>::@enum::A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const v
          reference: <none>
          type: A
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          getter: <none>
        synthetic static const values
          reference: <none>
          type: List<A>
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          getter: <none>
        final foo1
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@enum::A::@field::foo1
          getter: <none>
        final foo2
          reference: <none>
          type: int
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::foo2
          getter: <none>
      constructors
        synthetic const new
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@constructor::new
      getters
        synthetic static get v
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@getter::v
        synthetic static get values
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@getter::values
        synthetic get foo1
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@getter::foo1
        synthetic get foo2
          reference: <none>
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::foo2
''');
  }

  test_augmented_fields_add_generic() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment enum A<T2> {;
  final T2 foo2;
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
      enclosingElement: <testLibrary>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T1 @22
              defaultType: dynamic
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @30
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
            final foo1 @51
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
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          typeParameters
            covariant T2 @36
              defaultType: dynamic
          augmentationTarget: <testLibraryFragment>::@enum::A
          fields
            final foo2 @54
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
          element: <testLibraryFragment>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          typeParameters
            T1 @22
              element: <none>
          fields
            enumConstant v @30
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::values
            foo1 @51
              reference: <testLibraryFragment>::@enum::A::@field::foo1
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::foo1
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <none>
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <none>
            get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <none>
            get foo1 @-1
              reference: <testLibraryFragment>::@enum::A::@getter::foo1
              element: <none>
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A
          previousFragment: <testLibraryFragment>::@enum::A
          typeParameters
            T2 @36
              element: <none>
          fields
            foo2 @54
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::foo2
              element: <none>
              getter2: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::foo2
          getters
            get foo2 @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::foo2
              element: <none>
  enums
    enum A
      reference: <testLibraryFragment>::@enum::A
      typeParameters
        T1
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const v
          reference: <none>
          type: A<int>
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          getter: <none>
        synthetic static const values
          reference: <none>
          type: List<A<dynamic>>
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          getter: <none>
        final foo1
          reference: <none>
          type: T1
          firstFragment: <testLibraryFragment>::@enum::A::@field::foo1
          getter: <none>
        final foo2
          reference: <none>
          type: T2
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::foo2
          getter: <none>
      constructors
        synthetic const new
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@constructor::new
      getters
        synthetic static get v
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@getter::v
        synthetic static get values
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@getter::values
        synthetic get foo1
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@getter::foo1
        synthetic get foo2
          reference: <none>
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
      enclosingElement: <testLibrary>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              enclosingElement: <testLibraryFragment>::@enum::A
              type: A
              shouldUseTypeForInitializerInference: false
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              enclosingElement: <testLibraryFragment>::@enum::A
              type: List<A>
          constructors
            const @40
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@enum::A
              parameters
                requiredPositional final this.foo @47
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
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          fields
            final foo @51
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::foo
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              type: int
          accessors
            synthetic get foo @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::foo
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
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
          element: <testLibraryFragment>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            enumConstant v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::values
          constructors
            const new @40
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <none>
              parameters
                this.foo @47
                  element: <none>
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <none>
            get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <none>
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A
          previousFragment: <testLibraryFragment>::@enum::A
          fields
            foo @51
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::foo
              element: <none>
              getter2: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::foo
          getters
            get foo @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::foo
              element: <none>
  enums
    enum A
      reference: <testLibraryFragment>::@enum::A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const v
          reference: <none>
          type: A
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          getter: <none>
        synthetic static const values
          reference: <none>
          type: List<A>
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          getter: <none>
        final foo
          reference: <none>
          type: int
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::foo
          getter: <none>
      constructors
        const new
          reference: <none>
          parameters
            requiredPositional final foo
              reference: <none>
              type: int
          firstFragment: <testLibraryFragment>::@enum::A::@constructor::new
      getters
        synthetic static get v
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@getter::v
        synthetic static get values
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@getter::values
        synthetic get foo
          reference: <none>
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
      enclosingElement: <testLibrary>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              enclosingElement: <testLibraryFragment>::@enum::A
              type: A
              shouldUseTypeForInitializerInference: false
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              enclosingElement: <testLibraryFragment>::@enum::A
              type: List<A>
          constructors
            const @37
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@enum::A
              constantInitializers
                ConstructorFieldInitializer
                  fieldName: SimpleIdentifier
                    token: foo @43
                    staticElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::foo
                    staticType: null
                  equals: = @47
                  expression: IntegerLiteral
                    literal: 0 @49
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
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          fields
            final foo @51
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::foo
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              type: int
          accessors
            synthetic get foo @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::foo
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
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
          element: <testLibraryFragment>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            enumConstant v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::values
          constructors
            const new @37
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <none>
              constantInitializers
                ConstructorFieldInitializer
                  fieldName: SimpleIdentifier
                    token: foo @43
                    staticElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::foo
                    staticType: null
                  equals: = @47
                  expression: IntegerLiteral
                    literal: 0 @49
                    staticType: int
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <none>
            get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <none>
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A
          previousFragment: <testLibraryFragment>::@enum::A
          fields
            foo @51
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::foo
              element: <none>
              getter2: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::foo
          getters
            get foo @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::foo
              element: <none>
  enums
    enum A
      reference: <testLibraryFragment>::@enum::A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const v
          reference: <none>
          type: A
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          getter: <none>
        synthetic static const values
          reference: <none>
          type: List<A>
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          getter: <none>
        final foo
          reference: <none>
          type: int
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::foo
          getter: <none>
      constructors
        const new
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@constructor::new
      getters
        synthetic static get v
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@getter::v
        synthetic static get values
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@getter::values
        synthetic get foo
          reference: <none>
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
      enclosingElement: <testLibrary>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @26
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
            get foo1 @39
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
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @34
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
            get foo2 @49
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::foo2
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
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
          element: <testLibraryFragment>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            enumConstant v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::values
            foo1 @-1
              reference: <testLibraryFragment>::@enum::A::@field::foo1
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::foo1
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <none>
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <none>
            get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <none>
            get foo1 @39
              reference: <testLibraryFragment>::@enum::A::@getter::foo1
              element: <none>
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A
          previousFragment: <testLibraryFragment>::@enum::A
          fields
            foo2 @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::foo2
              element: <none>
              getter2: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::foo2
          getters
            get foo2 @49
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::foo2
              element: <none>
  enums
    enum A
      reference: <testLibraryFragment>::@enum::A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const v
          reference: <none>
          type: A
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          getter: <none>
        synthetic static const values
          reference: <none>
          type: List<A>
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          getter: <none>
        synthetic foo1
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@enum::A::@field::foo1
          getter: <none>
        synthetic foo2
          reference: <none>
          type: int
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::foo2
          getter: <none>
      constructors
        synthetic const new
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@constructor::new
      getters
        synthetic static get v
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@getter::v
        synthetic static get values
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@getter::values
        get foo1
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@getter::foo1
        get foo2
          reference: <none>
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::foo2
''');
  }

  test_augmented_getters_add_generic() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment enum A<T2> {;
  T2 get foo2;
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
      enclosingElement: <testLibrary>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T1 @22
              defaultType: dynamic
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @30
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
            abstract get foo1 @49
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
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          typeParameters
            covariant T2 @36
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
            abstract get foo2 @52
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::foo2
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              returnType: T2
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
          element: <testLibraryFragment>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          typeParameters
            T1 @22
              element: <none>
          fields
            enumConstant v @30
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::values
            foo1 @-1
              reference: <testLibraryFragment>::@enum::A::@field::foo1
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::foo1
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <none>
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <none>
            get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <none>
            get foo1 @49
              reference: <testLibraryFragment>::@enum::A::@getter::foo1
              element: <none>
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A
          previousFragment: <testLibraryFragment>::@enum::A
          typeParameters
            T2 @36
              element: <none>
          fields
            foo2 @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::foo2
              element: <none>
              getter2: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::foo2
          getters
            get foo2 @52
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getter::foo2
              element: <none>
  enums
    enum A
      reference: <testLibraryFragment>::@enum::A
      typeParameters
        T1
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const v
          reference: <none>
          type: A<int>
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          getter: <none>
        synthetic static const values
          reference: <none>
          type: List<A<dynamic>>
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          getter: <none>
        synthetic foo1
          reference: <none>
          type: T1
          firstFragment: <testLibraryFragment>::@enum::A::@field::foo1
          getter: <none>
        synthetic foo2
          reference: <none>
          type: T2
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::foo2
          getter: <none>
      constructors
        synthetic const new
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@constructor::new
      getters
        synthetic static get v
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@getter::v
        synthetic static get values
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@getter::values
        abstract get foo1
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@getter::foo1
        abstract get foo2
          reference: <none>
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
      enclosingElement: <testLibrary>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @26
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
            final foo @41
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
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          accessors
            augment get foo @57
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getterAugmentation::foo
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
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
          element: <testLibraryFragment>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            enumConstant v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::values
            foo @41
              reference: <testLibraryFragment>::@enum::A::@field::foo
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::foo
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <none>
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <none>
            get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <none>
            get foo @-1
              reference: <testLibraryFragment>::@enum::A::@getter::foo
              element: <none>
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getterAugmentation::foo
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A
          previousFragment: <testLibraryFragment>::@enum::A
          getters
            augment get foo @57
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getterAugmentation::foo
              element: <none>
              previousFragment: <testLibraryFragment>::@enum::A::@getter::foo
  enums
    enum A
      reference: <testLibraryFragment>::@enum::A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const v
          reference: <none>
          type: A
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          getter: <none>
        synthetic static const values
          reference: <none>
          type: List<A>
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          getter: <none>
        final foo
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@enum::A::@field::foo
          getter: <none>
      constructors
        synthetic const new
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@constructor::new
      getters
        synthetic static get v
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@getter::v
        synthetic static get values
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@getter::values
        synthetic get foo
          reference: <none>
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
      enclosingElement: <testLibrary>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
        part_1
          uri: package:test/b.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/b.dart
      enums
        enum A @35
          reference: <testLibraryFragment>::@enum::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @41
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
            final foo @56
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
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          augmentation: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          accessors
            augment get foo @57
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getterAugmentation::foo
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              returnType: int
              id: getter_3
              variable: field_2
              augmentationTarget: <testLibraryFragment>::@enum::A::@getter::foo
              augmentation: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@getterAugmentation::foo
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @34
          reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/b.dart
          augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          accessors
            augment get foo @57
              reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@getterAugmentation::foo
              enclosingElement: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
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
          element: <testLibraryFragment>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            enumConstant v @41
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::values
            foo @56
              reference: <testLibraryFragment>::@enum::A::@field::foo
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::foo
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <none>
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <none>
            get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <none>
            get foo @-1
              reference: <testLibraryFragment>::@enum::A::@getter::foo
              element: <none>
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getterAugmentation::foo
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A
          previousFragment: <testLibraryFragment>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          getters
            augment get foo @57
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getterAugmentation::foo
              element: <none>
              previousFragment: <testLibraryFragment>::@enum::A::@getter::foo
              nextFragment: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@getterAugmentation::foo
    <testLibrary>::@fragment::package:test/b.dart
      element: <testLibrary>
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A
          previousFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          getters
            augment get foo @57
              reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@getterAugmentation::foo
              element: <none>
              previousFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getterAugmentation::foo
  enums
    enum A
      reference: <testLibraryFragment>::@enum::A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const v
          reference: <none>
          type: A
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          getter: <none>
        synthetic static const values
          reference: <none>
          type: List<A>
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          getter: <none>
        final foo
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@enum::A::@field::foo
          getter: <none>
      constructors
        synthetic const new
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@constructor::new
      getters
        synthetic static get v
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@getter::v
        synthetic static get values
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@getter::values
        synthetic get foo
          reference: <none>
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
      enclosingElement: <testLibrary>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @26
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
            get foo1 @39
              reference: <testLibraryFragment>::@enum::A::@getter::foo1
              enclosingElement: <testLibraryFragment>::@enum::A
              returnType: int
              id: getter_2
              variable: field_2
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getterAugmentation::foo1
            get foo2 @60
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
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          accessors
            augment get foo1 @57
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getterAugmentation::foo1
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
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
          element: <testLibraryFragment>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            enumConstant v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::values
            foo1 @-1
              reference: <testLibraryFragment>::@enum::A::@field::foo1
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::foo1
            foo2 @-1
              reference: <testLibraryFragment>::@enum::A::@field::foo2
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::foo2
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <none>
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <none>
            get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <none>
            get foo1 @39
              reference: <testLibraryFragment>::@enum::A::@getter::foo1
              element: <none>
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getterAugmentation::foo1
            get foo2 @60
              reference: <testLibraryFragment>::@enum::A::@getter::foo2
              element: <none>
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A
          previousFragment: <testLibraryFragment>::@enum::A
          getters
            augment get foo1 @57
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getterAugmentation::foo1
              element: <none>
              previousFragment: <testLibraryFragment>::@enum::A::@getter::foo1
  enums
    enum A
      reference: <testLibraryFragment>::@enum::A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const v
          reference: <none>
          type: A
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          getter: <none>
        synthetic static const values
          reference: <none>
          type: List<A>
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          getter: <none>
        synthetic foo1
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@enum::A::@field::foo1
          getter: <none>
        synthetic foo2
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@enum::A::@field::foo2
          getter: <none>
      constructors
        synthetic const new
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@constructor::new
      getters
        synthetic static get v
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@getter::v
        synthetic static get values
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@getter::values
        get foo2
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@getter::foo2
        get foo1
          reference: <none>
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
      enclosingElement: <testLibrary>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @26
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
            get foo @39
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
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          accessors
            augment get foo @57
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getterAugmentation::foo::@def::0
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              returnType: int
              id: getter_3
              variable: field_2
              augmentationTarget: <testLibraryFragment>::@enum::A::@getter::foo
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getterAugmentation::foo::@def::1
            augment get foo @85
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getterAugmentation::foo::@def::1
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
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
          element: <testLibraryFragment>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            enumConstant v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::values
            foo @-1
              reference: <testLibraryFragment>::@enum::A::@field::foo
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::foo
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <none>
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <none>
            get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <none>
            get foo @39
              reference: <testLibraryFragment>::@enum::A::@getter::foo
              element: <none>
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getterAugmentation::foo::@def::0
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A
          previousFragment: <testLibraryFragment>::@enum::A
          getters
            augment get foo @57
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getterAugmentation::foo::@def::0
              element: <none>
              previousFragment: <testLibraryFragment>::@enum::A::@getter::foo
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getterAugmentation::foo::@def::1
            augment get foo @85
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getterAugmentation::foo::@def::1
              element: <none>
              previousFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getterAugmentation::foo::@def::0
  enums
    enum A
      reference: <testLibraryFragment>::@enum::A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const v
          reference: <none>
          type: A
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          getter: <none>
        synthetic static const values
          reference: <none>
          type: List<A>
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          getter: <none>
        synthetic foo
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@enum::A::@field::foo
          getter: <none>
      constructors
        synthetic const new
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@constructor::new
      getters
        synthetic static get v
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@getter::v
        synthetic static get values
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@getter::values
        get foo
          reference: <none>
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
      enclosingElement: <testLibrary>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
        part_1
          uri: package:test/b.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/b.dart
      enums
        enum A @35
          reference: <testLibraryFragment>::@enum::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @41
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
            get foo @54
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
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          augmentation: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          accessors
            augment get foo @57
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getterAugmentation::foo
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              returnType: int
              id: getter_3
              variable: field_2
              augmentationTarget: <testLibraryFragment>::@enum::A::@getter::foo
              augmentation: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@getterAugmentation::foo
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @34
          reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/b.dart
          augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          accessors
            augment get foo @57
              reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@getterAugmentation::foo
              enclosingElement: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
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
          element: <testLibraryFragment>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            enumConstant v @41
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::values
            foo @-1
              reference: <testLibraryFragment>::@enum::A::@field::foo
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::foo
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <none>
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <none>
            get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <none>
            get foo @54
              reference: <testLibraryFragment>::@enum::A::@getter::foo
              element: <none>
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getterAugmentation::foo
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A
          previousFragment: <testLibraryFragment>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          getters
            augment get foo @57
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getterAugmentation::foo
              element: <none>
              previousFragment: <testLibraryFragment>::@enum::A::@getter::foo
              nextFragment: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@getterAugmentation::foo
    <testLibrary>::@fragment::package:test/b.dart
      element: <testLibrary>
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A
          previousFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          getters
            augment get foo @57
              reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@getterAugmentation::foo
              element: <none>
              previousFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getterAugmentation::foo
  enums
    enum A
      reference: <testLibraryFragment>::@enum::A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const v
          reference: <none>
          type: A
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          getter: <none>
        synthetic static const values
          reference: <none>
          type: List<A>
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          getter: <none>
        synthetic foo
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@enum::A::@field::foo
          getter: <none>
      constructors
        synthetic const new
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@constructor::new
      getters
        synthetic static get v
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@getter::v
        synthetic static get values
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@getter::values
        get foo
          reference: <none>
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
      enclosingElement: <testLibrary>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @26
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
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          accessors
            augment get foo @57
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getterAugmentation::foo
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
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
          element: <testLibraryFragment>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            enumConstant v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::values
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <none>
            get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <none>
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A
          previousFragment: <testLibraryFragment>::@enum::A
          getters
            augment get foo @57
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@getterAugmentation::foo
              element: <none>
  enums
    enum A
      reference: <testLibraryFragment>::@enum::A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const v
          reference: <none>
          type: A
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          getter: <none>
        synthetic static const values
          reference: <none>
          type: List<A>
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          getter: <none>
      getters
        synthetic static get v
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@getter::v
        synthetic static get values
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@getter::values
        get foo
          reference: <none>
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
      enclosingElement: <testLibrary>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      classes
        class I1 @50
          reference: <testLibraryFragment>::@class::I1
          enclosingElement: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::I1::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::I1
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          interfaces
            I1
          fields
            static const enumConstant v @40
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
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      classes
        class I2 @59
          reference: <testLibrary>::@fragment::package:test/a.dart::@class::I2
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          constructors
            synthetic @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@class::I2::@constructor::new
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@class::I2
      enums
        augment enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
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
          element: <testLibraryFragment>::@class::I1
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::I1::@constructor::new
              element: <none>
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          element: <testLibraryFragment>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            enumConstant v @40
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <none>
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <none>
            get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <none>
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      classes
        class I2 @59
          reference: <testLibrary>::@fragment::package:test/a.dart::@class::I2
          element: <testLibrary>::@fragment::package:test/a.dart::@class::I2
          constructors
            synthetic new @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@class::I2::@constructor::new
              element: <none>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A
          previousFragment: <testLibraryFragment>::@enum::A
  classes
    class I1
      reference: <testLibraryFragment>::@class::I1
      firstFragment: <testLibraryFragment>::@class::I1
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::I1::@constructor::new
    class I2
      reference: <testLibrary>::@fragment::package:test/a.dart::@class::I2
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@class::I2
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@class::I2::@constructor::new
  enums
    enum A
      reference: <testLibraryFragment>::@enum::A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const v
          reference: <none>
          type: A
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          getter: <none>
        synthetic static const values
          reference: <none>
          type: List<A>
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          getter: <none>
      constructors
        synthetic const new
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@constructor::new
      getters
        synthetic static get v
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@getter::v
        synthetic static get values
          reference: <none>
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
      enclosingElement: <testLibrary>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      classes
        class I1 @50
          reference: <testLibraryFragment>::@class::I1
          enclosingElement: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::I1::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::I1
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          interfaces
            I1
          fields
            static const enumConstant v @40
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
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      parts
        part_1
          uri: package:test/b.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          unit: <testLibrary>::@fragment::package:test/b.dart
      classes
        class I2 @74
          reference: <testLibrary>::@fragment::package:test/a.dart::@class::I2
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          constructors
            synthetic @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@class::I2::@constructor::new
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@class::I2
      enums
        augment enum A @49
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          augmentation: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          interfaces
            I2
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
      classes
        class I3 @56
          reference: <testLibrary>::@fragment::package:test/b.dart::@class::I3
          enclosingElement: <testLibrary>::@fragment::package:test/b.dart
          constructors
            synthetic @-1
              reference: <testLibrary>::@fragment::package:test/b.dart::@class::I3::@constructor::new
              enclosingElement: <testLibrary>::@fragment::package:test/b.dart::@class::I3
      enums
        augment enum A @31
          reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/b.dart
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
          element: <testLibraryFragment>::@class::I1
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::I1::@constructor::new
              element: <none>
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          element: <testLibraryFragment>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            enumConstant v @40
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <none>
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <none>
            get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <none>
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      classes
        class I2 @74
          reference: <testLibrary>::@fragment::package:test/a.dart::@class::I2
          element: <testLibrary>::@fragment::package:test/a.dart::@class::I2
          constructors
            synthetic new @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@class::I2::@constructor::new
              element: <none>
      enums
        enum A @49
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A
          previousFragment: <testLibraryFragment>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
    <testLibrary>::@fragment::package:test/b.dart
      element: <testLibrary>
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      classes
        class I3 @56
          reference: <testLibrary>::@fragment::package:test/b.dart::@class::I3
          element: <testLibrary>::@fragment::package:test/b.dart::@class::I3
          constructors
            synthetic new @-1
              reference: <testLibrary>::@fragment::package:test/b.dart::@class::I3::@constructor::new
              element: <none>
      enums
        enum A @31
          reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A
          previousFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
  classes
    class I1
      reference: <testLibraryFragment>::@class::I1
      firstFragment: <testLibraryFragment>::@class::I1
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::I1::@constructor::new
    class I2
      reference: <testLibrary>::@fragment::package:test/a.dart::@class::I2
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@class::I2
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@class::I2::@constructor::new
    class I3
      reference: <testLibrary>::@fragment::package:test/b.dart::@class::I3
      firstFragment: <testLibrary>::@fragment::package:test/b.dart::@class::I3
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibrary>::@fragment::package:test/b.dart::@class::I3::@constructor::new
  enums
    enum A
      reference: <testLibraryFragment>::@enum::A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const v
          reference: <none>
          type: A
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          getter: <none>
        synthetic static const values
          reference: <none>
          type: List<A>
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          getter: <none>
      constructors
        synthetic const new
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@constructor::new
      getters
        synthetic static get v
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@getter::v
        synthetic static get values
          reference: <none>
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
      enclosingElement: <testLibrary>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      classes
        class I1 @60
          reference: <testLibraryFragment>::@class::I1
          enclosingElement: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::I1::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::I1
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          enclosingElement: <testLibraryFragment>
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
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      classes
        class I2 @67
          reference: <testLibrary>::@fragment::package:test/a.dart::@class::I2
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          typeParameters
            covariant E @70
              defaultType: dynamic
          constructors
            synthetic @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@class::I2::@constructor::new
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@class::I2
      enums
        augment enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
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
          element: <testLibraryFragment>::@class::I1
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::I1::@constructor::new
              element: <none>
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          element: <testLibraryFragment>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          typeParameters
            T @22
              element: <none>
          fields
            enumConstant v @43
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <none>
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <none>
            get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <none>
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      classes
        class I2 @67
          reference: <testLibrary>::@fragment::package:test/a.dart::@class::I2
          element: <testLibrary>::@fragment::package:test/a.dart::@class::I2
          typeParameters
            E @70
              element: <none>
          constructors
            synthetic new @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@class::I2::@constructor::new
              element: <none>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A
          previousFragment: <testLibraryFragment>::@enum::A
          typeParameters
            T2 @36
              element: <none>
  classes
    class I1
      reference: <testLibraryFragment>::@class::I1
      firstFragment: <testLibraryFragment>::@class::I1
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::I1::@constructor::new
    class I2
      reference: <testLibrary>::@fragment::package:test/a.dart::@class::I2
      typeParameters
        E
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@class::I2
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@class::I2::@constructor::new
  enums
    enum A
      reference: <testLibraryFragment>::@enum::A
      typeParameters
        T
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const v
          reference: <none>
          type: A<int>
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          getter: <none>
        synthetic static const values
          reference: <none>
          type: List<A<dynamic>>
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          getter: <none>
      constructors
        synthetic const new
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@constructor::new
      getters
        synthetic static get v
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@getter::v
        synthetic static get values
          reference: <none>
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
      enclosingElement: <testLibrary>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      classes
        class I1 @53
          reference: <testLibraryFragment>::@class::I1
          enclosingElement: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::I1::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::I1
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          enclosingElement: <testLibraryFragment>
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
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      classes
        class I2 @71
          reference: <testLibrary>::@fragment::package:test/a.dart::@class::I2
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          typeParameters
            covariant E @74
              defaultType: dynamic
          constructors
            synthetic @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@class::I2::@constructor::new
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@class::I2
      enums
        augment enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
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
          element: <testLibraryFragment>::@class::I1
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::I1::@constructor::new
              element: <none>
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          element: <testLibraryFragment>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          typeParameters
            T @22
              element: <none>
          fields
            enumConstant v @43
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <none>
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <none>
            get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <none>
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      classes
        class I2 @71
          reference: <testLibrary>::@fragment::package:test/a.dart::@class::I2
          element: <testLibrary>::@fragment::package:test/a.dart::@class::I2
          typeParameters
            E @74
              element: <none>
          constructors
            synthetic new @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@class::I2::@constructor::new
              element: <none>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A
          previousFragment: <testLibraryFragment>::@enum::A
          typeParameters
            T2 @36
              element: <none>
            T3 @40
              element: <none>
  classes
    class I1
      reference: <testLibraryFragment>::@class::I1
      firstFragment: <testLibraryFragment>::@class::I1
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::I1::@constructor::new
    class I2
      reference: <testLibrary>::@fragment::package:test/a.dart::@class::I2
      typeParameters
        E
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@class::I2
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@class::I2::@constructor::new
  enums
    enum A
      reference: <testLibraryFragment>::@enum::A
      typeParameters
        T
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const v
          reference: <none>
          type: A<dynamic>
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          getter: <none>
        synthetic static const values
          reference: <none>
          type: List<A<dynamic>>
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          getter: <none>
      constructors
        synthetic const new
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@constructor::new
      getters
        synthetic static get v
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@getter::v
        synthetic static get values
          reference: <none>
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
      enclosingElement: <testLibrary>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @26
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
            foo @36
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
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          methods
            bar @46
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@method::bar
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
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
          element: <testLibraryFragment>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            enumConstant v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <none>
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <none>
            get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <none>
          methods
            foo @36
              reference: <testLibraryFragment>::@enum::A::@method::foo
              element: <none>
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A
          previousFragment: <testLibraryFragment>::@enum::A
          methods
            bar @46
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@method::bar
              element: <none>
  enums
    enum A
      reference: <testLibraryFragment>::@enum::A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const v
          reference: <none>
          type: A
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          getter: <none>
        synthetic static const values
          reference: <none>
          type: List<A>
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          getter: <none>
      constructors
        synthetic const new
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@constructor::new
      getters
        synthetic static get v
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@getter::v
        synthetic static get values
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@getter::values
      methods
        foo
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@method::foo
        bar
          reference: <none>
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
      enclosingElement: <testLibrary>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @26
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
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          methods
            foo @46
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@method::foo
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
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
          element: <testLibraryFragment>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            enumConstant v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <none>
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <none>
            get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <none>
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A
          previousFragment: <testLibraryFragment>::@enum::A
          methods
            foo @46
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@method::foo
              element: <none>
              parameters
                default x @55
                  element: <none>
  enums
    enum A
      reference: <testLibraryFragment>::@enum::A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const v
          reference: <none>
          type: A
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          getter: <none>
        synthetic static const values
          reference: <none>
          type: List<A>
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          getter: <none>
      constructors
        synthetic const new
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@constructor::new
      getters
        synthetic static get v
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@getter::v
        synthetic static get values
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@getter::values
      methods
        foo
          reference: <none>
          parameters
            optionalPositional x
              reference: <none>
              type: int
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@method::foo
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
      enclosingElement: <testLibrary>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @26
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
            foo1 @36
              reference: <testLibraryFragment>::@enum::A::@method::foo1
              enclosingElement: <testLibraryFragment>::@enum::A
              returnType: void
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@methodAugmentation::foo1
            foo2 @53
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
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          methods
            augment foo1 @54
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@methodAugmentation::foo1
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
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
          element: <testLibraryFragment>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            enumConstant v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <none>
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <none>
            get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <none>
          methods
            foo1 @36
              reference: <testLibraryFragment>::@enum::A::@method::foo1
              element: <none>
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@methodAugmentation::foo1
            foo2 @53
              reference: <testLibraryFragment>::@enum::A::@method::foo2
              element: <none>
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A
          previousFragment: <testLibraryFragment>::@enum::A
          methods
            augment foo1 @54
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@methodAugmentation::foo1
              element: <none>
              previousFragment: <testLibraryFragment>::@enum::A::@method::foo1
  enums
    enum A
      reference: <testLibraryFragment>::@enum::A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const v
          reference: <none>
          type: A
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          getter: <none>
        synthetic static const values
          reference: <none>
          type: List<A>
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          getter: <none>
      constructors
        synthetic const new
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@constructor::new
      getters
        synthetic static get v
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@getter::v
        synthetic static get values
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@getter::values
      methods
        foo2
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@method::foo2
        foo1
          reference: <none>
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
      enclosingElement: <testLibrary>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @26
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
            foo @36
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
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          methods
            augment foo @54
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@methodAugmentation::foo::@def::0
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              returnType: void
              augmentationTarget: <testLibraryFragment>::@enum::A::@method::foo
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@methodAugmentation::foo::@def::1
            augment foo @78
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@methodAugmentation::foo::@def::1
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
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
          element: <testLibraryFragment>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            enumConstant v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <none>
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <none>
            get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <none>
          methods
            foo @36
              reference: <testLibraryFragment>::@enum::A::@method::foo
              element: <none>
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@methodAugmentation::foo::@def::0
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A
          previousFragment: <testLibraryFragment>::@enum::A
          methods
            augment foo @54
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@methodAugmentation::foo::@def::0
              element: <none>
              previousFragment: <testLibraryFragment>::@enum::A::@method::foo
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@methodAugmentation::foo::@def::1
            augment foo @78
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@methodAugmentation::foo::@def::1
              element: <none>
              previousFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@methodAugmentation::foo::@def::0
  enums
    enum A
      reference: <testLibraryFragment>::@enum::A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const v
          reference: <none>
          type: A
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          getter: <none>
        synthetic static const values
          reference: <none>
          type: List<A>
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          getter: <none>
      constructors
        synthetic const new
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@constructor::new
      getters
        synthetic static get v
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@getter::v
        synthetic static get values
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@getter::values
      methods
        foo
          reference: <none>
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
      enclosingElement: <testLibrary>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::0
          supertype: Enum
          fields
            static const enumConstant v @26
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
            foo @36
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
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::0
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::1
          methods
            augment foo @54
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::0::@methodAugmentation::foo
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::0
              returnType: void
              augmentationTarget: <testLibraryFragment>::@enum::A::@method::foo
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::1::@methodAugmentation::foo
        augment enum A @78
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::1
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::0
          methods
            augment foo @98
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::1::@methodAugmentation::foo
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::1
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
          element: <testLibraryFragment>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::0
          fields
            enumConstant v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <none>
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <none>
            get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <none>
          methods
            foo @36
              reference: <testLibraryFragment>::@enum::A::@method::foo
              element: <none>
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::0::@methodAugmentation::foo
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::0
          element: <testLibraryFragment>::@enum::A
          previousFragment: <testLibraryFragment>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::1
          methods
            augment foo @54
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::0::@methodAugmentation::foo
              element: <none>
              previousFragment: <testLibraryFragment>::@enum::A::@method::foo
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::1::@methodAugmentation::foo
        enum A @78
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::1
          element: <testLibraryFragment>::@enum::A
          previousFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::0
          methods
            augment foo @98
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::1::@methodAugmentation::foo
              element: <none>
              previousFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@def::0::@methodAugmentation::foo
  enums
    enum A
      reference: <testLibraryFragment>::@enum::A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const v
          reference: <none>
          type: A
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          getter: <none>
        synthetic static const values
          reference: <none>
          type: List<A>
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          getter: <none>
      constructors
        synthetic const new
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@constructor::new
      getters
        synthetic static get v
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@getter::v
        synthetic static get values
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@getter::values
      methods
        foo
          reference: <none>
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
      enclosingElement: <testLibrary>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @26
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
            foo @36
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
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      parts
        part_1
          uri: package:test/b.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
          unit: <testLibrary>::@fragment::package:test/b.dart
      enums
        augment enum A @49
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          augmentation: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          methods
            augment foo @69
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@methodAugmentation::foo
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              returnType: void
              augmentationTarget: <testLibraryFragment>::@enum::A::@method::foo
              augmentation: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@methodAugmentation::foo
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibrary>::@fragment::package:test/a.dart
      enums
        augment enum A @31
          reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/b.dart
          augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          methods
            augment foo @51
              reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@methodAugmentation::foo
              enclosingElement: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
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
          element: <testLibraryFragment>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            enumConstant v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <none>
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <none>
            get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <none>
          methods
            foo @36
              reference: <testLibraryFragment>::@enum::A::@method::foo
              element: <none>
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@methodAugmentation::foo
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      enums
        enum A @49
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A
          previousFragment: <testLibraryFragment>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          methods
            augment foo @69
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@methodAugmentation::foo
              element: <none>
              previousFragment: <testLibraryFragment>::@enum::A::@method::foo
              nextFragment: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@methodAugmentation::foo
    <testLibrary>::@fragment::package:test/b.dart
      element: <testLibrary>
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @31
          reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A
          previousFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          methods
            augment foo @51
              reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@methodAugmentation::foo
              element: <none>
              previousFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@methodAugmentation::foo
  enums
    enum A
      reference: <testLibraryFragment>::@enum::A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const v
          reference: <none>
          type: A
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          getter: <none>
        synthetic static const values
          reference: <none>
          type: List<A>
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          getter: <none>
      constructors
        synthetic const new
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@constructor::new
      getters
        synthetic static get v
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@getter::v
        synthetic static get values
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@getter::values
      methods
        foo
          reference: <none>
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
      enclosingElement: <testLibrary>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T @22
              defaultType: dynamic
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @29
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
            foo @43
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
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          typeParameters
            covariant T2 @36
              defaultType: dynamic
          augmentationTarget: <testLibraryFragment>::@enum::A
          methods
            bar @48
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@method::bar
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
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
          element: <testLibraryFragment>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          typeParameters
            T @22
              element: <none>
          fields
            enumConstant v @29
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <none>
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <none>
            get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <none>
          methods
            foo @43
              reference: <testLibraryFragment>::@enum::A::@method::foo
              element: <none>
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A
          previousFragment: <testLibraryFragment>::@enum::A
          typeParameters
            T2 @36
              element: <none>
          methods
            bar @48
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@method::bar
              element: <none>
  enums
    enum A
      reference: <testLibraryFragment>::@enum::A
      typeParameters
        T
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const v
          reference: <none>
          type: A<int>
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          getter: <none>
        synthetic static const values
          reference: <none>
          type: List<A<dynamic>>
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          getter: <none>
      constructors
        synthetic const new
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@constructor::new
      getters
        synthetic static get v
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@getter::v
        synthetic static get values
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@getter::values
      methods
        foo
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@method::foo
        bar
          reference: <none>
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
      enclosingElement: <testLibrary>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T @22
              defaultType: dynamic
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @29
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
            foo @43
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
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          typeParameters
            covariant T2 @36
              defaultType: dynamic
          augmentationTarget: <testLibraryFragment>::@enum::A
          methods
            augment foo @56
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@methodAugmentation::foo
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
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
          element: <testLibraryFragment>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          typeParameters
            T @22
              element: <none>
          fields
            enumConstant v @29
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <none>
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <none>
            get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <none>
          methods
            foo @43
              reference: <testLibraryFragment>::@enum::A::@method::foo
              element: <none>
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@methodAugmentation::foo
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A
          previousFragment: <testLibraryFragment>::@enum::A
          typeParameters
            T2 @36
              element: <none>
          methods
            augment foo @56
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@methodAugmentation::foo
              element: <none>
              previousFragment: <testLibraryFragment>::@enum::A::@method::foo
  enums
    enum A
      reference: <testLibraryFragment>::@enum::A
      typeParameters
        T
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const v
          reference: <none>
          type: A<int>
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          getter: <none>
        synthetic static const values
          reference: <none>
          type: List<A<dynamic>>
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          getter: <none>
      constructors
        synthetic const new
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@constructor::new
      getters
        synthetic static get v
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@getter::v
        synthetic static get values
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@getter::values
      methods
        foo
          reference: <none>
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
      enclosingElement: <testLibrary>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          mixins
            M1
          fields
            static const enumConstant v @34
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
        mixin M1 @44
          reference: <testLibraryFragment>::@mixin::M1
          enclosingElement: <testLibraryFragment>
          superclassConstraints
            Object
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          mixins
            M2
      mixins
        mixin M2 @53
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixin::M2
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
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
          element: <testLibraryFragment>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            enumConstant v @34
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <none>
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <none>
            get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <none>
      mixins
        mixin M1 @44
          reference: <testLibraryFragment>::@mixin::M1
          element: <testLibraryFragment>::@mixin::M1
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A
          previousFragment: <testLibraryFragment>::@enum::A
      mixins
        mixin M2 @53
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixin::M2
          element: <testLibrary>::@fragment::package:test/a.dart::@mixin::M2
  enums
    enum A
      reference: <testLibraryFragment>::@enum::A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const v
          reference: <none>
          type: A
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          getter: <none>
        synthetic static const values
          reference: <none>
          type: List<A>
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          getter: <none>
      constructors
        synthetic const new
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@constructor::new
      getters
        synthetic static get v
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@getter::v
        synthetic static get values
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@getter::values
  mixins
    mixin M1
      reference: <testLibraryFragment>::@mixin::M1
      firstFragment: <testLibraryFragment>::@mixin::M1
      superclassConstraints
        Object
    mixin M2
      reference: <testLibrary>::@fragment::package:test/a.dart::@mixin::M2
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
      enclosingElement: <testLibrary>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
        part_1
          uri: package:test/b.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/b.dart
      enums
        enum A @35
          reference: <testLibraryFragment>::@enum::A
          enclosingElement: <testLibraryFragment>
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
        mixin M1 @74
          reference: <testLibraryFragment>::@mixin::M1
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant U1 @77
              defaultType: dynamic
          superclassConstraints
            Object
    <testLibrary>::@fragment::package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
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
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          typeParameters
            covariant U2 @60
              defaultType: dynamic
          superclassConstraints
            M1<U2>
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @34
          reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/b.dart
          typeParameters
            covariant T3 @36
              defaultType: dynamic
          augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          mixins
            M3<T3>
      mixins
        mixin M3 @57
          reference: <testLibrary>::@fragment::package:test/b.dart::@mixin::M3
          enclosingElement: <testLibrary>::@fragment::package:test/b.dart
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
          element: <testLibraryFragment>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          typeParameters
            T1 @37
              element: <none>
          fields
            enumConstant v @57
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <none>
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <none>
            get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <none>
      mixins
        mixin M1 @74
          reference: <testLibraryFragment>::@mixin::M1
          element: <testLibraryFragment>::@mixin::M1
          typeParameters
            U1 @77
              element: <none>
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A
          previousFragment: <testLibraryFragment>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          typeParameters
            T2 @36
              element: <none>
      mixins
        mixin M2 @57
          reference: <testLibrary>::@fragment::package:test/a.dart::@mixin::M2
          element: <testLibrary>::@fragment::package:test/a.dart::@mixin::M2
          typeParameters
            U2 @60
              element: <none>
    <testLibrary>::@fragment::package:test/b.dart
      element: <testLibrary>
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A
          previousFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          typeParameters
            T3 @36
              element: <none>
      mixins
        mixin M3 @57
          reference: <testLibrary>::@fragment::package:test/b.dart::@mixin::M3
          element: <testLibrary>::@fragment::package:test/b.dart::@mixin::M3
          typeParameters
            U3 @60
              element: <none>
  enums
    enum A
      reference: <testLibraryFragment>::@enum::A
      typeParameters
        T1
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const v
          reference: <none>
          type: A<int>
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          getter: <none>
        synthetic static const values
          reference: <none>
          type: List<A<dynamic>>
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          getter: <none>
      constructors
        synthetic const new
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@constructor::new
      getters
        synthetic static get v
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@getter::v
        synthetic static get values
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@getter::values
  mixins
    mixin M1
      reference: <testLibraryFragment>::@mixin::M1
      typeParameters
        U1
      firstFragment: <testLibraryFragment>::@mixin::M1
      superclassConstraints
        Object
    mixin M2
      reference: <testLibrary>::@fragment::package:test/a.dart::@mixin::M2
      typeParameters
        U2
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@mixin::M2
      superclassConstraints
        M1<U2>
    mixin M3
      reference: <testLibrary>::@fragment::package:test/b.dart::@mixin::M3
      typeParameters
        U3
      firstFragment: <testLibrary>::@fragment::package:test/b.dart::@mixin::M3
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
      enclosingElement: <testLibrary>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @26
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
            set foo1= @35
              reference: <testLibraryFragment>::@enum::A::@setter::foo1
              enclosingElement: <testLibraryFragment>::@enum::A
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
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @34
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
            set foo2= @45
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@setter::foo2
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
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
          element: <testLibraryFragment>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            enumConstant v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::values
            foo1 @-1
              reference: <testLibraryFragment>::@enum::A::@field::foo1
              element: <none>
              setter2: <testLibraryFragment>::@enum::A::@setter::foo1
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <none>
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <none>
            get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <none>
          setters
            set foo1= @35
              reference: <testLibraryFragment>::@enum::A::@setter::foo1
              element: <none>
              parameters
                _ @44
                  element: <none>
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A
          previousFragment: <testLibraryFragment>::@enum::A
          fields
            foo2 @-1
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::foo2
              element: <none>
              setter2: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@setter::foo2
          setters
            set foo2= @45
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@setter::foo2
              element: <none>
              parameters
                _ @54
                  element: <none>
  enums
    enum A
      reference: <testLibraryFragment>::@enum::A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const v
          reference: <none>
          type: A
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          getter: <none>
        synthetic static const values
          reference: <none>
          type: List<A>
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          getter: <none>
        synthetic foo1
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@enum::A::@field::foo1
          setter: <none>
        synthetic foo2
          reference: <none>
          type: int
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@field::foo2
          setter: <none>
      constructors
        synthetic const new
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@constructor::new
      getters
        synthetic static get v
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@getter::v
        synthetic static get values
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@getter::values
      setters
        set foo1=
          reference: <none>
          parameters
            requiredPositional _
              reference: <none>
              type: int
          firstFragment: <testLibraryFragment>::@enum::A::@setter::foo1
        set foo2=
          reference: <none>
          parameters
            requiredPositional _
              reference: <none>
              type: int
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@setter::foo2
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
      enclosingElement: <testLibrary>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @26
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
            final foo @41
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
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          accessors
            augment set foo= @53
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@setterAugmentation::foo
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
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
          element: <testLibraryFragment>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            enumConstant v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::values
            foo @41
              reference: <testLibraryFragment>::@enum::A::@field::foo
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::foo
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <none>
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <none>
            get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <none>
            get foo @-1
              reference: <testLibraryFragment>::@enum::A::@getter::foo
              element: <none>
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A
          previousFragment: <testLibraryFragment>::@enum::A
          setters
            augment set foo= @53
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@setterAugmentation::foo
              element: <none>
              parameters
                _ @61
                  element: <none>
  enums
    enum A
      reference: <testLibraryFragment>::@enum::A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const v
          reference: <none>
          type: A
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          getter: <none>
        synthetic static const values
          reference: <none>
          type: List<A>
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          getter: <none>
        final foo
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@enum::A::@field::foo
          getter: <none>
      constructors
        synthetic const new
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@constructor::new
      getters
        synthetic static get v
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@getter::v
        synthetic static get values
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@getter::values
        synthetic get foo
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@getter::foo
      setters
        set foo=
          reference: <none>
          parameters
            requiredPositional _
              reference: <none>
              type: int
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@setterAugmentation::foo
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
      enclosingElement: <testLibrary>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @26
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
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          accessors
            augment set foo= @53
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@setterAugmentation::foo
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
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
          element: <testLibraryFragment>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            enumConstant v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <none>
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <none>
            get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <none>
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A
          previousFragment: <testLibraryFragment>::@enum::A
          setters
            augment set foo= @53
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@setterAugmentation::foo
              element: <none>
              parameters
                _ @61
                  element: <none>
  enums
    enum A
      reference: <testLibraryFragment>::@enum::A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const v
          reference: <none>
          type: A
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          getter: <none>
        synthetic static const values
          reference: <none>
          type: List<A>
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          getter: <none>
      constructors
        synthetic const new
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@constructor::new
      getters
        synthetic static get v
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@getter::v
        synthetic static get values
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@getter::values
      setters
        set foo=
          reference: <none>
          parameters
            requiredPositional _
              reference: <none>
              type: int
          firstFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@setterAugmentation::foo
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
      enclosingElement: <testLibrary>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @26
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
            set foo1= @35
              reference: <testLibraryFragment>::@enum::A::@setter::foo1
              enclosingElement: <testLibraryFragment>::@enum::A
              parameters
                requiredPositional _ @44
                  type: int
              returnType: void
              id: setter_0
              variable: field_2
              augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@setterAugmentation::foo1
            set foo2= @56
              reference: <testLibraryFragment>::@enum::A::@setter::foo2
              enclosingElement: <testLibraryFragment>::@enum::A
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
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          accessors
            augment set foo1= @53
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@setterAugmentation::foo1
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
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
          element: <testLibraryFragment>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            enumConstant v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::values
            foo1 @-1
              reference: <testLibraryFragment>::@enum::A::@field::foo1
              element: <none>
              setter2: <testLibraryFragment>::@enum::A::@setter::foo1
            foo2 @-1
              reference: <testLibraryFragment>::@enum::A::@field::foo2
              element: <none>
              setter2: <testLibraryFragment>::@enum::A::@setter::foo2
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <none>
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <none>
            get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <none>
          setters
            set foo1= @35
              reference: <testLibraryFragment>::@enum::A::@setter::foo1
              element: <none>
              parameters
                _ @44
                  element: <none>
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@setterAugmentation::foo1
            set foo2= @56
              reference: <testLibraryFragment>::@enum::A::@setter::foo2
              element: <none>
              parameters
                _ @65
                  element: <none>
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A
          previousFragment: <testLibraryFragment>::@enum::A
          setters
            augment set foo1= @53
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@setterAugmentation::foo1
              element: <none>
              parameters
                _ @62
                  element: <none>
              previousFragment: <testLibraryFragment>::@enum::A::@setter::foo1
  enums
    enum A
      reference: <testLibraryFragment>::@enum::A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const v
          reference: <none>
          type: A
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          getter: <none>
        synthetic static const values
          reference: <none>
          type: List<A>
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          getter: <none>
        synthetic foo1
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@enum::A::@field::foo1
          setter: <none>
        synthetic foo2
          reference: <none>
          type: int
          firstFragment: <testLibraryFragment>::@enum::A::@field::foo2
          setter: <none>
      constructors
        synthetic const new
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@constructor::new
      getters
        synthetic static get v
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@getter::v
        synthetic static get values
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@getter::values
      setters
        set foo2=
          reference: <none>
          parameters
            requiredPositional _
              reference: <none>
              type: int
          firstFragment: <testLibraryFragment>::@enum::A::@setter::foo2
        set foo1=
          reference: <none>
          parameters
            requiredPositional _
              reference: <none>
              type: int
          firstFragment: <testLibraryFragment>::@enum::A::@setter::foo1
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
      enclosingElement: <testLibrary>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
        part_1
          uri: package:test/b.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/b.dart
      enums
        enum A @36
          reference: <testLibraryFragment>::@enum::A
          enclosingElement: <testLibraryFragment>
          supertype: Enum
          fields
            static const enumConstant v @39
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
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      classes
        augment class A @36
          reference: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTargetAny: <testLibraryFragment>::@enum::A
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      classes
        augment class A @36
          reference: <testLibrary>::@fragment::package:test/b.dart::@classAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/b.dart
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
          element: <testLibraryFragment>::@enum::A
          fields
            enumConstant v @39
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::values
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <none>
            get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <none>
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      classes
        class A @36
          reference: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A
          element: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A
    <testLibrary>::@fragment::package:test/b.dart
      element: <testLibrary>
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      classes
        class A @36
          reference: <testLibrary>::@fragment::package:test/b.dart::@classAugmentation::A
          element: <testLibrary>::@fragment::package:test/b.dart::@classAugmentation::A
  classes
    class A
      reference: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A
    class A
      reference: <testLibrary>::@fragment::package:test/b.dart::@classAugmentation::A
      firstFragment: <testLibrary>::@fragment::package:test/b.dart::@classAugmentation::A
  enums
    enum A
      reference: <testLibraryFragment>::@enum::A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const v
          reference: <none>
          type: A
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          getter: <none>
        synthetic static const values
          reference: <none>
          type: List<A>
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          getter: <none>
      getters
        synthetic static get v
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@getter::v
        synthetic static get values
          reference: <none>
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
      enclosingElement: <testLibrary>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
        part_1
          uri: package:test/b.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/b.dart
      enums
        enum A @36
          reference: <testLibraryFragment>::@enum::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @39
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
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      classes
        augment class A @36
          reference: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTargetAny: <testLibraryFragment>::@enum::A
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @35
          reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/b.dart
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
          element: <testLibraryFragment>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          fields
            enumConstant v @39
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::values
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <none>
            get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <none>
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      classes
        class A @36
          reference: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A
          element: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A
    <testLibrary>::@fragment::package:test/b.dart
      element: <testLibrary>
      previousFragment: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @35
          reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A
          previousFragment: <testLibraryFragment>::@enum::A
  classes
    class A
      reference: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A
      firstFragment: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A
  enums
    enum A
      reference: <testLibraryFragment>::@enum::A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const v
          reference: <none>
          type: A
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          getter: <none>
        synthetic static const values
          reference: <none>
          type: List<A>
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          getter: <none>
      getters
        synthetic static get v
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@getter::v
        synthetic static get values
          reference: <none>
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
      enclosingElement: <testLibrary>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
        part_1
          uri: package:test/b.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/b.dart
      enums
        enum A @35
          reference: <testLibraryFragment>::@enum::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @41
              reference: <testLibraryFragment>::@enum::A::@field::v
              enclosingElement: <testLibraryFragment>::@enum::A
              type: A
              shouldUseTypeForInitializerInference: false
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              enclosingElement: <testLibraryFragment>::@enum::A
              type: List<A>
          constructors
            const named @62
              reference: <testLibraryFragment>::@enum::A::@constructor::named
              enclosingElement: <testLibraryFragment>::@enum::A
              periodOffset: 61
              nameEnd: 67
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
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          augmentation: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          constructors
            augment const named @57
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructorAugmentation::named
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
              periodOffset: 56
              nameEnd: 62
              augmentationTarget: <testLibraryFragment>::@enum::A::@constructor::named
              augmentation: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@constructorAugmentation::named
    <testLibrary>::@fragment::package:test/b.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @34
          reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/b.dart
          augmentationTarget: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          constructors
            augment const named @57
              reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@constructorAugmentation::named
              enclosingElement: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
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
          element: <testLibraryFragment>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            enumConstant v @41
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::values
          constructors
            const named @62
              reference: <testLibraryFragment>::@enum::A::@constructor::named
              element: <none>
              periodOffset: 61
              nameEnd: 67
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructorAugmentation::named
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <none>
            get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <none>
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/b.dart
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A
          previousFragment: <testLibraryFragment>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A
          constructors
            augment const named @57
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructorAugmentation::named
              element: <none>
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
          element: <testLibraryFragment>::@enum::A
          previousFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          constructors
            augment const named @57
              reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::A::@constructorAugmentation::named
              element: <none>
              periodOffset: 56
              nameEnd: 62
              previousFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructorAugmentation::named
  enums
    enum A
      reference: <testLibraryFragment>::@enum::A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const v
          reference: <none>
          type: A
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          getter: <none>
        synthetic static const values
          reference: <none>
          type: List<A>
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          getter: <none>
      constructors
        const named
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@constructor::named
      getters
        synthetic static get v
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@getter::v
        synthetic static get values
          reference: <none>
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
      enclosingElement: <testLibrary>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @26
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
            const named @47
              reference: <testLibraryFragment>::@enum::A::@constructor::named
              enclosingElement: <testLibraryFragment>::@enum::A
              periodOffset: 46
              nameEnd: 52
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
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          constructors
            augment const named @57
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructorAugmentation::named
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
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
          element: <testLibraryFragment>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            enumConstant v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::values
          constructors
            const named @47
              reference: <testLibraryFragment>::@enum::A::@constructor::named
              element: <none>
              periodOffset: 46
              nameEnd: 52
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructorAugmentation::named
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <none>
            get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <none>
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A
          previousFragment: <testLibraryFragment>::@enum::A
          constructors
            augment const named @57
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructorAugmentation::named
              element: <none>
              periodOffset: 56
              nameEnd: 62
              previousFragment: <testLibraryFragment>::@enum::A::@constructor::named
  enums
    enum A
      reference: <testLibraryFragment>::@enum::A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const v
          reference: <none>
          type: A
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          getter: <none>
        synthetic static const values
          reference: <none>
          type: List<A>
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          getter: <none>
      constructors
        const named
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@constructor::named
      getters
        synthetic static get v
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@getter::v
        synthetic static get values
          reference: <none>
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
      enclosingElement: <testLibrary>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @26
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
            const @37
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
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
          augmentationTarget: <testLibraryFragment>::@enum::A
          constructors
            augment const @55
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructorAugmentation::new
              enclosingElement: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
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
          element: <testLibraryFragment>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          fields
            enumConstant v @26
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::values
          constructors
            const new @37
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <none>
              nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructorAugmentation::new
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <none>
            get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <none>
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A
          previousFragment: <testLibraryFragment>::@enum::A
          constructors
            augment const new @55
              reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A::@constructorAugmentation::new
              element: <none>
              previousFragment: <testLibraryFragment>::@enum::A::@constructor::new
  enums
    enum A
      reference: <testLibraryFragment>::@enum::A
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const v
          reference: <none>
          type: A
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          getter: <none>
        synthetic static const values
          reference: <none>
          type: List<A>
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          getter: <none>
      constructors
        const new
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@constructor::new
      getters
        synthetic static get v
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@getter::v
        synthetic static get values
          reference: <none>
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
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  parts
    part_0
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryImports
        package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
      parts
        part_0
          uri: package:test/b.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/b.dart
      enums
        enum B @38
          reference: <testLibraryFragment>::@enum::B
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::B
          supertype: Enum
          interfaces
            A
          fields
            static const enumConstant v @57
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
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum B @34
          reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::B
          enclosingElement: <testLibrary>::@fragment::package:test/b.dart
          augmentationTarget: <testLibraryFragment>::@enum::B
          methods
            foo @41
              reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::B::@method::foo
              enclosingElement: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::B
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
          element: <testLibraryFragment>::@enum::B
          nextFragment: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::B
          fields
            enumConstant v @57
              reference: <testLibraryFragment>::@enum::B::@field::v
              element: <none>
              getter2: <testLibraryFragment>::@enum::B::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::B::@field::values
              element: <none>
              getter2: <testLibraryFragment>::@enum::B::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::B::@constructor::new
              element: <none>
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::B::@getter::v
              element: <none>
            get values @-1
              reference: <testLibraryFragment>::@enum::B::@getter::values
              element: <none>
    <testLibrary>::@fragment::package:test/b.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      enums
        enum B @34
          reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::B
          element: <testLibraryFragment>::@enum::B
          previousFragment: <testLibraryFragment>::@enum::B
          methods
            foo @41
              reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::B::@method::foo
              element: <none>
              parameters
                a @45
                  element: <none>
  enums
    enum B
      reference: <testLibraryFragment>::@enum::B
      firstFragment: <testLibraryFragment>::@enum::B
      supertype: Enum
      fields
        static const v
          reference: <none>
          type: B
          firstFragment: <testLibraryFragment>::@enum::B::@field::v
          getter: <none>
        synthetic static const values
          reference: <none>
          type: List<B>
          firstFragment: <testLibraryFragment>::@enum::B::@field::values
          getter: <none>
      constructors
        synthetic const new
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::B::@constructor::new
      getters
        synthetic static get v
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::B::@getter::v
        synthetic static get values
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::B::@getter::values
      methods
        foo
          reference: <none>
          parameters
            requiredPositional a
              reference: <none>
              type: String
          firstFragment: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::B::@method::foo
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
      enclosingElement: <testLibrary>
      parts
        part_0
          uri: package:test/b.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/b.dart
      enums
        enum B @21
          reference: <testLibraryFragment>::@enum::B
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::B
          supertype: Enum
          fields
            static const enumConstant v @27
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
            foo @32
              reference: <testLibraryFragment>::@enum::B::@method::foo
              enclosingElement: <testLibraryFragment>::@enum::B
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
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      libraryImports
        package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibrary>::@fragment::package:test/b.dart
      enums
        augment enum B @51
          reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::B
          enclosingElement: <testLibrary>::@fragment::package:test/b.dart
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
          element: <testLibraryFragment>::@enum::B
          nextFragment: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::B
          fields
            enumConstant v @27
              reference: <testLibraryFragment>::@enum::B::@field::v
              element: <none>
              getter2: <testLibraryFragment>::@enum::B::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::B::@field::values
              element: <none>
              getter2: <testLibraryFragment>::@enum::B::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::B::@constructor::new
              element: <none>
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::B::@getter::v
              element: <none>
            get values @-1
              reference: <testLibraryFragment>::@enum::B::@getter::values
              element: <none>
          methods
            foo @32
              reference: <testLibraryFragment>::@enum::B::@method::foo
              element: <none>
              parameters
                a @36
                  element: <none>
    <testLibrary>::@fragment::package:test/b.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      libraryImports
        package:test/a.dart
      enums
        enum B @51
          reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::B
          element: <testLibraryFragment>::@enum::B
          previousFragment: <testLibraryFragment>::@enum::B
  enums
    enum B
      reference: <testLibraryFragment>::@enum::B
      firstFragment: <testLibraryFragment>::@enum::B
      supertype: Enum
      fields
        static const v
          reference: <none>
          type: B
          firstFragment: <testLibraryFragment>::@enum::B::@field::v
          getter: <none>
        synthetic static const values
          reference: <none>
          type: List<B>
          firstFragment: <testLibraryFragment>::@enum::B::@field::values
          getter: <none>
      constructors
        synthetic const new
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::B::@constructor::new
      getters
        synthetic static get v
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::B::@getter::v
        synthetic static get values
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::B::@getter::values
      methods
        foo
          reference: <none>
          parameters
            requiredPositional a
              reference: <none>
              type: String
          firstFragment: <testLibraryFragment>::@enum::B::@method::foo
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
      enclosingElement: <testLibrary>
      parts
        part_0
          uri: package:test/b.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/b.dart
      enums
        enum B @21
          reference: <testLibraryFragment>::@enum::B
          enclosingElement: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::B
          supertype: Enum
          fields
            static const enumConstant v @27
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
            foo @32
              reference: <testLibraryFragment>::@enum::B::@method::foo
              enclosingElement: <testLibraryFragment>::@enum::B
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
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      libraryImports
        package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibrary>::@fragment::package:test/b.dart
      enums
        augment enum B @51
          reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::B
          enclosingElement: <testLibrary>::@fragment::package:test/b.dart
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
          element: <testLibraryFragment>::@enum::B
          nextFragment: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::B
          fields
            enumConstant v @27
              reference: <testLibraryFragment>::@enum::B::@field::v
              element: <none>
              getter2: <testLibraryFragment>::@enum::B::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::B::@field::values
              element: <none>
              getter2: <testLibraryFragment>::@enum::B::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::B::@constructor::new
              element: <none>
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::B::@getter::v
              element: <none>
            get values @-1
              reference: <testLibraryFragment>::@enum::B::@getter::values
              element: <none>
          methods
            foo @32
              reference: <testLibraryFragment>::@enum::B::@method::foo
              element: <none>
              parameters
                a @36
                  element: <none>
    <testLibrary>::@fragment::package:test/b.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      libraryImports
        package:test/a.dart
      enums
        enum B @51
          reference: <testLibrary>::@fragment::package:test/b.dart::@enumAugmentation::B
          element: <testLibraryFragment>::@enum::B
          previousFragment: <testLibraryFragment>::@enum::B
  enums
    enum B
      reference: <testLibraryFragment>::@enum::B
      firstFragment: <testLibraryFragment>::@enum::B
      supertype: Enum
      fields
        static const v
          reference: <none>
          type: B
          firstFragment: <testLibraryFragment>::@enum::B::@field::v
          getter: <none>
        synthetic static const values
          reference: <none>
          type: List<B>
          firstFragment: <testLibraryFragment>::@enum::B::@field::values
          getter: <none>
      constructors
        synthetic const new
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::B::@constructor::new
      getters
        synthetic static get v
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::B::@getter::v
        synthetic static get values
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::B::@getter::values
      methods
        foo
          reference: <none>
          parameters
            requiredPositional a
              reference: <none>
              type: String
          firstFragment: <testLibraryFragment>::@enum::B::@method::foo
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
      enclosingElement: <testLibrary>
      parts
        part_0
          uri: package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/a.dart
      classes
        class B @49
          reference: <testLibraryFragment>::@class::B
          enclosingElement: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::B::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::B
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T @22
              bound: B
              defaultType: B
          augmentation: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          supertype: Enum
          fields
            static const enumConstant v @39
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
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      enums
        augment enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          enclosingElement: <testLibrary>::@fragment::package:test/a.dart
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
          element: <testLibraryFragment>::@class::B
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::B::@constructor::new
              element: <none>
      enums
        enum A @20
          reference: <testLibraryFragment>::@enum::A
          element: <testLibraryFragment>::@enum::A
          nextFragment: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          typeParameters
            T @22
              element: <none>
          fields
            enumConstant v @39
              reference: <testLibraryFragment>::@enum::A::@field::v
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::A::@field::values
              element: <none>
              getter2: <testLibraryFragment>::@enum::A::@getter::values
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@enum::A::@constructor::new
              element: <none>
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::A::@getter::v
              element: <none>
            get values @-1
              reference: <testLibraryFragment>::@enum::A::@getter::values
              element: <none>
    <testLibrary>::@fragment::package:test/a.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      enums
        enum A @34
          reference: <testLibrary>::@fragment::package:test/a.dart::@enumAugmentation::A
          element: <testLibraryFragment>::@enum::A
          previousFragment: <testLibraryFragment>::@enum::A
          typeParameters
            T @36
              element: <none>
  classes
    class B
      reference: <testLibraryFragment>::@class::B
      firstFragment: <testLibraryFragment>::@class::B
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::B::@constructor::new
  enums
    enum A
      reference: <testLibraryFragment>::@enum::A
      typeParameters
        T
          bound: B
      firstFragment: <testLibraryFragment>::@enum::A
      supertype: Enum
      fields
        static const v
          reference: <none>
          type: A<B>
          firstFragment: <testLibraryFragment>::@enum::A::@field::v
          getter: <none>
        synthetic static const values
          reference: <none>
          type: List<A<B>>
          firstFragment: <testLibraryFragment>::@enum::A::@field::values
          getter: <none>
      constructors
        synthetic const new
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@constructor::new
      getters
        synthetic static get v
          reference: <none>
          firstFragment: <testLibraryFragment>::@enum::A::@getter::v
        synthetic static get values
          reference: <none>
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
