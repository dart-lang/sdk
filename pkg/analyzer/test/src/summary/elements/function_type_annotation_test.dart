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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      topLevelVariables
        static f @16
          reference: <testLibraryFragment>::@topLevelVariable::f
          enclosingElement: <testLibraryFragment>
          type: void Function()
      accessors
        synthetic static get f @-1
          reference: <testLibraryFragment>::@getter::f
          enclosingElement: <testLibraryFragment>
          returnType: void Function()
        synthetic static set f= @-1
          reference: <testLibraryFragment>::@setter::f
          enclosingElement: <testLibraryFragment>
          parameters
            requiredPositional _f @-1
              type: void Function()
          returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        f @16
          reference: <testLibraryFragment>::@topLevelVariable::f
          element: <none>
          getter2: <testLibraryFragment>::@getter::f
          setter2: <testLibraryFragment>::@setter::f
      getters
        get f @-1
          reference: <testLibraryFragment>::@getter::f
          element: <none>
      setters
        set f= @-1
          reference: <testLibraryFragment>::@setter::f
          element: <none>
          parameters
            _f @-1
              element: <none>
  topLevelVariables
    f
      reference: <none>
      type: void Function()
      firstFragment: <testLibraryFragment>::@topLevelVariable::f
      getter: <none>
      setter: <none>
  getters
    synthetic static get f
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::f
  setters
    synthetic static set f=
      reference: <none>
      parameters
        requiredPositional _f
          reference: <none>
          type: void Function()
      firstFragment: <testLibraryFragment>::@setter::f
''');
  }

  test_generic_function_type_nullability_question() async {
    var library = await buildLibrary('''
void Function()? f;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      topLevelVariables
        static f @17
          reference: <testLibraryFragment>::@topLevelVariable::f
          enclosingElement: <testLibraryFragment>
          type: void Function()?
      accessors
        synthetic static get f @-1
          reference: <testLibraryFragment>::@getter::f
          enclosingElement: <testLibraryFragment>
          returnType: void Function()?
        synthetic static set f= @-1
          reference: <testLibraryFragment>::@setter::f
          enclosingElement: <testLibraryFragment>
          parameters
            requiredPositional _f @-1
              type: void Function()?
          returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        f @17
          reference: <testLibraryFragment>::@topLevelVariable::f
          element: <none>
          getter2: <testLibraryFragment>::@getter::f
          setter2: <testLibraryFragment>::@setter::f
      getters
        get f @-1
          reference: <testLibraryFragment>::@getter::f
          element: <none>
      setters
        set f= @-1
          reference: <testLibraryFragment>::@setter::f
          element: <none>
          parameters
            _f @-1
              element: <none>
  topLevelVariables
    f
      reference: <none>
      type: void Function()?
      firstFragment: <testLibraryFragment>::@topLevelVariable::f
      getter: <none>
      setter: <none>
  getters
    synthetic static get f
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::f
  setters
    synthetic static set f=
      reference: <none>
      parameters
        requiredPositional _f
          reference: <none>
          type: void Function()?
      firstFragment: <testLibraryFragment>::@setter::f
''');
  }

  test_genericFunction_asFunctionReturnType() async {
    var library = await buildLibrary(r'''
