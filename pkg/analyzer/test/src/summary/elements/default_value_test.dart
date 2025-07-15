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
    var library = await buildLibrary('''
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
        #F1 class A @6
          element: <testLibrary>::@class::A
          typeParameters
            #F2 T @8
              element: #E0 T
          constructors
            #F3 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          methods
            #F4 X @21
              element: <testLibrary>::@class::A::@method::X
              formalParameters
                #F5 a @32
                  element: <testLibrary>::@class::A::@method::X::@formalParameter::a
                  initializer: expression_0
                    ListLiteral
                      constKeyword: const @36
                      leftBracket: [ @42
                      rightBracket: ] @43
                      staticType: List<Never>
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
      methods
        abstract X
          reference: <testLibrary>::@class::A::@method::X
          firstFragment: #F4
          hasEnclosingTypeParameterReference: true
          formalParameters
            #E1 optionalNamed a
              firstFragment: #F5
              type: List<T>
              constantInitializer
                fragment: #F5
                expression: expression_0
          returnType: dynamic
''');
  }

  test_defaultValue_genericFunction() async {
    var library = await buildLibrary('''
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
        #F1 class X @57
          element: <testLibrary>::@class::X
          fields
            #F2 f @71
              element: <testLibrary>::@class::X::@field::f
          constructors
            #F3 const new
              element: <testLibrary>::@class::X::@constructor::new
              typeName: X
              typeNameOffset: 82
              formalParameters
                #F4 this.f @90
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
            #F5 synthetic f
              element: <testLibrary>::@class::X::@getter::f
              returnType: void Function(dynamic)
                alias: <testLibrary>::@typeAlias::F
                  typeArguments
                    dynamic
      typeAliases
        #F6 F @13
          element: <testLibrary>::@typeAlias::F
          typeParameters
            #F7 T @15
              element: #E0 T
      functions
        #F8 defaultF @30
          element: <testLibrary>::@function::defaultF
          typeParameters
            #F9 T @39
              element: #E1 T
          formalParameters
            #F10 v @44
              element: <testLibrary>::@function::defaultF::@formalParameter::v
  classes
    class X
      reference: <testLibrary>::@class::X
      firstFragment: #F1
      fields
        final f
          reference: <testLibrary>::@class::X::@field::f
          firstFragment: #F2
          type: void Function(dynamic)
            alias: <testLibrary>::@typeAlias::F
              typeArguments
                dynamic
          getter: <testLibrary>::@class::X::@getter::f
      constructors
        const new
          reference: <testLibrary>::@class::X::@constructor::new
          firstFragment: #F3
          formalParameters
            #E2 optionalNamed final hasImplicitType f
              firstFragment: #F4
              type: void Function(dynamic)
                alias: <testLibrary>::@typeAlias::F
                  typeArguments
                    dynamic
              constantInitializer
                fragment: #F4
                expression: expression_0
      getters
        synthetic f
          reference: <testLibrary>::@class::X::@getter::f
          firstFragment: #F5
          returnType: void Function(dynamic)
            alias: <testLibrary>::@typeAlias::F
              typeArguments
                dynamic
          variable: <testLibrary>::@class::X::@field::f
  typeAliases
    F
      reference: <testLibrary>::@typeAlias::F
      firstFragment: #F6
      typeParameters
        #E0 T
          firstFragment: #F7
      aliasedType: void Function(T)
  functions
    defaultF
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
    var library = await buildLibrary('''
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
        #F1 class A @6
          element: <testLibrary>::@class::A
          typeParameters
            #F2 T @8
              element: #E0 T
          constructors
            #F3 const new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
              typeNameOffset: 21
        #F4 class B @34
          element: <testLibrary>::@class::B
          constructors
            #F5 synthetic new
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          methods
            #F6 foo @45
              element: <testLibrary>::@class::B::@method::foo
              formalParameters
                #F7 a @50
                  element: <testLibrary>::@class::B::@method::foo::@formalParameter::a
                  initializer: expression_0
                    InstanceCreationExpression
                      keyword: const @53
                      constructorName: ConstructorName
                        type: NamedType
                          name: A @59
                          typeArguments: TypeArgumentList
                            leftBracket: < @60
                            arguments
                              GenericFunctionType
                                functionKeyword: Function @61
                                parameters: FormalParameterList
                                  leftParenthesis: ( @69
                                  rightParenthesis: ) @70
                                declaredElement: GenericFunctionTypeElement
                                  parameters
                                  returnType: dynamic
                                  type: dynamic Function()
                                type: dynamic Function()
                            rightBracket: > @71
                          element2: <testLibrary>::@class::A
                          type: A<dynamic Function()>
                        element: ConstructorMember
                          baseElement: <testLibrary>::@class::A::@constructor::new
                          substitution: {T: dynamic Function()}
                      argumentList: ArgumentList
                        leftParenthesis: ( @72
                        rightParenthesis: ) @73
                      staticType: A<dynamic Function()>
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
      methods
        foo
          reference: <testLibrary>::@class::B::@method::foo
          firstFragment: #F6
          formalParameters
            #E1 optionalNamed hasImplicitType a
              firstFragment: #F7
              type: dynamic
              constantInitializer
                fragment: #F7
                expression: expression_0
          returnType: void
''');
  }

  test_defaultValue_inFunctionTypedFormalParameter() async {
    var library = await buildLibrary('''
void f( g({a: 0 is int}) ) {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      functions
        #F1 f @5
          element: <testLibrary>::@function::f
          formalParameters
            #F2 g @8
              element: <testLibrary>::@function::f::@formalParameter::g
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: #F1
      formalParameters
        #E0 requiredPositional g
          firstFragment: #F2
          type: dynamic Function({dynamic a})
          formalParameters
            #E1 optionalNamed hasImplicitType a
              firstFragment: #F3
              type: dynamic
      returnType: void
''');
  }

  test_defaultValue_methodMember() async {
    var library = await buildLibrary('''
void f([Comparator<T> compare = Comparable.compare]) {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      functions
        #F1 f @5
          element: <testLibrary>::@function::f
          formalParameters
            #F2 compare @22
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
    f
      reference: <testLibrary>::@function::f
      firstFragment: #F1
      formalParameters
        #E0 optionalPositional compare
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
    var library = await buildLibrary('''
void f({({int f1, bool f2}) x = (f1: 1, f2: true)}) {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      functions
        #F1 f @5
          element: <testLibrary>::@function::f
          formalParameters
            #F2 x @28
              element: <testLibrary>::@function::f::@formalParameter::x
              initializer: expression_0
                RecordLiteral
                  leftParenthesis: ( @32
                  fields
                    NamedExpression
                      name: Label
                        label: SimpleIdentifier
                          token: f1 @33
                          element: <null>
                          staticType: null
                        colon: : @35
                      expression: IntegerLiteral
                        literal: 1 @37
                        staticType: int
                    NamedExpression
                      name: Label
                        label: SimpleIdentifier
                          token: f2 @40
                          element: <null>
                          staticType: null
                        colon: : @42
                      expression: BooleanLiteral
                        literal: true @44
                        staticType: bool
                  rightParenthesis: ) @48
                  staticType: ({int f1, bool f2})
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: #F1
      formalParameters
        #E0 optionalNamed x
          firstFragment: #F2
          type: ({int f1, bool f2})
          constantInitializer
            fragment: #F2
            expression: expression_0
      returnType: void
''');
  }

  test_defaultValue_recordLiteral_named_const() async {
    var library = await buildLibrary('''
void f({({int f1, bool f2}) x = const (f1: 1, f2: true)}) {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      functions
        #F1 f @5
          element: <testLibrary>::@function::f
          formalParameters
            #F2 x @28
              element: <testLibrary>::@function::f::@formalParameter::x
              initializer: expression_0
                RecordLiteral
                  constKeyword: const @32
                  leftParenthesis: ( @38
                  fields
                    NamedExpression
                      name: Label
                        label: SimpleIdentifier
                          token: f1 @39
                          element: <null>
                          staticType: null
                        colon: : @41
                      expression: IntegerLiteral
                        literal: 1 @43
                        staticType: int
                    NamedExpression
                      name: Label
                        label: SimpleIdentifier
                          token: f2 @46
                          element: <null>
                          staticType: null
                        colon: : @48
                      expression: BooleanLiteral
                        literal: true @50
                        staticType: bool
                  rightParenthesis: ) @54
                  staticType: ({int f1, bool f2})
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: #F1
      formalParameters
        #E0 optionalNamed x
          firstFragment: #F2
          type: ({int f1, bool f2})
          constantInitializer
            fragment: #F2
            expression: expression_0
      returnType: void
''');
  }

  test_defaultValue_recordLiteral_positional() async {
    var library = await buildLibrary('''
void f({(int, bool) x = (1, true)}) {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      functions
        #F1 f @5
          element: <testLibrary>::@function::f
          formalParameters
            #F2 x @20
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
    f
      reference: <testLibrary>::@function::f
      firstFragment: #F1
      formalParameters
        #E0 optionalNamed x
          firstFragment: #F2
          type: (int, bool)
          constantInitializer
            fragment: #F2
            expression: expression_0
      returnType: void
''');
  }

  void test_defaultValue_recordLiteral_positional_const() async {
    var library = await buildLibrary('''
void f({(int, bool) x = const (1, true)}) {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      functions
        #F1 f @5
          element: <testLibrary>::@function::f
          formalParameters
            #F2 x @20
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
    f
      reference: <testLibrary>::@function::f
      firstFragment: #F1
      formalParameters
        #E0 optionalNamed x
          firstFragment: #F2
          type: (int, bool)
          constantInitializer
            fragment: #F2
            expression: expression_0
      returnType: void
''');
  }

  test_defaultValue_refersToExtension_method_inside() async {
    var library = await buildLibrary('''
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
        #F1 class A @6
          element: <testLibrary>::@class::A
          constructors
            #F2 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
      extensions
        #F3 extension E @21
          element: <testLibrary>::@extension::E
          methods
            #F4 f @44
              element: <testLibrary>::@extension::E::@method::f
            #F5 g @65
              element: <testLibrary>::@extension::E::@method::g
              formalParameters
                #F6 p @75
                  element: <testLibrary>::@extension::E::@method::g::@formalParameter::p
                  initializer: expression_0
                    SimpleIdentifier
                      token: f @79
                      element: <testLibrary>::@extension::E::@method::f
                      staticType: void Function()
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
  extensions
    extension E
      reference: <testLibrary>::@extension::E
      firstFragment: #F3
      extendedType: A
      methods
        static f
          reference: <testLibrary>::@extension::E::@method::f
          firstFragment: #F4
          returnType: void
        static g
          reference: <testLibrary>::@extension::E::@method::g
          firstFragment: #F5
          formalParameters
            #E0 optionalPositional p
              firstFragment: #F6
              type: Object
              constantInitializer
                fragment: #F6
                expression: expression_0
          returnType: void
''');
  }

  test_defaultValue_refersToGenericClass() async {
    var library = await buildLibrary('''
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
        #F1 class B @6
          element: <testLibrary>::@class::B
          typeParameters
            #F2 T1 @8
              element: #E0 T1
            #F3 T2 @12
              element: #E1 T2
          constructors
            #F4 const new
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
              typeNameOffset: 26
        #F5 class C @39
          element: <testLibrary>::@class::C
          constructors
            #F6 synthetic new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          methods
            #F7 foo @50
              element: <testLibrary>::@class::C::@method::foo
              formalParameters
                #F8 b @70
                  element: <testLibrary>::@class::C::@method::foo::@formalParameter::b
                  initializer: expression_0
                    InstanceCreationExpression
                      keyword: const @74
                      constructorName: ConstructorName
                        type: NamedType
                          name: B @80
                          element2: <testLibrary>::@class::B
                          type: B<int, double>
                        element: ConstructorMember
                          baseElement: <testLibrary>::@class::B::@constructor::new
                          substitution: {T1: int, T2: double}
                      argumentList: ArgumentList
                        leftParenthesis: ( @81
                        rightParenthesis: ) @82
                      staticType: B<int, double>
  classes
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F1
      typeParameters
        #E0 T1
          firstFragment: #F2
        #E1 T2
          firstFragment: #F3
      constructors
        const new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F4
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F5
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F6
      methods
        foo
          reference: <testLibrary>::@class::C::@method::foo
          firstFragment: #F7
          formalParameters
            #E2 optionalPositional b
              firstFragment: #F8
              type: B<int, double>
              constantInitializer
                fragment: #F8
                expression: expression_0
          returnType: void
''');
  }

  test_defaultValue_refersToGenericClass_constructor() async {
    var library = await buildLibrary('''
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
        #F1 class B @6
          element: <testLibrary>::@class::B
          typeParameters
            #F2 T @8
              element: #E0 T
          constructors
            #F3 const new
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
              typeNameOffset: 21
        #F4 class C @34
          element: <testLibrary>::@class::C
          typeParameters
            #F5 T @36
              element: #E1 T
          constructors
            #F6 const new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
              typeNameOffset: 49
              formalParameters
                #F7 b @57
                  element: <testLibrary>::@class::C::@constructor::new::@formalParameter::b
                  initializer: expression_0
                    InstanceCreationExpression
                      keyword: const @61
                      constructorName: ConstructorName
                        type: NamedType
                          name: B @67
                          element2: <testLibrary>::@class::B
                          type: B<Never>
                        element: ConstructorMember
                          baseElement: <testLibrary>::@class::B::@constructor::new
                          substitution: {T: Never}
                      argumentList: ArgumentList
                        leftParenthesis: ( @68
                        rightParenthesis: ) @69
                      staticType: B<Never>
  classes
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      constructors
        const new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F3
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F4
      typeParameters
        #E1 T
          firstFragment: #F5
      constructors
        const new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F6
          formalParameters
            #E2 optionalPositional b
              firstFragment: #F7
              type: B<T>
              constantInitializer
                fragment: #F7
                expression: expression_0
''');
  }

  test_defaultValue_refersToGenericClass_constructor2() async {
    var library = await buildLibrary('''
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
        #F1 class A @15
          element: <testLibrary>::@class::A
          typeParameters
            #F2 T @17
              element: #E0 T
          constructors
            #F3 synthetic new
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
        #F4 class B @29
          element: <testLibrary>::@class::B
          typeParameters
            #F5 T @31
              element: #E1 T
          constructors
            #F6 const new
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
              typeNameOffset: 60
        #F7 class C @73
          element: <testLibrary>::@class::C
          typeParameters
            #F8 T @75
              element: #E2 T
          constructors
            #F9 const new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
              typeNameOffset: 114
              formalParameters
                #F10 a @122
                  element: <testLibrary>::@class::C::@constructor::new::@formalParameter::a
                  initializer: expression_0
                    InstanceCreationExpression
                      keyword: const @126
                      constructorName: ConstructorName
                        type: NamedType
                          name: B @132
                          element2: <testLibrary>::@class::B
                          type: B<Never>
                        element: ConstructorMember
                          baseElement: <testLibrary>::@class::B::@constructor::new
                          substitution: {T: Never}
                      argumentList: ArgumentList
                        leftParenthesis: ( @133
                        rightParenthesis: ) @134
                      staticType: B<Never>
  classes
    abstract class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F4
      typeParameters
        #E1 T
          firstFragment: #F5
      interfaces
        A<T>
      constructors
        const new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F6
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F7
      typeParameters
        #E2 T
          firstFragment: #F8
      interfaces
        A<Iterable<T>>
      constructors
        const new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F9
          formalParameters
            #E3 optionalPositional a
              firstFragment: #F10
              type: A<T>
              constantInitializer
                fragment: #F10
                expression: expression_0
''');
  }

  test_defaultValue_refersToGenericClass_functionG() async {
    var library = await buildLibrary('''
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
        #F1 class B @6
          element: <testLibrary>::@class::B
          typeParameters
            #F2 T @8
              element: #E0 T
          constructors
            #F3 const new
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
              typeNameOffset: 21
      functions
        #F4 foo @33
          element: <testLibrary>::@function::foo
          typeParameters
            #F5 T @37
              element: #E1 T
          formalParameters
            #F6 b @46
              element: <testLibrary>::@function::foo::@formalParameter::b
              initializer: expression_0
                InstanceCreationExpression
                  keyword: const @50
                  constructorName: ConstructorName
                    type: NamedType
                      name: B @56
                      element2: <testLibrary>::@class::B
                      type: B<Never>
                    element: ConstructorMember
                      baseElement: <testLibrary>::@class::B::@constructor::new
                      substitution: {T: Never}
                  argumentList: ArgumentList
                    leftParenthesis: ( @57
                    rightParenthesis: ) @58
                  staticType: B<Never>
  classes
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      constructors
        const new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F3
  functions
    foo
      reference: <testLibrary>::@function::foo
      firstFragment: #F4
      typeParameters
        #E1 T
          firstFragment: #F5
      formalParameters
        #E2 optionalPositional b
          firstFragment: #F6
          type: B<T>
          constantInitializer
            fragment: #F6
            expression: expression_0
      returnType: void
''');
  }

  test_defaultValue_refersToGenericClass_methodG() async {
    var library = await buildLibrary('''
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
        #F1 class B @6
          element: <testLibrary>::@class::B
          typeParameters
            #F2 T @8
              element: #E0 T
          constructors
            #F3 const new
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
              typeNameOffset: 21
        #F4 class C @34
          element: <testLibrary>::@class::C
          constructors
            #F5 synthetic new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          methods
            #F6 foo @45
              element: <testLibrary>::@class::C::@method::foo
              typeParameters
                #F7 T @49
                  element: #E1 T
              formalParameters
                #F8 b @58
                  element: <testLibrary>::@class::C::@method::foo::@formalParameter::b
                  initializer: expression_0
                    InstanceCreationExpression
                      keyword: const @62
                      constructorName: ConstructorName
                        type: NamedType
                          name: B @68
                          element2: <testLibrary>::@class::B
                          type: B<Never>
                        element: ConstructorMember
                          baseElement: <testLibrary>::@class::B::@constructor::new
                          substitution: {T: Never}
                      argumentList: ArgumentList
                        leftParenthesis: ( @69
                        rightParenthesis: ) @70
                      staticType: B<Never>
  classes
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      constructors
        const new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F3
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F4
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F5
      methods
        foo
          reference: <testLibrary>::@class::C::@method::foo
          firstFragment: #F6
          typeParameters
            #E1 T
              firstFragment: #F7
          formalParameters
            #E2 optionalPositional b
              firstFragment: #F8
              type: B<T>
              constantInitializer
                fragment: #F8
                expression: expression_0
          returnType: void
''');
  }

  test_defaultValue_refersToGenericClass_methodG_classG() async {
    var library = await buildLibrary('''
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
        #F1 class B @6
          element: <testLibrary>::@class::B
          typeParameters
            #F2 T1 @8
              element: #E0 T1
            #F3 T2 @12
              element: #E1 T2
          constructors
            #F4 const new
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
              typeNameOffset: 26
        #F5 class C @39
          element: <testLibrary>::@class::C
          typeParameters
            #F6 E1 @41
              element: #E2 E1
          constructors
            #F7 synthetic new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          methods
            #F8 foo @54
              element: <testLibrary>::@class::C::@method::foo
              typeParameters
                #F9 E2 @58
                  element: #E3 E2
              formalParameters
                #F10 b @73
                  element: <testLibrary>::@class::C::@method::foo::@formalParameter::b
                  initializer: expression_0
                    InstanceCreationExpression
                      keyword: const @77
                      constructorName: ConstructorName
                        type: NamedType
                          name: B @83
                          element2: <testLibrary>::@class::B
                          type: B<Never, Never>
                        element: ConstructorMember
                          baseElement: <testLibrary>::@class::B::@constructor::new
                          substitution: {T1: Never, T2: Never}
                      argumentList: ArgumentList
                        leftParenthesis: ( @84
                        rightParenthesis: ) @85
                      staticType: B<Never, Never>
  classes
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F1
      typeParameters
        #E0 T1
          firstFragment: #F2
        #E1 T2
          firstFragment: #F3
      constructors
        const new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F4
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F5
      typeParameters
        #E2 E1
          firstFragment: #F6
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F7
      methods
        foo
          reference: <testLibrary>::@class::C::@method::foo
          firstFragment: #F8
          hasEnclosingTypeParameterReference: true
          typeParameters
            #E3 E2
              firstFragment: #F9
          formalParameters
            #E4 optionalPositional b
              firstFragment: #F10
              type: B<E1, E2>
              constantInitializer
                fragment: #F10
                expression: expression_0
          returnType: void
''');
  }

  test_defaultValue_refersToGenericClass_methodNG() async {
    var library = await buildLibrary('''
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
        #F1 class B @6
          element: <testLibrary>::@class::B
          typeParameters
            #F2 T @8
              element: #E0 T
          constructors
            #F3 const new
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
              typeNameOffset: 21
        #F4 class C @34
          element: <testLibrary>::@class::C
          typeParameters
            #F5 T @36
              element: #E1 T
          constructors
            #F6 synthetic new
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          methods
            #F7 foo @48
              element: <testLibrary>::@class::C::@method::foo
              formalParameters
                #F8 b @58
                  element: <testLibrary>::@class::C::@method::foo::@formalParameter::b
                  initializer: expression_0
                    InstanceCreationExpression
                      keyword: const @62
                      constructorName: ConstructorName
                        type: NamedType
                          name: B @68
                          element2: <testLibrary>::@class::B
                          type: B<Never>
                        element: ConstructorMember
                          baseElement: <testLibrary>::@class::B::@constructor::new
                          substitution: {T: Never}
                      argumentList: ArgumentList
                        leftParenthesis: ( @69
                        rightParenthesis: ) @70
                      staticType: B<Never>
  classes
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      constructors
        const new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F3
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F4
      typeParameters
        #E1 T
          firstFragment: #F5
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F6
      methods
        foo
          reference: <testLibrary>::@class::C::@method::foo
          firstFragment: #F7
          hasEnclosingTypeParameterReference: true
          formalParameters
            #E2 optionalPositional b
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
