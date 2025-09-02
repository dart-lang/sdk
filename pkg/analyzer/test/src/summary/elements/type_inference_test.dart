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
        #F1 hasInitializer f (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::f
      getters
        #F2 synthetic f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::f
  topLevelVariables
    final hasInitializer f
      reference: <testLibrary>::@topLevelVariable::f
      firstFragment: #F1
      type: V Function<U, V>(U, V)
      getter: <testLibrary>::@getter::f
  getters
    synthetic static f
      reference: <testLibrary>::@getter::f
      firstFragment: #F2
      returnType: V Function<U, V>(U, V)
      variable: <testLibrary>::@topLevelVariable::f
''');
  }

  test_closure_in_variable_declaration_in_part() async {
    newFile(
      '$testPackageLibPath/a.dart',
      'part of lib; final f = (int i) => i.toDouble();',
    );
    var library = await buildLibrary('''
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
          partKeywordOffset: 13
          unit: #F1
    #F1 package:test/a.dart
      element: <testLibrary>
      enclosingFragment: #F0
      previousFragment: #F0
      topLevelVariables
        #F2 hasInitializer f (nameOffset:19) (firstTokenOffset:19) (offset:19)
          element: <testLibrary>::@topLevelVariable::f
      getters
        #F3 synthetic f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:19)
          element: <testLibrary>::@getter::f
  topLevelVariables
    final hasInitializer f
      reference: <testLibrary>::@topLevelVariable::f
      firstFragment: #F2
      type: double Function(int)
      getter: <testLibrary>::@getter::f
  getters
    synthetic static f
      reference: <testLibrary>::@getter::f
      firstFragment: #F3
      returnType: double Function(int)
      variable: <testLibrary>::@topLevelVariable::f
''');
  }

  test_expr_invalid_typeParameter_asPrefix() async {
    var library = await buildLibrary('''
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
            #F3 hasInitializer f (nameOffset:21) (firstTokenOffset:21) (offset:21)
              element: <testLibrary>::@class::C::@field::f
          constructors
            #F4 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F5 synthetic f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@class::C::@getter::f
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      fields
        final hasInitializer f
          reference: <testLibrary>::@class::C::@field::f
          firstFragment: #F3
          type: InvalidType
          getter: <testLibrary>::@class::C::@getter::f
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F4
      getters
        synthetic f
          reference: <testLibrary>::@class::C::@getter::f
          firstFragment: #F5
          returnType: InvalidType
          variable: <testLibrary>::@class::C::@field::f
''');
  }

  test_infer_generic_typedef_complex() async {
    var library = await buildLibrary('''
typedef F<T> = D<T,U> Function<U>();
class C<V> {
  const C(F<V> f);
}
class D<T,U> {}
D<int,U> f<U>() => null;
const x = const C(f);
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class C (nameOffset:43) (firstTokenOffset:37) (offset:43)
          element: <testLibrary>::@class::C
          typeParameters
            #F2 V (nameOffset:45) (firstTokenOffset:45) (offset:45)
              element: #E0 V
          constructors
            #F3 const new (nameOffset:<null>) (firstTokenOffset:52) (offset:58)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
              typeNameOffset: 58
              formalParameters
                #F4 f (nameOffset:65) (firstTokenOffset:60) (offset:65)
                  element: <testLibrary>::@class::C::@constructor::new::@formalParameter::f
        #F5 class D (nameOffset:77) (firstTokenOffset:71) (offset:77)
          element: <testLibrary>::@class::D
          typeParameters
            #F6 T (nameOffset:79) (firstTokenOffset:79) (offset:79)
              element: #E1 T
            #F7 U (nameOffset:81) (firstTokenOffset:81) (offset:81)
              element: #E2 U
          constructors
            #F8 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:77)
              element: <testLibrary>::@class::D::@constructor::new
              typeName: D
      typeAliases
        #F9 F (nameOffset:8) (firstTokenOffset:0) (offset:8)
          element: <testLibrary>::@typeAlias::F
          typeParameters
            #F10 T (nameOffset:10) (firstTokenOffset:10) (offset:10)
              element: #E3 T
      topLevelVariables
        #F11 hasInitializer x (nameOffset:118) (firstTokenOffset:118) (offset:118)
          element: <testLibrary>::@topLevelVariable::x
          initializer: expression_0
            InstanceCreationExpression
              keyword: const @122
              constructorName: ConstructorName
                type: NamedType
                  name: C @128
                  element2: <testLibrary>::@class::C
                  type: C<int>
                element: ConstructorMember
                  baseElement: <testLibrary>::@class::C::@constructor::new
                  substitution: {V: int}
              argumentList: ArgumentList
                leftParenthesis: ( @129
                arguments
                  SimpleIdentifier
                    token: f @130
                    element: <testLibrary>::@function::f
                    staticType: D<int, U> Function<U>()
                rightParenthesis: ) @131
              staticType: C<int>
      getters
        #F12 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:118)
          element: <testLibrary>::@getter::x
      functions
        #F13 f (nameOffset:96) (firstTokenOffset:87) (offset:96)
          element: <testLibrary>::@function::f
          typeParameters
            #F14 U (nameOffset:98) (firstTokenOffset:98) (offset:98)
              element: #E4 U
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      typeParameters
        #E0 V
          firstFragment: #F2
      constructors
        const new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
          formalParameters
            #E5 requiredPositional f
              firstFragment: #F4
              type: D<V, U> Function<U>()
                alias: <testLibrary>::@typeAlias::F
                  typeArguments
                    V
    class D
      reference: <testLibrary>::@class::D
      firstFragment: #F5
      typeParameters
        #E1 T
          firstFragment: #F6
        #E2 U
          firstFragment: #F7
      constructors
        synthetic new
          reference: <testLibrary>::@class::D::@constructor::new
          firstFragment: #F8
  typeAliases
    F
      reference: <testLibrary>::@typeAlias::F
      firstFragment: #F9
      typeParameters
        #E3 T
          firstFragment: #F10
      aliasedType: D<T, U> Function<U>()
  topLevelVariables
    const hasInitializer x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F11
      type: C<int>
      constantInitializer
        fragment: #F11
        expression: expression_0
      getter: <testLibrary>::@getter::x
  getters
    synthetic static x
      reference: <testLibrary>::@getter::x
      firstFragment: #F12
      returnType: C<int>
      variable: <testLibrary>::@topLevelVariable::x
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: #F13
      typeParameters
        #E4 U
          firstFragment: #F14
      returnType: D<int, U>
''');
  }

  test_infer_generic_typedef_simple() async {
    var library = await buildLibrary('''
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
        #F1 class C (nameOffset:38) (firstTokenOffset:32) (offset:38)
          element: <testLibrary>::@class::C
          constructors
            #F2 const new (nameOffset:<null>) (firstTokenOffset:44) (offset:50)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
              typeNameOffset: 50
              formalParameters
                #F3 f (nameOffset:54) (firstTokenOffset:52) (offset:54)
                  element: <testLibrary>::@class::C::@constructor::new::@formalParameter::f
        #F4 class D (nameOffset:66) (firstTokenOffset:60) (offset:66)
          element: <testLibrary>::@class::D
          typeParameters
            #F5 T (nameOffset:68) (firstTokenOffset:68) (offset:68)
              element: #E0 T
          constructors
            #F6 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:66)
              element: <testLibrary>::@class::D::@constructor::new
              typeName: D
      typeAliases
        #F7 F (nameOffset:8) (firstTokenOffset:0) (offset:8)
          element: <testLibrary>::@typeAlias::F
      topLevelVariables
        #F8 hasInitializer x (nameOffset:101) (firstTokenOffset:101) (offset:101)
          element: <testLibrary>::@topLevelVariable::x
          initializer: expression_0
            InstanceCreationExpression
              keyword: const @105
              constructorName: ConstructorName
                type: NamedType
                  name: C @111
                  element2: <testLibrary>::@class::C
                  type: C
                element: <testLibrary>::@class::C::@constructor::new
              argumentList: ArgumentList
                leftParenthesis: ( @112
                arguments
                  SimpleIdentifier
                    token: f @113
                    element: <testLibrary>::@function::f
                    staticType: D<T> Function<T>()
                rightParenthesis: ) @114
              staticType: C
      getters
        #F9 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:101)
          element: <testLibrary>::@getter::x
      functions
        #F10 f (nameOffset:79) (firstTokenOffset:74) (offset:79)
          element: <testLibrary>::@function::f
          typeParameters
            #F11 T (nameOffset:81) (firstTokenOffset:81) (offset:81)
              element: #E1 T
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      constructors
        const new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
          formalParameters
            #E2 requiredPositional f
              firstFragment: #F3
              type: D<T> Function<T>()
                alias: <testLibrary>::@typeAlias::F
    class D
      reference: <testLibrary>::@class::D
      firstFragment: #F4
      typeParameters
        #E0 T
          firstFragment: #F5
      constructors
        synthetic new
          reference: <testLibrary>::@class::D::@constructor::new
          firstFragment: #F6
  typeAliases
    F
      reference: <testLibrary>::@typeAlias::F
      firstFragment: #F7
      aliasedType: D<T> Function<T>()
  topLevelVariables
    const hasInitializer x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F8
      type: C
      constantInitializer
        fragment: #F8
        expression: expression_0
      getter: <testLibrary>::@getter::x
  getters
    synthetic static x
      reference: <testLibrary>::@getter::x
      firstFragment: #F9
      returnType: C
      variable: <testLibrary>::@topLevelVariable::x
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: #F10
      typeParameters
        #E1 T
          firstFragment: #F11
      returnType: D<T>
