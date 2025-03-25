// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../dart/resolution/node_text_expectations.dart';
import '../elements_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FunctionTypeAnnotationElementTest_keepLinking);
    defineReflectiveTests(FunctionTypeAnnotationElementTest_fromBytes);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

abstract class FunctionTypeAnnotationElementTest extends ElementsBaseTest {
  test_generic_function_type_nullability_none() async {
    var library = await buildLibrary('''
void Function() f;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        f @16
          reference: <testLibraryFragment>::@topLevelVariable::f
          element: <testLibrary>::@topLevelVariable::f
          getter2: <testLibraryFragment>::@getter::f
          setter2: <testLibraryFragment>::@setter::f
      getters
        synthetic get f
          reference: <testLibraryFragment>::@getter::f
          element: <testLibraryFragment>::@getter::f#element
      setters
        synthetic set f
          reference: <testLibraryFragment>::@setter::f
          element: <testLibraryFragment>::@setter::f#element
          formalParameters
            _f
              element: <testLibraryFragment>::@setter::f::@parameter::_f#element
  topLevelVariables
    f
      reference: <testLibrary>::@topLevelVariable::f
      firstFragment: <testLibraryFragment>::@topLevelVariable::f
      type: void Function()
      getter: <testLibraryFragment>::@getter::f#element
      setter: <testLibraryFragment>::@setter::f#element
  getters
    synthetic static get f
      firstFragment: <testLibraryFragment>::@getter::f
  setters
    synthetic static set f
      firstFragment: <testLibraryFragment>::@setter::f
      formalParameters
        requiredPositional _f
          type: void Function()
''');
  }

  test_generic_function_type_nullability_question() async {
    var library = await buildLibrary('''
void Function()? f;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        f @17
          reference: <testLibraryFragment>::@topLevelVariable::f
          element: <testLibrary>::@topLevelVariable::f
          getter2: <testLibraryFragment>::@getter::f
          setter2: <testLibraryFragment>::@setter::f
      getters
        synthetic get f
          reference: <testLibraryFragment>::@getter::f
          element: <testLibraryFragment>::@getter::f#element
      setters
        synthetic set f
          reference: <testLibraryFragment>::@setter::f
          element: <testLibraryFragment>::@setter::f#element
          formalParameters
            _f
              element: <testLibraryFragment>::@setter::f::@parameter::_f#element
  topLevelVariables
    f
      reference: <testLibrary>::@topLevelVariable::f
      firstFragment: <testLibraryFragment>::@topLevelVariable::f
      type: void Function()?
      getter: <testLibraryFragment>::@getter::f#element
      setter: <testLibraryFragment>::@setter::f#element
  getters
    synthetic static get f
      firstFragment: <testLibraryFragment>::@getter::f
  setters
    synthetic static set f
      firstFragment: <testLibraryFragment>::@setter::f
      formalParameters
        requiredPositional _f
          type: void Function()?
''');
  }

  test_genericFunction_asFunctionReturnType() async {
    var library = await buildLibrary(r'''
int Function(int a, String b) f() => null;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      functions
        f @30
          reference: <testLibraryFragment>::@function::f
          element: <testLibrary>::@function::f
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: <testLibraryFragment>::@function::f
      returnType: int Function(int, String)
''');
  }

  test_genericFunction_asFunctionTypedParameterReturnType() async {
    var library = await buildLibrary(r'''
void f(int Function(int a, String b) p(num c)) => null;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      functions
        f @5
          reference: <testLibraryFragment>::@function::f
          element: <testLibrary>::@function::f
          formalParameters
            p @37
              element: <testLibraryFragment>::@function::f::@parameter::p#element
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: <testLibraryFragment>::@function::f
      formalParameters
        requiredPositional p
          type: int Function(int, String) Function(num)
          formalParameters
            requiredPositional c
              type: num
      returnType: void
''');
  }

