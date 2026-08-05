// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../dart/resolution/node_text_expectations.dart';
import '../elements_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DefaultValueElementTest_keepLinking);
    defineReflectiveTests(DefaultValueElementTest_fromBytes);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

abstract class DefaultValueElementTest extends ElementsBaseTest {
  test_defaultValue_eliminateTypeParameters() async {
    var library = await buildLibrary(r'''
class A<T> {
  const X({List<T> a = const []});
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
          constructors
            #F3 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          methods
            #F4 hasImplicitReturnType isAbstract isOriginDeclaration X (nameOffset:21) (firstTokenOffset:21) (offset:21)
              element: <testLibrary>::@class::A::@method::X
              formalParameters
                #F5 optionalNamed isOriginDeclaration a (nameOffset:32) (firstTokenOffset:24) (offset:32)
                  element: <testLibrary>::@class::A::@method::X::@formalParameter::a
                  initializer: expression_0
                    ListLiteral
                      constKeyword: const @36
                      leftBracket: [ @42
                      rightBracket: ] @43
                      staticType: List<Never>
  classes
    isSimplyBounded class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      constructors
        hasEnclosingTypeParameterReference isOriginImplicitDefault new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
      methods
        hasEnclosingTypeParameterReference isOriginDeclaration X
          reference: <testLibrary>::@class::A::@method::X
          firstFragment: #F4
          formalParameters
            #E1 optionalNamed hasDefaultValue a
              firstFragment: #F5
              type: List<T>
              constantInitializer
                fragment: #F5
                expression: expression_0
          returnType: dynamic
''');
  }

  test_defaultValue_genericFunction() async {
    var library = await buildLibrary(r'''
typedef void F<T>(T v);

void defaultF<T>(T v) {}

class X {
  final F f;
  const X({this.f: defaultF});
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class X (nameOffset:57) (firstTokenOffset:51) (offset:57)
          element: <testLibrary>::@class::X
          fields
            #F2 isFinal isOriginDeclaration f (nameOffset:71) (firstTokenOffset:71) (offset:71)
              element: <testLibrary>::@class::X::@field::f
              inducedGetter: #F3
          constructors
            #F4 isComplete isConst isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:76) (offset:82)
              element: <testLibrary>::@class::X::@constructor::new
              typeName: X
              typeNameOffset: 82
              formalParameters
                #F5 optionalNamed hasImplicitType isFinal isOriginDeclaration this.f (nameOffset:90) (firstTokenOffset:85) (offset:90)
                  element: <testLibrary>::@class::X::@constructor::new::@formalParameter::f
                  initializer: expression_0
                    FunctionReference
                      function: SimpleIdentifier
                        token: defaultF @93
                        element: <testLibrary>::@function::defaultF
                        staticType: void Function<T>(T)
                      staticType: void Function(dynamic)
                      typeArgumentTypes
                        dynamic
          getters
            #F3 isComplete isOriginVariable f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:71)
              element: <testLibrary>::@class::X::@getter::f
              inducingVariable: #F2
      typeAliases
        #F6 F (nameOffset:13) (firstTokenOffset:0) (offset:13)
          element: <testLibrary>::@typeAlias::F
          typeParameters
            #F7 T (nameOffset:15) (firstTokenOffset:15) (offset:15)
              element: #E0 T
      functions
        #F8 isComplete isOriginDeclaration isStatic defaultF (nameOffset:30) (firstTokenOffset:25) (offset:30)
          element: <testLibrary>::@function::defaultF
          typeParameters
            #F9 T (nameOffset:39) (firstTokenOffset:39) (offset:39)
              element: #E1 T
          formalParameters
            #F10 requiredPositional isOriginDeclaration v (nameOffset:44) (firstTokenOffset:42) (offset:44)
              element: <testLibrary>::@function::defaultF::@formalParameter::v
  classes
    isSimplyBounded class X
      reference: <testLibrary>::@class::X
      firstFragment: #F1
      fields
        isFinal isOriginDeclaration f
          reference: <testLibrary>::@class::X::@field::f
          firstFragment: #F2
          type: void Function(dynamic)
            alias: <testLibrary>::@typeAlias::F
              typeArguments
                dynamic
          getter: <testLibrary>::@class::X::@getter::f
      constructors
        isConst isOriginDeclaration new
          reference: <testLibrary>::@class::X::@constructor::new
          firstFragment: #F4
          formalParameters
            #E2 optionalNamed hasDefaultValue hasImplicitType isFinal this.f
              firstFragment: #F5
              type: void Function(dynamic)
                alias: <testLibrary>::@typeAlias::F
                  typeArguments
                    dynamic
              constantInitializer
                fragment: #F5
                expression: expression_0
              field: <testLibrary>::@class::X::@field::f
      getters
        isOriginVariable f
          reference: <testLibrary>::@class::X::@getter::f
          firstFragment: #F3
          returnType: void Function(dynamic)
            alias: <testLibrary>::@typeAlias::F
              typeArguments
                dynamic
          variable: <testLibrary>::@class::X::@field::f
  typeAliases
    isSimplyBounded F
      reference: <testLibrary>::@typeAlias::F
      firstFragment: #F6
      typeParameters
        #E0 T
          firstFragment: #F7
      aliasedType: void Function(T)
  functions
    isOriginDeclaration isStatic defaultF
      reference: <testLibrary>::@function::defaultF
      firstFragment: #F8
      typeParameters
        #E1 T
          firstFragment: #F9
      formalParameters
        #E3 requiredPositional v
          firstFragment: #F10
          type: T
      returnType: void
''');
  }