int Function(int a, String b) f() => null;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      functions
        f @30
          reference: <testLibraryFragment>::@function::f
          enclosingElement: <testLibraryFragment>
          returnType: int Function(int, String)
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      functions
        f @30
          reference: <testLibraryFragment>::@function::f
          element: <none>
  functions
    f
      reference: <none>
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      functions
        f @5
          reference: <testLibraryFragment>::@function::f
          enclosingElement: <testLibraryFragment>
          parameters
            requiredPositional p @37
              type: int Function(int, String) Function(num)
              parameters
                requiredPositional c @43
                  type: num
          returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      functions
        f @5
          reference: <testLibraryFragment>::@function::f
          element: <none>
          parameters
            p @37
              element: <none>
  functions
    f
      reference: <none>
      parameters
        requiredPositional p
          reference: <none>
          type: int Function(int, String) Function(num)
          parameters
            requiredPositional c
              reference: <none>
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      typeAliases
        F @8
          reference: <testLibraryFragment>::@typeAlias::F
          aliasedType: void Function(String) Function(int)
          aliasedElement: GenericFunctionTypeElement
            parameters
              requiredPositional b @49
                type: int
            returnType: void Function(String)
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        F @8
          reference: <testLibraryFragment>::@typeAlias::F
          element: <none>
  typeAliases
    F
      reference: <none>
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          enclosingElement: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::C
          methods
            m @42
              reference: <testLibraryFragment>::@class::C::@method::m
              enclosingElement: <testLibraryFragment>::@class::C
              returnType: int Function(int, String)
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <none>
          methods
            m @42
              reference: <testLibraryFragment>::@class::C::@method::m
              element: <none>
  classes
    class C
      reference: <testLibraryFragment>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      methods
        m
          reference: <none>
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      functions
        f @5
          reference: <testLibraryFragment>::@function::f
          enclosingElement: <testLibraryFragment>
          parameters
            requiredPositional p @37
              type: int Function(int, String)
          returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      functions
        f @5
          reference: <testLibraryFragment>::@function::f
          element: <none>
          parameters
            p @37
              element: <none>
  functions
    f
      reference: <none>
      parameters
        requiredPositional p
          reference: <none>
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      topLevelVariables
        static v @30
          reference: <testLibraryFragment>::@topLevelVariable::v
          enclosingElement: <testLibraryFragment>
          type: int Function(int, String)
      accessors
        synthetic static get v @-1
          reference: <testLibraryFragment>::@getter::v
          enclosingElement: <testLibraryFragment>
          returnType: int Function(int, String)
        synthetic static set v= @-1
          reference: <testLibraryFragment>::@setter::v
          enclosingElement: <testLibraryFragment>
          parameters
            requiredPositional _v @-1
              type: int Function(int, String)
          returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        v @30
          reference: <testLibraryFragment>::@topLevelVariable::v
          element: <none>
          getter2: <testLibraryFragment>::@getter::v
          setter2: <testLibraryFragment>::@setter::v
      getters
        get v @-1
          reference: <testLibraryFragment>::@getter::v
          element: <none>
      setters
        set v= @-1
          reference: <testLibraryFragment>::@setter::v
          element: <none>
          parameters
            _v @-1
              element: <none>
  topLevelVariables
    v
      reference: <none>
      type: int Function(int, String)
      firstFragment: <testLibraryFragment>::@topLevelVariable::v
      getter: <none>
      setter: <none>
  getters
    synthetic static get v
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::v
  setters
    synthetic static set v=
      reference: <none>
      parameters
        requiredPositional _v
          reference: <none>
          type: int Function(int, String)
      firstFragment: <testLibraryFragment>::@setter::v
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T @8
              defaultType: dynamic
          constructors
            const @21
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::A
        class B @64
          reference: <testLibraryFragment>::@class::B
          enclosingElement: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @29
              name: SimpleIdentifier
                token: A @30
                staticElement: <testLibraryFragment>::@class::A
                staticType: null
              typeArguments: TypeArgumentList
                leftBracket: < @31
                arguments
                  GenericFunctionType
                    returnType: NamedType
                      name: int @32
                      element: dart:core::<fragment>::@class::int
                      type: int
                    functionKeyword: Function @36
                    parameters: FormalParameterList
                      leftParenthesis: ( @44
                      parameter: SimpleFormalParameter
                        type: NamedType
                          name: String @45
                          element: dart:core::<fragment>::@class::String
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
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::B::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::B
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
          typeParameters
            T @8
              element: <none>
          constructors
            const new @21
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <none>
        class B @64
          reference: <testLibraryFragment>::@class::B
          element: <testLibraryFragment>::@class::B
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::B::@constructor::new
              element: <none>
  classes
    class A
      reference: <testLibraryFragment>::@class::A
      typeParameters
        T
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        const new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
    class B
      reference: <testLibraryFragment>::@class::B
      firstFragment: <testLibraryFragment>::@class::B
      constructors
        synthetic new
          reference: <none>
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T @8
              defaultType: dynamic
          constructors
            const @21
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::A
      topLevelVariables
        static v @62
          reference: <testLibraryFragment>::@topLevelVariable::v
          enclosingElement: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @29
              name: SimpleIdentifier
                token: A @30
                staticElement: <testLibraryFragment>::@class::A
                staticType: null
              typeArguments: TypeArgumentList
                leftBracket: < @31
                arguments
                  GenericFunctionType
                    returnType: NamedType
                      name: int @32
                      element: dart:core::<fragment>::@class::int
                      type: int
                    functionKeyword: Function @36
                    parameters: FormalParameterList
                      leftParenthesis: ( @44
                      parameter: SimpleFormalParameter
                        type: NamedType
                          name: String @45
                          element: dart:core::<fragment>::@class::String
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
          type: int
          shouldUseTypeForInitializerInference: false
      accessors
        synthetic static get v @-1
          reference: <testLibraryFragment>::@getter::v
          enclosingElement: <testLibraryFragment>
          returnType: int
        synthetic static set v= @-1
          reference: <testLibraryFragment>::@setter::v
          enclosingElement: <testLibraryFragment>
          parameters
            requiredPositional _v @-1
              type: int
          returnType: void
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
          typeParameters
            T @8
              element: <none>
          constructors
            const new @21
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <none>
      topLevelVariables
        v @62
          reference: <testLibraryFragment>::@topLevelVariable::v
          element: <none>
          metadata
            Annotation
              atSign: @ @29
              name: SimpleIdentifier
                token: A @30
                staticElement: <testLibraryFragment>::@class::A
                staticType: null
              typeArguments: TypeArgumentList
                leftBracket: < @31
                arguments
                  GenericFunctionType
                    returnType: NamedType
                      name: int @32
                      element: dart:core::<fragment>::@class::int
                      type: int
                    functionKeyword: Function @36
                    parameters: FormalParameterList
                      leftParenthesis: ( @44
                      parameter: SimpleFormalParameter
                        type: NamedType
                          name: String @45
                          element: dart:core::<fragment>::@class::String
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
          getter2: <testLibraryFragment>::@getter::v
          setter2: <testLibraryFragment>::@setter::v
      getters
        get v @-1
          reference: <testLibraryFragment>::@getter::v
          element: <none>
      setters
        set v= @-1
          reference: <testLibraryFragment>::@setter::v
          element: <none>
          parameters
            _v @-1
              element: <none>
  classes
    class A
      reference: <testLibraryFragment>::@class::A
      typeParameters
        T
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        const new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
  topLevelVariables
    v
      reference: <none>
      type: int
      firstFragment: <testLibraryFragment>::@topLevelVariable::v
      getter: <none>
      setter: <none>
  getters
    synthetic static get v
      reference: <none>
      firstFragment: <testLibraryFragment>::@getter::v
  setters
    synthetic static set v=
      reference: <none>
      parameters
        requiredPositional _v
          reference: <none>
          type: int
      firstFragment: <testLibraryFragment>::@setter::v
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T @8
              defaultType: dynamic
          constructors
            const @21
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::A
      topLevelVariables
        static const v @35
          reference: <testLibraryFragment>::@topLevelVariable::v
          enclosingElement: <testLibraryFragment>
          type: A<String Function({int? a})>
          shouldUseTypeForInitializerInference: false
          constantInitializer
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
                  type: A<String Function({int? a})>
                staticElement: ConstructorMember
                  base: <testLibraryFragment>::@class::A::@constructor::new
                  substitution: {T: String Function({int? a})}
              argumentList: ArgumentList
                leftParenthesis: ( @67
                rightParenthesis: ) @68
              staticType: A<String Function({int? a})>
      accessors
        synthetic static get v @-1
          reference: <testLibraryFragment>::@getter::v
          enclosingElement: <testLibraryFragment>
          returnType: A<String Function({int? a})>
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
          typeParameters
            T @8
              element: <none>
          constructors
            const new @21
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <none>
      topLevelVariables
        const v @35
          reference: <testLibraryFragment>::@topLevelVariable::v
          element: <none>
          getter2: <testLibraryFragment>::@getter::v
      getters
        get v @-1
          reference: <testLibraryFragment>::@getter::v
          element: <none>
  classes
    class A
      reference: <testLibraryFragment>::@class::A
      typeParameters
        T
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        const new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
  topLevelVariables
    const v
      reference: <none>
      type: A<String Function({int? a})>
      firstFragment: <testLibraryFragment>::@topLevelVariable::v
      getter: <none>
  getters
    synthetic static get v
      reference: <none>
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T @8
              defaultType: dynamic
          constructors
            const @21
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::A
      topLevelVariables
        static const v @35
          reference: <testLibraryFragment>::@topLevelVariable::v
          enclosingElement: <testLibraryFragment>
          type: A<String Function([int?])>
          shouldUseTypeForInitializerInference: false
          constantInitializer
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
                  type: A<String Function([int?])>
                staticElement: ConstructorMember
                  base: <testLibraryFragment>::@class::A::@constructor::new
                  substitution: {T: String Function([int?])}
              argumentList: ArgumentList
                leftParenthesis: ( @67
                rightParenthesis: ) @68
              staticType: A<String Function([int?])>
      accessors
        synthetic static get v @-1
          reference: <testLibraryFragment>::@getter::v
          enclosingElement: <testLibraryFragment>
          returnType: A<String Function([int?])>
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
          typeParameters
            T @8
              element: <none>
          constructors
            const new @21
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <none>
      topLevelVariables
        const v @35
          reference: <testLibraryFragment>::@topLevelVariable::v
          element: <none>
          getter2: <testLibraryFragment>::@getter::v
      getters
        get v @-1
          reference: <testLibraryFragment>::@getter::v
          element: <none>
  classes
    class A
      reference: <testLibraryFragment>::@class::A
      typeParameters
        T
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        const new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
  topLevelVariables
    const v
      reference: <none>
      type: A<String Function([int?])>
      firstFragment: <testLibraryFragment>::@topLevelVariable::v
      getter: <none>
  getters
    synthetic static get v
      reference: <none>
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T @8
              defaultType: dynamic
          constructors
            const @21
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::A
      topLevelVariables
        static const v @35
          reference: <testLibraryFragment>::@topLevelVariable::v
          enclosingElement: <testLibraryFragment>
          type: A<String Function({required int a})>
          shouldUseTypeForInitializerInference: false
          constantInitializer
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
                  type: A<String Function({required int a})>
                staticElement: ConstructorMember
                  base: <testLibraryFragment>::@class::A::@constructor::new
                  substitution: {T: String Function({required int a})}
              argumentList: ArgumentList
                leftParenthesis: ( @75
                rightParenthesis: ) @76
              staticType: A<String Function({required int a})>
      accessors
        synthetic static get v @-1
          reference: <testLibraryFragment>::@getter::v
          enclosingElement: <testLibraryFragment>
          returnType: A<String Function({required int a})>
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
          typeParameters
            T @8
              element: <none>
          constructors
            const new @21
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <none>
      topLevelVariables
        const v @35
          reference: <testLibraryFragment>::@topLevelVariable::v
          element: <none>
          getter2: <testLibraryFragment>::@getter::v
      getters
        get v @-1
          reference: <testLibraryFragment>::@getter::v
          element: <none>
  classes
    class A
      reference: <testLibraryFragment>::@class::A
      typeParameters
        T
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        const new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
  topLevelVariables
    const v
      reference: <none>
      type: A<String Function({required int a})>
      firstFragment: <testLibraryFragment>::@topLevelVariable::v
      getter: <none>
  getters
    synthetic static get v
      reference: <none>
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T @8
              defaultType: dynamic
          constructors
            const @21
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::A
      topLevelVariables
        static const v @35
          reference: <testLibraryFragment>::@topLevelVariable::v
          enclosingElement: <testLibraryFragment>
          type: A<String Function(int)>
          shouldUseTypeForInitializerInference: false
          constantInitializer
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
                          type: String
                        functionKeyword: Function @48
                        parameters: FormalParameterList
                          leftParenthesis: ( @56
                          parameter: SimpleFormalParameter
                            type: NamedType
                              name: int @57
                              element: dart:core::<fragment>::@class::int
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
                  type: A<String Function(int)>
                staticElement: ConstructorMember
                  base: <testLibraryFragment>::@class::A::@constructor::new
                  substitution: {T: String Function(int)}
              argumentList: ArgumentList
                leftParenthesis: ( @64
                rightParenthesis: ) @65
              staticType: A<String Function(int)>
      accessors
        synthetic static get v @-1
          reference: <testLibraryFragment>::@getter::v
          enclosingElement: <testLibraryFragment>
          returnType: A<String Function(int)>
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
          typeParameters
            T @8
              element: <none>
          constructors
            const new @21
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <none>
      topLevelVariables
        const v @35
          reference: <testLibraryFragment>::@topLevelVariable::v
          element: <none>
          getter2: <testLibraryFragment>::@getter::v
      getters
        get v @-1
          reference: <testLibraryFragment>::@getter::v
          element: <none>
  classes
    class A
      reference: <testLibraryFragment>::@class::A
      typeParameters
        T
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        const new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
  topLevelVariables
    const v
      reference: <none>
      type: A<String Function(int)>
      firstFragment: <testLibraryFragment>::@topLevelVariable::v
      getter: <none>
  getters
    synthetic static get v
      reference: <none>
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      mixins
        mixin B @6
          reference: <testLibraryFragment>::@mixin::B
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant X @8
              bound: void Function()
              defaultType: void Function()
          superclassConstraints
            Object
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      mixins
        mixin B @6
          reference: <testLibraryFragment>::@mixin::B
          element: <testLibraryFragment>::@mixin::B
          typeParameters
            X @8
              element: <none>
  mixins
    mixin B
      reference: <testLibraryFragment>::@mixin::B
      typeParameters
        X
          bound: void Function()
      firstFragment: <testLibraryFragment>::@mixin::B
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          enclosingElement: <testLibraryFragment>
          typeParameters
            covariant T @8
              defaultType: dynamic
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::A
        class alias B @31
          reference: <testLibraryFragment>::@class::B
          enclosingElement: <testLibraryFragment>
          supertype: A<void Function()>
          mixins
            M
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::B::@constructor::new
              enclosingElement: <testLibraryFragment>::@class::B
              constantInitializers
                SuperConstructorInvocation
                  superKeyword: super @0
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticElement: <testLibraryFragment>::@class::A::@constructor::new
              superConstructor: ConstructorMember
                base: <testLibraryFragment>::@class::A::@constructor::new
                substitution: {T: void Function()}
      mixins
        mixin M @20
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
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A
          typeParameters
            T @8
              element: <none>
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <none>
        class B @31
          reference: <testLibraryFragment>::@class::B
          element: <testLibraryFragment>::@class::B
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::B::@constructor::new
              element: <none>
              constantInitializers
                SuperConstructorInvocation
                  superKeyword: super @0
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticElement: <testLibraryFragment>::@class::A::@constructor::new
              superConstructor: ConstructorMember
                base: <testLibraryFragment>::@class::A::@constructor::new
                substitution: {T: void Function()}
      mixins
        mixin M @20
          reference: <testLibraryFragment>::@mixin::M
          element: <testLibraryFragment>::@mixin::M
  classes
    class A
      reference: <testLibraryFragment>::@class::A
      typeParameters
        T
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        synthetic new
          reference: <none>
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
    class alias B
      reference: <testLibraryFragment>::@class::B
      firstFragment: <testLibraryFragment>::@class::B
      supertype: A<void Function()>
      constructors
        synthetic new
          reference: <none>
          superConstructor: <none>
          firstFragment: <testLibraryFragment>::@class::B::@constructor::new
  mixins
    mixin M
      reference: <testLibraryFragment>::@mixin::M
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      typeAliases
        F1 @8
          reference: <testLibraryFragment>::@typeAlias::F1
          aliasedType: dynamic Function<V1>(V1 Function())
          aliasedElement: GenericFunctionTypeElement
            typeParameters
              covariant V1 @22
            parameters
              requiredPositional @-1
                type: V1 Function()
                  alias: <testLibraryFragment>::@typeAlias::F2
                    typeArguments
                      V1
            returnType: dynamic
        F2 @43
          reference: <testLibraryFragment>::@typeAlias::F2
          typeParameters
            covariant V2 @46
              defaultType: dynamic
          aliasedType: V2 Function()
          aliasedElement: GenericFunctionTypeElement
            returnType: V2
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        F1 @8
          reference: <testLibraryFragment>::@typeAlias::F1
          element: <none>
        F2 @43
          reference: <testLibraryFragment>::@typeAlias::F2
          element: <none>
          typeParameters
            V2 @46
              element: <none>
  typeAliases
    F1
      reference: <none>
      aliasedType: dynamic Function<V1>(V1 Function())
    F2
      reference: <none>
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