''');
  }

  test_infer_instanceCreation_fromArguments() async {
    var library = await buildLibrary('''
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
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
        #F3 class B (nameOffset:18) (firstTokenOffset:12) (offset:18)
          element: <testLibrary>::@class::B
          constructors
            #F4 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:18)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
        #F5 class S (nameOffset:40) (firstTokenOffset:34) (offset:40)
          element: <testLibrary>::@class::S
          typeParameters
            #F6 T (nameOffset:42) (firstTokenOffset:42) (offset:42)
              element: #E0 T
          constructors
            #F7 new (nameOffset:<null>) (firstTokenOffset:59) (offset:59)
              element: <testLibrary>::@class::S::@constructor::new
              typeName: S
              typeNameOffset: 59
              formalParameters
                #F8 _ (nameOffset:63) (firstTokenOffset:61) (offset:63)
                  element: <testLibrary>::@class::S::@constructor::new::@formalParameter::_
      topLevelVariables
        #F9 hasInitializer s (nameOffset:74) (firstTokenOffset:74) (offset:74)
          element: <testLibrary>::@topLevelVariable::s
      getters
        #F10 synthetic s (nameOffset:<null>) (firstTokenOffset:<null>) (offset:74)
          element: <testLibrary>::@getter::s
      setters
        #F11 synthetic s (nameOffset:<null>) (firstTokenOffset:<null>) (offset:74)
          element: <testLibrary>::@setter::s
          formalParameters
            #F12 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:74)
              element: <testLibrary>::@setter::s::@formalParameter::value
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F3
      supertype: A
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F4
          superConstructor: <testLibrary>::@class::A::@constructor::new
    class S
      reference: <testLibrary>::@class::S
      firstFragment: #F5
      typeParameters
        #E0 T
          firstFragment: #F6
          bound: A
      constructors
        new
          reference: <testLibrary>::@class::S::@constructor::new
          firstFragment: #F7
          formalParameters
            #E1 requiredPositional _
              firstFragment: #F8
              type: T
  topLevelVariables
    hasInitializer s
      reference: <testLibrary>::@topLevelVariable::s
      firstFragment: #F9
      type: S<B>
      getter: <testLibrary>::@getter::s
      setter: <testLibrary>::@setter::s
  getters
    synthetic static s
      reference: <testLibrary>::@getter::s
      firstFragment: #F10
      returnType: S<B>
      variable: <testLibrary>::@topLevelVariable::s
  setters
    synthetic static s
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
    var library = await buildLibrary('''
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
            #F2 b (nameOffset:14) (firstTokenOffset:14) (offset:14)
              element: <testLibrary>::@class::A::@field::b
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F4 synthetic b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:14)
              element: <testLibrary>::@class::A::@getter::b
          setters
            #F5 synthetic b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:14)
              element: <testLibrary>::@class::A::@setter::b
              formalParameters
                #F6 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:14)
                  element: <testLibrary>::@class::A::@setter::b::@formalParameter::value
        #F7 class B (nameOffset:25) (firstTokenOffset:19) (offset:25)
          element: <testLibrary>::@class::B
          fields
            #F8 synthetic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
              element: <testLibrary>::@class::B::@field::c
          constructors
            #F9 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          getters
            #F10 c (nameOffset:37) (firstTokenOffset:31) (offset:37)
              element: <testLibrary>::@class::B::@getter::c
          setters
            #F11 c (nameOffset:59) (firstTokenOffset:50) (offset:59)
              element: <testLibrary>::@class::B::@setter::c
              formalParameters
                #F12 value (nameOffset:63) (firstTokenOffset:61) (offset:63)
                  element: <testLibrary>::@class::B::@setter::c::@formalParameter::value
        #F13 class C (nameOffset:81) (firstTokenOffset:75) (offset:81)
          element: <testLibrary>::@class::C
          constructors
            #F14 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:81)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
        #F15 class D (nameOffset:92) (firstTokenOffset:86) (offset:92)
          element: <testLibrary>::@class::D
          constructors
            #F16 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:92)
              element: <testLibrary>::@class::D::@constructor::new
              typeName: D
      topLevelVariables
        #F17 hasInitializer a (nameOffset:111) (firstTokenOffset:111) (offset:111)
          element: <testLibrary>::@topLevelVariable::a
        #F18 hasInitializer x (nameOffset:128) (firstTokenOffset:128) (offset:128)
          element: <testLibrary>::@topLevelVariable::x
      getters
        #F19 synthetic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:111)
          element: <testLibrary>::@getter::a
        #F20 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:128)
          element: <testLibrary>::@getter::x
      setters
        #F21 synthetic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:111)
          element: <testLibrary>::@setter::a
          formalParameters
            #F22 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:111)
              element: <testLibrary>::@setter::a::@formalParameter::value
        #F23 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:128)
          element: <testLibrary>::@setter::x
          formalParameters
            #F24 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:128)
              element: <testLibrary>::@setter::x::@formalParameter::value
  classes
    hasNonFinalField class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        b
          reference: <testLibrary>::@class::A::@field::b
          firstFragment: #F2
          type: B
          getter: <testLibrary>::@class::A::@getter::b
          setter: <testLibrary>::@class::A::@setter::b
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F3
      getters
        synthetic b
          reference: <testLibrary>::@class::A::@getter::b
          firstFragment: #F4
          returnType: B
          variable: <testLibrary>::@class::A::@field::b
      setters
        synthetic b
          reference: <testLibrary>::@class::A::@setter::b
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F6
              type: B
          returnType: void
          variable: <testLibrary>::@class::A::@field::b
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F7
      fields
        synthetic c
          reference: <testLibrary>::@class::B::@field::c
          firstFragment: #F8
          type: C
          getter: <testLibrary>::@class::B::@getter::c
          setter: <testLibrary>::@class::B::@setter::c
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F9
      getters
        c
          reference: <testLibrary>::@class::B::@getter::c
          firstFragment: #F10
          returnType: C
          variable: <testLibrary>::@class::B::@field::c
      setters
        c
          reference: <testLibrary>::@class::B::@setter::c
          firstFragment: #F11
          formalParameters
            #E1 requiredPositional value
              firstFragment: #F12
              type: C
          returnType: void
          variable: <testLibrary>::@class::B::@field::c
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F13
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F14
    class D
      reference: <testLibrary>::@class::D
      firstFragment: #F15
      supertype: C
      constructors
        synthetic new
          reference: <testLibrary>::@class::D::@constructor::new
          firstFragment: #F16
          superConstructor: <testLibrary>::@class::C::@constructor::new
  topLevelVariables
    hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F17
      type: A
      getter: <testLibrary>::@getter::a
      setter: <testLibrary>::@setter::a
    hasInitializer x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F18
      type: C
      getter: <testLibrary>::@getter::x
      setter: <testLibrary>::@setter::x
  getters
    synthetic static a
      reference: <testLibrary>::@getter::a
      firstFragment: #F19
      returnType: A
      variable: <testLibrary>::@topLevelVariable::a
    synthetic static x
      reference: <testLibrary>::@getter::x
      firstFragment: #F20
      returnType: C
      variable: <testLibrary>::@topLevelVariable::x
  setters
    synthetic static a
      reference: <testLibrary>::@setter::a
      firstFragment: #F21
      formalParameters
        #E2 requiredPositional value
          firstFragment: #F22
          type: A
      returnType: void
      variable: <testLibrary>::@topLevelVariable::a
    synthetic static x
      reference: <testLibrary>::@setter::x
      firstFragment: #F23
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
    var library = await buildLibrary('''
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
        #F1 hasInitializer x (nameOffset:4) (firstTokenOffset:4) (offset:4)
          element: <testLibrary>::@topLevelVariable::x
        #F2 hasInitializer y (nameOffset:40) (firstTokenOffset:40) (offset:40)
          element: <testLibrary>::@topLevelVariable::y
        #F3 hasInitializer z (nameOffset:53) (firstTokenOffset:53) (offset:53)
          element: <testLibrary>::@topLevelVariable::z
      getters
        #F4 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@getter::x
        #F5 synthetic y (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
          element: <testLibrary>::@getter::y
        #F6 synthetic z (nameOffset:<null>) (firstTokenOffset:<null>) (offset:53)
          element: <testLibrary>::@getter::z
      setters
        #F7 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@setter::x
          formalParameters
            #F8 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
              element: <testLibrary>::@setter::x::@formalParameter::value
        #F9 synthetic y (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
          element: <testLibrary>::@setter::y
          formalParameters
            #F10 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
              element: <testLibrary>::@setter::y::@formalParameter::value
        #F11 synthetic z (nameOffset:<null>) (firstTokenOffset:<null>) (offset:53)
          element: <testLibrary>::@setter::z
          formalParameters
            #F12 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:53)
              element: <testLibrary>::@setter::z::@formalParameter::value
  topLevelVariables
    hasInitializer x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F1
      type: Iterable<String>
      getter: <testLibrary>::@getter::x
      setter: <testLibrary>::@setter::x
    hasInitializer y
      reference: <testLibrary>::@topLevelVariable::y
      firstFragment: #F2
      type: List<int>
      getter: <testLibrary>::@getter::y
      setter: <testLibrary>::@setter::y
    hasInitializer z
      reference: <testLibrary>::@topLevelVariable::z
      firstFragment: #F3
      type: List<String>
      getter: <testLibrary>::@getter::z
      setter: <testLibrary>::@setter::z
  getters
    synthetic static x
      reference: <testLibrary>::@getter::x
      firstFragment: #F4
      returnType: Iterable<String>
      variable: <testLibrary>::@topLevelVariable::x
    synthetic static y
      reference: <testLibrary>::@getter::y
      firstFragment: #F5
      returnType: List<int>
      variable: <testLibrary>::@topLevelVariable::y
    synthetic static z
      reference: <testLibrary>::@getter::z
      firstFragment: #F6
      returnType: List<String>
      variable: <testLibrary>::@topLevelVariable::z
  setters
    synthetic static x
      reference: <testLibrary>::@setter::x
      firstFragment: #F7
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F8
          type: Iterable<String>
      returnType: void
      variable: <testLibrary>::@topLevelVariable::x
    synthetic static y
      reference: <testLibrary>::@setter::y
      firstFragment: #F9
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F10
          type: List<int>
      returnType: void
      variable: <testLibrary>::@topLevelVariable::y
    synthetic static z
      reference: <testLibrary>::@setter::z
      firstFragment: #F11
      formalParameters
        #E2 requiredPositional value
          firstFragment: #F12
          type: List<String>
      returnType: void
      variable: <testLibrary>::@topLevelVariable::z
''');
  }

  test_inference_map() async {
    var library = await buildLibrary('''
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
            #F2 p (nameOffset:16) (firstTokenOffset:16) (offset:16)
              element: <testLibrary>::@class::C::@field::p
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F4 synthetic p (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@class::C::@getter::p
          setters
            #F5 synthetic p (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@class::C::@setter::p
              formalParameters
                #F6 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
                  element: <testLibrary>::@class::C::@setter::p::@formalParameter::value
      topLevelVariables
        #F7 hasInitializer x (nameOffset:25) (firstTokenOffset:25) (offset:25)
          element: <testLibrary>::@topLevelVariable::x
        #F8 hasInitializer y (nameOffset:40) (firstTokenOffset:40) (offset:40)
          element: <testLibrary>::@topLevelVariable::y
      getters
        #F9 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
          element: <testLibrary>::@getter::x
        #F10 synthetic y (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
          element: <testLibrary>::@getter::y
      setters
        #F11 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
          element: <testLibrary>::@setter::x
          formalParameters
            #F12 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
              element: <testLibrary>::@setter::x::@formalParameter::value
        #F13 synthetic y (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
          element: <testLibrary>::@setter::y
          formalParameters
            #F14 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
              element: <testLibrary>::@setter::y::@formalParameter::value
  classes
    hasNonFinalField class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      fields
        p
          reference: <testLibrary>::@class::C::@field::p
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@class::C::@getter::p
          setter: <testLibrary>::@class::C::@setter::p
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
      getters
        synthetic p
          reference: <testLibrary>::@class::C::@getter::p
          firstFragment: #F4
          returnType: int
          variable: <testLibrary>::@class::C::@field::p
      setters
        synthetic p
          reference: <testLibrary>::@class::C::@setter::p
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F6
              type: int
          returnType: void
          variable: <testLibrary>::@class::C::@field::p
  topLevelVariables
    hasInitializer x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F7
      type: List<C>
      getter: <testLibrary>::@getter::x
      setter: <testLibrary>::@setter::x
    hasInitializer y
      reference: <testLibrary>::@topLevelVariable::y
      firstFragment: #F8
      type: Iterable<int>
      getter: <testLibrary>::@getter::y
      setter: <testLibrary>::@setter::y
  getters
    synthetic static x
      reference: <testLibrary>::@getter::x
      firstFragment: #F9
      returnType: List<C>
      variable: <testLibrary>::@topLevelVariable::x
    synthetic static y
      reference: <testLibrary>::@getter::y
      firstFragment: #F10
      returnType: Iterable<int>
      variable: <testLibrary>::@topLevelVariable::y
  setters
    synthetic static x
      reference: <testLibrary>::@setter::x
      firstFragment: #F11
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F12
          type: List<C>
      returnType: void
      variable: <testLibrary>::@topLevelVariable::x
    synthetic static y
      reference: <testLibrary>::@setter::y
      firstFragment: #F13
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
    var library = await buildLibrary('''
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
        #F1 f (nameOffset:0) (firstTokenOffset:0) (offset:0)
          element: <testLibrary>::@function::f
          typeParameters
            #F2 U (nameOffset:2) (firstTokenOffset:2) (offset:2)
              element: #E0 U
            #F3 V (nameOffset:5) (firstTokenOffset:5) (offset:5)
              element: #E1 V
  functions
    f
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
    var library = await buildLibrary('''
class C<U, V> {
  final x;
  C() : x = (() => () => 0);
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
            #F4 x (nameOffset:24) (firstTokenOffset:24) (offset:24)
              element: <testLibrary>::@class::C::@field::x
          constructors
            #F5 new (nameOffset:<null>) (firstTokenOffset:29) (offset:29)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
              typeNameOffset: 29
          getters
            #F6 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:24)
              element: <testLibrary>::@class::C::@getter::x
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      typeParameters
        #E0 U
          firstFragment: #F2
        #E1 V
          firstFragment: #F3
      fields
        final x
          reference: <testLibrary>::@class::C::@field::x
          firstFragment: #F4
          type: dynamic
          getter: <testLibrary>::@class::C::@getter::x
      constructors
        new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F5
      getters
        synthetic x
          reference: <testLibrary>::@class::C::@getter::x
          firstFragment: #F6
          returnType: dynamic
          variable: <testLibrary>::@class::C::@field::x
''');
  }

  test_inferred_function_type_in_generic_class_getter() async {
    // In the code below, `() => () => 0` has an inferred return type of
    // `() => int`, with 2 (unused) type parameters from the enclosing class.
    var library = await buildLibrary('''
class C<U, V> {
  get x => () => () => 0;
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
            #F4 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@field::x
          constructors
            #F5 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F6 x (nameOffset:22) (firstTokenOffset:18) (offset:22)
              element: <testLibrary>::@class::C::@getter::x
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      typeParameters
        #E0 U
          firstFragment: #F2
        #E1 V
          firstFragment: #F3
      fields
        synthetic x
          reference: <testLibrary>::@class::C::@field::x
          firstFragment: #F4
          type: dynamic
          getter: <testLibrary>::@class::C::@getter::x
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F5
      getters
        x
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
    var library = await buildLibrary('''
class C<T> {
  f<U, V>() {
    print(() => () => 0);
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
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          methods
            #F4 f (nameOffset:15) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@class::C::@method::f
              typeParameters
                #F5 U (nameOffset:17) (firstTokenOffset:17) (offset:17)
                  element: #E1 U
                #F6 V (nameOffset:20) (firstTokenOffset:20) (offset:20)
                  element: #E2 V
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
      methods
        f
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
    var library = await buildLibrary('''
class C<U, V> {
  void set x(value) {
    print(() => () => 0);
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
            #F4 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@field::x
          constructors
            #F5 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          setters
            #F6 x (nameOffset:27) (firstTokenOffset:18) (offset:27)
              element: <testLibrary>::@class::C::@setter::x
              formalParameters
                #F7 value (nameOffset:29) (firstTokenOffset:29) (offset:29)
                  element: <testLibrary>::@class::C::@setter::x::@formalParameter::value
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      typeParameters
        #E0 U
          firstFragment: #F2
        #E1 V
          firstFragment: #F3
      fields
        synthetic x
          reference: <testLibrary>::@class::C::@field::x
          firstFragment: #F4
          type: dynamic
          setter: <testLibrary>::@class::C::@setter::x
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F5
      setters
        x
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
    var library = await buildLibrary('''
f<T>() {
  print(/*<U, V>*/() => () => 0);
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      functions
        #F1 f (nameOffset:0) (firstTokenOffset:0) (offset:0)
          element: <testLibrary>::@function::f
          typeParameters
            #F2 T (nameOffset:2) (firstTokenOffset:2) (offset:2)
              element: #E0 T
  functions
    f
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
    var library = await buildLibrary('''
f<T>() {
  print(/*<U, V>*/() => /*<W, X, Y, Z>*/() => 0);
}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      functions
        #F1 f (nameOffset:0) (firstTokenOffset:0) (offset:0)
          element: <testLibrary>::@function::f
          typeParameters
            #F2 T (nameOffset:2) (firstTokenOffset:2) (offset:2)
              element: #E0 T
  functions
    f
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
            #F3 factory new (nameOffset:<null>) (firstTokenOffset:27) (offset:35)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
              typeNameOffset: 35
              formalParameters
                #F4 p (nameOffset:49) (firstTokenOffset:37) (offset:49)
                  element: <testLibrary>::@class::C::@constructor::new::@formalParameter::p
            #F5 _ (nameOffset:66) (firstTokenOffset:64) (offset:66)
              element: <testLibrary>::@class::C::@constructor::_
              typeName: C
              typeNameOffset: 64
              periodOffset: 65
      topLevelVariables
        #F6 hasInitializer c (nameOffset:78) (firstTokenOffset:78) (offset:78)
          element: <testLibrary>::@topLevelVariable::c
      getters
        #F7 synthetic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:78)
          element: <testLibrary>::@getter::c
      setters
        #F8 synthetic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:78)
          element: <testLibrary>::@setter::c
          formalParameters
            #F9 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:78)
              element: <testLibrary>::@setter::c::@formalParameter::value
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      typeParameters
        #E0 P
          firstFragment: #F2
          bound: num
      constructors
        factory new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
          formalParameters
            #E1 requiredPositional p
              firstFragment: #F4
              type: Iterable<P>
        _
          reference: <testLibrary>::@class::C::@constructor::_
          firstFragment: #F5
  topLevelVariables
    hasInitializer c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: #F6
      type: C<num>
      getter: <testLibrary>::@getter::c
      setter: <testLibrary>::@setter::c
  getters
    synthetic static c
      reference: <testLibrary>::@getter::c
      firstFragment: #F7
      returnType: C<num>
      variable: <testLibrary>::@topLevelVariable::c
  setters
    synthetic static c
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
    var library = await buildLibrary('''
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
            #F2 hasInitializer foo (nameOffset:25) (firstTokenOffset:25) (offset:25)
              element: <testLibrary>::@class::A::@field::foo
            #F3 hasInitializer bar (nameOffset:56) (firstTokenOffset:56) (offset:56)
              element: <testLibrary>::@class::A::@field::bar
          constructors
            #F4 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F5 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
              element: <testLibrary>::@class::A::@getter::foo
            #F6 synthetic bar (nameOffset:<null>) (firstTokenOffset:<null>) (offset:56)
              element: <testLibrary>::@class::A::@getter::bar
          methods
            #F7 baz (nameOffset:100) (firstTokenOffset:72) (offset:100)
              element: <testLibrary>::@class::A::@method::baz
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        static final hasInitializer foo
          reference: <testLibrary>::@class::A::@field::foo
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@class::A::@getter::foo
        static final hasInitializer bar
          reference: <testLibrary>::@class::A::@field::bar
          firstFragment: #F3
          type: int Function(double)
          getter: <testLibrary>::@class::A::@getter::bar
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F4
      getters
        synthetic static foo
          reference: <testLibrary>::@class::A::@getter::foo
          firstFragment: #F5
          returnType: int
          variable: <testLibrary>::@class::A::@field::foo
        synthetic static bar
          reference: <testLibrary>::@class::A::@getter::bar
          firstFragment: #F6
          returnType: int Function(double)
          variable: <testLibrary>::@class::A::@field::bar
      methods
        static baz
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
        #F1 hasInitializer x (nameOffset:21) (firstTokenOffset:21) (offset:21)
          element: <testLibrary>::@topLevelVariable::x
      getters
        #F2 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
          element: <testLibrary>::@getter::x
      setters
        #F3 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
          element: <testLibrary>::@setter::x
          formalParameters
            #F4 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@setter::x::@formalParameter::value
      functions
        #F5 m (nameOffset:4) (firstTokenOffset:0) (offset:4)
          element: <testLibrary>::@function::m
          typeParameters
            #F6 T (nameOffset:6) (firstTokenOffset:6) (offset:6)
              element: #E0 T
  topLevelVariables
    hasInitializer x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::x
      setter: <testLibrary>::@setter::x
  getters
    synthetic static x
      reference: <testLibrary>::@getter::x
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::x
  setters
    synthetic static x
      reference: <testLibrary>::@setter::x
      firstFragment: #F3
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F4
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::x
  functions
    m
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
        #F1 hasInitializer m (nameOffset:19) (firstTokenOffset:19) (offset:19)
          element: <testLibrary>::@topLevelVariable::m
        #F2 hasInitializer n (nameOffset:53) (firstTokenOffset:53) (offset:53)
          element: <testLibrary>::@topLevelVariable::n
        #F3 hasInitializer x (nameOffset:73) (firstTokenOffset:73) (offset:73)
          element: <testLibrary>::@topLevelVariable::x
      getters
        #F4 synthetic m (nameOffset:<null>) (firstTokenOffset:<null>) (offset:19)
          element: <testLibrary>::@getter::m
        #F5 synthetic n (nameOffset:<null>) (firstTokenOffset:<null>) (offset:53)
          element: <testLibrary>::@getter::n
        #F6 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:73)
          element: <testLibrary>::@getter::x
      setters
        #F7 synthetic m (nameOffset:<null>) (firstTokenOffset:<null>) (offset:19)
          element: <testLibrary>::@setter::m
          formalParameters
            #F8 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:19)
              element: <testLibrary>::@setter::m::@formalParameter::value
        #F9 synthetic n (nameOffset:<null>) (firstTokenOffset:<null>) (offset:53)
          element: <testLibrary>::@setter::n
          formalParameters
            #F10 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:53)
              element: <testLibrary>::@setter::n::@formalParameter::value
        #F11 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:73)
          element: <testLibrary>::@setter::x
          formalParameters
            #F12 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:73)
              element: <testLibrary>::@setter::x::@formalParameter::value
  topLevelVariables
    hasInitializer m
      reference: <testLibrary>::@topLevelVariable::m
      firstFragment: #F1
      type: int Function<T>()?
      getter: <testLibrary>::@getter::m
      setter: <testLibrary>::@setter::m
    hasInitializer n
      reference: <testLibrary>::@topLevelVariable::n
      firstFragment: #F2
      type: int Function<T>()
      getter: <testLibrary>::@getter::n
      setter: <testLibrary>::@setter::n
    hasInitializer x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F3
      type: int
      getter: <testLibrary>::@getter::x
      setter: <testLibrary>::@setter::x
  getters
    synthetic static m
      reference: <testLibrary>::@getter::m
      firstFragment: #F4
      returnType: int Function<T>()?
      variable: <testLibrary>::@topLevelVariable::m
    synthetic static n
      reference: <testLibrary>::@getter::n
      firstFragment: #F5
      returnType: int Function<T>()
      variable: <testLibrary>::@topLevelVariable::n
    synthetic static x
      reference: <testLibrary>::@getter::x
      firstFragment: #F6
      returnType: int
      variable: <testLibrary>::@topLevelVariable::x
  setters
    synthetic static m
      reference: <testLibrary>::@setter::m
      firstFragment: #F7
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F8
          type: int Function<T>()?
      returnType: void
      variable: <testLibrary>::@topLevelVariable::m
    synthetic static n
      reference: <testLibrary>::@setter::n
      firstFragment: #F9
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F10
          type: int Function<T>()
      returnType: void
      variable: <testLibrary>::@topLevelVariable::n
    synthetic static x
      reference: <testLibrary>::@setter::x
      firstFragment: #F11
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
        #F1 hasInitializer m (nameOffset:30) (firstTokenOffset:30) (offset:30)
          element: <testLibrary>::@topLevelVariable::m
      getters
        #F2 synthetic m (nameOffset:<null>) (firstTokenOffset:<null>) (offset:30)
          element: <testLibrary>::@getter::m
      setters
        #F3 synthetic m (nameOffset:<null>) (firstTokenOffset:<null>) (offset:30)
          element: <testLibrary>::@setter::m
          formalParameters
            #F4 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:30)
              element: <testLibrary>::@setter::m::@formalParameter::value
  topLevelVariables
    hasInitializer m
      reference: <testLibrary>::@topLevelVariable::m
      firstFragment: #F1
      type: HashMap<dynamic, dynamic>
      getter: <testLibrary>::@getter::m
      setter: <testLibrary>::@setter::m
  getters
    synthetic static m
      reference: <testLibrary>::@getter::m
      firstFragment: #F2
      returnType: HashMap<dynamic, dynamic>
      variable: <testLibrary>::@topLevelVariable::m
  setters
    synthetic static m
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
        #F1 hasInitializer a (nameOffset:4) (firstTokenOffset:4) (offset:4)
          element: <testLibrary>::@topLevelVariable::a
        #F2 hasInitializer b (nameOffset:19) (firstTokenOffset:19) (offset:19)
          element: <testLibrary>::@topLevelVariable::b
        #F3 hasInitializer c (nameOffset:34) (firstTokenOffset:34) (offset:34)
          element: <testLibrary>::@topLevelVariable::c
        #F4 hasInitializer d (nameOffset:49) (firstTokenOffset:49) (offset:49)
          element: <testLibrary>::@topLevelVariable::d
      getters
        #F5 synthetic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@getter::a
        #F6 synthetic b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:19)
          element: <testLibrary>::@getter::b
        #F7 synthetic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:34)
          element: <testLibrary>::@getter::c
        #F8 synthetic d (nameOffset:<null>) (firstTokenOffset:<null>) (offset:49)
          element: <testLibrary>::@getter::d
      setters
        #F9 synthetic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@setter::a
          formalParameters
            #F10 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
              element: <testLibrary>::@setter::a::@formalParameter::value
        #F11 synthetic b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:19)
          element: <testLibrary>::@setter::b
          formalParameters
            #F12 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:19)
              element: <testLibrary>::@setter::b::@formalParameter::value
        #F13 synthetic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:34)
          element: <testLibrary>::@setter::c
          formalParameters
            #F14 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:34)
              element: <testLibrary>::@setter::c::@formalParameter::value
        #F15 synthetic d (nameOffset:<null>) (firstTokenOffset:<null>) (offset:49)
          element: <testLibrary>::@setter::d
          formalParameters
            #F16 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:49)
              element: <testLibrary>::@setter::d::@formalParameter::value
  topLevelVariables
    hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F1
      type: dynamic
      getter: <testLibrary>::@getter::a
      setter: <testLibrary>::@setter::a
    hasInitializer b
      reference: <testLibrary>::@topLevelVariable::b
      firstFragment: #F2
      type: dynamic
      getter: <testLibrary>::@getter::b
      setter: <testLibrary>::@setter::b
    hasInitializer c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: #F3
      type: dynamic
      getter: <testLibrary>::@getter::c
      setter: <testLibrary>::@setter::c
    hasInitializer d
      reference: <testLibrary>::@topLevelVariable::d
      firstFragment: #F4
      type: int
      getter: <testLibrary>::@getter::d
      setter: <testLibrary>::@setter::d
  getters
    synthetic static a
      reference: <testLibrary>::@getter::a
      firstFragment: #F5
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::a
    synthetic static b
      reference: <testLibrary>::@getter::b
      firstFragment: #F6
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::b
    synthetic static c
      reference: <testLibrary>::@getter::c
      firstFragment: #F7
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::c
    synthetic static d
      reference: <testLibrary>::@getter::d
      firstFragment: #F8
      returnType: int
      variable: <testLibrary>::@topLevelVariable::d
  setters
    synthetic static a
      reference: <testLibrary>::@setter::a
      firstFragment: #F9
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F10
          type: dynamic
      returnType: void
      variable: <testLibrary>::@topLevelVariable::a
    synthetic static b
      reference: <testLibrary>::@setter::b
      firstFragment: #F11
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F12
          type: dynamic
      returnType: void
      variable: <testLibrary>::@topLevelVariable::b
    synthetic static c
      reference: <testLibrary>::@setter::c
      firstFragment: #F13
      formalParameters
        #E2 requiredPositional value
          firstFragment: #F14
          type: dynamic
      returnType: void
      variable: <testLibrary>::@topLevelVariable::c
    synthetic static d
      reference: <testLibrary>::@setter::d
      firstFragment: #F15
      formalParameters
        #E3 requiredPositional value
          firstFragment: #F16
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::d
''');
  }

  test_inferred_type_is_typedef() async {
    var library = await buildLibrary(
      'typedef int F(String s);'
      ' class C extends D { var v; }'
      ' abstract class D { F get v; }',
    );
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      classes
        #F1 class C (nameOffset:31) (firstTokenOffset:25) (offset:31)
          element: <testLibrary>::@class::C
          fields
            #F2 v (nameOffset:49) (firstTokenOffset:49) (offset:49)
              element: <testLibrary>::@class::C::@field::v
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F4 synthetic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:49)
              element: <testLibrary>::@class::C::@getter::v
          setters
            #F5 synthetic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:49)
              element: <testLibrary>::@class::C::@setter::v
              formalParameters
                #F6 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:49)
                  element: <testLibrary>::@class::C::@setter::v::@formalParameter::value
        #F7 class D (nameOffset:69) (firstTokenOffset:54) (offset:69)
          element: <testLibrary>::@class::D
          fields
            #F8 synthetic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:69)
              element: <testLibrary>::@class::D::@field::v
          constructors
            #F9 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:69)
              element: <testLibrary>::@class::D::@constructor::new
              typeName: D
          getters
            #F10 v (nameOffset:79) (firstTokenOffset:73) (offset:79)
              element: <testLibrary>::@class::D::@getter::v
      typeAliases
        #F11 F (nameOffset:12) (firstTokenOffset:0) (offset:12)
          element: <testLibrary>::@typeAlias::F
  classes
    hasNonFinalField class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      supertype: D
      fields
        v
          reference: <testLibrary>::@class::C::@field::v
          firstFragment: #F2
          type: int Function(String)
            alias: <testLibrary>::@typeAlias::F
          getter: <testLibrary>::@class::C::@getter::v
          setter: <testLibrary>::@class::C::@setter::v
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
          superConstructor: <testLibrary>::@class::D::@constructor::new
      getters
        synthetic v
          reference: <testLibrary>::@class::C::@getter::v
          firstFragment: #F4
          returnType: int Function(String)
            alias: <testLibrary>::@typeAlias::F
          variable: <testLibrary>::@class::C::@field::v
      setters
        synthetic v
          reference: <testLibrary>::@class::C::@setter::v
          firstFragment: #F5
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F6
              type: int Function(String)
                alias: <testLibrary>::@typeAlias::F
          returnType: void
          variable: <testLibrary>::@class::C::@field::v
    abstract class D
      reference: <testLibrary>::@class::D
      firstFragment: #F7
      fields
        synthetic v
          reference: <testLibrary>::@class::D::@field::v
          firstFragment: #F8
          type: int Function(String)
            alias: <testLibrary>::@typeAlias::F
          getter: <testLibrary>::@class::D::@getter::v
      constructors
        synthetic new
          reference: <testLibrary>::@class::D::@constructor::new
          firstFragment: #F9
      getters
        abstract v
          reference: <testLibrary>::@class::D::@getter::v
          firstFragment: #F10
          returnType: int Function(String)
            alias: <testLibrary>::@typeAlias::F
          variable: <testLibrary>::@class::D::@field::v
  typeAliases
    F
      reference: <testLibrary>::@typeAlias::F
      firstFragment: #F11
      aliasedType: int Function(String)
''');
  }

  test_inferred_type_nullability_class_ref_none() async {
    newFile('$testPackageLibPath/a.dart', 'int f() => 0;');
    var library = await buildLibrary('''
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
        #F1 hasInitializer x (nameOffset:21) (firstTokenOffset:21) (offset:21)
          element: <testLibrary>::@topLevelVariable::x
      getters
        #F2 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
          element: <testLibrary>::@getter::x
      setters
        #F3 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
          element: <testLibrary>::@setter::x
          formalParameters
            #F4 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@setter::x::@formalParameter::value
  topLevelVariables
    hasInitializer x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::x
      setter: <testLibrary>::@setter::x
  getters
    synthetic static x
      reference: <testLibrary>::@getter::x
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::x
  setters
    synthetic static x
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
    newFile('$testPackageLibPath/a.dart', 'int? f() => 0;');
    var library = await buildLibrary('''
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
        #F1 hasInitializer x (nameOffset:21) (firstTokenOffset:21) (offset:21)
          element: <testLibrary>::@topLevelVariable::x
      getters
        #F2 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
          element: <testLibrary>::@getter::x
      setters
        #F3 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
          element: <testLibrary>::@setter::x
          formalParameters
            #F4 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@setter::x::@formalParameter::value
  topLevelVariables
    hasInitializer x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F1
      type: int?
      getter: <testLibrary>::@getter::x
      setter: <testLibrary>::@setter::x
  getters
    synthetic static x
      reference: <testLibrary>::@getter::x
      firstFragment: #F2
      returnType: int?
      variable: <testLibrary>::@topLevelVariable::x
  setters
    synthetic static x
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
    newFile('$testPackageLibPath/a.dart', 'void Function() f() => () {};');
    var library = await buildLibrary('''
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
        #F1 hasInitializer x (nameOffset:21) (firstTokenOffset:21) (offset:21)
          element: <testLibrary>::@topLevelVariable::x
      getters
        #F2 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
          element: <testLibrary>::@getter::x
      setters
        #F3 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
          element: <testLibrary>::@setter::x
          formalParameters
            #F4 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@setter::x::@formalParameter::value
  topLevelVariables
    hasInitializer x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F1
      type: void Function()
      getter: <testLibrary>::@getter::x
      setter: <testLibrary>::@setter::x
  getters
    synthetic static x
      reference: <testLibrary>::@getter::x
      firstFragment: #F2
      returnType: void Function()
      variable: <testLibrary>::@topLevelVariable::x
  setters
    synthetic static x
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
    newFile('$testPackageLibPath/a.dart', 'void Function()? f() => () {};');
    var library = await buildLibrary('''
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
        #F1 hasInitializer x (nameOffset:21) (firstTokenOffset:21) (offset:21)
          element: <testLibrary>::@topLevelVariable::x
      getters
        #F2 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
          element: <testLibrary>::@getter::x
      setters
        #F3 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
          element: <testLibrary>::@setter::x
          formalParameters
            #F4 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@setter::x::@formalParameter::value
  topLevelVariables
    hasInitializer x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F1
      type: void Function()?
      getter: <testLibrary>::@getter::x
      setter: <testLibrary>::@setter::x
  getters
    synthetic static x
      reference: <testLibrary>::@getter::x
      firstFragment: #F2
      returnType: void Function()?
      variable: <testLibrary>::@topLevelVariable::x
  setters
    synthetic static x
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
    var library = await buildLibrary('''
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
        #F1 class C (nameOffset:6) (firstTokenOffset:0) (offset:6)
          element: <testLibrary>::@class::C
          typeParameters
            #F2 T (nameOffset:8) (firstTokenOffset:8) (offset:8)
              element: #E0 T
          fields
            #F3 v (nameOffset:37) (firstTokenOffset:37) (offset:37)
              element: <testLibrary>::@class::C::@field::v
          constructors
            #F4 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F5 synthetic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:37)
              element: <testLibrary>::@class::C::@getter::v
          setters
            #F6 synthetic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:37)
              element: <testLibrary>::@class::C::@setter::v
              formalParameters
                #F7 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:37)
                  element: <testLibrary>::@class::C::@setter::v::@formalParameter::value
        #F8 class D (nameOffset:57) (firstTokenOffset:42) (offset:57)
          element: <testLibrary>::@class::D
          typeParameters
            #F9 U (nameOffset:59) (firstTokenOffset:59) (offset:59)
              element: #E1 U
            #F10 V (nameOffset:62) (firstTokenOffset:62) (offset:62)
              element: #E2 V
          fields
            #F11 synthetic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:57)
              element: <testLibrary>::@class::D::@field::v
          constructors
            #F12 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:57)
              element: <testLibrary>::@class::D::@constructor::new
              typeName: D
          getters
            #F13 v (nameOffset:83) (firstTokenOffset:69) (offset:83)
              element: <testLibrary>::@class::D::@getter::v
  classes
    hasNonFinalField class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      supertype: D<int, T>
      fields
        v
          reference: <testLibrary>::@class::C::@field::v
          firstFragment: #F3
          hasEnclosingTypeParameterReference: true
          type: Map<T, int>
          getter: <testLibrary>::@class::C::@getter::v
          setter: <testLibrary>::@class::C::@setter::v
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F4
          superConstructor: ConstructorMember
            baseElement: <testLibrary>::@class::D::@constructor::new
            substitution: {U: int, V: T}
      getters
        synthetic v
          reference: <testLibrary>::@class::C::@getter::v
          firstFragment: #F5
          hasEnclosingTypeParameterReference: true
          returnType: Map<T, int>
          variable: <testLibrary>::@class::C::@field::v
      setters
        synthetic v
          reference: <testLibrary>::@class::C::@setter::v
          firstFragment: #F6
          hasEnclosingTypeParameterReference: true
          formalParameters
            #E3 requiredPositional value
              firstFragment: #F7
              type: Map<T, int>
          returnType: void
          variable: <testLibrary>::@class::C::@field::v
    abstract class D
      reference: <testLibrary>::@class::D
      firstFragment: #F8
      typeParameters
        #E1 U
          firstFragment: #F9
        #E2 V
          firstFragment: #F10
      fields
        synthetic v
          reference: <testLibrary>::@class::D::@field::v
          firstFragment: #F11
          hasEnclosingTypeParameterReference: true
          type: Map<V, U>
          getter: <testLibrary>::@class::D::@getter::v
      constructors
        synthetic new
          reference: <testLibrary>::@class::D::@constructor::new
          firstFragment: #F12
      getters
        abstract v
          reference: <testLibrary>::@class::D::@getter::v
          firstFragment: #F13
          hasEnclosingTypeParameterReference: true
          returnType: Map<V, U>
          variable: <testLibrary>::@class::D::@field::v
''');
  }

  test_inferred_type_refers_to_function_typed_param_of_typedef() async {
    var library = await buildLibrary('''
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
        #F2 hasInitializer v (nameOffset:53) (firstTokenOffset:53) (offset:53)
          element: <testLibrary>::@topLevelVariable::v
      getters
        #F3 synthetic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:53)
          element: <testLibrary>::@getter::v
      setters
        #F4 synthetic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:53)
          element: <testLibrary>::@setter::v
          formalParameters
            #F5 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:53)
              element: <testLibrary>::@setter::v::@formalParameter::value
      functions
        #F6 h (nameOffset:33) (firstTokenOffset:33) (offset:33)
          element: <testLibrary>::@function::h
          formalParameters
            #F7 f (nameOffset:37) (firstTokenOffset:35) (offset:37)
              element: <testLibrary>::@function::h::@formalParameter::f
  typeAliases
    F
      reference: <testLibrary>::@typeAlias::F
      firstFragment: #F1
      aliasedType: void Function(int Function(String))
  topLevelVariables
    hasInitializer v
      reference: <testLibrary>::@topLevelVariable::v
      firstFragment: #F2
      type: dynamic
      getter: <testLibrary>::@getter::v
      setter: <testLibrary>::@setter::v
  getters
    synthetic static v
      reference: <testLibrary>::@getter::v
      firstFragment: #F3
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::v
  setters
    synthetic static v
      reference: <testLibrary>::@setter::v
      firstFragment: #F4
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F5
          type: dynamic
      returnType: void
      variable: <testLibrary>::@topLevelVariable::v
  functions
    h
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
    var library = await buildLibrary('''
class C<T, U> extends D<U, int> {
  void f(int x, g) {}
}
abstract class D<V, W> {
  void f(int x, W g(V s));
}''');
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
            #F4 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          methods
            #F5 f (nameOffset:41) (firstTokenOffset:36) (offset:41)
              element: <testLibrary>::@class::C::@method::f
              formalParameters
                #F6 x (nameOffset:47) (firstTokenOffset:43) (offset:47)
                  element: <testLibrary>::@class::C::@method::f::@formalParameter::x
                #F7 g (nameOffset:50) (firstTokenOffset:50) (offset:50)
                  element: <testLibrary>::@class::C::@method::f::@formalParameter::g
        #F8 class D (nameOffset:73) (firstTokenOffset:58) (offset:73)
          element: <testLibrary>::@class::D
          typeParameters
            #F9 V (nameOffset:75) (firstTokenOffset:75) (offset:75)
              element: #E2 V
            #F10 W (nameOffset:78) (firstTokenOffset:78) (offset:78)
              element: #E3 W
          constructors
            #F11 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:73)
              element: <testLibrary>::@class::D::@constructor::new
              typeName: D
          methods
            #F12 f (nameOffset:90) (firstTokenOffset:85) (offset:90)
              element: <testLibrary>::@class::D::@method::f
              formalParameters
                #F13 x (nameOffset:96) (firstTokenOffset:92) (offset:96)
                  element: <testLibrary>::@class::D::@method::f::@formalParameter::x
                #F14 g (nameOffset:101) (firstTokenOffset:99) (offset:101)
                  element: <testLibrary>::@class::D::@method::f::@formalParameter::g
                  parameters
                    #F15 s (nameOffset:105) (firstTokenOffset:103) (offset:105)
                      element: s@105
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
        #E1 U
          firstFragment: #F3
      supertype: D<U, int>
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F4
          superConstructor: ConstructorMember
            baseElement: <testLibrary>::@class::D::@constructor::new
            substitution: {V: U, W: int}
      methods
        f
          reference: <testLibrary>::@class::C::@method::f
          firstFragment: #F5
          hasEnclosingTypeParameterReference: true
          formalParameters
            #E4 requiredPositional x
              firstFragment: #F6
              type: int
            #E5 requiredPositional hasImplicitType g
              firstFragment: #F7
              type: int Function(U)
          returnType: void
    abstract class D
      reference: <testLibrary>::@class::D
      firstFragment: #F8
      typeParameters
        #E2 V
          firstFragment: #F9
        #E3 W
          firstFragment: #F10
      constructors
        synthetic new
          reference: <testLibrary>::@class::D::@constructor::new
          firstFragment: #F11
      methods
        abstract f
          reference: <testLibrary>::@class::D::@method::f
          firstFragment: #F12
          hasEnclosingTypeParameterReference: true
          formalParameters
            #E6 requiredPositional x
              firstFragment: #F13
              type: int
            #E7 requiredPositional g
              firstFragment: #F14
              type: W Function(V)
              formalParameters
                #E8 requiredPositional s
                  firstFragment: #F15
                  type: V
          returnType: void
''');
  }

  test_inferred_type_refers_to_function_typed_parameter_type_other_lib() async {
    newFile('$testPackageLibPath/a.dart', '''
import 'b.dart';
abstract class D extends E {}
''');
    newFile('$testPackageLibPath/b.dart', '''
abstract class E {
  void f(int x, int g(String s));
}
''');
    var library = await buildLibrary('''
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
        #F1 class C (nameOffset:23) (firstTokenOffset:17) (offset:23)
          element: <testLibrary>::@class::C
          constructors
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          methods
            #F3 f (nameOffset:44) (firstTokenOffset:39) (offset:44)
              element: <testLibrary>::@class::C::@method::f
              formalParameters
                #F4 x (nameOffset:50) (firstTokenOffset:46) (offset:50)
                  element: <testLibrary>::@class::C::@method::f::@formalParameter::x
                #F5 g (nameOffset:53) (firstTokenOffset:53) (offset:53)
                  element: <testLibrary>::@class::C::@method::f::@formalParameter::g
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      supertype: D
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
          superConstructor: package:test/a.dart::@class::D::@constructor::new
      methods
        f
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
    var library = await buildLibrary(
      'class C extends D { void f(int x, g) {} }'
      ' abstract class D { void f(int x, int g(String s)); }',
    );
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
            #F3 f (nameOffset:25) (firstTokenOffset:20) (offset:25)
              element: <testLibrary>::@class::C::@method::f
              formalParameters
                #F4 x (nameOffset:31) (firstTokenOffset:27) (offset:31)
                  element: <testLibrary>::@class::C::@method::f::@formalParameter::x
                #F5 g (nameOffset:34) (firstTokenOffset:34) (offset:34)
                  element: <testLibrary>::@class::C::@method::f::@formalParameter::g
        #F6 class D (nameOffset:57) (firstTokenOffset:42) (offset:57)
          element: <testLibrary>::@class::D
          constructors
            #F7 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:57)
              element: <testLibrary>::@class::D::@constructor::new
              typeName: D
          methods
            #F8 f (nameOffset:66) (firstTokenOffset:61) (offset:66)
              element: <testLibrary>::@class::D::@method::f
              formalParameters
                #F9 x (nameOffset:72) (firstTokenOffset:68) (offset:72)
                  element: <testLibrary>::@class::D::@method::f::@formalParameter::x
                #F10 g (nameOffset:79) (firstTokenOffset:75) (offset:79)
                  element: <testLibrary>::@class::D::@method::f::@formalParameter::g
                  parameters
                    #F11 s (nameOffset:88) (firstTokenOffset:81) (offset:88)
                      element: s@88
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      supertype: D
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
          superConstructor: <testLibrary>::@class::D::@constructor::new
      methods
        f
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
    abstract class D
      reference: <testLibrary>::@class::D
      firstFragment: #F6
      constructors
        synthetic new
          reference: <testLibrary>::@class::D::@constructor::new
          firstFragment: #F7
      methods
        abstract f
          reference: <testLibrary>::@class::D::@method::f
          firstFragment: #F8
          formalParameters
            #E2 requiredPositional x
              firstFragment: #F9
              type: int
            #E3 requiredPositional g
              firstFragment: #F10
              type: int Function(String)
              formalParameters
                #E4 requiredPositional s
                  firstFragment: #F11
                  type: String
          returnType: void
''');
  }

  test_inferred_type_refers_to_nested_function_typed_param() async {
    var library = await buildLibrary('''
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
        #F1 hasInitializer v (nameOffset:40) (firstTokenOffset:40) (offset:40)
          element: <testLibrary>::@topLevelVariable::v
      getters
        #F2 synthetic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
          element: <testLibrary>::@getter::v
      setters
        #F3 synthetic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
          element: <testLibrary>::@setter::v
          formalParameters
            #F4 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:40)
              element: <testLibrary>::@setter::v::@formalParameter::value
      functions
        #F5 f (nameOffset:0) (firstTokenOffset:0) (offset:0)
          element: <testLibrary>::@function::f
          formalParameters
            #F6 g (nameOffset:7) (firstTokenOffset:2) (offset:7)
              element: <testLibrary>::@function::f::@formalParameter::g
              parameters
                #F7 x (nameOffset:13) (firstTokenOffset:9) (offset:13)
                  element: x@13
                #F8 h (nameOffset:21) (firstTokenOffset:16) (offset:21)
                  element: h@21
  topLevelVariables
    hasInitializer v
      reference: <testLibrary>::@topLevelVariable::v
      firstFragment: #F1
      type: dynamic
      getter: <testLibrary>::@getter::v
      setter: <testLibrary>::@setter::v
  getters
    synthetic static v
      reference: <testLibrary>::@getter::v
      firstFragment: #F2
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::v
  setters
    synthetic static v
      reference: <testLibrary>::@setter::v
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F4
          type: dynamic
      returnType: void
      variable: <testLibrary>::@topLevelVariable::v
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: #F5
      formalParameters
        #E1 requiredPositional g
          firstFragment: #F6
          type: void Function(int, void Function())
          formalParameters
            #E2 requiredPositional x
              firstFragment: #F7
              type: int
            #E3 requiredPositional h
              firstFragment: #F8
              type: void Function()
      returnType: dynamic
''');
  }

  test_inferred_type_refers_to_nested_function_typed_param_named() async {
    var library = await buildLibrary('''
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
        #F1 hasInitializer v (nameOffset:42) (firstTokenOffset:42) (offset:42)
          element: <testLibrary>::@topLevelVariable::v
      getters
        #F2 synthetic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:42)
          element: <testLibrary>::@getter::v
      setters
        #F3 synthetic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:42)
          element: <testLibrary>::@setter::v
          formalParameters
            #F4 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:42)
              element: <testLibrary>::@setter::v::@formalParameter::value
      functions
        #F5 f (nameOffset:0) (firstTokenOffset:0) (offset:0)
          element: <testLibrary>::@function::f
          formalParameters
            #F6 g (nameOffset:8) (firstTokenOffset:3) (offset:8)
              element: <testLibrary>::@function::f::@formalParameter::g
              parameters
                #F7 x (nameOffset:14) (firstTokenOffset:10) (offset:14)
                  element: x@14
                #F8 h (nameOffset:22) (firstTokenOffset:17) (offset:22)
                  element: h@22
  topLevelVariables
    hasInitializer v
      reference: <testLibrary>::@topLevelVariable::v
      firstFragment: #F1
      type: dynamic
      getter: <testLibrary>::@getter::v
      setter: <testLibrary>::@setter::v
  getters
    synthetic static v
      reference: <testLibrary>::@getter::v
      firstFragment: #F2
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::v
  setters
    synthetic static v
      reference: <testLibrary>::@setter::v
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F4
          type: dynamic
      returnType: void
      variable: <testLibrary>::@topLevelVariable::v
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: #F5
      formalParameters
        #E1 optionalNamed g
          firstFragment: #F6
          type: void Function(int, void Function())
          formalParameters
            #E2 requiredPositional x
              firstFragment: #F7
              type: int
            #E3 requiredPositional h
              firstFragment: #F8
              type: void Function()
      returnType: dynamic
''');
  }

  test_inferred_type_refers_to_setter_function_typed_parameter_type() async {
    var library = await buildLibrary(
      'class C extends D { void set f(g) {} }'
      ' abstract class D { void set f(int g(String s)); }',
    );
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
            #F2 synthetic f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@field::f
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          setters
            #F4 f (nameOffset:29) (firstTokenOffset:20) (offset:29)
              element: <testLibrary>::@class::C::@setter::f
              formalParameters
                #F5 g (nameOffset:31) (firstTokenOffset:31) (offset:31)
                  element: <testLibrary>::@class::C::@setter::f::@formalParameter::g
        #F6 class D (nameOffset:54) (firstTokenOffset:39) (offset:54)
          element: <testLibrary>::@class::D
          fields
            #F7 synthetic f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:54)
              element: <testLibrary>::@class::D::@field::f
          constructors
            #F8 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:54)
              element: <testLibrary>::@class::D::@constructor::new
              typeName: D
          setters
            #F9 f (nameOffset:67) (firstTokenOffset:58) (offset:67)
              element: <testLibrary>::@class::D::@setter::f
              formalParameters
                #F10 g (nameOffset:73) (firstTokenOffset:69) (offset:73)
                  element: <testLibrary>::@class::D::@setter::f::@formalParameter::g
                  parameters
                    #F11 s (nameOffset:82) (firstTokenOffset:75) (offset:82)
                      element: s@82
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      supertype: D
      fields
        synthetic f
          reference: <testLibrary>::@class::C::@field::f
          firstFragment: #F2
          type: int Function(String)
          setter: <testLibrary>::@class::C::@setter::f
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
          superConstructor: <testLibrary>::@class::D::@constructor::new
      setters
        f
          reference: <testLibrary>::@class::C::@setter::f
          firstFragment: #F4
          formalParameters
            #E0 requiredPositional hasImplicitType g
              firstFragment: #F5
              type: int Function(String)
          returnType: void
          variable: <testLibrary>::@class::C::@field::f
    abstract class D
      reference: <testLibrary>::@class::D
      firstFragment: #F6
      fields
        synthetic f
          reference: <testLibrary>::@class::D::@field::f
          firstFragment: #F7
          type: int Function(String)
          setter: <testLibrary>::@class::D::@setter::f
      constructors
        synthetic new
          reference: <testLibrary>::@class::D::@constructor::new
          firstFragment: #F8
      setters
        abstract f
          reference: <testLibrary>::@class::D::@setter::f
          firstFragment: #F9
          formalParameters
            #E1 requiredPositional g
              firstFragment: #F10
              type: int Function(String)
              formalParameters
                #E2 requiredPositional s
                  firstFragment: #F11
                  type: String
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
        #F1 class B (nameOffset:23) (firstTokenOffset:17) (offset:23)
          element: <testLibrary>::@class::B
          constructors
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          methods
            #F3 m (nameOffset:39) (firstTokenOffset:39) (offset:39)
              element: <testLibrary>::@class::B::@method::m
              formalParameters
                #F4 p (nameOffset:41) (firstTokenOffset:41) (offset:41)
                  element: <testLibrary>::@class::B::@method::m::@formalParameter::p
  classes
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F1
      supertype: A
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F2
          superConstructor: package:test/a.dart::@class::A::@constructor::new
      methods
        m
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
            #F2 new (nameOffset:<null>) (firstTokenOffset:12) (offset:12)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
              typeNameOffset: 12
            #F3 named (nameOffset:21) (firstTokenOffset:19) (offset:21)
              element: <testLibrary>::@class::A::@constructor::named
              typeName: A
              typeNameOffset: 19
              periodOffset: 20
      topLevelVariables
        #F4 hasInitializer a1 (nameOffset:36) (firstTokenOffset:36) (offset:36)
          element: <testLibrary>::@topLevelVariable::a1
        #F5 hasInitializer a2 (nameOffset:50) (firstTokenOffset:50) (offset:50)
          element: <testLibrary>::@topLevelVariable::a2
      getters
        #F6 synthetic a1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:36)
          element: <testLibrary>::@getter::a1
        #F7 synthetic a2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:50)
          element: <testLibrary>::@getter::a2
      setters
        #F8 synthetic a1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:36)
          element: <testLibrary>::@setter::a1
          formalParameters
            #F9 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:36)
              element: <testLibrary>::@setter::a1::@formalParameter::value
        #F10 synthetic a2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:50)
          element: <testLibrary>::@setter::a2
          formalParameters
            #F11 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:50)
              element: <testLibrary>::@setter::a2::@formalParameter::value
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
        named
          reference: <testLibrary>::@class::A::@constructor::named
          firstFragment: #F3
  topLevelVariables
    hasInitializer a1
      reference: <testLibrary>::@topLevelVariable::a1
      firstFragment: #F4
      type: A
      getter: <testLibrary>::@getter::a1
      setter: <testLibrary>::@setter::a1
    hasInitializer a2
      reference: <testLibrary>::@topLevelVariable::a2
      firstFragment: #F5
      type: A
      getter: <testLibrary>::@getter::a2
      setter: <testLibrary>::@setter::a2
  getters
    synthetic static a1
      reference: <testLibrary>::@getter::a1
      firstFragment: #F6
      returnType: A
      variable: <testLibrary>::@topLevelVariable::a1
    synthetic static a2
      reference: <testLibrary>::@getter::a2
      firstFragment: #F7
      returnType: A
      variable: <testLibrary>::@topLevelVariable::a2
  setters
    synthetic static a1
      reference: <testLibrary>::@setter::a1
      firstFragment: #F8
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F9
          type: A
      returnType: void
      variable: <testLibrary>::@topLevelVariable::a1
    synthetic static a2
      reference: <testLibrary>::@setter::a2
      firstFragment: #F10
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F11
          type: A
      returnType: void
      variable: <testLibrary>::@topLevelVariable::a2
''');
  }

  test_inferredType_implicitCreation_prefixed() async {
    newFile('$testPackageLibPath/foo.dart', '''
class A {
  A();
  A.named();
}
''');
    var library = await buildLibrary('''
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
        <testLibraryFragment>::@prefix2::foo
          fragments: @21
      topLevelVariables
        #F1 hasInitializer a1 (nameOffset:30) (firstTokenOffset:30) (offset:30)
          element: <testLibrary>::@topLevelVariable::a1
        #F2 hasInitializer a2 (nameOffset:48) (firstTokenOffset:48) (offset:48)
          element: <testLibrary>::@topLevelVariable::a2
      getters
        #F3 synthetic a1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:30)
          element: <testLibrary>::@getter::a1
        #F4 synthetic a2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:48)
          element: <testLibrary>::@getter::a2
      setters
        #F5 synthetic a1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:30)
          element: <testLibrary>::@setter::a1
          formalParameters
            #F6 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:30)
              element: <testLibrary>::@setter::a1::@formalParameter::value
        #F7 synthetic a2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:48)
          element: <testLibrary>::@setter::a2
          formalParameters
            #F8 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:48)
              element: <testLibrary>::@setter::a2::@formalParameter::value
  topLevelVariables
    hasInitializer a1
      reference: <testLibrary>::@topLevelVariable::a1
      firstFragment: #F1
      type: A
      getter: <testLibrary>::@getter::a1
      setter: <testLibrary>::@setter::a1
    hasInitializer a2
      reference: <testLibrary>::@topLevelVariable::a2
      firstFragment: #F2
      type: A
      getter: <testLibrary>::@getter::a2
      setter: <testLibrary>::@setter::a2
  getters
    synthetic static a1
      reference: <testLibrary>::@getter::a1
      firstFragment: #F3
      returnType: A
      variable: <testLibrary>::@topLevelVariable::a1
    synthetic static a2
      reference: <testLibrary>::@getter::a2
      firstFragment: #F4
      returnType: A
      variable: <testLibrary>::@topLevelVariable::a2
  setters
    synthetic static a1
      reference: <testLibrary>::@setter::a1
      firstFragment: #F5
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F6
          type: A
      returnType: void
      variable: <testLibrary>::@topLevelVariable::a1
    synthetic static a2
      reference: <testLibrary>::@setter::a2
      firstFragment: #F7
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
    var library = await buildLibrary('''
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
        #F1 hasInitializer v (nameOffset:71) (firstTokenOffset:71) (offset:71)
          element: <testLibrary>::@topLevelVariable::v
      getters
        #F2 synthetic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:71)
          element: <testLibrary>::@getter::v
      setters
        #F3 synthetic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:71)
          element: <testLibrary>::@setter::v
          formalParameters
            #F4 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:71)
              element: <testLibrary>::@setter::v::@formalParameter::value
      functions
        #F5 f (nameOffset:4) (firstTokenOffset:0) (offset:4)
          element: <testLibrary>::@function::f
          formalParameters
            #F6 x (nameOffset:10) (firstTokenOffset:6) (offset:10)
              element: <testLibrary>::@function::f::@formalParameter::x
              parameters
                #F7 y (nameOffset:19) (firstTokenOffset:12) (offset:19)
                  element: y@19
        #F8 g (nameOffset:39) (firstTokenOffset:32) (offset:39)
          element: <testLibrary>::@function::g
          formalParameters
            #F9 x (nameOffset:45) (firstTokenOffset:41) (offset:45)
              element: <testLibrary>::@function::g::@formalParameter::x
              parameters
                #F10 y (nameOffset:54) (firstTokenOffset:47) (offset:54)
                  element: y@54
  topLevelVariables
    hasInitializer v
      reference: <testLibrary>::@topLevelVariable::v
      firstFragment: #F1
      type: List<Object Function(int Function(String))>
      getter: <testLibrary>::@getter::v
      setter: <testLibrary>::@setter::v
  getters
    synthetic static v
      reference: <testLibrary>::@getter::v
      firstFragment: #F2
      returnType: List<Object Function(int Function(String))>
      variable: <testLibrary>::@topLevelVariable::v
  setters
    synthetic static v
      reference: <testLibrary>::@setter::v
      firstFragment: #F3
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F4
          type: List<Object Function(int Function(String))>
      returnType: void
      variable: <testLibrary>::@topLevelVariable::v
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: #F5
      formalParameters
        #E1 requiredPositional x
          firstFragment: #F6
          type: int Function(String)
          formalParameters
            #E2 requiredPositional y
              firstFragment: #F7
              type: String
      returnType: int
    g
      reference: <testLibrary>::@function::g
      firstFragment: #F8
      formalParameters
        #E3 requiredPositional x
          firstFragment: #F9
          type: int Function(String)
          formalParameters
            #E4 requiredPositional y
              firstFragment: #F10
              type: String
      returnType: String
''');
  }

  test_inheritance_errors() async {
    var library = await buildLibrary('''
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
        #F1 class A (nameOffset:15) (firstTokenOffset:0) (offset:15)
          element: <testLibrary>::@class::A
          constructors
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          methods
            #F3 m (nameOffset:25) (firstTokenOffset:21) (offset:25)
              element: <testLibrary>::@class::A::@method::m
        #F4 class B (nameOffset:48) (firstTokenOffset:33) (offset:48)
          element: <testLibrary>::@class::B
          constructors
            #F5 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:48)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          methods
            #F6 m (nameOffset:61) (firstTokenOffset:54) (offset:61)
              element: <testLibrary>::@class::B::@method::m
        #F7 class C (nameOffset:84) (firstTokenOffset:69) (offset:84)
          element: <testLibrary>::@class::C
          constructors
            #F8 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:84)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
        #F9 class D (nameOffset:121) (firstTokenOffset:106) (offset:121)
          element: <testLibrary>::@class::D
          fields
            #F10 f (nameOffset:141) (firstTokenOffset:141) (offset:141)
              element: <testLibrary>::@class::D::@field::f
          constructors
            #F11 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:121)
              element: <testLibrary>::@class::D::@constructor::new
              typeName: D
          getters
            #F12 synthetic f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:141)
              element: <testLibrary>::@class::D::@getter::f
          setters
            #F13 synthetic f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:141)
              element: <testLibrary>::@class::D::@setter::f
              formalParameters
                #F14 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:141)
                  element: <testLibrary>::@class::D::@setter::f::@formalParameter::value
  classes
    abstract class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
      methods
        abstract m
          reference: <testLibrary>::@class::A::@method::m
          firstFragment: #F3
          returnType: int
    abstract class B
      reference: <testLibrary>::@class::B
      firstFragment: #F4
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F5
      methods
        abstract m
          reference: <testLibrary>::@class::B::@method::m
          firstFragment: #F6
          returnType: String
    abstract class C
      reference: <testLibrary>::@class::C
      firstFragment: #F7
      interfaces
        A
        B
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F8
    abstract hasNonFinalField class D
      reference: <testLibrary>::@class::D
      firstFragment: #F9
      supertype: C
      fields
        f
          reference: <testLibrary>::@class::D::@field::f
          firstFragment: #F10
          type: dynamic
          getter: <testLibrary>::@class::D::@getter::f
          setter: <testLibrary>::@class::D::@setter::f
      constructors
        synthetic new
          reference: <testLibrary>::@class::D::@constructor::new
          firstFragment: #F11
          superConstructor: <testLibrary>::@class::C::@constructor::new
      getters
        synthetic f
          reference: <testLibrary>::@class::D::@getter::f
          firstFragment: #F12
          returnType: dynamic
          variable: <testLibrary>::@class::D::@field::f
      setters
        synthetic f
          reference: <testLibrary>::@class::D::@setter::f
          firstFragment: #F13
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
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          methods
            #F3 call (nameOffset:19) (firstTokenOffset:12) (offset:19)
              element: <testLibrary>::@class::A::@method::call
        #F4 class B (nameOffset:42) (firstTokenOffset:36) (offset:42)
          element: <testLibrary>::@class::B
          fields
            #F5 a (nameOffset:50) (firstTokenOffset:50) (offset:50)
              element: <testLibrary>::@class::B::@field::a
          constructors
            #F6 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:42)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          getters
            #F7 synthetic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:50)
              element: <testLibrary>::@class::B::@getter::a
          setters
            #F8 synthetic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:50)
              element: <testLibrary>::@class::B::@setter::a
              formalParameters
                #F9 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:50)
                  element: <testLibrary>::@class::B::@setter::a::@formalParameter::value
      topLevelVariables
        #F10 hasInitializer c (nameOffset:59) (firstTokenOffset:59) (offset:59)
          element: <testLibrary>::@topLevelVariable::c
      getters
        #F11 synthetic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:59)
          element: <testLibrary>::@getter::c
      setters
        #F12 synthetic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:59)
          element: <testLibrary>::@setter::c
          formalParameters
            #F13 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:59)
              element: <testLibrary>::@setter::c::@formalParameter::value
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
      methods
        call
          reference: <testLibrary>::@class::A::@method::call
          firstFragment: #F3
          returnType: double
    hasNonFinalField class B
      reference: <testLibrary>::@class::B
      firstFragment: #F4
      fields
        a
          reference: <testLibrary>::@class::B::@field::a
          firstFragment: #F5
          type: A
          getter: <testLibrary>::@class::B::@getter::a
          setter: <testLibrary>::@class::B::@setter::a
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F6
      getters
        synthetic a
          reference: <testLibrary>::@class::B::@getter::a
          firstFragment: #F7
          returnType: A
          variable: <testLibrary>::@class::B::@field::a
      setters
        synthetic a
          reference: <testLibrary>::@class::B::@setter::a
          firstFragment: #F8
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F9
              type: A
          returnType: void
          variable: <testLibrary>::@class::B::@field::a
  topLevelVariables
    hasInitializer c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: #F10
      type: double
      getter: <testLibrary>::@getter::c
      setter: <testLibrary>::@setter::c
  getters
    synthetic static c
      reference: <testLibrary>::@getter::c
      firstFragment: #F11
      returnType: double
      variable: <testLibrary>::@topLevelVariable::c
  setters
    synthetic static c
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
    var library = await buildLibrary('''
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
        #F1 hasInitializer a (nameOffset:4) (firstTokenOffset:4) (offset:4)
          element: <testLibrary>::@topLevelVariable::a
        #F2 hasInitializer b (nameOffset:42) (firstTokenOffset:42) (offset:42)
          element: <testLibrary>::@topLevelVariable::b
      getters
        #F3 synthetic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@getter::a
        #F4 synthetic b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:42)
          element: <testLibrary>::@getter::b
      setters
        #F5 synthetic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@setter::a
          formalParameters
            #F6 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
              element: <testLibrary>::@setter::a::@formalParameter::value
        #F7 synthetic b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:42)
          element: <testLibrary>::@setter::b
          formalParameters
            #F8 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:42)
              element: <testLibrary>::@setter::b::@formalParameter::value
  topLevelVariables
    hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F1
      type: int Function()
      getter: <testLibrary>::@getter::a
      setter: <testLibrary>::@setter::a
    hasInitializer b
      reference: <testLibrary>::@topLevelVariable::b
      firstFragment: #F2
      type: int
      getter: <testLibrary>::@getter::b
      setter: <testLibrary>::@setter::b
  getters
    synthetic static a
      reference: <testLibrary>::@getter::a
      firstFragment: #F3
      returnType: int Function()
      variable: <testLibrary>::@topLevelVariable::a
    synthetic static b
      reference: <testLibrary>::@getter::b
      firstFragment: #F4
      returnType: int
      variable: <testLibrary>::@topLevelVariable::b
  setters
    synthetic static a
      reference: <testLibrary>::@setter::a
      firstFragment: #F5
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F6
          type: int Function()
      returnType: void
      variable: <testLibrary>::@topLevelVariable::a
    synthetic static b
      reference: <testLibrary>::@setter::b
      firstFragment: #F7
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F8
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::b
''');
  }

  test_type_inference_based_on_loadLibrary() async {
    newFile('$testPackageLibPath/a.dart', '');
    var library = await buildLibrary('''
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
        <testLibraryFragment>::@prefix2::a
          fragments: @28
      topLevelVariables
        #F1 hasInitializer x (nameOffset:35) (firstTokenOffset:35) (offset:35)
          element: <testLibrary>::@topLevelVariable::x
      getters
        #F2 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:35)
          element: <testLibrary>::@getter::x
      setters
        #F3 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:35)
          element: <testLibrary>::@setter::x
          formalParameters
            #F4 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:35)
              element: <testLibrary>::@setter::x::@formalParameter::value
  topLevelVariables
    hasInitializer x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F1
      type: Future<dynamic> Function()
      getter: <testLibrary>::@getter::x
      setter: <testLibrary>::@setter::x
  getters
    synthetic static x
      reference: <testLibrary>::@getter::x
      firstFragment: #F2
      returnType: Future<dynamic> Function()
      variable: <testLibrary>::@topLevelVariable::x
  setters
    synthetic static x
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
    var library = await buildLibrary('''
var x = (int f(String x)) => 0;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer x (nameOffset:4) (firstTokenOffset:4) (offset:4)
          element: <testLibrary>::@topLevelVariable::x
      getters
        #F2 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@getter::x
      setters
        #F3 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@setter::x
          formalParameters
            #F4 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
              element: <testLibrary>::@setter::x::@formalParameter::value
  topLevelVariables
    hasInitializer x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F1
      type: int Function(int Function(String))
      getter: <testLibrary>::@getter::x
      setter: <testLibrary>::@setter::x
  getters
    synthetic static x
      reference: <testLibrary>::@getter::x
      firstFragment: #F2
      returnType: int Function(int Function(String))
      variable: <testLibrary>::@topLevelVariable::x
  setters
    synthetic static x
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
    var library = await buildLibrary('''
var x = (int Function(String) f) => 0;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer x (nameOffset:4) (firstTokenOffset:4) (offset:4)
          element: <testLibrary>::@topLevelVariable::x
      getters
        #F2 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@getter::x
      setters
        #F3 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@setter::x
          formalParameters
            #F4 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
              element: <testLibrary>::@setter::x::@formalParameter::value
  topLevelVariables
    hasInitializer x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F1
      type: int Function(int Function(String))
      getter: <testLibrary>::@getter::x
      setter: <testLibrary>::@setter::x
  getters
    synthetic static x
      reference: <testLibrary>::@getter::x
      firstFragment: #F2
      returnType: int Function(int Function(String))
      variable: <testLibrary>::@topLevelVariable::x
  setters
    synthetic static x
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
    newFile('$testPackageLibPath/a.dart', 'export "b.dart";');
    newFile('$testPackageLibPath/b.dart', 'var x = 0;');
    var library = await buildLibrary('''
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
        #F1 hasInitializer y (nameOffset:21) (firstTokenOffset:21) (offset:21)
          element: <testLibrary>::@topLevelVariable::y
      getters
        #F2 synthetic y (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
          element: <testLibrary>::@getter::y
      setters
        #F3 synthetic y (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
          element: <testLibrary>::@setter::y
          formalParameters
            #F4 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@setter::y::@formalParameter::value
  topLevelVariables
    hasInitializer y
      reference: <testLibrary>::@topLevelVariable::y
      firstFragment: #F1
      type: int
      getter: <testLibrary>::@getter::y
      setter: <testLibrary>::@setter::y
  getters
    synthetic static y
      reference: <testLibrary>::@getter::y
      firstFragment: #F2
      returnType: int
      variable: <testLibrary>::@topLevelVariable::y
  setters
    synthetic static y
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
    var library = await buildLibrary('''
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
            #F2 hasInitializer x (nameOffset:25) (firstTokenOffset:25) (offset:25)
              element: <testLibrary>::@class::A::@field::x
            #F3 hasInitializer y (nameOffset:51) (firstTokenOffset:51) (offset:51)
              element: <testLibrary>::@class::A::@field::y
          constructors
            #F4 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F5 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
              element: <testLibrary>::@class::A::@getter::x
            #F6 synthetic y (nameOffset:<null>) (firstTokenOffset:<null>) (offset:51)
              element: <testLibrary>::@class::A::@getter::y
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        static final hasInitializer x
          reference: <testLibrary>::@class::A::@field::x
          firstFragment: #F2
          type: dynamic
          getter: <testLibrary>::@class::A::@getter::x
        static final hasInitializer y
          reference: <testLibrary>::@class::A::@field::y
          firstFragment: #F3
          type: dynamic
          getter: <testLibrary>::@class::A::@getter::y
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F4
      getters
        synthetic static x
          reference: <testLibrary>::@class::A::@getter::x
          firstFragment: #F5
          returnType: dynamic
          variable: <testLibrary>::@class::A::@field::x
        synthetic static y
          reference: <testLibrary>::@class::A::@getter::y
          firstFragment: #F6
          returnType: dynamic
          variable: <testLibrary>::@class::A::@field::y
''');
  }

  test_type_inference_field_cycle_chain() async {
    var library = await buildLibrary('''
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
            #F2 hasInitializer a (nameOffset:25) (firstTokenOffset:25) (offset:25)
              element: <testLibrary>::@class::A::@field::a
            #F3 hasInitializer b (nameOffset:49) (firstTokenOffset:49) (offset:49)
              element: <testLibrary>::@class::A::@field::b
            #F4 hasInitializer c (nameOffset:66) (firstTokenOffset:66) (offset:66)
              element: <testLibrary>::@class::A::@field::c
          constructors
            #F5 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
          getters
            #F6 synthetic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:25)
              element: <testLibrary>::@class::A::@getter::a
            #F7 synthetic b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:49)
              element: <testLibrary>::@class::A::@getter::b
            #F8 synthetic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:66)
              element: <testLibrary>::@class::A::@getter::c
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      fields
        static final hasInitializer a
          reference: <testLibrary>::@class::A::@field::a
          firstFragment: #F2
          type: dynamic
          getter: <testLibrary>::@class::A::@getter::a
        static final hasInitializer b
          reference: <testLibrary>::@class::A::@field::b
          firstFragment: #F3
          type: A
          getter: <testLibrary>::@class::A::@getter::b
        final hasInitializer c
          reference: <testLibrary>::@class::A::@field::c
          firstFragment: #F4
          type: dynamic
          getter: <testLibrary>::@class::A::@getter::c
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F5
      getters
        synthetic static a
          reference: <testLibrary>::@class::A::@getter::a
          firstFragment: #F6
          returnType: dynamic
          variable: <testLibrary>::@class::A::@field::a
        synthetic static b
          reference: <testLibrary>::@class::A::@getter::b
          firstFragment: #F7
          returnType: A
          variable: <testLibrary>::@class::A::@field::b
        synthetic c
          reference: <testLibrary>::@class::A::@getter::c
          firstFragment: #F8
          returnType: dynamic
          variable: <testLibrary>::@class::A::@field::c
''');
  }

  test_type_inference_field_depends_onFieldFormal() async {
    var library = await buildLibrary('''
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
            #F3 value (nameOffset:17) (firstTokenOffset:17) (offset:17)
              element: <testLibrary>::@class::A::@field::value
          constructors
            #F4 new (nameOffset:<null>) (firstTokenOffset:27) (offset:27)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
              typeNameOffset: 27
              formalParameters
                #F5 this.value (nameOffset:34) (firstTokenOffset:29) (offset:34)
                  element: <testLibrary>::@class::A::@constructor::new::@formalParameter::value
          getters
            #F6 synthetic value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:17)
              element: <testLibrary>::@class::A::@getter::value
          setters
            #F7 synthetic value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:17)
              element: <testLibrary>::@class::A::@setter::value
              formalParameters
                #F8 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:17)
                  element: <testLibrary>::@class::A::@setter::value::@formalParameter::value
        #F9 class B (nameOffset:51) (firstTokenOffset:45) (offset:51)
          element: <testLibrary>::@class::B
          fields
            #F10 hasInitializer a (nameOffset:61) (firstTokenOffset:61) (offset:61)
              element: <testLibrary>::@class::B::@field::a
          constructors
            #F11 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:51)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
          getters
            #F12 synthetic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:61)
              element: <testLibrary>::@class::B::@getter::a
          setters
            #F13 synthetic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:61)
              element: <testLibrary>::@class::B::@setter::a
              formalParameters
                #F14 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:61)
                  element: <testLibrary>::@class::B::@setter::a::@formalParameter::value
  classes
    hasNonFinalField class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      fields
        value
          reference: <testLibrary>::@class::A::@field::value
          firstFragment: #F3
          hasEnclosingTypeParameterReference: true
          type: T
          getter: <testLibrary>::@class::A::@getter::value
          setter: <testLibrary>::@class::A::@setter::value
      constructors
        new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F4
          formalParameters
            #E1 requiredPositional final hasImplicitType value
              firstFragment: #F5
              type: T
      getters
        synthetic value
          reference: <testLibrary>::@class::A::@getter::value
          firstFragment: #F6
          hasEnclosingTypeParameterReference: true
          returnType: T
          variable: <testLibrary>::@class::A::@field::value
      setters
        synthetic value
          reference: <testLibrary>::@class::A::@setter::value
          firstFragment: #F7
          hasEnclosingTypeParameterReference: true
          formalParameters
            #E2 requiredPositional value
              firstFragment: #F8
              type: T
          returnType: void
          variable: <testLibrary>::@class::A::@field::value
    hasNonFinalField class B
      reference: <testLibrary>::@class::B
      firstFragment: #F9
      fields
        hasInitializer a
          reference: <testLibrary>::@class::B::@field::a
          firstFragment: #F10
          type: A<String>
          getter: <testLibrary>::@class::B::@getter::a
          setter: <testLibrary>::@class::B::@setter::a
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F11
      getters
        synthetic a
          reference: <testLibrary>::@class::B::@getter::a
          firstFragment: #F12
          returnType: A<String>
          variable: <testLibrary>::@class::B::@field::a
      setters
        synthetic a
          reference: <testLibrary>::@class::B::@setter::a
          firstFragment: #F13
          formalParameters
            #E3 requiredPositional value
              firstFragment: #F14
              type: A<String>
          returnType: void
          variable: <testLibrary>::@class::B::@field::a
''');
  }

  test_type_inference_field_depends_onFieldFormal_withMixinApp() async {
    var library = await buildLibrary('''
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
            #F3 value (nameOffset:17) (firstTokenOffset:17) (offset:17)
              element: <testLibrary>::@class::A::@field::value
          constructors
            #F4 new (nameOffset:<null>) (firstTokenOffset:27) (offset:27)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
              typeNameOffset: 27
              formalParameters
                #F5 this.value (nameOffset:34) (firstTokenOffset:29) (offset:34)
                  element: <testLibrary>::@class::A::@constructor::new::@formalParameter::value
          getters
            #F6 synthetic value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:17)
              element: <testLibrary>::@class::A::@getter::value
          setters
            #F7 synthetic value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:17)
              element: <testLibrary>::@class::A::@setter::value
              formalParameters
                #F8 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:17)
                  element: <testLibrary>::@class::A::@setter::value::@formalParameter::value
        #F9 class B (nameOffset:51) (firstTokenOffset:45) (offset:51)
          element: <testLibrary>::@class::B
          typeParameters
            #F10 T (nameOffset:53) (firstTokenOffset:53) (offset:53)
              element: #E1 T
          constructors
            #F11 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:51)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
              formalParameters
                #F12 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:51)
                  element: <testLibrary>::@class::B::@constructor::new::@formalParameter::value
        #F13 class C (nameOffset:78) (firstTokenOffset:72) (offset:78)
          element: <testLibrary>::@class::C
          fields
            #F14 hasInitializer a (nameOffset:88) (firstTokenOffset:88) (offset:88)
              element: <testLibrary>::@class::C::@field::a
          constructors
            #F15 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:78)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F16 synthetic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:88)
              element: <testLibrary>::@class::C::@getter::a
          setters
            #F17 synthetic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:88)
              element: <testLibrary>::@class::C::@setter::a
              formalParameters
                #F18 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:88)
                  element: <testLibrary>::@class::C::@setter::a::@formalParameter::value
      mixins
        #F19 mixin M (nameOffset:112) (firstTokenOffset:106) (offset:112)
          element: <testLibrary>::@mixin::M
  classes
    hasNonFinalField class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      fields
        value
          reference: <testLibrary>::@class::A::@field::value
          firstFragment: #F3
          hasEnclosingTypeParameterReference: true
          type: T
          getter: <testLibrary>::@class::A::@getter::value
          setter: <testLibrary>::@class::A::@setter::value
      constructors
        new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F4
          formalParameters
            #E2 requiredPositional final hasImplicitType value
              firstFragment: #F5
              type: T
      getters
        synthetic value
          reference: <testLibrary>::@class::A::@getter::value
          firstFragment: #F6
          hasEnclosingTypeParameterReference: true
          returnType: T
          variable: <testLibrary>::@class::A::@field::value
      setters
        synthetic value
          reference: <testLibrary>::@class::A::@setter::value
          firstFragment: #F7
          hasEnclosingTypeParameterReference: true
          formalParameters
            #E3 requiredPositional value
              firstFragment: #F8
              type: T
          returnType: void
          variable: <testLibrary>::@class::A::@field::value
    hasNonFinalField class alias B
      reference: <testLibrary>::@class::B
      firstFragment: #F9
      typeParameters
        #E1 T
          firstFragment: #F10
      supertype: A<T>
      mixins
        M
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F11
          formalParameters
            #E4 requiredPositional final value
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
          superConstructor: ConstructorMember
            baseElement: <testLibrary>::@class::A::@constructor::new
            substitution: {T: T}
    hasNonFinalField class C
      reference: <testLibrary>::@class::C
      firstFragment: #F13
      fields
        hasInitializer a
          reference: <testLibrary>::@class::C::@field::a
          firstFragment: #F14
          type: B<int>
          getter: <testLibrary>::@class::C::@getter::a
          setter: <testLibrary>::@class::C::@setter::a
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F15
      getters
        synthetic a
          reference: <testLibrary>::@class::C::@getter::a
          firstFragment: #F16
          returnType: B<int>
          variable: <testLibrary>::@class::C::@field::a
      setters
        synthetic a
          reference: <testLibrary>::@class::C::@setter::a
          firstFragment: #F17
          formalParameters
            #E5 requiredPositional value
              firstFragment: #F18
              type: B<int>
          returnType: void
          variable: <testLibrary>::@class::C::@field::a
  mixins
    mixin M
      reference: <testLibrary>::@mixin::M
      firstFragment: #F19
      superclassConstraints
        Object
''');
  }

  test_type_inference_fieldFormal_depends_onField() async {
    var library = await buildLibrary('''
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
            #F3 hasInitializer f (nameOffset:19) (firstTokenOffset:19) (offset:19)
              element: <testLibrary>::@class::A::@field::f
          constructors
            #F4 new (nameOffset:<null>) (firstTokenOffset:28) (offset:28)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
              typeNameOffset: 28
              formalParameters
                #F5 this.f (nameOffset:35) (firstTokenOffset:30) (offset:35)
                  element: <testLibrary>::@class::A::@constructor::new::@formalParameter::f
          getters
            #F6 synthetic f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:19)
              element: <testLibrary>::@class::A::@getter::f
          setters
            #F7 synthetic f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:19)
              element: <testLibrary>::@class::A::@setter::f
              formalParameters
                #F8 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:19)
                  element: <testLibrary>::@class::A::@setter::f::@formalParameter::value
  classes
    hasNonFinalField class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      fields
        hasInitializer f
          reference: <testLibrary>::@class::A::@field::f
          firstFragment: #F3
          type: int
          getter: <testLibrary>::@class::A::@getter::f
          setter: <testLibrary>::@class::A::@setter::f
      constructors
        new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F4
          formalParameters
            #E1 requiredPositional final hasImplicitType f
              firstFragment: #F5
              type: int
      getters
        synthetic f
          reference: <testLibrary>::@class::A::@getter::f
          firstFragment: #F6
          returnType: int
          variable: <testLibrary>::@class::A::@field::f
      setters
        synthetic f
          reference: <testLibrary>::@class::A::@setter::f
          firstFragment: #F7
          formalParameters
            #E2 requiredPositional value
              firstFragment: #F8
              type: int
          returnType: void
          variable: <testLibrary>::@class::A::@field::f
''');
  }

  test_type_inference_instanceCreation_notGeneric() async {
    var library = await buildLibrary('''
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
            #F2 new (nameOffset:<null>) (firstTokenOffset:12) (offset:12)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
              typeNameOffset: 12
              formalParameters
                #F3 _ (nameOffset:14) (firstTokenOffset:14) (offset:14)
                  element: <testLibrary>::@class::A::@constructor::new::@formalParameter::_
      topLevelVariables
        #F4 hasInitializer a (nameOffset:26) (firstTokenOffset:26) (offset:26)
          element: <testLibrary>::@topLevelVariable::a
        #F5 hasInitializer b (nameOffset:48) (firstTokenOffset:48) (offset:48)
          element: <testLibrary>::@topLevelVariable::b
      getters
        #F6 synthetic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:26)
          element: <testLibrary>::@getter::a
        #F7 synthetic b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:48)
          element: <testLibrary>::@getter::b
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
          formalParameters
            #E0 requiredPositional hasImplicitType _
              firstFragment: #F3
              type: dynamic
  topLevelVariables
    final hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F4
      type: dynamic
      getter: <testLibrary>::@getter::a
    final hasInitializer b
      reference: <testLibrary>::@topLevelVariable::b
      firstFragment: #F5
      type: dynamic
      getter: <testLibrary>::@getter::b
  getters
    synthetic static a
      reference: <testLibrary>::@getter::a
      firstFragment: #F6
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::a
    synthetic static b
      reference: <testLibrary>::@getter::b
      firstFragment: #F7
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::b
''');
  }

  test_type_inference_multiplyDefinedElement() async {
    newFile('$testPackageLibPath/a.dart', 'class C {}');
    newFile('$testPackageLibPath/b.dart', 'class C {}');
    var library = await buildLibrary('''
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
        #F1 hasInitializer v (nameOffset:38) (firstTokenOffset:38) (offset:38)
          element: <testLibrary>::@topLevelVariable::v
      getters
        #F2 synthetic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:38)
          element: <testLibrary>::@getter::v
      setters
        #F3 synthetic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:38)
          element: <testLibrary>::@setter::v
          formalParameters
            #F4 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:38)
              element: <testLibrary>::@setter::v::@formalParameter::value
  topLevelVariables
    hasInitializer v
      reference: <testLibrary>::@topLevelVariable::v
      firstFragment: #F1
      type: InvalidType
      getter: <testLibrary>::@getter::v
      setter: <testLibrary>::@setter::v
  getters
    synthetic static v
      reference: <testLibrary>::@getter::v
      firstFragment: #F2
      returnType: InvalidType
      variable: <testLibrary>::@topLevelVariable::v
  setters
    synthetic static v
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
    var library = await buildLibrary('''
var x = (t) => (u) => t + u;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer x (nameOffset:4) (firstTokenOffset:4) (offset:4)
          element: <testLibrary>::@topLevelVariable::x
      getters
        #F2 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@getter::x
      setters
        #F3 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@setter::x
          formalParameters
            #F4 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
              element: <testLibrary>::@setter::x::@formalParameter::value
  topLevelVariables
    hasInitializer x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F1
      type: dynamic Function(dynamic) Function(dynamic)
      getter: <testLibrary>::@getter::x
      setter: <testLibrary>::@setter::x
  getters
    synthetic static x
      reference: <testLibrary>::@getter::x
      firstFragment: #F2
      returnType: dynamic Function(dynamic) Function(dynamic)
      variable: <testLibrary>::@topLevelVariable::x
  setters
    synthetic static x
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
    var library = await buildLibrary('''
var x = (int t) => (int u) => t + u;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer x (nameOffset:4) (firstTokenOffset:4) (offset:4)
          element: <testLibrary>::@topLevelVariable::x
      getters
        #F2 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@getter::x
      setters
        #F3 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@setter::x
          formalParameters
            #F4 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
              element: <testLibrary>::@setter::x::@formalParameter::value
  topLevelVariables
    hasInitializer x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F1
      type: int Function(int) Function(int)
      getter: <testLibrary>::@getter::x
      setter: <testLibrary>::@setter::x
  getters
    synthetic static x
      reference: <testLibrary>::@getter::x
      firstFragment: #F2
      returnType: int Function(int) Function(int)
      variable: <testLibrary>::@topLevelVariable::x
  setters
    synthetic static x
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
    var library = await buildLibrary('''
var x = ([y: 0]) => y;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 hasInitializer x (nameOffset:4) (firstTokenOffset:4) (offset:4)
          element: <testLibrary>::@topLevelVariable::x
      getters
        #F2 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@getter::x
      setters
        #F3 synthetic x (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@setter::x
          formalParameters
            #F4 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
              element: <testLibrary>::@setter::x::@formalParameter::value
  topLevelVariables
    hasInitializer x
      reference: <testLibrary>::@topLevelVariable::x
      firstFragment: #F1
      type: dynamic Function([dynamic])
      getter: <testLibrary>::@getter::x
      setter: <testLibrary>::@setter::x
  getters
    synthetic static x
      reference: <testLibrary>::@getter::x
      firstFragment: #F2
      returnType: dynamic Function([dynamic])
      variable: <testLibrary>::@topLevelVariable::x
  setters
    synthetic static x
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
    var library = await buildLibrary('''
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
        #F1 hasInitializer a (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::a
        #F2 hasInitializer b (nameOffset:19) (firstTokenOffset:19) (offset:19)
          element: <testLibrary>::@topLevelVariable::b
        #F3 hasInitializer c (nameOffset:32) (firstTokenOffset:32) (offset:32)
          element: <testLibrary>::@topLevelVariable::c
      getters
        #F4 synthetic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
        #F5 synthetic b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:19)
          element: <testLibrary>::@getter::b
        #F6 synthetic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:32)
          element: <testLibrary>::@getter::c
  topLevelVariables
    final hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F1
      type: dynamic
      getter: <testLibrary>::@getter::a
    final hasInitializer b
      reference: <testLibrary>::@topLevelVariable::b
      firstFragment: #F2
      type: dynamic
      getter: <testLibrary>::@getter::b
    final hasInitializer c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: #F3
      type: dynamic
      getter: <testLibrary>::@getter::c
  getters
    synthetic static a
      reference: <testLibrary>::@getter::a
      firstFragment: #F4
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::a
    synthetic static b
      reference: <testLibrary>::@getter::b
      firstFragment: #F5
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::b
    synthetic static c
      reference: <testLibrary>::@getter::c
      firstFragment: #F6
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_type_inference_topVariable_cycle_beforeChain() async {
    // Note that `c` depends on `b`, but does not belong to the cycle.
    var library = await buildLibrary('''
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
        #F1 hasInitializer a (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::a
        #F2 hasInitializer b (nameOffset:19) (firstTokenOffset:19) (offset:19)
          element: <testLibrary>::@topLevelVariable::b
        #F3 hasInitializer c (nameOffset:32) (firstTokenOffset:32) (offset:32)
          element: <testLibrary>::@topLevelVariable::c
      getters
        #F4 synthetic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
        #F5 synthetic b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:19)
          element: <testLibrary>::@getter::b
        #F6 synthetic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:32)
          element: <testLibrary>::@getter::c
  topLevelVariables
    final hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F1
      type: dynamic
      getter: <testLibrary>::@getter::a
    final hasInitializer b
      reference: <testLibrary>::@topLevelVariable::b
      firstFragment: #F2
      type: dynamic
      getter: <testLibrary>::@getter::b
    final hasInitializer c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: #F3
      type: dynamic
      getter: <testLibrary>::@getter::c
  getters
    synthetic static a
      reference: <testLibrary>::@getter::a
      firstFragment: #F4
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::a
    synthetic static b
      reference: <testLibrary>::@getter::b
      firstFragment: #F5
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::b
    synthetic static c
      reference: <testLibrary>::@getter::c
      firstFragment: #F6
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_type_inference_topVariable_cycle_inCycle() async {
    // `b` and `c` form a cycle.
    // `a` and `d` form a different cycle, even though `a` references `b`.
    var library = await buildLibrary('''
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
        #F1 hasInitializer a (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::a
        #F2 hasInitializer b (nameOffset:23) (firstTokenOffset:23) (offset:23)
          element: <testLibrary>::@topLevelVariable::b
        #F3 hasInitializer c (nameOffset:36) (firstTokenOffset:36) (offset:36)
          element: <testLibrary>::@topLevelVariable::c
        #F4 hasInitializer d (nameOffset:49) (firstTokenOffset:49) (offset:49)
          element: <testLibrary>::@topLevelVariable::d
      getters
        #F5 synthetic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
        #F6 synthetic b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
          element: <testLibrary>::@getter::b
        #F7 synthetic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:36)
          element: <testLibrary>::@getter::c
        #F8 synthetic d (nameOffset:<null>) (firstTokenOffset:<null>) (offset:49)
          element: <testLibrary>::@getter::d
  topLevelVariables
    final hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F1
      type: dynamic
      getter: <testLibrary>::@getter::a
    final hasInitializer b
      reference: <testLibrary>::@topLevelVariable::b
      firstFragment: #F2
      type: dynamic
      getter: <testLibrary>::@getter::b
    final hasInitializer c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: #F3
      type: dynamic
      getter: <testLibrary>::@getter::c
    final hasInitializer d
      reference: <testLibrary>::@topLevelVariable::d
      firstFragment: #F4
      type: dynamic
      getter: <testLibrary>::@getter::d
  getters
    synthetic static a
      reference: <testLibrary>::@getter::a
      firstFragment: #F5
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::a
    synthetic static b
      reference: <testLibrary>::@getter::b
      firstFragment: #F6
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::b
    synthetic static c
      reference: <testLibrary>::@getter::c
      firstFragment: #F7
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::c
    synthetic static d
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
    var library = await buildLibrary('''
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
        #F1 hasInitializer a (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::a
        #F2 hasInitializer b (nameOffset:19) (firstTokenOffset:19) (offset:19)
          element: <testLibrary>::@topLevelVariable::b
        #F3 hasInitializer c (nameOffset:36) (firstTokenOffset:36) (offset:36)
          element: <testLibrary>::@topLevelVariable::c
      getters
        #F4 synthetic a (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::a
        #F5 synthetic b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:19)
          element: <testLibrary>::@getter::b
        #F6 synthetic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:36)
          element: <testLibrary>::@getter::c
  topLevelVariables
    final hasInitializer a
      reference: <testLibrary>::@topLevelVariable::a
      firstFragment: #F1
      type: dynamic
      getter: <testLibrary>::@getter::a
    final hasInitializer b
      reference: <testLibrary>::@topLevelVariable::b
      firstFragment: #F2
      type: dynamic
      getter: <testLibrary>::@getter::b
    final hasInitializer c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: #F3
      type: dynamic
      getter: <testLibrary>::@getter::c
  getters
    synthetic static a
      reference: <testLibrary>::@getter::a
      firstFragment: #F4
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::a
    synthetic static b
      reference: <testLibrary>::@getter::b
      firstFragment: #F5
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::b
    synthetic static c
      reference: <testLibrary>::@getter::c
      firstFragment: #F6
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_type_inference_topVariable_depends_onFieldFormal() async {
    var library = await buildLibrary('''
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
            #F2 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::A::@constructor::new
              typeName: A
        #F3 class B (nameOffset:18) (firstTokenOffset:12) (offset:18)
          element: <testLibrary>::@class::B
          constructors
            #F4 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:18)
              element: <testLibrary>::@class::B::@constructor::new
              typeName: B
        #F5 class C (nameOffset:40) (firstTokenOffset:34) (offset:40)
          element: <testLibrary>::@class::C
          typeParameters
            #F6 T (nameOffset:42) (firstTokenOffset:42) (offset:42)
              element: #E0 T
          fields
            #F7 f (nameOffset:67) (firstTokenOffset:67) (offset:67)
              element: <testLibrary>::@class::C::@field::f
          constructors
            #F8 const new (nameOffset:<null>) (firstTokenOffset:72) (offset:78)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
              typeNameOffset: 78
              formalParameters
                #F9 this.f (nameOffset:85) (firstTokenOffset:80) (offset:85)
                  element: <testLibrary>::@class::C::@constructor::new::@formalParameter::f
          getters
            #F10 synthetic f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:67)
              element: <testLibrary>::@class::C::@getter::f
      topLevelVariables
        #F11 hasInitializer b (nameOffset:98) (firstTokenOffset:98) (offset:98)
          element: <testLibrary>::@topLevelVariable::b
        #F12 hasInitializer c (nameOffset:113) (firstTokenOffset:113) (offset:113)
          element: <testLibrary>::@topLevelVariable::c
      getters
        #F13 synthetic b (nameOffset:<null>) (firstTokenOffset:<null>) (offset:98)
          element: <testLibrary>::@getter::b
        #F14 synthetic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:113)
          element: <testLibrary>::@getter::c
  classes
    class A
      reference: <testLibrary>::@class::A
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::A::@constructor::new
          firstFragment: #F2
    class B
      reference: <testLibrary>::@class::B
      firstFragment: #F3
      supertype: A
      constructors
        synthetic new
          reference: <testLibrary>::@class::B::@constructor::new
          firstFragment: #F4
          superConstructor: <testLibrary>::@class::A::@constructor::new
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F5
      typeParameters
        #E0 T
          firstFragment: #F6
          bound: A
      fields
        final f
          reference: <testLibrary>::@class::C::@field::f
          firstFragment: #F7
          hasEnclosingTypeParameterReference: true
          type: T
          getter: <testLibrary>::@class::C::@getter::f
      constructors
        const new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F8
          formalParameters
            #E1 requiredPositional final hasImplicitType f
              firstFragment: #F9
              type: T
      getters
        synthetic f
          reference: <testLibrary>::@class::C::@getter::f
          firstFragment: #F10
          hasEnclosingTypeParameterReference: true
          returnType: T
          variable: <testLibrary>::@class::C::@field::f
  topLevelVariables
    final hasInitializer b
      reference: <testLibrary>::@topLevelVariable::b
      firstFragment: #F11
      type: B
      getter: <testLibrary>::@getter::b
    final hasInitializer c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: #F12
      type: C<B>
      getter: <testLibrary>::@getter::c
  getters
    synthetic static b
      reference: <testLibrary>::@getter::b
      firstFragment: #F13
      returnType: B
      variable: <testLibrary>::@topLevelVariable::b
    synthetic static c
      reference: <testLibrary>::@getter::c
      firstFragment: #F14
      returnType: C<B>
      variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_type_inference_using_extension_getter() async {
    var library = await buildLibrary('''
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
          element: <testLibrary>::@extension::0
          fields
            #F2 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:0)
              element: <testLibrary>::@extension::0::@field::foo
          getters
            #F3 foo (nameOffset:32) (firstTokenOffset:24) (offset:32)
              element: <testLibrary>::@extension::0::@getter::foo
      topLevelVariables
        #F4 hasInitializer v (nameOffset:48) (firstTokenOffset:48) (offset:48)
          element: <testLibrary>::@topLevelVariable::v
      getters
        #F5 synthetic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:48)
          element: <testLibrary>::@getter::v
      setters
        #F6 synthetic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:48)
          element: <testLibrary>::@setter::v
          formalParameters
            #F7 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:48)
              element: <testLibrary>::@setter::v::@formalParameter::value
  extensions
    extension <null-name>
      reference: <testLibrary>::@extension::0
      firstFragment: #F1
      extendedType: String
      fields
        synthetic foo
          reference: <testLibrary>::@extension::0::@field::foo
          firstFragment: #F2
          type: int
          getter: <testLibrary>::@extension::0::@getter::foo
      getters
        foo
          reference: <testLibrary>::@extension::0::@getter::foo
          firstFragment: #F3
          returnType: int
          variable: <testLibrary>::@extension::0::@field::foo
  topLevelVariables
    hasInitializer v
      reference: <testLibrary>::@topLevelVariable::v
      firstFragment: #F4
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
        #E0 requiredPositional value
          firstFragment: #F7
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::v
''');
  }

  test_type_invalid_topLevelVariableElement_asType() async {
    var library = await buildLibrary('''
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
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
      typeAliases
        #F4 F (nameOffset:34) (firstTokenOffset:24) (offset:34)
          element: <testLibrary>::@typeAlias::F
      topLevelVariables
        #F5 hasInitializer V2 (nameOffset:56) (firstTokenOffset:56) (offset:56)
          element: <testLibrary>::@topLevelVariable::V2
        #F6 hasInitializer V (nameOffset:71) (firstTokenOffset:71) (offset:71)
          element: <testLibrary>::@topLevelVariable::V
      getters
        #F7 synthetic V2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:56)
          element: <testLibrary>::@getter::V2
        #F8 synthetic V (nameOffset:<null>) (firstTokenOffset:<null>) (offset:71)
          element: <testLibrary>::@getter::V
      setters
        #F9 synthetic V2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:56)
          element: <testLibrary>::@setter::V2
          formalParameters
            #F10 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:56)
              element: <testLibrary>::@setter::V2::@formalParameter::value
        #F11 synthetic V (nameOffset:<null>) (firstTokenOffset:<null>) (offset:71)
          element: <testLibrary>::@setter::V
          formalParameters
            #F12 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:71)
              element: <testLibrary>::@setter::V::@formalParameter::value
      functions
        #F13 f (nameOffset:44) (firstTokenOffset:42) (offset:44)
          element: <testLibrary>::@function::f
          formalParameters
            #F14 p (nameOffset:48) (firstTokenOffset:46) (offset:48)
              element: <testLibrary>::@function::f::@formalParameter::p
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
          bound: dynamic
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
  typeAliases
    F
      reference: <testLibrary>::@typeAlias::F
      firstFragment: #F4
      aliasedType: dynamic Function(dynamic)
  topLevelVariables
    hasInitializer V2
      reference: <testLibrary>::@topLevelVariable::V2
      firstFragment: #F5
      type: dynamic
      getter: <testLibrary>::@getter::V2
      setter: <testLibrary>::@setter::V2
    hasInitializer V
      reference: <testLibrary>::@topLevelVariable::V
      firstFragment: #F6
      type: int
      getter: <testLibrary>::@getter::V
      setter: <testLibrary>::@setter::V
  getters
    synthetic static V2
      reference: <testLibrary>::@getter::V2
      firstFragment: #F7
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::V2
    synthetic static V
      reference: <testLibrary>::@getter::V
      firstFragment: #F8
      returnType: int
      variable: <testLibrary>::@topLevelVariable::V
  setters
    synthetic static V2
      reference: <testLibrary>::@setter::V2
      firstFragment: #F9
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F10
          type: dynamic
      returnType: void
      variable: <testLibrary>::@topLevelVariable::V2
    synthetic static V
      reference: <testLibrary>::@setter::V
      firstFragment: #F11
      formalParameters
        #E2 requiredPositional value
          firstFragment: #F12
          type: int
      returnType: void
      variable: <testLibrary>::@topLevelVariable::V
  functions
    f
      reference: <testLibrary>::@function::f
      firstFragment: #F13
      formalParameters
        #E3 requiredPositional p
          firstFragment: #F14
          type: dynamic
      returnType: dynamic
''');
  }

  test_type_invalid_topLevelVariableElement_asTypeArgument() async {
    var library = await buildLibrary('''
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
        #F1 V (nameOffset:4) (firstTokenOffset:4) (offset:4)
          element: <testLibrary>::@topLevelVariable::V
        #F2 V2 (nameOffset:22) (firstTokenOffset:22) (offset:22)
          element: <testLibrary>::@topLevelVariable::V2
      getters
        #F3 synthetic V (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@getter::V
        #F4 synthetic V2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
          element: <testLibrary>::@getter::V2
      setters
        #F5 synthetic V (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@setter::V
          formalParameters
            #F6 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
              element: <testLibrary>::@setter::V::@formalParameter::value
        #F7 synthetic V2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
          element: <testLibrary>::@setter::V2
          formalParameters
            #F8 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:22)
              element: <testLibrary>::@setter::V2::@formalParameter::value
  topLevelVariables
    V
      reference: <testLibrary>::@topLevelVariable::V
      firstFragment: #F1
      type: dynamic
      getter: <testLibrary>::@getter::V
      setter: <testLibrary>::@setter::V
    V2
      reference: <testLibrary>::@topLevelVariable::V2
      firstFragment: #F2
      type: List<dynamic>
      getter: <testLibrary>::@getter::V2
      setter: <testLibrary>::@setter::V2
  getters
    synthetic static V
      reference: <testLibrary>::@getter::V
      firstFragment: #F3
      returnType: dynamic
      variable: <testLibrary>::@topLevelVariable::V
    synthetic static V2
      reference: <testLibrary>::@getter::V2
      firstFragment: #F4
      returnType: List<dynamic>
      variable: <testLibrary>::@topLevelVariable::V2
  setters
    synthetic static V
      reference: <testLibrary>::@setter::V
      firstFragment: #F5
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F6
          type: dynamic
      returnType: void
      variable: <testLibrary>::@topLevelVariable::V
    synthetic static V2
      reference: <testLibrary>::@setter::V2
      firstFragment: #F7
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F8
          type: List<dynamic>
      returnType: void
      variable: <testLibrary>::@topLevelVariable::V2
''');
  }

  test_type_invalid_typeParameter_asPrefix() async {
    var library = await buildLibrary('''
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
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          methods
            #F4 m (nameOffset:15) (firstTokenOffset:15) (offset:15)
              element: <testLibrary>::@class::C::@method::m
              formalParameters
                #F5 p (nameOffset:21) (firstTokenOffset:17) (offset:21)
                  element: <testLibrary>::@class::C::@method::m::@formalParameter::p
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
      methods
        m
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
    var library = await buildLibrary('''
p.C v;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 v (nameOffset:4) (firstTokenOffset:4) (offset:4)
          element: <testLibrary>::@topLevelVariable::v
      getters
        #F2 synthetic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@getter::v
      setters
        #F3 synthetic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
          element: <testLibrary>::@setter::v
          formalParameters
            #F4 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:4)
              element: <testLibrary>::@setter::v::@formalParameter::value
  topLevelVariables
    v
      reference: <testLibrary>::@topLevelVariable::v
      firstFragment: #F1
      type: InvalidType
      getter: <testLibrary>::@getter::v
      setter: <testLibrary>::@setter::v
  getters
    synthetic static v
      reference: <testLibrary>::@getter::v
      firstFragment: #F2
      returnType: InvalidType
      variable: <testLibrary>::@topLevelVariable::v
  setters
    synthetic static v
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
    var library = await buildLibrary('Never d;');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      topLevelVariables
        #F1 d (nameOffset:6) (firstTokenOffset:6) (offset:6)
          element: <testLibrary>::@topLevelVariable::d
      getters
        #F2 synthetic d (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@getter::d
      setters
        #F3 synthetic d (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
          element: <testLibrary>::@setter::d
          formalParameters
            #F4 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@setter::d::@formalParameter::value
  topLevelVariables
    d
      reference: <testLibrary>::@topLevelVariable::d
      firstFragment: #F1
      type: Never
      getter: <testLibrary>::@getter::d
      setter: <testLibrary>::@setter::d
  getters
    synthetic static d
      reference: <testLibrary>::@getter::d
      firstFragment: #F2
      returnType: Never
      variable: <testLibrary>::@topLevelVariable::d
  setters
    synthetic static d
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
    var library = await buildLibrary('''
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
            #F3 t (nameOffset:17) (firstTokenOffset:17) (offset:17)
              element: <testLibrary>::@class::C::@field::t
          constructors
            #F4 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F5 synthetic t (nameOffset:<null>) (firstTokenOffset:<null>) (offset:17)
              element: <testLibrary>::@class::C::@getter::t
          setters
            #F6 synthetic t (nameOffset:<null>) (firstTokenOffset:<null>) (offset:17)
              element: <testLibrary>::@class::C::@setter::t
              formalParameters
                #F7 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:17)
                  element: <testLibrary>::@class::C::@setter::t::@formalParameter::value
  classes
    hasNonFinalField class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      fields
        t
          reference: <testLibrary>::@class::C::@field::t
          firstFragment: #F3
          hasEnclosingTypeParameterReference: true
          type: T
          getter: <testLibrary>::@class::C::@getter::t
          setter: <testLibrary>::@class::C::@setter::t
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F4
      getters
        synthetic t
          reference: <testLibrary>::@class::C::@getter::t
          firstFragment: #F5
          hasEnclosingTypeParameterReference: true
          returnType: T
          variable: <testLibrary>::@class::C::@field::t
      setters
        synthetic t
          reference: <testLibrary>::@class::C::@setter::t
          firstFragment: #F6
          hasEnclosingTypeParameterReference: true
          formalParameters
            #E1 requiredPositional value
              firstFragment: #F7
              type: T
          returnType: void
          variable: <testLibrary>::@class::C::@field::t
''');
  }

  test_type_param_ref_nullability_question() async {
    var library = await buildLibrary('''
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
            #F3 t (nameOffset:18) (firstTokenOffset:18) (offset:18)
              element: <testLibrary>::@class::C::@field::t
          constructors
            #F4 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
          getters
            #F5 synthetic t (nameOffset:<null>) (firstTokenOffset:<null>) (offset:18)
              element: <testLibrary>::@class::C::@getter::t
          setters
            #F6 synthetic t (nameOffset:<null>) (firstTokenOffset:<null>) (offset:18)
              element: <testLibrary>::@class::C::@setter::t
              formalParameters
                #F7 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:18)
                  element: <testLibrary>::@class::C::@setter::t::@formalParameter::value
  classes
    hasNonFinalField class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
      fields
        t
          reference: <testLibrary>::@class::C::@field::t
          firstFragment: #F3
          hasEnclosingTypeParameterReference: true
          type: T?
          getter: <testLibrary>::@class::C::@getter::t
          setter: <testLibrary>::@class::C::@setter::t
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F4
      getters
        synthetic t
          reference: <testLibrary>::@class::C::@getter::t
          firstFragment: #F5
          hasEnclosingTypeParameterReference: true
          returnType: T?
          variable: <testLibrary>::@class::C::@field::t
      setters
        synthetic t
          reference: <testLibrary>::@class::C::@setter::t
          firstFragment: #F6
          hasEnclosingTypeParameterReference: true
          formalParameters
            #E1 requiredPositional value
              firstFragment: #F7
              type: T?
          returnType: void
          variable: <testLibrary>::@class::C::@field::t
''');
  }

  test_type_reference_lib_to_lib() async {
    var library = await buildLibrary('''
class C {}
enum E { v }
typedef F();
C c;
E e;
F f;''');
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
      enums
        #F3 enum E (nameOffset:16) (firstTokenOffset:11) (offset:16)
          element: <testLibrary>::@enum::E
          fields
            #F4 hasInitializer v (nameOffset:20) (firstTokenOffset:20) (offset:20)
              element: <testLibrary>::@enum::E::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element2: <testLibrary>::@enum::E
                      type: E
                    element: <testLibrary>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            #F5 synthetic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
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
          constructors
            #F6 synthetic const new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F7 synthetic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:20)
              element: <testLibrary>::@enum::E::@getter::v
            #F8 synthetic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:16)
              element: <testLibrary>::@enum::E::@getter::values
      typeAliases
        #F9 F (nameOffset:32) (firstTokenOffset:24) (offset:32)
          element: <testLibrary>::@typeAlias::F
      topLevelVariables
        #F10 c (nameOffset:39) (firstTokenOffset:39) (offset:39)
          element: <testLibrary>::@topLevelVariable::c
        #F11 e (nameOffset:44) (firstTokenOffset:44) (offset:44)
          element: <testLibrary>::@topLevelVariable::e
        #F12 f (nameOffset:49) (firstTokenOffset:49) (offset:49)
          element: <testLibrary>::@topLevelVariable::f
      getters
        #F13 synthetic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:39)
          element: <testLibrary>::@getter::c
        #F14 synthetic e (nameOffset:<null>) (firstTokenOffset:<null>) (offset:44)
          element: <testLibrary>::@getter::e
        #F15 synthetic f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:49)
          element: <testLibrary>::@getter::f
      setters
        #F16 synthetic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:39)
          element: <testLibrary>::@setter::c
          formalParameters
            #F17 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:39)
              element: <testLibrary>::@setter::c::@formalParameter::value
        #F18 synthetic e (nameOffset:<null>) (firstTokenOffset:<null>) (offset:44)
          element: <testLibrary>::@setter::e
          formalParameters
            #F19 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:44)
              element: <testLibrary>::@setter::e::@formalParameter::value
        #F20 synthetic f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:49)
          element: <testLibrary>::@setter::f
          formalParameters
            #F21 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:49)
              element: <testLibrary>::@setter::f::@formalParameter::value
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F3
      supertype: Enum
      fields
        static const enumConstant hasInitializer v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F4
          type: E
          constantInitializer
            fragment: #F4
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        synthetic static const values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F5
          type: List<E>
          constantInitializer
            fragment: #F5
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        synthetic const new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F6
      getters
        synthetic static v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F7
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        synthetic static values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F8
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
  typeAliases
    F
      reference: <testLibrary>::@typeAlias::F
      firstFragment: #F9
      aliasedType: dynamic Function()
  topLevelVariables
    c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: #F10
      type: C
      getter: <testLibrary>::@getter::c
      setter: <testLibrary>::@setter::c
    e
      reference: <testLibrary>::@topLevelVariable::e
      firstFragment: #F11
      type: E
      getter: <testLibrary>::@getter::e
      setter: <testLibrary>::@setter::e
    f
      reference: <testLibrary>::@topLevelVariable::f
      firstFragment: #F12
      type: dynamic Function()
        alias: <testLibrary>::@typeAlias::F
      getter: <testLibrary>::@getter::f
      setter: <testLibrary>::@setter::f
  getters
    synthetic static c
      reference: <testLibrary>::@getter::c
      firstFragment: #F13
      returnType: C
      variable: <testLibrary>::@topLevelVariable::c
    synthetic static e
      reference: <testLibrary>::@getter::e
      firstFragment: #F14
      returnType: E
      variable: <testLibrary>::@topLevelVariable::e
    synthetic static f
      reference: <testLibrary>::@getter::f
      firstFragment: #F15
      returnType: dynamic Function()
        alias: <testLibrary>::@typeAlias::F
      variable: <testLibrary>::@topLevelVariable::f
  setters
    synthetic static c
      reference: <testLibrary>::@setter::c
      firstFragment: #F16
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F17
          type: C
      returnType: void
      variable: <testLibrary>::@topLevelVariable::c
    synthetic static e
      reference: <testLibrary>::@setter::e
      firstFragment: #F18
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F19
          type: E
      returnType: void
      variable: <testLibrary>::@topLevelVariable::e
    synthetic static f
      reference: <testLibrary>::@setter::f
      firstFragment: #F20
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
    newFile(
      '$testPackageLibPath/a.dart',
      'part of l; class C {} enum E { v } typedef F();',
    );
    var library = await buildLibrary(
      'library l; part "a.dart"; C c; E e; F f;',
    );
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
          partKeywordOffset: 11
          unit: #F1
      topLevelVariables
        #F2 c (nameOffset:28) (firstTokenOffset:28) (offset:28)
          element: <testLibrary>::@topLevelVariable::c
        #F3 e (nameOffset:33) (firstTokenOffset:33) (offset:33)
          element: <testLibrary>::@topLevelVariable::e
        #F4 f (nameOffset:38) (firstTokenOffset:38) (offset:38)
          element: <testLibrary>::@topLevelVariable::f
      getters
        #F5 synthetic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:28)
          element: <testLibrary>::@getter::c
        #F6 synthetic e (nameOffset:<null>) (firstTokenOffset:<null>) (offset:33)
          element: <testLibrary>::@getter::e
        #F7 synthetic f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:38)
          element: <testLibrary>::@getter::f
      setters
        #F8 synthetic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:28)
          element: <testLibrary>::@setter::c
          formalParameters
            #F9 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:28)
              element: <testLibrary>::@setter::c::@formalParameter::value
        #F10 synthetic e (nameOffset:<null>) (firstTokenOffset:<null>) (offset:33)
          element: <testLibrary>::@setter::e
          formalParameters
            #F11 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:33)
              element: <testLibrary>::@setter::e::@formalParameter::value
        #F12 synthetic f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:38)
          element: <testLibrary>::@setter::f
          formalParameters
            #F13 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:38)
              element: <testLibrary>::@setter::f::@formalParameter::value
    #F1 package:test/a.dart
      element: <testLibrary>
      enclosingFragment: #F0
      previousFragment: #F0
      classes
        #F14 class C (nameOffset:17) (firstTokenOffset:11) (offset:17)
          element: <testLibrary>::@class::C
          constructors
            #F15 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:17)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
      enums
        #F16 enum E (nameOffset:27) (firstTokenOffset:22) (offset:27)
          element: <testLibrary>::@enum::E
          fields
            #F17 hasInitializer v (nameOffset:31) (firstTokenOffset:31) (offset:31)
              element: <testLibrary>::@enum::E::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element2: <testLibrary>::@enum::E
                      type: E
                    element: <testLibrary>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            #F18 synthetic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:27)
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
          constructors
            #F19 synthetic const new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:27)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F20 synthetic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
              element: <testLibrary>::@enum::E::@getter::v
            #F21 synthetic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:27)
              element: <testLibrary>::@enum::E::@getter::values
      typeAliases
        #F22 F (nameOffset:43) (firstTokenOffset:35) (offset:43)
          element: <testLibrary>::@typeAlias::F
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F14
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F15
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F16
      supertype: Enum
      fields
        static const enumConstant hasInitializer v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F17
          type: E
          constantInitializer
            fragment: #F17
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        synthetic static const values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F18
          type: List<E>
          constantInitializer
            fragment: #F18
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        synthetic const new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F19
      getters
        synthetic static v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F20
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        synthetic static values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F21
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
  typeAliases
    F
      reference: <testLibrary>::@typeAlias::F
      firstFragment: #F22
      aliasedType: dynamic Function()
  topLevelVariables
    c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: #F2
      type: C
      getter: <testLibrary>::@getter::c
      setter: <testLibrary>::@setter::c
    e
      reference: <testLibrary>::@topLevelVariable::e
      firstFragment: #F3
      type: E
      getter: <testLibrary>::@getter::e
      setter: <testLibrary>::@setter::e
    f
      reference: <testLibrary>::@topLevelVariable::f
      firstFragment: #F4
      type: dynamic Function()
        alias: <testLibrary>::@typeAlias::F
      getter: <testLibrary>::@getter::f
      setter: <testLibrary>::@setter::f
  getters
    synthetic static c
      reference: <testLibrary>::@getter::c
      firstFragment: #F5
      returnType: C
      variable: <testLibrary>::@topLevelVariable::c
    synthetic static e
      reference: <testLibrary>::@getter::e
      firstFragment: #F6
      returnType: E
      variable: <testLibrary>::@topLevelVariable::e
    synthetic static f
      reference: <testLibrary>::@getter::f
      firstFragment: #F7
      returnType: dynamic Function()
        alias: <testLibrary>::@typeAlias::F
      variable: <testLibrary>::@topLevelVariable::f
  setters
    synthetic static c
      reference: <testLibrary>::@setter::c
      firstFragment: #F8
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F9
          type: C
      returnType: void
      variable: <testLibrary>::@topLevelVariable::c
    synthetic static e
      reference: <testLibrary>::@setter::e
      firstFragment: #F10
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F11
          type: E
      returnType: void
      variable: <testLibrary>::@topLevelVariable::e
    synthetic static f
      reference: <testLibrary>::@setter::f
      firstFragment: #F12
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
    newFile('$testPackageLibPath/a.dart', 'part of l; C c; E e; F f;');
    var library = await buildLibrary(
      'library l; part "a.dart"; class C {} enum E { v } typedef F();',
    );
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
          partKeywordOffset: 11
          unit: #F1
      classes
        #F2 class C (nameOffset:32) (firstTokenOffset:26) (offset:32)
          element: <testLibrary>::@class::C
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:32)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
      enums
        #F4 enum E (nameOffset:42) (firstTokenOffset:37) (offset:42)
          element: <testLibrary>::@enum::E
          fields
            #F5 hasInitializer v (nameOffset:46) (firstTokenOffset:46) (offset:46)
              element: <testLibrary>::@enum::E::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element2: <testLibrary>::@enum::E
                      type: E
                    element: <testLibrary>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            #F6 synthetic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:42)
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
          constructors
            #F7 synthetic const new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:42)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F8 synthetic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:46)
              element: <testLibrary>::@enum::E::@getter::v
            #F9 synthetic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:42)
              element: <testLibrary>::@enum::E::@getter::values
      typeAliases
        #F10 F (nameOffset:58) (firstTokenOffset:50) (offset:58)
          element: <testLibrary>::@typeAlias::F
    #F1 package:test/a.dart
      element: <testLibrary>
      enclosingFragment: #F0
      previousFragment: #F0
      topLevelVariables
        #F11 c (nameOffset:13) (firstTokenOffset:13) (offset:13)
          element: <testLibrary>::@topLevelVariable::c
        #F12 e (nameOffset:18) (firstTokenOffset:18) (offset:18)
          element: <testLibrary>::@topLevelVariable::e
        #F13 f (nameOffset:23) (firstTokenOffset:23) (offset:23)
          element: <testLibrary>::@topLevelVariable::f
      getters
        #F14 synthetic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:13)
          element: <testLibrary>::@getter::c
        #F15 synthetic e (nameOffset:<null>) (firstTokenOffset:<null>) (offset:18)
          element: <testLibrary>::@getter::e
        #F16 synthetic f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
          element: <testLibrary>::@getter::f
      setters
        #F17 synthetic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:13)
          element: <testLibrary>::@setter::c
          formalParameters
            #F18 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:13)
              element: <testLibrary>::@setter::c::@formalParameter::value
        #F19 synthetic e (nameOffset:<null>) (firstTokenOffset:<null>) (offset:18)
          element: <testLibrary>::@setter::e
          formalParameters
            #F20 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:18)
              element: <testLibrary>::@setter::e::@formalParameter::value
        #F21 synthetic f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
          element: <testLibrary>::@setter::f
          formalParameters
            #F22 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
              element: <testLibrary>::@setter::f::@formalParameter::value
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F2
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F4
      supertype: Enum
      fields
        static const enumConstant hasInitializer v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F5
          type: E
          constantInitializer
            fragment: #F5
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        synthetic static const values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F6
          type: List<E>
          constantInitializer
            fragment: #F6
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        synthetic const new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F7
      getters
        synthetic static v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F8
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        synthetic static values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F9
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
  typeAliases
    F
      reference: <testLibrary>::@typeAlias::F
      firstFragment: #F10
      aliasedType: dynamic Function()
  topLevelVariables
    c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: #F11
      type: C
      getter: <testLibrary>::@getter::c
      setter: <testLibrary>::@setter::c
    e
      reference: <testLibrary>::@topLevelVariable::e
      firstFragment: #F12
      type: E
      getter: <testLibrary>::@getter::e
      setter: <testLibrary>::@setter::e
    f
      reference: <testLibrary>::@topLevelVariable::f
      firstFragment: #F13
      type: dynamic Function()
        alias: <testLibrary>::@typeAlias::F
      getter: <testLibrary>::@getter::f
      setter: <testLibrary>::@setter::f
  getters
    synthetic static c
      reference: <testLibrary>::@getter::c
      firstFragment: #F14
      returnType: C
      variable: <testLibrary>::@topLevelVariable::c
    synthetic static e
      reference: <testLibrary>::@getter::e
      firstFragment: #F15
      returnType: E
      variable: <testLibrary>::@topLevelVariable::e
    synthetic static f
      reference: <testLibrary>::@getter::f
      firstFragment: #F16
      returnType: dynamic Function()
        alias: <testLibrary>::@typeAlias::F
      variable: <testLibrary>::@topLevelVariable::f
  setters
    synthetic static c
      reference: <testLibrary>::@setter::c
      firstFragment: #F17
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F18
          type: C
      returnType: void
      variable: <testLibrary>::@topLevelVariable::c
    synthetic static e
      reference: <testLibrary>::@setter::e
      firstFragment: #F19
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F20
          type: E
      returnType: void
      variable: <testLibrary>::@topLevelVariable::e
    synthetic static f
      reference: <testLibrary>::@setter::f
      firstFragment: #F21
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
    newFile(
      '$testPackageLibPath/a.dart',
      'part of l; class C {} enum E { v } typedef F();',
    );
    newFile('$testPackageLibPath/b.dart', 'part of l; C c; E e; F f;');
    var library = await buildLibrary(
      'library l; part "a.dart"; part "b.dart";',
    );
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
          partKeywordOffset: 11
          unit: #F1
        part_1
          uri: package:test/b.dart
          partKeywordOffset: 26
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
            #F4 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:17)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
      enums
        #F5 enum E (nameOffset:27) (firstTokenOffset:22) (offset:27)
          element: <testLibrary>::@enum::E
          fields
            #F6 hasInitializer v (nameOffset:31) (firstTokenOffset:31) (offset:31)
              element: <testLibrary>::@enum::E::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element2: <testLibrary>::@enum::E
                      type: E
                    element: <testLibrary>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            #F7 synthetic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:27)
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
          constructors
            #F8 synthetic const new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:27)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F9 synthetic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
              element: <testLibrary>::@enum::E::@getter::v
            #F10 synthetic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:27)
              element: <testLibrary>::@enum::E::@getter::values
      typeAliases
        #F11 F (nameOffset:43) (firstTokenOffset:35) (offset:43)
          element: <testLibrary>::@typeAlias::F
    #F2 package:test/b.dart
      element: <testLibrary>
      enclosingFragment: #F0
      previousFragment: #F1
      topLevelVariables
        #F12 c (nameOffset:13) (firstTokenOffset:13) (offset:13)
          element: <testLibrary>::@topLevelVariable::c
        #F13 e (nameOffset:18) (firstTokenOffset:18) (offset:18)
          element: <testLibrary>::@topLevelVariable::e
        #F14 f (nameOffset:23) (firstTokenOffset:23) (offset:23)
          element: <testLibrary>::@topLevelVariable::f
      getters
        #F15 synthetic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:13)
          element: <testLibrary>::@getter::c
        #F16 synthetic e (nameOffset:<null>) (firstTokenOffset:<null>) (offset:18)
          element: <testLibrary>::@getter::e
        #F17 synthetic f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
          element: <testLibrary>::@getter::f
      setters
        #F18 synthetic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:13)
          element: <testLibrary>::@setter::c
          formalParameters
            #F19 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:13)
              element: <testLibrary>::@setter::c::@formalParameter::value
        #F20 synthetic e (nameOffset:<null>) (firstTokenOffset:<null>) (offset:18)
          element: <testLibrary>::@setter::e
          formalParameters
            #F21 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:18)
              element: <testLibrary>::@setter::e::@formalParameter::value
        #F22 synthetic f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
          element: <testLibrary>::@setter::f
          formalParameters
            #F23 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:23)
              element: <testLibrary>::@setter::f::@formalParameter::value
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F3
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F4
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F5
      supertype: Enum
      fields
        static const enumConstant hasInitializer v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F6
          type: E
          constantInitializer
            fragment: #F6
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        synthetic static const values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F7
          type: List<E>
          constantInitializer
            fragment: #F7
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        synthetic const new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F8
      getters
        synthetic static v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F9
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        synthetic static values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F10
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
  typeAliases
    F
      reference: <testLibrary>::@typeAlias::F
      firstFragment: #F11
      aliasedType: dynamic Function()
  topLevelVariables
    c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: #F12
      type: C
      getter: <testLibrary>::@getter::c
      setter: <testLibrary>::@setter::c
    e
      reference: <testLibrary>::@topLevelVariable::e
      firstFragment: #F13
      type: E
      getter: <testLibrary>::@getter::e
      setter: <testLibrary>::@setter::e
    f
      reference: <testLibrary>::@topLevelVariable::f
      firstFragment: #F14
      type: dynamic Function()
        alias: <testLibrary>::@typeAlias::F
      getter: <testLibrary>::@getter::f
      setter: <testLibrary>::@setter::f
  getters
    synthetic static c
      reference: <testLibrary>::@getter::c
      firstFragment: #F15
      returnType: C
      variable: <testLibrary>::@topLevelVariable::c
    synthetic static e
      reference: <testLibrary>::@getter::e
      firstFragment: #F16
      returnType: E
      variable: <testLibrary>::@topLevelVariable::e
    synthetic static f
      reference: <testLibrary>::@getter::f
      firstFragment: #F17
      returnType: dynamic Function()
        alias: <testLibrary>::@typeAlias::F
      variable: <testLibrary>::@topLevelVariable::f
  setters
    synthetic static c
      reference: <testLibrary>::@setter::c
      firstFragment: #F18
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F19
          type: C
      returnType: void
      variable: <testLibrary>::@topLevelVariable::c
    synthetic static e
      reference: <testLibrary>::@setter::e
      firstFragment: #F20
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F21
          type: E
      returnType: void
      variable: <testLibrary>::@topLevelVariable::e
    synthetic static f
      reference: <testLibrary>::@setter::f
      firstFragment: #F22
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
    newFile(
      '$testPackageLibPath/a.dart',
      'part of l; class C {} enum E { v } typedef F(); C c; E e; F f;',
    );
    var library = await buildLibrary('library l; part "a.dart";');
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
          partKeywordOffset: 11
          unit: #F1
    #F1 package:test/a.dart
      element: <testLibrary>
      enclosingFragment: #F0
      previousFragment: #F0
      classes
        #F2 class C (nameOffset:17) (firstTokenOffset:11) (offset:17)
          element: <testLibrary>::@class::C
          constructors
            #F3 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:17)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
      enums
        #F4 enum E (nameOffset:27) (firstTokenOffset:22) (offset:27)
          element: <testLibrary>::@enum::E
          fields
            #F5 hasInitializer v (nameOffset:31) (firstTokenOffset:31) (offset:31)
              element: <testLibrary>::@enum::E::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element2: <testLibrary>::@enum::E
                      type: E
                    element: <testLibrary>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            #F6 synthetic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:27)
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
          constructors
            #F7 synthetic const new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:27)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F8 synthetic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
              element: <testLibrary>::@enum::E::@getter::v
            #F9 synthetic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:27)
              element: <testLibrary>::@enum::E::@getter::values
      typeAliases
        #F10 F (nameOffset:43) (firstTokenOffset:35) (offset:43)
          element: <testLibrary>::@typeAlias::F
      topLevelVariables
        #F11 c (nameOffset:50) (firstTokenOffset:50) (offset:50)
          element: <testLibrary>::@topLevelVariable::c
        #F12 e (nameOffset:55) (firstTokenOffset:55) (offset:55)
          element: <testLibrary>::@topLevelVariable::e
        #F13 f (nameOffset:60) (firstTokenOffset:60) (offset:60)
          element: <testLibrary>::@topLevelVariable::f
      getters
        #F14 synthetic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:50)
          element: <testLibrary>::@getter::c
        #F15 synthetic e (nameOffset:<null>) (firstTokenOffset:<null>) (offset:55)
          element: <testLibrary>::@getter::e
        #F16 synthetic f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:60)
          element: <testLibrary>::@getter::f
      setters
        #F17 synthetic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:50)
          element: <testLibrary>::@setter::c
          formalParameters
            #F18 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:50)
              element: <testLibrary>::@setter::c::@formalParameter::value
        #F19 synthetic e (nameOffset:<null>) (firstTokenOffset:<null>) (offset:55)
          element: <testLibrary>::@setter::e
          formalParameters
            #F20 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:55)
              element: <testLibrary>::@setter::e::@formalParameter::value
        #F21 synthetic f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:60)
          element: <testLibrary>::@setter::f
          formalParameters
            #F22 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:60)
              element: <testLibrary>::@setter::f::@formalParameter::value
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F2
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F3
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F4
      supertype: Enum
      fields
        static const enumConstant hasInitializer v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F5
          type: E
          constantInitializer
            fragment: #F5
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        synthetic static const values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F6
          type: List<E>
          constantInitializer
            fragment: #F6
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        synthetic const new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F7
      getters
        synthetic static v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F8
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        synthetic static values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F9
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
  typeAliases
    F
      reference: <testLibrary>::@typeAlias::F
      firstFragment: #F10
      aliasedType: dynamic Function()
  topLevelVariables
    c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: #F11
      type: C
      getter: <testLibrary>::@getter::c
      setter: <testLibrary>::@setter::c
    e
      reference: <testLibrary>::@topLevelVariable::e
      firstFragment: #F12
      type: E
      getter: <testLibrary>::@getter::e
      setter: <testLibrary>::@setter::e
    f
      reference: <testLibrary>::@topLevelVariable::f
      firstFragment: #F13
      type: dynamic Function()
        alias: <testLibrary>::@typeAlias::F
      getter: <testLibrary>::@getter::f
      setter: <testLibrary>::@setter::f
  getters
    synthetic static c
      reference: <testLibrary>::@getter::c
      firstFragment: #F14
      returnType: C
      variable: <testLibrary>::@topLevelVariable::c
    synthetic static e
      reference: <testLibrary>::@getter::e
      firstFragment: #F15
      returnType: E
      variable: <testLibrary>::@topLevelVariable::e
    synthetic static f
      reference: <testLibrary>::@getter::f
      firstFragment: #F16
      returnType: dynamic Function()
        alias: <testLibrary>::@typeAlias::F
      variable: <testLibrary>::@topLevelVariable::f
  setters
    synthetic static c
      reference: <testLibrary>::@setter::c
      firstFragment: #F17
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F18
          type: C
      returnType: void
      variable: <testLibrary>::@topLevelVariable::c
    synthetic static e
      reference: <testLibrary>::@setter::e
      firstFragment: #F19
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F20
          type: E
      returnType: void
      variable: <testLibrary>::@topLevelVariable::e
    synthetic static f
      reference: <testLibrary>::@setter::f
      firstFragment: #F21
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
    var library = await buildLibrary('class C {} C c;');
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
      topLevelVariables
        #F3 c (nameOffset:13) (firstTokenOffset:13) (offset:13)
          element: <testLibrary>::@topLevelVariable::c
      getters
        #F4 synthetic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:13)
          element: <testLibrary>::@getter::c
      setters
        #F5 synthetic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:13)
          element: <testLibrary>::@setter::c
          formalParameters
            #F6 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:13)
              element: <testLibrary>::@setter::c::@formalParameter::value
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F2
  topLevelVariables
    c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: #F3
      type: C
      getter: <testLibrary>::@getter::c
      setter: <testLibrary>::@setter::c
  getters
    synthetic static c
      reference: <testLibrary>::@getter::c
      firstFragment: #F4
      returnType: C
      variable: <testLibrary>::@topLevelVariable::c
  setters
    synthetic static c
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
    var library = await buildLibrary('class C<T, U> {} C<int, String> c;');
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
            #F4 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
      topLevelVariables
        #F5 c (nameOffset:32) (firstTokenOffset:32) (offset:32)
          element: <testLibrary>::@topLevelVariable::c
      getters
        #F6 synthetic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:32)
          element: <testLibrary>::@getter::c
      setters
        #F7 synthetic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:32)
          element: <testLibrary>::@setter::c
          formalParameters
            #F8 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:32)
              element: <testLibrary>::@setter::c::@formalParameter::value
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
        #E1 U
          firstFragment: #F3
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F4
  topLevelVariables
    c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: #F5
      type: C<int, String>
      getter: <testLibrary>::@getter::c
      setter: <testLibrary>::@setter::c
  getters
    synthetic static c
      reference: <testLibrary>::@getter::c
      firstFragment: #F6
      returnType: C<int, String>
      variable: <testLibrary>::@topLevelVariable::c
  setters
    synthetic static c
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
    var library = await buildLibrary('class C<T, U> {} C c;');
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
            #F4 synthetic new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:6)
              element: <testLibrary>::@class::C::@constructor::new
              typeName: C
      topLevelVariables
        #F5 c (nameOffset:19) (firstTokenOffset:19) (offset:19)
          element: <testLibrary>::@topLevelVariable::c
      getters
        #F6 synthetic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:19)
          element: <testLibrary>::@getter::c
      setters
        #F7 synthetic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:19)
          element: <testLibrary>::@setter::c
          formalParameters
            #F8 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:19)
              element: <testLibrary>::@setter::c::@formalParameter::value
  classes
    class C
      reference: <testLibrary>::@class::C
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
        #E1 U
          firstFragment: #F3
      constructors
        synthetic new
          reference: <testLibrary>::@class::C::@constructor::new
          firstFragment: #F4
  topLevelVariables
    c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: #F5
      type: C<dynamic, dynamic>
      getter: <testLibrary>::@getter::c
      setter: <testLibrary>::@setter::c
  getters
    synthetic static c
      reference: <testLibrary>::@getter::c
      firstFragment: #F6
      returnType: C<dynamic, dynamic>
      variable: <testLibrary>::@topLevelVariable::c
  setters
    synthetic static c
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
    var library = await buildLibrary('enum E { v } E e;');
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
            #F2 hasInitializer v (nameOffset:9) (firstTokenOffset:9) (offset:9)
              element: <testLibrary>::@enum::E::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element2: <testLibrary>::@enum::E
                      type: E
                    element: <testLibrary>::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            #F3 synthetic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
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
          constructors
            #F4 synthetic const new (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@constructor::new
              typeName: E
          getters
            #F5 synthetic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:9)
              element: <testLibrary>::@enum::E::@getter::v
            #F6 synthetic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:5)
              element: <testLibrary>::@enum::E::@getter::values
      topLevelVariables
        #F7 e (nameOffset:15) (firstTokenOffset:15) (offset:15)
          element: <testLibrary>::@topLevelVariable::e
      getters
        #F8 synthetic e (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
          element: <testLibrary>::@getter::e
      setters
        #F9 synthetic e (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
          element: <testLibrary>::@setter::e
          formalParameters
            #F10 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@setter::e::@formalParameter::value
  enums
    enum E
      reference: <testLibrary>::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasInitializer v
          reference: <testLibrary>::@enum::E::@field::v
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: <testLibrary>::@enum::E::@getter::v
        synthetic static const values
          reference: <testLibrary>::@enum::E::@field::values
          firstFragment: #F3
          type: List<E>
          constantInitializer
            fragment: #F3
            expression: expression_1
          getter: <testLibrary>::@enum::E::@getter::values
      constructors
        synthetic const new
          reference: <testLibrary>::@enum::E::@constructor::new
          firstFragment: #F4
      getters
        synthetic static v
          reference: <testLibrary>::@enum::E::@getter::v
          firstFragment: #F5
          returnType: E
          variable: <testLibrary>::@enum::E::@field::v
        synthetic static values
          reference: <testLibrary>::@enum::E::@getter::values
          firstFragment: #F6
          returnType: List<E>
          variable: <testLibrary>::@enum::E::@field::values
  topLevelVariables
    e
      reference: <testLibrary>::@topLevelVariable::e
      firstFragment: #F7
      type: E
      getter: <testLibrary>::@getter::e
      setter: <testLibrary>::@setter::e
  getters
    synthetic static e
      reference: <testLibrary>::@getter::e
      firstFragment: #F8
      returnType: E
      variable: <testLibrary>::@topLevelVariable::e
  setters
    synthetic static e
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
    newFile(
      '$testPackageLibPath/a.dart',
      'class C {} enum E { v } typedef F();',
    );
    var library = await buildLibrary('import "a.dart"; C c; E e; F f;');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart
      topLevelVariables
        #F1 c (nameOffset:19) (firstTokenOffset:19) (offset:19)
          element: <testLibrary>::@topLevelVariable::c
        #F2 e (nameOffset:24) (firstTokenOffset:24) (offset:24)
          element: <testLibrary>::@topLevelVariable::e
        #F3 f (nameOffset:29) (firstTokenOffset:29) (offset:29)
          element: <testLibrary>::@topLevelVariable::f
      getters
        #F4 synthetic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:19)
          element: <testLibrary>::@getter::c
        #F5 synthetic e (nameOffset:<null>) (firstTokenOffset:<null>) (offset:24)
          element: <testLibrary>::@getter::e
        #F6 synthetic f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:29)
          element: <testLibrary>::@getter::f
      setters
        #F7 synthetic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:19)
          element: <testLibrary>::@setter::c
          formalParameters
            #F8 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:19)
              element: <testLibrary>::@setter::c::@formalParameter::value
        #F9 synthetic e (nameOffset:<null>) (firstTokenOffset:<null>) (offset:24)
          element: <testLibrary>::@setter::e
          formalParameters
            #F10 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:24)
              element: <testLibrary>::@setter::e::@formalParameter::value
        #F11 synthetic f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:29)
          element: <testLibrary>::@setter::f
          formalParameters
            #F12 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:29)
              element: <testLibrary>::@setter::f::@formalParameter::value
  topLevelVariables
    c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: #F1
      type: C
      getter: <testLibrary>::@getter::c
      setter: <testLibrary>::@setter::c
    e
      reference: <testLibrary>::@topLevelVariable::e
      firstFragment: #F2
      type: E
      getter: <testLibrary>::@getter::e
      setter: <testLibrary>::@setter::e
    f
      reference: <testLibrary>::@topLevelVariable::f
      firstFragment: #F3
      type: dynamic Function()
        alias: package:test/a.dart::@typeAlias::F
      getter: <testLibrary>::@getter::f
      setter: <testLibrary>::@setter::f
  getters
    synthetic static c
      reference: <testLibrary>::@getter::c
      firstFragment: #F4
      returnType: C
      variable: <testLibrary>::@topLevelVariable::c
    synthetic static e
      reference: <testLibrary>::@getter::e
      firstFragment: #F5
      returnType: E
      variable: <testLibrary>::@topLevelVariable::e
    synthetic static f
      reference: <testLibrary>::@getter::f
      firstFragment: #F6
      returnType: dynamic Function()
        alias: package:test/a.dart::@typeAlias::F
      variable: <testLibrary>::@topLevelVariable::f
  setters
    synthetic static c
      reference: <testLibrary>::@setter::c
      firstFragment: #F7
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F8
          type: C
      returnType: void
      variable: <testLibrary>::@topLevelVariable::c
    synthetic static e
      reference: <testLibrary>::@setter::e
      firstFragment: #F9
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F10
          type: E
      returnType: void
      variable: <testLibrary>::@topLevelVariable::e
    synthetic static f
      reference: <testLibrary>::@setter::f
      firstFragment: #F11
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
    newFile('$testPackageLibPath/a.dart', 'export "b.dart";');
    newFile(
      '$testPackageLibPath/b.dart',
      'class C {} enum E { v } typedef F();',
    );
    var library = await buildLibrary('import "a.dart"; C c; E e; F f;');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart
      topLevelVariables
        #F1 c (nameOffset:19) (firstTokenOffset:19) (offset:19)
          element: <testLibrary>::@topLevelVariable::c
        #F2 e (nameOffset:24) (firstTokenOffset:24) (offset:24)
          element: <testLibrary>::@topLevelVariable::e
        #F3 f (nameOffset:29) (firstTokenOffset:29) (offset:29)
          element: <testLibrary>::@topLevelVariable::f
      getters
        #F4 synthetic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:19)
          element: <testLibrary>::@getter::c
        #F5 synthetic e (nameOffset:<null>) (firstTokenOffset:<null>) (offset:24)
          element: <testLibrary>::@getter::e
        #F6 synthetic f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:29)
          element: <testLibrary>::@getter::f
      setters
        #F7 synthetic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:19)
          element: <testLibrary>::@setter::c
          formalParameters
            #F8 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:19)
              element: <testLibrary>::@setter::c::@formalParameter::value
        #F9 synthetic e (nameOffset:<null>) (firstTokenOffset:<null>) (offset:24)
          element: <testLibrary>::@setter::e
          formalParameters
            #F10 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:24)
              element: <testLibrary>::@setter::e::@formalParameter::value
        #F11 synthetic f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:29)
          element: <testLibrary>::@setter::f
          formalParameters
            #F12 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:29)
              element: <testLibrary>::@setter::f::@formalParameter::value
  topLevelVariables
    c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: #F1
      type: C
      getter: <testLibrary>::@getter::c
      setter: <testLibrary>::@setter::c
    e
      reference: <testLibrary>::@topLevelVariable::e
      firstFragment: #F2
      type: E
      getter: <testLibrary>::@getter::e
      setter: <testLibrary>::@setter::e
    f
      reference: <testLibrary>::@topLevelVariable::f
      firstFragment: #F3
      type: dynamic Function()
        alias: package:test/b.dart::@typeAlias::F
      getter: <testLibrary>::@getter::f
      setter: <testLibrary>::@setter::f
  getters
    synthetic static c
      reference: <testLibrary>::@getter::c
      firstFragment: #F4
      returnType: C
      variable: <testLibrary>::@topLevelVariable::c
    synthetic static e
      reference: <testLibrary>::@getter::e
      firstFragment: #F5
      returnType: E
      variable: <testLibrary>::@topLevelVariable::e
    synthetic static f
      reference: <testLibrary>::@getter::f
      firstFragment: #F6
      returnType: dynamic Function()
        alias: package:test/b.dart::@typeAlias::F
      variable: <testLibrary>::@topLevelVariable::f
  setters
    synthetic static c
      reference: <testLibrary>::@setter::c
      firstFragment: #F7
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F8
          type: C
      returnType: void
      variable: <testLibrary>::@topLevelVariable::c
    synthetic static e
      reference: <testLibrary>::@setter::e
      firstFragment: #F9
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F10
          type: E
      returnType: void
      variable: <testLibrary>::@topLevelVariable::e
    synthetic static f
      reference: <testLibrary>::@setter::f
      firstFragment: #F11
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
    newFile('$testPackageLibPath/a.dart', 'export "b.dart";');
    newFile('$testPackageLibPath/b.dart', 'export "c.dart";');
    newFile(
      '$testPackageLibPath/c.dart',
      'class C {} enum E { v } typedef F();',
    );
    var library = await buildLibrary('import "a.dart"; C c; E e; F f;');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart
      topLevelVariables
        #F1 c (nameOffset:19) (firstTokenOffset:19) (offset:19)
          element: <testLibrary>::@topLevelVariable::c
        #F2 e (nameOffset:24) (firstTokenOffset:24) (offset:24)
          element: <testLibrary>::@topLevelVariable::e
        #F3 f (nameOffset:29) (firstTokenOffset:29) (offset:29)
          element: <testLibrary>::@topLevelVariable::f
      getters
        #F4 synthetic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:19)
          element: <testLibrary>::@getter::c
        #F5 synthetic e (nameOffset:<null>) (firstTokenOffset:<null>) (offset:24)
          element: <testLibrary>::@getter::e
        #F6 synthetic f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:29)
          element: <testLibrary>::@getter::f
      setters
        #F7 synthetic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:19)
          element: <testLibrary>::@setter::c
          formalParameters
            #F8 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:19)
              element: <testLibrary>::@setter::c::@formalParameter::value
        #F9 synthetic e (nameOffset:<null>) (firstTokenOffset:<null>) (offset:24)
          element: <testLibrary>::@setter::e
          formalParameters
            #F10 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:24)
              element: <testLibrary>::@setter::e::@formalParameter::value
        #F11 synthetic f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:29)
          element: <testLibrary>::@setter::f
          formalParameters
            #F12 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:29)
              element: <testLibrary>::@setter::f::@formalParameter::value
  topLevelVariables
    c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: #F1
      type: C
      getter: <testLibrary>::@getter::c
      setter: <testLibrary>::@setter::c
    e
      reference: <testLibrary>::@topLevelVariable::e
      firstFragment: #F2
      type: E
      getter: <testLibrary>::@getter::e
      setter: <testLibrary>::@setter::e
    f
      reference: <testLibrary>::@topLevelVariable::f
      firstFragment: #F3
      type: dynamic Function()
        alias: package:test/c.dart::@typeAlias::F
      getter: <testLibrary>::@getter::f
      setter: <testLibrary>::@setter::f
  getters
    synthetic static c
      reference: <testLibrary>::@getter::c
      firstFragment: #F4
      returnType: C
      variable: <testLibrary>::@topLevelVariable::c
    synthetic static e
      reference: <testLibrary>::@getter::e
      firstFragment: #F5
      returnType: E
      variable: <testLibrary>::@topLevelVariable::e
    synthetic static f
      reference: <testLibrary>::@getter::f
      firstFragment: #F6
      returnType: dynamic Function()
        alias: package:test/c.dart::@typeAlias::F
      variable: <testLibrary>::@topLevelVariable::f
  setters
    synthetic static c
      reference: <testLibrary>::@setter::c
      firstFragment: #F7
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F8
          type: C
      returnType: void
      variable: <testLibrary>::@topLevelVariable::c
    synthetic static e
      reference: <testLibrary>::@setter::e
      firstFragment: #F9
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F10
          type: E
      returnType: void
      variable: <testLibrary>::@topLevelVariable::e
    synthetic static f
      reference: <testLibrary>::@setter::f
      firstFragment: #F11
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
    newFile('$testPackageLibPath/a/a.dart', 'export "b/b.dart";');
    newFile('$testPackageLibPath/a/b/b.dart', 'export "../c/c.dart";');
    newFile(
      '$testPackageLibPath/a/c/c.dart',
      'class C {} enum E { v } typedef F();',
    );
    var library = await buildLibrary('import "a/a.dart"; C c; E e; F f;');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a/a.dart
      topLevelVariables
        #F1 c (nameOffset:21) (firstTokenOffset:21) (offset:21)
          element: <testLibrary>::@topLevelVariable::c
        #F2 e (nameOffset:26) (firstTokenOffset:26) (offset:26)
          element: <testLibrary>::@topLevelVariable::e
        #F3 f (nameOffset:31) (firstTokenOffset:31) (offset:31)
          element: <testLibrary>::@topLevelVariable::f
      getters
        #F4 synthetic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
          element: <testLibrary>::@getter::c
        #F5 synthetic e (nameOffset:<null>) (firstTokenOffset:<null>) (offset:26)
          element: <testLibrary>::@getter::e
        #F6 synthetic f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
          element: <testLibrary>::@getter::f
      setters
        #F7 synthetic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
          element: <testLibrary>::@setter::c
          formalParameters
            #F8 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@setter::c::@formalParameter::value
        #F9 synthetic e (nameOffset:<null>) (firstTokenOffset:<null>) (offset:26)
          element: <testLibrary>::@setter::e
          formalParameters
            #F10 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:26)
              element: <testLibrary>::@setter::e::@formalParameter::value
        #F11 synthetic f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
          element: <testLibrary>::@setter::f
          formalParameters
            #F12 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
              element: <testLibrary>::@setter::f::@formalParameter::value
  topLevelVariables
    c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: #F1
      type: C
      getter: <testLibrary>::@getter::c
      setter: <testLibrary>::@setter::c
    e
      reference: <testLibrary>::@topLevelVariable::e
      firstFragment: #F2
      type: E
      getter: <testLibrary>::@getter::e
      setter: <testLibrary>::@setter::e
    f
      reference: <testLibrary>::@topLevelVariable::f
      firstFragment: #F3
      type: dynamic Function()
        alias: package:test/a/c/c.dart::@typeAlias::F
      getter: <testLibrary>::@getter::f
      setter: <testLibrary>::@setter::f
  getters
    synthetic static c
      reference: <testLibrary>::@getter::c
      firstFragment: #F4
      returnType: C
      variable: <testLibrary>::@topLevelVariable::c
    synthetic static e
      reference: <testLibrary>::@getter::e
      firstFragment: #F5
      returnType: E
      variable: <testLibrary>::@topLevelVariable::e
    synthetic static f
      reference: <testLibrary>::@getter::f
      firstFragment: #F6
      returnType: dynamic Function()
        alias: package:test/a/c/c.dart::@typeAlias::F
      variable: <testLibrary>::@topLevelVariable::f
  setters
    synthetic static c
      reference: <testLibrary>::@setter::c
      firstFragment: #F7
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F8
          type: C
      returnType: void
      variable: <testLibrary>::@topLevelVariable::c
    synthetic static e
      reference: <testLibrary>::@setter::e
      firstFragment: #F9
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F10
          type: E
      returnType: void
      variable: <testLibrary>::@topLevelVariable::e
    synthetic static f
      reference: <testLibrary>::@setter::f
      firstFragment: #F11
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
    newFile('$testPackageLibPath/a/a.dart', 'export "b/b.dart";');
    newFile(
      '$testPackageLibPath/a/b/b.dart',
      'class C {} enum E { v } typedef F();',
    );
    var library = await buildLibrary('import "a/a.dart"; C c; E e; F f;');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a/a.dart
      topLevelVariables
        #F1 c (nameOffset:21) (firstTokenOffset:21) (offset:21)
          element: <testLibrary>::@topLevelVariable::c
        #F2 e (nameOffset:26) (firstTokenOffset:26) (offset:26)
          element: <testLibrary>::@topLevelVariable::e
        #F3 f (nameOffset:31) (firstTokenOffset:31) (offset:31)
          element: <testLibrary>::@topLevelVariable::f
      getters
        #F4 synthetic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
          element: <testLibrary>::@getter::c
        #F5 synthetic e (nameOffset:<null>) (firstTokenOffset:<null>) (offset:26)
          element: <testLibrary>::@getter::e
        #F6 synthetic f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
          element: <testLibrary>::@getter::f
      setters
        #F7 synthetic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
          element: <testLibrary>::@setter::c
          formalParameters
            #F8 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@setter::c::@formalParameter::value
        #F9 synthetic e (nameOffset:<null>) (firstTokenOffset:<null>) (offset:26)
          element: <testLibrary>::@setter::e
          formalParameters
            #F10 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:26)
              element: <testLibrary>::@setter::e::@formalParameter::value
        #F11 synthetic f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
          element: <testLibrary>::@setter::f
          formalParameters
            #F12 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
              element: <testLibrary>::@setter::f::@formalParameter::value
  topLevelVariables
    c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: #F1
      type: C
      getter: <testLibrary>::@getter::c
      setter: <testLibrary>::@setter::c
    e
      reference: <testLibrary>::@topLevelVariable::e
      firstFragment: #F2
      type: E
      getter: <testLibrary>::@getter::e
      setter: <testLibrary>::@setter::e
    f
      reference: <testLibrary>::@topLevelVariable::f
      firstFragment: #F3
      type: dynamic Function()
        alias: package:test/a/b/b.dart::@typeAlias::F
      getter: <testLibrary>::@getter::f
      setter: <testLibrary>::@setter::f
  getters
    synthetic static c
      reference: <testLibrary>::@getter::c
      firstFragment: #F4
      returnType: C
      variable: <testLibrary>::@topLevelVariable::c
    synthetic static e
      reference: <testLibrary>::@getter::e
      firstFragment: #F5
      returnType: E
      variable: <testLibrary>::@topLevelVariable::e
    synthetic static f
      reference: <testLibrary>::@getter::f
      firstFragment: #F6
      returnType: dynamic Function()
        alias: package:test/a/b/b.dart::@typeAlias::F
      variable: <testLibrary>::@topLevelVariable::f
  setters
    synthetic static c
      reference: <testLibrary>::@setter::c
      firstFragment: #F7
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F8
          type: C
      returnType: void
      variable: <testLibrary>::@topLevelVariable::c
    synthetic static e
      reference: <testLibrary>::@setter::e
      firstFragment: #F9
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F10
          type: E
      returnType: void
      variable: <testLibrary>::@topLevelVariable::e
    synthetic static f
      reference: <testLibrary>::@setter::f
      firstFragment: #F11
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
    newFile('$testPackageLibPath/a.dart', 'library l; part "b.dart";');
    newFile(
      '$testPackageLibPath/b.dart',
      'part of l; class C {} enum E { v } typedef F();',
    );
    var library = await buildLibrary('import "a.dart"; C c; E e; F f;');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart
      topLevelVariables
        #F1 c (nameOffset:19) (firstTokenOffset:19) (offset:19)
          element: <testLibrary>::@topLevelVariable::c
        #F2 e (nameOffset:24) (firstTokenOffset:24) (offset:24)
          element: <testLibrary>::@topLevelVariable::e
        #F3 f (nameOffset:29) (firstTokenOffset:29) (offset:29)
          element: <testLibrary>::@topLevelVariable::f
      getters
        #F4 synthetic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:19)
          element: <testLibrary>::@getter::c
        #F5 synthetic e (nameOffset:<null>) (firstTokenOffset:<null>) (offset:24)
          element: <testLibrary>::@getter::e
        #F6 synthetic f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:29)
          element: <testLibrary>::@getter::f
      setters
        #F7 synthetic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:19)
          element: <testLibrary>::@setter::c
          formalParameters
            #F8 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:19)
              element: <testLibrary>::@setter::c::@formalParameter::value
        #F9 synthetic e (nameOffset:<null>) (firstTokenOffset:<null>) (offset:24)
          element: <testLibrary>::@setter::e
          formalParameters
            #F10 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:24)
              element: <testLibrary>::@setter::e::@formalParameter::value
        #F11 synthetic f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:29)
          element: <testLibrary>::@setter::f
          formalParameters
            #F12 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:29)
              element: <testLibrary>::@setter::f::@formalParameter::value
  topLevelVariables
    c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: #F1
      type: C
      getter: <testLibrary>::@getter::c
      setter: <testLibrary>::@setter::c
    e
      reference: <testLibrary>::@topLevelVariable::e
      firstFragment: #F2
      type: E
      getter: <testLibrary>::@getter::e
      setter: <testLibrary>::@setter::e
    f
      reference: <testLibrary>::@topLevelVariable::f
      firstFragment: #F3
      type: dynamic Function()
        alias: package:test/a.dart::@typeAlias::F
      getter: <testLibrary>::@getter::f
      setter: <testLibrary>::@setter::f
  getters
    synthetic static c
      reference: <testLibrary>::@getter::c
      firstFragment: #F4
      returnType: C
      variable: <testLibrary>::@topLevelVariable::c
    synthetic static e
      reference: <testLibrary>::@getter::e
      firstFragment: #F5
      returnType: E
      variable: <testLibrary>::@topLevelVariable::e
    synthetic static f
      reference: <testLibrary>::@getter::f
      firstFragment: #F6
      returnType: dynamic Function()
        alias: package:test/a.dart::@typeAlias::F
      variable: <testLibrary>::@topLevelVariable::f
  setters
    synthetic static c
      reference: <testLibrary>::@setter::c
      firstFragment: #F7
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F8
          type: C
      returnType: void
      variable: <testLibrary>::@topLevelVariable::c
    synthetic static e
      reference: <testLibrary>::@setter::e
      firstFragment: #F9
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F10
          type: E
      returnType: void
      variable: <testLibrary>::@topLevelVariable::e
    synthetic static f
      reference: <testLibrary>::@setter::f
      firstFragment: #F11
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
    newFile(
      '$testPackageLibPath/a.dart',
      'library l; part "p1.dart"; part "p2.dart";',
    );
    newFile('$testPackageLibPath/p1.dart', 'part of l; class C1 {}');
    newFile('$testPackageLibPath/p2.dart', 'part of l; class C2 {}');
    var library = await buildLibrary('import "a.dart"; C1 c1; C2 c2;');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart
      topLevelVariables
        #F1 c1 (nameOffset:20) (firstTokenOffset:20) (offset:20)
          element: <testLibrary>::@topLevelVariable::c1
        #F2 c2 (nameOffset:27) (firstTokenOffset:27) (offset:27)
          element: <testLibrary>::@topLevelVariable::c2
      getters
        #F3 synthetic c1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:20)
          element: <testLibrary>::@getter::c1
        #F4 synthetic c2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:27)
          element: <testLibrary>::@getter::c2
      setters
        #F5 synthetic c1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:20)
          element: <testLibrary>::@setter::c1
          formalParameters
            #F6 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:20)
              element: <testLibrary>::@setter::c1::@formalParameter::value
        #F7 synthetic c2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:27)
          element: <testLibrary>::@setter::c2
          formalParameters
            #F8 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:27)
              element: <testLibrary>::@setter::c2::@formalParameter::value
  topLevelVariables
    c1
      reference: <testLibrary>::@topLevelVariable::c1
      firstFragment: #F1
      type: C1
      getter: <testLibrary>::@getter::c1
      setter: <testLibrary>::@setter::c1
    c2
      reference: <testLibrary>::@topLevelVariable::c2
      firstFragment: #F2
      type: C2
      getter: <testLibrary>::@getter::c2
      setter: <testLibrary>::@setter::c2
  getters
    synthetic static c1
      reference: <testLibrary>::@getter::c1
      firstFragment: #F3
      returnType: C1
      variable: <testLibrary>::@topLevelVariable::c1
    synthetic static c2
      reference: <testLibrary>::@getter::c2
      firstFragment: #F4
      returnType: C2
      variable: <testLibrary>::@topLevelVariable::c2
  setters
    synthetic static c1
      reference: <testLibrary>::@setter::c1
      firstFragment: #F5
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F6
          type: C1
      returnType: void
      variable: <testLibrary>::@topLevelVariable::c1
    synthetic static c2
      reference: <testLibrary>::@setter::c2
      firstFragment: #F7
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F8
          type: C2
      returnType: void
      variable: <testLibrary>::@topLevelVariable::c2
''');
  }

  test_type_reference_to_import_part_in_subdir() async {
    newFile('$testPackageLibPath/a/b.dart', 'library l; part "c.dart";');
    newFile(
      '$testPackageLibPath/a/c.dart',
      'part of l; class C {} enum E { v } typedef F();',
    );
    var library = await buildLibrary('import "a/b.dart"; C c; E e; F f;');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a/b.dart
      topLevelVariables
        #F1 c (nameOffset:21) (firstTokenOffset:21) (offset:21)
          element: <testLibrary>::@topLevelVariable::c
        #F2 e (nameOffset:26) (firstTokenOffset:26) (offset:26)
          element: <testLibrary>::@topLevelVariable::e
        #F3 f (nameOffset:31) (firstTokenOffset:31) (offset:31)
          element: <testLibrary>::@topLevelVariable::f
      getters
        #F4 synthetic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
          element: <testLibrary>::@getter::c
        #F5 synthetic e (nameOffset:<null>) (firstTokenOffset:<null>) (offset:26)
          element: <testLibrary>::@getter::e
        #F6 synthetic f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
          element: <testLibrary>::@getter::f
      setters
        #F7 synthetic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
          element: <testLibrary>::@setter::c
          formalParameters
            #F8 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:21)
              element: <testLibrary>::@setter::c::@formalParameter::value
        #F9 synthetic e (nameOffset:<null>) (firstTokenOffset:<null>) (offset:26)
          element: <testLibrary>::@setter::e
          formalParameters
            #F10 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:26)
              element: <testLibrary>::@setter::e::@formalParameter::value
        #F11 synthetic f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
          element: <testLibrary>::@setter::f
          formalParameters
            #F12 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
              element: <testLibrary>::@setter::f::@formalParameter::value
  topLevelVariables
    c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: #F1
      type: C
      getter: <testLibrary>::@getter::c
      setter: <testLibrary>::@setter::c
    e
      reference: <testLibrary>::@topLevelVariable::e
      firstFragment: #F2
      type: E
      getter: <testLibrary>::@getter::e
      setter: <testLibrary>::@setter::e
    f
      reference: <testLibrary>::@topLevelVariable::f
      firstFragment: #F3
      type: dynamic Function()
        alias: package:test/a/b.dart::@typeAlias::F
      getter: <testLibrary>::@getter::f
      setter: <testLibrary>::@setter::f
  getters
    synthetic static c
      reference: <testLibrary>::@getter::c
      firstFragment: #F4
      returnType: C
      variable: <testLibrary>::@topLevelVariable::c
    synthetic static e
      reference: <testLibrary>::@getter::e
      firstFragment: #F5
      returnType: E
      variable: <testLibrary>::@topLevelVariable::e
    synthetic static f
      reference: <testLibrary>::@getter::f
      firstFragment: #F6
      returnType: dynamic Function()
        alias: package:test/a/b.dart::@typeAlias::F
      variable: <testLibrary>::@topLevelVariable::f
  setters
    synthetic static c
      reference: <testLibrary>::@setter::c
      firstFragment: #F7
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F8
          type: C
      returnType: void
      variable: <testLibrary>::@topLevelVariable::c
    synthetic static e
      reference: <testLibrary>::@setter::e
      firstFragment: #F9
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F10
          type: E
      returnType: void
      variable: <testLibrary>::@topLevelVariable::e
    synthetic static f
      reference: <testLibrary>::@setter::f
      firstFragment: #F11
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
    newFile(
      '$testPackageLibPath/a.dart',
      'class C {} enum E { v } typedef F();',
    );
    var library = await buildLibrary('import "a.dart"; C c; E e; F f;');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  fragments
    #F0 <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart
      topLevelVariables
        #F1 c (nameOffset:19) (firstTokenOffset:19) (offset:19)
          element: <testLibrary>::@topLevelVariable::c
        #F2 e (nameOffset:24) (firstTokenOffset:24) (offset:24)
          element: <testLibrary>::@topLevelVariable::e
        #F3 f (nameOffset:29) (firstTokenOffset:29) (offset:29)
          element: <testLibrary>::@topLevelVariable::f
      getters
        #F4 synthetic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:19)
          element: <testLibrary>::@getter::c
        #F5 synthetic e (nameOffset:<null>) (firstTokenOffset:<null>) (offset:24)
          element: <testLibrary>::@getter::e
        #F6 synthetic f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:29)
          element: <testLibrary>::@getter::f
      setters
        #F7 synthetic c (nameOffset:<null>) (firstTokenOffset:<null>) (offset:19)
          element: <testLibrary>::@setter::c
          formalParameters
            #F8 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:19)
              element: <testLibrary>::@setter::c::@formalParameter::value
        #F9 synthetic e (nameOffset:<null>) (firstTokenOffset:<null>) (offset:24)
          element: <testLibrary>::@setter::e
          formalParameters
            #F10 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:24)
              element: <testLibrary>::@setter::e::@formalParameter::value
        #F11 synthetic f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:29)
          element: <testLibrary>::@setter::f
          formalParameters
            #F12 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:29)
              element: <testLibrary>::@setter::f::@formalParameter::value
  topLevelVariables
    c
      reference: <testLibrary>::@topLevelVariable::c
      firstFragment: #F1
      type: C
      getter: <testLibrary>::@getter::c
      setter: <testLibrary>::@setter::c
    e
      reference: <testLibrary>::@topLevelVariable::e
      firstFragment: #F2
      type: E
      getter: <testLibrary>::@getter::e
      setter: <testLibrary>::@setter::e
    f
      reference: <testLibrary>::@topLevelVariable::f
      firstFragment: #F3
      type: dynamic Function()
        alias: package:test/a.dart::@typeAlias::F
      getter: <testLibrary>::@getter::f
      setter: <testLibrary>::@setter::f
  getters
    synthetic static c
      reference: <testLibrary>::@getter::c
      firstFragment: #F4
      returnType: C
      variable: <testLibrary>::@topLevelVariable::c
    synthetic static e
      reference: <testLibrary>::@getter::e
      firstFragment: #F5
      returnType: E
      variable: <testLibrary>::@topLevelVariable::e
    synthetic static f
      reference: <testLibrary>::@getter::f
      firstFragment: #F6
      returnType: dynamic Function()
        alias: package:test/a.dart::@typeAlias::F
      variable: <testLibrary>::@topLevelVariable::f
  setters
    synthetic static c
      reference: <testLibrary>::@setter::c
      firstFragment: #F7
      formalParameters
        #E0 requiredPositional value
          firstFragment: #F8
          type: C
      returnType: void
      variable: <testLibrary>::@topLevelVariable::c
    synthetic static e
      reference: <testLibrary>::@setter::e
      firstFragment: #F9
      formalParameters
        #E1 requiredPositional value
          firstFragment: #F10
          type: E
      returnType: void
      variable: <testLibrary>::@topLevelVariable::e
    synthetic static f
      reference: <testLibrary>::@setter::f
      firstFragment: #F11
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
    var library = await buildLibrary('typedef F(); F f;');
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
        #F2 f (nameOffset:15) (firstTokenOffset:15) (offset:15)
          element: <testLibrary>::@topLevelVariable::f
      getters
        #F3 synthetic f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
          element: <testLibrary>::@getter::f
      setters
        #F4 synthetic f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
          element: <testLibrary>::@setter::f
          formalParameters
            #F5 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:15)
              element: <testLibrary>::@setter::f::@formalParameter::value
  typeAliases
    F
      reference: <testLibrary>::@typeAlias::F
      firstFragment: #F1
      aliasedType: dynamic Function()
  topLevelVariables
    f
      reference: <testLibrary>::@topLevelVariable::f
      firstFragment: #F2
      type: dynamic Function()
        alias: <testLibrary>::@typeAlias::F
      getter: <testLibrary>::@getter::f
      setter: <testLibrary>::@setter::f
  getters
    synthetic static f
      reference: <testLibrary>::@getter::f
      firstFragment: #F3
      returnType: dynamic Function()
        alias: <testLibrary>::@typeAlias::F
      variable: <testLibrary>::@topLevelVariable::f
  setters
    synthetic static f
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
    var library = await buildLibrary(
      'typedef U F<T, U>(T t); F<int, String> f;',
    );
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
        #F4 f (nameOffset:39) (firstTokenOffset:39) (offset:39)
          element: <testLibrary>::@topLevelVariable::f
      getters
        #F5 synthetic f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:39)
          element: <testLibrary>::@getter::f
      setters
        #F6 synthetic f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:39)
          element: <testLibrary>::@setter::f
          formalParameters
            #F7 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:39)
              element: <testLibrary>::@setter::f::@formalParameter::value
  typeAliases
    F
      reference: <testLibrary>::@typeAlias::F
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
        #E1 U
          firstFragment: #F3
      aliasedType: U Function(T)
  topLevelVariables
    f
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
    synthetic static f
      reference: <testLibrary>::@getter::f
      firstFragment: #F5
      returnType: String Function(int)
        alias: <testLibrary>::@typeAlias::F
          typeArguments
            int
            String
      variable: <testLibrary>::@topLevelVariable::f
  setters
    synthetic static f
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
    var library = await buildLibrary('typedef U F<T, U>(T t); F f;');
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
        #F4 f (nameOffset:26) (firstTokenOffset:26) (offset:26)
          element: <testLibrary>::@topLevelVariable::f
      getters
        #F5 synthetic f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:26)
          element: <testLibrary>::@getter::f
      setters
        #F6 synthetic f (nameOffset:<null>) (firstTokenOffset:<null>) (offset:26)
          element: <testLibrary>::@setter::f
          formalParameters
            #F7 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:26)
              element: <testLibrary>::@setter::f::@formalParameter::value
  typeAliases
    F
      reference: <testLibrary>::@typeAlias::F
      firstFragment: #F1
      typeParameters
        #E0 T
          firstFragment: #F2
        #E1 U
          firstFragment: #F3
      aliasedType: U Function(T)
  topLevelVariables
    f
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
    synthetic static f
      reference: <testLibrary>::@getter::f
      firstFragment: #F5
      returnType: dynamic Function(dynamic)
        alias: <testLibrary>::@typeAlias::F
          typeArguments
            dynamic
            dynamic
      variable: <testLibrary>::@topLevelVariable::f
  setters
    synthetic static f
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