  test_defaultValue_genericFunctionType() async {
    var library = await buildLibrary(r'''
class A<T> {
  const A();
}

class B {
  void foo({a: const A<Function()>()}) {}
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
          constructors
            #F3 isConst isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:15) (offset:21)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
              typeNameOffset: 21
        #F4 class B (nameOffset:35) (firstTokenOffset:29) (offset:35)
          element: <testLibrary>::@class::B
          constructors
            #F5 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:35)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          methods
            #F6 isComplete isOriginDeclaration foo (nameOffset:46) (firstTokenOffset:41) (offset:46)
              element: <testLibrary>::@class::B::@method::foo
              formalParameters
                #F7 optionalNamed hasImplicitType isOriginDeclaration a (nameOffset:51) (firstTokenOffset:51) (offset:51)
                  element: <testLibrary>::@class::B::@method::foo::@formalParameter::a
                  initializer: expression_0
                    InstanceCreationExpression
                      keyword: const @54
                      constructorName: ConstructorName
                        type: NamedType
                          name: A @60
                          typeArguments: TypeArgumentList
                            leftBracket: < @61
                            arguments
                              GenericFunctionType
                                functionKeyword: Function @62
                                parameters: FormalParameterList
                                  leftParenthesis: ( @70
                                  rightParenthesis: ) @71
                                declaredFragment: GenericFunctionTypeElement
                                  parameters
                                  returnType: dynamic
                                  type: dynamic Function()
                                type: dynamic Function()
                            rightBracket: > @72
                          element: <testLibrary>::@class::A
                          type: A<dynamic Function()>
                        element: SubstitutedConstructorElementImpl
                          baseElement: <testLibrary>::@class::A::@constructor::new
                          substitution: {T: dynamic Function()}
                      argumentList: ArgumentList
                        leftParenthesis: ( @73
                        rightParenthesis: ) @74
                      staticType: A<dynamic Function()>
  classes
    isSimplyBounded class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      constructors
        hasEnclosingTypeParameterReference isConst isOriginDeclaration new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
    isSimplyBounded class B
      reference: <testLibrary>::@class::B
      firstFragment: #F4
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F5
      methods
        isOriginDeclaration foo
          reference: <testLibrary>::@class::B::@method::foo
          firstFragment: #F6
          formalParameters
            #E1 optionalNamed hasDefaultValue hasImplicitType a
              firstFragment: #F7
              type: dynamic
              constantInitializer
                fragment: #F7
                expression: expression_0
          returnType: void
''');
  }

  test_defaultValue_inFunctionTypedFormalParameter() async {
    var library = await buildLibrary(r'''
void f( g({a: 0 is int}) ) {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      functions
        #F1 isComplete isOriginDeclaration isStatic f (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@function::f
          formalParameters
            #F2 requiredPositional isOriginDeclaration g (nameOffset:8) (firstTokenOffset:8) (offset:8)
              element: <testLibrary>::@function::f::@formalParameter::g
  functions
    isOriginDeclaration isStatic f
      reference: <testLibrary>::@function::f
      firstFragment: #F1
      formalParameters
        #E0 requiredPositional g
          firstFragment: #F2
          type: dynamic Function({dynamic a})
      returnType: void
''');
  }