  test_genericFunction_asGenericFunctionReturnType() async {
    var library = await buildLibrary(r'''
typedef F = void Function(String a) Function(int b);
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        F @8
          reference: <testLibraryFragment>::@typeAlias::F
          element: <testLibrary>::@typeAlias::F
  typeAliases
    F
      firstFragment: <testLibraryFragment>::@typeAlias::F
      aliasedType: void Function(String) Function(int)
''');
  }

  test_genericFunction_asMethodReturnType() async {
    var library = await buildLibrary(r'''
class C {
  int Function(int a, String b) m() => null;
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
              typeName: C
          methods
            m @42
              reference: <testLibraryFragment>::@class::C::@method::m
              element: <testLibraryFragment>::@class::C::@method::m#element
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      methods
        m
          firstFragment: <testLibraryFragment>::@class::C::@method::m
''');
  }

  test_genericFunction_asParameterType() async {
    var library = await buildLibrary(r'''
void f(int Function(int a, String b) p) => null;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      functions
        f @5
          reference: <testLibraryFragment>::@function::f
          element: <testLibrary>::@function::f
          formalParameters
            p @37
              element: <testLibraryFragment>::@function::f::@parameter::p#element
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: <testLibraryFragment>::@function::f
      formalParameters
        requiredPositional p
          type: int Function(int, String)
      returnType: void
''');
  }

  test_genericFunction_asTopLevelVariableType() async {
    var library = await buildLibrary(r'''
int Function(int a, String b) v;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        v @30
          reference: <testLibraryFragment>::@topLevelVariable::v
          element: <testLibrary>::@topLevelVariable::v
          getter2: <testLibraryFragment>::@getter::v
          setter2: <testLibraryFragment>::@setter::v
      getters
        synthetic get v
          reference: <testLibraryFragment>::@getter::v
          element: <testLibraryFragment>::@getter::v#element
      setters
        synthetic set v
          reference: <testLibraryFragment>::@setter::v
          element: <testLibraryFragment>::@setter::v#element
          formalParameters
            _v
              element: <testLibraryFragment>::@setter::v::@parameter::_v#element
  topLevelVariables
    v
      reference: <testLibrary>::@topLevelVariable::v
      firstFragment: <testLibraryFragment>::@topLevelVariable::v
      type: int Function(int, String)
      getter: <testLibraryFragment>::@getter::v#element
      setter: <testLibraryFragment>::@setter::v#element
  getters
    synthetic static get v
      firstFragment: <testLibraryFragment>::@getter::v
  setters
    synthetic static set v
      firstFragment: <testLibraryFragment>::@setter::v
      formalParameters
        requiredPositional _v
          type: int Function(int, String)
''');
  }

  test_genericFunction_asTypeArgument_ofAnnotation_class() async {
    var library = await buildLibrary(r'''
class A<T> {
  const A();
}

@A<int Function(String a)>()
class B {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          element: <testLibrary>::@class::A
          typeParameters
            T @8
              element: <not-implemented>
          constructors
            const new
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <testLibraryFragment>::@class::A::@constructor::new#element
              typeName: A
              typeNameOffset: 21
        class B @64
          reference: <testLibraryFragment>::@class::B
          element: <testLibrary>::@class::B
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::B::@constructor::new
              element: <testLibraryFragment>::@class::B::@constructor::new#element
              typeName: B
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
      typeParameters
        T
      constructors
        const new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
    class B
      reference: <testLibrary>::@class::B
      firstFragment: <testLibraryFragment>::@class::B
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::B::@constructor::new
''');
  }

