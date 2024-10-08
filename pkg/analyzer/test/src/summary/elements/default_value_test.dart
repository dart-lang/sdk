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
          methods
            abstract X @21
              reference: <testLibraryFragment>::@class::A::@method::X
              enclosingElement3: <testLibraryFragment>::@class::A
              parameters
                optionalNamed default a @32
                  reference: <testLibraryFragment>::@class::A::@method::X::@parameter::a
                  type: List<T>
                  constantInitializer
                    ListLiteral
                      constKeyword: const @36
                      leftBracket: [ @42
                      rightBracket: ] @43
                      staticType: List<Never>
              returnType: dynamic
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
          methods
            X @21
              reference: <testLibraryFragment>::@class::A::@method::X
              element: <testLibraryFragment>::@class::A::@method::X#element
              formalParameters
                default a @32
                  reference: <testLibraryFragment>::@class::A::@method::X::@parameter::a
                  element: <testLibraryFragment>::@class::A::@method::X::@parameter::a#element
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
      typeParameters
        T
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
      methods
        abstract X
          firstFragment: <testLibraryFragment>::@class::A::@method::X
          formalParameters
            optionalNamed a
              firstFragment: <testLibraryFragment>::@class::A::@method::X::@parameter::a
              type: List<T>
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        class X @57
          reference: <testLibraryFragment>::@class::X
          enclosingElement3: <testLibraryFragment>
          fields
            final f @71
              reference: <testLibraryFragment>::@class::X::@field::f
              enclosingElement3: <testLibraryFragment>::@class::X
              type: void Function(dynamic)
                alias: <testLibraryFragment>::@typeAlias::F
                  typeArguments
                    dynamic
          constructors
            const @82
              reference: <testLibraryFragment>::@class::X::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::X
              parameters
                optionalNamed default final this.f @90
                  reference: <testLibraryFragment>::@class::X::@constructor::new::@parameter::f
                  type: void Function(dynamic)
                    alias: <testLibraryFragment>::@typeAlias::F
                      typeArguments
                        dynamic
                  constantInitializer
                    FunctionReference
                      function: SimpleIdentifier
                        token: defaultF @93
                        staticElement: <testLibraryFragment>::@function::defaultF
                        element: <testLibraryFragment>::@function::defaultF#element
                        staticType: void Function<T>(T)
                      staticType: void Function(dynamic)
                      typeArgumentTypes
                        dynamic
                  field: <testLibraryFragment>::@class::X::@field::f
          accessors
            synthetic get f @-1
              reference: <testLibraryFragment>::@class::X::@getter::f
              enclosingElement3: <testLibraryFragment>::@class::X
              returnType: void Function(dynamic)
                alias: <testLibraryFragment>::@typeAlias::F
                  typeArguments
                    dynamic
      typeAliases
        functionTypeAliasBased F @13
          reference: <testLibraryFragment>::@typeAlias::F
          typeParameters
            contravariant T @15
              defaultType: dynamic
          aliasedType: void Function(T)
          aliasedElement: GenericFunctionTypeElement
            parameters
              requiredPositional v @20
                type: T
            returnType: void
      functions
        defaultF @30
          reference: <testLibraryFragment>::@function::defaultF
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant T @39
              defaultType: dynamic
          parameters
            requiredPositional v @44
              type: T
          returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class X @57
          reference: <testLibraryFragment>::@class::X
          element: <testLibraryFragment>::@class::X#element
          fields
            f @71
              reference: <testLibraryFragment>::@class::X::@field::f
              element: <testLibraryFragment>::@class::X::@field::f#element
              getter2: <testLibraryFragment>::@class::X::@getter::f
          constructors
            const new @82
              reference: <testLibraryFragment>::@class::X::@constructor::new
              element: <testLibraryFragment>::@class::X::@constructor::new#element
              formalParameters
                default this.f @90
                  reference: <testLibraryFragment>::@class::X::@constructor::new::@parameter::f
                  element: <testLibraryFragment>::@class::X::@constructor::new::@parameter::f#element
          getters
            get f @-1
              reference: <testLibraryFragment>::@class::X::@getter::f
              element: <testLibraryFragment>::@class::X::@getter::f#element
      typeAliases
        F @13
          reference: <testLibraryFragment>::@typeAlias::F
          element: <testLibraryFragment>::@typeAlias::F#element
          typeParameters
            T @15
              element: <not-implemented>
      functions
        defaultF @30
          reference: <testLibraryFragment>::@function::defaultF
          element: <testLibraryFragment>::@function::defaultF#element
          typeParameters
            T @39
              element: <not-implemented>
          formalParameters
            v @44
              element: <testLibraryFragment>::@function::defaultF::@parameter::v#element
  classes
    class X
      firstFragment: <testLibraryFragment>::@class::X
      fields
        final f
          firstFragment: <testLibraryFragment>::@class::X::@field::f
          type: void Function(dynamic)
            alias: <testLibraryFragment>::@typeAlias::F
              typeArguments
                dynamic
          getter: <testLibraryFragment>::@class::X::@getter::f#element
      constructors
        const new
          firstFragment: <testLibraryFragment>::@class::X::@constructor::new
          formalParameters
            optionalNamed final f
              firstFragment: <testLibraryFragment>::@class::X::@constructor::new::@parameter::f
              type: void Function(dynamic)
                alias: <testLibraryFragment>::@typeAlias::F
                  typeArguments
                    dynamic
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
        class B @34
          reference: <testLibraryFragment>::@class::B
          enclosingElement3: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::B::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::B
          methods
            foo @45
              reference: <testLibraryFragment>::@class::B::@method::foo
              enclosingElement3: <testLibraryFragment>::@class::B
              parameters
                optionalNamed default a @50
                  reference: <testLibraryFragment>::@class::B::@method::foo::@parameter::a
                  type: dynamic
                  constantInitializer
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
                          element: <testLibraryFragment>::@class::A
                          element2: <testLibraryFragment>::@class::A#element
                          type: A<dynamic Function()>
                        staticElement: ConstructorMember
                          base: <testLibraryFragment>::@class::A::@constructor::new
                          substitution: {T: dynamic Function()}
                        element: <testLibraryFragment>::@class::A::@constructor::new#element
                      argumentList: ArgumentList
                        leftParenthesis: ( @72
                        rightParenthesis: ) @73
                      staticType: A<dynamic Function()>
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
        class B @34
          reference: <testLibraryFragment>::@class::B
          element: <testLibraryFragment>::@class::B#element
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::B::@constructor::new
              element: <testLibraryFragment>::@class::B::@constructor::new#element
          methods
            foo @45
              reference: <testLibraryFragment>::@class::B::@method::foo
              element: <testLibraryFragment>::@class::B::@method::foo#element
              formalParameters
                default a @50
                  reference: <testLibraryFragment>::@class::B::@method::foo::@parameter::a
                  element: <testLibraryFragment>::@class::B::@method::foo::@parameter::a#element
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
      methods
        foo
          firstFragment: <testLibraryFragment>::@class::B::@method::foo
          formalParameters
            optionalNamed a
              firstFragment: <testLibraryFragment>::@class::B::@method::foo::@parameter::a
              type: dynamic