  test_defaultValue_methodMember() async {
    var library = await buildLibrary(r'''
void f([Comparator<T> compare = Comparable.compare]) {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      functions
        #F1 isComplete isOriginDeclaration isStatic f (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@function::f
          formalParameters
            #F2 optionalPositional isOriginDeclaration compare (nameOffset:22) (firstTokenOffset:8) (offset:22)
              element: <testLibrary>::@function::f::@formalParameter::compare
              initializer: expression_0
                PrefixedIdentifier
                  prefix: SimpleIdentifier
                    token: Comparable @32
                    element: dart:core::@class::Comparable
                    staticType: null
                  period: . @42
                  identifier: SimpleIdentifier
                    token: compare @43
                    element: dart:core::@class::Comparable::@method::compare
                    staticType: int Function(Comparable<dynamic>, Comparable<dynamic>)
                  element: dart:core::@class::Comparable::@method::compare
                  staticType: int Function(Comparable<dynamic>, Comparable<dynamic>)
  functions
    isOriginDeclaration isStatic f
      reference: <testLibrary>::@function::f
      firstFragment: #F1
      formalParameters
        #E0 optionalPositional hasDefaultValue compare
          firstFragment: #F2
          type: int Function(InvalidType, InvalidType)
            alias: dart:core::@typeAlias::Comparator
              typeArguments
                InvalidType
          constantInitializer
            fragment: #F2
            expression: expression_0
      returnType: void
''');
  }

  test_defaultValue_recordLiteral_named() async {
    var library = await buildLibrary(r'''
void f({({int f1, bool f2}) x = (f1: 1, f2: true)}) {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      functions
        #F1 isComplete isOriginDeclaration isStatic f (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@function::f
          formalParameters
            #F2 optionalNamed isOriginDeclaration x (nameOffset:28) (firstTokenOffset:8) (offset:28)
              element: <testLibrary>::@function::f::@formalParameter::x
              initializer: expression_0
                RecordLiteral
                  leftParenthesis: ( @32
                  fields
                    RecordLiteralNamedField
                      name: f1 @33
                      colon: : @35
                      fieldExpression: IntegerLiteral
                        literal: 1 @37
                        staticType: int
                    RecordLiteralNamedField
                      name: f2 @40
                      colon: : @42
                      fieldExpression: BooleanLiteral
                        literal: true @44
                        staticType: bool
                  rightParenthesis: ) @48
                  staticType: ({int f1, bool f2})
  functions
    isOriginDeclaration isStatic f
      reference: <testLibrary>::@function::f
      firstFragment: #F1
      formalParameters
        #E0 optionalNamed hasDefaultValue x
          firstFragment: #F2
          type: ({int f1, bool f2})
          constantInitializer
            fragment: #F2
            expression: expression_0
      returnType: void
''');
  }

  test_defaultValue_recordLiteral_named_const() async {
    var library = await buildLibrary(r'''
void f({({int f1, bool f2}) x = const (f1: 1, f2: true)}) {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      functions
        #F1 isComplete isOriginDeclaration isStatic f (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@function::f
          formalParameters
            #F2 optionalNamed isOriginDeclaration x (nameOffset:28) (firstTokenOffset:8) (offset:28)
              element: <testLibrary>::@function::f::@formalParameter::x
              initializer: expression_0
                RecordLiteral
                  constKeyword: const @32
                  leftParenthesis: ( @38
                  fields
                    RecordLiteralNamedField
                      name: f1 @39
                      colon: : @41
                      fieldExpression: IntegerLiteral
                        literal: 1 @43
                        staticType: int
                    RecordLiteralNamedField
                      name: f2 @46
                      colon: : @48
                      fieldExpression: BooleanLiteral
                        literal: true @50
                        staticType: bool
                  rightParenthesis: ) @54
                  staticType: ({int f1, bool f2})
  functions
    isOriginDeclaration isStatic f
      reference: <testLibrary>::@function::f
      firstFragment: #F1
      formalParameters
        #E0 optionalNamed hasDefaultValue x
          firstFragment: #F2
          type: ({int f1, bool f2})
          constantInitializer
            fragment: #F2
            expression: expression_0
      returnType: void
''');
  }

