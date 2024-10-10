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
      enclosingElement3: <null>
      topLevelVariables
        static f @16
          reference: <testLibraryFragment>::@topLevelVariable::f
          enclosingElement3: <testLibraryFragment>
          type: void Function()
      accessors
        synthetic static get f @-1
          reference: <testLibraryFragment>::@getter::f
          enclosingElement3: <testLibraryFragment>
          returnType: void Function()
        synthetic static set f= @-1
          reference: <testLibraryFragment>::@setter::f
          enclosingElement3: <testLibraryFragment>
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
          element: <testLibraryFragment>::@topLevelVariable::f#element
          getter2: <testLibraryFragment>::@getter::f
          setter2: <testLibraryFragment>::@setter::f
      getters
        get f @-1
          reference: <testLibraryFragment>::@getter::f
          element: <testLibraryFragment>::@getter::f#element
      setters
        set f= @-1
          reference: <testLibraryFragment>::@setter::f
          element: <testLibraryFragment>::@setter::f#element
          formalParameters
            _f @-1
              element: <testLibraryFragment>::@setter::f::@parameter::_f#element
  topLevelVariables
    f
      firstFragment: <testLibraryFragment>::@topLevelVariable::f
      type: void Function()
      getter: <testLibraryFragment>::@getter::f#element
      setter: <testLibraryFragment>::@setter::f#element
  getters
    synthetic static get f
      firstFragment: <testLibraryFragment>::@getter::f
  setters
    synthetic static set f=
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        static f @17
          reference: <testLibraryFragment>::@topLevelVariable::f
          enclosingElement3: <testLibraryFragment>
          type: void Function()?
      accessors
        synthetic static get f @-1
          reference: <testLibraryFragment>::@getter::f
          enclosingElement3: <testLibraryFragment>
          returnType: void Function()?
        synthetic static set f= @-1
          reference: <testLibraryFragment>::@setter::f
          enclosingElement3: <testLibraryFragment>
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
          element: <testLibraryFragment>::@topLevelVariable::f#element
          getter2: <testLibraryFragment>::@getter::f
          setter2: <testLibraryFragment>::@setter::f
      getters
        get f @-1
          reference: <testLibraryFragment>::@getter::f
          element: <testLibraryFragment>::@getter::f#element
      setters
        set f= @-1
          reference: <testLibraryFragment>::@setter::f
          element: <testLibraryFragment>::@setter::f#element
          formalParameters
            _f @-1
              element: <testLibraryFragment>::@setter::f::@parameter::_f#element
  topLevelVariables
    f
      firstFragment: <testLibraryFragment>::@topLevelVariable::f
      type: void Function()?
      getter: <testLibraryFragment>::@getter::f#element
      setter: <testLibraryFragment>::@setter::f#element
  getters
    synthetic static get f
      firstFragment: <testLibraryFragment>::@getter::f
  setters
    synthetic static set f=
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      functions
        f @30
          reference: <testLibraryFragment>::@function::f
          enclosingElement3: <testLibraryFragment>
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
          element: <testLibraryFragment>::@function::f#element
  functions
    f
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      functions
        f @5
          reference: <testLibraryFragment>::@function::f
          enclosingElement3: <testLibraryFragment>
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
          element: <testLibraryFragment>::@function::f#element
          formalParameters
            p @37
              element: <testLibraryFragment>::@function::f::@parameter::p#element
  functions
    f
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
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
          element: <testLibraryFragment>::@typeAlias::F#element
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        class C @6
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
          methods
            m @42
              reference: <testLibraryFragment>::@class::C::@method::m
              enclosingElement3: <testLibraryFragment>::@class::C
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
          element: <testLibraryFragment>::@class::C#element
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
          methods
            m @42
              reference: <testLibraryFragment>::@class::C::@method::m
              element: <testLibraryFragment>::@class::C::@method::m#element
  classes
    class C
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      functions
        f @5
          reference: <testLibraryFragment>::@function::f
          enclosingElement3: <testLibraryFragment>
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
          element: <testLibraryFragment>::@function::f#element
          formalParameters
            p @37
              element: <testLibraryFragment>::@function::f::@parameter::p#element
  functions
    f
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      topLevelVariables
        static v @30
          reference: <testLibraryFragment>::@topLevelVariable::v
          enclosingElement3: <testLibraryFragment>
          type: int Function(int, String)
      accessors
        synthetic static get v @-1
          reference: <testLibraryFragment>::@getter::v
          enclosingElement3: <testLibraryFragment>
          returnType: int Function(int, String)
        synthetic static set v= @-1
          reference: <testLibraryFragment>::@setter::v
          enclosingElement3: <testLibraryFragment>
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
          element: <testLibraryFragment>::@topLevelVariable::v#element
          getter2: <testLibraryFragment>::@getter::v
          setter2: <testLibraryFragment>::@setter::v
      getters
        get v @-1
          reference: <testLibraryFragment>::@getter::v
          element: <testLibraryFragment>::@getter::v#element
      setters
        set v= @-1
          reference: <testLibraryFragment>::@setter::v
          element: <testLibraryFragment>::@setter::v#element
          formalParameters
            _v @-1
              element: <testLibraryFragment>::@setter::v::@parameter::_v#element
  topLevelVariables
    v
      firstFragment: <testLibraryFragment>::@topLevelVariable::v
      type: int Function(int, String)
      getter: <testLibraryFragment>::@getter::v#element
      setter: <testLibraryFragment>::@setter::v#element
  getters
    synthetic static get v
      firstFragment: <testLibraryFragment>::@getter::v
  setters
    synthetic static set v=
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant T @8
              defaultType: dynamic
          constructors
            const @21
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::A
        class B @64
          reference: <testLibraryFragment>::@class::B
          enclosingElement3: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @29
              name: SimpleIdentifier
                token: A @30
                staticElement: <testLibraryFragment>::@class::A
                element: <testLibraryFragment>::@class::A#element
                staticType: null
              typeArguments: TypeArgumentList
                leftBracket: < @31
                arguments
                  GenericFunctionType
                    returnType: NamedType
                      name: int @32
                      element: dart:core::<fragment>::@class::int
                      element2: dart:core::<fragment>::@class::int#element
                      type: int
                    functionKeyword: Function @36
                    parameters: FormalParameterList
                      leftParenthesis: ( @44
                      parameter: SimpleFormalParameter
                        type: NamedType
                          name: String @45
                          element: dart:core::<fragment>::@class::String
                          element2: dart:core::<fragment>::@class::String#element
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
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::B::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::B
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
          typeParameters
            T @8
              element: <not-implemented>
          constructors
            const new @21
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <testLibraryFragment>::@class::A::@constructor::new#element
        class B @64
          reference: <testLibraryFragment>::@class::B
          element: <testLibraryFragment>::@class::B#element
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::B::@constructor::new
              element: <testLibraryFragment>::@class::B::@constructor::new#element
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
      typeParameters
        T
      constructors
        const new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
    class B
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant T @8
              defaultType: dynamic
          constructors
            const @21
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::A
      topLevelVariables
        static v @62
          reference: <testLibraryFragment>::@topLevelVariable::v
          enclosingElement3: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @29
              name: SimpleIdentifier
                token: A @30
                staticElement: <testLibraryFragment>::@class::A
                element: <testLibraryFragment>::@class::A#element
                staticType: null
              typeArguments: TypeArgumentList
                leftBracket: < @31
                arguments
                  GenericFunctionType
                    returnType: NamedType
                      name: int @32
                      element: dart:core::<fragment>::@class::int
                      element2: dart:core::<fragment>::@class::int#element
                      type: int
                    functionKeyword: Function @36
                    parameters: FormalParameterList
                      leftParenthesis: ( @44
                      parameter: SimpleFormalParameter
                        type: NamedType
                          name: String @45
                          element: dart:core::<fragment>::@class::String
                          element2: dart:core::<fragment>::@class::String#element
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
          shouldUseTypeForInitializerInference: false
      accessors
        synthetic static get v @-1
          reference: <testLibraryFragment>::@getter::v
          enclosingElement3: <testLibraryFragment>
          returnType: int
        synthetic static set v= @-1
          reference: <testLibraryFragment>::@setter::v
          enclosingElement3: <testLibraryFragment>
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
          element: <testLibraryFragment>::@class::A#element
          typeParameters
            T @8
              element: <not-implemented>
          constructors
            const new @21
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <testLibraryFragment>::@class::A::@constructor::new#element
      topLevelVariables
        v @62
          reference: <testLibraryFragment>::@topLevelVariable::v
          element: <testLibraryFragment>::@topLevelVariable::v#element
          metadata
            Annotation
              atSign: @ @29
              name: SimpleIdentifier
                token: A @30
                staticElement: <testLibraryFragment>::@class::A
                element: <testLibraryFragment>::@class::A#element
                staticType: null
              typeArguments: TypeArgumentList
                leftBracket: < @31
                arguments
                  GenericFunctionType
                    returnType: NamedType
                      name: int @32
                      element: dart:core::<fragment>::@class::int
                      element2: dart:core::<fragment>::@class::int#element
                      type: int
                    functionKeyword: Function @36
                    parameters: FormalParameterList
                      leftParenthesis: ( @44
                      parameter: SimpleFormalParameter
                        type: NamedType
                          name: String @45
                          element: dart:core::<fragment>::@class::String
                          element2: dart:core::<fragment>::@class::String#element
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
        get v @-1
          reference: <testLibraryFragment>::@getter::v
          element: <testLibraryFragment>::@getter::v#element
      setters
        set v= @-1
          reference: <testLibraryFragment>::@setter::v
          element: <testLibraryFragment>::@setter::v#element
          formalParameters
            _v @-1
              element: <testLibraryFragment>::@setter::v::@parameter::_v#element
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
      typeParameters
        T
      constructors
        const new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
  topLevelVariables
    v
      firstFragment: <testLibraryFragment>::@topLevelVariable::v
      metadata
        Annotation
          atSign: @ @29
          name: SimpleIdentifier
            token: A @30
            staticElement: <testLibraryFragment>::@class::A
            element: <testLibraryFragment>::@class::A#element
            staticType: null
          typeArguments: TypeArgumentList
            leftBracket: < @31
            arguments
              GenericFunctionType
                returnType: NamedType
                  name: int @32
                  element: dart:core::<fragment>::@class::int
                  element2: dart:core::<fragment>::@class::int#element
                  type: int
                functionKeyword: Function @36
                parameters: FormalParameterList
                  leftParenthesis: ( @44
                  parameter: SimpleFormalParameter
                    type: NamedType
                      name: String @45
                      element: dart:core::<fragment>::@class::String
                      element2: dart:core::<fragment>::@class::String#element
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
    synthetic static set v=
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant T @8
              defaultType: dynamic
          constructors
            const @21
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::A
      topLevelVariables
        static const v @35
          reference: <testLibraryFragment>::@topLevelVariable::v
          enclosingElement3: <testLibraryFragment>
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
                          element2: dart:core::<fragment>::@class::String#element
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
                                element2: dart:core::<fragment>::@class::int#element
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
                  element2: <testLibraryFragment>::@class::A#element
                  type: A<String Function({int? a})>
                staticElement: ConstructorMember
                  base: <testLibraryFragment>::@class::A::@constructor::new
                  substitution: {T: String Function({int? a})}
                element: <testLibraryFragment>::@class::A::@constructor::new#element
              argumentList: ArgumentList
                leftParenthesis: ( @67
                rightParenthesis: ) @68
              staticType: A<String Function({int? a})>
      accessors
        synthetic static get v @-1
          reference: <testLibraryFragment>::@getter::v
          enclosingElement3: <testLibraryFragment>
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
          element: <testLibraryFragment>::@class::A#element
          typeParameters
            T @8
              element: <not-implemented>
          constructors
            const new @21
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <testLibraryFragment>::@class::A::@constructor::new#element
      topLevelVariables
        const v @35
          reference: <testLibraryFragment>::@topLevelVariable::v
          element: <testLibraryFragment>::@topLevelVariable::v#element
          getter2: <testLibraryFragment>::@getter::v
      getters
        get v @-1
          reference: <testLibraryFragment>::@getter::v
          element: <testLibraryFragment>::@getter::v#element
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
      typeParameters
        T
      constructors
        const new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
  topLevelVariables
    const v
      firstFragment: <testLibraryFragment>::@topLevelVariable::v
      type: A<String Function({int? a})>
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant T @8
              defaultType: dynamic
          constructors
            const @21
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::A
      topLevelVariables
        static const v @35
          reference: <testLibraryFragment>::@topLevelVariable::v
          enclosingElement3: <testLibraryFragment>
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
                          element2: dart:core::<fragment>::@class::String#element
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
                                element2: dart:core::<fragment>::@class::int#element
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
                  element2: <testLibraryFragment>::@class::A#element
                  type: A<String Function([int?])>
                staticElement: ConstructorMember
                  base: <testLibraryFragment>::@class::A::@constructor::new
                  substitution: {T: String Function([int?])}
                element: <testLibraryFragment>::@class::A::@constructor::new#element
              argumentList: ArgumentList
                leftParenthesis: ( @67
                rightParenthesis: ) @68
              staticType: A<String Function([int?])>
      accessors
        synthetic static get v @-1
          reference: <testLibraryFragment>::@getter::v
          enclosingElement3: <testLibraryFragment>
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
          element: <testLibraryFragment>::@class::A#element
          typeParameters
            T @8
              element: <not-implemented>
          constructors
            const new @21
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <testLibraryFragment>::@class::A::@constructor::new#element
      topLevelVariables
        const v @35
          reference: <testLibraryFragment>::@topLevelVariable::v
          element: <testLibraryFragment>::@topLevelVariable::v#element
          getter2: <testLibraryFragment>::@getter::v
      getters
        get v @-1
          reference: <testLibraryFragment>::@getter::v
          element: <testLibraryFragment>::@getter::v#element
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
      typeParameters
        T
      constructors
        const new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
  topLevelVariables
    const v
      firstFragment: <testLibraryFragment>::@topLevelVariable::v
      type: A<String Function([int?])>
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant T @8
              defaultType: dynamic
          constructors
            const @21
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::A
      topLevelVariables
        static const v @35
          reference: <testLibraryFragment>::@topLevelVariable::v
          enclosingElement3: <testLibraryFragment>
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
                          element2: dart:core::<fragment>::@class::String#element
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
                                element2: dart:core::<fragment>::@class::int#element
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
                  element2: <testLibraryFragment>::@class::A#element
                  type: A<String Function({required int a})>
                staticElement: ConstructorMember
                  base: <testLibraryFragment>::@class::A::@constructor::new
                  substitution: {T: String Function({required int a})}
                element: <testLibraryFragment>::@class::A::@constructor::new#element
              argumentList: ArgumentList
                leftParenthesis: ( @75
                rightParenthesis: ) @76
              staticType: A<String Function({required int a})>
      accessors
        synthetic static get v @-1
          reference: <testLibraryFragment>::@getter::v
          enclosingElement3: <testLibraryFragment>
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
          element: <testLibraryFragment>::@class::A#element
          typeParameters
            T @8
              element: <not-implemented>
          constructors
            const new @21
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <testLibraryFragment>::@class::A::@constructor::new#element
      topLevelVariables
        const v @35
          reference: <testLibraryFragment>::@topLevelVariable::v
          element: <testLibraryFragment>::@topLevelVariable::v#element
          getter2: <testLibraryFragment>::@getter::v
      getters
        get v @-1
          reference: <testLibraryFragment>::@getter::v
          element: <testLibraryFragment>::@getter::v#element
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
      typeParameters
        T
      constructors
        const new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
  topLevelVariables
    const v
      firstFragment: <testLibraryFragment>::@topLevelVariable::v
      type: A<String Function({required int a})>
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant T @8
              defaultType: dynamic
          constructors
            const @21
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::A
      topLevelVariables
        static const v @35
          reference: <testLibraryFragment>::@topLevelVariable::v
          enclosingElement3: <testLibraryFragment>
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
                          element2: dart:core::<fragment>::@class::String#element
                          type: String
                        functionKeyword: Function @48
                        parameters: FormalParameterList
                          leftParenthesis: ( @56
                          parameter: SimpleFormalParameter
                            type: NamedType
                              name: int @57
                              element: dart:core::<fragment>::@class::int
                              element2: dart:core::<fragment>::@class::int#element
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
                  element2: <testLibraryFragment>::@class::A#element
                  type: A<String Function(int)>
                staticElement: ConstructorMember
                  base: <testLibraryFragment>::@class::A::@constructor::new
                  substitution: {T: String Function(int)}
                element: <testLibraryFragment>::@class::A::@constructor::new#element
              argumentList: ArgumentList
                leftParenthesis: ( @64
                rightParenthesis: ) @65
              staticType: A<String Function(int)>
      accessors
        synthetic static get v @-1
          reference: <testLibraryFragment>::@getter::v
          enclosingElement3: <testLibraryFragment>
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
          element: <testLibraryFragment>::@class::A#element
          typeParameters
            T @8
              element: <not-implemented>
          constructors
            const new @21
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <testLibraryFragment>::@class::A::@constructor::new#element
      topLevelVariables
        const v @35
          reference: <testLibraryFragment>::@topLevelVariable::v
          element: <testLibraryFragment>::@topLevelVariable::v#element
          getter2: <testLibraryFragment>::@getter::v
      getters
        get v @-1
          reference: <testLibraryFragment>::@getter::v
          element: <testLibraryFragment>::@getter::v#element
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
      typeParameters
        T
      constructors
        const new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
  topLevelVariables
    const v
      firstFragment: <testLibraryFragment>::@topLevelVariable::v
      type: A<String Function(int)>
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      mixins
        mixin B @6
          reference: <testLibraryFragment>::@mixin::B
          enclosingElement3: <testLibraryFragment>
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
          element: <testLibraryFragment>::@mixin::B#element
          typeParameters
            X @8
              element: <not-implemented>
  mixins
    mixin B
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant T @8
              defaultType: dynamic
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::A
        class alias B @31
          reference: <testLibraryFragment>::@class::B
          enclosingElement3: <testLibraryFragment>
          supertype: A<void Function()>
          mixins
            M
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::B::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::B
              constantInitializers
                SuperConstructorInvocation
                  superKeyword: super @0
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticElement: <testLibraryFragment>::@class::A::@constructor::new
                  element: <testLibraryFragment>::@class::A::@constructor::new#element
              superConstructor: ConstructorMember
                base: <testLibraryFragment>::@class::A::@constructor::new
                substitution: {T: void Function()}
      mixins
        mixin M @20
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
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A#element
          typeParameters
            T @8
              element: <not-implemented>
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <testLibraryFragment>::@class::A::@constructor::new#element
        class B @31
          reference: <testLibraryFragment>::@class::B
          element: <testLibraryFragment>::@class::B#element
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::B::@constructor::new
              element: <testLibraryFragment>::@class::B::@constructor::new#element
              constantInitializers
                SuperConstructorInvocation
                  superKeyword: super @0
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticElement: <testLibraryFragment>::@class::A::@constructor::new
                  element: <testLibraryFragment>::@class::A::@constructor::new#element
              superConstructor: ConstructorMember
                base: <testLibraryFragment>::@class::A::@constructor::new
                substitution: {T: void Function()}
      mixins
        mixin M @20
          reference: <testLibraryFragment>::@mixin::M
          element: <testLibraryFragment>::@mixin::M#element
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
      typeParameters
        T
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
    class alias B
      firstFragment: <testLibraryFragment>::@class::B
      supertype: A<void Function()>
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::B::@constructor::new
          superConstructor: <testLibraryFragment>::@class::A::@constructor::new#element
  mixins
    mixin M
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
      enclosingElement3: <null>
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
          element: <testLibraryFragment>::@typeAlias::F1#element
        F2 @43
          reference: <testLibraryFragment>::@typeAlias::F2
          element: <testLibraryFragment>::@typeAlias::F2#element
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
