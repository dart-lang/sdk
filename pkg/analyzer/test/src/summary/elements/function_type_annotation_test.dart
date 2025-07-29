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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 f (nameOffset:16) (firstTokenOffset:16) (offset:16)
          element: <testLibrary>::@topLevelVariable::f
      getters
        #F2 synthetic f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
          element: <testLibrary>::@getter::f
      setters
        #F3 synthetic f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
          element: <testLibrary>::@setter::f
          formalParameters
            #F4 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@setter::f::@formalParameter::value
  topLevelVariables
    f
      reference: <testLibrary>::@topLevelVariable::f
      firstFragment: #F1
      type: void Function()
      getter: <testLibrary>::@getter::f
      setter: <testLibrary>::@setter::f
  getters
    synthetic static f
      reference: <testLibrary>::@getter::f
      firstFragment: #F2
      returnType: void Function()
      variable: <testLibrary>::@topLevelVariable::f
  setters
    synthetic static f
      reference: <testLibrary>::@setter::f
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F4
          type: void Function()
      returnType: void
      variable: <testLibrary>::@topLevelVariable::f
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 f (nameOffset:17) (firstTokenOffset:17) (offset:17)
          element: <testLibrary>::@topLevelVariable::f
      getters
        #F2 synthetic f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:17)
          element: <testLibrary>::@getter::f
      setters
        #F3 synthetic f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:17)
          element: <testLibrary>::@setter::f
          formalParameters
            #F4 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:17)
              element: <testLibrary>::@setter::f::@formalParameter::value
  topLevelVariables
    f
      reference: <testLibrary>::@topLevelVariable::f
      firstFragment: #F1
      type: void Function()?
      getter: <testLibrary>::@getter::f
      setter: <testLibrary>::@setter::f
  getters
    synthetic static f
      reference: <testLibrary>::@getter::f
      firstFragment: #F2
      returnType: void Function()?
      variable: <testLibrary>::@topLevelVariable::f
  setters
    synthetic static f
      reference: <testLibrary>::@setter::f
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F4
          type: void Function()?
      returnType: void
      variable: <testLibrary>::@topLevelVariable::f
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      functions
        #F1 f (nameOffset:30) (firstTokenOffset:0) (offset:30)
          element: <testLibrary>::@function::f
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: #F1
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      functions
        #F1 f (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@function::f
          formalParameters
            #F2 p (nameOffset:37) (firstTokenOffset:7) (offset:37)
              element: <testLibrary>::@function::f::@formalParameter::p
              parameters
                #F3 c (nameOffset:43) (firstTokenOffset:39) (offset:43)
                  element: c@43
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: #F1
      formalParameters
        #E0 requiredPositional p
          firstFragment: #F2
          type: int Function(int, String) Function(num)
          formalParameters
            #E1 requiredPositional c
              firstFragment: #F3
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        #F1 F (nameOffset:8) (firstTokenOffset:0) (offset:8)
          element: <testLibrary>::@typeAlias::F
  typeAliases
    F
      reference: <testLibrary>::@typeAlias::F
      firstFragment: #F1
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class C (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::C
          constructors
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          methods
            #F3 m (nameOffset:42) (firstTokenOffset:12) (offset:42)
              element: <testLibrary>::@class::C::@method::m
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
      methods
        m
          reference: <testLibrary>::@class::C::@method::m
          firstFragment: #F3
          returnType: int Function(int, String)
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      functions
        #F1 f (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@function::f
          formalParameters
            #F2 p (nameOffset:37) (firstTokenOffset:7) (offset:37)
              element: <testLibrary>::@function::f::@formalParameter::p
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: #F1
      formalParameters
        #E0 requiredPositional p
          firstFragment: #F2
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 v (nameOffset:30) (firstTokenOffset:30) (offset:30)
          element: <testLibrary>::@topLevelVariable::v
      getters
        #F2 synthetic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:30)
          element: <testLibrary>::@getter::v
      setters
        #F3 synthetic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:30)
          element: <testLibrary>::@setter::v
          formalParameters
            #F4 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:30)
              element: <testLibrary>::@setter::v::@formalParameter::value
  topLevelVariables
    v
      reference: <testLibrary>::@topLevelVariable::v
      firstFragment: #F1
      type: int Function(int, String)
      getter: <testLibrary>::@getter::v
      setter: <testLibrary>::@setter::v
  getters
    synthetic static v
      reference: <testLibrary>::@getter::v
      firstFragment: #F2
      returnType: int Function(int, String)
      variable: <testLibrary>::@topLevelVariable::v
  setters
    synthetic static v
      reference: <testLibrary>::@setter::v
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F4
          type: int Function(int, String)
      returnType: void
      variable: <testLibrary>::@topLevelVariable::v
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::A
          typeParameters
            #F2 T (nameOffset:8) (firstTokenOffset:8) (offset:8)
              element: #E0 T
          constructors
            #F3 const new (nameOffset:<null>) (firstTokenOffset:15) (offset:21)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
              typeNameOffset: 21
        #F4 class B (nameOffset:64) (firstTokenOffset:29) (offset:64)
          element: <testLibrary>::@class::B
          constructors
            #F5 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:64)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      constructors
        const new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F4
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F5
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::A
          typeParameters
            #F2 T (nameOffset:8) (firstTokenOffset:8) (offset:8)
              element: #E0 T
          constructors
            #F3 const new (nameOffset:<null>) (firstTokenOffset:15) (offset:21)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
              typeNameOffset: 21
      topLevelVariables
        #F4 hasInitializer v (nameOffset:62) (firstTokenOffset:62) (offset:62)
          element: <testLibrary>::@topLevelVariable::v
          metadata
            Annotation
              atSign: @ @29
              name: SimpleIdentifier
                token: A @30
                element: <testLibrary>::@class::A
                staticType: null
              typeArguments: TypeArgumentList
                leftBracket: < @31
                arguments
                  GenericFunctionType
                    returnType: NamedType
                      name: int @32
                      element2: dart:core::@class::int
                      type: int
                    functionKeyword: Function @36
                    parameters: FormalParameterList
                      leftParenthesis: ( @44
                      parameter: SimpleFormalParameter
                        type: NamedType
                          name: String @45
                          element2: dart:core::@class::String
                          type: String
                        name: a @52
                        declaredElement: <testLibraryFragment> a@52
                          element: isPublic
                            type: String
                      rightParenthesis: ) @53
                    declaredElement: GenericFunctionTypeElement
                      parameters
                        a
                          kind: required positional
                          element:
                            type: String
                      returnType: int
                      type: int Function(String)
                    type: int Function(String)
                rightBracket: > @54
              arguments: ArgumentList
                leftParenthesis: ( @55
                rightParenthesis: ) @56
              element2: ConstructorMember
                baseElement: <testLibrary>::@class::A::@constructor::new
                substitution: {T: int Function(String)}
      getters
        #F5 synthetic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:62)
          element: <testLibrary>::@getter::v
      setters
        #F6 synthetic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:62)
          element: <testLibrary>::@setter::v
          formalParameters
            #F7 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:62)
              element: <testLibrary>::@setter::v::@formalParameter::value
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      constructors
        const new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
  topLevelVariables
    hasInitializer v
      reference: <testLibrary>::@topLevelVariable::v
      firstFragment: #F4
      metadata
        Annotation
          atSign: @ @29
          name: SimpleIdentifier
            token: A @30
            element: <testLibrary>::@class::A
            staticType: null
          typeArguments: TypeArgumentList
            leftBracket: < @31
            arguments
              GenericFunctionType
                returnType: NamedType
                  name: int @32
                  element2: dart:core::@class::int
                  type: int
                functionKeyword: Function @36
                parameters: FormalParameterList
                  leftParenthesis: ( @44
                  parameter: SimpleFormalParameter
                    type: NamedType
                      name: String @45
                      element2: dart:core::@class::String
                      type: String
                    name: a @52
                    declaredElement: <testLibraryFragment> a@52
                      element: isPublic
                        type: String
                  rightParenthesis: ) @53
                declaredElement: GenericFunctionTypeElement
                  parameters
                    a
                      kind: required positional
                      element:
                        type: String
                  returnType: int
                  type: int Function(String)
                type: int Function(String)
            rightBracket: > @54
          arguments: ArgumentList
            leftParenthesis: ( @55
            rightParenthesis: ) @56
          element2: ConstructorMember
            baseElement: <testLibrary>::@class::A::@constructor::new
            substitution: {T: int Function(String)}
      type: int
      getter: <testLibrary>::@getter::v
      setter: <testLibrary>::@setter::v
  getters
    synthetic static v
      reference: <testLibrary>::@getter::v
      firstFragment: #F5
      returnType: int
      variable: <testLibrary>::@topLevelVariable::v
  setters
    synthetic static v
      reference: <testLibrary>::@setter::v
      firstFragment: #F6
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F7
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::v
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::A
          typeParameters
            #F2 T (nameOffset:8) (firstTokenOffset:8) (offset:8)
              element: #E0 T
          constructors
            #F3 const new (nameOffset:<null>) (firstTokenOffset:15) (offset:21)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
              typeNameOffset: 21
      topLevelVariables
        #F4 hasInitializer v (nameOffset:35) (firstTokenOffset:35) (offset:35)
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
                                element2: dart:core::@class::int
                                type: int?
                              name: a @63
                              declaredElement: <testLibraryFragment> a@63
                                element: isPublic
                                  type: int?
                            declaredElement: <testLibraryFragment> a@63
                              element: isPublic
                                type: int?
                          rightDelimiter: } @64
                          rightParenthesis: ) @65
                        declaredElement: GenericFunctionTypeElement
                          parameters
                            a
                              kind: optional named
                              element:
                                type: int?
                          returnType: String
                          type: String Function({int? a})
                        type: String Function({int? a})
                    rightBracket: > @66
                  element2: <testLibrary>::@class::A
                  type: A<String Function({int? a})>
                element: ConstructorMember
                  baseElement: <testLibrary>::@class::A::@constructor::new
                  substitution: {T: String Function({int? a})}
              argumentList: ArgumentList
                leftParenthesis: ( @67
                rightParenthesis: ) @68
              staticType: A<String Function({int? a})>
      getters
        #F5 synthetic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:35)
          element: <testLibrary>::@getter::v
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      constructors
        const new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
  topLevelVariables
    const hasInitializer v
      reference: <testLibrary>::@topLevelVariable::v
      firstFragment: #F4
      type: A<String Function({int? a})>
      constantInitializer
        fragment: #F4
        expression: expression_0
      getter: <testLibrary>::@getter::v
  getters
    synthetic static v
      reference: <testLibrary>::@getter::v
      firstFragment: #F5
      returnType: A<String Function({int? a})>
      variable: <testLibrary>::@topLevelVariable::v
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::A
          typeParameters
            #F2 T (nameOffset:8) (firstTokenOffset:8) (offset:8)
              element: #E0 T
          constructors
            #F3 const new (nameOffset:<null>) (firstTokenOffset:15) (offset:21)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
              typeNameOffset: 21
      topLevelVariables
        #F4 hasInitializer v (nameOffset:35) (firstTokenOffset:35) (offset:35)
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
                                element2: dart:core::@class::int
                                type: int?
                              name: a @63
                              declaredElement: <testLibraryFragment> a@63
                                element: isPublic
                                  type: int?
                            declaredElement: <testLibraryFragment> a@63
                              element: isPublic
                                type: int?
                          rightDelimiter: ] @64
                          rightParenthesis: ) @65
                        declaredElement: GenericFunctionTypeElement
                          parameters
                            a
                              kind: optional positional
                              element:
                                type: int?
                          returnType: String
                          type: String Function([int?])
                        type: String Function([int?])
                    rightBracket: > @66
                  element2: <testLibrary>::@class::A
                  type: A<String Function([int?])>
                element: ConstructorMember
                  baseElement: <testLibrary>::@class::A::@constructor::new
                  substitution: {T: String Function([int?])}
              argumentList: ArgumentList
                leftParenthesis: ( @67
                rightParenthesis: ) @68
              staticType: A<String Function([int?])>
      getters
        #F5 synthetic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:35)
          element: <testLibrary>::@getter::v
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      constructors
        const new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
  topLevelVariables
    const hasInitializer v
      reference: <testLibrary>::@topLevelVariable::v
      firstFragment: #F4
      type: A<String Function([int?])>
      constantInitializer
        fragment: #F4
        expression: expression_0
      getter: <testLibrary>::@getter::v
  getters
    synthetic static v
      reference: <testLibrary>::@getter::v
      firstFragment: #F5
      returnType: A<String Function([int?])>
      variable: <testLibrary>::@topLevelVariable::v
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::A
          typeParameters
            #F2 T (nameOffset:8) (firstTokenOffset:8) (offset:8)
              element: #E0 T
          constructors
            #F3 const new (nameOffset:<null>) (firstTokenOffset:15) (offset:21)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
              typeNameOffset: 21
      topLevelVariables
        #F4 hasInitializer v (nameOffset:35) (firstTokenOffset:35) (offset:35)
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
                                element2: dart:core::@class::int
                                type: int
                              name: a @71
                              declaredElement: <testLibraryFragment> a@71
                                element: isPublic
                                  type: int
                            declaredElement: <testLibraryFragment> a@71
                              element: isPublic
                                type: int
                          rightDelimiter: } @72
                          rightParenthesis: ) @73
                        declaredElement: GenericFunctionTypeElement
                          parameters
                            a
                              kind: required named
                              element:
                                type: int
                          returnType: String
                          type: String Function({required int a})
                        type: String Function({required int a})
                    rightBracket: > @74
                  element2: <testLibrary>::@class::A
                  type: A<String Function({required int a})>
                element: ConstructorMember
                  baseElement: <testLibrary>::@class::A::@constructor::new
                  substitution: {T: String Function({required int a})}
              argumentList: ArgumentList
                leftParenthesis: ( @75
                rightParenthesis: ) @76
              staticType: A<String Function({required int a})>
      getters
        #F5 synthetic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:35)
          element: <testLibrary>::@getter::v
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      constructors
        const new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
  topLevelVariables
    const hasInitializer v
      reference: <testLibrary>::@topLevelVariable::v
      firstFragment: #F4
      type: A<String Function({required int a})>
      constantInitializer
        fragment: #F4
        expression: expression_0
      getter: <testLibrary>::@getter::v
  getters
    synthetic static v
      reference: <testLibrary>::@getter::v
      firstFragment: #F5
      returnType: A<String Function({required int a})>
      variable: <testLibrary>::@topLevelVariable::v
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::A
          typeParameters
            #F2 T (nameOffset:8) (firstTokenOffset:8) (offset:8)
              element: #E0 T
          constructors
            #F3 const new (nameOffset:<null>) (firstTokenOffset:15) (offset:21)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
              typeNameOffset: 21
      topLevelVariables
        #F4 hasInitializer v (nameOffset:35) (firstTokenOffset:35) (offset:35)
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
                          element2: dart:core::@class::String
                          type: String
                        functionKeyword: Function @48
                        parameters: FormalParameterList
                          leftParenthesis: ( @56
                          parameter: SimpleFormalParameter
                            type: NamedType
                              name: int @57
                              element2: dart:core::@class::int
                              type: int
                            name: a @61
                            declaredElement: <testLibraryFragment> a@61
                              element: isPublic
                                type: int
                          rightParenthesis: ) @62
                        declaredElement: GenericFunctionTypeElement
                          parameters
                            a
                              kind: required positional
                              element:
                                type: int
                          returnType: String
                          type: String Function(int)
                        type: String Function(int)
                    rightBracket: > @63
                  element2: <testLibrary>::@class::A
                  type: A<String Function(int)>
                element: ConstructorMember
                  baseElement: <testLibrary>::@class::A::@constructor::new
                  substitution: {T: String Function(int)}
              argumentList: ArgumentList
                leftParenthesis: ( @64
                rightParenthesis: ) @65
              staticType: A<String Function(int)>
      getters
        #F5 synthetic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:35)
          element: <testLibrary>::@getter::v
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      constructors
        const new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
  topLevelVariables
    const hasInitializer v
      reference: <testLibrary>::@topLevelVariable::v
      firstFragment: #F4
      type: A<String Function(int)>
      constantInitializer
        fragment: #F4
        expression: expression_0
      getter: <testLibrary>::@getter::v
  getters
    synthetic static v
      reference: <testLibrary>::@getter::v
      firstFragment: #F5
      returnType: A<String Function(int)>
      variable: <testLibrary>::@topLevelVariable::v
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      mixins
        #F1 mixin B (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@mixin::B
          typeParameters
            #F2 X (nameOffset:8) (firstTokenOffset:8) (offset:8)
              element: #E0 X
  mixins
    mixin B
      reference: <testLibrary>::@mixin::B
      firstFragment: #F1
      typeParameters
        #E0 X
          firstFragment: #F2
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class A (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::A
          typeParameters
            #F2 T (nameOffset:8) (firstTokenOffset:8) (offset:8)
              element: #E0 T
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
        #F4 class B (nameOffset:31) (firstTokenOffset:25) (offset:31)
          element: <testLibrary>::@class::B
          constructors
            #F5 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
      mixins
        #F6 mixin M (nameOffset:20) (firstTokenOffset:14) (offset:20)
          element: <testLibrary>::@mixin::M
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
    class alias B
      reference: <testLibrary>::@class::B
      firstFragment: #F4
      supertype: A<void Function()>
      mixins
        M
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F5
          constantInitializers
            SuperConstructorInvocation
              superKeyword: super @0
              argumentList: ArgumentList
                leftParenthesis: ( @0
                rightParenthesis: ) @0
              element: <testLibrary>::@class::A::@constructor::new
          superConstructor: ConstructorMember
            baseElement: <testLibrary>::@class::A::@constructor::new
            substitution: {T: void Function()}
  mixins
    mixin M
      reference: <testLibrary>::@mixin::M
      firstFragment: #F6
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
    #F0 <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        #F1 F1 (nameOffset:8) (firstTokenOffset:0) (offset:8)
          element: <testLibrary>::@typeAlias::F1
        #F2 F2 (nameOffset:43) (firstTokenOffset:35) (offset:43)
          element: <testLibrary>::@typeAlias::F2
          typeParameters
            #F3 V2 (nameOffset:46) (firstTokenOffset:46) (offset:46)
              element: #E0 V2
  typeAliases
    F1
      reference: <testLibrary>::@typeAlias::F1
      firstFragment: #F1
      aliasedType: dynamic Function<V1>(V1 Function())
    F2
      reference: <testLibrary>::@typeAlias::F2
      firstFragment: #F2
      typeParameters
        #E0 V2
          firstFragment: #F3
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