  test_defaultValue_recordLiteral_positional() async {
    var library = await buildLibrary(r'''
void f({(int, bool) x = (1, true)}) {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      functions
        #F1 isComplete isOriginDeclaration isStatic f (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@function::f
          formalParameters
            #F2 optionalNamed isOriginDeclaration x (nameOffset:20) (firstTokenOffset:8) (offset:20)
              element: <testLibrary>::@function::f::@formalParameter::x
              initializer: expression_0
                RecordLiteral
                  leftParenthesis: ( @24
                  fields
                    IntegerLiteral
                      literal: 1 @25
                      staticType: int
                    BooleanLiteral
                      literal: true @28
                      staticType: bool
                  rightParenthesis: ) @32
                  staticType: (int, bool)
  functions
    isOriginDeclaration isStatic f
      reference: <testLibrary>::@function::f
      firstFragment: #F1
      formalParameters
        #E0 optionalNamed hasDefaultValue x
          firstFragment: #F2
          type: (int, bool)
          constantInitializer
            fragment: #F2
            expression: expression_0
      returnType: void
''');
  }

  void test_defaultValue_recordLiteral_positional_const() async {
    var library = await buildLibrary(r'''
void f({(int, bool) x = const (1, true)}) {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      functions
        #F1 isComplete isOriginDeclaration isStatic f (nameOffset:5) (firstTokenOffset:0) (offset:5)
          element: <testLibrary>::@function::f
          formalParameters
            #F2 optionalNamed isOriginDeclaration x (nameOffset:20) (firstTokenOffset:8) (offset:20)
              element: <testLibrary>::@function::f::@formalParameter::x
              initializer: expression_0
                RecordLiteral
                  constKeyword: const @24
                  leftParenthesis: ( @30
                  fields
                    IntegerLiteral
                      literal: 1 @31
                      staticType: int
                    BooleanLiteral
                      literal: true @34
                      staticType: bool
                  rightParenthesis: ) @38
                  staticType: (int, bool)
  functions
    isOriginDeclaration isStatic f
      reference: <testLibrary>::@function::f
      firstFragment: #F1
      formalParameters
        #E0 optionalNamed hasDefaultValue x
          firstFragment: #F2
          type: (int, bool)
          constantInitializer
            fragment: #F2
            expression: expression_0
      returnType: void
''');
  }

  test_defaultValue_refersToExtension_method_inside() async {
    var library = await buildLibrary(r'''
class A {}

extension E on A {
  static void f() {}
  static void g([Object p = f]) {}
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
          constructors
            #F2 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
      extensions
        #F3 extension E (nameOffset:22) (firstTokenOffset:12) (offset:22)
          element: <testLibrary>::@extension::E
          methods
            #F4 isComplete isOriginDeclaration isStatic f (nameOffset:45) (firstTokenOffset:33) (offset:45)
              element: <testLibrary>::@extension::E::@method::f
            #F5 isComplete isOriginDeclaration isStatic g (nameOffset:66) (firstTokenOffset:54) (offset:66)
              element: <testLibrary>::@extension::E::@method::g
              formalParameters
                #F6 optionalPositional isOriginDeclaration p (nameOffset:76) (firstTokenOffset:69) (offset:76)
                  element: <testLibrary>::@extension::E::@method::g::@formalParameter::p
                  initializer: expression_0
                    SimpleIdentifier
                      token: f @80
                      element: <testLibrary>::@extension::E::@method::f
                      staticType: void Function()
  classes
    isSimplyBounded class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
  extensions
    extension E
      reference: <testLibrary>::@extension::E
      firstFragment: #F3
      extendedType: A
      onDeclaration: <testLibrary>::@class::A
      methods
        isOriginDeclaration isStatic f
          reference: <testLibrary>::@extension::E::@method::f
          firstFragment: #F4
          returnType: void
        isOriginDeclaration isStatic g
          reference: <testLibrary>::@extension::E::@method::g
          firstFragment: #F5
          formalParameters
            #E0 optionalPositional hasDefaultValue p
              firstFragment: #F6
              type: Object
              constantInitializer
                fragment: #F6
                expression: expression_0
          returnType: void
''');
  }