  test_genericFunction_asTypeArgument_ofAnnotation_topLevelVariable() async {
    var library = await buildLibrary(r'''
class A<T> {
  const A();
}

@A<int Function(String a)>()
var v = 0;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          element: <testLibrary>::@class::A
          typeParameters
            T @8
              element: <not-implemented>
          constructors
            const new
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <testLibraryFragment>::@class::A::@constructor::new#element
              typeName: A
              typeNameOffset: 21
      topLevelVariables
        hasInitializer v @62
          reference: <testLibraryFragment>::@topLevelVariable::v
          element: <testLibrary>::@topLevelVariable::v
          metadata
            Annotation
              atSign: @ @29
              name: SimpleIdentifier
                token: A @30
                staticElement: <testLibraryFragment>::@class::A
                element: <testLibrary>::@class::A
                staticType: null
              typeArguments: TypeArgumentList
                leftBracket: < @31
                arguments
                  GenericFunctionType
                    returnType: NamedType
                      name: int @32
                      element: dart:core::<fragment>::@class::int
                      element2: dart:core::@class::int
                      type: int
                    functionKeyword: Function @36
                    parameters: FormalParameterList
                      leftParenthesis: ( @44
                      parameter: SimpleFormalParameter
                        type: NamedType
                          name: String @45
                          element: dart:core::<fragment>::@class::String
                          element2: dart:core::@class::String
                          type: String
                        name: a @52
                        declaredElement: a@52
                          type: String
                      rightParenthesis: ) @53
                    declaredElement: GenericFunctionTypeElement
                      parameters
                        a
                          kind: required positional
                          type: String
                      returnType: int
                      type: int Function(String)
                    type: int Function(String)
                rightBracket: > @54
              arguments: ArgumentList
                leftParenthesis: ( @55
                rightParenthesis: ) @56
              element: ConstructorMember
                base: <testLibraryFragment>::@class::A::@constructor::new
                substitution: {T: int Function(String)}
              element2: <testLibraryFragment>::@class::A::@constructor::new#element
          getter2: <testLibraryFragment>::@getter::v
          setter2: <testLibraryFragment>::@setter::v
      getters
        synthetic get v
          reference: <testLibraryFragment>::@getter::v
          element: <testLibraryFragment>::@getter::v#element
      setters
        synthetic set v
          reference: <testLibraryFragment>::@setter::v
          element: <testLibraryFragment>::@setter::v#element
          formalParameters
            _v
              element: <testLibraryFragment>::@setter::v::@parameter::_v#element
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
      typeParameters
        T
      constructors
        const new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
  topLevelVariables
    hasInitializer v
      reference: <testLibrary>::@topLevelVariable::v
      firstFragment: <testLibraryFragment>::@topLevelVariable::v
      metadata
        Annotation
          atSign: @ @29
          name: SimpleIdentifier
            token: A @30
            staticElement: <testLibraryFragment>::@class::A
            element: <testLibrary>::@class::A
            staticType: null
          typeArguments: TypeArgumentList
            leftBracket: < @31
            arguments
              GenericFunctionType
                returnType: NamedType
                  name: int @32
                  element: dart:core::<fragment>::@class::int
                  element2: dart:core::@class::int
                  type: int
                functionKeyword: Function @36
                parameters: FormalParameterList
                  leftParenthesis: ( @44
                  parameter: SimpleFormalParameter
                    type: NamedType
                      name: String @45
                      element: dart:core::<fragment>::@class::String
                      element2: dart:core::@class::String
                      type: String
                    name: a @52
                    declaredElement: a@52
                      type: String
                  rightParenthesis: ) @53
                declaredElement: GenericFunctionTypeElement
                  parameters
                    a
                      kind: required positional
                      type: String
                  returnType: int
                  type: int Function(String)
                type: int Function(String)
            rightBracket: > @54
          arguments: ArgumentList
            leftParenthesis: ( @55
            rightParenthesis: ) @56
          element: ConstructorMember
            base: <testLibraryFragment>::@class::A::@constructor::new
            substitution: {T: int Function(String)}
          element2: <testLibraryFragment>::@class::A::@constructor::new#element
      type: int
      getter: <testLibraryFragment>::@getter::v#element
      setter: <testLibraryFragment>::@setter::v#element
  getters
    synthetic static get v
      firstFragment: <testLibraryFragment>::@getter::v
  setters
    synthetic static set v
      firstFragment: <testLibraryFragment>::@setter::v
      formalParameters
        requiredPositional _v
          type: int
''');
  }