''');
  }

  test_defaultValue_inFunctionTypedFormalParameter() async {
    var library = await buildLibrary('''
void f( g({a: 0 is int}) ) {}
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
            requiredPositional g @8
              type: dynamic Function({dynamic a})
              parameters
                optionalNamed a @11
                  type: dynamic
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
            g @8
              element: <testLibraryFragment>::@function::f::@parameter::g#element
  functions
    f
      firstFragment: <testLibraryFragment>::@function::f
      formalParameters
        requiredPositional g
          type: dynamic Function({dynamic a})
          formalParameters
            optionalNamed a
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      functions
        f @5
          reference: <testLibraryFragment>::@function::f
          enclosingElement3: <testLibraryFragment>
          parameters
            optionalPositional default compare @22
              type: int Function(InvalidType, InvalidType)
                alias: dart:core::<fragment>::@typeAlias::Comparator
                  typeArguments
                    InvalidType
              constantInitializer
                PrefixedIdentifier
                  prefix: SimpleIdentifier
                    token: Comparable @32
                    staticElement: dart:core::<fragment>::@class::Comparable
                    element: dart:core::<fragment>::@class::Comparable#element
                    staticType: null
                  period: . @42
                  identifier: SimpleIdentifier
                    token: compare @43
                    staticElement: dart:core::<fragment>::@class::Comparable::@method::compare
                    element: dart:core::<fragment>::@class::Comparable::@method::compare#element
                    staticType: int Function(Comparable<dynamic>, Comparable<dynamic>)
                  staticElement: dart:core::<fragment>::@class::Comparable::@method::compare
                  element: dart:core::<fragment>::@class::Comparable::@method::compare#element
                  staticType: int Function(Comparable<dynamic>, Comparable<dynamic>)
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
            default compare @22
              element: <testLibraryFragment>::@function::f::@parameter::compare#element
  functions
    f
      firstFragment: <testLibraryFragment>::@function::f
      formalParameters
        optionalPositional compare
          type: int Function(InvalidType, InvalidType)
            alias: dart:core::<fragment>::@typeAlias::Comparator
              typeArguments
                InvalidType
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      functions
        f @5
          reference: <testLibraryFragment>::@function::f
          enclosingElement3: <testLibraryFragment>
          parameters
            optionalNamed default x @28
              reference: <testLibraryFragment>::@function::f::@parameter::x
              type: ({int f1, bool f2})
              constantInitializer
                RecordLiteral
                  leftParenthesis: ( @32
                  fields
                    NamedExpression
                      name: Label
                        label: SimpleIdentifier
                          token: f1 @33
                          staticElement: <null>
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
                          staticElement: <null>
                          element: <null>
                          staticType: null
                        colon: : @42
                      expression: BooleanLiteral
                        literal: true @44
                        staticType: bool
                  rightParenthesis: ) @48
                  staticType: ({int f1, bool f2})
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
            default x @28
              reference: <testLibraryFragment>::@function::f::@parameter::x
              element: <testLibraryFragment>::@function::f::@parameter::x#element
  functions
    f
      firstFragment: <testLibraryFragment>::@function::f
      formalParameters
        optionalNamed x
          firstFragment: <testLibraryFragment>::@function::f::@parameter::x
          type: ({int f1, bool f2})
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      functions
        f @5
          reference: <testLibraryFragment>::@function::f
          enclosingElement3: <testLibraryFragment>
          parameters
            optionalNamed default x @28
              reference: <testLibraryFragment>::@function::f::@parameter::x
              type: ({int f1, bool f2})
              constantInitializer
                RecordLiteral
                  constKeyword: const @32
                  leftParenthesis: ( @38
                  fields
                    NamedExpression
                      name: Label
                        label: SimpleIdentifier
                          token: f1 @39
                          staticElement: <null>
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
                          staticElement: <null>
                          element: <null>
                          staticType: null
                        colon: : @48
                      expression: BooleanLiteral
                        literal: true @50
                        staticType: bool
                  rightParenthesis: ) @54
                  staticType: ({int f1, bool f2})
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
            default x @28
              reference: <testLibraryFragment>::@function::f::@parameter::x
              element: <testLibraryFragment>::@function::f::@parameter::x#element
  functions
    f
      firstFragment: <testLibraryFragment>::@function::f
      formalParameters
        optionalNamed x
          firstFragment: <testLibraryFragment>::@function::f::@parameter::x
          type: ({int f1, bool f2})
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      functions
        f @5
          reference: <testLibraryFragment>::@function::f
          enclosingElement3: <testLibraryFragment>
          parameters
            optionalNamed default x @20
              reference: <testLibraryFragment>::@function::f::@parameter::x
              type: (int, bool)
              constantInitializer
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
            default x @20
              reference: <testLibraryFragment>::@function::f::@parameter::x
              element: <testLibraryFragment>::@function::f::@parameter::x#element
  functions
    f
      firstFragment: <testLibraryFragment>::@function::f
      formalParameters
        optionalNamed x
          firstFragment: <testLibraryFragment>::@function::f::@parameter::x
          type: (int, bool)
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      functions
        f @5
          reference: <testLibraryFragment>::@function::f
          enclosingElement3: <testLibraryFragment>
          parameters
            optionalNamed default x @20
              reference: <testLibraryFragment>::@function::f::@parameter::x
              type: (int, bool)
              constantInitializer
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
            default x @20
              reference: <testLibraryFragment>::@function::f::@parameter::x
              element: <testLibraryFragment>::@function::f::@parameter::x#element
  functions
    f
      firstFragment: <testLibraryFragment>::@function::f
      formalParameters
        optionalNamed x
          firstFragment: <testLibraryFragment>::@function::f::@parameter::x
          type: (int, bool)
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        class A @6
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::A
      extensions
        E @21
          reference: <testLibraryFragment>::@extension::E
          enclosingElement3: <testLibraryFragment>
          extendedType: A
          methods
            static f @44
              reference: <testLibraryFragment>::@extension::E::@method::f
              enclosingElement3: <testLibraryFragment>::@extension::E
              returnType: void
            static g @65
              reference: <testLibraryFragment>::@extension::E::@method::g
              enclosingElement3: <testLibraryFragment>::@extension::E
              parameters
                optionalPositional default p @75
                  type: Object
                  constantInitializer
                    SimpleIdentifier
                      token: f @79
                      staticElement: <testLibraryFragment>::@extension::E::@method::f
                      element: <testLibraryFragment>::@extension::E::@method::f#element
                      staticType: void Function()
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
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <testLibraryFragment>::@class::A::@constructor::new#element
      extensions
        extension E @21
          reference: <testLibraryFragment>::@extension::E
          element: <testLibraryFragment>::@extension::E#element
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
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
  extensions
    extension E
      firstFragment: <testLibraryFragment>::@extension::E
      methods
        static f
          firstFragment: <testLibraryFragment>::@extension::E::@method::f
        static g
          firstFragment: <testLibraryFragment>::@extension::E::@method::g
          formalParameters
            optionalPositional p
              type: Object
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        class B @6
          reference: <testLibraryFragment>::@class::B
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant T1 @8
              defaultType: dynamic
            covariant T2 @12
              defaultType: dynamic
          constructors
            const @26
              reference: <testLibraryFragment>::@class::B::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::B
        class C @39
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
          methods
            foo @50
              reference: <testLibraryFragment>::@class::C::@method::foo
              enclosingElement3: <testLibraryFragment>::@class::C
              parameters
                optionalPositional default b @70
                  type: B<int, double>
                  constantInitializer
                    InstanceCreationExpression
                      keyword: const @74
                      constructorName: ConstructorName
                        type: NamedType
                          name: B @80
                          element: <testLibraryFragment>::@class::B
                          element2: <testLibraryFragment>::@class::B#element
                          type: B<int, double>
                        staticElement: ConstructorMember
                          base: <testLibraryFragment>::@class::B::@constructor::new
                          substitution: {T1: int, T2: double}
                        element: <testLibraryFragment>::@class::B::@constructor::new#element
                      argumentList: ArgumentList
                        leftParenthesis: ( @81
                        rightParenthesis: ) @82
                      staticType: B<int, double>
              returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class B @6
          reference: <testLibraryFragment>::@class::B
          element: <testLibraryFragment>::@class::B#element
          typeParameters
            T1 @8
              element: <not-implemented>
            T2 @12
              element: <not-implemented>
          constructors
            const new @26
              reference: <testLibraryFragment>::@class::B::@constructor::new
              element: <testLibraryFragment>::@class::B::@constructor::new#element
        class C @39
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C#element
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
          methods
            foo @50
              reference: <testLibraryFragment>::@class::C::@method::foo
              element: <testLibraryFragment>::@class::C::@method::foo#element
              formalParameters
                default b @70
                  element: <testLibraryFragment>::@class::C::@method::foo::@parameter::b#element
  classes
    class B
      firstFragment: <testLibraryFragment>::@class::B
      typeParameters
        T1
        T2
      constructors
        const new
          firstFragment: <testLibraryFragment>::@class::B::@constructor::new
    class C
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        class B @6
          reference: <testLibraryFragment>::@class::B
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant T @8
              defaultType: dynamic
          constructors
            const @21
              reference: <testLibraryFragment>::@class::B::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::B
        class C @34
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant T @36
              defaultType: dynamic
          constructors
            const @49
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
              parameters
                optionalPositional default b @57
                  type: B<T>
                  constantInitializer
                    InstanceCreationExpression
                      keyword: const @61
                      constructorName: ConstructorName
                        type: NamedType
                          name: B @67
                          element: <testLibraryFragment>::@class::B
                          element2: <testLibraryFragment>::@class::B#element
                          type: B<Never>
                        staticElement: ConstructorMember
                          base: <testLibraryFragment>::@class::B::@constructor::new
                          substitution: {T: Never}
                        element: <testLibraryFragment>::@class::B::@constructor::new#element
                      argumentList: ArgumentList
                        leftParenthesis: ( @68
                        rightParenthesis: ) @69
                      staticType: B<Never>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class B @6
          reference: <testLibraryFragment>::@class::B
          element: <testLibraryFragment>::@class::B#element
          typeParameters
            T @8
              element: <not-implemented>
          constructors
            const new @21
              reference: <testLibraryFragment>::@class::B::@constructor::new
              element: <testLibraryFragment>::@class::B::@constructor::new#element
        class C @34
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C#element
          typeParameters
            T @36
              element: <not-implemented>
          constructors
            const new @49
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
              formalParameters
                default b @57
                  element: <testLibraryFragment>::@class::C::@constructor::new::@parameter::b#element
  classes
    class B
      firstFragment: <testLibraryFragment>::@class::B
      typeParameters
        T
      constructors
        const new
          firstFragment: <testLibraryFragment>::@class::B::@constructor::new
    class C
      firstFragment: <testLibraryFragment>::@class::C
      typeParameters
        T
      constructors
        const new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
          formalParameters
            optionalPositional b
              type: B<T>
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        abstract class A @15
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant T @17
              defaultType: dynamic
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::A
        class B @29
          reference: <testLibraryFragment>::@class::B
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant T @31
              defaultType: dynamic
          interfaces
            A<T>
          constructors
            const @60
              reference: <testLibraryFragment>::@class::B::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::B
        class C @73
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant T @75
              defaultType: dynamic
          interfaces
            A<Iterable<T>>
          constructors
            const @114
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
              parameters
                optionalPositional default a @122
                  type: A<T>
                  constantInitializer
                    InstanceCreationExpression
                      keyword: const @126
                      constructorName: ConstructorName
                        type: NamedType
                          name: B @132
                          element: <testLibraryFragment>::@class::B
                          element2: <testLibraryFragment>::@class::B#element
                          type: B<Never>
                        staticElement: ConstructorMember
                          base: <testLibraryFragment>::@class::B::@constructor::new
                          substitution: {T: Never}
                        element: <testLibraryFragment>::@class::B::@constructor::new#element
                      argumentList: ArgumentList
                        leftParenthesis: ( @133
                        rightParenthesis: ) @134
                      staticType: B<Never>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @15
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A#element
          typeParameters
            T @17
              element: <not-implemented>
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <testLibraryFragment>::@class::A::@constructor::new#element
        class B @29
          reference: <testLibraryFragment>::@class::B
          element: <testLibraryFragment>::@class::B#element
          typeParameters
            T @31
              element: <not-implemented>
          constructors
            const new @60
              reference: <testLibraryFragment>::@class::B::@constructor::new
              element: <testLibraryFragment>::@class::B::@constructor::new#element
        class C @73
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C#element
          typeParameters
            T @75
              element: <not-implemented>
          constructors
            const new @114
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
              formalParameters
                default a @122
                  element: <testLibraryFragment>::@class::C::@constructor::new::@parameter::a#element
  classes
    abstract class A
      firstFragment: <testLibraryFragment>::@class::A
      typeParameters
        T
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
    class B
      firstFragment: <testLibraryFragment>::@class::B
      typeParameters
        T
      constructors
        const new
          firstFragment: <testLibraryFragment>::@class::B::@constructor::new
    class C
      firstFragment: <testLibraryFragment>::@class::C
      typeParameters
        T
      constructors
        const new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
          formalParameters
            optionalPositional a
              type: A<T>
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        class B @6
          reference: <testLibraryFragment>::@class::B
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant T @8
              defaultType: dynamic
          constructors
            const @21
              reference: <testLibraryFragment>::@class::B::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::B
      functions
        foo @33
          reference: <testLibraryFragment>::@function::foo
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant T @37
              defaultType: dynamic
          parameters
            optionalPositional default b @46
              type: B<T>
              constantInitializer
                InstanceCreationExpression
                  keyword: const @50
                  constructorName: ConstructorName
                    type: NamedType
                      name: B @56
                      element: <testLibraryFragment>::@class::B
                      element2: <testLibraryFragment>::@class::B#element
                      type: B<Never>
                    staticElement: ConstructorMember
                      base: <testLibraryFragment>::@class::B::@constructor::new
                      substitution: {T: Never}
                    element: <testLibraryFragment>::@class::B::@constructor::new#element
                  argumentList: ArgumentList
                    leftParenthesis: ( @57
                    rightParenthesis: ) @58
                  staticType: B<Never>
          returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class B @6
          reference: <testLibraryFragment>::@class::B
          element: <testLibraryFragment>::@class::B#element
          typeParameters
            T @8
              element: <not-implemented>
          constructors
            const new @21
              reference: <testLibraryFragment>::@class::B::@constructor::new
              element: <testLibraryFragment>::@class::B::@constructor::new#element
      functions
        foo @33
          reference: <testLibraryFragment>::@function::foo
          element: <testLibraryFragment>::@function::foo#element
          typeParameters
            T @37
              element: <not-implemented>
          formalParameters
            default b @46
              element: <testLibraryFragment>::@function::foo::@parameter::b#element
  classes
    class B
      firstFragment: <testLibraryFragment>::@class::B
      typeParameters
        T
      constructors
        const new
          firstFragment: <testLibraryFragment>::@class::B::@constructor::new
  functions
    foo
      firstFragment: <testLibraryFragment>::@function::foo
      typeParameters
        T
      formalParameters
        optionalPositional b
          type: B<T>
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        class B @6
          reference: <testLibraryFragment>::@class::B
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant T @8
              defaultType: dynamic
          constructors
            const @21
              reference: <testLibraryFragment>::@class::B::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::B
        class C @34
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
          methods
            foo @45
              reference: <testLibraryFragment>::@class::C::@method::foo
              enclosingElement3: <testLibraryFragment>::@class::C
              typeParameters
                covariant T @49
                  defaultType: dynamic
              parameters
                optionalPositional default b @58
                  type: B<T>
                  constantInitializer
                    InstanceCreationExpression
                      keyword: const @62
                      constructorName: ConstructorName
                        type: NamedType
                          name: B @68
                          element: <testLibraryFragment>::@class::B
                          element2: <testLibraryFragment>::@class::B#element
                          type: B<Never>
                        staticElement: ConstructorMember
                          base: <testLibraryFragment>::@class::B::@constructor::new
                          substitution: {T: Never}
                        element: <testLibraryFragment>::@class::B::@constructor::new#element
                      argumentList: ArgumentList
                        leftParenthesis: ( @69
                        rightParenthesis: ) @70
                      staticType: B<Never>
              returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class B @6
          reference: <testLibraryFragment>::@class::B
          element: <testLibraryFragment>::@class::B#element
          typeParameters
            T @8
              element: <not-implemented>
          constructors
            const new @21
              reference: <testLibraryFragment>::@class::B::@constructor::new
              element: <testLibraryFragment>::@class::B::@constructor::new#element
        class C @34
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C#element
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
          methods
            foo @45
              reference: <testLibraryFragment>::@class::C::@method::foo
              element: <testLibraryFragment>::@class::C::@method::foo#element
              typeParameters
                T @49
                  element: <not-implemented>
              formalParameters
                default b @58
                  element: <testLibraryFragment>::@class::C::@method::foo::@parameter::b#element
  classes
    class B
      firstFragment: <testLibraryFragment>::@class::B
      typeParameters
        T
      constructors
        const new
          firstFragment: <testLibraryFragment>::@class::B::@constructor::new
    class C
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        class B @6
          reference: <testLibraryFragment>::@class::B
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant T1 @8
              defaultType: dynamic
            covariant T2 @12
              defaultType: dynamic
          constructors
            const @26
              reference: <testLibraryFragment>::@class::B::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::B
        class C @39
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant E1 @41
              defaultType: dynamic
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
          methods
            foo @54
              reference: <testLibraryFragment>::@class::C::@method::foo
              enclosingElement3: <testLibraryFragment>::@class::C
              typeParameters
                covariant E2 @58
                  defaultType: dynamic
              parameters
                optionalPositional default b @73
                  type: B<E1, E2>
                  constantInitializer
                    InstanceCreationExpression
                      keyword: const @77
                      constructorName: ConstructorName
                        type: NamedType
                          name: B @83
                          element: <testLibraryFragment>::@class::B
                          element2: <testLibraryFragment>::@class::B#element
                          type: B<Never, Never>
                        staticElement: ConstructorMember
                          base: <testLibraryFragment>::@class::B::@constructor::new
                          substitution: {T1: Never, T2: Never}
                        element: <testLibraryFragment>::@class::B::@constructor::new#element
                      argumentList: ArgumentList
                        leftParenthesis: ( @84
                        rightParenthesis: ) @85
                      staticType: B<Never, Never>
              returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class B @6
          reference: <testLibraryFragment>::@class::B
          element: <testLibraryFragment>::@class::B#element
          typeParameters
            T1 @8
              element: <not-implemented>
            T2 @12
              element: <not-implemented>
          constructors
            const new @26
              reference: <testLibraryFragment>::@class::B::@constructor::new
              element: <testLibraryFragment>::@class::B::@constructor::new#element
        class C @39
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C#element
          typeParameters
            E1 @41
              element: <not-implemented>
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
          methods
            foo @54
              reference: <testLibraryFragment>::@class::C::@method::foo
              element: <testLibraryFragment>::@class::C::@method::foo#element
              typeParameters
                E2 @58
                  element: <not-implemented>
              formalParameters
                default b @73
                  element: <testLibraryFragment>::@class::C::@method::foo::@parameter::b#element
  classes
    class B
      firstFragment: <testLibraryFragment>::@class::B
      typeParameters
        T1
        T2
      constructors
        const new
          firstFragment: <testLibraryFragment>::@class::B::@constructor::new
    class C
      firstFragment: <testLibraryFragment>::@class::C
      typeParameters
        E1
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      methods
        foo
          firstFragment: <testLibraryFragment>::@class::C::@method::foo
          typeParameters
            E2
          formalParameters
            optionalPositional b
              type: B<E1, E2>
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
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        class B @6
          reference: <testLibraryFragment>::@class::B
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant T @8
              defaultType: dynamic
          constructors
            const @21
              reference: <testLibraryFragment>::@class::B::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::B
        class C @34
          reference: <testLibraryFragment>::@class::C
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant T @36
              defaultType: dynamic
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::C
          methods
            foo @48
              reference: <testLibraryFragment>::@class::C::@method::foo
              enclosingElement3: <testLibraryFragment>::@class::C
              parameters
                optionalPositional default b @58
                  type: B<T>
                  constantInitializer
                    InstanceCreationExpression
                      keyword: const @62
                      constructorName: ConstructorName
                        type: NamedType
                          name: B @68
                          element: <testLibraryFragment>::@class::B
                          element2: <testLibraryFragment>::@class::B#element
                          type: B<Never>
                        staticElement: ConstructorMember
                          base: <testLibraryFragment>::@class::B::@constructor::new
                          substitution: {T: Never}
                        element: <testLibraryFragment>::@class::B::@constructor::new#element
                      argumentList: ArgumentList
                        leftParenthesis: ( @69
                        rightParenthesis: ) @70
                      staticType: B<Never>
              returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class B @6
          reference: <testLibraryFragment>::@class::B
          element: <testLibraryFragment>::@class::B#element
          typeParameters
            T @8
              element: <not-implemented>
          constructors
            const new @21
              reference: <testLibraryFragment>::@class::B::@constructor::new
              element: <testLibraryFragment>::@class::B::@constructor::new#element
        class C @34
          reference: <testLibraryFragment>::@class::C
          element: <testLibraryFragment>::@class::C#element
          typeParameters
            T @36
              element: <not-implemented>
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::C::@constructor::new
              element: <testLibraryFragment>::@class::C::@constructor::new#element
          methods
            foo @48
              reference: <testLibraryFragment>::@class::C::@method::foo
              element: <testLibraryFragment>::@class::C::@method::foo#element
              formalParameters
                default b @58
                  element: <testLibraryFragment>::@class::C::@method::foo::@parameter::b#element
  classes
    class B
      firstFragment: <testLibraryFragment>::@class::B
      typeParameters
        T
      constructors
        const new
          firstFragment: <testLibraryFragment>::@class::B::@constructor::new
    class C
      firstFragment: <testLibraryFragment>::@class::C
      typeParameters
        T
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::C::@constructor::new
      methods
        foo
          firstFragment: <testLibraryFragment>::@class::C::@method::foo
          formalParameters
            optionalPositional b
              type: B<T>
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