  test_defaultValue_refersToGenericClass() async {
    var library = await buildLibrary(r'''
class B<T1, T2> {
  const B();
}

class C {
  void foo([B<int, double> b = const B()]) {}
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class B (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::B
          typeParameters
            #F2 T1 (nameOffset:8) (firstTokenOffset:8) (offset:8)
              element: #E0 T1
            #F3 T2 (nameOffset:12) (firstTokenOffset:12) (offset:12)
              element: #E1 T2
          constructors
            #F4 isConst isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:20) (offset:26)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
              typeNameOffset: 26
        #F5 class C (nameOffset:40) (firstTokenOffset:34) (offset:40)
          element: <testLibrary>::@class::C
          constructors
            #F6 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          methods
            #F7 isComplete isOriginDeclaration foo (nameOffset:51) (firstTokenOffset:46) (offset:51)
              element: <testLibrary>::@class::C::@method::foo
              formalParameters
                #F8 optionalPositional isOriginDeclaration b (nameOffset:71) (firstTokenOffset:56) (offset:71)
                  element: <testLibrary>::@class::C::@method::foo::@formalParameter::b
                  initializer: expression_0
                    InstanceCreationExpression
                      keyword: const @75
                      constructorName: ConstructorName
                        type: NamedType
                          name: B @81
                          element: <testLibrary>::@class::B
                          type: B<int, double>
                        element: SubstitutedConstructorElementImpl
                          baseElement: <testLibrary>::@class::B::@constructor::new
                          substitution: {T1: int, T2: double}
                      argumentList: ArgumentList
                        leftParenthesis: ( @82
                        rightParenthesis: ) @83
                      staticType: B<int, double>
  classes
    isSimplyBounded class B
      reference: <testLibrary>::@class::B
      firstFragment: #F1
      typeParameters
        #E0 T1
          firstFragment: #F2
        #E1 T2
          firstFragment: #F3
      constructors
        hasEnclosingTypeParameterReference isConst isOriginDeclaration new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F4
    isSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F5
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F6
      methods
        isOriginDeclaration foo
          reference: <testLibrary>::@class::C::@method::foo
          firstFragment: #F7
          formalParameters
            #E2 optionalPositional hasDefaultValue b
              firstFragment: #F8
              type: B<int, double>
              constantInitializer
                fragment: #F8
                expression: expression_0
          returnType: void
''');
  }

  test_defaultValue_refersToGenericClass_constructor() async {
    var library = await buildLibrary(r'''
class B<T> {
  const B();
}

class C<T> {
  const C([B<T> b = const B()]);
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class B (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::B
          typeParameters
            #F2 T (nameOffset:8) (firstTokenOffset:8) (offset:8)
              element: #E0 T
          constructors
            #F3 isConst isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:15) (offset:21)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
              typeNameOffset: 21
        #F4 class C (nameOffset:35) (firstTokenOffset:29) (offset:35)
          element: <testLibrary>::@class::C
          typeParameters
            #F5 T (nameOffset:37) (firstTokenOffset:37) (offset:37)
              element: #E1 T
          constructors
            #F6 isConst isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:44) (offset:50)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
              typeNameOffset: 50
              formalParameters
                #F7 optionalPositional isOriginDeclaration b (nameOffset:58) (firstTokenOffset:53) (offset:58)
                  element: <testLibrary>::@class::C::@constructor::new::@formalParameter::b
                  initializer: expression_0
                    InstanceCreationExpression
                      keyword: const @62
                      constructorName: ConstructorName
                        type: NamedType
                          name: B @68
                          element: <testLibrary>::@class::B
                          type: B<Never>
                        element: SubstitutedConstructorElementImpl
                          baseElement: <testLibrary>::@class::B::@constructor::new
                          substitution: {T: Never}
                      argumentList: ArgumentList
                        leftParenthesis: ( @69
                        rightParenthesis: ) @70
                      staticType: B<Never>
  classes
    isSimplyBounded class B
      reference: <testLibrary>::@class::B
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      constructors
        hasEnclosingTypeParameterReference isConst isOriginDeclaration new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F3
    isSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F4
      typeParameters
        #E1 T
          firstFragment: #F5
      constructors
        hasEnclosingTypeParameterReference isConst isOriginDeclaration new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F6
          formalParameters
            #E2 optionalPositional hasDefaultValue b
              firstFragment: #F7
              type: B<T>
              constantInitializer
                fragment: #F7
                expression: expression_0
''');
  }