  test_genericFunction_asTypeArgument_parameters_optionalNamed() async {
    var library = await buildLibrary(r'''
class A<T> {
  const A();
}

const v = A<String Function({int? a})>();
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          element: <testLibrary>::@class::A
          typeParameters
            T @8
              element: <not-implemented>
          constructors
            const new
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <testLibraryFragment>::@class::A::@constructor::new#element
              typeName: A
              typeNameOffset: 21
      topLevelVariables
        hasInitializer v @35
          reference: <testLibraryFragment>::@topLevelVariable::v
          element: <testLibrary>::@topLevelVariable::v
          initializer: expression_0
            InstanceCreationExpression
              constructorName: ConstructorName
                type: NamedType
                  name: A @39
                  typeArguments: TypeArgumentList
                    leftBracket: < @40
                    arguments
                      GenericFunctionType
                        returnType: NamedType
                          name: String @41
                          element: dart:core::<fragment>::@class::String
                          element2: dart:core::@class::String
                          type: String
                        functionKeyword: Function @48
                        parameters: FormalParameterList
                          leftParenthesis: ( @56
                          leftDelimiter: { @57
                          parameter: DefaultFormalParameter
                            parameter: SimpleFormalParameter
                              type: NamedType
                                name: int @58
                                question: ? @61
                                element: dart:core::<fragment>::@class::int
                                element2: dart:core::@class::int
                                type: int?
                              name: a @63
                              declaredElement: a@63
                                type: int?
                            declaredElement: a@63
                              type: int?
                          rightDelimiter: } @64
                          rightParenthesis: ) @65
                        declaredElement: GenericFunctionTypeElement
                          parameters
                            a
                              kind: optional named
                              type: int?
                          returnType: String
                          type: String Function({int? a})
                        type: String Function({int? a})
                    rightBracket: > @66
                  element: <testLibraryFragment>::@class::A
                  element2: <testLibrary>::@class::A
                  type: A<String Function({int? a})>
                staticElement: ConstructorMember
                  base: <testLibraryFragment>::@class::A::@constructor::new
                  substitution: {T: String Function({int? a})}
                element: <testLibraryFragment>::@class::A::@constructor::new#element
              argumentList: ArgumentList
                leftParenthesis: ( @67
                rightParenthesis: ) @68
              staticType: A<String Function({int? a})>
          getter2: <testLibraryFragment>::@getter::v
      getters
        synthetic get v
          reference: <testLibraryFragment>::@getter::v
          element: <testLibraryFragment>::@getter::v#element
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
      typeParameters
        T
      constructors
        const new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
  topLevelVariables
    const hasInitializer v
      reference: <testLibrary>::@topLevelVariable::v
      firstFragment: <testLibraryFragment>::@topLevelVariable::v
      type: A<String Function({int? a})>
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::v
        expression: expression_0
      getter: <testLibraryFragment>::@getter::v#element
  getters
    synthetic static get v
      firstFragment: <testLibraryFragment>::@getter::v
''');
  }

