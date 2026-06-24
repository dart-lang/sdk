// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer_testing/utilities/utilities.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../dart/resolution/node_text_expectations.dart';
import '../elements_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TypeInferenceElementTest_keepLinking);
    defineReflectiveTests(TypeInferenceElementTest_fromBytes);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

abstract class TypeInferenceElementTest extends ElementsBaseTest {
  test_closure_generic() async {
    var library = await buildLibrary(r'''
final f = <U, V>(U x, V y) => y;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasImplicitType hasInitializer isFinal isOriginDeclaration isStatic f (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::f
          inducedGetter: #F2
      getters
        #F2 isComplete isOriginVariable isStatic f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::f
          inducingVariable: #F1
  topLevelVariables
    hasImplicitType hasInitializer isFinal isOriginDeclaration isStatic isTypeInferredFromInitializer f
      reference: <testLibrary>::@topLevelVariable::f
      firstFragment: #F1
      type: V Function<U, V>(U, V)
      getter: <testLibrary>::@getter::f
  getters
    isOriginVariable isStatic f
      reference: <testLibrary>::@getter::f
      firstFragment: #F2
      returnType: V Function<U, V>(U, V)
      variable: <testLibrary>::@topLevelVariable::f
''');
  }

  test_closure_in_variable_declaration_in_part() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of lib;
final f = (int i) => i.toDouble();
''');
    var library = await buildLibrary(r'''
library lib;

part "a.dart";
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  name: lib
  fragments
    #F0 <testLibraryFragment> (nameOffset:<null>) (firstTokenOffset:0) (offset:8)
      element: <testLibrary>
      nextFragment: #F1
      parts
        part_0
          uri: package:test/a.dart
          partKeywordOffset: 14
          unit: #F1
    #F1 package:test/a.dart
      element: <testLibrary>
      enclosingFragment: #F0
      previousFragment: #F0
      topLevelVariables
        #F2 hasImplicitType hasInitializer isFinal isOriginDeclaration isStatic f (nameOffset:19) (firstTokenOffset:19) (offset:19)
          element: <testLibrary>::@topLevelVariable::f
          inducedGetter: #F3
      getters
        #F3 isComplete isOriginVariable isStatic f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:19)
          element: <testLibrary>::@getter::f
          inducingVariable: #F2
  topLevelVariables
    hasImplicitType hasInitializer isFinal isOriginDeclaration isStatic isTypeInferredFromInitializer f
      reference: <testLibrary>::@topLevelVariable::f
      firstFragment: #F2
      type: double Function(int)
      getter: <testLibrary>::@getter::f
  getters
    isOriginVariable isStatic f
      reference: <testLibrary>::@getter::f
      firstFragment: #F3
      returnType: double Function(int)
      variable: <testLibrary>::@topLevelVariable::f
''');
  }

  test_expr_invalid_typeParameter_asPrefix() async {
    var library = await buildLibrary(r'''
class C<T> {
  final f = T.k;
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
          typeParameters
            #F2 T (nameOffset:8) (firstTokenOffset:8) (offset:8)
              element: #E0 T
          fields
            #F3 hasImplicitType hasInitializer isFinal isOriginDeclaration f (nameOffset:21) (firstTokenOffset:21) (offset:21)
              element: <testLibrary>::@class::C::@field::f
              inducedGetter: #F4
          constructors
            #F5 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F4 isComplete isOriginVariable f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@class::C::@getter::f
              inducingVariable: #F3
  classes
    isSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      fields
        hasImplicitType hasInitializer isFinal isOriginDeclaration isTypeInferredFromInitializer f
          reference: <testLibrary>::@class::C::@field::f
          firstFragment: #F3
          type: InvalidType
          getter: <testLibrary>::@class::C::@getter::f
      constructors
        hasEnclosingTypeParameterReference isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F5
      getters
        isOriginVariable f
          reference: <testLibrary>::@class::C::@getter::f
          firstFragment: #F4
          returnType: InvalidType
          variable: <testLibrary>::@class::C::@field::f
''');
  }

  test_infer_generic_typedef_complex() async {
    var library = await buildLibrary(r'''
typedef F<T> = D<T, U> Function<U>();

class C<V> {
  const C(F<V> f);
}

class D<T, U> {}

D<int, U> f<U>() => null;
const x = const C(f);
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class C (nameOffset:45) (firstTokenOffset:39) (offset:45)
          element: <testLibrary>::@class::C
          typeParameters
            #F2 V (nameOffset:47) (firstTokenOffset:47) (offset:47)
              element: #E0 V
          constructors
            #F3 isConst isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:54) (offset:60)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
              typeNameOffset: 60
              formalParameters
                #F4 requiredPositional isOriginDeclaration f (nameOffset:67) (firstTokenOffset:62) (offset:67)
                  element: <testLibrary>::@class::C::@constructor::new::@formalParameter::f
        #F5 class D (nameOffset:80) (firstTokenOffset:74) (offset:80)
          element: <testLibrary>::@class::D
          typeParameters
            #F6 T (nameOffset:82) (firstTokenOffset:82) (offset:82)
              element: #E1 T
            #F7 U (nameOffset:85) (firstTokenOffset:85) (offset:85)
              element: #E2 U
          constructors
            #F8 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:80)
              element: <testLibrary>::@class::D::@constructor::new
              typeName: D
      typeAliases
        #F9 F (nameOffset:8) (firstTokenOffset:0) (offset:8)
          element: <testLibrary>::@typeAlias::F
          typeParameters
            #F10 T (nameOffset:10) (firstTokenOffset:10) (offset:10)
              element: #E3 T
      topLevelVariables
        #F11 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic x (nameOffset:124) (firstTokenOffset:124) (offset:124)
          element: <testLibrary>::@topLevelVariable::x
          initializer: expression_0
            InstanceCreationExpression
              keyword: const @128
              constructorName: ConstructorName
                type: NamedType
                  name: C @134
                  element: <testLibrary>::@class::C
                  type: C<int>
                element: SubstitutedConstructorElementImpl
                  baseElement: <testLibrary>::@class::C::@constructor::new
                  substitution: {V: int}
              argumentList: ArgumentList
                leftParenthesis: ( @135
                arguments
                  SimpleIdentifier
                    token: f @136
                    element: <testLibrary>::@function::f
                    staticType: D<int, U> Function<U>()
                rightParenthesis: ) @137
              staticType: C<int>
          inducedGetter: #F12
      getters
        #F12 isComplete isOriginVariable isStatic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:124)
          element: <testLibrary>::@getter::x
          inducingVariable: #F11
      functions
        #F13 isComplete isOriginDeclaration isStatic f (nameOffset:102) (firstTokenOffset:92) (offset:102)
          element: <testLibrary>::@function::f
          typeParameters
            #F14 U (nameOffset:104) (firstTokenOffset:104) (offset:104)
              element: #E4 U
  classes
    isSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      typeParameters
        #E0 V
          firstFragment: #F2
      constructors
        hasEnclosingTypeParameterReference isConst isOriginDeclaration new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
          formalParameters
            #E5 requiredPositional f
              firstFragment: #F4
              type: D<V, U> Function<U>()
                alias: <testLibrary>::@typeAlias::F
                  typeArguments
                    V
    isSimplyBounded class D
      reference: <testLibrary>::@class::D
      firstFragment: #F5
      typeParameters
        #E1 T
          firstFragment: #F6
        #E2 U
          firstFragment: #F7
      constructors
        hasEnclosingTypeParameterReference isOriginImplicitDefault new
          reference: <testLibrary>::@class::D::@constructor::new
          firstFragment: #F8
  typeAliases
    isSimplyBounded F
      reference: <testLibrary>::@typeAlias::F
      firstFragment: #F9
      typeParameters
        #E3 T
          firstFragment: #F10
      aliasedType: D<T, U> Function<U>()
  topLevelVariables
    hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F11
      type: C<int>
      constantInitializer
        fragment: #F11
        expression: expression_0
      getter: <testLibrary>::@getter::x
  getters
    isOriginVariable isStatic x
      reference: <testLibrary>::@getter::x
      firstFragment: #F12
      returnType: C<int>
      variable: <testLibrary>::@topLevelVariable::x
  functions
    isOriginDeclaration isStatic f
      reference: <testLibrary>::@function::f
      firstFragment: #F13
      typeParameters
        #E4 U
          firstFragment: #F14
      returnType: D<int, U>
''');
  }

  test_infer_generic_typedef_simple() async {
    var library = await buildLibrary(r'''
typedef F = D<T> Function<T>();

class C {
  const C(F f);
}

class D<T> {}

D<T> f<T>() => null;
const x = const C(f);
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class C (nameOffset:39) (firstTokenOffset:33) (offset:39)
          element: <testLibrary>::@class::C
          constructors
            #F2 isConst isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:45) (offset:51)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
              typeNameOffset: 51
              formalParameters
                #F3 requiredPositional isOriginDeclaration f (nameOffset:55) (firstTokenOffset:53) (offset:55)
                  element: <testLibrary>::@class::C::@constructor::new::@formalParameter::f
        #F4 class D (nameOffset:68) (firstTokenOffset:62) (offset:68)
          element: <testLibrary>::@class::D
          typeParameters
            #F5 T (nameOffset:70) (firstTokenOffset:70) (offset:70)
              element: #E0 T
          constructors
            #F6 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:68)
              element: <testLibrary>::@class::D::@constructor::new
              typeName: D
      typeAliases
        #F7 F (nameOffset:8) (firstTokenOffset:0) (offset:8)
          element: <testLibrary>::@typeAlias::F
      topLevelVariables
        #F8 hasImplicitType hasInitializer isConst isOriginDeclaration isStatic x (nameOffset:104) (firstTokenOffset:104) (offset:104)
          element: <testLibrary>::@topLevelVariable::x
          initializer: expression_0
            InstanceCreationExpression
              keyword: const @108
              constructorName: ConstructorName
                type: NamedType
                  name: C @114
                  element: <testLibrary>::@class::C
                  type: C
                element: <testLibrary>::@class::C::@constructor::new
              argumentList: ArgumentList
                leftParenthesis: ( @115
                arguments
                  SimpleIdentifier
                    token: f @116
                    element: <testLibrary>::@function::f
                    staticType: D<T> Function<T>()
                rightParenthesis: ) @117
              staticType: C
          inducedGetter: #F9
      getters
        #F9 isComplete isOriginVariable isStatic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:104)
          element: <testLibrary>::@getter::x
          inducingVariable: #F8
      functions
        #F10 isComplete isOriginDeclaration isStatic f (nameOffset:82) (firstTokenOffset:77) (offset:82)
          element: <testLibrary>::@function::f
          typeParameters
            #F11 T (nameOffset:84) (firstTokenOffset:84) (offset:84)
              element: #E1 T
  classes
    isSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      constructors
        isConst isOriginDeclaration new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
          formalParameters
            #E2 requiredPositional f
              firstFragment: #F3
              type: D<T> Function<T>()
                alias: <testLibrary>::@typeAlias::F
    isSimplyBounded class D
      reference: <testLibrary>::@class::D
      firstFragment: #F4
      typeParameters
        #E0 T
          firstFragment: #F5
      constructors
        hasEnclosingTypeParameterReference isOriginImplicitDefault new
          reference: <testLibrary>::@class::D::@constructor::new
          firstFragment: #F6
  typeAliases
    isSimplyBounded F
      reference: <testLibrary>::@typeAlias::F
      firstFragment: #F7
      aliasedType: D<T> Function<T>()
  topLevelVariables
    hasImplicitType hasInitializer isConst isOriginDeclaration isStatic isTypeInferredFromInitializer x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F8
      type: C
      constantInitializer
        fragment: #F8
        expression: expression_0
      getter: <testLibrary>::@getter::x
  getters
    isOriginVariable isStatic x
      reference: <testLibrary>::@getter::x
      firstFragment: #F9
      returnType: C
      variable: <testLibrary>::@topLevelVariable::x
  functions
    isOriginDeclaration isStatic f
      reference: <testLibrary>::@function::f
      firstFragment: #F10
      typeParameters
        #E1 T
          firstFragment: #F11
      returnType: D<T>
''');
  }

  test_infer_instanceCreation_fromArguments() async {
    var library = await buildLibrary(r'''
class A {}

class B extends A {}

class S<T extends A> {
  S(T _);
}

var s = new S(new B());
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
          constructors
            #F2 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
        #F3 hasExtendsClause class B (nameOffset:18) (firstTokenOffset:12) (offset:18)
          element: <testLibrary>::@class::B
          constructors
            #F4 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:18)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
        #F5 class S (nameOffset:40) (firstTokenOffset:34) (offset:40)
          element: <testLibrary>::@class::S
          typeParameters
            #F6 T (nameOffset:42) (firstTokenOffset:42) (offset:42)
              element: #E0 T
          constructors
            #F7 isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:59) (offset:59)
              element: <testLibrary>::@class::S::@constructor::new
              typeName: S
              typeNameOffset: 59
              formalParameters
                #F8 requiredPositional isOriginDeclaration _ (nameOffset:63) (firstTokenOffset:61) (offset:63)
                  element: <testLibrary>::@class::S::@constructor::new::@formalParameter::_
      topLevelVariables
        #F9 hasImplicitType hasInitializer isOriginDeclaration isStatic s (nameOffset:74) (firstTokenOffset:74) (offset:74)
          element: <testLibrary>::@topLevelVariable::s
          inducedGetter: #F10
          inducedSetter: #F11
      getters
        #F10 isComplete isOriginVariable isStatic s (nameOffset:<null>) (firstTokenOffset:<null>) (offset:74)
          element: <testLibrary>::@getter::s
          inducingVariable: #F9
      setters
        #F11 isComplete isOriginVariable isStatic s (nameOffset:<null>) (firstTokenOffset:<null>) (offset:74)
          element: <testLibrary>::@setter::s
          inducingVariable: #F9
          formalParameters
            #F12 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:74)
              element: <testLibrary>::@setter::s::@formalParameter::value
  classes
    isSimplyBounded class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
    isSimplyBounded class B
      reference: <testLibrary>::@class::B
      firstFragment: #F3
      supertype: A
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F4
          superConstructor: <testLibrary>::@class::A::@constructor::new
    isSimplyBounded class S
      reference: <testLibrary>::@class::S
      firstFragment: #F5
      typeParameters
        #E0 T
          firstFragment: #F6
          bound: A
      constructors
        hasEnclosingTypeParameterReference isOriginDeclaration new
          reference: <testLibrary>::@class::S::@constructor::new
          firstFragment: #F7
          formalParameters
            #E1 requiredPositional _
              firstFragment: #F8
              type: T
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer s
      reference: <testLibrary>::@topLevelVariable::s
      firstFragment: #F9
      type: S<B>
      getter: <testLibrary>::@getter::s
      setter: <testLibrary>::@setter::s
  getters
    isOriginVariable isStatic s
      reference: <testLibrary>::@getter::s
      firstFragment: #F10
      returnType: S<B>
      variable: <testLibrary>::@topLevelVariable::s
  setters
    isOriginVariable isStatic s
      reference: <testLibrary>::@setter::s
      firstFragment: #F11
      formalParameters
        #E2 requiredPositional value
          firstFragment: #F12
          type: S<B>
      returnType: void
      variable: <testLibrary>::@topLevelVariable::s
''');
  }

  test_infer_property_set() async {
    var library = await buildLibrary(r'''
class A {
  B b;
}

class B {
  C get c => null;
  void set c(C value) {}
}

class C {}

class D extends C {}

var a = new A();
var x = a.b.c ??= new D();
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
            #F2 isOriginDeclaration b (nameOffset:14) (firstTokenOffset:14) (offset:14)
              element: <testLibrary>::@class::A::@field::b
              inducedGetter: #F3
              inducedSetter: #F4
          constructors
            #F5 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F3 isComplete isOriginVariable b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:14)
              element: <testLibrary>::@class::A::@getter::b
              inducingVariable: #F2
          setters
            #F4 isComplete isOriginVariable b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:14)
              element: <testLibrary>::@class::A::@setter::b
              inducingVariable: #F2
              formalParameters
                #F6 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:14)
                  element: <testLibrary>::@class::A::@setter::b::@formalParameter::value
        #F7 class B (nameOffset:26) (firstTokenOffset:20) (offset:26)
          element: <testLibrary>::@class::B
          fields
            #F8 isOriginGetterSetter c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:26)
              element: <testLibrary>::@class::B::@field::c
          constructors
            #F9 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:26)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          getters
            #F10 isComplete isOriginDeclaration c (nameOffset:38) (firstTokenOffset:32) (offset:38)
              element: <testLibrary>::@class::B::@getter::c
          setters
            #F11 isComplete isOriginDeclaration c (nameOffset:60) (firstTokenOffset:51) (offset:60)
              element: <testLibrary>::@class::B::@setter::c
              formalParameters
                #F12 requiredPositional isOriginDeclaration value (nameOffset:64) (firstTokenOffset:62) (offset:64)
                  element: <testLibrary>::@class::B::@setter::c::@formalParameter::value
        #F13 class C (nameOffset:83) (firstTokenOffset:77) (offset:83)
          element: <testLibrary>::@class::C
          constructors
            #F14 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:83)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
        #F15 hasExtendsClause class D (nameOffset:95) (firstTokenOffset:89) (offset:95)
          element: <testLibrary>::@class::D
          constructors
            #F16 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:95)
              element: <testLibrary>::@class::D::@constructor::new
              typeName: D
      topLevelVariables
        #F17 hasImplicitType hasInitializer isOriginDeclaration isStatic a (nameOffset:115) (firstTokenOffset:115) (offset:115)
          element: <testLibrary>::@topLevelVariable::a
          inducedGetter: #F18
          inducedSetter: #F19
        #F20 hasImplicitType hasInitializer isOriginDeclaration isStatic x (nameOffset:132) (firstTokenOffset:132) (offset:132)
          element: <testLibrary>::@topLevelVariable::x
          inducedGetter: #F21
          inducedSetter: #F22
      getters
        #F18 isComplete isOriginVariable isStatic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:115)
          element: <testLibrary>::@getter::a
          inducingVariable: #F17
        #F21 isComplete isOriginVariable isStatic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:132)
          element: <testLibrary>::@getter::x
          inducingVariable: #F20
      setters
        #F19 isComplete isOriginVariable isStatic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:115)
          element: <testLibrary>::@setter::a
          inducingVariable: #F17
          formalParameters
            #F23 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:115)
              element: <testLibrary>::@setter::a::@formalParameter::value
        #F22 isComplete isOriginVariable isStatic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:132)
          element: <testLibrary>::@setter::x
          inducingVariable: #F20
          formalParameters
            #F24 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:132)
              element: <testLibrary>::@setter::x::@formalParameter::value
  classes
    hasNonFinalField isSimplyBounded class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        isOriginDeclaration b
          reference: <testLibrary>::@class::A::@field::b
          firstFragment: #F2
          type: B
          getter: <testLibrary>::@class::A::@getter::b
          setter: <testLibrary>::@class::A::@setter::b
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F5
      getters
        isOriginVariable b
          reference: <testLibrary>::@class::A::@getter::b
          firstFragment: #F3
          returnType: B
          variable: <testLibrary>::@class::A::@field::b
      setters
        isOriginVariable b
          reference: <testLibrary>::@class::A::@setter::b
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F6
              type: B
          returnType: void
          variable: <testLibrary>::@class::A::@field::b
    isSimplyBounded class B
      reference: <testLibrary>::@class::B
      firstFragment: #F7
      fields
        isOriginGetterSetter c
          reference: <testLibrary>::@class::B::@field::c
          firstFragment: #F8
          type: C
          getter: <testLibrary>::@class::B::@getter::c
          setter: <testLibrary>::@class::B::@setter::c
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F9
      getters
        isOriginDeclaration c
          reference: <testLibrary>::@class::B::@getter::c
          firstFragment: #F10
          returnType: C
          variable: <testLibrary>::@class::B::@field::c
      setters
        isOriginDeclaration c
          reference: <testLibrary>::@class::B::@setter::c
          firstFragment: #F11
          formalParameters
            #E1 requiredPositional value
              firstFragment: #F12
              type: C
          returnType: void
          variable: <testLibrary>::@class::B::@field::c
    isSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F13
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F14
    isSimplyBounded class D
      reference: <testLibrary>::@class::D
      firstFragment: #F15
      supertype: C
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::D::@constructor::new
          firstFragment: #F16
          superConstructor: <testLibrary>::@class::C::@constructor::new
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F17
      type: A
      getter: <testLibrary>::@getter::a
      setter: <testLibrary>::@setter::a
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F20
      type: C
      getter: <testLibrary>::@getter::x
      setter: <testLibrary>::@setter::x
  getters
    isOriginVariable isStatic a
      reference: <testLibrary>::@getter::a
      firstFragment: #F18
      returnType: A
      variable: <testLibrary>::@topLevelVariable::a
    isOriginVariable isStatic x
      reference: <testLibrary>::@getter::x
      firstFragment: #F21
      returnType: C
      variable: <testLibrary>::@topLevelVariable::x
  setters
    isOriginVariable isStatic a
      reference: <testLibrary>::@setter::a
      firstFragment: #F19
      formalParameters
        #E2 requiredPositional value
          firstFragment: #F23
          type: A
      returnType: void
      variable: <testLibrary>::@topLevelVariable::a
    isOriginVariable isStatic x
      reference: <testLibrary>::@setter::x
      firstFragment: #F22
      formalParameters
        #E3 requiredPositional value
          firstFragment: #F24
          type: C
      returnType: void
      variable: <testLibrary>::@topLevelVariable::x
''');
  }

  test_inference_issue_32394() async {
    // Test the type inference involved in dartbug.com/32394
    var library = await buildLibrary(r'''
var x = y.map((a) => a.toString());
var y = [3];
var z = x.toList();
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasImplicitType hasInitializer isOriginDeclaration isStatic x (nameOffset:4) (firstTokenOffset:4) (offset:4)
          element: <testLibrary>::@topLevelVariable::x
          inducedGetter: #F2
          inducedSetter: #F3
        #F4 hasImplicitType hasInitializer isOriginDeclaration isStatic y (nameOffset:40) (firstTokenOffset:40) (offset:40)
          element: <testLibrary>::@topLevelVariable::y
          inducedGetter: #F5
          inducedSetter: #F6
        #F7 hasImplicitType hasInitializer isOriginDeclaration isStatic z (nameOffset:53) (firstTokenOffset:53) (offset:53)
          element: <testLibrary>::@topLevelVariable::z
          inducedGetter: #F8
          inducedSetter: #F9
      getters
        #F2 isComplete isOriginVariable isStatic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@getter::x
          inducingVariable: #F1
        #F5 isComplete isOriginVariable isStatic y (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
          element: <testLibrary>::@getter::y
          inducingVariable: #F4
        #F8 isComplete isOriginVariable isStatic z (nameOffset:<null>) (firstTokenOffset:<null>) (offset:53)
          element: <testLibrary>::@getter::z
          inducingVariable: #F7
      setters
        #F3 isComplete isOriginVariable isStatic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@setter::x
          inducingVariable: #F1
          formalParameters
            #F10 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
              element: <testLibrary>::@setter::x::@formalParameter::value
        #F6 isComplete isOriginVariable isStatic y (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
          element: <testLibrary>::@setter::y
          inducingVariable: #F4
          formalParameters
            #F11 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
              element: <testLibrary>::@setter::y::@formalParameter::value
        #F9 isComplete isOriginVariable isStatic z (nameOffset:<null>) (firstTokenOffset:<null>) (offset:53)
          element: <testLibrary>::@setter::z
          inducingVariable: #F7
          formalParameters
            #F12 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:53)
              element: <testLibrary>::@setter::z::@formalParameter::value
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F1
      type: Iterable<String>
      getter: <testLibrary>::@getter::x
      setter: <testLibrary>::@setter::x
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer y
      reference: <testLibrary>::@topLevelVariable::y
      firstFragment: #F4
      type: List<int>
      getter: <testLibrary>::@getter::y
      setter: <testLibrary>::@setter::y
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer z
      reference: <testLibrary>::@topLevelVariable::z
      firstFragment: #F7
      type: List<String>
      getter: <testLibrary>::@getter::z
      setter: <testLibrary>::@setter::z
  getters
    isOriginVariable isStatic x
      reference: <testLibrary>::@getter::x
      firstFragment: #F2
      returnType: Iterable<String>
      variable: <testLibrary>::@topLevelVariable::x
    isOriginVariable isStatic y
      reference: <testLibrary>::@getter::y
      firstFragment: #F5
      returnType: List<int>
      variable: <testLibrary>::@topLevelVariable::y
    isOriginVariable isStatic z
      reference: <testLibrary>::@getter::z
      firstFragment: #F8
      returnType: List<String>
      variable: <testLibrary>::@topLevelVariable::z
  setters
    isOriginVariable isStatic x
      reference: <testLibrary>::@setter::x
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F10
          type: Iterable<String>
      returnType: void
      variable: <testLibrary>::@topLevelVariable::x
    isOriginVariable isStatic y
      reference: <testLibrary>::@setter::y
      firstFragment: #F6
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F11
          type: List<int>
      returnType: void
      variable: <testLibrary>::@topLevelVariable::y
    isOriginVariable isStatic z
      reference: <testLibrary>::@setter::z
      firstFragment: #F9
      formalParameters
        #E2 requiredPositional value
          firstFragment: #F12
          type: List<String>
      returnType: void
      variable: <testLibrary>::@topLevelVariable::z
''');
  }

  test_inference_map() async {
    var library = await buildLibrary(r'''
class C {
  int p;
}

var x = <C>[];
var y = x.map((c) => c.p);
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
          fields
            #F2 isOriginDeclaration p (nameOffset:16) (firstTokenOffset:16) (offset:16)
              element: <testLibrary>::@class::C::@field::p
              inducedGetter: #F3
              inducedSetter: #F4
          constructors
            #F5 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F3 isComplete isOriginVariable p (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@class::C::@getter::p
              inducingVariable: #F2
          setters
            #F4 isComplete isOriginVariable p (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@class::C::@setter::p
              inducingVariable: #F2
              formalParameters
                #F6 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
                  element: <testLibrary>::@class::C::@setter::p::@formalParameter::value
      topLevelVariables
        #F7 hasImplicitType hasInitializer isOriginDeclaration isStatic x (nameOffset:26) (firstTokenOffset:26) (offset:26)
          element: <testLibrary>::@topLevelVariable::x
          inducedGetter: #F8
          inducedSetter: #F9
        #F10 hasImplicitType hasInitializer isOriginDeclaration isStatic y (nameOffset:41) (firstTokenOffset:41) (offset:41)
          element: <testLibrary>::@topLevelVariable::y
          inducedGetter: #F11
          inducedSetter: #F12
      getters
        #F8 isComplete isOriginVariable isStatic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:26)
          element: <testLibrary>::@getter::x
          inducingVariable: #F7
        #F11 isComplete isOriginVariable isStatic y (nameOffset:<null>) (firstTokenOffset:<null>) (offset:41)
          element: <testLibrary>::@getter::y
          inducingVariable: #F10
      setters
        #F9 isComplete isOriginVariable isStatic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:26)
          element: <testLibrary>::@setter::x
          inducingVariable: #F7
          formalParameters
            #F13 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:26)
              element: <testLibrary>::@setter::x::@formalParameter::value
        #F12 isComplete isOriginVariable isStatic y (nameOffset:<null>) (firstTokenOffset:<null>) (offset:41)
          element: <testLibrary>::@setter::y
          inducingVariable: #F10
          formalParameters
            #F14 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:41)
              element: <testLibrary>::@setter::y::@formalParameter::value
  classes
    hasNonFinalField isSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        isOriginDeclaration p
          reference: <testLibrary>::@class::C::@field::p
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@class::C::@getter::p
          setter: <testLibrary>::@class::C::@setter::p
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F5
      getters
        isOriginVariable p
          reference: <testLibrary>::@class::C::@getter::p
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@class::C::@field::p
      setters
        isOriginVariable p
          reference: <testLibrary>::@class::C::@setter::p
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F6
              type: int
          returnType: void
          variable: <testLibrary>::@class::C::@field::p
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F7
      type: List<C>
      getter: <testLibrary>::@getter::x
      setter: <testLibrary>::@setter::x
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer y
      reference: <testLibrary>::@topLevelVariable::y
      firstFragment: #F10
      type: Iterable<int>
      getter: <testLibrary>::@getter::y
      setter: <testLibrary>::@setter::y
  getters
    isOriginVariable isStatic x
      reference: <testLibrary>::@getter::x
      firstFragment: #F8
      returnType: List<C>
      variable: <testLibrary>::@topLevelVariable::x
    isOriginVariable isStatic y
      reference: <testLibrary>::@getter::y
      firstFragment: #F11
      returnType: Iterable<int>
      variable: <testLibrary>::@topLevelVariable::y
  setters
    isOriginVariable isStatic x
      reference: <testLibrary>::@setter::x
      firstFragment: #F9
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F13
          type: List<C>
      returnType: void
      variable: <testLibrary>::@topLevelVariable::x
    isOriginVariable isStatic y
      reference: <testLibrary>::@setter::y
      firstFragment: #F12
      formalParameters
        #E2 requiredPositional value
          firstFragment: #F14
          type: Iterable<int>
      returnType: void
      variable: <testLibrary>::@topLevelVariable::y
''');
  }

  test_inferred_function_type_for_variable_in_generic_function() async {
    // In the code below, `x` has an inferred type of `() => int`, with 2
    // (unused) type parameters from the enclosing top level function.
    var library = await buildLibrary(r'''
f<U, V>() {
  var x = () => 0;
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      functions
        #F1 hasImplicitReturnType isComplete isOriginDeclaration isStatic f (nameOffset:0) (firstTokenOffset:0) (offset:0)
          element: <testLibrary>::@function::f
          typeParameters
            #F2 U (nameOffset:2) (firstTokenOffset:2) (offset:2)
              element: #E0 U
            #F3 V (nameOffset:5) (firstTokenOffset:5) (offset:5)
              element: #E1 V
  functions
    isOriginDeclaration isStatic f
      reference: <testLibrary>::@function::f
      firstFragment: #F1
      typeParameters
        #E0 U
          firstFragment: #F2
        #E1 V
          firstFragment: #F3
      returnType: dynamic
''');
  }

  test_inferred_function_type_in_generic_class_constructor() async {
    // In the code below, `() => () => 0` has an inferred return type of
    // `() => int`, with 2 (unused) type parameters from the enclosing class.
    var library = await buildLibrary(r'''
class C<U, V> {
  final x;
  C()
    : x = (() =>
          () => 0);
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
          typeParameters
            #F2 U (nameOffset:8) (firstTokenOffset:8) (offset:8)
              element: #E0 U
            #F3 V (nameOffset:11) (firstTokenOffset:11) (offset:11)
              element: #E1 V
          fields
            #F4 hasImplicitType isFinal isOriginDeclaration x (nameOffset:24) (firstTokenOffset:24) (offset:24)
              element: <testLibrary>::@class::C::@field::x
              inducedGetter: #F5
          constructors
            #F6 isComplete isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:29) (offset:29)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
              typeNameOffset: 29
          getters
            #F5 isComplete isOriginVariable x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:24)
              element: <testLibrary>::@class::C::@getter::x
              inducingVariable: #F4
  classes
    isSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      typeParameters
        #E0 U
          firstFragment: #F2
        #E1 V
          firstFragment: #F3
      fields
        hasImplicitType isFinal isOriginDeclaration x
          reference: <testLibrary>::@class::C::@field::x
          firstFragment: #F4
          type: dynamic
          getter: <testLibrary>::@class::C::@getter::x
      constructors
        hasEnclosingTypeParameterReference isOriginDeclaration new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F6
      getters
        isOriginVariable x
          reference: <testLibrary>::@class::C::@getter::x
          firstFragment: #F5
          returnType: dynamic
          variable: <testLibrary>::@class::C::@field::x
''');
  }

  test_inferred_function_type_in_generic_class_getter() async {
    // In the code below, `() => () => 0` has an inferred return type of
    // `() => int`, with 2 (unused) type parameters from the enclosing class.
    var library = await buildLibrary(r'''
class C<U, V> {
  get x =>
      () =>
          () => 0;
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
          typeParameters
            #F2 U (nameOffset:8) (firstTokenOffset:8) (offset:8)
              element: #E0 U
            #F3 V (nameOffset:11) (firstTokenOffset:11) (offset:11)
              element: #E1 V
          fields
            #F4 isOriginGetterSetter x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@field::x
          constructors
            #F5 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F6 hasImplicitReturnType isComplete isOriginDeclaration x (nameOffset:22) (firstTokenOffset:18) (offset:22)
              element: <testLibrary>::@class::C::@getter::x
  classes
    isSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      typeParameters
        #E0 U
          firstFragment: #F2
        #E1 V
          firstFragment: #F3
      fields
        isOriginGetterSetter x
          reference: <testLibrary>::@class::C::@field::x
          firstFragment: #F4
          type: dynamic
          getter: <testLibrary>::@class::C::@getter::x
      constructors
        hasEnclosingTypeParameterReference isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F5
      getters
        isOriginDeclaration x
          reference: <testLibrary>::@class::C::@getter::x
          firstFragment: #F6
          returnType: dynamic
          variable: <testLibrary>::@class::C::@field::x
''');
  }

  test_inferred_function_type_in_generic_class_in_generic_method() async {
    // In the code below, `() => () => 0` has an inferred return type of
    // `() => int`, with 3 (unused) type parameters from the enclosing class
    // and method.
    var library = await buildLibrary(r'''
class C<T> {
  f<U, V>() {
    print(
      () =>
          () => 0,
    );
  }
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
          typeParameters
            #F2 T (nameOffset:8) (firstTokenOffset:8) (offset:8)
              element: #E0 T
          constructors
            #F3 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          methods
            #F4 hasImplicitReturnType isComplete isOriginDeclaration f (nameOffset:15) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@class::C::@method::f
              typeParameters
                #F5 U (nameOffset:17) (firstTokenOffset:17) (offset:17)
                  element: #E1 U
                #F6 V (nameOffset:20) (firstTokenOffset:20) (offset:20)
                  element: #E2 V
  classes
    isSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      constructors
        hasEnclosingTypeParameterReference isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
      methods
        isOriginDeclaration f
          reference: <testLibrary>::@class::C::@method::f
          firstFragment: #F4
          typeParameters
            #E1 U
              firstFragment: #F5
            #E2 V
              firstFragment: #F6
          returnType: dynamic
''');
  }

  test_inferred_function_type_in_generic_class_setter() async {
    // In the code below, `() => () => 0` has an inferred return type of
    // `() => int`, with 2 (unused) type parameters from the enclosing class.
    var library = await buildLibrary(r'''
class C<U, V> {
  void set x(value) {
    print(
      () =>
          () => 0,
    );
  }
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
          typeParameters
            #F2 U (nameOffset:8) (firstTokenOffset:8) (offset:8)
              element: #E0 U
            #F3 V (nameOffset:11) (firstTokenOffset:11) (offset:11)
              element: #E1 V
          fields
            #F4 isOriginGetterSetter x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@field::x
          constructors
            #F5 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          setters
            #F6 isComplete isOriginDeclaration x (nameOffset:27) (firstTokenOffset:18) (offset:27)
              element: <testLibrary>::@class::C::@setter::x
              formalParameters
                #F7 requiredPositional hasImplicitType isOriginDeclaration value (nameOffset:29) (firstTokenOffset:29) (offset:29)
                  element: <testLibrary>::@class::C::@setter::x::@formalParameter::value
  classes
    isSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      typeParameters
        #E0 U
          firstFragment: #F2
        #E1 V
          firstFragment: #F3
      fields
        isOriginGetterSetter x
          reference: <testLibrary>::@class::C::@field::x
          firstFragment: #F4
          type: dynamic
          setter: <testLibrary>::@class::C::@setter::x
      constructors
        hasEnclosingTypeParameterReference isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F5
      setters
        isOriginDeclaration x
          reference: <testLibrary>::@class::C::@setter::x
          firstFragment: #F6
          formalParameters
            #E2 requiredPositional hasImplicitType value
              firstFragment: #F7
              type: dynamic
          returnType: void
          variable: <testLibrary>::@class::C::@field::x
''');
  }

  test_inferred_function_type_in_generic_closure() async {
    // In the code below, `<U, V>() => () => 0` has an inferred return type of
    // `() => int`, with 3 (unused) type parameters.
    var library = await buildLibrary(r'''
f<T>() {
  print(
    /*<U, V>*/ () =>
        () => 0,
  );
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      functions
        #F1 hasImplicitReturnType isComplete isOriginDeclaration isStatic f (nameOffset:0) (firstTokenOffset:0) (offset:0)
          element: <testLibrary>::@function::f
          typeParameters
            #F2 T (nameOffset:2) (firstTokenOffset:2) (offset:2)
              element: #E0 T
  functions
    isOriginDeclaration isStatic f
      reference: <testLibrary>::@function::f
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      returnType: dynamic
''');
  }

  test_inferred_generic_function_type_in_generic_closure() async {
    // In the code below, `<U, V>() => <W, X, Y, Z>() => 0` has an inferred
    // return type of `() => int`, with 7 (unused) type parameters.
    var library = await buildLibrary(r'''
f<T>() {
  print(
    /*<U, V>*/ () => /*<W, X, Y, Z>*/
        () => 0,
  );
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      functions
        #F1 hasImplicitReturnType isComplete isOriginDeclaration isStatic f (nameOffset:0) (firstTokenOffset:0) (offset:0)
          element: <testLibrary>::@function::f
          typeParameters
            #F2 T (nameOffset:2) (firstTokenOffset:2) (offset:2)
              element: #E0 T
  functions
    isOriginDeclaration isStatic f
      reference: <testLibrary>::@function::f
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      returnType: dynamic
''');
  }

  test_inferred_type_could_not_infer() async {
    var library = await buildLibrary(r'''
class C<P extends num> {
  factory C(Iterable<P> p) => C._();
  C._();
}

var c = C([]);
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
          typeParameters
            #F2 P (nameOffset:8) (firstTokenOffset:8) (offset:8)
              element: #E0 P
          constructors
            #F3 isComplete isFactory isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:27) (offset:35)
              element: <testLibrary>::@class::C::@constructor::new
              factoryKeywordOffset: 27
              typeName: C
              typeNameOffset: 35
              formalParameters
                #F4 requiredPositional isOriginDeclaration p (nameOffset:49) (firstTokenOffset:37) (offset:49)
                  element: <testLibrary>::@class::C::@constructor::new::@formalParameter::p
            #F5 isOriginDeclaration _ (nameOffset:66) (firstTokenOffset:64) (offset:66)
              element: <testLibrary>::@class::C::@constructor::_
              typeName: C
              typeNameOffset: 64
              periodOffset: 65
      topLevelVariables
        #F6 hasImplicitType hasInitializer isOriginDeclaration isStatic c (nameOffset:78) (firstTokenOffset:78) (offset:78)
          element: <testLibrary>::@topLevelVariable::c
          inducedGetter: #F7
          inducedSetter: #F8
      getters
        #F7 isComplete isOriginVariable isStatic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:78)
          element: <testLibrary>::@getter::c
          inducingVariable: #F6
      setters
        #F8 isComplete isOriginVariable isStatic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:78)
          element: <testLibrary>::@setter::c
          inducingVariable: #F6
          formalParameters
            #F9 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:78)
              element: <testLibrary>::@setter::c::@formalParameter::value
  classes
    isSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      typeParameters
        #E0 P
          firstFragment: #F2
          bound: num
      constructors
        hasEnclosingTypeParameterReference isFactory isOriginDeclaration new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
          formalParameters
            #E1 requiredPositional p
              firstFragment: #F4
              type: Iterable<P>
        hasEnclosingTypeParameterReference isOriginDeclaration _
          reference: <testLibrary>::@class::C::@constructor::_
          firstFragment: #F5
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: #F6
      type: C<num>
      getter: <testLibrary>::@getter::c
      setter: <testLibrary>::@setter::c
  getters
    isOriginVariable isStatic c
      reference: <testLibrary>::@getter::c
      firstFragment: #F7
      returnType: C<num>
      variable: <testLibrary>::@topLevelVariable::c
  setters
    isOriginVariable isStatic c
      reference: <testLibrary>::@setter::c
      firstFragment: #F8
      formalParameters
        #E2 requiredPositional value
          firstFragment: #F9
          type: C<num>
      returnType: void
      variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_inferred_type_functionExpressionInvocation_oppositeOrder() async {
    var library = await buildLibrary(r'''
class A {
  static final foo = bar(1.2);
  static final bar = baz();

  static int Function(double) baz() => (throw 0);
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
            #F2 hasImplicitType hasInitializer isFinal isOriginDeclaration isStatic foo (nameOffset:25) (firstTokenOffset:25) (offset:25)
              element: <testLibrary>::@class::A::@field::foo
              inducedGetter: #F3
            #F4 hasImplicitType hasInitializer isFinal isOriginDeclaration isStatic bar (nameOffset:56) (firstTokenOffset:56) (offset:56)
              element: <testLibrary>::@class::A::@field::bar
              inducedGetter: #F5
          constructors
            #F6 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F3 isComplete isOriginVariable isStatic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
              element: <testLibrary>::@class::A::@getter::foo
              inducingVariable: #F2
            #F5 isComplete isOriginVariable isStatic bar (nameOffset:<null>) (firstTokenOffset:<null>) (offset:56)
              element: <testLibrary>::@class::A::@getter::bar
              inducingVariable: #F4
          methods
            #F7 isComplete isOriginDeclaration isStatic baz (nameOffset:100) (firstTokenOffset:72) (offset:100)
              element: <testLibrary>::@class::A::@method::baz
  classes
    isSimplyBounded class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        hasImplicitType hasInitializer isFinal isOriginDeclaration isStatic isTypeInferredFromInitializer foo
          reference: <testLibrary>::@class::A::@field::foo
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@class::A::@getter::foo
        hasImplicitType hasInitializer isFinal isOriginDeclaration isStatic isTypeInferredFromInitializer bar
          reference: <testLibrary>::@class::A::@field::bar
          firstFragment: #F4
          type: int Function(double)
          getter: <testLibrary>::@class::A::@getter::bar
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F6
      getters
        isOriginVariable isStatic foo
          reference: <testLibrary>::@class::A::@getter::foo
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@class::A::@field::foo
        isOriginVariable isStatic bar
          reference: <testLibrary>::@class::A::@getter::bar
          firstFragment: #F5
          returnType: int Function(double)
          variable: <testLibrary>::@class::A::@field::bar
      methods
        isOriginDeclaration isStatic baz
          reference: <testLibrary>::@class::A::@method::baz
          firstFragment: #F7
          returnType: int Function(double)
''');
  }

  test_inferred_type_inference_failure_on_function_invocation() async {
    writeTestPackageAnalysisOptionsFile(
      analysisOptionsContent(strictInference: true),
    );
    var library = await buildLibrary(r'''
int m<T>() => 1;
var x = m();
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasImplicitType hasInitializer isOriginDeclaration isStatic x (nameOffset:21) (firstTokenOffset:21) (offset:21)
          element: <testLibrary>::@topLevelVariable::x
          inducedGetter: #F2
          inducedSetter: #F3
      getters
        #F2 isComplete isOriginVariable isStatic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
          element: <testLibrary>::@getter::x
          inducingVariable: #F1
      setters
        #F3 isComplete isOriginVariable isStatic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
          element: <testLibrary>::@setter::x
          inducingVariable: #F1
          formalParameters
            #F4 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@setter::x::@formalParameter::value
      functions
        #F5 isComplete isOriginDeclaration isStatic m (nameOffset:4) (firstTokenOffset:0) (offset:4)
          element: <testLibrary>::@function::m
          typeParameters
            #F6 T (nameOffset:6) (firstTokenOffset:6) (offset:6)
              element: #E0 T
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::x
      setter: <testLibrary>::@setter::x
  getters
    isOriginVariable isStatic x
      reference: <testLibrary>::@getter::x
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::x
  setters
    isOriginVariable isStatic x
      reference: <testLibrary>::@setter::x
      firstFragment: #F3
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F4
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::x
  functions
    isOriginDeclaration isStatic m
      reference: <testLibrary>::@function::m
      firstFragment: #F5
      typeParameters
        #E0 T
          firstFragment: #F6
      returnType: int
''');
  }

  test_inferred_type_inference_failure_on_generic_invocation() async {
    writeTestPackageAnalysisOptionsFile(
      analysisOptionsContent(strictInference: true),
    );
    var library = await buildLibrary(r'''
int Function<T>()? m = <T>() => 1;
int Function<T>() n = <T>() => 2;
var x = (m ?? n)();
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer isOriginDeclaration isStatic m (nameOffset:19) (firstTokenOffset:19) (offset:19)
          element: <testLibrary>::@topLevelVariable::m
          inducedGetter: #F2
          inducedSetter: #F3
        #F4 hasInitializer isOriginDeclaration isStatic n (nameOffset:53) (firstTokenOffset:53) (offset:53)
          element: <testLibrary>::@topLevelVariable::n
          inducedGetter: #F5
          inducedSetter: #F6
        #F7 hasImplicitType hasInitializer isOriginDeclaration isStatic x (nameOffset:73) (firstTokenOffset:73) (offset:73)
          element: <testLibrary>::@topLevelVariable::x
          inducedGetter: #F8
          inducedSetter: #F9
      getters
        #F2 isComplete isOriginVariable isStatic m (nameOffset:<null>) (firstTokenOffset:<null>) (offset:19)
          element: <testLibrary>::@getter::m
          inducingVariable: #F1
        #F5 isComplete isOriginVariable isStatic n (nameOffset:<null>) (firstTokenOffset:<null>) (offset:53)
          element: <testLibrary>::@getter::n
          inducingVariable: #F4
        #F8 isComplete isOriginVariable isStatic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:73)
          element: <testLibrary>::@getter::x
          inducingVariable: #F7
      setters
        #F3 isComplete isOriginVariable isStatic m (nameOffset:<null>) (firstTokenOffset:<null>) (offset:19)
          element: <testLibrary>::@setter::m
          inducingVariable: #F1
          formalParameters
            #F10 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:19)
              element: <testLibrary>::@setter::m::@formalParameter::value
        #F6 isComplete isOriginVariable isStatic n (nameOffset:<null>) (firstTokenOffset:<null>) (offset:53)
          element: <testLibrary>::@setter::n
          inducingVariable: #F4
          formalParameters
            #F11 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:53)
              element: <testLibrary>::@setter::n::@formalParameter::value
        #F9 isComplete isOriginVariable isStatic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:73)
          element: <testLibrary>::@setter::x
          inducingVariable: #F7
          formalParameters
            #F12 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:73)
              element: <testLibrary>::@setter::x::@formalParameter::value
  topLevelVariables
    hasInitializer isOriginDeclaration isStatic m
      reference: <testLibrary>::@topLevelVariable::m
      firstFragment: #F1
      type: int Function<T>()?
      getter: <testLibrary>::@getter::m
      setter: <testLibrary>::@setter::m
    hasInitializer isOriginDeclaration isStatic n
      reference: <testLibrary>::@topLevelVariable::n
      firstFragment: #F4
      type: int Function<T>()
      getter: <testLibrary>::@getter::n
      setter: <testLibrary>::@setter::n
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F7
      type: int
      getter: <testLibrary>::@getter::x
      setter: <testLibrary>::@setter::x
  getters
    isOriginVariable isStatic m
      reference: <testLibrary>::@getter::m
      firstFragment: #F2
      returnType: int Function<T>()?
      variable: <testLibrary>::@topLevelVariable::m
    isOriginVariable isStatic n
      reference: <testLibrary>::@getter::n
      firstFragment: #F5
      returnType: int Function<T>()
      variable: <testLibrary>::@topLevelVariable::n
    isOriginVariable isStatic x
      reference: <testLibrary>::@getter::x
      firstFragment: #F8
      returnType: int
      variable: <testLibrary>::@topLevelVariable::x
  setters
    isOriginVariable isStatic m
      reference: <testLibrary>::@setter::m
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F10
          type: int Function<T>()?
      returnType: void
      variable: <testLibrary>::@topLevelVariable::m
    isOriginVariable isStatic n
      reference: <testLibrary>::@setter::n
      firstFragment: #F6
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F11
          type: int Function<T>()
      returnType: void
      variable: <testLibrary>::@topLevelVariable::n
    isOriginVariable isStatic x
      reference: <testLibrary>::@setter::x
      firstFragment: #F9
      formalParameters
        #E2 requiredPositional value
          firstFragment: #F12
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::x
''');
  }

  test_inferred_type_inference_failure_on_instance_creation() async {
    writeTestPackageAnalysisOptionsFile(
      analysisOptionsContent(strictInference: true),
    );
    var library = await buildLibrary(r'''
import 'dart:collection';

var m = HashMap();
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        dart:collection
      topLevelVariables
        #F1 hasImplicitType hasInitializer isOriginDeclaration isStatic m (nameOffset:31) (firstTokenOffset:31) (offset:31)
          element: <testLibrary>::@topLevelVariable::m
          inducedGetter: #F2
          inducedSetter: #F3
      getters
        #F2 isComplete isOriginVariable isStatic m (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
          element: <testLibrary>::@getter::m
          inducingVariable: #F1
      setters
        #F3 isComplete isOriginVariable isStatic m (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
          element: <testLibrary>::@setter::m
          inducingVariable: #F1
          formalParameters
            #F4 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
              element: <testLibrary>::@setter::m::@formalParameter::value
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer m
      reference: <testLibrary>::@topLevelVariable::m
      firstFragment: #F1
      type: HashMap<dynamic, dynamic>
      getter: <testLibrary>::@getter::m
      setter: <testLibrary>::@setter::m
  getters
    isOriginVariable isStatic m
      reference: <testLibrary>::@getter::m
      firstFragment: #F2
      returnType: HashMap<dynamic, dynamic>
      variable: <testLibrary>::@topLevelVariable::m
  setters
    isOriginVariable isStatic m
      reference: <testLibrary>::@setter::m
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F4
          type: HashMap<dynamic, dynamic>
      returnType: void
      variable: <testLibrary>::@topLevelVariable::m
''');
  }

  test_inferred_type_initializer_cycle() async {
    var library = await buildLibrary(r'''
var a = b + 1;
var b = c + 2;
var c = a + 3;
var d = 4;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasImplicitType hasInitializer isOriginDeclaration isStatic a (nameOffset:4) (firstTokenOffset:4) (offset:4)
          element: <testLibrary>::@topLevelVariable::a
          inducedGetter: #F2
          inducedSetter: #F3
        #F4 hasImplicitType hasInitializer isOriginDeclaration isStatic b (nameOffset:19) (firstTokenOffset:19) (offset:19)
          element: <testLibrary>::@topLevelVariable::b
          inducedGetter: #F5
          inducedSetter: #F6
        #F7 hasImplicitType hasInitializer isOriginDeclaration isStatic c (nameOffset:34) (firstTokenOffset:34) (offset:34)
          element: <testLibrary>::@topLevelVariable::c
          inducedGetter: #F8
          inducedSetter: #F9
        #F10 hasImplicitType hasInitializer isOriginDeclaration isStatic d (nameOffset:49) (firstTokenOffset:49) (offset:49)
          element: <testLibrary>::@topLevelVariable::d
          inducedGetter: #F11
          inducedSetter: #F12
      getters
        #F2 isComplete isOriginVariable isStatic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@getter::a
          inducingVariable: #F1
        #F5 isComplete isOriginVariable isStatic b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:19)
          element: <testLibrary>::@getter::b
          inducingVariable: #F4
        #F8 isComplete isOriginVariable isStatic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:34)
          element: <testLibrary>::@getter::c
          inducingVariable: #F7
        #F11 isComplete isOriginVariable isStatic d (nameOffset:<null>) (firstTokenOffset:<null>) (offset:49)
          element: <testLibrary>::@getter::d
          inducingVariable: #F10
      setters
        #F3 isComplete isOriginVariable isStatic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@setter::a
          inducingVariable: #F1
          formalParameters
            #F13 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
              element: <testLibrary>::@setter::a::@formalParameter::value
        #F6 isComplete isOriginVariable isStatic b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:19)
          element: <testLibrary>::@setter::b
          inducingVariable: #F4
          formalParameters
            #F14 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:19)
              element: <testLibrary>::@setter::b::@formalParameter::value
        #F9 isComplete isOriginVariable isStatic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:34)
          element: <testLibrary>::@setter::c
          inducingVariable: #F7
          formalParameters
            #F15 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:34)
              element: <testLibrary>::@setter::c::@formalParameter::value
        #F12 isComplete isOriginVariable isStatic d (nameOffset:<null>) (firstTokenOffset:<null>) (offset:49)
          element: <testLibrary>::@setter::d
          inducingVariable: #F10
          formalParameters
            #F16 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:49)
              element: <testLibrary>::@setter::d::@formalParameter::value
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration isStatic a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F1
      typeInferenceError: dependencyCycle
        arguments: [a, b, c]
      type: dynamic
      getter: <testLibrary>::@getter::a
      setter: <testLibrary>::@setter::a
    hasImplicitType hasInitializer isOriginDeclaration isStatic b
      reference: <testLibrary>::@topLevelVariable::b
      firstFragment: #F4
      typeInferenceError: dependencyCycle
        arguments: [a, b, c]
      type: dynamic
      getter: <testLibrary>::@getter::b
      setter: <testLibrary>::@setter::b
    hasImplicitType hasInitializer isOriginDeclaration isStatic c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: #F7
      typeInferenceError: dependencyCycle
        arguments: [a, b, c]
      type: dynamic
      getter: <testLibrary>::@getter::c
      setter: <testLibrary>::@setter::c
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer d
      reference: <testLibrary>::@topLevelVariable::d
      firstFragment: #F10
      type: int
      getter: <testLibrary>::@getter::d
      setter: <testLibrary>::@setter::d
  getters
    isOriginVariable isStatic a
      reference: <testLibrary>::@getter::a
      firstFragment: #F2
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::a
    isOriginVariable isStatic b
      reference: <testLibrary>::@getter::b
      firstFragment: #F5
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::b
    isOriginVariable isStatic c
      reference: <testLibrary>::@getter::c
      firstFragment: #F8
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::c
    isOriginVariable isStatic d
      reference: <testLibrary>::@getter::d
      firstFragment: #F11
      returnType: int
      variable: <testLibrary>::@topLevelVariable::d
  setters
    isOriginVariable isStatic a
      reference: <testLibrary>::@setter::a
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F13
          type: dynamic
      returnType: void
      variable: <testLibrary>::@topLevelVariable::a
    isOriginVariable isStatic b
      reference: <testLibrary>::@setter::b
      firstFragment: #F6
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F14
          type: dynamic
      returnType: void
      variable: <testLibrary>::@topLevelVariable::b
    isOriginVariable isStatic c
      reference: <testLibrary>::@setter::c
      firstFragment: #F9
      formalParameters
        #E2 requiredPositional value
          firstFragment: #F15
          type: dynamic
      returnType: void
      variable: <testLibrary>::@topLevelVariable::c
    isOriginVariable isStatic d
      reference: <testLibrary>::@setter::d
      firstFragment: #F12
      formalParameters
        #E3 requiredPositional value
          firstFragment: #F16
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::d
''');
  }

  test_inferred_type_is_typedef() async {
    var library = await buildLibrary(r'''
typedef int F(String s);

class C extends D {
  var v;
}

abstract class D {
  F get v;
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 hasExtendsClause class C (nameOffset:32) (firstTokenOffset:26) (offset:32)
          element: <testLibrary>::@class::C
          fields
            #F2 hasImplicitType isOriginDeclaration v (nameOffset:52) (firstTokenOffset:52) (offset:52)
              element: <testLibrary>::@class::C::@field::v
              inducedGetter: #F3
              inducedSetter: #F4
          constructors
            #F5 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:32)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F3 isComplete isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:52)
              element: <testLibrary>::@class::C::@getter::v
              inducingVariable: #F2
          setters
            #F4 isComplete isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:52)
              element: <testLibrary>::@class::C::@setter::v
              inducingVariable: #F2
              formalParameters
                #F6 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:52)
                  element: <testLibrary>::@class::C::@setter::v::@formalParameter::value
        #F7 isAbstract class D (nameOffset:73) (firstTokenOffset:58) (offset:73)
          element: <testLibrary>::@class::D
          fields
            #F8 isOriginGetterSetter v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:73)
              element: <testLibrary>::@class::D::@field::v
          constructors
            #F9 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:73)
              element: <testLibrary>::@class::D::@constructor::new
              typeName: D
          getters
            #F10 isAbstract isOriginDeclaration v (nameOffset:85) (firstTokenOffset:79) (offset:85)
              element: <testLibrary>::@class::D::@getter::v
      typeAliases
        #F11 F (nameOffset:12) (firstTokenOffset:0) (offset:12)
          element: <testLibrary>::@typeAlias::F
  classes
    hasNonFinalField isSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      supertype: D
      fields
        hasImplicitType isOriginDeclaration v
          reference: <testLibrary>::@class::C::@field::v
          firstFragment: #F2
          type: int Function(String)
            alias: <testLibrary>::@typeAlias::F
          getter: <testLibrary>::@class::C::@getter::v
          setter: <testLibrary>::@class::C::@setter::v
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F5
          superConstructor: <testLibrary>::@class::D::@constructor::new
      getters
        isOriginVariable v
          reference: <testLibrary>::@class::C::@getter::v
          firstFragment: #F3
          returnType: int Function(String)
            alias: <testLibrary>::@typeAlias::F
          variable: <testLibrary>::@class::C::@field::v
      setters
        isOriginVariable v
          reference: <testLibrary>::@class::C::@setter::v
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F6
              type: int Function(String)
                alias: <testLibrary>::@typeAlias::F
          returnType: void
          variable: <testLibrary>::@class::C::@field::v
    isAbstract isSimplyBounded class D
      reference: <testLibrary>::@class::D
      firstFragment: #F7
      fields
        isOriginGetterSetter v
          reference: <testLibrary>::@class::D::@field::v
          firstFragment: #F8
          type: int Function(String)
            alias: <testLibrary>::@typeAlias::F
          getter: <testLibrary>::@class::D::@getter::v
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::D::@constructor::new
          firstFragment: #F9
      getters
        isOriginDeclaration v
          reference: <testLibrary>::@class::D::@getter::v
          firstFragment: #F10
          returnType: int Function(String)
            alias: <testLibrary>::@typeAlias::F
          variable: <testLibrary>::@class::D::@field::v
  typeAliases
    isSimplyBounded F
      reference: <testLibrary>::@typeAlias::F
      firstFragment: #F11
      aliasedType: int Function(String)
''');
  }

  test_inferred_type_nullability_class_ref_none() async {
    newFile('$testPackageLibPath/a.dart', r'''
int f() => 0;
''');
    var library = await buildLibrary(r'''
import 'a.dart';

var x = f();
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart
      topLevelVariables
        #F1 hasImplicitType hasInitializer isOriginDeclaration isStatic x (nameOffset:22) (firstTokenOffset:22) (offset:22)
          element: <testLibrary>::@topLevelVariable::x
          inducedGetter: #F2
          inducedSetter: #F3
      getters
        #F2 isComplete isOriginVariable isStatic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
          element: <testLibrary>::@getter::x
          inducingVariable: #F1
      setters
        #F3 isComplete isOriginVariable isStatic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
          element: <testLibrary>::@setter::x
          inducingVariable: #F1
          formalParameters
            #F4 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
              element: <testLibrary>::@setter::x::@formalParameter::value
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::x
      setter: <testLibrary>::@setter::x
  getters
    isOriginVariable isStatic x
      reference: <testLibrary>::@getter::x
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::x
  setters
    isOriginVariable isStatic x
      reference: <testLibrary>::@setter::x
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F4
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::x
''');
  }

  test_inferred_type_nullability_class_ref_question() async {
    newFile('$testPackageLibPath/a.dart', r'''
int? f() => 0;
''');
    var library = await buildLibrary(r'''
import 'a.dart';

var x = f();
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart
      topLevelVariables
        #F1 hasImplicitType hasInitializer isOriginDeclaration isStatic x (nameOffset:22) (firstTokenOffset:22) (offset:22)
          element: <testLibrary>::@topLevelVariable::x
          inducedGetter: #F2
          inducedSetter: #F3
      getters
        #F2 isComplete isOriginVariable isStatic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
          element: <testLibrary>::@getter::x
          inducingVariable: #F1
      setters
        #F3 isComplete isOriginVariable isStatic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
          element: <testLibrary>::@setter::x
          inducingVariable: #F1
          formalParameters
            #F4 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
              element: <testLibrary>::@setter::x::@formalParameter::value
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F1
      type: int?
      getter: <testLibrary>::@getter::x
      setter: <testLibrary>::@setter::x
  getters
    isOriginVariable isStatic x
      reference: <testLibrary>::@getter::x
      firstFragment: #F2
      returnType: int?
      variable: <testLibrary>::@topLevelVariable::x
  setters
    isOriginVariable isStatic x
      reference: <testLibrary>::@setter::x
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F4
          type: int?
      returnType: void
      variable: <testLibrary>::@topLevelVariable::x
''');
  }

  test_inferred_type_nullability_function_type_none() async {
    newFile('$testPackageLibPath/a.dart', r'''
void Function() f() => () {};
''');
    var library = await buildLibrary(r'''
import 'a.dart';

var x = f();
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart
      topLevelVariables
        #F1 hasImplicitType hasInitializer isOriginDeclaration isStatic x (nameOffset:22) (firstTokenOffset:22) (offset:22)
          element: <testLibrary>::@topLevelVariable::x
          inducedGetter: #F2
          inducedSetter: #F3
      getters
        #F2 isComplete isOriginVariable isStatic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
          element: <testLibrary>::@getter::x
          inducingVariable: #F1
      setters
        #F3 isComplete isOriginVariable isStatic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
          element: <testLibrary>::@setter::x
          inducingVariable: #F1
          formalParameters
            #F4 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
              element: <testLibrary>::@setter::x::@formalParameter::value
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F1
      type: void Function()
      getter: <testLibrary>::@getter::x
      setter: <testLibrary>::@setter::x
  getters
    isOriginVariable isStatic x
      reference: <testLibrary>::@getter::x
      firstFragment: #F2
      returnType: void Function()
      variable: <testLibrary>::@topLevelVariable::x
  setters
    isOriginVariable isStatic x
      reference: <testLibrary>::@setter::x
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F4
          type: void Function()
      returnType: void
      variable: <testLibrary>::@topLevelVariable::x
''');
  }

  test_inferred_type_nullability_function_type_question() async {
    newFile('$testPackageLibPath/a.dart', r'''
void Function()? f() => () {};
''');
    var library = await buildLibrary(r'''
import 'a.dart';

var x = f();
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart
      topLevelVariables
        #F1 hasImplicitType hasInitializer isOriginDeclaration isStatic x (nameOffset:22) (firstTokenOffset:22) (offset:22)
          element: <testLibrary>::@topLevelVariable::x
          inducedGetter: #F2
          inducedSetter: #F3
      getters
        #F2 isComplete isOriginVariable isStatic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
          element: <testLibrary>::@getter::x
          inducingVariable: #F1
      setters
        #F3 isComplete isOriginVariable isStatic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
          element: <testLibrary>::@setter::x
          inducingVariable: #F1
          formalParameters
            #F4 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
              element: <testLibrary>::@setter::x::@formalParameter::value
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F1
      type: void Function()?
      getter: <testLibrary>::@getter::x
      setter: <testLibrary>::@setter::x
  getters
    isOriginVariable isStatic x
      reference: <testLibrary>::@getter::x
      firstFragment: #F2
      returnType: void Function()?
      variable: <testLibrary>::@topLevelVariable::x
  setters
    isOriginVariable isStatic x
      reference: <testLibrary>::@setter::x
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F4
          type: void Function()?
      returnType: void
      variable: <testLibrary>::@topLevelVariable::x
''');
  }

  test_inferred_type_refers_to_bound_type_param() async {
    var library = await buildLibrary(r'''
class C<T> extends D<int, T> {
  var v;
}

abstract class D<U, V> {
  Map<V, U> get v;
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 hasExtendsClause class C (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::C
          typeParameters
            #F2 T (nameOffset:8) (firstTokenOffset:8) (offset:8)
              element: #E0 T
          fields
            #F3 hasImplicitType isOriginDeclaration v (nameOffset:37) (firstTokenOffset:37) (offset:37)
              element: <testLibrary>::@class::C::@field::v
              inducedGetter: #F4
              inducedSetter: #F5
          constructors
            #F6 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F4 isComplete isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:37)
              element: <testLibrary>::@class::C::@getter::v
              inducingVariable: #F3
          setters
            #F5 isComplete isOriginVariable v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:37)
              element: <testLibrary>::@class::C::@setter::v
              inducingVariable: #F3
              formalParameters
                #F7 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:37)
                  element: <testLibrary>::@class::C::@setter::v::@formalParameter::value
        #F8 isAbstract class D (nameOffset:58) (firstTokenOffset:43) (offset:58)
          element: <testLibrary>::@class::D
          typeParameters
            #F9 U (nameOffset:60) (firstTokenOffset:60) (offset:60)
              element: #E1 U
            #F10 V (nameOffset:63) (firstTokenOffset:63) (offset:63)
              element: #E2 V
          fields
            #F11 isOriginGetterSetter v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:58)
              element: <testLibrary>::@class::D::@field::v
          constructors
            #F12 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:58)
              element: <testLibrary>::@class::D::@constructor::new
              typeName: D
          getters
            #F13 isAbstract isOriginDeclaration v (nameOffset:84) (firstTokenOffset:70) (offset:84)
              element: <testLibrary>::@class::D::@getter::v
  classes
    hasNonFinalField isSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      supertype: D<int, T>
      fields
        hasEnclosingTypeParameterReference hasImplicitType isOriginDeclaration v
          reference: <testLibrary>::@class::C::@field::v
          firstFragment: #F3
          type: Map<T, int>
          getter: <testLibrary>::@class::C::@getter::v
          setter: <testLibrary>::@class::C::@setter::v
      constructors
        hasEnclosingTypeParameterReference isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F6
          superConstructor: SubstitutedConstructorElementImpl
            baseElement: <testLibrary>::@class::D::@constructor::new
            substitution: {U: int, V: T}
      getters
        hasEnclosingTypeParameterReference isOriginVariable v
          reference: <testLibrary>::@class::C::@getter::v
          firstFragment: #F4
          returnType: Map<T, int>
          variable: <testLibrary>::@class::C::@field::v
      setters
        hasEnclosingTypeParameterReference isOriginVariable v
          reference: <testLibrary>::@class::C::@setter::v
          firstFragment: #F5
          formalParameters
            #E3 requiredPositional value
              firstFragment: #F7
              type: Map<T, int>
          returnType: void
          variable: <testLibrary>::@class::C::@field::v
    isAbstract isSimplyBounded class D
      reference: <testLibrary>::@class::D
      firstFragment: #F8
      typeParameters
        #E1 U
          firstFragment: #F9
        #E2 V
          firstFragment: #F10
      fields
        hasEnclosingTypeParameterReference isOriginGetterSetter v
          reference: <testLibrary>::@class::D::@field::v
          firstFragment: #F11
          type: Map<V, U>
          getter: <testLibrary>::@class::D::@getter::v
      constructors
        hasEnclosingTypeParameterReference isOriginImplicitDefault new
          reference: <testLibrary>::@class::D::@constructor::new
          firstFragment: #F12
      getters
        hasEnclosingTypeParameterReference isOriginDeclaration v
          reference: <testLibrary>::@class::D::@getter::v
          firstFragment: #F13
          returnType: Map<V, U>
          variable: <testLibrary>::@class::D::@field::v
''');
  }

  test_inferred_type_refers_to_function_typed_param_of_typedef() async {
    var library = await buildLibrary(r'''
typedef void F(int g(String s));
h(F f) => null;
var v = h((y) {});
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        #F1 F (nameOffset:13) (firstTokenOffset:0) (offset:13)
          element: <testLibrary>::@typeAlias::F
      topLevelVariables
        #F2 hasImplicitType hasInitializer isOriginDeclaration isStatic v (nameOffset:53) (firstTokenOffset:53) (offset:53)
          element: <testLibrary>::@topLevelVariable::v
          inducedGetter: #F3
          inducedSetter: #F4
      getters
        #F3 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:53)
          element: <testLibrary>::@getter::v
          inducingVariable: #F2
      setters
        #F4 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:53)
          element: <testLibrary>::@setter::v
          inducingVariable: #F2
          formalParameters
            #F5 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:53)
              element: <testLibrary>::@setter::v::@formalParameter::value
      functions
        #F6 hasImplicitReturnType isComplete isOriginDeclaration isStatic h (nameOffset:33) (firstTokenOffset:33) (offset:33)
          element: <testLibrary>::@function::h
          formalParameters
            #F7 requiredPositional isOriginDeclaration f (nameOffset:37) (firstTokenOffset:35) (offset:37)
              element: <testLibrary>::@function::h::@formalParameter::f
  typeAliases
    isSimplyBounded F
      reference: <testLibrary>::@typeAlias::F
      firstFragment: #F1
      aliasedType: void Function(int Function(String))
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer v
      reference: <testLibrary>::@topLevelVariable::v
      firstFragment: #F2
      type: dynamic
      getter: <testLibrary>::@getter::v
      setter: <testLibrary>::@setter::v
  getters
    isOriginVariable isStatic v
      reference: <testLibrary>::@getter::v
      firstFragment: #F3
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::v
  setters
    isOriginVariable isStatic v
      reference: <testLibrary>::@setter::v
      firstFragment: #F4
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F5
          type: dynamic
      returnType: void
      variable: <testLibrary>::@topLevelVariable::v
  functions
    isOriginDeclaration isStatic h
      reference: <testLibrary>::@function::h
      firstFragment: #F6
      formalParameters
        #E1 requiredPositional f
          firstFragment: #F7
          type: void Function(int Function(String))
            alias: <testLibrary>::@typeAlias::F
      returnType: dynamic
''');
  }

  test_inferred_type_refers_to_function_typed_parameter_type_generic_class() async {
    var library = await buildLibrary(r'''
class C<T, U> extends D<U, int> {
  void f(int x, g) {}
}

abstract class D<V, W> {
  void f(int x, W g(V s));
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 hasExtendsClause class C (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::C
          typeParameters
            #F2 T (nameOffset:8) (firstTokenOffset:8) (offset:8)
              element: #E0 T
            #F3 U (nameOffset:11) (firstTokenOffset:11) (offset:11)
              element: #E1 U
          constructors
            #F4 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          methods
            #F5 isComplete isOriginDeclaration f (nameOffset:41) (firstTokenOffset:36) (offset:41)
              element: <testLibrary>::@class::C::@method::f
              formalParameters
                #F6 requiredPositional isOriginDeclaration x (nameOffset:47) (firstTokenOffset:43) (offset:47)
                  element: <testLibrary>::@class::C::@method::f::@formalParameter::x
                #F7 requiredPositional hasImplicitType isOriginDeclaration g (nameOffset:50) (firstTokenOffset:50) (offset:50)
                  element: <testLibrary>::@class::C::@method::f::@formalParameter::g
        #F8 isAbstract class D (nameOffset:74) (firstTokenOffset:59) (offset:74)
          element: <testLibrary>::@class::D
          typeParameters
            #F9 V (nameOffset:76) (firstTokenOffset:76) (offset:76)
              element: #E2 V
            #F10 W (nameOffset:79) (firstTokenOffset:79) (offset:79)
              element: #E3 W
          constructors
            #F11 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:74)
              element: <testLibrary>::@class::D::@constructor::new
              typeName: D
          methods
            #F12 isAbstract isOriginDeclaration f (nameOffset:91) (firstTokenOffset:86) (offset:91)
              element: <testLibrary>::@class::D::@method::f
              formalParameters
                #F13 requiredPositional isOriginDeclaration x (nameOffset:97) (firstTokenOffset:93) (offset:97)
                  element: <testLibrary>::@class::D::@method::f::@formalParameter::x
                #F14 requiredPositional isOriginDeclaration g (nameOffset:102) (firstTokenOffset:100) (offset:102)
                  element: <testLibrary>::@class::D::@method::f::@formalParameter::g
  classes
    isSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
        #E1 U
          firstFragment: #F3
      supertype: D<U, int>
      constructors
        hasEnclosingTypeParameterReference isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F4
          superConstructor: SubstitutedConstructorElementImpl
            baseElement: <testLibrary>::@class::D::@constructor::new
            substitution: {V: U, W: int}
      methods
        hasEnclosingTypeParameterReference isOriginDeclaration f
          reference: <testLibrary>::@class::C::@method::f
          firstFragment: #F5
          formalParameters
            #E4 requiredPositional x
              firstFragment: #F6
              type: int
            #E5 requiredPositional hasImplicitType g
              firstFragment: #F7
              type: int Function(U)
          returnType: void
    isAbstract isSimplyBounded class D
      reference: <testLibrary>::@class::D
      firstFragment: #F8
      typeParameters
        #E2 V
          firstFragment: #F9
        #E3 W
          firstFragment: #F10
      constructors
        hasEnclosingTypeParameterReference isOriginImplicitDefault new
          reference: <testLibrary>::@class::D::@constructor::new
          firstFragment: #F11
      methods
        hasEnclosingTypeParameterReference isOriginDeclaration f
          reference: <testLibrary>::@class::D::@method::f
          firstFragment: #F12
          formalParameters
            #E6 requiredPositional x
              firstFragment: #F13
              type: int
            #E7 requiredPositional g
              firstFragment: #F14
              type: W Function(V)
          returnType: void
''');
  }

  test_inferred_type_refers_to_function_typed_parameter_type_other_lib() async {
    newFile('$testPackageLibPath/a.dart', r'''
import 'b.dart';
abstract class D extends E {}
''');
    newFile('$testPackageLibPath/b.dart', r'''
abstract class E {
  void f(int x, int g(String s));
}
''');
    var library = await buildLibrary(r'''
import 'a.dart';

class C extends D {
  void f(int x, g) {}
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart
      classes
        #F1 hasExtendsClause class C (nameOffset:24) (firstTokenOffset:18) (offset:24)
          element: <testLibrary>::@class::C
          constructors
            #F2 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:24)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          methods
            #F3 isComplete isOriginDeclaration f (nameOffset:45) (firstTokenOffset:40) (offset:45)
              element: <testLibrary>::@class::C::@method::f
              formalParameters
                #F4 requiredPositional isOriginDeclaration x (nameOffset:51) (firstTokenOffset:47) (offset:51)
                  element: <testLibrary>::@class::C::@method::f::@formalParameter::x
                #F5 requiredPositional hasImplicitType isOriginDeclaration g (nameOffset:54) (firstTokenOffset:54) (offset:54)
                  element: <testLibrary>::@class::C::@method::f::@formalParameter::g
  classes
    isSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      supertype: D
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
          superConstructor: package:test/a.dart::@class::D::@constructor::new
      methods
        isOriginDeclaration f
          reference: <testLibrary>::@class::C::@method::f
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional x
              firstFragment: #F4
              type: int
            #E1 requiredPositional hasImplicitType g
              firstFragment: #F5
              type: int Function(String)
          returnType: void
''');
  }

  test_inferred_type_refers_to_method_function_typed_parameter_type() async {
    var library = await buildLibrary(r'''
class C extends D {
  void f(int x, g) {}
}

abstract class D {
  void f(int x, int g(String s));
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 hasExtendsClause class C (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::C
          constructors
            #F2 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          methods
            #F3 isComplete isOriginDeclaration f (nameOffset:27) (firstTokenOffset:22) (offset:27)
              element: <testLibrary>::@class::C::@method::f
              formalParameters
                #F4 requiredPositional isOriginDeclaration x (nameOffset:33) (firstTokenOffset:29) (offset:33)
                  element: <testLibrary>::@class::C::@method::f::@formalParameter::x
                #F5 requiredPositional hasImplicitType isOriginDeclaration g (nameOffset:36) (firstTokenOffset:36) (offset:36)
                  element: <testLibrary>::@class::C::@method::f::@formalParameter::g
        #F6 isAbstract class D (nameOffset:60) (firstTokenOffset:45) (offset:60)
          element: <testLibrary>::@class::D
          constructors
            #F7 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:60)
              element: <testLibrary>::@class::D::@constructor::new
              typeName: D
          methods
            #F8 isAbstract isOriginDeclaration f (nameOffset:71) (firstTokenOffset:66) (offset:71)
              element: <testLibrary>::@class::D::@method::f
              formalParameters
                #F9 requiredPositional isOriginDeclaration x (nameOffset:77) (firstTokenOffset:73) (offset:77)
                  element: <testLibrary>::@class::D::@method::f::@formalParameter::x
                #F10 requiredPositional isOriginDeclaration g (nameOffset:84) (firstTokenOffset:80) (offset:84)
                  element: <testLibrary>::@class::D::@method::f::@formalParameter::g
  classes
    isSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      supertype: D
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
          superConstructor: <testLibrary>::@class::D::@constructor::new
      methods
        isOriginDeclaration f
          reference: <testLibrary>::@class::C::@method::f
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional x
              firstFragment: #F4
              type: int
            #E1 requiredPositional hasImplicitType g
              firstFragment: #F5
              type: int Function(String)
          returnType: void
    isAbstract isSimplyBounded class D
      reference: <testLibrary>::@class::D
      firstFragment: #F6
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::D::@constructor::new
          firstFragment: #F7
      methods
        isOriginDeclaration f
          reference: <testLibrary>::@class::D::@method::f
          firstFragment: #F8
          formalParameters
            #E2 requiredPositional x
              firstFragment: #F9
              type: int
            #E3 requiredPositional g
              firstFragment: #F10
              type: int Function(String)
          returnType: void
''');
  }

  test_inferred_type_refers_to_nested_function_typed_param() async {
    var library = await buildLibrary(r'''
f(void g(int x, void h())) => null;
var v = f((x, y) {});
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasImplicitType hasInitializer isOriginDeclaration isStatic v (nameOffset:40) (firstTokenOffset:40) (offset:40)
          element: <testLibrary>::@topLevelVariable::v
          inducedGetter: #F2
          inducedSetter: #F3
      getters
        #F2 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
          element: <testLibrary>::@getter::v
          inducingVariable: #F1
      setters
        #F3 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
          element: <testLibrary>::@setter::v
          inducingVariable: #F1
          formalParameters
            #F4 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
              element: <testLibrary>::@setter::v::@formalParameter::value
      functions
        #F5 hasImplicitReturnType isComplete isOriginDeclaration isStatic f (nameOffset:0) (firstTokenOffset:0) (offset:0)
          element: <testLibrary>::@function::f
          formalParameters
            #F6 requiredPositional isOriginDeclaration g (nameOffset:7) (firstTokenOffset:2) (offset:7)
              element: <testLibrary>::@function::f::@formalParameter::g
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer v
      reference: <testLibrary>::@topLevelVariable::v
      firstFragment: #F1
      type: dynamic
      getter: <testLibrary>::@getter::v
      setter: <testLibrary>::@setter::v
  getters
    isOriginVariable isStatic v
      reference: <testLibrary>::@getter::v
      firstFragment: #F2
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::v
  setters
    isOriginVariable isStatic v
      reference: <testLibrary>::@setter::v
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F4
          type: dynamic
      returnType: void
      variable: <testLibrary>::@topLevelVariable::v
  functions
    isOriginDeclaration isStatic f
      reference: <testLibrary>::@function::f
      firstFragment: #F5
      formalParameters
        #E1 requiredPositional g
          firstFragment: #F6
          type: void Function(int, void Function())
      returnType: dynamic
''');
  }

  test_inferred_type_refers_to_nested_function_typed_param_named() async {
    var library = await buildLibrary(r'''
f({void g(int x, void h())}) => null;
var v = f(g: (x, y) {});
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasImplicitType hasInitializer isOriginDeclaration isStatic v (nameOffset:42) (firstTokenOffset:42) (offset:42)
          element: <testLibrary>::@topLevelVariable::v
          inducedGetter: #F2
          inducedSetter: #F3
      getters
        #F2 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:42)
          element: <testLibrary>::@getter::v
          inducingVariable: #F1
      setters
        #F3 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:42)
          element: <testLibrary>::@setter::v
          inducingVariable: #F1
          formalParameters
            #F4 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:42)
              element: <testLibrary>::@setter::v::@formalParameter::value
      functions
        #F5 hasImplicitReturnType isComplete isOriginDeclaration isStatic f (nameOffset:0) (firstTokenOffset:0) (offset:0)
          element: <testLibrary>::@function::f
          formalParameters
            #F6 optionalNamed isOriginDeclaration g (nameOffset:8) (firstTokenOffset:3) (offset:8)
              element: <testLibrary>::@function::f::@formalParameter::g
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer v
      reference: <testLibrary>::@topLevelVariable::v
      firstFragment: #F1
      type: dynamic
      getter: <testLibrary>::@getter::v
      setter: <testLibrary>::@setter::v
  getters
    isOriginVariable isStatic v
      reference: <testLibrary>::@getter::v
      firstFragment: #F2
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::v
  setters
    isOriginVariable isStatic v
      reference: <testLibrary>::@setter::v
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F4
          type: dynamic
      returnType: void
      variable: <testLibrary>::@topLevelVariable::v
  functions
    isOriginDeclaration isStatic f
      reference: <testLibrary>::@function::f
      firstFragment: #F5
      formalParameters
        #E1 optionalNamed g
          firstFragment: #F6
          type: void Function(int, void Function())
      returnType: dynamic
''');
  }

  test_inferred_type_refers_to_setter_function_typed_parameter_type() async {
    var library = await buildLibrary(r'''
class C extends D {
  void set f(g) {}
}

abstract class D {
  void set f(int g(String s));
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 hasExtendsClause class C (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::C
          fields
            #F2 isOriginGetterSetter f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@field::f
          constructors
            #F3 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          setters
            #F4 isComplete isOriginDeclaration f (nameOffset:31) (firstTokenOffset:22) (offset:31)
              element: <testLibrary>::@class::C::@setter::f
              formalParameters
                #F5 requiredPositional hasImplicitType isOriginDeclaration g (nameOffset:33) (firstTokenOffset:33) (offset:33)
                  element: <testLibrary>::@class::C::@setter::f::@formalParameter::g
        #F6 isAbstract class D (nameOffset:57) (firstTokenOffset:42) (offset:57)
          element: <testLibrary>::@class::D
          fields
            #F7 isOriginGetterSetter f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:57)
              element: <testLibrary>::@class::D::@field::f
          constructors
            #F8 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:57)
              element: <testLibrary>::@class::D::@constructor::new
              typeName: D
          setters
            #F9 isAbstract isOriginDeclaration f (nameOffset:72) (firstTokenOffset:63) (offset:72)
              element: <testLibrary>::@class::D::@setter::f
              formalParameters
                #F10 requiredPositional isOriginDeclaration g (nameOffset:78) (firstTokenOffset:74) (offset:78)
                  element: <testLibrary>::@class::D::@setter::f::@formalParameter::g
  classes
    isSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      supertype: D
      fields
        isOriginGetterSetter f
          reference: <testLibrary>::@class::C::@field::f
          firstFragment: #F2
          type: int Function(String)
          setter: <testLibrary>::@class::C::@setter::f
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
          superConstructor: <testLibrary>::@class::D::@constructor::new
      setters
        isOriginDeclaration f
          reference: <testLibrary>::@class::C::@setter::f
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional hasImplicitType g
              firstFragment: #F5
              type: int Function(String)
          returnType: void
          variable: <testLibrary>::@class::C::@field::f
    isAbstract isSimplyBounded class D
      reference: <testLibrary>::@class::D
      firstFragment: #F6
      fields
        isOriginGetterSetter f
          reference: <testLibrary>::@class::D::@field::f
          firstFragment: #F7
          type: int Function(String)
          setter: <testLibrary>::@class::D::@setter::f
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::D::@constructor::new
          firstFragment: #F8
      setters
        isOriginDeclaration f
          reference: <testLibrary>::@class::D::@setter::f
          firstFragment: #F9
          formalParameters
            #E1 requiredPositional g
              firstFragment: #F10
              type: int Function(String)
          returnType: void
          variable: <testLibrary>::@class::D::@field::f
''');
  }

  test_inferredType_definedInSdkLibraryPart() async {
    newFile('$testPackageLibPath/a.dart', r'''
import 'dart:async';
class A {
  m(Stream p) {}
}
''');
    var library = await buildLibrary(r'''
import 'a.dart';

class B extends A {
  m(p) {}
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart
      classes
        #F1 hasExtendsClause class B (nameOffset:24) (firstTokenOffset:18) (offset:24)
          element: <testLibrary>::@class::B
          constructors
            #F2 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:24)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          methods
            #F3 hasImplicitReturnType isComplete isOriginDeclaration m (nameOffset:40) (firstTokenOffset:40) (offset:40)
              element: <testLibrary>::@class::B::@method::m
              formalParameters
                #F4 requiredPositional hasImplicitType isOriginDeclaration p (nameOffset:42) (firstTokenOffset:42) (offset:42)
                  element: <testLibrary>::@class::B::@method::m::@formalParameter::p
  classes
    isSimplyBounded class B
      reference: <testLibrary>::@class::B
      firstFragment: #F1
      supertype: A
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F2
          superConstructor: package:test/a.dart::@class::A::@constructor::new
      methods
        isOriginDeclaration m
          reference: <testLibrary>::@class::B::@method::m
          firstFragment: #F3
          formalParameters
            #E0 requiredPositional hasImplicitType p
              firstFragment: #F4
              type: Stream<dynamic>
          returnType: dynamic
''');
    var b = library.classes[0];
    var p = b.methods[0].formalParameters[0];
    // This test should verify that we correctly record inferred types,
    // when the type is defined in a part of an SDK library. So, test that
    // the type is actually in a part.
    var streamElement = (p.type as InterfaceType).element;
    expect(
      streamElement.firstFragment.libraryFragment.source,
      isNot(streamElement.library.firstFragment.source),
    );
  }

  test_inferredType_implicitCreation() async {
    var library = await buildLibrary(r'''
class A {
  A();
  A.named();
}

var a1 = A();
var a2 = A.named();
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
          constructors
            #F2 isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:12) (offset:12)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
              typeNameOffset: 12
            #F3 isOriginDeclaration named (nameOffset:21) (firstTokenOffset:19) (offset:21)
              element: <testLibrary>::@class::A::@constructor::named
              typeName: A
              typeNameOffset: 19
              periodOffset: 20
      topLevelVariables
        #F4 hasImplicitType hasInitializer isOriginDeclaration isStatic a1 (nameOffset:37) (firstTokenOffset:37) (offset:37)
          element: <testLibrary>::@topLevelVariable::a1
          inducedGetter: #F5
          inducedSetter: #F6
        #F7 hasImplicitType hasInitializer isOriginDeclaration isStatic a2 (nameOffset:51) (firstTokenOffset:51) (offset:51)
          element: <testLibrary>::@topLevelVariable::a2
          inducedGetter: #F8
          inducedSetter: #F9
      getters
        #F5 isComplete isOriginVariable isStatic a1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:37)
          element: <testLibrary>::@getter::a1
          inducingVariable: #F4
        #F8 isComplete isOriginVariable isStatic a2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:51)
          element: <testLibrary>::@getter::a2
          inducingVariable: #F7
      setters
        #F6 isComplete isOriginVariable isStatic a1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:37)
          element: <testLibrary>::@setter::a1
          inducingVariable: #F4
          formalParameters
            #F10 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:37)
              element: <testLibrary>::@setter::a1::@formalParameter::value
        #F9 isComplete isOriginVariable isStatic a2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:51)
          element: <testLibrary>::@setter::a2
          inducingVariable: #F7
          formalParameters
            #F11 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:51)
              element: <testLibrary>::@setter::a2::@formalParameter::value
  classes
    isSimplyBounded class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        isOriginDeclaration new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
        isOriginDeclaration named
          reference: <testLibrary>::@class::A::@constructor::named
          firstFragment: #F3
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer a1
      reference: <testLibrary>::@topLevelVariable::a1
      firstFragment: #F4
      type: A
      getter: <testLibrary>::@getter::a1
      setter: <testLibrary>::@setter::a1
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer a2
      reference: <testLibrary>::@topLevelVariable::a2
      firstFragment: #F7
      type: A
      getter: <testLibrary>::@getter::a2
      setter: <testLibrary>::@setter::a2
  getters
    isOriginVariable isStatic a1
      reference: <testLibrary>::@getter::a1
      firstFragment: #F5
      returnType: A
      variable: <testLibrary>::@topLevelVariable::a1
    isOriginVariable isStatic a2
      reference: <testLibrary>::@getter::a2
      firstFragment: #F8
      returnType: A
      variable: <testLibrary>::@topLevelVariable::a2
  setters
    isOriginVariable isStatic a1
      reference: <testLibrary>::@setter::a1
      firstFragment: #F6
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F10
          type: A
      returnType: void
      variable: <testLibrary>::@topLevelVariable::a1
    isOriginVariable isStatic a2
      reference: <testLibrary>::@setter::a2
      firstFragment: #F9
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F11
          type: A
      returnType: void
      variable: <testLibrary>::@topLevelVariable::a2
''');
  }

  test_inferredType_implicitCreation_prefixed() async {
    newFile('$testPackageLibPath/foo.dart', r'''
class A {
  A();
  A.named();
}
''');
    var library = await buildLibrary(r'''
import 'foo.dart' as foo;

var a1 = foo.A();
var a2 = foo.A.named();
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/foo.dart as foo (nameOffset:21) (firstTokenOffset:<null>) (offset:21)
      prefixes
        <testLibraryFragment>::@prefix::foo
          fragments: @21
      topLevelVariables
        #F1 hasImplicitType hasInitializer isOriginDeclaration isStatic a1 (nameOffset:31) (firstTokenOffset:31) (offset:31)
          element: <testLibrary>::@topLevelVariable::a1
          inducedGetter: #F2
          inducedSetter: #F3
        #F4 hasImplicitType hasInitializer isOriginDeclaration isStatic a2 (nameOffset:49) (firstTokenOffset:49) (offset:49)
          element: <testLibrary>::@topLevelVariable::a2
          inducedGetter: #F5
          inducedSetter: #F6
      getters
        #F2 isComplete isOriginVariable isStatic a1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
          element: <testLibrary>::@getter::a1
          inducingVariable: #F1
        #F5 isComplete isOriginVariable isStatic a2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:49)
          element: <testLibrary>::@getter::a2
          inducingVariable: #F4
      setters
        #F3 isComplete isOriginVariable isStatic a1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
          element: <testLibrary>::@setter::a1
          inducingVariable: #F1
          formalParameters
            #F7 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
              element: <testLibrary>::@setter::a1::@formalParameter::value
        #F6 isComplete isOriginVariable isStatic a2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:49)
          element: <testLibrary>::@setter::a2
          inducingVariable: #F4
          formalParameters
            #F8 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:49)
              element: <testLibrary>::@setter::a2::@formalParameter::value
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer a1
      reference: <testLibrary>::@topLevelVariable::a1
      firstFragment: #F1
      type: A
      getter: <testLibrary>::@getter::a1
      setter: <testLibrary>::@setter::a1
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer a2
      reference: <testLibrary>::@topLevelVariable::a2
      firstFragment: #F4
      type: A
      getter: <testLibrary>::@getter::a2
      setter: <testLibrary>::@setter::a2
  getters
    isOriginVariable isStatic a1
      reference: <testLibrary>::@getter::a1
      firstFragment: #F2
      returnType: A
      variable: <testLibrary>::@topLevelVariable::a1
    isOriginVariable isStatic a2
      reference: <testLibrary>::@getter::a2
      firstFragment: #F5
      returnType: A
      variable: <testLibrary>::@topLevelVariable::a2
  setters
    isOriginVariable isStatic a1
      reference: <testLibrary>::@setter::a1
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F7
          type: A
      returnType: void
      variable: <testLibrary>::@topLevelVariable::a1
    isOriginVariable isStatic a2
      reference: <testLibrary>::@setter::a2
      firstFragment: #F6
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F8
          type: A
      returnType: void
      variable: <testLibrary>::@topLevelVariable::a2
''');
  }

  test_inferredType_usesSyntheticFunctionType_functionTypedParam() async {
    // AnalysisContext does not set the enclosing element for the synthetic
    // FunctionElement created for the [f, g] type argument.
    var library = await buildLibrary(r'''
int f(int x(String y)) => null;
String g(int x(String y)) => null;
var v = [f, g];
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasImplicitType hasInitializer isOriginDeclaration isStatic v (nameOffset:71) (firstTokenOffset:71) (offset:71)
          element: <testLibrary>::@topLevelVariable::v
          inducedGetter: #F2
          inducedSetter: #F3
      getters
        #F2 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:71)
          element: <testLibrary>::@getter::v
          inducingVariable: #F1
      setters
        #F3 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:71)
          element: <testLibrary>::@setter::v
          inducingVariable: #F1
          formalParameters
            #F4 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:71)
              element: <testLibrary>::@setter::v::@formalParameter::value
      functions
        #F5 isComplete isOriginDeclaration isStatic f (nameOffset:4) (firstTokenOffset:0) (offset:4)
          element: <testLibrary>::@function::f
          formalParameters
            #F6 requiredPositional isOriginDeclaration x (nameOffset:10) (firstTokenOffset:6) (offset:10)
              element: <testLibrary>::@function::f::@formalParameter::x
        #F7 isComplete isOriginDeclaration isStatic g (nameOffset:39) (firstTokenOffset:32) (offset:39)
          element: <testLibrary>::@function::g
          formalParameters
            #F8 requiredPositional isOriginDeclaration x (nameOffset:45) (firstTokenOffset:41) (offset:45)
              element: <testLibrary>::@function::g::@formalParameter::x
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer v
      reference: <testLibrary>::@topLevelVariable::v
      firstFragment: #F1
      type: List<Object Function(int Function(String))>
      getter: <testLibrary>::@getter::v
      setter: <testLibrary>::@setter::v
  getters
    isOriginVariable isStatic v
      reference: <testLibrary>::@getter::v
      firstFragment: #F2
      returnType: List<Object Function(int Function(String))>
      variable: <testLibrary>::@topLevelVariable::v
  setters
    isOriginVariable isStatic v
      reference: <testLibrary>::@setter::v
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F4
          type: List<Object Function(int Function(String))>
      returnType: void
      variable: <testLibrary>::@topLevelVariable::v
  functions
    isOriginDeclaration isStatic f
      reference: <testLibrary>::@function::f
      firstFragment: #F5
      formalParameters
        #E1 requiredPositional x
          firstFragment: #F6
          type: int Function(String)
      returnType: int
    isOriginDeclaration isStatic g
      reference: <testLibrary>::@function::g
      firstFragment: #F7
      formalParameters
        #E2 requiredPositional x
          firstFragment: #F8
          type: int Function(String)
      returnType: String
''');
  }

  test_inheritance_errors() async {
    var library = await buildLibrary(r'''
abstract class A {
  int m();
}

abstract class B {
  String m();
}

abstract class C implements A, B {}

abstract class D extends C {
  var f;
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 isAbstract class A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@class::A
          constructors
            #F2 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          methods
            #F3 isAbstract isOriginDeclaration m (nameOffset:25) (firstTokenOffset:21) (offset:25)
              element: <testLibrary>::@class::A::@method::m
        #F4 isAbstract class B (nameOffset:48) (firstTokenOffset:33) (offset:48)
          element: <testLibrary>::@class::B
          constructors
            #F5 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:48)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          methods
            #F6 isAbstract isOriginDeclaration m (nameOffset:61) (firstTokenOffset:54) (offset:61)
              element: <testLibrary>::@class::B::@method::m
        #F7 isAbstract class C (nameOffset:84) (firstTokenOffset:69) (offset:84)
          element: <testLibrary>::@class::C
          constructors
            #F8 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:84)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
        #F9 hasExtendsClause isAbstract class D (nameOffset:121) (firstTokenOffset:106) (offset:121)
          element: <testLibrary>::@class::D
          fields
            #F10 hasImplicitType isOriginDeclaration f (nameOffset:141) (firstTokenOffset:141) (offset:141)
              element: <testLibrary>::@class::D::@field::f
              inducedGetter: #F11
              inducedSetter: #F12
          constructors
            #F13 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:121)
              element: <testLibrary>::@class::D::@constructor::new
              typeName: D
          getters
            #F11 isComplete isOriginVariable f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:141)
              element: <testLibrary>::@class::D::@getter::f
              inducingVariable: #F10
          setters
            #F12 isComplete isOriginVariable f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:141)
              element: <testLibrary>::@class::D::@setter::f
              inducingVariable: #F10
              formalParameters
                #F14 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:141)
                  element: <testLibrary>::@class::D::@setter::f::@formalParameter::value
  classes
    isAbstract isSimplyBounded class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
      methods
        isOriginDeclaration m
          reference: <testLibrary>::@class::A::@method::m
          firstFragment: #F3
          returnType: int
    isAbstract isSimplyBounded class B
      reference: <testLibrary>::@class::B
      firstFragment: #F4
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F5
      methods
        isOriginDeclaration m
          reference: <testLibrary>::@class::B::@method::m
          firstFragment: #F6
          returnType: String
    isAbstract isSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F7
      interfaces
        A
        B
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F8
    hasNonFinalField isAbstract isSimplyBounded class D
      reference: <testLibrary>::@class::D
      firstFragment: #F9
      supertype: C
      fields
        hasImplicitType isOriginDeclaration f
          reference: <testLibrary>::@class::D::@field::f
          firstFragment: #F10
          type: dynamic
          getter: <testLibrary>::@class::D::@getter::f
          setter: <testLibrary>::@class::D::@setter::f
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::D::@constructor::new
          firstFragment: #F13
          superConstructor: <testLibrary>::@class::C::@constructor::new
      getters
        isOriginVariable f
          reference: <testLibrary>::@class::D::@getter::f
          firstFragment: #F11
          returnType: dynamic
          variable: <testLibrary>::@class::D::@field::f
      setters
        isOriginVariable f
          reference: <testLibrary>::@class::D::@setter::f
          firstFragment: #F12
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F14
              type: dynamic
          returnType: void
          variable: <testLibrary>::@class::D::@field::f
''');
  }

  test_methodInvocation_implicitCall() async {
    var library = await buildLibrary(r'''
class A {
  double call() => 0.0;
}

class B {
  A a;
}

var c = new B().a();
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
          constructors
            #F2 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          methods
            #F3 isComplete isOriginDeclaration call (nameOffset:19) (firstTokenOffset:12) (offset:19)
              element: <testLibrary>::@class::A::@method::call
        #F4 class B (nameOffset:43) (firstTokenOffset:37) (offset:43)
          element: <testLibrary>::@class::B
          fields
            #F5 isOriginDeclaration a (nameOffset:51) (firstTokenOffset:51) (offset:51)
              element: <testLibrary>::@class::B::@field::a
              inducedGetter: #F6
              inducedSetter: #F7
          constructors
            #F8 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:43)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          getters
            #F6 isComplete isOriginVariable a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:51)
              element: <testLibrary>::@class::B::@getter::a
              inducingVariable: #F5
          setters
            #F7 isComplete isOriginVariable a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:51)
              element: <testLibrary>::@class::B::@setter::a
              inducingVariable: #F5
              formalParameters
                #F9 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:51)
                  element: <testLibrary>::@class::B::@setter::a::@formalParameter::value
      topLevelVariables
        #F10 hasImplicitType hasInitializer isOriginDeclaration isStatic c (nameOffset:61) (firstTokenOffset:61) (offset:61)
          element: <testLibrary>::@topLevelVariable::c
          inducedGetter: #F11
          inducedSetter: #F12
      getters
        #F11 isComplete isOriginVariable isStatic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:61)
          element: <testLibrary>::@getter::c
          inducingVariable: #F10
      setters
        #F12 isComplete isOriginVariable isStatic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:61)
          element: <testLibrary>::@setter::c
          inducingVariable: #F10
          formalParameters
            #F13 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:61)
              element: <testLibrary>::@setter::c::@formalParameter::value
  classes
    isSimplyBounded class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
      methods
        isOriginDeclaration call
          reference: <testLibrary>::@class::A::@method::call
          firstFragment: #F3
          returnType: double
    hasNonFinalField isSimplyBounded class B
      reference: <testLibrary>::@class::B
      firstFragment: #F4
      fields
        isOriginDeclaration a
          reference: <testLibrary>::@class::B::@field::a
          firstFragment: #F5
          type: A
          getter: <testLibrary>::@class::B::@getter::a
          setter: <testLibrary>::@class::B::@setter::a
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F8
      getters
        isOriginVariable a
          reference: <testLibrary>::@class::B::@getter::a
          firstFragment: #F6
          returnType: A
          variable: <testLibrary>::@class::B::@field::a
      setters
        isOriginVariable a
          reference: <testLibrary>::@class::B::@setter::a
          firstFragment: #F7
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F9
              type: A
          returnType: void
          variable: <testLibrary>::@class::B::@field::a
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: #F10
      type: double
      getter: <testLibrary>::@getter::c
      setter: <testLibrary>::@setter::c
  getters
    isOriginVariable isStatic c
      reference: <testLibrary>::@getter::c
      firstFragment: #F11
      returnType: double
      variable: <testLibrary>::@topLevelVariable::c
  setters
    isOriginVariable isStatic c
      reference: <testLibrary>::@setter::c
      firstFragment: #F12
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F13
          type: double
      returnType: void
      variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_type_inference_assignmentExpression_references_onTopLevelVariable() async {
    var library = await buildLibrary(r'''
var a = () {
  b += 0;
  return 0;
};
var b = 0;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasImplicitType hasInitializer isOriginDeclaration isStatic a (nameOffset:4) (firstTokenOffset:4) (offset:4)
          element: <testLibrary>::@topLevelVariable::a
          inducedGetter: #F2
          inducedSetter: #F3
        #F4 hasImplicitType hasInitializer isOriginDeclaration isStatic b (nameOffset:42) (firstTokenOffset:42) (offset:42)
          element: <testLibrary>::@topLevelVariable::b
          inducedGetter: #F5
          inducedSetter: #F6
      getters
        #F2 isComplete isOriginVariable isStatic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@getter::a
          inducingVariable: #F1
        #F5 isComplete isOriginVariable isStatic b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:42)
          element: <testLibrary>::@getter::b
          inducingVariable: #F4
      setters
        #F3 isComplete isOriginVariable isStatic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@setter::a
          inducingVariable: #F1
          formalParameters
            #F7 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
              element: <testLibrary>::@setter::a::@formalParameter::value
        #F6 isComplete isOriginVariable isStatic b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:42)
          element: <testLibrary>::@setter::b
          inducingVariable: #F4
          formalParameters
            #F8 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:42)
              element: <testLibrary>::@setter::b::@formalParameter::value
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F1
      type: int Function()
      getter: <testLibrary>::@getter::a
      setter: <testLibrary>::@setter::a
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer b
      reference: <testLibrary>::@topLevelVariable::b
      firstFragment: #F4
      type: int
      getter: <testLibrary>::@getter::b
      setter: <testLibrary>::@setter::b
  getters
    isOriginVariable isStatic a
      reference: <testLibrary>::@getter::a
      firstFragment: #F2
      returnType: int Function()
      variable: <testLibrary>::@topLevelVariable::a
    isOriginVariable isStatic b
      reference: <testLibrary>::@getter::b
      firstFragment: #F5
      returnType: int
      variable: <testLibrary>::@topLevelVariable::b
  setters
    isOriginVariable isStatic a
      reference: <testLibrary>::@setter::a
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F7
          type: int Function()
      returnType: void
      variable: <testLibrary>::@topLevelVariable::a
    isOriginVariable isStatic b
      reference: <testLibrary>::@setter::b
      firstFragment: #F6
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F8
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::b
''');
  }

  test_type_inference_based_on_loadLibrary() async {
    newFile('$testPackageLibPath/a.dart', r'''
''');
    var library = await buildLibrary(r'''
import 'a.dart' deferred as a;

var x = a.loadLibrary;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart deferred as a (nameOffset:28) (firstTokenOffset:<null>) (offset:28)
      prefixes
        <testLibraryFragment>::@prefix::a
          fragments: @28
      topLevelVariables
        #F1 hasImplicitType hasInitializer isOriginDeclaration isStatic x (nameOffset:36) (firstTokenOffset:36) (offset:36)
          element: <testLibrary>::@topLevelVariable::x
          inducedGetter: #F2
          inducedSetter: #F3
      getters
        #F2 isComplete isOriginVariable isStatic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:36)
          element: <testLibrary>::@getter::x
          inducingVariable: #F1
      setters
        #F3 isComplete isOriginVariable isStatic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:36)
          element: <testLibrary>::@setter::x
          inducingVariable: #F1
          formalParameters
            #F4 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:36)
              element: <testLibrary>::@setter::x::@formalParameter::value
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F1
      type: Future<dynamic> Function()
      getter: <testLibrary>::@getter::x
      setter: <testLibrary>::@setter::x
  getters
    isOriginVariable isStatic x
      reference: <testLibrary>::@getter::x
      firstFragment: #F2
      returnType: Future<dynamic> Function()
      variable: <testLibrary>::@topLevelVariable::x
  setters
    isOriginVariable isStatic x
      reference: <testLibrary>::@setter::x
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F4
          type: Future<dynamic> Function()
      returnType: void
      variable: <testLibrary>::@topLevelVariable::x
''');
  }

  test_type_inference_closure_with_function_typed_parameter() async {
    var library = await buildLibrary(r'''
var x = (int f(String x)) => 0;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasImplicitType hasInitializer isOriginDeclaration isStatic x (nameOffset:4) (firstTokenOffset:4) (offset:4)
          element: <testLibrary>::@topLevelVariable::x
          inducedGetter: #F2
          inducedSetter: #F3
      getters
        #F2 isComplete isOriginVariable isStatic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@getter::x
          inducingVariable: #F1
      setters
        #F3 isComplete isOriginVariable isStatic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@setter::x
          inducingVariable: #F1
          formalParameters
            #F4 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
              element: <testLibrary>::@setter::x::@formalParameter::value
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F1
      type: int Function(int Function(String))
      getter: <testLibrary>::@getter::x
      setter: <testLibrary>::@setter::x
  getters
    isOriginVariable isStatic x
      reference: <testLibrary>::@getter::x
      firstFragment: #F2
      returnType: int Function(int Function(String))
      variable: <testLibrary>::@topLevelVariable::x
  setters
    isOriginVariable isStatic x
      reference: <testLibrary>::@setter::x
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F4
          type: int Function(int Function(String))
      returnType: void
      variable: <testLibrary>::@topLevelVariable::x
''');
  }

  test_type_inference_closure_with_function_typed_parameter_new() async {
    var library = await buildLibrary(r'''
var x = (int Function(String) f) => 0;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasImplicitType hasInitializer isOriginDeclaration isStatic x (nameOffset:4) (firstTokenOffset:4) (offset:4)
          element: <testLibrary>::@topLevelVariable::x
          inducedGetter: #F2
          inducedSetter: #F3
      getters
        #F2 isComplete isOriginVariable isStatic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@getter::x
          inducingVariable: #F1
      setters
        #F3 isComplete isOriginVariable isStatic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@setter::x
          inducingVariable: #F1
          formalParameters
            #F4 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
              element: <testLibrary>::@setter::x::@formalParameter::value
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F1
      type: int Function(int Function(String))
      getter: <testLibrary>::@getter::x
      setter: <testLibrary>::@setter::x
  getters
    isOriginVariable isStatic x
      reference: <testLibrary>::@getter::x
      firstFragment: #F2
      returnType: int Function(int Function(String))
      variable: <testLibrary>::@topLevelVariable::x
  setters
    isOriginVariable isStatic x
      reference: <testLibrary>::@setter::x
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F4
          type: int Function(int Function(String))
      returnType: void
      variable: <testLibrary>::@topLevelVariable::x
''');
  }

  test_type_inference_depends_on_exported_variable() async {
    newFile('$testPackageLibPath/a.dart', r'''
export "b.dart";
''');
    newFile('$testPackageLibPath/b.dart', r'''
var x = 0;
''');
    var library = await buildLibrary(r'''
import 'a.dart';

var y = x;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart
      topLevelVariables
        #F1 hasImplicitType hasInitializer isOriginDeclaration isStatic y (nameOffset:22) (firstTokenOffset:22) (offset:22)
          element: <testLibrary>::@topLevelVariable::y
          inducedGetter: #F2
          inducedSetter: #F3
      getters
        #F2 isComplete isOriginVariable isStatic y (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
          element: <testLibrary>::@getter::y
          inducingVariable: #F1
      setters
        #F3 isComplete isOriginVariable isStatic y (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
          element: <testLibrary>::@setter::y
          inducingVariable: #F1
          formalParameters
            #F4 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
              element: <testLibrary>::@setter::y::@formalParameter::value
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer y
      reference: <testLibrary>::@topLevelVariable::y
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::y
      setter: <testLibrary>::@setter::y
  getters
    isOriginVariable isStatic y
      reference: <testLibrary>::@getter::y
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::y
  setters
    isOriginVariable isStatic y
      reference: <testLibrary>::@setter::y
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F4
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::y
''');
  }

  test_type_inference_field_cycle() async {
    var library = await buildLibrary(r'''
class A {
  static final x = y + 1;
  static final y = x + 1;
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
            #F2 hasImplicitType hasInitializer isFinal isOriginDeclaration isStatic x (nameOffset:25) (firstTokenOffset:25) (offset:25)
              element: <testLibrary>::@class::A::@field::x
              inducedGetter: #F3
            #F4 hasImplicitType hasInitializer isFinal isOriginDeclaration isStatic y (nameOffset:51) (firstTokenOffset:51) (offset:51)
              element: <testLibrary>::@class::A::@field::y
              inducedGetter: #F5
          constructors
            #F6 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F3 isComplete isOriginVariable isStatic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
              element: <testLibrary>::@class::A::@getter::x
              inducingVariable: #F2
            #F5 isComplete isOriginVariable isStatic y (nameOffset:<null>) (firstTokenOffset:<null>) (offset:51)
              element: <testLibrary>::@class::A::@getter::y
              inducingVariable: #F4
  classes
    isSimplyBounded class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        hasImplicitType hasInitializer isFinal isOriginDeclaration isStatic x
          reference: <testLibrary>::@class::A::@field::x
          firstFragment: #F2
          typeInferenceError: dependencyCycle
            arguments: [x, y]
          type: dynamic
          getter: <testLibrary>::@class::A::@getter::x
        hasImplicitType hasInitializer isFinal isOriginDeclaration isStatic y
          reference: <testLibrary>::@class::A::@field::y
          firstFragment: #F4
          typeInferenceError: dependencyCycle
            arguments: [x, y]
          type: dynamic
          getter: <testLibrary>::@class::A::@getter::y
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F6
      getters
        isOriginVariable isStatic x
          reference: <testLibrary>::@class::A::@getter::x
          firstFragment: #F3
          returnType: dynamic
          variable: <testLibrary>::@class::A::@field::x
        isOriginVariable isStatic y
          reference: <testLibrary>::@class::A::@getter::y
          firstFragment: #F5
          returnType: dynamic
          variable: <testLibrary>::@class::A::@field::y
''');
  }

  test_type_inference_field_cycle_chain() async {
    var library = await buildLibrary(r'''
class A {
  static final a = b.c;
  static final b = A();
  final c = a;
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
            #F2 hasImplicitType hasInitializer isFinal isOriginDeclaration isStatic a (nameOffset:25) (firstTokenOffset:25) (offset:25)
              element: <testLibrary>::@class::A::@field::a
              inducedGetter: #F3
            #F4 hasImplicitType hasInitializer isFinal isOriginDeclaration isStatic b (nameOffset:49) (firstTokenOffset:49) (offset:49)
              element: <testLibrary>::@class::A::@field::b
              inducedGetter: #F5
            #F6 hasImplicitType hasInitializer isFinal isOriginDeclaration c (nameOffset:66) (firstTokenOffset:66) (offset:66)
              element: <testLibrary>::@class::A::@field::c
              inducedGetter: #F7
          constructors
            #F8 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F3 isComplete isOriginVariable isStatic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
              element: <testLibrary>::@class::A::@getter::a
              inducingVariable: #F2
            #F5 isComplete isOriginVariable isStatic b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:49)
              element: <testLibrary>::@class::A::@getter::b
              inducingVariable: #F4
            #F7 isComplete isOriginVariable c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:66)
              element: <testLibrary>::@class::A::@getter::c
              inducingVariable: #F6
  classes
    isSimplyBounded class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        hasImplicitType hasInitializer isFinal isOriginDeclaration isStatic a
          reference: <testLibrary>::@class::A::@field::a
          firstFragment: #F2
          typeInferenceError: dependencyCycle
            arguments: [a, c]
          type: dynamic
          getter: <testLibrary>::@class::A::@getter::a
        hasImplicitType hasInitializer isFinal isOriginDeclaration isStatic isTypeInferredFromInitializer b
          reference: <testLibrary>::@class::A::@field::b
          firstFragment: #F4
          type: A
          getter: <testLibrary>::@class::A::@getter::b
        hasImplicitType hasInitializer isFinal isOriginDeclaration c
          reference: <testLibrary>::@class::A::@field::c
          firstFragment: #F6
          typeInferenceError: dependencyCycle
            arguments: [a, c]
          type: dynamic
          getter: <testLibrary>::@class::A::@getter::c
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F8
      getters
        isOriginVariable isStatic a
          reference: <testLibrary>::@class::A::@getter::a
          firstFragment: #F3
          returnType: dynamic
          variable: <testLibrary>::@class::A::@field::a
        isOriginVariable isStatic b
          reference: <testLibrary>::@class::A::@getter::b
          firstFragment: #F5
          returnType: A
          variable: <testLibrary>::@class::A::@field::b
        isOriginVariable c
          reference: <testLibrary>::@class::A::@getter::c
          firstFragment: #F7
          returnType: dynamic
          variable: <testLibrary>::@class::A::@field::c
''');
  }

  test_type_inference_field_depends_onFieldFormal() async {
    var library = await buildLibrary(r'''
class A<T> {
  T value;

  A(this.value);
}

class B {
  var a = new A('');
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
          typeParameters
            #F2 T (nameOffset:8) (firstTokenOffset:8) (offset:8)
              element: #E0 T
          fields
            #F3 isOriginDeclaration value (nameOffset:17) (firstTokenOffset:17) (offset:17)
              element: <testLibrary>::@class::A::@field::value
              inducedGetter: #F4
              inducedSetter: #F5
          constructors
            #F6 isComplete isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:27) (offset:27)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
              typeNameOffset: 27
              formalParameters
                #F7 requiredPositional hasImplicitType isFinal isOriginDeclaration this.value (nameOffset:34) (firstTokenOffset:29) (offset:34)
                  element: <testLibrary>::@class::A::@constructor::new::@formalParameter::value
          getters
            #F4 isComplete isOriginVariable value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:17)
              element: <testLibrary>::@class::A::@getter::value
              inducingVariable: #F3
          setters
            #F5 isComplete isOriginVariable value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:17)
              element: <testLibrary>::@class::A::@setter::value
              inducingVariable: #F3
              formalParameters
                #F8 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:17)
                  element: <testLibrary>::@class::A::@setter::value::@formalParameter::value
        #F9 class B (nameOffset:51) (firstTokenOffset:45) (offset:51)
          element: <testLibrary>::@class::B
          fields
            #F10 hasImplicitType hasInitializer isOriginDeclaration a (nameOffset:61) (firstTokenOffset:61) (offset:61)
              element: <testLibrary>::@class::B::@field::a
              inducedGetter: #F11
              inducedSetter: #F12
          constructors
            #F13 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:51)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          getters
            #F11 isComplete isOriginVariable a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:61)
              element: <testLibrary>::@class::B::@getter::a
              inducingVariable: #F10
          setters
            #F12 isComplete isOriginVariable a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:61)
              element: <testLibrary>::@class::B::@setter::a
              inducingVariable: #F10
              formalParameters
                #F14 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:61)
                  element: <testLibrary>::@class::B::@setter::a::@formalParameter::value
  classes
    hasNonFinalField isSimplyBounded class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      fields
        hasEnclosingTypeParameterReference isOriginDeclaration value
          reference: <testLibrary>::@class::A::@field::value
          firstFragment: #F3
          type: T
          getter: <testLibrary>::@class::A::@getter::value
          setter: <testLibrary>::@class::A::@setter::value
      constructors
        hasEnclosingTypeParameterReference isOriginDeclaration new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F6
          formalParameters
            #E1 requiredPositional hasImplicitType isFinal this.value
              firstFragment: #F7
              type: T
              field: <testLibrary>::@class::A::@field::value
      getters
        hasEnclosingTypeParameterReference isOriginVariable value
          reference: <testLibrary>::@class::A::@getter::value
          firstFragment: #F4
          returnType: T
          variable: <testLibrary>::@class::A::@field::value
      setters
        hasEnclosingTypeParameterReference isOriginVariable value
          reference: <testLibrary>::@class::A::@setter::value
          firstFragment: #F5
          formalParameters
            #E2 requiredPositional value
              firstFragment: #F8
              type: T
          returnType: void
          variable: <testLibrary>::@class::A::@field::value
    hasNonFinalField isSimplyBounded class B
      reference: <testLibrary>::@class::B
      firstFragment: #F9
      fields
        hasImplicitType hasInitializer isOriginDeclaration isTypeInferredFromInitializer a
          reference: <testLibrary>::@class::B::@field::a
          firstFragment: #F10
          type: A<String>
          getter: <testLibrary>::@class::B::@getter::a
          setter: <testLibrary>::@class::B::@setter::a
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F13
      getters
        isOriginVariable a
          reference: <testLibrary>::@class::B::@getter::a
          firstFragment: #F11
          returnType: A<String>
          variable: <testLibrary>::@class::B::@field::a
      setters
        isOriginVariable a
          reference: <testLibrary>::@class::B::@setter::a
          firstFragment: #F12
          formalParameters
            #E3 requiredPositional value
              firstFragment: #F14
              type: A<String>
          returnType: void
          variable: <testLibrary>::@class::B::@field::a
''');
  }

  test_type_inference_field_depends_onFieldFormal_withMixinApp() async {
    var library = await buildLibrary(r'''
class A<T> {
  T value;

  A(this.value);
}

class B<T> = A<T> with M;

class C {
  var a = new B(42);
}

mixin M {}
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
          fields
            #F3 isOriginDeclaration value (nameOffset:17) (firstTokenOffset:17) (offset:17)
              element: <testLibrary>::@class::A::@field::value
              inducedGetter: #F4
              inducedSetter: #F5
          constructors
            #F6 isComplete isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:27) (offset:27)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
              typeNameOffset: 27
              formalParameters
                #F7 requiredPositional hasImplicitType isFinal isOriginDeclaration this.value (nameOffset:34) (firstTokenOffset:29) (offset:34)
                  element: <testLibrary>::@class::A::@constructor::new::@formalParameter::value
          getters
            #F4 isComplete isOriginVariable value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:17)
              element: <testLibrary>::@class::A::@getter::value
              inducingVariable: #F3
          setters
            #F5 isComplete isOriginVariable value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:17)
              element: <testLibrary>::@class::A::@setter::value
              inducingVariable: #F3
              formalParameters
                #F8 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:17)
                  element: <testLibrary>::@class::A::@setter::value::@formalParameter::value
        #F9 isMixinApplication class B (nameOffset:51) (firstTokenOffset:45) (offset:51)
          element: <testLibrary>::@class::B
          typeParameters
            #F10 T (nameOffset:53) (firstTokenOffset:53) (offset:53)
              element: #E1 T
          constructors
            #F11 isOriginMixinApplication new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:51)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
              formalParameters
                #F12 requiredPositional isFinal isOriginMixinApplicationClassConstructor value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:51)
                  element: <testLibrary>::@class::B::@constructor::new::@formalParameter::value
        #F13 class C (nameOffset:78) (firstTokenOffset:72) (offset:78)
          element: <testLibrary>::@class::C
          fields
            #F14 hasImplicitType hasInitializer isOriginDeclaration a (nameOffset:88) (firstTokenOffset:88) (offset:88)
              element: <testLibrary>::@class::C::@field::a
              inducedGetter: #F15
              inducedSetter: #F16
          constructors
            #F17 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:78)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F15 isComplete isOriginVariable a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:88)
              element: <testLibrary>::@class::C::@getter::a
              inducingVariable: #F14
          setters
            #F16 isComplete isOriginVariable a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:88)
              element: <testLibrary>::@class::C::@setter::a
              inducingVariable: #F14
              formalParameters
                #F18 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:88)
                  element: <testLibrary>::@class::C::@setter::a::@formalParameter::value
      mixins
        #F19 mixin M (nameOffset:112) (firstTokenOffset:106) (offset:112)
          element: <testLibrary>::@mixin::M
  classes
    hasNonFinalField isSimplyBounded class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      fields
        hasEnclosingTypeParameterReference isOriginDeclaration value
          reference: <testLibrary>::@class::A::@field::value
          firstFragment: #F3
          type: T
          getter: <testLibrary>::@class::A::@getter::value
          setter: <testLibrary>::@class::A::@setter::value
      constructors
        hasEnclosingTypeParameterReference isOriginDeclaration new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F6
          formalParameters
            #E2 requiredPositional hasImplicitType isFinal this.value
              firstFragment: #F7
              type: T
              field: <testLibrary>::@class::A::@field::value
      getters
        hasEnclosingTypeParameterReference isOriginVariable value
          reference: <testLibrary>::@class::A::@getter::value
          firstFragment: #F4
          returnType: T
          variable: <testLibrary>::@class::A::@field::value
      setters
        hasEnclosingTypeParameterReference isOriginVariable value
          reference: <testLibrary>::@class::A::@setter::value
          firstFragment: #F5
          formalParameters
            #E3 requiredPositional value
              firstFragment: #F8
              type: T
          returnType: void
          variable: <testLibrary>::@class::A::@field::value
    hasNonFinalField isMixinApplication isSimplyBounded class B
      reference: <testLibrary>::@class::B
      firstFragment: #F9
      typeParameters
        #E1 T
          firstFragment: #F10
      supertype: A<T>
      mixins
        M
      constructors
        hasEnclosingTypeParameterReference isOriginMixinApplication new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F11
          formalParameters
            #E4 requiredPositional isFinal value
              firstFragment: #F12
              type: T
          constantInitializers
            SuperConstructorInvocation
              superKeyword: super @0
              argumentList: ArgumentList
                leftParenthesis: ( @0
                arguments
                  SimpleIdentifier
                    token: value @-1
                    element: <testLibrary>::@class::B::@constructor::new::@formalParameter::value
                    staticType: T
                rightParenthesis: ) @0
              element: <testLibrary>::@class::A::@constructor::new
          superConstructor: SubstitutedConstructorElementImpl
            baseElement: <testLibrary>::@class::A::@constructor::new
            substitution: {T: T}
    hasNonFinalField isSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F13
      fields
        hasImplicitType hasInitializer isOriginDeclaration isTypeInferredFromInitializer a
          reference: <testLibrary>::@class::C::@field::a
          firstFragment: #F14
          type: B<int>
          getter: <testLibrary>::@class::C::@getter::a
          setter: <testLibrary>::@class::C::@setter::a
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F17
      getters
        isOriginVariable a
          reference: <testLibrary>::@class::C::@getter::a
          firstFragment: #F15
          returnType: B<int>
          variable: <testLibrary>::@class::C::@field::a
      setters
        isOriginVariable a
          reference: <testLibrary>::@class::C::@setter::a
          firstFragment: #F16
          formalParameters
            #E5 requiredPositional value
              firstFragment: #F18
              type: B<int>
          returnType: void
          variable: <testLibrary>::@class::C::@field::a
  mixins
    isSimplyBounded mixin M
      reference: <testLibrary>::@mixin::M
      firstFragment: #F19
      superclassConstraints
        Object
''');
  }

  test_type_inference_fieldFormal_depends_onField() async {
    var library = await buildLibrary(r'''
class A<T> {
  var f = 0;
  A(this.f);
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
          typeParameters
            #F2 T (nameOffset:8) (firstTokenOffset:8) (offset:8)
              element: #E0 T
          fields
            #F3 hasImplicitType hasInitializer isOriginDeclaration f (nameOffset:19) (firstTokenOffset:19) (offset:19)
              element: <testLibrary>::@class::A::@field::f
              inducedGetter: #F4
              inducedSetter: #F5
          constructors
            #F6 isComplete isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:28) (offset:28)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
              typeNameOffset: 28
              formalParameters
                #F7 requiredPositional hasImplicitType isFinal isOriginDeclaration this.f (nameOffset:35) (firstTokenOffset:30) (offset:35)
                  element: <testLibrary>::@class::A::@constructor::new::@formalParameter::f
          getters
            #F4 isComplete isOriginVariable f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:19)
              element: <testLibrary>::@class::A::@getter::f
              inducingVariable: #F3
          setters
            #F5 isComplete isOriginVariable f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:19)
              element: <testLibrary>::@class::A::@setter::f
              inducingVariable: #F3
              formalParameters
                #F8 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:19)
                  element: <testLibrary>::@class::A::@setter::f::@formalParameter::value
  classes
    hasNonFinalField isSimplyBounded class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      fields
        hasImplicitType hasInitializer isOriginDeclaration isTypeInferredFromInitializer f
          reference: <testLibrary>::@class::A::@field::f
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@class::A::@getter::f
          setter: <testLibrary>::@class::A::@setter::f
      constructors
        hasEnclosingTypeParameterReference isOriginDeclaration new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F6
          formalParameters
            #E1 requiredPositional hasImplicitType isFinal this.f
              firstFragment: #F7
              type: int
              field: <testLibrary>::@class::A::@field::f
      getters
        isOriginVariable f
          reference: <testLibrary>::@class::A::@getter::f
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@class::A::@field::f
      setters
        isOriginVariable f
          reference: <testLibrary>::@class::A::@setter::f
          firstFragment: #F5
          formalParameters
            #E2 requiredPositional value
              firstFragment: #F8
              type: int
          returnType: void
          variable: <testLibrary>::@class::A::@field::f
''');
  }

  test_type_inference_instanceCreation_notGeneric() async {
    var library = await buildLibrary(r'''
class A {
  A(_);
}

final a = A(() => b);
final b = A(() => a);
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
          constructors
            #F2 isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:12) (offset:12)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
              typeNameOffset: 12
              formalParameters
                #F3 requiredPositional hasImplicitType isOriginDeclaration _ (nameOffset:14) (firstTokenOffset:14) (offset:14)
                  element: <testLibrary>::@class::A::@constructor::new::@formalParameter::_
      topLevelVariables
        #F4 hasImplicitType hasInitializer isFinal isOriginDeclaration isStatic a (nameOffset:27) (firstTokenOffset:27) (offset:27)
          element: <testLibrary>::@topLevelVariable::a
          inducedGetter: #F5
        #F6 hasImplicitType hasInitializer isFinal isOriginDeclaration isStatic b (nameOffset:49) (firstTokenOffset:49) (offset:49)
          element: <testLibrary>::@topLevelVariable::b
          inducedGetter: #F7
      getters
        #F5 isComplete isOriginVariable isStatic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:27)
          element: <testLibrary>::@getter::a
          inducingVariable: #F4
        #F7 isComplete isOriginVariable isStatic b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:49)
          element: <testLibrary>::@getter::b
          inducingVariable: #F6
  classes
    isSimplyBounded class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        isOriginDeclaration new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
          formalParameters
            #E0 requiredPositional hasImplicitType _
              firstFragment: #F3
              type: dynamic
  topLevelVariables
    hasImplicitType hasInitializer isFinal isOriginDeclaration isStatic a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F4
      typeInferenceError: dependencyCycle
        arguments: [a, b]
      type: dynamic
      getter: <testLibrary>::@getter::a
    hasImplicitType hasInitializer isFinal isOriginDeclaration isStatic b
      reference: <testLibrary>::@topLevelVariable::b
      firstFragment: #F6
      typeInferenceError: dependencyCycle
        arguments: [a, b]
      type: dynamic
      getter: <testLibrary>::@getter::b
  getters
    isOriginVariable isStatic a
      reference: <testLibrary>::@getter::a
      firstFragment: #F5
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::a
    isOriginVariable isStatic b
      reference: <testLibrary>::@getter::b
      firstFragment: #F7
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::b
''');
  }

  test_type_inference_multiplyDefinedElement() async {
    newFile('$testPackageLibPath/a.dart', r'''
class C {}
''');
    newFile('$testPackageLibPath/b.dart', r'''
class C {}
''');
    var library = await buildLibrary(r'''
import 'a.dart';
import 'b.dart';

var v = C;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart
        package:test/b.dart
      topLevelVariables
        #F1 hasImplicitType hasInitializer isOriginDeclaration isStatic v (nameOffset:39) (firstTokenOffset:39) (offset:39)
          element: <testLibrary>::@topLevelVariable::v
          inducedGetter: #F2
          inducedSetter: #F3
      getters
        #F2 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:39)
          element: <testLibrary>::@getter::v
          inducingVariable: #F1
      setters
        #F3 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:39)
          element: <testLibrary>::@setter::v
          inducingVariable: #F1
          formalParameters
            #F4 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:39)
              element: <testLibrary>::@setter::v::@formalParameter::value
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer v
      reference: <testLibrary>::@topLevelVariable::v
      firstFragment: #F1
      type: InvalidType
      getter: <testLibrary>::@getter::v
      setter: <testLibrary>::@setter::v
  getters
    isOriginVariable isStatic v
      reference: <testLibrary>::@getter::v
      firstFragment: #F2
      returnType: InvalidType
      variable: <testLibrary>::@topLevelVariable::v
  setters
    isOriginVariable isStatic v
      reference: <testLibrary>::@setter::v
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F4
          type: InvalidType
      returnType: void
      variable: <testLibrary>::@topLevelVariable::v
''');
  }

  test_type_inference_nested_function() async {
    var library = await buildLibrary(r'''
var x = (t) =>
    (u) => t + u;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasImplicitType hasInitializer isOriginDeclaration isStatic x (nameOffset:4) (firstTokenOffset:4) (offset:4)
          element: <testLibrary>::@topLevelVariable::x
          inducedGetter: #F2
          inducedSetter: #F3
      getters
        #F2 isComplete isOriginVariable isStatic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@getter::x
          inducingVariable: #F1
      setters
        #F3 isComplete isOriginVariable isStatic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@setter::x
          inducingVariable: #F1
          formalParameters
            #F4 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
              element: <testLibrary>::@setter::x::@formalParameter::value
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F1
      type: dynamic Function(dynamic) Function(dynamic)
      getter: <testLibrary>::@getter::x
      setter: <testLibrary>::@setter::x
  getters
    isOriginVariable isStatic x
      reference: <testLibrary>::@getter::x
      firstFragment: #F2
      returnType: dynamic Function(dynamic) Function(dynamic)
      variable: <testLibrary>::@topLevelVariable::x
  setters
    isOriginVariable isStatic x
      reference: <testLibrary>::@setter::x
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F4
          type: dynamic Function(dynamic) Function(dynamic)
      returnType: void
      variable: <testLibrary>::@topLevelVariable::x
''');
  }

  test_type_inference_nested_function_with_parameter_types() async {
    var library = await buildLibrary(r'''
var x = (int t) =>
    (int u) => t + u;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasImplicitType hasInitializer isOriginDeclaration isStatic x (nameOffset:4) (firstTokenOffset:4) (offset:4)
          element: <testLibrary>::@topLevelVariable::x
          inducedGetter: #F2
          inducedSetter: #F3
      getters
        #F2 isComplete isOriginVariable isStatic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@getter::x
          inducingVariable: #F1
      setters
        #F3 isComplete isOriginVariable isStatic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@setter::x
          inducingVariable: #F1
          formalParameters
            #F4 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
              element: <testLibrary>::@setter::x::@formalParameter::value
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F1
      type: int Function(int) Function(int)
      getter: <testLibrary>::@getter::x
      setter: <testLibrary>::@setter::x
  getters
    isOriginVariable isStatic x
      reference: <testLibrary>::@getter::x
      firstFragment: #F2
      returnType: int Function(int) Function(int)
      variable: <testLibrary>::@topLevelVariable::x
  setters
    isOriginVariable isStatic x
      reference: <testLibrary>::@setter::x
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F4
          type: int Function(int) Function(int)
      returnType: void
      variable: <testLibrary>::@topLevelVariable::x
''');
  }

  test_type_inference_of_closure_with_default_value() async {
    var library = await buildLibrary(r'''
var x = ([y: 0]) => y;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasImplicitType hasInitializer isOriginDeclaration isStatic x (nameOffset:4) (firstTokenOffset:4) (offset:4)
          element: <testLibrary>::@topLevelVariable::x
          inducedGetter: #F2
          inducedSetter: #F3
      getters
        #F2 isComplete isOriginVariable isStatic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@getter::x
          inducingVariable: #F1
      setters
        #F3 isComplete isOriginVariable isStatic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@setter::x
          inducingVariable: #F1
          formalParameters
            #F4 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
              element: <testLibrary>::@setter::x::@formalParameter::value
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F1
      type: dynamic Function([dynamic])
      getter: <testLibrary>::@getter::x
      setter: <testLibrary>::@setter::x
  getters
    isOriginVariable isStatic x
      reference: <testLibrary>::@getter::x
      firstFragment: #F2
      returnType: dynamic Function([dynamic])
      variable: <testLibrary>::@topLevelVariable::x
  setters
    isOriginVariable isStatic x
      reference: <testLibrary>::@setter::x
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F4
          type: dynamic Function([dynamic])
      returnType: void
      variable: <testLibrary>::@topLevelVariable::x
''');
  }

  test_type_inference_topVariable_cycle_afterChain() async {
    // Note that `a` depends on `b`, but does not belong to the cycle.
    var library = await buildLibrary(r'''
final a = b;
final b = c;
final c = b;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasImplicitType hasInitializer isFinal isOriginDeclaration isStatic a (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::a
          inducedGetter: #F2
        #F3 hasImplicitType hasInitializer isFinal isOriginDeclaration isStatic b (nameOffset:19) (firstTokenOffset:19) (offset:19)
          element: <testLibrary>::@topLevelVariable::b
          inducedGetter: #F4
        #F5 hasImplicitType hasInitializer isFinal isOriginDeclaration isStatic c (nameOffset:32) (firstTokenOffset:32) (offset:32)
          element: <testLibrary>::@topLevelVariable::c
          inducedGetter: #F6
      getters
        #F2 isComplete isOriginVariable isStatic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
          inducingVariable: #F1
        #F4 isComplete isOriginVariable isStatic b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:19)
          element: <testLibrary>::@getter::b
          inducingVariable: #F3
        #F6 isComplete isOriginVariable isStatic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:32)
          element: <testLibrary>::@getter::c
          inducingVariable: #F5
  topLevelVariables
    hasImplicitType hasInitializer isFinal isOriginDeclaration isStatic isTypeInferredFromInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F1
      type: dynamic
      getter: <testLibrary>::@getter::a
    hasImplicitType hasInitializer isFinal isOriginDeclaration isStatic b
      reference: <testLibrary>::@topLevelVariable::b
      firstFragment: #F3
      typeInferenceError: dependencyCycle
        arguments: [b, c]
      type: dynamic
      getter: <testLibrary>::@getter::b
    hasImplicitType hasInitializer isFinal isOriginDeclaration isStatic c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: #F5
      typeInferenceError: dependencyCycle
        arguments: [b, c]
      type: dynamic
      getter: <testLibrary>::@getter::c
  getters
    isOriginVariable isStatic a
      reference: <testLibrary>::@getter::a
      firstFragment: #F2
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::a
    isOriginVariable isStatic b
      reference: <testLibrary>::@getter::b
      firstFragment: #F4
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::b
    isOriginVariable isStatic c
      reference: <testLibrary>::@getter::c
      firstFragment: #F6
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_type_inference_topVariable_cycle_beforeChain() async {
    // Note that `c` depends on `b`, but does not belong to the cycle.
    var library = await buildLibrary(r'''
final a = b;
final b = a;
final c = b;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasImplicitType hasInitializer isFinal isOriginDeclaration isStatic a (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::a
          inducedGetter: #F2
        #F3 hasImplicitType hasInitializer isFinal isOriginDeclaration isStatic b (nameOffset:19) (firstTokenOffset:19) (offset:19)
          element: <testLibrary>::@topLevelVariable::b
          inducedGetter: #F4
        #F5 hasImplicitType hasInitializer isFinal isOriginDeclaration isStatic c (nameOffset:32) (firstTokenOffset:32) (offset:32)
          element: <testLibrary>::@topLevelVariable::c
          inducedGetter: #F6
      getters
        #F2 isComplete isOriginVariable isStatic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
          inducingVariable: #F1
        #F4 isComplete isOriginVariable isStatic b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:19)
          element: <testLibrary>::@getter::b
          inducingVariable: #F3
        #F6 isComplete isOriginVariable isStatic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:32)
          element: <testLibrary>::@getter::c
          inducingVariable: #F5
  topLevelVariables
    hasImplicitType hasInitializer isFinal isOriginDeclaration isStatic a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F1
      typeInferenceError: dependencyCycle
        arguments: [a, b]
      type: dynamic
      getter: <testLibrary>::@getter::a
    hasImplicitType hasInitializer isFinal isOriginDeclaration isStatic b
      reference: <testLibrary>::@topLevelVariable::b
      firstFragment: #F3
      typeInferenceError: dependencyCycle
        arguments: [a, b]
      type: dynamic
      getter: <testLibrary>::@getter::b
    hasImplicitType hasInitializer isFinal isOriginDeclaration isStatic isTypeInferredFromInitializer c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: #F5
      type: dynamic
      getter: <testLibrary>::@getter::c
  getters
    isOriginVariable isStatic a
      reference: <testLibrary>::@getter::a
      firstFragment: #F2
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::a
    isOriginVariable isStatic b
      reference: <testLibrary>::@getter::b
      firstFragment: #F4
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::b
    isOriginVariable isStatic c
      reference: <testLibrary>::@getter::c
      firstFragment: #F6
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_type_inference_topVariable_cycle_inCycle() async {
    // `b` and `c` form a cycle.
    // `a` and `d` form a different cycle, even though `a` references `b`.
    var library = await buildLibrary(r'''
final a = b + d;
final b = c;
final c = b;
final d = a;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasImplicitType hasInitializer isFinal isOriginDeclaration isStatic a (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::a
          inducedGetter: #F2
        #F3 hasImplicitType hasInitializer isFinal isOriginDeclaration isStatic b (nameOffset:23) (firstTokenOffset:23) (offset:23)
          element: <testLibrary>::@topLevelVariable::b
          inducedGetter: #F4
        #F5 hasImplicitType hasInitializer isFinal isOriginDeclaration isStatic c (nameOffset:36) (firstTokenOffset:36) (offset:36)
          element: <testLibrary>::@topLevelVariable::c
          inducedGetter: #F6
        #F7 hasImplicitType hasInitializer isFinal isOriginDeclaration isStatic d (nameOffset:49) (firstTokenOffset:49) (offset:49)
          element: <testLibrary>::@topLevelVariable::d
          inducedGetter: #F8
      getters
        #F2 isComplete isOriginVariable isStatic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
          inducingVariable: #F1
        #F4 isComplete isOriginVariable isStatic b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
          element: <testLibrary>::@getter::b
          inducingVariable: #F3
        #F6 isComplete isOriginVariable isStatic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:36)
          element: <testLibrary>::@getter::c
          inducingVariable: #F5
        #F8 isComplete isOriginVariable isStatic d (nameOffset:<null>) (firstTokenOffset:<null>) (offset:49)
          element: <testLibrary>::@getter::d
          inducingVariable: #F7
  topLevelVariables
    hasImplicitType hasInitializer isFinal isOriginDeclaration isStatic a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F1
      typeInferenceError: dependencyCycle
        arguments: [a, d]
      type: dynamic
      getter: <testLibrary>::@getter::a
    hasImplicitType hasInitializer isFinal isOriginDeclaration isStatic b
      reference: <testLibrary>::@topLevelVariable::b
      firstFragment: #F3
      typeInferenceError: dependencyCycle
        arguments: [b, c]
      type: dynamic
      getter: <testLibrary>::@getter::b
    hasImplicitType hasInitializer isFinal isOriginDeclaration isStatic c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: #F5
      typeInferenceError: dependencyCycle
        arguments: [b, c]
      type: dynamic
      getter: <testLibrary>::@getter::c
    hasImplicitType hasInitializer isFinal isOriginDeclaration isStatic d
      reference: <testLibrary>::@topLevelVariable::d
      firstFragment: #F7
      typeInferenceError: dependencyCycle
        arguments: [a, d]
      type: dynamic
      getter: <testLibrary>::@getter::d
  getters
    isOriginVariable isStatic a
      reference: <testLibrary>::@getter::a
      firstFragment: #F2
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::a
    isOriginVariable isStatic b
      reference: <testLibrary>::@getter::b
      firstFragment: #F4
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::b
    isOriginVariable isStatic c
      reference: <testLibrary>::@getter::c
      firstFragment: #F6
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::c
    isOriginVariable isStatic d
      reference: <testLibrary>::@getter::d
      firstFragment: #F8
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::d
''');
  }

  test_type_inference_topVariable_cycle_sharedElement() async {
    // 1. Push `a`, start resolving.
    // 2. Go to `b`, push, start resolving.
    // 3. Go to `c`, push, start resolving.
    // 4. Go to `b`, detect cycle `[b, c]`, set `dynamic`, return.
    // 5. Pop `c`, already inferred (to `dynamic`), return.
    // 6. Continue resolving `b` (it is not done, and not popped yet).
    // 7. Go to `a`, detect cycle `[a, b]`, set `dynamic`, return.
    var library = await buildLibrary(r'''
final a = b;
final b = c + a;
final c = b;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasImplicitType hasInitializer isFinal isOriginDeclaration isStatic a (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::a
          inducedGetter: #F2
        #F3 hasImplicitType hasInitializer isFinal isOriginDeclaration isStatic b (nameOffset:19) (firstTokenOffset:19) (offset:19)
          element: <testLibrary>::@topLevelVariable::b
          inducedGetter: #F4
        #F5 hasImplicitType hasInitializer isFinal isOriginDeclaration isStatic c (nameOffset:36) (firstTokenOffset:36) (offset:36)
          element: <testLibrary>::@topLevelVariable::c
          inducedGetter: #F6
      getters
        #F2 isComplete isOriginVariable isStatic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
          inducingVariable: #F1
        #F4 isComplete isOriginVariable isStatic b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:19)
          element: <testLibrary>::@getter::b
          inducingVariable: #F3
        #F6 isComplete isOriginVariable isStatic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:36)
          element: <testLibrary>::@getter::c
          inducingVariable: #F5
  topLevelVariables
    hasImplicitType hasInitializer isFinal isOriginDeclaration isStatic a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F1
      typeInferenceError: dependencyCycle
        arguments: [a, b]
      type: dynamic
      getter: <testLibrary>::@getter::a
    hasImplicitType hasInitializer isFinal isOriginDeclaration isStatic b
      reference: <testLibrary>::@topLevelVariable::b
      firstFragment: #F3
      typeInferenceError: dependencyCycle
        arguments: [b, c]
      type: dynamic
      getter: <testLibrary>::@getter::b
    hasImplicitType hasInitializer isFinal isOriginDeclaration isStatic c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: #F5
      typeInferenceError: dependencyCycle
        arguments: [b, c]
      type: dynamic
      getter: <testLibrary>::@getter::c
  getters
    isOriginVariable isStatic a
      reference: <testLibrary>::@getter::a
      firstFragment: #F2
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::a
    isOriginVariable isStatic b
      reference: <testLibrary>::@getter::b
      firstFragment: #F4
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::b
    isOriginVariable isStatic c
      reference: <testLibrary>::@getter::c
      firstFragment: #F6
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_type_inference_topVariable_depends_onFieldFormal() async {
    var library = await buildLibrary(r'''
class A {}

class B extends A {}

class C<T extends A> {
  final T f;
  const C(this.f);
}

final b = B();
final c = C(b);
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
          constructors
            #F2 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
        #F3 hasExtendsClause class B (nameOffset:18) (firstTokenOffset:12) (offset:18)
          element: <testLibrary>::@class::B
          constructors
            #F4 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:18)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
        #F5 class C (nameOffset:40) (firstTokenOffset:34) (offset:40)
          element: <testLibrary>::@class::C
          typeParameters
            #F6 T (nameOffset:42) (firstTokenOffset:42) (offset:42)
              element: #E0 T
          fields
            #F7 isFinal isOriginDeclaration f (nameOffset:67) (firstTokenOffset:67) (offset:67)
              element: <testLibrary>::@class::C::@field::f
              inducedGetter: #F8
          constructors
            #F9 isComplete isConst isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:72) (offset:78)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
              typeNameOffset: 78
              formalParameters
                #F10 requiredPositional hasImplicitType isFinal isOriginDeclaration this.f (nameOffset:85) (firstTokenOffset:80) (offset:85)
                  element: <testLibrary>::@class::C::@constructor::new::@formalParameter::f
          getters
            #F8 isComplete isOriginVariable f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:67)
              element: <testLibrary>::@class::C::@getter::f
              inducingVariable: #F7
      topLevelVariables
        #F11 hasImplicitType hasInitializer isFinal isOriginDeclaration isStatic b (nameOffset:98) (firstTokenOffset:98) (offset:98)
          element: <testLibrary>::@topLevelVariable::b
          inducedGetter: #F12
        #F13 hasImplicitType hasInitializer isFinal isOriginDeclaration isStatic c (nameOffset:113) (firstTokenOffset:113) (offset:113)
          element: <testLibrary>::@topLevelVariable::c
          inducedGetter: #F14
      getters
        #F12 isComplete isOriginVariable isStatic b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:98)
          element: <testLibrary>::@getter::b
          inducingVariable: #F11
        #F14 isComplete isOriginVariable isStatic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:113)
          element: <testLibrary>::@getter::c
          inducingVariable: #F13
  classes
    isSimplyBounded class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
    isSimplyBounded class B
      reference: <testLibrary>::@class::B
      firstFragment: #F3
      supertype: A
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F4
          superConstructor: <testLibrary>::@class::A::@constructor::new
    isSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F5
      typeParameters
        #E0 T
          firstFragment: #F6
          bound: A
      fields
        hasEnclosingTypeParameterReference isFinal isOriginDeclaration f
          reference: <testLibrary>::@class::C::@field::f
          firstFragment: #F7
          type: T
          getter: <testLibrary>::@class::C::@getter::f
      constructors
        hasEnclosingTypeParameterReference isConst isOriginDeclaration new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F9
          formalParameters
            #E1 requiredPositional hasImplicitType isFinal this.f
              firstFragment: #F10
              type: T
              field: <testLibrary>::@class::C::@field::f
      getters
        hasEnclosingTypeParameterReference isOriginVariable f
          reference: <testLibrary>::@class::C::@getter::f
          firstFragment: #F8
          returnType: T
          variable: <testLibrary>::@class::C::@field::f
  topLevelVariables
    hasImplicitType hasInitializer isFinal isOriginDeclaration isStatic isTypeInferredFromInitializer b
      reference: <testLibrary>::@topLevelVariable::b
      firstFragment: #F11
      type: B
      getter: <testLibrary>::@getter::b
    hasImplicitType hasInitializer isFinal isOriginDeclaration isStatic isTypeInferredFromInitializer c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: #F13
      type: C<B>
      getter: <testLibrary>::@getter::c
  getters
    isOriginVariable isStatic b
      reference: <testLibrary>::@getter::b
      firstFragment: #F12
      returnType: B
      variable: <testLibrary>::@topLevelVariable::b
    isOriginVariable isStatic c
      reference: <testLibrary>::@getter::c
      firstFragment: #F14
      returnType: C<B>
      variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_type_inference_using_extension_getter() async {
    var library = await buildLibrary(r'''
extension on String {
  int get foo => 0;
}

var v = 'a'.foo;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      extensions
        #F1 extension <null-name> (nameOffset:<null>) (firstTokenOffset:0) (offset:0)
          element: <testLibrary>::@extension::#0
          fields
            #F2 isOriginGetterSetter foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:0)
              element: <testLibrary>::@extension::#0::@field::foo
          getters
            #F3 isComplete isOriginDeclaration foo (nameOffset:32) (firstTokenOffset:24) (offset:32)
              element: <testLibrary>::@extension::#0::@getter::foo
      topLevelVariables
        #F4 hasImplicitType hasInitializer isOriginDeclaration isStatic v (nameOffset:49) (firstTokenOffset:49) (offset:49)
          element: <testLibrary>::@topLevelVariable::v
          inducedGetter: #F5
          inducedSetter: #F6
      getters
        #F5 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:49)
          element: <testLibrary>::@getter::v
          inducingVariable: #F4
      setters
        #F6 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:49)
          element: <testLibrary>::@setter::v
          inducingVariable: #F4
          formalParameters
            #F7 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:49)
              element: <testLibrary>::@setter::v::@formalParameter::value
  extensions
    extension <null-name>
      reference: <testLibrary>::@extension::#0
      firstFragment: #F1
      extendedType: String
      onDeclaration: dart:core::@class::String
      fields
        isOriginGetterSetter foo
          reference: <testLibrary>::@extension::#0::@field::foo
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extension::#0::@getter::foo
      getters
        isOriginDeclaration foo
          reference: <testLibrary>::@extension::#0::@getter::foo
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@extension::#0::@field::foo
  topLevelVariables
    hasImplicitType hasInitializer isOriginDeclaration isStatic isTypeInferredFromInitializer v
      reference: <testLibrary>::@topLevelVariable::v
      firstFragment: #F4
      type: int
      getter: <testLibrary>::@getter::v
      setter: <testLibrary>::@setter::v
  getters
    isOriginVariable isStatic v
      reference: <testLibrary>::@getter::v
      firstFragment: #F5
      returnType: int
      variable: <testLibrary>::@topLevelVariable::v
  setters
    isOriginVariable isStatic v
      reference: <testLibrary>::@setter::v
      firstFragment: #F6
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F7
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::v
''');
  }

  test_type_invalid_topLevelVariableElement_asType() async {
    var library = await buildLibrary(r'''
class C<T extends V> {}

typedef V F(V p);
V f(V p) {}
V V2 = null;
int V = 0;
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
          typeParameters
            #F2 T (nameOffset:8) (firstTokenOffset:8) (offset:8)
              element: #E0 T
          constructors
            #F3 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
      typeAliases
        #F4 F (nameOffset:35) (firstTokenOffset:25) (offset:35)
          element: <testLibrary>::@typeAlias::F
      topLevelVariables
        #F5 hasInitializer isOriginDeclaration isStatic V2 (nameOffset:57) (firstTokenOffset:57) (offset:57)
          element: <testLibrary>::@topLevelVariable::V2
          inducedGetter: #F6
          inducedSetter: #F7
        #F8 hasInitializer isOriginDeclaration isStatic V (nameOffset:72) (firstTokenOffset:72) (offset:72)
          element: <testLibrary>::@topLevelVariable::V
          inducedGetter: #F9
          inducedSetter: #F10
      getters
        #F6 isComplete isOriginVariable isStatic V2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:57)
          element: <testLibrary>::@getter::V2
          inducingVariable: #F5
        #F9 isComplete isOriginVariable isStatic V (nameOffset:<null>) (firstTokenOffset:<null>) (offset:72)
          element: <testLibrary>::@getter::V
          inducingVariable: #F8
      setters
        #F7 isComplete isOriginVariable isStatic V2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:57)
          element: <testLibrary>::@setter::V2
          inducingVariable: #F5
          formalParameters
            #F11 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:57)
              element: <testLibrary>::@setter::V2::@formalParameter::value
        #F10 isComplete isOriginVariable isStatic V (nameOffset:<null>) (firstTokenOffset:<null>) (offset:72)
          element: <testLibrary>::@setter::V
          inducingVariable: #F8
          formalParameters
            #F12 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:72)
              element: <testLibrary>::@setter::V::@formalParameter::value
      functions
        #F13 isComplete isOriginDeclaration isStatic f (nameOffset:45) (firstTokenOffset:43) (offset:45)
          element: <testLibrary>::@function::f
          formalParameters
            #F14 requiredPositional isOriginDeclaration p (nameOffset:49) (firstTokenOffset:47) (offset:49)
              element: <testLibrary>::@function::f::@formalParameter::p
  classes
    isSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
          bound: InvalidType
      constructors
        hasEnclosingTypeParameterReference isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
  typeAliases
    isSimplyBounded F
      reference: <testLibrary>::@typeAlias::F
      firstFragment: #F4
      aliasedType: InvalidType Function(InvalidType)
  topLevelVariables
    hasInitializer isOriginDeclaration isStatic V2
      reference: <testLibrary>::@topLevelVariable::V2
      firstFragment: #F5
      type: InvalidType
      getter: <testLibrary>::@getter::V2
      setter: <testLibrary>::@setter::V2
    hasInitializer isOriginDeclaration isStatic V
      reference: <testLibrary>::@topLevelVariable::V
      firstFragment: #F8
      type: int
      getter: <testLibrary>::@getter::V
      setter: <testLibrary>::@setter::V
  getters
    isOriginVariable isStatic V2
      reference: <testLibrary>::@getter::V2
      firstFragment: #F6
      returnType: InvalidType
      variable: <testLibrary>::@topLevelVariable::V2
    isOriginVariable isStatic V
      reference: <testLibrary>::@getter::V
      firstFragment: #F9
      returnType: int
      variable: <testLibrary>::@topLevelVariable::V
  setters
    isOriginVariable isStatic V2
      reference: <testLibrary>::@setter::V2
      firstFragment: #F7
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F11
          type: InvalidType
      returnType: void
      variable: <testLibrary>::@topLevelVariable::V2
    isOriginVariable isStatic V
      reference: <testLibrary>::@setter::V
      firstFragment: #F10
      formalParameters
        #E2 requiredPositional value
          firstFragment: #F12
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::V
  functions
    isOriginDeclaration isStatic f
      reference: <testLibrary>::@function::f
      firstFragment: #F13
      formalParameters
        #E3 requiredPositional p
          firstFragment: #F14
          type: InvalidType
      returnType: InvalidType
''');
  }

  test_type_invalid_topLevelVariableElement_asTypeArgument() async {
    var library = await buildLibrary(r'''
var V;
static List<V> V2;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasImplicitType isOriginDeclaration isStatic V (nameOffset:4) (firstTokenOffset:4) (offset:4)
          element: <testLibrary>::@topLevelVariable::V
          inducedGetter: #F2
          inducedSetter: #F3
        #F4 isOriginDeclaration isStatic V2 (nameOffset:22) (firstTokenOffset:22) (offset:22)
          element: <testLibrary>::@topLevelVariable::V2
          inducedGetter: #F5
          inducedSetter: #F6
      getters
        #F2 isComplete isOriginVariable isStatic V (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@getter::V
          inducingVariable: #F1
        #F5 isComplete isOriginVariable isStatic V2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
          element: <testLibrary>::@getter::V2
          inducingVariable: #F4
      setters
        #F3 isComplete isOriginVariable isStatic V (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@setter::V
          inducingVariable: #F1
          formalParameters
            #F7 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
              element: <testLibrary>::@setter::V::@formalParameter::value
        #F6 isComplete isOriginVariable isStatic V2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
          element: <testLibrary>::@setter::V2
          inducingVariable: #F4
          formalParameters
            #F8 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
              element: <testLibrary>::@setter::V2::@formalParameter::value
  topLevelVariables
    hasImplicitType isOriginDeclaration isStatic V
      reference: <testLibrary>::@topLevelVariable::V
      firstFragment: #F1
      type: dynamic
      getter: <testLibrary>::@getter::V
      setter: <testLibrary>::@setter::V
    isOriginDeclaration isStatic V2
      reference: <testLibrary>::@topLevelVariable::V2
      firstFragment: #F4
      type: List<InvalidType>
      getter: <testLibrary>::@getter::V2
      setter: <testLibrary>::@setter::V2
  getters
    isOriginVariable isStatic V
      reference: <testLibrary>::@getter::V
      firstFragment: #F2
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::V
    isOriginVariable isStatic V2
      reference: <testLibrary>::@getter::V2
      firstFragment: #F5
      returnType: List<InvalidType>
      variable: <testLibrary>::@topLevelVariable::V2
  setters
    isOriginVariable isStatic V
      reference: <testLibrary>::@setter::V
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F7
          type: dynamic
      returnType: void
      variable: <testLibrary>::@topLevelVariable::V
    isOriginVariable isStatic V2
      reference: <testLibrary>::@setter::V2
      firstFragment: #F6
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F8
          type: List<InvalidType>
      returnType: void
      variable: <testLibrary>::@topLevelVariable::V2
''');
  }

  test_type_invalid_typeParameter_asPrefix() async {
    var library = await buildLibrary(r'''
class C<T> {
  m(T.K p) {}
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
          typeParameters
            #F2 T (nameOffset:8) (firstTokenOffset:8) (offset:8)
              element: #E0 T
          constructors
            #F3 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          methods
            #F4 hasImplicitReturnType isComplete isOriginDeclaration m (nameOffset:15) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@class::C::@method::m
              formalParameters
                #F5 requiredPositional isOriginDeclaration p (nameOffset:21) (firstTokenOffset:17) (offset:21)
                  element: <testLibrary>::@class::C::@method::m::@formalParameter::p
  classes
    isSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      constructors
        hasEnclosingTypeParameterReference isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
      methods
        isOriginDeclaration m
          reference: <testLibrary>::@class::C::@method::m
          firstFragment: #F4
          formalParameters
            #E1 requiredPositional p
              firstFragment: #F5
              type: InvalidType
          returnType: dynamic
''');
  }

  test_type_invalid_unresolvedPrefix() async {
    var library = await buildLibrary(r'''
p.C v;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 isOriginDeclaration isStatic v (nameOffset:4) (firstTokenOffset:4) (offset:4)
          element: <testLibrary>::@topLevelVariable::v
          inducedGetter: #F2
          inducedSetter: #F3
      getters
        #F2 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@getter::v
          inducingVariable: #F1
      setters
        #F3 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@setter::v
          inducingVariable: #F1
          formalParameters
            #F4 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
              element: <testLibrary>::@setter::v::@formalParameter::value
  topLevelVariables
    isOriginDeclaration isStatic v
      reference: <testLibrary>::@topLevelVariable::v
      firstFragment: #F1
      type: InvalidType
      getter: <testLibrary>::@getter::v
      setter: <testLibrary>::@setter::v
  getters
    isOriginVariable isStatic v
      reference: <testLibrary>::@getter::v
      firstFragment: #F2
      returnType: InvalidType
      variable: <testLibrary>::@topLevelVariable::v
  setters
    isOriginVariable isStatic v
      reference: <testLibrary>::@setter::v
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F4
          type: InvalidType
      returnType: void
      variable: <testLibrary>::@topLevelVariable::v
''');
  }

  test_type_never() async {
    var library = await buildLibrary(r'''
Never d;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 isOriginDeclaration isStatic d (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::d
          inducedGetter: #F2
          inducedSetter: #F3
      getters
        #F2 isComplete isOriginVariable isStatic d (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::d
          inducingVariable: #F1
      setters
        #F3 isComplete isOriginVariable isStatic d (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@setter::d
          inducingVariable: #F1
          formalParameters
            #F4 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@setter::d::@formalParameter::value
  topLevelVariables
    isOriginDeclaration isStatic d
      reference: <testLibrary>::@topLevelVariable::d
      firstFragment: #F1
      type: Never
      getter: <testLibrary>::@getter::d
      setter: <testLibrary>::@setter::d
  getters
    isOriginVariable isStatic d
      reference: <testLibrary>::@getter::d
      firstFragment: #F2
      returnType: Never
      variable: <testLibrary>::@topLevelVariable::d
  setters
    isOriginVariable isStatic d
      reference: <testLibrary>::@setter::d
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F4
          type: Never
      returnType: void
      variable: <testLibrary>::@topLevelVariable::d
''');
  }

  test_type_param_ref_nullability_none() async {
    var library = await buildLibrary(r'''
class C<T> {
  T t;
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
          typeParameters
            #F2 T (nameOffset:8) (firstTokenOffset:8) (offset:8)
              element: #E0 T
          fields
            #F3 isOriginDeclaration t (nameOffset:17) (firstTokenOffset:17) (offset:17)
              element: <testLibrary>::@class::C::@field::t
              inducedGetter: #F4
              inducedSetter: #F5
          constructors
            #F6 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F4 isComplete isOriginVariable t (nameOffset:<null>) (firstTokenOffset:<null>) (offset:17)
              element: <testLibrary>::@class::C::@getter::t
              inducingVariable: #F3
          setters
            #F5 isComplete isOriginVariable t (nameOffset:<null>) (firstTokenOffset:<null>) (offset:17)
              element: <testLibrary>::@class::C::@setter::t
              inducingVariable: #F3
              formalParameters
                #F7 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:17)
                  element: <testLibrary>::@class::C::@setter::t::@formalParameter::value
  classes
    hasNonFinalField isSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      fields
        hasEnclosingTypeParameterReference isOriginDeclaration t
          reference: <testLibrary>::@class::C::@field::t
          firstFragment: #F3
          type: T
          getter: <testLibrary>::@class::C::@getter::t
          setter: <testLibrary>::@class::C::@setter::t
      constructors
        hasEnclosingTypeParameterReference isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F6
      getters
        hasEnclosingTypeParameterReference isOriginVariable t
          reference: <testLibrary>::@class::C::@getter::t
          firstFragment: #F4
          returnType: T
          variable: <testLibrary>::@class::C::@field::t
      setters
        hasEnclosingTypeParameterReference isOriginVariable t
          reference: <testLibrary>::@class::C::@setter::t
          firstFragment: #F5
          formalParameters
            #E1 requiredPositional value
              firstFragment: #F7
              type: T
          returnType: void
          variable: <testLibrary>::@class::C::@field::t
''');
  }

  test_type_param_ref_nullability_question() async {
    var library = await buildLibrary(r'''
class C<T> {
  T? t;
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
          typeParameters
            #F2 T (nameOffset:8) (firstTokenOffset:8) (offset:8)
              element: #E0 T
          fields
            #F3 isOriginDeclaration t (nameOffset:18) (firstTokenOffset:18) (offset:18)
              element: <testLibrary>::@class::C::@field::t
              inducedGetter: #F4
              inducedSetter: #F5
          constructors
            #F6 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F4 isComplete isOriginVariable t (nameOffset:<null>) (firstTokenOffset:<null>) (offset:18)
              element: <testLibrary>::@class::C::@getter::t
              inducingVariable: #F3
          setters
            #F5 isComplete isOriginVariable t (nameOffset:<null>) (firstTokenOffset:<null>) (offset:18)
              element: <testLibrary>::@class::C::@setter::t
              inducingVariable: #F3
              formalParameters
                #F7 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:18)
                  element: <testLibrary>::@class::C::@setter::t::@formalParameter::value
  classes
    hasNonFinalField isSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      fields
        hasEnclosingTypeParameterReference isOriginDeclaration t
          reference: <testLibrary>::@class::C::@field::t
          firstFragment: #F3
          type: T?
          getter: <testLibrary>::@class::C::@getter::t
          setter: <testLibrary>::@class::C::@setter::t
      constructors
        hasEnclosingTypeParameterReference isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F6
      getters
        hasEnclosingTypeParameterReference isOriginVariable t
          reference: <testLibrary>::@class::C::@getter::t
          firstFragment: #F4
          returnType: T?
          variable: <testLibrary>::@class::C::@field::t
      setters
        hasEnclosingTypeParameterReference isOriginVariable t
          reference: <testLibrary>::@class::C::@setter::t
          firstFragment: #F5
          formalParameters
            #E1 requiredPositional value
              firstFragment: #F7
              type: T?
          returnType: void
          variable: <testLibrary>::@class::C::@field::t
''');
  }

  test_type_reference_lib_to_lib() async {
    var library = await buildLibrary(r'''
class C {}

enum E { v }

typedef F();
C c;
E e;
F f;
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
            #F2 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
      enums
        #F3 enum E (nameOffset:17) (firstTokenOffset:12) (offset:17)
          element: <testLibrary>::@enum::E
          fields
            #F4 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:21) (firstTokenOffset:21) (offset:21)
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
            #F5 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@enum::E::@getter::v
              inducingVariable: #F4
            #F7 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:17)
              element: <testLibrary>::@enum::E::@getter::values
              inducingVariable: #F6
      typeAliases
        #F9 F (nameOffset:34) (firstTokenOffset:26) (offset:34)
          element: <testLibrary>::@typeAlias::F
      topLevelVariables
        #F10 isOriginDeclaration isStatic c (nameOffset:41) (firstTokenOffset:41) (offset:41)
          element: <testLibrary>::@topLevelVariable::c
          inducedGetter: #F11
          inducedSetter: #F12
        #F13 isOriginDeclaration isStatic e (nameOffset:46) (firstTokenOffset:46) (offset:46)
          element: <testLibrary>::@topLevelVariable::e
          inducedGetter: #F14
          inducedSetter: #F15
        #F16 isOriginDeclaration isStatic f (nameOffset:51) (firstTokenOffset:51) (offset:51)
          element: <testLibrary>::@topLevelVariable::f
          inducedGetter: #F17
          inducedSetter: #F18
      getters
        #F11 isComplete isOriginVariable isStatic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:41)
          element: <testLibrary>::@getter::c
          inducingVariable: #F10
        #F14 isComplete isOriginVariable isStatic e (nameOffset:<null>) (firstTokenOffset:<null>) (offset:46)
          element: <testLibrary>::@getter::e
          inducingVariable: #F13
        #F17 isComplete isOriginVariable isStatic f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:51)
          element: <testLibrary>::@getter::f
          inducingVariable: #F16
      setters
        #F12 isComplete isOriginVariable isStatic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:41)
          element: <testLibrary>::@setter::c
          inducingVariable: #F10
          formalParameters
            #F19 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:41)
              element: <testLibrary>::@setter::c::@formalParameter::value
        #F15 isComplete isOriginVariable isStatic e (nameOffset:<null>) (firstTokenOffset:<null>) (offset:46)
          element: <testLibrary>::@setter::e
          inducingVariable: #F13
          formalParameters
            #F20 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:46)
              element: <testLibrary>::@setter::e::@formalParameter::value
        #F18 isComplete isOriginVariable isStatic f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:51)
          element: <testLibrary>::@setter::f
          inducingVariable: #F16
          formalParameters
            #F21 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:51)
              element: <testLibrary>::@setter::f::@formalParameter::value
  classes
    isSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
  enums
    isSimplyBounded enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F3
      supertype: Enum
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
  typeAliases
    isSimplyBounded F
      reference: <testLibrary>::@typeAlias::F
      firstFragment: #F9
      aliasedType: dynamic Function()
  topLevelVariables
    isOriginDeclaration isStatic c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: #F10
      type: C
      getter: <testLibrary>::@getter::c
      setter: <testLibrary>::@setter::c
    isOriginDeclaration isStatic e
      reference: <testLibrary>::@topLevelVariable::e
      firstFragment: #F13
      type: E
      getter: <testLibrary>::@getter::e
      setter: <testLibrary>::@setter::e
    isOriginDeclaration isStatic f
      reference: <testLibrary>::@topLevelVariable::f
      firstFragment: #F16
      type: dynamic Function()
        alias: <testLibrary>::@typeAlias::F
      getter: <testLibrary>::@getter::f
      setter: <testLibrary>::@setter::f
  getters
    isOriginVariable isStatic c
      reference: <testLibrary>::@getter::c
      firstFragment: #F11
      returnType: C
      variable: <testLibrary>::@topLevelVariable::c
    isOriginVariable isStatic e
      reference: <testLibrary>::@getter::e
      firstFragment: #F14
      returnType: E
      variable: <testLibrary>::@topLevelVariable::e
    isOriginVariable isStatic f
      reference: <testLibrary>::@getter::f
      firstFragment: #F17
      returnType: dynamic Function()
        alias: <testLibrary>::@typeAlias::F
      variable: <testLibrary>::@topLevelVariable::f
  setters
    isOriginVariable isStatic c
      reference: <testLibrary>::@setter::c
      firstFragment: #F12
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F19
          type: C
      returnType: void
      variable: <testLibrary>::@topLevelVariable::c
    isOriginVariable isStatic e
      reference: <testLibrary>::@setter::e
      firstFragment: #F15
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F20
          type: E
      returnType: void
      variable: <testLibrary>::@topLevelVariable::e
    isOriginVariable isStatic f
      reference: <testLibrary>::@setter::f
      firstFragment: #F18
      formalParameters
        #E2 requiredPositional value
          firstFragment: #F21
          type: dynamic Function()
            alias: <testLibrary>::@typeAlias::F
      returnType: void
      variable: <testLibrary>::@topLevelVariable::f
''');
  }

  test_type_reference_lib_to_part() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of l;
class C {}
enum E {
  v
}
typedef F();
''');
    var library = await buildLibrary(r'''
library l;

part "a.dart";

C c;
E e;
F f;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  name: l
  fragments
    #F0 <testLibraryFragment> (nameOffset:<null>) (firstTokenOffset:0) (offset:8)
      element: <testLibrary>
      nextFragment: #F1
      parts
        part_0
          uri: package:test/a.dart
          partKeywordOffset: 12
          unit: #F1
      topLevelVariables
        #F2 isOriginDeclaration isStatic c (nameOffset:30) (firstTokenOffset:30) (offset:30)
          element: <testLibrary>::@topLevelVariable::c
          inducedGetter: #F3
          inducedSetter: #F4
        #F5 isOriginDeclaration isStatic e (nameOffset:35) (firstTokenOffset:35) (offset:35)
          element: <testLibrary>::@topLevelVariable::e
          inducedGetter: #F6
          inducedSetter: #F7
        #F8 isOriginDeclaration isStatic f (nameOffset:40) (firstTokenOffset:40) (offset:40)
          element: <testLibrary>::@topLevelVariable::f
          inducedGetter: #F9
          inducedSetter: #F10
      getters
        #F3 isComplete isOriginVariable isStatic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:30)
          element: <testLibrary>::@getter::c
          inducingVariable: #F2
        #F6 isComplete isOriginVariable isStatic e (nameOffset:<null>) (firstTokenOffset:<null>) (offset:35)
          element: <testLibrary>::@getter::e
          inducingVariable: #F5
        #F9 isComplete isOriginVariable isStatic f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
          element: <testLibrary>::@getter::f
          inducingVariable: #F8
      setters
        #F4 isComplete isOriginVariable isStatic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:30)
          element: <testLibrary>::@setter::c
          inducingVariable: #F2
          formalParameters
            #F11 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:30)
              element: <testLibrary>::@setter::c::@formalParameter::value
        #F7 isComplete isOriginVariable isStatic e (nameOffset:<null>) (firstTokenOffset:<null>) (offset:35)
          element: <testLibrary>::@setter::e
          inducingVariable: #F5
          formalParameters
            #F12 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:35)
              element: <testLibrary>::@setter::e::@formalParameter::value
        #F10 isComplete isOriginVariable isStatic f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
          element: <testLibrary>::@setter::f
          inducingVariable: #F8
          formalParameters
            #F13 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
              element: <testLibrary>::@setter::f::@formalParameter::value
    #F1 package:test/a.dart
      element: <testLibrary>
      enclosingFragment: #F0
      previousFragment: #F0
      classes
        #F14 class C (nameOffset:17) (firstTokenOffset:11) (offset:17)
          element: <testLibrary>::@class::C
          constructors
            #F15 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:17)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
      enums
        #F16 enum E (nameOffset:27) (firstTokenOffset:22) (offset:27)
          element: <testLibrary>::@enum::E
          fields
            #F17 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:33) (firstTokenOffset:33) (offset:33)
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
              inducedGetter: #F18
            #F19 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:27)
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
              inducedGetter: #F20
          constructors
            #F21 isConst isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:27)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F18 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:33)
              element: <testLibrary>::@enum::E::@getter::v
              inducingVariable: #F17
            #F20 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:27)
              element: <testLibrary>::@enum::E::@getter::values
              inducingVariable: #F19
      typeAliases
        #F22 F (nameOffset:45) (firstTokenOffset:37) (offset:45)
          element: <testLibrary>::@typeAlias::F
  classes
    isSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F14
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F15
  enums
    isSimplyBounded enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F16
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F17
          type: E
          constantInitializer
            fragment: #F17
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F19
          type: List<E>
          constantInitializer
            fragment: #F19
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        isConst isOriginImplicitDefault new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F21
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F18
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F20
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
  typeAliases
    isSimplyBounded F
      reference: <testLibrary>::@typeAlias::F
      firstFragment: #F22
      aliasedType: dynamic Function()
  topLevelVariables
    isOriginDeclaration isStatic c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: #F2
      type: C
      getter: <testLibrary>::@getter::c
      setter: <testLibrary>::@setter::c
    isOriginDeclaration isStatic e
      reference: <testLibrary>::@topLevelVariable::e
      firstFragment: #F5
      type: E
      getter: <testLibrary>::@getter::e
      setter: <testLibrary>::@setter::e
    isOriginDeclaration isStatic f
      reference: <testLibrary>::@topLevelVariable::f
      firstFragment: #F8
      type: dynamic Function()
        alias: <testLibrary>::@typeAlias::F
      getter: <testLibrary>::@getter::f
      setter: <testLibrary>::@setter::f
  getters
    isOriginVariable isStatic c
      reference: <testLibrary>::@getter::c
      firstFragment: #F3
      returnType: C
      variable: <testLibrary>::@topLevelVariable::c
    isOriginVariable isStatic e
      reference: <testLibrary>::@getter::e
      firstFragment: #F6
      returnType: E
      variable: <testLibrary>::@topLevelVariable::e
    isOriginVariable isStatic f
      reference: <testLibrary>::@getter::f
      firstFragment: #F9
      returnType: dynamic Function()
        alias: <testLibrary>::@typeAlias::F
      variable: <testLibrary>::@topLevelVariable::f
  setters
    isOriginVariable isStatic c
      reference: <testLibrary>::@setter::c
      firstFragment: #F4
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F11
          type: C
      returnType: void
      variable: <testLibrary>::@topLevelVariable::c
    isOriginVariable isStatic e
      reference: <testLibrary>::@setter::e
      firstFragment: #F7
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F12
          type: E
      returnType: void
      variable: <testLibrary>::@topLevelVariable::e
    isOriginVariable isStatic f
      reference: <testLibrary>::@setter::f
      firstFragment: #F10
      formalParameters
        #E2 requiredPositional value
          firstFragment: #F13
          type: dynamic Function()
            alias: <testLibrary>::@typeAlias::F
      returnType: void
      variable: <testLibrary>::@topLevelVariable::f
''');
  }

  test_type_reference_part_to_lib() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of l;
C c;
E e;
F f;
''');
    var library = await buildLibrary(r'''
library l;

part "a.dart";

class C {}

enum E { v }

typedef F();
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  name: l
  fragments
    #F0 <testLibraryFragment> (nameOffset:<null>) (firstTokenOffset:0) (offset:8)
      element: <testLibrary>
      nextFragment: #F1
      parts
        part_0
          uri: package:test/a.dart
          partKeywordOffset: 12
          unit: #F1
      classes
        #F2 class C (nameOffset:34) (firstTokenOffset:28) (offset:34)
          element: <testLibrary>::@class::C
          constructors
            #F3 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:34)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
      enums
        #F4 enum E (nameOffset:45) (firstTokenOffset:40) (offset:45)
          element: <testLibrary>::@enum::E
          fields
            #F5 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:49) (firstTokenOffset:49) (offset:49)
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
              inducedGetter: #F6
            #F7 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:45)
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
              inducedGetter: #F8
          constructors
            #F9 isConst isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:45)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F6 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:49)
              element: <testLibrary>::@enum::E::@getter::v
              inducingVariable: #F5
            #F8 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:45)
              element: <testLibrary>::@enum::E::@getter::values
              inducingVariable: #F7
      typeAliases
        #F10 F (nameOffset:62) (firstTokenOffset:54) (offset:62)
          element: <testLibrary>::@typeAlias::F
    #F1 package:test/a.dart
      element: <testLibrary>
      enclosingFragment: #F0
      previousFragment: #F0
      topLevelVariables
        #F11 isOriginDeclaration isStatic c (nameOffset:13) (firstTokenOffset:13) (offset:13)
          element: <testLibrary>::@topLevelVariable::c
          inducedGetter: #F12
          inducedSetter: #F13
        #F14 isOriginDeclaration isStatic e (nameOffset:18) (firstTokenOffset:18) (offset:18)
          element: <testLibrary>::@topLevelVariable::e
          inducedGetter: #F15
          inducedSetter: #F16
        #F17 isOriginDeclaration isStatic f (nameOffset:23) (firstTokenOffset:23) (offset:23)
          element: <testLibrary>::@topLevelVariable::f
          inducedGetter: #F18
          inducedSetter: #F19
      getters
        #F12 isComplete isOriginVariable isStatic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:13)
          element: <testLibrary>::@getter::c
          inducingVariable: #F11
        #F15 isComplete isOriginVariable isStatic e (nameOffset:<null>) (firstTokenOffset:<null>) (offset:18)
          element: <testLibrary>::@getter::e
          inducingVariable: #F14
        #F18 isComplete isOriginVariable isStatic f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
          element: <testLibrary>::@getter::f
          inducingVariable: #F17
      setters
        #F13 isComplete isOriginVariable isStatic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:13)
          element: <testLibrary>::@setter::c
          inducingVariable: #F11
          formalParameters
            #F20 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:13)
              element: <testLibrary>::@setter::c::@formalParameter::value
        #F16 isComplete isOriginVariable isStatic e (nameOffset:<null>) (firstTokenOffset:<null>) (offset:18)
          element: <testLibrary>::@setter::e
          inducingVariable: #F14
          formalParameters
            #F21 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:18)
              element: <testLibrary>::@setter::e::@formalParameter::value
        #F19 isComplete isOriginVariable isStatic f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
          element: <testLibrary>::@setter::f
          inducingVariable: #F17
          formalParameters
            #F22 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
              element: <testLibrary>::@setter::f::@formalParameter::value
  classes
    isSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F2
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
  enums
    isSimplyBounded enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F4
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F5
          type: E
          constantInitializer
            fragment: #F5
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F7
          type: List<E>
          constantInitializer
            fragment: #F7
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        isConst isOriginImplicitDefault new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F9
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F6
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F8
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
  typeAliases
    isSimplyBounded F
      reference: <testLibrary>::@typeAlias::F
      firstFragment: #F10
      aliasedType: dynamic Function()
  topLevelVariables
    isOriginDeclaration isStatic c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: #F11
      type: C
      getter: <testLibrary>::@getter::c
      setter: <testLibrary>::@setter::c
    isOriginDeclaration isStatic e
      reference: <testLibrary>::@topLevelVariable::e
      firstFragment: #F14
      type: E
      getter: <testLibrary>::@getter::e
      setter: <testLibrary>::@setter::e
    isOriginDeclaration isStatic f
      reference: <testLibrary>::@topLevelVariable::f
      firstFragment: #F17
      type: dynamic Function()
        alias: <testLibrary>::@typeAlias::F
      getter: <testLibrary>::@getter::f
      setter: <testLibrary>::@setter::f
  getters
    isOriginVariable isStatic c
      reference: <testLibrary>::@getter::c
      firstFragment: #F12
      returnType: C
      variable: <testLibrary>::@topLevelVariable::c
    isOriginVariable isStatic e
      reference: <testLibrary>::@getter::e
      firstFragment: #F15
      returnType: E
      variable: <testLibrary>::@topLevelVariable::e
    isOriginVariable isStatic f
      reference: <testLibrary>::@getter::f
      firstFragment: #F18
      returnType: dynamic Function()
        alias: <testLibrary>::@typeAlias::F
      variable: <testLibrary>::@topLevelVariable::f
  setters
    isOriginVariable isStatic c
      reference: <testLibrary>::@setter::c
      firstFragment: #F13
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F20
          type: C
      returnType: void
      variable: <testLibrary>::@topLevelVariable::c
    isOriginVariable isStatic e
      reference: <testLibrary>::@setter::e
      firstFragment: #F16
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F21
          type: E
      returnType: void
      variable: <testLibrary>::@topLevelVariable::e
    isOriginVariable isStatic f
      reference: <testLibrary>::@setter::f
      firstFragment: #F19
      formalParameters
        #E2 requiredPositional value
          firstFragment: #F22
          type: dynamic Function()
            alias: <testLibrary>::@typeAlias::F
      returnType: void
      variable: <testLibrary>::@topLevelVariable::f
''');
  }

  test_type_reference_part_to_other_part() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of l;
class C {}
enum E {
  v
}
typedef F();
''');
    newFile('$testPackageLibPath/b.dart', r'''
part of l;
C c;
E e;
F f;
''');
    var library = await buildLibrary(r'''
library l;

part "a.dart";
part "b.dart";
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  name: l
  fragments
    #F0 <testLibraryFragment> (nameOffset:<null>) (firstTokenOffset:0) (offset:8)
      element: <testLibrary>
      nextFragment: #F1
      parts
        part_0
          uri: package:test/a.dart
          partKeywordOffset: 12
          unit: #F1
        part_1
          uri: package:test/b.dart
          partKeywordOffset: 27
          unit: #F2
    #F1 package:test/a.dart
      element: <testLibrary>
      enclosingFragment: #F0
      previousFragment: #F0
      nextFragment: #F2
      classes
        #F3 class C (nameOffset:17) (firstTokenOffset:11) (offset:17)
          element: <testLibrary>::@class::C
          constructors
            #F4 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:17)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
      enums
        #F5 enum E (nameOffset:27) (firstTokenOffset:22) (offset:27)
          element: <testLibrary>::@enum::E
          fields
            #F6 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:33) (firstTokenOffset:33) (offset:33)
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
            #F8 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:27)
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
            #F10 isConst isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:27)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F7 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:33)
              element: <testLibrary>::@enum::E::@getter::v
              inducingVariable: #F6
            #F9 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:27)
              element: <testLibrary>::@enum::E::@getter::values
              inducingVariable: #F8
      typeAliases
        #F11 F (nameOffset:45) (firstTokenOffset:37) (offset:45)
          element: <testLibrary>::@typeAlias::F
    #F2 package:test/b.dart
      element: <testLibrary>
      enclosingFragment: #F0
      previousFragment: #F1
      topLevelVariables
        #F12 isOriginDeclaration isStatic c (nameOffset:13) (firstTokenOffset:13) (offset:13)
          element: <testLibrary>::@topLevelVariable::c
          inducedGetter: #F13
          inducedSetter: #F14
        #F15 isOriginDeclaration isStatic e (nameOffset:18) (firstTokenOffset:18) (offset:18)
          element: <testLibrary>::@topLevelVariable::e
          inducedGetter: #F16
          inducedSetter: #F17
        #F18 isOriginDeclaration isStatic f (nameOffset:23) (firstTokenOffset:23) (offset:23)
          element: <testLibrary>::@topLevelVariable::f
          inducedGetter: #F19
          inducedSetter: #F20
      getters
        #F13 isComplete isOriginVariable isStatic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:13)
          element: <testLibrary>::@getter::c
          inducingVariable: #F12
        #F16 isComplete isOriginVariable isStatic e (nameOffset:<null>) (firstTokenOffset:<null>) (offset:18)
          element: <testLibrary>::@getter::e
          inducingVariable: #F15
        #F19 isComplete isOriginVariable isStatic f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
          element: <testLibrary>::@getter::f
          inducingVariable: #F18
      setters
        #F14 isComplete isOriginVariable isStatic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:13)
          element: <testLibrary>::@setter::c
          inducingVariable: #F12
          formalParameters
            #F21 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:13)
              element: <testLibrary>::@setter::c::@formalParameter::value
        #F17 isComplete isOriginVariable isStatic e (nameOffset:<null>) (firstTokenOffset:<null>) (offset:18)
          element: <testLibrary>::@setter::e
          inducingVariable: #F15
          formalParameters
            #F22 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:18)
              element: <testLibrary>::@setter::e::@formalParameter::value
        #F20 isComplete isOriginVariable isStatic f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
          element: <testLibrary>::@setter::f
          inducingVariable: #F18
          formalParameters
            #F23 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
              element: <testLibrary>::@setter::f::@formalParameter::value
  classes
    isSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F3
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F4
  enums
    isSimplyBounded enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F5
      supertype: Enum
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
  typeAliases
    isSimplyBounded F
      reference: <testLibrary>::@typeAlias::F
      firstFragment: #F11
      aliasedType: dynamic Function()
  topLevelVariables
    isOriginDeclaration isStatic c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: #F12
      type: C
      getter: <testLibrary>::@getter::c
      setter: <testLibrary>::@setter::c
    isOriginDeclaration isStatic e
      reference: <testLibrary>::@topLevelVariable::e
      firstFragment: #F15
      type: E
      getter: <testLibrary>::@getter::e
      setter: <testLibrary>::@setter::e
    isOriginDeclaration isStatic f
      reference: <testLibrary>::@topLevelVariable::f
      firstFragment: #F18
      type: dynamic Function()
        alias: <testLibrary>::@typeAlias::F
      getter: <testLibrary>::@getter::f
      setter: <testLibrary>::@setter::f
  getters
    isOriginVariable isStatic c
      reference: <testLibrary>::@getter::c
      firstFragment: #F13
      returnType: C
      variable: <testLibrary>::@topLevelVariable::c
    isOriginVariable isStatic e
      reference: <testLibrary>::@getter::e
      firstFragment: #F16
      returnType: E
      variable: <testLibrary>::@topLevelVariable::e
    isOriginVariable isStatic f
      reference: <testLibrary>::@getter::f
      firstFragment: #F19
      returnType: dynamic Function()
        alias: <testLibrary>::@typeAlias::F
      variable: <testLibrary>::@topLevelVariable::f
  setters
    isOriginVariable isStatic c
      reference: <testLibrary>::@setter::c
      firstFragment: #F14
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F21
          type: C
      returnType: void
      variable: <testLibrary>::@topLevelVariable::c
    isOriginVariable isStatic e
      reference: <testLibrary>::@setter::e
      firstFragment: #F17
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F22
          type: E
      returnType: void
      variable: <testLibrary>::@topLevelVariable::e
    isOriginVariable isStatic f
      reference: <testLibrary>::@setter::f
      firstFragment: #F20
      formalParameters
        #E2 requiredPositional value
          firstFragment: #F23
          type: dynamic Function()
            alias: <testLibrary>::@typeAlias::F
      returnType: void
      variable: <testLibrary>::@topLevelVariable::f
''');
  }

  test_type_reference_part_to_part() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of l;
class C {}
enum E {
  v
}
typedef F();
C c;
E e;
F f;
''');
    var library = await buildLibrary(r'''
library l;

part "a.dart";
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  name: l
  fragments
    #F0 <testLibraryFragment> (nameOffset:<null>) (firstTokenOffset:0) (offset:8)
      element: <testLibrary>
      nextFragment: #F1
      parts
        part_0
          uri: package:test/a.dart
          partKeywordOffset: 12
          unit: #F1
    #F1 package:test/a.dart
      element: <testLibrary>
      enclosingFragment: #F0
      previousFragment: #F0
      classes
        #F2 class C (nameOffset:17) (firstTokenOffset:11) (offset:17)
          element: <testLibrary>::@class::C
          constructors
            #F3 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:17)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
      enums
        #F4 enum E (nameOffset:27) (firstTokenOffset:22) (offset:27)
          element: <testLibrary>::@enum::E
          fields
            #F5 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:33) (firstTokenOffset:33) (offset:33)
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
              inducedGetter: #F6
            #F7 isConst isOriginEnumValues isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:27)
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
              inducedGetter: #F8
          constructors
            #F9 isConst isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:27)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F6 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:33)
              element: <testLibrary>::@enum::E::@getter::v
              inducingVariable: #F5
            #F8 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:27)
              element: <testLibrary>::@enum::E::@getter::values
              inducingVariable: #F7
      typeAliases
        #F10 F (nameOffset:45) (firstTokenOffset:37) (offset:45)
          element: <testLibrary>::@typeAlias::F
      topLevelVariables
        #F11 isOriginDeclaration isStatic c (nameOffset:52) (firstTokenOffset:52) (offset:52)
          element: <testLibrary>::@topLevelVariable::c
          inducedGetter: #F12
          inducedSetter: #F13
        #F14 isOriginDeclaration isStatic e (nameOffset:57) (firstTokenOffset:57) (offset:57)
          element: <testLibrary>::@topLevelVariable::e
          inducedGetter: #F15
          inducedSetter: #F16
        #F17 isOriginDeclaration isStatic f (nameOffset:62) (firstTokenOffset:62) (offset:62)
          element: <testLibrary>::@topLevelVariable::f
          inducedGetter: #F18
          inducedSetter: #F19
      getters
        #F12 isComplete isOriginVariable isStatic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:52)
          element: <testLibrary>::@getter::c
          inducingVariable: #F11
        #F15 isComplete isOriginVariable isStatic e (nameOffset:<null>) (firstTokenOffset:<null>) (offset:57)
          element: <testLibrary>::@getter::e
          inducingVariable: #F14
        #F18 isComplete isOriginVariable isStatic f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:62)
          element: <testLibrary>::@getter::f
          inducingVariable: #F17
      setters
        #F13 isComplete isOriginVariable isStatic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:52)
          element: <testLibrary>::@setter::c
          inducingVariable: #F11
          formalParameters
            #F20 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:52)
              element: <testLibrary>::@setter::c::@formalParameter::value
        #F16 isComplete isOriginVariable isStatic e (nameOffset:<null>) (firstTokenOffset:<null>) (offset:57)
          element: <testLibrary>::@setter::e
          inducingVariable: #F14
          formalParameters
            #F21 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:57)
              element: <testLibrary>::@setter::e::@formalParameter::value
        #F19 isComplete isOriginVariable isStatic f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:62)
          element: <testLibrary>::@setter::f
          inducingVariable: #F17
          formalParameters
            #F22 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:62)
              element: <testLibrary>::@setter::f::@formalParameter::value
  classes
    isSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F2
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
  enums
    isSimplyBounded enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F4
      supertype: Enum
      fields
        hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic isTypeInferredFromInitializer v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F5
          type: E
          constantInitializer
            fragment: #F5
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        isConst isOriginEnumValues isStatic values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F7
          type: List<E>
          constantInitializer
            fragment: #F7
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        isConst isOriginImplicitDefault new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F9
          superConstructor: dart:core::@class::Enum::@constructor::new
      getters
        isOriginVariable isStatic v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F6
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        isOriginVariable isStatic values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F8
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
  typeAliases
    isSimplyBounded F
      reference: <testLibrary>::@typeAlias::F
      firstFragment: #F10
      aliasedType: dynamic Function()
  topLevelVariables
    isOriginDeclaration isStatic c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: #F11
      type: C
      getter: <testLibrary>::@getter::c
      setter: <testLibrary>::@setter::c
    isOriginDeclaration isStatic e
      reference: <testLibrary>::@topLevelVariable::e
      firstFragment: #F14
      type: E
      getter: <testLibrary>::@getter::e
      setter: <testLibrary>::@setter::e
    isOriginDeclaration isStatic f
      reference: <testLibrary>::@topLevelVariable::f
      firstFragment: #F17
      type: dynamic Function()
        alias: <testLibrary>::@typeAlias::F
      getter: <testLibrary>::@getter::f
      setter: <testLibrary>::@setter::f
  getters
    isOriginVariable isStatic c
      reference: <testLibrary>::@getter::c
      firstFragment: #F12
      returnType: C
      variable: <testLibrary>::@topLevelVariable::c
    isOriginVariable isStatic e
      reference: <testLibrary>::@getter::e
      firstFragment: #F15
      returnType: E
      variable: <testLibrary>::@topLevelVariable::e
    isOriginVariable isStatic f
      reference: <testLibrary>::@getter::f
      firstFragment: #F18
      returnType: dynamic Function()
        alias: <testLibrary>::@typeAlias::F
      variable: <testLibrary>::@topLevelVariable::f
  setters
    isOriginVariable isStatic c
      reference: <testLibrary>::@setter::c
      firstFragment: #F13
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F20
          type: C
      returnType: void
      variable: <testLibrary>::@topLevelVariable::c
    isOriginVariable isStatic e
      reference: <testLibrary>::@setter::e
      firstFragment: #F16
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F21
          type: E
      returnType: void
      variable: <testLibrary>::@topLevelVariable::e
    isOriginVariable isStatic f
      reference: <testLibrary>::@setter::f
      firstFragment: #F19
      formalParameters
        #E2 requiredPositional value
          firstFragment: #F22
          type: dynamic Function()
            alias: <testLibrary>::@typeAlias::F
      returnType: void
      variable: <testLibrary>::@topLevelVariable::f
''');
  }

  test_type_reference_to_class() async {
    var library = await buildLibrary(r'''
class C {}

C c;
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
            #F2 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
      topLevelVariables
        #F3 isOriginDeclaration isStatic c (nameOffset:14) (firstTokenOffset:14) (offset:14)
          element: <testLibrary>::@topLevelVariable::c
          inducedGetter: #F4
          inducedSetter: #F5
      getters
        #F4 isComplete isOriginVariable isStatic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:14)
          element: <testLibrary>::@getter::c
          inducingVariable: #F3
      setters
        #F5 isComplete isOriginVariable isStatic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:14)
          element: <testLibrary>::@setter::c
          inducingVariable: #F3
          formalParameters
            #F6 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:14)
              element: <testLibrary>::@setter::c::@formalParameter::value
  classes
    isSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
  topLevelVariables
    isOriginDeclaration isStatic c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: #F3
      type: C
      getter: <testLibrary>::@getter::c
      setter: <testLibrary>::@setter::c
  getters
    isOriginVariable isStatic c
      reference: <testLibrary>::@getter::c
      firstFragment: #F4
      returnType: C
      variable: <testLibrary>::@topLevelVariable::c
  setters
    isOriginVariable isStatic c
      reference: <testLibrary>::@setter::c
      firstFragment: #F5
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F6
          type: C
      returnType: void
      variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_type_reference_to_class_with_type_arguments() async {
    var library = await buildLibrary(r'''
class C<T, U> {}

C<int, String> c;
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
          typeParameters
            #F2 T (nameOffset:8) (firstTokenOffset:8) (offset:8)
              element: #E0 T
            #F3 U (nameOffset:11) (firstTokenOffset:11) (offset:11)
              element: #E1 U
          constructors
            #F4 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
      topLevelVariables
        #F5 isOriginDeclaration isStatic c (nameOffset:33) (firstTokenOffset:33) (offset:33)
          element: <testLibrary>::@topLevelVariable::c
          inducedGetter: #F6
          inducedSetter: #F7
      getters
        #F6 isComplete isOriginVariable isStatic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:33)
          element: <testLibrary>::@getter::c
          inducingVariable: #F5
      setters
        #F7 isComplete isOriginVariable isStatic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:33)
          element: <testLibrary>::@setter::c
          inducingVariable: #F5
          formalParameters
            #F8 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:33)
              element: <testLibrary>::@setter::c::@formalParameter::value
  classes
    isSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
        #E1 U
          firstFragment: #F3
      constructors
        hasEnclosingTypeParameterReference isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F4
  topLevelVariables
    isOriginDeclaration isStatic c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: #F5
      type: C<int, String>
      getter: <testLibrary>::@getter::c
      setter: <testLibrary>::@setter::c
  getters
    isOriginVariable isStatic c
      reference: <testLibrary>::@getter::c
      firstFragment: #F6
      returnType: C<int, String>
      variable: <testLibrary>::@topLevelVariable::c
  setters
    isOriginVariable isStatic c
      reference: <testLibrary>::@setter::c
      firstFragment: #F7
      formalParameters
        #E2 requiredPositional value
          firstFragment: #F8
          type: C<int, String>
      returnType: void
      variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_type_reference_to_class_with_type_arguments_implicit() async {
    var library = await buildLibrary(r'''
class C<T, U> {}

C c;
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
          typeParameters
            #F2 T (nameOffset:8) (firstTokenOffset:8) (offset:8)
              element: #E0 T
            #F3 U (nameOffset:11) (firstTokenOffset:11) (offset:11)
              element: #E1 U
          constructors
            #F4 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
      topLevelVariables
        #F5 isOriginDeclaration isStatic c (nameOffset:20) (firstTokenOffset:20) (offset:20)
          element: <testLibrary>::@topLevelVariable::c
          inducedGetter: #F6
          inducedSetter: #F7
      getters
        #F6 isComplete isOriginVariable isStatic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:20)
          element: <testLibrary>::@getter::c
          inducingVariable: #F5
      setters
        #F7 isComplete isOriginVariable isStatic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:20)
          element: <testLibrary>::@setter::c
          inducingVariable: #F5
          formalParameters
            #F8 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:20)
              element: <testLibrary>::@setter::c::@formalParameter::value
  classes
    isSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
        #E1 U
          firstFragment: #F3
      constructors
        hasEnclosingTypeParameterReference isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F4
  topLevelVariables
    isOriginDeclaration isStatic c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: #F5
      type: C<dynamic, dynamic>
      getter: <testLibrary>::@getter::c
      setter: <testLibrary>::@setter::c
  getters
    isOriginVariable isStatic c
      reference: <testLibrary>::@getter::c
      firstFragment: #F6
      returnType: C<dynamic, dynamic>
      variable: <testLibrary>::@topLevelVariable::c
  setters
    isOriginVariable isStatic c
      reference: <testLibrary>::@setter::c
      firstFragment: #F7
      formalParameters
        #E2 requiredPositional value
          firstFragment: #F8
          type: C<dynamic, dynamic>
      returnType: void
      variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_type_reference_to_enum() async {
    var library = await buildLibrary(r'''
enum E { v }

E e;
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
            #F2 hasImplicitType hasInitializer isConst isEnumConstant isOriginDeclaration isStatic v (nameOffset:9) (firstTokenOffset:9) (offset:9)
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
            #F3 isComplete isOriginVariable isStatic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:9)
              element: <testLibrary>::@enum::E::@getter::v
              inducingVariable: #F2
            #F5 isComplete isOriginVariable isStatic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
              inducingVariable: #F4
      topLevelVariables
        #F7 isOriginDeclaration isStatic e (nameOffset:16) (firstTokenOffset:16) (offset:16)
          element: <testLibrary>::@topLevelVariable::e
          inducedGetter: #F8
          inducedSetter: #F9
      getters
        #F8 isComplete isOriginVariable isStatic e (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
          element: <testLibrary>::@getter::e
          inducingVariable: #F7
      setters
        #F9 isComplete isOriginVariable isStatic e (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
          element: <testLibrary>::@setter::e
          inducingVariable: #F7
          formalParameters
            #F10 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@setter::e::@formalParameter::value
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
    isOriginDeclaration isStatic e
      reference: <testLibrary>::@topLevelVariable::e
      firstFragment: #F7
      type: E
      getter: <testLibrary>::@getter::e
      setter: <testLibrary>::@setter::e
  getters
    isOriginVariable isStatic e
      reference: <testLibrary>::@getter::e
      firstFragment: #F8
      returnType: E
      variable: <testLibrary>::@topLevelVariable::e
  setters
    isOriginVariable isStatic e
      reference: <testLibrary>::@setter::e
      firstFragment: #F9
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F10
          type: E
      returnType: void
      variable: <testLibrary>::@topLevelVariable::e
''');
  }

  test_type_reference_to_import() async {
    newFile('$testPackageLibPath/a.dart', r'''
class C {}
enum E {
  v
}
typedef F();
''');
    var library = await buildLibrary(r'''
import "a.dart";

C c;
E e;
F f;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart
      topLevelVariables
        #F1 isOriginDeclaration isStatic c (nameOffset:20) (firstTokenOffset:20) (offset:20)
          element: <testLibrary>::@topLevelVariable::c
          inducedGetter: #F2
          inducedSetter: #F3
        #F4 isOriginDeclaration isStatic e (nameOffset:25) (firstTokenOffset:25) (offset:25)
          element: <testLibrary>::@topLevelVariable::e
          inducedGetter: #F5
          inducedSetter: #F6
        #F7 isOriginDeclaration isStatic f (nameOffset:30) (firstTokenOffset:30) (offset:30)
          element: <testLibrary>::@topLevelVariable::f
          inducedGetter: #F8
          inducedSetter: #F9
      getters
        #F2 isComplete isOriginVariable isStatic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:20)
          element: <testLibrary>::@getter::c
          inducingVariable: #F1
        #F5 isComplete isOriginVariable isStatic e (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
          element: <testLibrary>::@getter::e
          inducingVariable: #F4
        #F8 isComplete isOriginVariable isStatic f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:30)
          element: <testLibrary>::@getter::f
          inducingVariable: #F7
      setters
        #F3 isComplete isOriginVariable isStatic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:20)
          element: <testLibrary>::@setter::c
          inducingVariable: #F1
          formalParameters
            #F10 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:20)
              element: <testLibrary>::@setter::c::@formalParameter::value
        #F6 isComplete isOriginVariable isStatic e (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
          element: <testLibrary>::@setter::e
          inducingVariable: #F4
          formalParameters
            #F11 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
              element: <testLibrary>::@setter::e::@formalParameter::value
        #F9 isComplete isOriginVariable isStatic f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:30)
          element: <testLibrary>::@setter::f
          inducingVariable: #F7
          formalParameters
            #F12 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:30)
              element: <testLibrary>::@setter::f::@formalParameter::value
  topLevelVariables
    isOriginDeclaration isStatic c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: #F1
      type: C
      getter: <testLibrary>::@getter::c
      setter: <testLibrary>::@setter::c
    isOriginDeclaration isStatic e
      reference: <testLibrary>::@topLevelVariable::e
      firstFragment: #F4
      type: E
      getter: <testLibrary>::@getter::e
      setter: <testLibrary>::@setter::e
    isOriginDeclaration isStatic f
      reference: <testLibrary>::@topLevelVariable::f
      firstFragment: #F7
      type: dynamic Function()
        alias: package:test/a.dart::@typeAlias::F
      getter: <testLibrary>::@getter::f
      setter: <testLibrary>::@setter::f
  getters
    isOriginVariable isStatic c
      reference: <testLibrary>::@getter::c
      firstFragment: #F2
      returnType: C
      variable: <testLibrary>::@topLevelVariable::c
    isOriginVariable isStatic e
      reference: <testLibrary>::@getter::e
      firstFragment: #F5
      returnType: E
      variable: <testLibrary>::@topLevelVariable::e
    isOriginVariable isStatic f
      reference: <testLibrary>::@getter::f
      firstFragment: #F8
      returnType: dynamic Function()
        alias: package:test/a.dart::@typeAlias::F
      variable: <testLibrary>::@topLevelVariable::f
  setters
    isOriginVariable isStatic c
      reference: <testLibrary>::@setter::c
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F10
          type: C
      returnType: void
      variable: <testLibrary>::@topLevelVariable::c
    isOriginVariable isStatic e
      reference: <testLibrary>::@setter::e
      firstFragment: #F6
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F11
          type: E
      returnType: void
      variable: <testLibrary>::@topLevelVariable::e
    isOriginVariable isStatic f
      reference: <testLibrary>::@setter::f
      firstFragment: #F9
      formalParameters
        #E2 requiredPositional value
          firstFragment: #F12
          type: dynamic Function()
            alias: package:test/a.dart::@typeAlias::F
      returnType: void
      variable: <testLibrary>::@topLevelVariable::f
''');
  }

  test_type_reference_to_import_export() async {
    newFile('$testPackageLibPath/a.dart', r'''
export "b.dart";
''');
    newFile('$testPackageLibPath/b.dart', r'''
class C {}
enum E {
  v
}
typedef F();
''');
    var library = await buildLibrary(r'''
import "a.dart";

C c;
E e;
F f;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart
      topLevelVariables
        #F1 isOriginDeclaration isStatic c (nameOffset:20) (firstTokenOffset:20) (offset:20)
          element: <testLibrary>::@topLevelVariable::c
          inducedGetter: #F2
          inducedSetter: #F3
        #F4 isOriginDeclaration isStatic e (nameOffset:25) (firstTokenOffset:25) (offset:25)
          element: <testLibrary>::@topLevelVariable::e
          inducedGetter: #F5
          inducedSetter: #F6
        #F7 isOriginDeclaration isStatic f (nameOffset:30) (firstTokenOffset:30) (offset:30)
          element: <testLibrary>::@topLevelVariable::f
          inducedGetter: #F8
          inducedSetter: #F9
      getters
        #F2 isComplete isOriginVariable isStatic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:20)
          element: <testLibrary>::@getter::c
          inducingVariable: #F1
        #F5 isComplete isOriginVariable isStatic e (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
          element: <testLibrary>::@getter::e
          inducingVariable: #F4
        #F8 isComplete isOriginVariable isStatic f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:30)
          element: <testLibrary>::@getter::f
          inducingVariable: #F7
      setters
        #F3 isComplete isOriginVariable isStatic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:20)
          element: <testLibrary>::@setter::c
          inducingVariable: #F1
          formalParameters
            #F10 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:20)
              element: <testLibrary>::@setter::c::@formalParameter::value
        #F6 isComplete isOriginVariable isStatic e (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
          element: <testLibrary>::@setter::e
          inducingVariable: #F4
          formalParameters
            #F11 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
              element: <testLibrary>::@setter::e::@formalParameter::value
        #F9 isComplete isOriginVariable isStatic f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:30)
          element: <testLibrary>::@setter::f
          inducingVariable: #F7
          formalParameters
            #F12 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:30)
              element: <testLibrary>::@setter::f::@formalParameter::value
  topLevelVariables
    isOriginDeclaration isStatic c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: #F1
      type: C
      getter: <testLibrary>::@getter::c
      setter: <testLibrary>::@setter::c
    isOriginDeclaration isStatic e
      reference: <testLibrary>::@topLevelVariable::e
      firstFragment: #F4
      type: E
      getter: <testLibrary>::@getter::e
      setter: <testLibrary>::@setter::e
    isOriginDeclaration isStatic f
      reference: <testLibrary>::@topLevelVariable::f
      firstFragment: #F7
      type: dynamic Function()
        alias: package:test/b.dart::@typeAlias::F
      getter: <testLibrary>::@getter::f
      setter: <testLibrary>::@setter::f
  getters
    isOriginVariable isStatic c
      reference: <testLibrary>::@getter::c
      firstFragment: #F2
      returnType: C
      variable: <testLibrary>::@topLevelVariable::c
    isOriginVariable isStatic e
      reference: <testLibrary>::@getter::e
      firstFragment: #F5
      returnType: E
      variable: <testLibrary>::@topLevelVariable::e
    isOriginVariable isStatic f
      reference: <testLibrary>::@getter::f
      firstFragment: #F8
      returnType: dynamic Function()
        alias: package:test/b.dart::@typeAlias::F
      variable: <testLibrary>::@topLevelVariable::f
  setters
    isOriginVariable isStatic c
      reference: <testLibrary>::@setter::c
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F10
          type: C
      returnType: void
      variable: <testLibrary>::@topLevelVariable::c
    isOriginVariable isStatic e
      reference: <testLibrary>::@setter::e
      firstFragment: #F6
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F11
          type: E
      returnType: void
      variable: <testLibrary>::@topLevelVariable::e
    isOriginVariable isStatic f
      reference: <testLibrary>::@setter::f
      firstFragment: #F9
      formalParameters
        #E2 requiredPositional value
          firstFragment: #F12
          type: dynamic Function()
            alias: package:test/b.dart::@typeAlias::F
      returnType: void
      variable: <testLibrary>::@topLevelVariable::f
''');
  }

  test_type_reference_to_import_export_export() async {
    newFile('$testPackageLibPath/a.dart', r'''
export "b.dart";
''');
    newFile('$testPackageLibPath/b.dart', r'''
export "c.dart";
''');
    newFile('$testPackageLibPath/c.dart', r'''
class C {}
enum E {
  v
}
typedef F();
''');
    var library = await buildLibrary(r'''
import "a.dart";

C c;
E e;
F f;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart
      topLevelVariables
        #F1 isOriginDeclaration isStatic c (nameOffset:20) (firstTokenOffset:20) (offset:20)
          element: <testLibrary>::@topLevelVariable::c
          inducedGetter: #F2
          inducedSetter: #F3
        #F4 isOriginDeclaration isStatic e (nameOffset:25) (firstTokenOffset:25) (offset:25)
          element: <testLibrary>::@topLevelVariable::e
          inducedGetter: #F5
          inducedSetter: #F6
        #F7 isOriginDeclaration isStatic f (nameOffset:30) (firstTokenOffset:30) (offset:30)
          element: <testLibrary>::@topLevelVariable::f
          inducedGetter: #F8
          inducedSetter: #F9
      getters
        #F2 isComplete isOriginVariable isStatic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:20)
          element: <testLibrary>::@getter::c
          inducingVariable: #F1
        #F5 isComplete isOriginVariable isStatic e (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
          element: <testLibrary>::@getter::e
          inducingVariable: #F4
        #F8 isComplete isOriginVariable isStatic f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:30)
          element: <testLibrary>::@getter::f
          inducingVariable: #F7
      setters
        #F3 isComplete isOriginVariable isStatic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:20)
          element: <testLibrary>::@setter::c
          inducingVariable: #F1
          formalParameters
            #F10 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:20)
              element: <testLibrary>::@setter::c::@formalParameter::value
        #F6 isComplete isOriginVariable isStatic e (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
          element: <testLibrary>::@setter::e
          inducingVariable: #F4
          formalParameters
            #F11 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
              element: <testLibrary>::@setter::e::@formalParameter::value
        #F9 isComplete isOriginVariable isStatic f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:30)
          element: <testLibrary>::@setter::f
          inducingVariable: #F7
          formalParameters
            #F12 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:30)
              element: <testLibrary>::@setter::f::@formalParameter::value
  topLevelVariables
    isOriginDeclaration isStatic c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: #F1
      type: C
      getter: <testLibrary>::@getter::c
      setter: <testLibrary>::@setter::c
    isOriginDeclaration isStatic e
      reference: <testLibrary>::@topLevelVariable::e
      firstFragment: #F4
      type: E
      getter: <testLibrary>::@getter::e
      setter: <testLibrary>::@setter::e
    isOriginDeclaration isStatic f
      reference: <testLibrary>::@topLevelVariable::f
      firstFragment: #F7
      type: dynamic Function()
        alias: package:test/c.dart::@typeAlias::F
      getter: <testLibrary>::@getter::f
      setter: <testLibrary>::@setter::f
  getters
    isOriginVariable isStatic c
      reference: <testLibrary>::@getter::c
      firstFragment: #F2
      returnType: C
      variable: <testLibrary>::@topLevelVariable::c
    isOriginVariable isStatic e
      reference: <testLibrary>::@getter::e
      firstFragment: #F5
      returnType: E
      variable: <testLibrary>::@topLevelVariable::e
    isOriginVariable isStatic f
      reference: <testLibrary>::@getter::f
      firstFragment: #F8
      returnType: dynamic Function()
        alias: package:test/c.dart::@typeAlias::F
      variable: <testLibrary>::@topLevelVariable::f
  setters
    isOriginVariable isStatic c
      reference: <testLibrary>::@setter::c
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F10
          type: C
      returnType: void
      variable: <testLibrary>::@topLevelVariable::c
    isOriginVariable isStatic e
      reference: <testLibrary>::@setter::e
      firstFragment: #F6
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F11
          type: E
      returnType: void
      variable: <testLibrary>::@topLevelVariable::e
    isOriginVariable isStatic f
      reference: <testLibrary>::@setter::f
      firstFragment: #F9
      formalParameters
        #E2 requiredPositional value
          firstFragment: #F12
          type: dynamic Function()
            alias: package:test/c.dart::@typeAlias::F
      returnType: void
      variable: <testLibrary>::@topLevelVariable::f
''');
  }

  test_type_reference_to_import_export_export_in_subdirs() async {
    newFile('$testPackageLibPath/a/a.dart', r'''
export "b/b.dart";
''');
    newFile('$testPackageLibPath/a/b/b.dart', r'''
export "../c/c.dart";
''');
    newFile('$testPackageLibPath/a/c/c.dart', r'''
class C {}
enum E {
  v
}
typedef F();
''');
    var library = await buildLibrary(r'''
import "a/a.dart";

C c;
E e;
F f;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a/a.dart
      topLevelVariables
        #F1 isOriginDeclaration isStatic c (nameOffset:22) (firstTokenOffset:22) (offset:22)
          element: <testLibrary>::@topLevelVariable::c
          inducedGetter: #F2
          inducedSetter: #F3
        #F4 isOriginDeclaration isStatic e (nameOffset:27) (firstTokenOffset:27) (offset:27)
          element: <testLibrary>::@topLevelVariable::e
          inducedGetter: #F5
          inducedSetter: #F6
        #F7 isOriginDeclaration isStatic f (nameOffset:32) (firstTokenOffset:32) (offset:32)
          element: <testLibrary>::@topLevelVariable::f
          inducedGetter: #F8
          inducedSetter: #F9
      getters
        #F2 isComplete isOriginVariable isStatic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
          element: <testLibrary>::@getter::c
          inducingVariable: #F1
        #F5 isComplete isOriginVariable isStatic e (nameOffset:<null>) (firstTokenOffset:<null>) (offset:27)
          element: <testLibrary>::@getter::e
          inducingVariable: #F4
        #F8 isComplete isOriginVariable isStatic f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:32)
          element: <testLibrary>::@getter::f
          inducingVariable: #F7
      setters
        #F3 isComplete isOriginVariable isStatic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
          element: <testLibrary>::@setter::c
          inducingVariable: #F1
          formalParameters
            #F10 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
              element: <testLibrary>::@setter::c::@formalParameter::value
        #F6 isComplete isOriginVariable isStatic e (nameOffset:<null>) (firstTokenOffset:<null>) (offset:27)
          element: <testLibrary>::@setter::e
          inducingVariable: #F4
          formalParameters
            #F11 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:27)
              element: <testLibrary>::@setter::e::@formalParameter::value
        #F9 isComplete isOriginVariable isStatic f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:32)
          element: <testLibrary>::@setter::f
          inducingVariable: #F7
          formalParameters
            #F12 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:32)
              element: <testLibrary>::@setter::f::@formalParameter::value
  topLevelVariables
    isOriginDeclaration isStatic c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: #F1
      type: C
      getter: <testLibrary>::@getter::c
      setter: <testLibrary>::@setter::c
    isOriginDeclaration isStatic e
      reference: <testLibrary>::@topLevelVariable::e
      firstFragment: #F4
      type: E
      getter: <testLibrary>::@getter::e
      setter: <testLibrary>::@setter::e
    isOriginDeclaration isStatic f
      reference: <testLibrary>::@topLevelVariable::f
      firstFragment: #F7
      type: dynamic Function()
        alias: package:test/a/c/c.dart::@typeAlias::F
      getter: <testLibrary>::@getter::f
      setter: <testLibrary>::@setter::f
  getters
    isOriginVariable isStatic c
      reference: <testLibrary>::@getter::c
      firstFragment: #F2
      returnType: C
      variable: <testLibrary>::@topLevelVariable::c
    isOriginVariable isStatic e
      reference: <testLibrary>::@getter::e
      firstFragment: #F5
      returnType: E
      variable: <testLibrary>::@topLevelVariable::e
    isOriginVariable isStatic f
      reference: <testLibrary>::@getter::f
      firstFragment: #F8
      returnType: dynamic Function()
        alias: package:test/a/c/c.dart::@typeAlias::F
      variable: <testLibrary>::@topLevelVariable::f
  setters
    isOriginVariable isStatic c
      reference: <testLibrary>::@setter::c
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F10
          type: C
      returnType: void
      variable: <testLibrary>::@topLevelVariable::c
    isOriginVariable isStatic e
      reference: <testLibrary>::@setter::e
      firstFragment: #F6
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F11
          type: E
      returnType: void
      variable: <testLibrary>::@topLevelVariable::e
    isOriginVariable isStatic f
      reference: <testLibrary>::@setter::f
      firstFragment: #F9
      formalParameters
        #E2 requiredPositional value
          firstFragment: #F12
          type: dynamic Function()
            alias: package:test/a/c/c.dart::@typeAlias::F
      returnType: void
      variable: <testLibrary>::@topLevelVariable::f
''');
  }

  test_type_reference_to_import_export_in_subdirs() async {
    newFile('$testPackageLibPath/a/a.dart', r'''
export "b/b.dart";
''');
    newFile('$testPackageLibPath/a/b/b.dart', r'''
class C {}
enum E {
  v
}
typedef F();
''');
    var library = await buildLibrary(r'''
import "a/a.dart";

C c;
E e;
F f;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a/a.dart
      topLevelVariables
        #F1 isOriginDeclaration isStatic c (nameOffset:22) (firstTokenOffset:22) (offset:22)
          element: <testLibrary>::@topLevelVariable::c
          inducedGetter: #F2
          inducedSetter: #F3
        #F4 isOriginDeclaration isStatic e (nameOffset:27) (firstTokenOffset:27) (offset:27)
          element: <testLibrary>::@topLevelVariable::e
          inducedGetter: #F5
          inducedSetter: #F6
        #F7 isOriginDeclaration isStatic f (nameOffset:32) (firstTokenOffset:32) (offset:32)
          element: <testLibrary>::@topLevelVariable::f
          inducedGetter: #F8
          inducedSetter: #F9
      getters
        #F2 isComplete isOriginVariable isStatic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
          element: <testLibrary>::@getter::c
          inducingVariable: #F1
        #F5 isComplete isOriginVariable isStatic e (nameOffset:<null>) (firstTokenOffset:<null>) (offset:27)
          element: <testLibrary>::@getter::e
          inducingVariable: #F4
        #F8 isComplete isOriginVariable isStatic f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:32)
          element: <testLibrary>::@getter::f
          inducingVariable: #F7
      setters
        #F3 isComplete isOriginVariable isStatic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
          element: <testLibrary>::@setter::c
          inducingVariable: #F1
          formalParameters
            #F10 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
              element: <testLibrary>::@setter::c::@formalParameter::value
        #F6 isComplete isOriginVariable isStatic e (nameOffset:<null>) (firstTokenOffset:<null>) (offset:27)
          element: <testLibrary>::@setter::e
          inducingVariable: #F4
          formalParameters
            #F11 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:27)
              element: <testLibrary>::@setter::e::@formalParameter::value
        #F9 isComplete isOriginVariable isStatic f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:32)
          element: <testLibrary>::@setter::f
          inducingVariable: #F7
          formalParameters
            #F12 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:32)
              element: <testLibrary>::@setter::f::@formalParameter::value
  topLevelVariables
    isOriginDeclaration isStatic c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: #F1
      type: C
      getter: <testLibrary>::@getter::c
      setter: <testLibrary>::@setter::c
    isOriginDeclaration isStatic e
      reference: <testLibrary>::@topLevelVariable::e
      firstFragment: #F4
      type: E
      getter: <testLibrary>::@getter::e
      setter: <testLibrary>::@setter::e
    isOriginDeclaration isStatic f
      reference: <testLibrary>::@topLevelVariable::f
      firstFragment: #F7
      type: dynamic Function()
        alias: package:test/a/b/b.dart::@typeAlias::F
      getter: <testLibrary>::@getter::f
      setter: <testLibrary>::@setter::f
  getters
    isOriginVariable isStatic c
      reference: <testLibrary>::@getter::c
      firstFragment: #F2
      returnType: C
      variable: <testLibrary>::@topLevelVariable::c
    isOriginVariable isStatic e
      reference: <testLibrary>::@getter::e
      firstFragment: #F5
      returnType: E
      variable: <testLibrary>::@topLevelVariable::e
    isOriginVariable isStatic f
      reference: <testLibrary>::@getter::f
      firstFragment: #F8
      returnType: dynamic Function()
        alias: package:test/a/b/b.dart::@typeAlias::F
      variable: <testLibrary>::@topLevelVariable::f
  setters
    isOriginVariable isStatic c
      reference: <testLibrary>::@setter::c
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F10
          type: C
      returnType: void
      variable: <testLibrary>::@topLevelVariable::c
    isOriginVariable isStatic e
      reference: <testLibrary>::@setter::e
      firstFragment: #F6
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F11
          type: E
      returnType: void
      variable: <testLibrary>::@topLevelVariable::e
    isOriginVariable isStatic f
      reference: <testLibrary>::@setter::f
      firstFragment: #F9
      formalParameters
        #E2 requiredPositional value
          firstFragment: #F12
          type: dynamic Function()
            alias: package:test/a/b/b.dart::@typeAlias::F
      returnType: void
      variable: <testLibrary>::@topLevelVariable::f
''');
  }

  test_type_reference_to_import_part() async {
    newFile('$testPackageLibPath/a.dart', r'''
library l;
part "b.dart";
''');
    newFile('$testPackageLibPath/b.dart', r'''
part of l;
class C {}
enum E {
  v
}
typedef F();
''');
    var library = await buildLibrary(r'''
import "a.dart";

C c;
E e;
F f;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart
      topLevelVariables
        #F1 isOriginDeclaration isStatic c (nameOffset:20) (firstTokenOffset:20) (offset:20)
          element: <testLibrary>::@topLevelVariable::c
          inducedGetter: #F2
          inducedSetter: #F3
        #F4 isOriginDeclaration isStatic e (nameOffset:25) (firstTokenOffset:25) (offset:25)
          element: <testLibrary>::@topLevelVariable::e
          inducedGetter: #F5
          inducedSetter: #F6
        #F7 isOriginDeclaration isStatic f (nameOffset:30) (firstTokenOffset:30) (offset:30)
          element: <testLibrary>::@topLevelVariable::f
          inducedGetter: #F8
          inducedSetter: #F9
      getters
        #F2 isComplete isOriginVariable isStatic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:20)
          element: <testLibrary>::@getter::c
          inducingVariable: #F1
        #F5 isComplete isOriginVariable isStatic e (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
          element: <testLibrary>::@getter::e
          inducingVariable: #F4
        #F8 isComplete isOriginVariable isStatic f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:30)
          element: <testLibrary>::@getter::f
          inducingVariable: #F7
      setters
        #F3 isComplete isOriginVariable isStatic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:20)
          element: <testLibrary>::@setter::c
          inducingVariable: #F1
          formalParameters
            #F10 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:20)
              element: <testLibrary>::@setter::c::@formalParameter::value
        #F6 isComplete isOriginVariable isStatic e (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
          element: <testLibrary>::@setter::e
          inducingVariable: #F4
          formalParameters
            #F11 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
              element: <testLibrary>::@setter::e::@formalParameter::value
        #F9 isComplete isOriginVariable isStatic f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:30)
          element: <testLibrary>::@setter::f
          inducingVariable: #F7
          formalParameters
            #F12 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:30)
              element: <testLibrary>::@setter::f::@formalParameter::value
  topLevelVariables
    isOriginDeclaration isStatic c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: #F1
      type: C
      getter: <testLibrary>::@getter::c
      setter: <testLibrary>::@setter::c
    isOriginDeclaration isStatic e
      reference: <testLibrary>::@topLevelVariable::e
      firstFragment: #F4
      type: E
      getter: <testLibrary>::@getter::e
      setter: <testLibrary>::@setter::e
    isOriginDeclaration isStatic f
      reference: <testLibrary>::@topLevelVariable::f
      firstFragment: #F7
      type: dynamic Function()
        alias: package:test/a.dart::@typeAlias::F
      getter: <testLibrary>::@getter::f
      setter: <testLibrary>::@setter::f
  getters
    isOriginVariable isStatic c
      reference: <testLibrary>::@getter::c
      firstFragment: #F2
      returnType: C
      variable: <testLibrary>::@topLevelVariable::c
    isOriginVariable isStatic e
      reference: <testLibrary>::@getter::e
      firstFragment: #F5
      returnType: E
      variable: <testLibrary>::@topLevelVariable::e
    isOriginVariable isStatic f
      reference: <testLibrary>::@getter::f
      firstFragment: #F8
      returnType: dynamic Function()
        alias: package:test/a.dart::@typeAlias::F
      variable: <testLibrary>::@topLevelVariable::f
  setters
    isOriginVariable isStatic c
      reference: <testLibrary>::@setter::c
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F10
          type: C
      returnType: void
      variable: <testLibrary>::@topLevelVariable::c
    isOriginVariable isStatic e
      reference: <testLibrary>::@setter::e
      firstFragment: #F6
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F11
          type: E
      returnType: void
      variable: <testLibrary>::@topLevelVariable::e
    isOriginVariable isStatic f
      reference: <testLibrary>::@setter::f
      firstFragment: #F9
      formalParameters
        #E2 requiredPositional value
          firstFragment: #F12
          type: dynamic Function()
            alias: package:test/a.dart::@typeAlias::F
      returnType: void
      variable: <testLibrary>::@topLevelVariable::f
''');
  }

  test_type_reference_to_import_part2() async {
    newFile('$testPackageLibPath/a.dart', r'''
library l;
part "p1.dart";
part "p2.dart";
''');
    newFile('$testPackageLibPath/p1.dart', r'''
part of l;
class C1 {}
''');
    newFile('$testPackageLibPath/p2.dart', r'''
part of l;
class C2 {}
''');
    var library = await buildLibrary(r'''
import "a.dart";

C1 c1;
C2 c2;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart
      topLevelVariables
        #F1 isOriginDeclaration isStatic c1 (nameOffset:21) (firstTokenOffset:21) (offset:21)
          element: <testLibrary>::@topLevelVariable::c1
          inducedGetter: #F2
          inducedSetter: #F3
        #F4 isOriginDeclaration isStatic c2 (nameOffset:28) (firstTokenOffset:28) (offset:28)
          element: <testLibrary>::@topLevelVariable::c2
          inducedGetter: #F5
          inducedSetter: #F6
      getters
        #F2 isComplete isOriginVariable isStatic c1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
          element: <testLibrary>::@getter::c1
          inducingVariable: #F1
        #F5 isComplete isOriginVariable isStatic c2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:28)
          element: <testLibrary>::@getter::c2
          inducingVariable: #F4
      setters
        #F3 isComplete isOriginVariable isStatic c1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
          element: <testLibrary>::@setter::c1
          inducingVariable: #F1
          formalParameters
            #F7 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@setter::c1::@formalParameter::value
        #F6 isComplete isOriginVariable isStatic c2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:28)
          element: <testLibrary>::@setter::c2
          inducingVariable: #F4
          formalParameters
            #F8 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:28)
              element: <testLibrary>::@setter::c2::@formalParameter::value
  topLevelVariables
    isOriginDeclaration isStatic c1
      reference: <testLibrary>::@topLevelVariable::c1
      firstFragment: #F1
      type: C1
      getter: <testLibrary>::@getter::c1
      setter: <testLibrary>::@setter::c1
    isOriginDeclaration isStatic c2
      reference: <testLibrary>::@topLevelVariable::c2
      firstFragment: #F4
      type: C2
      getter: <testLibrary>::@getter::c2
      setter: <testLibrary>::@setter::c2
  getters
    isOriginVariable isStatic c1
      reference: <testLibrary>::@getter::c1
      firstFragment: #F2
      returnType: C1
      variable: <testLibrary>::@topLevelVariable::c1
    isOriginVariable isStatic c2
      reference: <testLibrary>::@getter::c2
      firstFragment: #F5
      returnType: C2
      variable: <testLibrary>::@topLevelVariable::c2
  setters
    isOriginVariable isStatic c1
      reference: <testLibrary>::@setter::c1
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F7
          type: C1
      returnType: void
      variable: <testLibrary>::@topLevelVariable::c1
    isOriginVariable isStatic c2
      reference: <testLibrary>::@setter::c2
      firstFragment: #F6
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F8
          type: C2
      returnType: void
      variable: <testLibrary>::@topLevelVariable::c2
''');
  }

  test_type_reference_to_import_part_in_subdir() async {
    newFile('$testPackageLibPath/a/b.dart', r'''
library l;
part "c.dart";
''');
    newFile('$testPackageLibPath/a/c.dart', r'''
part of l;
class C {}
enum E {
  v
}
typedef F();
''');
    var library = await buildLibrary(r'''
import "a/b.dart";

C c;
E e;
F f;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a/b.dart
      topLevelVariables
        #F1 isOriginDeclaration isStatic c (nameOffset:22) (firstTokenOffset:22) (offset:22)
          element: <testLibrary>::@topLevelVariable::c
          inducedGetter: #F2
          inducedSetter: #F3
        #F4 isOriginDeclaration isStatic e (nameOffset:27) (firstTokenOffset:27) (offset:27)
          element: <testLibrary>::@topLevelVariable::e
          inducedGetter: #F5
          inducedSetter: #F6
        #F7 isOriginDeclaration isStatic f (nameOffset:32) (firstTokenOffset:32) (offset:32)
          element: <testLibrary>::@topLevelVariable::f
          inducedGetter: #F8
          inducedSetter: #F9
      getters
        #F2 isComplete isOriginVariable isStatic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
          element: <testLibrary>::@getter::c
          inducingVariable: #F1
        #F5 isComplete isOriginVariable isStatic e (nameOffset:<null>) (firstTokenOffset:<null>) (offset:27)
          element: <testLibrary>::@getter::e
          inducingVariable: #F4
        #F8 isComplete isOriginVariable isStatic f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:32)
          element: <testLibrary>::@getter::f
          inducingVariable: #F7
      setters
        #F3 isComplete isOriginVariable isStatic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
          element: <testLibrary>::@setter::c
          inducingVariable: #F1
          formalParameters
            #F10 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
              element: <testLibrary>::@setter::c::@formalParameter::value
        #F6 isComplete isOriginVariable isStatic e (nameOffset:<null>) (firstTokenOffset:<null>) (offset:27)
          element: <testLibrary>::@setter::e
          inducingVariable: #F4
          formalParameters
            #F11 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:27)
              element: <testLibrary>::@setter::e::@formalParameter::value
        #F9 isComplete isOriginVariable isStatic f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:32)
          element: <testLibrary>::@setter::f
          inducingVariable: #F7
          formalParameters
            #F12 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:32)
              element: <testLibrary>::@setter::f::@formalParameter::value
  topLevelVariables
    isOriginDeclaration isStatic c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: #F1
      type: C
      getter: <testLibrary>::@getter::c
      setter: <testLibrary>::@setter::c
    isOriginDeclaration isStatic e
      reference: <testLibrary>::@topLevelVariable::e
      firstFragment: #F4
      type: E
      getter: <testLibrary>::@getter::e
      setter: <testLibrary>::@setter::e
    isOriginDeclaration isStatic f
      reference: <testLibrary>::@topLevelVariable::f
      firstFragment: #F7
      type: dynamic Function()
        alias: package:test/a/b.dart::@typeAlias::F
      getter: <testLibrary>::@getter::f
      setter: <testLibrary>::@setter::f
  getters
    isOriginVariable isStatic c
      reference: <testLibrary>::@getter::c
      firstFragment: #F2
      returnType: C
      variable: <testLibrary>::@topLevelVariable::c
    isOriginVariable isStatic e
      reference: <testLibrary>::@getter::e
      firstFragment: #F5
      returnType: E
      variable: <testLibrary>::@topLevelVariable::e
    isOriginVariable isStatic f
      reference: <testLibrary>::@getter::f
      firstFragment: #F8
      returnType: dynamic Function()
        alias: package:test/a/b.dart::@typeAlias::F
      variable: <testLibrary>::@topLevelVariable::f
  setters
    isOriginVariable isStatic c
      reference: <testLibrary>::@setter::c
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F10
          type: C
      returnType: void
      variable: <testLibrary>::@topLevelVariable::c
    isOriginVariable isStatic e
      reference: <testLibrary>::@setter::e
      firstFragment: #F6
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F11
          type: E
      returnType: void
      variable: <testLibrary>::@topLevelVariable::e
    isOriginVariable isStatic f
      reference: <testLibrary>::@setter::f
      firstFragment: #F9
      formalParameters
        #E2 requiredPositional value
          firstFragment: #F12
          type: dynamic Function()
            alias: package:test/a/b.dart::@typeAlias::F
      returnType: void
      variable: <testLibrary>::@topLevelVariable::f
''');
  }

  test_type_reference_to_import_relative() async {
    newFile('$testPackageLibPath/a.dart', r'''
class C {}
enum E {
  v
}
typedef F();
''');
    var library = await buildLibrary(r'''
import "a.dart";

C c;
E e;
F f;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart
      topLevelVariables
        #F1 isOriginDeclaration isStatic c (nameOffset:20) (firstTokenOffset:20) (offset:20)
          element: <testLibrary>::@topLevelVariable::c
          inducedGetter: #F2
          inducedSetter: #F3
        #F4 isOriginDeclaration isStatic e (nameOffset:25) (firstTokenOffset:25) (offset:25)
          element: <testLibrary>::@topLevelVariable::e
          inducedGetter: #F5
          inducedSetter: #F6
        #F7 isOriginDeclaration isStatic f (nameOffset:30) (firstTokenOffset:30) (offset:30)
          element: <testLibrary>::@topLevelVariable::f
          inducedGetter: #F8
          inducedSetter: #F9
      getters
        #F2 isComplete isOriginVariable isStatic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:20)
          element: <testLibrary>::@getter::c
          inducingVariable: #F1
        #F5 isComplete isOriginVariable isStatic e (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
          element: <testLibrary>::@getter::e
          inducingVariable: #F4
        #F8 isComplete isOriginVariable isStatic f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:30)
          element: <testLibrary>::@getter::f
          inducingVariable: #F7
      setters
        #F3 isComplete isOriginVariable isStatic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:20)
          element: <testLibrary>::@setter::c
          inducingVariable: #F1
          formalParameters
            #F10 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:20)
              element: <testLibrary>::@setter::c::@formalParameter::value
        #F6 isComplete isOriginVariable isStatic e (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
          element: <testLibrary>::@setter::e
          inducingVariable: #F4
          formalParameters
            #F11 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
              element: <testLibrary>::@setter::e::@formalParameter::value
        #F9 isComplete isOriginVariable isStatic f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:30)
          element: <testLibrary>::@setter::f
          inducingVariable: #F7
          formalParameters
            #F12 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:30)
              element: <testLibrary>::@setter::f::@formalParameter::value
  topLevelVariables
    isOriginDeclaration isStatic c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: #F1
      type: C
      getter: <testLibrary>::@getter::c
      setter: <testLibrary>::@setter::c
    isOriginDeclaration isStatic e
      reference: <testLibrary>::@topLevelVariable::e
      firstFragment: #F4
      type: E
      getter: <testLibrary>::@getter::e
      setter: <testLibrary>::@setter::e
    isOriginDeclaration isStatic f
      reference: <testLibrary>::@topLevelVariable::f
      firstFragment: #F7
      type: dynamic Function()
        alias: package:test/a.dart::@typeAlias::F
      getter: <testLibrary>::@getter::f
      setter: <testLibrary>::@setter::f
  getters
    isOriginVariable isStatic c
      reference: <testLibrary>::@getter::c
      firstFragment: #F2
      returnType: C
      variable: <testLibrary>::@topLevelVariable::c
    isOriginVariable isStatic e
      reference: <testLibrary>::@getter::e
      firstFragment: #F5
      returnType: E
      variable: <testLibrary>::@topLevelVariable::e
    isOriginVariable isStatic f
      reference: <testLibrary>::@getter::f
      firstFragment: #F8
      returnType: dynamic Function()
        alias: package:test/a.dart::@typeAlias::F
      variable: <testLibrary>::@topLevelVariable::f
  setters
    isOriginVariable isStatic c
      reference: <testLibrary>::@setter::c
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F10
          type: C
      returnType: void
      variable: <testLibrary>::@topLevelVariable::c
    isOriginVariable isStatic e
      reference: <testLibrary>::@setter::e
      firstFragment: #F6
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F11
          type: E
      returnType: void
      variable: <testLibrary>::@topLevelVariable::e
    isOriginVariable isStatic f
      reference: <testLibrary>::@setter::f
      firstFragment: #F9
      formalParameters
        #E2 requiredPositional value
          firstFragment: #F12
          type: dynamic Function()
            alias: package:test/a.dart::@typeAlias::F
      returnType: void
      variable: <testLibrary>::@topLevelVariable::f
''');
  }

  test_type_reference_to_typedef() async {
    var library = await buildLibrary(r'''
typedef F();
F f;
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
      topLevelVariables
        #F2 isOriginDeclaration isStatic f (nameOffset:15) (firstTokenOffset:15) (offset:15)
          element: <testLibrary>::@topLevelVariable::f
          inducedGetter: #F3
          inducedSetter: #F4
      getters
        #F3 isComplete isOriginVariable isStatic f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
          element: <testLibrary>::@getter::f
          inducingVariable: #F2
      setters
        #F4 isComplete isOriginVariable isStatic f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
          element: <testLibrary>::@setter::f
          inducingVariable: #F2
          formalParameters
            #F5 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@setter::f::@formalParameter::value
  typeAliases
    isSimplyBounded F
      reference: <testLibrary>::@typeAlias::F
      firstFragment: #F1
      aliasedType: dynamic Function()
  topLevelVariables
    isOriginDeclaration isStatic f
      reference: <testLibrary>::@topLevelVariable::f
      firstFragment: #F2
      type: dynamic Function()
        alias: <testLibrary>::@typeAlias::F
      getter: <testLibrary>::@getter::f
      setter: <testLibrary>::@setter::f
  getters
    isOriginVariable isStatic f
      reference: <testLibrary>::@getter::f
      firstFragment: #F3
      returnType: dynamic Function()
        alias: <testLibrary>::@typeAlias::F
      variable: <testLibrary>::@topLevelVariable::f
  setters
    isOriginVariable isStatic f
      reference: <testLibrary>::@setter::f
      firstFragment: #F4
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F5
          type: dynamic Function()
            alias: <testLibrary>::@typeAlias::F
      returnType: void
      variable: <testLibrary>::@topLevelVariable::f
''');
  }

  test_type_reference_to_typedef_with_type_arguments() async {
    var library = await buildLibrary(r'''
typedef U F<T, U>(T t);
F<int, String> f;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        #F1 F (nameOffset:10) (firstTokenOffset:0) (offset:10)
          element: <testLibrary>::@typeAlias::F
          typeParameters
            #F2 T (nameOffset:12) (firstTokenOffset:12) (offset:12)
              element: #E0 T
            #F3 U (nameOffset:15) (firstTokenOffset:15) (offset:15)
              element: #E1 U
      topLevelVariables
        #F4 isOriginDeclaration isStatic f (nameOffset:39) (firstTokenOffset:39) (offset:39)
          element: <testLibrary>::@topLevelVariable::f
          inducedGetter: #F5
          inducedSetter: #F6
      getters
        #F5 isComplete isOriginVariable isStatic f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:39)
          element: <testLibrary>::@getter::f
          inducingVariable: #F4
      setters
        #F6 isComplete isOriginVariable isStatic f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:39)
          element: <testLibrary>::@setter::f
          inducingVariable: #F4
          formalParameters
            #F7 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:39)
              element: <testLibrary>::@setter::f::@formalParameter::value
  typeAliases
    isSimplyBounded F
      reference: <testLibrary>::@typeAlias::F
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
        #E1 U
          firstFragment: #F3
      aliasedType: U Function(T)
  topLevelVariables
    isOriginDeclaration isStatic f
      reference: <testLibrary>::@topLevelVariable::f
      firstFragment: #F4
      type: String Function(int)
        alias: <testLibrary>::@typeAlias::F
          typeArguments
            int
            String
      getter: <testLibrary>::@getter::f
      setter: <testLibrary>::@setter::f
  getters
    isOriginVariable isStatic f
      reference: <testLibrary>::@getter::f
      firstFragment: #F5
      returnType: String Function(int)
        alias: <testLibrary>::@typeAlias::F
          typeArguments
            int
            String
      variable: <testLibrary>::@topLevelVariable::f
  setters
    isOriginVariable isStatic f
      reference: <testLibrary>::@setter::f
      firstFragment: #F6
      formalParameters
        #E2 requiredPositional value
          firstFragment: #F7
          type: String Function(int)
            alias: <testLibrary>::@typeAlias::F
              typeArguments
                int
                String
      returnType: void
      variable: <testLibrary>::@topLevelVariable::f
''');
  }

  test_type_reference_to_typedef_with_type_arguments_implicit() async {
    var library = await buildLibrary(r'''
typedef U F<T, U>(T t);
F f;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      typeAliases
        #F1 F (nameOffset:10) (firstTokenOffset:0) (offset:10)
          element: <testLibrary>::@typeAlias::F
          typeParameters
            #F2 T (nameOffset:12) (firstTokenOffset:12) (offset:12)
              element: #E0 T
            #F3 U (nameOffset:15) (firstTokenOffset:15) (offset:15)
              element: #E1 U
      topLevelVariables
        #F4 isOriginDeclaration isStatic f (nameOffset:26) (firstTokenOffset:26) (offset:26)
          element: <testLibrary>::@topLevelVariable::f
          inducedGetter: #F5
          inducedSetter: #F6
      getters
        #F5 isComplete isOriginVariable isStatic f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:26)
          element: <testLibrary>::@getter::f
          inducingVariable: #F4
      setters
        #F6 isComplete isOriginVariable isStatic f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:26)
          element: <testLibrary>::@setter::f
          inducingVariable: #F4
          formalParameters
            #F7 requiredPositional value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:26)
              element: <testLibrary>::@setter::f::@formalParameter::value
  typeAliases
    isSimplyBounded F
      reference: <testLibrary>::@typeAlias::F
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
        #E1 U
          firstFragment: #F3
      aliasedType: U Function(T)
  topLevelVariables
    isOriginDeclaration isStatic f
      reference: <testLibrary>::@topLevelVariable::f
      firstFragment: #F4
      type: dynamic Function(dynamic)
        alias: <testLibrary>::@typeAlias::F
          typeArguments
            dynamic
            dynamic
      getter: <testLibrary>::@getter::f
      setter: <testLibrary>::@setter::f
  getters
    isOriginVariable isStatic f
      reference: <testLibrary>::@getter::f
      firstFragment: #F5
      returnType: dynamic Function(dynamic)
        alias: <testLibrary>::@typeAlias::F
          typeArguments
            dynamic
            dynamic
      variable: <testLibrary>::@topLevelVariable::f
  setters
    isOriginVariable isStatic f
      reference: <testLibrary>::@setter::f
      firstFragment: #F6
      formalParameters
        #E2 requiredPositional value
          firstFragment: #F7
          type: dynamic Function(dynamic)
            alias: <testLibrary>::@typeAlias::F
              typeArguments
                dynamic
                dynamic
      returnType: void
      variable: <testLibrary>::@topLevelVariable::f
''');
  }
}

@reflectiveTest
class TypeInferenceElementTest_fromBytes extends TypeInferenceElementTest {
  @override
  bool get keepLinkingLibraries => false;
}

@reflectiveTest
class TypeInferenceElementTest_keepLinking extends TypeInferenceElementTest {
  @override
  bool get keepLinkingLibraries => true;
}