  test_defaultValue_refersToGenericClass_constructor2() async {
    var library = await buildLibrary(r'''
abstract class A<T> {}

class B<T> implements A<T> {
  const B();
}

class C<T> implements A<Iterable<T>> {
  const C([A<T> a = const B()]);
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
          typeParameters
            #F2 T (nameOffset:17) (firstTokenOffset:17) (offset:17)
              element: #E0 T
          constructors
            #F3 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
        #F4 class B (nameOffset:30) (firstTokenOffset:24) (offset:30)
          element: <testLibrary>::@class::B
          typeParameters
            #F5 T (nameOffset:32) (firstTokenOffset:32) (offset:32)
              element: #E1 T
          constructors
            #F6 isConst isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:55) (offset:61)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
              typeNameOffset: 61
        #F7 class C (nameOffset:75) (firstTokenOffset:69) (offset:75)
          element: <testLibrary>::@class::C
          typeParameters
            #F8 T (nameOffset:77) (firstTokenOffset:77) (offset:77)
              element: #E2 T
          constructors
            #F9 isConst isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:110) (offset:116)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
              typeNameOffset: 116
              formalParameters
                #F10 optionalPositional isOriginDeclaration a (nameOffset:124) (firstTokenOffset:119) (offset:124)
                  element: <testLibrary>::@class::C::@constructor::new::@formalParameter::a
                  initializer: expression_0
                    InstanceCreationExpression
                      keyword: const @128
                      constructorName: ConstructorName
                        type: NamedType
                          name: B @134
                          element: <testLibrary>::@class::B
                          type: B<Never>
                        element: SubstitutedConstructorElementImpl
                          baseElement: <testLibrary>::@class::B::@constructor::new
                          substitution: {T: Never}
                      argumentList: ArgumentList
                        leftParenthesis: ( @135
                        rightParenthesis: ) @136
                      staticType: B<Never>
  classes
    isAbstract isSimplyBounded class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      constructors
        hasEnclosingTypeParameterReference isOriginImplicitDefault new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
    isSimplyBounded class B
      reference: <testLibrary>::@class::B
      firstFragment: #F4
      typeParameters
        #E1 T
          firstFragment: #F5
      interfaces
        A<T>
      constructors
        hasEnclosingTypeParameterReference isConst isOriginDeclaration new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F6
    isSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F7
      typeParameters
        #E2 T
          firstFragment: #F8
      interfaces
        A<Iterable<T>>
      constructors
        hasEnclosingTypeParameterReference isConst isOriginDeclaration new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F9
          formalParameters
            #E3 optionalPositional hasDefaultValue a
              firstFragment: #F10
              type: A<T>
              constantInitializer
                fragment: #F10
                expression: expression_0
''');
  }

  test_defaultValue_refersToGenericClass_functionG() async {
    var library = await buildLibrary(r'''
class B<T> {
  const B();
}

void foo<T>([B<T> b = const B()]) {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class B (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::B
          typeParameters
            #F2 T (nameOffset:8) (firstTokenOffset:8) (offset:8)
              element: #E0 T
          constructors
            #F3 isConst isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:15) (offset:21)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
              typeNameOffset: 21
      functions
        #F4 isComplete isOriginDeclaration isStatic foo (nameOffset:34) (firstTokenOffset:29) (offset:34)
          element: <testLibrary>::@function::foo
          typeParameters
            #F5 T (nameOffset:38) (firstTokenOffset:38) (offset:38)
              element: #E1 T
          formalParameters
            #F6 optionalPositional isOriginDeclaration b (nameOffset:47) (firstTokenOffset:42) (offset:47)
              element: <testLibrary>::@function::foo::@formalParameter::b
              initializer: expression_0
                InstanceCreationExpression
                  keyword: const @51
                  constructorName: ConstructorName
                    type: NamedType
                      name: B @57
                      element: <testLibrary>::@class::B
                      type: B<Never>
                    element: SubstitutedConstructorElementImpl
                      baseElement: <testLibrary>::@class::B::@constructor::new
                      substitution: {T: Never}
                  argumentList: ArgumentList
                    leftParenthesis: ( @58
                    rightParenthesis: ) @59
                  staticType: B<Never>
  classes
    isSimplyBounded class B
      reference: <testLibrary>::@class::B
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      constructors
        hasEnclosingTypeParameterReference isConst isOriginDeclaration new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F3
  functions
    isOriginDeclaration isStatic foo
      reference: <testLibrary>::@function::foo
      firstFragment: #F4
      typeParameters
        #E1 T
          firstFragment: #F5
      formalParameters
        #E2 optionalPositional hasDefaultValue b
          firstFragment: #F6
          type: B<T>
          constantInitializer
            fragment: #F6
            expression: expression_0
      returnType: void
''');
  }