  test_genericFunction_asTypeArgument_parameters_optionalPositional() async {
    var library = await buildLibrary(r'''
class A<T> {
  const A();
}

const v = A<String Function([int? a])>();
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          element: <testLibrary>::@class::A
          typeParameters
            T @8
              element: <not-implemented>
          constructors
            const new
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <testLibraryFragment>::@class::A::@constructor::new#element
              typeName: A
              typeNameOffset: 21
      topLevelVariables
        hasInitializer v @35
          reference: <testLibraryFragment>::@topLevelVariable::v
          element: <testLibrary>::@topLevelVariable::v
          initializer: expression_0
            InstanceCreationExpression
              constructorName: ConstructorName
                type: NamedType
                  name: A @39
                  typeArguments: TypeArgumentList
                    leftBracket: < @40
                    arguments
                      GenericFunctionType
                        returnType: NamedType
                          name: String @41
                          element: dart:core::<fragment>::@class::String
                          element2: dart:core::@class::String
                          type: String
                        functionKeyword: Function @48
                        parameters: FormalParameterList
                          leftParenthesis: ( @56
                          leftDelimiter: [ @57
                          parameter: DefaultFormalParameter
                            parameter: SimpleFormalParameter
                              type: NamedType
                                name: int @58
                                question: ? @61
                                element: dart:core::<fragment>::@class::int
                                element2: dart:core::@class::int
                                type: int?
                              name: a @63
                              declaredElement: a@63
                                type: int?
                            declaredElement: a@63
                              type: int?
                          rightDelimiter: ] @64
                          rightParenthesis: ) @65
                        declaredElement: GenericFunctionTypeElement
                          parameters
                            a
                              kind: optional positional
                              type: int?
                          returnType: String
                          type: String Function([int?])
                        type: String Function([int?])
                    rightBracket: > @66
                  element: <testLibraryFragment>::@class::A
                  element2: <testLibrary>::@class::A
                  type: A<String Function([int?])>
                staticElement: ConstructorMember
                  base: <testLibraryFragment>::@class::A::@constructor::new
                  substitution: {T: String Function([int?])}
                element: <testLibraryFragment>::@class::A::@constructor::new#element
              argumentList: ArgumentList
                leftParenthesis: ( @67
                rightParenthesis: ) @68
              staticType: A<String Function([int?])>
          getter2: <testLibraryFragment>::@getter::v
      getters
        synthetic get v
          reference: <testLibraryFragment>::@getter::v
          element: <testLibraryFragment>::@getter::v#element
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
      typeParameters
        T
      constructors
        const new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
  topLevelVariables
    const hasInitializer v
      reference: <testLibrary>::@topLevelVariable::v
      firstFragment: <testLibraryFragment>::@topLevelVariable::v
      type: A<String Function([int?])>
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::v
        expression: expression_0
      getter: <testLibraryFragment>::@getter::v#element
  getters
    synthetic static get v
      firstFragment: <testLibraryFragment>::@getter::v
''');
  }

