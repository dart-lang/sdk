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
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          element: <testLibrary>::@class::A
          typeParameters
            T @8
              element: T@8
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <testLibraryFragment>::@class::A::@constructor::new#element
              typeName: A
          methods
            X @21
              reference: <testLibraryFragment>::@class::A::@method::X
              element: <testLibraryFragment>::@class::A::@method::X#element
              formalParameters
                default a @32
                  reference: <testLibraryFragment>::@class::A::@method::X::@parameter::a
                  element: <testLibraryFragment>::@class::A::@method::X::@parameter::a#element
                  initializer: expression_0
                    ListLiteral
                      constKeyword: const @36
                      leftBracket: [ @42
                      rightBracket: ] @43
                      staticType: List<Never>
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
      typeParameters
        T
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
      methods
        abstract X
          firstFragment: <testLibraryFragment>::@class::A::@method::X
          hasEnclosingTypeParameterReference: true
          formalParameters
            optionalNamed a
              firstFragment: <testLibraryFragment>::@class::A::@method::X::@parameter::a
              type: List<T>
              constantInitializer
                fragment: <testLibraryFragment>::@class::A::@method::X::@parameter::a
                expression: expression_0
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
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class X @57
          reference: <testLibraryFragment>::@class::X
          element: <testLibrary>::@class::X
          fields
            f @71
              reference: <testLibraryFragment>::@class::X::@field::f
              element: <testLibraryFragment>::@class::X::@field::f#element
              getter2: <testLibraryFragment>::@class::X::@getter::f
          constructors
            const new
              reference: <testLibraryFragment>::@class::X::@constructor::new
              element: <testLibraryFragment>::@class::X::@constructor::new#element
              typeName: X
              typeNameOffset: 82
              formalParameters
                default this.f @90
                  reference: <testLibraryFragment>::@class::X::@constructor::new::@parameter::f
                  element: <testLibraryFragment>::@class::X::@constructor::new::@parameter::f#element
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
            synthetic get f
              reference: <testLibraryFragment>::@class::X::@getter::f
              element: <testLibraryFragment>::@class::X::@getter::f#element
      typeAliases
        F @13
          reference: <testLibraryFragment>::@typeAlias::F
          element: <testLibrary>::@typeAlias::F
          typeParameters
            T @15
              element: T@15
      functions
        defaultF @30
          reference: <testLibraryFragment>::@function::defaultF
          element: <testLibrary>::@function::defaultF
          typeParameters
            T @39
              element: T@39
          formalParameters
            v @44
              element: <testLibraryFragment>::@function::defaultF::@parameter::v#element
  classes
    class X
      reference: <testLibrary>::@class::X
      firstFragment: <testLibraryFragment>::@class::X
      fields
        final f
          firstFragment: <testLibraryFragment>::@class::X::@field::f
          type: void Function(dynamic)
            alias: <testLibrary>::@typeAlias::F
              typeArguments
                dynamic
          getter: <testLibraryFragment>::@class::X::@getter::f#element
      constructors
        const new
          firstFragment: <testLibraryFragment>::@class::X::@constructor::new
          formalParameters
            optionalNamed final hasImplicitType f
              firstFragment: <testLibraryFragment>::@class::X::@constructor::new::@parameter::f
              type: void Function(dynamic)
                alias: <testLibrary>::@typeAlias::F
                  typeArguments
                    dynamic
              constantInitializer
                fragment: <testLibraryFragment>::@class::X::@constructor::new::@parameter::f
                expression: expression_0
      getters
        synthetic get f
          firstFragment: <testLibraryFragment>::@class::X::@getter::f
  typeAliases
    F
      firstFragment: <testLibraryFragment>::@typeAlias::F
      typeParameters
        T
      aliasedType: void Function(T)
  functions
    defaultF
      reference: <testLibrary>::@function::defaultF
      firstFragment: <testLibraryFragment>::@function::defaultF
      typeParameters
        T
      formalParameters
        requiredPositional v
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
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          element: <testLibrary>::@class::A
          typeParameters
            T @8
              element: T@8
          constructors
            const new
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <testLibraryFragment>::@class::A::@constructor::new#element
              typeName: A
              typeNameOffset: 21
        class B @34
          reference: <testLibraryFragment>::@class::B
          element: <testLibrary>::@class::B
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::B::@constructor::new
              element: <testLibraryFragment>::@class::B::@constructor::new#element
              typeName: B
          methods
            foo @45
              reference: <testLibraryFragment>::@class::B::@method::foo
              element: <testLibraryFragment>::@class::B::@method::foo#element
              formalParameters
                default a @50
                  reference: <testLibraryFragment>::@class::B::@method::foo::@parameter::a
                  element: <testLibraryFragment>::@class::B::@method::foo::@parameter::a#element
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
                          baseElement: <testLibraryFragment>::@class::A::@constructor::new#element
                          substitution: {T: dynamic Function()}
                      argumentList: ArgumentList
                        leftParenthesis: ( @72
                        rightParenthesis: ) @73
                      staticType: A<dynamic Function()>
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
      methods
        foo
          firstFragment: <testLibraryFragment>::@class::B::@method::foo
          formalParameters
            optionalNamed hasImplicitType a
              firstFragment: <testLibraryFragment>::@class::B::@method::foo::@parameter::a
              type: dynamic
              constantInitializer
                fragment: <testLibraryFragment>::@class::B::@method::foo::@parameter::a
                expression: expression_0
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
    <testLibraryFragment>
      element: <testLibrary>
      functions
        f @5
          reference: <testLibraryFragment>::@function::f
          element: <testLibrary>::@function::f
          formalParameters
            g @8
              element: <testLibraryFragment>::@function::f::@parameter::g#element
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: <testLibraryFragment>::@function::f
      formalParameters
        requiredPositional g
          type: dynamic Function({dynamic a})
          formalParameters
            optionalNamed hasImplicitType a
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
    <testLibraryFragment>
      element: <testLibrary>
      functions
        f @5
          reference: <testLibraryFragment>::@function::f
          element: <testLibrary>::@function::f
          formalParameters
            default compare @22
              element: <testLibraryFragment>::@function::f::@parameter::compare#element
              initializer: expression_0
                PrefixedIdentifier
                  prefix: SimpleIdentifier
                    token: Comparable @32
                    element: dart:core::@class::Comparable
                    staticType: null
                  period: . @42
                  identifier: SimpleIdentifier
                    token: compare @43
                    element: dart:core::<fragment>::@class::Comparable::@method::compare#element
                    staticType: int Function(Comparable<dynamic>, Comparable<dynamic>)
                  element: dart:core::<fragment>::@class::Comparable::@method::compare#element
                  staticType: int Function(Comparable<dynamic>, Comparable<dynamic>)
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: <testLibraryFragment>::@function::f
      formalParameters
        optionalPositional compare
          type: int Function(InvalidType, InvalidType)
            alias: dart:core::@typeAlias::Comparator
              typeArguments
                InvalidType
          constantInitializer
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
    <testLibraryFragment>
      element: <testLibrary>
      functions
        f @5
          reference: <testLibraryFragment>::@function::f
          element: <testLibrary>::@function::f
          formalParameters
            default x @28
              reference: <testLibraryFragment>::@function::f::@parameter::x
              element: <testLibraryFragment>::@function::f::@parameter::x#element
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
      firstFragment: <testLibraryFragment>::@function::f
      formalParameters
        optionalNamed x
          firstFragment: <testLibraryFragment>::@function::f::@parameter::x
          type: ({int f1, bool f2})
          constantInitializer
            fragment: <testLibraryFragment>::@function::f::@parameter::x
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
    <testLibraryFragment>
      element: <testLibrary>
      functions
        f @5
          reference: <testLibraryFragment>::@function::f
          element: <testLibrary>::@function::f
          formalParameters
            default x @28
              reference: <testLibraryFragment>::@function::f::@parameter::x
              element: <testLibraryFragment>::@function::f::@parameter::x#element
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
      firstFragment: <testLibraryFragment>::@function::f
      formalParameters
        optionalNamed x
          firstFragment: <testLibraryFragment>::@function::f::@parameter::x
          type: ({int f1, bool f2})
          constantInitializer
            fragment: <testLibraryFragment>::@function::f::@parameter::x
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
    <testLibraryFragment>
      element: <testLibrary>
      functions
        f @5
          reference: <testLibraryFragment>::@function::f
          element: <testLibrary>::@function::f
          formalParameters
            default x @20
              reference: <testLibraryFragment>::@function::f::@parameter::x
              element: <testLibraryFragment>::@function::f::@parameter::x#element
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
      firstFragment: <testLibraryFragment>::@function::f
      formalParameters
        optionalNamed x
          firstFragment: <testLibraryFragment>::@function::f::@parameter::x
          type: (int, bool)
          constantInitializer
            fragment: <testLibraryFragment>::@function::f::@parameter::x
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
    <testLibraryFragment>
      element: <testLibrary>
      functions
        f @5
          reference: <testLibraryFragment>::@function::f
          element: <testLibrary>::@function::f
          formalParameters
            default x @20
              reference: <testLibraryFragment>::@function::f::@parameter::x
              element: <testLibraryFragment>::@function::f::@parameter::x#element
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
      firstFragment: <testLibraryFragment>::@function::f
      formalParameters
        optionalNamed x
          firstFragment: <testLibraryFragment>::@function::f::@parameter::x
          type: (int, bool)
          constantInitializer
            fragment: <testLibraryFragment>::@function::f::@parameter::x
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
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          element: <testLibrary>::@class::A
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <testLibraryFragment>::@class::A::@constructor::new#element
              typeName: A
      extensions
        extension E @21
          reference: <testLibraryFragment>::@extension::E
          element: <testLibrary>::@extension::E
          methods
            f @44
              reference: <testLibraryFragment>::@extension::E::@method::f
              element: <testLibraryFragment>::@extension::E::@method::f#element
            g @65
              reference: <testLibraryFragment>::@extension::E::@method::g
              element: <testLibraryFragment>::@extension::E::@method::g#element
              formalParameters
                default p @75
                  element: <testLibraryFragment>::@extension::E::@method::g::@parameter::p#element
                  initializer: expression_0
                    SimpleIdentifier
                      token: f @79
                      element: <testLibraryFragment>::@extension::E::@method::f#element
                      staticType: void Function()
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
  extensions
    extension E
      reference: <testLibrary>::@extension::E
      firstFragment: <testLibraryFragment>::@extension::E
      methods
        static f
          firstFragment: <testLibraryFragment>::@extension::E::@method::f
        static g
          firstFragment: <testLibraryFragment>::@extension::E::@method::g
          formalParameters
            optionalPositional p
              type: Object
              constantInitializer
                expression: expression_0
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
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class B @6
          reference: <testLibraryFragment>::@class::B
          element: <testLibrary>::@class::B
          typeParameters
            T1 @8
              element: T1@8
            T2 @12
              element: T2@12
          constructors
            const new
              reference: <testLibraryFragment>::@class::B::@constructor::new
              element: <testLibraryFragment>::@class::B::@constructor::new#element
              typeName: B
              typeNameOffset: 26
        class C @39
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
              typeName: C
          methods
            foo @50
              reference: <testLibraryFragment>::@class::C::@method::foo
              element: <testLibraryFragment>::@class::C::@method::foo#element
              formalParameters
                default b @70
                  element: <testLibraryFragment>::@class::C::@method::foo::@parameter::b#element
                  initializer: expression_0
                    InstanceCreationExpression
                      keyword: const @74
                      constructorName: ConstructorName
                        type: NamedType
                          name: B @80
                          element2: <testLibrary>::@class::B
                          type: B<int, double>
                        element: ConstructorMember
                          baseElement: <testLibraryFragment>::@class::B::@constructor::new#element
                          substitution: {T1: int, T2: double}
                      argumentList: ArgumentList
                        leftParenthesis: ( @81
                        rightParenthesis: ) @82
                      staticType: B<int, double>
  classes
    class B
      reference: <testLibrary>::@class::B
      firstFragment: <testLibraryFragment>::@class::B
      typeParameters
        T1
        T2
      constructors
        const new
          firstFragment: <testLibraryFragment>::@class::B::@constructor::new
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      methods
        foo
          firstFragment: <testLibraryFragment>::@class::C::@method::foo
          formalParameters
            optionalPositional b
              type: B<int, double>
              constantInitializer
                expression: expression_0
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
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class B @6
          reference: <testLibraryFragment>::@class::B
          element: <testLibrary>::@class::B
          typeParameters
            T @8
              element: T@8
          constructors
            const new
              reference: <testLibraryFragment>::@class::B::@constructor::new
              element: <testLibraryFragment>::@class::B::@constructor::new#element
              typeName: B
              typeNameOffset: 21
        class C @34
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
          typeParameters
            T @36
              element: T@36
          constructors
            const new
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
              typeName: C
              typeNameOffset: 49
              formalParameters
                default b @57
                  element: <testLibraryFragment>::@class::C::@constructor::new::@parameter::b#element
                  initializer: expression_0
                    InstanceCreationExpression
                      keyword: const @61
                      constructorName: ConstructorName
                        type: NamedType
                          name: B @67
                          element2: <testLibrary>::@class::B
                          type: B<Never>
                        element: ConstructorMember
                          baseElement: <testLibraryFragment>::@class::B::@constructor::new#element
                          substitution: {T: Never}
                      argumentList: ArgumentList
                        leftParenthesis: ( @68
                        rightParenthesis: ) @69
                      staticType: B<Never>
  classes
    class B
      reference: <testLibrary>::@class::B
      firstFragment: <testLibraryFragment>::@class::B
      typeParameters
        T
      constructors
        const new
          firstFragment: <testLibraryFragment>::@class::B::@constructor::new
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      typeParameters
        T
      constructors
        const new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
          formalParameters
            optionalPositional b
              type: B<T>
              constantInitializer
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
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @15
          reference: <testLibraryFragment>::@class::A
          element: <testLibrary>::@class::A
          typeParameters
            T @17
              element: T@17
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <testLibraryFragment>::@class::A::@constructor::new#element
              typeName: A
        class B @29
          reference: <testLibraryFragment>::@class::B
          element: <testLibrary>::@class::B
          typeParameters
            T @31
              element: T@31
          constructors
            const new
              reference: <testLibraryFragment>::@class::B::@constructor::new
              element: <testLibraryFragment>::@class::B::@constructor::new#element
              typeName: B
              typeNameOffset: 60
        class C @73
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
          typeParameters
            T @75
              element: T@75
          constructors
            const new
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
              typeName: C
              typeNameOffset: 114
              formalParameters
                default a @122
                  element: <testLibraryFragment>::@class::C::@constructor::new::@parameter::a#element
                  initializer: expression_0
                    InstanceCreationExpression
                      keyword: const @126
                      constructorName: ConstructorName
                        type: NamedType
                          name: B @132
                          element2: <testLibrary>::@class::B
                          type: B<Never>
                        element: ConstructorMember
                          baseElement: <testLibraryFragment>::@class::B::@constructor::new#element
                          substitution: {T: Never}
                      argumentList: ArgumentList
                        leftParenthesis: ( @133
                        rightParenthesis: ) @134
                      staticType: B<Never>
  classes
    abstract class A
      reference: <testLibrary>::@class::A
      firstFragment: <testLibraryFragment>::@class::A
      typeParameters
        T
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
    class B
      reference: <testLibrary>::@class::B
      firstFragment: <testLibraryFragment>::@class::B
      typeParameters
        T
      interfaces
        A<T>
      constructors
        const new
          firstFragment: <testLibraryFragment>::@class::B::@constructor::new
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      typeParameters
        T
      interfaces
        A<Iterable<T>>
      constructors
        const new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
          formalParameters
            optionalPositional a
              type: A<T>
              constantInitializer
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
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class B @6
          reference: <testLibraryFragment>::@class::B
          element: <testLibrary>::@class::B
          typeParameters
            T @8
              element: T@8
          constructors
            const new
              reference: <testLibraryFragment>::@class::B::@constructor::new
              element: <testLibraryFragment>::@class::B::@constructor::new#element
              typeName: B
              typeNameOffset: 21
      functions
        foo @33
          reference: <testLibraryFragment>::@function::foo
          element: <testLibrary>::@function::foo
          typeParameters
            T @37
              element: T@37
          formalParameters
            default b @46
              element: <testLibraryFragment>::@function::foo::@parameter::b#element
              initializer: expression_0
                InstanceCreationExpression
                  keyword: const @50
                  constructorName: ConstructorName
                    type: NamedType
                      name: B @56
                      element2: <testLibrary>::@class::B
                      type: B<Never>
                    element: ConstructorMember
                      baseElement: <testLibraryFragment>::@class::B::@constructor::new#element
                      substitution: {T: Never}
                  argumentList: ArgumentList
                    leftParenthesis: ( @57
                    rightParenthesis: ) @58
                  staticType: B<Never>
  classes
    class B
      reference: <testLibrary>::@class::B
      firstFragment: <testLibraryFragment>::@class::B
      typeParameters
        T
      constructors
        const new
          firstFragment: <testLibraryFragment>::@class::B::@constructor::new
  functions
    foo
      reference: <testLibrary>::@function::foo
      firstFragment: <testLibraryFragment>::@function::foo
      typeParameters
        T
      formalParameters
        optionalPositional b
          type: B<T>
          constantInitializer
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
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class B @6
          reference: <testLibraryFragment>::@class::B
          element: <testLibrary>::@class::B
          typeParameters
            T @8
              element: T@8
          constructors
            const new
              reference: <testLibraryFragment>::@class::B::@constructor::new
              element: <testLibraryFragment>::@class::B::@constructor::new#element
              typeName: B
              typeNameOffset: 21
        class C @34
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
              typeName: C
          methods
            foo @45
              reference: <testLibraryFragment>::@class::C::@method::foo
              element: <testLibraryFragment>::@class::C::@method::foo#element
              typeParameters
                T @49
                  element: T@49
              formalParameters
                default b @58
                  element: <testLibraryFragment>::@class::C::@method::foo::@parameter::b#element
                  initializer: expression_0
                    InstanceCreationExpression
                      keyword: const @62
                      constructorName: ConstructorName
                        type: NamedType
                          name: B @68
                          element2: <testLibrary>::@class::B
                          type: B<Never>
                        element: ConstructorMember
                          baseElement: <testLibraryFragment>::@class::B::@constructor::new#element
                          substitution: {T: Never}
                      argumentList: ArgumentList
                        leftParenthesis: ( @69
                        rightParenthesis: ) @70
                      staticType: B<Never>
  classes
    class B
      reference: <testLibrary>::@class::B
      firstFragment: <testLibraryFragment>::@class::B
      typeParameters
        T
      constructors
        const new
          firstFragment: <testLibraryFragment>::@class::B::@constructor::new
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      methods
        foo
          firstFragment: <testLibraryFragment>::@class::C::@method::foo
          typeParameters
            T
          formalParameters
            optionalPositional b
              type: B<T>
              constantInitializer
                expression: expression_0
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
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class B @6
          reference: <testLibraryFragment>::@class::B
          element: <testLibrary>::@class::B
          typeParameters
            T1 @8
              element: T1@8
            T2 @12
              element: T2@12
          constructors
            const new
              reference: <testLibraryFragment>::@class::B::@constructor::new
              element: <testLibraryFragment>::@class::B::@constructor::new#element
              typeName: B
              typeNameOffset: 26
        class C @39
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
          typeParameters
            E1 @41
              element: E1@41
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
              typeName: C
          methods
            foo @54
              reference: <testLibraryFragment>::@class::C::@method::foo
              element: <testLibraryFragment>::@class::C::@method::foo#element
              typeParameters
                E2 @58
                  element: E2@58
              formalParameters
                default b @73
                  element: <testLibraryFragment>::@class::C::@method::foo::@parameter::b#element
                  initializer: expression_0
                    InstanceCreationExpression
                      keyword: const @77
                      constructorName: ConstructorName
                        type: NamedType
                          name: B @83
                          element2: <testLibrary>::@class::B
                          type: B<Never, Never>
                        element: ConstructorMember
                          baseElement: <testLibraryFragment>::@class::B::@constructor::new#element
                          substitution: {T1: Never, T2: Never}
                      argumentList: ArgumentList
                        leftParenthesis: ( @84
                        rightParenthesis: ) @85
                      staticType: B<Never, Never>
  classes
    class B
      reference: <testLibrary>::@class::B
      firstFragment: <testLibraryFragment>::@class::B
      typeParameters
        T1
        T2
      constructors
        const new
          firstFragment: <testLibraryFragment>::@class::B::@constructor::new
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      typeParameters
        E1
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      methods
        foo
          firstFragment: <testLibraryFragment>::@class::C::@method::foo
          hasEnclosingTypeParameterReference: true
          typeParameters
            E2
          formalParameters
            optionalPositional b
              type: B<E1, E2>
              constantInitializer
                expression: expression_0
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
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class B @6
          reference: <testLibraryFragment>::@class::B
          element: <testLibrary>::@class::B
          typeParameters
            T @8
              element: T@8
          constructors
            const new
              reference: <testLibraryFragment>::@class::B::@constructor::new
              element: <testLibraryFragment>::@class::B::@constructor::new#element
              typeName: B
              typeNameOffset: 21
        class C @34
          reference: <testLibraryFragment>::@class::C
          element: <testLibrary>::@class::C
          typeParameters
            T @36
              element: T@36
          constructors
            synthetic new
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
              typeName: C
          methods
            foo @48
              reference: <testLibraryFragment>::@class::C::@method::foo
              element: <testLibraryFragment>::@class::C::@method::foo#element
              formalParameters
                default b @58
                  element: <testLibraryFragment>::@class::C::@method::foo::@parameter::b#element
                  initializer: expression_0
                    InstanceCreationExpression
                      keyword: const @62
                      constructorName: ConstructorName
                        type: NamedType
                          name: B @68
                          element2: <testLibrary>::@class::B
                          type: B<Never>
                        element: ConstructorMember
                          baseElement: <testLibraryFragment>::@class::B::@constructor::new#element
                          substitution: {T: Never}
                      argumentList: ArgumentList
                        leftParenthesis: ( @69
                        rightParenthesis: ) @70
                      staticType: B<Never>
  classes
    class B
      reference: <testLibrary>::@class::B
      firstFragment: <testLibraryFragment>::@class::B
      typeParameters
        T
      constructors
        const new
          firstFragment: <testLibraryFragment>::@class::B::@constructor::new
    class C
      reference: <testLibrary>::@class::C
      firstFragment: <testLibraryFragment>::@class::C
      typeParameters
        T
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      methods
        foo
          firstFragment: <testLibraryFragment>::@class::C::@method::foo
          hasEnclosingTypeParameterReference: true
          formalParameters
            optionalPositional b
              type: B<T>
              constantInitializer
                expression: expression_0
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