  test_defaultValue_refersToGenericClass_methodG() async {
    var library = await buildLibrary(r'''
class B<T> {
  const B();
}

class C {
  void foo<T>([B<T> b = const B()]) {}
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class B (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::B
          typeParameters
            #F2 T (nameOffset:8) (firstTokenOffset:8) (offset:8)
              element: #E0 T
          constructors
            #F3 isConst isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:15) (offset:21)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
              typeNameOffset: 21
        #F4 class C (nameOffset:35) (firstTokenOffset:29) (offset:35)
          element: <testLibrary>::@class::C
          constructors
            #F5 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:35)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          methods
            #F6 isComplete isOriginDeclaration foo (nameOffset:46) (firstTokenOffset:41) (offset:46)
              element: <testLibrary>::@class::C::@method::foo
              typeParameters
                #F7 T (nameOffset:50) (firstTokenOffset:50) (offset:50)
                  element: #E1 T
              formalParameters
                #F8 optionalPositional isOriginDeclaration b (nameOffset:59) (firstTokenOffset:54) (offset:59)
                  element: <testLibrary>::@class::C::@method::foo::@formalParameter::b
                  initializer: expression_0
                    InstanceCreationExpression
                      keyword: const @63
                      constructorName: ConstructorName
                        type: NamedType
                          name: B @69
                          element: <testLibrary>::@class::B
                          type: B<Never>
                        element: SubstitutedConstructorElementImpl
                          baseElement: <testLibrary>::@class::B::@constructor::new
                          substitution: {T: Never}
                      argumentList: ArgumentList
                        leftParenthesis: ( @70
                        rightParenthesis: ) @71
                      staticType: B<Never>
  classes
    isSimplyBounded class B
      reference: <testLibrary>::@class::B
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      constructors
        hasEnclosingTypeParameterReference isConst isOriginDeclaration new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F3
    isSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F4
      constructors
        isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F5
      methods
        isOriginDeclaration foo
          reference: <testLibrary>::@class::C::@method::foo
          firstFragment: #F6
          typeParameters
            #E1 T
              firstFragment: #F7
          formalParameters
            #E2 optionalPositional hasDefaultValue b
              firstFragment: #F8
              type: B<T>
              constantInitializer
                fragment: #F8
                expression: expression_0
          returnType: void
''');
  }

  test_defaultValue_refersToGenericClass_methodG_classG() async {
    var library = await buildLibrary(r'''
class B<T1, T2> {
  const B();
}

class C<E1> {
  void foo<E2>([B<E1, E2> b = const B()]) {}
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class B (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::B
          typeParameters
            #F2 T1 (nameOffset:8) (firstTokenOffset:8) (offset:8)
              element: #E0 T1
            #F3 T2 (nameOffset:12) (firstTokenOffset:12) (offset:12)
              element: #E1 T2
          constructors
            #F4 isConst isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:20) (offset:26)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
              typeNameOffset: 26
        #F5 class C (nameOffset:40) (firstTokenOffset:34) (offset:40)
          element: <testLibrary>::@class::C
          typeParameters
            #F6 E1 (nameOffset:42) (firstTokenOffset:42) (offset:42)
              element: #E2 E1
          constructors
            #F7 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          methods
            #F8 isComplete isOriginDeclaration foo (nameOffset:55) (firstTokenOffset:50) (offset:55)
              element: <testLibrary>::@class::C::@method::foo
              typeParameters
                #F9 E2 (nameOffset:59) (firstTokenOffset:59) (offset:59)
                  element: #E3 E2
              formalParameters
                #F10 optionalPositional isOriginDeclaration b (nameOffset:74) (firstTokenOffset:64) (offset:74)
                  element: <testLibrary>::@class::C::@method::foo::@formalParameter::b
                  initializer: expression_0
                    InstanceCreationExpression
                      keyword: const @78
                      constructorName: ConstructorName
                        type: NamedType
                          name: B @84
                          element: <testLibrary>::@class::B
                          type: B<Never, Never>
                        element: SubstitutedConstructorElementImpl
                          baseElement: <testLibrary>::@class::B::@constructor::new
                          substitution: {T1: Never, T2: Never}
                      argumentList: ArgumentList
                        leftParenthesis: ( @85
                        rightParenthesis: ) @86
                      staticType: B<Never, Never>
  classes
    isSimplyBounded class B
      reference: <testLibrary>::@class::B
      firstFragment: #F1
      typeParameters
        #E0 T1
          firstFragment: #F2
        #E1 T2
          firstFragment: #F3
      constructors
        hasEnclosingTypeParameterReference isConst isOriginDeclaration new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F4
    isSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F5
      typeParameters
        #E2 E1
          firstFragment: #F6
      constructors
        hasEnclosingTypeParameterReference isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F7
      methods
        hasEnclosingTypeParameterReference isOriginDeclaration foo
          reference: <testLibrary>::@class::C::@method::foo
          firstFragment: #F8
          typeParameters
            #E3 E2
              firstFragment: #F9
          formalParameters
            #E4 optionalPositional hasDefaultValue b
              firstFragment: #F10
              type: B<E1, E2>
              constantInitializer
                fragment: #F10
                expression: expression_0
          returnType: void
''');
  }