  test_genericFunction_asTypeArgument_parameters_requiredNamed() async {
    var library = await buildLibrary(r'''
class A<T> {
  const A();
}

const v = A<String Function({required int a})>();
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          element: <testLibrary>::@class::A
          typeParameters
            T @8
              element: <not-implemented>
          constructors
            const new
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <testLibraryFragment>::@class::A::@constructor::new#element
              typeName: A
              typeNameOffset: 21
      topLevelVariables
        hasInitializer v @35
          reference: <testLibraryFragment>::@topLevelVariable::v
          element: <testLibrary>::@topLevelVariable::v
          initializer: expression_0
            InstanceCreationExpression
              constructorName: ConstructorName
                type: NamedType
                  name: A @39
                  typeArguments: TypeArgumentList
                    leftBracket: < @40
                    arguments
                      GenericFunctionType
                        returnType: NamedType
                          name: String @41
                          element: dart:core::<fragment>::@class::String
                          element2: dart:core::@class::String
                          type: String
                        functionKeyword: Function @48
                        parameters: FormalParameterList
                          leftParenthesis: ( @56
                          leftDelimiter: { @57
                          parameter: DefaultFormalParameter
                            parameter: SimpleFormalParameter
                              requiredKeyword: required @58
                              type: NamedType
                                name: int @67
                                element: dart:core::<fragment>::@class::int
                                element2: dart:core::@class::int
                                type: int
                              name: a @71
                              declaredElement: a@71
                                type: int
                            declaredElement: a@71
                              type: int
                          rightDelimiter: } @72
                          rightParenthesis: ) @73
                        declaredElement: GenericFunctionTypeElement
                          parameters
                            a
                              kind: required named
                              type: int
                          returnType: String
                          type: String Function({required int a})
                        type: String Function({required int a})
                    rightBracket: > @74
                  element: <testLibraryFragment>::@class::A
                  element2: <testLibrary>::@class::A
                  type: A<String Function({required int a})>
                staticElement: ConstructorMember
                  base: <testLibraryFragment>::@class::A::@constructor::new
                  substitution: {T: String Function({required int a})}
                element: <testLibraryFragment>::@class::A::@constructor::new#element
              argumentList: ArgumentList
                leftParenthesis: ( @75
                rightParenthesis: ) @76
              staticType: A<String Function({required int a})>
          getter2: <testLibraryFragment>::@getter::v
      getters
        synthetic get v
          reference: <testLibraryFragment>::@getter::v
          element: <testLibraryFragment>::@getter::v#element
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
      typeParameters
        T
      constructors
        const new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
  topLevelVariables
    const hasInitializer v
      reference: <testLibrary>::@topLevelVariable::v
      firstFragment: <testLibraryFragment>::@topLevelVariable::v
      type: A<String Function({required int a})>
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::v
        expression: expression_0
      getter: <testLibraryFragment>::@getter::v#element
  getters
    synthetic static get v
      firstFragment: <testLibraryFragment>::@getter::v
''');
  }

  test_genericFunction_asTypeArgument_parameters_requiredPositional() async {
    var library = await buildLibrary(r'''
class A<T> {
  const A();
}

const v = A<String Function(int a)>();
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          element: <testLibrary>::@class::A
          typeParameters
            T @8
              element: <not-implemented>
          constructors
            const new
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <testLibraryFragment>::@class::A::@constructor::new#element
              typeName: A
              typeNameOffset: 21
      topLevelVariables
        hasInitializer v @35
          reference: <testLibraryFragment>::@topLevelVariable::v
          element: <testLibrary>::@topLevelVariable::v
          initializer: expression_0
            InstanceCreationExpression
              constructorName: ConstructorName
                type: NamedType
                  name: A @39
                  typeArguments: TypeArgumentList
                    leftBracket: < @40
                    arguments
                      GenericFunctionType
                        returnType: NamedType
                          name: String @41
                          element: dart:core::<fragment>::@class::String
                          element2: dart:core::@class::String
                          type: String
                        functionKeyword: Function @48
                        parameters: FormalParameterList
                          leftParenthesis: ( @56
                          parameter: SimpleFormalParameter
                            type: NamedType
                              name: int @57
                              element: dart:core::<fragment>::@class::int
                              element2: dart:core::@class::int
                              type: int
                            name: a @61
                            declaredElement: a@61
                              type: int
                          rightParenthesis: ) @62
                        declaredElement: GenericFunctionTypeElement
                          parameters
                            a
                              kind: required positional
                              type: int
                          returnType: String
                          type: String Function(int)
                        type: String Function(int)
                    rightBracket: > @63
                  element: <testLibraryFragment>::@class::A
                  element2: <testLibrary>::@class::A
                  type: A<String Function(int)>
                staticElement: ConstructorMember
                  base: <testLibraryFragment>::@class::A::@constructor::new
                  substitution: {T: String Function(int)}
                element: <testLibraryFragment>::@class::A::@constructor::new#element
              argumentList: ArgumentList
                leftParenthesis: ( @64
                rightParenthesis: ) @65
              staticType: A<String Function(int)>
          getter2: <testLibraryFragment>::@getter::v
      getters
        synthetic get v
          reference: <testLibraryFragment>::@getter::v
          element: <testLibraryFragment>::@getter::v#element
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
      typeParameters
        T
      constructors
        const new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
  topLevelVariables
    const hasInitializer v
      reference: <testLibrary>::@topLevelVariable::v
      firstFragment: <testLibraryFragment>::@topLevelVariable::v
      type: A<String Function(int)>
      constantInitializer
        fragment: <testLibraryFragment>::@topLevelVariable::v
        expression: expression_0
      getter: <testLibraryFragment>::@getter::v#element
  getters
    synthetic static get v
      firstFragment: <testLibraryFragment>::@getter::v
''');
  }