  test_defaultValue_refersToGenericClass_methodNG() async {
    var library = await buildLibrary(r'''
class B<T> {
  const B();
}

class C<T> {
  void foo([B<T> b = const B()]) {}
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class B (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::B
          typeParameters
            #F2 T (nameOffset:8) (firstTokenOffset:8) (offset:8)
              element: #E0 T
          constructors
            #F3 isConst isOriginDeclaration new (nameOffset:<null>) (firstTokenOffset:15) (offset:21)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
              typeNameOffset: 21
        #F4 class C (nameOffset:35) (firstTokenOffset:29) (offset:35)
          element: <testLibrary>::@class::C
          typeParameters
            #F5 T (nameOffset:37) (firstTokenOffset:37) (offset:37)
              element: #E1 T
          constructors
            #F6 isOriginImplicitDefault new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:35)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          methods
            #F7 isComplete isOriginDeclaration foo (nameOffset:49) (firstTokenOffset:44) (offset:49)
              element: <testLibrary>::@class::C::@method::foo
              formalParameters
                #F8 optionalPositional isOriginDeclaration b (nameOffset:59) (firstTokenOffset:54) (offset:59)
                  element: <testLibrary>::@class::C::@method::foo::@formalParameter::b
                  initializer: expression_0
                    InstanceCreationExpression
                      keyword: const @63
                      constructorName: ConstructorName
                        type: NamedType
                          name: B @69
                          element: <testLibrary>::@class::B
                          type: B<Never>
                        element: SubstitutedConstructorElementImpl
                          baseElement: <testLibrary>::@class::B::@constructor::new
                          substitution: {T: Never}
                      argumentList: ArgumentList
                        leftParenthesis: ( @70
                        rightParenthesis: ) @71
                      staticType: B<Never>
  classes
    isSimplyBounded class B
      reference: <testLibrary>::@class::B
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      constructors
        hasEnclosingTypeParameterReference isConst isOriginDeclaration new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F3
    isSimplyBounded class C
      reference: <testLibrary>::@class::C
      firstFragment: #F4
      typeParameters
        #E1 T
          firstFragment: #F5
      constructors
        hasEnclosingTypeParameterReference isOriginImplicitDefault new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F6
      methods
        hasEnclosingTypeParameterReference isOriginDeclaration foo
          reference: <testLibrary>::@class::C::@method::foo
          firstFragment: #F7
          formalParameters
            #E2 optionalPositional hasDefaultValue b
              firstFragment: #F8
              type: B<T>
              constantInitializer
                fragment: #F8
                expression: expression_0
          returnType: void
''');
  }
}

@reflectiveTest
class DefaultValueElementTest_fromBytes extends DefaultValueElementTest {
  @override
  bool get keepLinkingLibraries => false;
}

@reflectiveTest
class DefaultValueElementTest_keepLinking extends DefaultValueElementTest {
  @override
  bool get keepLinkingLibraries => true;
}