  test_genericFunction_boundOf_typeParameter_ofMixin() async {
    var library = await buildLibrary(r'''
mixin B<X extends void Function()> {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      mixins
        mixin B @6
          reference: <testLibraryFragment>::@mixin::B
          element: <testLibrary>::@mixin::B
          typeParameters
            X @8
              element: <not-implemented>
  mixins
    mixin B
      reference: <testLibrary>::@mixin::B
      firstFragment: <testLibraryFragment>::@mixin::B
      typeParameters
        X
          bound: void Function()
      superclassConstraints
        Object
''');
  }

  test_genericFunction_typeArgument_ofSuperclass_ofClassAlias() async {
    var library = await buildLibrary(r'''
class A<T> {}
mixin M {}
class B = A<void Function()> with M;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          element: <testLibrary>::@class::A
          typeParameters
            T @8
              element: <not-implemented>
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <testLibraryFragment>::@class::A::@constructor::new#element
              typeName: A
        class B @31
          reference: <testLibraryFragment>::@class::B
          element: <testLibrary>::@class::B
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::B::@constructor::new
              element: <testLibraryFragment>::@class::B::@constructor::new#element
              typeName: B
      mixins
        mixin M @20
          reference: <testLibraryFragment>::@mixin::M
          element: <testLibrary>::@mixin::M
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
      typeParameters
        T
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
    class alias B
      reference: <testLibrary>::@class::B
      firstFragment: <testLibraryFragment>::@class::B
      supertype: A<void Function()>
      mixins
        M
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::B::@constructor::new
          constantInitializers
            SuperConstructorInvocation
              superKeyword: super @0
              argumentList: ArgumentList
                leftParenthesis: ( @0
                rightParenthesis: ) @0
              staticElement: <testLibraryFragment>::@class::A::@constructor::new
              element: <testLibraryFragment>::@class::A::@constructor::new#element
          superConstructor: <testLibraryFragment>::@class::A::@constructor::new#element
  mixins
    mixin M
      reference: <testLibrary>::@mixin::M
      firstFragment: <testLibraryFragment>::@mixin::M
      superclassConstraints
        Object
''');
  }

  test_genericFunction_typeParameter_asTypedefArgument() async {
    var library = await buildLibrary(r'''
typedef F1 = Function<V1>(F2<V1>);
typedef F2<V2> = V2 Function();
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        F1 @8
          reference: <testLibraryFragment>::@typeAlias::F1
          element: <testLibrary>::@typeAlias::F1
        F2 @43
          reference: <testLibraryFragment>::@typeAlias::F2
          element: <testLibrary>::@typeAlias::F2
          typeParameters
            V2 @46
              element: <not-implemented>
  typeAliases
    F1
      firstFragment: <testLibraryFragment>::@typeAlias::F1
      aliasedType: dynamic Function<V1>(V1 Function())
    F2
      firstFragment: <testLibraryFragment>::@typeAlias::F2
      typeParameters
        V2
      aliasedType: V2 Function()
''');
  }
}

@reflectiveTest
class FunctionTypeAnnotationElementTest_fromBytes
    extends FunctionTypeAnnotationElementTest {
  @override
  bool get keepLinkingLibraries => false;
}

@reflectiveTest
class FunctionTypeAnnotationElementTest_keepLinking
    extends FunctionTypeAnnotationElementTest {
  @override
  bool get keepLinkingLibraries => true;
}
